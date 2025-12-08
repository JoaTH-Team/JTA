package jta.util.plugins;

import flixel.FlxBasic;
import jta.states.level.Level;
import jta.modding.PolymodHandler;
import jta.modding.base.ScriptedBaseState;

/**
 * A plugin that lets you press `F5` (or `Shift + 5` on HTML5) to reload all game assets and the current state.
 * This is useful during development.
 */
class ReloadAssetsDebugPlugin extends FlxBasic
{
	public function new():Void
	{
		super();
	}

	public static function initialize():Void
	{
		FlxG.plugins.addPlugin(new ReloadAssetsDebugPlugin());
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if html5
		if (FlxG.keys.justPressed.FIVE && FlxG.keys.pressed.SHIFT)
		#else
		if (FlxG.keys.justPressed.F5)
		#end
		{
			PolymodHandler.forceReloadAssets();

			if (Std.isOfType(FlxG.state, ScriptedBaseState))
			{
				var scriptedState = cast(FlxG.state, ScriptedBaseState);
				FlxG.switchState(ScriptedBaseState.init(scriptedState.id));
			}
			else if (Std.isOfType(FlxG.state, Level))
				Level.resetLevel();
			else
				FlxG.resetState();
		}
	}

	override public function destroy():Void
	{
		super.destroy();
	}
}
