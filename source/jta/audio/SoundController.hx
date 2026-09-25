package jta.audio;

import jta.Data;
import jta.audio.GameSound;
import flixel.sound.FlxSound;
import flixel.sound.FlxSoundGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.frontEnds.SoundFrontEnd;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.media.Sound;

/**
 * An extension of SoundFrontEnd that uses `GameSound` instead `FlxSound`
 * This class should be used for loading and playing sounds instead of `FlxG.sound`.
 */
class SoundController
{
	/**
	 * GameSound group that recycles destroyed/null sounds to be reused in the pool like `FlxG.sound.list`.
	 */
	public static var pool(default, null):FlxTypedGroup<GameSound> = new FlxTypedGroup<GameSound>();

	/**
	 * Redirect to `FlxG.sound.music` for consistency.
	 */
	public static var music(get, set):FlxSound;

	static function get_music():FlxSound
	{
		return FlxG.sound.music;
	}

	static function set_music(value:FlxSound):FlxSound
	{
		return FlxG.sound.music = value;
	}

	/**
	 * Instantiates a new `GameSound` object.
	 * @return An empty GameSound.
	 */
	static function construct():GameSound
	{
		var sound:GameSound = new GameSound();
		return add(sound);
	}

	/**
	 * Adds a `GameSound` to the list and pool.
	 * @param sound The GameSound to add.
	 * @return The added GameSound.
	 */
	public static function add(sound:GameSound):GameSound
	{
		pool.add(sound);
		FlxG.sound.list.add(sound);
		return sound;
	}

	/**
	 * Removes a `GameSound` from the list and pool.
	 * @param sound The GameSound to remove.
	 * @return The removed GameSound.
	 */
	public static function remove(sound:GameSound):GameSound
	{
		pool.remove(sound);
		FlxG.sound.list.remove(sound);
		return sound;
	}

	/**
	 * Constructs, and loads a sound asset to play as the current music track. 
	 * @param embeddedMusic The sound asset to play. 
	 * @param volume The volume of the sound asset.
	 * @param looped Whether the music should be looped.
	 * @param group (Optional) The sound group this music asset should be in.
	 */
	public static function playMusic(embeddedMusic:FlxSoundAsset, volume = 1.0, looped = true, ?group:FlxSoundGroup)
	{
		if (group == null)
			group = FlxG.sound.defaultMusicGroup;

		if (music == null)
			music = new GameSound(MUSIC);
		else if (music.active)
			music.stop();

		music.load(embeddedMusic);
		music.looped = looped;
		music.volume = volume;
		music.persist = true;
		group.add(music);
		music.play();
	}

	/**
	 * Loads, and plays the given sound asset.
	 * @param embeddedSound The sound asset to play.
	 * @param volume The volume the sound should be at.
	 * @param looped Whether this sound object should restart when completed.
	 * @param soundType The type of sound this sound asset is. Used to automate the volume based on user preferences.
	 * @param group The group to put this sound in.
	 * @param autoDestroy Should the sound be destroyed on complete?
	 * @param onComplete Called when the sound is finished playing.
	 * @return A constructed `GameSound` object that plays.
	 */
	public static function play(embeddedSound:FlxSoundAsset, volume = 1.0, looped = false, ?soundType:SoundType = SFX, ?group:FlxSoundGroup,
			autoDestroy = true, ?onComplete:Void->Void):GameSound
	{
		var sound:GameSound = pool.recycle(construct).load(embeddedSound);
		sound.soundType = soundType;
		sound.looped = looped;
		sound.autoDestroy = autoDestroy;
		sound.onComplete = onComplete;

		return loadHelper(sound, volume, group, true);
	}

	/**
	 * Loads, and returns a new `GameSound` object to use.
	 * @param embeddedSound The sound asset to load.
	 * @param volume The volume the sound should be at.
	 * @param looped Whether this sound object should restart when completed.
	 * @param soundType The type of sound this sound asset is. Used to automate the volume based on user preferences.
	 * @param group The group to put this sound in.
	 * @param autoDestroy Should the sound be destroyed on complete?
	 * @param autoPlay Whether the song should play when loaded. 
	 * @param onComplete Called when the sound is finished playing.
	 * @param onLoad Called when the sound has loaded.
	 * @return A constructed `GameSound` object.
	 */
	public static function load(embeddedSound:FlxSoundAsset, volume = 1.0, looped = false, ?soundType:SoundType = SFX, ?group:FlxSoundGroup,
			autoDestroy = false, autoPlay = false, ?onComplete:Void->Void, ?onLoad:Void->Void):GameSound
	{
		var sound:GameSound = pool.recycle(construct).load(embeddedSound);
		sound.soundType = soundType;
		sound.looped = looped;
		sound.autoDestroy = autoDestroy;
		sound.onComplete = onComplete;
		loadHelper(sound, volume, group, autoPlay);
		@:privateAccess
		if (onLoad != null && sound._sound != null)
			onLoad();

		return sound;
	}

	/**
	 * Pauses all sounds in this group.
	 * Redirects to `FlxG.sound.pause()` for convenience.
	 */
	public static function pause():Void
	{
		FlxG.sound.pause();
	}

	/**
	 * Resumes all sounds in this group.
	 * Redirects to `FlxG.sound.resume()` for convenience.
	 */
	public static function resume():Void
	{
		FlxG.sound.resume();
	}

	static function loadHelper(sound:GameSound, volume:Float, ?group:FlxSoundGroup, autoPlay:Bool = false):GameSound
	{
		if (group == null)
			group = FlxG.sound.defaultSoundGroup;

		sound.volume = volume;
		group.add(sound);

		if (autoPlay)
			sound.play();

		return sound;
	}
}
