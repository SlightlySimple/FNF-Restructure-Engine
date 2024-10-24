package game.results;

import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

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
		finalTween = FlxTween.num(0.0, finalDigit, 23/24, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
				new FlxTimer().start(finalDelay / 24, function(tmr:FlxTimer) {
					animation.play(animation.curAnim.name, true, false, 0);
				});
			}
		}, function(x) {
			var digitRounded = Math.floor(x);
			digit = digitRounded;
		});
	}


	function shuffleProgress(shuffleTimer:FlxTimer)
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