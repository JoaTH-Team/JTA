package jta.api.native;

/**
 * Class for Windows API-related functions.
 */
#if windows
@:buildXml('
    <target id="haxe">
        <lib name="dwmapi.lib" if="windows" />
    </target>
    ')
@:cppFileCode('
    #include <Windows.h>
    #include <cstdio>
    #include <iostream>
    #include <tchar.h>
    #include <dwmapi.h>
    #include <winuser.h>

    #ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
    #define DWMWA_USE_IMMERSIVE_DARK_MODE 20 // support for windows 11
    #endif
    ')
class WindowsAPI
{
	@:functionCode('
        int darkMode = enable ? 1 : 0;
        HWND window = GetActiveWindow();
        if (S_OK != DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE, reinterpret_cast<LPCVOID>(&darkMode), sizeof(darkMode)))
            DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE, reinterpret_cast<LPCVOID>(&darkMode), sizeof(darkMode));
    ')
	public static function setDarkMode(enable:Bool) {}

	/**
	 * Enables or disables dark mode for the current application window.
	 * @param enable Whether to enable or disable dark mode.
	 */
	public static function darkMode(enable:Bool)
	{
		setDarkMode(enable);
		Application.current.window.borderless = true;
		Application.current.window.borderless = false;
	}

	@:functionCode('
        int result = MessageBox(GetActiveWindow(), message, caption, icon | MB_SETFOREGROUND);
    ')
	public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING) {}

	/**
	 * Shows a message box with the specified caption, message, and icon.
	 * @param caption The caption of the message box.
	 * @param message The message to display in the message box.
	 * @param icon The icon to display in the message box.
	 */
	public static function messageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING)
	{
		showMessageBox(caption, message, icon);
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
