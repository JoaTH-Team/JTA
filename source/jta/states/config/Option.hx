package jta.states.config;

import haxe.Exception;
import jta.locale.Locale;

/**
 * Enum representing different types of options available.
 */
enum OptionType
{
	/**
	 * A toggle option, usually a `Bool` value.
	 */
	Toggle;

	/**
	 * An integer option with specified range and step values.
	 * @param min The minimum value.
	 * @param max The maximum.
	 * @param step The step value.
	 */
	Integer(min:Int, max:Int, step:Int);

	/**
	 * A decimal option with specified range and step values.
	 * @param min The minimum value.
	 * @param max The maximum.
	 * @param step The step value.
	 */
	Decimal(min:Float, max:Float, step:Float);

	/**
	 * A function option which triggers a specific action when selected.
	 */
	Function;

	/**
	 * A choice option with a list of predefined choices.
	 * @param choices The array of choices.
	 */
	Choice(choices:Array<String>);
}

/**
 * Represents a configuration option in the settings menu.
 * @author Joalor64
 */
class Option
{
	/**
	 * The name of the option displayed in the settings menu.
	 */
	public var name:String;

	/**
	 * The type of the option.
	 */
	public var type:OptionType;

	/**
	 * The current value of the option.
	 */
	public var value:Dynamic;

	/**
	 * Whether or not to display a '%' sign for Integer and Decimal types.
	 */
	public var showPercentage:Bool = false;

	/**
	 * A function to be called when the option value changes.
	 */
	public var onChange:Dynamic->Void;

	/**
	 * Creates an option with the specified name, type, and value.
	 * @param name The name of the option.
	 * @param type The type of the option.
	 * @param value The initial value of the option.
	 */
	public function new(name:String, type:OptionType, value:Dynamic):Void
	{
		this.name = name;
		this.type = type;
		this.value = value;
	}

	/**
	 * Changes the value of the option based on the direction input.
	 * Adjusts the value by a step amount.
	 * @param direction The direction to adjust the value.
	 */
	public function changeValue(?direction:Int = 0):Void
	{
		switch (type)
		{
			case OptionType.Toggle:
				value = !value;
			case OptionType.Integer(min, max, step):
				value = Math.floor(FlxMath.bound(value + direction * step, min, max));
			case OptionType.Decimal(min, max, step):
				value = FlxMath.bound(value + direction * step, min, max);
			case OptionType.Choice(choices):
				value = choices[FlxMath.wrap(choices.indexOf(value) + direction, 0, choices.length - 1)];
			default:
		}

		if (type != OptionType.Function && onChange != null)
			onChange(value);
	}

	/**
	 * Executes the function associated with this option if it is of type Function.
	 * Attempts to call the function stored in the value property and logs an error if unsuccessful.
	 */
	public function execute():Void
	{
		try
		{
			if (type == OptionType.Function && (value != null && Reflect.isFunction(value)))
				Reflect.callMethod(null, value, []);
		}
		catch (e:Exception)
			FlxG.log.error('Unable to call the function for "$name" option: ${e.message}');
	}

	/**
	 * Converts the option to a string for display purposes.
	 * @return A string representation of the option, formatted according to its type.
	 */
	public function toString():String
	{
		var formattedString:String = 'Error!';

		switch (type)
		{
			case OptionType.Toggle:
				formattedString = '$name: ${value ? Locale.getSettings("$ON") : Locale.getSettings("$OFF")}';
			case OptionType.Integer(_, _, _):
				formattedString = '$name: $value${showPercentage ? '%' : ''}';
			case OptionType.Decimal(_, _, _):
				formattedString = '$name: $value${showPercentage ? '%' : ''}';
			case OptionType.Choice(_):
				formattedString = '$name: $value';
			default:
				formattedString = name;
		}

		return formattedString;
	}
}
