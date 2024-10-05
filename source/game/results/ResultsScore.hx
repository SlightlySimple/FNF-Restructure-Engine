package game.results;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;

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