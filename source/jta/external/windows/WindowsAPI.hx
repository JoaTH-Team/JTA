package jta.external.windows;

/**
 * Class for Windows API-related functions.
 */
#if windows
@:cppFileCode('
    #include <Windows.h>
    ')
class WindowsAPI
{
	/**
	 * Shows a message box with an error icon.
	 * @param message The message to display.
	 * @param title The title of the message box.
	 * @return The result of the message box interaction.
	 */
	public static function showError(title:cpp.ConstCharStar, message:cpp.ConstCharStar):Int
	{
		return untyped MessageBox(null, message, title, untyped MB_OK | untyped MB_ICONERROR);
	}

	/**
	 * Shows a message box with a warning icon.
	 * @param message The message to display.
	 * @param title The title of the message box.
	 * @return The result of the message box interaction.
	 */
	public static function showWarning(title:cpp.ConstCharStar, message:cpp.ConstCharStar):Int
	{
		return untyped MessageBox(null, message, title, untyped MB_OK | untyped MB_ICONWARNING);
	}

	/**
	 * Shows a message box with an information icon.
	 * @param message The message to display.
	 * @param title The title of the message box.
	 * @return The result of the message box interaction.
	 */
	public static function showInformation(title:cpp.ConstCharStar, message:cpp.ConstCharStar):Int
	{
		return untyped MessageBox(null, message, title, untyped MB_OK | untyped MB_ICONINFORMATION);
	}

	/**
	 * Shows a message box with a question icon.
	 * @param message The message to display.
	 * @param title The title of the message box.
	 * @return The result of the message box interaction.
	 */
	public static function showQuestion(title:cpp.ConstCharStar, message:cpp.ConstCharStar):Int
	{
		return untyped MessageBox(null, message, title, untyped MB_OKCANCEL | untyped MB_ICONQUESTION);
	}

	/**
	 * Disables the "Report to Microsoft" dialog that appears when the application crashes.
	 */
	public static function disableErrorReporting():Void
	{
		untyped SetErrorMode(untyped SEM_FAILCRITICALERRORS | untyped SEM_NOGPFAULTERRORBOX);
	}
}
#end
