package funkui;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class Label extends FlxText
{
	override public function new(text:String, object:FlxSprite)
	{
		super(object.x, object.y - 16, 0, Lang.get(text), 12);
		if (this.text != "" && !this.text.endsWith(":"))
			this.text += ":";
		color = FlxColor.BLACK;
		font = "VCR OSD Mono";
	}
}