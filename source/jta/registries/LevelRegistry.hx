package jta.registries;

import haxe.Json;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFLAssets;
import jta.locale.Locale;
import jta.states.level.Level;
import jta.states.level.LevelData;
import jta.states.level.ScriptedLevel;

/**
 * Handles the loading and management of level classes within the game.
 */
class LevelRegistry
{
	static final LEVELS_DIR:String = 'assets/levels/';

	/**
	 * Level ID -> parsed `level.json`.
	 */
	static final levelData:Map<String, LevelData> = [];

	/**
	 * World ID -> parsed `world.json`.
	 */
	static final worldData:Map<String, WorldData> = [];

	/**
	 * Level ID -> scripted class name, for levels that have a script.
	 */
	static final levelScriptedClasses:Map<String, String> = [];

	/**
	 * Every level ID, in play order.
	 */
	static var levelOrder:Array<String> = [];

	/**
	 * Loads all level data and scripts.
	 */
	public static function loadLevels():Void
	{
		clearLevels();

		for (path in OpenFLAssets.list(AssetType.TEXT))
		{
			if (!path.startsWith(LEVELS_DIR) || !path.endsWith('.json'))
				continue;

			final parts:Array<String> = path.substr(LEVELS_DIR.length).split('/');

			if (parts.length == 3 && parts[2] == 'level.json')
			{
				final id:String = '${parts[0]}/${parts[1]}';
				final data:Null<LevelData> = parseJson(path);

				if (data != null)
				{
					if (data.name == null)
						data.name = id;

					levelData.set(id, data);
				}
			}
			else if (parts.length == 2 && parts[1] == 'world.json')
			{
				final data:Null<WorldData> = parseJson(path);

				if (data != null)
					worldData.set(parts[0], data);
			}
		}

		final scriptClasses:Array<String> = ScriptedLevel.listScriptClasses();

		for (levelClass in scriptClasses)
		{
			final level:Level = ScriptedLevel.scriptInit(levelClass, 'unknown');

			if (level == null || level.levelId == null)
				continue;

			if (!levelData.exists(level.levelId))
				FlxG.log.warn('Level script "$levelClass" is for "${level.levelId}", which has no level.json (it won\'t be on the level select)');

			levelScriptedClasses.set(level.levelId, levelClass);
		}

		levelOrder = [for (id in levelData.keys()) id];
		levelOrder.sort(compareLevels);

		FlxG.log.notice('Successfully loaded ${levelOrder.length} level(s) (${Lambda.count(levelScriptedClasses)} scripted)!');
	}

	/**
	 * Gets the level IDs in play order.
	 * @param includeHidden Whether to include levels marked `hidden`.
	 * @return The level IDs.
	 */
	public static function listLevels(?includeHidden:Bool = false):Array<String>
	{
		return [
			for (id in levelOrder)
				if (includeHidden || levelData.get(id)?.hidden != true) id
		];
	}

	/**
	 * Gets the parsed `level.json` of a level.
	 * @param levelId The level ID.
	 * @return The data, or null if the level has no `level.json`.
	 */
	public static function getLevelData(levelId:String):Null<LevelData>
	{
		return levelData.get(levelId);
	}

	/**
	 * Gets the display name of a level, translated if its name is a `$` locale key.
	 * @param levelId The level ID.
	 * @return The display name.
	 */
	public static function getLevelName(levelId:String):String
	{
		final data:Null<LevelData> = levelData.get(levelId);

		if (data == null)
			return levelId;

		return localize(data.name);
	}

	/**
	 * Gets the world IDs in map order. Worlds come from `world.json` files and from level folders.
	 * @param includeHidden Whether to include worlds marked `hidden`.
	 * @return The world IDs.
	 */
	public static function listWorlds(?includeHidden:Bool = false):Array<String>
	{
		final worlds:Array<String> = [for (id in worldData.keys()) id];

		for (levelId in levelOrder)
		{
			final worldId:String = getWorldOf(levelId);
			if (!worlds.contains(worldId))
				worlds.push(worldId);
		}

		worlds.sort(compareWorlds);

		return [
			for (id in worlds)
				if (includeHidden || worldData.get(id)?.hidden != true) id
		];
	}

	/**
	 * Gets the visible levels of one world, in play order.
	 * @param worldId The world ID (e.g. `world1`).
	 * @return The level IDs.
	 */
	public static function listLevelsInWorld(worldId:String):Array<String>
	{
		return [for (id in listLevels()) if (getWorldOf(id) == worldId) id];
	}

	/**
	 * Gets the parsed `world.json` of a world.
	 * @param worldId The world ID.
	 * @return The data, or null if the world has no `world.json`.
	 */
	public static function getWorldData(worldId:String):Null<WorldData>
	{
		return worldData.get(worldId);
	}

	/**
	 * Gets the display name of a world, translated if its name is a `$` locale key.
	 * @param worldId The world ID.
	 * @return The display name.
	 */
	public static function getWorldName(worldId:String):String
	{
		final name:Null<String> = worldData.get(worldId)?.name;
		return (name != null) ? localize(name) : worldId;
	}

	/**
	 * Gets the world a level belongs to (the first part of its ID).
	 * @param levelId The level ID (e.g. `world1/lev2`).
	 * @return The world ID (e.g. `world1`).
	 */
	public static function getWorldOf(levelId:String):String
	{
		return levelId.split('/')[0];
	}

	/**
	 * Gets the next visible level after the given one, for "continue" style buttons.
	 * @param levelId The level ID.
	 * @return The next level ID, or null if it's the last one.
	 */
	public static function getNextLevel(levelId:String):Null<String>
	{
		final list:Array<String> = listLevels();
		final index:Int = list.indexOf(levelId);

		return (index >= 0 && index + 1 < list.length) ? list[index + 1] : null;
	}

	/**
	 * Creates a level by its ID.
	 * Uses the level's script if it has one, otherwise a plain `Level` built from `level.json`.
	 * @param levelId The level ID.
	 * @return The level, or null if it doesn't exist.
	 */
	public static function fetchLevel(levelId:String):Null<Level>
	{
		final data:Null<LevelData> = levelData.get(levelId);
		final levelClass:Null<String> = levelScriptedClasses.get(levelId);

		if (data == null && levelClass == null)
		{
			FlxG.log.error('Unable to load level "$levelId": no level.json or script found');
			return null;
		}

		final level:Null<Level> = (levelClass != null) ? ScriptedLevel.scriptInit(levelClass, levelId) : new Level(levelId);

		if (level == null)
		{
			FlxG.log.error('Unable to initiate level "$levelId"');
			return null;
		}

		level.levelData = data;
		level.levelName = getLevelName(levelId);

		return level;
	}

	/**
	 * Clears all loaded levels.
	 */
	public static function clearLevels():Void
	{
		levelData.clear();
		worldData.clear();
		levelScriptedClasses.clear();
		levelOrder = [];
	}

	static function localize(name:String):String
	{
		if (name.startsWith("$"))
		{
			final str:Null<String> = Locale.getString(name, 'levels');

			if (str != null && str != '')
				return str;
		}

		return name;
	}

	static function compareWorlds(a:String, b:String):Int
	{
		final orderA:Int = worldData.get(a)?.order ?? 999999;
		final orderB:Int = worldData.get(b)?.order ?? 999999;

		return (orderA != orderB) ? orderA - orderB : Reflect.compare(a, b);
	}

	static function compareLevels(a:String, b:String):Int
	{
		final worldA:String = a.split('/')[0];
		final worldB:String = b.split('/')[0];

		if (worldA != worldB)
		{
			final orderA:Int = worldData.get(worldA)?.order ?? 999999;
			final orderB:Int = worldData.get(worldB)?.order ?? 999999;

			return (orderA != orderB) ? orderA - orderB : Reflect.compare(worldA, worldB);
		}

		final orderA:Int = levelData.get(a)?.order ?? 0;
		final orderB:Int = levelData.get(b)?.order ?? 0;

		return (orderA != orderB) ? orderA - orderB : Reflect.compare(a, b);
	}

	static function parseJson(path:String):Dynamic
	{
		try
		{
			final text:Null<String> = OpenFLAssets.getText(path);

			if (text != null)
				return Json.parse(text);
		}
		catch (e:Dynamic)
			FlxG.log.error('Failed to parse "$path": $e');

		return null;
	}
}
