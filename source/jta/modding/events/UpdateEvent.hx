package jta.modding.events;

import jta.modding.module.Module;
import jta.modding.module.ModuleEvent;

/**
 * Event issued every frame.
 * @author Joalor64
 */
class UpdateEvent extends ModuleEvent
{
	/**
	 * The time elapsed since the last update.
	 */
	public var elapsed:Float;

	/**
	 * Initializes the update event.
	 * @param module The module this event is issued to.
	 * @param state The current game state.
	 * @param elapsed The time elapsed since the last update.
	 */
	public function new(module:Module, state:String, elapsed:Float):Void
	{
		super(module, state);

		this.elapsed = elapsed;
	}

	override public function toString():String
		return 'UpdateEvent(module: $module, state: $state, elapsed: $elapsed)';
}
