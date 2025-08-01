package jta.objects.dialogue.typers;

import flixel.util.FlxStringUtil;
import flixel.util.FlxDestroyUtil;
import openfl.media.Sound;

/**
 * A structure representing the sound settings for typing effects.
 */
typedef TypingSound =
{
	/**
	 * The sound to be played when typing.
	 */
	sound:Sound,

	/**
	 * The volume level of the sound.
	 */
	volume:Float,

	/**
	 * The pitch of the sound, if specified.
	 */
	?pitch:Float
}

/**
 * Represents a typer for displaying text in the game.
 */
class Typer implements IFlxDestroyable
{
	/**
	 * The ID of the typer.
	 */
	public var typerID:String;

	/**
	 * The offset position of the typer.
	 */
	public var typerOffset:FlxPoint = FlxPoint.get();

	/**
	 * Array of sounds associated with the typer.
	 */
	public var typerSounds:Array<TypingSound>;

	/**
	 * The amount of seconds between characters being typed.
	 */
	public var typerFPS:Float;

	/**
	 * The name of the font used by the typer.
	 */
	public var fontName:String;

	/**
	 * The size of the font used by the typer.
	 */
	public var fontSize:Int;

	/**
	 * The spacing between characters in the text.
	 */
	public var fontSpacing:Null<Float>;

	/**
	 * Initializes the typer with a specific ID.
	 * @param typerID The ID of the typer.
	 */
	public function new(typerID:String):Void
	{
		this.typerID = typerID;
	}

	/**
	 * Cleans up memory.
	 */
	public function destroy():Void
	{
		typerOffset = FlxDestroyUtil.put(typerOffset);
		typerSounds = FlxArrayUtil.clearArray(typerSounds);
	}

	/**
	 * Converts the typer to a string for display.
	 * @return A string representation of the typer.
	 */
	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak('Typer ID', typerID),
			LabelValuePair.weak('Font Name', fontName),
			LabelValuePair.weak('Font Size', fontSize),
			LabelValuePair.weak('Font Spacing', fontSpacing),
			LabelValuePair.weak('Typer Sounds', typerSounds),
			LabelValuePair.weak('Typer Letters Per Second', typerFPS)
		]);
	}
}
