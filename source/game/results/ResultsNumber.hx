package game.results;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import objects.AnimatedSprite;

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

		for (i in 0...members.length)
		{
			if (i >= digits.length)
				members[i].visible = false;
			else
			{
				members[i].visible = true;
				members[i].playAnim(Std.string(digits[i]));
			}
		}
	}
}