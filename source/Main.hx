package;

import jta.Game;
import jta.debug.FPS;
import jta.util.WindowUtil;
import jta.util.macro.MacroUtil;
#if windows
import winapi.WindowsAPI;
import hxwindowmode.WindowColorMode;
#end
#if hxgamemode
import hxgamemode.GamemodeClient;
#end
import flixel.util.typeLimit.NextState;
import openfl.events.Event;

/**
 * The main entry point for the game.
 */
@:nullSafety
class Main extends openfl.display.Sprite
{
	/**
	 * The width of the game in pixels (set in `Project.xml`).
	 */
	@:noCompletion
	private static final GAME_WIDTH:Int = Std.parseInt(MacroUtil.getDefine('GAME_WIDTH', '1024')) ?? 1024;

	/**
	 * The height of the game in pixels (set in `Project.xml`).
	 */
	@:noCompletion
	private static final GAME_HEIGHT:Int = Std.parseInt(MacroUtil.getDefine('GAME_HEIGHT', '768')) ?? 768;

	/**
	 * The frame rate of the game, in frames per second (set in `Project.xml`).
	 */
	@:noCompletion
	private static final GAME_FRAMERATE:Int = Std.parseInt(MacroUtil.getDefine('GAME_FPS', '60')) ?? 60;

	/**
	 * The initial state of the game.
	 */
	@:noCompletion
	private static final GAME_INITIAL_STATE:InitialState = () -> new jta.states.Startup();

	/**
	 * Whether to skip the splash screen on startup.
	 */
	@:noCompletion
	private static final GAME_SKIP_SPLASH:Bool = true;

	/**
	 * Whether to start the game in fullscreen mode on desktop.
	 */
	@:noCompletion
	private static final GAME_START_FULLSCREEN:Bool = false;

	/**
	 * The frame rate display.
	 */
	public static var fps:Null<FPS>;

	/**
	 * This will make it so it is run right at startup.
	 */
	@:noCompletion
	private static function __init__():Void
	{
		#if !web
		jta.util.logging.ErrorHandler.initCriticalErrorHandler();
		#end

		#if hxgamemode
		if (GamemodeClient.request_start() != 0)
			Sys.println('Couldn\'t start gamemode (${GamemodeClient.error_string()}), continuing without it');
		else
			Sys.println('Successfully requested gamemode to start');
		#end
	}

	/**
	 * The entry point of the application.
	 */
	public static function main():Void
	{
		#if android
		Sys.setCwd(haxe.io.Path.addTrailingSlash(getAndroidStorageDir()));
		#elseif ios
		Sys.setCwd(haxe.io.Path.addTrailingSlash(openfl.filesystem.File.documentsDirectory.nativePath));
		#end

		#if !web
		jta.util.logging.ErrorHandler.initUncaughtErrorHandler();
		#end

		WindowUtil.init();

		#if FEATURE_DEBUG_TRACY
		WindowUtil.initTracy();
		#end

		#if windows
		WindowsAPI.setWindowRound(WindowRound.DWMWCP_ROUND);
		WindowColorMode.setDarkMode();
		if (WindowColorMode.isWindows10)
			WindowColorMode.redrawWindowHeader();
		WindowsAPI.centerWindow();
		#end

		Lib.current.stage.align = openfl.display.StageAlign.TOP_LEFT;
		Lib.current.stage.quality = openfl.display.StageQuality.LOW;
		Lib.current.stage.scaleMode = openfl.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}

	#if android
	/**
	 * The folder used for `mods/` and `logs/` on Android.
	 * Falls back to the old location if it can't be created or written to.
	 */
	@:nullSafety(Off)
	private static function getAndroidStorageDir():String
	{
		var packageName:String = null;
		try
		{
			packageName = lime.app.Application.current.meta.get('packageName');
		}
		catch (e:Dynamic)
			Sys.println('Couldn\'t read the package name: $e');

		if (packageName == null || packageName.length == 0)
			packageName = 'com.joalor64.jta';

		try
		{
			final mediaDir:String = haxe.io.Path.join([
				extension.androidtools.os.Environment.getExternalStorageDirectory(),
				'Android',
				'media',
				packageName
			]);

			if (!sys.FileSystem.exists(mediaDir))
				sys.FileSystem.createDirectory(mediaDir);

			final testFile:String = haxe.io.Path.join([mediaDir, '.write_test']);
			sys.io.File.saveContent(testFile, '');
			sys.FileSystem.deleteFile(testFile);

			return mediaDir;
		}
		catch (e:Dynamic)
			Sys.println('Can\'t use Android/media for game files ($e), using the app folder instead');

		return
			extension.androidtools.os.Build.VERSION.SDK_INT > 30 ? extension.androidtools.content.Context.getObbDir() : extension.androidtools.content.Context.getExternalFilesDir();
	}
	#end

	/**
	 * Initializes the game and sets up the application.
	 */
	public function new():Void
	{
		#if desktop
		untyped __cpp__('', jta.api.ALSoftConfig);
		#end

		super();

		if (stage != null)
			setupGame();
		else
			addEventListener(Event.ADDED_TO_STAGE, setupGame);
	}

	@:noCompletion
	private function setupGame(?event:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, setupGame);

		#if hxdiscord_rpc
		jta.api.DiscordClient.load();
		#end

		jta.util.CleanupUtil.init();
		jta.util.ResizeUtil.init();

		final game:Game = new Game(GAME_WIDTH, GAME_HEIGHT, GAME_INITIAL_STATE, GAME_FRAMERATE, GAME_FRAMERATE, GAME_SKIP_SPLASH, GAME_START_FULLSCREEN);

		#if debug
		FlxG.log.redirectTraces = true;
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if debug
		jta.util.plugins.MemoryGCPlugin.initialize();
		#end
		jta.util.plugins.EvacuateDebugPlugin.initialize();
		jta.util.plugins.CrashPlugin.initialize();
		jta.util.plugins.ReloadAssetsDebugPlugin.initialize();

		FlxG.debugger.toggleKeys = [F2];

		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		FlxG.sound.muteKeys = [];

		#if FLX_MOUSE
		FlxG.mouse.useSystemCursor = true;
		#end

		#if (desktop || web)
		FlxG.mouse.visible = false;
		#end

		addChild(game);

		fps = new FPS(10, 10, 0xffffff);
		addChild(fps);

		jta.util.FramerateUtil.adjustStageFramerate();

		#if hxgamemode
		Lib.current.stage.application.window.onClose.add(function()
		{
			if (GamemodeClient.request_end() != 0)
				Sys.println('Couldn\'t end gamemode (${GamemodeClient.error_string()})');
		});
		#end
	}
}
