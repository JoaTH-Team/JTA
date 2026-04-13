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
			if (!saveLog(log.join('\n')))
				log.push('The logging file hasn\'t been saved.');
			#end
		}

		Sys.println(ANSI.apply(log.join('\n'), [Bold, Red]));

		#if (windows && cpp)
		WindowsAPI.showError('Uncaught Error', log.join('\n'));
		#else
		WindowUtil.showAlert('Uncaught Error', log.join('\n'));
		#end

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
		if (!saveLog(log.join('\n')))
			log.push('The logging file hasn\'t been saved.');
		#end

		Sys.println(ANSI.apply(log.join('\n'), [Bold, Red]));

		#if (windows && cpp)
		WindowsAPI.showError('Critical Error', log.join('\n'));
		#else
		WindowUtil.showAlert('Critical Error', log.join('\n'));
		#end

		System.exit(1);
	}
	#end

	#if sys
	@:noCompletion
	private static function saveLog(msg:String):Bool
	{
		try
		{
			if (!FileSystem.exists(LOGS_ROOT))
				FileSystem.createDirectory(LOGS_ROOT);

			final formattedData:Null<String> = DateUtil.getFormattedDateTimeForFile();

			if (formattedData != null)
			{
				final filename:String = 'crash-$formattedData.log';

				File.saveContent('$LOGS_ROOT/$filename', msg);

				return true;
			}

			return false;
		}
		catch (e:Exception)
			return false;
	}
	#end
}
#end
