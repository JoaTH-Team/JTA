package jta.objects.level;

import jta.objects.Vector;

/**
 * Represents a player in the game.
 */
class Player extends FlxSprite
{
	/**
	 * The direction the player is facing, represented as a `Vector`.
	 */
	public var direction:Vector = new Vector(0, 0);

	/**
	 * The speed of the player, represented as a `Vector`.
	 */
	public var speed:Vector = new Vector(0, 0);

	/**
	 * The ID of the player character.
	 */
	public var characterID:String;

	/**
	 * Whether or not the player character is controllable.
	 */
	public var characterControllable:Bool = true;

	/**
	 * Initializes the object with a specified ID.
	 * @param characterID The ID of the player character.
	 */
	public function new(characterID:String):Void
	{
		super();

		this.characterID = characterID;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		this.x += direction.dx * speed.dx;
		this.y += direction.dy * speed.dy;
	}
}
