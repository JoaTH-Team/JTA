package jta.states;

import jta.Assets;
import jta.locale.Locale;
import jta.modding.PolymodHandler;
import jta.states.BaseState;
import jta.states.MainMenu;
import jta.mobile.MobileInput;
import jta.util.FolderUtil;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import polymod.Polymod.ModMetadata;

class ModRow extends FlxSpriteGroup
{
	public static final ROW_WIDTH:Int = 944;
	public static final ROW_HEIGHT:Int = 84;
	public static final ICON_SIZE:Int = 64;

	public var mod:ModMetadata;
	public var enabled:Bool = true;

	var border:FlxSprite;
	var inner:FlxSprite;
	var icon:FlxSprite;
	var titleText:FlxText;
	var infoText:FlxText;
	var stateText:FlxText;

	var selected:Bool = false;

	public function new(mod:ModMetadata, enabled:Bool)
	{
		super();

		this.mod = mod;
		this.enabled = enabled;

		border = new FlxSprite().makeGraphic(ROW_WIDTH, ROW_HEIGHT, FlxColor.WHITE);
		add(border);

		inner = new FlxSprite(4, 4).makeGraphic(ROW_WIDTH - 8, ROW_HEIGHT - 8, FlxColor.WHITE);
		add(inner);

		icon = ModIcon.create(mod, ICON_SIZE);
		icon.x = 10 + (ICON_SIZE - icon.width) / 2;
		icon.y = (ROW_HEIGHT - icon.height) / 2;
		add(icon);

		titleText = TextUtil.make(ICON_SIZE + 24, 8, ROW_WIDTH - ICON_SIZE - 160, '', 30);
		titleText.borderSize = 2;
		add(titleText);

		infoText = TextUtil.make(ICON_SIZE + 24, 48, ROW_WIDTH - ICON_SIZE - 160, '', 20, LEFT, FlxColor.fromRGB(190, 190, 210));
		add(infoText);

		stateText = TextUtil.make(ROW_WIDTH - 130, 22, 110, '', 32, RIGHT);
		stateText.borderSize = 2;
		add(stateText);

		var info:String = 'v${mod.modVersion?.toString() ?? '1.0.0'}';
		final author:Null<String> = getAuthor(mod);
		if (author != null && author != '')
			info += '  -  ' + Locale.replaceFlagsAndReturn("$MOD_AUTHOR", 'menu', ['<X>'], [author]);
		infoText.text = info;

		refresh(0);
	}

	public static function getAuthor(mod:ModMetadata):Null<String>
	{
		final contributors:Null<Array<Dynamic>> = mod.contributors;

		if (contributors != null && contributors.length > 0)
		{
			final name:Null<String> = contributors[0]?.name;
			if (name != null && name != '')
				return name;
		}

		@:privateAccess
		return mod._author;
	}

	public function refresh(position:Int):Void
	{
		final title:String = (mod.title != null && mod.title != '') ? mod.title : mod.id;
		titleText.text = '${position + 1}. $title';

		stateText.text = Locale.getSettings(enabled ? "$ON" : "$OFF");
		stateText.color = enabled ? FlxColor.LIME : FlxColor.RED;

		icon.alpha = enabled ? 1 : 0.4;
		titleText.color = enabled ? (selected ? FlxColor.YELLOW : FlxColor.WHITE) : FlxColor.GRAY;

		border.color = selected ? FlxColor.YELLOW : FlxColor.fromRGB(80, 80, 100);
		inner.color = selected ? FlxColor.fromRGB(40, 44, 82) : FlxColor.fromRGB(22, 22, 38);
		inner.alpha = 0.9;
	}

	public function setSelected(value:Bool, position:Int):Void
	{
		selected = value;
		refresh(position);
	}
}

/**
 * Builds mod icon sprites from a mod's `_polymod_icon.png`.
 *
 * Icons can be animated two ways:
 * - **Sparrow atlas:** put a `_polymod_icon.xml` next to the icon. Every frame in it is played in order.
 * - **Strip:** a horizontal strip of same-size frames, with the frame count set in `_polymod_meta.json`:
 *   `"metadata": { "iconFrames": "8" }`
 *
 * Either way, the speed can be set with `"metadata": { "iconFramerate": "12" }` (default 12).
 */
class ModIcon
{
	public static final DEFAULT_FRAMERATE:Float = 12;

	/**
	 * Creates a sprite for a mod's icon, scaled to fit in a square box.
	 * @param mod The mod.
	 * @param size The size of the box, in pixels.
	 */
	public static function create(mod:ModMetadata, size:Int):FlxSprite
	{
		final sprite:FlxSprite = new FlxSprite();
		var loaded:Bool = false;

		try
		{
			loaded = loadInto(sprite, mod);
		}
		catch (e:Dynamic)
			trace('Couldn\'t load the icon of mod "${mod.id}": $e');

		if (!loaded)
			sprite.loadGraphic(Paths.image('menu/mods/no_icon'));

		var scale:Float = Math.min(size / sprite.frameWidth, size / sprite.frameHeight);
		if (scale >= 1)
			scale = Math.max(1, Math.floor(scale));

		sprite.scale.set(scale, scale);
		sprite.updateHitbox();
		sprite.antialiasing = scale < 1;

		return sprite;
	}

	static function loadInto(sprite:FlxSprite, mod:ModMetadata):Bool
	{
		final bytes = mod.icon;
		if (bytes == null)
			return false;

		final bitmap:Null<BitmapData> = BitmapData.fromBytes(ByteArray.fromBytes(bytes));
		if (bitmap == null)
			return false;

		final graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, 'modicon:${mod.id}');
		final framerate:Float = getMetaFloat(mod, 'iconFramerate', DEFAULT_FRAMERATE);

		final xml:Null<String> = PolymodHandler.readModText(mod, PolymodHandler.ICON_XML_FILE);

		if (xml != null)
		{
			sprite.frames = FlxAtlasFrames.fromSparrow(graphic, xml);

			if (sprite.frames != null && sprite.frames.numFrames > 0)
			{
				sprite.animation.addByPrefix('icon', '', framerate, true);
				sprite.animation.play('icon');
				return true;
			}
		}

		final frameCount:Int = Std.int(getMetaFloat(mod, 'iconFrames', 1));

		if (frameCount > 1 && bitmap.width % frameCount == 0)
		{
			sprite.loadGraphic(graphic, true, Std.int(bitmap.width / frameCount), bitmap.height);
			sprite.animation.add('icon', [for (i in 0...frameCount) i], framerate, true);
			sprite.animation.play('icon');
			return true;
		}

		sprite.loadGraphic(graphic);
		return true;
	}

	static function getMetaFloat(mod:ModMetadata, key:String, fallback:Float):Float
	{
		final value:Null<String> = mod.metadata?.get(key);
		if (value == null)
			return fallback;

		final parsed:Float = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}
}

class ModMenu extends BaseState
{
	static final LIST_TOP:Float = 84;
	static final ROW_GAP:Float = 8;
	static final VISIBLE_ROWS:Int = 5;

	var rows:Array<ModRow> = [];
	var selectedIndex:Int = 0;
	var scrollIndex:Int = 0;

	var descText:FlxText;

	var initialState:String = '';

	var leaving:Bool = false;

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Mod Menu', null);
		#end

		if (!(FlxG.sound.music?.playing ?? false))
			SoundController.playMusic(Paths.music('Pumpin_Pixels'));

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/settings_bg'));
		bg.screenCenter();
		add(bg);

		var title:FlxText = TextUtil.make(10, 10, FlxG.width, Locale.getMenu("$MODS").toUpperCase(), 40);
		add(title);

		PolymodHandler.getMods();

		for (mod in PolymodHandler.trackedMods)
		{
			final row:ModRow = new ModRow(mod, PolymodHandler.isModEnabled(mod.id));
			row.x = (FlxG.width - ModRow.ROW_WIDTH) / 2;
			rows.push(row);
			add(row);
		}

		initialState = describeState();

		var panel:FlxSprite = new FlxSprite((FlxG.width - ModRow.ROW_WIDTH) / 2, 560).makeGraphic(ModRow.ROW_WIDTH, 140, FlxColor.BLACK);
		panel.alpha = 0.6;
		add(panel);

		descText = TextUtil.make(panel.x + 16, panel.y + 12, ModRow.ROW_WIDTH - 32, '', 22);
		add(descText);

		var hint:FlxText = TextUtil.make(0, 712, FlxG.width, Locale.getMenu("$MODS_HINT"), 20, CENTER, FlxColor.fromRGB(200, 200, 220));
		add(hint);

		if (rows.length == 0)
		{
			panel.visible = false;
			hint.visible = false;

			var empty:FlxText = TextUtil.make(0, 0, FlxG.width, Locale.getMenu("$NO_MODS"), 34, CENTER);
			empty.screenCenter(Y);
			add(empty);
		}

		#if mobile
		var mobileControls:MobileInput = new MobileInput();
		mobileControls.setupMenuFull();

		mobileControls.addButton(FlxG.width - MobileInput.margin - MobileInput.utilSize, MobileInput.margin, 'openmods', 'util', 'folder',
			MobileInput.utilSize);
		add(mobileControls);

		var folderText:FlxText = TextUtil.make(10, 54, FlxG.width - 20,
			Locale.replaceFlagsAndReturn("$MODS_FOLDER", 'menu', ['<X>'], [FolderUtil.getDisplayPath(PolymodHandler.getModsFolder())]), 18, LEFT,
			FlxColor.fromRGB(200, 200, 220));
		add(folderText);
		#end

		super.create();

		updateRows(false);
	}

	function describeState():String
		return [for (row in rows) '${row.mod.id}:${row.enabled ? 1 : 0}'].join(',');

	#if mobile
	/**
	 * Opens the mods folder in the file manager, and pops up where it is (some file managers ignore the request).
	 */
	function openModsFolder():Void
	{
		SoundController.play(Paths.sound('select'));

		final folder:String = PolymodHandler.getModsFolder();
		FolderUtil.openFolder(folder);

		#if android
		extension.androidtools.widget.Toast.makeText(Locale.replaceFlagsAndReturn("$MODS_FOLDER", 'menu', ['<X>'], [FolderUtil.getDisplayPath(folder)]),
			extension.androidtools.widget.Toast.LENGTH_LONG);
		#end

		FlxG.signals.focusGained.addOnce(function():Void
		{
			if (FlxG.state == this && !leaving && describeState() == initialState)
				FlxG.resetState();
		});
	}
	#end

	override public function update(elapsed:Float):Void
	{
		#if mobile
		if (!leaving && Input.justPressed('openmods'))
			openModsFolder();
		#end

		if (!leaving)
		{
			if (rows.length > 0)
			{
				if (Input.justPressed('up'))
					changeSelection(-1);
				else if (Input.justPressed('down'))
					changeSelection(1);

				if (Input.justPressed('confirm'))
					toggleSelected();
				else if (Input.justPressed('left'))
					moveSelected(-1);
				else if (Input.justPressed('right'))
					moveSelected(1);
			}

			if (Input.justPressed('cancel'))
				exit();
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int):Void
	{
		SoundController.play(Paths.sound('scroll'));
		selectedIndex = FlxMath.wrap(selectedIndex + change, 0, rows.length - 1);
		updateRows();
	}

	function toggleSelected():Void
	{
		final row:ModRow = rows[selectedIndex];
		row.enabled = !row.enabled;
		SoundController.play(Paths.sound(row.enabled ? 'select' : 'cancel'));
		updateRows();
	}

	function moveSelected(direction:Int):Void
	{
		final target:Int = selectedIndex + direction;

		if (target < 0 || target >= rows.length)
			return;

		final row:ModRow = rows[selectedIndex];
		rows[selectedIndex] = rows[target];
		rows[target] = row;
		selectedIndex = target;

		SoundController.play(Paths.sound('scroll'));
		updateRows();
	}

	function updateRows(?animate:Bool = true):Void
	{
		if (selectedIndex < scrollIndex)
			scrollIndex = selectedIndex;
		else if (selectedIndex >= scrollIndex + VISIBLE_ROWS)
			scrollIndex = selectedIndex - VISIBLE_ROWS + 1;

		for (i in 0...rows.length)
		{
			final row:ModRow = rows[i];
			final visibleIndex:Int = i - scrollIndex;
			final targetY:Float = LIST_TOP + visibleIndex * (ModRow.ROW_HEIGHT + ROW_GAP);

			row.setSelected(i == selectedIndex, i);
			row.visible = visibleIndex >= 0 && visibleIndex < VISIBLE_ROWS;

			FlxTween.cancelTweensOf(row, ['y']);
			if (animate)
				FlxTween.tween(row, {y: targetY}, 0.12, {ease: FlxEase.quadOut});
			else
				row.y = targetY;
		}

		if (rows.length > 0)
		{
			final mod:ModMetadata = rows[selectedIndex].mod;
			descText.text = (mod.description != null && mod.description != '') ? mod.description : mod.id;
		}
	}

	function exit():Void
	{
		leaving = true;
		SoundController.play(Paths.sound('cancel'));

		if (describeState() == initialState)
		{
			transitionState(new MainMenu());
			return;
		}

		PolymodHandler.saveModSettings([for (row in rows) row.mod.id], [for (row in rows) if (!row.enabled) row.mod.id]);

		var reloading:FlxText = TextUtil.make(0, 0, FlxG.width, Locale.getMenu("$MODS_RELOADING"), 40, CENTER, FlxColor.YELLOW);
		reloading.screenCenter(Y);
		add(reloading);

		new FlxTimer().start(0.05, function(_):Void
		{
			PolymodHandler.load();
			transitionState(new MainMenu());
		});
	}
}
