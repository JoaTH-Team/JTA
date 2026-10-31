package jta.util;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import jta.locale.Locale;

/**
 * Helpers for making text in the game's style (the current language's font, white with a black outline).
 */
@:nullSafety
class TextUtil
{
	/**
	 * Font used when the current language doesn't set one (or its font can't be found).
	 */
	public static final DEFAULT_FONT:String = 'main';

	static var cachedKey:Null<String> = null;
	static var cachedFont:Null<String> = null;

	/**
	 * Gets the font for the current language: `$FONT_NAME` in the language's `data.csv`
	 * (a file in `assets/fonts/`), falling back to `DEFAULT_FONT`.
	 * @return The font name, ready for `setFormat()`.
	 */
	public static function getFont():String
	{
		final localeFont:Null<String> = Locale.fontName;
		final key:String = '${Locale.locale}|${localeFont ?? ''}';

		if (cachedFont != null && cachedKey == key)
			return cachedFont;

		var font:Null<String> = null;

		if (localeFont != null && localeFont != '')
		{
			final name:String = haxe.io.Path.withoutExtension(localeFont);

			if (Assets.exists('assets/fonts/$name.ttf') || Assets.exists('assets/fonts/$name.otf'))
				font = Paths.font(name);
		}

		font ??= Paths.font(DEFAULT_FONT);

		final result:String = font ?? DEFAULT_FONT;
		cachedKey = key;
		cachedFont = result;
		return result;
	}

	/**
	 * Makes a text in the game's style: current language's font, black outline.
	 * Same order as `new FlxText()`, plus alignment and color.
	 *
	 * ```haxe
	 * var title = TextUtil.make(0, 20, FlxG.width, 'Hello', 40, CENTER, FlxColor.YELLOW);
	 * ```
	 * @param x X position.
	 * @param y Y position.
	 * @param fieldWidth Width of the text box (0 = fit the text).
	 * @param text The text.
	 * @param size Font size.
	 * @param align Alignment (defaults to `LEFT`).
	 * @param color Text color (defaults to white).
	 */
	public static function make(x:Float, y:Float, ?fieldWidth:Float = 0, ?text:String = '', ?size:Int = 24, ?align:FlxTextAlign,
			?color:FlxColor):FlxText
	{
		return style(new FlxText(x, y, fieldWidth, text), size, align, color);
	}

	/**
	 * Applies the game's text style to an existing text.
	 * @param text The text to style.
	 * @param size Font size.
	 * @param align Alignment (defaults to `LEFT`).
	 * @param color Text color (defaults to white).
	 * @return The same text, for chaining.
	 */
	public static function style(text:FlxText, ?size:Int = 24, ?align:FlxTextAlign, ?color:FlxColor):FlxText
	{
		text.setFormat(getFont(), size, color ?? FlxColor.WHITE, align ?? LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		return text;
	}
}
