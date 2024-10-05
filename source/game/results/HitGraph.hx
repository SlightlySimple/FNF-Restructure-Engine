package game.results;

import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import data.Options;
import data.ScoreSystems;

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