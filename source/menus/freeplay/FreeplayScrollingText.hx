package menus.freeplay;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class FreeplayScrollingText extends FlxTypedSpriteGroup<FlxText>
{
	public var speed:Float = 1;

	override public function new(x:Float, y:Float, text:String, w:Float = 100, ?bold:Bool = false, ?size:Int = 48, ?color:FlxColor = FlxColor.WHITE, ?speed:Float = 1)
	{
		super(x, y);
		this.speed = speed;

		var xx:Float = 0;
		while (xx < w)
		{
			var txt:FlxText = new FlxText(xx, 0, 0, text, size);
			txt.color = color;
			txt.font = "5by7";
			txt.bold = bold;
			txt.updateHitbox();
			txt.active = false;
			add(txt);

			xx += txt.frameWidth + 20;
		}
	}

	override public function update(elapsed:Float)
	{
		x -= speed * (elapsed / (1 / 60));

		if (speed > 0)
		{
			if (x < -members[0].frameWidth + 20)
				x += members[0].frameWidth + 20;
		}
		else
		{
			if (x >= 0)
				x -= members[0].frameWidth + 20;
		}

		super.update(elapsed);
	}
}