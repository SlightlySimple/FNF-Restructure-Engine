package funkui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import data.Options;

class TextButton extends FlxSpriteGroup
{
	public var textObject:FlxText;
	public var hovered:Bool = false;
	public var rePress:Float = 0;
	public var onClicked:Void->Void = null;

	override public function new(x:Float, y:Float, ?w:Float = 20, ?h:Float = 20, ?text:String = "")
	{
		super(x, y);

		var key:String = "TextButton_" + Std.string(w) + "_" + Std.string(h);
		if (FlxG.bitmap.get(key) == null)
		{
			var img:BitmapData = new BitmapData(Std.int(w), Std.int(h * 2), false, FlxColor.BLACK);
			img.fillRect(new Rectangle(1, 1, Std.int(w - 2), Std.int(h - 2)), FlxColor.WHITE);
			img.fillRect(new Rectangle(2, Std.int(h + 2), Std.int(w - 4), Std.int(h - 4)), FlxColor.WHITE);
			FlxGraphic.fromBitmapData(img, false, key);
		}

		var back:FlxSprite = new FlxSprite();
		back.frames = FlxTileFrames.fromGraphic(FlxG.bitmap.get(key), FlxPoint.get(Std.int(w), Std.int(h)));
		back.animation.add("idle", [0]);
		back.animation.add("hover", [1]);
		add(back);

		textObject = new FlxText(0, 0, w, Lang.get(text), 18);
		textObject.color = FlxColor.BLACK;
		textObject.font = "VCR OSD Mono";
		textObject.alignment = CENTER;
		add(textObject);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		rePress -= elapsed;
		if (DropdownMenu.isOneActive) return;

		if (FlxG.mouse.justMoved)
		{
			if (overlapsPoint(FlxG.mouse.getWorldPosition(camera, _point), true, camera) && !hovered)
			{
				hovered = true;
				members[0].animation.play("hover");
			}
			else if (!overlapsPoint(FlxG.mouse.getWorldPosition(camera, _point), true, camera) && hovered)
			{
				hovered = false;
				members[0].animation.play("idle");
			}
		}

		if (hovered && Options.mouseJustPressed() && rePress <= 0 && onClicked != null)
		{
			rePress = 0.01;
			onClicked();
		}
	}
}