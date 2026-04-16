package jta.states.level;

import haxe.Json;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.tile.FlxTilemap;
import jta.states.BaseState;
import jta.substates.GameOver;
import jta.substates.PauseMenu;
import jta.registries.LevelRegistry;
import jta.registries.level.PlayerRegistry;
import jta.registries.level.ObjectRegistry;
import jta.objects.dialogue.DialogueBox;
import jta.objects.dialogue.Writer;
import jta.objects.level.Player;
import jta.objects.level.Object;
import jta.objects.HUD;
import jta.input.Input;
import jta.Global;
import jta.Paths;

/**
 * Base class for all levels in the game.
 * @author Joalor64
 */
class Level extends BaseState
{
	/**
	 * Current level number.
	 */
	public var levelNumber:Int;

	/**
	 * Current level name.
	 */
	public var levelName:String;

	/**
	 * Whether the level is a base game level or not.
	 * Mostly made to prevent saving a non-existent flag when completing a level.
	 */
	public var baseLevel:Bool = true;

	/**
	 * Current player character in the level.
	 */
	private var player:Player;

	/**
	 * Main tilemap for the level.
	 */
	private var map:FlxTilemap;

	/**
	 * Background tilemap for the level.
	 */
	private var background:FlxTilemap;

	/**
	 * Group containing all objects in the level.
	 */
	private var objects:FlxTypedGroup<Object>;

	/**
	 * `FlxCamera` used for the HUD.
	 */
	private var camHUD:FlxCamera;

	/**
	 * UI used by `Level`.
	 */
	private var hud:HUD;

	/**
	 * Whether the camera should follow the `Player` or not.
	 */
	private var camFollowControllable:Bool = false;

	/**
	 * Dialogue box used for displaying dialogue.
	 */
	private var dialogueBox:DialogueBox;

	var paused:Bool = false;

	/**
	 * Initializes the level with a specified level number.
	 * @param levelNumber The number of the level.
	 */
	public function new(levelNumber:Int):Void
	{
		super();

		this.levelNumber = levelNumber;
	}

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Playing Level: $levelName', null);
		#end

		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);

		if (background != null)
			add(background);

		if (map != null)
			add(map);

		if (objects != null)
			add(objects);

		if (player != null)
			add(player);

		hud = new HUD();
		hud.cameras = [camHUD];
		add(hud);

		dialogueBox = new DialogueBox(DialogueBoxPosition.BOTTOM);
		dialogueBox.cameras = [camHUD];
		dialogueBox.scrollFactor.set();
		dialogueBox.kill();
		add(dialogueBox);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		if (Input.justPressed('cancel') && !dialogueBox.alive)
		{
			persistentUpdate = false;
			openSubState(new PauseMenu());
		}

		if (Global.lives == 0)
		{
			persistentUpdate = false;
			openSubState(new GameOver());
		}

		super.update(elapsed);

		if (player != null)
		{
			if (map != null)
				FlxG.collide(map, player);

			if (camFollowControllable && player.y >= 0 && player.y <= FlxG.height)
				FlxG.camera.follow(player, LOCKON, 0.5);

			if (objects != null)
			{
				objects.forEach(function(obj:Object):Void
				{
					if (obj != null && player.characterControllable && player.overlaps(obj) && obj.objectInteractable)
					{
						if (Input.pressed('confirm'))
							obj.interact();
						else
							obj.overlap();
					}
				});
			}
		}
	}

	override function openSubState(SubState:FlxSubState):Void
	{
		if (paused)
			if (FlxG.sound.music != null)
				FlxG.sound.music.pause();

		super.openSubState(SubState);
	}

	override function closeSubState():Void
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.resume();
			paused = false;
		}

		super.closeSubState();
	}

	/**
	 * Creates a new player character in the level.
	 * @param id The player ID to load.
	 * @param x The x position to spawn the player at.
	 * @param y The y position to spawn the player at.
	 * @return The created player.
	 */
	public function loadPlayer(id:String, x:Float, y:Float):Player
	{
		player = PlayerRegistry.fetchPlayer(id);
		player.setPosition(x, y);
		add(player);
		return player;
	}

	/**
	 * Creates a new object in the level.
	 * @param id The object ID to load.
	 * @param x The x position to spawn the object at.
	 * @param y The y position to spawn the object at.
	 * @return The created object.
	 */
	public function createObject(id:String, x:Float, y:Float):Object
	{
		if (objects == null)
			objects = new FlxTypedGroup<Object>();

		final object:Object = ObjectRegistry.fetchObject(id);
		object.setPosition(x, y);
		return objects.add(object);
	}

	/**
	 * Loads the main tilemap for the level.
	 * @param path The path to the CSV file for the tilemap.
	 * @param image The image to use for the tilemap.
	 * @param w The width of each tile in the tilemap.
	 * @param h The height of each tile in the tilemap.
	 * @return The tilemap at `path` (if it exists).
	 */
	public function loadMap(path:String, image:String, ?w:Int = 16, ?h:Int = 16):FlxTilemap
	{
		map = new FlxTilemap();
		map.loadMapFromCSV(Paths.csv('levels/$path-map'), Paths.image('tiles/$image'), w, h);
		map.follow();
		add(map);
		return map;
	}

	/**
	 * Loads the background tilemap for the level.
	 * @param path The path to the CSV file for the background tilemap.
	 * @param image The image to use for the background tilemap.
	 * @param w The width of each tile in the tilemap.
	 * @param h The height of each tile in the tilemap.
	 * @param scrollFactorX The scroll factor for the X axis.
	 * @param scrollFactorY The scroll factor for the Y axis.
	 * @return The tilemap at `path` (if it exists).
	 */
	public function loadMapBackground(path:String, image:String, ?w:Int = 16, ?h:Int = 16, ?scrollFactorX:Float = 1, ?scrollFactorY:Float = 1):FlxTilemap
	{
		background = new FlxTilemap();
		background.loadMapFromCSV(Paths.csv('levels/$path-background'), Paths.image('tiles/$image' + '_bg'), w, h);
		background.scrollFactor.set(scrollFactorX, scrollFactorY);
		background.follow();
		add(background);
		return background;
	}

	/**
	 * Loads objects from a CSV file.
	 * @param path The path to the CSV file containing object IDs.
	 * @param w The width of each object in the CSV file.
	 * @param h The height of each object in the CSV file.
	 */
	public function loadObjects(path:String, ?w:Int = 16, ?h:Int = 16):Void
	{
		var rows:Array<String> = Assets.getText(Paths.csv('levels/$path-objects')).split('\n');

		for (rowIndex in 0...rows.length)
		{
			var cols = rows[rowIndex].split(',');
			for (colIndex in 0...cols.length)
			{
				var objID:String = StringTools.trim(cols[colIndex]);
				if (objID != '' && objID != '0' && objID != '.')
					createObject(objID, colIndex * w, rowIndex * h);
			}
		}
	}

	/**
	 * Loads a dialogue file from a specified path.
	 * Made as a workaround to not get any errors when loading it through polymod scripts.
	 * @param path The path to the dialogue file.
	 * @param id The level ID to load the dialogue file from.
	 * @return The dialogue file.
	 */
	public function loadDialogue(path:Dynamic, id:Int):Dynamic
	{
		return Json.parse(Assets.getText(Paths.json('data/dialogue/$id/$path')));
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
	 * Resets the current level.
	 * Apparently, using `FlxG.resetState()` doesn't work, so this is a workaround.
	 */
	public static function resetLevel():Void
	{
		if (Std.isOfType(FlxG.state, Level))
		{
			var level = cast(FlxG.state, Level);
			FlxG.switchState(LevelRegistry.fetchLevel(level.levelNumber));
		}
	}
}
