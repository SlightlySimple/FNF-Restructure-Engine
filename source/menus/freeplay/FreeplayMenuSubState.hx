package menus.freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxRuntimeShader;
import flxanimate.FlxAnimate;
import haxe.Json;
import haxe.ds.ArraySort;
import lime.graphics.Image;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import data.ObjectData;
import data.Options;
import data.ScoreSystems;
import data.SMFile;
import data.Song;
import helpers.IntervalShake;
import objects.AnimatedSprite;
import game.PlayState;
import game.results.ResultsState;
import menus.story.StoryMenuState;
import menus.UINavigation;
import scripting.HscriptState;
import shaders.StrokeShader;
import MusicBeatState;

using StringTools;

typedef FreeplayTrack =
{
	var name:String;
	var timings:Array<Array<Float>>;
	var start:Float;
	var end:Float;
}

class FreeplayMenuSubState extends MusicBeatSubState
{
	static var menuState:Int = 0;
	var categories:Map<String, Array<String>>;
	var categoriesList:Array<String> = [];
	static var category:String = "";
	var curCategory:Int = 0;
	var filters:Array<String> = [];

	var weeks:Map<String, WeekData> = new Map<String, WeekData>();
	var songLists:Map<String, Array<String>> = new Map<String, Array<String>>();
	static var selectedId:String = "";
	var curSong:Int = 0;

	public static var difficulty:String = "normal";

	var pinkBack:FlxSprite;
	var orangeBackShit:FlxSprite;
	var alsoOrangeLOL:FlxSprite;
	var grpTxtScrolls:FlxTypedSpriteGroup<FreeplayScrollingText>;

	var confirmGlow:FlxSprite;
	var confirmGlow2:FlxSprite;
	var confirmTextGlow:FlxSprite;
	var backingTextYeah:FlxAnimate;

	var cardGlow:FlxSprite;
	var dj:FreeplayBoyfriend;
	var ostName:FlxText;
	var grpCapsules:FlxTypedSpriteGroup<FreeplayCapsule>;
	var difficultySprite:FlxSprite;
	var difficultyText:FlxText;
	var diffSelLeft:AnimatedSprite;
	var diffSelRight:AnimatedSprite;

	var rankCamera:FlxCamera;
	var rankBg:FlxSprite;
	var rankVignette:FlxSprite;

	var curTrack:FreeplayTrack = null;
	var defaultTrack:FreeplayTrack = null;
	var randomTrack:FreeplayTrack = null;

	var modIcon:FlxSprite;
	var albumRoll:FreeplayAlbum;
	var diffStars:FreeplayDifficultyStars;

	var fp:FreeplayScore;
	var fpClear:FreeplayClear;

	var letterSort:FreeplayFilters;

	var chartInfo:FreeplayChartInfo;

	var nav:UINumeralNavigation;
	var nav2:UINumeralNavigation;
	public static var navSwitch:Bool = true;
	var songStuff:Array<FlxSprite> = [];

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

	override public function new(?shouldDoIntro:Bool = false)
	{
		super();
		MainMenuState.curSubstate = "freeplay";

		if (FlxG.save.data.unlockedWeeks == null)
			FlxG.save.data.unlockedWeeks = [];

		defaultTrack = {name: Paths.music(Util.menuSong), timings: [[0, Std.parseFloat(Paths.raw("music/" + Util.menuSong + ".bpm"))]], start: -1, end: -1};
		randomTrack = {name: Paths.music("freeplayRandom"), timings: [[0, Std.parseFloat(Paths.raw("music/freeplayRandom.bpm"))]], start: -1, end: -1};
		curTrack = defaultTrack;

		camera = new FlxCamera();
		camera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camera, false);

		rankCamera = new FlxCamera();
		rankCamera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(rankCamera, false);

		pinkBack = new FlxSprite(Paths.image("ui/freeplay/pinkBack"));
		pinkBack.color = 0xFFFFD863;
		add(pinkBack);
		introActions.push(function() {
			pinkBack.x -= pinkBack.width;
			pinkBack.color = 0xFFFFD4E9;
			FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
		});

		orangeBackShit = new FlxSprite(84, 440).makeGraphic(Std.int(pinkBack.width), 75, 0xFFFEDA00);
		add(orangeBackShit);

		alsoOrangeLOL = new FlxSprite(0, orangeBackShit.y).makeGraphic(100, Std.int(orangeBackShit.height), 0xFFFFD400);
		add(alsoOrangeLOL);

		outroActions.push(function() {
			FlxTween.tween(pinkBack, {x: -pinkBack.width}, 0.4, {ease: FlxEase.expoIn});
			FlxTween.tween(orangeBackShit, {x: -pinkBack.width}, 0.4, {ease: FlxEase.expoIn});
			FlxTween.tween(alsoOrangeLOL, {x: -pinkBack.width}, 0.4, {ease: FlxEase.expoIn});
		});

		FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);

		confirmGlow = new FlxSprite(-30, 240, Paths.image("ui/freeplay/confirmGlow"));
		confirmGlow.blend = ADD;
		confirmGlow.visible = false;

		confirmGlow2 = new FlxSprite(confirmGlow.x, confirmGlow.y, Paths.image("ui/freeplay/confirmGlow2"));
		confirmGlow2.visible = false;

		add(confirmGlow2);
		add(confirmGlow);

		confirmTextGlow = new FlxSprite(-8, 115, Paths.image("ui/freeplay/glowingText"));
		confirmTextGlow.blend = ADD;
		confirmTextGlow.visible = false;
		add(confirmTextGlow);

		backingTextYeah = new FlxAnimate(640, 370, Paths.atlas("ui/freeplay/backing-text-yeah"));
		backingTextYeah.anim.addBySymbol("BF back card confirm raw", "BF back card confirm raw", 0, 0, 24);
		backingTextYeah.visible = false;
		add(backingTextYeah);

		grpTxtScrolls = new FlxTypedSpriteGroup<FreeplayScrollingText>();
		add(grpTxtScrolls);

		grpTxtScrolls.add(new FreeplayScrollingText(0, 160, Lang.get("#freeplay.backgroundText.0"), FlxG.width, true, 43, 0xFFFFF383, 6.8));
		grpTxtScrolls.add(new FreeplayScrollingText(0, 220, Lang.get("#freeplay.backgroundText.1"), FlxG.width, false, 60, 0xFFFF9963, -3.8));
		grpTxtScrolls.add(new FreeplayScrollingText(0, 285, Lang.get("#freeplay.backgroundText.2"), FlxG.width, true, 43, FlxColor.WHITE, 3.5));
		grpTxtScrolls.add(new FreeplayScrollingText(0, 335, Lang.get("#freeplay.backgroundText.1"), FlxG.width, false, 60, 0xFFFF9963, -3.8));
		grpTxtScrolls.add(new FreeplayScrollingText(0, 397, Lang.get("#freeplay.backgroundText.0"), FlxG.width, true, 43, 0xFFFFF383, 6.8));
		grpTxtScrolls.add(new FreeplayScrollingText(0, 450, Lang.get("#freeplay.backgroundText.1"), FlxG.width, false, 60, 0xFFFEA400, -3.8));

		outroActions.push(function() {
			grpTxtScrolls.forEachAlive(function(txt:FreeplayScrollingText) {
				if (txt.speed < 0)
					FlxTween.tween(txt, {x: -txt.width * 2}, 0.4, {ease: FlxEase.expoIn});
				else
					FlxTween.tween(txt, {x: FlxG.width * 2}, 0.4, {ease: FlxEase.expoIn});
			});
		});

		cardGlow = new FlxSprite(-30, -30, Paths.image("ui/freeplay/cardGlow"));
		cardGlow.blend = ADD;
		cardGlow.visible = false;
		add(cardGlow);

		dj = new FreeplayBoyfriend(640, 366);
		add(dj);
		introActions.push(function() {
			dj.playAnim("boyfriend dj intro");
		});
		outroActions.push(function() {
			FlxTween.tween(dj, {x: -640}, 0.5, {ease: FlxEase.expoIn});
		});

		var bgDad:FlxSprite = new FlxSprite(pinkBack.width * 0.75, 0, Paths.image("ui/freeplay/freeplayBGdad"));
		bgDad.setGraphicSize(0, FlxG.height);
		bgDad.updateHitbox();

		var blackOverlay:FlxSprite = new FlxSprite(pinkBack.width * 0.75).makeGraphic(Std.int(bgDad.width), Std.int(bgDad.height), FlxColor.BLACK);
		add(blackOverlay);
		introActions.push(function() {
			blackOverlay.x = FlxG.width;
			FlxTween.tween(blackOverlay, {x: pinkBack.width * 0.75}, 0.7, {ease: FlxEase.quintOut});
		});

		var bgDadShader:FlxRuntimeShader = new FlxRuntimeShader(Paths.shader("AngleMask"), null);
		bgDadShader.data.endPosition.value = [90, 100];
		bgDad.shader = bgDadShader;
		blackOverlay.shader = bgDadShader;
		add(bgDad);
		outroActions.push(function() {
			FlxTween.tween(bgDad, {x: FlxG.width * 1.5}, 0.4, {ease: FlxEase.expoIn});
			FlxTween.tween(blackOverlay, {x: FlxG.width * 1.5}, 0.4, {ease: FlxEase.expoIn});
		});

		rankBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xD3000000);
		rankBg.alpha = 0;
		rankBg.cameras = [rankCamera];
		add(rankBg);

		grpCapsules = new FlxTypedSpriteGroup<FreeplayCapsule>();
		add(grpCapsules);
		introActions.push(function() {
			grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
				capsule.doAnim("enter");
			});
		});
		outroActions.push(function() {
			grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
				capsule.doAnim("exit");
			});
		});

		difficultySprite = new FlxSprite(90, 80, Paths.image("ui/freeplay/difficulties/normal"));
		add(difficultySprite);
		songStuff.push(difficultySprite);

		difficultyText = new FlxText(85, 80, 0, "").setFormat("FNF Dialogue", 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		difficultyText.borderSize = 4;
		add(difficultyText);
		songStuff.push(difficultyText);

		diffSelLeft = new AnimatedSprite(20, difficultySprite.y - 10, Paths.sparrow("ui/freeplay/freeplaySelector"));
		diffSelLeft.addAnim("idle", "", 24, true);
		diffSelLeft.playAnim("idle");
		add(diffSelLeft);
		songStuff.push(diffSelLeft);

		diffSelRight = new AnimatedSprite(325, difficultySprite.y - 10, diffSelLeft.frames);
		diffSelRight.flipX = true;
		diffSelRight.addAnim("idle", "", 24, true);
		diffSelRight.playAnim("idle");
		add(diffSelRight);
		songStuff.push(diffSelRight);

		if (menuState > 0 && !shouldDoIntro)
			difficulty = PlayState.difficulty;

		if (difficulty != "normal")
			onChangeDifficulty();

		modIcon = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		modIcon.angle = 10;
		add(modIcon);
		introActions.push(function() {
			modIcon.x += FlxG.width / 2;
			FlxTween.tween(modIcon, {x: modIcon.x - FlxG.width / 2}, 0.3, {ease: FlxEase.expoOut});
		});
		outroActions.push(function() {
			FlxTween.tween(modIcon, {x: modIcon.x + FlxG.width / 2}, 0.3, {ease: FlxEase.expoIn});
		});

		albumRoll = new FreeplayAlbum();
		albumRoll.visible = false;
		add(albumRoll);

		albumRoll.album = "";

		diffStars = new FreeplayDifficultyStars(140, 39);
		add(diffStars);

		chartInfo = new FreeplayChartInfo();
		add(chartInfo);
		songStuff.push(chartInfo);

		var overhangStuff:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 64, FlxColor.BLACK);
		add(overhangStuff);
		introActions.push(function() {
			overhangStuff.y -= overhangStuff.height;
			FlxTween.tween(overhangStuff, {y: 0}, 0.3, {ease: FlxEase.quartOut});
		});

		var fnfFreeplay:FlxText = new FlxText(8, 8, 0, Lang.get("#freeplay.title"), 48);
		fnfFreeplay.font = 'VCR OSD Mono';
		add(fnfFreeplay);

		ostName = new FlxText(0, 8, 0, Lang.get("#freeplay.ost"), 48);
		ostName.font = 'VCR OSD Mono';
		ostName.visible = false;
		ostName.x = Math.round(FlxG.width - ostName.width - 16);
		add(ostName);

		outroActions.push(function() {
			FlxTween.tween(overhangStuff, {y: -overhangStuff.height}, 0.2, {ease: FlxEase.expoIn});
			FlxTween.tween(fnfFreeplay, {y: -overhangStuff.height}, 0.2, {ease: FlxEase.expoIn});
		});

		var fnfHighscoreSpr:AnimatedSprite = new AnimatedSprite(860, 70, Paths.sparrow("ui/freeplay/highscore"));
		fnfHighscoreSpr.addAnim("highscore", "highscore small", 24, false);
		add(fnfHighscoreSpr);
		songStuff.push(fnfHighscoreSpr);

		new FlxTimer().start(FlxG.random.float(12, 50), function(tmr:FlxTimer) {
			fnfHighscoreSpr.playAnim("highscore");
			tmr.time = FlxG.random.float(20, 60);
		}, 0);

		fp = new FreeplayScore(920, 120, 7);
		add(fp);
		songStuff.push(fp);

		fpClear = new FreeplayClear(1165, 65);
		add(fpClear);
		songStuff.push(fpClear);

		letterSort = new FreeplayFilters(400, 75);
		letterSort.onChanged = function(filter:String) {
			switch (filter)
			{
				case "ALL": filters = [];
				case "#": filters = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
				default:
					if (filter.length == 1)
						filters = [filter];
					else
					{
						filters = [];
						for (i in filter.charCodeAt(0)...filter.charCodeAt(1) + 1)
							filters.push(String.fromCharCode(i));
					}
			}
			if (menuState == 0)
				changeCategory();
			else
			{
				changeSelection();
				grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
					if (capsule.songId != "" && capsule.songId != "!random")
						capsule.updateFavorited();
				});
			}
		}
		add(letterSort);
		outroActions.push(function() {
			FlxTween.tween(letterSort, {y: -100}, 0.3, {ease: FlxEase.expoIn});
		});

		introActions.push(function() {
			orangeBackShit.visible = false;
			alsoOrangeLOL.visible = false;
			bgDad.visible = false;
			grpTxtScrolls.visible = false;
			letterSort.visible = false;
			fnfFreeplay.visible = false;

			var sillyStroke:StrokeShader = new StrokeShader(0xFFFFFFFF, 2, 2);
			fnfFreeplay.shader = sillyStroke;

			new FlxTimer().start(18 / 24, function(tmr:FlxTimer) {
				pinkBack.color = 0xFFFFD863;
				orangeBackShit.visible = true;
				alsoOrangeLOL.visible = true;
				bgDad.visible = true;
				grpTxtScrolls.visible = true;
				letterSort.visible = true;

				cardGlow.visible = true;
				FlxTween.tween(cardGlow, {alpha: 0}, 0.45, {ease: FlxEase.sineOut});
				FlxTween.tween(cardGlow.scale, {x: 1.2, y: 1.2}, 0.45, {ease: FlxEase.sineOut});

				new FlxTimer().start(1 / 24, function(handShit) {
					fnfFreeplay.visible = true;

					new FlxTimer().start(1.5 / 24, function(bold) {
						sillyStroke.width = 0;
						sillyStroke.height = 0;
					});
				});
			});
		});

		outroActions.push(function() {
			cardGlow.visible = true;
			cardGlow.alpha = 1;
			cardGlow.scale.set(1, 1);
			FlxTween.tween(cardGlow, {alpha: 0}, 0.25, {ease: FlxEase.sineOut});
			FlxTween.tween(cardGlow.scale, {x: 1.2, y: 1.2}, 0.25, {ease: FlxEase.sineOut});
		});

		rankVignette = new FlxSprite(Paths.image("ui/freeplay/rankVignette"));
		rankVignette.scale.set(2, 2);
		rankVignette.updateHitbox();
		rankVignette.blend = ADD;
		add(rankVignette);
		rankVignette.alpha = 0;

		findCategories();

		weekOrder = Paths.text("weekOrder").replace("\r","").split("\n");

		FreeplaySandbox.reloadLists();

		nav = new UINumeralNavigation(null, changeCategory, function() {
			var capsule:FreeplayCapsule = currentCapsule();

			if (capsule.songId == "!random")
			{
				curCategory = FlxG.random.int(1, countCapsules() - 1);
				changeCategory();
			}
			else if (Paths.hscriptExists("data/states/" + capsule.songId + "-freeplay"))
			{
				dj.stopTv();
				FlxG.switchState(new HscriptState("data/states/" + capsule.songId + "-freeplay"));
			}
			else
			{
				category = capsule.songId;
				menuState = 1;
				curSong = 1;
				reloadMenuStuff();
			}
		}, function() { doOutro(); }, changeCategory);
		nav.leftClick = nav.accept;
		nav.rightClick = nav.back;
		add(nav);

		nav2 = new UINumeralNavigation(changeDifficulty, changeSelection, function() {
			var capsule:FreeplayCapsule = currentCapsule();

			if ((capsule.songId != "" || (capsule.songInfo.hscript != null && capsule.songInfo.hscript != "")) && capsule.songUnlocked)
			{
				FlxG.sound.play(Paths.sound("ui/confirmMenu"));
				if (capsule.songId == "!random")
				{
					curSong = FlxG.random.int(1, countCapsules() - 1);
					changeSelection();
				}
				else
				{
					nav2.locked = true;

					if (capsule.songId == "")
					{
						new FlxTimer().start(0.75, function(tmr:FlxTimer)
						{
							FlxG.sound.music.fadeOut(0.5, 0, function(twn:FlxTween) { FlxG.sound.music.stop(); });
							HscriptState.script = "data/states/" + capsule.songInfo.hscript;
							FlxG.switchState(new HscriptState());
						});
					}
					else
					{
						confirmAnim();
						Util.gotoSong(capsule.songId, difficulty, capsule.songInfo.difficulties);
					}
				}
			}
		}, function() {
			menuState = 0;
			reloadMenuStuff();
		}, changeSelection);
		nav2.uiSounds = [false, false, true];
		add(nav2);

		if (categoriesList.length <= 1 || !navSwitch)
		{
			menuState = 1;
			category = categoriesList[0];
			remove(nav);
			nav2.back = nav.back;
		}
		nav2.leftClick = nav2.accept;
		nav2.rightClick = nav2.back;

		reloadMenuStuff();

		if (shouldDoIntro)
			doIntro();

		if (menuState > 0 && ResultsState.compareRanks.length >= 2 && ResultsState.compareRanks[1] > ResultsState.compareRanks[0])
			rankUpgrade(ResultsState.compareRanks[0], ResultsState.compareRanks[1]);
		ResultsState.compareRanks = [];
	}

	var introActions:Array<Void->Void> = [];
	function doIntro()
	{
		for (action in introActions)
			action();
	}

	var outroActions:Array<Void->Void> = [];
	function doOutro()
	{
		nav.locked = true;
		nav2.locked = true;
		new FlxTimer().start(0.5, function(tmr:FlxTimer) {
			FlxTween.globalManager.forEach(function(twn:FlxTween) { twn.cancel(); });
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) { tmr.cancel(); });
			close();
		});
		dj.stopTv();

		if (curTrack.name != Paths.music(Util.menuSong))
		{
			FlxG.sound.music.stop();
			Conductor.playMusic(Util.menuSong, 0.7);
		}

		for (action in outroActions)
			action();
	}

	function findCategories()
	{
		categories = new Map<String, Array<String>>();
		categoriesList = [];
		if (ModLoader.packagePath == "")
			categoriesList = ["!favorites"];
		categories["!favorites"] = [];
		var possibleCats:Array<String> = [];
		for (file in Paths.listFilesAndModsSub("data/weeks/", ".json"))
		{
			if (!possibleCats.contains(file[1]))
			{
				var rawData:String = Paths.rawFromMod("data/weeks/"+file[0]+".json", file[1]);
				var newWeek:WeekData = StoryMenuState.parseWeek(file[0], true, Json.parse(rawData));
				if (newWeek.condition != "storyonly" && !(newWeek.startsLocked && !FlxG.save.data.unlockedWeeks.contains(file[0]) && newWeek.hiddenWhenLocked))
					possibleCats.push(file[1]);
			}
		}

		for (file in Paths.listFilesAndModsSub("data/songs/", ".json"))
		{
			if (!possibleCats.contains(file[1]))
			{
				if (file[0].endsWith("/_auto"))
					possibleCats.push(file[1]);
			}
		}

		#if ALLOW_SM
		for (file in Paths.listFilesAndMods("sm/", ""))
		{
			if (!possibleCats.contains(file[1]))
				possibleCats.push(file[1]);
		}
		#end

		if (possibleCats.contains("") && !PackagesState.excludeBase)
		{
			categoriesList.push("");
			categories[""] = [];
		}

		for (c in ModLoader.modListLoaded)
		{
			if (possibleCats.contains(c) || Paths.hscriptExists("data/states/" + c + "-freeplay"))
			{
				categoriesList.push(c);
				categories[c] = [];
			}
		}
	}

	function buildCategory(cat:String)
	{
		if (categoriesList.contains(cat))
		{
			categories[cat] = [];

			for (file in Paths.listFilesFromModSub(cat, "data/weeks/", ".json"))
			{
				var rawData:String = Paths.rawFromMod("data/weeks/" + file + ".json", cat);
				var newWeek:WeekData = StoryMenuState.parseWeek(file, true, Json.parse(rawData));
				if (newWeek.condition != "storyonly" && !(newWeek.startsLocked && !FlxG.save.data.unlockedWeeks.contains(file) && newWeek.hiddenWhenLocked))
					categories[cat].push(file);
			}

			for (file in Paths.listFilesFromModSub(cat, "data/songs/", ".json"))
			{
				if (file.endsWith("/_auto"))
				{
					if (!categories[cat].contains("!AUTO"))
					{
						categories[cat].push("!AUTO");
						break;
					}
				}
			}

			#if ALLOW_SM
			if (Paths.listFilesAndMods("sm/", "").length > 0 && !categories[cat].contains("!SM"))
				categories[cat].push("!SM");
			#end
		}
	}

	function reloadMenuStuff()
	{
		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			capsule.kill();
		});

		switch (menuState)
		{
			case 0:
				nav.locked = false;
				nav2.locked = true;
				for (s in songStuff)
					s.visible = false;
				modIcon.visible = true;
				albumRoll.album = "";
				ostName.visible = false;

				var capsule:FreeplayCapsule = makeCapsule("!random", Lang.get("#freeplay.song.random"), "none", true);
				capsule.tracks[""] = randomTrack;
				capsule.updateFavorited(false);

				for (i in 0...categoriesList.length)
				{
					var categoryName:String = TitleState.defaultVariables.game;
					if (categoriesList[i] == "!favorites")
						categoryName = "Favorites";
					else if (categoriesList[i] != "")
						categoryName = ModLoader.getModMetaData(categoriesList[i]).title;

					var capsule:FreeplayCapsule = makeCapsule(categoriesList[i], categoryName, "none", true);
					capsule.updateFavorited(false);
				}

				var i:Int = 0;
				grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
					if (passesFilters(capsule))
					{
						if (capsule.songId == category)
							curCategory = i;
						i++;
					}
				});

				changeCategory();
				grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
					capsule.snapToPosition();
				});

			case 1:
				nav.locked = true;
				nav2.locked = false;
				for (s in songStuff)
					s.visible = true;
				modIcon.visible = false;

				if (!categories.exists(category))
				{
					menuState = 0;
					reloadMenuStuff();
					return;
				}
				ostName.visible = (category == "");

				var capsule:FreeplayCapsule = makeCapsule("!random", Lang.get("#freeplay.song.random"), "none", true);
				capsule.tracks[""] = randomTrack;
				capsule.updateFavorited(false);

				if (category == "!favorites")
				{
					var cats:Array<String> = [];
					var catMap:Map<String, Array<FavoriteSongData>> = new Map<String, Array<FavoriteSongData>>();
					for (song in Util.favoriteSongs)
					{
						if (!cats.contains(song.group))
						{
							cats.push(song.group);
							catMap[song.group] = [];
						}
						catMap[song.group].push(song);
					}

					for (cat in cats)
					{
						var song:WeekSongData = {songId: "", iconNew: TitleState.defaultVariables.noicon, difficulties: [""], characters: 3};
						var capsule:FreeplayCapsule = makeCapsule("", cat, "none", false, song);
						capsule.updateFavorited(false);

						for (song in catMap[cat])
						{
							var songName:String = (song.title == "" ? Song.getSongName(song.song.songId, song.song.difficulties[0]) : Lang.get(song.title));
							var capsule:FreeplayCapsule = makeCapsule(song.song.songId, songName, song.song.iconNew, true, song.song, song.artist, true);
							if (Paths.smExists(song.song.songId))
							{
								var thisSMFile:SMFile = SMFile.load(song.song.songId);
								capsule.songInfo.difficulties = thisSMFile.difficulties;
								capsule.tracks[""] = {name: Paths.smSong(song.song.songId, thisSMFile.ogg), timings: thisSMFile.bpmMap, start: thisSMFile.previewStart * 1000, end: (thisSMFile.previewStart + thisSMFile.previewLength) * 1000};
								capsule.quickInfo = thisSMFile.quickInfo;
							}
							else
							{
								for (d in song.song.difficulties)
								{
									capsule.tracks[d] = Song.getFreeplayTrackFromSong(song.song.songId, d);
									capsule.quickInfo[d] = Song.getSongQuickInfo(song.song.songId, d);
								}
							}
							capsule.updateFavorited();
						}
					}
				}
				else
				{
					if (categories[category].length <= 0)
						buildCategory(category);

					var weekNames:Array<String> = categories[category].copy();
					if (!songLists.exists(category))
						songLists[category] = [];
					ArraySort.sort(weekNames, sortWeeks);
					var hasAuto:Bool = false;
					if (weekNames.contains("!AUTO"))
					{
						hasAuto = true;
						weekNames.remove("!AUTO");
					}
					var hasSM:Bool = false;
					if (weekNames.contains("!SM"))
					{
						hasSM = true;
						weekNames.remove("!SM");
					}

					var spot:Int = 0;
					if (weekNames.length > 0)
					{
						for (i in 0...weekNames.length)
						{
							if (!weeks.exists(weekNames[i]))
							{
								var rawData:String = Paths.rawFromMod("data/weeks/"+weekNames[i]+".json", category);
								weeks[weekNames[i]] = StoryMenuState.parseWeek(weekNames[i], false, Json.parse(rawData));
							}
							var newWeek:WeekData = weeks[weekNames[i]];
							var weekLocked:Bool = (newWeek.startsLocked && !FlxG.save.data.unlockedWeeks.contains(weekNames[i]));
							if (newWeek.startsLockedInFreeplay && !ScoreSystems.weekBeaten(weekNames[i]))
								weekLocked = true;
							for (song in newWeek.songs)
							{
								if (song.difficulties == null || song.difficulties.length == 0)
									song.difficulties = newWeek.difficulties;

								if (song.title == null)
									song.title = "";
								if (spot >= songLists[category].length)
								{
									var songName:String = (song.title == "" ? Song.getSongName(song.songId, song.difficulties[0]) : Lang.get(song.title));
									if (weekLocked)
										songName = Lang.get("#freeplay.song.locked");
									songLists[category].push(songName);
								}

								var capsule:FreeplayCapsule = makeCapsule(song.songId, songLists[category][spot], song.iconNew, !(song.songId == "" && (song.hscript == null || song.hscript == "")), song, (song.songId == "" ? "" : "!get_artist"), !weekLocked);
								if (song.songId != "" && !weekLocked)
								{
									for (d in song.difficulties)
									{
										capsule.tracks[d] = Song.getFreeplayTrackFromSong(song.songId, d);
										capsule.quickInfo[d] = Song.getSongQuickInfo(song.songId, d);
									}
								}
								if (weekNames[i].indexOf("week") > -1)
								{
									var weekType:Int = 0;
									var ind:Int = weekNames[i].indexOf("week") + 4;
									var nums:Array<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
									if (weekNames[i].indexOf("weekend") > -1)
									{
										capsule.weekType = -1;
										ind += 3;
									}
									else
										capsule.weekType = 1;

									if (nums.contains(weekNames[i].charAt(ind)) && ind < weekNames[i].length)
									{
										while (nums.contains(weekNames[i].charAt(ind)) && ind < weekNames[i].length)
										{
											weekType *= 10;
											weekType += Std.parseInt(weekNames[i].charAt(ind));
											ind++;
										}
										capsule.weekType *= weekType;
									}
									else
										capsule.weekType = 0;
								}
								capsule.updateFavorited();
								spot++;
							}
						}
					}

					if (hasAuto)
					{
						var autoFiles:Array<String> = Paths.listFilesFromModSub(category, "data/songs/", ".json");

						for (f in autoFiles)
						{
							if (f.endsWith("/_auto"))
							{
								var song:WeekSongData = cast Paths.json("songs/" + f);
								song.songId = f.substr(0, f.lastIndexOf("/"));
								if (song.difficulties == null || song.difficulties.length == 0)
									song.difficulties = ["normal", "hard", "easy"];
								if (song.characters == null)
									song.characters = 3;
								if (song.characterLabels == null || song.characterLabels.length < 3)
									song.characterLabels = ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"];

								var capsule:FreeplayCapsule = makeCapsule(song.songId, Song.getSongName(song.songId, song.difficulties[0]), (song.iconNew == null ? "none" : song.iconNew), true, song, "!get_artist", true);
								if (song.songId != "")
								{
									for (d in song.difficulties)
									{
										capsule.tracks[d] = Song.getFreeplayTrackFromSong(song.songId, d);
										capsule.quickInfo[d] = Song.getSongQuickInfo(song.songId, d);
									}
								}
								capsule.updateFavorited();
							}
						}
					}

					if (hasSM)
					{
						var smFolders:Array<String> = Paths.listFilesFromMod(category,"sm/","");

						for (fl in smFolders)
						{
							var song:WeekSongData = {songId: "", iconNew: TitleState.defaultVariables.noicon, difficulties: [""], characters: 3};

							var capsule:FreeplayCapsule = makeCapsule("", fl, "none", false, song);
							capsule.updateFavorited(false);

							var smFiles:Array<String> = Paths.listFilesFromMod(category, "sm/" + fl + "/", "");
							for (f in smFiles)
							{
								var thisSM:String = Paths.listFilesFromMod(category, "sm/" + fl + "/" + f, ".sm")[0];
								var thisSMFile:SMFile = SMFile.load(fl + "/" + f + "/" + thisSM);

								if (Assets.exists(Paths.smSong(fl + "/" + f + "/" + thisSM, thisSMFile.ogg)))
								{
									song = {songId: fl + "/" + f + "/" + thisSM, icon: TitleState.defaultVariables.noicon, difficulties: thisSMFile.difficulties, characters: 3};
									var capsule:FreeplayCapsule = makeCapsule(song.songId, thisSMFile.title, "none", true, song, thisSMFile.artist);
									capsule.tracks[""] = {name: Paths.smSong(song.songId, thisSMFile.ogg), timings: thisSMFile.bpmMap, start: thisSMFile.previewStart * 1000, end: (thisSMFile.previewStart + thisSMFile.previewLength) * 1000};
									capsule.quickInfo = thisSMFile.quickInfo;
									capsule.updateFavorited();
								}
							}
						}
					}
				}

				if (curSong == 0)
				{
					var i:Int = 0;
					grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
						if (passesFilters(capsule))
						{
							if (selectedId.startsWith("script!"))
							{
								if (capsule.songInfo != null && capsule.songInfo.hscript == selectedId.substr(7))
									curSong = i;
							}
							else if (capsule.songId == selectedId)
								curSong = i;
							i++;
						}
					});
				}

				changeSelection();
				grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
					capsule.snapToPosition();
				});
		}
	}

	function switchTrack(newTrack:FreeplayTrack, ?forced:Bool = false)
	{
		if (curTrack.name != newTrack.name || forced)
		{
			curTrack = newTrack;
			FlxG.sound.music.stop();
			FlxG.sound.playMusic(curTrack.name, 0);
			FlxG.sound.music.fadeIn(0.5, 0, 0.7);

			if (curTrack.end > curTrack.start)
			{
				FlxG.sound.music.time = curTrack.start;
				FlxG.sound.music.loopTime = curTrack.start;
				FlxG.sound.music.endTime = curTrack.end;
				Conductor.songPosition = FlxG.sound.music.time;
			}
			else
			{
				FlxG.sound.music.loopTime = 0;
				FlxG.sound.music.endTime = null;
				Conductor.songPosition = 0;
			}
			Conductor.overrideSongPosition = false;
			Conductor.recalculateTimings(curTrack.timings);
		}
	}

	function switchToDefaultTrack(?forced:Bool = false)
	{
		if (curTrack.name != defaultTrack.name || forced)
		{
			curTrack = defaultTrack;
			FlxG.sound.music.stop();
			Util.menuMusic();
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.fadeIn(0.5, 0, 0.7);
		}
	}

	function makeCapsule(songId:String, text:String, icon:String, lit:Bool, ?songInfo:WeekSongData = null, ?songArtist:String = "", ?songUnlocked:Bool = true):FreeplayCapsule
	{
		var capsule:FreeplayCapsule = grpCapsules.recycle(FreeplayCapsule);
		capsule.songId = songId;
		capsule.songInfo = songInfo;
		capsule.songUnlocked = songUnlocked;
		capsule.songArtist = songArtist;
		capsule.songAlbums.clear();
		if (songInfo != null && songInfo.albums != null)
		{
			for (album in songInfo.albums)
				capsule.songAlbums[album[0]] = album[1];
		}
		capsule.tracks.clear();
		capsule.quickInfo.clear();
		capsule.curQuickInfo = null;
		capsule.weekType = 0;
		capsule.icon = icon;
		capsule.text = text;
		capsule.filter = text;
		capsule.lit = lit;
		capsule.rank = -1;
		grpCapsules.add(capsule);
		return capsule;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!(nav.locked && nav2.locked))
		{
			if (menuState > 0)
			{
				if (Options.keyJustPressed("favoriteSong"))
				{
					var capsule:FreeplayCapsule = currentCapsule();
					if (capsule.songId != "" && capsule.songId != "!random")
					{
						var categoryName:String = TitleState.defaultVariables.game;
						if (category != "" && category != "!favorites")
							categoryName = ModLoader.getModMetaData(category).title;
						if (category == "!favorites")
							Util.favoriteSong(capsule.songInfo, capsule.filter, capsule.songArtist, capsule.text.split("(")[1].split(")")[0]);
						else
							Util.favoriteSong(capsule.songInfo, capsule.text, capsule.songArtist, categoryName);

						capsule.updateFavorited(true, true);
						nav2.locked = true;
						capsule.anim = "fav";
						if (capsule.favorited)
						{
							FlxTween.tween(capsule, {y: capsule.y - 5}, 0.1, {ease: FlxEase.expoOut});
							FlxTween.tween(capsule, {y: capsule.y + 5}, 0.1, {
								ease: FlxEase.expoIn,
								startDelay: 0.1,
								onComplete: function(twn:FlxTween) {
									capsule.anim = "";
									nav2.locked = false;
								}
							});
						}
						else
						{
							FlxTween.tween(capsule, {y: capsule.y + 5}, 0.1, {ease: FlxEase.expoOut});
							FlxTween.tween(capsule, {y: capsule.y - 5}, 0.1, {
								ease: FlxEase.expoIn,
								startDelay: 0.1,
								onComplete: function(twn:FlxTween) {
									capsule.anim = "";
									nav2.locked = false;
								}
							}); 
						}
					}
				}

				if (Options.keyJustPressed("ui_reset"))
				{
					var capsule:FreeplayCapsule = currentCapsule();
					if (capsule.songId != "" && capsule.songId != "!random")
					{
						persistentUpdate = false;
						openSubState(new FreeplayMenuResetSubState(capsule.songId, difficulty, FreeplaySandbox.chartSide, reload));
					}
				}

				if (Options.keyJustPressed("sandbox"))
				{
					var capsule:FreeplayCapsule = currentCapsule();
					if (capsule.songId != "" && capsule.songId != "!random")
					{
						nav2.locked = true;
						letterSort.locked = true;
						add(new FreeplaySandbox(this, reload, function() { nav2.locked = false; letterSort.locked = false; }));
					}
				}
			}
		}
	}

	override public function beatHit()
	{
		super.beatHit();
		if (Conductor.bpm <= 220 || curBeat % 2 == 0)
			dj.beatHit();
	}

	function confirmAnim()
	{
		dj.stopTv();
		dj.playAnim("Boyfriend DJ confirm");
		dj.state = 1;

		var capsule:FreeplayCapsule = currentCapsule();
		capsule.confirmAnim();

		FlxTween.color(pinkBack, 0.33, 0xFFFFD0D5, 0xFF171831, {ease: FlxEase.quadOut});
		orangeBackShit.visible = false;
		alsoOrangeLOL.visible = false;
		grpTxtScrolls.forEachAlive(function(txt:FreeplayScrollingText) { txt.visible = false; });

		confirmGlow.alpha = 0;
		confirmGlow.visible = true;
		confirmGlow2.alpha = 0;
		confirmGlow2.visible = true;

		backingTextYeah.visible = true;
		backingTextYeah.playAnim("BF back card confirm raw", true, false);

		FlxTween.tween(confirmGlow2, {alpha: 0.5}, 0.33, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween) {
				confirmGlow2.alpha = 0.6;
				confirmGlow.alpha = 1;
				confirmTextGlow.visible = true;
				confirmTextGlow.alpha = 1;
				FlxTween.tween(confirmTextGlow, {alpha: 0.4}, 0.5);
				FlxTween.tween(confirmGlow, {alpha: 0}, 0.5);
			}
		});
	}

	function getScore()
	{
		var capsule:FreeplayCapsule = currentCapsule();
		if (capsule.songId == "" || capsule.songId == "!random")
		{
			fp.score = 0;
			fpClear.percentage = 0;
		}
		else
		{
			var scoreData:ScoreData = ScoreSystems.loadSongScoreData(capsule.songId, difficulty, FreeplaySandbox.chartSide);
			fp.score = scoreData.score;
			fpClear.percentage = scoreData.clear * 100;
		}
	}

	function passesFilters(capsule:FreeplayCapsule):Bool
	{
		if (filters.length <= 0)
			return true;

		if (capsule.songId == "!random")
			return true;

		if (menuState > 0 && capsule.songId == "")
		{
			if (capsule.songInfo == null)
				return true;

			if (capsule.songInfo.hscript == null || capsule.songInfo.hscript == "")
				return true;
		}

		for (f in filters)
		{
			if (capsule.filter.toLowerCase().startsWith(f.toLowerCase()))
				return true;
		}

		return false;
	}

	function countCapsules():Int
	{
		var ret:Int = 0;
		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			if (passesFilters(capsule))
				ret++;
		});

		return ret;
	}

	function changeCategory(change:Int = 0)
	{
		dj.idleTimer = 0;
		curCategory = Util.loop(curCategory + change, 0, countCapsules() - 1);

		var i:Int = -curCategory;
		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			if (passesFilters(capsule))
			{
				i++;
				capsule.visible = true;
				capsule.index = i;
			}
			else
			{
				capsule.visible = false;
				capsule.index = -1;
			}
		});

		diffStars.difficulty = -1;
		var capsule:FreeplayCapsule = currentCapsule();
		category = capsule.songId;

		var categoryIcon = null;
		if (category != "" && category != "!random" && category != "!favorites")
			categoryIcon = ModLoader.getModMetaData(category).icon;

		if (categoryIcon == null)
			modIcon.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		else
		{
			modIcon.pixels = BitmapData.fromImage( Image.fromBytes(categoryIcon) );
			modIcon.scale.set(1, 1);
			if (modIcon.width > 260 || modIcon.height > 260)
				modIcon.setGraphicSize(260);
			modIcon.updateHitbox();
			modIcon.setPosition(1082, 413);
			modIcon.x -= modIcon.width / 2;
			modIcon.y -= modIcon.height / 2;
		}

		if (capsule.tracks.exists(""))
			switchTrack(capsule.tracks[""]);
		else
			switchToDefaultTrack();
	}

	function changeSelection(change:Int = 0)
	{
		dj.idleTimer = 0;
		curSong = Util.loop(curSong + change, 0, countCapsules() - 1);

		var i:Int = -curSong;
		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			if (passesFilters(capsule))
			{
				i++;
				capsule.visible = true;
				capsule.index = i;
			}
			else
			{
				capsule.visible = false;
				capsule.index = -1;
			}
		});

		var capsule:FreeplayCapsule = currentCapsule();
		if (!capsule.lit)
		{
			if (change == 0)
				changeSelection(1);
			else
				changeSelection(change);
			return;
		}

		FlxG.sound.play(Paths.sound("ui/scrollMenu"));

		selectedId = capsule.songId;
		if (selectedId == "")
			selectedId = "script!" + capsule.songInfo.hscript;

		if (capsule.songId == "" || capsule.songId == "!random")
		{
			difficultySprite.visible = false;
			difficultyText.visible = false;
			diffSelLeft.visible = false;
			diffSelRight.visible = false;
		}
		else
		{
			difficultySprite.visible = true;
			difficultyText.visible = true;
			if (capsule.songInfo.difficulties.length > 1)
			{
				diffSelLeft.visible = true;
				diffSelRight.visible = true;
			}
			else
			{
				diffSelLeft.visible = false;
				diffSelRight.visible = false;
			}

			if (!capsule.songInfo.difficulties.contains(difficulty))
			{
				difficulty = capsule.songInfo.difficulties[0];
				onChangeDifficulty();
			}

			FreeplaySandbox.setCharacterCount(capsule.songInfo.characters, capsule.songInfo.characterLabels);
		}

		if (!capsule.songAlbums.exists(""))
			albumRoll.album = "";
		else
		{
			if (capsule.songAlbums.exists(difficulty))
				albumRoll.album = capsule.songAlbums[difficulty];
			else
				albumRoll.album = capsule.songAlbums[""];
		}

		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			if (passesFilters(capsule))
			{
				if (capsule.quickInfo.exists(difficulty))
					capsule.curQuickInfo = capsule.quickInfo[difficulty];
				else
					capsule.curQuickInfo = null;
			}
		});

		if (capsule.tracks.exists(difficulty))
			switchTrack(capsule.tracks[difficulty]);
		else if (capsule.tracks.exists(""))
			switchTrack(capsule.tracks[""]);
		else
			switchToDefaultTrack();

		reload();
	}

	function changeDifficulty(change:Int = 0)
	{
		var capsule:FreeplayCapsule = currentCapsule();
		if (capsule.songId == "" || capsule.songId == "!random") return;

		var diff:String = difficulty;
		var difficultyIndex:Int = capsule.songInfo.difficulties.indexOf(difficulty);

		difficultyIndex = Util.loop(difficultyIndex + change, 0, capsule.songInfo.difficulties.length - 1);
		difficulty = capsule.songInfo.difficulties[difficultyIndex];
		if (diff != difficulty)
		{
			dj.idleTimer = 0;
			FlxG.sound.play(Paths.sound("ui/scrollMenu"));
			onChangeDifficulty();
		}

		if (change < 0)
		{
			diffSelLeft.offset.y -= 5;
			diffSelLeft.scale.set(0.5, 0.5);

			new FlxTimer().start(1 / 12, function(tmr) {
				diffSelLeft.scale.set(1, 1);
				diffSelLeft.updateHitbox();
			});
		}

		if (change > 0)
		{
			diffSelRight.offset.y -= 5;
			diffSelRight.scale.set(0.5, 0.5);

			new FlxTimer().start(1 / 12, function(tmr) {
				diffSelRight.scale.set(1, 1);
				diffSelRight.updateHitbox();
			});
		}

		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			if (passesFilters(capsule))
			{
				if (capsule.quickInfo.exists(difficulty))
					capsule.curQuickInfo = capsule.quickInfo[difficulty];
				else
					capsule.curQuickInfo = null;
			}
		});

		var capsule:FreeplayCapsule = currentCapsule();
		if (!capsule.songAlbums.exists(""))
			albumRoll.album = "";
		else
		{
			if (capsule.songAlbums.exists(difficulty))
				albumRoll.album = capsule.songAlbums[difficulty];
			else
				albumRoll.album = capsule.songAlbums[""];
		}

		if (capsule.tracks.exists(difficulty))
			switchTrack(capsule.tracks[difficulty]);
		else if (capsule.tracks.exists(""))
			switchTrack(capsule.tracks[""]);
		else
			switchToDefaultTrack();

		reload();
	}

	function onChangeDifficulty()
	{
		var showSprite:Bool = true;

		if (Paths.sparrowExists("ui/freeplay/difficulties/" + difficulty))
		{
			difficultySprite.frames = Paths.sparrow("ui/freeplay/difficulties/" + difficulty);
			difficultySprite.animation.addByPrefix("idle", "", 24, true);
			difficultySprite.animation.play("idle");
		}
		else if (Paths.imageExists("ui/freeplay/difficulties/" + difficulty))
			difficultySprite.loadGraphic(Paths.image("ui/freeplay/difficulties/" + difficulty));
		else if (Paths.sparrowExists("ui/difficulties/" + difficulty))
		{
			difficultySprite.frames = Paths.sparrow("ui/difficulties/" + difficulty);
			difficultySprite.animation.addByPrefix("idle", "", 24, true);
			difficultySprite.animation.play("idle");
		}
		else if (Paths.imageExists("ui/difficulties/" + difficulty))
			difficultySprite.loadGraphic(Paths.image("ui/difficulties/" + difficulty));
		else
		{
			showSprite = false;
			difficultyText.text = difficulty.toUpperCase();
			difficultyText.updateHitbox();
			difficultyText.setGraphicSize(230);
			difficultyText.updateHitbox();
		}

		if (showSprite)
		{
			difficultyText.alpha = 0;
			difficultySprite.offset.y += 5;
			difficultySprite.alpha = 0.5;
			new FlxTimer().start(1 / 24, function(tmr) {
				difficultySprite.alpha = 1;
				difficultySprite.updateHitbox();
			});
		}
		else
		{
			difficultySprite.alpha = 0;
			difficultyText.offset.y += 5;
			difficultyText.alpha = 0.5;
			new FlxTimer().start(1 / 24, function(tmr) {
				difficultyText.alpha = 1;
				difficultyText.updateHitbox();
			});
		}
	}

	function updateCapsuleInfo()
	{
		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			capsule.chartSide = FreeplaySandbox.chartSide;
			if (capsule.songInfo != null && capsule.songInfo.difficulties.contains(difficulty))
				capsule.rank = ScoreSystems.loadSongScoreData(capsule.songId, difficulty, FreeplaySandbox.chartSide).rank;
			else
				capsule.rank = -1;
		});

		var capsule:FreeplayCapsule = currentCapsule();
		if (capsule.difficultyNum.value == "")
			diffStars.difficulty = -1;
		else
			diffStars.difficulty = Std.parseInt(capsule.difficultyNum.value);
	}

	function reload()
	{
		getScore();
		reloadChartInfo();
		updateCapsuleInfo();
	}

	function reloadChartInfo()
	{
		var capsule:FreeplayCapsule = currentCapsule();
		if (capsule.songId == "" || capsule.songId == "!random")
			chartInfo.reload("", difficulty, FreeplaySandbox.chartSide, "");
		else
		{
			if (Paths.smExists(capsule.songId))
			{
				var smFile:SMFile = SMFile.load(capsule.songId, false);
				var divChart:SongData = smFile.songData[smFile.difficulties.indexOf(difficulty)];
				divChart = Song.correctDivisions(divChart);

				FreeplaySandbox.sideList = divChart.columnDivisionNames.copy();
			}
			else
				FreeplaySandbox.sideList = Song.getSongSideList(capsule.songId, difficulty);

			if (FreeplaySandbox.chartSide >= FreeplaySandbox.sideList.length)
				FreeplaySandbox.chartSide = 0;

			var songArtist:String = capsule.songArtist;
			if (songArtist == "!get_artist")
				songArtist = Song.getSongArtist(capsule.songId, difficulty);
			chartInfo.reload(capsule.songId, difficulty, FreeplaySandbox.chartSide, songArtist);
		}
	}

	var sparks:AnimatedSprite;
	var sparksADD:AnimatedSprite;

	function rankUpgrade(oldRank:Int, newRank:Int)
	{
		FlxG.sound.music.stop();
		nav2.locked = true;
		var capsule:FreeplayCapsule = currentCapsule();
		capsule.rank = oldRank;
		capsule.anim = "rankUpgrade";

		dj.state = 4;
		rankCamera.fade(FlxColor.BLACK, 0.5, true, null, true);
		rankBg.alpha = 1;

		if (oldRank > -1)
		{
			sparks = new AnimatedSprite(517, 134, Paths.sparrow("ui/freeplay/capsule/sparks"));
			sparks.addAnim('sparks', 'sparks', 24, false);
			sparks.visible = false;
			sparks.blend = ADD;
			sparks.scale.set(0.5, 0.5);
			add(sparks);
			sparks.cameras = [rankCamera];

			sparksADD = new AnimatedSprite(498, 116, Paths.sparrow("ui/freeplay/capsule/sparksadd"));
			sparksADD.addAnim('sparks add', 'sparks add', 24, false);
			sparksADD.visible = false;
			sparksADD.blend = ADD;
			sparksADD.scale.set(0.5, 0.5);
			add(sparksADD);
			sparksADD.cameras = [rankCamera];

			switch (oldRank)
			{
				case 0: sparksADD.color = 0xFF6044FF;
				case 1: sparksADD.color = 0xFFEF8764;
				case 2: sparksADD.color = 0xFFEAF6FF;
				case 3: sparksADD.color = 0xFFFDCB42;
				case 4: sparksADD.color = 0xFFFF58B4;
				case 5: sparksADD.color = 0xFFFFB619;
			}
		}

		rankCamera.zoom = 1.85;
		FlxTween.tween(rankCamera, {zoom: 1.8}, 0.6, {ease: FlxEase.sineIn});

		camera.zoom = 1.15;
		FlxTween.tween(camera, {zoom: 1.1}, 0.6, {ease: FlxEase.sineIn});

		capsule.cameras = [rankCamera];
		capsule.setPosition((FlxG.width - capsule.capsule.width) / 2, (FlxG.height - capsule.capsule.height) / 2);

		new FlxTimer().start(0.5, function(tmr:FlxTimer) { rankDisplayNew(oldRank, newRank); });
	}

	function rankDisplayNew(oldRank:Int, newRank:Int)
	{
		var capsule:FreeplayCapsule = currentCapsule();
		capsule.rank = newRank;

		capsule.ranking.scale.set(20, 20);
		FlxTween.tween(capsule.ranking.scale, {x: 1, y: 1}, 0.1);
		capsule.blurredRanking.scale.set(20, 20);
		FlxTween.tween(capsule.blurredRanking.scale, {x: 1, y: 1}, 0.1);

		new FlxTimer().start(0.1, function(tmr:FlxTimer) {
			if (oldRank > -1)
			{
				sparks.visible = true;
				sparks.playAnim('sparks', true);
				sparksADD.visible = true;
				sparksADD.playAnim('sparks add', true);

				sparks.animation.finishCallback = function(anim:String) {
					sparks.visible = false;
					sparksADD.visible = false;
				}
			}

			switch (newRank)
			{
				case 0: FlxG.sound.play(Paths.sound("ui/ranks/rankinbad"));
				case 4: FlxG.sound.play(Paths.sound("ui/ranks/rankinperfect"));
				case 5: FlxG.sound.play(Paths.sound("ui/ranks/rankinperfect"));
				default: FlxG.sound.play(Paths.sound("ui/ranks/rankinnormal"));
			}

			rankCamera.zoom = 1.3;
			FlxTween.tween(rankCamera, {zoom: 1.5}, 0.3, {ease: FlxEase.backInOut});
			FlxTween.tween(camera, {zoom: 1.05}, 0.3, {ease: FlxEase.elasticOut});

			capsule.x -= 10;
			capsule.y -= 20;

			capsule.capsule.angle = -3;
			FlxTween.tween(capsule.capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});

			IntervalShake.shake(capsule.capsule, 0.3, 1 / 30, 0.1, 0, FlxEase.quadOut);
		});

		new FlxTimer().start(0.4, function(tmr:FlxTimer) {
			FlxTween.tween(rankCamera, {zoom: 1.2}, 0.8, {ease: FlxEase.backIn});
			FlxTween.tween(camera, {zoom: 1}, 0.8, {ease: FlxEase.sineIn});
			FlxTween.tween(capsule, {x: 320.488 - 7, y: 235.6 - 80}, 1.3, {ease: FlxEase.quartIn});
		});

		new FlxTimer().start(0.6, function(tmr:FlxTimer) { rankAnimSlam(oldRank, newRank); });
	}

	function rankAnimSlam(oldRank:Int, newRank:Int)
	{
		FlxTween.tween(rankBg, {alpha: 0}, 0.5, {ease: FlxEase.expoIn});

		switch (newRank)
		{
			case 0: FlxG.sound.play(Paths.sound("ui/ranks/loss"));
			case 1: FlxG.sound.play(Paths.sound("ui/ranks/good"));
			case 2: FlxG.sound.play(Paths.sound("ui/ranks/great"));
			case 3: FlxG.sound.play(Paths.sound("ui/ranks/excellent"));
			case 4: FlxG.sound.play(Paths.sound("ui/ranks/perfect"));
			case 5: FlxG.sound.play(Paths.sound("ui/ranks/perfect"));
			default: FlxG.sound.play(Paths.sound("ui/ranks/loss"));
		}

		new FlxTimer().start(0.5, function(tmr:FlxTimer) {
			camera.shake(0.0045, 0.35);

			dj.state = 0;
			if (newRank == 0)
				dj.playAnim("Boyfriend DJ loss reaction 1", true, false);
			else
				dj.playAnim("Boyfriend DJ fist pump", true, false);
			dj.anim.curFrame = 4;

			camera.zoom = 0.8;
			FlxTween.tween(camera, {zoom: 1}, 0.8, {ease: FlxEase.elasticOut});
			rankCamera.zoom = 0.8;
			FlxTween.tween(rankCamera, {zoom: 1}, 1, {ease: FlxEase.elasticOut});

			grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
				var distFromSelected:Float = Math.abs(capsule.index - 1) - 1;

				if (distFromSelected < 5)
				{
					if (capsule.index == 1)
					{
						FlxTween.cancelTweensOf(capsule);
						capsule.fadeAnim();

						rankVignette.color = capsule.evilTrail.color;
						rankVignette.alpha = 1;
						FlxTween.tween(rankVignette, {alpha: 0}, 0.6, {ease: FlxEase.expoOut});

						capsule.setPosition(320.488, 235.6);
						IntervalShake.shake(capsule, 0.6, 1 / 24, 0.12, 0, FlxEase.quadOut, function(_) {
							capsule.anim = "";
							capsule.cameras = [camera];

							nav2.locked = false;

							if (capsule.tracks.exists(difficulty))
								switchTrack(capsule.tracks[difficulty], true);
							else if (capsule.tracks.exists(""))
								switchTrack(capsule.tracks[""], true);
							else
								switchToDefaultTrack(true);
						}, null);
					}
					else
					{
						new FlxTimer().start(distFromSelected / 20, function(tmr:FlxTimer) {
							capsule.anim = "shake";

							capsule.capsule.angle = FlxG.random.float(-10 + (distFromSelected * 2), 10 - (distFromSelected * 2));
							FlxTween.tween(capsule.capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});

							IntervalShake.shake(capsule, 0.6, 1 / 24, 0.12 / (distFromSelected + 1), 0, FlxEase.quadOut, function(_) { capsule.anim = ""; });
						});
					}
				}
			});
		});
	}

	function currentCapsule():FreeplayCapsule
	{
		var ret:FreeplayCapsule = null;
		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			if (capsule.index == 1)
				ret = capsule;
		});

		return ret;
	}
}