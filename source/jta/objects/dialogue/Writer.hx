package jta.objects.dialogue;

import flixel.util.FlxSignal;
import jta.registries.dialogue.TyperRegistry;
import jta.objects.dialogue.TextTyper;
import jta.input.Input;

using flixel.util.FlxArrayUtil;

typedef WriterData =
{
	typer:String,
	?portrait:String,
	text:String
}

/**
 * Represents a dialogue writer that displays text sequentially, allowing the player to advance or skip through dialogue pages.
 * Handles the display of dialogue using different typers and invokes a callback when the dialogue is finished.
 */
class Writer extends TextTyper
{
	/**
	 * Whether or not the player can skip the dialogue text.
	 */
	public var skippable:Bool = true;

	/**
	 * Callback function to be executed when all dialogue pages are completed.
	 */
	public var finishCallback:Void->Void = null;

	public var onPortraitChange:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * Whether or not the dialogue has been completed.
	 */
	@:noCompletion
	private var done:Bool = false;

	/**
	 * A list of `WriterData` objects, each containing a typer and text for the dialogue.
	 */
	@:noCompletion
	private var list:Array<WriterData> = [];

	/**
	 * The current page of the dialogue being displayed.
	 */
	@:noCompletion
	private var page:Int = 0;

	/**
	 * Starts the dialogue sequence with the provided list of dialogue data.
	 * @param list The list of `WriterData` objects representing the dialogue pages.
	 */
	public function startDialogue(list:Array<WriterData>):Void
	{
		this.list = list ?? [{typer: 'default', text: 'Error!'}];

		page = 0;

		if (list[page] != null)
			changeDialogue(list[page]);
	}

	/**
	 * Changes the current dialogue page to the specified `WriterData`.
	 * @param dialogue The `WriterData` object containing the typer and text for the dialogue page.
	 */
	public function changeDialogue(dialogue:WriterData):Void
	{
		if (dialogue == null)
			dialogue = {typer: 'default', text: 'Error!'};

		onPortraitChange.dispatch(dialogue.portrait ?? '');

		done = false;

		start(TyperRegistry.fetchTyper(dialogue.typer ?? 'default'), dialogue.text);
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (Input.justPressed('confirm') && finished && !done)
		{
			if (page < list.indexOf(list.last()))
			{
				page++;
				changeDialogue(list[page]);
			}
			else if (page == list.indexOf(list.last()))
			{
				if (finishCallback != null)
					finishCallback();

				done = true;
			}
		}
		else if (Input.justPressed('cancel') && !finished && skippable)
			skip();
	}
}
