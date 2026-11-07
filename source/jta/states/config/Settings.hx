package jta.states.config;

import jta.locale.Locale;
import jta.states.MainMenu;
import jta.states.BaseState;
import jta.states.config.Option;
import jta.states.config.Controls;
import jta.util.FilterUtil;
import jta.objects.MenuList;
#if mobile
import jta.mobile.MobileInput;
#end

/**
 * Settings menu to configure game options.
 * @author Joalor64
 */
class Settings extends BaseState
{
	var options:Array<Option> = [];

	var menu:MenuList;

	@:noCompletion
	private var holdTimer:FlxTimer;

	@:noCompletion
	private var holdDirection:Int = 0;

	public function new():Void
	{
		super();

		var option:Option = new Option(Locale.getSettings("$VOLUME"), OptionType.Integer(0, 100, 1), FlxG.sound.volume * 100);
		option.showPercentage = true;
		option.onChange = (value:Dynamic) ->
		{
			Data.settings.volume = value;
			FlxG.sound.volume = Data.settings.volume / 100;
		};
		options.push(option);

		var option:Option = new Option(Locale.getSettings("$MUSIC_VOL"), OptionType.Integer(0, 100, 1), Data.settings.musicVolume);
		option.showPercentage = true;
		option.onChange = (value:Dynamic) -> Data.settings.musicVolume = value;
		options.push(option);

		var option:Option = new Option(Locale.getSettings("$SFX_VOL"), OptionType.Integer(0, 100, 1), Data.settings.sfxVolume);
		option.showPercentage = true;
		option.onChange = (value:Dynamic) -> Data.settings.sfxVolume = value;
		options.push(option);

		var option:Option = new Option(Locale.getSettings("$FPS_DISP"), OptionType.Toggle, Data.settings.fpsCounter);
		option.onChange = (value:Dynamic) ->
		{
			Data.settings.fpsCounter = value;
			if (Main.fps != null)
				Main.fps.visible = Data.settings.fpsCounter;
		};
		options.push(option);

		#if desktop
		var option:Option = new Option(Locale.getSettings("$FLSCRN"), OptionType.Toggle, Data.settings.fullscreen);
		option.onChange = (value:Dynamic) ->
		{
			Data.settings.fullscreen = value;
			FlxG.fullscreen = Data.settings.fullscreen;
		};
		options.push(option);
		#end

		var option:Option = new Option(Locale.getSettings("$SKIP_SPLASH"), OptionType.Toggle, Data.settings.skipSplash);
		option.onChange = (value:Dynamic) -> Data.settings.skipSplash = value;
		options.push(option);

		var option:Option = new Option(Locale.getSettings("$LANG"), OptionType.Choice(Locale.locales), Data.settings.locale);
		option.onChange = (value:Dynamic) ->
		{
			Data.settings.locale = value;
			Locale.loadLanguage(Data.settings.locale);
			FlxG.resetState();
		};
		options.push(option);

		var option:Option = new Option(Locale.getSettings("$FILTER"), OptionType.Choice(FilterUtil.getFiltersKeys().concat(['None'])), Data.settings.filter);
		option.onChange = (value:Dynamic) ->
		{
			Data.settings.filter = value;
			FilterUtil.reloadGameFilter(Data.settings.filter);
		};
		options.push(option);

		#if !mobile
		var option:Option = new Option(Locale.getSettings("$CTRLS"), OptionType.Function, function():Void
		{
			Data.save();
			openSubState(new Controls.DeviceSelect());
		});
		options.push(option);
		#end

		var option:Option = new Option(Locale.getMenu("$EXIT"), OptionType.Function, function():Void
		{
			Data.save();
			transitionState(new MainMenu());
		});
		options.push(option);
	}

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Settings Menu', null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/settings_bg'));
		bg.screenCenter();
		add(bg);

		var title:FlxText = TextUtil.make(10, 10, FlxG.width, Locale.getSettings("$SETTINGS"), 40);
		add(title);

		menu = new MenuList(30, 70, 42, 36);
		for (i in 0...options.length)
			menu.addOption(options[i].toString(), () -> confirmOption(i));
		add(menu);

		holdTimer = new FlxTimer();

		#if mobile
		var mobileControls:MobileInput = new MobileInput();
		mobileControls.setupMenuFull();
		add(mobileControls);
		#end

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		if (Input.justPressed('right'))
			startHold(1);
		else if (Input.justPressed('left'))
			startHold(-1);

		if (Input.justReleased('right') || Input.justReleased('left'))
		{
			if (holdTimer.active)
				holdTimer.cancel();
		}

		if (Input.justPressed('cancel'))
		{
			Data.save();
			SoundController.play(Paths.sound('cancel'));
			transitionState(new MainMenu());
		}

		super.update(elapsed);
	}

	@:noCompletion
	private function confirmOption(index:Int):Void
	{
		final option:Null<Option> = options[index];
		if (option == null)
			return;

		if (option.type == OptionType.Toggle)
		{
			option.changeValue(1);
			menu.setLabel(index, option.toString());
		}
		else
			option.execute();
	}

	@:noCompletion
	private function changeValue(direction:Int = 0):Void
	{
		var option:Option = options[menu.selectedIndex];

		if (option != null)
		{
			option.changeValue(direction);
			menu.setLabel(menu.selectedIndex, option.toString());
		}
	}

	@:noCompletion
	private function startHold(direction:Int = 0):Void
	{
		var option:Option = options[menu.selectedIndex];

		if (option == null || option.type == OptionType.Function)
			return;

		SoundController.play(Paths.sound('scroll'));

		holdDirection = direction;
		changeValue(holdDirection);

		switch (option.type)
		{
			case OptionType.Integer(_, _, _) | OptionType.Decimal(_, _, _):
				if (!holdTimer.active)
				{
					holdTimer.start(0.5, function(timer:FlxTimer):Void
					{
						timer.start(0.05, function(timer:FlxTimer):Void
						{
							changeValue(holdDirection);
						}, 0);
					});
				}
			default:
		}
	}
}
