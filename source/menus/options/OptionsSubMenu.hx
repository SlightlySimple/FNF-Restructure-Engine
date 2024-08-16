package menus.options;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.input.keyboard.FlxKey;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import openfl.events.KeyboardEvent;

import data.Noteskins;
import data.Options;
import objects.Note;
import objects.StrumNote;
import shaders.ColorSwap;

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