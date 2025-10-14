package jta.util;

import flixel.FlxState;

class StateUtil
{
	public static function getCurrentState():String
	{
		if (FlxG.state == null)
			return 'Unknown';

		var cls:Null<Class<FlxState>> = Type.getClass(FlxG.state);
		if (cls == null)
			return 'Unknown';

		var name:Null<String> = Type.getClassName(cls);
		if (name == null)
			return 'Unknown';

		var parts:Array<String> = name.split('.');
		if (parts == null || parts.length == 0)
			return 'Unknown';

		var last:Null<String> = parts.pop();
		return last != null ? last : 'Unknown';
	}
}
