package jta.modding.module;

import jta.modding.events.StateEvent;
import jta.modding.module.Module;

/**
 * Base class for events issued to modules.
 * @author Joalor64
 */
class ModuleEvent extends StateEvent
{
	/**
	 * The module this event is issued to.
	 */
	public var module:Module;

	/**
	 * Initializes the module event.
	 * @param module The module this event is issued to.
	 * @param state The current game state.
	 */
	public function new(module:Module, state:String):Void
	{
		super(state);

		this.module = module;
	}

	override public function toString():String
		return 'ModuleEvent(module: ${module.moduleID}, state: $state)';
}
