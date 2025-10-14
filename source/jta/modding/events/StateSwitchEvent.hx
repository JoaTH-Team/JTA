package jta.modding.events;

import jta.modding.events.StateEvent;

/**
 * Event issued when the game state switches.
 * @author Joalor64
 */
class StateSwitchEvent extends StateEvent
{
	override public function toString():String
		return 'StateSwitchEvent(state: $state)';
}
