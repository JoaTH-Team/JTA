package jta;

import jta.util.FilterUtil;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

@:structInit class Settings
{
	public var volume:Int = 100;
	public var framerate:Int = 60;
	public var fpsCounter:Bool = true;
	#if desktop
	public var fullscreen:Bool = false;
	#end

	public var skipSplash:Bool = false;
	public var locale:String = 'en-US';
	public var filter:String = 'None';

	public var keyboardBinds:Array<FlxKey> = [LEFT, DOWN, UP, RIGHT, SPACE, SHIFT, ENTER, ESCAPE];
	public var gamepadBinds:Array<FlxGamepadInputID> = [DPAD_LEFT, DPAD_DOWN, DPAD_UP, DPAD_RIGHT, A, RIGHT_TRIGGER, START, BACK];
}

/**
 * Handles saving and loading game settings.
 */
@:nullSafety
class Data
{
	/**
	 * Stores the game settings.
	 */
	public static var settings:Settings = {};

	/**
	 * Loads the settings from the save data and applies them.
	 */
	public static function init():Void
	{
		for (key in Reflect.fields(settings))
			if (Reflect.field(FlxG.save.data, key) != null)
				Reflect.setField(settings, key, Reflect.field(FlxG.save.data, key));

		if (Main.fpsDisplay != null)
			Main.fpsDisplay.visible = settings.fpsCounter;

		if (FlxG.save.data.framerate == null)
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			settings.framerate = Std.int(FlxMath.bound(refreshRate, 60, 240));
		}

		Main.framerate = settings.framerate;

		if (settings.filter != null)
			FilterUtil.reloadGameFilter(settings.filter);
	}

	/**
	 * Saves the current settings to the save data.
	 */
	public static function saveSettings():Void
	{
		for (key in Reflect.fields(settings))
			Reflect.setField(FlxG.save.data, key, Reflect.field(settings, key));

		FlxG.save.flush();
	}
}
