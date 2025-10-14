package jta.modding.events;

/**
 * Enum for focus event types.
 */
enum FocusEventType
{
	LOST;
	GAINED;
}

/**
 * Event issued when the game loses or regains focus.
 * @author Joalor64
 */
class FocusEvent
{
	public var focusType:FocusEventType;

	public function new(focusType:FocusEventType):Void
	{
		this.focusType = focusType;
	}

	public function toString():String
		return 'FocusEvent(focusType: $focusType)';
}
