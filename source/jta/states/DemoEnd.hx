package jta.states;

import jta.states.MainMenu;
import jta.states.BaseState;
import jta.mobile.MobileInput;

class DemoEnd extends BaseState
{
	@:noCompletion
	private var soundPlayed:Bool = false;

	override public function create():Void
	{
		var text:FlxText = new FlxText(0, 290, FlxG.width, 'END OF DEMO\nThanks for playing!', 12);
		text.setFormat(TextUtil.getFont(), 40, FlxColor.WHITE, CENTER);
		text.screenCenter(X);
		add(text);

		super.create();

		FlxG.sound.play(Paths.sound('end'), function():Void
		{
			new FlxTimer().start(1, function(tmr:FlxTimer):Void
			{
				text.text += #if mobile '\n\nTAP TO CONTINUE' #else '\n\nPRESS ANYTHING TO CONTINUE' #end;
				soundPlayed = true;
			});
		});
	}

	override public function update(elapsed:Float):Void
	{
		if (soundPlayed && (Input.justPressed('any') #if mobile || MobileInput.checkAnyTouch(JUST_PRESSED) #end))
		{
			SoundController.play(Paths.sound('select'));
			transitionState(new MainMenu());
		}

		super.update(elapsed);
	}
}
