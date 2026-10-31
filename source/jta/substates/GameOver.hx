package jta.substates;

import jta.locale.Locale;
import jta.objects.MenuList;
import jta.states.WorldMap;
import jta.states.level.Level;
import jta.substates.BaseSubState;
import jta.mobile.MobileInput;

class GameOver extends BaseSubState
{
	var menu:MenuList;

	private var mobileControls:Null<MobileInput>;

	public function new():Void
	{
		super(0x80000000);
	}

	override public function create():Void
	{
		cameras = [FlxG.cameras.list[1]];

		SoundController.play(Paths.sound('die'));

		var title:FlxText = TextUtil.make(10, 10, FlxG.width, Locale.getMenu("$GAME_OVER"), 40);
		title.scrollFactor.set();
		add(title);

		menu = new MenuList(30, 100);
		menu.addOption(Locale.getMenu("$RESTART"), function():Void
		{
			refillLives();
			Level.restartFromStart();
		});
		menu.addOption(Locale.getMenu("$RETURN"), function():Void
		{
			refillLives();
			transitionState(new WorldMap());
		}, 'cancel');
		add(menu);

		#if mobile
		mobileControls = new MobileInput();
		mobileControls.setupMenuVertical(false);
		add(mobileControls);
		#end

		super.create();
	}

	function refillLives():Void
	{
		Global.lives = Global.DEFAULT_LIVES;
		Global.save();
	}
}
