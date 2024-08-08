package menus.freeplay;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

import objects.AnimatedSprite;

class FreeplayClear extends FlxSpriteGroup
{
	public var percentage:Float = 0;
	var displayClear(default, set):Float = -1;

	override public function new(x:Float, y:Float)
	{
		super(x, y);

		var clearBoxSprite:FlxSprite = new FlxSprite(Paths.image("ui/freeplay/clearBox"));
		clearBoxSprite.active = false;
		add(clearBoxSprite);

		displayClear = 0;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (percentage != displayClear)
		{
			displayClear = FlxMath.lerp(displayClear, percentage, 1 - Math.pow(1 / 100, elapsed / 0.5));
			if (Math.abs(percentage - displayClear) < 1)
				displayClear = percentage;
		}
	}

	function set_displayClear(val:Float):Float
	{
		if (Math.floor(displayClear) != Math.floor(val))
		{
			var flooredVal:Int = Std.int(Math.floor(val));
			var digits:Array<Int> = [];
			while (flooredVal > 0)
			{
				digits.push(flooredVal % 10);
				flooredVal = Std.int(Math.floor(flooredVal / 10));
			}
			if (digits.length <= 0)
				digits = [0];

			if (digits.length > members.length - 1)
			{
				while (digits.length > members.length - 1)
				{
					var num:AnimatedSprite = new AnimatedSprite(Paths.sparrow("ui/freeplay/freeplay-clear"));
					for (i in 0...10)
						num.addAnim(Std.string(i), Std.string(i), 24, true);
					add(num);
				}
			}

			if (digits.length < members.length - 1)
			{
				for (i in (digits.length + 1)...members.length)
					members[i].alpha = 0;
			}

			var xx:Float = x + 68;
			for (i in 0...digits.length)
			{
				var num:FlxSprite = members[i + 1];
				num.alpha = 1;
				num.setPosition(xx, y + 46);
				num.animation.play(Std.string(digits[i]));
				num.updateHitbox();
				num.x -= num.width;
				num.y -= num.height;
				xx -= num.width;
			}
		}

		return displayClear = val;
	}
}