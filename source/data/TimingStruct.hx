package data;

import flixel.FlxG;
import flixel.util.FlxSort;

typedef StructTiming =
{
	var startTime:Float;
	var startBeat:Float;
	var bpm:Float;
}

class TimingStruct
{
	public var timingStruct:Array<StructTiming> = [{startTime: 0, startBeat: 0, bpm: 0}];

	public function new()
	{
	}

	public function setBPM(newBPM:Float)
	{
		timingStruct = [{startTime: 0, startBeat: 0, bpm: newBPM}];
	}

	function sortTimingStruct(Obj1:StructTiming, Obj2:StructTiming):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.startBeat, Obj2.startBeat);
	}

	public function recalculateTimings(timings:Array<Array<Float>>)
	{
		timingStruct = [];
		var latestBeat:Int = 0;
		for (t in timings)
		{
			timingStruct.push({startTime: 0, startBeat: t[0], bpm: t[1]});
			if (t[0] > latestBeat)
				latestBeat = Std.int(t[0]);
		}

		timingStruct.sort(sortTimingStruct);

		if (latestBeat > 0)
		{
			var totalTime:Float = 0;
			var timingIncrement:Float = 0;
			var prevStartBeat:Float = 0;
			for (t in 0...timingStruct.length)
			{
				totalTime += timingIncrement * (timingStruct[t].startBeat - prevStartBeat);
				timingStruct[t].startTime = totalTime;
				timingIncrement = 1000 / ( timingStruct[t].bpm / 60 );
				prevStartBeat = timingStruct[t].startBeat;
			}
		}
	}

	public function beatFromTime(time:Float, ?actingTime:Float = 0):Float
	{
		var trueActingTime:Float = time;
		if (actingTime != 0)
			trueActingTime = actingTime;
		var myT:StructTiming = timingStruct[0];
		for (t in timingStruct)
		{
			if (trueActingTime >= t.startTime)
				myT = t;
		}
		var beatsFromTiming:Float = time - myT.startTime;
		beatsFromTiming /= 1000;
		beatsFromTiming *= myT.bpm / 60;
		beatsFromTiming *= 192;
		beatsFromTiming = Math.round(beatsFromTiming);
		beatsFromTiming /= 192;
		return beatsFromTiming + myT.startBeat;
	}

	public function timeFromBeat(beat:Float):Float
	{
		var myT:StructTiming = timingStruct[0];
		for (t in timingStruct)
		{
			if (beat >= t.startBeat)
				myT = t;
		}
		var timeFromTiming:Float = beat - myT.startBeat;
		timeFromTiming /= myT.bpm / 60;
		timeFromTiming *= 1000;
		return timeFromTiming + myT.startTime;
	}

	public function stepFromTime(time:Float):Float
	{
		return beatFromTime(time) * 4;
	}

	public function timeFromStep(step:Float):Float
	{
		return timeFromBeat(step / 4);
	}
}