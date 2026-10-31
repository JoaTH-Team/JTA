package jta.states.config;

import jta.locale.Locale;
import jta.states.BaseState;
import jta.states.config.Settings;
import jta.substates.BaseSubState;
import jta.objects.MenuList;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

class DeviceSelect extends BaseSubState
{
	var menu:MenuList;

	var ignoreInputTimer:Float = 0;

	public function new():Void
	{
		super(0x80000000);

		ignoreInputTimer = 0.5;
	}

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Configuring Controls', null);
		#end

		var title:FlxText = TextUtil.make(10, 10, FlxG.width, Locale.getSettings("$DEVICE"), 40);
		add(title);

		menu = new MenuList(30, 100);
		menu.addOption(Locale.getSettings("$KEYBOARD"), function():Void
		{
			menu.enabled = false;
			transitionState(new Controls(false));
		});
		menu.addOption(Locale.getSettings("$GAMEPAD"), function():Void
		{
			if (FlxG.gamepads.lastActive != null)
			{
				SoundController.play(Paths.sound('select'));
				menu.enabled = false;
				transitionState(new Controls(true));
			}
			else
				SoundController.play(Paths.sound('cancel'));
		}, null);
		menu.addOption(Locale.getMenu("$BACK"), close);
		menu.enabled = false;
		add(menu);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		if (ignoreInputTimer > 0)
		{
			ignoreInputTimer -= elapsed;
			if (ignoreInputTimer <= 0)
				menu.enabled = true;

			super.update(elapsed);
			return;
		}

		if (menu.enabled && Input.justPressed('cancel'))
		{
			SoundController.play(Paths.sound('cancel'));
			close();
		}

		super.update(elapsed);
	}
}

class Controls extends BaseState
{
	var menu:MenuList;

	var isGamepad:Bool = false;
	var isChangingBind:Bool = false;

	var tempBG:FlxSprite;
	var anyKeyTxt:FlxText;

	public function new(?isGamepad:Bool = false):Void
	{
		super();

		this.isGamepad = isGamepad;
	}

	override public function create():Void
	{
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/settings_bg'));
		bg.screenCenter();
		add(bg);

		var titleText = isGamepad ? Locale.getSettings("$GPBINDS") : Locale.getSettings("$KBBINDS");
		var title:FlxText = TextUtil.make(10, 10, FlxG.width, titleText, 40);
		add(title);

		menu = new MenuList(30, 90, 50);
		for (i in 0...Input.ACTIONS.length)
			menu.addOption(getBindLabel(i), startChangingBind, null);
		add(menu);

		tempBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		tempBG.alpha = 0.5;
		tempBG.visible = false;
		add(tempBG);

		anyKeyTxt = TextUtil.make(0, 0, FlxG.width, '', 36, CENTER);
		anyKeyTxt.screenCenter();
		anyKeyTxt.visible = false;
		add(anyKeyTxt);

		super.create();
	}

	function startChangingBind():Void
	{
		isChangingBind = true;
		menu.enabled = false;

		anyKeyTxt.text = Locale.getSettings("$PRESS_ANY") + ' ' + (isGamepad ? Locale.getSettings("$BTN") : Locale.getSettings("$KEY"));
		anyKeyTxt.visible = true;
		tempBG.visible = true;

		menu.setLabel(menu.selectedIndex, '${Input.ACTIONS[menu.selectedIndex].toUpperCase()}: ...');
	}

	override public function update(elapsed:Float):Void
	{
		if (!isChangingBind)
		{
			if (Input.justPressed('cancel'))
			{
				SoundController.play(Paths.sound('cancel'));
				menu.enabled = false;
				transitionState(new Settings());
			}

			super.update(elapsed);
			return;
		}

		final index:Int = menu.selectedIndex;
		var changed:Bool = false;

		if (isGamepad)
		{
			final pad:Null<FlxGamepad> = FlxG.gamepads.lastActive;
			if (pad != null)
			{
				final btn:FlxGamepadInputID = pad.firstJustPressedID();
				if (btn != FlxGamepadInputID.NONE)
				{
					Data.settings.gamepadBinds[index] = btn;
					changed = true;
				}
			}
		}
		else
		{
			final key:FlxKey = FlxG.keys.firstJustPressed();
			if (key != FlxKey.NONE)
			{
				Data.settings.keyboardBinds[index] = key;
				changed = true;
			}
		}

		if (changed)
		{
			SoundController.play(Paths.sound('select'));
			Data.save();
			Input.refreshControls();

			isChangingBind = false;
			tempBG.visible = false;
			anyKeyTxt.visible = false;
			refreshBinds();

			new FlxTimer().start(0.01, (_) -> menu.enabled = true);
		}

		super.update(elapsed);
	}

	function getBindLabel(index:Int):String
	{
		final tag:String = Input.ACTIONS[index];

		if (isGamepad)
			return '${tag.toUpperCase()}: ${FlxGamepadInputID.toStringMap.get(Data.settings.gamepadBinds[index])}';
		else
			return '${tag.toUpperCase()}: ${FlxKey.toStringMap.get(Data.settings.keyboardBinds[index])}';
	}

	function refreshBinds():Void
	{
		for (i in 0...Input.ACTIONS.length)
			menu.setLabel(i, getBindLabel(i));
	}
}
