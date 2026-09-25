package jta.registries;

import jta.states.level.Level;
import jta.states.level.ScriptedLevel;

/**
 * Handles the loading and management of level classes within the game.
 */
class LevelRegistry
{
	/**
	 * Map to store associations between level numbers and their classes.
	 */
	private static final levelScriptedClasses:Map<Int, String> = [];

	/**
	 * Loads and initializes level classes.
	 */
	public static function loadLevels():Void
	{
		clearLevels();

		final levelList:Array<String> = ScriptedLevel.listScriptClasses();

		if (levelList.length > 0)
		{
			FlxG.log.notice('Initiating ${levelList.length} levels...');

			for (levelClass in levelList)
			{
				final level:Level = ScriptedLevel.scriptInit(levelClass, 0);

				if (level == null)
					continue;

				FlxG.log.notice('Initialized level "${level.levelNumber}"!');

				levelScriptedClasses.set(level.levelNumber, levelClass);
			}
		}

		FlxG.log.notice('Successfully loaded ${Lambda.count(levelScriptedClasses)} level(s)!');
	}

	/**
	 * Fetches a level by its number.
	 * @param levelNumber The number of the level.
	 * @return The level or null if not found.
	 */
	public static function fetchLevel(levelNumber:Int):Null<Level>
	{
		if (!levelScriptedClasses.exists(levelNumber))
		{
			FlxG.log.error('Unable to load level number "${levelNumber}", not found in cache');

			return null;
		}

		final levelClass:Null<String> = levelScriptedClasses.get(levelNumber);

		if (levelClass != null)
		{
			final level:Level = ScriptedLevel.scriptInit(levelClass, levelNumber);

			if (level == null)
			{
				FlxG.log.error('Unable to initiate level number "${levelNumber}"');

				return null;
			}

			return level;
		}

		return null;
	}

	/**
	 * Clears all loaded level classes.
	 */
	public static function clearLevels():Void
	{
		if (levelScriptedClasses != null)
			levelScriptedClasses.clear();
	}
}
