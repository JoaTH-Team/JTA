package jta.mobile;

import jta.Paths;
import jta.Assets;
import flixel.FlxCamera;
import flixel.input.touch.FlxTouch;

/**
 * A virtual touchscreen button.
 *
 * The button's `action` is the logical input action it represents,
 * while `imageName` controls which button graphic is displayed.
 *
 * This allows the same A graphic to represent both `jump` in gameplay
 * and `confirm` in menus.
 *
 * Input state is tracked per button (not per touch), so sliding a finger
 * onto a button counts as a press and sliding off counts as a release.
 * The state is refreshed once per frame by `MobileInput`'s plugin, right
 * after Flixel updates its touch input and before the state updates.
 */
class VirtualButton extends FlxSprite
{
	/**
	 * Size in pixels of the source button graphics.
	 */
	public static inline var BASE_SIZE:Int = 16;

	/**
	 * Logical input action represented by this button.
	 */
	public var action:String;

	/**
	 * Asset name used to display this button.
	 */
	public var imageName:String;

	/**
	 * Whether this button can currently receive touch input.
	 */
	public var enabled(default, set):Bool = true;

	/**
	 * Normal button opacity.
	 */
	public var normalAlpha:Float = 0.6;

	/**
	 * Opacity while being pressed.
	 */
	public var pressedAlpha:Float = 1.0;

	/**
	 * Whether a touch is over this button this frame.
	 */
	var currentlyPressed:Bool = false;

	/**
	 * Whether a touch was over this button last frame.
	 */
	var previouslyPressed:Bool = false;

	/**
	 * Whether the input state has been sampled at least once. On the first
	 * sample, a finger that is already resting on the button (e.g. held over
	 * from the previous screen) does not count as a fresh press.
	 */
	var initialized:Bool = false;

	/**
	 * Set when a finger was already resting on the button when it appeared
	 * (or was re-shown). The button ignores that finger until it lifts off or
	 * slides away, so e.g. resuming from the pause menu with A doesn't make
	 * the player jump with the gameplay A button underneath.
	 */
	var waitForRelease:Bool = false;

	/**
	 * @param x The x position (top-left of the touch area).
	 * @param y The y position (top-left of the touch area).
	 * @param action The logical input action.
	 * @param type Graphic subfolder (`default`, `navigation`, `util`).
	 * @param imageName Graphic override. Defaults based on `action`.
	 * @param size On-screen size of the button in pixels.
	 */
	public function new(x:Float, y:Float, action:String, ?type:String = 'default', ?imageName:String = null, ?size:Float = 96):Void
	{
		super(x, y);

		this.action = action;

		if (imageName == null)
		{
			imageName = switch (action)
			{
				case 'jump', 'confirm':
					'a';

				case 'run', 'cancel':
					'b';

				default:
					action;
			};
		}

		this.imageName = imageName;

		var folder:String = (type == null || type == '' || type == 'default') ? '' : '/$type';
		var path:String = 'buttons$folder/$imageName';

		if (Assets.exists(Paths.image(path)))
			loadGraphic(Paths.image(path));
		else if (Assets.exists(Paths.image('buttons/default')))
			loadGraphic(Paths.image('buttons/default'));
		else
			makeGraphic(BASE_SIZE, BASE_SIZE, 0xFF808080);

		setGraphicSize(Std.int(size), Std.int(size));
		updateHitbox();

		scrollFactor.set();

		alpha = normalAlpha;
		antialiasing = false;
	}

	@:noCompletion
	function set_enabled(value:Bool):Bool
	{
		if (value && !enabled)
			resetInput();

		return enabled = value;
	}

	/**
	 * Forgets the current press state. The next sample will not report
	 * a `justPressed` for a finger that is already resting on the button.
	 */
	public function resetInput():Void
	{
		currentlyPressed = false;
		previouslyPressed = false;
		initialized = false;
		waitForRelease = false;
	}

	private function getTouchCamera():FlxCamera
	{
		var cams = cameras;
		if (cams != null && cams.length > 0 && cams[0] != null)
			return cams[0];

		return FlxG.camera;
	}

	/**
	 * Whether this button can be interacted with right now.
	 */
	public inline function isInteractable():Bool
		return enabled && visible && exists && alive;

	/**
	 * Returns whether any touch is currently over this button.
	 */
	private function touchIsOver():Bool
	{
		#if FLX_TOUCH
		if (!isInteractable())
			return false;

		var camera:FlxCamera = getTouchCamera();
		for (touch in FlxG.touches.list)
		{
			if (touch != null && touch.pressed && touch.overlaps(this, camera))
				return true;
		}
		#end

		return false;
	}

	/**
	 * Samples touch input. Called once per frame by `MobileInput`.
	 */
	public function updateInput():Void
	{
		var over:Bool = touchIsOver();

		if (!initialized)
		{
			waitForRelease = over;
			previouslyPressed = false;
			currentlyPressed = false;
			initialized = true;
			return;
		}

		if (waitForRelease)
		{
			if (over)
				over = false;
			else
				waitForRelease = false;
		}

		previouslyPressed = currentlyPressed;
		currentlyPressed = over;
	}

	/**
	 * Returns whether a touch is currently pressing this button.
	 * Multitouch is supported because every active touch is checked.
	 */
	public inline function isPressed():Bool
		return isInteractable() && currentlyPressed;

	/**
	 * Returns whether this button was just pressed this frame.
	 */
	public inline function justPressed():Bool
		return isInteractable() && currentlyPressed && !previouslyPressed;

	/**
	 * Returns whether this button was just released this frame.
	 */
	public inline function justReleased():Bool
		return !currentlyPressed && previouslyPressed;

	/**
	 * Updates the visual appearance of the button.
	 */
	public function updateVisual():Void
	{
		if (!enabled)
		{
			alpha = 0;
			return;
		}

		alpha = isPressed() ? pressedAlpha : normalAlpha;
	}

	override public function update(elapsed:Float):Void
	{
		updateVisual();

		super.update(elapsed);
	}
}
