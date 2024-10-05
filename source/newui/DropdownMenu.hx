package newui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.ui.MouseCursor;
import data.Options;

using StringTools;

class DropdownMenu extends FlxSpriteGroup
{
	public var infoText:String = "";

	var hovered:Bool = false;
	var hoveredItem:Int = -1;

	public var condition:Void->String = null;
	public var onChanged:Void->Void = null;

	public var value(default, set):String = "";
	public var valueInt:Int = 0;
	public var valueList(default, set):Array<String>;
	public var valueText:Map<String, String> = new Map<String, String>();
	var valueInts:Array<Int> = [];
	var dropdownStatus:Int = 0;
	var scrollPos:Int = 0;
	var maxScroll:Int = 0;

	var state:FlxState;

	var button:FlxSprite;
	var textObject:FlxText;
	var allowSearch:Bool = false;
	var searchObject:InputText = null;
	var dropdownList:FlxSpriteGroup = null;
	var scrollBar:ScrollBar;
	var dropdownButtons:Array<FlxSprite> = [];
	var dropdownTextObjects:Array<FlxText> = [];

	public static var isOneActive:Bool = false;
	public static var currentActive:DropdownMenu = null;

	override public function new(x:Float, y:Float, text:String, list:Array<String>, ?blankOption:String = "", ?allowSearch:Bool = false)
	{
		super(x, y);
		this.allowSearch = allowSearch;

		button = new FlxSprite(Paths.image("ui/editors/dropdownMenu"));
		add(button);

		textObject = new FlxText(40, 0, Std.int(button.width - 80), (text.trim() == "" ? blankOption : text), 20);
		textObject.color = FlxColor.BLACK;
		textObject.font = "FNF Dialogue";
		textObject.alignment = CENTER;
		textObject.wordWrap = false;
		textObject.y = Std.int((button.height - textObject.height) / 2) - 3;
		add(textObject);

		if (blankOption != "")
			valueText[""] = blankOption;

		scrollBar = new ScrollBar(0, 0, FlxG.height);
		scrollBar.onChanged = function() {
			scrollPos = Std.int(scrollBar.scroll * maxScroll);
			updateDropdownList();
		};

		valueList = list.copy();
		value = text;
		if (valueInt > -1 && dropdownList.height > FlxG.height - 30)
			scrollPos = valueInt;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (dropdownStatus)
		{
			case 1:
				if (searchObject != null)
					searchObject.hasFocus = true;
				if (FlxG.mouse.justMoved)
				{
					hoveredItem = -1;
					for (i in 0...dropdownButtons.length)
					{
						var b:FlxSprite = dropdownButtons[i];
						var t:FlxText = dropdownTextObjects[i];

						b.color = FlxColor.WHITE;
						t.color = FlxColor.BLACK;
						if (FlxG.mouse.overlaps(b) && b.visible && hoveredItem == -1)
						{
							hoveredItem = i;
							b.color = 0xFF254949;
							t.color = FlxColor.WHITE;
							UIControl.cursor = MouseCursor.BUTTON;
						}
						if (valueList[valueInts[i]] == value)
							t.color = FlxColor.GRAY;
					}
				}

				if (Options.mouseJustPressed() && !scrollBar.hovered)
				{
					if (hoveredItem > -1)
					{
						value = valueList[valueInts[hoveredItem]];
						valueInt = valueInts[hoveredItem];
						FlxG.sound.play(Paths.sound("ui/editors/ClickDown"), 0.5);
						if (onChanged != null)
							onChanged();
					}

					close();
				}
				else if (FlxG.mouse.wheel != 0 && dropdownList.height > FlxG.height)
				{
					scrollPos -= FlxG.mouse.wheel * (valueList.length >= 50 ? 5 : 1);
					updateDropdownList();
					scrollBar.scroll = scrollPos / maxScroll;

					for (i in 0...dropdownButtons.length)
					{
						var b:FlxSprite = dropdownButtons[i];
						var t:FlxText = dropdownTextObjects[i];

						b.color = FlxColor.WHITE;
						t.color = FlxColor.BLACK;
						if (i == hoveredItem)
						{
							b.color = 0xFF254949;
							t.color = FlxColor.WHITE;
						}
						if (valueList[valueInts[i]] == value)
							t.color = FlxColor.GRAY;
					}
				}

			default:
				if (DropdownMenu.isOneActive) return;

				if (hovered)
					button.scale.x = FlxMath.lerp(button.scale.x, 0.9, elapsed * 10);
				else
					button.scale.x = FlxMath.lerp(button.scale.x, 1, elapsed * 10);
				button.scale.y = button.scale.x;

				if (FlxG.mouse.justMoved)
				{
					if (UIControl.mouseOver(this))
					{
						if (!hovered)
						{
							hovered = true;
							if (infoText != "")
								UIControl.infoText = infoText;
						}
					}
					else if (hovered)
						hovered = false;
				}

				if (hovered)
				{
					UIControl.cursor = MouseCursor.BUTTON;
					if (Options.mouseJustPressed())
					{
						dropdownStatus = 1;
						hovered = false;
						hoveredItem = -1;
						isOneActive = true;
						currentActive = this;
						button.scale.set(1, 1);
						FlxG.sound.play(Paths.sound("ui/editors/ClickDown"), 0.5);

						dropdownList.x = x + width;
						dropdownList.y = y;
						dropdownList.cameras = cameras;
						if (dropdownList.y + dropdownList.height > FlxG.height)
							dropdownList.y = Math.max(0, FlxG.height - dropdownList.height);

						if (searchObject != null)
						{
							searchObject.text = "";
							searchObject.caretIndex = 0;
							searchObject.hasFocus = true;
						}

						state = FlxG.state;
						if (state.subState != null)
						{
							while (state.subState != null)
								state = state.subState;
						}

						state.add(dropdownList);
						updateDropdownList();

						if (dropdownList.height > FlxG.height)
						{
							scrollBar.x = dropdownList.x + dropdownList.width;
							scrollBar.scroll = scrollPos / maxScroll;
							scrollBar.cameras = cameras;
							state.add(scrollBar);
						}
					}
				}

				if (condition != null)
				{
					var newVal:String = condition();
					if (value != newVal)
						value = newVal;
				}
		}
	}

	public function close()
	{
		state.remove(dropdownList, true);
		if (state.members.contains(scrollBar))
			state.remove(scrollBar, true);
		dropdownStatus = 0;
		isOneActive = false;
		currentActive = null;
		if (searchObject != null)
			searchObject.hasFocus = false;
	}

	function rebuildDropdownList()
	{
		if (dropdownList != null)
		{
			dropdownList.kill();
			dropdownList.destroy();
		}

		dropdownList = new FlxSpriteGroup();
		dropdownButtons = [];
		dropdownTextObjects = [];

		var longestText:String = "";
		for (v in valueList)
		{
			var test:String = (valueText.exists(v) ? valueText[v] : v);
			if (test.length > longestText.length)
				longestText = test;
		}
		var tempTextObject:FlxText = new FlxText(0, 0, 0, longestText, 16);
		tempTextObject.font = "Monsterrat";
		var w:Float = Math.max(100, tempTextObject.width + 10);
		tempTextObject.destroy();

		var yy:Float = 2;
		for (i in 0...Std.int(Math.min(50, valueList.length)))
		{
			var txt:FlxText = new FlxText(5, yy, 0, (valueText.exists(valueList[i]) ? valueText[valueList[i]] : valueList[i]), 16);
			txt.color = FlxColor.BLACK;
			txt.font = "Monsterrat";
			if (txt.width + 10 > w)
				w = txt.width + 10;
			dropdownTextObjects.push(txt);

			yy += 25;
		}

		yy = 2;
		for (i in 0...dropdownTextObjects.length)
		{
			var btn:FlxSprite = new FlxSprite(2, yy).makeGraphic(Std.int(w) - 4, 25, FlxColor.WHITE);
			btn.active = false;
			dropdownButtons.push(btn);

			yy += 25;
		}

		var h:Float = Math.min(FlxG.height - 30, yy + 2);

		var back:FlxSprite = new FlxSprite().makeGraphic(Std.int(w), Std.int(h), 0xFF254949);
		dropdownList.add(back);

		var front:FlxSprite = new FlxSprite(2, 2).makeGraphic(Std.int(w - 4), Std.int(h - 4), FlxColor.WHITE);
		dropdownList.add(front);

		if (allowSearch)
		{
			searchObject = new InputText(0, 0, Std.int(w), "");
			searchObject.callback = function(text:String, action:String) { updateDropdownList(); }
			dropdownList.add(searchObject);
			back.y += 30;
			front.y += 30;
		}

		for (b in dropdownButtons)
			dropdownList.add(b);

		for (t in dropdownTextObjects)
			dropdownList.add(t);

		if (h < FlxG.height - 30)
			scrollPos = 0;
	}

	function updateDropdownList()
	{
		if (dropdownStatus != 1) return;

		var suitableValueList:Array<String> = [];
		valueInts = [];
		for (i in 0...valueList.length)
		{
			if (searchObject == null || searchObject.text == "")
				valueInts.push(i);
			else
			{
				var testingVal:String = (valueText.exists(valueList[i]) ? valueText[valueList[i]] : valueList[i]);
				if (testingVal.toLowerCase().indexOf(searchObject.text.toLowerCase()) > -1)
					valueInts.push(i);
			}
		}
		maxScroll = valueInts.length - 1;
		scrollPos = Std.int(Math.max(0, Math.min(maxScroll, scrollPos)));

		for (ii in 0...scrollPos)
		{
			if (valueInts.length > 0)
				valueInts.shift();
		}

		for (i in valueInts)
			suitableValueList.push(valueList[i]);

		for (i in 0...dropdownButtons.length)
		{
			var b:FlxSprite = dropdownButtons[i];
			var t:FlxText = dropdownTextObjects[i];

			if (i < suitableValueList.length)
			{
				b.visible = true;
				t.visible = true;
				t.text = (valueText.exists(suitableValueList[i]) ? valueText[suitableValueList[i]] : suitableValueList[i]);
			}
			else
			{
				b.visible = false;
				t.visible = false;
			}

			if (i == 0)
				b.y = dropdownList.members[0].y + 2;
			else
				b.y = dropdownButtons[i-1].y + 25;
			t.y = b.y;
		}
	}

	public function setValueByInt(newVal:Int)
	{
		value = valueList[newVal];
		valueInt = newVal;
	}

	public function set_value(newVal:String):String
	{
		textObject.text = (valueText.exists(newVal) ? valueText[newVal] : newVal);
		while (textObject.textField.maxScrollH > 0)
			textObject.text = textObject.text.substr(1);
		valueInt = valueList.indexOf(newVal);
		return value = newVal;
	}

	public function set_valueList(newVal:Array<String>):Array<String>
	{
		valueList = newVal;
		rebuildDropdownList();
		return newVal;
	}
}