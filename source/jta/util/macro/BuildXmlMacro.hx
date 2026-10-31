package jta.util.macro;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;

/**
 * Helpers for hxcpp `@:buildXml` includes.
 */
class BuildXmlMacro
{
	/**
	 * Adds `@:buildXml('<include name="..."/>')` pointing at a file next to the
	 * class's own source file, using an **absolute** path.
	 *
	 * Usage: `@:build(jta.util.macro.BuildXmlMacro.includeLocal('build.xml'))`
	 */
	public static macro function includeLocal(file:String = 'build.xml'):Array<Field>
	{
		final cls = Context.getLocalClass().get();
		final sourceFile:String = Context.getPosInfos(cls.pos).file;
		final dir:String = Path.directory(FileSystem.fullPath(sourceFile));
		final path:String = Path.normalize(Path.join([dir, file]));

		if (!FileSystem.exists(path))
			Context.error('BuildXmlMacro: could not find "$path"', cls.pos);

		final xml:String = '<include name="$path" />';
		cls.meta.add(':buildXml', [macro $v{xml}], cls.pos);

		return null;
	}
}
#end
