package jta.registries.level;

import jta.objects.level.Object;
import jta.objects.level.ScriptedObject;

/**
 * Handles the loading and management of scripted level object classes.
 */
class ObjectRegistry
{
	/**
	 * Map to store associations between level object IDs and scripted level object classes.
	 */
	private static final objectScriptedClasses:Map<String, String> = [];

	/**
	 * Loads and initializes scripted level object classes.
	 */
	public static function loadObjects():Void
	{
		clearObjects();

		final scriptedObjects:Array<String> = ScriptedObject.listScriptClasses();

		if (scriptedObjects.length > 0)
		{
			FlxG.log.notice('Initiating ${scriptedObjects.length} scripted objects...');

			for (scriptedObject in scriptedObjects)
			{
				final object:Object = ScriptedObject.scriptInit(scriptedObject, 'unknown');

				if (object == null)
					continue;

				FlxG.log.notice('Initialized object "${object.objectID}"!');

				objectScriptedClasses.set(object.objectID, scriptedObject);
			}
		}

		FlxG.log.notice('Successfully loaded ${Lambda.count(objectScriptedClasses)} object(s)!');
	}

	/**
	 * Fetches a scripted level object by its ID.
	 * @param objectID The ID of the object.
	 * @return The object or null if not found.
	 */
	public static function fetchObject(objectID:String):Null<Object>
	{
		if (!objectScriptedClasses.exists(objectID))
		{
			FlxG.log.error('Unable to load "${objectID}", not found in cache');

			return null;
		}

		final objectScriptedClass:Null<String> = objectScriptedClasses.get(objectID);

		if (objectScriptedClass != null)
		{
			final object:Object = ScriptedObject.scriptInit(objectScriptedClass, objectID);

			if (object == null)
			{
				FlxG.log.error('Unable to initiate "${objectID}"');

				return null;
			}

			return object;
		}

		return null;
	}

	/**
	 * Clears all loaded level objects scripted classes.
	 */
	public static function clearObjects():Void
	{
		if (objectScriptedClasses != null)
			objectScriptedClasses.clear();
	}
}
