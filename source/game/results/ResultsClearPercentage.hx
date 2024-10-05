package game.results;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import objects.AnimatedSprite;
import shaders.ColorFade;

class ResultsClearPercentage extends FlxSpriteGroup
{
	public var curNumber(default, set):Int = 0;

	function set_curNumber(val:Int):Int
	{
		if (curNumber != val)
		{
			curNumber = val;
			drawNumbers();
		}
		return val;
	}

	var small:Bool = false;
	public var flashShader:ColorFade;

	override public function new(x:Float, y:Float, startingNumber:Int = 0, small:Bool = false)
	{
		super(x, y);

		flashShader = new ColorFade();

		this.small = small;

		var clearPercentText:FlxSprite = new FlxSprite(Paths.image("ui/results/clearPercent/clearPercentText" + (small ? "Small" : "")));
		clearPercentText.x = small ? 40 : 0;
		add(clearPercentText);

		curNumber = startingNumber;
	}

	function drawNumbers()
	{
		var seperatedScore:Array<Int> = [];
		var tempCombo:Int = Std.int(Math.round(curNumber));

		while (tempCombo > 0)
		{
			seperatedScore.unshift(tempCombo % 10);
			tempCombo = Std.int(Math.floor(tempCombo / 10));
		}

		if (seperatedScore.length == 0)
			seperatedScore.unshift(0);

		for (ind in 0...seperatedScore.length)
		{
			var num:Int = seperatedScore[ind];
			var digitIndex:Int = ind + 1;

			var digitOffset = (seperatedScore.length == 1) ? 1 : (seperatedScore.length == 3) ? -1 : 0;
			var digitSize = small ? 32 : 72;
			var digitHeightOffset = small ? -4 : 0;

			var xPos = (digitIndex - 1 + digitOffset) * (digitSize * this.scale.x);
			xPos += small ? -24 : 0;
			var yPos = (digitIndex - 1 + digitOffset) * (digitHeightOffset * this.scale.y);
			yPos += small ? 0 : 72;

			if (digitIndex >= members.length)
			{
				var variant:Bool = (seperatedScore.length == 3) ? (digitIndex >= 2) : (digitIndex >= 1);
				var numb:AnimatedSprite = new AnimatedSprite(xPos, yPos, Paths.sparrow("ui/results/clearPercent/clearPercentNumber" + (small ? "Small" : variant ? "Right" : "Left")));
				for (i in 0...10)
					numb.animation.addByPrefix(Std.string(i), "number " + Std.string(i) + " 0", 24, false);
				numb.animation.play(Std.string(num));
				numb.updateHitbox();

				numb.scale.set(this.scale.x, this.scale.y);
				numb.shader = flashShader;
				numb.visible = true;
				add(numb);
			}
			else
			{
				members[digitIndex].animation.play(Std.string(num));
				members[digitIndex].x = xPos + this.x;
				members[digitIndex].y = yPos + this.y;
				members[digitIndex].visible = true;
			}
		}

		for (ind in (seperatedScore.length + 1)...members.length)
			members[ind].visible = false;
	}
}