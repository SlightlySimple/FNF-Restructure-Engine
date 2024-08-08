package menus.freeplay;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flxanimate.FlxAnimate;

import objects.AnimatedSprite;

class FreeplayDifficultyStars extends FlxSpriteGroup
{
	public var difficulty(default, set):Int = -1;

	var stars:FlxAnimate;
	var flames:FlxTypedSpriteGroup<AnimatedSprite>;

	override public function new(x:Float, y:Float)
	{
		super(x, y);

		flames = new FlxTypedSpriteGroup<AnimatedSprite>();
		for (i in 0...5)
		{
			var flame:AnimatedSprite = new AnimatedSprite(917 + (i * 29) - x, 103 + (i * 6) - y, Paths.sparrow("ui/freeplay/freeplayFlame"));
			flame.addAnim("flame", "fire loop full instance 1", FlxG.random.int(23, 25), false);
			flame.playAnim("flame");
			flame.visible = false;

			flame.animation.finishCallback = function(anim:String) { flame.animation.play("flame", true, false, 2); };
			flames.add(flame);
		}
		add(flames);

		stars = new FlxAnimate(497.25, 320.95, Paths.atlas("ui/freeplay/freeplayStars"));
		for (i in 0...15)
			stars.anim.addByAnimIndices(Std.string(i + 1), Util.generateIndices(i * 100, (i * 100) + 99), 24);
		stars.anim.addByAnimIndices("0", [1500], 24);
		stars.playAnim("0", true, true);
		stars.visible = false;
		add(stars);
	}

	public function set_difficulty(val:Int):Int
	{
		if (val != difficulty)
		{
			if (val >= 0)
			{
				stars.visible = true;
				stars.playAnim(Std.string(Math.min(15, val)), true, true);
				var flameCount:Int = Std.int(Math.max(0, Math.min(5, val - 10)));
				if (flameCount > 0)
				{
					for (i in 0...flameCount)
					{
						if (!flames.members[i].visible)
						{
							flames.members[i].visible = true;
							flames.members[i].playAnim("flame", true);
						}
					}
					for (i in flameCount...flames.members.length)
						flames.members[i].visible = false;
				}
				else
					flames.forEachAlive(function(flame:AnimatedSprite) { flame.visible = false; });
			}
			else
			{
				stars.visible = false;
				flames.forEachAlive(function(flame:AnimatedSprite) { flame.visible = false; });
			}
		}

		return difficulty = val;
	}
}