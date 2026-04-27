package jta.states.config;

import jta.Data;
import jta.input.Input;
import jta.locale.Locale;
import jta.states.MainMenu;
import jta.states.BaseState;
import jta.states.config.Option;
import jta.states.config.Controls;
import jta.util.FilterUtil;

/**
 * Settings menu to configure game options.
 * @author Joalor64
 */
class Settings extends BaseState
{
	var options:Array<Option> = [];
	var selectedIndex:Int = 0;

	var selectionGroup:FlxTypedGroup<FlxText>;

	var holdTimer:FlxTimer;
	var holdDirection:Int = 0;

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

		var option:Option = new Option(Locale.getSettings("$FPS_DISP"), OptionType.Toggle, Data.settings.fpsCounter);
		option.onChange = (value:Dynamic) ->
		{
			Data.settings.fpsCounter = value;
			if (Main.fpsDisplay != null)
				Main.fpsDisplay.visible = Data.settings.fpsCounter;
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

		var option:Option = new Option(Locale.getSettings("$CTRLS"), OptionType.Function, function():Void
		{
			Data.saveSettings();
			openSubState(new Controls.DeviceSelect());
		});
		options.push(option);

		var option:Option = new Option(Locale.getMenu("$EXIT"), OptionType.Function, function():Void
		{
			Data.saveSettings();
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

		var title:FlxText = new FlxText(10, 10, FlxG.width, Locale.getSettings("$SETTINGS"));
		title.setFormat(Paths.font('main'), 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(title);

		selectionGroup = new FlxTypedGroup<FlxText>();
		add(selectionGroup);

		for (i in 0...options.length)
		{
			var selection:FlxText = new FlxText(10, 70 + i * 42, FlxG.width, options[i].toString());
			selection.setFormat(Paths.font('main'), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			selection.ID = i;
			selectionGroup.add(selection);
		}

		holdTimer = new FlxTimer();

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		if (Input.justPressed('up'))
			changeSelection(-1);
		else if (Input.justPressed('down'))
			changeSelection(1);

		if (Input.justPressed('right'))
			startHold(1);
		else if (Input.justPressed('left'))
			startHold(-1);

		if (Input.justReleased('right') || Input.justReleased('left'))
		{
			if (holdTimer.active)
				holdTimer.cancel();
		}

		if (Input.justPressed('confirm'))
		{
			FlxG.sound.play(Paths.sound('select'));
			var option:Option = options[selectedIndex];
			if (option != null)
				option.execute();
		}
		else if (Input.justPressed('cancel'))
		{
			Data.saveSettings();
			FlxG.sound.play(Paths.sound('cancel'));
			transitionState(new MainMenu());
		}

		selectionGroup.forEach(function(text:FlxText):Void
		{
			text.color = (text.ID == selectedIndex) ? FlxColor.YELLOW : FlxColor.WHITE;
		});

		super.update(elapsed);
	}

	private function changeSelection(num:Int):Void
	{
		FlxG.sound.play(Paths.sound('scroll'));
		selectedIndex = FlxMath.wrap(selectedIndex + num, 0, options.length - 1);
	}

	private function changeValue(direction:Int = 0):Void
	{
		var option:Option = options[selectedIndex];

		if (option != null)
		{
			option.changeValue(direction);

			selectionGroup.forEach(function(txt:FlxText):Void
			{
				if (txt.ID == selectedIndex)
					txt.text = option.toString();
			});
		}
	}

	private function startHold(direction:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scroll'));

		holdDirection = direction;

		var option:Option = options[selectedIndex];

		if (option != null)
		{
			if (option.type != OptionType.Function)
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
}
