package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import openfl.ui.MouseCursor;
import data.Options;

using StringTools;

class Checkbox extends FlxSpriteGroup
{
	public var infoText:String = "";
	public var rePress:Float = 0;

	var button:FlxSprite;
	public var hovered:Bool = false;
	public var checked(default, set):Bool = false;

	public var onClicked:Void->Void = null;
	public var condition:Void->Bool = null;

	override public function new(x:Float, y:Float, text:String, ?defaultValue:Bool = false, ?onClicked:Void->Void = null)
	{
		super(x, y);

		button = new FlxSprite();
		button.frames = Paths.sparrow("ui/editors/checkbox");
		button.animation.addByPrefix("unchecked", "Checkbox Unchecked", 24);
		button.animation.addByPrefix("checked", "Checkbox Checked", 24);
		button.animation.addByPrefix("uncheck", "Checkbox Uncheck0", 24, false);
		button.animation.addByPrefix("check", "Checkbox Check0", 24, false);
		button.animation.play("unchecked");
		add(button);

		var textObject:FlxText = new FlxText(Std.int(button.width) + 5, 0, 0, text);
		textObject.setFormat("FNF Dialogue", 20, FlxColor.WHITE, CENTER, OUTLINE, 0xFF254949);
		textObject.borderSize = 2;
		textObject.y += Std.int((button.height - textObject.height) / 2);
		add(textObject);

		button.animation.finishCallback = function(anim:String) {
			if (!StringTools.endsWith(anim, "ed"))
				button.animation.play(anim + "ed");
		}

		if (onClicked != null)
			this.onClicked = onClicked;

		checked = defaultValue;
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
				checked = !checked;
				button.animation.play(checked ? "check" : "uncheck");
				FlxG.sound.play(Paths.sound("ui/editors/ClickDown"), 0.5);
				if (onClicked != null)
					onClicked();
			}
		}

		if (condition != null)
		{
			var newVal:Bool = condition();
			if (checked != newVal)
				checked = newVal;
		}
	}

	public function set_checked(newVal:Bool):Bool
	{
		button.animation.play(newVal ? "checked" : "unchecked");
		return checked = newVal;
	}
}