package menus.freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxRuntimeShader;
import flxanimate.FlxAnimate;
import haxe.Json;
import haxe.ds.ArraySort;
import lime.graphics.Image;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import openfl.filters.ShaderFilter;
import data.ObjectData;
import data.Options;
import data.PlayableCharacter;
import data.ScoreSystems;
import data.SMFile;
import data.Song;
import helpers.IntervalShake;
import objects.AnimatedSprite;
import game.PlayState;
import game.results.ResultsState;
import menus.story.StoryMenuState;
import menus.freeplay.FreeplayDJ;
import menus.characterSelect.CharacterSelectState;
import menus.UINavigation;
import scripting.HscriptHandler;
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
	static var fromCharacterSelect:Bool = false;
	var categories:Map<String, Array<String>> = new Map<String, Array<String>>();
	static var categoriesList:Array<String> = [];
	static var category:String = "";
	var curCategory:Int = 0;
	var filters:Array<String> = [];

	var style:PlayableCharacterFreeplayStyle;

	var weeks:Map<String, WeekData> = new Map<String, WeekData>();
	var songLists:Map<String, Array<Array<String>>> = new Map<String, Array<Array<String>>>();
	static var selectedId:String = "";
	var curSong:Int = 0;

	public static var difficulty:String = "normal";

	var blueFade:FlxRuntimeShader;
	var blueFadeFilter:ShaderFilter;

	var pinkBack:FlxSprite;

	var cardGlow:FlxSprite;
	var dj:FreeplayDJ;
	var djScript:HscriptHandler = null;
	var bgDad:FlxSprite;
	var bgDadShader:FlxRuntimeShader;
	var ostName:FlxText;
	var grpCapsules:FlxTypedSpriteGroup<FreeplayCapsule>;
	var charSelectHint:FlxText;
	var hintTimer:Float = 0;

	var difficultySprite:FlxSprite;
	var difficultyText:FlxText;
	var difficultySpriteTimer:FlxTimer = new FlxTimer();
	var diffSelLeft:AnimatedSprite;
	var diffSelRight:AnimatedSprite;
	var difficultyDots:FlxTypedSpriteGroup<FreeplayDifficultyDot>;

	var rankCamera:FlxCamera;
	var rankBg:FlxSprite;
	var rankVignette:FlxSprite;

	var curTrack:FreeplayTrack = null;
	var defaultTrack:FreeplayTrack = null;
	var randomTrack:FreeplayTrack = null;

	var modIcon:FlxSprite;
	var albumRoll:FreeplayAlbum;
	var diffStars:FreeplayDifficultyStars;

	var fpScore:FreeplayScore;
	var fpClear:FreeplayClear;

	var letterSort:FreeplayFilters;

	var chartInfo:FreeplayChartInfo;

	var newCharacter:Bool = false;

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

		for (c in Paths.listFilesSub("data/players/", ".json"))
		{
			var char:PlayableCharacter = cast Paths.json("players/" + c);
			if (!FlxG.save.data.unlockedCharacters.contains(c))
			{
				if (char.unlockCondition == null)
					FlxG.save.data.unlockedCharacters.push(c);
				else
				{
					switch (char.unlockCondition.type)
					{
						case "song":
							if (ScoreSystems.songBeaten(char.unlockCondition.id, char.unlockCondition.difficulties))
								FlxG.save.data.unlockedCharacters.push(c);

						case "week":
							if (ScoreSystems.weekBeaten(char.unlockCondition.id, char.unlockCondition.difficulties))
								FlxG.save.data.unlockedCharacters.push(c);
					}
				}
			}
		}

		var unlockedCharacters:Array<String> = FlxG.save.data.unlockedCharacters;
		var unlockedCharactersSeen:Array<String> = FlxG.save.data.unlockedCharactersSeen;
		for (c in unlockedCharacters)
		{
			if (!unlockedCharactersSeen.contains(c))
				newCharacter = true;
		}

		if (newCharacter)
			CharacterSelectState.player = "bf";

		style = cast Paths.json("players/" + CharacterSelectState.player).freeplayStyle;

		defaultTrack = {name: Paths.music(Util.menuSong), timings: [[0, Std.parseFloat(Paths.raw("music/" + Util.menuSong + ".bpm"))]], start: -1, end: -1};
		randomTrack = {name: Paths.music("freeplayRandom"), timings: [[0, Std.parseFloat(Paths.raw("music/freeplayRandom.bpm"))]], start: -1, end: -1};
		curTrack = defaultTrack;

		blueFade = new FlxRuntimeShader(Paths.shader("BlueFade"));
		blueFade.setFloat("fadeAmt", 1.0);
		blueFadeFilter = new ShaderFilter(blueFade);

		camera = new FlxCamera();
		camera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camera, false);

		rankCamera = new FlxCamera();
		rankCamera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(rankCamera, false);

		pinkBack = new FlxSprite(Paths.image("ui/freeplay/pinkBack"));
		add(pinkBack);
		introActions.push(function() {
			pinkBack.x -= pinkBack.width;
			pinkBack.color = 0xFFFFD4E9;
			FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
		});

		outroActions.push(function() {
			pinkBack.color = 0xFFFFD4E9;
			FlxTween.tween(pinkBack, {x: -pinkBack.width}, 0.4, {ease: FlxEase.expoIn});
		});
		createCharacterSelectTransition([pinkBack], -100, 0.8);

		cardGlow = new FlxSprite(-30, -30, Paths.image("ui/freeplay/cardGlow"));
		cardGlow.blend = ADD;
		cardGlow.visible = false;
		add(cardGlow);

		dj = new FreeplayDJ(640, 366);
		if (newCharacter)
			dj.state = FreeplayDJState.NEW_CHARACTER;
		add(dj);
		introActions.push(function() {
			dj.playAnim("intro");
		});
		outroActions.push(function() {
			FlxTween.tween(dj, {x: -640}, 0.5, {ease: FlxEase.expoIn});
		});
		createCharacterSelectTransition([dj], -175, 0.8);

		difficultySprite = new FlxSprite(200, 117, Paths.image("ui/freeplay/difficulties/normal"));
		difficultySprite.setPosition(200 - Math.round(difficultySprite.width / 2), 117 - Math.round(difficultySprite.height / 2));
		add(difficultySprite);
		songStuff.push(difficultySprite);

		difficultyText = new FlxText(85, 80, 0, "").setFormat("FNF Dialogue", 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		difficultyText.borderSize = 4;
		add(difficultyText);
		songStuff.push(difficultyText);

		diffSelLeft = new AnimatedSprite(20, 70, Paths.sparrow("ui/freeplay/characters/" + CharacterSelectState.player + "/" + style.selectorAsset));
		diffSelLeft.addAnim("idle", "", 24, true);
		diffSelLeft.playAnim("idle");
		add(diffSelLeft);
		songStuff.push(diffSelLeft);

		diffSelRight = new AnimatedSprite(325, 70, diffSelLeft.frames);
		diffSelRight.flipX = true;
		diffSelRight.addAnim("idle", "", 24, true);
		diffSelRight.playAnim("idle");
		add(diffSelRight);
		songStuff.push(diffSelRight);

		difficultyDots = new FlxTypedSpriteGroup<FreeplayDifficultyDot>();
		add(difficultyDots);
		songStuff.push(difficultyDots);
		toCharacterSelectActions.push(function() {
			difficultyDots.forEachAlive(function(dot:FreeplayDifficultyDot) {
				FlxTween.tween(dot, {alpha: 0}, 0.25, {ease: FlxEase.quartOut});
			});
		});

		createCharacterSelectTransition([difficultySprite, difficultyText, diffSelLeft, diffSelRight], -270, 0.8);

		if (menuState > 0 && !shouldDoIntro)
			difficulty = PlayState.difficulty;

		if (difficulty != "normal")
			onChangeDifficulty();

		bgDad = new FlxSprite(pinkBack.width * 0.75, 0, Paths.image("ui/freeplay/characters/" + CharacterSelectState.player + "/" + style.bgAsset));
		bgDad.setGraphicSize(0, FlxG.height);
		bgDad.updateHitbox();

		var blackOverlay:FlxSprite = new FlxSprite(pinkBack.width * 0.75).makeGraphic(Std.int(bgDad.width), Std.int(bgDad.height), FlxColor.BLACK);
		add(blackOverlay);
		introActions.push(function() {
			blackOverlay.x = FlxG.width;
			FlxTween.tween(blackOverlay, {x: pinkBack.width * 0.75}, 0.7, {ease: FlxEase.quintOut});
		});
		createCharacterSelectTransition([bgDad, blackOverlay], -100, 0.8);

		bgDadShader = new FlxRuntimeShader(Paths.shader("AngleMask"), null);
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
		createCharacterSelectTransition([modIcon, albumRoll, diffStars], -175, 0.8);

		chartInfo = new FreeplayChartInfo();
		add(chartInfo);
		songStuff.push(chartInfo);

		var overhangStuff:FlxSprite = new FlxSprite(0, -100).makeGraphic(FlxG.width, 164, FlxColor.BLACK);
		add(overhangStuff);
		introActions.push(function() {
			overhangStuff.y -= overhangStuff.height;
			FlxTween.tween(overhangStuff, {y: -100}, 0.3, {ease: FlxEase.quartOut});
		});

		var fnfFreeplay:FlxText = new FlxText(8, 8, 0, Lang.get("#freeplay.title"), 48);
		fnfFreeplay.font = 'VCR OSD Mono';
		add(fnfFreeplay);

		ostName = new FlxText(0, 8, 0, Lang.get("#freeplay.ost"), 48);
		ostName.font = 'VCR OSD Mono';
		ostName.visible = false;
		ostName.x = Math.round(FlxG.width - ostName.width - 16);
		add(ostName);

		charSelectHint = new FlxText(-40, 18, FlxG.width - 16, Lang.get("#freeplay.characterSelect", [Options.keyString("characterSelect").toUpperCase()])).setFormat("5by7", 32, 0xFF5F5F5F, CENTER);
		introActions.push(function() {
			charSelectHint.y -= 100;
			FlxTween.tween(charSelectHint, {y: charSelectHint.y + 100}, 0.8, {ease: FlxEase.quartOut});
		});
		if (newCharacter)
			add(charSelectHint);

		outroActions.push(function() {
			FlxTween.tween(overhangStuff, {y: -overhangStuff.height}, 0.2, {ease: FlxEase.expoIn});
			FlxTween.tween(fnfFreeplay, {y: -overhangStuff.height}, 0.2, {ease: FlxEase.expoIn});
			FlxTween.tween(charSelectHint, {y: -overhangStuff.height}, 0.2, {ease: FlxEase.expoIn});
		});
		createCharacterSelectTransition([overhangStuff, fnfFreeplay, ostName, charSelectHint], -300, 0.8);

		var highscore:AnimatedSprite = new AnimatedSprite(860, 70, Paths.sparrow("ui/freeplay/highscore"));
		highscore.addAnim("highscore", "highscore small", 24, false);
		add(highscore);
		songStuff.push(highscore);

		new FlxTimer().start(FlxG.random.float(12, 50), function(tmr:FlxTimer) {
			highscore.playAnim("highscore");
			tmr.time = FlxG.random.float(20, 60);
		}, 0);

		fpScore = new FreeplayScore(920, 120, 7, "ui/freeplay/characters/" + CharacterSelectState.player + "/" + style.numbersAsset);
		add(fpScore);
		songStuff.push(fpScore);

		fpClear = new FreeplayClear(1165, 65);
		add(fpClear);
		songStuff.push(fpClear);
		createCharacterSelectTransition([fpScore, fpClear, highscore], -270, 0.8);

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
		createCharacterSelectTransition([letterSort], -270, 0.8);

		introActions.push(function() {
			bgDad.visible = false;
			letterSort.visible = false;
			fnfFreeplay.visible = false;

			var sillyStroke:StrokeShader = new StrokeShader(0xFFFFFFFF, 2, 2);
			fnfFreeplay.shader = sillyStroke;

			new FlxTimer().start(18 / 24, function(tmr:FlxTimer) {
				bgDad.visible = true;
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

		if (categoriesList.length <= 0)
			findCategories();
		for (c in categoriesList)
			categories[c] = [];

		weekOrder = Paths.text("weekOrder").replace("\r","").split("\n");

		FreeplaySandbox.reloadLists();

		nav = new UINumeralNavigation(null, changeCategory, function() {
			var capsule:FreeplayCapsule = currentCapsule();

			if (capsule.songId == "!random")
			{
				curCategory = FlxG.random.int(1, countCapsules() - 1);
				changeCategory();
			}
			else if (ModLoader.modMenus.exists(capsule.songId) && Paths.hscriptExists("data/states/" + ModLoader.modMenus[capsule.songId].freeplay))
			{
				dj.stopTv();
				FlxG.switchState(new HscriptState("data/states/" + ModLoader.modMenus[capsule.songId].freeplay));
			}
			else
			{
				category = capsule.songId;
				menuState = 1;
				curSong = 1;
				reloadMenuStuff();
			}
		}, function() { doOutro(); }, changeCategory);
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
						Util.gotoSong(capsule.songId, difficulty, capsule.songInfo.difficulties, CharacterSelectState.player, capsule.variantScore, style.startDelay);
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

		djScript = new HscriptHandler("data/players/" + CharacterSelectState.player, false);

		djScript.setVar("state", this);
		djScript.setVar("add", add);
		djScript.setVar("insert", insert);
		djScript.setVar("remove", remove);
		djScript.setVar("FreeplayScrollingText", FreeplayScrollingText);

		djScript.execFunc("create", []);

		reloadMenuStuff();

		if (fromCharacterSelect)
		{
			fromCharacterSelect = false;
			doIntroFromCharacterSelect();
		}
		else if (shouldDoIntro)
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
		djScript.execFunc("doIntro", []);
	}

	var outroActions:Array<Void->Void> = [];
	function doOutro()
	{
		nav.locked = true;
		nav2.locked = true;
		letterSort.locked = true;
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
		djScript.execFunc("doOutro", []);
	}

	function createCharacterSelectTransition(objs:Array<FlxSprite>, _y:Float, _time:Float)
	{
		fromCharacterSelectActions.push(function() {
			for (obj in objs)
			{
				obj.y += _y;
				FlxTween.tween(obj, {y: obj.y - _y}, _time * 1.2, {ease: FlxEase.expoOut});
			}
		});
		toCharacterSelectActions.push(function() {
			for (obj in objs)
				FlxTween.tween(obj, {y: obj.y + _y}, _time, {ease: FlxEase.backIn});
		});
	}

	var fromCharacterSelectActions:Array<Void->Void> = [];
	function doIntroFromCharacterSelect()
	{
		var transitionGradient:FlxSprite = new FlxSprite(Paths.image("ui/freeplay/transitionGradient"));
		transitionGradient.scale.set(1280, 1);
		transitionGradient.updateHitbox();
		add(transitionGradient);
		FlxTween.tween(transitionGradient, {y: 720}, 1.8, {ease: FlxEase.expoOut});

		camera.setFilters([blueFadeFilter]);
		FlxTween.num(0.0, 1.0, 0.8, {ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) { camera.setFilters([]); }}, function(num:Float) { blueFade.setFloat("fadeAmt", num); });

		for (action in fromCharacterSelectActions)
			action();
		djScript.execFunc("doIntroFromCharacterSelect", []);
	}

	var toCharacterSelectActions:Array<Void->Void> = [];
	function gotoCharacterSelect()
	{
		nav.locked = true;
		nav2.locked = true;
		dj.playAnim("charSelect");

		for (capsule in grpCapsules.members)
		{
			var distFromSelected:Float = Math.abs(capsule.index - 1) - 1;
			if (distFromSelected < 5)
			{
				capsule.anim = "charSel";
				createCharacterSelectTransition([capsule], -250, 0.8);
			}
		}

		new FlxTimer().start(dj.data.charSelect.transitionDelay, function(tmr:FlxTimer) {
			var transitionGradient:FlxSprite = new FlxSprite(0, 720, Paths.image("ui/freeplay/transitionGradient"));
			transitionGradient.scale.set(1280, 1);
			transitionGradient.updateHitbox();
			add(transitionGradient);
			FlxTween.tween(transitionGradient, {y: 0}, 0.8, {ease: FlxEase.backIn});
			FlxG.sound.music.fadeOut(0.9, function(twn:FlxTween) { FlxG.sound.music.stop(); });

			camera.setFilters([blueFadeFilter]);
			FlxTween.num(1.0, 0.0, 0.8, {ease: FlxEase.quadIn}, function(num:Float) { blueFade.setFloat("fadeAmt", num); });

			new FlxTimer().start(0.9, function(tmr:FlxTimer) {
				MusicBeatState.doTransOut = false;
				MusicBeatState.doTransIn = false;
				fromCharacterSelect = true;
				FlxG.switchState(new CharacterSelectState());
			});

			for (action in toCharacterSelectActions)
				action();
			djScript.execFunc("gotoCharacterSelect", []);
		});
	}

	function findCategories()
	{
		categoriesList = ["!favorites"];
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
			categoriesList.push("");

		for (c in ModLoader.modListLoaded)
		{
			if (possibleCats.contains(c) || Paths.hscriptExists("data/states/" + ModLoader.modMenus[c].freeplay))
				categoriesList.push(c);
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
						if (Paths.smExists(song.song.songId) || Paths.listFiles("songs/" + song.song.songId + "/", ".ogg").length > 0 || Paths.listFiles("data/songs/" + song.song.songId + "/", ".ogg").length > 0)
						{
							if (!cats.contains(song.group))
							{
								cats.push(song.group);
								catMap[song.group] = [];
							}
							catMap[song.group].push(song);
						}
					}

					for (cat in cats)
					{
						var song:WeekSongData = {songId: "", iconNew: TitleState.defaultVariables.noicon, difficulties: [""]};
						var capsule:FreeplayCapsule = makeCapsule("", cat, "none", false, song);
						capsule.updateFavorited(false);

						for (song in catMap[cat])
						{
							if (Paths.smExists(song.song.songId))
							{
								var thisSMFile:SMFile = SMFile.load(song.song.songId);
								var capsule:FreeplayCapsule = makeCapsule(song.song.songId, thisSMFile.title, "none", true, song.song, song.artist, true);
								capsule.category = cat;
								capsule.tracks[""] = {name: Paths.smSong(song.song.songId, thisSMFile.ogg), timings: thisSMFile.bpmMap, start: thisSMFile.previewStart * 1000, end: (thisSMFile.previewStart + thisSMFile.previewLength) * 1000};
								capsule.quickInfo = thisSMFile.quickInfo;
								capsule.updateFavorited();
							}
							else
							{
								var variant:String = (song.song.variant == null ? "bf" : song.song.variant);
								var variantInfo:WeekSongData = null;
								if (variant != CharacterSelectState.player && song.song.songId != "" && Paths.jsonExists("songs/" + song.song.songId + "/_variant_" + CharacterSelectState.player))
									variantInfo = cast Paths.json("songs/" + song.song.songId + "/_variant_" + CharacterSelectState.player);

								if (variant == CharacterSelectState.player || variantInfo != null)
								{
									if (variantInfo != null)
									{
										if (variantInfo.iconNew != null)
											song.song.iconNew = variantInfo.iconNew;

										if (variantInfo.difficulties != null && variantInfo.difficulties.length > 0)
											song.song.difficulties = variantInfo.difficulties;

										if (variantInfo.albums != null)
											song.song.albums = variantInfo.albums;
									}

									var difficulties:Array<String> = song.song.difficulties;

									var songName:String = (song.title == "" ? Song.getSongName(song.song.songId, difficulties[0], CharacterSelectState.player) : Lang.get(song.title));
									var capsule:FreeplayCapsule = makeCapsule(song.song.songId, songName, song.song.iconNew, true, song.song, (variant != CharacterSelectState.player), song.artist, true);
									capsule.category = cat;
									for (d in difficulties)
									{
										capsule.tracks[d] = Song.getFreeplayTrackFromSong(song.song.songId, d, CharacterSelectState.player);
										capsule.quickInfo[d] = Song.getSongQuickInfo(song.song.songId, d, CharacterSelectState.player);
									}
									capsule.updateFavorited();
								}
							}
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
								var variant:String = (song.variant == null ? "bf" : song.variant);
								var variantInfo:WeekSongData = null;
								if (variant != CharacterSelectState.player && song.songId != "" && Paths.jsonExists("songs/" + song.songId + "/_variant_" + CharacterSelectState.player))
									variantInfo = cast Paths.json("songs/" + song.songId + "/_variant_" + CharacterSelectState.player);

								if (variant == CharacterSelectState.player || variantInfo != null)
								{
									if (variantInfo != null)
									{
										if (variantInfo.iconNew != null)
											song.iconNew = variantInfo.iconNew;

										if (variantInfo.difficulties != null && variantInfo.difficulties.length > 0)
											song.difficulties = variantInfo.difficulties;

										if (variantInfo.albums != null)
											song.albums = variantInfo.albums;
									}

									var difficulties:Array<String> = song.difficulties;

									if (song.title == null)
										song.title = "";
									if (spot >= songLists[category].length)
									{
										var songName:String = Lang.get(song.title);
										var initialSongName:String = (songName == "" ? Song.getSongName(song.songId, difficulties[0], CharacterSelectState.player) : songName);
										if (weekLocked)
										{
											songName = Lang.get("#freeplay.song.locked");
											initialSongName = Lang.get("#freeplay.song.locked");
										}
										songLists[category].push([initialSongName, songName]);
									}

									var capsule:FreeplayCapsule = makeCapsule(song.songId, songLists[category][spot][0], song.iconNew, !(song.songId == "" && (song.hscript == null || song.hscript == "")), song, (variant != CharacterSelectState.player), (song.songId == "" ? "" : "!get_artist"), !weekLocked);
									if (song.songId != "" && !weekLocked)
									{
										for (d in difficulties)
										{
											capsule.tracks[d] = Song.getFreeplayTrackFromSong(song.songId, d, CharacterSelectState.player);
											capsule.quickInfo[d] = Song.getSongQuickInfo(song.songId, d, CharacterSelectState.player);
											if (songLists[category][spot][1] != "")
												capsule.quickInfo[d].name = songLists[category][spot][1];
										}
									}
									if (weekNames[i].indexOf("week") > -1)
									{
										var weekType:Int = 0;
										var ind:Int = weekNames[i].lastIndexOf("week") + 4;
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

								var variant:String = (song.variant == null ? "bf" : song.variant);
								var variantInfo:WeekSongData = null;
								if (variant != CharacterSelectState.player && Paths.jsonExists("songs/" + song.songId + "/_variant_" + CharacterSelectState.player))
									variantInfo = cast Paths.json("songs/" + song.songId + "/_variant_" + CharacterSelectState.player);

								if (variant == CharacterSelectState.player || variantInfo != null)
								{
									if (variantInfo != null)
									{
										if (variantInfo.iconNew != null)
											song.iconNew = variantInfo.iconNew;

										if (variantInfo.difficulties != null && variantInfo.difficulties.length > 0)
											song.difficulties = variantInfo.difficulties;

										if (variantInfo.albums != null)
											song.albums = variantInfo.albums;
									}

									var difficulties:Array<String> = song.difficulties;
									if (difficulties == null || difficulties.length == 0)
										difficulties = ["normal", "hard", "easy"];
									if (song.characterLabels == null || song.characterLabels.length < 3)
										song.characterLabels = ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"];

									var capsule:FreeplayCapsule = makeCapsule(song.songId, Song.getSongName(song.songId, difficulties[0], CharacterSelectState.player), (song.iconNew == null ? "none" : song.iconNew), true, song, (variant != CharacterSelectState.player), "!get_artist", true);
									if (song.songId != "")
									{
										for (d in difficulties)
										{
											capsule.tracks[d] = Song.getFreeplayTrackFromSong(song.songId, d, CharacterSelectState.player);
											capsule.quickInfo[d] = Song.getSongQuickInfo(song.songId, d, CharacterSelectState.player);
										}
									}
									capsule.updateFavorited();
								}
							}
						}
					}

					if (hasSM)
					{
						var smFolders:Array<String> = Paths.listFilesFromMod(category,"sm/","");

						for (fl in smFolders)
						{
							var song:WeekSongData = {songId: "", iconNew: TitleState.defaultVariables.noicon, difficulties: [""]};

							var capsule:FreeplayCapsule = makeCapsule("", fl, "none", false, song);
							capsule.updateFavorited(false);

							var smFiles:Array<String> = Paths.listFilesFromMod(category, "sm/" + fl + "/", "");
							for (f in smFiles)
							{
								var thisSM:String = Paths.listFilesFromMod(category, "sm/" + fl + "/" + f, ".sm")[0];
								var thisSMFile:SMFile = SMFile.load(fl + "/" + f + "/" + thisSM);

								if (Assets.exists(Paths.smSong(fl + "/" + f + "/" + thisSM, thisSMFile.ogg)))
								{
									song = {songId: fl + "/" + f + "/" + thisSM, iconNew: TitleState.defaultVariables.noicon, difficulties: thisSMFile.difficulties};
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
		if (curTrack.name != defaultTrack.name || !FlxG.sound.music.playing || forced)
		{
			curTrack = defaultTrack;
			FlxG.sound.music.stop();
			Util.menuMusic();
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.fadeIn(0.5, 0, 0.7);
		}
	}

	function makeCapsule(songId:String, text:String, icon:String, lit:Bool, ?songInfo:WeekSongData = null, ?variantScore:Bool = false, ?songArtist:String = "", ?songUnlocked:Bool = true):FreeplayCapsule
	{
		var capsule:FreeplayCapsule = grpCapsules.recycle(FreeplayCapsule, function() { return new FreeplayCapsule(CharacterSelectState.player, style); });
		capsule.songId = songId;
		capsule.songInfo = songInfo;
		capsule.variantScore = variantScore;
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
		djScript.execFunc("update", [elapsed]);
		bgDadShader.data.extraTint.value = [bgDad.color.redFloat, bgDad.color.greenFloat, bgDad.color.blueFloat];

		if (newCharacter)
		{
			hintTimer += elapsed * 2;
			var targetAmt:Float = (FlxMath.fastSin(hintTimer) + 1) / 2;
			charSelectHint.alpha = FlxMath.lerp(0.3, 0.9, targetAmt);
		}

		if (!(nav.locked && nav2.locked))
		{
			if (menuState > 0)
			{
				if (Options.keyJustPressed("favoriteSong"))
				{
					var capsule:FreeplayCapsule = currentCapsule();
					if (capsule.songId != "" && capsule.songId != "!random" && !capsule.variantScore)
					{
						var categoryName:String = TitleState.defaultVariables.game;
						if (category != "" && category != "!favorites")
							categoryName = ModLoader.getModMetaData(category).title;
						if (category == "!favorites")
							Util.favoriteSong(capsule.songInfo, capsule.filter, capsule.songArtist, capsule.category);
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
						openSubState(new FreeplayMenuResetSubState(capsule.songId, difficulty + (capsule.variantScore ? "-" + CharacterSelectState.player : ""), FreeplaySandbox.chartSide, reload));
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

			if (Options.keyJustPressed("characterSelect") && FlxG.save.data.unlockedCharacters.length > 1)
				gotoCharacterSelect();
		}

		djScript.execFunc("updatePost", [elapsed]);
	}

	override public function beatHit()
	{
		super.beatHit();
		if (Conductor.bpm <= 220 || curBeat % 2 == 0)
			dj.beatHit();
		djScript.execFunc("beatHit", []);
	}

	override public function stepHit()
	{
		super.stepHit();
		djScript.execFunc("stepHit", []);
	}

	function confirmAnim()
	{
		dj.stopTv();
		dj.playAnim("confirm");
		dj.state = FreeplayDJState.ACCEPT;

		var capsule:FreeplayCapsule = currentCapsule();
		capsule.confirmAnim();

		djScript.execFunc("confirmAnim", []);
	}

	function getScore()
	{
		var capsule:FreeplayCapsule = currentCapsule();
		if (capsule.songId == "" || capsule.songId == "!random")
		{
			fpScore.score = 0;
			fpClear.percentage = 0;
		}
		else
		{
			var scoreData:ScoreData = ScoreSystems.loadSongScoreData(capsule.songId, difficulty + (capsule.variantScore ? "-" + CharacterSelectState.player : ""), FreeplaySandbox.chartSide);
			fpScore.score = scoreData.score;
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

		refreshDifficultyDots();
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

			FreeplaySandbox.setCharacterLabels(capsule.songInfo.characterLabels);
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
			onChangeDifficulty(change);
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

	function onChangeDifficulty(?change:Int = 0)
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
			difficultySprite.updateHitbox();
			difficultySprite.offset.set();
			difficultySprite.setPosition(200 - Math.round(difficultySprite.width / 2), 117 - Math.round(difficultySprite.height / 2));
			difficultySprite.offset.y += 5;
			difficultySprite.alpha = 0.5;
			difficultySpriteTimer.cancel();
			difficultySpriteTimer.start(1 / 24, function(tmr) {
				difficultySprite.alpha = 1;
				difficultySprite.updateHitbox();
			});

			FlxTween.cancelTweensOf(difficultySprite, ["x"]);
			difficultySprite.x += 410 * change;
			FlxTween.tween(difficultySprite, {x: difficultySprite.x - (410 * change)}, 0.2, {ease: FlxEase.circInOut});
		}
		else
		{
			difficultySprite.alpha = 0;
			difficultyText.y = 117 - Math.round(difficultyText.height / 2);
			difficultyText.offset.y += 5;
			difficultyText.alpha = 0.5;
			difficultySpriteTimer.cancel();
			difficultySpriteTimer.start(1 / 24, function(tmr) {
				difficultyText.alpha = 1;
				difficultyText.updateHitbox();
			});

			FlxTween.cancelTweensOf(difficultyText, ["x"]);
			difficultyText.x += 410 * change;
			FlxTween.tween(difficultyText, {x: difficultyText.x - (410 * change)}, 0.2, {ease: FlxEase.circInOut});
		}

		difficultyDots.forEachAlive(function(dot:FreeplayDifficultyDot) {
			dot.updateSelected(difficulty);
		});
	}

	function refreshDifficultyDots()
	{
		difficultyDots.forEachAlive(function(dot:FreeplayDifficultyDot) {
			dot.kill();
			dot.destroy();
		});
		difficultyDots.clear();
		difficultyDots.setPosition(0, 0);

		var capsule:FreeplayCapsule = currentCapsule();
		if (capsule.songInfo != null && capsule.songInfo.difficulties != null)
		{
			var diffs:Array<String> = capsule.songInfo.difficulties;
			if (diffs[diffs.length - 1] == "easy")
			{
				diffs.remove("easy");
				diffs.unshift("easy");
			}
			for (i in 0...diffs.length)
			{
				var dot:FreeplayDifficultyDot = new FreeplayDifficultyDot(capsule.songInfo.difficulties[i], i);
				dot.updateSelected(difficulty, true);
				difficultyDots.add(dot);
			}
			difficultyDots.setPosition(203 - (difficultyDots.width / 2), 170);
		}
	}

	function updateCapsuleInfo()
	{
		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			capsule.chartSide = FreeplaySandbox.chartSide;
			if (capsule.songInfo != null && capsule.songInfo.difficulties.contains(difficulty))
				capsule.rank = ScoreSystems.loadSongScoreData(capsule.songId, difficulty + (capsule.variantScore ? "-" + CharacterSelectState.player : ""), FreeplaySandbox.chartSide).rank;
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
			chartInfo.reload("", difficulty, FreeplaySandbox.chartSide, "", CharacterSelectState.player);
		else
		{
			if (Paths.smExists(capsule.songId))
			{
				var smFile:SMFile = SMFile.load(capsule.songId, false);
				var divChart:SongData = smFile.songData[smFile.difficulties.indexOf(difficulty)];
				divChart = Song.correctDivisions(divChart);

				FreeplaySandbox.sideList = divChart.columnDivisionNames.copy();
				FreeplaySandbox.variantList = [""];
			}
			else
			{
				FreeplaySandbox.sideList = Song.getSongSideList(capsule.songId, difficulty, CharacterSelectState.player);
				FreeplaySandbox.variantList = Song.getSongVariantList(capsule.songId, difficulty, CharacterSelectState.player);
			}

			if (FreeplaySandbox.chartSide >= FreeplaySandbox.sideList.length)
				FreeplaySandbox.chartSide = 0;

			if (!FreeplaySandbox.variantList.contains(FreeplaySandbox.songVariant))
				FreeplaySandbox.songVariant = "";

			var songArtist:String = capsule.songArtist;
			if (songArtist == "!get_artist")
				songArtist = Song.getSongArtist(capsule.songId, difficulty, CharacterSelectState.player);

			chartInfo.reload(capsule.songId, difficulty, FreeplaySandbox.chartSide, songArtist, CharacterSelectState.player);
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

		if (newRank == 0)
		{
			dj.playAnim("loss", true, false);
			dj.state = FreeplayDJState.RANKING_BAD;
		}
		else
		{
			dj.playAnim("fistPump", true, false);
			dj.state = FreeplayDJState.RANKING;
		}
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

			dj.state = FreeplayDJState.IDLE;
			if (newRank == 0)
			{
				dj.playAnim("loss", true, false);
				dj.anim.curFrame = dj.data.fistPump.loopBadStartFrame;
			}
			else
			{
				dj.playAnim("fistPump", true, false);
				dj.anim.curFrame = dj.data.fistPump.loopStartFrame;
			}

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