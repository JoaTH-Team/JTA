package jta.states;

import jta.Data;
import jta.Global;
import jta.input.Input;
import jta.modding.PolymodHandler;
import jta.states.BaseState;
import flixel.sound.FlxSound;

class Startup extends BaseState
{
	var bg:FlxSprite;
	var haxeflixel:FlxSprite;
	var haxeflixelTxt:FlxText;

	var blipSnd:FlxSound;

	static public var transitionsAllowed:Bool = false;

	override public function create():Void
	{
		FlxG.autoPause = FlxG.fixedTimestep = false;

		Data.init();
		Global.load();
		Input.refreshControls();
		PolymodHandler.init();

		if (!Data.settings.skipSplash)
		{
			blipSnd = FlxG.sound.load(Paths.sound('blip'));

			bg = new FlxSprite().loadGraphic(Paths.image('menu/start_bg'));
			bg.screenCenter();
			add(bg);

			haxeflixel = new FlxSprite().loadGraphic(Paths.image('haxeflixel'), true, 16, 16);
			haxeflixel.animation.add('green', [0], 1);
			haxeflixel.animation.add('yellow', [1], 1);
			haxeflixel.animation.add('red', [2], 1);
			haxeflixel.animation.add('blue', [3], 1);
			haxeflixel.animation.add('full', [4, 5, 6, 7, 8, 9], 12, false);
			haxeflixel.screenCenter();
			haxeflixel.scale.set(10, 10);
			haxeflixel.alpha = 0;
			add(haxeflixel);

			haxeflixelTxt = new FlxText(0, haxeflixel.y + 130, FlxG.width, '');
			haxeflixelTxt.setFormat(Paths.font('main.ttf'), 24, FlxColor.WHITE, CENTER);
			haxeflixelTxt.screenCenter(X);
			add(haxeflixelTxt);

			new FlxTimer().start(0.041, function(tmr:FlxTimer):Void
			{
				playBlip();
				haxeflixel.alpha = 1;
				haxeflixel.animation.play('green');
				haxeflixelTxt.text = 'Made';
				haxeflixelTxt.color = 0x00b922;
			});
			new FlxTimer().start(0.184, function(tmr:FlxTimer):Void
			{
				playBlip();
				haxeflixel.animation.play('yellow');
				haxeflixelTxt.text = 'Made with';
				haxeflixelTxt.color = 0xffc132;
			});
			new FlxTimer().start(0.334, function(tmr:FlxTimer):Void
			{
				playBlip();
				haxeflixel.animation.play('red');
				haxeflixelTxt.text = 'Made with Haxe';
				haxeflixelTxt.color = 0xf5274e;
			});
			new FlxTimer().start(0.495, function(tmr:FlxTimer):Void
			{
				playBlip();
				haxeflixel.animation.play('blue');
				haxeflixelTxt.text = 'Made with HaxeFli';
				haxeflixelTxt.color = 0x3641ff;
			});
			new FlxTimer().start(0.636, function(tmr:FlxTimer):Void
			{
				playBlip();
				haxeflixel.animation.play('full');
				haxeflixelTxt.text = 'Made with HaxeFlixel';
				haxeflixelTxt.color = 0x04cdfb;
				new FlxTimer().start(1.5, function(tmr:FlxTimer):Void
				{
					transitionState(new MainMenu());
				});
			});
		}
		else
			transitionState(new MainMenu());
	}

	function playBlip():Void
	{
		if (blipSnd != null)
		{
			blipSnd.play();
			blipSnd.pitch = FlxG.random.float(0.8, 1.2);
		}
		else
			FlxG.sound.play(Paths.sound('blip'));
	}
}
