package funkui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class DropdownMenu extends FlxSpriteGroup
{
	var hovered:Bool = false;
	public var onChanged:Void->Void = null;

	public var value(default, set):String = "";
	public var valueInt:Int = 0;
	public var valueList:Array<String>;
	var valueInts:Array<Int> = [];
	var dropdownStatus:Int = 0;
	var scrollPos:Int = 0;

	var textObject:FlxText;
	var searchObject:InputText = null;
	var dropdownList:FlxSpriteGroup;
	var dropdownTextObjects:Array<FlxText>;

	public static var isOneActive:Bool = false;

	override public function new(x:Float, y:Float, w:Float, h:Float, text:String, list:Array<String>, ?fontSize:Int = 16, ?allowSearch:Bool = false)
	{
		super(x, y);

		var back:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(w), Std.int(h), FlxColor.BLACK);
		add(back);

		var front:FlxSprite = new FlxSprite(1, 1).makeGraphic(Std.int(w-2), Std.int(h-2), FlxColor.WHITE);
		add(front);

		textObject = new FlxText(0, 0, w, text, fontSize);
		textObject.color = FlxColor.BLACK;
		textObject.font = "VCR OSD Mono";
		textObject.alignment = CENTER;
		add(textObject);

		if (allowSearch)
		{
			searchObject = new InputText(0, 0, Std.int(w), "", fontSize);
			searchObject.visible = false;
			searchObject.callback = function(text:String, action:String) { updateItemsList(); }
			add(searchObject);
		}

		valueList = list.copy();
		value = text;
		if (valueInt > -1)
			scrollPos = valueInt;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (dropdownStatus)
		{
			case 1:
				if (FlxG.mouse.justMoved)
				{
					var foundItem:Bool = false;
					for (t in dropdownTextObjects)
					{
						t.color = FlxColor.BLACK;
						if (FlxG.mouse.overlaps(t) && t.visible)
						{
							t.color = FlxColor.GRAY;
							foundItem = true;
						}
					}
				}

				if (FlxG.mouse.justPressed)
				{
					var i:Int = 0;
					var clickedText:FlxText = null;
					for (t in dropdownTextObjects)
					{
						if (clickedText == null)
						{
							if (FlxG.mouse.overlaps(t) && t.visible)
								clickedText = t;
							else
								i++;
						}
					}
					if (clickedText != null)
					{
						value = clickedText.text;
						valueInt = valueInts[i];
						if (onChanged != null)
							onChanged();
					}

					remove(dropdownList);
					dropdownList.kill();
					dropdownList.destroy();
					dropdownStatus = 0;
					isOneActive = false;
					if (searchObject != null)
					{
						searchObject.visible = false;
						searchObject.hasFocus = false;
					}

					members[1].x--;
					members[1].y--;
					members[1].setGraphicSize(Std.int(members[0].width - 2), Std.int(members[0].height - 2));
					members[1].updateHitbox();
				}
				else if (FlxG.mouse.wheel != 0)
				{
					scrollPos -= FlxG.mouse.wheel * (valueList.length >= 50 ? 5 : 1);
					updateItemsList();
				}

			default:
				if (DropdownMenu.isOneActive) return;
				if (FlxG.mouse.justMoved)
				{
					if (FlxG.mouse.overlaps(members[0]) && !hovered)
					{
						hovered = true;
						members[1].x++;
						members[1].y++;
						members[1].setGraphicSize(Std.int(members[0].width - 4), Std.int(members[0].height - 4));
						members[1].updateHitbox();
					}
					else if (!FlxG.mouse.overlaps(members[0]) && hovered)
					{
						hovered = false;
						members[1].x--;
						members[1].y--;
						members[1].setGraphicSize(Std.int(members[0].width - 2), Std.int(members[0].height - 2));
						members[1].updateHitbox();
					}
				}

				if (hovered && FlxG.mouse.justPressed)
				{
					dropdownStatus = 1;
					hovered = false;
					isOneActive = true;
					if (searchObject != null)
					{
						searchObject.visible = true;
						searchObject.text = "";
						searchObject.caretIndex = 0;
						searchObject.hasFocus = true;
					}

					dropdownList = new FlxSpriteGroup();
					dropdownTextObjects = [];

					var w:Float = members[0].width;

					var yy:Float = 0;
					var yy2:Float = 0;
					for (i in 0...Std.int(Math.min(30, valueList.length)))
					{
						var dropdownTextObject:FlxText = new FlxText(5, yy, w - 10, valueList[i], 12);
						dropdownTextObject.color = FlxColor.BLACK;
						dropdownTextObject.font = "VCR OSD Mono";
						if (i - scrollPos < 0)
							dropdownTextObject.visible = false;
						else
							yy += dropdownTextObject.height;
						yy2 += dropdownTextObject.height;
						dropdownTextObjects.push(dropdownTextObject);
					}

					var h:Float = Math.min(FlxG.height, yy2 + 4);

					var back:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(w), Std.int(h), FlxColor.BLACK);
					dropdownList.add(back);

					var front:FlxSprite = new FlxSprite(1, 1).makeGraphic(Std.int(w-2), Std.int(h-2), FlxColor.WHITE);
					dropdownList.add(front);

					for (t in dropdownTextObjects)
						dropdownList.add(t);

					dropdownList.y += members[0].height;
					add(dropdownList);
					updateItemsList();
				}
		}
	}

	function updateItemsList()
	{
		if (dropdownStatus != 1) return;

		var suitableValueList:Array<String> = [];
		valueInts = [];
		for (i in 0...valueList.length)
		{
			if (searchObject == null || searchObject.text == "" || valueList[i].toLowerCase().indexOf(searchObject.text.toLowerCase()) > -1)
				valueInts.push(i);
		}
		scrollPos = Std.int(Math.max(0, Math.min(valueInts.length - 1, scrollPos)));

		for (ii in 0...scrollPos)
		{
			if (valueInts.length > 0)
				valueInts.shift();
		}

		for (i in valueInts)
			suitableValueList.push(valueList[i]);

		var i:Int = 0;
		for (t in dropdownTextObjects)
		{
			if (i < suitableValueList.length)
			{
				t.visible = true;
				t.text = suitableValueList[i];
			}
			else
				t.visible = false;

			if (i == 0)
				t.y = dropdownList.members[0].y;
			else
				t.y = dropdownTextObjects[i-1].y + dropdownTextObjects[i-1].height;

			i++;
		}
	}

	public function setValueByInt(newVal:Int)
	{
		value = valueList[newVal];
		valueInt = newVal;
	}

	public function set_value(newVal:String):String
	{
		textObject.text = newVal;
		valueInt = valueList.indexOf(newVal);
		return value = newVal;
	}
}