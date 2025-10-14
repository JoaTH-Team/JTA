package jta.substates;

import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.typeLimit.NextState;
import jta.modding.module.ModuleHandler;
import jta.modding.events.CreateEvent;
import jta.modding.events.UpdateEvent;
import jta.Data;

/**
 * Base class used for all substates in the game.
 * @author Joalor64
 */
class BaseSubState extends FlxSubState
{
	public var id:String = 'default';

	/**
	 * @param bgColor Optional background color forwarded to FlxSubState.
	 * @param id The ID of the substate.
	 */
	override public function new(?bgColor:Null<Int> = null, ?id:String = 'default'):Void
	{
		super(bgColor);

		this.id = id;
	}

	override public function create():Void
	{
		super.create();

		id ??= 'default';

		ModuleHandler.callEvent(module ->
		{
			module.create(new CreateEvent(module, id));
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		FlxG.stage.frameRate = Data.settings.framerate;

		ModuleHandler.callEvent(module ->
		{
			module.update(new UpdateEvent(module, id, elapsed));
		});
	}

	override public function destroy():Void
	{
		super.destroy();

		id = 'default';
	}

	public function transitionState(state:NextState, ?noTransition:Bool = false):Void
	{
		FlxTransitionableState.skipNextTransIn = noTransition;
		FlxTransitionableState.skipNextTransOut = noTransition;

		FlxG.switchState(state);
	}
}
