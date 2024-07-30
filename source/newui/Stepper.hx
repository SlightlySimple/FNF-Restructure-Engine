package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.addons.ui.FlxInputText;
import lime.system.Clipboard;
import openfl.ui.MouseCursor;
import data.Options;

using StringTools;

class Stepper extends FlxSpriteGroup
{
	public var infoText:String = "";

	public var hovered:Int = 0;
	public var value(default, set):Float = 0;
	public var valueInt:Int = 0;
	public var stepVal:Float = 1;
	public var minVal:Float = -9999;
	public var maxVal:Float = 9999;
	public var decimals:Int = 0;

	var plusButton:FlxSprite;
	var minusButton:FlxSprite;
	var textObject:FlxInputText;
	public var labelText:FlxText = null;

	public static var isOneActive:Bool = false;

	public var onChanged:Void->Void = null;
	public var condition:Void->Float = null;

	override public function new(x:Float, y:Float, ?label:String = "", ?defaultValue:Float = 0, ?stepVal:Float = 1, ?minVal:Float = -9999, ?maxVal:Float = 9999, ?decimals:Int = 0)
	{
		super(x, y);

		var xx:Int = 0;
		var w:Int = 50;

		if (label != "")
		{
			labelText = new FlxText(0, 0, 0, label);
			labelText.setFormat("FNF Dialogue", 18, FlxColor.WHITE, LEFT, OUTLINE, 0xFF254949);
			labelText.borderSize = 2;
			xx = Std.int(labelText.width + 5);
			add(labelText);
		}

		var bg:FlxSprite = new FlxSprite(xx).makeGraphic(w, 20, 0xFF254949);
		bg.active = false;
		add(bg);

		var fg:FlxSprite = new FlxSprite(xx + 2, 2).makeGraphic(w - 4, 16, FlxColor.WHITE);
		fg.active = false;
		add(fg);

		plusButton = new FlxSprite(xx + bg.width, 0);
		plusButton.frames = Paths.tiles("ui/editors/stepperPlus", 1, 2);
		plusButton.animation.add("idle", [0]);
		plusButton.animation.add("pressed", [1]);
		plusButton.animation.play("idle");
		add(plusButton);

		minusButton = new FlxSprite(xx + bg.width + plusButton.width, 0);
		minusButton.frames = Paths.tiles("ui/editors/stepperMinus", 1, 2);
		minusButton.animation.add("idle", [0]);
		minusButton.animation.add("pressed", [1]);
		minusButton.animation.play("idle");
		add(minusButton);

		textObject = new FlxInputText(xx + 2, 0, w - 2, "", 16, FlxColor.BLACK, FlxColor.TRANSPARENT);
		textObject.fieldBorderThickness = 0;
		textObject.font = "FNF Dialogue";
		textObject.customFilterPattern = ~/[^0-9.-]*/g;
		textObject.focusGained = function() { Stepper.isOneActive = true; }
		textObject.focusLost = function() {
			if (textObject.text.replace("-", "") == "")
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
		if (DropdownMenu.isOneActive) return;

		if (hovered == 1)
			plusButton.scale.x = FlxMath.lerp(plusButton.scale.x, 0.9, elapsed * 10);
		else
			plusButton.scale.x = FlxMath.lerp(plusButton.scale.x, 1, elapsed * 10);
		plusButton.scale.y = plusButton.scale.x;

		if (hovered == 2)
			minusButton.scale.x = FlxMath.lerp(minusButton.scale.x, 0.9, elapsed * 10);
		else
			minusButton.scale.x = FlxMath.lerp(minusButton.scale.x, 1, elapsed * 10);
		minusButton.scale.y = minusButton.scale.x;

		if (FlxG.mouse.justMoved)
		{
			if (infoText != "" && UIControl.mouseOver(this))
				UIControl.infoText = infoText;

			if (UIControl.mouseOver(textObject))
			{
				hovered = 0;
				UIControl.cursor = MouseCursor.IBEAM;
			}
			else if (UIControl.mouseOver(plusButton))
			{
				hovered = 1;
				UIControl.cursor = MouseCursor.BUTTON;
			}
			else if (UIControl.mouseOver(minusButton))
			{
				hovered = 2;
				UIControl.cursor = MouseCursor.BUTTON;
			}
			else
				hovered = 0;
		}

		if (Options.mouseJustPressed())
		{
			if (plusButton.animation.curAnim.name != "pressed" && hovered == 1)
			{
				plusButton.animation.play("pressed");
				if (value + stepVal <= maxVal || maxVal == 9999)
					value = value + stepVal;
				FlxG.sound.play(Paths.sound("ui/editors/ClickDown"), 0.5);
				if (onChanged != null)
					onChanged();
			}
			else if (minusButton.animation.curAnim.name != "pressed" && hovered == 2)
			{
				minusButton.animation.play("pressed");
				if (value - stepVal >= minVal || minVal == -9999)
					value = value - stepVal;
				FlxG.sound.play(Paths.sound("ui/editors/ClickDown"), 0.5);
				if (onChanged != null)
					onChanged();
			}
		}

		if (condition != null && !textObject.hasFocus)
		{
			var newVal:Float = condition();
			if (value != newVal)
				value = newVal;
		}

		if (plusButton.animation.curAnim.name == "pressed" && !Options.mousePressed())
		{
			plusButton.animation.play("idle");
			FlxG.sound.play(Paths.sound("ui/editors/ClickUp"), 0.5);
		}

		if (minusButton.animation.curAnim.name == "pressed" && !Options.mousePressed())
		{
			minusButton.animation.play("idle");
			FlxG.sound.play(Paths.sound("ui/editors/ClickUp"), 0.5);
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