package jta.util.github;

import haxe.Exception;
import haxe.Http;
import haxe.Json;
import lime.net.HTTPRequest;
import openfl.display.BitmapData;

/**
 * Represents a GitHub contributor.
 */
typedef Contributor =
{
	login:String,
	id:Int,
	node_id:String,
	avatar_url:String,
	gravatar_id:String,
	url:String,
	html_url:String,
	followers_url:String,
	following_url:String,
	gists_url:String,
	starred_url:String,
	subscriptions_url:String,
	organizations_url:String,
	repos_url:String,
	events_url:String,
	received_events_url:String,
	type:String,
	site_admin:Bool,
	contributions:Int
}

/**
 * Utility class for interacting with the GitHub API.
 */
class GitHubUtil
{
	/**
	 * The GitHub username for the repository owner.
	 */
	@:noCompletion
	private static final USER:String = 'JoaTH-Team';

	/**
	 * The name of the GitHub repository.
	 */
	@:noCompletion
	private static final REPOSITORY:String = 'JTA';

	/**
	 * Retrieves the list of contributors for the specified GitHub repository.
	 * @return An array of Contributor objects representing the contributors.
	 * @throws Exception if there is an error while fetching the contributors.
	 */
	public static inline function getContributors():Array<Contributor>
	{
		var contributors:Array<Contributor> = [];

		try
		{
			var http:Http = new Http('https://api.github.com/repos/$USER/$REPOSITORY/contributors');
			http.setHeader('User-Agent', 'JTA v${Lib.application.meta['version']}');
			http.onStatus = function(status:Int):Void
			{
				if (status >= 300 && status < 400)
				{
					final responseLocation:Null<String> = http.responseHeaders.get('Location');

					if (responseLocation != null)
					{
						http.url = responseLocation;
						http.request(false);
					}
					else
						throw 'Redirect location header missing';
				}
			}
			http.onData = function(data:String):Void
			{
				if (data != null && data.length > 0)
					contributors = Json.parse(data.trim());
			}
			http.onError = (message:String) -> throw message;
			http.request(false);
		}
		catch (e:Exception)
			FlxG.log.error('Error while trying to get the contributors: ${e.message}');

		return contributors;
	}

	/**
	 * Fetches the contributors in the background and calls `onComplete` with them when done.
	 * Unlike `getContributors()`, this works on html5 (where requests can't block)
	 * and doesn't freeze the game while waiting on desktop and mobile.
	 * @param onComplete Called with the contributors, or an empty array if the request failed.
	 */
	public static function requestContributors(onComplete:Array<Contributor>->Void):Void
	{
		final request:HTTPRequest<String> = new HTTPRequest<String>();

		request.userAgent = 'JTA v${Lib.application.meta['version']}';

		request.load('https://api.github.com/repos/$USER/$REPOSITORY/contributors').onComplete(function(data:String):Void
		{
			var contributors:Array<Contributor> = [];

			try
			{
				final parsed:Dynamic = (data != null && data.length > 0) ? Json.parse(data.trim()) : null;

				if (parsed is Array)
					contributors = parsed;
				else
					FlxG.log.error('Unexpected response while getting the contributors: $data');
			}
			catch (e:Exception)
				FlxG.log.error('Error while trying to parse the contributors: ${e.message}');

			onComplete(contributors);
		}).onError(function(error:Dynamic):Void
		{
				FlxG.log.error('Error while trying to get the contributors: $error');
				onComplete([]);
		});
	}

	/**
	 * Downloads a contributor's profile picture in the background.
	 * @param contributor The contributor.
	 * @param size The size to request from GitHub, in pixels (avatars are square).
	 * @param onComplete Called with the image, or null if it failed to load.
	 */
	public static function requestAvatar(contributor:Contributor, size:Int, onComplete:Null<BitmapData>->Void):Void
	{
		if (contributor.avatar_url == null || contributor.avatar_url.length == 0)
		{
			onComplete(null);
			return;
		}

		final url:String = contributor.avatar_url + (contributor.avatar_url.indexOf('?') >= 0 ? '&' : '?') + 's=$size';

		BitmapData.loadFromFile(url).onComplete(onComplete).onError(function(error:Dynamic):Void
		{
			FlxG.log.warn('Could not load the avatar of ${contributor.login}: $error');
			onComplete(null);
		});
	}
}
