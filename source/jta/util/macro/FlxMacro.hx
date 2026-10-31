package jta.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Field;

/**
 * Class for handling macro of various flixel classes.
 */
class FlxMacro
{
	/**
	 * A macro for adding additional functionaility to `flixel.FlxBasic`
	 * @return A list of the fields in `flixel.FlxBasic`
	 */
	public static function buildFlxBasic():Array<Field>
	{
		var fields:Array<Field> = haxe.macro.Context.getBuildFields();

		// Add `zIndex` property through macro.
		fields = fields.concat([
			{
				name: 'zIndex',
				access: [haxe.macro.Expr.Access.APublic],
				kind: haxe.macro.Expr.FieldType.FVar(macro :Int, macro $v{0}), // Variable type and default value
				pos: Context.currentPos(),
			}
		]);
		return fields;
	}
}
#end
