package jta.states;

import jta.Assets;
import jta.Global;
import jta.locale.Locale;
import jta.states.BaseState;
import jta.states.WorldMap;
import jta.states.MainMenu;
import jta.mobile.MobileInput;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * One save slot on the save select menu.
 * Everything is code-drawn for now, so it can be swapped for real art later
 * (the border/inner boxes are the parts to replace).
 */
class SaveCard extends FlxSpriteGroup
{
	public static final CARD_WIDTH:Int = 780;
	public static final CARD_HEIGHT:Int = 168;
	static final BORDER:Int = 6;

	public var info:SlotInfo;

	var border:FlxSprite;
	var inner:FlxSprite;
	var cover:FlxSprite;
	var titleText:FlxText;
	var line1:FlxText;
	var line2:FlxText;
	var actionsText:FlxText;

	var coverBaseY:Float = 0;
	var bobTime:Float = 0;

	public var selected(default, null):Bool = false;

	public function new(x:Float, y:Float, info:SlotInfo)
	{
		super(x, y);

		border = new FlxSprite().makeGraphic(CARD_WIDTH, CARD_HEIGHT, FlxColor.WHITE);
		add(border);

		inner = new FlxSprite(BORDER, BORDER).makeGraphic(CARD_WIDTH - BORDER * 2, CARD_HEIGHT - BORDER * 2, FlxColor.WHITE);
		add(inner);

		cover = new FlxSprite(22, 0);
		add(cover);

		titleText = makeText(184, 14, 36);
		add(titleText);

		line1 = makeText(184, 66, 24);
		add(line1);

		line2 = makeText(184, 100, 24);
		add(line2);

		actionsText = makeText(0, 12, 26);
		actionsText.fieldWidth = CARD_WIDTH - 24;
		actionsText.alignment = RIGHT;
		add(actionsText);

		refresh(info);
		setSelected(false);
	}

	function makeText(x:Float, y:Float, size:Int):FlxText
	{
		final text:FlxText = TextUtil.make(x, y, 0, '', size);
		text.borderSize = 2;
		return text;
	}

	/**
	 * Redraws the card from new slot info (e.g. after erasing).
	 */
	public function refresh(info:SlotInfo):Void
	{
		this.info = info;

		titleText.text = Locale.replaceFlagsAndReturn("$FILE", 'menu', ['<X>'], [info.slot + 1]);

		final coverName:String = info.empty ? 'placeholder' : Global.getFurthestCover(info);
		final coverPath:String = 'menu/level/$coverName';
		cover.loadGraphic(Paths.image(Assets.exists(Paths.image(coverPath)) ? coverPath : 'menu/level/placeholder'));
		cover.setGraphicSize(128, 128);
		cover.updateHitbox();
		cover.antialiasing = false;
		cover.alpha = info.empty ? 0.35 : 1;
		cover.y = y + (CARD_HEIGHT - cover.height) / 2;
		coverBaseY = cover.y;

		if (info.empty)
		{
			line1.text = Locale.getMenu("$NEW_GAME");
			line1.size = 32;
			line1.color = FlxColor.GRAY;
			line2.text = '';
		}
		else
		{
			final completion = Global.getCompletion(info);

			line1.size = 24;
			line1.color = FlxColor.WHITE;
			line1.text = Locale.replaceFlagsAndReturn("$FILE_LEVELS", 'menu', ['<X>', '<Y>'], [completion.done, completion.total])
				+ '    '
				+ Locale.replaceFlagsAndReturn("$COINS", 'playState', ['<coins>'], [info.coins])
				+ '    '
				+ Locale.replaceFlagsAndReturn("$LIVES", 'playState', ['<lives>'], [info.lives]);

			line2.text = Locale.replaceFlagsAndReturn("$FILE_TIME", 'menu', ['<X>'], [Global.formatPlaytime(info.playtime)]);

			if (info.lastPlayed > 0)
				line2.text += '    ' + DateTools.format(Date.fromTime(info.lastPlayed), '%Y-%m-%d');
		}

		updateColors();
	}

	public function setSelected(value:Bool):Void
	{
		selected = value;

		if (!selected)
		{
			actionsText.text = '';
			cover.y = coverBaseY;
		}

		updateColors();
	}

	/**
	 * Shows the Continue/Erase choice on a used slot.
	 * @param action 0 = Continue, 1 = Erase.
	 */
	public function showActions(action:Int):Void
	{
		if (info.empty)
		{
			actionsText.text = '';
			return;
		}

		final cont:String = Locale.getMenu("$CONTINUE");
		final erase:String = Locale.getMenu("$ERASE");

		actionsText.text = (action == 0) ? '> $cont <    $erase' : '$cont    > $erase <';
	}

	function updateColors():Void
	{
		border.color = selected ? FlxColor.YELLOW : FlxColor.fromRGB(90, 90, 110);
		inner.color = selected ? FlxColor.fromRGB(40, 44, 82) : FlxColor.fromRGB(22, 22, 38);
		inner.alpha = selected ? 0.95 : 0.85;
		titleText.color = selected ? FlxColor.YELLOW : FlxColor.WHITE;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (selected && !info.empty)
		{
			bobTime += elapsed;
			cover.y = coverBaseY + Math.sin(bobTime * 4) * 4;
		}
	}
}

/**
 * The save select menu, between the main menu and the level select.
 *
 * Up/Down picks a file. On an empty file, Confirm starts a new game.
 * On a used file, Left/Right picks Continue or Erase; Erase asks for confirmation first.
 */
class SaveSelect extends BaseState
{
	var cards:Array<SaveCard> = [];
	var selectedIndex:Int = 0;

	/**
	 * 0 = Continue, 1 = Erase (only used on files that have data).
	 */
	var selectedAction:Int = 0;

	var confirmGroup:FlxSpriteGroup;
	var confirmText:FlxText;
	var confirmChoices:FlxText;
	var confirming:Bool = false;

	/**
	 * 0 = No, 1 = Yes. Defaults to No so nobody erases a file by mashing.
	 */
	var confirmChoice:Int = 0;

	var leaving:Bool = false;

	static final CARD_SLIDE:Float = 36;

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Selecting a File', null);
		#end

		if (!(FlxG.sound.music?.playing ?? false))
			SoundController.playMusic(Paths.music('Pumpin_Pixels'));

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/menu_bg'));
		bg.screenCenter();
		bg.color = FlxColor.fromRGB(110, 110, 150);
		add(bg);

		var checker:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(48, 48, 96, 96, true, 0x22FFFFFF, 0x00000000));
		checker.velocity.set(28, 18);
		add(checker);

		var title:FlxText = TextUtil.make(0, 28, FlxG.width, Locale.getMenu("$SELECT_FILE"), 44, CENTER);
		title.borderSize = 3;
		add(title);

		final gap:Float = 20;
		final totalHeight:Float = Global.SLOT_COUNT * SaveCard.CARD_HEIGHT + (Global.SLOT_COUNT - 1) * gap;
		final startY:Float = Math.max(100, (FlxG.height - totalHeight) / 2 + 20);

		for (i in 0...Global.SLOT_COUNT)
		{
			final card:SaveCard = new SaveCard(cardX(false), startY + i * (SaveCard.CARD_HEIGHT + gap), Global.getSlotInfo(i));
			cards.push(card);
			add(card);
		}

		if (Global.currentSlot >= 0)
			selectedIndex = Global.currentSlot;
		else
		{
			var newest:Float = 0;
			for (card in cards)
			{
				if (!card.info.empty && card.info.lastPlayed > newest)
				{
					newest = card.info.lastPlayed;
					selectedIndex = card.info.slot;
				}
			}
		}

		createConfirmBox();

		#if mobile
		var mobileControls:MobileInput = new MobileInput();
		mobileControls.setupMenuFull();
		add(mobileControls);
		#end

		super.create();

		changeSelection(0, false);
	}

	inline function cardX(selected:Bool):Float
		return (FlxG.width - SaveCard.CARD_WIDTH) / 2 + (selected ? CARD_SLIDE : 0) - CARD_SLIDE / 2;

	function createConfirmBox():Void
	{
		confirmGroup = new FlxSpriteGroup();

		var shade:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		shade.alpha = 0.6;
		confirmGroup.add(shade);

		final boxW:Int = 640;
		final boxH:Int = 240;
		final boxX:Float = (FlxG.width - boxW) / 2;
		final boxY:Float = (FlxG.height - boxH) / 2;

		var border:FlxSprite = new FlxSprite(boxX, boxY).makeGraphic(boxW, boxH, FlxColor.RED);
		confirmGroup.add(border);

		var inner:FlxSprite = new FlxSprite(boxX + 6, boxY + 6).makeGraphic(boxW - 12, boxH - 12, FlxColor.fromRGB(40, 16, 24));
		confirmGroup.add(inner);

		confirmText = TextUtil.make(boxX, boxY + 34, boxW, '', 34, CENTER);
		confirmText.borderSize = 2;
		confirmGroup.add(confirmText);

		confirmChoices = TextUtil.make(boxX, boxY + boxH - 70, boxW, '', 34, CENTER);
		confirmChoices.borderSize = 2;
		confirmGroup.add(confirmChoices);

		confirmGroup.visible = false;
		add(confirmGroup);
	}

	override public function update(elapsed:Float):Void
	{
		if (!leaving)
		{
			if (confirming)
				updateConfirm();
			else
				updateSelect();
		}

		super.update(elapsed);
	}

	function updateSelect():Void
	{
		if (Input.justPressed('up'))
			changeSelection(-1);
		else if (Input.justPressed('down'))
			changeSelection(1);

		final card:SaveCard = cards[selectedIndex];

		if (!card.info.empty && (Input.justPressed('left') || Input.justPressed('right')))
		{
			SoundController.play(Paths.sound('scroll'));
			selectedAction = (selectedAction == 0) ? 1 : 0;
			card.showActions(selectedAction);
		}

		if (Input.justPressed('confirm'))
		{
			if (card.info.empty)
			{
				SoundController.play(Paths.sound('select'));
				Global.newGame(selectedIndex);
				goToWorldMap();
			}
			else if (selectedAction == 0)
			{
				SoundController.play(Paths.sound('select'));
				Global.loadSlot(selectedIndex);
				goToWorldMap();
			}
			else
				openConfirm();
		}
		else if (Input.justPressed('cancel'))
		{
			leaving = true;
			SoundController.play(Paths.sound('cancel'));
			transitionState(new MainMenu());
		}
	}

	function goToWorldMap():Void
	{
		leaving = true;

		final card:SaveCard = cards[selectedIndex];
		FlxTween.color(card, 0.15, FlxColor.WHITE, FlxColor.YELLOW, {type: PINGPONG});

		new FlxTimer().start(0.35, function(_):Void
		{
			transitionState(new WorldMap());
		});
	}

	function openConfirm():Void
	{
		SoundController.play(Paths.sound('select'));
		confirming = true;
		confirmChoice = 0;
		confirmText.text = Locale.replaceFlagsAndReturn("$ERASE_CONFIRM", 'menu', ['<X>'], [selectedIndex + 1]);
		updateConfirmChoices();
		confirmGroup.visible = true;
	}

	function closeConfirm():Void
	{
		confirming = false;
		confirmGroup.visible = false;
	}

	function updateConfirm():Void
	{
		if (Input.justPressed('left') || Input.justPressed('right'))
		{
			SoundController.play(Paths.sound('scroll'));
			confirmChoice = (confirmChoice == 0) ? 1 : 0;
			updateConfirmChoices();
		}

		if (Input.justPressed('confirm'))
		{
			if (confirmChoice == 1)
			{
				SoundController.play(Paths.sound('die'));
				Global.eraseSlot(selectedIndex);

				final card:SaveCard = cards[selectedIndex];
				card.refresh(Global.getSlotInfo(selectedIndex));
				card.showActions(0);
				FlxG.camera.shake(0.006, 0.2);
			}
			else
				SoundController.play(Paths.sound('cancel'));

			closeConfirm();
		}
		else if (Input.justPressed('cancel'))
		{
			SoundController.play(Paths.sound('cancel'));
			closeConfirm();
		}
	}

	function updateConfirmChoices():Void
	{
		final no:String = Locale.getMenu("$NO");
		final yes:String = Locale.getMenu("$YES");

		confirmChoices.text = (confirmChoice == 0) ? '> $no <        $yes' : '$no        > $yes <';
		confirmChoices.color = (confirmChoice == 1) ? FlxColor.RED : FlxColor.WHITE;
	}

	function changeSelection(change:Int, ?playSound:Bool = true):Void
	{
		if (playSound && change != 0)
			SoundController.play(Paths.sound('scroll'));

		selectedIndex = FlxMath.wrap(selectedIndex + change, 0, cards.length - 1);
		selectedAction = 0;

		for (i in 0...cards.length)
		{
			final card:SaveCard = cards[i];
			final isSelected:Bool = (i == selectedIndex);

			card.setSelected(isSelected);

			if (isSelected)
				card.showActions(selectedAction);

			FlxTween.cancelTweensOf(card, ['x']);
			FlxTween.tween(card, {x: cardX(isSelected)}, 0.18, {ease: FlxEase.quadOut});
		}
	}
}
