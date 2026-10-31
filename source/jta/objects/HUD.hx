package jta.objects;

import jta.Global;
import jta.util.TextUtil;
import jta.audio.SoundController;
import jta.locale.Locale;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * Class to hold all HUD elements.
 * @author Joalor64
 */
class HUD extends FlxTypedGroup<FlxSprite>
{
	/**
	 * How much the 16x16 HUD icons are scaled up.
	 */
	static final ICON_SCALE:Float = 2;

	/**
	 * Seconds left when the timer starts warning (faster clock, red text, ticking).
	 */
	static final TIME_WARNING:Int = 10;

	/**
	 * The lives the HUD showed last, kept between level resets.
	 * Used to play the heart's hurt frame after respawning (falling resets the level right away).
	 */
	static var shownLives:Int = -1;

	/**
	 * Forgets the last shown lives, so the next HUD doesn't play the hurt frame.
	 * Called by menus (e.g. after switching save files).
	 */
	public static function resetLifeTracking():Void
		shownLives = -1;

	/**
	 * Displays the current score.
	 */
	public var scoreTxt:FlxText;

	/**
	 * Displays the current coins.
	 */
	public var coinsTxt:FlxText;

	/**
	 * Displays the current lives.
	 */
	public var livesTxt:FlxText;

	/**
	 * Displays the time left on timed levels.
	 */
	public var timeTxt:FlxText;

	public var heartIcon:FlxSprite;
	public var coinIcon:FlxSprite;
	public var clockIcon:FlxSprite;

	@:noCompletion
	private var lastScore:Int = -1;

	@:noCompletion
	private var lastCoins:Int = -1;

	@:noCompletion
	private var lastLives:Int = -1;

	@:noCompletion
	private var lastSeconds:Int = -1;

	@:noCompletion
	private var hurtTimer:Null<FlxTimer> = null;

	public function new():Void
	{
		super();

		heartIcon = makeIcon(10, 8, 'hud/heart');
		heartIcon.animation.add('idle', [0], 1);
		heartIcon.animation.add('hurt', [1], 1);
		heartIcon.animation.play('idle');
		add(heartIcon);

		livesTxt = makeText(10 + heartIcon.width + 6, 10, LEFT);
		add(livesTxt);

		coinIcon = makeIcon(10, 46, 'objects/coin');
		coinIcon.animation.add('idle', [0], 1);
		coinIcon.animation.play('idle');
		add(coinIcon);

		coinsTxt = makeText(10 + coinIcon.width + 6, 48, LEFT);
		add(coinsTxt);

		scoreTxt = makeText(0, 10, RIGHT);
		scoreTxt.fieldWidth = 250;
		add(scoreTxt);

		clockIcon = makeIcon(0, 8, 'hud/clock');
		clockIcon.animation.add('tick', [for (i in 0...16) i], 8, true);
		clockIcon.animation.play('tick');
		add(clockIcon);

		timeTxt = makeText(0, 10, LEFT);
		add(timeTxt);

		clockIcon.visible = timeTxt.visible = false;

		updateScoreText();
		updateCoinsText();
		updateLivesText();
	}

	function makeIcon(x:Float, y:Float, image:String):FlxSprite
	{
		final icon:FlxSprite = new FlxSprite(x, y).loadGraphic(Paths.image(image), true, 16, 16);
		icon.scale.set(ICON_SCALE, ICON_SCALE);
		icon.updateHitbox();
		icon.antialiasing = false;
		icon.scrollFactor.set();
		return icon;
	}

	function makeText(x:Float, y:Float, align:FlxTextAlign):FlxText
	{
		final text:FlxText = TextUtil.make(x, y, 0, '', 24, align);
		text.scrollFactor.set();
		return text;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (Global.score != lastScore)
			updateScoreText();

		if (Global.coins != lastCoins)
			updateCoinsText();

		if (Global.lives != lastLives)
			updateLivesText();
	}

	/**
	 * Shows the timer with the given time left. Called every frame by timed levels.
	 * @param seconds Time left in seconds.
	 */
	public function setTime(seconds:Float):Void
	{
		final whole:Int = Std.int(Math.max(0, Math.ceil(seconds)));

		if (!timeTxt.visible)
			clockIcon.visible = timeTxt.visible = true;

		if (whole == lastSeconds)
			return;

		final firstUpdate:Bool = lastSeconds < 0;
		lastSeconds = whole;

		timeTxt.text = Std.string(whole);

		final totalWidth:Float = clockIcon.width + 6 + timeTxt.width;
		clockIcon.x = (FlxG.width - totalWidth) / 2;
		timeTxt.x = clockIcon.x + clockIcon.width + 6;

		final warning:Bool = whole <= TIME_WARNING;
		timeTxt.color = warning ? FlxColor.RED : FlxColor.WHITE;
		clockIcon.animation.curAnim.frameRate = warning ? 16 : 8;

		if (warning && !firstUpdate && whole > 0)
		{
			SoundController.play(Paths.sound('blip'));
			pop(timeTxt);
		}
	}

	/**
	 * Hides the timer (e.g. after the level is cleared).
	 */
	public function hideTime():Void
	{
		clockIcon.visible = timeTxt.visible = false;
	}

	/**
	 * Stops the clock animation (e.g. when time runs out).
	 */
	public function stopClock():Void
	{
		clockIcon.animation.pause();
	}

	@:noCompletion
	private function updateScoreText():Void
	{
		lastScore = Global.score;
		scoreTxt.text = Locale.replaceFlagsAndReturn("$SCORE", 'playState', ['<score>'], [Global.score]);
		scoreTxt.x = FlxG.width - scoreTxt.width - 10;
	}

	@:noCompletion
	private function updateCoinsText():Void
	{
		final gained:Bool = lastCoins >= 0 && Global.coins > lastCoins;

		lastCoins = Global.coins;
		coinsTxt.text = 'x${Global.coins}';

		if (gained)
			pop(coinIcon, ICON_SCALE);
	}

	@:noCompletion
	private function updateLivesText():Void
	{
		final lost:Bool = shownLives >= 0 && Global.lives < shownLives;
		final gained:Bool = lastLives >= 0 && Global.lives > lastLives;

		lastLives = shownLives = Global.lives;
		livesTxt.text = 'x${Global.lives}';

		if (lost)
			showHurt();
		else if (gained)
			pop(heartIcon, ICON_SCALE);
	}

	/**
	 * Shows the heart's hurt frame for a moment.
	 */
	public function showHurt(?duration:Float = 1.2):Void
	{
		heartIcon.animation.play('hurt');
		pop(heartIcon, ICON_SCALE);

		hurtTimer?.cancel();
		hurtTimer = new FlxTimer().start(duration, function(_):Void
		{
			heartIcon.animation.play('idle');
		});
	}

	/**
	 * Little bounce on a HUD element.
	 */
	function pop(sprite:FlxSprite, ?baseScale:Float = 1):Void
	{
		FlxTween.cancelTweensOf(sprite.scale);
		sprite.scale.set(baseScale * 1.3, baseScale * 1.3);
		FlxTween.tween(sprite.scale, {x: baseScale, y: baseScale}, 0.2, {ease: FlxEase.backOut});
	}
}
