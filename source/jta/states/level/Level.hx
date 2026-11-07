package jta.states.level;

import haxe.Json;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.tile.FlxTilemap;
import flixel.FlxObject;
import flixel.util.FlxDirectionFlags;
import jta.states.BaseState;
import jta.states.LevelSelect;
import jta.states.WorldMap;
import jta.states.level.WorldRun;
import jta.locale.Locale;
import jta.states.level.LevelData;
import jta.substates.GameOver;
import jta.substates.PauseMenu;
import jta.substates.LevelComplete;
import jta.video.VideoState;
import jta.mobile.MobileInput;
import jta.mobile.VirtualButton;
import flixel.addons.transition.Transition;
import jta.registries.level.PlayerRegistry;
import jta.registries.level.ObjectRegistry;
import jta.objects.dialogue.DialogueBox;
import jta.objects.dialogue.Writer;
import jta.objects.level.Player;
import jta.objects.level.Object;
import jta.objects.HUD;

/**
 * Base class for all levels in the game.
 * @author Joalor64
 */
class Level extends BaseState
{
	/**
	 * The level's ID`.
	 */
	public var levelId:String;

	/**
	 * Current level name.
	 */
	public var levelName:String;

	/**
	 * The level's parsed `level.json`.
	 * Null for script-only levels.
	 */
	public var levelData:Null<LevelData>;

	/**
	 * Whether the level is a base game level or not.
	 * Mostly made to prevent saving a non-existent flag when completing a level.
	 */
	public var baseLevel:Bool = true;

	/**
	 * Whether `create()` builds the level from `levelData` automatically.
	 * Set to `false` in a script's constructor to build it manually.
	 */
	public var autoBuild:Bool = true;

	/**
	 * The current player in the level.
	 */
	@:noCompletion
	private var player:Player;

	/**
	 * Main tilemap for the level.
	 */
	@:noCompletion
	private var map:FlxTilemap;

	/**
	 * Background tilemap for the level.
	 */
	@:noCompletion
	private var background:FlxTilemap;

	/**
	 * A group containing the interactive objects in the level.
	 */
	@:noCompletion
	private var objects:FlxTypedGroup<Object>;

	/**
	 * The HUD camera used for displaying overlays like dialogue boxes.
	 */
	@:noCompletion
	private var camHUD:FlxCamera;

	/**
	 * HUD used by `Level`.
	 */
	@:noCompletion
	private var hud:HUD;

	/**
	 * Determines whether the camera's following behavior can be controlled.
	 */
	@:noCompletion
	private var camFollowControllable:Bool = false;

	/**
	 * Dialogue box used for displaying dialogue.
	 */
	@:noCompletion
	private var dialogueBox:DialogueBox;

	/**
	 * Mobile touchscreen controls.
	 */
	@:noCompletion
	private var mobileControls:MobileInput;

	/**
	 * Whether the mobile controls are currently showing the dialogue layout.
	 */
	@:noCompletion
	private var mobileDialogueLayout:Bool = false;

	var paused:Bool = false;

	/**
	 * Seconds left on a timed level, or -1 if the level isn't timed.
	 * Set from `timeLimit` in `level.json`; a script can also set it (and `timerActive`) itself.
	 */
	public var timeLeft:Float = -1;

	/**
	 * Whether the timer is counting down. Paused during dialogue, stopped when the level is won or time runs out.
	 */
	public var timerActive:Bool = false;

	/**
	 * How long `killPlayer()` waits before restarting the level (or opening the game over screen), by default.
	 */
	public static final DEATH_DELAY:Float = 2;

	/**
	 * Whether the player died and the level is about to restart.
	 */
	public var dying(default, null):Bool = false;

	/**
	 * Whether the level was won (the win sequence started). The player can't die after this.
	 */
	public var won(default, null):Bool = false;

	/**
	 * The last checkpoint reached: which level, and where the player respawns
	 * (`x` = left edge, `y` = the ground the player stands on). Kept across level resets.
	 * Cleared when the level is finished, restarted from the start, or left for a menu.
	 */
	/**
	 * Custom tile effects added by `registerTileEffect()`, by name.
	 */
	@:noCompletion
	private var tileEffects:Map<String, (tile:FlxObject, object:FlxObject, power:Null<Float>) -> Void> = [];

	/**
	 * Whether any non-solid tile has an effect (those need an extra overlap check every frame).
	 */
	@:noCompletion
	private var hasPassableTileEffects:Bool = false;

	public static var checkpoint(default, null):Null<{levelId:String, x:Float, y:Float}> = null;

	/**
	 * Text shown when time runs out.
	 */
	@:noCompletion
	private var timesUpText:Null<FlxText> = null;

	/**
	 * Initializes the level with a specified level ID.
	 * @param levelId The level's ID.
	 */
	public function new(levelId:String):Void
	{
		super();

		this.levelId = levelId;
		this.levelName = levelId;
	}

	override public function create():Void
	{
		if (autoBuild && levelData != null)
			buildLevel();

		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Playing Level: $levelName', null);
		#end

		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);

		hud = new HUD();
		hud.cameras = [camHUD];
		add(hud);

		if (levelData?.timeLimit != null && levelData.timeLimit > 0)
		{
			timeLeft = levelData.timeLimit;
			timerActive = true;
		}

		dialogueBox = new DialogueBox(DialogueBoxPosition.BOTTOM);
		dialogueBox.cameras = [camHUD];
		dialogueBox.scrollFactor.set();
		dialogueBox.kill();
		add(dialogueBox);

		#if mobile
		mobileControls = new MobileInput();
		mobileControls.setupGameplay();
		add(mobileControls);
		#end

		super.create();
	}

	/**
	 * Builds the level from `levelData`: music, background color, camera, tilemaps, objects and player.
	 */
	public function buildLevel():Void
	{
		final data:Null<LevelData> = levelData;

		if (data == null)
			return;

		final tileSize:Int = data.tileSize ?? 16;

		camFollowControllable = data.cameraFollow ?? true;

		if (data.music != null)
			SoundController.playMusic(Paths.music(data.music));

		if (data.bgColor != null)
		{
			final color:Null<FlxColor> = FlxColor.fromString(data.bgColor);

			if (color != null)
				FlxG.camera.bgColor = color;
		}

		FlxG.camera.zoom = data.zoom ?? 1;

		if (data.tileset != null)
		{
			if (Assets.exists(Paths.level(levelId, 'background.csv')))
				loadMapBackground(data.tileset, tileSize, data.backgroundScroll?.x ?? 1, data.backgroundScroll?.y ?? 1);

			loadMap(data.tileset, tileSize, null, data.tileProperties);
		}

		if (Assets.exists(Paths.level(levelId, 'objects.csv')))
			loadObjects(tileSize);

		loadPlayer(data.player ?? 'mainplayer', data.spawn?.x ?? 0, data.spawn?.y ?? 0);
	}

	override public function update(elapsed:Float):Void
	{
		if (player != null && player.y > FlxG.camera.scroll.y + FlxG.height)
			killPlayer(1);

		#if mobile
		updateMobileLayout();
		#end

		if ((Input.justPressed('cancel') #if mobile || MobileInput.checkInput('pause', JUST_PRESSED) #end) && !dialogueBox.alive && !dying)
			pauseGame();

		updateTimer(elapsed);

		final dialogueWasOpen:Bool = dialogueBox.alive;

		if (Global.lives <= 0 && !dying)
		{
			persistentUpdate = false;
			openSubState(new GameOver());
		}

		super.update(elapsed);

		if (player != null)
		{
			if (map != null)
			{
				FlxG.collide(map, player);

				if (hasPassableTileEffects)
					map.objectOverlapsTiles(player, null, null, false);
			}

			if (camFollowControllable && FlxG.camera.target != player && player.y >= 0 && player.y <= FlxG.height)
				FlxG.camera.follow(player, LOCKON, 0.5);

			if (player.x < 0)
				player.x = 0;
			else if (map != null && player.x > map.width - player.width)
				player.x = map.width - player.width;

			var canInteract:Bool = false;

			if (objects != null)
			{
				for (obj in objects.members)
				{
					if (obj != null && player.characterControllable && player.overlaps(obj) && obj.objectInteractable)
					{
						if (obj.objectHasInteraction)
							canInteract = true;

						if (Input.justPressed('confirm') && !dialogueWasOpen)
							obj.interact();
						else
							obj.overlap();
					}
				}
			}

			#if mobile
			if (mobileControls != null && !mobileDialogueLayout)
			{
				var interactButton:VirtualButton = mobileControls.getButton('confirm');
				if (interactButton != null)
					interactButton.visible = canInteract && player.characterControllable;
			}
			#end
		}
	}

	#if mobile
	/**
	 * Swaps the touch controls between the gameplay and dialogue layouts.
	 */
	@:noCompletion
	private function updateMobileLayout():Void
	{
		if (mobileControls == null || dialogueBox == null)
			return;

		if (dialogueBox.alive && !mobileDialogueLayout)
		{
			mobileControls.setupDialogue(dialogueBox.boxTop);
			mobileDialogueLayout = true;
		}
		else if (!dialogueBox.alive && mobileDialogueLayout)
		{
			mobileControls.setupGameplay();
			mobileDialogueLayout = false;
		}
	}
	#end

	/**
	 * Opens the pause menu.
	 */
	public function pauseGame():Void
	{
		persistentUpdate = false;
		openSubState(new PauseMenu());
	}

	#if mobile
	/**
	 * Called when the app goes to the background.
	 * Opens the pause menu so the player comes back
	 * to a paused game instead of resuming straight into the action.
	 */
	override public function onFocusLost():Void
	{
		super.onFocusLost();

		if (subState != null || dialogueBox == null || dialogueBox.alive)
			return;

		pauseGame();
	}
	#end

	override function openSubState(SubState:FlxSubState):Void
	{
		if (!paused && !(SubState is Transition))
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.pause();
			paused = true;
		}

		#if mobile
		if (mobileControls != null && !(SubState is Transition))
			mobileControls.setVisible(false);
		#end

		super.openSubState(SubState);
	}

	override function closeSubState():Void
	{
		if (paused && !(subState is Transition))
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.resume();
			paused = false;
		}

		#if mobile
		if (mobileControls != null)
			mobileControls.setVisible(true);
		#end

		super.closeSubState();
	}

	/**
	 * Creates a new player in the level.
	 * @param id The player ID to load.
	 * @param x The x position to spawn the player at.
	 * @param y The y position to spawn the player at.
	 * @return The created player.
	 */
	public function loadPlayer(id:String, x:Float, y:Float):Player
	{
		player = PlayerRegistry.fetchPlayer(id);
		player.setPosition(x, y);

		final cp = checkpoint;
		final atCheckpoint:Bool = cp != null && cp.levelId == levelId;
		if (atCheckpoint)
			player.setPosition(cp.x, cp.y - player.height);

		add(player);

		if (atCheckpoint && camFollowControllable)
		{
			FlxG.camera.follow(player, LOCKON, 0.5);
			FlxG.camera.snapToTarget();
		}

		return player;
	}

	/**
	 * Sets the checkpoint for this level. The player respawns there after dying.
	 * @param x Where the player respawns (left edge).
	 * @param y The ground the player respawns on (the player's feet go here).
	 */
	public function setCheckpoint(x:Float, y:Float):Void
	{
		checkpoint = {levelId: levelId, x: x, y: y};
	}

	/**
	 * Whether the given position is this level's current checkpoint (used by checkpoint objects to show themselves as reached).
	 */
	public function isCheckpoint(x:Float, y:Float):Bool
	{
		final cp = checkpoint;
		return cp != null && cp.levelId == levelId && cp.x == x && cp.y == y;
	}

	/**
	 * Forgets the checkpoint, so the next level load starts from the level's spawn.
	 */
	public static function clearCheckpoint():Void
	{
		checkpoint = null;
	}

	/**
	 * Restarts the level from the start (not from the checkpoint).
	 */
	public static function restartFromStart():Void
	{
		clearCheckpoint();
		resetLevel();
	}

	/**
	 * Creates a new object in the level.
	 * @param id The object ID to load.
	 * @param x The x position to spawn the object at.
	 * @param y The y position to spawn the object at.
	 * @param params Extra values for the object, from `id:param1:param2` cells in `objects.csv`.
	 * @return The created object, or null if `id` doesn't exist.
	 */
	public function createObject(id:String, x:Float, y:Float, ?params:Array<String>):Null<Object>
	{
		if (objects == null)
		{
			objects = new FlxTypedGroup<Object>();
			add(objects);
		}

		final object:Null<Object> = ObjectRegistry.fetchObject(id);
		if (object == null)
			return null;

		object.objectParams = params ?? [];
		object.setPosition(x, y);
		object.onPlaced();
		return objects.add(object);
	}

	/**
	 * Loads the main tilemap (`map.csv`) for the level.
	 * @param tileset The tileset folder in `images/tiles/` (uses its `main.png`).
	 * @param tileSize The size of each tile in pixels.
	 * @param levelId Which level's `map.csv` to load. Defaults to this level.
	 * @return The tilemap.
	 */
	public function loadMap(tileset:String, ?tileSize:Int = 16, ?levelId:String, ?properties:Array<TileProperty>):FlxTilemap
	{
		map = new FlxTilemap();
		map.loadMapFromCSV(Paths.level(levelId ?? this.levelId, 'map.csv'), Paths.image('tiles/$tileset/main'), tileSize, tileSize);
		map.follow();
		add(map);

		if (properties != null)
			for (property in properties)
				applyTileProperty(property);

		return map;
	}

	/**
	 * Changes how one or more tiles of the main tilemap behave. Call after the map is loaded.
	 *
	 * ```haxe
	 * setTileProperty(9, 'oneway', null, 3);   // tiles 9, 10 and 11 become jump-through platforms
	 * setTileProperty(12, 'solid', 'bounce');  // tile 12 is a springboard
	 * setTileProperty(13, 'none', 'kill');     // tile 13 is a non-solid hazard
	 * ```
	 * @param tile The tile's number in `map.csv`.
	 * @param collision Which sides are solid (see `TileProperty.collision`). Defaults to `solid`.
	 * @param effect What happens when the player touches it (see `TileProperty.effect`).
	 * @param range How many tiles in a row (starting at `tile`) to change.
	 * @param power Strength for the effect.
	 */
	public function setTileProperty(tile:Int, ?collision:String, ?effect:String, ?range:Int = 1, ?power:Float):Void
	{
		applyTileProperty({
			tile: tile,
			collision: collision,
			effect: effect,
			range: range,
			power: power
		});
	}

	/**
	 * Adds a custom tile effect that tiles can use by name (in `level.json` or `setTileProperty()`).
	 * Can be called before or after the map is loaded.
	 *
	 * ```haxe
	 * registerTileEffect('coinBlock', function(tile, object, power) { Global.coins++; });
	 * ```
	 * @param name The effect's name.
	 * @param callback Called with the tile, the object touching it (the player) and the tile's `power`.
	 */
	public function registerTileEffect(name:String, callback:(tile:FlxObject, object:FlxObject, power:Null<Float>) -> Void):Void
	{
		tileEffects.set(name, callback);
	}

	@:noCompletion
	private function applyTileProperty(property:TileProperty):Void
	{
		if (map == null)
		{
			FlxG.log.warn('Tile properties need the map to be loaded first.');
			return;
		}

		final collision:FlxDirectionFlags = parseCollision(property.collision);
		final effect:Null<String> = property.effect;
		final power:Null<Float> = property.power;

		final callback:Null<FlxObject->FlxObject->Void> = (effect != null) ? (tile, object) -> runTileEffect(effect, tile, object, power) : null;

		map.setTileProperties(property.tile, collision, callback, null, property.range ?? 1);

		if (callback != null && collision == NONE)
			hasPassableTileEffects = true;
	}

	/**
	 * Turns a `collision` string from `level.json` into collision flags.
	 */
	@:noCompletion
	private function parseCollision(?value:String):FlxDirectionFlags
	{
		if (value == null || value == '')
			return ANY;

		var flags:Int = 0;

		for (part in value.toLowerCase().split('|'))
		{
			flags |= switch (part.trim())
			{
				case 'solid' | 'any': ANY;
				case 'none' | 'passable': NONE;
				case 'oneway' | 'platform' | 'up' | 'top': UP;
				case 'down' | 'bottom': DOWN;
				case 'left': LEFT;
				case 'right': RIGHT;
				case 'wall': WALL;
				default:
					FlxG.log.warn('Unknown tile collision "$part" (use solid, none, oneway, up, down, left, right or wall).');
					ANY;
			}
		}

		return flags;
	}

	/**
	 * Runs a tile effect on whatever touched the tile.
	 */
	@:noCompletion
	private function runTileEffect(name:String, tile:FlxObject, object:FlxObject, power:Null<Float>):Void
	{
		if (object != player || player == null || dying || won)
			return;

		final custom = tileEffects.get(name);
		if (custom != null)
		{
			custom(tile, object, power);
			return;
		}

		switch (name)
		{
			case 'kill':
				killPlayer();
			case 'bounce':
				player.velocity.y = -(power ?? 400);
			case 'bounceLeft':
				player.velocity.x = -(power ?? 300);
			case 'bounceRight':
				player.velocity.x = power ?? 300;
			default:
				FlxG.log.warn('Unknown tile effect "$name". Add it with registerTileEffect() in the level script.');
		}
	}

	/**
	 * Loads the background tilemap (`background.csv`) for the level.
	 * @param tileset The tileset folder in `images/tiles/` (uses its `background.png`).
	 * @param tileSize The size of each tile in pixels.
	 * @param scrollFactorX The scroll factor for the X axis.
	 * @param scrollFactorY The scroll factor for the Y axis.
	 * @param levelId Which level's `background.csv` to load. Defaults to this level.
	 * @return The tilemap.
	 */
	public function loadMapBackground(tileset:String, ?tileSize:Int = 16, ?scrollFactorX:Float = 1, ?scrollFactorY:Float = 1, ?levelId:String):FlxTilemap
	{
		background = new FlxTilemap();
		background.loadMapFromCSV(Paths.level(levelId ?? this.levelId, 'background.csv'), Paths.image('tiles/$tileset/background'), tileSize, tileSize);
		background.scrollFactor.set(scrollFactorX, scrollFactorY);
		background.follow();
		add(background);
		return background;
	}

	/**
	 * Loads objects from the level's `objects.csv`.
	 * Each cell is an object ID, optionally followed by `:`-separated params (e.g. `sign:welcome`).
	 * Empty cells, `0` and `.` are skipped.
	 * @param gridSize The size of each cell in pixels.
	 * @param levelId Which level's `objects.csv` to load. Defaults to this level.
	 */
	public function loadObjects(?gridSize:Int = 16, ?levelId:String):Void
	{
		final text:Null<String> = Assets.getText(Paths.level(levelId ?? this.levelId, 'objects.csv'));

		if (text == null)
			return;

		final rows:Array<String> = text.split('\n');

		for (rowIndex in 0...rows.length)
		{
			final cols:Array<String> = rows[rowIndex].split(',');

			for (colIndex in 0...cols.length)
			{
				final cell:String = cols[colIndex].trim();

				if (cell == '' || cell == '0' || cell == '.')
					continue;

				final parts:Array<String> = cell.split(':');
				final id:String = parts.shift();

				createObject(id, colIndex * gridSize, rowIndex * gridSize, parts);
			}
		}
	}

	/**
	 * Loads a dialogue file, in the current language if a translation exists (English otherwise).
	 * Looks in `assets/locales/<language>/dialogue/<level ID>/<name>.json`.
	 * @param name The dialogue file name, without `.json`.
	 * @param levelId Which level's dialogue folder to look in. Defaults to this level.
	 * @return The dialogue lines, or an empty array if the file doesn't exist.
	 */
	public function loadDialogue(name:String, ?levelId:String):Array<WriterData>
	{
		final path:Null<String> = Paths.dialogue(levelId ?? this.levelId, name);

		if (path == null)
		{
			FlxG.log.error('Dialogue "$name" not found for level "${levelId ?? this.levelId}"');
			return [];
		}

		try
		{
			final json:Dynamic = Json.parse(Assets.getText(path));
			final lines:Null<Array<WriterData>> = json.dialogueData;
			return lines ?? [];
		}
		catch (e:Dynamic)
		{
			FlxG.log.error('Failed to parse dialogue "$path": $e');
			return [];
		}
	}

	/**
	 * Starts dialogue with the given `dialogue` data.
	 * @param dialogue The dialogue data needed for the `Writer` to display.
	 * @param finishCallback What to do when the dialogue finishes.
	 * @param position The position of the dialogue box on the screen.
	 */
	public function startDialogue(dialogue:Array<WriterData>, ?finishCallback:Void->Void, ?position:DialogueBoxPosition = DialogueBoxPosition.BOTTOM):Void
	{
		if (dialogueBox == null || dialogueBox.alive)
			return;

		dialogueBox.finishCallback = function():Void
		{
			if (finishCallback != null)
				finishCallback();

			dialogueBox.kill();
		}
		dialogueBox.setPositionType(position);
		dialogueBox.revive();
		dialogueBox.startDialogue(dialogue);
	}

	/**
	 * Loads and plays a dialogue file, freezing the player until it's over.
	 * @param name The dialogue file name (see `loadDialogue()`).
	 * @param onFinish What to do when the dialogue finishes.
	 * @param position The position of the dialogue box on the screen.
	 */
	public function playDialogue(name:String, ?onFinish:Void->Void, ?position:DialogueBoxPosition = DialogueBoxPosition.BOTTOM):Void
	{
		final lines:Array<WriterData> = loadDialogue(name);

		if (lines.length == 0 || dialogueBox == null || dialogueBox.alive)
		{
			if (onFinish != null)
				onFinish();
			return;
		}

		if (player != null)
			player.characterControllable = false;

		startDialogue(lines, function():Void
		{
			if (player != null)
				player.characterControllable = true;

			if (onFinish != null)
				onFinish();
		}, position);
	}

	/**
	 * Counts the timer down and shows it on the HUD. Calls `onTimeUp()` when it hits 0.
	 */
	public function updateTimer(elapsed:Float):Void
	{
		if (timeLeft < 0)
			return;

		final canTick:Bool = timerActive && !dialogueBox.alive && (player == null || player.characterControllable);

		if (canTick)
		{
			timeLeft = Math.max(0, timeLeft - elapsed);

			if (timeLeft <= 0)
			{
				timerActive = false;
				onTimeUp();
			}
		}

		hud.setTime(timeLeft);
	}

	/**
	 * Called when the timer hits 0. Shows "Time's Up!" and kills the player (see `killPlayer()`).
	 * Override in a level script to do something else.
	 */
	public function onTimeUp():Void
	{
		if (dying || won)
			return;

		hud.stopClock();

		timesUpText = TextUtil.make(0, 0, FlxG.width, Locale.getPlayState("$TIMES_UP"), 64, CENTER, FlxColor.RED);
		timesUpText.borderSize = 4;
		timesUpText.screenCenter(Y);
		timesUpText.cameras = [camHUD];
		timesUpText.scrollFactor.set();
		add(timesUpText);

		timesUpText.scale.set(2, 2);
		flixel.tweens.FlxTween.tween(timesUpText.scale, {x: 1, y: 1}, 0.4, {ease: flixel.tweens.FlxEase.backOut});

		killPlayer(2.5);
	}

	/**
	 * Kills the player. Every way of dying should go through this (falling, spikes, the timer, enemies...).
	 *
	 * Stops the music, plays the death sound and the player's `dead` animation, takes a life (and saves),
	 * then after `delay` seconds restarts the level, or opens the game over screen if that was the last life.
	 * Does nothing if the player is already dying or the level was won.
	 *
	 * From a script: `FlxG.state.killPlayer();`
	 * @param delay Seconds to wait before restarting. Defaults to `DEATH_DELAY`.
	 */
	public function killPlayer(?delay:Float):Void
	{
		if (dying || won)
			return;

		dying = true;
		timerActive = false;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		SoundController.play(Paths.sound('die'));

		if (player != null)
		{
			player.characterControllable = false;
			player.animation.play('dead');
			player.velocity.x = 0;
		}

		Global.lives--;
		Global.save();

		onPlayerDeath();

		new FlxTimer().start(delay ?? DEATH_DELAY, function(_):Void
		{
			if (Global.lives > 0)
				Level.resetLevel();
			else
			{
				persistentUpdate = false;
				openSubState(new GameOver());
			}
		});
	}

	/**
	 * Called by `killPlayer()` right after the life is taken. Does nothing by default;
	 * override in a level script to add something (e.g. a custom effect).
	 */
	public function onPlayerDeath():Void {}

	/**
	 * Plays the "level complete" sequence: stops the music, freezes the player in a dance,
	 * then opens the level complete menu, which calls `finishLevel()` when continuing.
	 * Goal objects (flag, roulette...) call this.
	 * @param delay How long to dance before the menu opens, in seconds.
	 */
	public function startWinSequence(?delay:Float = 3):Void
	{
		if (dying)
			return;

		won = true;
		timerActive = false;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (player != null)
		{
			player.characterControllable = false;
			player.animation.play('dance');
			player.velocity.x = 0;
		}

		new FlxTimer().start(delay, function(_):Void
		{
			persistentUpdate = false;
			openSubState(new LevelComplete(finishLevel));
		});
	}

	/**
	 * Marks the level as completed, plays the level's `endCutscene` (if any), then calls `afterFinish()`.
	 * During a "Play All Levels" run, it goes to the run's next level instead of calling `afterFinish()`
	 * (the run's last level still calls `afterFinish()`).
	 */
	public function finishLevel():Void
	{
		clearCheckpoint();

		if (baseLevel)
			Global.completeLevel(levelId);

		final nextInRun:Null<String> = WorldRun.next(levelId);
		final then:Void->Void = (nextInRun != null) ? () -> switchToLevel(nextInRun) : afterFinish;

		final cutscene:Null<String> = levelData?.endCutscene;

		if (cutscene != null)
			FlxG.switchState(new VideoState(cutscene, true, then));
		else
			then();
	}

	/**
	 * Called at the very end of `finishLevel()`. By default, goes back to this level's world on the level select,
	 * or to the world map if a "Play All Levels" run was just finished.
	 * Override in a level script to go somewhere else.
	 */
	public function afterFinish():Void
	{
		if (WorldRun.consumeFinished())
			FlxG.switchState(new WorldMap());
		else
			FlxG.switchState(new LevelSelect(levelId.split('/')[0]));
	}

	/**
	 * Resets the current level.
	 * Apparently, using `FlxG.resetState()` doesn't work, so this is a workaround.
	 */
	public static function resetLevel():Void
	{
		if (Std.isOfType(FlxG.state, Level))
		{
			final level:Level = cast(FlxG.state, Level);
			switchToLevel(level.levelId);
		}
	}

	/**
	 * Switches to a level by its ID (goes through the registry, so scripted levels work).
	 * @param levelId The level ID.
	 */
	public static function switchToLevel(levelId:String):Void
	{
		final registryClass:Class<Dynamic> = Type.resolveClass('jta.registries.LevelRegistry');

		if (registryClass != null)
		{
			final fetchMethod:Dynamic = Reflect.field(registryClass, 'fetchLevel');

			if (Reflect.isFunction(fetchMethod))
			{
				final newState:Dynamic = Reflect.callMethod(registryClass, fetchMethod, [levelId]);
				if (newState != null)
					FlxG.switchState(newState);
			}
		}
	}
}
