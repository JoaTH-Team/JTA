package jta.modding;

import polymod.Polymod;
import polymod.format.ParseRules;
import polymod.fs.ZipFileSystem;
import polymod.util.VersionUtil;
import jta.modding.events.FocusEvent;
import jta.modding.events.StateSwitchEvent;
import jta.modding.module.ModuleHandler;
import jta.modding.PolymodErrorHandler;
import jta.util.macro.ClassMacro;
import jta.util.StateUtil;
import jta.util.TimerUtil;
import jta.locale.Locale;
#if sys
import sys.FileSystem;
#end

/**
 * Handles the initialization and management of mods in the game.
 * @see https://github.com/FunkinCrew/Funkin/blob/main/source/funkin/modding/PolymodHandler.hx
 */
@:nullSafety
class PolymodHandler
{
	/**
	 * The root directory for mods.
	 */
	static final MOD_DIR:String =
		#if (REDIRECT_ASSETS_FOLDER && macos)
		'../../../../../../../mods'
		#elseif REDIRECT_ASSETS_FOLDER
		'../../../../mods'
		#else
		'mods'
		#end;

	/**
	 * The core directory for assets.
	 */
	static final CORE_DIR:Null<String> =
		#if (REDIRECT_ASSETS_FOLDER && macos)
		'../../../../../../../assets'
		#elseif REDIRECT_ASSETS_FOLDER
		'../../../../assets'
		#else
		#if desktop
		'assets'
		#else
		null
		#end
		#end;

	/**
	 * The API version of the modding system.
	 */
	static final API_VERSION:String = '0.1.0';

	/**
	 * Stores the metadata of currently loaded mods.
	 */
	public static var trackedMods:Array<ModMetadata> = [];

	/**
	 * Name of the optional Sparrow atlas next to a mod's icon, for animated icons.
	 */
	public static final ICON_XML_FILE:String = '_polymod_icon.xml';

	/**
	 * Whether the module signal handlers were added already (so reloading doesn't add them twice).
	 */
	static var signalsAdded:Bool = false;

	/**
	 * Loads all mods and initializes the Polymod system.
	 * Safe to call again to reload mods (e.g. after changing them in the mod menu).
	 */
	public static function load():Void
	{
		Polymod.clearScripts();
		Polymod.onError = PolymodErrorHandler.onPolymodError;

		if (!signalsAdded)
		{
			signalsAdded = true;
			addSignals();
		}
		else
			Polymod.clearCache();

		buildImports();

		#if sys
		if (!FileSystem.exists(MOD_DIR))
			FileSystem.createDirectory(MOD_DIR);
		#end

		final appVersion:Null<String> = Lib.application.meta?.get('version');
		final versionRule:String = appVersion != null ? '${appVersion.split(".")[0]}.${appVersion.split(".")[1]}.*' : API_VERSION;

		Locale.init(); // Initialize localization before Polymod
		Polymod.init({
			modRoot: MOD_DIR,
			dirs: getMods(),
			framework: OPENFL,
			apiVersionRule: versionRule,
			frameworkParams: {
				coreAssetRedirect: CORE_DIR
			},
			parseRules: getParseRules(),
			useScriptedClasses: true,
			loadScriptsAsync: #if html5 true #else false #end,
			ignoredFiles: buildIgnoreList(),
			extensionMap: ['frag' => TEXT, 'vert' => TEXT],
			customFilesystem: buildFileSystem(),
			firetongue: Locale.tongue
		});

		loadRegistries();
	}

	@:noCompletion
	private static function addSignals():Void
	{
		FlxG.signals.focusGained.add(function()
		{
			ModuleHandler.callEvent(module -> module.onFocusGained(new FocusEvent(FocusEventType.GAINED)));
		});

		FlxG.signals.focusLost.add(function()
		{
			ModuleHandler.callEvent(module -> module.onFocusLost(new FocusEvent(FocusEventType.LOST)));
		});

		FlxG.signals.preStateSwitch.add(function()
		{
			ModuleHandler.callEvent(module -> module.onStateSwitchPre(new StateSwitchEvent(StateUtil.getCurrentState())));
		});

		FlxG.signals.postStateSwitch.add(function()
		{
			ModuleHandler.callEvent(module -> module.onStateSwitchPost(new StateSwitchEvent(StateUtil.getCurrentState())));
		});
	}

	@:noCompletion
	private static function loadRegistries():Void
	{
		final registriesStart:Float = TimerUtil.start();

		jta.registries.dialogue.TyperRegistry.loadTypers();
		jta.registries.dialogue.PortraitRegistry.loadPortraits();

		jta.registries.level.PlayerRegistry.loadPlayers();
		jta.registries.level.ObjectRegistry.loadObjects();

		jta.registries.LevelRegistry.loadLevels();

		jta.registries.ModuleRegistry.loadModules();

		FlxG.log.notice('Registries loading took: ${TimerUtil.seconds(registriesStart)}');
	}

	/**
	 * Scans for mods (filling `trackedMods`, sorted by the saved load order)
	 * and returns the IDs of the enabled ones, in load order.
	 */
	public static function getMods():Array<String>
	{
		trackedMods = [];

		if (FlxG.save.data.disabledMods == null)
		{
			FlxG.save.data.disabledMods = [];
			FlxG.save.flush();
		}

		if (FlxG.save.data.modOrder == null)
		{
			FlxG.save.data.modOrder = [];
			FlxG.save.flush();
		}

		final appVersion:Null<String> = Lib.application.meta?.get('version');
		final versionRule:String = appVersion != null ? '${appVersion.split(".")[0]}.${appVersion.split(".")[1]}.*' : API_VERSION;

		for (i in Polymod.scan({modRoot: MOD_DIR, apiVersionRule: versionRule, errorCallback: PolymodErrorHandler.onPolymodError}))
		{
			if (i != null)
				trackedMods.push(i);
		}

		final order:Array<String> = FlxG.save.data.modOrder;
		final scanOrder:Array<String> = [for (m in trackedMods) m.id];

		trackedMods.sort(function(a:ModMetadata, b:ModMetadata):Int
		{
			final ia:Int = order.indexOf(a.id);
			final ib:Int = order.indexOf(b.id);
			final ka:Int = (ia >= 0) ? ia : order.length + scanOrder.indexOf(a.id);
			final kb:Int = (ib >= 0) ? ib : order.length + scanOrder.indexOf(b.id);
			return ka - kb;
		});

		return [for (m in trackedMods) if (isModEnabled(m.id)) m.id];
	}

	/**
	 * Whether a mod is enabled (mods are enabled unless turned off in the mod menu).
	 * @param id The mod ID.
	 */
	public static function isModEnabled(id:String):Bool
	{
		final disabled:Null<Array<String>> = FlxG.save.data.disabledMods;
		return disabled == null || !disabled.contains(id);
	}

	/**
	 * Saves which mods are enabled and the load order. Call `load()` afterwards to apply it.
	 * @param orderedIds Every mod ID, in load order (first loads first).
	 * @param disabledIds The IDs of the disabled mods.
	 */
	public static function saveModSettings(orderedIds:Array<String>, disabledIds:Array<String>):Void
	{
		FlxG.save.data.modOrder = orderedIds.copy();
		FlxG.save.data.disabledMods = disabledIds.copy();
		FlxG.save.flush();
	}

	/**
	 * Reads a text file from a mod's folder (or zip), e.g. its animated icon's XML.
	 * @param mod The mod.
	 * @param file The file's path inside the mod.
	 * @return The file's contents, or null if it doesn't exist.
	 */
	public static function readModText(mod:ModMetadata, file:String):Null<String>
	{
		#if sys
		final modPath:Null<String> = mod.modPath;
		if (modPath == null)
			return null;

		final path:String = haxe.io.Path.join([modPath, file]);

		try
		{
			final fs = Polymod.getFileSystem();
			if (fs != null && fs.exists(path))
				return fs.getFileContent(path);

			if (FileSystem.exists(path))
				return sys.io.File.getContent(path);
		}
		catch (e:Dynamic)
			trace('Couldn\'t read "$path": $e');
		#end

		return null;
	}

	/**
	 * The full path of the mods folder.
	 */
	public static function getModsFolder():String
	{
		#if sys
		return FileSystem.absolutePath(MOD_DIR);
		#else
		return MOD_DIR;
		#end
	}

	public static function getModIDs():Array<String>
	{
		return (trackedMods.length > 0) ? [for (i in trackedMods) i.id] : [];
	}

	@:noCompletion
	private static inline function buildImports():Void
	{
		Polymod.addImportAlias('flixel.effects.particles.FlxEmitter', flixel.effects.particles.FlxEmitter);
		Polymod.addImportAlias('flixel.group.FlxContainer', flixel.group.FlxContainer);
		Polymod.addImportAlias('flixel.group.FlxGroup', flixel.group.FlxGroup);
		Polymod.addImportAlias('flixel.group.FlxSpriteContainer', flixel.group.FlxSpriteContainer);
		Polymod.addImportAlias('flixel.group.FlxSpriteGroup', flixel.group.FlxSpriteGroup);
		Polymod.addImportAlias('flixel.math.FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
		Polymod.addImportAlias('lime.utils.Assets', jta.Assets);
		Polymod.addImportAlias('openfl.utils.Assets', jta.Assets);
		Polymod.addImportAlias('Reflect', jta.util.ReflectUtil);
		Polymod.addImportAlias('Type', jta.util.ReflectUtil);

		#if cpp
		Polymod.blacklistImport('cpp.Lib');
		#end
		Polymod.blacklistImport('haxe.Http');
		Polymod.blacklistImport('haxe.Serializer');
		Polymod.blacklistImport('haxe.Unserializer');
		Polymod.blacklistImport('lime.system.CFFI');
		Polymod.blacklistImport('lime.system.System');
		Polymod.blacklistImport('lime.system.JNI');
		Polymod.blacklistImport('lime.utils.AssetLibrary');
		Polymod.blacklistImport('lime.utils.Assets');
		Polymod.blacklistImport('openfl.Lib');
		Polymod.blacklistImport('openfl.desktop.NativeProcess');
		Polymod.blacklistImport('openfl.utils.Assets');
		Polymod.blacklistImport('Sys');

		Polymod.blacklistStaticFields(flixel.util.FlxSave, ['resolveFlixelClasses']);
		Polymod.blacklistStaticFields(flixel.FlxG, ['save']);

		Polymod.blacklistStaticFields(haxe.Unserializer, ['run']);
		Polymod.blacklistInstanceFields(haxe.Unserializer, ['unserialize']);

		#if !html5
		Polymod.blacklistInstanceFields(openfl.filesystem.FileStream, ['readObject']);
		#end
		Polymod.blacklistInstanceFields(openfl.net.Socket, ['readObject']);
		Polymod.blacklistInstanceFields(openfl.utils.ByteArray.ByteArrayData, ['readObject']);

		for (cls in ClassMacro.listClassesInPackage('jta.util.macro'))
		{
			if (cls == null)
				continue;

			Polymod.blacklistImport(Type.getClassName(cls));
		}

		for (cls in ClassMacro.listClassesInPackage('extension.androidtools'))
		{
			if (cls == null)
				continue;

			Polymod.blacklistImport(Type.getClassName(cls));
		}

		for (cls in ClassMacro.listClassesInPackage('polymod'))
		{
			if (cls == null)
				continue;

			Polymod.blacklistImport(Type.getClassName(cls));
		}

		for (cls in ClassMacro.listClassesInPackage('hscript'))
		{
			if (cls == null)
				continue;

			Polymod.blacklistImport(Type.getClassName(cls));
		}

		#if sys
		for (cls in ClassMacro.listClassesInPackage('sys'))
		{
			if (cls == null)
				continue;

			Polymod.blacklistImport(Type.getClassName(cls));
		}
		#end

		Polymod.blacklistInstanceFields(polymod.hscript._internal.PolymodScriptClass.PolymodScriptClass, ['_interp']);
	}

	@:noCompletion
	private static inline function buildFileSystem():ZipFileSystem
	{
		return new ZipFileSystem({modRoot: MOD_DIR, autoScan: true});
	}

	@:noCompletion
	private static function buildIgnoreList():Array<String>
	{
		var result:Array<String> = Polymod.getDefaultIgnoreList();

		result.push('.vscode');
		result.push('.idea');
		result.push('.git');
		result.push('.gitignore');
		result.push('.gitattributes');
		result.push('README.md');
		result.push(ICON_XML_FILE);

		return result;
	}

	@:noCompletion
	private static function getParseRules():ParseRules
	{
		final output:ParseRules = ParseRules.getDefault();
		output.addType('txt', TextFileFormat.LINES);
		output.addType('json', TextFileFormat.JSON);
		output.addType('hscript', TextFileFormat.PLAINTEXT);
		output.addType('hxs', TextFileFormat.PLAINTEXT);
		output.addType('hxc', TextFileFormat.PLAINTEXT);
		output.addType('hx', TextFileFormat.PLAINTEXT);
		return output;
	}
}
