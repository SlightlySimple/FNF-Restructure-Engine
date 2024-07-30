package newui;

import flixel.text.FlxText;
import flixel.util.FlxColor;

class InfoBox extends Draggable
{
	var infoText:FlxText;

	override public function new(x:Int, y:Int)
	{
		super(x, y, "infoBox");

		infoText = new FlxText(15, 15, 250, "");
		infoText.setFormat("FNF Dialogue", 20, FlxColor.WHITE, LEFT, OUTLINE, 0xFF254949);
		infoText.borderSize = 2;
		add(infoText);
		draggables.push(infoText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (infoText.text != UIControl.infoText)
			infoText.text = UIControl.infoText;
	}
}