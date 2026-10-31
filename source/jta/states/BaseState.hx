package jta.states;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.util.typeLimit.NextState;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import jta.modding.module.ModuleHandler;
import jta.modding.events.CreateEvent;
import jta.modding.events.UpdateEvent;
import jta.states.Startup;
import jta.Paths;

/**
 * Base class used for all states in the game.
 * @author Joalor64
 */
class BaseState extends FlxTransitionableState
{
	public var leftWatermarkText:Null<FlxText> = null;
	public var rightWatermarkText:Null<FlxText> = null;

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

		#if mobile
		final transWidth:Float = FlxG.width + jta.mobile.MobileInput.barWidth * 2;
		final transHeight:Float = FlxG.height + jta.mobile.MobileInput.barHeight * 2;
		#else
		final transWidth:Float = FlxG.width;
		final transHeight:Float = FlxG.height;
		#end

		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;
		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-300, -300, transWidth * 1.8, transHeight * 1.8));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-300, -300, transWidth * 1.8, transHeight * 1.85));

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

		createWatermarkText();
	}

	function createWatermarkText()
	{
		leftWatermarkText = new FlxText(0, FlxG.height - 48, FlxG.width, '', 12);
		rightWatermarkText = new FlxText(0, FlxG.height - 48, FlxG.width, '', 12);

		leftWatermarkText.zIndex = 100000;
		rightWatermarkText.zIndex = 100000;
		leftWatermarkText.scrollFactor.set(0, 0);
		rightWatermarkText.scrollFactor.set(0, 0);
		TextUtil.style(leftWatermarkText, 36, LEFT);
		TextUtil.style(rightWatermarkText, 36, RIGHT);

		leftWatermarkText.x = 0;
		rightWatermarkText.x = FlxG.width - rightWatermarkText.width - 10;

		add(leftWatermarkText);
		add(rightWatermarkText);
	}

	override public function update(elapsed:Float):Void
	{
		#if desktop
		if (FlxG.save.data != null && FlxG.fullscreen != Data.settings.fullscreen)
			FlxG.fullscreen = Data.settings.fullscreen;
		#end

		super.update(elapsed);

		if (Global.currentSlot >= 0)
			Global.playtime += elapsed;

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
