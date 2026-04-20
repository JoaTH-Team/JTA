package jta.video;

import jta.input.Input;
import jta.states.BaseState;
import jta.video.GlobalVideo;
import flixel.sound.FlxSound;
import openfl.display.Sprite;
#if android
import extension.videoview.VideoView;
#end

/**
 * Class used to play videos.
 * @see https://github.com/GrowtopiaFli/openfl-haxeflixel-video-code
 */
class VideoState extends BaseState
{
	/**
	 * The source of the video to play.
	 */
	public var source:String = '';

	/**
	 * The sound associated with the video.
	 */
	public var vidSound:FlxSound = null;

	/**
	 * Whether the video can be skipped or not.
	 */
	public var canSkip:Bool = true;

	/**
	 * Callback function triggered when the video ends or is skipped.
	 */
	public var onComplete:Void->Void;

	var holdTimer:Float = 0;
	var timeToSkip:Float = 1;
	var skipSprite:Sprite;

	/**
	 * Initializes the video player with the video source and a completion callback.
	 * @param source The source of the video to play.
	 * @param canSkip Whether the video can be skipped or not.
	 * @param onComplete Triggered when the video ends or is skipped.
	 */
	public function new(source:String, ?canSkip:Bool = true, ?onComplete:Void->Void):Void
	{
		super();

		this.source = source;
		this.canSkip = canSkip;
		this.onComplete = onComplete;
	}

	override public function create():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();

		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK));

		#if android
		VideoView.playVideo(Paths.video(source));
		VideoView.onCompletion = () -> end();
		#else
		if (GlobalVideo.isWebm)
			vidSound = FlxG.sound.play(Paths.videoSound(source), 1, false, null, true);

		var ourVideo:Dynamic = GlobalVideo.get();
		ourVideo.source(Paths.video(source));

		if (ourVideo == null)
		{
			end();
			return;
		}

		ourVideo.clearPause();

		if (GlobalVideo.isWebm)
			ourVideo.updatePlayer();

		ourVideo.show();

		if (GlobalVideo.isWebm)
			ourVideo.restart();
		else
			ourVideo.play();
		#end

		skipSprite = new Sprite();
		var gfx = skipSprite.graphics;
		gfx.beginFill(0xFFFFFF);
		gfx.drawCircle(0, 0, 20);
		gfx.endFill();
		skipSprite.x = FlxG.width - 80;
		skipSprite.y = FlxG.height - 72;
		if (canSkip)
			FlxG.stage.addChild(skipSprite);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		#if !android
		var ourVideo:Dynamic = GlobalVideo.get();

		if (ourVideo == null)
		{
			end();
			return;
		}

		ourVideo.update(elapsed);

		if (ourVideo.ended || ourVideo.stopped)
		{
			ourVideo.hide();
			ourVideo.stop();
		}

		if (!ourVideo.paused)
			ourVideo.unalpha();

		if (ourVideo.ended)
		{
			end();
			return;
		}

		if (ourVideo.played || ourVideo.restarted)
			ourVideo.show();

		if (holdTimer >= timeToSkip)
			ourVideo.stop();

		ourVideo.restarted = false;
		ourVideo.played = false;
		#end

		if (canSkip)
		{
			if (Input.pressed('confirm'))
			{
				holdTimer = Math.max(0, Math.min(timeToSkip, holdTimer + elapsed));
			}
			else if (holdTimer > 0)
			{
				holdTimer = Math.max(0, FlxMath.lerp(holdTimer, -0.1, FlxMath.bound(elapsed * 3, 0, 1)));
			}

			skipSprite.alpha = FlxMath.remapToRange(holdTimer / timeToSkip, 0.025, 1, 0, 1);
		}

		if (holdTimer >= timeToSkip)
		{
			end();
			return;
		}

		super.update(elapsed);
	}

	public function end():Void
	{
		#if !android
		var ourVideo:Dynamic = GlobalVideo.get();
		if (ourVideo != null)
		{
			ourVideo.stop();
			ourVideo.hide();
		}
		#end

		if (skipSprite != null && skipSprite.parent != null && canSkip)
		{
			skipSprite.parent.removeChild(skipSprite);
			skipSprite = null;
		}

		if (vidSound != null)
			vidSound.destroy();

		if (onComplete != null)
			onComplete();
	}
}
