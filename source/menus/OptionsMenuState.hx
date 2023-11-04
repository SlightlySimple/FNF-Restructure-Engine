package menus;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import data.Noteskins;
import data.Options;
import menus.UINavigation;
import objects.AnimatedSprite;
import objects.Note;
import objects.StrumNote;
import shaders.ColorSwap;

import funkui.TabMenu;
import funkui.ColorSwatch;
import funkui.TextButton;
import funkui.Stepper;

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
		var bg:FlxSprite = new FlxSprite(Paths.image('ui/' + MainMenuState.menuImages[3]));
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
		menu.state = this;
		add(menu);
	}
}



class OptionsMenuCurs extends FlxText
{
	public var pos:Array<Float> = [0, 0];

	override public function new(text:String, size:Int, _offset:Float)
	{
		super(0, 0, 0, text, size);
		setFormat("VCR OSD Mono", size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		offset.set(width * _offset, height / 2);
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

class OptionsMenu extends FlxGroup
{
	var optMenuData:Array<OptionsMenuCategory>;

	var optionsGroupList:FlxSpriteGroup;
	var optionsGroupTextList:FlxTypedSpriteGroup<FlxText>;

	var optionsMenuBG:FlxSprite;
	var optionsDisplay:FlxTypedSpriteGroup<FlxText>;
	var optionsCheckmarks:FlxTypedSpriteGroup<AnimatedSprite>;
	var optionsDescBox:FlxSprite;
	var optionsDescText:FlxText;

	var cursLeft:OptionsMenuCurs;
	var cursRight:OptionsMenuCurs;
	var cursMenu:OptionsMenuCurs;

	var curCat:Int = 0;
	var curOption:Int = 0;
	var inCat:Bool = false;
	var secondColumn:Bool = false;
	var holding:Bool = false;
	var holdTimer:Float = 0;
	var holdTick:Float = 0;

	var nav:UINumeralNavigation;
	var nav2:UINumeralNavigation;

	var from:Int = 0;
	public var state:FlxSubState = null;

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

		optMenuData = [];
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
					}
				}
			}
		}

		optionsMenuBG = new FlxSprite(300, 50).makeGraphic(Std.int(FlxG.width - 350), Std.int(FlxG.height - 100), FlxColor.BLACK);
		optionsMenuBG.alpha = 0.6;
		add(optionsMenuBG);

		optionsDisplay = new FlxTypedSpriteGroup<FlxText>();
		add(optionsDisplay);

		optionsCheckmarks = new FlxTypedSpriteGroup<AnimatedSprite>();
		add(optionsCheckmarks);

		optionsDescBox = new FlxSprite(300, Std.int(FlxG.height - 100)).makeGraphic(Std.int(FlxG.width - 350), 50, FlxColor.BLACK);
		optionsDescBox.alpha = 0.5;
		optionsDescBox.visible = false;
		add(optionsDescBox);

		optionsDescText = new FlxText(Std.int(optionsDescBox.x + 15), Std.int(optionsDescBox.y + 3), Std.int(optionsDescBox.width - 30), '', 20);
		optionsDescText.font = "VCR OSD Mono";
		optionsDescText.borderColor = FlxColor.BLACK;
		optionsDescText.borderStyle = OUTLINE;
		if (from == 1)
			optionsDescText.text = Lang.get("#optInGameNotice");
		add(optionsDescText);

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
		}

		cursLeft = new OptionsMenuCurs(">", 32, 1);
		add(cursLeft);

		cursRight = new OptionsMenuCurs("<", 32, 0);
		add(cursRight);

		cursMenu = new OptionsMenuCurs(">", 24, 0);
		cursMenu.visible = false;
		add(cursMenu);

		selectCat();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		nav = new UINumeralNavigation(null, selectCat, function() {enterCat();}, function() {
			switch (from)
			{
				case 1: state.close();
				case 2: FlxG.save.data.setupOptions = true; FlxG.save.flush(); MusicBeatState.doTransIn = false; FlxG.switchState(new TitleState());
				default: FlxG.switchState(new MainMenuState());
			}
		}, selectCat, function() {enterCat();});
		nav.rightClick = nav.back;
		add(nav);

		nav2 = new UINumeralNavigation(changeCurrentOption, selectOption, doAcceptCurrentOption, function() {
			exitCat();
			Options.refreshSaveData();
		}, selectOption, doAcceptCurrentOption);
		nav2.uiSounds = [false, false, true];
		nav2.rightClick = nav2.back;
		nav2.locked = true;
		add(nav2);
	}

	var menuState:Int = 0;

	override function update(elapsed:Float) {
		var opt:OptionMenuStuff = optMenuData[curCat].contents[curOption];
		switch (menuState)
		{
			case 1:
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
						case "vol_up":
							FlxG.sound.volumeUpKeys = Options.getKeys("vol_up");
						case "vol_down":
							FlxG.sound.volumeDownKeys = Options.getKeys("vol_down");
						case "mute":
							FlxG.sound.muteKeys = Options.getKeys("mute");
						case "screenshot":
							Main.screenshotKeys = Options.getKeys("screenshot");
					}

					FlxG.sound.play(Paths.sound('ui/confirmMenu'));
					menuState = 0;
					nav2.locked = false;
					updateOptionText(curOption);
				}

			case 2:
				for (i in 0...testBinds.length)
				{
					if (Options.keyJustPressed(testBinds[i]))
						keybindStrums.members[i].playAnim("press", true, true);

					if (Options.keyJustReleased(testBinds[i]))
						keybindStrums.members[i].playAnim("static", true, true);
				}

				if (Options.keyJustPressed("ui_back"))
				{
					FlxG.sound.play(Paths.sound('ui/cancelMenu'));

					remove(keybindStrums);
					remove(helpText);

					showOptionsMenu();
					selectCat();
					enterCat(false);
					menuState = 0;
					nav2.locked = false;
				}

			case 3:
				if (noteColorState == 0)
				{
					if (Options.keyJustPressed("ui_left"))
					{
						FlxG.sound.play(Paths.sound('ui/scrollMenu'));
						curColorNote--;
						if (curColorNote < 0)
							curColorNote = colorNotes.members.length - 1;

						for (c in colorNotes.members)
							c.alpha = 0.5;
						colorNotes.members[curColorNote].alpha = 1;
					}

					if (Options.keyJustPressed("ui_right"))
					{
						FlxG.sound.play(Paths.sound('ui/scrollMenu'));
						curColorNote++;
						if (curColorNote >= colorNotes.members.length)
							curColorNote = 0;

						for (c in colorNotes.members)
							c.alpha = 0.5;
						colorNotes.members[curColorNote].alpha = 1;
					}

					if (Options.keyJustPressed("ui_accept"))
					{
						FlxG.sound.play(Paths.sound('ui/confirmMenu'));
						noteColorState = 1;
						noteColorSelection = 0;
						if (!Reflect.hasField(Options.options.noteColors, colorNames[curColorNote]))
							Reflect.setProperty(Options.options.noteColors, colorNames[curColorNote], [0, true, 0, 0]);

						noteColorsUpdate();
						for (i in 0...colorOptions.members.length)
							colorOptions.members[i].alpha = 0.5;
						colorOptions.members[0].alpha = 1;
					}

					if (Options.keyJustPressed("ui_back"))
					{
						FlxG.sound.play(Paths.sound('ui/cancelMenu'));

						remove(colorNotes);
						remove(colorOptions);
						remove(helpText);

						showOptionsMenu();
						selectCat();
						enterCat(false);
						menuState = 0;
						nav2.locked = false;
					}
				}
				else
				{
					if (Options.keyJustPressed("ui_up"))
					{
						FlxG.sound.play(Paths.sound('ui/scrollMenu'));
						noteColorSelection--;
						if (noteColorSelection < 0)
							noteColorSelection = colorOptions.members.length - 1;

						for (c in colorOptions.members)
							c.alpha = 0.5;
						colorOptions.members[noteColorSelection].alpha = 1;
					}

					if (Options.keyJustPressed("ui_down"))
					{
						FlxG.sound.play(Paths.sound('ui/scrollMenu'));
						noteColorSelection++;
						if (noteColorSelection >= colorOptions.members.length)
							noteColorSelection = 0;

						for (c in colorOptions.members)
							c.alpha = 0.5;
						colorOptions.members[noteColorSelection].alpha = 1;
					}

					var change:Float = -FlxG.mouse.wheel;
					if (Options.keyJustPressed("ui_left"))
						change = -1;
					if (Options.keyJustPressed("ui_right"))
						change = 1;

					if (change != 0)
					{
						FlxG.sound.play(Paths.sound('ui/scrollMenu'));
						var col:Array<Dynamic> = Reflect.getProperty(Options.options.noteColors, colorNames[curColorNote]);
						if (noteColorSelection == 1)
							col[noteColorSelection] = !col[noteColorSelection];
						else
						{
							col[noteColorSelection] += change * 0.01;
							if (noteColorSelection == 0)
							{
								if (col[noteColorSelection] < 0)
									col[noteColorSelection] += 1;
								if (col[noteColorSelection] >= 1)
									col[noteColorSelection] -= 1;
							}
							else
							{
								if (col[noteColorSelection] < -1)
									col[noteColorSelection] = -1;
								if (col[noteColorSelection] > 1)
									col[noteColorSelection] = 1;
							}
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
						for (c in colorOptions.members)
							c.text = "";
					}
				}

			case 4:
				switch (comboAdjustState)
				{
					case 1:
						Options.options.judgementOffset = [FlxG.mouse.screenX - lastMousePos[0], FlxG.mouse.screenY - lastMousePos[1]];
						resetComboPositionStuff();
						if (FlxG.mouse.justReleased)
							comboAdjustState = 0;

					case 2:
						Options.options.comboOffset = [FlxG.mouse.screenX - lastMousePos[0], FlxG.mouse.screenY - lastMousePos[1]];
						resetComboPositionStuff();
						if (FlxG.mouse.justReleased)
							comboAdjustState = 0;

					default:
						if (FlxG.mouse.justPressed)
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

							remove(displayJudgement);
							remove(displayCombo);
							remove(helpText);

							showOptionsMenu();
							selectCat();
							enterCat(false);
							FlxG.mouse.visible = false;
							menuState = 0;
							nav2.locked = false;
						}
				}

			default:
				if (holding && !nav2.locked)
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
		}

		super.update(elapsed);
	}

	function quickLerp(s:FlxSprite, goal:Array<Int>)
	{
		s.x = FlxMath.lerp(s.x, goal[0], (s.x == 0 ? 1 : FlxG.elapsed * 20));
		s.y = FlxMath.lerp(s.y, goal[1], (s.y == 0 ? 1 : FlxG.elapsed * 20));
	}

	function selectCat(change:Int = 0)
	{
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



		optionsDisplay.forEachAlive(function(txt:FlxText) {
			txt.destroy();
			txt.kill();
		});

		optionsDisplay.clear();

		optionsCheckmarks.forEachAlive(function(check:AnimatedSprite) {
			check.destroy();
			check.kill();
		});

		optionsCheckmarks.clear();

		var yy:Int = 80;
		for (i in 0...optMenuData[curCat].contents.length)
		{
			var opt = optMenuData[curCat].contents[i];
			var optTxt:FlxText = new FlxText(330, yy, 0, "", 24);
			optTxt.font = "VCR OSD Mono";
			optTxt.borderColor = FlxColor.BLACK;
			optTxt.borderStyle = OUTLINE;
			optTxt.alpha = 0.5;
			if (opt.type == 'label')
			{
				yy += 10;
				optTxt.size = 32;
			}
			optionsDisplay.add(optTxt);

			var optCheck:AnimatedSprite = new AnimatedSprite(-9999, optTxt.y, Paths.tiles("ui/checkmark", 2, 1));
			optCheck.animation.add('unchecked', [0]);
			optCheck.animation.add('checked', [1]);
			optCheck.alpha = 0.5;
			optionsCheckmarks.add(optCheck);

			updateOptionText(i);

			yy += 30;
		}
	}

	function selectOption(change:Int = 0)
	{
		curOption = Util.loop(curOption + change, 0, optMenuData[curCat].contents.length - 1);

		if (optMenuData[curCat].contents[curOption].type == "label")
		{
			while (optMenuData[curCat].contents[curOption].type == "label")
			{
				if (change == 0)
					curOption++;
				else
					curOption += Std.int(change / Math.abs(change));

				curOption = Util.loop(curOption, 0, optMenuData[curCat].contents.length - 1);
			}
		}

		if (change != 0)
			FlxG.sound.play(Paths.sound('ui/scrollMenu'));

		var yShift:Int = 0;
		var optionY:Int = Std.int(optionsDisplay.members[curOption].y);
		if (optionY < 100 && optionsDisplay.members[0].y < 80)
		{
			while (optionY < 100 && optionsDisplay.members[0].y < 80)
			{
				yShift += 30;
				optionY += 30;
			}
		}
		if (optionY > FlxG.height - 150)
		{
			while (optionY > FlxG.height - 150)
			{
				yShift -= 30;
				optionY -= 30;
			}
		}
		cursMenu.y += yShift;

		var i:Int = 0;
		optionsDisplay.forEachAlive(function(txt:FlxText) {
			txt.x = 330;
			txt.y += yShift;
			if (i == curOption)
			{
				cursMenu.pos[0] = txt.x;
				cursMenu.pos[1] = txt.getMidpoint().y;
				txt.x += 30;
			}
			updateOptionText(i);
			i++;
		});

		optionsDescText.text = Lang.get(optMenuData[curCat].contents[curOption].description);
	}

	function changeCurrentOption( change:Int = 0 )
	{
		var opt:OptionMenuStuff = optMenuData[curCat].contents[curOption];

		switch (opt.type)
		{
			case "bool":
				if (opt.options != null && opt.options.length == 2)
				{
					setOptVal(curOption, !getOptVal(curOption));
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
				var valInt:Int = opt.options.indexOf(getOptVal(curOption));
				valInt = Util.loop(valInt + change, 0, opt.options.length - 1);

				setOptVal(curOption, opt.options[valInt]);
				if (opt.variable == "noteskin")
				{
					Noteskins.noteskinName = Options.options.noteskin;
					SustainNote.noteGraphics.clear();
				}
				FlxG.sound.play(Paths.sound('ui/scrollMenu'));

			case "choices":
				var valInt:Int = getOptVal(curOption);
				valInt = Util.loop(valInt + change, 0, opt.options.length - 1);

				setOptVal(curOption, valInt);
				FlxG.sound.play(Paths.sound('ui/scrollMenu'));

			case "float" | "int" | "percent":
				setOptVal(curOption, getOptVal(curOption) + (opt.changeValue * change));
				if (getOptVal(curOption) < opt.range[0])
					setOptVal(curOption, opt.range[0]);
				if (getOptVal(curOption) > opt.range[1])
					setOptVal(curOption, opt.range[1]);
				if (opt.type == "int")
					setOptVal(curOption, Std.int(getOptVal(curOption)));
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
		var opt:OptionMenuStuff = optMenuData[curCat].contents[curOption];

		switch (opt.type)
		{
			case "bool":
				if (opt.options == null || opt.options.length != 2)
				{
					setOptVal(curOption, !getOptVal(curOption));
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
				nav2.locked = true;

			case "color":
				FlxG.sound.play(Paths.sound('ui/confirmMenu'));
				nav2.locked = true;
				FlxG.mouse.visible = true;

				var tabMenu:IsolatedTabMenu = new IsolatedTabMenu(0, 0, 300, 260);
				tabMenu.screenCenter();
				add(tabMenu);

				var tabGroupColor = new TabGroup();

				var ol1:FlxSprite = new FlxSprite(48, 8).makeGraphic(204, 34, FlxColor.BLACK);
				tabGroupColor.add(ol1);

				var ol2:FlxSprite = new FlxSprite(48, 48).makeGraphic(144, 144, FlxColor.BLACK);
				tabGroupColor.add(ol2);

				var ol3:FlxSprite = new FlxSprite(218, 48).makeGraphic(34, 144, FlxColor.BLACK);
				tabGroupColor.add(ol3);

				var colorThing:FlxSprite = new FlxSprite(50, 10).makeGraphic(200, 30, FlxColor.WHITE);
				colorThing.color = getOptVal(curOption);
				tabGroupColor.add(colorThing);

				var colorSwatch:ColorSwatch = new ColorSwatch(50, 50, 140, 140, 30, getOptVal(curOption));
				tabGroupColor.add(colorSwatch);

				var stepperR:Stepper = new Stepper(20, 200, 80, 20, colorThing.color.red, 5, 0, 255);
				var stepperG:Stepper = new Stepper(110, 200, 80, 20, colorThing.color.green, 5, 0, 255);
				var stepperB:Stepper = new Stepper(200, 200, 80, 20, colorThing.color.blue, 5, 0, 255);

				stepperR.onChanged = function() { colorSwatch.r = stepperR.valueInt; colorThing.color = colorSwatch.swatchColor; }
				tabGroupColor.add(stepperR);

				stepperG.onChanged = function() { colorSwatch.g = stepperG.valueInt; colorThing.color = colorSwatch.swatchColor; }
				tabGroupColor.add(stepperG);

				stepperB.onChanged = function() { colorSwatch.b = stepperB.valueInt; colorThing.color = colorSwatch.swatchColor; }
				tabGroupColor.add(stepperB);

				colorSwatch.onChanged = function() { colorThing.color = colorSwatch.swatchColor; stepperR.value = colorSwatch.r; stepperG.value = colorSwatch.g; stepperB.value = colorSwatch.b; }

				var acceptButton:TextButton = new TextButton(20, 230, 260, 20, "#accept");
				acceptButton.onClicked = function()
				{
					setOptVal(curOption, colorThing.color);
					nav2.locked = false;
					remove(tabMenu);
					FlxG.mouse.visible = false;
				};
				tabGroupColor.add(acceptButton);

				tabMenu.addGroup(tabGroupColor);

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

	function enterCat(?resetCurOption:Bool = true)
	{
		nav.locked = true;
		if (menuState <= 0)
			nav2.locked = false;
		inCat = true;
		optionsDescBox.visible = true;
		cursMenu.visible = true;

		optionsDisplay.forEachAlive(function(txt:FlxText) {
			txt.alpha = 1;
		});

		optionsCheckmarks.forEachAlive(function(check:AnimatedSprite) {
			check.alpha = 1;
		});

		if (resetCurOption)
			curOption = 0;
		selectOption();
	}

	function exitCat()
	{
		nav.locked = false;
		nav2.locked = true;
		inCat = false;
		optionsDescBox.visible = false;
		if (from == 1)
			optionsDescText.text = Lang.get("#optInGameNotice");
		else
			optionsDescText.text = "";

		var i:Int = 0;
		optionsDisplay.forEachAlive(function(txt:FlxText) {
			txt.x = 330;
			txt.alpha = 0.5;
			updateOptionText(i);
			i++;
		});

		optionsCheckmarks.forEachAlive(function(check:AnimatedSprite) {
			check.alpha = 0.5;
		});

		cursMenu.setPosition();
		cursMenu.visible = false;
	}

	function setOptVal(option:Int, value:Dynamic)
	{
		var opt:OptionMenuStuff = optMenuData[curCat].contents[option];
		Reflect.setProperty(Options.options, opt.variable, value);
	}

	function getOptVal(option:Int):Dynamic
	{
		var opt:OptionMenuStuff = optMenuData[curCat].contents[option];
		return Reflect.getProperty(Options.options, opt.variable);
	}

	function updateOptionText(option:Int)
	{
		var opt:OptionMenuStuff = optMenuData[curCat].contents[option];

		switch (opt.type)
		{
			case "bool":
				if (opt.options == null || opt.options.length != 2)
				{
					optionsDisplay.members[option].text = Lang.get(opt.label);
					optionsCheckmarks.members[option].animation.play(getOptVal(option) ? "checked" : "unchecked");
					optionsCheckmarks.members[option].x = optionsDisplay.members[option].x + optionsDisplay.members[option].width + 20;
					optionsCheckmarks.members[option].y = optionsDisplay.members[option].y;
				}
				else
					optionsDisplay.members[option].text = Lang.get(opt.label) + "   < " + Lang.get(opt.options[getOptVal(option) ? 0 : 1]) + " >";

			case "choicesPopulate": optionsDisplay.members[option].text = Lang.get(opt.label) + "   < " + getOptVal(option) + " >";
			case "choices": optionsDisplay.members[option].text = Lang.get(opt.label) + "   < " + Lang.get(opt.options[getOptVal(option)]) + " >";
			case "float" | "int": optionsDisplay.members[option].text = Lang.get(opt.label) + "   < " + Std.string(getOptVal(option)) + " >";
			case "percent": optionsDisplay.members[option].text = Lang.get(opt.label) + "   < " + Std.string(getOptVal(option) * 100) + "% >";

			case "control":
				var keys:Array<FlxKey> = Reflect.getProperty(Options.options.keys, opt.variable);
				var keyStrings:Array<String> = [keys[0].toString(), keys[1].toString()];
				if (keys[0] == FlxKey.NONE)
					keyStrings[0] = "None";
				if (keys[1] == FlxKey.NONE)
					keyStrings[1] = "None";
				if (inCat && option == curOption)
				{
					if (secondColumn)
					{
						if (menuState == 1)
							optionsDisplay.members[option].text = Lang.get(opt.label) + "   " + keyStrings[0] + " | >   <";
						else
							optionsDisplay.members[option].text = Lang.get(opt.label) + "   " + keyStrings[0] + " | > " + keyStrings[1] + " <";
					}
					else
					{
						if (menuState == 1)
							optionsDisplay.members[option].text = Lang.get(opt.label) + "   >   < | " + keyStrings[1];
						else
							optionsDisplay.members[option].text = Lang.get(opt.label) + "   > " + keyStrings[0] + " < | " + keyStrings[1];
					}
				}
				else
					optionsDisplay.members[option].text = Lang.get(opt.label) + "   " + keyStrings[0] + " | " + keyStrings[1];

			default: optionsDisplay.members[option].text = Lang.get(opt.label);
		}

		if (optionsDisplay.members[option].y < 50 || optionsDisplay.members[option].y + optionsDisplay.members[option].height > FlxG.height - 50)
			optionsDisplay.members[option].visible = false;
		else
			optionsDisplay.members[option].visible = true;
		optionsCheckmarks.members[option].visible = optionsDisplay.members[option].visible;
	}

	function showOptionsMenu()
	{
		optionsMenuBG.visible = true;
		optionsGroupList.visible = true;
		optionsGroupTextList.visible = true;
		optionsDisplay.visible = true;
		optionsCheckmarks.visible = true;
		optionsDescBox.visible = true;
		optionsDescText.visible = true;
		cursLeft.visible = true;
		cursRight.visible = true;
	}

	function hideOptionsMenu()
	{
		optionsMenuBG.visible = false;
		optionsGroupList.visible = false;
		optionsGroupTextList.visible = false;
		optionsDisplay.visible = false;
		optionsCheckmarks.visible = false;
		optionsDescBox.visible = false;
		optionsDescText.visible = false;
		cursLeft.visible = false;
		cursRight.visible = false;
		cursMenu.visible = false;
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
						case "vol_up":
							FlxG.sound.volumeUpKeys = Options.getKeys("vol_up");
						case "vol_down":
							FlxG.sound.volumeDownKeys = Options.getKeys("vol_down");
						case "mute":
							FlxG.sound.muteKeys = Options.getKeys("mute");
						case "screenshot":
							Main.screenshotKeys = Options.getKeys("screenshot");
					}
				}
			}
		}

		var i:Int = 0;
		optionsDisplay.forEachAlive(function(txt:FlxText) {
			updateOptionText(i);
			i++;
		});
	}

	var testBinds:Array<String> = [];
	var keybindStrums:FlxTypedSpriteGroup<StrumNote>;
	var helpText:FlxText;
	function testKeybinds(noteskinType:String, binds:Array<String>)
	{
		menuState = 2;
		nav2.locked = true;
		testBinds = binds;

		hideOptionsMenu();

		keybindStrums = new FlxTypedSpriteGroup<StrumNote>();
		add(keybindStrums);

		var ints:Array<Int> = [];
		for (i in 0...binds.length)
			ints.push(0);

		for (i in 0...binds.length)
		{
			var strum:StrumNote = new StrumNote(i, noteskinType);
			strum.resetPosition(Options.options.downscroll, true, ints);
			keybindStrums.add(strum);
		}

		if (binds.length == 4)
		{
			helpText = new FlxText(0, 0, 0, Lang.get("#optKeybindTestNotice"), 32);
			helpText.font = "VCR OSD Mono";
			helpText.borderColor = FlxColor.BLACK;
			helpText.borderStyle = OUTLINE;
			helpText.screenCenter();
			add(helpText);
		}
	}

	var colorNotes:FlxSpriteGroup;
	var colorNoteShaders:Array<ColorSwap>;
	var colorOptions:FlxTypedSpriteGroup<FlxText>;
	var colorOptionText:Array<String> = ["#optNoteColorsHue", "", "#optNoteColorsSaturation", "#optNoteColorsBrightness"];
	var colorNames:Array<String>;
	var curColorNote:Int = 0;
	var noteColorState:Int = 0;
	var noteColorSelection:Int = 0;
	function noteColors(noteskinType:String)
	{
		menuState = 3;
		nav2.locked = true;
		hideOptionsMenu();

		colorNotes = new FlxSpriteGroup();
		add(colorNotes);
		curColorNote = 0;
		noteColorState = 0;

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
			note.shader = s.shader;
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
			colorOptions.add(colorOption);
		}

		helpText = new FlxText(0, FlxG.height * 0.9, 0, Lang.get("#optNoteColorsNotice"), 32);
		helpText.font = "VCR OSD Mono";
		helpText.borderColor = FlxColor.BLACK;
		helpText.borderStyle = OUTLINE;
		helpText.screenCenter(X);
		add(helpText);
	}

	function noteColorsUpdate()
	{
		var col:Array<Dynamic> = Options.noteColor(colorNames[curColorNote]);
		for (i in 0...colorOptions.members.length)
		{
			if (i == 1)
				colorOptions.members[i].text = Lang.get(col[i] ? "#optNoteColorsHueSettingB" : "#optNoteColorsHueSettingA");
			else
				colorOptions.members[i].text = Lang.get(colorOptionText[i], [Std.string(Std.int(col[i] * 100))]);
			colorOptions.members[i].screenCenter(X);
		}
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



	var displayJudgement:FlxSprite;
	var displayCombo:FlxSpriteGroup;

	var lastMousePos:Array<Int> = [];
	var comboAdjustState:Int = 0;
	function adjustComboPosition()
	{
		menuState = 4;
		nav2.locked = true;
		FlxG.mouse.visible = true;

		hideOptionsMenu();

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

		helpText = new FlxText(0, FlxG.height * 0.9, 0, Lang.get("#optAdjustComboNotice"), 32);
		helpText.font = "VCR OSD Mono";
		helpText.borderColor = FlxColor.BLACK;
		helpText.borderStyle = OUTLINE;
		helpText.screenCenter(X);
		add(helpText);
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