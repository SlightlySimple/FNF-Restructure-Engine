package menus;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import data.Options;
import data.Song;
import editors.ChartEditorState;
import game.PlayState;
import menus.UINavigation;
import objects.Alphabet;

import haxe.Json;

using StringTools;

class PauseSubState extends FlxSubState
{
	public static var instance:PauseSubState;
	public static var music:String = "breakfast";
	public static var menuMusic:FlxSound = null;

	var from:Int = 0;

	var bg:FlxSprite;
	var songMetadata:FlxTypedSpriteGroup<FlxText>;
	public static var deathCounterText:String = "";

	var menu:Array<Array<Dynamic>> = [];
	var menuButtons:UIMenu;
	var menuButtonsXOffset:Float = 0;
	public var menuButtonPosition:Void->Void;
	var curOption:Int = 0;

	var difficultyMenu:Array<Array<Dynamic>> = [];
	var difficultyMenuButtons:UIMenu;
	var difficultyMenuButtonsXOffset:Float = FlxG.width;
	public var difficultyMenuButtonPosition:Void->Void;
	var curDifficulty:Int = 0;

	var nav:UINumeralNavigation;
	var nav2:UINumeralNavigation;

	public static var pausedTweens:Array<FlxTween> = [];
	public static var pausedTimers:Array<FlxTimer> = [];

	override public function new(?from:Int = 0)
	{
		super();

		instance = this;
		this.from = from;
		menuButtonPosition = defaultMenuButtonPosition;
		difficultyMenuButtonPosition = defaultDifficultyMenuButtonPosition;

		if (from == 0)
		{
			pausedTweens = [];
			FlxTween.globalManager.forEach(function(twn:FlxTween) { if (twn.active) pausedTweens.push(twn); });
			if (pausedTweens.length > 0)
			{
				for (t in pausedTweens)
					t.active = false;
			}

			pausedTimers = [];
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) { if (tmr.active) pausedTimers.push(tmr); });
			if (pausedTimers.length > 0)
			{
				for (t in pausedTimers)
					t.active = false;
			}
		}

		if (menuMusic == null && Paths.musicExists(music))
		{
			menuMusic = new FlxSound().loadEmbedded(Paths.music(music), true);
			FlxG.sound.list.add(menuMusic);
			menuMusic.volume = 0;
			menuMusic.play();
			menuMusic.fadeIn(1, 0, 0.5);
		}

		bg = new FlxSprite().makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.BLACK);
		if (from == 0)
		{
			bg.alpha = 0;
			FlxTween.tween(bg, {alpha: 0.5}, 0.4);
		}
		else
			bg.alpha = 0.5;
		add(bg);

		menuButtons = new UIMenu();
		menuButtons.onIdle = function(s:FlxSprite) { s.alpha = 0.6; };
		menuButtons.onHover = function(s:FlxSprite) { s.alpha = 1; };
		add(menuButtons);

		difficultyMenuButtons = new UIMenu(difficultyMenuButtonsXOffset);
		difficultyMenuButtons.onIdle = function(s:FlxSprite) { s.alpha = 0.6; };
		difficultyMenuButtons.onHover = function(s:FlxSprite) { s.alpha = 1; };
		add(difficultyMenuButtons);



		songMetadata = new FlxTypedSpriteGroup<FlxText>();
		add(songMetadata);
		var songMetadataList:Array<String> = [];

		songMetadataList.push(Lang.get("#pause.metadata.songName", [PlayState.instance.songName]));

		if (PlayState.instance.songData.artist.trim() != "")
			songMetadataList.push(Lang.get("#pause.metadata.songArtist", [PlayState.instance.songData.artist]));
		else
			songMetadataList.push(Lang.get("#pause.metadata.songArtist", [Lang.get("#pause.metadata.songArtist.default")]));

		if (PlayState.instance.songData.charter.trim() != "")
			songMetadataList.push(Lang.get("#pause.metadata.songCharter", [PlayState.instance.songData.charter]));
		else
			songMetadataList.push(Lang.get("#pause.metadata.songCharter", [Lang.get("#pause.metadata.songCharter.default")]));

		songMetadataList.push(Lang.get("#pause.metadata.difficulty", [Lang.get("#difficulty." + PlayState.difficulty, PlayState.difficulty)]));

		var trueDeathCounterText:String = Lang.get("#pause.gameOver.default", [Std.string(PlayState.deaths)]);
		if (deathCounterText.trim() != "")
		{
			if (deathCounterText.trim().startsWith("#"))
				trueDeathCounterText = Lang.get(deathCounterText.trim(), [Std.string(PlayState.deaths)]);
			else
			{
				trueDeathCounterText = deathCounterText.trim();
				if (trueDeathCounterText.indexOf("%s1") > -1)
					trueDeathCounterText = trueDeathCounterText.replace("%s1", Std.string(PlayState.deaths));
				else
				{
					if (!trueDeathCounterText.endsWith(":"))
						trueDeathCounterText += ":";
					trueDeathCounterText += " " + Std.string(PlayState.deaths);
				}
			}
		}
		songMetadataList.push(trueDeathCounterText);

		var yy:Float = 15;
		var showDelay:Float = 0.1;
		for (meta in songMetadataList)
		{
			var metaTxt:FlxText = new FlxText(0, yy, 0, meta).setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT);
			metaTxt.x = FlxG.width - metaTxt.width - 20;
			songMetadata.add(metaTxt);
			if (from == 0)
			{
				metaTxt.alpha = 0;
				FlxTween.tween(metaTxt, {alpha: 1, y: yy + 5}, 1.8, {ease: FlxEase.quartOut, startDelay: showDelay});
			}
			else
				metaTxt.y += 5;
			yy += 32;
			showDelay += 0.1;
		}
		if (from == 1)
		{
			songMetadata.x = FlxG.width;
			FlxTween.tween(songMetadata, {x: 0}, 0.2, {ease: FlxEase.expoOut});
		}



		menu.push(["#pause.menu.resume", function() {
			nav.locked = true;
			new FlxTimer().start(0.75, function(tmr:FlxTimer) {
				PlayState.instance.hscriptExec("pauseResume", []);
				stopMusic();
				unpauseAll();
				close();
			});
		}]);
		menu.push(["#pause.menu.restart", function() {
			stopMusic();
			unpauseAll();
			PlayState.instance.restartSong();
		}]);

		if ((!PlayState.inStoryMode || PlayState.storyProgress == 0) && !PlayState.testingChart && PlayState.difficultyList.length > 1)
		{
			menu.push(["#pause.menu.changeDifficulty", function() {
				nav.locked = true;
				FlxTween.color(menuButtons, 0.3, FlxColor.WHITE, FlxColor.GRAY, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) { nav2.locked = false; }});
				FlxTween.tween(this, {menuButtonsXOffset: -450}, 0.3, {ease: FlxEase.quadInOut});
				FlxTween.tween(this, {difficultyMenuButtonsXOffset: 300}, 0.3, {ease: FlxEase.quadInOut});

				curDifficulty = PlayState.difficultyList.indexOf(PlayState.difficulty);
				changeDifficulty();
			}]);
		}

		if (PlayState.instance.isSM)
			menu.push(["#pause.menu.saveChart", saveChart]);

		var optionsMenuPosition:Int = menu.length;
		menu.push(["#pause.menu.options", function() {
			nav.locked = true;
			PlayState.optionsMenuStatus = 1;
			FlxTween.tween(menuButtons, {x: menuButtons.x - FlxG.width}, 0.2, {ease: FlxEase.expoIn, onComplete: function(twn:FlxTween) { menuButtons.visible = false; }});
			FlxTween.tween(songMetadata, {x: songMetadata.x + FlxG.width}, 0.2, {ease: FlxEase.expoIn});
			new FlxTimer().start(0.25, function(tmr:FlxTimer) {
				close();
			});
		}]);

		if (PlayState.testingChart)
		{
			menu.push(["#pause.menu.exitToChartEditor", function() {
				stopMusic();
				unpauseAll();
				PlayState.instance.exitToMenu(false);
			}]);
		}
		else
		{
			menu.push(["#pause.menu.exitToMenu", function() {
				stopMusic();
				unpauseAll();
				PlayState.instance.exitToMenu(true);
			}]);
		}

		for (i in 0...menu.length)
		{
			var textButton:Alphabet = new Alphabet(Std.int((i * 20) + 90), Std.int((i * 1.3 * 120) + (FlxG.height * 0.48)), Lang.get(menu[i][0]));
			menuButtons.add(textButton);
		}

		nav = new UINumeralNavigation(null, changeSelection, function() {
			menu[curOption][1]();
			PlayState.instance.hscriptExec("pauseAccept", []);
		}, null, changeSelection);
		nav.leftClick = nav.accept;
		add(nav);



		if (PlayState.difficultyList != null && PlayState.difficultyList.length > 0)
		{
			for (d in PlayState.difficultyList)
			{
				difficultyMenu.push([Lang.get("#difficulty." + d, d), function() {
					stopMusic();
					unpauseAll();
					PlayState.difficulty = d;
					PlayState.instance.restartSong();
				}]);
			}
		}

		difficultyMenu.push(["#pause.menu.changeDifficulty.back", function() {
			nav2.locked = true;
			FlxTween.color(menuButtons, 0.3, FlxColor.GRAY, FlxColor.WHITE, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) { nav.locked = false; }});
			FlxTween.tween(this, {menuButtonsXOffset: 0}, 0.3, {ease: FlxEase.quadInOut});
			FlxTween.tween(this, {difficultyMenuButtonsXOffset: FlxG.width}, 0.3, {ease: FlxEase.quadInOut});
		}]);

		for (i in 0...difficultyMenu.length)
		{
			var textButton:Alphabet = new Alphabet(Std.int((i * 20) + 90), Std.int((i * 1.3 * 120) + (FlxG.height * 0.48)), Lang.get(difficultyMenu[i][0]));
			difficultyMenuButtons.add(textButton);
		}

		nav2 = new UINumeralNavigation(null, changeDifficulty, function() {
			difficultyMenu[curDifficulty][1]();
			PlayState.instance.hscriptExec("pauseAcceptDifficulty", []);
		}, null, changeDifficulty);
		nav2.leftClick = nav2.accept;
		nav2.locked = true;
		add(nav2);



		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		PlayState.instance.hscriptExec("pauseCreate", []);

		if (from == 1)
			curOption = optionsMenuPosition;
		menuButtons.x = curOption * -20;
		menuButtons.y = curOption * 1.3 * -120;
		changeSelection();

		if (from == 1)
		{
			menuButtons.x -= FlxG.width;
			FlxTween.tween(menuButtons, {x: menuButtons.x + FlxG.width}, 0.2, {ease: FlxEase.expoOut});
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.hscriptExec("pauseUpdate", [elapsed]);

		menuButtonPosition();
		difficultyMenuButtonPosition();

		PlayState.instance.hscriptExec("pauseUpdatePost", [elapsed]);
	}

	function defaultMenuButtonPosition()
	{
		menuButtons.x = FlxMath.lerp(menuButtons.x, (curOption * -20) + menuButtonsXOffset, 0.16 * FlxG.elapsed * 60);
		menuButtons.y = FlxMath.lerp(menuButtons.y, curOption * 1.3 * -120, 0.16 * FlxG.elapsed * 60);
	}

	function defaultDifficultyMenuButtonPosition()
	{
		difficultyMenuButtons.x = FlxMath.lerp(difficultyMenuButtons.x, (curDifficulty * -20) + difficultyMenuButtonsXOffset, 0.16 * FlxG.elapsed * 60);
		difficultyMenuButtons.y = FlxMath.lerp(difficultyMenuButtons.y, curDifficulty * 1.3 * -120, 0.16 * FlxG.elapsed * 60);
	}

	function stopMusic()
	{
		if (menuMusic != null)
		{
			if (menuMusic.fadeTween != null)
				menuMusic.fadeTween.cancel();
			menuMusic.stop();
			menuMusic.destroy();
			menuMusic = null;
		}
	}

	function unpauseAll()
	{
		if (pausedTweens.length > 0)
		{
			for (t in pausedTweens)
				t.active = true;
		}
		pausedTweens = [];

		if (pausedTimers.length > 0)
		{
			for (t in pausedTimers)
				t.active = true;
		}
		pausedTimers = [];
	}

	function changeSelection(change:Int = 0)
	{
		curOption = Util.loop(curOption + change, 0, menu.length - 1);
		menuButtons.selection = curOption;
		PlayState.instance.hscriptExec("pauseChangeSelection", []);
	}

	function changeDifficulty(change:Int = 0)
	{
		curDifficulty = Util.loop(curDifficulty + change, 0, difficultyMenu.length - 1);
		difficultyMenuButtons.selection = curDifficulty;
		PlayState.instance.hscriptExec("pauseChangeDifficultySelection", []);
	}



	function saveChart()
	{
		PlayState.instance.songData.useBeats = true;
		var songData:SongData = ChartEditorState.prepareChartSave(PlayState.instance.songData);
		var data:String = Json.stringify({song: songData});

		if ((data != null) && (data.length > 0))
		{
			var file:FileBrowser = new FileBrowser();
			file.save(PlayState.songId + ".json", data.trim());
		}
	}
}