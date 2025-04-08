package shaders;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxFrame;
import flixel.addons.display.FlxRuntimeShader;
import openfl.display.BitmapData;

class DropShadowShader extends FlxRuntimeShader
{
	public var angle(default, set):Float;
	public var strength(default, set):Float;
	public var distance(default, set):Float;
	public var threshold(default, set):Float;
	public var baseHue(default, set):Float;
	public var baseSaturation(default, set):Float;
	public var baseBrightness(default, set):Float;
	public var baseContrast(default, set):Float;
	public var antialiasAmt(default, set):Float;
	public var attachedSprite(default, set):FlxSprite;
	public var maskThreshold(default, set):Float;
	public var useAltMask(default, set):Bool;
	public var altMaskImage(default, set):BitmapData;
	public var color(default, set):FlxColor;

	override public function new(?frag:String = "dropShadow")
	{
		super(Paths.shader(frag));

		angle = 0;
		strength = 1;
		distance = 15;
		threshold = 0.1;
		baseHue = 0;
		baseSaturation = 0;
		baseBrightness = 0;
		baseContrast = 0;
		antialiasAmt = 2;
		useAltMask = false;
		color = FlxColor.BLACK;
	}

	public function setAdjustColor(b:Float, h:Float, c:Float, s:Float)
	{
		baseBrightness = b;
		baseHue = h;
		baseContrast = c;
		baseSaturation = s;
	}

	public function set_baseHue(val):Float
	{
		data.hue.value = [val];
		return baseHue = val;
	}

	public function set_baseSaturation(val):Float
	{
		data.saturation.value = [val];
		return baseSaturation = val;
	}

	public function set_baseBrightness(val):Float
	{
		data.brightness.value = [val];
		return baseBrightness = val;
	}

	public function set_baseContrast(val):Float
	{
		data.contrast.value = [val];
		return baseContrast = val;
	}

	public function set_threshold(val:Float):Float
	{
		data.thr.value = [val];
		return threshold = val;
	}

	public function set_antialiasAmt(val:Float):Float
	{
		data.AA_STAGES.value = [val];
		return antialiasAmt = val;
	}

	public function set_color(col:FlxColor):FlxColor
	{
		data.dropColor.value = [col.red / 255, col.green / 255, col.blue / 255];
		return color = col;
	}

	public function set_angle(val:Float):Float
	{
		data.ang.value = [val * (Math.PI / 180)];
		return angle = val;
	}

	public function set_distance(val:Float):Float
	{
		data.dist.value = [val];
		return distance = val;
	}

	public function set_strength(val:Float):Float
	{
		data.str.value = [val];
		return strength = val;
	}

	public function set_attachedSprite(spr:FlxSprite):FlxSprite
	{
		updateFrameInfo(spr.frame);
		spr.shader = this;
		spr.animation.callback = onAttachedFrame;
		return attachedSprite = spr;
	}

	public function onAttachedFrame(name:String, frameNum:Int, frameIndex:Int)
	{
		if (attachedSprite != null)
			updateFrameInfo(attachedSprite.frame);
	}

	public function updateFrameInfo(frame:FlxFrame)
	{
		data.uFrameBounds.value = [frame.uv.x,frame.uv.y,frame.uv.width,frame.uv.height];
		data.angOffset.value = [frame.angle * (Math.PI / 180)];
	}

	public function set_altMaskImage(_bitmapData:BitmapData):BitmapData
	{
		data.altMask.input = _bitmapData;
		return altMaskImage = _bitmapData;
	}

	public function set_maskThreshold(val:Float):Float
	{
		data.thr2.value = [val];
		return maskThreshold = val;
	}

	public function set_useAltMask(val:Bool):Bool
	{
		data.useMask.value = [val];
		return useAltMask = val;
	}
}

class DropShadowScreenspace extends DropShadowShader
{
	public var curZoom(default, set):Float;

	override public function new()
	{
		super("dropShadowScreenspace");
		curZoom = 1;
	}

	public function set_curZoom(val:Float):Float
	{
		data.zoom.value = [val];
		return curZoom = val;
	}
}