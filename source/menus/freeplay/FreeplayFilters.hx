package menus.freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import flxanimate.FlxAnimate;

import data.Options;

class FreeplayFilters extends FlxSpriteGroup
{
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var letters:Array<FlxAnimate> = [];
	var letterAnims:Array<String> = ["ALL", "AB", "CD", "EH", "IL", "MN", "OR", "S", "T", "UZ", "#"];
	var positions:Array<Float> = [-10, -22, 2, 0];
	var index:Int = 0;

	public var onChanged:String->Void = null;
	public var locked:Bool = false;

	override public function new(x:Float, y:Float)
	{
		super(x, y);

		for (i in 0...5)
		{
			var letter:FlxAnimate = new FlxAnimate(i * 80, 0, Paths.atlas("ui/freeplay/sortedLetters"));
			letter.x += 50;
			letter.y += 50;
			for (a in letterAnims)
				letter.anim.addBySymbol(a, a + " move", 0, 0, 24);
			add(letter);

			letters.push(letter);

			if (i != 2)
				letter.scale.set(0.8, 0.8);

			var darkness:Float = Math.abs(i - 2) / 6;

			letter.color = letter.color.getDarkened(darkness);

			if (i < 4)
			{
				var sep:FlxSprite = new FlxSprite((i * 80) + 60, 20, Paths.image("ui/freeplay/seperator"));
				sep.color = letter.color.getDarkened(darkness);
				add(sep);
			}
		}

		leftArrow = new FlxSprite(-20, 15, Paths.image("ui/freeplay/miniArrow"));
		leftArrow.flipX = true;
		add(leftArrow);

		rightArrow = new FlxSprite(380, 15, Paths.image("ui/freeplay/miniArrow"));
		add(rightArrow);

		changeSelection();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (locked) return;

		if (Options.keyJustPressed("filter_right"))
			changeSelection(1);

		if (Options.keyJustPressed("filter_left"))
			changeSelection(-1);
	}

	function changeSelection(?val:Int = 0)
	{
		FlxG.sound.play(Paths.sound("ui/scrollMenu"), 0.5);

		index = Util.loop(index + val, 0, letterAnims.length - 1);
		for (i in 0...letters.length)
		{
			letters[i].playAnim(letterAnims[Util.loop(index + i - 2, 0, letterAnims.length - 1)], true, true);
			if (i != 2)
				letters[i].pauseAnim();
		}

		if (val != 0)
		{
			for (i in 0...positions.length)
			{
				new FlxTimer().start(i / 24, function(tmr:FlxTimer) {
					for (m in members)
					{
						if (m != leftArrow && m != rightArrow)
							m.offset.x = positions[i] * val;
					}
				});
			}

			var arrowToMove:FlxSprite = val < 0 ? leftArrow : rightArrow;
			arrowToMove.offset.x = 3 * val;
			new FlxTimer().start(2 / 24, function(_) {
				arrowToMove.offset.x = 0;
			});
		}

		if (onChanged != null)
			onChanged(letterAnims[index]);
	}
}