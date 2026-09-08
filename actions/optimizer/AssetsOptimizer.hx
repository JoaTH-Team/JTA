package;

import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

class AssetsOptimizer
{
	private static final OXIPNG_COMPRESSION:Int = 4;

	public static function main():Void
	{
		final args:Array<String> = Sys.args();

		if (args == null || args.length <= 0)
			throw 'Usage: AssetsOptimizer <directory>';

		final directory:String = Path.normalize(FileSystem.absolutePath(args[0]));

		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory))
			throw 'Directory not Found: $directory';

		processDirectory(directory);
	}

	public static function processDirectory(directory:String):Void
	{
		for (file in FileSystem.readDirectory(directory))
		{
			final path:String = Path.join([directory, file]);

			if (FileSystem.isDirectory(path))
				processDirectory(path);
			else
			{
				switch (Path.extension(path))
				{
					case 'ogg':
						runCommand(['optivorbis', path, '-']);
					case 'png':
						runCommand([
							'oxipng',
							'-o',
							Std.string(OXIPNG_COMPRESSION),
							'--strip',
							'safe',
							'--alpha',
							path
						]);
				}
			}
		}
	}

	/**
	 * Executes a system command with the provided arguments.
	 * @param args The command and its arguments to be executed.
	 */
	public static function runCommand(args:Array<String>):Void
	{
		final command:String = args.join(' ');

		switch (args[0])
		{
			case 'optivorbis':
				if (command != AnsiColors.cyan(command))
					Sys.println(AnsiColors.cyan(command));
			default:
				if (command != AnsiColors.yellow(command))
					Sys.println(AnsiColors.yellow(command));
		}

		Sys.command(args.shift(), args);
	}
}

/**
 * Utility class for applying ANSI color codes to strings for terminal output.
 * @see https://github.com/andywhite37/hmm/blob/master/src/hmm/utils/AnsiColors.hx
 */
class AnsiColors
{
	/**
	 * Colors the input string red.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function red(input:String):String
	{
		return color(input, Red);
	}

	/**
	 * Colors the input string green.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function green(input:String):String
	{
		return color(input, Green);
	}

	/**
	 * Colors the input string yellow.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function yellow(input:String):String
	{
		return color(input, Yellow);
	}

	/**
	 * Colors the input string blue.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function blue(input:String):String
	{
		return color(input, Blue);
	}

	/**
	 * Colors the input string magenta.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function magenta(input:String):String
	{
		return color(input, Magenta);
	}

	/**
	 * Colors the input string cyan.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function cyan(input:String):String
	{
		return color(input, Cyan);
	}

	/**
	 * Colors the input string gray.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function gray(input:String):String
	{
		return color(input, Gray);
	}

	/**
	 * Colors the input string white.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function white(input:String):String
	{
		return color(input, White);
	}

	/**
	 * Removes any color from the input string.
	 * @param input The input string.
	 * @return The uncolored string.
	 */
	public static inline function none(input:String):String
	{
		return color(input, None);
	}

	/**
	 * Applies the specified ANSI color code to the input string.
	 * @param input The input string.
	 * @param ansiColor The ANSI color code.
	 * @return The colored string.
	 */
	public static inline function color(input:String, ansiColor:AnsiColor):String
	{
		return #if sys '$ansiColor$input${AnsiColor.None}' #else input #end;
	}
}

/**
 * Enum abstract representing ANSI color codes.
 */
enum abstract AnsiColor(String) from String to String
{
	var Black = '\033[0;30m';
	var Red = '\033[0;31m';
	var Green = '\033[0;32m';
	var Yellow = '\033[0;33m';
	var Blue = '\033[0;34m';
	var Magenta = '\033[0;35m';
	var Cyan = '\033[0;36m';
	var Gray = '\033[0;37m';
	var White = '\033[1;37m';
	var None = '\033[0;0m';
}
