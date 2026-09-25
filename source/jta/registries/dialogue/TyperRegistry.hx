package jta.registries.dialogue;

import jta.objects.dialogue.typers.ScriptedTyper;
import jta.objects.dialogue.typers.Typer;

/**
 * Handles the loading and management of scripted dialogue typer classes.
 */
class TyperRegistry
{
	/**
	 * Map to store associations between dialogue typer IDs and scripted dialogue typer classes.
	 */
	private static final typerScriptedClasses:Map<String, String> = [];

	/**
	 * Loads and initializes scripted dialogue typer classes.
	 */
	public static function loadTypers():Void
	{
		clearTypers();

		final scriptedTypers:Array<String> = ScriptedTyper.listScriptClasses();

		if (scriptedTypers.length > 0)
		{
			FlxG.log.notice('Initiating ${scriptedTypers.length} scripted dialogue typers...');

			for (scriptedTyper in scriptedTypers)
			{
				final typer:Typer = ScriptedTyper.scriptInit(scriptedTyper, 'unknown');

				if (typer == null)
					continue;

				FlxG.log.notice('Initialized dialogue typer "${typer.typerID}"!');

				typerScriptedClasses.set(typer.typerID, scriptedTyper);
			}
		}

		FlxG.log.notice('Successfully loaded ${Lambda.count(typerScriptedClasses)} typer(s)!');
	}

	/**
	 * Fetches a scripted dialogue typer by its ID.
	 * @param typerID The ID of the typer.
	 * @return The typer or null if not found.
	 */
	public static function fetchTyper(typerID:String):Null<Typer>
	{
		if (!typerScriptedClasses.exists(typerID))
		{
			FlxG.log.error('Unable to load "${typerID}", not found in cache');

			return null;
		}

		final typerScriptedClass:Null<String> = typerScriptedClasses.get(typerID);

		if (typerScriptedClass != null)
		{
			final typer:Typer = ScriptedTyper.scriptInit(typerScriptedClass, typerID);

			if (typer == null)
			{
				FlxG.log.error('Unable to initiate "${typerID}"');

				return null;
			}

			return typer;
		}

		return null;
	}

	/**
	 * Clears all loaded dialogue typers scripted classes.
	 */
	public static function clearTypers():Void
	{
		if (typerScriptedClasses != null)
			typerScriptedClasses.clear();
	}
}
