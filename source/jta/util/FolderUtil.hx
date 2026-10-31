package jta.util;

#if android
import extension.androidtools.os.Environment;
#end

/**
 * Helpers for showing folders (like `mods/`) to the player.
 */
@:nullSafety
class FolderUtil
{
	/**
	 * Tries to open a folder in the system's file manager.
	 *
	 * On Android, this asks the built-in Files app to show the folder. Some phones' file managers
	 * ignore that request, so also show the player the path (see `getDisplayPath()`).
	 * @param path The folder's full path.
	 */
	public static function openFolder(path:String):Void
	{
		#if android
		final uri:Null<String> = getAndroidDocumentUri(path);
		if (uri != null)
			lime.system.System.openURL(uri); // lime catches the error if nothing can open it
		#elseif windows
		Sys.command('explorer', [path.replace('/', '\\')]);
		#elseif mac
		Sys.command('open', [path]);
		#elseif linux
		Sys.command('xdg-open', [path]);
		#end
	}

	/**
	 * Gets a shorter path to show the player. On Android it's relative to the phone's storage
	 * (e.g. `Android/media/com.joalor64.jta/mods`), which is what file managers show.
	 * @param path The folder's full path.
	 */
	public static function getDisplayPath(path:String):String
	{
		#if android
		final relative:Null<String> = getAndroidRelativePath(path);
		if (relative != null)
			return relative;
		#end

		return path;
	}

	#if android
	/**
	 * The path relative to the phone's shared storage (`/storage/emulated/0`), or null if it isn't in there.
	 */
	static function getAndroidRelativePath(path:String):Null<String>
	{
		final root:Null<String> = Environment.getExternalStorageDirectory();
		if (root == null || root == '')
			return null;

		final base:String = haxe.io.Path.removeTrailingSlashes(root);
		final full:String = haxe.io.Path.removeTrailingSlashes(haxe.io.Path.normalize(path));

		if (!full.startsWith(base + '/'))
			return null;

		return full.substr(base.length + 1);
	}

	/**
	 * A `content://` link to the folder that Android's Files app understands
	 * (plain file paths can't be opened by other apps on Android 7 and up).
	 */
	static function getAndroidDocumentUri(path:String):Null<String>
	{
		final relative:Null<String> = getAndroidRelativePath(path);
		if (relative == null)
			return null;

		return 'content://com.android.externalstorage.documents/document/' + StringTools.urlEncode('primary:' + relative);
	}
	#end
}
