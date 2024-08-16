package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BlendMode;
import data.Options;

class ColorSwatch extends FlxSpriteGroup
{
	public var mode(default, set):String = "rgb";

	var modeRGB:Array<FlxSprite> = [];
	var modeHSV:Array<FlxSprite> = [];

	var swatchR:FlxSprite;
	var swatchH:FlxSprite;
	var swatchSide:FlxSprite;

	var swatchCursorA:FlxSprite;
	var swatchCursorB:FlxSprite;

	var draggingSwatch:Int = 0;
	public var r(get, set):Int;
	public var g(get, set):Int;
	public var b(get, set):Int;
	public var h(get, set):Float;
	public var s(get, set):Float;
	public var v(get, set):Float;
	public var swatchColor:FlxColor;
	public var onChanged:Void->Void = null;

	override public function new(x:Float, y:Float, ?w:Int = 100, ?h:Int = 100, ?defaultColor:FlxColor = FlxColor.WHITE)
	{
		super(x, y);

		var border:FlxSprite = new FlxSprite().makeGraphic(w, h, 0xFF254949);
		add(border);

		swatchR = new FlxSprite(2, 2).makeGraphic(w - 4, h - 4, FlxColor.RED);
		add(swatchR);
		modeRGB.push(swatchR);

		var swatchG:FlxSprite = FlxGradient.createGradientFlxSprite(w - 4, h - 4, [FlxColor.TRANSPARENT, FlxColor.LIME], 1, 0);
		swatchG.setPosition(2, 2);
		swatchG.blend = BlendMode.ADD;
		add(swatchG);
		modeRGB.push(swatchG);

		var swatchB:FlxSprite = FlxGradient.createGradientFlxSprite(w - 4, h - 4, [FlxColor.TRANSPARENT, FlxColor.BLUE], 1, 90);
		swatchB.setPosition(2, 2);
		swatchB.blend = BlendMode.ADD;
		add(swatchB);
		modeRGB.push(swatchB);

		swatchH = new FlxSprite(2, 2).makeGraphic(w - 4, h - 4, FlxColor.WHITE);
		add(swatchH);
		modeHSV.push(swatchH);

		var swatchV:FlxSprite = FlxGradient.createGradientFlxSprite(w - 4, h - 4, [FlxColor.WHITE, FlxColor.TRANSPARENT], 1, 0);
		swatchV.setPosition(2, 2);
		add(swatchV);
		modeHSV.push(swatchV);

		var swatchS:FlxSprite = FlxGradient.createGradientFlxSprite(w - 4, h - 4, [FlxColor.TRANSPARENT, FlxColor.BLACK]);
		swatchS.setPosition(2, 2);
		add(swatchS);
		modeHSV.push(swatchS);

		swatchCursorA = new FlxSprite(2, 2, Paths.image("ui/editors/colorDot"));
		swatchCursorA.offset.set(Std.int(swatchCursorA.width / 2), Std.int(swatchCursorA.height / 2));
		add(swatchCursorA);

		var border2:FlxSprite = new FlxSprite(w + 20).makeGraphic(40, h, 0xFF254949);
		add(border2);

		swatchSide = new FlxSprite(w + 2 + 20, 2).makeGraphic(36, h - 4, FlxColor.WHITE);
		add(swatchSide);
		modeRGB.push(swatchSide);

		var swatchSideR:FlxSprite = FlxGradient.createGradientFlxSprite(36, h - 4, [FlxColor.TRANSPARENT, FlxColor.RED], 1, 270);
		swatchSideR.setPosition(swatchSide.x - x, swatchSide.y - y);
		swatchSideR.blend = BlendMode.ADD;
		add(swatchSideR);
		modeRGB.push(swatchSideR);

		var colors = [];
		for (i in 0...9)
			colors.push(FlxColor.fromHSB((i / 8) * 359, 1, 1));
		var swatchSideH:FlxSprite = FlxGradient.createGradientFlxSprite(36, h - 4, colors);
		swatchSideH.setPosition(swatchSide.x - x, swatchSide.y - y);
		add(swatchSideH);
		modeHSV.push(swatchSideH);

		swatchCursorB = new FlxSprite(border2.x - x, 2, Paths.image("ui/editors/colorSlider"));
		swatchCursorB.offset.set(Std.int((swatchCursorB.width - 40) / 2), Std.int(swatchCursorB.height / 2));
		add(swatchCursorB);

		swatchColor = defaultColor;
		mode = "rgb";
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
				if (mode == "hsv")
					swatchColor = FlxColor.fromHSB(Std.int(((swatchCursorB.y - swatchSide.y) / swatchSide.height) * 359), (swatchCursorA.x - swatchR.x) / swatchR.width, 1 - ((swatchCursorA.y - swatchR.y) / swatchR.height));
				else
					swatchColor = FlxColor.fromRGB(r, Std.int(((swatchCursorA.x - swatchR.x) / swatchR.width) * 255), Std.int(((swatchCursorA.y - swatchR.y) / swatchR.height) * 255));
				if (onChanged != null)
					onChanged();

			case 2:
				swatchCursorB.y = Math.min(swatchSide.y + swatchSide.height, Math.max(swatchSide.y, FlxG.mouse.y));
				if (mode == "hsv")
					h = Std.int(((swatchCursorB.y - swatchSide.y) / swatchSide.height) * 359);
				else
					r = 255 - Std.int(((swatchCursorB.y - swatchSide.y) / swatchSide.height) * 255);
				if (onChanged != null)
					onChanged();
		}

		swatchR.color = FlxColor.fromRGB(r, 255, 255, 255);
		swatchH.color = FlxColor.fromHSB(h, 1, 1, 255);
		swatchSide.color = FlxColor.fromRGB(0, g, b, 255);
	}

	public function resetCursorPositions()
	{
		if (mode == "hsv")
		{
			swatchCursorA.setPosition(swatchR.x + (swatchR.width * s), swatchR.y + (swatchR.height * (1 - v)));
			swatchCursorB.y = swatchSide.y + (swatchSide.height * (h / 359));
		}
		else
		{
			swatchCursorA.setPosition(swatchR.x + (swatchR.width * (g / 255)), swatchR.y + (swatchR.height * (b / 255)));
			swatchCursorB.y = swatchSide.y + (swatchSide.height * (1 - (r / 255)));
		}
	}

	public function get_r():Int
	{
		return swatchColor.red;
	}

	public function get_g():Int
	{
		return swatchColor.green;
	}

	public function get_b():Int
	{
		return swatchColor.blue;
	}

	public function set_r(v:Int):Int
	{
		swatchColor = FlxColor.fromRGB(v, g, b);
		swatchCursorB.y = swatchSide.y + swatchSide.height - (v / 255 * swatchSide.height);
		resetCursorPositions();
		return v;
	}

	public function set_g(v:Int):Int
	{
		swatchColor = FlxColor.fromRGB(r, v, b);
		swatchCursorA.x = swatchR.x + (v / 255 * swatchR.width);
		resetCursorPositions();
		return v;
	}

	public function set_b(v:Int):Int
	{
		swatchColor = FlxColor.fromRGB(r, g, v);
		swatchCursorA.y = swatchR.y + (v / 255 * swatchR.height);
		resetCursorPositions();
		return v;
	}

	public function get_h():Float
	{
		return swatchColor.hue;
	}

	public function get_s():Float
	{
		return swatchColor.saturation;
	}

	public function get_v():Float
	{
		return swatchColor.brightness;
	}

	public function set_h(val:Float):Float
	{
		swatchColor = FlxColor.fromHSB(val, s, v);
		resetCursorPositions();
		return val;
	}

	public function set_s(val:Float):Float
	{
		swatchColor = FlxColor.fromHSB(h, val, v);
		resetCursorPositions();
		return val;
	}

	public function set_v(val:Float):Float
	{
		swatchColor = FlxColor.fromHSB(h, s, val);
		resetCursorPositions();
		return val;
	}

	public function set_mode(val:String):String
	{
		for (s in modeRGB)
			s.visible = (val == "rgb");
		for (s in modeHSV)
			s.visible = (val == "hsv");
		mode = val;
		resetCursorPositions();
		return val;
	}
}