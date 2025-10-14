package jta.states;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.util.typeLimit.NextState;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import jta.modding.module.ModuleHandler;
import jta.modding.events.CreateEvent;
import jta.modding.events.UpdateEvent;
import jta.states.Startup;
import jta.Data;

/**
 * Base class used for all states in the game.
 * @author Joalor64
 */
class BaseState extends FlxTransitionableState
{
	public var id:String = 'default';

	/**
	 * @param id The ID of the state.
	 * @param noTransition Whether or not to skip the transition when entering a state.
	 */
	override public function new(?id:String = 'default', ?noTransition:Bool = false):Void
	{
		super();

		this.id = id;

		if (!Startup.transitionsAllowed)
		{
			noTransition = true;
			Startup.transitionsAllowed = true;
		}

		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;
		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		FlxTransitionableState.skipNextTransIn = noTransition;
		FlxTransitionableState.skipNextTransOut = noTransition;
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
		#if desktop
		if (FlxG.save.data != null)
			FlxG.fullscreen = Data.settings.fullscreen;
		#end

		super.update(elapsed);

		if (FlxG.stage != null)
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
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		FlxTransitionableState.skipNextTransIn = noTransition;
		FlxTransitionableState.skipNextTransOut = noTransition;

		FlxG.switchState(state);
	}
}
