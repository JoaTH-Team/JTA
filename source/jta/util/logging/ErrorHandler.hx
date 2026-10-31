package jta.util.logging;

#if !web
import haxe.CallStack;
import haxe.Exception;
import openfl.events.ErrorEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.system.System;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import jta.util.logging.ANSI;
#if (windows && cpp)
import jta.external.windows.WindowsAPI;
#end
import jta.util.DateUtil;
import jta.util.WindowUtil;

/**
 * Error handler utility class for handling uncaught errors and critical errors.
 */
class ErrorHandler
{
	/**
	 * The root directory where log files will be saved.
	 */
	@:noCompletion
	private static final LOGS_ROOT:String = 'logs';

	/**
	 * Initializes the error handler by setting up the necessary error listeners.
	 */
	public static function initUncaughtErrorHandler():Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
	}

	/**
	 * Initializes the error handler by setting up the necessary error listeners.
	 */
	public static function initCriticalErrorHandler():Void
	{
		#if (windows && cpp)
		WindowsAPI.disableErrorReporting();
		#end

		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
		#end
	}

	@:noCompletion
	private static inline function onUncaughtError(event:UncaughtErrorEvent):Void
	{
		event.preventDefault();
		event.stopImmediatePropagation();

		final log:Array<String> = [];

		if (Std.isOfType(event.error, ErrorEvent))
		{
			final error:ErrorEvent = cast(event.error, ErrorEvent);

			log.push(error.text);
		}
		else
		{
			if (Std.isOfType(event.error, String))
				log.push(event.error);
			else
				log.push(Std.string(event.error));

			#if HXCPP_STACK_TRACE
			log.push(CallStack.toString(CallStack.exceptionStack(true)));
			#end

			#if sys
			pushLogLocation(log, saveLog(log.join('\n')));
			#end
		}

		Sys.println(ANSI.apply(log.join('\n'), [Bold, Red]));

		showErrorAndExit('Uncaught Error', log.join('\n'));

		System.exit(1);
	}

	#if cpp
	@:noCompletion
	private static inline function onCriticalError(message:String):Void
	{
		final log:Array<String> = [];

		if (message != null && message.length > 0)
			log.push(message);

		#if HXCPP_STACK_TRACE
		log.push(CallStack.toString(CallStack.exceptionStack(true)));
		#end

		#if sys
		pushLogLocation(log, saveLog(log.join('\n')));
		#end

		Sys.println(ANSI.apply(log.join('\n'), [Bold, Red]));

		#if (windows && cpp)
		WindowsAPI.showError('Critical Error', log.join('\n'));
		#else
		WindowUtil.showAlert('Critical Error', log.join('\n'));
		#end

		showErrorAndExit('Critical Error', log.join('\n'));
	}
	#end

	/**
	 * Shows the error popup, then closes the game.
	 *
	 * On Android the popup is asynchronous, so closing straight away would kill
	 * the app before the player ever sees it. There, the game closes when the
	 * player taps OK instead.
	 */
	@:noCompletion
	private static function showErrorAndExit(title:String, message:String):Void
	{
		#if (windows && cpp)
		WindowsAPI.showError(title, message);
		System.exit(1);
		#elseif android
		extension.androidtools.Tools.showAlertDialog(title, message, {name: 'OK', func: () -> System.exit(1)});
		WindowUtil.showAlert(title, message);
		System.exit(1);
		#end
	}

	#if sys
	/**
	 * Adds a line telling the player where the crash log was saved
	 * (as a full path, since on phones it's not obvious where "logs" is).
	 */
	@:noCompletion
	private static function pushLogLocation(log:Array<String>, savedPath:Null<String>):Void
	{
		if (savedPath == null)
		{
			log.push('The logging file hasn\'t been saved.');
			return;
		}

		var fullPath:String = savedPath;
		try
		{
			fullPath = FileSystem.fullPath(savedPath);
		}
		catch (e:Exception) {}

		log.push('');
		log.push('Crash log saved to:');
		log.push(fullPath);
	}

	/**
	 * Saves the crash log.
	 * @return The path of the saved log, or `null` if it couldn't be saved.
	 */
	@:noCompletion
	private static function saveLog(msg:String):Null<String>
	{
		try
		{
			if (!FileSystem.exists(LOGS_ROOT))
				FileSystem.createDirectory(LOGS_ROOT);

			final formattedData:Null<String> = DateUtil.getFormattedDateTimeForFile();

			if (formattedData != null)
			{
				final filename:String = 'crash-$formattedData.log';

				final path:String = '$LOGS_ROOT/$filename';
				File.saveContent(path, msg);

				return path;
			}

			return null;
		}
		catch (e:Exception)
			return null;
	}
	#end
}
#end
