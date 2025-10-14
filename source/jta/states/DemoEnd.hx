package jta.states;

import jta.Paths;
import jta.input.Input;
import jta.states.MainMenu;
import jta.states.BaseState;

class DemoEnd extends BaseState
{
	override public function create():Void
	{
		var text:FlxText = new FlxText(0, 0, FlxG.width, 'END OF DEMO\nThanks for playing!', 12);
		text.setFormat(Paths.font('main'), 40, FlxColor.WHITE, CENTER);
		text.screenCenter();
		add(text);

		var text2:FlxText = new FlxText(0, text.y + 300, FlxG.width, 'PRESS ANYTHING TO CONTINUE', 12);
		text2.setFormat(Paths.font('main'), 20, FlxColor.WHITE, CENTER);
		add(text2);

		super.create();

		FlxG.sound.play(Paths.sound('end'));
	}

	override public function update(elapsed:Float):Void
	{
		if (Input.justPressed('any'))
		{
			FlxG.sound.play(Paths.sound('select'));
			transitionState(new MainMenu());
		}

		super.update(elapsed);
	}
}
