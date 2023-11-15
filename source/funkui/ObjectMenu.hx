package funkui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import data.Options;

class ObjectMenu extends FlxSpriteGroup
{
	public var hovered:Bool = false;
	public var onChanged:Void->Void = null;

	public var value(default, set):Int = 0;
	public var valueList(default, set):Array<String> = [];
	public var scrollPos:Int = 0;
	public var allowFastScroll:Bool = true;
	var dropdownList:FlxTypedSpriteGroup<FlxText>;

	public static var isOneActive:Bool = false;

	override public function new(x:Float, y:Float, w:Float, h:Float, defaultVal:Int, list:Array<String>, ?allowFastScroll:Bool = true)
	{
		super(x, y);
		this.allowFastScroll = allowFastScroll;

		var back:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(w), Std.int(h), FlxColor.BLACK);
		add(back);

		var front:FlxSprite = new FlxSprite(1, 1).makeGraphic(Std.int(w-2), Std.int(h-2), FlxColor.WHITE);
		add(front);

		dropdownList = new FlxTypedSpriteGroup<FlxText>();
		add(dropdownList);

		valueList = list.copy();
		value = defaultVal;
		scrollPos = value;
	}

	override public function update(elapsed:Float)
	{
		if (DropdownMenu.isOneActive) return;
		if (FlxG.mouse.justMoved)
		{
			if (FlxG.mouse.overlaps(members[0]) && !hovered)
			{
				hovered = true;
				isOneActive = true;
				members[1].x++;
				members[1].y++;
				members[1].setGraphicSize(Std.int(members[0].width - 4), Std.int(members[0].height - 4));
				members[1].updateHitbox();
			}
			else if (!FlxG.mouse.overlaps(members[0]) && hovered)
			{
				hovered = false;
				isOneActive = false;
				members[1].x--;
				members[1].y--;
				members[1].setGraphicSize(Std.int(members[0].width - 2), Std.int(members[0].height - 2));
				members[1].updateHitbox();
			}
		}

		if (hovered)
		{
			if (FlxG.mouse.wheel != 0)
			{
				scrollPos -= FlxG.mouse.wheel * (valueList.length >= 50 && allowFastScroll ? 5 : 1);
				updateItemsList();
			}

			if (FlxG.mouse.justMoved)
			{
				var i:Int = 0;
				var foundItem:Bool = false;
				dropdownList.forEachAlive(function(t:FlxText)
				{
					t.color = FlxColor.BLACK;
					if (FlxG.mouse.overlaps(t) && t.visible && !foundItem)
					{
						t.color = FlxColor.GRAY;
						foundItem = true;
					}
					i++;
				});
			}

			if (Options.mouseJustPressed() && valueList.length > 0)
			{
				var i:Int = 0;
				var foundItem:Bool = false;
				var clickedText:FlxText = null;
				dropdownList.forEachAlive(function(t:FlxText)
				{
					if (!foundItem)
					{
						if (FlxG.mouse.overlaps(t) && t.visible)
						{
							clickedText = t;
							foundItem = true;
						}
						else
							i++;
					}
				});
				if (clickedText != null)
				{
					value = i;
					if (onChanged != null)
						onChanged();
				}
			}
		}
	}

	function updateItemsList()
	{
		if (valueList.length <= 0) return;

		scrollPos = Std.int(Math.max(0, Math.min(valueList.length - 1, scrollPos)));

		var suitableItems:Array<FlxText> = [];

		dropdownList.forEachAlive(function(t:FlxText)
		{
			t.visible = true;
			suitableItems.push(t);
		});

		for (ii in 0...scrollPos)
		{
			suitableItems[0].visible = false;
			suitableItems.shift();
		}

		var i:Int = 0;
		for (item in suitableItems)
		{
			if (i == 0)
				item.y = dropdownList.members[0].y;
			else
				item.y = suitableItems[i-1].y + suitableItems[i-1].height;
			i++;
		}

		dropdownList.forEachAlive(function(t:FlxText)
		{
			if (t.y + t.height > members[0].y + members[0].height)
				t.visible = false;
		});
	}

	public function set_value(newVal:Int):Int
	{
		var i:Int = 0;
		if (valueList.length > 0)
		{
			dropdownList.forEachAlive(function(t:FlxText)
			{
				if (i == newVal)
					t.borderColor = 0xCCCCCCFF;
				else
					t.borderColor = FlxColor.TRANSPARENT;
				i++;
			});
		}

		return value = newVal;
	}

	public function set_valueList(newVal:Array<String>):Array<String>
	{
		valueList = newVal;

		dropdownList.forEachAlive(function(t:FlxText)
		{
			t.kill();
			t.destroy();
		});
		dropdownList.clear();

		if (valueList.length > 0)
		{
			var w:Float = members[0].width;
			var yy:Float = 0;
			for (i in 0...valueList.length)
			{
				var dropdownTextObject:FlxText = new FlxText(5, yy, w - 10, valueList[i], 12);
				dropdownTextObject.color = FlxColor.BLACK;
				dropdownTextObject.borderStyle = OUTLINE;
				if (i == value)
					dropdownTextObject.borderColor = 0xCCCCCCFF;
				else
					dropdownTextObject.borderColor = FlxColor.TRANSPARENT;
				dropdownTextObject.font = "VCR OSD Mono";
				yy += dropdownTextObject.height;
				dropdownList.add(dropdownTextObject);
			}

			updateItemsList();
		}

		return newVal;
	}
}