package jta.states.level;

import flixel.tile.FlxTilemap;
import jta.states.BaseState;
import jta.substates.GameOver;
import jta.substates.PauseMenu;
import jta.registries.level.PlayerRegistry;
import jta.registries.level.ObjectRegistry;
import jta.objects.level.Player;
import jta.objects.level.Object;
import jta.objects.dialogue.DialogueBox;
import jta.objects.dialogue.Writer;
import jta.objects.HUD;
import jta.input.Input;
import jta.Global;
import jta.Paths;

class Level extends BaseState
{
	public var levelNumber:Int;
	public var levelName:String;

	private var player:Player;

	private var map:FlxTilemap;
	private var background:FlxTilemap;
	private var objects:FlxTypedGroup<Object>;

	private var camHUD:FlxCamera;
	private var hud:HUD;

	private var camFollowControllable:Bool = false;

	private var dialogueBox:DialogueBox;

	public function new(levelNumber:Int):Void
	{
		super();

		this.levelNumber = levelNumber;
	}

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Playing Level: ' + levelName, null);
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
				FlxG.camera.follow(player, LOCKON, 0.9);

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

	public function loadPlayer(id:String, x:Float, y:Float):Player
	{
		player = PlayerRegistry.fetchPlayer(id);
		player.setPosition(x, y);
		add(player);
		return player;
	}

	public function createObject(id:String, x:Float, y:Float):Object
	{
		if (objects == null)
			objects = new FlxTypedGroup<Object>();

		final object:Object = ObjectRegistry.fetchObject(id);
		object.setPosition(x, y);
		return objects.add(object);
	}

	public function loadMap(path:String, image:String, ?w:Int = 16, ?h:Int = 16):FlxTilemap
	{
		map = new FlxTilemap();
		map.loadMapFromCSV(Paths.csv('levels/' + path + '-map'), Paths.image('tiles/' + image), w, h);
		add(map);
		return map;
	}

	public function loadMapBackground(path:String, image:String, ?w:Int = 16, ?h:Int = 16):FlxTilemap
	{
		background = new FlxTilemap();
		background.loadMapFromCSV(Paths.csv('levels/' + path + '-background'), Paths.image('tiles/' + image + '_bg'), w, h);
		add(background);
		return background;
	}

	public function loadObjects(path:String, ?w:Int = 16, ?h:Int = 16):Void
	{
		var rows = Assets.getText(Paths.csv('levels/' + path + '-objects')).split("\n");

		for (rowIndex in 0...rows.length)
		{
			var cols = rows[rowIndex].split(",");
			for (colIndex in 0...cols.length)
			{
				var objID = StringTools.trim(cols[colIndex]);
				if (objID != "" && objID != "0" && objID != ".")
					createObject(objID, colIndex * w, rowIndex * h);
			}
		}
	}

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
}
