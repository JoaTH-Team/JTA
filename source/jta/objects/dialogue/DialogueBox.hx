package jta.objects.dialogue;

import flixel.group.FlxSpriteGroup;
import flixel.addons.display.shapes.FlxShapeBox;
import jta.registries.dialogue.PortraitRegistry;
import jta.objects.dialogue.portraits.Portrait;
import jta.objects.dialogue.Writer;

/**
 * Enum for the position of the dialogue box.
 */
enum DialogueBoxPosition
{
	TOP;
	BOTTOM;
	CUSTOM(x:Int, y:Int);
}

/**
 * A dialogue box that displays text and a character portrait.
 */
class DialogueBox extends FlxSpriteGroup
{
	/**
	 * The width of the dialogue box.
	 */
	@:noCompletion
	private static final BOX_WIDTH:Int = 600;

	/**
	 * The height of the dialogue box.
	 */
	@:noCompletion
	private static final BOX_HEIGHT:Int = 150;

	/**
	 * A function that's called when the dialogue finishes.
	 */
	public var finishCallback:Void->Void;

	/**
	 * The background box of the dialogue, rendered as a `FlxShapeBox`.
	 */
	@:noCompletion
	private var box:FlxShapeBox;

	/**
	 * The current portrait being displayed in the dialogue box.
	 */
	@:noCompletion
	private var portrait:Portrait;

	/**
	 * The writer that handles displaying text in the dialogue box.
	 */
	@:noCompletion
	private var writer(default, null):Writer;

	/**
	 * Initializes the dialogue box with a specified position.
	 * @param position The position of the dialogue box on the screen.
	 */
	public function new(?position:DialogueBoxPosition = BOTTOM):Void
	{
		super();

		var x:Float = Std.int((FlxG.width - BOX_WIDTH) / 2);
		var y:Float = switch (position)
		{
			case TOP: 10;
			case BOTTOM: 320;
			case CUSTOM(cx, cy): cy;
		};

		box = new FlxShapeBox(x, y, BOX_WIDTH, BOX_HEIGHT, {thickness: 6, jointStyle: MITER, color: FlxColor.BLACK}, FlxColor.WHITE);
		box.scrollFactor.set();
		box.active = false;
		add(box);

		writer = new Writer(box.x, box.y);
		writer.finishCallback = function():Void
		{
			if (finishCallback != null)
				finishCallback();
		}
		writer.onPortraitChange.add(function(id:String):Void
		{
			if (id == null || id.length <= 0)
				writer.setPosition(box.x, box.y);
			else if (portrait == null || portrait.portraitID != id)
			{
				if (portrait != null)
					remove(portrait);

				portrait = PortraitRegistry.fetchPortrait(id);
				portrait.setPosition(box.x, box.y);
				portrait.scrollFactor.set();
				insert(members.indexOf(box) + 1, portrait);

				writer.setPosition(box.x + 104, box.y);
			}
		});
		writer.onFaceChange.add(function(expression:String):Void
		{
			if (portrait != null)
				portrait.changeFace(expression);
		});
		writer.scrollFactor.set();
		add(writer);
	}

	public function setBoxPosition(x:Int, y:Int):Void
	{
		box.setPosition(x, y);
		if (portrait != null)
		{
			portrait.setPosition(box.x, box.y);
			writer.setPosition(box.x + 104, box.y);
		}
		else
			writer.setPosition(box.x, box.y);
	}

	public function setPositionType(position:DialogueBoxPosition):Void
	{
		var x = Std.int((FlxG.width - BOX_WIDTH) / 2);
		var y = switch (position)
		{
			case TOP: 10;
			case BOTTOM: FlxG.height - BOX_HEIGHT - 10;
			case CUSTOM(_, cy): cy;
		};
		setBoxPosition(x, y);
	}

	/**
	 * Starts the dialogue with the provided list of dialogue data.
	 * @param list The list of `WriterData` objects representing dialogue pages.
	 */
	public inline function startDialogue(list:Array<WriterData>):Void
	{
		writer.startDialogue(list);
	}
}
