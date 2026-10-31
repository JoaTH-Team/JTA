package jta.states;

import jta.util.DateUtil;
import jta.locale.Locale;
import jta.states.BaseState;
import jta.states.SaveSelect;
import jta.states.config.Settings;
import jta.mobile.MobileInput;
import jta.objects.MenuList;
import flixel.effects.particles.FlxEmitter;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class MainMenu extends BaseState
{
	var menu:MenuList;

	static final MENU_X:Float = 70;

	static final MENU_Y:Float = 364;
	static final MENU_SPACING:Float = 56;
	static final SELECTED_SLIDE:Float = 16;

	var player:FlxSprite;

	@:noCompletion
	private var animTimer:Float = 0;

	@:noCompletion
	private var animCooldown:Float = 3 + FlxG.random.float(0, 2);

	@:noCompletion
	private var isAnimating:Bool = false;

	@:noCompletion
	private var weather:Int = 0;

	public function new():Void
	{
		super();

		weather = DateUtil.getWeather();
	}

	override public function create():Void
	{
		jta.states.level.WorldRun.stop();
		jta.states.level.Level.clearCheckpoint();

		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Main Menu', null);
		#end

		if (!(FlxG.sound.music?.playing ?? false))
			SoundController.playMusic(Paths.music('Pumpin_Pixels'));

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/menu_bg'));
		bg.screenCenter();
		add(bg);

		if (weather != 3)
		{
			final particles:FlxEmitter = new FlxEmitter(0, 0);
			particles.loadParticles(Paths.image('menu/particles/' + (weather == 1 ? 'snow' : 'leaf')), 120);
			particles.alpha.set(0.5, 0.5);
			particles.scale.set(2, 2);

			switch (weather)
			{
				case 2:
					particles.color.set(FlxColor.interpolate(FlxColor.RED, FlxColor.WHITE, 0.5));
				case 4:
					particles.color.set(FlxColor.YELLOW, FlxColor.fromRGB(255, 159, 64), FlxColor.RED);
			}

			particles.width = FlxG.width;
			particles.launchMode = SQUARE;
			particles.acceleration.set(120, 120, 120, 120);
			particles.velocity.set(-10, 80, 0, FlxG.height);
			add(particles);
			new FlxTimer().start(0.1, function(tmr:FlxTimer):Void
			{
				particles.start(false, 0.01);
			});
		}

		var logo:FlxSprite = new FlxSprite(#if !mobile 50 #else 0 #end, 25).loadGraphic(Paths.image('menu/mainmenu/logo'));
		logo.scale.set(4, 4);
		#if mobile
		logo.screenCenter(X);
		#end
		logo.updateHitbox();
		add(logo);

		FlxTween.tween(logo, {y: logo.y + 10}, 1.2, {ease: FlxEase.sineInOut, type: PINGPONG});

		player = new FlxSprite().loadGraphic(Paths.image('menu/mainmenu/playerTitle'), true, 15, 38);
		player.animation.add('idle', [0], 1);
		player.animation.add('blink', [1], 1);
		player.animation.add('left', [2], 1);
		player.animation.add('right', [3], 1);
		player.scale.set(11, 11);
		player.updateHitbox();
		player.x = FlxG.width * 0.78 - player.width / 2;
		player.y = FlxG.height + 20;
		add(player);

		FlxTween.tween(player, {y: FlxG.height - player.height + 40}, 1, {ease: FlxEase.quadOut});

		menu = new MenuList(MENU_X, MENU_Y, MENU_SPACING, 36, true, SELECTED_SLIDE);
		menu.minBarWidth = 330;
		#if mobile
		menu.centered = true;
		#end
		menu.addOption(Locale.getMenu("$START"), () -> leave(new SaveSelect()));
		menu.addOption(Locale.getMenu("$SETTINGS"), () -> leave(new Settings()));
		#if sys
		menu.addOption(Locale.getMenu("$MODS"), () -> leave(new ModMenu()));
		#end
		menu.addOption(Locale.getMenu("$CREDITS"), () -> leave(new Credits()));
		#if desktop
		menu.addOption(Locale.getMenu("$EXIT"), () -> Sys.exit(0), null);
		#end
		add(menu);

		#if mobile
		var mobileControls:MobileInput = new MobileInput();
		mobileControls.setupMenuVertical(false);
		add(mobileControls);
		#end

		super.create();

		initVersionText();
	}

	function initVersionText():Void
	{
		if (leftWatermarkText == null)
			return;

		leftWatermarkText.size = 24;
		leftWatermarkText.setPosition(14, FlxG.height - 40);
		leftWatermarkText.text = 'v${Lib.application.meta.get('version')}';
		leftWatermarkText.text += #if (debug && !web) ' (${jta.util.macro.git.GitUtil.getCommitHash()})' #else ' (DEMO)' #end;
	}

	/**
	 * Goes to another menu (and stops the list from taking more input during the transition).
	 */
	function leave(state:flixel.util.typeLimit.NextState):Void
	{
		menu.enabled = false;
		transitionState(state);
	}

	override public function update(elapsed:Float):Void
	{
		#if (debug && !mobile)
		if (Input.justPressed('v'))
		{
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
				FlxG.sound.music.stop();

			transitionState(new jta.video.VideoState('paint', () ->
			{
				transitionState(new jta.states.MainMenu());
			}));
		}
		#end

		super.update(elapsed);

		animTimer += elapsed;

		if (!isAnimating && animTimer >= animCooldown)
		{
			animTimer = 0;
			animCooldown = 3 + FlxG.random.float(0, 2);
			isAnimating = true;

			var anims:Array<String> = ['idle', 'left', 'right'];
			var nextAnim = FlxG.random.getObject(anims);

			player.animation.play('blink');

			FlxTimer.wait(0.2, function():Void
			{
				player.animation.play(nextAnim);
				isAnimating = false;
			});
		}
	}

}
