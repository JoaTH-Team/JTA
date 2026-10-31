package jta.objects;

import jta.input.Input;
import jta.audio.SoundController;
import jta.util.TextUtil;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * One option in a `MenuList`.
 */
typedef MenuOption =
{
	/**
	 * The text shown (already translated).
	 */
	var label:String;

	/**
	 * Called when the option is picked.
	 */
	var ?callback:Void->Void;

	/**
	 * Sound played when the option is picked (in `sounds/`), or null for none. Defaults to `select`.
	 */
	var ?sound:Null<String>;
}

/**
 * A vertical list of menu options, in the game's style:
 * the selected option turns yellow, slides in a little and has a dark bar behind it.
 *
 * Handles up/down (wrapping) and confirm by itself, so a menu only has to say what each option does:
 * ```haxe
 * var menu = new MenuList(70, 300);
 * menu.addOption(Locale.getMenu("$RESUME"), close);
 * menu.addOption(Locale.getMenu("$RETURN"), () -> transitionState(new WorldMap()), 'cancel');
 * add(menu);
 * ```
 * Back/cancel isn't handled here, since what it does depends on the menu.
 */
class MenuList extends FlxTypedGroup<FlxSprite>
{
	/**
	 * The options, in order.
	 */
	public var options(default, null):Array<MenuOption> = [];

	/**
	 * The text of each option, in order.
	 */
	public var items(default, null):Array<FlxText> = [];

	/**
	 * The selected option.
	 */
	public var selectedIndex(default, null):Int = 0;

	/**
	 * Whether the list reacts to input. Turn off while leaving the menu or while something else has focus.
	 */
	public var enabled:Bool = true;

	/**
	 * Called with the new index whenever the selection changes.
	 */
	public var onChange:Null<Int->Void> = null;

	public var normalColor:FlxColor = FlxColor.WHITE;
	public var selectedColor:FlxColor = FlxColor.YELLOW;

	/**
	 * Left edge of the options.
	 */
	public var x(default, null):Float;

	/**
	 * Top of the first option.
	 */
	public var y(default, null):Float;

	/**
	 * Distance between options.
	 */
	public var spacing(default, null):Float;

	/**
	 * Font size of the options.
	 */
	public var size(default, null):Int;

	/**
	 * How far the selected option slides to the right.
	 */
	public var slide(default, null):Float;

	/**
	 * The dark bar behind the selected option, or null if the list was made without one.
	 */
	public var bar(default, null):Null<FlxSprite> = null;

	/**
	 * If `true`, every option is centered on the screen instead of starting at `x` (the selected one doesn't slide).
	 * Set it before adding options.
	 */
	public var centered:Bool = false;

	/**
	 * The bar is at least this wide, so short menus don't get a tiny bar.
	 */
	public var minBarWidth:Float = 0;

	/**
	 * @param x Left edge of the options.
	 * @param y Top of the first option.
	 * @param spacing Distance between options.
	 * @param size Font size.
	 * @param showBar Whether to draw the dark bar behind the selected option.
	 * @param slide How far the selected option slides to the right.
	 */
	public function new(x:Float, y:Float, ?spacing:Float = 56, ?size:Int = 36, ?showBar:Bool = true, ?slide:Float = 16)
	{
		super();

		this.x = x;
		this.y = y;
		this.spacing = spacing;
		this.size = size;
		this.slide = slide;

		if (showBar)
		{
			bar = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			bar.alpha = 0.45;
			bar.scrollFactor.set();
			add(bar);
		}
	}

	/**
	 * Adds an option to the end of the list.
	 * @param label The text shown (already translated).
	 * @param callback Called when the option is picked.
	 * @param sound Sound played when it's picked (defaults to `select`; null for none).
	 * @return The option's text.
	 */
	public function addOption(label:String, ?callback:Void->Void, ?sound:String = 'select'):FlxText
	{
		options.push({label: label, callback: callback, sound: sound});

		final item:FlxText = TextUtil.make(x, y + items.length * spacing, 0, label, size);
		item.scrollFactor.set();
		items.push(item);
		add(item);

		refresh(false);
		return item;
	}

	/**
	 * Changes an option's text.
	 */
	public function setLabel(index:Int, label:String):Void
	{
		if (index < 0 || index >= items.length)
			return;

		options[index].label = label;
		items[index].text = label;
		refresh(false);
	}

	/**
	 * Selects an option.
	 * @param index The option's index.
	 * @param animate Whether to slide the bar and text over (false snaps them).
	 */
	public function select(index:Int, ?animate:Bool = true):Void
	{
		if (items.length == 0)
			return;

		final previous:Int = selectedIndex;
		selectedIndex = FlxMath.wrap(index, 0, items.length - 1);
		refresh(animate);

		if (selectedIndex != previous && onChange != null)
			onChange(selectedIndex);
	}

	/**
	 * Moves the selection up (-1) or down (1), wrapping around, with the scroll sound.
	 */
	public function changeSelection(change:Int):Void
	{
		if (items.length == 0)
			return;

		SoundController.play(Paths.sound('scroll'));
		select(selectedIndex + change);
	}

	/**
	 * Picks the selected option: plays its sound and calls its callback.
	 */
	public function confirm():Void
	{
		if (options.length == 0)
			return;

		final option:MenuOption = options[selectedIndex];

		if (option.sound != null)
			SoundController.play(Paths.sound(option.sound));

		if (option.callback != null)
			option.callback();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled || items.length == 0)
			return;

		if (Input.justPressed('up'))
			changeSelection(-1);
		else if (Input.justPressed('down'))
			changeSelection(1);
		else if (Input.justPressed('confirm'))
			confirm();
	}

	/**
	 * Updates colors, positions and the bar.
	 */
	function refresh(animate:Bool):Void
	{
		var widest:Float = 0;

		for (i in 0...items.length)
		{
			final item:FlxText = items[i];
			final isSelected:Bool = (i == selectedIndex);
			final targetX:Float = centered ? (FlxG.width - item.width) / 2 : x + (isSelected ? slide : 0);

			item.color = isSelected ? selectedColor : normalColor;
			widest = Math.max(widest, item.width);

			FlxTween.cancelTweensOf(item, ['x']);
			if (animate)
				FlxTween.tween(item, {x: targetX}, 0.12, {ease: FlxEase.quadOut});
			else
				item.x = targetX;
		}

		if (bar != null)
		{
			final barHeight:Int = size + 16;

			bar.setGraphicSize(Std.int(Math.max(minBarWidth, widest + (centered ? 0 : slide) + 40)), barHeight);
			bar.updateHitbox();
			bar.x = centered ? (FlxG.width - bar.width) / 2 : x - 20;
			bar.visible = items.length > 0;

			final barY:Float = y + selectedIndex * spacing - 8;

			FlxTween.cancelTweensOf(bar, ['y']);
			if (animate)
				FlxTween.tween(bar, {y: barY}, 0.12, {ease: FlxEase.quadOut});
			else
				bar.y = barY;
		}
	}
}
