package editors;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import data.ObjectData;
import data.Options;
import objects.Character;
import objects.HealthIcon;
import objects.Stage;
import haxe.Json;
import menus.EditorMenuState;
import menus.StoryMenuState;

import lime.app.Application;

import funkui.TabMenu;
import funkui.Checkbox;
import funkui.TextButton;
import funkui.InputText;
import funkui.Stepper;
import funkui.DropdownMenu;
import funkui.Label;

using StringTools;

class StoryCharacterEditorState extends MusicBeatState
{
	public static var newCharacter:Bool = false;
	public static var newCharacterImage:String = "";
	public static var curCharacter:String = "";
	var charPos:Int = 1;
	var charPosOffset:Array<Int> = [0, 0];
	var otherCharPos:Int = 1;

	var myCharacter:FlxSprite;

	var allAnimData:String = "";
	var allAnimPrefixes:Array<String> = [];
	var animGhost:FlxSprite = null;
	var otherAnimGhost:Character;
	var myCharacterData:WeekCharacterData;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	var	movingCamera:Bool = false;
	var	movingCharacter:Bool = false;
	var	movingAnimOffset:Bool = false;
	var dragStart:Array<Int> = [0, 0];
	var dragOffset:Array<Float> = [0, 0];

	var charAnimList:Array<String>;
	var charAnims:FlxTypedSpriteGroup<FlxText>;
	var curCharAnim:Int = -1;
	var listOffset:Int = 0;

	var tabMenu:IsolatedTabMenu;

	var charPosDropdown:DropdownMenu = null;
	var charPosStepper:Stepper;
	var otherCharPosStepper:Stepper;
	var otherCharAnimDropdown:DropdownMenu;

	var charPositionText:FlxText;
	var posLocked:Checkbox;
	var charScaleX:Stepper;
	var charScaleY:Stepper;
	var camPosX:Stepper;
	var camPosY:Stepper;
	var firstAnimDropdown:DropdownMenu;

	var animName:InputText;
	var animPrefix:InputText;
	var animPrefixDropdown:DropdownMenu = null;
	var animIndices:InputText;
	var animLooped:Checkbox;
	var animFPS:Stepper;
	var curFrameText:FlxText;

	override public function create()
	{
		camGame = new FlxCamera();
		FlxG.cameras.add(camGame);

		camHUD = new FlxCamera();
		camHUD.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camHUD, false);

		super.create();

		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);
		add(bgYellow);

		if (newCharacter)
		{
			myCharacterData =
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
			myCharacterData = MenuCharacter.parseCharacter(curCharacter);

		myCharacter = new FlxSprite();
		reloadAsset();

		myCharacter.antialiasing = myCharacterData.antialias;
		myCharacter.flipX = myCharacterData.flip;

		if (myCharacterData.scale != null && myCharacterData.scale.length == 2)
		{
			myCharacter.scale.x = myCharacterData.scale[0];
			myCharacter.scale.y = myCharacterData.scale[1];
		}
		else
			myCharacterData.scale = [1, 1];
		myCharacter.updateHitbox();

		animGhost = new FlxSprite(myCharacter.x, myCharacter.y);
		animGhost.alpha = 0.5;
		animGhost.visible = false;
		animGhost.frames = myCharacter.frames;
		animGhost.antialiasing = myCharacter.antialiasing;
		animGhost.flipX = myCharacter.flipX;

		refreshCharacterColor();

		if (newCharacter)
		{
			var idleIndex:String = allAnimPrefixes[0];
			for (a in allAnimPrefixes)
			{
				if (a.toLowerCase().indexOf("idle") != -1 || a.toLowerCase().indexOf("dance") != -1)
				{
					idleIndex = a;
					break;
				}
			}
			myCharacterData.animations.push({name: "idle", prefix: idleIndex, fps: 24, loop: false, offsets: [0, 0]});
			myCharacterData.firstAnimation = "idle";
			myCharacterData.idles = ["idle"];
		}
		reloadAnimations();

		animGhost.scale.x = myCharacter.scale.x;
		animGhost.scale.y = myCharacter.scale.y;
		animGhost.updateHitbox();

		otherAnimGhost = new Character(0, 0, TitleState.defaultVariables.player2);
		otherAnimGhost.alpha = 0.5;
		otherAnimGhost.visible = false;

		add(animGhost);
		add(myCharacter);

		charAnimList = [];
		for (i in 0...myCharacterData.animations.length)
			charAnimList.push(myCharacterData.animations[i].name);

		if (myCharacterData.firstAnimation != null && myCharacterData.firstAnimation != "")
		{
			if (!charAnimList.contains(myCharacterData.firstAnimation))
				myCharacterData.firstAnimation = charAnimList[0];

			playAnim(myCharacterData.firstAnimation);
			playAnim(myCharacterData.firstAnimation, false, true);
		}

		charAnims = new FlxTypedSpriteGroup<FlxText>();
		charAnims.cameras = [camHUD];
		add(charAnims);



		tabMenu = new IsolatedTabMenu(50, 50, 250, 500);
		tabMenu.cameras = [camHUD];
		tabMenu.x = Std.int(FlxG.width - 425);
		add(tabMenu);
		refreshCharAnims();

		var tabButtons:TabButtons = new TabButtons(0, 0, 425, ["General", "Properties", "Animations", "Offsets", "Help"]);
		tabButtons.cameras = [camHUD];
		tabButtons.menu = tabMenu;
		add(tabButtons);



		var tabGroupGeneral = new TabGroup();

		var loadCharacterButton:TextButton = new TextButton(10, 10, 115, 20, "Load");
		loadCharacterButton.onClicked = loadCharacter;
		tabGroupGeneral.add(loadCharacterButton);

		var saveCharacterButton:TextButton = new TextButton(loadCharacterButton.x + 115, loadCharacterButton.y, 115, 20, "Save");
		saveCharacterButton.onClicked = saveCharacter;
		tabGroupGeneral.add(saveCharacterButton);

		var changeAssetButton:TextButton = new TextButton(10, saveCharacterButton.y + 30, 230, 20, "Change Asset");
		changeAssetButton.onClicked = function() {
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = changeAssetCallback;
			file.load("png");
		}
		tabGroupGeneral.add(changeAssetButton);

		var showAnimGhost:Checkbox = new Checkbox(10, changeAssetButton.y + 30, "Animation Ghost");
		showAnimGhost.checked = false;
		showAnimGhost.onClicked = function()
		{
			animGhost.visible = showAnimGhost.checked;
		};
		tabGroupGeneral.add(showAnimGhost);

		charPosDropdown = new DropdownMenu(10, showAnimGhost.y + 40, 230, 20, "left", ["left", "center", "right"]);
		charPosDropdown.onChanged = function() {
			switch (charPosDropdown.value)
			{
				case "left": tabMenu.x = Std.int(FlxG.width - 425);
				case "center": tabMenu.x = 50;
				case "right": tabMenu.x = 50;
			}
			resetCharPosition();
			refreshCharAnims();
		}
		resetCharPosition();
		tabGroupGeneral.add(charPosDropdown);
		var charPosLabel:Label = new Label("Preview Position:", charPosDropdown);
		tabGroupGeneral.add(charPosLabel);

		tabMenu.addGroup(tabGroupGeneral);



		var tabGroupProperties = new TabGroup();

		charPositionText = new FlxText(10, 10, 150, "Position:", 18);
		charPositionText.color = FlxColor.BLACK;
		charPositionText.font = "VCR OSD Mono";
		charPositionText.alignment = CENTER;
		tabGroupProperties.add(charPositionText);

		posLocked = new Checkbox(charPositionText.x + 150, charPositionText.y + 10, "Lock", true);
		tabGroupProperties.add(posLocked);

		var charAntialias:Checkbox = new Checkbox(10, posLocked.y + 30, "Antialias", myCharacterData.antialias);
		charAntialias.onClicked = function()
		{
			myCharacterData.antialias = charAntialias.checked;
			myCharacter.antialiasing = myCharacterData.antialias;
			animGhost.antialiasing = myCharacter.antialiasing;
		};
		tabGroupProperties.add(charAntialias);

		var charFlip:Checkbox = new Checkbox(charAntialias.x + 150, charAntialias.y, "Flip", myCharacterData.flip);
		charFlip.onClicked = function()
		{
			myCharacterData.flip = charFlip.checked;
			myCharacter.flipX = myCharacterData.flip;
			animGhost.flipX = myCharacter.flipX;
		};
		tabGroupProperties.add(charFlip);

		var charDanceSpeed:Stepper = new Stepper(10, charAntialias.y + 40, 230, 20, myCharacterData.danceSpeed, 0.25, 0, 9999, 2);
		charDanceSpeed.onChanged = function() { myCharacterData.danceSpeed = charDanceSpeed.value; }
		tabGroupProperties.add(charDanceSpeed);
		var charDanceSpeedLabel:Label = new Label("Dance Speed:", charDanceSpeed);
		tabGroupProperties.add(charDanceSpeedLabel);

		charScaleX = new Stepper(10, charDanceSpeed.y + 40, 115, 20, myCharacterData.scale[0], 0.05, 0, 9999, 3);
		charScaleX.onChanged = function() {
			myCharacterData.scale[0] = charScaleX.value;
			myCharacter.scale.x = myCharacterData.scale[0];
			animGhost.scale.x = myCharacter.scale.x;
			myCharacter.updateHitbox();
			animGhost.updateHitbox();
			if (myCharacterData.animations.length > 0)
			{
				playAnim(myCharacterData.animations[curCharAnim].name, true);
				if (animGhost.animation.curAnim.name == myCharacterData.animations[curCharAnim].name)
					playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			}
		};
		tabGroupProperties.add(charScaleX);
		charScaleY = new Stepper(charScaleX.x + 115, charScaleX.y, 115, 20, myCharacterData.scale[1], 0.05, 0, 9999, 3);
		charScaleY.onChanged = function() {
			myCharacterData.scale[1] = charScaleY.value;
			myCharacter.scale.y = myCharacterData.scale[1];
			animGhost.scale.y = myCharacter.scale.y;
			myCharacter.updateHitbox();
			animGhost.updateHitbox();
			if (myCharacterData.animations.length > 0)
			{
				playAnim(myCharacterData.animations[curCharAnim].name, true);
				if (animGhost.animation.curAnim.name == myCharacterData.animations[curCharAnim].name)
					playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			}
		};
		tabGroupProperties.add(charScaleY);
		var charScaleLabel:Label = new Label("Scale:", charScaleX);
		tabGroupProperties.add(charScaleLabel);

		var idlesInput:InputText = new InputText(10, charScaleX.y + 40, 115);
		idlesInput.focusGained = function() {
			idlesInput.text = myCharacterData.idles.join(",");
		}
		idlesInput.focusLost = function() {
			idlesInput.text = myCharacterData.idles.join(",");
		}
		idlesInput.callback = function(text:String, action:String) {
			myCharacterData.idles = text.split(",");
			var poppers:Array<String> = [];
			var charLowerList:Array<String> = [];
			for (a in charAnimList)
				charLowerList.push(a.toLowerCase());

			for (i in 0...myCharacterData.idles.length)
			{
				if (!charLowerList.contains(myCharacterData.idles[i].toLowerCase()))
					poppers.push(myCharacterData.idles[i]);
				else if (!charAnimList.contains(myCharacterData.idles[i]))
					myCharacterData.idles[i] = charAnimList[charLowerList.indexOf(myCharacterData.idles[i].toLowerCase())];
			}

			for (p in poppers)
				myCharacterData.idles.remove(p);
		}
		tabGroupProperties.add(idlesInput);
		var idlesInputLabel:Label = new Label("Idle Animations:", idlesInput);
		tabGroupProperties.add(idlesInputLabel);

		var firstAnimList:Array<String> = [""];
		if (charAnimList.length > 0)
			firstAnimList = charAnimList;
		firstAnimDropdown = new DropdownMenu(idlesInput.x + 115, idlesInput.y, 115, 20, myCharacterData.firstAnimation, firstAnimList, true);
		firstAnimDropdown.onChanged = function() {
			myCharacterData.firstAnimation = firstAnimDropdown.value;
		};
		tabGroupProperties.add(firstAnimDropdown);
		var firstAnimLabel:Label = new Label("First Animation:", firstAnimDropdown);
		tabGroupProperties.add(firstAnimLabel);

		var autoAnimButton:TextButton = new TextButton(10, firstAnimDropdown.y + 30, 230, 20, "Fill Anim Fields");
		autoAnimButton.onClicked = function()
		{
			if (charAnimList.contains("danceLeft") && charAnimList.contains("danceRight"))
			{
				myCharacterData.idles = ["danceLeft", "danceRight"];
				myCharacterData.firstAnimation = "danceLeft";
			}
			else if (charAnimList.contains("idle"))
			{
				myCharacterData.idles = ["idle"];
				myCharacterData.firstAnimation = "idle";
			}
			else if (charAnimList.contains("firstDeath"))
				myCharacterData.firstAnimation = "firstDeath";
			idlesInput.text = myCharacterData.idles.join(",");
		};
		tabGroupProperties.add(autoAnimButton);

		var matchColorCheckbox:Checkbox = new Checkbox(10, autoAnimButton.y + 30, "Match Color", myCharacterData.matchColor);
		matchColorCheckbox.onClicked = function()
		{
			myCharacterData.matchColor = matchColorCheckbox.checked;
			refreshCharacterColor();
		};
		tabGroupProperties.add(matchColorCheckbox);

		tabMenu.addGroup(tabGroupProperties);



		var tabGroupAnims = new TabGroup();

		animName = new InputText(10, 20);
		tabGroupAnims.add(animName);
		var animNameLabel:Label = new Label("Animation Name:", animName);
		tabGroupAnims.add(animNameLabel);

		var commonAnimations:Array<String> = Paths.textData("commonAnimations").replace("\r","").split("\n");
		var animNameDropdown:DropdownMenu = new DropdownMenu(10, animName.y + 30, 230, 20, commonAnimations[0], commonAnimations, true);
		animNameDropdown.onChanged = function() {
			animName.text = animNameDropdown.value;
		};
		tabGroupAnims.add(animNameDropdown);

		animPrefix = new InputText(10, animNameDropdown.y + 40);

		tabGroupAnims.add(animPrefix);
		var animPrefixLabel:Label = new Label("Prefix:", animPrefix);
		tabGroupAnims.add(animPrefixLabel);

		animPrefixDropdown = new DropdownMenu(10, animPrefix.y + 30, 230, 20, allAnimPrefixes[0], allAnimPrefixes, true);
		animPrefixDropdown.onChanged = function() {
			animPrefix.text = animPrefixDropdown.value;
		};
		tabGroupAnims.add(animPrefixDropdown);

		animIndices = new InputText(10, animPrefixDropdown.y + 40);
		tabGroupAnims.add(animIndices);
		var animIndicesLabel:Label = new Label("Indices (Optional):", animIndices);
		tabGroupAnims.add(animIndicesLabel);

		var allIndices:TextButton = new TextButton(10, animIndices.y + 30, 230, 20, "All Indices");
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
		tabGroupAnims.add(allIndices);

		animLooped = new Checkbox(10, animIndices.y + 70, "Loop");
		animLooped.checked = false;
		tabGroupAnims.add(animLooped);

		animFPS = new Stepper(animLooped.x + 115, animLooped.y, 115, 20, 24, 1, 0);
		tabGroupAnims.add(animFPS);
		var animFPSLabel:Label = new Label("FPS:", animFPS);
		tabGroupAnims.add(animFPSLabel);

		var addAnimButton:TextButton = new TextButton(10, animLooped.y + 30, 230, 20, "Add/Update Animation");
		addAnimButton.onClicked = function()
		{
			var cause:Int = -1;
			if (animName.text.trim() == "")
				cause = 0;
			if (allAnimData.indexOf(animPrefix.text) == -1)
				cause = 1;

			var causes:Array<String> = ["The animation name cannot be blank.", "The spritesheet does not contain an animation with that prefix."];

			if (cause > -1)
			{
				var notify:Notify = new Notify(300, 100, causes[cause], this);
				notify.cameras = [camHUD];
			}
			else
			{
				var newAnim:CharacterAnimation =
				{
					name: animName.text,
					prefix: animPrefix.text,
					fps: animFPS.valueInt,
					loop: animLooped.checked,
					offsets: [0, 0]
				};

				if (curCharAnim > -1)
				{
					newAnim.offsets[0] = myCharacterData.animations[curCharAnim].offsets[0];
					newAnim.offsets[1] = myCharacterData.animations[curCharAnim].offsets[1];
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
				for (i in 0...myCharacterData.animations.length)
				{
					if (myCharacterData.animations[i].name == newAnim.name)
						animToReplace = i;
				}

				if (animToReplace > -1)
				{
					newAnim.offsets = myCharacterData.animations[animToReplace].offsets;
					myCharacterData.animations[animToReplace] = newAnim;
				}
				else
					myCharacterData.animations.push(newAnim);

				if (newAnim.indices != null && newAnim.indices.length > 0)
				{
					myCharacter.animation.addByIndices(newAnim.name, newAnim.prefix, newAnim.indices, "", newAnim.fps, newAnim.loop);
					animGhost.animation.addByIndices(newAnim.name, newAnim.prefix, newAnim.indices, "", newAnim.fps, newAnim.loop);
				}
				else
				{
					myCharacter.animation.addByPrefix(newAnim.name, newAnim.prefix, newAnim.fps, newAnim.loop);
					animGhost.animation.addByPrefix(newAnim.name, newAnim.prefix, newAnim.fps, newAnim.loop);
				}

				refreshCharAnims();
				playAnim(newAnim.name, true);
				if (animGhost.animation.curAnim == null)
					playAnim(newAnim.name, true, true);
				refreshCharAnims();
				firstAnimDropdown.valueList = charAnimList;
				if (myCharacterData.firstAnimation == "")
				{
					myCharacterData.firstAnimation = newAnim.name;
					firstAnimDropdown.value = newAnim.name;
				}
			}
		};
		tabGroupAnims.add(addAnimButton);

		curFrameText = new FlxText(10, addAnimButton.y + 30, 230, "Frame: 0", 18);
		curFrameText.color = FlxColor.BLACK;
		curFrameText.font = "VCR OSD Mono";
		curFrameText.alignment = CENTER;
		tabGroupAnims.add(curFrameText);

		var toggleAnimButton:TextButton = new TextButton(10, curFrameText.y + 30, 230, 20, "Toggle");
		toggleAnimButton.onClicked = function()
		{
			if (myCharacter.animation.curAnim != null)
				myCharacter.animation.curAnim.paused = !myCharacter.animation.curAnim.paused;
		};
		tabGroupAnims.add(toggleAnimButton);

		var prevFrame:TextButton = new TextButton(10, toggleAnimButton.y + 30, 115, 20, "Prev");
		prevFrame.onClicked = function()
		{
			if (myCharacter.animation.curAnim != null && myCharacter.animation.curAnim.curFrame > 0)
				myCharacter.animation.curAnim.curFrame--;
		};
		tabGroupAnims.add(prevFrame);

		var nextFrame:TextButton = new TextButton(prevFrame.x + 115, prevFrame.y, 115, 20, "Next");
		nextFrame.onClicked = function()
		{
			if (myCharacter.animation.curAnim != null && myCharacter.animation.curAnim.curFrame < myCharacter.animation.curAnim.numFrames - 1)
				myCharacter.animation.curAnim.curFrame++;
		};
		tabGroupAnims.add(nextFrame);

		tabMenu.addGroup(tabGroupAnims);



		var tabGroupOffsets = new TabGroup();

		var offsetStepper:Stepper = new Stepper(10, 10, 230, 20, 0, 1, -9999, 9999, 3);
		tabGroupOffsets.add(offsetStepper);

		var offsetAddX:TextButton = new TextButton(10, offsetStepper.y + 30, 115, 20, "Add X");
		offsetAddX.onClicked = function() {
			for (a in myCharacterData.animations)
				a.offsets[0] += Std.int(offsetStepper.value);

			playAnim(myCharacterData.animations[curCharAnim].name, true);
			playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			refreshCharAnims();
		}
		tabGroupOffsets.add(offsetAddX);

		var offsetAddY:TextButton = new TextButton(offsetAddX.x + 115, offsetAddX.y, 115, 20, "Add Y");
		offsetAddY.onClicked = function() {
			for (a in myCharacterData.animations)
				a.offsets[1] += Std.int(offsetStepper.value);

			playAnim(myCharacterData.animations[curCharAnim].name, true);
			playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			refreshCharAnims();
		}
		tabGroupOffsets.add(offsetAddY);

		var offsetScaleX:TextButton = new TextButton(10, offsetAddX.y + 30, 115, 20, "Scale X");
		offsetScaleX.onClicked = function() {
			for (a in myCharacterData.animations)
				a.offsets[0] = Std.int(a.offsets[0] * offsetStepper.value);

			playAnim(myCharacterData.animations[curCharAnim].name, true);
			playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			refreshCharAnims();
		}
		tabGroupOffsets.add(offsetScaleX);

		var offsetScaleY:TextButton = new TextButton(offsetScaleX.x + 115, offsetScaleX.y, 115, 20, "Scale Y");
		offsetScaleY.onClicked = function() {
			for (a in myCharacterData.animations)
				a.offsets[1] = Std.int(a.offsets[1] * offsetStepper.value);

			playAnim(myCharacterData.animations[curCharAnim].name, true);
			playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			refreshCharAnims();
		}
		tabGroupOffsets.add(offsetScaleY);

		var offsetZero:TextButton = new TextButton(10, offsetScaleY.y + 30, 230, 20, "Set current to 0");
		offsetZero.onClicked = function() {
			var offX:Int = myCharacterData.animations[curCharAnim].offsets[0];
			var offY:Int = myCharacterData.animations[curCharAnim].offsets[1];
			for (a in myCharacterData.animations)
			{
				a.offsets[0] -= offX;
				a.offsets[1] -= offY;
			}
			myCharacterData.position[0] -= offX;
			myCharacterData.position[1] -= offY;

			resetCharPosition();
			playAnim(myCharacterData.animations[curCharAnim].name, true);
			playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			refreshCharAnims();
		}
		tabGroupOffsets.add(offsetZero);

		tabMenu.addGroup(tabGroupOffsets);



		var tabGroupHelp = new TabGroup();

		var help:String = Paths.text("helpText").replace("\r","").split("!CharacterEditor\n")[1].split("\n\n")[0];
		var helpText:FlxText = new FlxText(10, 10, 230, help + "\n", 12);
		helpText.color = FlxColor.BLACK;
		helpText.font = "VCR OSD Mono";
		tabGroupHelp.add(helpText);

		tabMenu.addGroup(tabGroupHelp);
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
			saveCharacter();

		super.update(elapsed);

		charAnims.forEachAlive(function(anim:FlxText)
		{
			if (FlxG.mouse.overlaps(anim, camHUD))
			{
				anim.borderSize = 2;
				anim.borderColor = FlxColor.GRAY;
			}
			else
			{
				anim.borderSize = 1;
				anim.borderColor = FlxColor.BLACK;
			}
		});

		if (movingCharacter)
		{
			dragOffset[0] += FlxG.mouse.drag.x;
			dragOffset[1] += FlxG.mouse.drag.y;
			if (movingAnimOffset)
			{
				myCharacterData.animations[curCharAnim].offsets = [Std.int(dragStart[0] - dragOffset[0]), Std.int(dragStart[1] - dragOffset[1])];
				playAnim(myCharacterData.animations[curCharAnim].name, true);
				if (animGhost.animation.curAnim.name == myCharacterData.animations[curCharAnim].name)
					playAnim(myCharacterData.animations[curCharAnim].name, true, true);
				updateCharAnim(curCharAnim);
			}
			else
			{
				if (charPosDropdown.value == "right")
					myCharacterData.position = [Std.int(dragStart[0] - dragOffset[0]), Std.int(dragStart[1] + dragOffset[1])];
				else
					myCharacterData.position = [Std.int(dragStart[0] + dragOffset[0]), Std.int(dragStart[1] + dragOffset[1])];
				resetCharPositionForMenuCharacter();
				myCharacter.y = myCharacterData.position[1] + charPosOffset[1];
				animGhost.setPosition(myCharacter.x, myCharacter.y);
			}

			if (Options.mouseJustReleased())
				movingCharacter = false;
		}
		else
		{
			if (Options.mouseJustPressed())
			{
				var clickedOne:Bool = false;
				var i:Int = 0;
				charAnims.forEachAlive(function(anim:FlxText)
				{
					if (FlxG.mouse.overlaps(anim, camHUD))
					{
						var animData:CharacterAnimation = myCharacterData.animations[i];
						if (animData != null)
						{
							playAnim(animData.name, true);
							animName.text = animData.name;
							animPrefix.text = animData.prefix;
							if (animData.indices != null && animData.indices.length > 0)
								animIndices.text = Character.compactIndices(animData.indices).join(",");
							else
								animIndices.text = "";
							animLooped.checked = animData.loop;
							animFPS.value = animData.fps;
						}
						clickedOne = true;
					}
					i++;
				});

				if (clickedOne)
					refreshCharAnims();

				if (!posLocked.checked && !clickedOne && !FlxG.mouse.overlaps(tabMenu, camHUD))
				{
					movingAnimOffset = FlxG.keys.pressed.SHIFT;
					if (myCharacterData.animations.length <= 0)
						movingAnimOffset = false;

					movingCharacter = true;
					if (movingAnimOffset)
						dragStart = Reflect.copy(myCharacterData.animations[curCharAnim].offsets);
					else
						dragStart = Reflect.copy(myCharacterData.position);
					dragOffset = [0, 0];
				}
			}
			else if (Options.mouseJustPressed(true))
			{
				charAnims.forEachAlive(function(anim:FlxText)
				{
					if (FlxG.mouse.overlaps(anim, camHUD))
					{
						var animationName:String = anim.text.split(" ")[0];
						if (animationName == ">")
							animationName = anim.text.split(" ")[1];
						playAnim(animationName, true, true);
					}
				});
			}
		}

		if (FlxG.keys.justPressed.UP && FlxG.keys.pressed.CONTROL)
		{
			listOffset++;
			listOffset = Std.int(Math.min(listOffset, myCharacterData.animations.length - 1));

			for (i in 0...charAnims.members.length)
				updateCharAnim(i);
		}

		if (FlxG.keys.justPressed.DOWN && FlxG.keys.pressed.CONTROL)
		{
			listOffset--;
			listOffset = Std.int(Math.max(listOffset, 0));

			for (i in 0...charAnims.members.length)
				updateCharAnim(i);
		}

		if (!posLocked.checked)
		{
			if (FlxG.keys.justPressed.LEFT)
				doMovement(-1, 0);

			if (FlxG.keys.justPressed.RIGHT)
				doMovement(1, 0);

			if (FlxG.keys.justPressed.UP && !FlxG.keys.pressed.CONTROL)
				doMovement(0, -1);

			if (FlxG.keys.justPressed.DOWN && !FlxG.keys.pressed.CONTROL)
				doMovement(0, 1);
		}

		if (FlxG.keys.justPressed.DELETE && myCharacterData.animations.length > 0)
		{
			var confirm:Confirm = new Confirm(300, 100, "Are you sure you want to delete the current animation?", this);
			confirm.yesFunc = function() {
				deleteAnim(charAnimList[curCharAnim]);
			}
			confirm.cameras = [camHUD];
		}

		var posTxt:String = "Position:\n" + Std.string(myCharacterData.position);
		if (charPositionText.text != posTxt)
			charPositionText.text = posTxt;

		var frameText:String = "Frame: ";
		if (myCharacter.animation.curAnim != null)
			frameText += Std.string(myCharacter.animation.curAnim.curFrame);
		else
			frameText += "0";
		if (curFrameText.text != frameText)
			curFrameText.text = frameText;

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new EditorMenuState());
	}

	function reloadAsset()
	{
		var asset:String = myCharacterData.asset;
		asset = "ui/story_characters/" + asset;

		if (!Paths.imageExists(asset))
		{
			Application.current.window.alert("The image asset does not exist: " + Paths.imagePath(asset), "Alert");
			FlxG.switchState(new EditorMenuState());
			return;
		}

		allAnimData = "";
		allAnimPrefixes = [];
		if (Paths.sparrowExists(asset))
		{
			myCharacter.frames = Paths.sparrow(asset);
			myCharacter.y = myCharacterData.position[1] + 56;
			charPosOffset = [0, 56];
			if (Paths.exists("images/ui/story_characters/" + myCharacterData.asset + ".txt"))
				allAnimData = Paths.raw("images/ui/story_characters/" + myCharacterData.asset + ".txt");
			else
				allAnimData = Paths.raw("images/ui/story_characters/" + myCharacterData.asset + ".xml");
			allAnimPrefixes = Paths.sparrowAnimations("ui/story_characters/" + myCharacterData.asset);
			if (animPrefixDropdown != null)
				animPrefixDropdown.valueList = allAnimPrefixes;
		}
	}

	function reloadAnimations()
	{
		if (myCharacterData.animations.length > 0)
		{
			var poppers:Array<CharacterAnimation> = [];
			for (anim in myCharacterData.animations)
			{
				if (allAnimData.indexOf(anim.prefix) == -1)
					poppers.push(anim);
				else
				{
					if (anim.indices != null && anim.indices.length > 0)
					{
						myCharacter.animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
						animGhost.animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
					}
					else
					{
						myCharacter.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
						animGhost.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
					}
				}
			}

			for (p in poppers)
				myCharacterData.animations.remove(p);
		}
	}

	function refreshCharacterColor()
	{
		if (myCharacterData.matchColor)
			myCharacter.color = 0xFFF9CF51;
		else
			myCharacter.color = FlxColor.WHITE;
		animGhost.color = myCharacter.color;
	}

	function resetCharPosition()
	{
		resetCharPositionForMenuCharacter();
		myCharacter.y = myCharacterData.position[1] + charPosOffset[1];
		animGhost.x = myCharacter.x;
		animGhost.y = myCharacter.y;
	}

	function resetCharPositionForMenuCharacter()
	{
		switch (charPosDropdown.value)
		{
			case "center": myCharacter.x = (FlxG.width - myCharacter.width + myCharacterData.position[0]) / 2;
			case "right": myCharacter.x = FlxG.width - myCharacter.width - myCharacterData.position[0];
			default: myCharacter.x = myCharacterData.position[0];
		}
	}

	function doMovement(xDir:Int, yDir:Int)
	{
		if (FlxG.keys.pressed.SHIFT && myCharacterData.animations.length > 0)
		{
			myCharacterData.animations[curCharAnim].offsets[0] -= xDir;
			myCharacterData.animations[curCharAnim].offsets[1] -= yDir;
			playAnim(myCharacterData.animations[curCharAnim].name, true);
			if (animGhost.animation.curAnim.name == myCharacterData.animations[curCharAnim].name)
				playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			updateCharAnim(curCharAnim);
		}
		else
		{
			if (charPosDropdown.value == "right")
				myCharacterData.position[0] -= xDir;
			else
				myCharacterData.position[0] += xDir;
			myCharacterData.position[1] += yDir;
			resetCharPosition();
		}
	}

	function playAnim(animName:String, forced:Bool = false, ?ghost:Bool = false)
	{
		var charAnim:Int = charAnimList.indexOf(animName);
		if (charAnim > -1)
		{
			var animData:CharacterAnimation = myCharacterData.animations[charAnim];
			if (animData != null)
			{
				if (ghost)
				{
					animGhost.animation.play(animName, forced);
					animGhost.offset.x = animData.offsets[0];
					animGhost.offset.y = animData.offsets[1];
				}
				else
				{
					curCharAnim = charAnim;
					myCharacter.animation.play(animName, forced);
					myCharacter.offset.x = animData.offsets[0];
					myCharacter.offset.y = animData.offsets[1];
				}
			}
		}
	}

	function deleteAnim(animName:String)
	{
		var animData:CharacterAnimation = myCharacterData.animations[charAnimList.indexOf(animName)];
		if (animData != null)
		{
			myCharacterData.animations.remove(animData);
			if (curCharAnim >= charAnimList.length - 1)
				curCharAnim = charAnimList.length - 2;
			listOffset = Std.int(Math.min(listOffset, myCharacterData.animations.length - 1));
			refreshCharAnims();

			firstAnimDropdown.valueList = charAnimList;
			if (!charAnimList.contains(myCharacterData.firstAnimation))
			{
				myCharacterData.firstAnimation = charAnimList[0];
				firstAnimDropdown.value = charAnimList[0];
			}
		}
	}

	function refreshCharAnims(forceRebuild:Bool = false)
	{
		if (charAnims.members.length != myCharacterData.animations.length || forceRebuild)
		{
			charAnims.forEachAlive(function(anim:FlxText)
			{
				anim.kill();
				anim.destroy();
			});
			charAnims.clear();
			charAnimList = [];

			for (i in 0...myCharacterData.animations.length)
			{
				charAnimList.push(myCharacterData.animations[i].name);
				var txt:FlxText = new FlxText(0, 0, 0, "", 16);
				txt.font = "VCR OSD Mono";
				txt.borderColor = FlxColor.BLACK;
				txt.borderStyle = OUTLINE;
				charAnims.add(txt);
			}
		}

		for (i in 0...charAnims.members.length)
			updateCharAnim(i);
	}

	function updateCharAnim(anim:Int)
	{
		var txt:FlxText = charAnims.members[anim];
		txt.y = 50 + ((anim - listOffset) * 25);
		txt.text = myCharacterData.animations[anim].name + " " + Std.string(myCharacterData.animations[anim].offsets);
		if (anim == curCharAnim)
			txt.text = "> " + txt.text;

		if (tabMenu.x > FlxG.width / 2)
			txt.x = 20;
		else
			txt.x = Std.int(FlxG.width - 20 - txt.width);
	}

	function changeAssetCallback(fullPath:String)
	{
		var imageNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (imageNameArray.contains("story_characters"))
		{
			while (imageNameArray[0] != "story_characters")
				imageNameArray.remove(imageNameArray[0]);
			imageNameArray.remove(imageNameArray[0]);

			var finalImageName = imageNameArray.join('/').split('.png')[0];

			myCharacterData.asset = finalImageName;
			reloadAsset();
			animGhost.frames = myCharacter.frames;
			reloadAnimations();
		}
	}



	function saveCharacter()
	{
		var saveData:WeekCharacterData = Reflect.copy(myCharacterData);
		saveData.animations = [];
		for (a in myCharacterData.animations)
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

		if ((data != null) && (data.length > 0))
		{
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = changeCurCharacter;
			file.save(curCharacter + ".json", data.trim());
		}
	}

	function loadCharacter()
	{
		var file:FileBrowser = new FileBrowser();
		file.loadCallback = EditorMenuState.loadStoryCharacterCallback;
		file.load();
	}

	function changeCurCharacter(path:String)
	{
		var jsonNameArray:Array<String> = path.replace('\\','/').split('/');
		if (jsonNameArray.contains("story_characters"))
		{
			while (jsonNameArray[0] != "story_characters")
				jsonNameArray.remove(jsonNameArray[0]);
			var finalJsonName = jsonNameArray.join("/").split('.json')[0];
			curCharacter = finalJsonName;
		}
	}
}