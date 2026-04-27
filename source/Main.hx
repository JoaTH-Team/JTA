package;

import jta.Game;
import jta.debug.FPS;
import jta.video.GlobalVideo;
import jta.video.VideoHandler;
import jta.video.WebmHandler;
#if windows
import winapi.WindowsAPI;
import hxwindowmode.WindowColorMode;
#end
#if hxgamemode
import hxgamemode.GamemodeClient;
#end
import flixel.util.typeLimit.NextState;
import openfl.system.System;
import openfl.events.Event;

/**
 * The main entry point for the game.
 */
@:nullSafety
class Main extends openfl.display.Sprite
{
	/**
	 * The width of the game window in pixels.
	 */
	@:noCompletion
	private static final GAME_WIDTH:Int = 1024;

	/**
	 * The height of the game window in pixels.
	 */
	@:noCompletion
	private static final GAME_HEIGHT:Int = 768;

	/**
	 * The frame rate of the game, in frames per second (FPS).
	 */
	@:noCompletion
	private static final GAME_FRAMERATE:Int = 60;

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
	public static var fpsDisplay:Null<FPS>;

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
		{
			Sys.println('Failed to request gamemode start: ${GamemodeClient.error_string()}...');
			System.exit(1);
		}
		else
			Sys.println('Succesfully requested gamemode to start...');
		#end
	}

	/**
	 * The entry point of the application.
	 */
	public static function main():Void
	{
		#if android
		Sys.setCwd(haxe.io.Path.addTrailingSlash(extension.androidtools.os.Build.VERSION.SDK_INT > 30 ? extension.androidtools.content.Context.getObbDir() : extension.androidtools.content.Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(haxe.io.Path.addTrailingSlash(openfl.filesystem.File.documentsDirectory.nativePath));
		#end

		#if !web
		jta.util.logging.ErrorHandler.initUncaughtErrorHandler();
		#end

		jta.util.WindowUtil.init();

		#if windows
		WindowColorMode.setDarkMode();
		WindowColorMode.redrawWindowHeader();

		WindowsAPI.centerWindow();
		#end

		Lib.current.stage.align = openfl.display.StageAlign.TOP_LEFT;
		Lib.current.stage.quality = openfl.display.StageQuality.LOW;
		Lib.current.stage.scaleMode = openfl.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}

	/**
	 * Initializes the game and sets up the application.
	 */
	public function new():Void
	{
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

		#if desktop
		FlxG.mouse.visible = false;
		#end

		addChild(game);

		var vidSource:String = 'assets/videos/DO NOT DELETE OR GAME WILL CRASH/dontDelete.webm';

		#if web
		var str1:String = 'HTML VIDEO';
		var vHandler:VideoHandler = new VideoHandler();
		vHandler.init1();
		vHandler.video.name = str1;
		addChild(vHandler.video);
		vHandler.init2();
		GlobalVideo.setVid(vHandler);
		vHandler.source(vidSource);
		#elseif desktop
		var str1:String = 'WEBM VIDEO';
		var webmHandle:WebmHandler = new WebmHandler();
		webmHandle.source(vidSource);
		webmHandle.makePlayer();
		webmHandle.webm.name = str1;
		addChild(webmHandle.webm);
		GlobalVideo.setWebm(webmHandle);
		#end

		fpsDisplay = new FPS(10, 10, 0xffffff);
		addChild(fpsDisplay);

		jta.util.FramerateUtil.adjustStageFramerate();

		Lib.current.stage.application.window.onClose.add(function()
		{
			#if hxgamemode
			if (GamemodeClient.request_end() != 0)
			{
				Sys.println('Failed to request gamemode end: ${GamemodeClient.error_string()}...');
				System.exit(1);
			}
			else
				Sys.println('Succesfully requested gamemode to end...');
			#end
		});
	}
}
