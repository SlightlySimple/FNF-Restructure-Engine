package data;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.tweens.FlxEase;
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

typedef ScoreData =
{
	var score:Int;
	var clear:Float;
	var rank:Int;
}

class ScoreSystems
{
	public static var save:FlxSave;

	public var notes:Array<Float> = [];
	public var sustainMS:Float = 0;
	public static var judgeMS:Array<Float> = [];
	static var rankThresholds:Array<Float> = [0, 0.6, 0.8, 0.9, 1];

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

	public static var songScores:Map<String, Map<String, Array<ScoreData>>>;
	public static var weekScores:Map<String, Map<String, ScoreData>>;
	public static var resultsArray:Array<PlayResults>;

	public function new()
	{
		results = { hitGraph: [], songLength: 0 };
		judgeMS = [Options.options.msMV, Options.options.msSK, Options.options.msGD, Options.options.msBD, Options.options.msSH];
		recalculateRating();
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
		recalculateAccuracy();
		recalculateScore();
		recalculateRating();
		if (ret >= 4)
			combo = 0;
		else
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
		notes.push(-judgeMS[4] * 2);
		judgeNote(-1);
		recalculateAccuracy();
		recalculateScore();
		recalculateRating();
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

	public function recalculateAccuracy()
	{
		var acc:Float = 0;
		for (note in notes)
			acc += 1 - (Math.abs(note) / judgeMS[4]);
		acc /= notes.length;
		if (acc > 0)
			accuracy = FlxEase.quadIn(FlxEase.sineInOut(acc)) * 100;
		else
			accuracy = acc * 100;
	}

	public function recalculateScore()
	{
		//score = (judgements[0] * 350) + (judgements[1] * 350) + (judgements[2] * 200) + (judgements[3] * 100) + (judgements[4] * 50) + (judgements[5] * -10);

		var fScore:Float = 0;
		for (note in notes)
		{
			if (note < -judgeMS[4])
				fScore -= 10;
			else
			{
				var absTiming:Float = Math.abs(note);

				if (absTiming < 5)
					fScore += 500;
				else
				{
					var factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-0.080 * (((absTiming / judgeMS[4]) * 160) - 54.99))));
					fScore += 500 * factor + 9;
				}
			}
		}
		fScore += (sustainMS / 1000) * 250;
		score = Std.int(Math.round(fScore));
	}

	public function recalculateRating()
	{
		rating = ratingFromJudgements(judgements);
	}

	public static function ratingFromJudgements(j:Array<Int>):String
	{
		if (j[4] + j[5] > 9)
			return "clear";
		if (j[4] + j[5] > 0)
			return "sdcb";
		if (j[3] > 0)
			return "fc";
		if (j[2] > 0)
			return "gfc";
		if (j[1] > 0)
			return "sfc";
		if (j[0] > 0)
			return "mfc";
		return "none";
	}

	public static function clearFromJudgements(j:Array<Int>):Float
	{
		return (j[0] + j[1] + j[2]) / (j[0] + j[1] + j[2] + j[3] + j[4] + j[5]);
	}

	public static function rankFromJudgements(j:Array<Int>):Int
	{
		var clear:Float = clearFromJudgements(j);
		if (clear == 1 && j[2] == 0)
			return 5;

		return rankFromClear(clear);
	}

	public static function rankFromClear(clear:Float):Int
	{
		var ret:Int = -1;
		if (clear > 0)
		{
			for (i in 0...rankThresholds.length)
			{
				if (clear >= rankThresholds[i])
					ret = i;
			}
		}
		return ret;
	}

	public function writeJudgementCounter():String
	{
		return Lang.get("#game.judgements", [Std.string(judgements[0]), Std.string(judgements[1]), Std.string(judgements[2]), Std.string(judgements[3]), Std.string(judgements[4]), Std.string(sustains), Std.string(judgements[5])]);
	}

	public static function initScores()
	{
		save = new FlxSave();
		save.bind("scores");

		if (save.data.songScores == null)
		{
			songScores = new Map<String, Map<String, Array<ScoreData>>>();
			save.data.songScores = songScores;
		}
		else
		{
			songScores = save.data.songScores;
			for (k in songScores.keys())
			{
				for (l in songScores[k].keys())
				{
					if (Std.isOfType(songScores[k][l][0], Int))
					{
						for (i in 0...songScores[k][l].length)
						{
							var oldScore:Int = cast songScores[k][l][i];
							songScores[k][l][i] = {score: oldScore, clear: 0, rank: -1};
						}
					}
				}
			}
		}

		if (save.data.weekScores == null)
		{
			weekScores = new Map<String, Map<String, ScoreData>>();
			save.data.weekScores = weekScores;
		}
		else
		{
			weekScores = save.data.weekScores;
			for (k in weekScores.keys())
			{
				for (l in weekScores[k].keys())
				{
					if (Std.isOfType(weekScores[k][l], Int))
					{
						var oldScore:Int = cast weekScores[k][l];
						weekScores[k][l] = {score: oldScore, clear: 0.0, rank: -1};
					}
				}
			}
		}

		save.flush();
	}

	public static function saveSongScore(song:String, difficulty:String, score:Int, ?songScoreIndex:Int = 0)
	{
		if (!songScores.exists(song.toLowerCase()))
			songScores.set(song.toLowerCase(), new Map<String, Array<ScoreData>>());

		var songScoreMap:Map<String, Array<ScoreData>> = songScores[song.toLowerCase()];

		if (!songScoreMap.exists(difficulty.toLowerCase()))
			songScoreMap[difficulty.toLowerCase()] = [];
		while (songScoreMap[difficulty.toLowerCase()].length < songScoreIndex + 1)
			songScoreMap[difficulty.toLowerCase()].push({score: 0, clear: 0, rank: -1});

		if (songScoreMap[difficulty.toLowerCase()][songScoreIndex].score < score)
			songScoreMap[difficulty.toLowerCase()][songScoreIndex].score = score;
		save.data.songScores = songScores;
		save.flush();
	}

	public static function loadSongScore(song:String, difficulty:String, ?songScoreIndex:Int = 0):Int
	{
		if (songScores.exists(song.toLowerCase()))
		{
			var songScoreMap:Map<String, Array<ScoreData>> = songScores[song.toLowerCase()];
			if (songScoreMap.exists(difficulty.toLowerCase()))
			{
				if (songScoreMap[difficulty.toLowerCase()].length > songScoreIndex)
					return songScoreMap[difficulty.toLowerCase()][songScoreIndex].score;
			}
		}
		return 0;
	}

	public static function resetSongScore(song:String, difficulty:String, ?songScoreIndex:Int = 0)
	{
		if (songScores.exists(song.toLowerCase()))
		{
			var songScoreMap:Map<String, Array<ScoreData>> = songScores[song.toLowerCase()];
			if (songScoreMap.exists(difficulty.toLowerCase()))
			{
				if (songScoreMap[difficulty.toLowerCase()].length > songScoreIndex)
					songScoreMap[difficulty.toLowerCase()][songScoreIndex] = {score: 0, clear: 0, rank: -1};
			}
		}
		save.flush();
	}

	public static function saveSongScoreData(song:String, difficulty:String, scoreData:ScoreData, ?songScoreIndex:Int = 0)
	{
		if (!songScores.exists(song.toLowerCase()))
			songScores.set(song.toLowerCase(), new Map<String, Array<ScoreData>>());

		var songScoreMap:Map<String, Array<ScoreData>> = songScores[song.toLowerCase()];

		if (!songScoreMap.exists(difficulty.toLowerCase()))
			songScoreMap[difficulty.toLowerCase()] = [];
		while (songScoreMap[difficulty.toLowerCase()].length < songScoreIndex + 1)
			songScoreMap[difficulty.toLowerCase()].push({score: 0, clear: 0, rank: -1});

		if (songScoreMap[difficulty.toLowerCase()][songScoreIndex].score < scoreData.score)
			songScoreMap[difficulty.toLowerCase()][songScoreIndex].score = scoreData.score;

		if (songScoreMap[difficulty.toLowerCase()][songScoreIndex].clear < scoreData.clear)
			songScoreMap[difficulty.toLowerCase()][songScoreIndex].clear = scoreData.clear;

		if (songScoreMap[difficulty.toLowerCase()][songScoreIndex].rank < scoreData.rank)
			songScoreMap[difficulty.toLowerCase()][songScoreIndex].rank = scoreData.rank;

		save.data.songScores = songScores;
		save.flush();
	}

	public static function loadSongScoreData(song:String, difficulty:String, ?songScoreIndex:Int = 0):ScoreData
	{
		if (songScores.exists(song.toLowerCase()))
		{
			var songScoreMap:Map<String, Array<ScoreData>> = songScores[song.toLowerCase()];
			if (songScoreMap.exists(difficulty.toLowerCase()))
			{
				if (songScoreMap[difficulty.toLowerCase()].length > songScoreIndex)
					return Reflect.copy(songScoreMap[difficulty.toLowerCase()][songScoreIndex]);		// It has to be a copy because this is used for the results screen and freeplay menu to find out what the old score was
			}
		}
		return {score: 0, clear: 0, rank: -1};
	}

	public static function saveWeekScore(week:String, difficulty:String)
	{
		if (!weekScores.exists(week.toLowerCase()))
			weekScores.set(week.toLowerCase(), new Map<String, ScoreData>());

		var weekScoreMap:Map<String, ScoreData> = weekScores[week.toLowerCase()];
		if (weekScoreMap.exists(difficulty.toLowerCase()))
		{
			if (weekScoreMap[difficulty.toLowerCase()].score < weekScore)
				weekScoreMap[difficulty.toLowerCase()].score = weekScore;
		}
		else
			weekScoreMap[difficulty.toLowerCase()] = {score: weekScore, clear: 0.0, rank: -1};
		save.data.weekScores = weekScores;
		save.flush();
	}

	public static function loadWeekScore(week:String, difficulty:String):Int
	{
		if (weekScores.exists(week.toLowerCase()))
		{
			if (weekScores[week.toLowerCase()].exists(difficulty.toLowerCase()))
				return weekScores[week.toLowerCase()][difficulty.toLowerCase()].score;
		}
		return 0;
	}

	public static function resetWeekScore(week:String, difficulty:String)
	{
		if (weekScores.exists(week.toLowerCase()))
		{
			var weekScoreMap:Map<String, ScoreData> = weekScores[week.toLowerCase()];
			if (weekScoreMap.exists(difficulty.toLowerCase()))
				weekScoreMap.remove(difficulty.toLowerCase());
		}
		save.data.weekScores = weekScores;
		save.flush();
	}

	public static function songBeaten(song:String, ?difficulties:Array<String> = null):Bool
	{
		if (songScores.exists(song.toLowerCase()))
		{
			if (difficulties == null)
			{
				for (diff in songScores[song.toLowerCase()].keys())
				{
					for (side in songScores[song.toLowerCase()][diff])
					{
						if (side.score > 0)
							return true;
					}
				}
			}
			else
			{
				for (diff in difficulties)
				{
					if (songScores[song.toLowerCase()].exists(diff))
					{
						for (side in songScores[song.toLowerCase()][diff])
						{
							if (side.score > 0)
								return true;
						}
					}
				}
			}
		}
		return false;
	}

	public static function weekBeaten(week:String, ?difficulties:Array<String> = null):Bool
	{
		if (weekScores.exists(week.toLowerCase()))
		{
			if (difficulties == null)
			{
				for (diff in weekScores[week.toLowerCase()].keys())
				{
					if (weekScores[week.toLowerCase()][diff].score > 0)
						return true;
				}
			}
			else
			{
				for (diff in difficulties)
				{
					if (weekScores[week.toLowerCase()].exists(diff) && weekScores[week.toLowerCase()][diff].score > 0)
						return true;
				}
			}
		}
		return false;
	}
}