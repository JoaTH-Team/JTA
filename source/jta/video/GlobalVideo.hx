package jta.video;

import jta.video.WebmHandler;
import jta.video.VideoHandler;
import jta.video.GameDimensions;
import openfl.display.DisplayObject;

/**
 * Holds the desktop (WebM) or web (HTML) video player, which is shared by every `VideoState`.
 * Mobile uses the system's video player instead (see `VideoState`).
 */
class GlobalVideo
{
	private static var video:VideoHandler;
	private static var webm:WebmHandler;

	public static var isWebm:Bool = false;

	public static var daAlpha1:Float = 0.2;
	public static var daAlpha2:Float = 1;

	/**
	 * Creates the video player if it hasn't been yet. Called by `VideoState` before playing a video,
	 * so the game doesn't need to load a placeholder video on startup.
	 * @param path The first video to play (the WebM player needs a file to start with).
	 */
	public static function init(path:String):Void
	{
		#if web
		if (video != null)
			return;

		final handler:VideoHandler = new VideoHandler();
		handler.init1();
		handler.video.name = 'HTML VIDEO';
		addToStage(handler.video);
		handler.init2();
		setVid(handler);
		#elseif desktop
		if (webm != null)
			return;

		final handler:WebmHandler = new WebmHandler();
		handler.source(path);
		handler.makePlayer();
		handler.webm.name = 'WEBM VIDEO';
		addToStage(handler.webm);
		setWebm(handler);
		#end
	}

	/**
	 * Adds the player right above the game (and under the FPS counter).
	 */
	static function addToStage(object:DisplayObject):Void
	{
		final parent = FlxG.game.parent;
		if (parent != null)
			parent.addChildAt(object, parent.getChildIndex(FlxG.game) + 1);
		else
			Lib.current.addChild(object);
	}

	public static function setVid(vid:VideoHandler):Void
	{
		video = vid;
	}

	public static function getVid():VideoHandler
	{
		return video;
	}

	public static function setWebm(vid:WebmHandler):Void
	{
		webm = vid;
		isWebm = true;
	}

	public static function getWebm():WebmHandler
	{
		return webm;
	}

	public static function get():Dynamic
	{
		return (isWebm) ? getWebm() : getVid();
	}

	public static function calc(ind:Int):Dynamic
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		var width:Float = GameDimensions.width;
		var height:Float = GameDimensions.height;

		var ratioX:Float = height / width;
		var ratioY:Float = width / height;
		var appliedWidth:Float = stageHeight * ratioY;
		var appliedHeight:Float = stageWidth * ratioX;

		var remainingX:Float = stageWidth - appliedWidth;
		var remainingY:Float = stageHeight - appliedHeight;
		remainingX = remainingX / 2;
		remainingY = remainingY / 2;

		appliedWidth = Std.int(appliedWidth);
		appliedHeight = Std.int(appliedHeight);

		if (appliedHeight > stageHeight)
		{
			remainingY = 0;
			appliedHeight = stageHeight;
		}

		if (appliedWidth > stageWidth)
		{
			remainingX = 0;
			appliedWidth = stageWidth;
		}

		switch (ind)
		{
			case 0:
				return remainingX;
			case 1:
				return remainingY;
			case 2:
				return appliedWidth;
			case 3:
				return appliedHeight;
		}

		return null;
	}
}
