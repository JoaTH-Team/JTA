package jta;

import jta.util.FilterUtil;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

@:structInit class Settings
{
	public var volume:Int = 100;
	public var musicVolume:Int = 100;
	public var sfxVolume:Int = 100;
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
	public static function load():Void
	{
		for (key in Reflect.fields(settings))
		{
			final saved:Dynamic = Reflect.field(FlxG.save.data, key);
			if (saved == null)
				continue;

			final current:Dynamic = Reflect.field(settings, key);

			if (current is Array && saved is Array)
			{
				final defaults:Array<Dynamic> = cast current;
				final savedList:Array<Dynamic> = cast saved;
				Reflect.setField(settings, key, [for (i in 0...defaults.length) i < savedList.length ? savedList[i] : defaults[i]]);
			}
			else
				Reflect.setField(settings, key, saved);
		}

		if (Main.fps != null)
			Main.fps.visible = settings.fpsCounter;

		if (settings.filter != null)
			FilterUtil.reloadGameFilter(settings.filter);
	}

	/**
	 * Saves the current settings to the save data.
	 */
	public static function save():Void
	{
		for (key in Reflect.fields(settings))
			Reflect.setField(FlxG.save.data, key, Reflect.field(settings, key));

		FlxG.save.flush();
	}
}
