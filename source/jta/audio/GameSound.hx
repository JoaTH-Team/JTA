package jta.audio;

import jta.Data;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;

/**
 * The type of sound this sound object is.
 */
enum SoundType
{
	MUSIC;
	SFX;
}

/**
 * An FlxSound extension with an additional `SoundType` allowing for volume automation based on what sound it is.
 */
class GameSound extends FlxSound
{
	public var soundType:SoundType = SFX;

	public function new(?soundType:SoundType = SFX)
	{
		this.soundType = soundType;
		super();
	}

	/**
	 * Loads, and returns this sound object based on the given sound asset. Synonym for `loadEmbedded` from FlxSound. 
	 * @param embeddedSound The sound asset to load.
	 * @param looped Whether this sound should loop.
	 * @param autoDestroy Should the sound destroy when completed?
	 * @param onComplete Called when the audio is finished.
	 */
	public override function load(asset:FlxSoundAsset, allowCache:Bool = true):GameSound
	{
		super.load(asset, allowCache);
		return this;
	}

	// Override to take user volume preferences into account.
	override function updateTransform():Void
	{
		var volumeMultiplier:Float = switch (soundType)
		{
			case MUSIC: Data.settings.musicVolume;
			case SFX: Data.settings.sfxVolume;
		}
		_transform.volume = #if FLX_SOUND_SYSTEM (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume * #end
			(group != null ? group.volume : 1) * _volume * _volumeAdjust * (volumeMultiplier / 100);

		if (_channel != null)
			_channel.soundTransform = _transform;
	}
}
