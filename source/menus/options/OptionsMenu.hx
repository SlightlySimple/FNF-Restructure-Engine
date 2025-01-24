package menus.options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxRect;

import data.Noteskins;
import data.Options;
import menus.UINavigation;
import menus.options.OptionsSubMenu;
import newui.PopupWindow;
import objects.AnimatedSprite;
import objects.Note;

using StringTools;

typedef OptionsMenuCategory =
{
	label:String,
	contents:Array<OptionMenuStuff>
}

typedef OptionMenuStuff =
{
	type:String,
	label:String,
	?description:String,
	?variable:String,
	?defValue:Dynamic,
	?options:Array<String>,
	?range:Array<Float>,
	?scrollSpeed:Float,
	?changeValue:Float
}

class OptionsMenuCursor extends FlxText
{
	public var pos:Array<Float> = [0, 0];

	override public function new(text:String, size:Int, _offset:Float)
	{
		super(0, 0, 0, text, size);
		setFormat("VCR OSD Mono", size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		offset.set(width * _offset, height / 2);
		pixelPerfect = true;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		x = FlxMath.lerp(x, pos[0], (x == 0 ? 1 : FlxG.elapsed * 20));
		y = FlxMath.lerp(y, pos[1], (y == 0 ? 1 : FlxG.elapsed * 20));
	}

	override public function setPosition(x:Float = 0, y:Float = 0)
	{
		super.setPosition(x, y);
		pos = [x, y];
	}
}

class OptionsMenuItem extends FlxSpriteGroup
{
	public var ystart:Float = 0;
	public var goalY:Float = 0;

	public var text(default, set):String = "";
	public var textR(default, set):String = "";
	public var size(default, set):Int = 32;
	public var showCheck(default, set):Bool = false;
	public var checked(default, set):Bool = false;
	public var isLabel(default, set):Bool = false;

	var textObject:FlxText;
	var textObjectR:FlxText;
	var check:AnimatedSprite;

	override public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		ystart = y;
		goalY = y;

		textObject = new FlxText(0, 0, 0, "", 32);
		textObject.font = "VCR OSD Mono";
		textObject.borderColor = FlxColor.BLACK;
		textObject.borderStyle = OUTLINE;
		add(textObject);

		textObjectR = new FlxText(0, 0, 0, "", 32);
		textObjectR.font = "VCR OSD Mono";
		textObjectR.borderColor = FlxColor.BLACK;
		textObjectR.borderStyle = OUTLINE;
		add(textObjectR);

		check = new AnimatedSprite(9999, 0, Paths.sparrow("ui/checkmark"));
		check.addAnim("unchecked", "unchecked", 24, false);
		check.addAnim("checked", "checked", 24, false);
		check.addAnim("uncheck", "uncheck", 24, false);
		check.addAnim("check", "check0", 24, false);
		check.playAnim("unchecked");
		check.animation.finishCallback = function(anim:String) {
			if (!anim.endsWith("ed"))
				check.playAnim(anim + "ed");
		}
		add(check);
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		y = FlxMath.lerp(y, goalY, FlxG.elapsed * 20);
	}

	public function initialCheck()
	{
		if (!check.animation.curAnim.name.endsWith("ed"))
			check.playAnim(check.animation.curAnim.name + "ed");
	}

	public function set_text(val:String):String
	{
		textObject.text = val;
		showCheck = showCheck;
		check.y = textObject.y + ((textObject.height - check.height) / 2);
		textObjectR.x = x + textObject.width + 50;
		return text = val;
	}

	public function set_textR(val:String):String
	{
		textObjectR.text = val;
		return textR = val;
	}

	public function set_size(val:Int):Int
	{
		textObject.size = val;
		textObjectR.size = val;
		showCheck = showCheck;
		check.y = textObject.y + Math.round(textObject.height - check.height);
		textObjectR.x = x + textObject.width + 50;
		return size = val;
	}

	public function set_showCheck(val:Bool):Bool
	{
		if (val)
			check.x = x + textObject.width + 25;
		else
			check.x = 9999;
		return showCheck = val;
	}

	public function set_checked(val:Bool):Bool
	{
		var anim:String = val ? "check" : "uncheck";
		if (!check.animation.curAnim.name.startsWith(anim))
			check.playAnim(anim);
		return checked = val;
	}

	public function set_isLabel(val:Bool):Bool
	{
		if (val)
		{
			size = 40;
			textObject.borderSize = 2;
		}
		else
		{
			size = 32;
			textObject.borderSize = 1;
		}
		return isLabel = val;
	}
}

class OptionsMenu extends FlxGroup
{
	var optMenuData:Array<OptionsMenuCategory> = [];

	var optionsGroupList:FlxSpriteGroup;
	var optionsGroupTextList:FlxTypedSpriteGroup<FlxText>;

	var optionsCategories:Array<OptionsCategory> = [];

	var cursLeft:OptionsMenuCursor;
	var cursRight:OptionsMenuCursor;

	var curCat:Int = 0;

	var nav:UINumeralNavigation;

	var from:Int = 0;
	public var exitCallback:Void->Void = null;

	public function new(from:Int = 0)
	{
		super();
		this.from = from;

		if (from == 1)
		{
			var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0.6;
			add(bg);
		}

		Noteskins.loadNoteskins();
		var noteskinOptions:Array<String> = Noteskins.noteskinOptions();

		var hitsoundOptions:Array<String> = Paths.listFiles("hitsounds/",".ogg");
		hitsoundOptions.unshift("None");

		var languageOptions:Array<String> = Paths.listFiles("languages/", "");
		languageOptions.unshift("");

		var editorMusicOptions:Array<String> = Paths.listFiles("music/editors/",".ogg");

		var cats:Array<OptionsMenuCategory> = Options.getOptionsData();
		for (c in cats)
		{
			optMenuData.push(c);
			for (o in c.contents)
			{
				if (o.type == "choicesPopulate")
				{
					switch (o.variable)
					{
						case "noteskin": o.options = noteskinOptions;
						case "hitsound": o.options = hitsoundOptions;
						case "language": o.options = languageOptions;
						case "editorMusic": o.options = editorMusicOptions;
					}
				}
			}
		}

		optionsGroupList = new FlxSpriteGroup();
		add(optionsGroupList);

		optionsGroupTextList = new FlxTypedSpriteGroup<FlxText>();
		add(optionsGroupTextList);

		for (i in 0...optMenuData.length)
		{
			var optGroup:FlxSprite = new FlxSprite( 50, 50 + (i * 60) ).makeGraphic( 250, 50, FlxColor.BLACK );
			optionsGroupList.add(optGroup);

			var optGroupTxt:FlxText = new FlxText( 50, 50 + (i * 60), 0, Lang.get(optMenuData[i].label), 24);
			optGroupTxt.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			optGroupTxt.x += (optGroup.width - optGroupTxt.width) / 2;
			optGroupTxt.y += (optGroup.height - optGroupTxt.height) / 2;
			optionsGroupTextList.add(optGroupTxt);

			var optCategory:OptionsCategory = new OptionsCategory(optMenuData[i], from);
			optCategory.exitCallback = function() {
				exitCat();
				Options.refreshSaveData();
			}
			optCategory.showCallback = showOptionsMenu;
			optCategory.hideCallback = hideOptionsMenu;
			optionsCategories.push(optCategory);
		}

		cursLeft = new OptionsMenuCursor(">", 32, 1);
		add(cursLeft);

		cursRight = new OptionsMenuCursor("<", 32, 0);
		add(cursRight);

		selectCat();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		nav = new UINumeralNavigation(null, selectCat, enterCat, function() {
			if (exitCallback != null)
				exitCallback();
			else
				FlxG.switchState(new MainMenuState());
		}, selectCat, enterCat);
		nav.rightClick = nav.back;
		add(nav);
	}

	function selectCat(change:Int = 0)
	{
		if (members.contains(optionsCategories[curCat]))
			remove(optionsCategories[curCat], true);

		curCat = Util.loop(curCat + change, 0, optMenuData.length - 1);

		for (i in 0...optMenuData.length)
		{
			if (i == curCat)
			{
				optionsGroupList.members[i].alpha = 0.6;
				optionsGroupTextList.members[i].alpha = 1;
				cursLeft.pos[0] = optionsGroupTextList.members[i].x - 10;
				cursLeft.pos[1] = optionsGroupTextList.members[i].getMidpoint().y;
				cursRight.pos[0] = optionsGroupTextList.members[i].x + optionsGroupTextList.members[i].width + 10;
				cursRight.pos[1] = optionsGroupTextList.members[i].getMidpoint().y;
			}
			else
			{
				optionsGroupList.members[i].alpha = 0.4;
				optionsGroupTextList.members[i].alpha = 0.5;
			}
		}

		add(optionsCategories[curCat]);
	}

	function enterCat()
	{
		nav.locked = true;
		optionsCategories[curCat].menuActive = true;
	}

	function exitCat()
	{
		nav.locked = false;
		optionsCategories[curCat].menuActive = false;
	}

	public function showOptionsMenu()
	{
		optionsGroupList.visible = true;
		optionsGroupTextList.visible = true;
		cursLeft.visible = true;
		cursRight.visible = true;
	}

	public function hideOptionsMenu()
	{
		optionsGroupList.visible = false;
		optionsGroupTextList.visible = false;
		cursLeft.visible = false;
		cursRight.visible = false;
	}
}

class OptionsCategory extends FlxGroup
{
	var data:OptionsMenuCategory;
	public var menuActive(default, set):Bool = false;

	var curOption:Int = 0;
	var secondColumn:Bool = false;
	var holding:Bool = false;
	var holdTimer:Float = 0;
	var holdTick:Float = 0;

	var menuState:Int = 0;

	var bg:FlxSprite;
	var optionsDisplay:FlxTypedSpriteGroup<OptionsMenuItem>;
	var descBox:FlxSprite;
	var descText:FlxText;
	var cursor:OptionsMenuCursor;
	var yOffset:Float = 0;
	var maxY:Float = 0;

	var nav:UINumeralNavigation;

	var from:Int = 0;
	public var exitCallback:Void->Void = null;
	public var showCallback:Void->Void = null;
	public var hideCallback:Void->Void = null;

	public override function new(data:OptionsMenuCategory, ?from:Int = 0)
	{
		super();
		this.data = data;
		this.from = from;

		bg = new FlxSprite(300, 50).makeGraphic(Std.int(FlxG.width - 350), Std.int(FlxG.height - 100), FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		optionsDisplay = new FlxTypedSpriteGroup<OptionsMenuItem>(300, 50);
		optionsDisplay.clipRect = new FlxRect(0, 30, FlxG.width, FlxG.height - 160);
		add(optionsDisplay);

		descBox = new FlxSprite(300, Std.int(FlxG.height - 100)).makeGraphic(Std.int(FlxG.width - 350), 50, FlxColor.BLACK);
		descBox.alpha = 0.5;
		descBox.visible = false;
		add(descBox);

		descText = new FlxText(Std.int(descBox.x + 15), Std.int(descBox.y + 3), Std.int(descBox.width - 30), '', 20);
		descText.font = "VCR OSD Mono";
		descText.borderColor = FlxColor.BLACK;
		descText.borderStyle = OUTLINE;
		if (from == 1)
			descText.text = Lang.get("#options.menu.inGameNotice");
		add(descText);

		cursor = new OptionsMenuCursor(">", 32, 0);
		cursor.visible = false;
		add(cursor);

		var yy:Int = 30;
		for (i in 0...data.contents.length)
		{
			var opt = data.contents[i];
			var optItem:OptionsMenuItem = new OptionsMenuItem(30, yy);
			optItem.alpha = 0.4;
			if (opt.type == "label" && opt.label != "")
			{
				yy += 10;
				optItem.isLabel = true;
				optItem.alpha = 0.5;
				if (i > 0)
				{
					yy += 20;
					optItem.y += 20;
				}
			}
			optionsDisplay.add(optItem);
			optItem.ystart = optItem.y;
			optItem.goalY = optItem.y;

			setupOptionText(i);

			if (opt.label != "")
				yy += 35;
		}

		maxY = Math.max(0, yy - FlxG.height + 150);

		nav = new UINumeralNavigation(changeCurrentOption, selectOption, doAcceptCurrentOption, function() {
			if (exitCallback != null)
				exitCallback();
		}, selectOption, doAcceptCurrentOption);
		nav.uiSounds = [false, false, true];
		nav.rightClick = nav.back;
		nav.locked = true;
		add(nav);
	}

	override function update(elapsed:Float)
	{
		optionsDisplay.clipRect = optionsDisplay.clipRect;

		var opt:OptionMenuStuff = data.contents[curOption];
		if (menuState == 1)
		{
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1)
			{
				var keysArray:Array<FlxKey> = Reflect.getProperty(Options.options.keys, opt.variable);
				var keyPressedKey:FlxKey = cast keyPressed;
				keysArray[secondColumn ? 1 : 0] = keyPressedKey;

				var opposite:Int = (secondColumn ? 0 : 1);
				if(keysArray[opposite] == keysArray[1 - opposite]) {
					keysArray[opposite] = FlxKey.NONE;
				}
				Reflect.setProperty(Options.options.keys, opt.variable, keysArray);

				switch (opt.variable)
				{
					case "vol_up": FlxG.sound.volumeUpKeys = Options.getKeys("vol_up");
					case "vol_down": FlxG.sound.volumeDownKeys = Options.getKeys("vol_down");
					case "mute": FlxG.sound.muteKeys = Options.getKeys("mute");
					case "screenshot": Main.screenshotKeys = Options.getKeys("screenshot");
					case "fullscreen": Main.fullscreenKeys = Options.getKeys("fullscreen");
				}

				FlxG.sound.play(Paths.sound('ui/confirmMenu'));
				menuState = 0;
				nav.locked = false;
				updateOptionText(curOption);
			}
		}
		else if (holding && !nav.locked)
		{
			holdTimer -= elapsed;
			holdTick -= elapsed;
			if (holdTimer <= 0 && holdTick <= 0)
			{
				if (Options.keyPressed("ui_left"))
					changeCurrentOption(-1);
				if (Options.keyPressed("ui_right"))
					changeCurrentOption(1);
				holdTick = opt.scrollSpeed;
			}
			if (Options.keyJustReleased("ui_left") || Options.keyJustReleased("ui_right"))
				holding = false;
		}

		super.update(elapsed);
	}

	function selectOption(change:Int = 0)
	{
		curOption = Util.loop(curOption + change, 0, data.contents.length - 1);

		if (data.contents[curOption].type == "label")
		{
			while (data.contents[curOption].type == "label")
			{
				if (change == 0)
					curOption++;
				else
					curOption += Std.int(change / Math.abs(change));

				curOption = Util.loop(curOption, 0, data.contents.length - 1);
			}
		}

		if (change != 0)
			FlxG.sound.play(Paths.sound('ui/scrollMenu'));

		var optionY:Int = Std.int(optionsDisplay.members[curOption].y);
		if (optionY < (FlxG.height / 2) - 125)
		{
			while (optionY < (FlxG.height / 2) - 125)
			{
				yOffset += 30;
				optionY += 30;
			}
		}
		if (optionY > (FlxG.height / 2) + 125)
		{
			while (optionY > (FlxG.height / 2) + 125)
			{
				yOffset -= 30;
				optionY -= 30;
			}
		}
		yOffset = Math.min(0, Math.max(-maxY, yOffset));

		var i:Int = 0;
		optionsDisplay.forEachAlive(function(txt:OptionsMenuItem) {
			txt.x = optionsDisplay.x + 30;
			txt.goalY = txt.ystart + yOffset;
			if (txt.isLabel)
				txt.alpha = 1;
			else
				txt.alpha = 0.7;
			if (i == curOption)
			{
				cursor.pos[0] = txt.x;
				cursor.pos[1] = txt.goalY + (txt.height / 2);
				txt.x += 30;
				txt.alpha = 1;
			}
			updateOptionText(i);
			i++;
		});

		descText.text = Lang.get(data.contents[curOption].description);
	}

	function changeCurrentOption(change:Int = 0)
	{
		var opt:OptionMenuStuff = data.contents[curOption];

		switch (opt.type)
		{
			case "bool":
				if (opt.options != null && opt.options.length == 2)
				{
					setOptionValue(curOption, !getOptionValue(curOption));
					switch (opt.variable)
					{
						case "autoPause":
							FlxG.autoPause = Options.options.autoPause;
						case "fps":
							Main.fpsVisible = Options.options.fps;
					}
					FlxG.sound.play(Paths.sound('ui/scrollMenu'));
				}

			case "choicesPopulate":
				var valInt:Int = opt.options.indexOf(getOptionValue(curOption));
				valInt = Util.loop(valInt + change, 0, opt.options.length - 1);

				setOptionValue(curOption, opt.options[valInt]);
				if (opt.variable == "noteskin")
				{
					Noteskins.noteskinName = Options.options.noteskin;
					SustainNote.noteGraphics.clear();
				}
				FlxG.sound.play(Paths.sound('ui/scrollMenu'));

			case "choices":
				var valInt:Int = getOptionValue(curOption);
				valInt = Util.loop(valInt + change, 0, opt.options.length - 1);

				setOptionValue(curOption, valInt);
				FlxG.sound.play(Paths.sound('ui/scrollMenu'));

			case "float" | "int" | "percent":
				var start:Float = getOptionValue(curOption);
				var goal:Float = start + (opt.changeValue * change);
				if (opt.changeValue != Math.round(opt.changeValue))
					goal = Math.round(goal / opt.changeValue) * opt.changeValue;
				if (goal < opt.range[0])
					goal = opt.range[0];
				if (goal > opt.range[1])
					goal = opt.range[1];
				setOptionValue(curOption, goal);
				if (opt.type == "int")
					setOptionValue(curOption, Std.int(goal));
				if (start != goal)
					FlxG.sound.play(Paths.sound('ui/scrollMenu'));
				if (opt.scrollSpeed > 0 && !holding)
				{
					holding = true;
					holdTimer = 0.6;
				}

				switch (opt.variable)
				{
					case "framerate":
						FlxG.updateFramerate = Options.options.framerate;
						FlxG.drawFramerate = Options.options.framerate;
				}

			case "control":
				secondColumn = !secondColumn;
				FlxG.sound.play(Paths.sound('ui/scrollMenu'));
		}

		updateOptionText(curOption);
	}

	function doAcceptCurrentOption()
	{
		var opt:OptionMenuStuff = data.contents[curOption];

		switch (opt.type)
		{
			case "bool":
				if (opt.options == null || opt.options.length != 2)
				{
					setOptionValue(curOption, !getOptionValue(curOption));
					switch (opt.variable)
					{
						case "autoPause":
							FlxG.autoPause = Options.options.autoPause;
						case "fps":
							Main.fpsVisible = Options.options.fps;
					}
					FlxG.sound.play(Paths.sound('ui/scrollMenu'));
				}

			case "control":
				FlxG.sound.play(Paths.sound('ui/confirmMenu'));
				menuState = 1;
				nav.locked = true;

			case "color":
				FlxG.sound.play(Paths.sound('ui/confirmMenu'));
				nav.locked = true;
				FlxG.mouse.visible = true;

				new ColorPicker(getOptionValue(curOption), function(clr:FlxColor) {
					setOptionValue(curOption, clr);
					nav.locked = false;
					FlxG.mouse.visible = false;
				}, function() {
					nav.locked = false;
					FlxG.mouse.visible = false;
				});

			case "function":
				var func = Reflect.getProperty(this, opt.variable);
				if (Reflect.isFunction(func))
					Reflect.callMethod(this, func, []);

			case "testKeybinds":
				testKeybinds(opt.variable, opt.options);

			case "noteColors":
				FlxG.sound.play(Paths.sound('ui/confirmMenu'));
				noteColors(opt.variable);
		}

		updateOptionText(curOption);
	}

	function setOptionValue(option:Int, value:Dynamic)
	{
		var opt:OptionMenuStuff = data.contents[option];
		Reflect.setProperty(Options.options, opt.variable, value);
	}

	function getOptionValue(option:Int):Dynamic
	{
		var opt:OptionMenuStuff = data.contents[option];
		return Reflect.getProperty(Options.options, opt.variable);
	}

	function setupOptionText(option:Int)
	{
		var opt:OptionMenuStuff = data.contents[option];
		var item:OptionsMenuItem = optionsDisplay.members[option];
		item.text = Lang.get(opt.label);
		item.textR = "";
		item.showCheck = false;

		if (opt.type == "bool" && (opt.options == null || opt.options.length != 2))
		{
			item.showCheck = true;
			item.checked = getOptionValue(option);
			item.initialCheck();
		}

		updateOptionText(option);
	}

	function updateOptionText(option:Int)
	{
		var opt:OptionMenuStuff = data.contents[option];
		var item:OptionsMenuItem = optionsDisplay.members[option];

		switch (opt.type)
		{
			case "bool":
				if (opt.options == null || opt.options.length != 2)
				{
					item.showCheck = true;
					item.checked = getOptionValue(option);
				}
				else
				{
					item.textR = Lang.get(opt.options[getOptionValue(option) ? 0 : 1]);
					if (menuActive && option == curOption)
						item.textR = "< " + item.textR + " >";
				}

			case "choicesPopulate":
				item.textR = (getOptionValue(option) == "" ? Lang.get(opt.label.replace(".name", ".blank")) : getOptionValue(option));
				if (menuActive && option == curOption)
					item.textR = "< " + item.textR + " >";

			case "choices":
				item.textR = Lang.get(opt.options[getOptionValue(option)]);
				if (menuActive && option == curOption)
					item.textR = "< " + item.textR + " >";

			case "float" | "int":
				item.textR = Std.string(getOptionValue(option));
				if (menuActive && option == curOption)
					item.textR = "< " + item.textR + " >";

			case "percent":
				item.textR = Std.string(getOptionValue(option) * 100) + "%";
				if (menuActive && option == curOption)
					item.textR = "< " + item.textR + " >";

			case "control":
				var keys:Array<FlxKey> = Reflect.getProperty(Options.options.keys, opt.variable);
				var keyStrings:Array<String> = [Lang.get("#options.key." + keys[0].toString().toLowerCase(), keys[0].toString()), Lang.get("#options.key." + keys[1].toString().toLowerCase(), keys[1].toString())];
				if (keys[0] == FlxKey.NONE)
					keyStrings[0] = Lang.get("#options.key.none");
				if (keys[1] == FlxKey.NONE)
					keyStrings[1] = Lang.get("#options.key.none");
				if (menuActive && option == curOption)
				{
					if (secondColumn)
					{
						if (menuState == 1)
							item.textR = keyStrings[0] + " | >   <";
						else
							item.textR = keyStrings[0] + " | > " + keyStrings[1] + " <";
					}
					else
					{
						if (menuState == 1)
							item.textR = ">   < | " + keyStrings[1];
						else
							item.textR = "> " + keyStrings[0] + " < | " + keyStrings[1];
					}
				}
				else
					item.textR = keyStrings[0] + " | " + keyStrings[1];
		}
	}

	function showOptionsMenu()
	{
		if (showCallback != null)
			showCallback();
		bg.visible = true;
		optionsDisplay.visible = true;
		descBox.visible = true;
		descText.visible = true;
		cursor.visible = true;
		selectOption();
	}

	function hideOptionsMenu()
	{
		if (hideCallback != null)
			hideCallback();
		bg.visible = false;
		optionsDisplay.visible = false;
		descBox.visible = false;
		descText.visible = false;
		cursor.visible = false;
	}

	public function set_menuActive(val:Bool):Bool
	{
		nav.locked = !val;
		descBox.visible = val;
		cursor.visible = val;
		menuActive = val;

		if (val)
			selectOption();
		else
		{
			if (from == 1)
				descText.text = Lang.get("#options.menu.inGameNotice");
			else
				descText.text = "";

			var i:Int = 0;
			optionsDisplay.forEachAlive(function(txt:OptionsMenuItem) {
				txt.x = optionsDisplay.x + 30;
				if (txt.isLabel)
					txt.alpha = 0.5;
				else
					txt.alpha = 0.4;
				updateOptionText(i);
				i++;
			});
		}

		return val;
	}

	function resetControls()
	{
		FlxG.sound.play(Paths.sound("ui/confirmMenu"));

		var cats:Array<OptionsMenuCategory> = Options.getOptionsData();
		for (c in cats)
		{
			for (o in c.contents)
			{
				if (o.type == "control")
				{
					Reflect.setProperty(Options.options.keys, o.variable, [FlxKey.fromString(o.defValue[0]), FlxKey.fromString(o.defValue[1])]);

					switch (o.variable)
					{
						case "vol_up": FlxG.sound.volumeUpKeys = Options.getKeys("vol_up");
						case "vol_down": FlxG.sound.volumeDownKeys = Options.getKeys("vol_down");
						case "mute": FlxG.sound.muteKeys = Options.getKeys("mute");
						case "screenshot": Main.screenshotKeys = Options.getKeys("screenshot");
						case "fullscreen": Main.fullscreenKeys = Options.getKeys("fullscreen");
					}
				}
			}
		}

		var i:Int = 0;
		optionsDisplay.forEachAlive(function(txt:OptionsMenuItem) {
			updateOptionText(i);
			i++;
		});
	}

	function testKeybinds(noteskinType:String, binds:Array<String>)
	{
		hideOptionsMenu();
		new OptionsSubMenuTestKeybinds(noteskinType, binds).exitCallback = showOptionsMenu;
	}

	function noteColors(noteskinType:String)
	{
		hideOptionsMenu();
		new OptionsSubMenuNoteColors(noteskinType).exitCallback = showOptionsMenu;
	}

	function calibrateOffset()
	{
		hideOptionsMenu();
		new OptionsSubMenuCalibrateOffset().exitCallback = showOptionsMenu;
	}

	function adjustComboPosition()
	{
		hideOptionsMenu();
		new OptionsSubMenuComboPosition().exitCallback = showOptionsMenu;
	}
}