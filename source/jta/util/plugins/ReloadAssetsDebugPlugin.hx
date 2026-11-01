package jta.util.plugins;

import flixel.FlxBasic;
import jta.states.level.Level;
import jta.modding.PolymodHandler;
import jta.modding.base.ScriptedFlxState;
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
			PolymodHandler.load();

			if (FlxG.state is ScriptedBaseState)
			{
				@:privateAccess {
					final scriptedState:ScriptedBaseState = cast(FlxG.state, ScriptedBaseState);
					final className:String = scriptedState._asc.fullyQualifiedName;
					final stateId:String = scriptedState.id;
					FlxG.switchState(() -> ScriptedBaseState.scriptInit(className, stateId));
				}
			}
			else if (FlxG.state is ScriptedFlxState)
			{
				@:privateAccess {
					final scriptedState:ScriptedFlxState = cast(FlxG.state, ScriptedFlxState);
					final className:String = scriptedState._asc.fullyQualifiedName;
					FlxG.switchState(() -> ScriptedFlxState.scriptInit(className));
				}
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
