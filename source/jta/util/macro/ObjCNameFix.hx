package jta.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * Fixes C++ name clashes with Objective-C on iOS (and macOS).
 */
class ObjCNameFix
{
	/**
	 * Names that Objective-C headers define as macros.
	 */
	static final OBJC_MACROS:Array<String> = ['Nil', 'nil', 'YES', 'NO'];

	public static macro function build():Array<Field>
	{
		final fields:Array<Field> = Context.getBuildFields();
		final localType:Null<Type> = Context.getLocalType();

		switch (localType)
		{
			case TEnum(ref, _):
				renameType(ref.get().pack, ref.get().name, ref.get().meta, ref.get().pos);
			case TInst(ref, _):
				renameType(ref.get().pack, ref.get().name, ref.get().meta, ref.get().pos);
			default:
		}

		for (field in fields)
		{
			if (OBJC_MACROS.contains(field.name) && !hasMeta(field.meta, ':native'))
			{
				if (field.meta == null)
					field.meta = [];

				field.meta.push({name: ':native', params: [macro $v{'objcsafe_' + field.name}], pos: field.pos});
			}
		}

		return fields;
	}

	static function renameType(pack:Array<String>, name:String, meta:MetaAccess, pos:Position):Void
	{
		if (!OBJC_MACROS.contains(name) || meta.has(':native'))
			return;

		final nativeName:String = pack.concat(['ObjCSafe_' + name]).join('.');
		meta.add(':native', [macro $v{nativeName}], pos);
	}

	static function hasMeta(meta:Null<Metadata>, name:String):Bool
	{
		if (meta == null)
			return false;

		for (entry in meta)
			if (entry.name == name)
				return true;

		return false;
	}
}
#end
