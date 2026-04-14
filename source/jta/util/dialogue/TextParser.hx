package jta.util.dialogue;

/**
 * Represents parsed text with cleaned content and extracted actions.
 */
typedef ParsedText =
{
	/**
	 * The text with tags removed.
	 */
	cleanedText:String,

	/**
	 * List of actions extracted from the text.
	 */
	actions:Array<Action>
}

/**
 * Represents an action found in the text.
 */
typedef Action =
{
	/**
	 * Position in the cleaned text where the action occurs.
	 */
	index:Int,

	/**
	 * The action type.
	 */
	type:String,

	/**
	 * The action value.
	 */
	value:String
}

/**
 * Class for parsing text with embedded actions.
 */
class TextParser
{
	/**
	 * Regex for matching tags in the text.
	 */
	private static final PARSE_REGEX:EReg = ~/(\[([a-zA-Z]+):([^\]]+)\])/;

	/**
	 * Parses the text, removing tags and returning the cleaned text and actions.
	 * @param text The input text with potential tags.
	 * @return A ParsedText object with the cleaned text and extracted actions.
	 */
	public static function parse(text:String):ParsedText
	{
		final cleanedText:StringBuf = new StringBuf();
		final actions:Array<Action> = new Array<Action>();

		var lastPos:Int = 0;
		var matchPos:Int = 0;

		while (PARSE_REGEX.match(text))
		{
			matchPos = PARSE_REGEX.matchedPos().pos;

			final fullMatch:String = PARSE_REGEX.matched(1);
			final type:String = PARSE_REGEX.matched(2);
			final value:String = PARSE_REGEX.matched(3);

			cleanedText.addSub(text, lastPos, matchPos - lastPos);

			actions.push({index: cleanedText.length, type: type, value: value});

			lastPos = matchPos + fullMatch.length;
			text = text.substr(lastPos);
			lastPos = 0;
		}

		cleanedText.addSub(text, lastPos, text.length - lastPos);

		return {cleanedText: cleanedText.toString(), actions: actions};
	}
}
