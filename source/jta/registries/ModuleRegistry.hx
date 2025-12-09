package jta.registries;

import jta.modding.module.Module;
import jta.modding.module.ScriptedModule;

/**
 * Handles the loading and management of module classes used in game states.
 */
class ModuleRegistry
{
	/**
	 * Map to store associations between module IDs and their classes.
	 */
	private static final moduleClasses:Map<String, Module> = [];

	/**
	 * Loads and initializes all available modules.
	 */
	public static function loadModules():Void
	{
		clearModules();

		final moduleList:Array<String> = ScriptedModule.listScriptClasses();

		if (moduleList.length > 0)
		{
			FlxG.log.notice('Loading ${moduleList.length} modules...');

			for (moduleID in moduleList)
			{
				final module:Module = ScriptedModule.init(moduleID, 'unknown');

				if (module == null)
					continue;

				FlxG.log.notice('Initialized module "${module.moduleID}"!');

				moduleClasses.set(module.moduleID, module);
			}
		}

		FlxG.log.notice('Successfully loaded ${Lambda.count(moduleClasses)} module(s)!');
	}

	/**
	 * Gets a module by its ID.
	 * @param moduleID The ID of the module.
	 * @return The module instance or null if not found.
	 */
	public static function fetchModule(moduleID:String):Null<Module>
	{
		if (!moduleClasses.exists(moduleID))
		{
			FlxG.log.error('Module "${moduleID}" not found in registry!');
			return null;
		}

		final moduleClass:Null<String> = moduleClasses.get(moduleID);

		if (moduleClass != null)
		{
			final module:Module = ScriptedModule.init(moduleClass, moduleID);

			if (module == null)
			{
				FlxG.log.error('Unable to initiate module "${moduleID}"');

				return null;
			}

			return module;
		}

		return null;
	}

	/**
	 * Returns a sorted array of loaded modules ordered by priority.
	 * @return An array of loaded modules sorted by priority.
	 */
	public static function getLoadedModules():Array<Module>
	{
		var arr:Array<Module> = [];
		for (k in moduleClasses.keys())
		{
			var m = moduleClasses.get(k);
			if (m != null)
				arr.push(m);
		}
		arr.sort(function(a:Module, b:Module) return a.priority - b.priority);
		return arr;
	}

	/**
	 * Clears the registry of loaded modules.
	 */
	public static function clearModules():Void
	{
		if (moduleClasses != null)
			moduleClasses.clear();
	}
}
