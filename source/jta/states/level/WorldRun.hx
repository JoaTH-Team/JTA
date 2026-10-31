package jta.states.level;

/**
 * Keeps track of "Play All Levels" runs, where every level of a world is played back to back.
 *
 * `Level.finishLevel()` asks this for the next level. Menus call `stop()` when they open,
 * so quitting a run from the pause menu, game over screen, etc. always ends it.
 */
class WorldRun
{
	/**
	 * The world being played, or null if there's no run going on.
	 */
	public static var worldId(default, null):Null<String> = null;

	/**
	 * The levels of the run, in order.
	 */
	public static var levels(default, null):Array<String> = [];

	/**
	 * Set when the last level of a run was just cleared, so the default `Level.afterFinish()`
	 * knows to go back to the world map. Cleared by `consumeFinished()`.
	 */
	static var justFinished:Bool = false;

	/**
	 * Whether a run is going on.
	 */
	public static var active(get, never):Bool;

	static function get_active():Bool
		return worldId != null;

	/**
	 * Starts a run.
	 * @param worldId The world being played.
	 * @param levels The levels to play, in order.
	 */
	public static function start(worldId:String, levels:Array<String>):Void
	{
		WorldRun.worldId = worldId;
		WorldRun.levels = levels.copy();
		justFinished = false;
	}

	/**
	 * Ends the run (if any).
	 */
	public static function stop():Void
	{
		worldId = null;
		levels = [];
		justFinished = false;
	}

	/**
	 * Called when a level is cleared. Returns the next level of the run, or null if there's no run
	 * or this was the last level (in which case the run ends).
	 * @param levelId The level that was just cleared.
	 */
	public static function next(levelId:String):Null<String>
	{
		if (!active)
			return null;

		final index:Int = levels.indexOf(levelId);

		if (index >= 0 && index + 1 < levels.length)
			return levels[index + 1];

		stop();
		justFinished = true;
		return null;
	}

	/**
	 * Whether a run just ended by clearing its last level. Resets after it's checked.
	 */
	public static function consumeFinished():Bool
	{
		final value:Bool = justFinished;
		justFinished = false;
		return value;
	}

	/**
	 * Where the given level is in the run, as "2/3", or null if it's not part of a run.
	 */
	public static function getProgress(levelId:String):Null<String>
	{
		if (!active)
			return null;

		final index:Int = levels.indexOf(levelId);
		return (index >= 0) ? '${index + 1}/${levels.length}' : null;
	}
}
