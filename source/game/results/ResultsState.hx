package game.results;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import data.Options;
import data.ScoreSystems;
import scripting.HscriptHandler;
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

class ResultsState extends MusicBeatState
{
	static var ranks:Array<String> = ["SHIT", "GOOD", "GREAT", "EXCELLENT", "PERFECT", "PERFECT_GOLD"];

	public static var music:String = "results/results";

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
	var stickerTransition:Bool = true;

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

		PlayState.charactersToUnlock = PlayState.charactersToUnlock.filter(function(c:String) { return !FlxG.save.data.unlockedCharacters.contains(c); });
		if ((!PlayState.inStoryMode && ResultsState.compareRanks[1] > ResultsState.compareRanks[0]) || PlayState.charactersToUnlock.length > 0)
			stickerTransition = false;

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
			if (stickerTransition)
				PlayState.GotoMenu(true);
			else
			{
				var rankBg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				rankBg.alpha = 0;
				add(rankBg);
				FlxTween.tween(rankBg, {alpha: 1}, 0.5, {ease: FlxEase.expoOut, onComplete: function(twn:FlxTween) {
					if (menuMusic != null && menuMusic.playing)
						menuMusic.stop();
					MusicBeatState.doTransIn = false;
					MusicBeatState.doTransOut = false;
					if (PlayState.charactersToUnlock.length > 0)
						CharacterUnlockState.unlockCharacter();
					else
						PlayState.GotoMenu(false);
				}});
			}
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