package jta.substates;

import jta.locale.Locale;
import jta.objects.MenuList;
import jta.states.WorldMap;
import jta.states.LevelSelect;
import jta.substates.BaseSubState;
import jta.mobile.MobileInput;

class LevelComplete extends BaseSubState
{
	var onContinue:Void->Void;

	var menu:MenuList;

	private var mobileControls:Null<MobileInput>;

	public function new(?onContinue:Void->Void):Void
	{
		super(0x80000000);

		this.onContinue = onContinue;
	}

	override public function create():Void
	{
		cameras = [FlxG.cameras.list[1]];

		var title:FlxText = TextUtil.make(10, 10, FlxG.width, Locale.getMenu("$LEVEL_COMPLETE"), 40);
		title.scrollFactor.set();
		add(title);

		menu = new MenuList(30, 100);
		menu.addOption(Locale.getMenu("$CONTINUE"), function():Void
		{
			menu.enabled = false;

			if (onContinue != null)
				onContinue();
			else
				transitionState(new LevelSelect());
		});
		menu.addOption(Locale.getMenu("$RETURN"), function():Void
		{
			menu.enabled = false;
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
}
