package jta;

import haxe.Exception;
import openfl.text.Font;
import openfl.media.Sound;
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFLAssets;

/**
 * Provides utility functions for handling game assets, such as images, sounds, fonts, and text files.
 */
@:nullSafety
class Assets
{
	/**
	 * Checks if an asset exists at the given path.
	 * @param path The path to the asset.
	 * @return `true` if the asset exists, `false` otherwise.
	 */
	public static function exists(path:String):Bool
		return OpenFLAssets.exists(path);

	/**
	 * Retrieves a bitmap image asset.
	 * @param path The path to the image file.
	 * @param cache Whether to cache the bitmap data (default is true).
	 * @return The `BitmapData` object, or null if the file does not exist or an error occurs.
	 */
	public static function getBitmapData(path:String, ?cache:Bool = true):Null<BitmapData>
	{
		try
		{
			return OpenFLAssets.getBitmapData(path, cache);
		}
		catch (e:Exception)
			FlxG.log.error(e.message);

		return null;
	}

	/**
	 * Retrieves a sound asset.
	 * @param path The path to the sound file.
	 * @param cache Whether to cache the sound data (default is true).
	 * @return The `Sound` object, or null if the file does not exist or an error occurs.
	 */
	public static function getSound(path:String, ?cache:Bool = true):Null<Sound>
	{
		try
		{
			return OpenFLAssets.getSound(path, cache);
		}
		catch (e:Exception)
			FlxG.log.error(e.message);

		return null;
	}

	/**
	 * Retrieves a font asset.
	 * @param path The path to the font file.
	 * @param cache Whether to cache the font data (default is true).
	 * @return The `Font` object, or null if the file does not exist or an error occurs.
	 */
	public static function getFont(path:String, ?cache:Bool = true):Null<Font>
	{
		try
		{
			return OpenFLAssets.getFont(path, cache);
		}
		catch (e:Exception)
			FlxG.log.error(e.message);

		return null;
	}

	/**
	 * Retrieves the text content of a file.
	 * @param path The path to the text file.
	 * @return The content of the file as a `String`, or null if the file does not exist or an error occurs.
	 */
	public static function getText(path:String):Null<String>
	{
		try
		{
			return OpenFLAssets.getText(path);
		}
		catch (e:Exception)
			FlxG.log.error(e.message);

		return null;
	}
}
