package jta.audio;

import flixel.sound.FlxSound;
import flixel.sound.FlxSoundGroup;
import flixel.tweens.FlxTween;

/**
 * A group that holds a list of sounds. Unlike `FlxSoundGroup`, this allows to change the time, and pitch of sounds.
 * Each sound in group will be synced with each other.
 */
class SoundGroup extends FlxSoundGroup
{
	/**
	 * The current time of the group.
	 * When changed, all sounds are timed to this position.
	 */
	public var time(get, set):Float;

	function set_time(value:Float):Float
	{
		forEach(function(sound:FlxSound)
		{
			sound.time = value;
		});
		return value;
	}

	function get_time():Float
		return sounds[0]?.time ?? 0.0;

	/**
	 * The current pitch of the group.
	 * When changed, all sounds are pitched to this value.
	 */
	public var pitch(get, set):Float;

	function set_pitch(value:Float):Float
	{
		forEach(function(sound:FlxSound)
		{
			sound.pitch = value;
		});
		return value;
	}

	function get_pitch():Float
	{
		return sounds[0]?.pitch ?? 1.0;
	}

	/**
	 * Whether the group is currently playing, or not.
	 */
	public var playing(get, never):Bool;

	function get_playing():Bool
	{
		return sounds[0]?.playing ?? false;
	}

	/**
	 * Adds a new sound to the group.
	 * @param sound The sound object to add.
	 * @return Whether the sound was successfully able to be added to the group.
	 */
	public override function add(sound:FlxSound):Bool
	{
		if (super.add(sound))
		{
			sound.time = time;
			sound.pitch = pitch;
			return true;
		}
		return false;
	}

	/**
	 * Pauses the sounds in this group.
	 */
	public override function pause():Void
	{
		// Resync sounds in the group
		this.time = time;

		super.pause();
	}

	/**
	 * Pauses the sound in this group.
	 */
	public override function resume():Void
	{
		// Resync sounds in the group
		this.time = time;

		super.resume();
	}

	/**
	 * Plays each sound in the group.
	 */
	public function play():Void
	{
		forEach(function(sound:FlxSound)
		{
			sound.play();
		});
	}

	/**
	 * Stops each sound from playing in the group.
	 */
	public function stop():Void
	{
		forEach(function(sound:FlxSound)
		{
			sound.stop();
		});
	}

	/**
	 * Iterates through each sound in the group.
	 * @param func The function to call for each sound.
	 */
	public function forEach(func:FlxSound->Void):Void
	{
		for (sound in sounds)
			if (sound != null)
				func(sound);
	}

	/**
	 * Fades in each sound in the group.
	 * @param duration How long the fade effect should last.
	 * @param from The sound should start from this volume.
	 * @param to The sound should go to this volume.
	 * @param onComplete Called when the fade effect is complete.
	 */
	public function fadeIn(duration:Float = 1, from:Float = 0, to:Float = 1, ?onComplete:FlxTween->Void):Void
	{
		forEach(function(sound:FlxSound)
		{
			sound.fadeIn(duration, from, to, onComplete);
		});
	}

	/**
	 * Fades out each sound in the group.
	 * @param duration How long the fade effect should last.
	 * @param to The sound should go to this volume.
	 * @param onComplete Called when the fade effect is complete.
	 */
	public function fadeOut(duration:Float = 1, to:Float = 0, ?onComplete:FlxTween->Void):Void
	{
		forEach(function(sound:FlxSound)
		{
			sound.fadeOut(duration, to, onComplete);
		});
	}
}
