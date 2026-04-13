package jta.api;

#if hxdiscord_rpc
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import sys.thread.Thread;

/**
 * Class to handle Discord Rich Presence integration.
 */
@:nullSafety(Off)
class DiscordClient
{
	/**
	 * If Discord Rich Presence has been initialized.
	 */
	public static var initialized(default, null):Bool = false;

	/**
	 * Whether the thread is running or not;
	 */
	@:noCompletion
	private static var deamonThreadRunning:Bool = false;

	/**
	 * The default Discord Client ID.
	 */
	@:noCompletion
	private static final _defaultID:String = '1390837442701168730';

	public static var clientID(default, set):String = _defaultID;

	private static function set_clientID(newID:String):String
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if (change && initialized)
		{
			shutdown();
			load();
			changePresence();
		}
		return newID;
	}

	/**
	 * Initializes Discord Rich Presence.
	 *
	 * Sets up the Discord Rich Presence, starts a background thread for updates,
	 * and ensures proper shutdown on application exit.
	 */
	public static function load():Void
	{
		if (initialized)
			return;

		final handlers:DiscordEventHandlers = new DiscordEventHandlers();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(handlers), false, null);

		if (!deamonThreadRunning)
		{
			deamonThreadRunning = true;

			EntryPoint.addThread(function():Void
			{
				while (deamonThreadRunning)
				{
					#if DISCORD_DISABLE_IO_THREAD
					Discord.UpdateConnection();
					#end

					Discord.RunCallbacks();

					Sys.sleep(2);
				}
			});
		}

		if (Lib.application != null && !Lib.application.onExit.has(shutdown))
			Lib.application.onExit.add(shutdown);

		initialized = true;
	}

	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool,
			?endTimestamp:Float):Void
	{
		final discordPresence:DiscordRichPresence = new DiscordRichPresence();
		var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
			endTimestamp = startTimestamp + endTimestamp;

		discordPresence.details = details;

		if (state != null)
			discordPresence.state = state;

		discordPresence.largeImageKey = 'icon';
		discordPresence.largeImageText = 'Journey Through Aubekhia';
		discordPresence.smallImageKey = smallImageKey;
		discordPresence.startTimestamp = Std.int(startTimestamp / 1000);
		discordPresence.endTimestamp = Std.int(endTimestamp / 1000);
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
	}

	@:noCompletion
	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		final username:String = request[0].username;

		final discriminator:Int = Std.parseInt(request[0].discriminator);

		if (discriminator != 0)
			FlxG.log.notice('(Discord) Connected to User "$username#$discriminator"');
		else
			FlxG.log.notice('(Discord) Connected to User "$username"');

		changePresence('Just Started');
	}

	public static function resetClientID():Void
	{
		clientID = _defaultID;
	}

	@:noCompletion
	private static function shutdown(exitCode:Int):Void
	{
		if (!initialized)
			return;
		deamonThreadRunning = false;
		initialized = false;
		Discord.Shutdown();
	}

	@:noCompletion
	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		FlxG.log.notice('(Discord) Disconnected ($errorCode: $message)');
	}

	@:noCompletion
	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		FlxG.log.notice('(Discord) Error ($errorCode: $message)');
	}
}
#end
