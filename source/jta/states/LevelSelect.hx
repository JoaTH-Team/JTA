package jta.states;

import jta.Assets;
import jta.states.WorldMap;
import jta.states.level.WorldRun;
import jta.states.BaseState;
import jta.registries.LevelRegistry;
import jta.states.level.LevelData;

class LevelSelect extends BaseState
{
	/**
	 * The world whose levels are shown, or null to show every level.
	 */
	var worldId:Null<String> = null;

	var levelList:Array<String> = [];
	var selectedIndex:Int = 0;

	var coverGroup:FlxTypedGroup<FlxSprite>;
	var titleText:FlxText;

	var arrowL:FlxSprite;
	var arrowR:FlxSprite;

	/**
	 * @param worldId The world whose levels to show (e.g. `world1`). Leave it out to show every level.
	 */
	public function new(?worldId:String):Void
	{
		super();

		this.worldId = worldId;
	}

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Level Selection Menu', null);
		#end

		if (!(FlxG.sound.music?.playing ?? false))
			SoundController.playMusic(Paths.music('Pumpin_Pixels'));

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/level_bg'));
		bg.screenCenter();
		add(bg);

		WorldRun.stop();
		jta.states.level.Level.clearCheckpoint();
		jta.objects.HUD.resetLifeTracking();

		levelList = (worldId != null) ? LevelRegistry.listLevelsInWorld(worldId) : LevelRegistry.listLevels();

		if (worldId != null)
		{
			var worldText:FlxText = TextUtil.make(0, 14, FlxG.width, LevelRegistry.getWorldName(worldId), 30, CENTER, FlxColor.YELLOW);
			add(worldText);
		}

		titleText = TextUtil.make(0, 60, FlxG.width, '', 40, CENTER);
		titleText.screenCenter(X);
		add(titleText);

		coverGroup = new FlxTypedGroup<FlxSprite>();
		add(coverGroup);

		arrowL = new FlxSprite().loadGraphic(Paths.image('menu/level/arrow'), true, 16, 16);
		arrowL.animation.add('idle', [0], 1);
		arrowL.animation.add('pressed', [1], 1);
		arrowL.animation.play('idle');
		arrowL.scale.set(5, 5);
		arrowL.updateHitbox();
		arrowL.screenCenter(Y);
		add(arrowL);

		arrowR = new FlxSprite().loadGraphic(Paths.image('menu/level/arrow'), true, 16, 16);
		arrowR.animation.add('idle', [0], 1);
		arrowR.animation.add('pressed', [1], 1);
		arrowR.animation.play('idle');
		arrowR.scale.set(5, 5);
		arrowR.updateHitbox();
		arrowR.screenCenter(Y);
		arrowR.flipX = true;
		add(arrowR);

		updateCovers();

		super.create();
	}

	function updateCovers():Void
	{
		coverGroup.clear();

		if (levelList.length == 0)
			return;

		var centerCover:FlxSprite = null;

		for (i in -1...2)
		{
			var idx:Int = selectedIndex + i;
			if (idx < 0 || idx >= levelList.length)
				continue;

			var data:Null<LevelData> = LevelRegistry.getLevelData(levelList[idx]);
			var sprite:FlxSprite = new FlxSprite();

			var imagePath:String = 'menu/level/${data?.cover ?? 'placeholder'}';
			if (Assets.exists(Paths.image(imagePath)))
				sprite.loadGraphic(Paths.image(imagePath));
			else
			{
				trace('Missing level image: $imagePath');
				sprite.loadGraphic(Paths.image('menu/level/placeholder'));
			}

			if (i == 0)
			{
				sprite.scale.set(4, 4);
				centerCover = sprite;
			}
			else
				sprite.scale.set(3, 3);

			sprite.updateHitbox();

			if (i == 0)
				sprite.screenCenter();
			else if (i == -1)
			{
				sprite.x = FlxG.width / 2 - sprite.width - 190;
				sprite.screenCenter(Y);
			}
			else if (i == 1)
			{
				sprite.x = FlxG.width / 2 + 190;
				sprite.screenCenter(Y);
			}

			coverGroup.add(sprite);

			if (Global.isLevelCompleted(levelList[idx]))
			{
				var check:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/level/check'));
				check.scale.set(i == 0 ? 3 : 2, i == 0 ? 3 : 2);
				check.updateHitbox();
				check.x = sprite.x + sprite.width - check.width * 0.6;
				check.y = sprite.y - check.height * 0.4;
				coverGroup.add(check);
			}
		}

		if (centerCover != null)
		{
			arrowL.x = centerCover.x - arrowL.width - 20;
			arrowR.x = centerCover.x + centerCover.width + 20;
		}

		titleText.text = LevelRegistry.getLevelName(levelList[selectedIndex]);
	}

	override public function update(elapsed:Float):Void
	{
		if (Input.pressed('left'))
			arrowL.animation.play('pressed');
		else
			arrowL.animation.play('idle');

		if (Input.pressed('right'))
			arrowR.animation.play('pressed');
		else
			arrowR.animation.play('idle');

		if (levelList.length == 0)
		{
			if (Input.justPressed('cancel'))
			{
				SoundController.play(Paths.sound('ui/cancel'));
				transitionState(new WorldMap());
			}

			super.update(elapsed);
			return;
		}

		if (Input.justPressed('left'))
		{
			SoundController.play(Paths.sound('scroll'));
			selectedIndex = (selectedIndex - 1 + levelList.length) % levelList.length;
			updateCovers();
		}
		else if (Input.justPressed('right'))
		{
			SoundController.play(Paths.sound('scroll'));
			selectedIndex = (selectedIndex + 1) % levelList.length;
			updateCovers();
		}

		if (Input.justPressed('confirm'))
		{
			final level = LevelRegistry.fetchLevel(levelList[selectedIndex]);
			if (level != null)
			{
				if (FlxG.sound.music != null && FlxG.sound.music.playing)
					FlxG.sound.music.stop();
				SoundController.play(Paths.sound('select'));
				transitionState(level);
			}
		}
		else if (Input.justPressed('cancel'))
		{
			SoundController.play(Paths.sound('cancel'));
			transitionState(new WorldMap());
		}

		super.update(elapsed);
	}
}
