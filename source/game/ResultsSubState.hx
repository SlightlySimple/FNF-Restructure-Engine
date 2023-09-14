package game;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxCamera;
import data.Options;
import data.ScoreSystems;

class HitGraph extends BitmapData
{
	override public function new(width:Int, height:Int, results:PlayResults)
	{
		super(width, height, true, 0x80000000);
		var judgeMS:Array<Float> = ScoreSystems.judgeMS;
		judgeMS.push(judgeMS[4] * 2);

		fillRect(new Rectangle(0, Std.int(height / 2), width, 1), FlxColor.WHITE);
		for (i in 0...4)
		{
			fillRect(new Rectangle(0, Std.int(((judgeMS[i] + judgeMS[4]) / judgeMS[5]) * height), width, 1), FlxColor.GRAY);
			fillRect(new Rectangle(0, Std.int(((-judgeMS[i] + judgeMS[4]) / judgeMS[5]) * height), width, 1), FlxColor.GRAY);
		}

		for (note in results.hitGraph)
		{
			var xx:Float = (note.time / results.songLength) * PlayState.instance.playbackRate;
			xx *= width;
			var yy:Float = (note.offset + judgeMS[4]) / judgeMS[5];
			yy *= height;
			var col:FlxColor = Options.options.colorMS;
			switch (note.judgement)
			{
				case 0: col = Options.options.colorMV;
				case 1: col = Options.options.colorSK;
				case 2: col = Options.options.colorGD;
				case 3: col = Options.options.colorBD;
				case 4: col = Options.options.colorSH;
			}

			fillRect(new Rectangle(Std.int(xx) - 1, Std.int(yy) - 1, 3, 3), col);
		}
	}
}

class HealthGraph extends BitmapData
{
	override public function new(width:Int, height:Int, data:Array<Array<Float>>)
	{
		super(width, height, true, 0x80000000);

		var maxWValue:Float = data[data.length - 1][0];

		for (i in 0...data.length - 1)
		{
			var d = data[i];
			var e = data[i+1];

			var xx = Std.int((d[0] / maxWValue) * width);
			var yy = Std.int(((100 - d[1]) / 100) * height);
			var xxNext = Std.int((e[0] / maxWValue) * width);
			var ww = Std.int( xxNext - xx );
			var hh = Std.int( height - yy );
			fillRect(new Rectangle(xx, yy, ww, hh), Options.options.healthBarColorR);
		}
	}
}

class ResultsSubState extends FlxSubState
{
	public static var menuMusic:FlxSound = null;
	public static var music:String = "results";
	public static var musicEnd:String = "resultsEnd";

	public static var songNames:Array<String> = [];
	public static var sideName:String = "";
	public static var healthData:Array<Array<Array<Float>>> = [];
	var resultsStuff:Array<PlayResults> = [];
	var camResults:FlxCamera;

	var songName:FlxText;
	var hitGraph:FlxSprite;
	var healthGraph:FlxSprite;
	var continueText:FlxText;

	var viewingSong:Int = 0;
	var ratingNames:Array<String> = [];

	public static function resetStatics()
	{
		songNames = [];
		healthData = [];
		music = "results";
		musicEnd = "resultsEnd";
	}

	override public function new(scores:ScoreSystems)
	{
		super();

		if (menuMusic == null && music != "")
		{
			menuMusic = new FlxSound().loadEmbedded(Paths.music(music), true);
			FlxG.sound.list.add(menuMusic);
			menuMusic.volume = 0;
			menuMusic.play();
			menuMusic.fadeIn(1, 0, 0.5);
		}

		ratingNames = ["#resRatingMV", "#resRatingSK", "#resRatingGD", "#resRatingBD", "#resRatingSH"];

		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.BLACK);
		bg.alpha = 0.5;
		add(bg);

		songName = new FlxText(460, 120, 740, songNames[0], 18);
		if (songNames.length > 1)
			songName.text = "< " + songName.text + " >";
		songName.font = "VCR OSD Mono";
		songName.alignment = CENTER;
		add(songName);

		resultsStuff = [scores.results];
		if (PlayState.inStoryMode)
			resultsStuff = ScoreSystems.resultsArray;

		hitGraph = new FlxSprite(460, 180);
		hitGraph.antialiasing = false;
		hitGraph.pixels = new HitGraph(740, 200, resultsStuff[0]);
		add(hitGraph);

		var earlyText:FlxText = new FlxText(460, 385, 0, Lang.get("#resEarly", [Std.string(ScoreSystems.judgeMS[4])]), 18);
		earlyText.font = "VCR OSD Mono";
		add(earlyText);

		var lateText:FlxText = new FlxText(460, 175, 0, Lang.get("#resLate", [Std.string(ScoreSystems.judgeMS[4])]), 18);
		lateText.font = "VCR OSD Mono";
		lateText.y -= lateText.height;
		add(lateText);

		healthGraph = new FlxSprite(460, 455);
		healthGraph.antialiasing = false;
		healthGraph.pixels = new HealthGraph(740, 150, healthData[0]);
		add(healthGraph);

		var resultsTitle:FlxText = new FlxText(0, 50, 0, Lang.get("#resTitle"), 48);
		resultsTitle.font = "VCR OSD Mono";
		resultsTitle.screenCenter(X);
		add(resultsTitle);

		var resultsText:FlxText = new FlxText(100, 0, 0, "", 24);
		resultsText.text = Lang.get("#resDifficulty", [Lang.getNoHash(PlayState.difficulty).toUpperCase()]) + "\n";
		if (PlayState.instance.chartSide > 0)
			resultsText.text += Lang.get("#resSide", [Lang.get(sideName)]) + "\n";
		if (PlayState.instance.playbackRate != 1)
			resultsText.text += Lang.get("#resRate", [Std.string(PlayState.instance.playbackRate)]) + "\n";

		var nums:Array<Float> = [scores.score, scores.highestCombo, scores.sustains];
		var nums2:Array<Int> = scores.judgements;
		if (PlayState.inStoryMode)
		{
			nums = [ScoreSystems.weekScore, ScoreSystems.highestComboInWeek, ScoreSystems.weekSustains];
			nums2 = ScoreSystems.weekJudgements;
		}
		resultsText.text += "\n" + Lang.get("#resScore", [Std.string(nums[0])])
		+ "\n" + Lang.get("#resHighestCombo", [Std.string(nums[1])])
		+ "\n" + Lang.get("#resAccuracy", [Std.string(Math.fround(scores.accuracy * 100) / 100)]);
		if (PlayState.inStoryMode)
			resultsText.text += "\n" + ScoreSystems.ratingFromJudgements(ScoreSystems.weekJudgements) + "\n";
		else
			resultsText.text += "\n" + scores.rating + "\n";
		for (i in 0...ratingNames.length)
			resultsText.text += "\n" + Lang.get(ratingNames[i], [Std.string(nums2[i])]);
		resultsText.text += "\n" + Lang.get("#resSustains", [Std.string(nums[2])])
		+ "\n" + Lang.get("#resMisses", [Std.string(nums2[5])]);
		resultsText.font = "VCR OSD Mono";
		resultsText.screenCenter(Y);
		add(resultsText);

		continueText = new FlxText(0, 650, FlxG.width, Lang.get("#resPressEnter"), 32);
		continueText.font = "VCR OSD Mono";
		continueText.alignment = CENTER;
		add(continueText);

		for (m in members)
		{
			var s:FlxSprite = cast m;
			var a:Float = s.alpha;
			s.alpha = 0;
			FlxTween.tween(s, {alpha: a}, 0.2);
		}

		camResults = new FlxCamera();
		camResults.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camResults, false);

		camera = camResults;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Options.keyJustPressed("fullscreen"))
			FlxG.fullscreen = !FlxG.fullscreen;

		if (resultsStuff.length > 1)
		{
			if (Options.keyJustPressed("ui_right"))
				changeSelection(1);

			if (Options.keyJustPressed("ui_left"))
				changeSelection(-1);
		}

		if (Options.keyJustPressed("ui_accept"))
		{
			if (musicEnd != "")
				FlxG.sound.play(Paths.music(musicEnd), 0.5);
			stopMusic();
			continueText.scale.set(0.85, 0.85);
			FlxTween.tween(continueText.scale, {x: 0.9, y: 0.9}, 0.3, {ease: FlxEase.quadOut});
			new FlxTimer().start(0.75, function(tmr) { PlayState.instance.gotoMenuState(); });
		}
	}

	function changeSelection(change:Int = 0)
	{
		viewingSong += change;
		if (viewingSong < 0)
			viewingSong = resultsStuff.length - 1;
		if (viewingSong >= resultsStuff.length)
			viewingSong = 0;

		if (change != 0)
			FlxG.sound.play(Paths.sound("ui/scrollMenu"));

		songName.text = "< " + songNames[viewingSong] + " >";
		hitGraph.pixels = new HitGraph(740, 200, resultsStuff[viewingSong]);
		healthGraph.pixels = new HealthGraph(740, 150, healthData[viewingSong]);
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
}