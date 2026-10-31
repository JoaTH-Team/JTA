package jta.objects.level;

/**
 * Represents an object in a level.
 */
class Object extends FlxSprite
{
	/**
	 * The ID of the object.
	 */
	public var objectID:String;

	/**
	 * Whether or not the object can be interacted with.
	 */
	public var objectInteractable:Bool;

	/**
	 * Whether the object has an `interact()` action as opposed to
	 * only reacting to being touched.
	 */
	public var objectHasInteraction:Bool = false;

	/**
	 * Extra values given to this object in `objects.csv`..
	 */
	public var objectParams:Array<String> = [];

	/**
	 * Initializes the object with a specified ID.
	 * @param objectID The ID of the object.
	 */
	public function new(objectID:String):Void
	{
		super();

		this.objectID = objectID;
	}

	/**
	 * Gets one of the object's params, with a fallback if it wasn't given.
	 * @param index Which param (0 is the first one after the ID).
	 * @param fallback What to return if the param is missing or empty.
	 * @return The param.
	 */
	public function getParam(index:Int, ?fallback:String):Null<String>
	{
		final value:Null<String> = objectParams[index];
		return (value != null && value != '') ? value : fallback;
	}

	/**
	 * Function called once the object has been placed in the level, after `objectParams` and its position are set.
	 */
	public function onPlaced():Void {}

	/**
	 * Function called when the object is interacted with, if it is interactable.
	 */
	public function interact():Void {}

	/**
	 * Function called when the player overlaps the object.
	 */
	public function overlap():Void {}
}
