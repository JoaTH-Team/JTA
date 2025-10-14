package jta.util.plugins;

import flixel.FlxBasic;
import jta.util.MemoryUtil;

/**
 * A plugin that let's you press `Insert` to manually trigger garbage collection.
 */
class MemoryGCPlugin extends FlxBasic
{
	public function new():Void
	{
		super();
	}

	public static function initialize():Void
	{
		FlxG.plugins.addPlugin(new MemoryGCPlugin());
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.INSERT)
			MemoryUtil.collect(true);
	}

	override public function destroy():Void
	{
		super.destroy();
	}
}
