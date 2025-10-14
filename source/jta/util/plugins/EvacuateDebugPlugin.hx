package jta.util.plugins;

import flixel.FlxBasic;

/**
 * A plugin that let's you evacuate to the main menu when `F4` is pressed.
 * This is useful for debugging or if you get softlocked.
 */
class EvacuateDebugPlugin extends FlxBasic
{
	public function new():Void
	{
		super();
	}

	public static function initialize():Void
	{
		FlxG.plugins.addPlugin(new EvacuateDebugPlugin());
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.F4)
			FlxG.switchState(new jta.states.MainMenu());
	}

	override public function destroy():Void
	{
		super.destroy();
	}
}
