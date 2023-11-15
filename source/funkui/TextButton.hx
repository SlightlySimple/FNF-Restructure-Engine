package funkui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import data.Options;

class TextButton extends FlxSpriteGroup
{
	public var hovered:Bool = false;
	public var rePress:Float = 0;
	public var onClicked:Void->Void = null;

	override public function new(x:Float, y:Float, ?w:Float = 20, ?h:Float = 20, ?text:String = "")
	{
		super(x, y);

		var back:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(w), Std.int(h), FlxColor.BLACK);
		add(back);

		var front:FlxSprite = new FlxSprite(1, 1).makeGraphic(Std.int(w-2), Std.int(h-2), FlxColor.WHITE);
		add(front);

		var textObject:FlxText = new FlxText(0, 0, w, Lang.get(text), 18);
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
				members[1].x++;
				members[1].y++;
				members[1].setGraphicSize(Std.int(members[0].width - 4), Std.int(members[0].height - 4));
				members[1].updateHitbox();
			}
			else if (!overlapsPoint(FlxG.mouse.getWorldPosition(camera, _point), true, camera) && hovered)
			{
				hovered = false;
				members[1].x--;
				members[1].y--;
				members[1].setGraphicSize(Std.int(members[0].width - 2), Std.int(members[0].height - 2));
				members[1].updateHitbox();
			}
		}

		if (hovered && Options.mouseJustPressed() && rePress <= 0 && onClicked != null)
		{
			rePress = 0.01;
			onClicked();
		}
	}
}