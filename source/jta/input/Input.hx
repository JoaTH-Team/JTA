package jta.input;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.FlxInput.FlxInputState;
#if mobile
import jta.mobile.MobileInput;
#end

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
 * Class for handling inputs for keyboard, gamepad and (on mobile) the on-screen touch buttons.
 * @author Joalor64
 */
@:nullSafety
class Input
{
	/**
	 * The actions, in the same order as `Data.settings.keyboardBinds` and `gamepadBinds`.
	 */
	public static final ACTIONS:Array<String> = ['left', 'down', 'up', 'right', 'jump', 'run', 'confirm', 'cancel'];

	static public var kBinds:Array<FlxKey> = Data.settings.keyboardBinds;
	static public var gBinds:Array<FlxGamepadInputID> = Data.settings.gamepadBinds;

	/**
	 * A map of input bindings.
	 */
	public static var binds:Map<String, Bind> = buildBinds();

	/**
	 * Refreshes the input controls based on the current settings.
	 */
	public static function refreshControls():Void
	{
		kBinds = Data.settings.keyboardBinds;
		gBinds = Data.settings.gamepadBinds;
		binds = buildBinds();
	}

	/**
	 * Builds the action -> key/button map from `kBinds` and `gBinds`.
	 */
	static function buildBinds():Map<String, Bind>
	{
		final map:Map<String, Bind> = [];

		for (i in 0...ACTIONS.length)
			map.set(ACTIONS[i], {key: kBinds[i], gamepad: gBinds[i]});

		return map;
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
	 *
	 * The tag can be an action (`'jump'`), a key or gamepad button name (`'F5'`, `'A'`), or `'any'`.
	 * On mobile, the on-screen buttons for that action count too.
	 * @param tag The action name to check.
	 * @param state The state to check.
	 * @return `true` if the key or gamepad button is in the specified state, `false` otherwise.
	 */
	public static function checkInput(tag:String, state:FlxInputState):Bool
	{
		#if android
		if (checkAndroidBack(tag, state))
			return true;
		#end

		final gamepad:Null<FlxGamepad> = FlxG.gamepads.lastActive;

		if (binds.exists(tag))
		{
			final bind:Null<Bind> = binds.get(tag);
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
			final kbInput:Null<FlxKey> = FlxKey.fromString(tag);
			if (kbInput != null && kbInput != FlxKey.NONE && FlxG.keys.checkStatus(kbInput, state))
				return true;
			#end

			#if FLX_GAMEPAD
			final gpInput:Null<FlxGamepadInputID> = FlxGamepadInputID.fromString(tag);
			if (gamepad != null && gpInput != null && gpInput != FlxGamepadInputID.NONE && gamepad.checkStatus(gpInput, state))
				return true;
			#end
		}

		#if mobile
		if (checkTouch(tag, state))
			return true;
		#end

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
		if (tags == null || tags.length <= 0)
			return false;

		#if android
		for (tag in tags)
		{
			if (checkAndroidBack(tag, state))
				return true;
		}
		#end

		for (tag in tags)
			if (checkInput(tag, state))
				return true;

		return false;
	}

	#if mobile
	/**
	 * Checks the on-screen touch buttons. `'any'` matches any button.
	 */
	static function checkTouch(tag:String, state:FlxInputState):Bool
	{
		if (tag.toLowerCase() == 'any')
			return MobileInput.checkAnyInput(state);

		return MobileInput.checkInput(tag, state);
	}
	#end

	#if android
	/**
	 * The Android system back button acts as `cancel`
	 * Main.hx stops it from closing the app via `FlxG.android.preventDefaultKeys`.
	 */
	static function checkAndroidBack(tag:String, state:FlxInputState):Bool
	{
		return tag == 'cancel' && FlxG.android != null && FlxG.android.checkStatus(BACK, state);
	}
	#end
}
