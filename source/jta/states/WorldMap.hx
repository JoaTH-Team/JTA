package jta.states;

import jta.Assets;
import jta.Global;
import jta.locale.Locale;
import jta.registries.LevelRegistry;
import jta.states.BaseState;
import jta.states.LevelSelect;
import jta.states.SaveSelect;
import jta.states.level.LevelData;
import jta.states.level.WorldRun;
import jta.mobile.MobileInput;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * One world on the world map.
 */
typedef MapNode =
{
	var worldId:String;
	var status:WorldStatus;
	var x:Float;
	var y:Float;
	var sprite:FlxSprite;
	var label:FlxText;
}

/**
 * The overworld map, between the save select and the level select.
 *
 * The map is bigger than the screen and the camera follows the player as they walk between worlds.
 * Worlds come from `world.json` (`mapPosition`, `icon`, `hidden`), so new worlds show up on their own.
 *
 * Art (all in `images/menu/worldmap/`, drawn small and scaled up by `MAP_SCALE`):
 * - `map.png`  : the whole map. Node positions in `world.json` are in pixels of this image.
 * - `node.png` : 4 frames of 16x16: open, cleared, locked, coming soon.
 * - `path.png` : one dot of the path drawn between worlds.
 */
class WorldMap extends BaseState
{
	/**
	 * How much the map art is scaled up.
	 */
	public static final MAP_SCALE:Float = 4;

	/**
	 * Set to `false` once the path is drawn into `map.png` itself.
	 */
	public static final DRAW_PATH:Bool = true;

	/**
	 * How fast the player walks between worlds, in pixels per second (after scaling).
	 */
	static final WALK_SPEED:Float = 420;

	static final PATH_DOT_SPACING:Float = 36;

	var nodes:Array<MapNode> = [];
	var currentIndex:Int = 0;

	var player:FlxSprite;
	var walking:Bool = false;

	var camHUD:FlxCamera;

	var worldNameText:FlxText;
	var worldInfoText:FlxText;

	var popup:FlxTypedGroup<FlxSprite>;
	var popupTitle:FlxText;
	var popupOptions:Array<FlxText> = [];
	var popupOpen:Bool = false;
	var popupIndex:Int = 0;

	var leaving:Bool = false;

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('World Map', null);
		#end

		WorldRun.stop();
		jta.states.level.Level.clearCheckpoint();
		jta.objects.HUD.resetLifeTracking();

		if (!(FlxG.sound.music?.playing ?? false))
			SoundController.playMusic(Paths.music('Pumpin_Pixels'));

		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);

		final worlds:Array<String> = LevelRegistry.listWorlds();

		var map:FlxSprite = new FlxSprite();

		if (Assets.exists(Paths.image('menu/worldmap/map')))
		{
			map.loadGraphic(Paths.image('menu/worldmap/map'));
			map.scale.set(MAP_SCALE, MAP_SCALE);
			map.updateHitbox();
		}
		else
		{
			trace('Missing world map image, using a plain background');
			map.makeGraphic(Std.int(Math.max(FlxG.width, 300 * (worlds.length + 1))), FlxG.height, FlxColor.fromRGB(92, 168, 84));
		}

		map.antialiasing = false;
		add(map);

		final mapWidth:Float = Math.max(map.width, FlxG.width);
		final mapHeight:Float = Math.max(map.height, FlxG.height);

		var lastX:Float = -60;

		for (i in 0...worlds.length)
		{
			final worldId:String = worlds[i];
			final data:Null<WorldData> = LevelRegistry.getWorldData(worldId);

			final pos:FlxPoint = (data?.mapPosition != null) ? FlxPoint.get(data.mapPosition.x * MAP_SCALE,
				data.mapPosition.y * MAP_SCALE) : FlxPoint.get(lastX + 300, mapHeight / 2);

			lastX = pos.x;

			nodes.push({
				worldId: worldId,
				status: Global.getWorldStatus(worldId),
				x: pos.x,
				y: pos.y,
				sprite: null,
				label: null
			});

			pos.put();
		}

		if (DRAW_PATH)
			drawPath();

		for (node in nodes)
			createNode(node);

		player = new FlxSprite().loadGraphic(Paths.image('player/player'), true, 16, 16);
		player.animation.add('idle', [0], 1);
		player.animation.add('walk', [1, 0, 2, 0], 12);
		player.animation.add('dance', [5, 6, 7, 6], 12);
		player.animation.play('idle');
		player.scale.set(MAP_SCALE, MAP_SCALE);
		player.updateHitbox();
		player.antialiasing = false;
		add(player);

		currentIndex = findStartIndex();

		if (nodes.length > 0)
			placePlayerAt(nodes[currentIndex]);
		else
			player.visible = false;

		var boundsRight:Float = mapWidth;
		var boundsBottom:Float = mapHeight;

		for (node in nodes)
		{
			boundsRight = Math.max(boundsRight, node.x + 240);
			boundsBottom = Math.max(boundsBottom, node.y + 200);
		}

		if (boundsRight > map.width || boundsBottom > map.height)
			FlxG.camera.bgColor = map.pixels.getPixel32(map.frameWidth - 1, Std.int(map.frameHeight / 2));

		FlxG.camera.setScrollBoundsRect(0, 0, boundsRight, boundsBottom);
		FlxG.camera.follow(player, LOCKON, 0.12);
		FlxG.camera.snapToTarget();

		var bar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 100, FlxColor.BLACK);
		bar.alpha = 0.55;
		bar.cameras = [camHUD];
		add(bar);

		worldNameText = TextUtil.make(0, 10, FlxG.width, '', 42, CENTER);
		worldNameText.borderSize = 3;
		worldNameText.cameras = [camHUD];
		add(worldNameText);

		worldInfoText = TextUtil.make(0, 58, FlxG.width, '', 28, CENTER);
		worldInfoText.borderSize = 2;
		worldInfoText.cameras = [camHUD];
		add(worldInfoText);

		createPopup();
		updateHUD();

		#if mobile
		var mobileControls:MobileInput = new MobileInput(camHUD);
		mobileControls.setupMenuFull();
		add(mobileControls);
		#end

		super.create();

		if (leftWatermarkText != null)
			leftWatermarkText.cameras = [camHUD];
		if (rightWatermarkText != null)
			rightWatermarkText.cameras = [camHUD];
	}

	function drawPath():Void
	{
		final hasDot:Bool = Assets.exists(Paths.image('menu/worldmap/path'));

		for (i in 1...nodes.length)
		{
			final a:MapNode = nodes[i - 1];
			final b:MapNode = nodes[i];

			final dist:Float = Math.sqrt(Math.pow(b.x - a.x, 2) + Math.pow(b.y - a.y, 2));
			final count:Int = Std.int(dist / PATH_DOT_SPACING);
			final reachable:Bool = isWalkable(b.status);

			for (d in 1...count)
			{
				final t:Float = d / count;
				final dot:FlxSprite = new FlxSprite();

				if (hasDot)
				{
					dot.loadGraphic(Paths.image('menu/worldmap/path'));
					dot.scale.set(MAP_SCALE, MAP_SCALE);
					dot.updateHitbox();
				}
				else
					dot.makeGraphic(16, 16, FlxColor.fromRGB(250, 235, 190));

				dot.antialiasing = false;
				dot.x = a.x + (b.x - a.x) * t - dot.width / 2;
				dot.y = a.y + (b.y - a.y) * t - dot.height / 2;
				dot.alpha = reachable ? 1 : 0.35;
				add(dot);
			}
		}
	}

	function createNode(node:MapNode):Void
	{
		final icon:Null<String> = LevelRegistry.getWorldData(node.worldId)?.icon;
		var image:String = 'menu/worldmap/node';

		if (icon != null && Assets.exists(Paths.image('menu/worldmap/$icon')))
			image = 'menu/worldmap/$icon';

		final sprite:FlxSprite = new FlxSprite();

		if (Assets.exists(Paths.image(image)))
			sprite.loadGraphic(Paths.image(image), true, 16, 16);
		else
			sprite.makeGraphic(16, 16, FlxColor.WHITE);

		sprite.animation.add('status', [Std.int(Math.min(node.status, sprite.animation.numFrames - 1))], 1);
		sprite.animation.play('status');
		sprite.scale.set(MAP_SCALE, MAP_SCALE);
		sprite.updateHitbox();
		sprite.antialiasing = false;
		sprite.setPosition(node.x - sprite.width / 2, node.y - sprite.height / 2);
		add(sprite);

		final label:FlxText = TextUtil.make(node.x - 150, node.y + sprite.height / 2 + 2, 300, '', 22, CENTER);
		label.borderSize = 2;
		label.text = (node.status == LOCKED) ? '???' : LevelRegistry.getWorldName(node.worldId);
		label.alpha = isWalkable(node.status) ? 1 : 0.6;
		add(label);

		node.sprite = sprite;
		node.label = label;
	}

	function createPopup():Void
	{
		popup = new FlxTypedGroup<FlxSprite>();

		var shade:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		shade.alpha = 0.5;
		popup.add(shade);

		final boxW:Int = 560;
		final boxH:Int = 250;
		final boxX:Float = (FlxG.width - boxW) / 2;
		final boxY:Float = (FlxG.height - boxH) / 2;

		var border:FlxSprite = new FlxSprite(boxX, boxY).makeGraphic(boxW, boxH, FlxColor.YELLOW);
		popup.add(border);

		var inner:FlxSprite = new FlxSprite(boxX + 6, boxY + 6).makeGraphic(boxW - 12, boxH - 12, FlxColor.fromRGB(30, 34, 70));
		popup.add(inner);

		popupTitle = TextUtil.make(boxX, boxY + 22, boxW, '', 40, CENTER, FlxColor.YELLOW);
		popupTitle.borderSize = 3;
		popup.add(popupTitle);

		final options:Array<String> = [Locale.getMenu("$SELECT_LEVEL"), Locale.getMenu("$PLAY_ALL")];

		for (i in 0...options.length)
		{
			final option:FlxText = TextUtil.make(boxX, boxY + 100 + i * 56, boxW, options[i], 34, CENTER);
			option.borderSize = 2;
			popupOptions.push(option);
			popup.add(option);
		}

		popup.forEach(function(sprite:FlxSprite):Void
		{
			sprite.cameras = [camHUD];
		});

		popup.visible = false;
		add(popup);
	}

	inline function isWalkable(status:WorldStatus):Bool
		return status == OPEN || status == CLEARED;

	/**
	 * Starts on the world the player was last on, or the furthest unlocked world.
	 */
	function findStartIndex():Int
	{
		if (Global.lastWorld != null)
		{
			for (i in 0...nodes.length)
				if (nodes[i].worldId == Global.lastWorld && isWalkable(nodes[i].status))
					return i;
		}

		var furthest:Int = 0;
		for (i in 0...nodes.length)
			if (isWalkable(nodes[i].status))
				furthest = i;

		return furthest;
	}

	function placePlayerAt(node:MapNode):Void
	{
		player.x = node.x - player.width / 2;
		player.y = node.y - player.height + 2;
	}

	override public function update(elapsed:Float):Void
	{
		if (!leaving && !walking)
		{
			if (popupOpen)
				updatePopup();
			else
				updateMap();
		}

		super.update(elapsed);
	}

	function updateMap():Void
	{
		if (nodes.length > 0)
		{
			if (Input.pressed('left') || Input.pressed('up'))
				walkTo(currentIndex - 1);
			else if (Input.pressed('right') || Input.pressed('down'))
				walkTo(currentIndex + 1);
		}

		if (walking)
			return;

		if (Input.justPressed('confirm') && nodes.length > 0)
		{
			if (isWalkable(nodes[currentIndex].status))
				openPopup();
			else
				SoundController.play(Paths.sound('cancel'));
		}
		else if (Input.justPressed('cancel'))
		{
			leaving = true;
			SoundController.play(Paths.sound('cancel'));
			transitionState(new SaveSelect());
		}
	}

	function walkTo(index:Int):Void
	{
		if (index < 0 || index >= nodes.length)
			return;

		final target:MapNode = nodes[index];

		if (!isWalkable(target.status))
		{
			if (Input.justPressed('left') || Input.justPressed('right') || Input.justPressed('up') || Input.justPressed('down'))
			{
				SoundController.play(Paths.sound('cancel'));
				FlxTween.cancelTweensOf(target.sprite);
				FlxTween.shake(target.sprite, 0.08, 0.2, X);
			}
			return;
		}

		final from:MapNode = nodes[currentIndex];
		final dist:Float = Math.sqrt(Math.pow(target.x - from.x, 2) + Math.pow(target.y - from.y, 2));

		walking = true;
		player.flipX = target.x < from.x;
		player.animation.play('walk');
		SoundController.play(Paths.sound('scroll'));

		FlxTween.tween(player, {x: target.x - player.width / 2, y: target.y - player.height + 2}, Math.max(0.15, dist / WALK_SPEED), {
			ease: FlxEase.linear,
			onComplete: function(_):Void
			{
				walking = false;
				currentIndex = index;
				player.animation.play('idle');
				updateHUD();
			}
		});

		currentIndex = index;
		updateHUD();
	}

	function updateHUD():Void
	{
		if (nodes.length == 0)
		{
			worldNameText.text = Locale.getMenu("$COMING_SOON");
			worldInfoText.text = '';
			return;
		}

		final node:MapNode = nodes[currentIndex];
		worldNameText.text = LevelRegistry.getWorldName(node.worldId);

		switch (node.status)
		{
			case LOCKED:
				worldInfoText.text = Locale.getMenu("$LOCKED");
				worldInfoText.color = FlxColor.GRAY;
			case COMING_SOON:
				worldInfoText.text = Locale.getMenu("$COMING_SOON");
				worldInfoText.color = FlxColor.GRAY;
			default:
				final levels:Array<String> = LevelRegistry.listLevelsInWorld(node.worldId);
				var done:Int = 0;
				for (id in levels)
					if (Global.isLevelCompleted(id))
						done++;

				worldInfoText.text = Locale.replaceFlagsAndReturn("$FILE_LEVELS", 'menu', ['<X>', '<Y>'], [done, levels.length]);
				worldInfoText.color = (node.status == CLEARED) ? FlxColor.YELLOW : FlxColor.WHITE;
		}
	}

	function openPopup():Void
	{
		SoundController.play(Paths.sound('select'));
		popupOpen = true;
		popupIndex = 0;
		popupTitle.text = LevelRegistry.getWorldName(nodes[currentIndex].worldId);
		updatePopupColors();
		popup.visible = true;
	}

	function closePopup():Void
	{
		popupOpen = false;
		popup.visible = false;
	}

	function updatePopup():Void
	{
		if (Input.justPressed('up') || Input.justPressed('down'))
		{
			SoundController.play(Paths.sound('scroll'));
			popupIndex = FlxMath.wrap(popupIndex + (Input.justPressed('up') ? -1 : 1), 0, popupOptions.length - 1);
			updatePopupColors();
		}

		if (Input.justPressed('confirm'))
		{
			final worldId:String = nodes[currentIndex].worldId;

			Global.lastWorld = worldId;
			Global.save();

			switch (popupIndex)
			{
				case 0:
					leaving = true;
					SoundController.play(Paths.sound('select'));
					transitionState(new LevelSelect(worldId));
				case 1:
					startWorldRun(worldId);
			}
		}
		else if (Input.justPressed('cancel'))
		{
			SoundController.play(Paths.sound('cancel'));
			closePopup();
		}
	}

	function updatePopupColors():Void
	{
		for (i in 0...popupOptions.length)
			popupOptions[i].color = (i == popupIndex) ? FlxColor.YELLOW : FlxColor.WHITE;
	}

	function startWorldRun(worldId:String):Void
	{
		final levels:Array<String> = LevelRegistry.listLevelsInWorld(worldId);

		if (levels.length == 0)
			return;

		final level = LevelRegistry.fetchLevel(levels[0]);

		if (level == null)
			return;

		leaving = true;
		WorldRun.start(worldId, levels);

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		SoundController.play(Paths.sound('select'));
		player.animation.play('dance');
		transitionState(level);
	}
}
