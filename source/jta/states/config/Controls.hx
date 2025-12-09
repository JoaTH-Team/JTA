package jta.states.config;

import jta.Data;
import jta.Paths;
import jta.input.Input;
import jta.locale.Locale;
import jta.states.BaseState;
import jta.states.config.Settings;
import jta.substates.BaseSubState;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

class DeviceSelect extends BaseSubState
{
	var selections:Array<String> = ["$KEYBOARD", "$GAMEPAD", "$BACK"];
	var selectedIndex:Int = 0;

	var selectionGroup:FlxTypedGroup<FlxText>;

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

		var title:FlxText = new FlxText(10, 10, FlxG.width, Locale.getSettings("$DEVICE"));
		title.setFormat(Paths.font('main'), 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(title);

		selectionGroup = new FlxTypedGroup<FlxText>();
		add(selectionGroup);

		for (i in 0...selections.length)
		{
			var selection:FlxText = new FlxText(10, 100 + i * 42, FlxG.width, (i != 2) ? Locale.getSettings(selections[i]) : Locale.getMenu(selections[i]));
			selection.setFormat(Paths.font('main'), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			selection.ID = i;
			selectionGroup.add(selection);
		}

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		if (ignoreInputTimer > 0)
		{
			ignoreInputTimer -= elapsed;
			return;
		}

		if (Input.justPressed('up'))
			changeSelection(-1);
		else if (Input.justPressed('down'))
			changeSelection(1);

		if (Input.justPressed('confirm'))
		{
			switch (selectedIndex)
			{
				case 0:
					FlxG.sound.play(Paths.sound('select'));
					transitionState(new Controls(false));
				case 1:
					var gamepad = FlxG.gamepads.lastActive;
					if (gamepad != null)
						transitionState(new Controls(true));
					else
						FlxG.sound.play(Paths.sound('cancel'));
				case 2:
					FlxG.sound.play(Paths.sound('select'));
					close();
			}
		}
		else if (Input.justPressed('cancel'))
		{
			FlxG.sound.play(Paths.sound('cancel'));
			close();
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
		selectedIndex = FlxMath.wrap(selectedIndex + num, 0, selections.length - 1);
	}
}

class Controls extends BaseState
{
	var controls:Array<String> = ['left', 'down', 'up', 'right', 'jump', 'run', 'confirm', 'cancel'];
	var selectionGroup:FlxTypedGroup<FlxText>;
	var selectedIndex:Int = 0;

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
		var title:FlxText = new FlxText(10, 10, FlxG.width, titleText);
		title.setFormat(Paths.font('main'), 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(title);

		selectionGroup = new FlxTypedGroup<FlxText>();
		add(selectionGroup);

		for (i in 0...controls.length)
		{
			var selection:FlxText = new FlxText(10, 100 + i * 42, FlxG.width, getBindLabel(controls[i], i));
			selection.setFormat(Paths.font('main'), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			selection.ID = i;
			selectionGroup.add(selection);
		}

		tempBG = new FlxSprite().makeGraphic(900, FlxG.height, FlxColor.BLACK);
		tempBG.alpha = 0.5;
		tempBG.visible = false;
		add(tempBG);

		anyKeyTxt = new FlxText(0, 0, FlxG.width, '', 32);
		anyKeyTxt.setFormat(Paths.font('main'), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		anyKeyTxt.screenCenter();
		anyKeyTxt.visible = false;
		add(anyKeyTxt);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		if (!isChangingBind)
		{
			if (Input.justPressed('up'))
				changeSelection(-1);
			else if (Input.justPressed('down'))
				changeSelection(1);

			if (Input.justPressed('confirm'))
			{
				isChangingBind = true;
				anyKeyTxt.text = Locale.getSettings("$PRESS_ANY") + " " + (isGamepad ? Locale.getSettings("$BTN") : Locale.getSettings("$KEY"));
				anyKeyTxt.visible = true;
				tempBG.visible = true;

				var selectedText:FlxText = cast selectionGroup.members[selectedIndex];
				selectedText.text = '${controls[selectedIndex].toUpperCase()}: ...';
			}
			else if (Input.justPressed('cancel'))
			{
				FlxG.sound.play(Paths.sound('cancel'));
				transitionState(new Settings());
			}
		}
		else
		{
			if (Input.justPressed('any'))
			{
				FlxG.sound.play(Paths.sound('select'));
				if (isGamepad)
				{
					var pad:FlxGamepad = FlxG.gamepads.lastActive;
					var btn:FlxGamepadInputID = pad.firstJustPressedID();
					if (pad != null && btn.toString() != FlxGamepadInputID.NONE)
						Data.settings.gamepadBinds[selectedIndex] = btn;
				}
				else
					Data.settings.keyboardBinds[selectedIndex] = FlxG.keys.getIsDown()[0].ID.toString();
				Data.saveSettings();
				Input.refreshControls();
				isChangingBind = false;
				tempBG.visible = false;
				anyKeyTxt.visible = false;
				refreshBinds();
			}
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
		selectedIndex = FlxMath.wrap(selectedIndex + num, 0, controls.length - 1);
	}

	function getBindLabel(tag:String, index:Int):String
	{
		if (isGamepad)
			return '${tag.toUpperCase()}: ${FlxGamepadInputID.toStringMap.get(Data.settings.gamepadBinds[index])}';
		else
			return '${tag.toUpperCase()}: ${FlxKey.toStringMap.get(Data.settings.keyboardBinds[index])}';
	}

	function refreshBinds():Void
	{
		for (i in 0...controls.length)
		{
			var label = getBindLabel(controls[i], i);
			var text:FlxText = cast selectionGroup.members[i];
			text.text = label;
		}
	}
}
