package jta.objects;

import jta.Global;
import jta.locale.Locale;

/**
 * Class to hold all HUD elements.
 * @author Joalor64
 */
class HUD extends FlxTypedGroup<FlxSprite>
{
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

	@:noCompletion
	private var lastScore:Int = -1;

	@:noCompletion
	private var lastCoins:Int = -1;

	@:noCompletion
	private var lastLives:Int = -1;

	public function new():Void
	{
		super();

		livesTxt = new FlxText(10, 10, 200, '', 24);
		livesTxt.setFormat(Paths.font('main'), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(livesTxt);

		coinsTxt = new FlxText(10, 40, 200, '', 24);
		coinsTxt.setFormat(Paths.font('main'), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(coinsTxt);

		scoreTxt = new FlxText(0, 10, 250, '', 24);
		scoreTxt.setFormat(Paths.font('main'), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(scoreTxt);

		updateScoreText();
		updateCoinsText();
		updateLivesText();
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
		lastCoins = Global.coins;
		coinsTxt.text = Locale.replaceFlagsAndReturn("$COINS", 'playState', ['<coins>'], [Global.coins]);
	}

	@:noCompletion
	private function updateLivesText():Void
	{
		lastLives = Global.lives;
		livesTxt.text = Locale.replaceFlagsAndReturn("$LIVES", 'playState', ['<lives>'], [Global.lives]);
	}
}
