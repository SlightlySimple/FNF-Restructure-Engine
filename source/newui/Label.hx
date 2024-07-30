package newui;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;

using StringTools;

class Label extends FlxText
{
	override public function new(text:String)
	{
		super(0, 0, 0, Lang.get(text));

		setFormat("FNF Dialogue", 22, FlxColor.WHITE, CENTER, OUTLINE, 0xFF254949);
		wordWrap = false;
		borderSize = 2;
	}
}