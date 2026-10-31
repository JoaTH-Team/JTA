package jta.objects.dialogue.portraits;

import jta.Paths;
import jta.Assets;

/**
 * Represents an portrait within a dialogue.
 */
class Portrait extends FlxSprite
{
	/**
	 * Scale applied to every face.
	 */
	public static inline var DEFAULT_SCALE:Float = 2;

	/**
	 * Offset applied to every face.
	 */
	public static inline var DEFAULT_OFFSET:Float = -45;

	/**
	 * The ID of the portrait.
	 */
	public var portraitID:String;

	/**
	 * The face currently shown.
	 */
	public var currentFace:String = 'default';

	/**
	 * Initializes the portrait with a specific ID, and shows its default face if it has one.
	 * @param portraitID The ID of the portrait.
	 */
	public function new(portraitID:String):Void
	{
		super();

		this.portraitID = portraitID;

		active = false;

		loadFace('default');
	}

	/**
	 * Changes the face of the portrait.
	 * @param name The name of the face.
	 */
	public function changeFace(name:String):Void
	{
		loadFace(name);
	}

	/**
	 * Loads `images/portraits/<portrait ID>/<name>.png`, or `default.png` if that face doesn't exist.
	 * @param name The name of the face.
	 * @return Whether an image was loaded.
	 */
	public function loadFace(name:String):Bool
	{
		var path:String = Paths.image('portraits/$portraitID/$name');

		if (!Assets.exists(path))
		{
			name = 'default';
			path = Paths.image('portraits/$portraitID/default');
		}

		if (!Assets.exists(path))
			return false;

		loadGraphic(path);
		scale.set(DEFAULT_SCALE, DEFAULT_SCALE);
		updateHitbox();
		offset.set(DEFAULT_OFFSET, DEFAULT_OFFSET);

		currentFace = name;
		return true;
	}

	/**
	 * Whether a portrait ID has images.
	 * @param portraitID The ID of the portrait.
	 */
	public static function hasImages(portraitID:String):Bool
		return Assets.exists(Paths.image('portraits/$portraitID/default'));
}
