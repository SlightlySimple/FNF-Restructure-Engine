package editors;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.input.keyboard.FlxKey;
import helpers.DeepEquals;
import helpers.Cloner;
import data.ObjectData;
import data.Options;
import objects.Character;
import objects.HealthIcon;
import objects.Stage;
import haxe.Json;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import menus.EditorMenuState;
import menus.story.StoryMenuCharacter;

import lime.app.Application;

import newui.UIControl;
import newui.TopMenu;
import newui.TabMenu;
import newui.InfoBox;
import newui.Button;
import newui.Checkbox;
import newui.Draggable;
import newui.InputText;
import newui.ObjectMenu;
import newui.PopupWindow;
import newui.Stepper;
import newui.DropdownMenu;

using StringTools;

class StoryCharacterEditorState extends BaseEditorState
{
	public static var newCharacterImage:String = "";
	var charPos:String = "center";
	var charPosOffset:Array<Int> = [Std.int(FlxG.width / 3), 56];

	var character:FlxSprite;
	var characterGhost:FlxSprite = null;

	var allAnimData:String = "";
	var allAnimPrefixes:Array<String> = [];

	var characterData:WeekCharacterData;
	var dataLog:Array<WeekCharacterData> = [];

	var mousePos:FlxPoint;

	var	movingCharacter:Bool = false;
	var	movingAnimOffset:Bool = false;
	var dragStart:Array<Int> = [0, 0];
	var dragOffset:Array<Float> = [0, 0];

	var charAnimList:Array<String>;
	var charAnims:ObjectMenu;
	var curCharAnim:Int = -1;

	var showAnimGhost:Checkbox;

	var posLocked:Bool = false;
	var charScaleX:Stepper;
	var charScaleY:Stepper;
	var camPosX:Stepper;
	var camPosY:Stepper;
	var firstAnimDropdown:DropdownMenu;

	var animName:InputText;
	var animPrefix:InputText;
	var animPrefixDropdown:DropdownMenu = null;
	var animIndices:InputText;
	var animOffsetX:Stepper;
	var animOffsetY:Stepper;
	var animLooped:Checkbox;
	var animFPS:Stepper;
	var curFrameText:FlxText;

	override public function create()
	{
		mousePos = FlxPoint.get();

		super.create();
		filenameNew = "New Character";

		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);
		add(bgYellow);

		if (isNew)
		{
			characterData =
			{
				asset: newCharacterImage,
				position: [0, 0],
				scale: [1, 1],
				antialias: true,
				animations: [],
				firstAnimation: "",
				idles: [],
				danceSpeed: 1,
				flip: false,
				matchColor: true
			}
		}
		else
			characterData = StoryMenuCharacter.parseCharacter(id);

		character = new FlxSprite();
		reloadAsset();

		character.antialiasing = characterData.antialias;
		character.flipX = characterData.flip;

		if (characterData.scale != null && characterData.scale.length == 2)
		{
			character.scale.x = characterData.scale[0];
			character.scale.y = characterData.scale[1];
		}
		else
			characterData.scale = [1, 1];
		character.updateHitbox();

		characterGhost = new FlxSprite(character.x, character.y);
		characterGhost.alpha = 0.5;
		characterGhost.visible = false;
		characterGhost.frames = character.frames;
		characterGhost.antialiasing = character.antialiasing;
		characterGhost.flipX = character.flipX;

		refreshCharacterColor();

		if (isNew)
		{
			var idleIndex:String = allAnimPrefixes[0];
			for (a in allAnimPrefixes)
			{
				if (a.toLowerCase().indexOf("idle") != -1 || a.toLowerCase().indexOf("dance") != -1 || a.toLowerCase().indexOf("dancing") != -1)
				{
					idleIndex = a;
					break;
				}
			}
			characterData.animations.push({name: "idle", prefix: idleIndex, fps: 24, loop: false, offsets: [0, 0]});
			characterData.firstAnimation = "idle";
			characterData.idles = ["idle"];
		}
		reloadAnimations();

		characterGhost.scale.x = character.scale.x;
		characterGhost.scale.y = character.scale.y;
		characterGhost.updateHitbox();

		add(characterGhost);
		add(character);



		charAnimList = [];
		for (i in 0...characterData.animations.length)
			charAnimList.push(characterData.animations[i].name);

		charAnims = new ObjectMenu(990, 250, "animationBox");
		charAnims.onClicked = function(index:Int) {
			var animData:CharacterAnimation = characterData.animations[index];
			if (animData != null)
			{
				playAnim(animData.name, true);
				animName.text = animData.name;
				animPrefix.text = animData.prefix;
				if (animData.indices != null && animData.indices.length > 0)
					animIndices.text = Character.compactIndices(animData.indices).join(",");
				else
					animIndices.text = "";
			}
		}
		charAnims.onRightClicked = function(index:Int) {
			var animationName:String = characterData.animations[index].name;
			playAnim(animationName, true, true);
			if (!showAnimGhost.checked)
			{
				showAnimGhost.checked = true;
				showAnimGhost.onClicked();
			}
		}
		charAnims.cameras = [camHUD];
		add(charAnims);
		refreshCharAnims();

		if (characterData.firstAnimation != null && characterData.firstAnimation != "")
		{
			if (!charAnimList.contains(characterData.firstAnimation))
				characterData.firstAnimation = charAnimList[0];

			playAnim(characterData.firstAnimation);
			playAnim(characterData.firstAnimation, false, true);
		}



		createUI("StoryCharacterEditor");



		var characterAsset:InputText = cast element("characterAsset");
		characterAsset.text = characterData.asset;
		characterAsset.condition = function() { return characterData.asset; }
		characterAsset.focusLost = function() {
			if (!changeAsset(characterAsset.text))
				characterAsset.text = characterData.asset;
		}

		var loadAssetButton:Button = cast element("loadAssetButton");
		loadAssetButton.onClicked = function() {
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = function(fullPath:String) {
				var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
				if (nameArray.contains("images"))
				{
					while (nameArray[0] != "images")
						nameArray.shift();
					nameArray.shift();

					var finalName = nameArray.join("/");
					finalName = finalName.substr(0, finalName.length - 4);

					changeAsset(finalName);
				}
			}
			file.load("png");
		}

		showAnimGhost = cast element("showAnimGhost");
		showAnimGhost.onClicked = function() { characterGhost.visible = showAnimGhost.checked; };

		var charPosLeft:ToggleButton = cast element("charPosLeft");
		charPosLeft.condition = function() { return charPos == "left"; }
		charPosLeft.onClicked = function() { charPos = "left"; charPosOffset[0] = 0; resetCharPosition(); }

		var charPosCenter:ToggleButton = cast element("charPosCenter");
		charPosCenter.condition = function() { return charPos == "center"; }
		charPosCenter.onClicked = function() { charPos = "center"; charPosOffset[0] = Std.int(FlxG.width / 3); resetCharPosition(); }

		var charPosRight:ToggleButton = cast element("charPosRight");
		charPosRight.condition = function() { return charPos == "right"; }
		charPosRight.onClicked = function() { charPos = "right"; charPosOffset[0] = Std.int(FlxG.width * 2 / 3); resetCharPosition(); }

		resetCharPosition();



		var charX:Stepper = cast element("charX");
		charX.value = characterData.position[0];
		charX.condition = function() { return characterData.position[0]; }
		charX.onChanged = function() {
			characterData.position[0] = charX.valueInt;
			resetCharPosition();
		}

		var charY:Stepper = cast element("charY");
		charY.value = characterData.position[1];
		charY.condition = function() { return characterData.position[1]; }
		charY.onChanged = function() {
			characterData.position[1] = charY.valueInt;
			resetCharPosition();
		}

		var charAntialias:Checkbox = cast element("charAntialias");
		charAntialias.checked = characterData.antialias;
		charAntialias.condition = function() { return characterData.antialias; }
		charAntialias.onClicked = function()
		{
			characterData.antialias = charAntialias.checked;
			character.antialiasing = characterData.antialias;
			characterGhost.antialiasing = character.antialiasing;
		}

		var charFlip:Checkbox = cast element("charFlip");
		charFlip.checked = characterData.flip;
		charFlip.condition = function() { return characterData.flip; }
		charFlip.onClicked = function()
		{
			characterData.flip = charFlip.checked;
			character.flipX = characterData.flip;
			characterGhost.flipX = character.flipX;
		}

		var charDanceSpeed:Stepper = cast element("charDanceSpeed");
		charDanceSpeed.value = characterData.danceSpeed;
		charDanceSpeed.condition = function() { return characterData.danceSpeed; }
		charDanceSpeed.onChanged = function() { characterData.danceSpeed = charDanceSpeed.value; }

		charScaleX = cast element("charScaleX");
		charScaleX.value = characterData.scale[0];
		charScaleX.condition = function() { return characterData.scale[0]; }
		charScaleX.onChanged = function() {
			characterData.scale[0] = charScaleX.value;
			character.scale.x = characterData.scale[0];
			characterGhost.scale.x = character.scale.x;
			character.updateHitbox();
			characterGhost.updateHitbox();
			if (characterData.animations.length > 0)
			{
				playAnim(characterData.animations[curCharAnim].name, true);
				if (characterGhost.animation.curAnim.name == characterData.animations[curCharAnim].name)
					playAnim(characterData.animations[curCharAnim].name, true, true);
			}
		}

		charScaleY = cast element("charScaleY");
		charScaleY.value = characterData.scale[1];
		charScaleY.condition = function() { return characterData.scale[1]; }
		charScaleY.onChanged = function() {
			characterData.scale[1] = charScaleY.value;
			character.scale.y = characterData.scale[1];
			characterGhost.scale.y = character.scale.y;
			character.updateHitbox();
			characterGhost.updateHitbox();
			if (characterData.animations.length > 0)
			{
				playAnim(characterData.animations[curCharAnim].name, true);
				if (characterGhost.animation.curAnim.name == characterData.animations[curCharAnim].name)
					playAnim(characterData.animations[curCharAnim].name, true, true);
			}
		}

		var idles:TextButton = cast element("idles");
		idles.onClicked = function()
		{
			var window:PopupWindow = null;
			var vbox:VBox = new VBox(35, 35);

			var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
			var scroll:VBox = menu.vbox;

			for (i in 0...characterData.idles.length)
			{
				var animHbox:HBox = new HBox();
				var anim:DropdownMenu = new DropdownMenu(0, 0, characterData.idles[i], charAnimList, true);
				anim.onChanged = function() { characterData.idles[i] = anim.value; }
				animHbox.add(anim);
				var _remove:Button = new Button(0, 0, "buttonTrash");
				_remove.onClicked = function() {
					characterData.idles.splice(i, 1);
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { idles.onClicked(); });
				}
				animHbox.add(_remove);
				scroll.add(animHbox);
			}

			if (characterData.idles.length > 0)
				vbox.add(menu);

			var _add:TextButton = new TextButton(0, 0, "Add");
			_add.onClicked = function() {
				if (characterData.idles.length > 0)
					characterData.idles.push(characterData.idles[characterData.idles.length-1]);
				else
					characterData.idles.push(charAnimList[0]);
				window.close();
				new FlxTimer().start(0.01, function(tmr:FlxTimer) { idles.onClicked(); });
			}
			vbox.add(_add);

			var accept:TextButton = new TextButton(0, 0, "Accept", function() { window.close(); });
			vbox.add(accept);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		var firstAnimList:Array<String> = [""];
		if (charAnimList.length > 0)
			firstAnimList = charAnimList;
		firstAnimDropdown = cast element("firstAnimDropdown");
		firstAnimDropdown.valueList = firstAnimList;
		firstAnimDropdown.value = characterData.firstAnimation;
		firstAnimDropdown.condition = function() { return characterData.firstAnimation; }
		firstAnimDropdown.onChanged = function() {
			characterData.firstAnimation = firstAnimDropdown.value;
		}

		var autoAnimButton:TextButton = cast element("autoAnimButton");
		autoAnimButton.onClicked = function()
		{
			if (charAnimList.contains("danceLeft") && charAnimList.contains("danceRight"))
			{
				characterData.idles = ["danceLeft", "danceRight"];
				characterData.firstAnimation = "danceLeft";
			}
			else if (charAnimList.contains("idle"))
			{
				characterData.idles = ["idle"];
				characterData.firstAnimation = "idle";
			}
		}

		var matchColorCheckbox:Checkbox = cast element("matchColorCheckbox");
		matchColorCheckbox.checked = characterData.matchColor;
		matchColorCheckbox.condition = function() { return characterData.matchColor; }
		matchColorCheckbox.onClicked = function()
		{
			characterData.matchColor = matchColorCheckbox.checked;
			refreshCharacterColor();
		}



		animName = cast element("animName");

		animPrefix = cast element("animPrefix");

		animPrefixDropdown = cast element("animPrefixDropdown");
		animPrefixDropdown.valueList = allAnimPrefixes;
		animPrefixDropdown.value = allAnimPrefixes[0];
		animPrefixDropdown.onChanged = function() {
			animPrefix.text = animPrefixDropdown.value;
		};

		animIndices = cast element("animIndices");

		var allIndices:TextButton = cast element("allIndices");
		allIndices.onClicked = function()
		{
			if (animPrefix.text != "" && allAnimData.indexOf(animPrefix.text) != -1)
			{
				var len:Int = allAnimData.split(animPrefix.text).length - 1;
				animIndices.text = "";
				for (i in 0...len)
				{
					animIndices.text += Std.string(i);
					if (i < len - 1)
						animIndices.text += ",";
				}
			}
		};

		animOffsetX = cast element("animOffsetX");
		animOffsetX.condition = function() {
			if (characterData.animations.length > 0)
				return characterData.animations[curCharAnim].offsets[0];
			return animOffsetX.value;
		}
		animOffsetX.onChanged = function() {
			if (characterData.animations.length > 0)
			{
				characterData.animations[curCharAnim].offsets[0] = animOffsetX.valueInt;
				refreshCharAnims();
				updateOffsets();
			}
		}

		animOffsetY = cast element("animOffsetY");
		animOffsetY.condition = function() {
			if (characterData.animations.length > 0)
				return characterData.animations[curCharAnim].offsets[1];
			return animOffsetY.value;
		}
		animOffsetY.onChanged = function() {
			if (characterData.animations.length > 0)
			{
				characterData.animations[curCharAnim].offsets[1] = animOffsetY.valueInt;
				refreshCharAnims();
				updateOffsets();
			}
		}

		animLooped = cast element("animLooped");
		animLooped.condition = function() {
			if (characterData.animations.length > 0)
				return characterData.animations[curCharAnim].loop;
			return animLooped.checked;
		}
		animLooped.onClicked = function() {
			if (characterData.animations.length > 0)
			{
				characterData.animations[curCharAnim].loop = animLooped.checked;
				reloadSingleAnimation(curCharAnim);
				playCurrentAnim();
			}
		}

		animFPS = cast element("animFPS");
		animFPS.condition = function() {
			if (characterData.animations.length > 0)
				return characterData.animations[curCharAnim].fps;
			return animFPS.value;
		}
		animFPS.onChanged = function() {
			if (characterData.animations.length > 0)
			{
				characterData.animations[curCharAnim].fps = animFPS.valueInt;
				reloadSingleAnimation(curCharAnim);
				playCurrentAnim();
			}
		}

		var addAnimButton:TextButton = cast element("addAnimButton");
		addAnimButton.onClicked = function()
		{
			var cause:String = "";
			if (animName.text.trim() == "")
				cause = "The animation name cannot be blank.";
			if (allAnimData.indexOf(animPrefix.text) == -1)
				cause = "The spritesheet does not contain an animation with that prefix.";

			if (cause != "")
				new Notify(cause);
			else
			{
				var newAnim:CharacterAnimation =
				{
					name: animName.text,
					prefix: animPrefix.text,
					fps: animFPS.valueInt,
					loop: animLooped.checked,
					offsets: [animOffsetX.valueInt, animOffsetY.valueInt]
				}

				if (animIndices.text != "")
				{
					newAnim.indices = [];
					var indicesSplit:Array<String> = animIndices.text.split(",");
					for (i in indicesSplit)
						newAnim.indices.push(Std.parseInt(i));
					newAnim.indices = Character.uncompactIndices(newAnim.indices);
				}

				var animToReplace:Int = -1;
				for (i in 0...characterData.animations.length)
				{
					if (characterData.animations[i].name == newAnim.name)
						animToReplace = i;
				}

				if (animToReplace > -1)
				{
					newAnim.offsets = characterData.animations[animToReplace].offsets;
					characterData.animations[animToReplace] = newAnim;
				}
				else
					characterData.animations.push(newAnim);

				if (newAnim.indices != null && newAnim.indices.length > 0)
				{
					character.animation.addByIndices(newAnim.name, newAnim.prefix, newAnim.indices, "", newAnim.fps, newAnim.loop);
					characterGhost.animation.addByIndices(newAnim.name, newAnim.prefix, newAnim.indices, "", newAnim.fps, newAnim.loop);
				}
				else
				{
					character.animation.addByPrefix(newAnim.name, newAnim.prefix, newAnim.fps, newAnim.loop);
					characterGhost.animation.addByPrefix(newAnim.name, newAnim.prefix, newAnim.fps, newAnim.loop);
				}

				refreshCharAnimList();
				playAnim(newAnim.name, true);
				if (characterGhost.animation.curAnim == null)
					playAnim(newAnim.name, true, true);
				refreshCharAnims();
				firstAnimDropdown.valueList = charAnimList;
				if (characterData.firstAnimation == "")
				{
					characterData.firstAnimation = newAnim.name;
					firstAnimDropdown.value = newAnim.name;
				}
			}
		}

		var removeAnimButton:TextButton = cast element("removeAnimButton");
		removeAnimButton.onClicked = tryDeleteAnim;

		curFrameText = cast element("curFrameText");
		curFrameText.text = "Frame: 0";

		var toggleAnimButton:TextButton = cast element("toggleAnimButton");
		toggleAnimButton.onClicked = function()
		{
			if (character.animation.curAnim != null)
				character.animation.curAnim.paused = !character.animation.curAnim.paused;
		}

		var prevFrame:TextButton = cast element("prevFrame");
		prevFrame.onClicked = function()
		{
			if (character.animation.curAnim != null && character.animation.curAnim.curFrame > 0)
				character.animation.curAnim.curFrame--;
		}

		var nextFrame:TextButton = cast element("nextFrame");
		nextFrame.onClicked = function()
		{
			if (character.animation.curAnim != null && character.animation.curAnim.curFrame < character.animation.curAnim.numFrames - 1)
				character.animation.curAnim.curFrame++;
		}



		var tabOptions:Array<TopMenuOption> = [];
		for (t in tabMenu.tabs)
			tabOptions.push({label: t, action: function() { tabMenu.selectTabByName(t); }, condition: function() { return tabMenu.curTabName == t; }, icon: "bullet"});

		var topmenu:TopMenu;
		topmenu = new TopMenu([
			{
				label: "File",
				options: [
					{
						label: "New",
						action: function() { _confirm("make a new character", _new); },
						shortcut: [FlxKey.CONTROL, FlxKey.N],
						icon: "new"
					},
					{
						label: "Open",
						action: function() { _confirm("load another character", _open); },
						shortcut: [FlxKey.CONTROL, FlxKey.O],
						icon: "open"
					},
					{
						label: "Save",
						action: function() { _save(false); },
						shortcut: [FlxKey.CONTROL, FlxKey.S],
						icon: "save"
					},
					{
						label: "Save As...",
						action: function() { _save(true); },
						shortcut: [FlxKey.CONTROL, FlxKey.SHIFT, FlxKey.S],
						icon: "save"
					},
					null,
					{
						label: "Exit",
						action: function() { _confirm("exit", function() { FlxG.switchState(new EditorMenuState()); }); },
						shortcut: [FlxKey.ESCAPE]
					}
				]
			},
			{
				label: "Edit",
				options: [
					{
						label: "Undo",
						action: undo,
						shortcut: [FlxKey.CONTROL, FlxKey.Z],
						icon: "undo"
					},
					{
						label: "Redo",
						action: redo,
						shortcut: [FlxKey.CONTROL, FlxKey.SHIFT, FlxKey.Z],
						icon: "redo"
					},
					null,
					{
						label: "Lock Click & Dragging",
						condition: function() { return posLocked; },
						action: function() { posLocked = !posLocked; },
						shortcut: [FlxKey.CONTROL, FlxKey.L],
						icon: "bullet"
					}
				]
			},
			{
				label: "View",
				options: [
					{
						label: "Information Panel",
						condition: function() { return members.contains(infoBox); },
						action: function() {
							if (members.contains(infoBox))
								remove(infoBox, true);
							else
								insert(members.indexOf(topmenu), infoBox);
						},
						icon: "bullet"
					},
					{
						label: "Animations Panel",
						condition: function() { return members.contains(charAnims); },
						action: function() {
							if (members.contains(charAnims))
								remove(charAnims, true);
							else
								insert(members.indexOf(topmenu), charAnims);
						},
						icon: "bullet"
					}
				]
			},
			{
				label: "Tab",
				options: tabOptions
			}
		]);
		topmenu.cameras = [camHUD];
		add(topmenu);

		dataLog = [Cloner.clone(characterData)];
	}

	override public function update(elapsed:Float)
	{
		mousePos.x = FlxG.mouse.x;
		mousePos.y = FlxG.mouse.y;

		if (FlxG.mouse.justMoved)
		{
			if (posLocked)
				UIControl.cursor = MouseCursor.ARROW;
			else 
			{
				UIControl.cursor = MouseCursor.ARROW;
				if (character.pixelsOverlapPoint(mousePos, 128, camGame))
					UIControl.cursor = MouseCursor.HAND;
			}
		}

		if (!pauseUndo && !DeepEquals.deepEquals(characterData, dataLog[undoPosition]))
		{
			if (undoPosition < dataLog.length - 1)
				dataLog.resize(undoPosition + 1);
			dataLog.push(Cloner.clone(characterData));
			unsaved = true;
			undoPosition = dataLog.length - 1;
			refreshFilename();
		}

		super.update(elapsed);

		if (movingCharacter)
		{
			dragOffset[0] += FlxG.mouse.deltaX;
			dragOffset[1] += FlxG.mouse.deltaY;
			if (movingAnimOffset)
			{
				characterData.animations[curCharAnim].offsets = [Std.int(dragStart[0] - dragOffset[0]), Std.int(dragStart[1] - dragOffset[1])];
				updateOffsets();
				refreshCharAnims();
			}
			else
			{
				characterData.position = [Std.int(dragStart[0] + dragOffset[0]), Std.int(dragStart[1] + dragOffset[1])];
				resetCharPosition();
			}

			if (Options.mouseJustReleased())
			{
				pauseUndo = false;
				movingCharacter = false;
			}
		}
		else
		{
			if (Options.mouseJustPressed())
			{
				if (!posLocked && UIControl.cursor == MouseCursor.HAND && !FlxG.mouse.overlaps(tabMenu, camHUD) && (!members.contains(infoBox) || !FlxG.mouse.overlaps(infoBox, camHUD)) && (!members.contains(charAnims) || !FlxG.mouse.overlaps(charAnims, camHUD)))
				{
					movingAnimOffset = FlxG.keys.pressed.SHIFT;
					if (characterData.animations.length <= 0)
						movingAnimOffset = false;

					movingCharacter = true;
					pauseUndo = true;
					if (movingAnimOffset)
						dragStart = Reflect.copy(characterData.animations[curCharAnim].offsets);
					else
						dragStart = Reflect.copy(characterData.position);
					dragOffset = [0, 0];
				}
			}
		}

		if (FlxG.keys.justPressed.DELETE)
			tryDeleteAnim();

		var frameText:String = "Frame: ";
		if (character.animation.curAnim != null)
			frameText += Std.string(character.animation.curAnim.curFrame);
		else
			frameText += "0";
		if (curFrameText.text != frameText)
			curFrameText.text = frameText;

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}

	function reloadAsset():Bool
	{
		var asset:String = characterData.asset;

		if (!Paths.imageExists(asset))
		{
			var choices:Array<Array<Dynamic>> = [["Return", function() { FlxG.switchState(new EditorMenuState()); }], ["Browse", function() {
				var file:FileBrowser = new FileBrowser();
				file.loadCallback = function(fullPath:String) {
					var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
					if (nameArray.indexOf("images") != -1)
					{
						while (nameArray[0] != "images")
							nameArray.shift();
						nameArray.shift();

						var finalName = nameArray.join("/");
						finalName = finalName.substr(0, finalName.length - 4);

						changeAsset(finalName);
					}
				}
				file.load("png");
			}]];
			new ChoiceWindow("The image asset does not exist:\n\"" + Paths.imagePath(asset) + "\"", choices);
			return false;
		}

		allAnimData = "";
		allAnimPrefixes = [];
		if (Paths.sparrowExists(asset))
		{
			character.frames = Paths.sparrow(asset);
			if (Paths.exists("images/" + characterData.asset + ".txt"))
				allAnimData = Paths.raw("images/" + characterData.asset + ".txt");
			else
				allAnimData = Paths.raw("images/" + characterData.asset + ".xml");
			allAnimPrefixes = Paths.sparrowAnimations(characterData.asset);
			if (animPrefixDropdown != null)
				animPrefixDropdown.valueList = allAnimPrefixes;
		}

		return true;
	}

	function changeAsset(asset:String):Bool
	{
		if (Paths.sparrowExists(asset))
		{
			characterData.asset = asset;
			reloadAsset();
			characterGhost.frames = character.frames;
			reloadAnimations();

			return true;
		}
		return false;
	}

	function reloadAnimations()
	{
		if (characterData.animations.length > 0)
		{
			var poppers:Array<CharacterAnimation> = [];
			for (i in 0...characterData.animations.length)
			{
				var anim:CharacterAnimation = characterData.animations[i];
				if (allAnimData.indexOf(anim.prefix) == -1)
					poppers.push(anim);
				else
					reloadSingleAnimation(i);
			}

			for (p in poppers)
				characterData.animations.remove(p);
		}
	}

	function reloadSingleAnimation(a:Int)
	{
		if (characterData.animations.length > a)
		{
			var anim:CharacterAnimation = characterData.animations[a];
			if (allAnimData.indexOf(anim.prefix) != -1)
			{
				if (anim.indices != null && anim.indices.length > 0)
				{
					character.animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
					characterGhost.animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
				}
				else
				{
					character.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
					characterGhost.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
				}
			}
		}
	}

	function refreshCharacterColor()
	{
		if (characterData.matchColor)
			character.color = 0xFFF9CF51;
		else
			character.color = FlxColor.WHITE;
		characterGhost.color = character.color;
	}

	function resetCharPosition()
	{
		character.x = characterData.position[0] + charPosOffset[0];
		character.y = characterData.position[1] + charPosOffset[1];
		characterGhost.setPosition(character.x, character.y);
	}

	function playAnim(animName:String, forced:Bool = false, ?ghost:Bool = false)
	{
		var charAnim:Int = charAnimList.indexOf(animName);
		if (charAnim > -1)
		{
			var animData:CharacterAnimation = characterData.animations[charAnim];
			if (animData != null)
			{
				if (ghost)
				{
					characterGhost.animation.play(animName, forced);
					characterGhost.offset.x = animData.offsets[0];
					characterGhost.offset.y = animData.offsets[1];
				}
				else
				{
					curCharAnim = charAnim;
					charAnims.selected = curCharAnim;
					refreshCharAnims();
					character.animation.play(animName, forced);
					character.offset.x = animData.offsets[0];
					character.offset.y = animData.offsets[1];
				}
			}
		}
	}

	function playCurrentAnim(?ghost:Bool = false)
	{
		if (ghost)
		{
			if (characterGhost.animation.curAnim != null)
				playAnim(characterGhost.animation.curAnim.name, true, true);
		}
		else
		{
			if (character.animation.curAnim != null)
				playAnim(character.animation.curAnim.name, true);
		}
	}

	function updateOffsets()
	{
		if (characterData.animations.length > 0)
		{
			var animData:CharacterAnimation = characterData.animations[curCharAnim];
			if (animData != null)
			{
				character.offset.x = animData.offsets[0];
				character.offset.y = animData.offsets[1];
			}
		}
	}

	function tryDeleteAnim()
	{
		if (characterData.animations.length > 0)
			new Confirm("Are you sure you want to delete the animation \"" + charAnimList[curCharAnim] + "\"?", function() { deleteAnim(charAnimList[curCharAnim]); });
	}

	function deleteAnim(animName:String)
	{
		var animData:CharacterAnimation = characterData.animations[charAnimList.indexOf(animName)];
		if (animData != null)
		{
			characterData.animations.remove(animData);
			if (curCharAnim >= charAnimList.length - 1)
			{
				curCharAnim = charAnimList.length - 2;
				charAnims.selected = curCharAnim;
			}
			charAnims.listOffset = Std.int(Math.min(charAnims.listOffset, characterData.animations.length - 1));
			refreshCharAnims();

			firstAnimDropdown.valueList = charAnimList;
			if (!charAnimList.contains(characterData.firstAnimation))
			{
				characterData.firstAnimation = charAnimList[0];
				firstAnimDropdown.value = charAnimList[0];
			}
		}
	}

	function refreshCharAnimList()
	{
		charAnimList = [];
		for (i in 0...characterData.animations.length)
			charAnimList.push(characterData.animations[i].name);
	}

	function refreshCharAnims()
	{
		refreshCharAnimList();

		charAnims.items = [];
		for (anim in characterData.animations)
			charAnims.items.push(anim.name + " (" + Std.string(anim.offsets[0]) + ", " + Std.string(anim.offsets[1]) + ")");

		charAnims.refreshText();
	}

	function undo()
	{
		if (undoPosition > 0)
		{
			var oldAsset:String = characterData.asset;
			undoPosition--;
			if (!unsaved)
			{
				unsaved = true;
				refreshFilename();
			}
			characterData = Cloner.clone(dataLog[undoPosition]);
			if (characterData.asset != oldAsset)
				changeAsset(characterData.asset);
			postUndoRedo();
		}
	}

	function redo()
	{
		if (undoPosition < dataLog.length - 1)
		{
			var oldAsset:String = characterData.asset;
			undoPosition++;
			if (!unsaved)
			{
				unsaved = true;
				refreshFilename();
			}
			characterData = Cloner.clone(dataLog[undoPosition]);
			if (characterData.asset != oldAsset)
				changeAsset(characterData.asset);
			postUndoRedo();
		}
	}

	function postUndoRedo()
	{
		resetCharPosition();

		character.scale.set(characterData.scale[0], characterData.scale[1]);
		characterGhost.scale.set(characterData.scale[0], characterData.scale[1]);
		character.updateHitbox();
		characterGhost.updateHitbox();
		character.antialiasing = characterData.antialias;
		characterGhost.antialiasing = character.antialiasing;
		character.flipX = characterData.flip;
		characterGhost.flipX = character.flipX;
		refreshCharacterColor();

		refreshCharAnims();
		reloadAnimations();

		if (characterData.animations.length > 0)
		{
			playCurrentAnim();
			if (characterGhost.animation.curAnim.name == characterData.animations[curCharAnim].name)
				playCurrentAnim(true);
		}
	}



	function _new()
	{
		var file:FileBrowser = new FileBrowser();
		file.label = "Choose a spritesheet for your character";
		file.loadCallback = function(fullPath:String)
		{
			var imageNameArray:Array<String> = fullPath.replace('\\','/').split('/');
			if (imageNameArray.indexOf("images") == -1)
				new Notify("The file you have selected is not a character asset.");
			else
			{
				while (imageNameArray[0] != "images")
					imageNameArray.shift();
				imageNameArray.shift();

				var finalImageName = imageNameArray.join('/').split('.png')[0];

				StoryCharacterEditorState.newCharacterImage = finalImageName;
				FlxG.switchState(new StoryCharacterEditorState(true, "", ""));
			}
		}
		file.load("png");
	}

	function _open()
	{
		var file:FileBrowser = new FileBrowser();
		file.loadCallback = function(fullPath:String) {
			var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
			if (jsonNameArray.indexOf("story_characters") == -1)
				new Notify("The file you have selected is not a character.");
			else
			{
				while (jsonNameArray[0] != "story_characters")
					jsonNameArray.shift();
				jsonNameArray.shift();

				var finalJsonName = jsonNameArray.join("/").split('.json')[0];

				FlxG.switchState(new StoryCharacterEditorState(false, finalJsonName, fullPath));
			}
		}
		file.load();
	}

	function _save(?browse:Bool = true)
	{
		var saveData:WeekCharacterData = Reflect.copy(characterData);
		saveData.animations = [];
		for (a in characterData.animations)
			saveData.animations.push(Reflect.copy(a));

		if (saveData.scale[0] == 1 && saveData.scale[1] == 1)
			Reflect.deleteField(saveData, "scale");

		for (a in saveData.animations)
		{
			if (a.loop == false)
				Reflect.deleteField(a, "loop");

			if (a.fps == 24)
				Reflect.deleteField(a, "fps");

			if (a.indices != null)
				a.indices = Character.compactIndices(a.indices);
		}

		var data:String = Json.stringify(saveData, null, "\t");
		if (Options.options.compactJsons)
			data = Json.stringify(saveData);

		if (data != null && data.length > 0)
		{
			if (browse || filename == "" || filename.replace("\\", "/").indexOf(id.replace("\\", "/")) == -1)
			{
				var file:FileBrowser = new FileBrowser();
				file.saveCallback = changeCurCharacter;
				file.save(id + ".json", data.trim());
			}
			else
			{
				FileBrowser.saveAs(filename, data.trim());
				unsaved = false;
				refreshFilename();
			}
		}
	}

	function changeCurCharacter(path:String)
	{
		changeSaveName(path);

		var jsonNameArray:Array<String> = path.replace('\\','/').split('/');
		if (jsonNameArray.contains("story_characters"))
		{
			while (jsonNameArray[0] != "story_characters")
				jsonNameArray.shift();
			jsonNameArray.shift();
			var finalJsonName = jsonNameArray.join("/").split('.json')[0];
			id = finalJsonName;
		}
	}
}