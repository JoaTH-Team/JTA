package jta.states;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import jta.locale.Locale;
import jta.states.BaseState;
import jta.states.MainMenu;
import jta.util.github.GitHubUtil;
import jta.mobile.MobileInput;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * One contributor's box on the credits menu (same style as the mod menu's rows).
 */
class CreditRow extends FlxSpriteGroup
{
	public static final ROW_WIDTH:Int = 944;
	public static final ROW_HEIGHT:Int = 84;
	public static final AVATAR_SIZE:Int = 64;

	public var contributor(default, null):Contributor;

	var border:FlxSprite;
	var inner:FlxSprite;
	var avatar:FlxSprite;
	var nameText:FlxText;
	var commitsText:FlxText;

	public function new(contributor:Contributor)
	{
		super();

		this.contributor = contributor;

		border = new FlxSprite().makeGraphic(ROW_WIDTH, ROW_HEIGHT, FlxColor.WHITE);
		add(border);

		inner = new FlxSprite(4, 4).makeGraphic(ROW_WIDTH - 8, ROW_HEIGHT - 8, FlxColor.WHITE);
		add(inner);

		avatar = new FlxSprite(10, (ROW_HEIGHT - AVATAR_SIZE) / 2);
		add(avatar);
		setAvatar(null);

		nameText = TextUtil.make(AVATAR_SIZE + 24, 0, ROW_WIDTH - AVATAR_SIZE - 260, contributor.login, 32);
		nameText.borderSize = 2;
		nameText.y = (ROW_HEIGHT - nameText.height) / 2;
		add(nameText);

		commitsText = TextUtil.make(ROW_WIDTH - 230, 0, 210, Locale.replaceFlagsAndReturn("$CREDITS_COMMITS", 'menu', ['<X>'], [contributor.contributions]),
			24, RIGHT, FlxColor.fromRGB(190, 190, 210));
		commitsText.y = (ROW_HEIGHT - commitsText.height) / 2;
		add(commitsText);

		setSelected(false);
	}

	/**
	 * Shows a profile picture, or a gray square while it's loading (or if it failed).
	 */
	public function setAvatar(graphic:Null<FlxGraphic>):Void
	{
		final avatarX:Float = avatar.x;
		final avatarY:Float = avatar.y;

		if (graphic != null)
		{
			avatar.loadGraphic(graphic);
			avatar.antialiasing = true;
		}
		else
			avatar.makeGraphic(AVATAR_SIZE, AVATAR_SIZE, 0xFF404040);

		avatar.setGraphicSize(AVATAR_SIZE, AVATAR_SIZE);
		avatar.updateHitbox();
		avatar.setPosition(avatarX, avatarY);
	}

	public function setSelected(selected:Bool):Void
	{
		border.color = selected ? FlxColor.YELLOW : FlxColor.fromRGB(80, 80, 100);
		inner.color = selected ? FlxColor.fromRGB(40, 44, 82) : FlxColor.fromRGB(22, 22, 38);
		inner.alpha = 0.9;
		nameText.color = selected ? FlxColor.YELLOW : FlxColor.WHITE;
		avatar.alpha = selected ? 1 : 0.75;
	}
}

/**
 * Lists the GitHub contributors of the game's repository, with their profile pictures.
 * Up/down to scroll, confirm to open someone's GitHub profile, cancel to go back.
 */
class Credits extends BaseState
{
	/**
	 * How many boxes fit on screen at once.
	 */
	static inline var VISIBLE_ROWS:Int = 6;

	/**
	 * Space between boxes.
	 */
	static inline var ROW_GAP:Int = 8;

	/**
	 * Y position of the first box.
	 */
	static inline var LIST_Y:Int = 84;

	/**
	 * Contributors from the last successful fetch, kept so reopening the menu
	 * doesn't hit GitHub again (unauthenticated requests are limited to 60 an hour).
	 */
	static var cachedContributors:Null<Array<Contributor>> = null;

	/**
	 * Profile pictures already downloaded, by login.
	 */
	static final cachedAvatars:Map<String, FlxGraphic> = [];

	var contributors:Array<Contributor> = [];
	var rows:Array<CreditRow> = [];
	var selectedIndex:Int = 0;
	var scrollTop:Int = 0;

	var rowGroup:FlxTypedGroup<CreditRow>;
	var statusText:FlxText;

	var loading:Bool = true;

	/**
	 * Set when the state is destroyed, so late downloads don't touch it.
	 */
	var closed:Bool = false;

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Credits Menu', null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/settings_bg'));
		bg.screenCenter();
		add(bg);

		var title:FlxText = TextUtil.make(10, 10, FlxG.width, Locale.getMenu("$CREDITS"), 40);
		add(title);

		rowGroup = new FlxTypedGroup<CreditRow>();
		add(rowGroup);

		statusText = TextUtil.make(0, 0, FlxG.width, Locale.getMenu("$CREDITS_LOADING"), 36, CENTER);
		statusText.screenCenter(Y);
		add(statusText);

		#if mobile
		var mobileControls:MobileInput = new MobileInput();
		mobileControls.setupMenuVertical();
		add(mobileControls);
		#end

		super.create();

		if (cachedContributors != null)
			showContributors(cachedContributors);
		else
		{
			GitHubUtil.requestContributors(function(result:Array<Contributor>):Void
			{
				if (result.length > 0)
					cachedContributors = result;

				if (!closed)
					showContributors(result);
			});
		}
	}

	override public function destroy():Void
	{
		closed = true;

		super.destroy();
	}

	function showContributors(list:Array<Contributor>):Void
	{
		loading = false;

		contributors = [for (c in list) if (c.type != 'Bot') c];

		if (contributors.length == 0)
		{
			statusText.text = Locale.getMenu("$CREDITS_FAILED");
			statusText.screenCenter(Y);
			return;
		}

		statusText.visible = false;

		for (contributor in contributors)
		{
			final row:CreditRow = new CreditRow(contributor);
			row.x = (FlxG.width - CreditRow.ROW_WIDTH) / 2;
			rows.push(row);
			rowGroup.add(row);

			if (cachedAvatars.exists(contributor.login))
				row.setAvatar(cachedAvatars.get(contributor.login));
			else
				loadAvatar(contributor, row);
		}

		updateList(false);
	}

	/**
	 * Downloads a contributor's profile picture and puts it in their box once it arrives.
	 */
	function loadAvatar(contributor:Contributor, row:CreditRow):Void
	{
		GitHubUtil.requestAvatar(contributor, CreditRow.AVATAR_SIZE * 2, function(bitmap:Null<BitmapData>):Void
		{
			if (bitmap == null)
				return;

			final graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, 'github-avatar:${contributor.login}');
			graphic.persist = true;
			graphic.destroyOnNoUse = false;
			cachedAvatars.set(contributor.login, graphic);

			if (!closed)
				row.setAvatar(graphic);
		});
	}

	override public function update(elapsed:Float):Void
	{
		if (!loading && contributors.length > 0)
		{
			if (Input.justPressed('up'))
				changeSelection(-1);
			else if (Input.justPressed('down'))
				changeSelection(1);

			if (Input.justPressed('confirm'))
			{
				SoundController.play(Paths.sound('select'));
				FlxG.openURL(contributors[selectedIndex].html_url);
			}
		}

		if (Input.justPressed('cancel'))
		{
			SoundController.play(Paths.sound('cancel'));
			transitionState(new MainMenu());
		}

		super.update(elapsed);
	}

	function changeSelection(num:Int):Void
	{
		SoundController.play(Paths.sound('scroll'));
		selectedIndex = FlxMath.wrap(selectedIndex + num, 0, contributors.length - 1);
		updateList();
	}

	function updateList(?animate:Bool = true):Void
	{
		if (selectedIndex < scrollTop)
			scrollTop = selectedIndex;
		else if (selectedIndex >= scrollTop + VISIBLE_ROWS)
			scrollTop = selectedIndex - VISIBLE_ROWS + 1;

		for (i in 0...rows.length)
		{
			final row:CreditRow = rows[i];
			final visibleIndex:Int = i - scrollTop;
			final targetY:Float = LIST_Y + visibleIndex * (CreditRow.ROW_HEIGHT + ROW_GAP);

			row.setSelected(i == selectedIndex);
			row.visible = visibleIndex >= 0 && visibleIndex < VISIBLE_ROWS;

			FlxTween.cancelTweensOf(row, ['y']);
			if (animate)
				FlxTween.tween(row, {y: targetY}, 0.12, {ease: FlxEase.quadOut});
			else
				row.y = targetY;
		}
	}
}
