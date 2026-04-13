package jta.util.logging;

/**
 * Enum abstract representing ANSI codes for text colors, background colors, and text styles.
 */
#if !web
enum abstract ANSICode(String) from String to String
{
	// Text colors
	var Black = '\\x1b[0;30m';
	var Red = '\\x1b[0;31m';
	var Green = '\\x1b[0;32m';
	var Yellow = '\\x1b[0;33m';
	var Blue = '\\x1b[0;34m';
	var Magenta = '\\x1b[0;35m';
	var Cyan = '\\x1b[0;36m';
	var Gray = '\\x1b[0;37m';
	var White = '\\x1b[1;37m';

	// Background colors
	var BgBlack = '\\x1b[40m';
	var BgRed = '\\x1b[41m';
	var BgGreen = '\\x1b[42m';
	var BgYellow = '\\x1b[43m';
	var BgBlue = '\\x1b[44m';
	var BgMagenta = '\\x1b[45m';
	var BgCyan = '\\x1b[46m';
	var BgWhite = '\\x1b[47m';

	// Text styles
	var Reset = '\\x1b[0m';
	var Bold = '\\x1b[1m';
	var Underline = '\\x1b[4m';
	var Blink = '\\x1b[5m';
	var Inverse = '\\x1b[7m';
	var Hidden = '\\x1b[8m';
}

/**
 * Utility class for applying ANSI codes to strings for terminal output.
 */
class ANSI
{
	/**
	 * Common CI environment variable names used to detect ANSI code support.
	 */
	@:noCompletion
	private static final CI_ENV_NAMES:Array<String> = [
		'GITHUB_ACTIONS',
		'GITEA_ACTIONS',
		'TRAVIS',
		'CIRCLECI',
		'APPVEYOR',
		'GITLAB_CI',
		'BUILDKITE',
		'DRONE'
	];

	/**
	 * Indicates if ANSI code support is available in the terminal.
	 */
	@:noCompletion
	private static var codesSupported:Null<Bool> = null;

	/**
	 * Applies the specified ANSI codes to the input string.
	 * You can pass one or multiple ANSI codes for combining styles.
	 * @param input The input string.
	 * @param codes The ANSI codes to apply.
	 * @return The styled string.
	 */
	public static function apply(input:String, codes:Array<ANSICode>):String
	{
		return stripCodes(codes.join('') + input + ANSICode.Reset);
	}

	/**
	 * Strips ANSI codes from the input string if the terminal doesn't support them.
	 * @param output The string to check for ANSI code support.
	 * @return The string with or without ANSI codes depending on terminal support.
	 */
	@:noCompletion
	private static function stripCodes(output:String):String
	{
		if (codesSupported == null)
		{
			final term:String = Sys.getEnv('TERM');

			if (term == 'dumb')
				codesSupported = false;
			else
			{
				if (Sys.getEnv('CI') != null)
				{
					for (ci in CI_ENV_NAMES)
					{
						if (Sys.getEnv(ci) != null)
						{
							codesSupported = true;
							break;
						}
					}

					if (codesSupported != true && Sys.getEnv('CI_NAME') == 'codeship')
						codesSupported = true;
				}

				if (codesSupported != true && Sys.getEnv('TEAMCITY_VERSION') != null)
					codesSupported = ~/^9\.(0*[1-9]\d*)\.|\d{2,}\./.match(Sys.getEnv('TEAMCITY_VERSION'));

				if (codesSupported != true && term != null)
				{
					codesSupported = ~/(?i)-256(color)?$/.match(term)
						|| ~/(?i)^screen|^xterm|^vt100|^vt220|^rxvt|color|ansi|cygwin|linux/.match(term);
				}

				if (codesSupported != true)
				{
					codesSupported = Sys.getEnv('TERM_PROGRAM') == 'iTerm.app'
						|| Sys.getEnv('TERM_PROGRAM') == 'Apple_Terminal'
						|| Sys.getEnv('COLORTERM') != null
						|| Sys.getEnv('ANSICON') != null
						|| Sys.getEnv('ConEmuANSI') != null
						|| Sys.getEnv('WT_SESSION') != null;
				}
			}
		}

		return codesSupported == true ? output : ~/\x1b\[[0-9;]*m/g.replace(output, '');
	}
}
#end
