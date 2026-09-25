package jta;

import flixel.util.FlxSave;

class Global
{
	public static var coins:Int = 0;

	private static var _score:Int = 0;
	public static var score(get, set):Int;

	static function get_score():Int
		return _score;

	static function set_score(value:Int):Int
	{
		_score = (value > 9999990) ? 9999990 : value;
		return _score;
	}

	public static var lives:Int = 3;
	public static var flags:Array<Int> = [for (i in 0...25) 0]; // 25 flags with the value 0

	@:noCompletion
	private static var _save:FlxSave;

	@:noCompletion
	private static function getSave():FlxSave
	{
		if (_save == null)
		{
			_save = new FlxSave();
			_save.bind('file', Lib.application.meta.get('file'));
		}

		return _save;
	}

	public static function save():Void
	{
		var save:FlxSave = getSave();
		save.data.coins = coins;
		save.data.score = score;
		save.data.lives = lives;
		save.data.flags = flags;
		save.flush();
	}

	public static function load():Void
	{
		var save:FlxSave = getSave();
		if (!save.isEmpty())
		{
			if (save.data.coins != null)
				coins = save.data.coins;

			if (save.data.score != null)
				score = save.data.score;

			if (save.data.lives != null)
				lives = save.data.lives;

			if (save.data.flags != null)
				flags = save.data.flags;
		}
	}
}
