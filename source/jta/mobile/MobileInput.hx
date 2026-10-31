package jta.mobile;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.FlxInput.FlxInputState;
import jta.mobile.VirtualButton;

/**
 * Handles virtual touchscreen controls.
 *
 * Layouts are computed from the button size and screen size, so changing
 * `buttonSize`, `utilSize`, `margin` or `spacing` keeps everything on screen
 * and non-overlapping.
 */
class MobileInput extends FlxTypedGroup<VirtualButton>
{
	/**
	 * Every live control layout, oldest first. The last one is the active one.
	 * Using a stack (instead of a single "previous" pointer) keeps things
	 * correct no matter what order states and substates get destroyed in.
	 */
	static var instances:Array<MobileInput> = [];

	/**
	 * Currently active mobile input manager (the most recently created one
	 * that is still alive). Input.hx uses this to query touchscreen controls.
	 */
	public static var activeInstance(get, never):Null<MobileInput>;

	/**
	 * Plugin that samples touch input once per frame.
	 */
	static var plugin:Null<MobileInputPlugin>;

	/**
	 * On-screen size of the main buttons (A/B/arrows), in pixels.
	 */
	public static var buttonSize:Float = 96;

	/**
	 * On-screen size of utility buttons (pause/back/skip), in pixels.
	 */
	public static var utilSize:Float = 64;

	/**
	 * Distance from the top and bottom edges of the screen.
	 */
	public static var margin:Float = 24;

	/**
	 * Distance from the left and right edges of the screen. A bit larger than
	 * `margin` to keep clear of rounded screen corners and camera cutouts.
	 */
	public static var sideMargin:Float = 40;

	/**
	 * The camera all touch controls are drawn on (see `getControlsCamera()`).
	 */
	static var controlsCamera:Null<FlxCamera>;

	static var resizeListenerAdded:Bool = false;

	/**
	 * Re-applies this instance's current layout (used after a screen resize).
	 */
	var relayout:Null<Void->Void>;

	/**
	 * Gap between neighbouring buttons.
	 */
	public static var spacing:Float = 12;

	/**
	 * Creates a mobile input manager.
	 * @param camera Ignored. Kept so older code calling `new MobileInput(someCamera)` still compiles.
	 */
	public function new(?camera:FlxCamera):Void
	{
		super();

		ensurePlugin();

		instances.push(this);

		cameras = [getControlsCamera()];
	}

	// ---------------------------------------------------------------------
	// Full-screen controls camera
	// ---------------------------------------------------------------------

	/**
	 * Returns the camera the touch controls are drawn on, creating it if
	 * needed. It's added on top of every other camera and stretched to cover
	 * the whole device screen, letterbox bars included.
	 *
	 * Flixel removes all cameras when the state switches, so a new one is
	 * made for each state; substates (pause menu etc.) reuse their state's.
	 */
	public static function getControlsCamera():FlxCamera
	{
		if (controlsCamera == null || !FlxG.cameras.list.contains(controlsCamera))
		{
			controlsCamera = new FlxCamera();
			controlsCamera.bgColor = 0x00000000;
			FlxG.cameras.add(controlsCamera, false);
			fitCameraToScreen(controlsCamera);
		}

		if (!resizeListenerAdded)
		{
			FlxG.signals.gameResized.add(onGameResized);
			resizeListenerAdded = true;
		}

		return controlsCamera;
	}

	/**
	 * Width of the letterbox bar on each side of the game, in game pixels.
	 */
	public static var barWidth(get, never):Float;

	/**
	 * Height of the letterbox bar above and below the game, in game pixels.
	 */
	public static var barHeight(get, never):Float;

	@:noCompletion
	static function get_barWidth():Float
		return (FlxG.scaleMode != null && FlxG.scaleMode.scale.x > 0) ? Math.max(0, FlxG.scaleMode.offset.x / FlxG.scaleMode.scale.x) : 0;

	@:noCompletion
	static function get_barHeight():Float
		return (FlxG.scaleMode != null && FlxG.scaleMode.scale.y > 0) ? Math.max(0, FlxG.scaleMode.offset.y / FlxG.scaleMode.scale.y) : 0;

	static function fitCameraToScreen(camera:FlxCamera):Void
	{
		final bx:Float = barWidth;
		final by:Float = barHeight;

		// Negative position + bigger size = the camera reaches into the bars.
		camera.setPosition(-bx, -by);
		camera.setSize(Math.ceil(FlxG.width + bx * 2), Math.ceil(FlxG.height + by * 2));
	}

	static function onGameResized(width:Int, height:Int):Void
	{
		if (controlsCamera == null || !FlxG.cameras.list.contains(controlsCamera))
			return;

		fitCameraToScreen(controlsCamera);

		for (instance in instances)
			if (instance != null && instance.relayout != null)
				instance.relayout();
	}

	/** 
	 * Width of the area the controls can use (the whole screen), in game pixels. 
	 */
	static inline function screenWidth():Float
		return FlxG.width + barWidth * 2;

	/** 
	 * Height of the area the controls can use (the whole screen), in game pixels. 
	 */
	static inline function screenHeight():Float
		return FlxG.height + barHeight * 2;

	/**
	 * Converts a y position in game coordinates into controls-camera coordinates.
	 */
	public static inline function gameToScreenY(y:Float):Float
		return y + barHeight;

	@:noCompletion
	static function get_activeInstance():Null<MobileInput>
		return instances.length > 0 ? instances[instances.length - 1] : null;

	@:noCompletion
	static function ensurePlugin():Void
	{
		if (plugin == null || !plugin.exists)
		{
			plugin = new MobileInputPlugin();
			FlxG.plugins.addPlugin(plugin);
		}
	}

	/**
	 * Samples touch input for every live layout. Called by the plugin.
	 */
	public static function updateAll():Void
	{
		for (instance in instances)
		{
			if (instance == null || instance.members == null)
				continue;

			for (button in instance.members)
			{
				if (button != null)
					button.updateInput();
			}
		}
	}

	/**
	 * Adds a virtual button to this control layout.
	 */
	public function addButton(x:Float, y:Float, action:String, ?type:String = 'default', ?imageName:String = null, ?size:Float):VirtualButton
	{
		var button:VirtualButton = new VirtualButton(x, y, action, type, imageName, size ?? buttonSize);
		button.cameras = cameras;
		add(button);

		return button;
	}

	/**
	 * Finds the first button for an action.
	 */
	public function getButton(action:String):Null<VirtualButton>
	{
		for (button in members)
			if (button != null && button.action == action)
				return button;

		return null;
	}

	/**
	 * Removes all currently displayed buttons.
	 */
	public function clearButtons():Void
	{
		for (button in members)
			if (button != null)
				button.destroy();

		clear();
	}

	/**
	 * Enables or disables every button.
	 */
	public function setEnabled(value:Bool):Void
	{
		for (button in members)
			if (button != null)
				button.enabled = value;
	}

	/**
	 * Shows or hides the whole layout. Hidden layouts receive no input.
	 */
	public function setVisible(value:Bool):Void
	{
		if (value && !visible)
			for (button in members)
				if (button != null)
					button.resetInput();

		visible = value;
		active = value;
	}

	/** 
	 * Left edge of the left-most column. 
	 */
	inline function leftX(col:Float = 0):Float
		return sideMargin + col * (buttonSize + spacing);

	/** 
	 * Left edge of a column counted from the right edge (0 = right-most).
	 */
	inline function rightX(col:Int = 0):Float
		return screenWidth() - sideMargin - buttonSize - col * (buttonSize + spacing);

	/** 
	 * Top edge of a row counted from the bottom (0 = bottom-most).
	 */
	inline function bottomY(row:Int = 0):Float
		return screenHeight() - margin - buttonSize - row * (buttonSize + spacing);

	/**
	 * Width of the A/B cluster plus its side margin.
	 */
	static inline function faceClusterWidth():Float
		return sideMargin + buttonSize * 2 + spacing;

	/**
	 * Adds the A/B pair in the bottom-right corner, arranged diagonally
	 * like a controller: B bottom-left, A raised on the right.
	 */
	function addFaceButtons(aAction:String, bAction:Null<String>, ?bottom:Float):Void
	{
		var base:Float = bottom ?? screenHeight() - margin;
		var aY:Float = base - buttonSize - (buttonSize + spacing) * 0.5;
		var bY:Float = base - buttonSize;

		addButton(rightX(0), aY, aAction);

		if (bAction != null)
			addButton(rightX(1), bY, bAction);
	}

	/**
	 * Shows the standard gameplay layout.
	 *
	 * Left/right in the bottom-left, run (B) and jump (A) in the bottom-right,
	 * pause at the top centre (the HUD uses both top corners), and a
	 * contextual interact button above the arrows that only appears when
	 * the player is standing on something interactable.
	 */
	public function setupGameplay():Void
	{
		relayout = setupGameplay;
		clearButtons();

		addButton(leftX(0), bottomY(0), 'left', 'navigation');
		addButton(leftX(1), bottomY(0), 'right', 'navigation');

		addFaceButtons('jump', 'run');

		addButton((screenWidth() - utilSize) / 2, margin, 'pause', 'util', null, utilSize);

		var interact:VirtualButton = addButton(leftX(0.5), bottomY(1), 'confirm', 'navigation', 'up');
		interact.visible = false;
	}

	/**
	 * Layout used while a dialogue box is open: A advances, B skips.
	 * @param boxTop The top of the dialogue box, if it sits at the bottom of the screen.
	 *               The buttons are placed just above it so they don't cover the text.
	 */
	public function setupDialogue(?boxTop:Float):Void
	{
		relayout = () -> setupDialogue(boxTop);
		clearButtons();

		var bottom:Float = screenHeight() - margin;

		if (barWidth < faceClusterWidth() && boxTop != null && boxTop > FlxG.height * 0.5)
			bottom = gameToScreenY(boxTop) - spacing;

		addFaceButtons('confirm', 'cancel', bottom);
	}

	/**
	 * Sets up a normal vertical menu layout.
	 * @param showCancel Whether to show the B (cancel) button.
	 */
	public function setupMenuVertical(?showCancel:Bool = true):Void
	{
		relayout = () -> setupMenuVertical(showCancel);
		clearButtons();

		addButton(leftX(0), bottomY(1), 'up', 'navigation');
		addButton(leftX(0), bottomY(0), 'down', 'navigation');

		addFaceButtons('confirm', showCancel ? 'cancel' : null);
	}

	/**
	 * Sets up a horizontal menu layout.
	 * @param showCancel Whether to show the B (cancel) button.
	 */
	public function setupMenuHorizontal(?showCancel:Bool = true):Void
	{
		relayout = () -> setupMenuHorizontal(showCancel);
		clearButtons();

		addButton(leftX(0), bottomY(0), 'left', 'navigation');
		addButton(leftX(1), bottomY(0), 'right', 'navigation');

		addFaceButtons('confirm', showCancel ? 'cancel' : null);
	}

	/**
	 * Sets up a full d-pad menu layout (for menus such as Settings that
	 * use both up/down and left/right).
	 * @param showCancel Whether to show the B (cancel) button.
	 */
	public function setupMenuFull(?showCancel:Bool = true):Void
	{
		relayout = () -> setupMenuFull(showCancel);
		clearButtons();

		addButton(leftX(1), bottomY(2), 'up', 'navigation');
		addButton(leftX(0), bottomY(1), 'left', 'navigation');
		addButton(leftX(2), bottomY(1), 'right', 'navigation');
		addButton(leftX(1), bottomY(0), 'down', 'navigation');

		addFaceButtons('confirm', showCancel ? 'cancel' : null);
	}

	/**
	 * Adds utility buttons to the current layout.
	 * Back goes top-left, skip/pause go top-right.
	 */
	public function setupUtility(?showBack:Bool = false, ?showSkip:Bool = false, ?showPause:Bool = false):Void
	{
		if (showBack)
			addButton(sideMargin, margin, 'cancel', 'util', 'back', utilSize);

		var rightSlot:Float = screenWidth() - sideMargin - utilSize;

		if (showSkip)
		{
			addButton(rightSlot, margin, 'skip', 'util', null, utilSize);
			rightSlot -= utilSize + spacing;
		}

		if (showPause)
			addButton(rightSlot, margin, 'pause', 'util', null, utilSize);
	}

	/**
	 * Updates the visual state of every button.
	 */
	public function updateInput():Void
	{
		for (button in members)
			if (button != null)
				button.updateVisual();
	}

	/**
	 * Checks a mobile button for the requested input state.
	 */
	public static function checkInput(action:String, state:FlxInputState):Bool
	{
		var instance = activeInstance;
		if (instance == null || !instance.visible || !instance.exists)
			return false;

		for (button in instance.members)
		{
			if (button == null || button.action != action)
				continue;

			if (checkButton(button, state))
				return true;
		}

		return false;
	}

	/**
	 * Checks whether any mobile button is in a given state.
	 */
	public static function checkAnyInput(state:FlxInputState):Bool
	{
		var instance = activeInstance;
		if (instance == null || !instance.visible || !instance.exists)
			return false;

		for (button in instance.members)
		{
			if (button != null && checkButton(button, state))
				return true;
		}

		return false;
	}

	/**
	 * Checks whether any touch anywhere on the screen is in a given state.
	 * Useful for "tap to continue" screens.
	 */
	public static function checkAnyTouch(state:FlxInputState):Bool
	{
		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (touch == null)
				continue;

			switch (state)
			{
				case JUST_PRESSED:
					if (touch.justPressed)
						return true;
				case PRESSED:
					if (touch.pressed)
						return true;
				case JUST_RELEASED:
					if (touch.justReleased)
						return true;
				default:
			}
		}
		#end

		return false;
	}

	static function checkButton(button:VirtualButton, state:FlxInputState):Bool
	{
		return switch (state)
		{
			case JUST_PRESSED: button.justPressed();
			case PRESSED: button.isPressed();
			case JUST_RELEASED: button.justReleased();
			default: false;
		}
	}

	override public function destroy():Void
	{
		instances.remove(this);
		relayout = null;

		super.destroy();
	}
}

/**
 * Samples touch input for all virtual buttons once per frame.
 */
class MobileInputPlugin extends FlxBasic
{
	public function new():Void
	{
		super();

		visible = false;
	}

	override public function update(elapsed:Float):Void
	{
		MobileInput.updateAll();
	}
}
