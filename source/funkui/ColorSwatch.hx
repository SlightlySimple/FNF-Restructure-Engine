package funkui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BlendMode;
import data.Options;

class ColorSwatch extends FlxSpriteGroup
{
	var swatchR:FlxSprite;
	var swatchSide:FlxSprite;

	var swatchCursorA:FlxSprite;
	var swatchCursorB:FlxSprite;

	var draggingSwatch:Int = 0;
	public var r(default, set):Int = 0;
	public var g(default, set):Int = 0;
	public var b(default, set):Int = 0;
	public var swatchColor(get, never):FlxColor;
	public var onChanged:Void->Void = null;

	override public function new(x:Float, y:Float, ?w:Int = 20, ?h:Int = 20, ?sideWidth:Int = 20, ?defaultColor:FlxColor = FlxColor.WHITE)
	{
		super(x, y);

		swatchR = new FlxSprite().makeGraphic(w, h, FlxColor.RED);
		add(swatchR);

		var swatchG:FlxSprite = FlxGradient.createGradientFlxSprite(w, h, [FlxColor.TRANSPARENT, FlxColor.LIME], 1, 0);
		swatchG.blend = BlendMode.ADD;
		add(swatchG);

		var swatchB:FlxSprite = FlxGradient.createGradientFlxSprite(w, h, [FlxColor.TRANSPARENT, FlxColor.BLUE], 1, 90);
		swatchB.blend = BlendMode.ADD;
		add(swatchB);

		swatchCursorA = new FlxSprite().makeGraphic(5, 5, FlxColor.GRAY);
		swatchCursorA.offset.set(2, 2);
		add(swatchCursorA);

		swatchSide = new FlxSprite(w + sideWidth, 0).makeGraphic(sideWidth, h, FlxColor.WHITE);
		add(swatchSide);

		var swatchSideR:FlxSprite = FlxGradient.createGradientFlxSprite(sideWidth, h, [FlxColor.TRANSPARENT, FlxColor.RED], 1, 270);
		swatchSideR.setPosition(swatchSide.x - x, swatchSide.y - y);
		swatchSideR.blend = BlendMode.ADD;
		add(swatchSideR);

		swatchCursorB = new FlxSprite(swatchSide.x - x, 0).makeGraphic(sideWidth, 5, FlxColor.GRAY);
		swatchCursorB.offset.set(0, 2);
		add(swatchCursorB);

		r = defaultColor.red;
		g = defaultColor.green;
		b = defaultColor.blue;
	}

	override public function update(elapsed)
	{
		if (Options.mouseJustPressed())
		{
			if (swatchR.overlapsPoint(FlxG.mouse.getWorldPosition(camera, swatchR._point), true, camera))
				draggingSwatch = 1;
			if (swatchSide.overlapsPoint(FlxG.mouse.getWorldPosition(camera, swatchSide._point), true, camera))
				draggingSwatch = 2;
		}

		if (Options.mouseJustReleased())
			draggingSwatch = 0;

		switch (draggingSwatch)
		{
			case 1:
				swatchCursorA.setPosition(Math.min(swatchR.x + swatchR.width, Math.max(swatchR.x, FlxG.mouse.x)), Math.min(swatchR.y + swatchR.height, Math.max(swatchR.y, FlxG.mouse.y)));
				g = Std.int(((swatchCursorA.x - swatchR.x) / swatchR.width) * 255);
				b = Std.int(((swatchCursorA.y - swatchR.y) / swatchR.height) * 255);
				if (onChanged != null)
					onChanged();

			case 2:
				swatchCursorB.y = Math.min(swatchSide.y + swatchSide.height, Math.max(swatchSide.y, FlxG.mouse.y));
				r = 255 - Std.int(((swatchCursorB.y - swatchSide.y) / swatchSide.height) * 255);
				if (onChanged != null)
					onChanged();
		}

		swatchR.color = FlxColor.fromRGB(r, 255, 255, 255);
		swatchSide.color = FlxColor.fromRGB(0, g, b, 255);
	}

	public function set_r(v:Int):Int
	{
		swatchCursorB.y = swatchSide.y + swatchSide.height - (v / 255 * swatchSide.height);
		return r = v;
	}

	public function set_g(v:Int):Int
	{
		swatchCursorA.x = swatchR.x + (v / 255 * swatchR.width);
		return g = v;
	}

	public function set_b(v:Int):Int
	{
		swatchCursorA.y = swatchR.y + (v / 255 * swatchR.height);
		return b = v;
	}

	public function get_swatchColor():FlxColor
	{
		return FlxColor.fromRGB(r, g, b, 255);
	}
}