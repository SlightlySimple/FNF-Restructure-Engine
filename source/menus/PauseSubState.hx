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
	var bg:FlxSprite;
	var songStuff:FlxText;
	var menuButtonText:Array<String> = ["#pResume", "#pRestart", "#pOptions", "#pExit"];
	var menuButtons:FlxTypedSpriteGroup<Alphabet>;
	public var menuButtonPosition:Void->Void;
	var curOption:Int = 0;
	var nav:UINumeralNavigation;

	public static var pausedTweens:Array<FlxTween> = [];
	public static var pausedTimers:Array<FlxTimer> = [];

	override public function new(?option:Int = 0)
	{
		super();

		instance = this;
		menuButtonPosition = defaultMenuButtonPosition;

		if (option == 0)
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
		if (option == 0)
		{
			bg.alpha = 0;
			FlxTween.tween(bg, {alpha: 0.5}, 0.4);
		}
		else
			bg.alpha = 0.5;
		add(bg);

		menuButtons = new FlxTypedSpriteGroup<Alphabet>();
		add(menuButtons);

		songStuff = new FlxText(0, 15, FlxG.width - 20, PlayState.instance.songName + "\n" + Lang.getNoHash(PlayState.difficulty).toUpperCase() + "\n", 32);
		songStuff.font = "VCR OSD Mono";
		songStuff.alignment = RIGHT;
		songStuff.alpha = 0;
		add(songStuff);

		FlxTween.tween(songStuff, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});

		if (PlayState.instance.isSM)
			menuButtonText.insert(2, "#pSaveChart");
		for (i in 0...menuButtonText.length)
		{
			var textButton:Alphabet = new Alphabet(Std.int((i * 20) + 90), Std.int((i * 1.3 * 120) + (FlxG.height * 0.48)), Lang.get(menuButtonText[i]));
			menuButtons.add(textButton);
		}

		nav = new UINumeralNavigation(null, changeSelection, function() {
			switch (menuButtonText[curOption])
			{
				case "#pResume":
					nav.locked = true;
					new FlxTimer().start(0.75, function(tmr:FlxTimer)
					{
						PlayState.instance.hscriptExec("pauseResume", []);
						stopMusic();
						unpauseAll();
						close();
					});

				case "#pRestart":
					stopMusic();
					unpauseAll();
					PlayState.instance.restartSong();

				case "#pOptions":
					PlayState.optionsMenuStatus = 1;
					close();

				case "#pExit":
					stopMusic();
					unpauseAll();
					PlayState.instance.exitToMenu();

				case "#pSaveChart": saveChart();
			}
			PlayState.instance.hscriptExec("pauseAccept", []);
		}, null, changeSelection);
		nav.leftClick = nav.accept;
		add(nav);

		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		PlayState.instance.hscriptExec("pauseCreate", []);

		curOption = option;
		menuButtons.x = curOption * -20;
		menuButtons.y = curOption * 1.3 * -120;
		changeSelection();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.hscriptExec("pauseUpdate", [elapsed]);

		if (Options.keyJustPressed("fullscreen"))
			FlxG.fullscreen = !FlxG.fullscreen;

		menuButtonPosition();

		PlayState.instance.hscriptExec("pauseUpdatePost", [elapsed]);
	}

	function defaultMenuButtonPosition()
	{
		menuButtons.x = FlxMath.lerp(menuButtons.x, curOption * -20, 0.16 * FlxG.elapsed * 60);
		menuButtons.y = FlxMath.lerp(menuButtons.y, curOption * 1.3 * -120, 0.16 * FlxG.elapsed * 60);
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
		curOption = Util.loop(curOption + change, 0, menuButtons.members.length - 1);

		var i:Int = 0;

		menuButtons.forEachAlive(function(button:Alphabet)
		{
			if (i == curOption)
				button.alpha = 1;
			else
				button.alpha = 0.6;
			i++;
		});

		PlayState.instance.hscriptExec("pauseChangeSelection", []);
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