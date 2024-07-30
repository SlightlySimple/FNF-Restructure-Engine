package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import openfl.ui.MouseCursor;
import data.Options;

class Button extends FlxSpriteGroup
{
	public static var DEFAULT:String = "button";
	public static var SHORT:String = "buttonShort";
	public static var LONG:String = "buttonLong";

	public var infoText:String = "";

	public var button:FlxSprite;
	public var hovered:Bool = false;
	public var onClicked:Void->Void = null;
	public var onRightClicked:Void->Void = null;

	override public function new(x:Float, y:Float, ?graphic:String = "button", ?onClicked:Void->Void = null, ?onRightClicked:Void->Void = null)
	{
		super(x, y);

		button = new FlxSprite();
		button.frames = Paths.tiles("ui/editors/" + graphic, 1, 2);
		button.animation.add("idle", [0]);
		button.animation.add("pressed", [1]);
		button.animation.play("idle");
		add(button);

		if (onClicked != null)
			this.onClicked = onClicked;

		if (onRightClicked != null)
			this.onRightClicked = onRightClicked;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (DropdownMenu.isOneActive) return;

		if (hovered)
			button.scale.x = FlxMath.lerp(button.scale.x, 0.9, elapsed * 10);
		else
			button.scale.x = FlxMath.lerp(button.scale.x, 1, elapsed * 10);
		button.scale.y = button.scale.x;

		if (FlxG.mouse.justMoved)
		{
			if (UIControl.mouseOver(this))
			{
				if (!hovered)
				{
					hovered = true;
					if (infoText != "")
						UIControl.infoText = infoText;
				}
			}
			else if (hovered)
				hovered = false;
		}

		if (button.animation.curAnim.name == "pressed" && !Options.mousePressed() && !Options.mousePressed(true))
		{
			button.animation.play("idle");
			FlxG.sound.play(Paths.sound("ui/editors/ClickUp"), 0.5);
		}

		if (hovered)
		{
			UIControl.cursor = MouseCursor.BUTTON;
			if (Options.mouseJustPressed() && button.animation.curAnim.name != "pressed")
			{
				button.animation.play("pressed");
				FlxG.sound.play(Paths.sound("ui/editors/ClickDown"), 0.5);
				if (onClicked != null)
					onClicked();
			}

			if (onRightClicked != null && Options.mouseJustPressed(true) && button.animation.curAnim.name != "pressed")
			{
				button.animation.play("pressed");
				FlxG.sound.play(Paths.sound("ui/editors/ClickDown"), 0.5);
				onRightClicked();
			}
		}
	}
}

class TextButton extends Button
{
	public var textObject:FlxText;
	var textY:Float = 0;
	var iconObject:FlxSprite = null;
	var iconY:Float = 0;

	override public function new(x:Float, y:Float, text:String, ?graphic:String = "button", ?icon:String = "", ?onClicked:Void->Void = null)
	{
		super(x, y, graphic, onClicked);

		textObject = new FlxText(0, 0, 0, Lang.get(text)).setFormat("FNF Dialogue", 20, FlxColor.WHITE, CENTER, OUTLINE, 0xFF254949);
		textObject.wordWrap = false;
		textObject.borderSize = 2;
		textObject.x = Std.int((button.width - textObject.width) / 2);
		textObject.y = Std.int((button.height - textObject.height) / 2) - 3;
		textY = textObject.y;

		if (icon != "")
		{
			iconObject = new FlxSprite(0, 0, Paths.image("ui/editors/" + icon));
			textObject.x = Std.int((button.width - (textObject.width + iconObject.width + 6)) / 2);
			iconObject.x = Std.int(textObject.x + textObject.width) + 6;
			iconObject.y = Std.int(textObject.y + (textObject.height - iconObject.height) / 2);
			iconY = iconObject.y;
			add(iconObject);
		}

		add(textObject);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (DropdownMenu.isOneActive) return;

		if (button.animation.curAnim.name == "idle" && textObject.y > y + textY)
		{
			textObject.y = y + textY;
			if (iconObject != null)
				iconObject.y = y + iconY;
		}

		if (button.animation.curAnim.name == "pressed" && textObject.y <= y + textY)
		{
			textObject.y = y + textY + 3;
			if (iconObject != null)
				iconObject.y = y + iconY + 3;
		}
	}
}

class ToggleButton extends FlxSpriteGroup
{
	public var infoText:String = "";
	public var rePress:Float = 0;

	var button:FlxSprite;
	public var textObject:FlxText;
	public var state(default, set):Bool = false;
	public var hovered:Bool = false;
	public var condition:Void->Bool = null;
	public var ranConditionOnce:Bool = false;
	public var onClicked:Void->Void = null;

	public var onText:String = "";
	public var onTextBorder:FlxColor = FlxColor.TRANSPARENT;
	public var offText:String = "";
	public var offTextBorder:FlxColor = FlxColor.TRANSPARENT;

	override public function new(x:Float, y:Float, text:String, ?graphic:String = "button", ?onText:String = "", ?onTextBorder:FlxColor = FlxColor.TRANSPARENT, ?offText:String = "", ?offTextBorder:FlxColor = FlxColor.TRANSPARENT, ?condition:Void->Bool = null, ?onClicked:Void->Void = null)
	{
		super(x, y);

		this.onText = onText;
		this.onTextBorder = onTextBorder;
		this.offText = offText;
		this.offTextBorder = offTextBorder;

		button = new FlxSprite();
		button.frames = Paths.tiles("ui/editors/" + graphic, 1, 2);
		button.animation.add("idle", [0]);
		button.animation.add("pressed", [1]);
		button.animation.play("idle");
		add(button);

		textObject = new FlxText(0, 0, Std.int(button.width), Lang.get(text));
		textObject.setFormat("FNF Dialogue", 20, FlxColor.WHITE, CENTER, OUTLINE, 0xFF254949);
		textObject.wordWrap = false;
		textObject.borderSize = 2;
		textObject.y += Std.int((button.height - textObject.height) / 2) - 3;
		add(textObject);

		if (condition != null)
		{
			ranConditionOnce = true;
			this.condition = condition;
			state = condition();
		}

		if (onClicked != null)
			this.onClicked = onClicked;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		rePress -= elapsed;
		if (DropdownMenu.isOneActive) return;

		if (hovered)
			button.scale.x = FlxMath.lerp(button.scale.x, 0.9, elapsed * 10);
		else
			button.scale.x = FlxMath.lerp(button.scale.x, 1, elapsed * 10);
		button.scale.y = button.scale.x;

		if (condition != null)
		{
			var goalState:Bool = condition();
			if (goalState != state || !ranConditionOnce)
			{
				ranConditionOnce = true;
				state = goalState;
			}
		}

		if (FlxG.mouse.justMoved)
		{
			if (UIControl.mouseOver(this))
			{
				if (!hovered)
				{
					hovered = true;
					if (infoText != "")
						UIControl.infoText = infoText;
				}
			}
			else if (hovered)
				hovered = false;
		}

		if (hovered)
		{
			UIControl.cursor = MouseCursor.BUTTON;
			if (Options.mouseJustPressed() && rePress <= 0)
			{
				rePress = 0.01;
				FlxG.sound.play(Paths.sound("ui/editors/ClickDown"), 0.5);
				if (onClicked != null)
					onClicked();
			}
		}
	}

	function set_state(value:Bool):Bool
	{
		if (value)
		{
			if (button.animation.curAnim.name != "pressed")
			{
				button.animation.play("pressed");
				textObject.y += 3;
			}
			if (onText != "")
				textObject.text = Lang.get(onText);
			if (onTextBorder != FlxColor.TRANSPARENT)
				textObject.borderColor = onTextBorder;
		}
		else
		{
			if (button.animation.curAnim.name == "pressed")
			{
				button.animation.play("idle");
				textObject.y -= 3;
			}
			if (offText != "")
				textObject.text = Lang.get(offText);
			if (offTextBorder != FlxColor.TRANSPARENT)
				textObject.borderColor = offTextBorder;
		}

		return state = value;
	}
}