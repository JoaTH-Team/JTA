package jta;

import flixel.util.FlxSave;
import jta.registries.LevelRegistry;
import jta.states.level.LevelData;

/**
 * A read-only summary of a save slot, used by the save select menu.
 * Reading one doesn't load the slot into `Global`.
 */
typedef SlotInfo =
{
	/**
	 * The slot number (starting at 0).
	 */
	var slot:Int;

	/**
	 * Whether the slot has no save data.
	 */
	var empty:Bool;

	var coins:Int;
	var score:Int;
	var lives:Int;
	var completedLevels:Array<String>;

	/**
	 * Total time played in seconds.
	 */
	var playtime:Float;

	/**
	 * When the slot was last saved (`Date.getTime()`), or 0 if unknown.
	 */
	var lastPlayed:Float;

	/**
	 * The world the player was last on (on the world map), or null.
	 */
	var lastWorld:Null<String>;

	/**
	 * Worlds whose last level was beaten (see `Global.clearedWorlds`).
	 */
	var clearedWorlds:Array<String>;
}

/**
 * How a world looks on the world map.
 */
enum abstract WorldStatus(Int) to Int
{
	/**
	 * Unlocked, but the last level isn't cleared yet.
	 */
	var OPEN = 0;

	/**
	 * The last level of the world is cleared.
	 */
	var CLEARED = 1;

	/**
	 * The world before it isn't cleared yet.
	 */
	var LOCKED = 2;

	/**
	 * The world has no levels yet.
	 */
	var COMING_SOON = 3;
}

/**
 * Holds the player's progress (coins, score, lives, completed levels) and handles save slots.
 *
 * Each slot is its own `FlxSave` (`slot1`, `slot2`, ...), so erasing or corrupting one doesn't touch the others.
 * Settings and keybinds are NOT stored here; those are shared across slots in `Data`.
 */
class Global
{
	/**
	 * How many save slots there are.
	 */
	public static final SLOT_COUNT:Int = 3;

	/**
	 * The version of the save format. Bump this whenever the saved fields change,
	 * and handle the old version in `readSlot()`.
	 */
	public static final SAVE_VERSION:Int = 1;

	/**
	 * Lives a new file (or a game over) starts with.
	 */
	public static final DEFAULT_LIVES:Int = 3;

	/**
	 * The currently loaded slot, or -1 if no slot has been picked yet.
	 * While this is -1, `save()` does nothing.
	 */
	public static var currentSlot(default, null):Int = -1;

	public static var coins:Int = 0;

	private static var _score:Int = 0;
	public static var score(get, set):Int;

	static function get_score():Int
		return _score;

	static function set_score(value:Int):Int
	{
		_score = (value > 9999990) ? 9999990 : value;
		return _score;
	}

	public static var lives:Int = DEFAULT_LIVES;

	/**
	 * IDs of the levels the player has completed (e.g. `world1/lev1`).
	 * Replaces the old `flags` array, which was indexed by level number.
	 */
	public static var completedLevels:Array<String> = [];

	/**
	 * Total time played on the current slot, in seconds.
	 * Ticked by `BaseState` while a slot is loaded.
	 */
	public static var playtime:Float = 0;

	/**
	 * The world the player was last on (on the world map), or null to start on the furthest unlocked world.
	 */
	public static var lastWorld:Null<String> = null;

	/**
	 * Worlds the player has cleared (beaten the world's last level).
	 * Stored separately from `completedLevels` so a world stays cleared even if a mod adds levels after its old last level.
	 */
	public static var clearedWorlds:Array<String> = [];

	/**
	 * Marks a level as completed and saves.
	 * @param levelId The level ID.
	 */
	public static function completeLevel(levelId:String):Void
	{
		if (!completedLevels.contains(levelId))
			completedLevels.push(levelId);

		updateClearedWorlds();
		save();
	}

	/**
	 * Whether a level has been completed.
	 * @param levelId The level ID.
	 */
	public static function isLevelCompleted(levelId:String):Bool
		return completedLevels.contains(levelId);

	/**
	 * Resets the progress in memory to a brand new file. Doesn't touch any save data.
	 */
	public static function resetProgress():Void
	{
		coins = 0;
		score = 0;
		lives = DEFAULT_LIVES;
		completedLevels = [];
		playtime = 0;
		lastWorld = null;
		clearedWorlds = [];
	}

	@:noCompletion
	private static var _save:Null<FlxSave>;

	@:noCompletion
	private static function bindSlot(slot:Int):FlxSave
	{
		final save:FlxSave = new FlxSave();
		save.bind('slot${slot + 1}', Lib.application.meta.get('file'));
		return save;
	}

	@:noCompletion
	private static function isValidSlot(slot:Int):Bool
		return slot >= 0 && slot < SLOT_COUNT;

	/**
	 * Starts a new game in a slot, overwriting whatever was there.
	 * @param slot The slot number (starting at 0).
	 */
	public static function newGame(slot:Int):Void
	{
		if (!isValidSlot(slot))
			return;

		resetProgress();
		useSlot(slot);
		save();
	}

	/**
	 * Loads a slot's progress into `Global` and makes it the current slot.
	 * @param slot The slot number (starting at 0).
	 */
	public static function loadSlot(slot:Int):Void
	{
		if (!isValidSlot(slot))
			return;

		final info:SlotInfo = getSlotInfo(slot);

		coins = info.coins;
		score = info.score;
		lives = info.lives;
		completedLevels = info.completedLevels;
		playtime = info.playtime;
		lastWorld = info.lastWorld;
		clearedWorlds = info.clearedWorlds;

		useSlot(slot);
		updateClearedWorlds();
	}

	/**
	 * Deletes a slot's save data. If it's the current slot, the progress in memory is reset too.
	 * @param slot The slot number (starting at 0).
	 */
	public static function eraseSlot(slot:Int):Void
	{
		if (!isValidSlot(slot))
			return;

		if (slot == currentSlot)
		{
			_save?.erase();
			_save?.destroy();
			_save = null;
			currentSlot = -1;
			resetProgress();
		}
		else
		{
			final save:FlxSave = bindSlot(slot);
			save.erase();
			save.destroy();
		}
	}

	/**
	 * Reads a slot without loading it.
	 * @param slot The slot number (starting at 0).
	 */
	public static function getSlotInfo(slot:Int):SlotInfo
	{
		final save:FlxSave = (slot == currentSlot && _save != null) ? _save : bindSlot(slot);
		final info:SlotInfo = readSlot(slot, save.isEmpty() ? null : save.data);

		if (save != _save)
			save.destroy();

		return info;
	}

	@:noCompletion
	private static function readSlot(slot:Int, data:Null<Dynamic>):SlotInfo
	{
		final info:SlotInfo = {
			slot: slot,
			empty: true,
			coins: 0,
			score: 0,
			lives: DEFAULT_LIVES,
			completedLevels: [],
			playtime: 0,
			lastPlayed: 0,
			lastWorld: null,
			clearedWorlds: []
		};

		if (data == null)
			return info;

		info.empty = false;

		if (data.coins != null)
			info.coins = data.coins;
		if (data.score != null)
			info.score = data.score;
		if (data.lives != null)
			info.lives = data.lives;
		if (data.completedLevels != null)
			info.completedLevels = (data.completedLevels : Array<String>).copy();
		if (data.playtime != null)
			info.playtime = data.playtime;
		if (data.lastPlayed != null)
			info.lastPlayed = data.lastPlayed;
		if (data.lastWorld != null)
			info.lastWorld = data.lastWorld;
		if (data.clearedWorlds != null)
			info.clearedWorlds = (data.clearedWorlds : Array<String>).copy();

		return info;
	}

	@:noCompletion
	private static function useSlot(slot:Int):Void
	{
		if (_save != null && currentSlot != slot)
		{
			_save.destroy();
			_save = null;
		}

		_save ??= bindSlot(slot);
		currentSlot = slot;
	}

	/**
	 * Saves the progress to the current slot. Does nothing if no slot is loaded.
	 */
	public static function save():Void
	{
		if (_save == null || currentSlot < 0)
		{
			trace('No save slot loaded, progress not saved.');
			return;
		}

		_save.data.version = SAVE_VERSION;
		_save.data.coins = coins;
		_save.data.score = score;
		_save.data.lives = lives;
		_save.data.completedLevels = completedLevels;
		_save.data.playtime = playtime;
		_save.data.lastPlayed = Date.now().getTime();
		_save.data.lastWorld = lastWorld;
		_save.data.clearedWorlds = clearedWorlds;
		_save.flush();
	}

	/**
	 * Old name for loading. Progress is now loaded by picking a slot (`loadSlot()`),
	 * so this only moves a Demo 1 save into slot 1 if there is one.
	 */
	public static function load():Void
		migrateLegacySave();

	/**
	 * Demo 1 kept all progress in a single save named `file`.
	 * If that save exists and slot 1 is empty, its progress is moved into slot 1 and the old save is erased.
	 */
	public static function migrateLegacySave():Void
	{
		final legacy:FlxSave = new FlxSave();
		legacy.bind('file', Lib.application.meta.get('file'));

		if (legacy.isEmpty())
		{
			legacy.destroy();
			return;
		}

		final slot:FlxSave = bindSlot(0);

		if (slot.isEmpty())
		{
			slot.data.version = SAVE_VERSION;
			slot.data.coins = legacy.data.coins ?? 0;
			slot.data.score = legacy.data.score ?? 0;
			slot.data.lives = legacy.data.lives ?? DEFAULT_LIVES;
			slot.data.completedLevels = legacy.data.completedLevels ?? [];
			slot.data.playtime = 0;
			slot.data.lastPlayed = Date.now().getTime();

			if (slot.flush())
			{
				trace('Moved Demo 1 save into slot 1.');
				legacy.erase();
			}
		}
		else
			trace('Found a Demo 1 save, but slot 1 is already used. Leaving it alone.');

		slot.destroy();
		legacy.destroy();
	}

	/**
	 * Whether a world's last level has been completed on the current slot.
	 * @param worldId The world ID (e.g. `world1`).
	 */
	public static function isWorldCleared(worldId:String):Bool
	{
		if (clearedWorlds.contains(worldId))
			return true;

		final levels:Array<String> = LevelRegistry.listLevelsInWorld(worldId);
		return levels.length > 0 && isLevelCompleted(levels[levels.length - 1]);
	}

	/**
	 * Adds every world whose last level is completed to `clearedWorlds`. Once a world is in there, it stays.
	 * Called when a level is completed and when a slot is loaded (for saves made before `clearedWorlds` existed).
	 */
	public static function updateClearedWorlds():Void
	{
		for (worldId in LevelRegistry.listWorlds(true))
		{
			if (clearedWorlds.contains(worldId))
				continue;

			final levels:Array<String> = LevelRegistry.listLevelsInWorld(worldId);

			if (levels.length > 0 && isLevelCompleted(levels[levels.length - 1]))
				clearedWorlds.push(worldId);
		}
	}

	/**
	 * Gets how a world should look on the world map for the current slot.
	 * The first world is always unlocked; every other world unlocks once the world before it is cleared.
	 * All levels of an unlocked world are playable.
	 * @param worldId The world ID (e.g. `world1`).
	 */
	public static function getWorldStatus(worldId:String):WorldStatus
	{
		if (LevelRegistry.listLevelsInWorld(worldId).length == 0)
			return COMING_SOON;

		final worlds:Array<String> = LevelRegistry.listWorlds();
		final index:Int = worlds.indexOf(worldId);

		if (index > 0 && !isWorldCleared(worlds[index - 1]))
			return LOCKED;

		return isWorldCleared(worldId) ? CLEARED : OPEN;
	}

	/**
	 * Whether the player can enter a world (it's open or cleared).
	 * @param worldId The world ID.
	 */
	public static function isWorldUnlocked(worldId:String):Bool
	{
		final status:WorldStatus = getWorldStatus(worldId);
		return status == OPEN || status == CLEARED;
	}

	/**
	 * How many (visible) levels a slot has completed, and how many there are in total.
	 * Uses the level registry, so new worlds count automatically.
	 */
	public static function getCompletion(info:SlotInfo):{done:Int, total:Int}
	{
		final levels:Array<String> = LevelRegistry.listLevels();
		var done:Int = 0;

		for (id in levels)
			if (info.completedLevels.contains(id))
				done++;

		return {done: done, total: levels.length};
	}

	/**
	 * The cover image (in `images/menu/level/`) of the furthest level a slot has completed.
	 * Falls back to the first level's cover, then `placeholder`.
	 */
	public static function getFurthestCover(info:SlotInfo):String
	{
		final levels:Array<String> = LevelRegistry.listLevels();
		var cover:Null<String> = null;

		for (id in levels)
		{
			final data:Null<LevelData> = LevelRegistry.getLevelData(id);

			if (cover == null || info.completedLevels.contains(id))
				cover = data?.cover ?? cover;
		}

		return cover ?? 'placeholder';
	}

	/**
	 * Formats seconds as `H:MM:SS` (or `M:SS` under an hour).
	 */
	public static function formatPlaytime(seconds:Float):String
	{
		final total:Int = Std.int(Math.max(0, seconds));
		final h:Int = Std.int(total / 3600);
		final m:Int = Std.int((total % 3600) / 60);
		final s:Int = total % 60;

		final ss:String = StringTools.lpad(Std.string(s), '0', 2);

		if (h > 0)
			return '$h:${StringTools.lpad(Std.string(m), '0', 2)}:$ss';

		return '$m:$ss';
	}
}
