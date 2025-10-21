package jta.modding.module;

import haxe.Exception;
import jta.modding.module.Module;
import jta.registries.ModuleRegistry;

/**
 * Handles module-related operations.
 * @author Joalor64
 */
class ModuleHandler
{
	/**
	 * Fetches a module by its ID.
	 * @param id The ID of the module.
	 * @return The module with the given ID, or null if not found.
	 */
	public static function getModule(id:String):Null<Module>
	{
		return ModuleRegistry.fetchModule(id);
	}

	/**
	 * Calls a callback for each loaded module.
	 * @param callback The callback to call for each module.
	 */
	public static function callEvent(callback:Module->Void):Void
	{
		if (callback == null)
			return;

		for (module in ModuleRegistry.getLoadedModules())
		{
			if (module == null)
				continue;
			if (!module.enabled)
				continue;

			try
			{
				callback(module);
			}
			catch (e:Exception)
				FlxG.log.error('ModuleHandler: error in module ${module.moduleID}: ${Std.string(e.message)}');
		}
	}
}
