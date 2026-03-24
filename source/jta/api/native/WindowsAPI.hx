package jta.api.native;

import lime.app.Application;

/**
 * Class for Windows API-related functions.
 */
#if windows
@:cppFileCode('
    #include <Windows.h>
    ')
class WindowsAPI
{
	@:functionCode('
        int result = MessageBox(GetActiveWindow(), message, caption, icon | MB_SETFOREGROUND);
    ')
	public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING):Void {}

	/**
	 * Shows a message box with the specified caption, message, and icon.
	 * @param caption The caption of the message box.
	 * @param message The message to display in the message box.
	 * @param icon The icon to display in the message box.
	 */
	public static function messageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING):Void
	{
		showMessageBox(caption, message, icon);
	}

	/**
	 * Disables the "Report to Microsoft" dialog that appears when the application crashes.
	 */
	public static function disableErrorReporting():Void
	{
		untyped SetErrorMode(untyped SEM_FAILCRITICALERRORS | untyped SEM_NOGPFAULTERRORBOX);
	}
}

/**
 * Enum for message box icons.
 */
@:enum abstract MessageBoxIcon(Int)
{
	var MSG_ERROR:MessageBoxIcon = 0x00000010;
	var MSG_QUESTION:MessageBoxIcon = 0x00000020;
	var MSG_WARNING:MessageBoxIcon = 0x00000030;
	var MSG_INFORMATION:MessageBoxIcon = 0x00000040;
}
#end
