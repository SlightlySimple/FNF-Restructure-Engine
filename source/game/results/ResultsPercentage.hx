package game.results;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import objects.AnimatedSprite;

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