package jta.util;

#if linux
import jta.Assets;
#end

/**
 * Utility class for window-related functions.
 */
@:nullSafety
class WindowUtil
{
	/**
	 * Initializes the window utility.
	 */
	public static function init():Void
	{
		#if linux
		if (Assets.exists('icon.png'))
		{
			final icon:Null<openfl.display.BitmapData> = Assets.getBitmapData('icon.png', false);

			if (icon != null)
				Lib.application.window.setIcon(icon.image);
		}
		#end
	}

	/**
	 * Show a popup with the given text.
	 * @param name The title of the popup.
	 * @param desc The content of the popup.
	 */
	public static inline function showAlert(name:String, desc:String):Void
	{
		#if !android
		Lib.application.window.alert(desc, name);
		#else
		extension.androidtools.Tools.showAlertDialog(name, desc, {name: 'Ok', func: null});
		#end
	}
}
