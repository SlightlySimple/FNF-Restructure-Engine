package game.results;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import data.Options;
import data.ScoreSystems;
import objects.AnimatedSprite;
import scripting.HscriptHandler;
import shaders.ColorFade;
import MusicBeatState;

typedef ResultsData =
{
	var ?title:String;
	var playbackRate:Float;
	var chartSide:Int;
	var ?sideName:String;
	var ?songNames:Array<String>;
	var ?artistNames:Array<String>;
	var ?difficulty:String;
	var ?rating:String;
	var ?oldScore:ScoreData;
	var ?score:ScoreData;

	var ?noteGraphData:Array<PlayResults>;
	var ?judgements:Array<Int>;
	var ?accuracy:Float;
}

class HitGraph extends BitmapData
{
	override public function new(width:Int, height:Int, results:PlayResults, ?playbackRate:Float)
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
			var xx:Float = (note.time / results.songLength) * playbackRate;
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

class ResultsNumber extends FlxTypedSpriteGroup<AnimatedSprite>
{
	public var number(default, set):Int = 0;
	var flavor:FlxColor;

	public override function new(x:Float, y:Float, number:Int, flavor:FlxColor)
	{
		super(x, y);
		this.flavor = flavor;
		this.number = number;
		if (number == 0)
			drawNumbers();
	}

	public function set_number(val:Int):Int
	{
		if (val != number)
		{
			number = val;
			drawNumbers();
		}

		return val;
	}

	function drawNumbers()
	{
		var digits:Array<Int> = [];
		if (number > 0)
		{
			var finalVal:Int = number;
			while (finalVal > 0)
			{
				digits.unshift(finalVal % 10);
				finalVal = Std.int(Math.floor(finalVal / 10));
			}
		}
		else
			digits = [0];

		if (digits.length > members.length)
		{
			while (digits.length > members.length)
			{
				var digit:AnimatedSprite = new AnimatedSprite(members.length * 43, 0, Paths.sparrow("ui/results/tallieNumber"));
				for (i in 0...10)
					digit.addAnim(Std.string(i), Std.string(i), 24, false);
				digit.color = flavor;
				add(digit);
			}
		}

		for (i in 0...digits.length)
			members[i].playAnim(Std.string(digits[i]));
	}
}

class ResultsPercentage extends FlxTypedSpriteGroup<AnimatedSprite>
{
	public var number(default, set):Float = 0;
	var flavor:FlxColor;

	public override function new(x:Float, y:Float, number:Float, flavor:FlxColor)
	{
		super(x, y);
		this.flavor = flavor;
		this.number = number;
		if (number == 0)
			drawNumbers();
	}

	public function set_number(val:Float):Float
	{
		if (val != number)
		{
			number = val;
			drawNumbers();
		}

		return val;
	}

	function drawNumbers()
	{
		var digits:Array<String> = [];
		if (number > 0)
		{
			var finalVal:Float = Math.fround(number * 100) / 100;
			var dot:Int = 0;
			while (finalVal != Math.floor(finalVal) && dot < 2)
			{
				finalVal *= 10;
				dot++;
			}
			finalVal = Math.round(finalVal);

			while (finalVal > 0)
			{
				digits.unshift(Std.string(finalVal % 10));
				finalVal = Math.floor(finalVal / 10);
				if (digits.length == dot)
					digits.unshift("dot");
			}
		}
		else
			digits = ["0"];
		digits.push("percent");

		if (digits.length > members.length)
		{
			while (digits.length > members.length)
			{
				var digit:AnimatedSprite = new AnimatedSprite(members.length * 43, 0, Paths.sparrow("ui/results/tallieNumber"));
				for (i in 0...10)
					digit.addAnim(Std.string(i), Std.string(i), 24, false);
				digit.addAnim("dot", "dot", 24, false);
				digit.addAnim("percent", "percent", 24, false);
				digit.color = flavor;
				add(digit);
			}
		}

		var xx:Int = 0;
		for (i in 0...members.length)
		{
			if (i >= digits.length)
				members[i].visible = false;
			else
			{
				members[i].visible = true;
				members[i].x = x + xx;
				members[i].playAnim(digits[i]);
				if (digits[i] == "dot")
				{
					xx += 24;
					members[i].y = y + 24;
				}
				else
				{
					xx += 43;
					members[i].y = y;
				}
			}
		}
	}
}

class ResultsScore extends FlxTypedSpriteGroup<ResultsScoreNum>
{
	public var scoreShit(default, set):Int = 0;

	public var scoreStart:Int = 0;

	function set_scoreShit(val):Int
	{
		if (group == null || group.members == null) return val;

		var loopNum:Int = group.members.length - 1;
		var dumbNumb = Std.parseInt(Std.string(val));
		var prevNum:ResultsScoreNum;

		while (dumbNumb > 0)
		{
			scoreStart += 1;
			group.members[loopNum].finalDigit = dumbNumb % 10;

			dumbNumb = Math.floor(dumbNumb / 10);
			loopNum--;
		}

		while (loopNum > 0)
		{
			group.members[loopNum].digit = 10;
			loopNum--;
		}

		return val;
	}

	public function animateNumbers()
	{
		for (i in group.members.length-scoreStart...group.members.length)
		{
			new FlxTimer().start((i - 1) / 24, function(tmr:FlxTimer) {
				group.members[i].finalDelay = scoreStart - (i-1);
				group.members[i].playAnim();
				group.members[i].shuffle();
			});
		}
	}

	public function new(x:Float, y:Float, digitCount:Int, scoreShit:Int = 100)
	{
		super(x, y);

		for (i in 0...digitCount)
			add(new ResultsScoreNum(x + (65 * i), y));

		this.scoreShit = scoreShit;
	}

	public function updateScore(scoreNew:Int)
	{
		scoreShit = scoreNew;
	}
}

class ResultsScoreNum extends FlxSprite
{
	public var digit(default, set):Int = 10;
	public var finalDigit(default, set):Int = 10;
	public var glow:Bool = true;

	function set_finalDigit(val:Int):Int
	{
		animation.play("GONE", true, false, 0);
		return finalDigit = val;
	}

	function set_digit(val:Int):Int
	{
		if (val >= 0 && animation.curAnim != null && animation.curAnim.name != numToString[val])
		{
			if (glow)
			{
				animation.play(numToString[val], true, false, 0);
				glow = false;
			}
			else
				animation.play(numToString[val], true, false, 4);
			updateHitbox();
			centerOffsets(false);
		}

		return digit = val;
	}

	public function playAnim()
	{
		animation.play(numToString[digit], true, false, 0);
	}

	public var shuffleTimer:FlxTimer;
	public var finalTween:FlxTween;
	public var finalDelay:Float = 0;

	public var baseX:Float = 0;
	public var baseY:Float = 0;

	var numToString:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "DISABLED"];

	function finishShuffleTween()
	{
		finalTween = FlxTween.num(0.0, finalDigit, 23/24, {
			ease: FlxEase.quadOut,
			onComplete: function(input) {
				new FlxTimer().start(finalDelay / 24, function(tmr:FlxTimer) {
					animation.play(animation.curAnim.name, true, false, 0);
				});
			}
		}, function(x) {
			var digitRounded = Math.floor(x);
			digit = digitRounded;
		});
	}


	function shuffleProgress(shuffleTimer:FlxTimer):Void
	{
		var tempDigit:Int = digit;
		tempDigit += 1;
		if (tempDigit > 9) tempDigit = 0;
		if (tempDigit < 0) tempDigit = 0;
		digit = tempDigit;

		if (shuffleTimer.loops > 0 && shuffleTimer.loopsLeft == 0)
			finishShuffleTween();
	}

	public function shuffle()
	{
		var duration:Float = 41 / 24;
		var interval:Float = 1 / 24;
		shuffleTimer = new FlxTimer().start(interval, shuffleProgress, Std.int(duration / interval));
	}

	public function new(x:Float, y:Float)
	{
		super(x, y);

		baseX = x;
		baseY = y;

		frames = Paths.sparrow("ui/results/score-digital-numbers");

		for (i in 0...10)
		{
			var stringNum:String = numToString[i];
			animation.addByPrefix(stringNum, stringNum + " DIGITAL", 24, false);
		}

		animation.addByPrefix("DISABLED", "DISABLED", 24, false);
		animation.addByPrefix("GONE", "GONE", 24, false);

		this.digit = 10;

		animation.play(numToString[digit], true);

		updateHitbox();
	}
}

class ResultsClearPercentage extends FlxSpriteGroup
{
	public var curNumber(default, set):Int = 0;

	function set_curNumber(val:Int):Int
	{
		if (curNumber != val)
		{
			curNumber = val;
			drawNumbers();
		}
		return val;
	}

	var small:Bool = false;
	public var flashShader:ColorFade;

	override public function new(x:Float, y:Float, startingNumber:Int = 0, small:Bool = false)
	{
		super(x, y);

		flashShader = new ColorFade();

		this.small = small;

		var clearPercentText:FlxSprite = new FlxSprite(Paths.image("ui/results/clearPercent/clearPercentText" + (small ? "Small" : "")));
		clearPercentText.x = small ? 40 : 0;
		add(clearPercentText);

		curNumber = startingNumber;
	}

	function drawNumbers()
	{
		var seperatedScore:Array<Int> = [];
		var tempCombo:Int = Std.int(Math.round(curNumber));

		while (tempCombo > 0)
		{
			seperatedScore.unshift(tempCombo % 10);
			tempCombo = Std.int(Math.floor(tempCombo / 10));
		}

		if (seperatedScore.length == 0)
			seperatedScore.unshift(0);

		for (ind in 0...seperatedScore.length)
		{
			var num:Int = seperatedScore[ind];
			var digitIndex:Int = ind + 1;

			var digitOffset = (seperatedScore.length == 1) ? 1 : (seperatedScore.length == 3) ? -1 : 0;
			var digitSize = small ? 32 : 72;
			var digitHeightOffset = small ? -4 : 0;

			var xPos = (digitIndex - 1 + digitOffset) * (digitSize * this.scale.x);
			xPos += small ? -24 : 0;
			var yPos = (digitIndex - 1 + digitOffset) * (digitHeightOffset * this.scale.y);
			yPos += small ? 0 : 72;

			if (digitIndex >= members.length)
			{
				var variant:Bool = (seperatedScore.length == 3) ? (digitIndex >= 2) : (digitIndex >= 1);
				var numb:AnimatedSprite = new AnimatedSprite(xPos, yPos, Paths.sparrow("ui/results/clearPercent/clearPercentNumber" + (small ? "Small" : variant ? "Right" : "Left")));
				for (i in 0...10)
					numb.animation.addByPrefix(Std.string(i), "number " + Std.string(i) + " 0", 24, false);
				numb.animation.play(Std.string(num));
				numb.updateHitbox();

				numb.scale.set(this.scale.x, this.scale.y);
				numb.shader = flashShader;
				numb.visible = true;
				add(numb);
			}
			else
			{
				members[digitIndex].animation.play(Std.string(num));
				members[digitIndex].x = xPos + this.x;
				members[digitIndex].y = yPos + this.y;
				members[digitIndex].visible = true;
			}
		}

		for (ind in (seperatedScore.length + 1)...members.length)
			members[ind].visible = false;
	}
}

class ResultsState extends MusicBeatState
{
	static var ranks:Array<String> = ["SHIT", "GOOD", "GREAT", "EXCELLENT", "PERFECT", "PERFECT_GOLD"];

	public static var music:String = "results";

	public static var script:String = "ResultsState";

	public static var songNames:Array<String> = [];
	public static var artistNames:Array<String> = [];
	public static var sideName:String = "";
	public static var healthData:Array<Array<Array<Float>>> = [];
	public static var oldScore:ScoreData = null;

	var scores:ScoreSystems;
	var data:ResultsData;
	public static var compareRanks:Array<Int> = [];

	public static function resetStatics()
	{
		songNames = [];
		artistNames = [];
		healthData = [];
		script = "ResultsState";
	}

	override public function new(scores:ScoreSystems, data:ResultsData)
	{
		this.scores = scores;
		this.data = data;

		super();
	}

	override public function create()
	{
		super.create();

		openSubState(new ResultsSubState(scores, data));
	}

	public static function callResultsState(scores:ScoreSystems, data:ResultsData)
	{
		if (!Paths.hscriptExists(script) && Paths.hscriptExists("data/states/" + script))
			script = "data/states/" + script;

		var substateTest:HscriptHandler = new HscriptHandler(script);
		if (substateTest.getVar("isSubstate"))
		{
			FlxG.state.persistentUpdate = false;
			FlxG.state.openSubState(new ResultsSubState(scores, data));
		}
		else
		{
			MusicBeatState.doTransIn = false;
			FlxG.switchState(new ResultsState(scores, data));
		}
	}
}

class ResultsSubState extends MusicBeatSubState
{
	var myScript:HscriptHandler;

	var menuMusic:FlxSound = null;
	var nums:Array<Float> = [];
	var transitioning:Bool = false;

	var scores:ScoreSystems;
	var data:ResultsData;

	override public function new(scores:ScoreSystems, data:ResultsData)
	{
		this.scores = scores;
		this.data = data;

		super();

		if (PlayState.inStoryMode)
		{
			data.title = PlayState.storyWeekTitle;
			data.rating = ScoreSystems.ratingFromJudgements(ScoreSystems.weekJudgements);
		}
		else
		{
			data.title = ResultsState.songNames[0];
			if (ResultsState.artistNames[0] != "")
				data.title = Lang.get("#results.songNameAndArtist", [ResultsState.songNames[0], ResultsState.artistNames[0]]);

			data.rating = scores.rating;
		}

		data.songNames = ResultsState.songNames;
		data.artistNames = ResultsState.artistNames;
		data.difficulty = PlayState.difficulty;
		data.sideName = ResultsState.sideName;
		data.oldScore = ResultsState.oldScore;
		data.accuracy = scores.accuracy;

		if (PlayState.inStoryMode)
		{
			data.noteGraphData = ScoreSystems.resultsArray;
			nums = [ScoreSystems.weekScore, ScoreSystems.highestComboInWeek, ScoreSystems.weekSustains];
			data.judgements = ScoreSystems.weekJudgements;
		}
		else
		{
			data.noteGraphData = [scores.results];
			nums = [scores.score, scores.highestCombo, scores.sustains];
			data.judgements = scores.judgements;
		}

		var clear:Float = ScoreSystems.clearFromJudgements(data.judgements);
		data.score = {score: Std.int(nums[0]), clear: clear, rank: ScoreSystems.rankFromJudgements(data.judgements)};

		ResultsState.compareRanks = [ResultsState.oldScore.rank, data.score.rank];

		camera = new FlxCamera();
		camera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camera, false);

		if (!Paths.hscriptExists(ResultsState.script) && Paths.hscriptExists("data/states/" + ResultsState.script))
			ResultsState.script = "data/states/" + ResultsState.script;
		myScript = new HscriptHandler(ResultsState.script);
		myScript.setVar("this", this);
		myScript.setVar("HitGraph", HitGraph);
		myScript.setVar("HealthGraph", HealthGraph);
		myScript.setVar("ResultsNumber", ResultsNumber);
		myScript.setVar("ResultsPercentage", ResultsPercentage);
		myScript.setVar("ResultsScore", ResultsScore);
		myScript.setVar("ResultsClearPercentage", ResultsClearPercentage);
		myScript.execFunc("create", [data]);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		myScript.execFunc("update", [elapsed]);

		if (Options.keyJustPressed("ui_accept") && !transitioning)
		{
			transitioning = true;
			stopMusic();
			if (!PlayState.inStoryMode && ResultsState.compareRanks[1] > ResultsState.compareRanks[0])
			{
				var rankBg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				rankBg.alpha = 0;
				add(rankBg);
				FlxTween.tween(rankBg, {alpha: 1}, 0.5, {ease: FlxEase.expoOut, onComplete: function(twn:FlxTween) {
					if (menuMusic != null && menuMusic.playing)
						menuMusic.stop();
					MusicBeatState.doTransIn = false;
					MusicBeatState.doTransOut = false;
					PlayState.GotoMenu(false);
				}});
			}
			else
				PlayState.GotoMenu(true);
		}
	}

	function stopMusic()
	{
		if (menuMusic != null)
		{
			if (menuMusic.fadeTween != null)
				menuMusic.fadeTween.cancel();

			FlxTween.tween(menuMusic, {volume: 0}, 0.8);
			FlxTween.tween(menuMusic, {pitch: 3}, 0.1, {onComplete: function(twn) {
				FlxTween.tween(menuMusic, {pitch: 0.5}, 0.4, {onComplete: function(twn:FlxTween) {
					menuMusic.stop();
				}});
			}});
		}
	}
}