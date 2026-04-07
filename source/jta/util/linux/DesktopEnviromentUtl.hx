#if linux
package jta.util.linux;

using StringTools;

/**
 * Utility class for linux current desktop enviroment functions.
 *
 * @author Infinite Kemonoyagi (infinite-kemonoyagi)
 */
@:nullSafety
final class DesktopEnviromentUtl
{
	/**
	 * possibles variables, depending on the desktop enviroment their name will be in one of these variables...
	 *
	 * but in most cases is located in the "XDG_CURRENT_DESKTOP" variable.
	 */
	private static final variables:Array<String> = ["XDG_CURRENT_DESKTOP", "DESKTOP_SESSION", "XDG_SESSION_DESKTOP"];

	/**
	 * return the current desktop enviroment
	 */
	public static function getDesktopEnviroment():String
	{
		for (variable in variables)
		{
			final value:String = Sys.getEnv(variable).trim();
			if (value != null && value != "")
				return value.toLowerCase();
		}

		return "unknown";
	}
}
#end
