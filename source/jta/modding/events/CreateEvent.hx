package jta.modding.events;

import jta.modding.module.ModuleEvent;

/**
 * Event issued when a module is created.
 * @author Joalor64
 */
class CreateEvent extends ModuleEvent
{
	override public function toString():String
		return 'CreateEvent(module: ${module.moduleID}, state: $state)';
}
