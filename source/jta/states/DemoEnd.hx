package jta.states;

import jta.states.MainMenu;
import jta.states.BaseState;

class DemoEnd extends BaseState
{
	@:noCompletion
	private var soundPlayed:Bool = false;

	override public function create():Void
	{
		var text:FlxText = new FlxText(0, 290, FlxG.width, 'END OF DEMO\nThanks for playing!', 12);
		text.setFormat(Paths.font('main'), 40, FlxColor.WHITE, CENTER);
		text.screenCenter(X);
		add(text);

		super.create();

		FlxG.sound.play(Paths.sound('end'), function():Void
		{
			new FlxTimer().start(1, function(tmr:FlxTimer):Void
			{
				text.text += '\n\nPRESS ANYTHING TO CONTINUE';
				soundPlayed = true;
			});
		});
	}

	override public function update(elapsed:Float):Void
	{
		if (soundPlayed && Input.justPressed('any'))
		{
			SoundController.play(Paths.sound('select'));
			transitionState(new MainMenu());
		}

		super.update(elapsed);
	}
}
