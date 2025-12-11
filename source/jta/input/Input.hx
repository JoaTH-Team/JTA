package jta.input;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.FlxInput.FlxInputState;

/**
 * A structure for input bindings, which includes both a keyboard key and a gamepad button.
 */
typedef Bind =
{
	/**
	 * The keyboard key associated with the action.
	 */
	key:FlxKey,

	/**
	 * The gamepad button associated with the action.
	 */
	gamepad:FlxGamepadInputID
}

/**
 * Class for handling inputs for keyboard and gamepad.
 * @author Joalor64
 */
@:nullSafety
class Input
{
	static public var kBinds:Array<FlxKey> = Data.settings.keyboardBinds;
	static public var gBinds:Array<FlxGamepadInputID> = Data.settings.gamepadBinds;

	/**
	 * A map of input bindings.
	 */
	public static var binds:Map<String, Bind> = [
		'left' => {key: kBinds[0], gamepad: gBinds[0]},
		'down' => {key: kBinds[1], gamepad: gBinds[1]},
		'up' => {key: kBinds[2], gamepad: gBinds[2]},
		'right' => {key: kBinds[3], gamepad: gBinds[3]},
		'jump' => {key: kBinds[4], gamepad: gBinds[4]},
		'run' => {key: kBinds[5], gamepad: gBinds[5]},
		'confirm' => {key: kBinds[6], gamepad: gBinds[6]},
		'cancel' => {key: kBinds[7], gamepad: gBinds[7]}
	];

	/**
	 * Refreshes the input controls based on the current settings.
	 */
	public static function refreshControls():Void
	{
		kBinds = Data.settings.keyboardBinds;
		gBinds = Data.settings.gamepadBinds;

		binds.clear();
		binds = [
			'left' => {key: kBinds[0], gamepad: gBinds[0]},
			'down' => {key: kBinds[1], gamepad: gBinds[1]},
			'up' => {key: kBinds[2], gamepad: gBinds[2]},
			'right' => {key: kBinds[3], gamepad: gBinds[3]},
			'jump' => {key: kBinds[4], gamepad: gBinds[4]},
			'run' => {key: kBinds[5], gamepad: gBinds[5]},
			'confirm' => {key: kBinds[6], gamepad: gBinds[6]},
			'cancel' => {key: kBinds[7], gamepad: gBinds[7]}
		];
	}

	/**
	 * Checks if the input associated with the given tag was just pressed.
	 * @param tag The action name to check.
	 * @return `true` if the key or gamepad button was just pressed, `false` otherwise.
	 */
	public static function justPressed(tag:String):Bool
		return checkInput(tag, JUST_PRESSED);

	/**
	 * Checks if the input associated with the given tag is currently pressed.
	 * @param tag The action name to check.
	 * @return `true` if the key or gamepad button is pressed, `false` otherwise.
	 */
	public static function pressed(tag:String):Bool
		return checkInput(tag, PRESSED);

	/**
	 * Checks if the input associated with the given tag was just released.
	 * @param tag The action name to check.
	 * @return `true` if the key or gamepad button was just released, `false` otherwise.
	 */
	public static function justReleased(tag:String):Bool
		return checkInput(tag, JUST_RELEASED);

	/**
	 * Checks if any of the inputs associated with the given tags were just pressed.
	 * @param tags An array of action names to check.
	 * @return `true` if any of the keys or gamepad buttons were just pressed, `false` otherwise.
	 */
	public static function anyJustPressed(tags:Array<String>):Bool
		return checkAnyInputs(tags, JUST_PRESSED);

	/**
	 * Checks if any of the inputs associated with the given tags are currently pressed.
	 * @param tags An array of action names to check.
	 * @return `true` if any of the keys or gamepad buttons are currently pressed, `false` otherwise.
	 */
	public static function anyPressed(tags:Array<String>):Bool
		return checkAnyInputs(tags, PRESSED);

	/**
	 * Checks if any of the inputs associated with the given tags were just released.
	 * @param tags An array of action names to check.
	 * @return `true` if any of the keys or gamepad buttons were just released, `false` otherwise.
	 */
	public static function anyJustReleased(tags:Array<String>):Bool
		return checkAnyInputs(tags, JUST_RELEASED);

	/**
	 * Checks if the input associated with the given tag is in the specified state.
	 * @param tag The action name to check.
	 * @param state The state to check.
	 * @return `true` if the key or gamepad button is in the specified state, `false` otherwise.
	 */
	public static function checkInput(tag:String, state:FlxInputState):Bool
	{
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (binds.exists(tag))
		{
			var bind:Null<Bind> = binds.get(tag);
			if (bind == null)
				return false;

			#if FLX_KEYBOARD
			if (FlxG.keys.checkStatus(bind.key, state))
				return true;
			#end

			#if FLX_GAMEPAD
			if (gamepad != null && gamepad.checkStatus(bind.gamepad, state))
				return true;
			#end
		}
		else
		{
			#if FLX_KEYBOARD
			var kbInput:Null<FlxKey> = FlxKey.fromString(tag);
			if (kbInput != null && kbInput != FlxKey.NONE && FlxG.keys.checkStatus(kbInput, state))
				return true;
			#end

			#if FLX_GAMEPAD
			var gpInput:Null<FlxGamepadInputID> = FlxGamepadInputID.fromString(tag);
			if (gamepad != null && gpInput != null && gpInput != FlxGamepadInputID.NONE && gamepad.checkStatus(gpInput, state))
				return true;
			#end
		}

		return false;
	}

	/**
	 * Checks if any of the inputs associated with the given tags are in the specified state.
	 * @param tags An array of action names to check.
	 * @param state The state to check.
	 * @return `true` if any of the keys or gamepad buttons are in the specified state, `false` otherwise.
	 */
	public static function checkAnyInputs(tags:Array<String>, state:FlxInputState):Bool
	{
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (tags == null || tags.length <= 0)
			return false;

		for (tag in tags)
		{
			if (binds.exists(tag))
			{
				var bind:Null<Bind> = binds.get(tag);
				if (bind == null)
					return false;

				#if FLX_KEYBOARD
				if (FlxG.keys.checkStatus(bind.key, state))
					return true;
				#end

				#if FLX_GAMEPAD
				if (gamepad != null && gamepad.checkStatus(bind.gamepad, state))
					return true;
				#end
			}
			else
			{
				#if FLX_KEYBOARD
				var kbInput:Null<FlxKey> = FlxKey.fromString(tag);
				if (kbInput != null && kbInput != FlxKey.NONE && FlxG.keys.checkStatus(kbInput, state))
					return true;
				#end

				#if FLX_GAMEPAD
				var gpInput:Null<FlxGamepadInputID> = FlxGamepadInputID.fromString(tag);
				if (gamepad != null && gpInput != null && gpInput != FlxGamepadInputID.NONE && gamepad.checkStatus(gpInput, state))
					return true;
				#end
			}
		}

		return false;
	}
}
