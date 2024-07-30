package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.ui.MouseCursor;
import data.Options;

class ObjectMenu extends Draggable
{
	public var items:Array<String> = [];
	public var onClicked:Int->Void = null;
	public var onRightClicked:Int->Void = null;
	public var selected:Int = -1;

	var bar:FlxSprite;
	var text:FlxTypedSpriteGroup<FlxText> = null;
	var hoveredIndex:Int = -1;
	public var listOffset:Int = -1;

	override public function new(x:Float, y:Float, graphic:String)
	{
		super(x, y, graphic, 50);

		bar = new FlxSprite(20, 0).makeGraphic(240, 24, 0xFF254949);
		bar.visible = false;
		add(bar);

		text = new FlxTypedSpriteGroup<FlxText>();
		add(text);

		for (i in 0...16)
		{
			var txt:FlxText = new FlxText(20, 50 + (i * 20), 240, "").setFormat("FNF Dialogue", 20, FlxColor.BLACK, CENTER);
			txt.wordWrap = false;
			text.add(txt);
		}

		text.members[0].flipY = true;
		text.members[0].text = "V";
		text.members[15].text = "V";
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justMoved)
		{
			hoveredIndex = -1;
			bar.visible = false;
			var i:Int = 0;
			text.forEachAlive(function(txt:FlxText) {
				if (txt.visible && FlxG.mouse.overlaps(txt, camera) && hoveredIndex == -1)
				{
					txt.color = FlxColor.WHITE;
					hoveredIndex = i;
					bar.visible = true;
					bar.y = txt.y;
					UIControl.cursor = MouseCursor.BUTTON;
				}
				else
					txt.color = FlxColor.BLACK;
				i++;
			});
		}

		if (hoveredIndex > -1)
		{
			if (Options.mouseJustPressed())
			{
				if (hoveredIndex == 15)
				{
					if (items.length > 15 + listOffset)
					{
						listOffset++;
						refreshText();
					}
				}
				else if (hoveredIndex == 0)
				{
					if (listOffset >= 0)
					{
						listOffset--;
						refreshText();
					}
				}
				else
				{
					selected = hoveredIndex + listOffset;
					onClicked(selected);
					refreshText();
				}
			}

			if (Options.mouseJustPressed(true) && onRightClicked != null && hoveredIndex > 0 && hoveredIndex < 15)
				onRightClicked(hoveredIndex + listOffset);
		}
	}

	public function refreshText()
	{
		if (text != null)
		{
			for (i in 0...text.members.length)
				refreshSingleText(i);
		}
	}

	public function refreshSingleText(i:Int)
	{
		if (text != null)
		{
			var txt:FlxText = text.members[i];
			switch (i)
			{
				case 0:
					if (listOffset >= 0)
						txt.visible = true;
					else
						txt.visible = false;

				case 15:
					if (items.length > i + listOffset)
						txt.visible = true;
					else
						txt.visible = false;

				default:
					if (items.length > i + listOffset)
					{
						txt.visible = true;
						txt.text = items[i + listOffset];
						if (i + listOffset == selected)
							txt.text = "> " + txt.text;
					}
					else
						txt.visible = false;
			}
		}
	}
}