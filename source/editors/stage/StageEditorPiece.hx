package editors.stage;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.addons.display.FlxBackdrop;
import objects.AnimatedSprite;

class StageEditorPiece extends AnimatedSprite
{
	public var highlightState(default, set):Int = 0;
	public var backdrop:FlxBackdrop = null;

	public function makeBackdrop(?Graphic:FlxGraphicAsset, ScrollX:Float = 1, ScrollY:Float = 1, RepeatX:Bool = true, RepeatY:Bool = true, SpaceX:Int = 0, SpaceY:Int = 0):StageEditorPiece
	{
		backdrop = new FlxBackdrop(Graphic, ScrollX, ScrollY, RepeatX, RepeatY, SpaceX, SpaceY);
		return this;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (backdrop != null)
			backdrop.update(elapsed);
	}

	override public function draw()
	{
		if (backdrop != null)
		{
			backdrop.setPosition(x, y);
			backdrop.scale.set(scale.x, scale.y);
			backdrop.origin.set(origin.x, origin.y);
			backdrop.offset.set(offset.x, offset.y);
			backdrop.antialiasing = antialiasing;
			backdrop.color = color;
			backdrop.alpha = alpha;
			backdrop.blend = blend;
			backdrop.draw();
		}
		else
			super.draw();
	}

	public function set_highlightState(v:Int):Int
	{
		if (highlightState != v)
		{
			var _alpha:Float = alpha;
			switch (v)
			{
				case 0: setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
				case 1: setColorTransform(1, 1, 1, 1, 0, Std.int(255 * 0.15), 0, 0);
				case 2: setColorTransform(1, 1, 1, 1, 0, Std.int(255 * 0.25), 0, 0);
			}
			alpha = _alpha;
		}
		return highlightState = v;
	}
}