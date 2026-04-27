package jta.objects.dialogue;

import jta.objects.dialogue.typers.Typer;
import jta.util.dialogue.TextParser;
import jta.util.FramerateUtil;
import flixel.sound.FlxSound;
import flixel.util.FlxSignal;
import flixel.util.FlxDestroyUtil;

/**
 * Displays text with a typewriter effect, revealing characters one by one.
 * Optionally plays a sound for each character and supports skipping to the end.
 */
class TextTyper extends FlxText
{
	/**
	 * Characters that will not trigger sound playback during the typing effect.
	 */
	private static final IGNORE_CHARACTERS:Array<String> = [' ', '\n', '*', '^', '/', '\\'];

	/**
	 * A callback that is dispatched when the dialogue tries to call a function.
	 */
	public var onFunctionCall:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * A callback that is dispatched when the dialogue tries to change the face of the current portrait.
	 */
	public var onFaceChange:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * Stores the original text that is being typed out.
	 */
	private var originalText:String = '';

	private var actions:Array<Action> = [];

	/**
	 * Current position in the text that has been revealed.
	 */
	private var textPos:Int = 0;

	/**
	 * The `Typer` object controlling the appearance and behavior of the typing effect.
	 */
	private var typer:Typer;

	private var delay:Float = 0;
	private var counter:Float = 0;

	private var typing:Bool = false;
	private var waiting:Bool = false;
	private var finished:Bool = false;
	private var sounds:Array<FlxSound> = [];

	/**
	 * Initializes the typer.
	 * @param x The x-coordinate of the text.
	 * @param y The y-coordinate of the text.
	 */
	public function new(x:Float, y:Float):Void
	{
		super(x, y, 0, '', 8, true);
		color = FlxColor.BLACK;
	}

	public override function update(elapsed:Float):Void
	{
		if (typing && !finished)
		{
			counter += elapsed;

			while (counter >= delay)
			{
				counter -= delay;
				processText();
			}
		}

		super.update(elapsed);
	}

	public override function destroy():Void
	{
		super.destroy();

		counter = 0;
		typing = false;
		finished = true;
		waiting = false;
		typer = FlxDestroyUtil.destroy(typer);
	}

	/**
	 * Starts typing out the specified text using the provided `Typer`.
	 * @param typer The `Typer` instance controlling the typing effect.
	 * @param text The text to be typed out.
	 */
	public function start(typer:Typer, text:String):Void
	{
		setupTyper(typer);

		counter = 0;
		waiting = finished = false;
		textPos = 0;

		final parsedText:ParsedText = TextParser.parse(text);

		originalText = parsedText.cleanedText;
		actions = parsedText.actions;

		processText();

		typing = true;
	}

	/**
	 * Skips the typing effect, immediately displaying the full text.
	 */
	public function skip():Void
	{
		if (typing && !waiting && !finished)
		{
			textPos = originalText.length;
			processText();
		}
	}

	private inline function setupTyper(typer:Typer):Void
	{
		if (this.typer != null && this.typer != typer)
			this.typer.destroy();

		if (font != typer.fontName)
			font = typer.fontName;

		if (size != typer.fontSize)
			size = typer.fontSize;

		if (typer.fontSpacing != null && letterSpacing != typer.fontSpacing)
			letterSpacing = typer.fontSpacing;

		if (offset != typer.typerOffset)
			offset.copyFrom(typer.typerOffset);

		for (s in sounds)
			s.destroy();
		sounds = [];

		for (typingSound in typer.typerSounds)
		{
			if (typingSound == null)
				continue;

			final sound:FlxSound = FlxG.sound.load(typingSound.sound, typingSound.volume);

			if (typingSound.pitch != null)
				sound.pitch = typingSound.pitch;

			sounds.push(sound);
		}

		delay = FramerateUtil.SINGLE_FRAME_TIMING * typer.typerFPS;

		this.typer = typer;
	}

	private function processText():Void
	{
		processActions();

		if (updateTextPos())
			updateText();
	}

	private function updateTextPos():Bool
	{
		if (waiting)
			return false;

		final currentChar:String = originalText.charAt(textPos);

		playSounds(currentChar);

		textPos++;

		if (IGNORE_CHARACTERS.contains(currentChar))
			return updateTextPos();

		if (textPos > originalText.length)
			textPos = originalText.length;

		return true;
	}

	private function updateText():Void
	{
		final curText:String = originalText.substr(0, textPos);

		if (text != curText)
		{
			text = curText;

			if (textPos >= originalText.length)
			{
				counter = 0;
				typing = false;
				finished = true;
				waiting = false;
			}
		}
	}

	private function processActions():Void
	{
		if (actions != null && actions.length > 0)
		{
			while (actions.length > 0 && actions[0].index == textPos)
			{
				final action:Action = actions.shift();

				FlxG.log.notice('Currently trying to dispatch ${action.type} event.');

				switch (action.type)
				{
					case 'speed':
						final speed:Null<Float> = Std.parseFloat(action.value);

						if (speed != null && speed > 0)
							delay = FramerateUtil.SINGLE_FRAME_TIMING * speed;
					case 'wait':
						final waitTime:Null<Float> = Std.parseFloat(action.value);

						if (waitTime != null && waitTime > 0)
						{
							waiting = true;
							FlxTimer.wait(waitTime, () -> waiting = false);
							break;
						}
					case 'w':
						final waitTime:Null<Int> = Std.parseInt(action.value);

						if (waitTime != null && waitTime > 0)
						{
							waiting = true;
							FlxTimer.wait(FramerateUtil.SINGLE_FRAME_TIMING * waitTime, () -> waiting = false);
							break;
						}
					case 'function':
						if (onFunctionCall != null)
							onFunctionCall.dispatch(action.value);
					case 'face':
						if (onFaceChange != null)
							onFaceChange.dispatch(action.value);
				}
			}
		}
	}

	private function playSounds(currentChar:String):Void
	{
		if (sounds?.length > 0 && !IGNORE_CHARACTERS.contains(currentChar))
		{
			for (sound in sounds)
				sound.stop();

			sounds[FlxG.random.int(0, sounds.length - 1)].play();
		}
	}
}
