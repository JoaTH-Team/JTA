package jta.registries.dialogue;

import jta.objects.dialogue.portraits.ScriptedPortrait;
import jta.objects.dialogue.portraits.Portrait;

/**
 * Handles the loading and management of scripted dialogue portrait classes.
 */
class PortraitRegistry
{
	/**
	 * Map to store associations between dialogue portrait IDs and scripted dialogue portrait classes.
	 */
	private static final portraitScriptedClasses:Map<String, String> = [];

	/**
	 * Loads and initializes scripted dialogue portrait classes.
	 */
	public static function loadPortraits():Void
	{
		clearPortraits();

		final scriptedPortraits:Array<String> = ScriptedPortrait.listScriptClasses();

		if (scriptedPortraits.length > 0)
		{
			FlxG.log.notice('Initiating ${scriptedPortraits.length} scripted dialogue portraits...');

			for (scriptedPortrait in scriptedPortraits)
			{
				final portrait:Portrait = ScriptedPortrait.scriptInit(scriptedPortrait, 'unknown');

				if (portrait == null)
					continue;

				FlxG.log.notice('Initialized dialogue portrait "${portrait.portraitID}"!');

				portraitScriptedClasses.set(portrait.portraitID, scriptedPortrait);
			}
		}

		FlxG.log.notice('Successfully loaded ${Lambda.count(portraitScriptedClasses)} portrait(s)!');
	}

	/**
	 * Fetches a scripted dialogue portrait by its ID.
	 * @param portraitID The ID of the portrait.
	 * @return The portrait or null if not found.
	 */
	public static function fetchPortrait(portraitID:String):Null<Portrait>
	{
		if (!portraitScriptedClasses.exists(portraitID))
		{
			FlxG.log.error('Unable to load "${portraitID}", not found in cache');

			return null;
		}

		final portraitScriptedClass:Null<String> = portraitScriptedClasses.get(portraitID);

		if (portraitScriptedClass != null)
		{
			final portrait:Portrait = ScriptedPortrait.scriptInit(portraitScriptedClass, portraitID);

			if (portrait == null)
			{
				FlxG.log.error('Unable to initiate "${portraitID}"');

				return null;
			}

			return portrait;
		}

		return null;
	}

	/**
	 * Clears all loaded dialogue portraits scripted classes.
	 */
	public static function clearPortraits():Void
	{
		if (portraitScriptedClasses != null)
			portraitScriptedClasses.clear();
	}
}
