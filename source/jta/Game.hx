package jta;

import flixel.FlxGame;

/**
 * Custom game class that extends FlxGame, incorporating error handling for various lifecycle events.
 * This class ensures that uncaught errors during the game's execution are handled appropriately
 * by leveraging the stage's error handling mechanisms when enabled.
 */
@:access(openfl.display.Stage)
@:access(openfl.events.UncaughtErrorEvents)
@:nullSafety
class Game extends FlxGame
{
	public override function create(_):Void
	{
		if (stage.__uncaughtErrorEvents.__enabled)
		{
			try
			{
				super.create(_);
			}
			catch (e:Dynamic)
				stage.__handleError(e);
		}
		else
			super.create(_);
	}

	private override function onFocus(_):Void
	{
		if (stage.__uncaughtErrorEvents.__enabled)
		{
			try
			{
				super.onFocus(_);
			}
			catch (e:Dynamic)
				stage.__handleError(e);
		}
		else
			super.onFocus(_);
	}

	private override function onFocusLost(_):Void
	{
		if (stage.__uncaughtErrorEvents.__enabled)
		{
			try
			{
				super.onFocusLost(_);
			}
			catch (e:Dynamic)
				stage.__handleError(e);
		}
		else
			super.onFocusLost(_);
	}

	private override function onEnterFrame(_):Void
	{
		if (stage.__uncaughtErrorEvents.__enabled)
		{
			try
			{
				super.onEnterFrame(_);
			}
			catch (e:Dynamic)
				stage.__handleError(e);
		}
		else
			super.onEnterFrame(_);
	}

	public override function update():Void
	{
		if (stage.__uncaughtErrorEvents.__enabled)
		{
			try
			{
				super.update();
			}
			catch (e:Dynamic)
				stage.__handleError(e);
		}
		else
			super.update();
	}

	private override function draw():Void
	{
		if (stage.__uncaughtErrorEvents.__enabled)
		{
			try
			{
				super.draw();
			}
			catch (e:Dynamic)
				stage.__handleError(e);
		}
		else
			super.draw();
	}

	private override function onResize(_):Void
	{
		if (stage.__uncaughtErrorEvents.__enabled)
		{
			try
			{
				super.onResize(_);
			}
			catch (e:Dynamic)
				stage.__handleError(e);
		}
		else
			super.onResize(_);
	}
}
