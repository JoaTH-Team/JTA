package jta;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import jta.Assets;

using haxe.io.Path;

/**
 * Enum representing different types of sprite sheets.
 */
enum SpriteSheetType
{
	ASEPRITE;
	PACKER;
	SPARROW;
	TEXTURE_PATCHER_JSON;
	TEXTURE_PATCHER_XML;
}

/**
 * Provides utility functions for handling asset paths and loading assets in a game.
 */
@:keep
@:nullSafety
class Paths
{
	/**
	 * The sound extension to use.
	 */
	public static final SOUND_EXT:String = #if !web 'ogg' #else 'mp3' #end;

	/**
	 * Finds an asset by checking the given path with multiple extensions.
	 * @param path The base path of the asset.
	 * @param exts What extensions to check for the asset.
	 * @return The path to the asset with the matching extension.
	 */
	static function findAsset(path:String, exts:Array<String>):String
	{
		for (ext in exts)
			if (path.extension() == '' && Assets.exists(path.withExtension(ext)))
				return path.withExtension(ext);
		return path;
	}

	/**
	 * Gets an array of strings from the text content of a file at the given path.
	 * @param path The path to the file.
	 * @return The array of strings, each representing a line in the file.
	 */
	inline public static function getTextArray(path:String):Array<String>
		return Assets.exists(path) ? [for (i in (Assets.getText(path) ?? '').trim().split('\n')) i.trim()] : [];

	/**
	 * Gets a text file.
	 * @param key The key for the text file.
	 * @return The path to the text file.
	 */
	inline static public function txt(key:String):String
		return 'assets/$key.txt';

	/**
	 * Gets a JSON file.
	 * @param key The key for the JSON file.
	 * @return The path to the JSON file.
	 */
	inline static public function json(key:String):String
		return 'assets/$key.json';

	/**
	 * Gets a CSV file.
	 * @param key The key for the CSV file.
	 * @return The path to the CSV file.
	 */
	inline static public function csv(key:String):String
		return 'assets/$key.csv';

	/**
	 * Gets a sound effect as a `Sound` object.
	 * @param key The key for the sound file.
	 * @param cache Whether or not to cache the sound.
	 * @return The path to the sound file.
	 */
	inline static public function sound(key:String, ?cache:Bool = true):Null<Sound>
		return Assets.getSound(findAsset('assets/sounds/$key', [SOUND_EXT, 'wav']), cache);

	/**
	 * Gets a music track as a `Sound` object.
	 * @param key The key for the music file.
	 * @param cache Whether or not to cache the sound.
	 * @return The path to the music file.
	 */
	inline static public function music(key:String, ?cache:Bool = true):Null<Sound>
		return Assets.getSound(findAsset('assets/music/$key', [SOUND_EXT, 'wav']), cache);

	/**
	 * Gets a font file.
	 * @param key The key for the font file.
	 * @param cache Whether or not to cache the font.
	 * @return The font name.
	 */
	inline static public function font(key:String, ?cache:Bool = true):Null<String>
		return Assets.getFont(findAsset('assets/fonts/$key', ['ttf', 'otf']), cache).fontName;

	/**
	 * Gets an image file.
	 * @param key The key for the image file.
	 * @return The path to the image file.
	 */
	inline static public function image(key:String):String
		return 'assets/images/$key.png';

	/**
	 * Gets a video file.
	 * @param key The key for the video file.
	 * @return The path to the video file.
	 */
	inline static public function video(key:String):String
		return 'assets/videos/$key.webm';

	/**
	 * Gets a sound file for a video as a `Sound` object.
	 * @param key The key for the sound file.
	 * @param cache Whether or not to cache the sound.
	 * @return The path to the sound file.
	 */
	inline static public function videoSound(key:String, ?cache:Bool = true):Null<Sound>
		return Assets.getSound(findAsset('assets/videos/$key', [SOUND_EXT, 'wav']), cache);

	/**
	 * Gets a spritesheet in a specific format.
	 * @param key The key for the spritesheet.
	 * @param type The type of the spritesheet.
	 * @return The path to the spritesheet, `null` otherwise.
	 */
	public static inline function spritesheet(key:String, ?type:SpriteSheetType):Null<FlxAtlasFrames>
	{
		type = type ?? SPARROW;
		return switch (type)
		{
			case ASEPRITE: FlxAtlasFrames.fromAseprite(image(key), image(key).withExtension('json'));
			case PACKER: FlxAtlasFrames.fromSpriteSheetPacker(image(key), image(key).withExtension('txt'));
			case SPARROW: FlxAtlasFrames.fromSparrow(image(key), image(key).withExtension('xml'));
			case TEXTURE_PATCHER_JSON: FlxAtlasFrames.fromTexturePackerJson(image(key), image(key).withExtension('json'));
			case TEXTURE_PATCHER_XML: FlxAtlasFrames.fromTexturePackerXml(image(key), image(key).withExtension('xml'));
			default: FlxAtlasFrames.fromSparrow(image('errorSparrow'), image('errorSparrow').withExtension('xml'));
		}
	}
}
