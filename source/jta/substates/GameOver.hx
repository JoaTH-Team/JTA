package jta.substates;

import jta.Global;
import jta.input.Input;
import jta.locale.Locale;
import jta.states.MainMenu;
import jta.states.level.Level;
import jta.substates.BaseSubState;

class GameOver extends BaseSubState
{
	var selections:Array<String> = ["$RESTART", "$RETURN"];
	var selectedIndex:Int = 0;

	var selectionGroup:FlxTypedGroup<FlxText>;

	public function new():Void
	{
		super(0x80000000);
	}

	override public function create():Void
	{
		cameras = [FlxG.cameras.list[1]];

		FlxG.sound.play(Paths.sound('die'));

		var title:FlxText = new FlxText(10, 10, FlxG.width, Locale.getMenu("$GAME_OVER"));
		title.setFormat(Paths.font('main'), 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.scrollFactor.set();
		add(title);

		selectionGroup = new FlxTypedGroup<FlxText>();
		add(selectionGroup);

		for (i in 0...selections.length)
		{
			var selection:FlxText = new FlxText(10, 100 + i * 42, FlxG.width, Locale.getMenu(selections[i]));
			selection.setFormat(Paths.font('main'), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			selection.scrollFactor.set();
			selection.ID = i;
			selectionGroup.add(selection);
		}

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		if (Input.justPressed('up'))
			changeSelection(-1);
		else if (Input.justPressed('down'))
			changeSelection(1);

		if (Input.justPressed('confirm'))
		{
			Global.lives = 3;
			Global.save();
			switch (selectedIndex)
			{
				case 0:
					FlxG.sound.play(Paths.sound('select'));
					Level.resetLevel();
				case 1:
					FlxG.sound.play(Paths.sound('cancel'));
					transitionState(new MainMenu());
			}
		}

		selectionGroup.forEach(function(text:FlxText):Void
		{
			text.color = (text.ID == selectedIndex) ? FlxColor.YELLOW : FlxColor.WHITE;
		});

		super.update(elapsed);
	}

	private function changeSelection(num:Int):Void
	{
		FlxG.sound.play(Paths.sound('scroll'));
		selectedIndex = FlxMath.wrap(selectedIndex + num, 0, selections.length - 1);
	}
}
