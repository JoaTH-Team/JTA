package jta.modding.events;

/**
 * Base class for events issued to scripted classes.
 * @author Joalor64
 */
class StateEvent
{
	/**
	 * The current game state.
	 */
	public var state:String;

	/**
	 * Initializes the state event.
	 * @param state The current game state.
	 */
	public function new(state:String):Void
	{
		this.state = state;
	}

	public function toString():String
		return 'StateEvent(state: $state)';
}
