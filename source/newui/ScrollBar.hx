package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.ui.MouseCursor;
import data.Options;

class ScrollBar extends FlxSpriteGroup
{
	var h:Float = 0;
	public var scroll(default, set):Float = 0;
	public var onChanged:Void->Void = null;

	public var hovered:Bool = false;
	var pressed:Bool = false;

	var back:FlxSprite;
	var backAdd:FlxSprite;
	var bar:FlxSprite;

	override public function new(x:Float, y:Float, h:Float)
	{
		super(x, y);
		this.h = h;

		var key:String = "ThreeSlice_ScrollBack_" + Std.string(h);
		if (FlxG.bitmap.get(key) == null)
		{
			var w:Int = Std.int(Paths.image("ui/editors/sideScrollBack").width);
			var img:BitmapData = new BitmapData(w, Std.int(h), true, FlxColor.TRANSPARENT);
			PopupWindow.createThreeSlice(img, Paths.image("ui/editors/sideScrollBack").bitmap, 20, 0, 0, Std.int(h));
			FlxGraphic.fromBitmapData(img, false, key);
		}

		back = new FlxSprite(FlxG.bitmap.get(key));
		back.active = false;
		add(back);

		backAdd = new FlxSprite(FlxG.bitmap.get(key));
		backAdd.active = false;
		backAdd.alpha = 0.3;
		backAdd.blend = SUBTRACT;
		add(backAdd);

		bar = new FlxSprite(Paths.image("ui/editors/sideScroll"));
		bar.active = false;
		add(bar);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (visible && UIControl.mouseOver(this))
		{
			if (!hovered)
			{
				hovered = true;
				backAdd.alpha = 0.1;
			}
		}
		else if (hovered)
		{
			hovered = false;
			backAdd.alpha = 0.3;
		}

		if (hovered)
		{
			UIControl.cursor = MouseCursor.BUTTON;
			if (!pressed && Options.mouseJustPressed())
				pressed = true;
		}

		if (pressed)
		{
			UIControl.cursor = MouseCursor.BUTTON;
			backAdd.alpha = 0.1;

			scroll = (((FlxG.mouse.y - (bar.height / 2)) - back.y) / (h - bar.height));
			if (onChanged != null)
				onChanged();

			if (Options.mouseJustReleased())
			{
				pressed = false;
				backAdd.alpha = 0.3;
			}
		}
	}

	public function set_scroll(val:Float):Float
	{
		scroll = Math.min(1, Math.max(0, val));
		bar.y = Std.int(back.y + (scroll * (h - bar.height)));

		return scroll;
	}
}