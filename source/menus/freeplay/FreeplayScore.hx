package menus.freeplay;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

import objects.AnimatedSprite;

class FreeplayScore extends FlxTypedSpriteGroup<AnimatedSprite>
{
	public var score:Int = 0;
	var displayScore(default, set):Float = 0;

	static var numberAnims:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"];

	public override function new(x:Float, y:Float, digitCount:Int, ?asset:String = "ui/freeplay/characters/bf/digital_numbers")
	{
		super(x, y);

		for (i in 0...digitCount)
		{
			var num:AnimatedSprite = new AnimatedSprite(45 * i, 0, Paths.sparrow(asset));
			for (i in 0...numberAnims.length)
				num.addAnim(Std.string(i), numberAnims[i], 24, false);
			num.playAnim("0");
			num.scale.set(0.4, 0.4);
			num.updateHitbox();
			add(num);
		}
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (score != displayScore)
		{
			displayScore = FlxMath.lerp(displayScore, score, 1 - Math.pow(1 / 100, elapsed / 0.5));
			if (Math.abs(score - displayScore) < 10)
				displayScore = score;
		}
	}

	function set_displayScore(val:Float):Float
	{
		if (Math.round(val) != Math.round(displayScore))
		{
			var nums:Array<Int> = [];
			var numSplit:Int = Std.int(Math.round(val));

			while (numSplit > 0)
			{
				nums.unshift(numSplit % 10);
				numSplit = Std.int(Math.floor(numSplit / 10));
			}

			while (nums.length < members.length)
				nums.unshift(0);

			while (nums.length > members.length)
				nums.shift();

			for (i in 0...nums.length)
			{
				if (members[i].animation.curAnim.name != Std.string(nums[i]))
				{
					members[i].playAnim(Std.string(nums[i]));
					members[i].updateHitbox();
					if (nums[i] == 1)
						members[i].offset.x -= 15;
				}
			}
		}
		return displayScore = val;
	}
}