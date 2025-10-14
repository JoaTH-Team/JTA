package jta.modding.module;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import jta.modding.events.CreateEvent;
import jta.modding.events.FocusEvent;
import jta.modding.events.StateSwitchEvent;
import jta.modding.events.UpdateEvent;

/**
 * Base class for all modules in the game.
 * @author Joalor64
 */
class Module implements IFlxDestroyable
{
	/**
	 * The ID of the module.
	 */
	public var moduleID:String;

	/**
	 * Whether the module is enabled.
	 */
	public var enabled:Bool = true;

	/**
	 * The priority of the module.
	 */
	public var priority:Int = 0;

	/**
	 * Initializes the module with an ID.
	 * @param moduleID The ID of the module.
	 */
	public function new(moduleID:String):Void
	{
		this.moduleID = moduleID;
	}

	public function toString():String
		return 'Module(id: $moduleID, enabled: $enabled, priority: $priority)';

	/**
	 * Called when the module is created.
	 * @param event The create event.
	 */
	public function create(event:CreateEvent):Void {}

	/**
	 * Called every frame.
	 * @param elapsed The time elapsed since the last update.
	 * @param event The update event.
	 */
	public function update(event:UpdateEvent):Void {}

	/**
	 * Called before a state switch occurs.
	 * @param event The state switch event.
	 */
	public function onStateSwitchPre(event:StateSwitchEvent):Void {}

	/**
	 * Called after a state switch occurs.
	 * @param event The state switch event.
	 */
	public function onStateSwitchPost(event:StateSwitchEvent):Void {}

	/**
	 * Called when the game regains focus.
	 * @param event The focus event.
	 */
	public function onFocusGained(event:FocusEvent):Void {}

	/**
	 * Called when the game loses focus.
	 * @param event The focus event.
	 */
	public function onFocusLost(event:FocusEvent):Void {}

	/**
	 * Called when the state is destroyed or the module is unloaded.
	 */
	public function destroy():Void {}
}
