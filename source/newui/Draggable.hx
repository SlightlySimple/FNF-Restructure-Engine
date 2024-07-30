package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import openfl.ui.MouseCursor;
import data.Options;

class Draggable extends FlxSpriteGroup
{
	public var back:FlxSprite;
	public var draggables:Array<FlxSprite> = [];
	var heightLimit:Int = 0;
	var hovered:Bool = false;
	var dragging:Bool = false;

	override public function new(x:Float, y:Float, graphic:String, ?heightLimit:Int = 0)
	{
		super(x, y);
		this.heightLimit = heightLimit;

		back = new FlxSprite();
		if (graphic != "")
			back.loadGraphic(Paths.image("ui/editors/" + graphic));
		add(back);
		draggables.push(back);
	}

	override public function update(elapsed:Float)
	{
		if (TopMenu.busy) return;

		if (FlxG.mouse.justMoved)
		{
			hovered = false;
			for (i in 0...members.length)
			{
				if (members[i].overlapsPoint(FlxG.mouse.getWorldPosition(camera, members[i]._point), true, camera))
				{
					if (draggables.contains(members[i]))
					{
						hovered = true;
						if (heightLimit == 0 || FlxG.mouse.y <= y + heightLimit)
							UIControl.cursor = MouseCursor.HAND;
						else
							UIControl.cursor = MouseCursor.ARROW;
					}
					else
					{
						hovered = false;
						UIControl.cursor = MouseCursor.ARROW;
					}
				}
			}
		}

		super.update(elapsed);

		if (dragging)
		{
			x += FlxG.mouse.deltaX;
			y += FlxG.mouse.deltaY;
			x = Math.max(0, Math.min(FlxG.width - width, x));
			y = Math.max(0, Math.min(FlxG.height - height, y));

			if (!Options.mousePressed())
				dragging = false;
		}
		else
		{
			if (Options.mouseJustPressed() && hovered && (heightLimit == 0 || FlxG.mouse.y <= y + heightLimit))
				dragging = true;
		}
	}
}