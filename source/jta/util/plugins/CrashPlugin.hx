package jta.util.plugins;

import flixel.FlxBasic;

/**
 * A plugin that lets you press `Ctrl + Shift + C` to crash the game for testing purposes.
 */
class CrashPlugin extends FlxBasic
{
	public function new():Void
	{
		super();
	}

	public static function initialize():Void
	{
		FlxG.plugins.addPlugin(new CrashPlugin());
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.C)
		{
			throw "CrashPlugin: Forced crash for testing purposes.";
		}
	}

	override public function destroy():Void
	{
		super.destroy();
	}
}
