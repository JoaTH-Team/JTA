package jta.locale;

import jta.Data;
import jta.Paths;
import jta.Assets;
import firetongue.Replace;
import firetongue.FireTongue;

/**
 * Handles localization and language settings for the game.
 * @see https://github.com/larsiusprime/firetongue
 */
class Locale
{
	/**
	 * The FireTongue instance.
	 */
	public static var tongue:FireTongue;

	/**
	 * List of available locales.
	 */
	public static var locales:Array<String>;

	/**
	 * The name of the font used for localization.
	 */
	public static var fontName:String;

	/**
	 * The current locale being used.
	 */
	public static var locale:String = 'en-US';

	/**
	 * Initializes the localization system.
	 */
	public static function init():Void
	{
		if (Data.settings.locale != null)
			locale = Data.settings.locale;

		tongue = new FireTongue();
		tongue.initialize({
			locale: locale,
			finishedCallback: onFinish,
			checkMissing: true
		});

		locale = tongue.locale;

		locales = tongue.locales.copy();
		locales.sort(function(a, b) return Reflect.compare(a, b));

		fontName = getData("$FONT_NAME");
	}

	/**
	 * Called when localization is finished loading.
	 */
	static function onFinish():Void
	{
		var text:String = '';
		var contextArray:Array<String> = ['data', 'menu', 'playState', 'settings'];
		if (tongue.missingFiles != null)
		{
			for (context in contextArray)
			{
				var str:String = tongue.get("$MISSING_FILES", context);
				str = Replace.flags(str, ['<X>'], [Std.string(tongue.missingFiles.length)]);
				text += '$str\n';
				for (file in tongue.missingFiles)
					text += '     $file\n';

				trace(text);
			}
		}

		if (tongue.missingFlags != null)
		{
			var missingFlags = tongue.missingFlags;

			for (context in contextArray)
			{
				var miss_str:String = tongue.get("$MISSING_FLAGS", context);

				var count:Int = 0;
				var flag_str:String = '';

				for (key in missingFlags.keys())
				{
					var list:Array<String> = missingFlags.get(key);
					count += list.length;
					for (flag in list)
						flag_str += '    Context($key): $flag\n';
				}

				miss_str = Replace.flags(miss_str, ['<X>'], [Std.string(count)]);
				text += '$miss_str\n';
				text += '$flag_str\n';
			}

			trace(text);
		}

		if (tongue.missingFlags == null && tongue.missingFiles == null)
			trace('Successfully loaded language stuff');
	}

	/**
	 * Loads a language file.
	 * @param lang The language to load.
	 */
	public static function loadLanguage(lang:String):Void
	{
		tongue.initialize({
			locale: lang,
			finishedCallback: onFinish,
			checkMissing: true
		});

		locales = tongue.locales.copy();
		locales.sort(function(a, b) return Reflect.compare(a, b));

		fontName = getData("$FONT_NAME");
	}

	/**
	 * Gets a localized string for the given key and context, and replaces flags with values.
	 * @param key The key to look up in the localization files.
	 * @param context The context in which to look up the key.
	 * @param flags The flags to replace in the string.
	 * @param values The values to replace the flags with.
	 * @return The localized string with flags replaced.
	 */
	public static function replaceFlagsAndReturn(key:String, context:String, flags:Array<String>, values:Array<Dynamic>):String
	{
		var stringArray:Array<String> = [];
		for (i in values)
			stringArray.push(i.toString());
		return Replace.flags(getString(key, context), flags, stringArray);
	}

	/**
	 * Gets the localized string for the given key.
	 * @param key The key to look up in the localization files.
	 * @return The localized string.
	 */
	public static function getData(key:String):String
	{
		return tongue.get(key, 'data');
	}

	/**
	 * Gets the localized string for the given key.
	 * @param key The key to look up in the localization files.
	 * @return The localized string.
	 */
	public static function getMenu(key:String):String
	{
		return tongue.get(key, 'menu');
	}

	/**
	 * Gets the localized string for the given key.
	 * @param key The key to look up in the localization files.
	 * @return The localized string.
	 */
	public static function getPlayState(key:String):String
	{
		return tongue.get(key, 'playState');
	}

	/**
	 * Gets the localized string for the given key.
	 * @param key The key to look up in the localization files.
	 * @return The localized string.
	 */
	public static function getSettings(key:String):String
	{
		return tongue.get(key, 'settings');
	}

	/**
	 * Gets the localized string for the given key.
	 * @param key The key to look up in the localization files.
	 * @param context A key specifying which index to look for the key in.
	 * @return The localized string.
	 */
	public static function getString(key:String, context:String):String
	{
		return tongue.get(key, context);
	}

	/**
	 * Gets a localized file path.
	 * @param path The path to the file.
	 * @return The localized file path.
	 */
	public static function getFile(path:String):String
	{
		if (Assets.exists('assets/locales/$locale/$path'))
			return 'assets/locales/$locale/$path';
		return null;
	}
}
