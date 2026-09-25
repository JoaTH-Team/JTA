package jta.api;

import openfl.text.Font;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.Stage;
import flixel.system.FlxBasePreloader;

@:bitmap('assets/images/preloaderLogo.png') class PreloaderLogo extends BitmapData {}
@:font('assets/fonts/ByteBounce.ttf') class PreloaderFont extends Font {}

/**
 * A basic custom preloader showing the logo and loading status, while the game downloads assets.
 */
class Preloader extends FlxBasePreloader
{
	var _stage:Stage;

	var logo:Bitmap;
	var loadBar:Sprite;

	var text:TextField;

	public function new(MinDisplayTime:Float = 5, ?AllowedURLs:Array<String>):Void
	{
		super(MinDisplayTime, AllowedURLs);
	}

	override function create():Void
	{
		_stage = Lib.application.window.stage;

		logo = createBitmap(PreloaderLogo, function(logo:Bitmap):Void
		{
			logo.width = logo.width * 0.45;
			logo.height = logo.height * 0.45;
			logo.x = (_stage.stageWidth - logo.width) / 2;
			logo.y = (_stage.stageHeight - logo.height) / 2;
			logo.alpha = 0;
		});
		addChild(logo);

		loadBar = new Sprite();
		loadBar.graphics.beginFill(0xFFFFFF);
		loadBar.graphics.drawRect(0, 0, 1, 1);
		loadBar.height = 20 - 8;
		loadBar.y = _stage.stageHeight - loadBar.height - 8;
		changeBarSize(0);
		addChild(loadBar);

		Font.registerFont(PreloaderFont);
		text = new TextField();
		text.defaultTextFormat = new TextFormat('ByteBounce', 30, 0xffffff, false, false, false, '', '', TextFormatAlign.CENTER);
		text.embedFonts = true;
		text.selectable = false;
		text.multiline = false;
		text.width = _stage.stageWidth;
		text.height = 40;
		text.x = 0;
		text.y = loadBar.y - text.height - 10;
		text.text = 'Loading';
		addChild(text);

		super.create();
	}

	override public function update(percent:Float):Void
	{
		var newSize:Float = (_stage.stageWidth - 16) * percent;
		changeBarSize(FlxMath.lerp(loadBar.width, newSize, 0.7));

		if (percent < 0.3)
			logo.alpha = FlxMath.lerp(percent * (10 / 3), logo.alpha, 0.7);
		else if (percent > 0.85)
			logo.alpha = FlxMath.lerp(((1 - percent) * (100 / 15)), logo.alpha, 0.7);
		else
			logo.alpha = 1;

		text.text = 'Loading ${Std.int(percent * 100)}%';
		super.update(percent);
	}

	override function destroy():Void
	{
		_stage = null;
		logo = null;
		loadBar = null;

		super.destroy();
	}

	function changeBarSize(newSize:Float):Void
	{
		loadBar.width = newSize;
		loadBar.x = (_stage.stageWidth - loadBar.width) / 2;
	}
}
