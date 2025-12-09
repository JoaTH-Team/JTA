package jta.states;

import jta.Paths;
import jta.Assets;
import jta.input.Input;
import jta.states.MainMenu;
import jta.states.BaseState;
import jta.registries.LevelRegistry;

class LevelSelect extends BaseState
{
	var levelList:Array<{name:String, id:String, ?cover:String}> = [];
	var selectedIndex:Int = 0;

	var coverGroup:FlxTypedGroup<FlxSprite>;
	var titleText:FlxText;

	var arrowL:FlxSprite;
	var arrowR:FlxSprite;

	override public function create():Void
	{
		#if hxdiscord_rpc
		jta.api.DiscordClient.changePresence('Level Selection Menu', null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/level_bg'));
		bg.screenCenter();
		add(bg);

		var initLevels:Array<String> = Paths.getTextArray(Paths.txt('levels/levelList'));

		if (Assets.exists(Paths.txt('levels/levelList')))
		{
			initLevels = Assets.getText(Paths.txt('levels/levelList')).trim().split('\n');

			for (i in 0...initLevels.length)
				initLevels[i] = initLevels[i].trim();
		}

		for (i in 0...initLevels.length)
		{
			var data:Array<String> = initLevels[i].split('|');
			levelList.push({name: data[0], id: data[1], cover: (data.length > 2) ? data[2] : null});
		}

		titleText = new FlxText(0, 60, FlxG.width, '');
		titleText.setFormat(Paths.font('main'), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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
			var idx = selectedIndex + i;
			if (idx < 0 || idx >= levelList.length)
				continue;

			var level = levelList[idx];
			var sprite = new FlxSprite();

			var imagePath:String = 'menu/level/' + ((level.cover != null) ? formatLevelPath(level.cover) : formatLevelPath(level.name));
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
		}

		if (centerCover != null)
		{
			arrowL.x = centerCover.x - arrowL.width - 20;
			arrowR.x = centerCover.x + centerCover.width + 20;
		}

		titleText.text = levelList[selectedIndex].name;
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

		if (Input.justPressed('left'))
		{
			FlxG.sound.play(Paths.sound('scroll'));
			selectedIndex = (selectedIndex - 1 + levelList.length) % levelList.length;
			updateCovers();
		}
		else if (Input.justPressed('right'))
		{
			FlxG.sound.play(Paths.sound('scroll'));
			selectedIndex = (selectedIndex + 1) % levelList.length;
			updateCovers();
		}

		if (Input.justPressed('confirm'))
		{
			FlxG.sound.play(Paths.sound('select'));
			transitionState(LevelRegistry.fetchLevel(Std.parseInt(levelList[selectedIndex].id)));
		}
		else if (Input.justPressed('cancel'))
		{
			FlxG.sound.play(Paths.sound('cancel'));
			transitionState(new MainMenu());
		}

		super.update(elapsed);
	}

	private function formatLevelPath(path:String):String
		return path.toLowerCase().replace(' ', '-');
}
