package menus;

import flixel.FlxG;
import flixel.FlxSubState;
import haxe.ds.ArraySort;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;

import haxe.io.Bytes;
import lime.graphics.Image;
import openfl.display.BitmapData;

import data.ObjectData;
import data.Options;
import data.ScoreSystems;
import data.Song;
import game.PlayState;
import game.ResultsSubState;
import menus.UINavigation;
import objects.Alphabet;
import objects.AnimatedSprite;
import objects.Character;
import scripting.HscriptHandler;
import scripting.HscriptState;

using StringTools;

class WeekButton extends FlxSprite
{
	var colors:Array<FlxColor> = [FlxColor.WHITE, 0xFF33ffff];

	override public function new(x:Int, y:Int, image:String)
	{
		super(x, y);
		loadGraphic(Paths.image("ui/weeks/" + image));
	}

	public function flicker()
	{
		if (!Options.options.flashingLights)
			return;

		new FlxTimer().start(0.05, function(tmr:FlxTimer)
		{
			if (color == colors[0])
				color = colors[1];
			else
				color = colors[0];
		}, 0);
	}
}

class MenuCharacter extends FlxSprite
{
	public var characterData:WeekCharacterData = null;
	public var curCharacter:String = "";
	var animOffsets:Map<String, Array<Int>>;

	var pos:Int = 0;
	public var lastIdle:Int = 0;
	public var danceSpeed:Float = 1;

	override public function new(pos:Int)
	{
		super();
		this.pos = pos;
		animOffsets = new Map<String, Array<Int>>();
		refreshCharacter(TitleState.defaultVariables.story2);
	}

	public static function parseCharacter(id:String):WeekCharacterData
	{
		var cData:WeekCharacterData = cast Paths.json("story_characters/" + id);

		var allAnims:Array<String> = [];
		for (a in cData.animations)
		{
			allAnims.push(a.name);

			if (a.loop == null)
				a.loop = false;

			if (a.fps == null)
				a.fps = 24;

			if (a.indices != null)
				a.indices = Character.uncompactIndices(a.indices);
		}

		if (cData.danceSpeed == null)
			cData.danceSpeed = 1;

		if (cData.scale == null)
			cData.scale = [1, 1];

		if (cData.flip == null)
			cData.flip = false;

		if (cData.matchColor == null)
			cData.matchColor = true;

		if (cData.idles == null)
		{
			if (allAnims.contains("danceLeft") && allAnims.contains("danceRight"))
				cData.idles = ["danceLeft", "danceRight"];
			else if (allAnims.contains("idle"))
				cData.idles = ["idle"];
			else
				cData.idles = [];
		}

		return cData;
	}

	public function refreshCharacter(char:String)
	{
		if (char != curCharacter)
		{
			curCharacter = char;
			if (!Paths.jsonExists("story_characters/" + char))
				curCharacter = TitleState.defaultVariables.story2;

			if (characterData != null)
			{
				danceSpeed = 1;
				animOffsets.clear();
			}

			characterData = parseCharacter(curCharacter);

			frames = Paths.sparrow("ui/story_characters/" + characterData.asset);
			for (i in 0...characterData.animations.length)
			{
				var anim = characterData.animations[i];
				if (anim.indices != null && anim.indices.length > 0)
					animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
				else
					animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
				animOffsets.set(anim.name, anim.offsets);
			}

			danceSpeed = characterData.danceSpeed;

			flipX = characterData.flip;

			if (characterData.scale != null && characterData.scale.length == 2)
				scale.set(characterData.scale[0], characterData.scale[1]);
			else
				scale.set(1, 1);
			updateHitbox();

			switch (pos)
			{
				case 1: x = (FlxG.width - width + characterData.position[0]) / 2;
				case 2: x = FlxG.width - width - characterData.position[0];
				default: x = characterData.position[0];
			}
			y = 56 + characterData.position[1];

			playAnim(characterData.firstAnimation);

			antialiasing = characterData.antialias;
		}
	}

	public function playAnim(animName:String, forced:Bool = false)
	{
		if (animOffsets.exists(animName))
		{
			animation.play(animName, forced);
			offset.x = animOffsets.get(animName)[0];
			offset.y = animOffsets.get(animName)[1];
		}
	}

	public function dance()
	{
		if (characterData.idles.length <= 0)
			return;

		if (lastIdle < characterData.idles.length)
			playAnim(characterData.idles[lastIdle], true);
		lastIdle = (lastIdle + 1) % characterData.idles.length;
	}
}

class StoryMenuState extends MusicBeatState
{
	static var menuState:Int = 0;
	var categories:Map<String, Array<String>>;
	var categoriesList:Array<String> = [];
	var category:String = "";
	static var curCategory:Int = 0;

	var weekList:Map<String, WeekData>;
	public var weekNames:Array<String> = [];
	var weekButtons:FlxTypedSpriteGroup<WeekButton>;
	var weekLocks:FlxSpriteGroup;
	public static var curWeek:Int = 0;
	var unlockedWeeks:Array<String> = [];
	var weekUnlocked:Array<Bool> = [];

	var menuCharacters:FlxTypedSpriteGroup<MenuCharacter>;
	var scoreDisplay:FlxText;
	public var score:Int = 0;
	var displayScore:Int = 0;
	var weekTitle:FlxText;
	var tracks:FlxText;
	var bgYellow:FlxSprite;
	var banner:FlxSprite;
	var categoryText:Alphabet;
	var categoryIcon:FlxSprite;

	public static var difficulty:String = "normal";
	var difficultySprite:FlxSprite;
	var arrowLeft:AnimatedSprite;
	var arrowRight:AnimatedSprite;

	var nav:UINumeralNavigation;
	var nav2:UINumeralNavigation;
	public static var navSwitch:Bool = true;

	var myScripts:Map<String, HscriptHandler>;

	public static function convertWeek(id:String, ?quick:Bool = false):WeekData
	{
		var data:Dynamic = Paths.json("weeks/" + id);

		var wData:WeekData = cast data;
		if (data.weekName != null)			// This is a Psych Engine week and must be converted to the Slightly Engine format
		{
			wData = {
				image: id,
				title: data.storyName.toUpperCase(),
				characters: data.weekCharacters,
				banner: "menu_" + data.weekBackground,
				songs: [],
				startsLocked: !data.startUnlocked,
				weekToUnlock: data.weekBefore,
				hiddenWhenLocked: data.hiddenUntilUnlocked
			}

			var oldSongList:Array<Array<Dynamic>> = cast data.songs;
			for (s in oldSongList)
			{
				var sId:String = cast s[0];
				wData.songs.push({songId: sId.toLowerCase().replace(" ","-"), icon: s[1]});
			}

			if (data.difficulties != null && data.difficulties != "")
				wData.difficulties = data.difficulties.toLowerCase().split(",");

			if (data.hideStoryMode)
				wData.condition = "freeplayonly";
			else if (data.hideFreeplay)
				wData.condition = "storyonly";
		}

		if (!Paths.imageExists("ui/weeks/" + wData.image))
			wData.image = TitleState.defaultVariables.storyimage;

		for (s in wData.songs)
		{
			if (!Paths.exists("songs/" + s.songId + "/Inst.ogg") && Paths.exists("songs/" + id + "/" + s.songId + "/Inst.ogg"))
				s.songId = id + "/" + s.songId;
		}

		if (!quick)
		{
			var iconList:Array<String> = null;
			for (s in wData.songs)
			{
				if (!Paths.imageExists("icons/icon-" + s.icon))
				{
					if (iconList == null)
						iconList = Paths.listFilesSub("images/icons/", ".png");
					for (f in iconList)
					{
						if (f.indexOf("/") > -1)
						{
							if (f.split("/")[f.split("/").length-1] == s.icon)
								s.icon = f;
							else if (f.split("/")[f.split("/").length-1].split("icon-")[1] == s.icon)
								s.icon = f.replace("icon-","");
						}
					}
				}

				if (s.characters == null)
					s.characters = 3;

				if (s.characterLabels == null || s.characterLabels.length < 3)
					s.characterLabels = ["#fpSandboxCharacter0", "#fpSandboxCharacter1", "#fpSandboxCharacter2"];
			}
		}

		return wData;
	}

	public static function parseWeek(id:String, ?quick:Bool = false):WeekData
	{
		var wData:WeekData = convertWeek(id, quick);

		if (wData.color == null)
			wData.color = [249, 207, 81];

		if (wData.condition == null)
			wData.condition = "";
		wData.condition = wData.condition.toLowerCase();

		if (wData.difficulties == null || wData.difficulties.length == 0)
			wData.difficulties = ["normal", "hard", "easy"];

		return wData;
	}

	var weekOrder:Array<String> = [];
	function sortWeeks(a:String, b:String):Int
	{
		if (weekOrder.contains(a) && weekOrder.contains(b))
		{
			if (weekOrder.indexOf(a) > weekOrder.indexOf(b))
				return 1;
			if (weekOrder.indexOf(a) < weekOrder.indexOf(b))
				return -1;
		}
		return 0;
	}

	override public function create()
	{
		super.create();
		HscriptHandler.curMenu = "story";

		if (FlxG.save.data.unlockedWeeks == null)
			FlxG.save.data.unlockedWeeks = [];
		unlockedWeeks = FlxG.save.data.unlockedWeeks;

		Util.menuMusic();

		weekButtons = new FlxTypedSpriteGroup<WeekButton>();
		add(weekButtons);

		weekLocks = new FlxSpriteGroup();
		add(weekLocks);

		var bgBlack:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(bgBlack);

		bgYellow = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, FlxColor.WHITE);
		bgYellow.color = 0xFFF9CF51;
		add(bgYellow);

		categoryText = new Alphabet(0, 200, "", "default", Std.int(FlxG.width * 0.95));
		add(categoryText);

		categoryIcon = new FlxSprite();
		categoryIcon.visible = false;
		add(categoryIcon);

		banner = new FlxSprite(0, 56);
		banner.visible = false;
		add(banner);

		menuCharacters = new FlxTypedSpriteGroup<MenuCharacter>();
		add(menuCharacters);
		for (i in 0...3)
		{
			var char:MenuCharacter = new MenuCharacter(i);
			menuCharacters.add(char);
		}

		scoreDisplay = new FlxText(10, 10, 0, Lang.get("#smScore", [Std.string(displayScore)]), 32);
		scoreDisplay.font = "VCR OSD Mono";
		add(scoreDisplay);

		weekTitle = new FlxText(0, 10, FlxG.width - 10, "", 32);
		weekTitle.alpha = 0.7;
		weekTitle.font = "VCR OSD Mono";
		weekTitle.alignment = RIGHT;
		add(weekTitle);

		tracks = new FlxText(0, 500, 0, "", 32);
		tracks.color = 0xFFE55777;
		tracks.font = "VCR OSD Mono";
		tracks.alignment = CENTER;
		add(tracks);

		difficultySprite = new FlxSprite(FlxG.width * 0.72, 490, Paths.image("ui/difficulties/normal"));
		add(difficultySprite);

		arrowLeft = new AnimatedSprite(0, 0, Paths.tiles("ui/arrow", 2, 1));
		arrowLeft.animation.add('idle', [0]);
		arrowLeft.animation.add('press', [1]);
		arrowLeft.animation.play('idle');
		arrowLeft.flipX = true;
		add(arrowLeft);

		arrowRight = new AnimatedSprite(0, 0, arrowLeft.frames);
		arrowRight.animation.add('idle', [0]);
		arrowRight.animation.add('press', [1]);
		arrowRight.animation.play('idle');
		add(arrowRight);

		myScripts = new Map<String, HscriptHandler>();

		categories = new Map<String, Array<String>>();
		categoriesList = [];
		var possibleCats:Array<String> = [];
		weekList = new Map<String, WeekData>();
		for (file in Paths.listFilesAndMods("data/weeks/", ".json"))
		{
			var newWeek:WeekData = parseWeek(file[0], true);
			if (newWeek.condition != "freeplayonly" && !(newWeek.startsLocked && !FlxG.save.data.unlockedWeeks.contains(file[0]) && newWeek.hiddenWhenLocked))
			{
				if (categories.exists(file[1]))
					categories.get(file[1]).push(file[0]);
				else
				{
					categories.set(file[1], [file[0]]);
					possibleCats.push(file[1]);
				}
				weekList.set(file[0], newWeek);

				hscriptAdd(file[0], 'data/weeks/' + file[0], false);
			}
		}

		if (possibleCats.contains("") && !PackagesState.excludeBase)
			categoriesList.push("");
		for (c in ModLoader.modListLoaded)
		{
			if (possibleCats.contains(c) || Paths.hscriptExists("data/states/" + c + "-story"))
				categoriesList.push(c);
		}

		weekOrder = Paths.text("weekOrder").replace("\r","").split("\n");
		for (c in categories.keys())
			ArraySort.sort(categories[c], sortWeeks);

		nav = new UINumeralNavigation(changeCategory, null, function() {
			if (Paths.hscriptExists("data/states/" + categoriesList[curCategory] + "-story"))
				FlxG.switchState(new HscriptState("data/states/" + categoriesList[curCategory] + "-story"));
			else
			{
				menuState = 1;
				clearMenuStuff();
				curWeek = 0;
				reloadMenuStuff();
			}
		}, function() { FlxG.switchState(new MainMenuState()); }, changeCategory);
		nav.leftClick = nav.accept;
		nav.rightClick = nav.back;
		add(nav);

		nav2 = new UINumeralNavigation(changeDifficulty, changeSelection, function() {
			if (weekUnlocked[curWeek])
			{
				FlxG.sound.play(Paths.sound("ui/confirmMenu"));
				menuCharacters.forEachAlive(function(char:MenuCharacter) { char.playAnim("hey"); });
				if (weekButtons.members.length > curWeek)
					weekButtons.members[curWeek].flicker();
				nav2.locked = true;

				gotoWeek(weekNames[curWeek], difficulty);
			}
		}, function() {
			menuState = 0;
			clearMenuStuff();
			reloadMenuStuff();
		}, changeSelection);
		nav2.uiSounds = [true, false, true];
		nav2.leftClick = nav2.accept;
		nav2.rightClick = nav2.back;
		add(nav2);

		if (categoriesList.length <= 1 || !navSwitch)
		{
			menuState = 1;
			remove(nav);
			nav2.back = nav.back;
		}
		reloadMenuStuff();

		hscriptExec("create", []);
	}

	function clearMenuStuff()
	{
		switch (menuState)
		{
			case 0:
				hscriptIdExec(weekNames[curWeek], "weekUnselected", []);

				weekButtons.forEachAlive(function(btn:WeekButton)
				{
					btn.kill();
					btn.destroy();
				});
				weekButtons.clear();

				weekLocks.forEachAlive(function(lock:FlxSprite)
				{
					lock.kill();
					lock.destroy();
				});
				weekLocks.clear();

				weekUnlocked = [];
				bgYellow.color = 0xFFF9CF51;

			case 1:
				categoryText.text = "";
				categoryIcon.visible = false;
		}
	}

	function reloadMenuStuff()
	{
		switch (menuState)
		{
			case 0:
				nav.locked = false;
				nav2.locked = true;
				scoreDisplay.visible = false;
				weekTitle.visible = false;
				tracks.visible = false;
				difficultySprite.visible = false;
				banner.visible = false;
				bgYellow.visible = true;
				for (m in menuCharacters.members)
					m.visible = false;

				arrowLeft.visible = true;
				arrowLeft.y = categoryText.y - 15;
				arrowRight.visible = true;
				arrowRight.y = categoryText.y - 15;

				changeCategory();

			case 1:
				nav.locked = true;
				nav2.locked = false;
				category = categoriesList[curCategory];
				scoreDisplay.visible = true;
				weekTitle.visible = true;
				tracks.visible = true;
				difficultySprite.visible = true;

				weekNames = categories.get(category);
				weekButtons.y = 0;
				weekLocks.y = 0;

				arrowLeft.x = FlxG.width * 0.72 - 60;
				arrowLeft.y = 475;
				arrowRight.x = FlxG.width * 0.72 + 320;
				arrowRight.y = 475;

				for (i in 0...weekNames.length)
				{
					var newWeek:WeekData = weekList.get(weekNames[i]);
					for (j in 0...newWeek.songs.length)
					{
						if (newWeek.songs[j].difficulties == null || newWeek.songs[j].difficulties.length == 0)
							newWeek.songs[j].difficulties = newWeek.difficulties;
					}
					weekList.set(weekNames[i], newWeek);

					var imageButton:WeekButton = new WeekButton(0, i * 120, newWeek.image);
					imageButton.screenCenter(X);
					weekButtons.add(imageButton);

					var lock:FlxSprite = new FlxSprite(imageButton.x + imageButton.width + 10, imageButton.y);
					lock.frames = arrowLeft.frames;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.visible = (newWeek.startsLocked && !unlockedWeeks.contains(weekNames[i]));
					weekUnlocked.push(!lock.visible);
					weekLocks.add(lock);
				}

				for (i in 0...weekNames.length)
					hscriptIdSet(weekNames[i], "thisButton", weekButtons.members[i]);

				changeSelection();
				changeDifficulty();

				weekButtons.y = 480 - (curWeek * 120);
				weekLocks.y = weekButtons.y;

				hscriptIdExec(weekNames[curWeek], "weekSelected", []);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		hscriptExec("update", [elapsed]);

		if (Options.keyJustPressed("fullscreen"))
			FlxG.fullscreen = !FlxG.fullscreen;

		weekButtons.y = FlxMath.lerp(weekButtons.y, 480 - (curWeek * 120), 0.17 * elapsed * 60);
		weekLocks.y = weekButtons.y;

		if (displayScore != score)
		{
			displayScore = Std.int(Math.floor(FlxMath.lerp(displayScore, score, 0.4)));
			if (Math.abs(displayScore - score) <= 10)
				displayScore = score;

			scoreDisplay.text = Lang.get("#smScore", [Std.string(displayScore)]);
		}

		if (!(nav.locked && nav2.locked))
		{
			if (nav.locked && Options.keyJustPressed("ui_reset"))
			{
				persistentUpdate = false;
				openSubState(new StoryMenuResetSubState(weekNames[curWeek], difficulty, getScore));
			}

			if (Options.keyJustPressed("ui_left") && (nav2.locked || weekUnlocked[curWeek]))
				arrowLeft.animation.play('press', true);

			if (Options.keyJustPressed("ui_right") && (nav2.locked || weekUnlocked[curWeek]))
				arrowRight.animation.play('press', true);

			if (Options.keyJustReleased("ui_left"))
				arrowLeft.animation.play('idle', true);

			if (Options.keyJustReleased("ui_right"))
				arrowRight.animation.play('idle', true);
		}

		hscriptExec("updatePost", [elapsed]);
	}

	public function hscriptAdd(id:String, file:String, ?forced:Bool = false)
	{
		if (Paths.hscriptExists(file) && (!myScripts.exists(id) || forced))
		{
			var newScript = new HscriptHandler(file);
			myScripts.set(id, newScript);
		}
		else if (myScripts.exists(id) && forced)
			myScripts.remove(id);
	}

	public function hscriptRefresh()
	{
		for (sc in myScripts.iterator())
			sc.refreshVariables();
	}

	public function hscriptExec(func:String, args:Array<Dynamic>)
	{
		for (sc in myScripts.iterator())
			sc.execFunc(func, args);
	}

	public function hscriptSet(vari:String, val:Dynamic)
	{
		for (sc in myScripts.iterator())
			sc.setVar(vari, val);
	}

	public function hscriptIdExec(id:String, func:String, args:Array<Dynamic>)
	{
		if (myScripts.exists(id))
			myScripts.get(id).execFunc(func, args);
	}

	public function hscriptIdSet(id:String, vari:String, val:Dynamic)
	{
		if (myScripts.exists(id))
			myScripts.get(id).setVar(vari, val);
	}

	public function hscriptIdGet(id:String, vari:String):Dynamic
	{
		if (myScripts.exists(id))
			return myScripts.get(id).getVar(vari);
		return null;
	}

	function changeCategory(change:Int = 0)
	{
		curCategory = Util.loop(curCategory + change, 0, categoriesList.length - 1);

		var categoryName:String = TitleState.defaultVariables.game;
		var categoryIconBytes:Bytes = null;
		if (categoriesList[curCategory] != "")
		{
			categoryName = ModLoader.getModMetaData(categoriesList[curCategory]).title;
			categoryIconBytes = ModLoader.getModMetaData(categoriesList[curCategory]).icon;
		}

		categoryText.text = categoryName;

		categoryText.screenCenter(X);
		arrowLeft.x = categoryText.x - arrowLeft.width - 30;
		arrowRight.x = categoryText.x + categoryText.width + 30;

		if (categoryIconBytes == null)
			categoryIcon.visible = false;
		else
		{
			categoryIcon.visible = true;
			categoryIcon.pixels = BitmapData.fromImage( Image.fromBytes(categoryIconBytes) );
			categoryIcon.scale.set(1, 1);
			categoryIcon.updateHitbox();
			if (categoryIcon.width > 250 || categoryIcon.height > 250)
			{
				categoryIcon.setGraphicSize(250);
				categoryIcon.updateHitbox();
			}
			categoryIcon.screenCenter();
			categoryIcon.y += 225;
		}
	}

	function changeSelection(change:Int = 0)
	{
		var oldWeek:String = weekNames[curWeek];
		curWeek = Util.loop(curWeek + change, 0, weekNames.length - 1);

		var i:Int = 0;

		weekButtons.forEachAlive(function(button:WeekButton)
		{
			if (i == curWeek && weekUnlocked[i])
				button.alpha = 1;
			else
				button.alpha = 0.6;
			i++;
		});

		difficultySprite.visible = weekUnlocked[curWeek];
		arrowLeft.visible = weekUnlocked[curWeek];
		arrowRight.visible = weekUnlocked[curWeek];

		var weekData:WeekData = weekList.get(weekNames[curWeek]);
		if (weekData.difficulties.length <= 1)
		{
			arrowLeft.visible = false;
			arrowRight.visible = false;
		}

		if (weekData.banner != null && weekData.banner != "")
		{
			banner.loadGraphic(Paths.image("ui/story_banners/" + weekData.banner));
			banner.setGraphicSize(1280);
			banner.updateHitbox();
			banner.visible = true;
			bgYellow.visible = false;
		}
		else
		{
			banner.visible = false;
			bgYellow.visible = true;
		}
		bgYellow.color = FlxColor.fromRGB(weekData.color[0], weekData.color[1], weekData.color[2]);

		for (i in 0...weekData.characters.length)
		{
			if (weekData.characters[i] == "")
				menuCharacters.members[i].visible = false;
			else
			{
				menuCharacters.members[i].visible = true;
				menuCharacters.members[i].refreshCharacter(weekData.characters[i]);
				if (menuCharacters.members[i].characterData.matchColor)
					menuCharacters.members[i].color = bgYellow.color;
				else
					menuCharacters.members[i].color = FlxColor.WHITE;
			}
		}

		if (weekData.title != null)
			weekTitle.text = Lang.get(weekData.title);

		tracks.text = Lang.get("#smTracks") + "\n\n";
		for (track in weekData.songs)
		{
			var songName:String = Song.getSongName(track.songId, weekData.difficulties[0]);
			tracks.text += songName.toUpperCase() + "\n";
		}
		tracks.screenCenter(X);
		tracks.x -= FlxG.width * 0.35;

		if (!weekData.difficulties.contains(difficulty))
		{
			difficulty = weekData.difficulties[0];
			onChangedDifficulty();
		}
		getScore();

		if (oldWeek != weekNames[curWeek])
		{
			hscriptIdExec(oldWeek, "weekUnselected", []);
			hscriptIdExec(weekNames[curWeek], "weekSelected", []);
		}
	}

	function changeDifficulty(change:Int = 0)
	{
		if (change != 0 && !weekUnlocked[curWeek]) return;

		var weekData:WeekData = weekList.get(weekNames[curWeek]);
		if (weekData.difficulties.length <= 1)
			return;

		var diffInt:Int = weekData.difficulties.indexOf(difficulty);
		diffInt = Util.loop(diffInt + change, 0, weekData.difficulties.length - 1);
		difficulty = weekData.difficulties[diffInt];

		onChangedDifficulty();
		getScore();
	}

	function onChangedDifficulty()
	{
		difficultySprite.x += difficultySprite.width / 2;
		difficultySprite.loadGraphic(Paths.image("ui/difficulties/" + difficulty.toLowerCase()));
		difficultySprite.x -= difficultySprite.width / 2;

		difficultySprite.y = 460;
		difficultySprite.alpha = 0;
		FlxTween.tween(difficultySprite, {y: 490, alpha: 1}, 0.07);
	}

	function getScore()
	{
		score = ScoreSystems.loadWeekScore(weekNames[curWeek], difficulty);
	}

	public static function gotoWeek(week:String, diff:String, ?delay:Float = 1)
	{
		ResultsSubState.resetStatics();
		ScoreSystems.resetWeekData();

		new FlxTimer().start(delay, function(tmr:FlxTimer)
		{
			FlxG.sound.music.fadeOut(0.5, 0, function(twn:FlxTween) { FlxG.sound.music.stop(); });
			PlayState.firstPlay = true;
			var weekD:WeekData = parseWeek(week, true);
			if (weekD.hscript != null && weekD.hscript != "")
			{
				HscriptState.script = "data/states/" + weekD.hscript;
				FlxG.switchState(new HscriptState());
			}
			else
			{
				if (Std.isOfType(FlxG.state, HscriptState))
					HscriptState.setFromState();
				FlxG.switchState(new PlayState(true, "", diff, week, 0));
			}
		});
	}

	override public function beatHit()
	{
		super.beatHit();

		hscriptExec("beatHit", []);
	}

	override public function stepHit()
	{
		super.stepHit();

		menuCharacters.forEachAlive(function(char:MenuCharacter)
		{
			if (char.animation.curAnim.name != "hey" && curStep % Std.int(Math.round(char.danceSpeed * 4)) == 0)
				char.dance();
		});

		hscriptExec("stepHit", []);
	}

	public static function lockWeek(week:String)
	{
		if (FlxG.save.data.unlockedWeeks.contains(week))
			FlxG.save.data.unlockedWeeks.remove(week);
	}

	public static function unlockWeek(week:String)
	{
		if (!FlxG.save.data.unlockedWeeks.contains(week))
			FlxG.save.data.unlockedWeeks.push(week);
	}

	public static function unlockWeeks(weekBeaten:String)
	{
		var allWeeks:Array<String> = Paths.listFiles("data/weeks/", ".json");
		for (w in allWeeks)
		{
			var weekStuff:WeekData = cast Paths.json("weeks/" + w);
			if (weekStuff.startsLocked && weekStuff.weekToUnlock == weekBeaten)
				unlockWeek(w);
		}
		FlxG.save.flush();
	}
}

class StoryMenuResetSubState extends FlxSubState
{
	var yes:Alphabet;
	var no:Alphabet;
	var option:Bool = false;

	override public function new(week:String, difficulty:String, ?onOption:Void->Void = null)
	{
		super();

		FlxG.sound.play(Paths.sound("ui/cancelMenu"));

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		var confirmText:Alphabet = new Alphabet(0, 150, "Are you sure you want to reset your score for this week and difficulty?", "bold", Std.int(FlxG.width * 0.9), true, 0.75);
		confirmText.align = "center";
		confirmText.screenCenter(X);
		add(confirmText);

		yes = new Alphabet(0, 500, "");
		add(yes);

		no = new Alphabet(0, 500, "");
		add(no);

		updateText();

		for (m in members)
		{
			var s:FlxSprite = cast m;
			var a:Float = s.alpha;
			s.alpha = 0;
			FlxTween.tween(s, {alpha: a}, 0.5);
		}

		var nav:UINumeralNavigation = new UINumeralNavigation(function(a) {
			option = !option;
			updateText();
		}, null, function() {
			if (!option)
				ScoreSystems.resetWeekScore(week, difficulty);
			if (onOption != null)
				onOption();
			close();
		});
		add(nav);
	}

	function updateText()
	{
		if (option)
		{
			yes.text = "Yes";
			no.text = "> No <";
		}
		else
		{
			yes.text = "> Yes <";
			no.text = "No";
		}
		yes.x = (FlxG.width / 3) - (yes.width / 2);
		no.x = (FlxG.width * 2 / 3) - (no.width / 2);
	}
}