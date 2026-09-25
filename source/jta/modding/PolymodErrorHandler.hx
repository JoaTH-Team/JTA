package jta.modding;

import polymod.Polymod.PolymodError;
import flixel.util.FlxStringUtil;
#if (windows && cpp)
import jta.external.windows.WindowsAPI;
#end
import jta.util.WindowUtil;
import openfl.Lib;

@:nullSafety
class PolymodErrorHandler
{
	public static function onPolymodError(error:PolymodError):Void
	{
		switch (error.code)
		{
			case MOD_MISSING_DIRECTORY:
				trace('(WARNING)' + 'Tried to load a mod that was not installed: ${error.message}');
				WindowUtil.showAlert('Mod Load Error', error.message);

			case MOD_MISSING_ID:
				trace('(WARNING)' + ' Tried to load a mod that was not installed: ${error.message}');
				WindowUtil.showAlert('Mod Load Error', error.message);

			case MOD_MISSING_METADATA:
				trace('(ERROR)' + ' Tried to load a mod with no metadata: ${error.message}');

			case MOD_METADATA_PARSE_FAILED:
				trace('(ERROR)' + ' Failed to parse mod metadata: ${error.message}');
				WindowUtil.showAlert('Mod Metadata Parse Error', error.message);

			case MOD_VERSION_PARSE_FAILED:
				trace('(ERROR)' + ' Failed to parse mod version: ${error.message}');
				WindowUtil.showAlert('Mod Version Parse Error', error.message);

			case MOD_API_VERSION_PARSE_FAILED:
				trace('(ERROR)' + ' Failed to parse mod API version: ${error.message}');
				WindowUtil.showAlert('Mod API Version Parse Error', error.message);

			case MOD_MISSING_ICON:
				trace('(WARNING)' + ' A mod is missing an icon: ${error.message}');

			case MOD_API_VERSION_MISMATCH:
				trace('(WARNING)' + ' Failed to load mod - ${error.message}');

				var regex:EReg = ~/Mod "([-_a-zA-Z0-9]+)" is not compatible with API version "(.*?)", got "(.*?)"/;
				if (regex.match(error.message))
				{
					var modId:String = regex.matched(1);
					var modVersion:String = regex.matched(3);

					var gameVersion:String = Lib.application.meta.get('version') ?? 'Unknown';
					var message:String = 'Installed mod "$modId" was built for modding version "v$modVersion". It is not compatible with game version ${gameVersion}, and must be skipped.'
						+ '\n\nPlease inform the mod developer that "$modId" must be updated for compatibility.';

					WindowUtil.showAlert('Mod Outdated', message);
				}
				else
				{
					WindowUtil.showAlert('Mod Outdated', error.message);
				}

			case MOD_LOAD_FAILED:
				trace('(WARNING)' + ' Failed to load mod - ${error.message}');

			case MOD_LOAD_DONE:
				trace('(INFO)' + ' Loaded mod - ${error.message}');

			case MOD_OPTIONAL_DEPENDENCY_UNMET:
				trace('(INFO)' + ' Installed mod is missing an optional dependency: ${error.message}');

			case MOD_DEPENDENCY_UNMET:
				switch (error.origin)
				{
					case SCAN:
						trace('(WARNING)' + ' Installed mod is missing a dependency: ${error.message}');
						WindowUtil.showAlert('Mod Dependency Error', error.message);
					default:
						trace('(ERROR)' + ' Failed to load mod due to missing dependency: ${error.message}');
						WindowUtil.showAlert('Mod Dependency Error', error.message);
				}

			case MOD_DEPENDENCY_VERSION_MISMATCH:
				switch (error.origin)
				{
					case SCAN:
						trace('(WARNING)' + ' Installed mod has a mismatched dependency: ${error.message}');
						WindowUtil.showAlert('Mod Dependency Error', error.message);
					default:
						trace('(ERROR)' + ' Failed to load mod due to mismatched dependency: ${error.message}');
						WindowUtil.showAlert('Mod Dependency Error', error.message);
				}

			case MOD_DEPENDENCY_CYCLICAL:
				trace('(ERROR)' + ' Failed to load mod due to cyclical dependency: ${error.message}');
				WindowUtil.showAlert('Mod Dependency Error', error.message);

			case SCRIPT_PARSE_FAILED:
				trace('(ERROR)' + ' ' + error.message);
				WindowUtil.showAlert('Script Parsing Error', error.message);

			case SCRIPT_RUNTIME_EXCEPTION:
				trace('(ERROR)' + ' ' + error.message);
				WindowUtil.showAlert('Script Exception', error.message);

			case SCRIPTED_CLASS_NOT_REGISTERED:
				trace('(ERROR)' + ' ' + error.message);
				WindowUtil.showAlert('Script Parsing Error', error.message);

			case SCRIPTED_CLASS_ALREADY_REGISTERED:
				trace('(ERROR)' + ' ' + error.message);
				WindowUtil.showAlert('Script Parsing Error', error.message);

			case SCRIPTED_CLASS_REDUNDANT_IMPORT:
				trace('(WARNING)' + ' ' + error.message);

			case SCRIPTED_CLASS_UNRESOLVED_IMPORT:
				trace('(ERROR)' + ' ' + error.message);
				WindowUtil.showAlert('Script Import Error', error.message);

			case SCRIPTED_CLASS_BLACKLISTED_MODULE:
				trace('(ERROR)' + ' ' + error.message);
				WindowUtil.showAlert('Script Blacklist Violation', error.message);

			case SCRIPTED_CLASS_BLACKLISTED_FIELD:
				trace('(ERROR)' + ' ' + error.message);
				WindowUtil.showAlert('Script Blacklist Violation', error.message);

			case FRAMEWORK_INIT, MOD_DEPENDENCY_CHECK_SKIPPED, SCRIPT_PARSE_START, SCRIPT_PARSE_DONE:
				return;

			default:
				var code:String = FlxStringUtil.toTitleCase(Std.string(error.code).split('_').join(' '));
				switch (error.severity)
				{
					case ERROR:
						FlxG.log.error('($code) ${error.message}');

						#if (windows && cpp)
						WindowsAPI.showError(code, error.message);
						#else
						WindowUtil.showAlert(code, error.message);
						#end
					case WARNING:
						FlxG.log.warn('($code) ${error.message}');

						#if (windows && debug && cpp)
						WindowsAPI.showWarning(code, error.message);
						#elseif debug
						WindowUtil.showAlert(code, error.message);
						#end
					case INFO:
						FlxG.log.notice('($code) ${error.message}');
					case DEBUG:
						trace('($code) ${error.message}');
				}
		}
	}
}
