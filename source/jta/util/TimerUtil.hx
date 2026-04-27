package jta.util;

import haxe.Timer;

/**
 * Utility class for measuring elapsed time.
 * @see https://github.com/FunkinCrew/Funkin/blob/main/source/funkin/util/TimerUtil.hx
 */
class TimerUtil
{
	/**
	 * Starts the timer.
	 * @return The current time.
	 */
	public static function start():Float
	{
		return Timer.stamp();
	}

	/**
	 * Gets the elapsed time in seconds as a string.
	 * @param start The start time.
	 * @param end The end time (optional).
	 * @param precision The number of decimal places (optional, default is 2).
	 * @return The elapsed time in seconds.
	 */
	@:nullSafety(Off)
	public static function seconds(start:Float, ?end:Float, ?precision:Int = 2):String
	{
		return '${FlxMath.roundDecimal(took(start, end), precision)} seconds';
	}

	/**
	 * Gets the elapsed time in milliseconds as a string.
	 * @param start The start time.
	 * @param end The end time (optional).
	 * @return The elapsed time in milliseconds.
	 */
	public static function ms(start:Float, ?end:Float):String
	{
		return '${took(start, end) * 1000} ms';
	}

	/**
	 * Gets the elapsed time.
	 * @param start The start time.
	 * @param end The end time (optional).
	 * @return The elapsed time.
	 */
	@:noCompletion
	private static function took(start:Float, ?end:Float):Float
	{
		return (end != null ? end : Timer.stamp()) - start;
	}
}
