package;

import flixel.FlxG;
import flixel.util.FlxSort;
import data.TimingStruct;
import game.PlayState;

class Conductor
{
	public static var bpm:Float = 0;
	public static var timingStruct:TimingStruct = new TimingStruct();

	public static var stepLength:Float = 0;
	public static var beatLength:Float = 0;
	public static var stepSeconds:Float = 0;
	public static var beatSeconds:Float = 0;
	public static var songPosition:Float = 0;
	public static var overrideSongPosition:Bool = false;

	public static function setBPM(newBPM:Float)
	{
		timingStruct.setBPM(newBPM);
		bpm = newBPM;
		beatLength = 1000 / ( bpm / 60 );
		stepLength = beatLength / 4;
		beatSeconds = beatLength / 1000.0;
		stepSeconds = stepLength / 1000.0;
	}

	public static function playMusic(song:String, ?volume:Float = 1)
	{
		FlxG.sound.playMusic(Paths.music(song), volume);
		songPosition = 0;
		overrideSongPosition = false;
		if (Paths.exists("music/" + song + ".bpm"))
			setBPM(Std.parseFloat(Paths.raw("music/" + song + ".bpm")));
	}

	public static function recalculateTimings(timings:Array<Array<Float>>)
	{
		timingStruct.recalculateTimings(timings);

		bpm = timingStruct.timingStruct[0].bpm;
		beatLength = 1000 / ( bpm / 60 );
		stepLength = beatLength / 4;
		beatSeconds = beatLength / 1000.0;
		stepSeconds = stepLength / 1000.0;
	}

	public static function recalculateBPM()
	{
		if (songPosition >= 0)
		{
			for (t in timingStruct.timingStruct)
			{
				if (t.startTime <= songPosition && t.bpm != bpm)
				{
					bpm = t.bpm;
					beatLength = 1000 / ( bpm / 60 );
					stepLength = beatLength / 4;
					beatSeconds = beatLength / 1000.0;
					stepSeconds = stepLength / 1000.0;
				}
			}
		}
		else
		{
			if (timingStruct.timingStruct[0].bpm != bpm)
			{
				bpm = timingStruct.timingStruct[0].bpm;
				beatLength = 1000 / ( bpm / 60 );
				stepLength = beatLength / 4;
				beatSeconds = beatLength / 1000.0;
				stepSeconds = stepLength / 1000.0;
			}
		}
	}

	public static function update(elapsed:Float)
	{
		if (!overrideSongPosition)
		{
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
				Conductor.songPosition = FlxG.sound.music.time;
			else
				songPosition += elapsed * 1000;
		}

		recalculateBPM();
	}

	public static function beatFromTime(time:Float):Float
	{
		return timingStruct.beatFromTime(time);
	}

	public static function timeFromBeat(beat:Float):Float
	{
		return timingStruct.timeFromBeat(beat);
	}

	public static function stepFromTime(time:Float):Float
	{
		return timingStruct.stepFromTime(time);
	}

	public static function timeFromStep(step:Float):Float
	{
		return timingStruct.timeFromStep(step);
	}
}