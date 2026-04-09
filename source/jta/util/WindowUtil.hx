package jta.util;

#if linux
import haxe.Json;
import jta.Assets;
import sys.io.Process;
import jta.util.linux.DesktopEnviromentUtl;
#end

/**
 * Utility class for window-related functions.
 */
@:nullSafety
class WindowUtil
{
	#if linux
	public static var address:String = "";
	#end

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

		if (DesktopEnviromentUtl.getDesktopEnviroment() == "hyprland")
		{
			setWindowAddress();
			toggleFloatingMode();
			centerHyprWindow();
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

	#if linux
	/**
	 * this is exclusive for Hyprland users
	 */
	public static inline function setWindowAddress():Void
	{
		try
		{
			final proccess:Process = new Process("hyprctl", ["activewindow", "-j"]);
			final output:String = proccess.stdout.readAll().toString();
			final json = Json.parse(output);
			proccess.close();
			address = json.address;
		}
		catch (e:Dynamic)
		{
			address = "";
		}
	}

	/**
	 * Toggle the floating mode in the game window.
	 *
	 * this is exclusive for Hyprland users.
	 */
	public static inline function toggleFloatingMode():Void
	{
		Sys.command('hyprctl dispatch togglefloating address:$address');
	}

	/**
	 * center the game window.
	 *
	 * this is exclusive for Hyprland users.
	 */
	public static inline function centerHyprWindow():Void
	{
		Sys.command('hyprctl dispatch centerwindow address:$address');
	}
	#end
}
