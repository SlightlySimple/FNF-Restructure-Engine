package funkui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import data.Options;

import flixel.addons.ui.FlxUIInputText;
import lime.system.Clipboard;

class Stepper extends FlxSpriteGroup
{
	public var hovered:Int = 0;
	public var rePress:Float = 0;
	public var value(default, set):Float = 0;
	public var valueInt:Int = 0;
	public var stepVal:Float = 1;
	public var minVal:Float = -9999;
	public var maxVal:Float = 9999;
	public var decimals:Int = 0;

	public var plusButton:FlxSprite;
	public var minusButton:FlxSprite;
	public var textObject:FlxUIInputText;

	public static var isOneActive:Bool = false;

	public var onChanged:Void->Void = null;

	override public function new(x:Float, y:Float, ?w:Float = 20, ?h:Float = 20, ?defaultValue:Float = 0, ?stepVal:Float = 1, ?minVal:Float = -9999, ?maxVal:Float = 9999, ?decimals:Int = 0)
	{
		super(x, y);

		var key:String = "PlusButton_" + Std.string(w) + "_" + Std.string(h);
		if (FlxG.bitmap.get(key) == null)
		{
			var img:BitmapData = new BitmapData(Std.int(h), Std.int(h * 2), false, FlxColor.BLACK);
			img.fillRect(new Rectangle(1, 1, Std.int(h - 2), Std.int(h - 2)), FlxColor.WHITE);
			img.fillRect(new Rectangle(2, Std.int(h + 2), Std.int(h - 4), Std.int(h - 4)), FlxColor.WHITE);
			img.fillRect(new Rectangle(5, Std.int(h / 2) - 1, Std.int(h - 10), 3), FlxColor.BLACK);
			img.fillRect(new Rectangle(Std.int(h / 2) - 1, 5, 3, Std.int(h - 10)), FlxColor.BLACK);
			img.fillRect(new Rectangle(5, Std.int(h * 1.5) - 1, Std.int(h - 10), 3), FlxColor.BLACK);
			img.fillRect(new Rectangle(Std.int(h / 2) - 1, Std.int(h) + 5, 3, Std.int(h - 10)), FlxColor.BLACK);
			FlxGraphic.fromBitmapData(img, false, key);
		}

		var key2:String = "MinusButton_" + Std.string(w) + "_" + Std.string(h);
		if (FlxG.bitmap.get(key2) == null)
		{
			var img:BitmapData = new BitmapData(Std.int(h), Std.int(h * 2), false, FlxColor.BLACK);
			img.fillRect(new Rectangle(1, 1, Std.int(h - 2), Std.int(h - 2)), FlxColor.WHITE);
			img.fillRect(new Rectangle(2, Std.int(h + 2), Std.int(h - 4), Std.int(h - 4)), FlxColor.WHITE);
			img.fillRect(new Rectangle(5, Std.int(h / 2) - 1, Std.int(h - 10), 3), FlxColor.BLACK);
			img.fillRect(new Rectangle(5, Std.int(h * 1.5) - 1, Std.int(h - 10), 3), FlxColor.BLACK);
			FlxGraphic.fromBitmapData(img, false, key2);
		}

		plusButton = new FlxSprite(Std.int(w - (h * 2)), 0);
		plusButton.frames = FlxTileFrames.fromGraphic(FlxG.bitmap.get(key), FlxPoint.get(Std.int(h), Std.int(h)));
		plusButton.animation.add("idle", [0]);
		plusButton.animation.add("hover", [1]);
		add(plusButton);

		minusButton = new FlxSprite(Std.int(w - h), 0);
		minusButton.frames = FlxTileFrames.fromGraphic(FlxG.bitmap.get(key2), FlxPoint.get(Std.int(h), Std.int(h)));
		minusButton.animation.add("idle", [0]);
		minusButton.animation.add("hover", [1]);
		add(minusButton);

		textObject = new FlxUIInputText(1, 1, Std.int(w - (h * 2))-1, "", Std.int(h - 5));
		textObject.font = "VCR OSD Mono";
		textObject.customFilterPattern = ~/[^0-9.-]*/g;
		textObject.focusGained = function() { Stepper.isOneActive = true; }
		textObject.focusLost = function() {
			if (textObject.text == "")
				value = 0;
			else
				value = Std.parseFloat(textObject.text);
			if (onChanged != null)
				onChanged();
			Stepper.isOneActive = false;
		}
		add(textObject);

		this.stepVal = stepVal;
		this.minVal = minVal;
		this.maxVal = maxVal;
		this.decimals = decimals;
		value = defaultValue;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		rePress -= elapsed;
		if (DropdownMenu.isOneActive) return;

		if (FlxG.mouse.justMoved)
		{
			if (plusButton.overlapsPoint(FlxG.mouse.getWorldPosition(camera, plusButton._point), true, camera) && hovered == 0)
			{
				hovered = 1;
				plusButton.animation.play("hover");
			}
			else if (!plusButton.overlapsPoint(FlxG.mouse.getWorldPosition(camera, plusButton._point), true, camera) && hovered == 1)
			{
				hovered = 0;
				plusButton.animation.play("idle");
			}

			if (minusButton.overlapsPoint(FlxG.mouse.getWorldPosition(camera, minusButton._point), true, camera) && hovered == 0)
			{
				hovered = 2;
				minusButton.animation.play("hover");
			}
			else if (!minusButton.overlapsPoint(FlxG.mouse.getWorldPosition(camera, minusButton._point), true, camera) && hovered == 2)
			{
				hovered = 0;
				minusButton.animation.play("idle");
			}
		}

		if (Options.mouseJustPressed() && rePress <= 0)
		{
			switch (hovered)
			{
				case 1:
					if (value + stepVal <= maxVal)
						value = value + stepVal;
					rePress = 0.01;
					if (onChanged != null)
						onChanged();
				case 2:
					if (value - stepVal >= minVal)
						value = value - stepVal;
					rePress = 0.01;
					if (onChanged != null)
						onChanged();
			}
		}

		if (textObject.hasFocus && FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.C)
				Clipboard.text = textObject.text;

			if (FlxG.keys.justPressed.V)
			{
				textObject.text = Clipboard.text;
				textObject.caretIndex = Clipboard.text.length;
				@:privateAccess
				textObject.onChange("input");
			}
		}
	}

	public function set_value(newVal:Float):Float
	{
		var trueNewVal:Float = newVal;
		if (trueNewVal < minVal && minVal != -9999)
			trueNewVal = minVal;
		if (trueNewVal > maxVal && maxVal != 9999)
			trueNewVal = maxVal;
		trueNewVal *= Math.pow(10, decimals);
		trueNewVal = Math.round(trueNewVal);
		trueNewVal /= Math.pow(10, decimals);
		textObject.text = Std.string(trueNewVal);
		valueInt = Std.int(trueNewVal);
		return value = trueNewVal;
	}
}