package menus;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.input.keyboard.FlxKey;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import openfl.events.KeyboardEvent;
import data.Noteskins;
import data.Options;
import menus.UINavigation;
import objects.AnimatedSprite;
import objects.Note;
import objects.StrumNote;
import shaders.ColorSwap;

import newui.PopupWindow;

using StringTools;

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

typedef OptionsMenuCategory =
{
	label:String,
	contents:Array<OptionMenuStuff>
}

class OptionsMenuState extends MusicBeatState
{
	override public function create()
	{
		var bg:FlxSprite = new FlxSprite(Paths.image("ui/" + MainMenuState.menuImages[3]));
		bg.color = MainMenuState.menuColors[3];
		add(bg);

		add(new OptionsMenu());

		super.create();
	}
}

class OptionsMenuSubState extends FlxSubState
{
	var from:Int = 0;

	override public function new(from:Int = 0)
	{
		super();
		this.from = from;
	}

	override public function create()
	{
		super.create();
		var menu = new OptionsMenu(from);
		switch (from)
		{
			case 1: menu.exitCallback = function() { close(); }
			case 2: menu.exitCallback = function() { FlxG.save.data.setupOptions = true; FlxG.save.flush(); MusicBeatState.doTransIn = false; FlxG.switchState(new TitleState()); }
			default: menu.exitCallback = function() { FlxG.switchState(new MainMenuState()); }
		}
		add(menu);
	}
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

			updateOptionText(i);

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
			if (FlxG.keys.justReleased.LEFT || FlxG.keys.justReleased.RIGHT)
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

	function updateOptionText(option:Int)
	{
		var opt:OptionMenuStuff = data.contents[option];
		var item:OptionsMenuItem = optionsDisplay.members[option];
		item.text = Lang.get(opt.label);
		item.textR = "";
		item.showCheck = false;

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

class OptionsSubMenu extends FlxSubState
{
	public var exitCallback:Void->Void;

	override public function new()
	{
		super();

		var state:FlxState = FlxG.state;
		if (state.subState != null)
		{
			while (state.subState != null)
				state = state.subState;
		}
		state.persistentUpdate = false;
		state.openSubState(this);

		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}
}

class OptionsSubMenuTestKeybinds extends OptionsSubMenu
{
	var testBinds:Array<String> = [];
	var keybindStrums:FlxTypedSpriteGroup<StrumNote>;
	var helpText:FlxText;

	override public function new(noteskinType:String, binds:Array<String>)
	{
		super();

		testBinds = binds;

		keybindStrums = new FlxTypedSpriteGroup<StrumNote>();
		add(keybindStrums);

		var ints:Array<Int> = [];
		for (i in 0...binds.length)
			ints.push(0);

		for (i in 0...binds.length)
		{
			var strum:StrumNote = new StrumNote(i, noteskinType);
			strum.resetPosition(Options.options.downscroll, true, ints);
			strum.isOptionsMenuStrum = true;
			keybindStrums.add(strum);
		}

		if (binds.length == 4)
		{
			helpText = new FlxText(0, 0, 0, Lang.get("#options.menu.keybindTestNotice"), 32);
			helpText.font = "VCR OSD Mono";
			helpText.borderColor = FlxColor.BLACK;
			helpText.borderStyle = OUTLINE;
			helpText.screenCenter();
			helpText.setPosition(Math.round(helpText.x), Math.round(helpText.y));
			add(helpText);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		for (i in 0...testBinds.length)
		{
			if (Options.keyJustPressed(testBinds[i]))
				keybindStrums.members[i].playAnim("press", true);

			if (Options.keyJustReleased(testBinds[i]))
				keybindStrums.members[i].playAnim("static", true);
		}

		if (Options.keyJustPressed("ui_back"))
		{
			FlxG.sound.play(Paths.sound('ui/cancelMenu'));

			if (exitCallback != null)
				exitCallback();
			close();
		}
	}
}

class OptionsSubMenuNoteColors extends OptionsSubMenu
{
	var colorNotes:FlxSpriteGroup;
	var colorNoteShaders:Array<ColorSwap>;
	var colorOptions:FlxTypedSpriteGroup<FlxText>;
	var colorOptionText:Array<String> = ["#options.noteColors.hue", "", "#options.noteColors.saturation", "#options.noteColors.brightness"];
	var colorNames:Array<String>;
	var curColorNote:Int = 0;
	var noteColorState:Int = 0;
	var noteColorSelection:Int = 0;
	var helpText:FlxText;

	override public function new(noteskinType:String)
	{
		super();

		colorNotes = new FlxSpriteGroup();
		add(colorNotes);

		var noteskinData:NoteskinTypedef = Noteskins.getData(Noteskins.noteskinName, noteskinType);
		var colors:Array<NoteskinColor> = [];
		colorNames = [];
		colorNoteShaders = [];
		for (c in noteskinData.colors)
		{
			if (!colorNames.contains(c.color))
			{
				colors.push(c);
				colorNames.push(c.color);
			}
		}

		for (i in 0...colors.length)
		{
			var c:NoteskinColor = colors[i];
			var note:FlxSprite = new FlxSprite(0, 200);
			Noteskins.addNoteAnim(note, noteskinData, c.color, c.shape);
			note.animation.play("idle");

			var s:ColorSwap = new ColorSwap();
			note.shader = s;
			colorNoteShaders.push(s);

			note.scale.set(noteskinData.scale * 2, noteskinData.scale * 2);
			note.updateHitbox();
			note.antialiasing = noteskinData.antialias;

			note.x = ((i + 0.5) * (FlxG.width / colors.length)) - (note.width / 2);
			note.y -= note.height / 2;
			if (i > 0)
				note.alpha = 0.5;

			colorNotes.add(note);
		}
		noteShadersUpdate();

		colorOptions = new FlxTypedSpriteGroup<FlxText>();
		add(colorOptions);
		for (i in 0...colorOptionText.length)
		{
			var colorOption:FlxText = new FlxText(0, 350 + (i * 60), 0, "", 64);
			colorOption.font = "VCR OSD Mono";
			colorOption.borderColor = FlxColor.BLACK;
			colorOption.borderStyle = OUTLINE;
			colorOption.borderSize = 3;
			colorOptions.add(colorOption);
		}
		noteColorsUpdate();

		helpText = new FlxText(0, FlxG.height * 0.9, FlxG.width * 0.9, Lang.get("#options.noteColors.helpText"), 24);
		helpText.font = "VCR OSD Mono";
		helpText.alignment = CENTER;
		helpText.borderColor = FlxColor.BLACK;
		helpText.borderStyle = OUTLINE;
		helpText.screenCenter(X);
		add(helpText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (noteColorState == 0)
		{
			if (Options.keyJustPressed("ui_left"))
				changeNote(-1);

			if (Options.keyJustPressed("ui_right"))
				changeNote(1);

			if (Options.keyJustPressed("ui_accept"))
			{
				FlxG.sound.play(Paths.sound('ui/confirmMenu'));
				noteColorState = 1;
				noteColorSelection = 0;
				if (!Reflect.hasField(Options.options.noteColors, colorNames[curColorNote]))
					Reflect.setProperty(Options.options.noteColors, colorNames[curColorNote], [0, true, 0, 0]);

				noteColorsUpdate();
			}

			if (Options.keyJustPressed("ui_back"))
			{
				FlxG.sound.play(Paths.sound('ui/cancelMenu'));

				if (exitCallback != null)
					exitCallback();
				close();
			}
		}
		else
		{
			if (Options.keyJustPressed("ui_up"))
				changeColorOption(-1);

			if (Options.keyJustPressed("ui_down"))
				changeColorOption(1);

			var change:Float = -FlxG.mouse.wheel;
			if (Options.keyJustPressed("ui_left"))
				change = -1;
			if (Options.keyJustPressed("ui_right"))
				change = 1;
			if (FlxG.keys.pressed.SHIFT)
				change *= 5;

			if (change != 0)
			{
				FlxG.sound.play(Paths.sound('ui/scrollMenu'));
				var col:Array<Dynamic> = Reflect.getProperty(Options.options.noteColors, colorNames[curColorNote]);
				if (noteColorSelection == 1)
					col[noteColorSelection] = !col[noteColorSelection];
				else
				{
					col[noteColorSelection] += change * 0.01;
					col[noteColorSelection] = Math.round(col[noteColorSelection] * 100) / 100;
					if (noteColorSelection == 0)
					{
						if (col[noteColorSelection] < 0)
							col[noteColorSelection] += 1;
						if (col[noteColorSelection] >= 1)
							col[noteColorSelection] -= 1;
					}
					else
						col[noteColorSelection] = Math.min(1, Math.max(-1, col[noteColorSelection]));
				}
				noteColorsUpdate();
				noteShadersUpdate();
			}

			if (Options.keyJustPressed("ui_accept") || Options.keyJustPressed("ui_back"))
			{
				if (Note.cs.exists(colorNames[curColorNote]))
				{
					Note.cs.remove(colorNames[curColorNote]);
					Note.getShader(colorNames[curColorNote]);
				}

				FlxG.sound.play(Paths.sound('ui/confirmMenu'));
				noteColorState = 0;
				noteColorsUpdate();
			}
		}
	}

	function changeNote(?val:Int = 0)
	{
		FlxG.sound.play(Paths.sound('ui/scrollMenu'));
		curColorNote = Util.loop(curColorNote + val, 0, colorNotes.members.length - 1);

		for (c in colorNotes.members)
			c.alpha = 0.5;
		colorNotes.members[curColorNote].alpha = 1;

		noteColorsUpdate();
	}

	function changeColorOption(?val:Int = 0)
	{
		FlxG.sound.play(Paths.sound('ui/scrollMenu'));
		noteColorSelection = Util.loop(noteColorSelection + val, 0, colorOptions.members.length - 1);

		noteColorsUpdate();
	}

	function noteColorsUpdate()
	{
		var col:Array<Dynamic> = Options.noteColor(colorNames[curColorNote]);
		for (i in 0...colorOptions.members.length)
		{
			if (i == 1)
			{
				colorOptions.members[i].text = Lang.get(col[i] ? "#options.noteColors.hue.setting.1" : "#options.noteColors.hue.setting.0");
				if (noteColorState == 1 && i == noteColorSelection)
					colorOptions.members[i].text = "< " + colorOptions.members[i].text + " >";
			}
			else
			{
				if (noteColorState == 1 && i == noteColorSelection)
					colorOptions.members[i].text = Lang.get(colorOptionText[i]) + " < " + Std.string(Math.round(col[i] * 100)) + " >";
				else
					colorOptions.members[i].text = Lang.get(colorOptionText[i]) + " " + Std.string(Math.round(col[i] * 100));
			}
			colorOptions.members[i].screenCenter(X);
			colorOptions.members[i].alpha = 0.5;
		}

		if (noteColorState == 1)
			colorOptions.members[noteColorSelection].alpha = 1;
	}

	function noteShadersUpdate()
	{
		for (i in 0...colorNames.length)
		{
			var col:Array<Float> = Options.noteColorArray(colorNames[i]);
			colorNoteShaders[i].setHSV(col);
			colorNoteShaders[i].hAdd = Options.noteColor(colorNames[i])[1];
		}
	}
}

class OptionsSubMenuComboPosition extends OptionsSubMenu
{
	var displayJudgement:FlxSprite;
	var displayCombo:FlxSpriteGroup;

	var lastMousePos:Array<Int> = [];
	var comboAdjustState:Int = 0;
	var helpText:FlxText;

	override public function new()
	{
		super();

		FlxG.mouse.visible = true;

		displayJudgement = new FlxSprite(Paths.image("ui/skins/default/sick"));
		add(displayJudgement);

		displayCombo = new FlxSpriteGroup();
		add(displayCombo);

		var combo:FlxSprite = new FlxSprite((FlxG.width * 0.55) + (43 * 3) - 90, FlxG.height * 0.4 + 80, Paths.image("ui/skins/default/combo"));
		combo.scale.x = 0.7;
		combo.scale.y = 0.7;
		combo.updateHitbox();
		displayCombo.add(combo);

		for (i in 0...3)
		{
			var digit:FlxSprite = new FlxSprite(Paths.image("ui/skins/default/num0"));
			digit.scale.x = 0.5;
			digit.scale.y = 0.5;
			digit.updateHitbox();

			digit.screenCenter(Y);
			digit.x = (FlxG.width * 0.55) + (43 * i) - 90;
			digit.y += 80;

			displayCombo.add(digit);
		}

		resetComboPositionStuff();

		helpText = new FlxText(0, FlxG.height * 0.9, FlxG.width * 0.9, Lang.get("#options.adjustCombo.helpText"), 32);
		helpText.font = "VCR OSD Mono";
		helpText.borderColor = FlxColor.BLACK;
		helpText.borderStyle = OUTLINE;
		helpText.screenCenter(X);
		add(helpText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (comboAdjustState)
		{
			case 1:
				Options.options.judgementOffset = [FlxG.mouse.screenX - lastMousePos[0], FlxG.mouse.screenY - lastMousePos[1]];
				resetComboPositionStuff();
				if (Options.mouseJustReleased())
					comboAdjustState = 0;

			case 2:
				Options.options.comboOffset = [FlxG.mouse.screenX - lastMousePos[0], FlxG.mouse.screenY - lastMousePos[1]];
				resetComboPositionStuff();
				if (Options.mouseJustReleased())
					comboAdjustState = 0;

			default:
				if (FlxG.mouse.justMoved)
				{
					Mouse.cursor = MouseCursor.ARROW;
					if (displayCombo.overlapsPoint(FlxG.mouse.getWorldPosition(camera), true, camera) || displayJudgement.overlapsPoint(FlxG.mouse.getWorldPosition(camera), true, camera))
						Mouse.cursor = MouseCursor.HAND;
				}

				if (Options.mouseJustPressed())
				{
					lastMousePos = [FlxG.mouse.screenX, FlxG.mouse.screenY];
					if (displayCombo.overlapsPoint(FlxG.mouse.getWorldPosition(camera), true, camera))
					{
						comboAdjustState = 2;
						lastMousePos[0] -= Std.int(Options.options.comboOffset[0]);
						lastMousePos[1] -= Std.int(Options.options.comboOffset[1]);
					}
					else if (displayJudgement.overlapsPoint(FlxG.mouse.getWorldPosition(camera), true, camera))
					{
						comboAdjustState = 1;
						lastMousePos[0] -= Std.int(Options.options.judgementOffset[0]);
						lastMousePos[1] -= Std.int(Options.options.judgementOffset[1]);
					}
				}

				if (FlxG.keys.justPressed.R)
				{
					Options.options.judgementOffset = [0, 0];
					Options.options.comboOffset = [0, 0];
					resetComboPositionStuff();
				}

				if (Options.keyJustPressed("ui_back"))
				{
					FlxG.sound.play(Paths.sound('ui/confirmMenu'));
					FlxG.mouse.visible = false;

					if (exitCallback != null)
						exitCallback();
					close();
				}
		}
	}

	function resetComboPositionStuff()
	{
		displayJudgement.scale.set(1, 1);
		displayJudgement.updateHitbox();

		displayJudgement.x = (FlxG.width * 0.55) + 100;
		displayJudgement.y = 275;

		displayJudgement.x += Options.options.judgementOffset[0];
		displayJudgement.y += Options.options.judgementOffset[1];

		displayJudgement.scale.set(0.7, 0.7);
		displayJudgement.updateHitbox();
		displayJudgement.x -= displayJudgement.width / 2;
		displayJudgement.y -= displayJudgement.height / 2;

		displayCombo.setPosition(Options.options.comboOffset[0], Options.options.comboOffset[1]);
	}
}

class OptionsSubMenuCalibrateOffset extends OptionsSubMenu
{
	var soundTest:FlxSound;
	var offsetText:FlxText;
	var offsetInputs:Array<Float> = [];
	var curTick:Float = 0;

	var strum:StrumNote;
	var note:Note;

	override public function new()
	{
		super();
		FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.2);

		strum = new StrumNote(0, "default");
		strum.resetPosition(Options.options.downscroll, true, [0]);
		strum.isOptionsMenuStrum = true;
		strum.screenCenter();
		add(strum);

		note = new Note(0, 0);
		note.screenCenter();
		add(note);

		offsetText = new FlxText(0, 600, 0, "< Offset: 0 >").setFormat("VCR OSD Mono", 48, CENTER, OUTLINE, FlxColor.BLACK);
		add(offsetText);
		resetOffsetText();

		soundTest = new FlxSound().loadEmbedded(Paths.sound("ui/soundTest"), true);
		FlxG.sound.list.add(soundTest);
		soundTest.play();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyReleased);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var prevTick:Float = curTick;
		var tickTime:Float = soundTest.time - Options.options.offset;
		curTick = Math.floor(tickTime / 500);
		if (curTick != prevTick)
			strum.playAnim("confirm", true, note.noteColor);
		if (tickTime >= (curTick * 500) + 100 && strum.animation.curAnim.name != "static")
			strum.playAnim("static", true);

		note.x = strum.x + (tickTime - ((curTick + 1) * 500));

		if (Options.keyJustPressed("ui_left"))
		{
			FlxG.sound.play(Paths.sound('ui/scrollMenu'));
			Options.options.offset--;
			offsetInputs = [];
			resetOffsetText();
		}

		if (Options.keyJustPressed("ui_right"))
		{
			FlxG.sound.play(Paths.sound('ui/scrollMenu'));
			Options.options.offset++;
			offsetInputs = [];
			resetOffsetText();
		}

		if (Options.keyJustPressed("ui_back"))
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyReleased);

			soundTest.stop();
			soundTest.destroy();

			FlxG.sound.play(Paths.sound('ui/confirmMenu'));
			FlxTween.tween(FlxG.sound.music, {volume: 0.7}, 0.2);

			if (exitCallback != null)
				exitCallback();
			close();
		}
	}

	function resetOffsetText()
	{
		offsetText.text = "< Offset: " + Std.string(Options.options.offset) + " >";
		offsetText.screenCenter(X);
	}

	function onKeyPressed(event:KeyboardEvent)
	{
		var _key:FlxKey = cast event.keyCode;
		if (Options.getKeys("ui_accept").contains(_key))
		{
			var closestBeat:Float = Math.round(soundTest.time / 500) * 500;
			var offsetInput:Float = soundTest.time - closestBeat;
			offsetInputs.push(offsetInput);
			var finalOffset:Float = 0;
			for (i in offsetInputs)
				finalOffset += i;
			finalOffset /= offsetInputs.length;
			Options.options.offset = Math.round(finalOffset);
			resetOffsetText();
		}
	}

	function onKeyReleased(event:KeyboardEvent)
	{
	}
}