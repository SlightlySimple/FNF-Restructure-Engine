package data;

import flixel.FlxG;
import flixel.util.FlxSave;
import game.PlayState;

using StringTools;

typedef HitNotes =
{
	var time:Float;
	var offset:Float;
	var judgement:Int;
}

typedef PlayResults =
{
	var hitGraph:Array<HitNotes>;
	var songLength:Float;
}

class ScoreSystems
{
	public static var save:FlxSave;

	public var notes:Array<Float> = [];
	public static var judgeMS:Array<Float> = [];

	public var judgements:Array<Int> = [0, 0, 0, 0, 0, 0];
	public var sustains:Int = 0;
	public var score:Int = 0;
	public var accuracy:Float = 0;
	public var rating:String = "";

	public static var weekJudgements:Array<Int> = [0, 0, 0, 0, 0, 0];
	public static var weekSustains:Int = 0;
	public static var weekScore:Int = 0;
	public static var highestComboInWeek:Int = 0;

	public var combo:Int = 0;
	public var highestCombo:Int = 0;
	public var nps:Int = 0;
	public var maxNps:Int = 0;
	public var npsNotes:Array<Float> = [];

	public var results:PlayResults;

	public static var songScores:Map<String, Map<String, Array<Int>>>;
	public static var weekScores:Map<String, Map<String, Int>>;
	public static var resultsArray:Array<PlayResults>;

	public function new()
	{
		results = { hitGraph: [], songLength: 0 };
		judgeMS = [Options.options.msMV, Options.options.msSK, Options.options.msGD, Options.options.msBD, Options.options.msSH];
		recalculcateRating();
	}

	public function update(elapsed:Float)
	{
		var poppers:Array<Int> = [];
		for (i in 0...npsNotes.length)
		{
			if (npsNotes[i] <= (Conductor.songPosition / PlayState.instance.playbackRate))
				poppers.push(i);
		}

		for (p in poppers)
			npsNotes.splice(p, 1);
	}

	public static function resetWeekData()
	{
		weekJudgements = [0, 0, 0, 0, 0, 0];
		weekSustains = 0;
		weekScore = 0;
		highestComboInWeek = 0;
		resultsArray = [];
	}

	public static function onWeekSongBeaten(scores:ScoreSystems)
	{
		for (i in 0...weekJudgements.length)
			weekJudgements[i] += scores.judgements[i];
		weekSustains += scores.sustains;
		weekScore += scores.score;
		if (scores.highestCombo > highestComboInWeek)
			highestComboInWeek = scores.highestCombo;

		resultsArray.push(scores.results);
	}

	public function hitNote(time:Float, offset:Float):Int
	{
		notes.push(offset);
		npsNotes.push((Conductor.songPosition / PlayState.instance.playbackRate) + 1000);
		var ret:Int = judgeNote(Math.abs(offset));
		recalculcateAccuracy();
		recalculcateScore();
		recalculcateRating();
		combo++;
		if (highestCombo < combo)
			highestCombo = combo;

		results.hitGraph.push({time: time, offset: offset, judgement: ret});

		nps = npsNotes.length;
		if (nps > maxNps)
			maxNps = nps;

		return ret;
	}

	public function missNote(time:Float)
	{
		notes.push(-360);
		judgeNote(-1);
		recalculcateAccuracy();
		recalculcateScore();
		recalculcateRating();
		combo = 0;

		if (time != -1)
			results.hitGraph.push({time: time, offset: -judgeMS[4], judgement: 5});

		nps = npsNotes.length;
		if (nps > maxNps)
			maxNps = nps;
	}

	public function judgeNote(offset:Float):Int
	{
		var rating:Int = justJudgeNote(offset);

		judgements[rating]++;
		return rating;
	}

	public function justJudgeNote(offset:Float):Int
	{
		var rating:Int = 4;
		if (offset < 0)
			rating = 5;
		else if (offset <= judgeMS[0])
			rating = 0;
		else if (offset <= judgeMS[1])
			rating = 1;
		else if (offset <= judgeMS[2])
			rating = 2;
		else if (offset <= judgeMS[3])
			rating = 3;

		return rating;
	}

	public function recalculcateAccuracy()
	{
		var acc:Float = 0;
		for (i in 0...notes.length)
			acc += 1 - (Math.abs(notes[i]) / judgeMS[4]);
		acc /= notes.length;
		accuracy = acc * 100;
	}

	public function recalculcateScore()
	{
		score = (judgements[0] * 350) + (judgements[1] * 350) + (judgements[2] * 200) + (judgements[3] * 100) + (judgements[4] * 50) + (judgements[5] * -10);
	}

	public function recalculcateRating()
	{
		rating = ratingFromJudgements(judgements);
	}

	public static function ratingFromJudgements(j:Array<Int>):String
	{
		if (j[5] > 9)
			return Lang.get("#clear");
		if (j[5] > 0)
			return Lang.get("#sdcb");
		if (j[3] > 0 || j[4] > 0)
			return Lang.get("#fc");
		if (j[2] > 0)
			return Lang.get("#gfc");
		if (j[1] > 0)
			return Lang.get("#sfc");
		if (j[0] > 0)
			return Lang.get("#mfc");
		return Lang.get("#noRating");
	}

	public function writeJudgementCounter():String
	{
		return Lang.get("#judgements", [Std.string(judgements[0]), Std.string(judgements[1]), Std.string(judgements[2]), Std.string(judgements[3]), Std.string(judgements[4]), Std.string(sustains), Std.string(judgements[5])]);
	}

	public static function initScores()
	{
		save = new FlxSave();
		save.bind("scores");

		if (save.data.songScores == null)
		{
			songScores = new Map<String, Map<String, Array<Int>>>();
			save.data.songScores = songScores;
		}
		else
			songScores = save.data.songScores;

		if (save.data.weekScores == null)
		{
			weekScores = new Map<String, Map<String, Int>>();
			save.data.weekScores = weekScores;
		}
		else
			weekScores = save.data.weekScores;

		save.flush();
	}

	public static function saveSongScore(song:String, difficulty:String, score:Int, ?songScoreIndex:Int = 0)
	{
		if (!songScores.exists(song.toLowerCase()))
			songScores.set(song.toLowerCase(), new Map<String, Array<Int>>());

		var songScoreMap:Map<String, Array<Int>> = songScores[song.toLowerCase()];

		if (!songScoreMap.exists(difficulty.toLowerCase()))
			songScoreMap[difficulty.toLowerCase()] = [];
		while (songScoreMap[difficulty.toLowerCase()].length < songScoreIndex + 1)
			songScoreMap[difficulty.toLowerCase()].push(0);

		if (songScoreMap[difficulty.toLowerCase()][songScoreIndex] < score)
			songScoreMap[difficulty.toLowerCase()][songScoreIndex] = score;
		save.data.songScores = songScores;
		save.flush();
	}

	public static function loadSongScore(song:String, difficulty:String, ?songScoreIndex:Int = 0):Int
	{
		if (songScores.exists(song.toLowerCase()))
		{
			var songScoreMap:Map<String, Array<Int>> = songScores[song.toLowerCase()];
			if (songScoreMap.exists(difficulty.toLowerCase()))
			{
				if (songScoreMap[difficulty.toLowerCase()].length > songScoreIndex)
					return songScoreMap[difficulty.toLowerCase()][songScoreIndex];
			}
		}
		return 0;
	}

	public static function resetSongScore(song:String, difficulty:String, ?songScoreIndex:Int = 0)
	{
		if (songScores.exists(song.toLowerCase()))
		{
			var songScoreMap:Map<String, Array<Int>> = songScores[song.toLowerCase()];
			if (songScoreMap.exists(difficulty.toLowerCase()))
			{
				if (songScoreMap[difficulty.toLowerCase()].length > songScoreIndex)
					songScoreMap[difficulty.toLowerCase()][songScoreIndex] = 0;
			}
		}
		save.flush();
	}

	public static function saveWeekScore(week:String, difficulty:String)
	{
		if (!weekScores.exists(week.toLowerCase()))
			weekScores.set(week.toLowerCase(), new Map<String, Int>());

		var weekScoreMap:Map<String, Int> = weekScores.get(week.toLowerCase());
		if (weekScoreMap.exists(difficulty.toLowerCase()))
		{
			if (weekScoreMap.get(difficulty.toLowerCase()) < weekScore)
				weekScoreMap.set(difficulty.toLowerCase(), weekScore);
		}
		else
			weekScoreMap.set(difficulty.toLowerCase(), weekScore);
		save.data.weekScores = weekScores;
		save.flush();
	}

	public static function loadWeekScore(week:String, difficulty:String):Int
	{
		if (weekScores.exists(week.toLowerCase()))
		{
			if (weekScores.get(week.toLowerCase()).exists(difficulty.toLowerCase()))
				return weekScores.get(week.toLowerCase()).get(difficulty.toLowerCase());
		}
		return 0;
	}

	public static function resetWeekScore(week:String, difficulty:String)
	{
		if (weekScores.exists(week.toLowerCase()))
		{
			var weekScoreMap:Map<String, Int> = weekScores.get(week.toLowerCase());
			if (weekScoreMap.exists(difficulty.toLowerCase()))
				weekScoreMap.remove(difficulty.toLowerCase());
		}
		save.data.weekScores = weekScores;
		save.flush();
	}
}