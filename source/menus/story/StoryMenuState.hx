package menus.story;

import flixel.FlxG;
import flixel.FlxSubState;
import haxe.ds.ArraySort;
import haxe.Json;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

import haxe.io.Bytes;
import lime.graphics.Image;
import openfl.display.BitmapData;

import data.ObjectData;
import data.Options;
import data.ScoreSystems;
import data.Song;
import game.PlayState;
import menus.UINavigation;
import helpers.DeepEquals;
import objects.Alphabet;
import objects.AnimatedSprite;
import objects.Character;
import scripting.HscriptHandler;
import scripting.HscriptState;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	static var menuState:Int = 0;
	var categories:Map<String, Array<String>>;
	var categoriesList:Array<String> = [];
	var category:String = "";
	static var curCategory:Int = 0;

	var weekList:Map<String, WeekData>;
	public var weekNames:Array<String> = [];
	var weekButtons:FlxTypedSpriteGroup<StoryWeekButton>;
	var weekLocks:FlxSpriteGroup;
	public static var curWeek:Int = 0;
	var unlockedWeeks:Array<String> = [];
	var weekUnlocked:Array<Bool> = [];

	var menuCharacters:FlxTypedSpriteGroup<StoryMenuCharacter>;
	var scoreDisplay:FlxText;
	public var score:Int = 0;
	var displayScore:Int = 0;
	var weekTitle:FlxText;
	var tracksLabel:FlxText;
	var tracks:FlxText;
	var bgYellow:FlxSprite;
	var banner:FlxSprite;
	var categoryText:Alphabet;
	var categoryIcon:FlxSprite;

	var difficulties:Array<String> = [];
	var difficultiesLocked:Array<String> = [];
	public static var difficulty:String = "normal";
	var difficultySprite:FlxSprite;
	var difficultyLock:FlxSprite;
	var arrowLeft:AnimatedSprite;
	var arrowRight:AnimatedSprite;

	var nav:UINumeralNavigation;
	var nav2:UINumeralNavigation;
	public static var navSwitch:Bool = true;

	var myScripts:Map<String, HscriptHandler>;

	public static function convertWeek(id:String, ?quick:Bool = false, ?rawData:Dynamic = null):WeekData
	{
		var data:Dynamic = rawData;
		if (data == null)
			data = Paths.json("weeks/" + id);

		var wData:WeekData = cast data;
		if (data.weekName != null)			// This is a Psych Engine week and must be converted to the Restructure Engine format
		{
			wData = {
				image: id,
				title: data.storyName.toUpperCase(),
				characters: [[data.weekCharacters[0], 0, 0], [data.weekCharacters[1], Math.round(FlxG.width / 3 / 5) * 5, 0], [data.weekCharacters[2], Math.round(FlxG.width * 2 / 3 / 5) * 5, 0]],
				banner: "menu_" + data.weekBackground,
				songs: [],
				startsLocked: !data.startUnlocked,
				startsLockedInFreeplay: false,
				weekToUnlock: data.weekBefore,
				hiddenWhenLocked: data.hiddenUntilUnlocked
			}

			var oldSongList:Array<Array<Dynamic>> = cast data.songs;
			for (s in oldSongList)
			{
				var sId:String = cast s[0];
				wData.songs.push({songId: sId.toLowerCase().replace(" ","-")});
			}

			if (data.difficulties != null && data.difficulties != "")
				wData.difficulties = data.difficulties.toLowerCase().split(",");

			if (data.hideStoryMode)
				wData.condition = "freeplayonly";
			else if (data.hideFreeplay)
				wData.condition = "storyonly";
		}

		if (wData.startsLockedInFreeplay == null)
			wData.startsLockedInFreeplay = false;

		if (wData.difficulties == null || wData.difficulties.length <= 0)
			wData.difficulties = ["normal", "hard", "easy"];

		if (wData.difficultiesLocked == null)
			wData.difficultiesLocked = [];

		if (!Paths.imageExists("ui/story/weeks/" + wData.image))
			wData.image = TitleState.defaultVariables.storyimage;

		for (i in 0...wData.characters.length)
		{
			if (Std.isOfType(wData.characters[i], String))
				wData.characters[i] = [wData.characters[i], Math.round((FlxG.width * (i / wData.characters.length)) / 5) * 5, 0];
		}

		for (s in wData.songs)
		{
			if (!Paths.songExists(s.songId, "Inst"))
			{
				if (Paths.songExists(id + "/" + s.songId, "Inst"))
					s.songId = id + "/" + s.songId;
				else if (id.indexOf("/") > -1 && Paths.songExists(id.substr(0, id.lastIndexOf("/")+1) + s.songId, "Inst"))
					s.songId = id.substr(0, id.lastIndexOf("/")+1) + s.songId;
			}

			if (s.variant == null || s.variant == "")
				s.variant = "bf";

			if (s.difficulties == null || s.difficulties.length <= 0)
				s.difficulties = wData.difficulties.copy();
		}

		if (!quick)
		{
			var iconList:Array<String> = null;
			for (s in wData.songs)
			{
				if (s.iconNew == null)
				{
					if (s.icon == null)
						s.iconNew = "none";
					else if (Paths.imageExists("ui/freeplay/icons/" + s.icon + "pixel"))
						s.iconNew = s.icon;
					else if (Paths.imageExists("ui/freeplay/icons/" + s.icon + "dypixel"))
						s.iconNew = s.icon + "dy";
					else if (Paths.imageExists("ui/freeplay/icons/" + s.icon + "mypixel"))
						s.iconNew = s.icon + "my";
					else
						s.iconNew = "none";
				}

				if (s.characters == null)
					s.characters = 3;

				if (s.characterLabels == null || s.characterLabels.length < 3)
					s.characterLabels = ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"];
			}
		}

		return wData;
	}

	public static function parseWeek(id:String, ?quick:Bool = false, ?rawData:Dynamic = null):WeekData
	{
		var wData:WeekData = convertWeek(id, quick, rawData);

		if (wData.color == null)
			wData.color = [249, 207, 81];

		if (wData.condition == null)
			wData.condition = "";
		wData.condition = wData.condition.toLowerCase();

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

		weekButtons = new FlxTypedSpriteGroup<StoryWeekButton>();
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

		menuCharacters = new FlxTypedSpriteGroup<StoryMenuCharacter>();
		add(menuCharacters);
		for (i in 0...3)
		{
			var char:StoryMenuCharacter = new StoryMenuCharacter(i);
			menuCharacters.add(char);
		}

		scoreDisplay = new FlxText(10, 10, 0, Lang.get("#story.highscore", [Std.string(displayScore)]), 32);
		scoreDisplay.font = "VCR OSD Mono";
		add(scoreDisplay);

		weekTitle = new FlxText(0, 10, FlxG.width - 10, "", 32);
		weekTitle.alpha = 0.7;
		weekTitle.font = "VCR OSD Mono";
		weekTitle.alignment = RIGHT;
		add(weekTitle);

		tracksLabel = new FlxText(0, 500, 0, Lang.get("#story.tracks"), 32);
		tracksLabel.color = 0xFFE55777;
		tracksLabel.font = "VCR OSD Mono";
		tracksLabel.screenCenter(X);
		tracksLabel.x -= FlxG.width * 0.35;
		add(tracksLabel);

		tracks = new FlxText(0, 558, 0, "", 32);
		tracks.color = 0xFFE55777;
		tracks.font = "VCR OSD Mono";
		tracks.alignment = CENTER;
		add(tracks);

		difficultySprite = new FlxSprite(1075, 490);
		add(difficultySprite);

		difficultyLock = new FlxSprite(1075, 475, Paths.image("ui/lock"));
		difficultyLock.x -= Math.round(difficultyLock.width / 2);
		add(difficultyLock);

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

		onChangedDifficulty();

		myScripts = new Map<String, HscriptHandler>();

		categories = new Map<String, Array<String>>();
		categoriesList = [];
		var possibleCats:Array<String> = [];
		weekList = new Map<String, WeekData>();
		for (file in Paths.listFilesAndModsSub("data/weeks/", ".json"))
		{
			var rawData:String = Paths.rawFromMod("data/weeks/"+file[0]+".json", file[1]);
			var newWeek:WeekData = parseWeek(file[0], true, Json.parse(rawData));

			if (newWeek.startsLocked && !FlxG.save.data.unlockedWeeks.contains(file[0]) && ScoreSystems.weekBeaten(newWeek.weekToUnlock))
				unlockWeek(file[0]);

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
			if (possibleCats.contains(c) || Paths.hscriptExists("data/states/" + ModLoader.modMenus[c].story))
				categoriesList.push(c);
		}

		weekOrder = Paths.text("weekOrder").replace("\r","").split("\n");
		for (c in categories.keys())
			ArraySort.sort(categories[c], sortWeeks);

		nav = new UINumeralNavigation(changeCategory, null, function() {
			if (ModLoader.modMenus.exists(categoriesList[curCategory]) && Paths.hscriptExists("data/states/" + ModLoader.modMenus[categoriesList[curCategory]].story))
				FlxG.switchState(new HscriptState("data/states/" + ModLoader.modMenus[categoriesList[curCategory]].story));
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
			if (weekUnlocked[curWeek] && !difficultiesLocked.contains(difficulty))
			{
				FlxG.sound.play(Paths.sound("ui/confirmMenu"));
				menuCharacters.forEachAlive(function(char:StoryMenuCharacter) { char.playAnim("hey"); });
				if (weekButtons.members.length > curWeek)
					weekButtons.members[curWeek].flicker();
				nav2.locked = true;

				var difficultyList:Array<String> = difficulties;
				var weekData:WeekData = weekList.get(weekNames[curWeek]);
				for (s in weekData.songs)
				{
					if ((s.songId != null && s.songId != "") && (s.difficulties != null && !DeepEquals.deepEquals(difficulties, s.difficulties)))
					{
						difficultyList = [difficulty];
						break;
					}
				}
				Util.gotoWeek(weekNames[curWeek], difficulty, difficultyList);
			}
		}, function() {
			menuState = 0;
			clearMenuStuff();
			reloadMenuStuff();
		}, changeSelection);
		nav2.uiSounds = [true, false, true];
		add(nav2);

		if (categoriesList.length <= 1 || !navSwitch)
		{
			menuState = 1;
			remove(nav);
			nav2.back = nav.back;
		}
		nav2.leftClick = nav2.accept;
		nav2.rightClick = nav2.back;
		reloadMenuStuff();

		Util.menuMusic();

		hscriptExec("create", []);
	}

	function clearMenuStuff()
	{
		switch (menuState)
		{
			case 0:
				hscriptIdExec(weekNames[curWeek], "weekUnselected", []);

				weekButtons.forEachAlive(function(btn:StoryWeekButton)
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
				FlxTween.cancelTweensOf(bgYellow);
				FlxTween.color(bgYellow, 0.9, bgYellow.color, 0xFFF9CF51, {ease: FlxEase.quartOut});

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
				tracksLabel.visible = false;
				tracks.visible = false;
				difficultySprite.visible = false;
				difficultyLock.visible = false;
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
				tracksLabel.visible = true;
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

					var imageButton:StoryWeekButton = new StoryWeekButton(0, i * 120, newWeek.image);
					imageButton.screenCenter(X);
					imageButton.y -= imageButton.height / 2;
					weekButtons.add(imageButton);

					var lock:FlxSprite = new FlxSprite(imageButton.x + imageButton.width + 10, i * 120, Paths.image("ui/lock"));
					lock.y -= lock.height / 2;
					lock.visible = (newWeek.startsLocked && !unlockedWeeks.contains(weekNames[i]));
					weekUnlocked.push(!lock.visible);
					weekLocks.add(lock);
				}

				for (i in 0...weekNames.length)
					hscriptIdSet(weekNames[i], "thisButton", weekButtons.members[i]);

				changeSelection();
				changeDifficulty();

				weekButtons.y = 520 - (curWeek * 120);
				weekLocks.y = weekButtons.y;

				hscriptIdExec(weekNames[curWeek], "weekSelected", []);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		hscriptExec("update", [elapsed]);

		weekButtons.y = FlxMath.lerp(weekButtons.y, 520 - (curWeek * 120), 0.17 * elapsed * 60);
		weekLocks.y = weekButtons.y;

		if (displayScore != score)
		{
			displayScore = Std.int(Math.floor(FlxMath.lerp(displayScore, score, 0.4)));
			if (Math.abs(displayScore - score) <= 10)
				displayScore = score;

			scoreDisplay.text = Lang.get("#story.highscore", [Std.string(displayScore)]);
		}

		if (nav.locked)
		{
			menuCharacters.forEachAlive(function(char:StoryMenuCharacter)
			{
				if (char.characterData.matchColor)
					char.color = bgYellow.color;
				else
					char.color = FlxColor.WHITE;
			});
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
			myScripts[id] = newScript;
			newScript.setVar("scriptId", id);
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

		weekButtons.forEachAlive(function(button:StoryWeekButton)
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
		difficulties = weekData.difficulties.copy();
		var diffWasLocked:Bool = difficultiesLocked.contains(difficulty);
		if (weekData.difficultiesLocked != null && weekData.difficultiesLocked.length > 0 && !ScoreSystems.weekBeaten(weekNames[curWeek]))
			difficultiesLocked = weekData.difficultiesLocked.copy();
		else
			difficultiesLocked = [];

		if (difficulties.length <= 1)
		{
			arrowLeft.visible = false;
			arrowRight.visible = false;
		}

		if (weekData.banner != null && weekData.banner != "" && Paths.imageExists("ui/story/banners/" + weekData.banner))
		{
			banner.loadGraphic(Paths.image("ui/story/banners/" + weekData.banner));
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

		FlxTween.cancelTweensOf(bgYellow);
		var clr:FlxColor = FlxColor.fromRGB(weekData.color[0], weekData.color[1], weekData.color[2]);
		FlxTween.color(bgYellow, 0.9, bgYellow.color, clr, {ease: FlxEase.quartOut});

		for (i in 0...weekData.characters.length)
		{
			if (weekData.characters[i][0] == "")
				menuCharacters.members[i].visible = false;
			else
			{
				menuCharacters.members[i].visible = true;
				menuCharacters.members[i].setPosition(weekData.characters[i][1], 56 + weekData.characters[i][2]);
				menuCharacters.members[i].refreshCharacter(weekData.characters[i][0]);
			}
		}

		if (weekData.title != null)
			weekTitle.text = Lang.get(weekData.title);

		if (!difficulties.contains(difficulty))
		{
			difficulty = difficulties[0];
			onChangedDifficulty();
		}
		else if (diffWasLocked != difficultiesLocked.contains(difficulty))
			onChangedDifficulty();
		listSongNames();
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

		if (difficulties.length <= 1)
			return;

		var diffInt:Int = difficulties.indexOf(difficulty);
		diffInt = Util.loop(diffInt + change, 0, difficulties.length - 1);
		difficulty = difficulties[diffInt];

		onChangedDifficulty();
		listSongNames();
		getScore();
	}

	function onChangedDifficulty()
	{
		if (Paths.sparrowExists("ui/story/difficulties/" + difficulty))
		{
			difficultySprite.frames = Paths.sparrow("ui/story/difficulties/" + difficulty);
			difficultySprite.animation.addByPrefix("idle", "", 24, true);
			difficultySprite.animation.play("idle");
		}
		else if (Paths.imageExists("ui/story/difficulties/" + difficulty))
			difficultySprite.loadGraphic(Paths.image("ui/story/difficulties/" + difficulty));
		else if (Paths.sparrowExists("ui/difficulties/" + difficulty))
		{
			difficultySprite.frames = Paths.sparrow("ui/difficulties/" + difficulty);
			difficultySprite.animation.addByPrefix("idle", "", 24, true);
			difficultySprite.animation.play("idle");
		}
		else
			difficultySprite.loadGraphic(Paths.image("ui/difficulties/" + difficulty));

		difficultyLock.visible = (weekUnlocked[curWeek] && difficultiesLocked.contains(difficulty));

		FlxTween.cancelTweensOf(difficultySprite);
		difficultySprite.x = 1075 - (difficultySprite.width / 2);
		difficultySprite.y = 460;
		difficultySprite.alpha = 0;
		FlxTween.tween(difficultySprite, {y: 490, alpha: (difficultyLock.visible ? 0.5 : 1)}, 0.07);

		FlxTween.cancelTweensOf(difficultyLock);
		difficultyLock.y = 445;
		difficultyLock.alpha = 0;
		FlxTween.tween(difficultyLock, {y: 475, alpha: 1}, 0.07);
	}

	function listSongNames()
	{
		var weekData:WeekData = weekList.get(weekNames[curWeek]);
		tracks.text = "";
		for (i in 0...weekData.songs.length)
		{
			var track:WeekSongData = weekData.songs[i];
			if ((track.songId != null && track.songId != "") && (track.difficulties == null || track.difficulties.contains(difficulty)))
			{
				var songName:String = Song.getSongName(track.songId, difficulty, track.variant);
				tracks.text += songName;
				if (i < weekData.songs.length - 1)
					tracks.text += "\n";
			}
		}
		tracks.x = (FlxG.width * 0.15) - (tracks.width / 2);
		if (tracks.x < 0)
			tracks.scale.x = (tracks.width + (tracks.x * 2)) / tracks.width;
		else
			tracks.scale.x = 1;

		hscriptExec("listSongNames", []);
	}

	function getScore()
	{
		score = ScoreSystems.loadWeekScore(weekNames[curWeek], difficulty);
	}

	override public function beatHit()
	{
		super.beatHit();

		hscriptExec("beatHit", []);
	}

	override public function stepHit()
	{
		super.stepHit();

		menuCharacters.forEachAlive(function(char:StoryMenuCharacter) {
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
		var allWeeks:Array<String> = Paths.listFilesSub("data/weeks/", ".json");
		for (w in allWeeks)
		{
			var weekStuff:WeekData = cast Paths.json("weeks/" + w);
			if (weekStuff.startsLocked && weekStuff.weekToUnlock == weekBeaten)
				unlockWeek(w);
		}
		FlxG.save.flush();
	}
}