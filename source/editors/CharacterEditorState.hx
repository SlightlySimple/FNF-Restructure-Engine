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
import flxanimate.FlxAnimate;

import lime.app.Application;

import funkui.TabMenu;
import funkui.Checkbox;
import funkui.TextButton;
import funkui.InputText;
import funkui.Stepper;
import funkui.DropdownMenu;
import funkui.Label;

using StringTools;

class CharacterEditorState extends MusicBeatState
{
	public static var newCharacter:Bool = false;
	public static var newCharacterImage:String = "";
	public static var curCharacter:String = "";
	var charPos:Int = 1;
	var charPosOffset:Array<Int> = [0, 0];
	var otherCharPos:Int = 1;

	var myCharacter:FlxSprite;
	var myCharType:String = "sparrow";
	var atlas:FlxAnimate = null;

	var allAnimData:String = "";
	var allAnimPrefixes:Array<String> = [];
	var animGhost:FlxSprite = null;
	var atlasGhost:FlxAnimate = null;
	var otherAnimGhost:Character;
	var stage:Stage = null;
	var myCharacterData:CharacterData;

	var camFollow:FlxObject;
	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var camPosText:FlxText;

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
	var charFacing:DropdownMenu;
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
	var animLoopedFrames:Stepper;
	var animSustainFrame:Stepper;
	var animImportant:Checkbox;
	var animNextDropdown:DropdownMenu;
	var curFrameText:FlxText;

	override public function create()
	{
		camGame = new FlxCamera();
		FlxG.cameras.add(camGame);

		camFollow = new FlxObject();
		camGame.follow(camFollow, LOCKON, 1);

		camHUD = new FlxCamera();
		camHUD.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camHUD, false);

		super.create();

		if (newCharacter)
		{
			myCharacterData =
			{
				asset: newCharacterImage,
				position: [0, 0],
				camPosition: [0, 0],
				scale: [1, 1],
				antialias: true,
				animations: [],
				firstAnimation: "",
				idles: [],
				danceSpeed: 1,
				flip: false,
				facing: "right",
				icon: "",
				gameOverCharacter: "",
				script: ""
			}
		}
		else
			myCharacterData = Character.parseCharacter(curCharacter);

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

		if (newCharacter && myCharType == "sparrow")
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
			myCharacterData.animations.push({name: "idle", prefix: idleIndex, fps: 24, loop: false, loopedFrames: 0, sustainFrame: -1, offsets: [0, 0]});
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

		changeStage(TitleState.defaultVariables.stage, false);

		camFollow.x = myCharacter.getMidpoint().x;
		camFollow.y = myCharacter.getMidpoint().y;

		charAnimList = [];
		for (i in 0...myCharacterData.animations.length)
			charAnimList.push(myCharacterData.animations[i].name);

		if (myCharacterData.firstAnimation != null && myCharacterData.firstAnimation != "")
		{
			if (!charAnimList.contains(myCharacterData.firstAnimation))
				myCharacterData.firstAnimation = charAnimList[0];

			playAnim(myCharacterData.firstAnimation);
			playAnim(myCharacterData.firstAnimation, false, true);

			myCharacter.updateHitbox();
			animGhost.updateHitbox();
		}

		charAnims = new FlxTypedSpriteGroup<FlxText>();
		charAnims.cameras = [camHUD];
		add(charAnims);

		camPosText = new FlxText(10, 10, 0, "", 16);
		camPosText.font = "VCR OSD Mono";
		camPosText.borderColor = FlxColor.BLACK;
		camPosText.borderStyle = OUTLINE;
		camPosText.cameras = [camHUD];
		add(camPosText);



		tabMenu = new IsolatedTabMenu(50, 50, 250, 500);
		tabMenu.cameras = [camHUD];
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

		var createCopyButton:TextButton = new TextButton(10, saveCharacterButton.y + 30, 230, 20, "Create Copy");
		createCopyButton.onClicked = function() {
			if (curCharacter == "" || curCharacter == "*")
				Application.current.window.alert("You can only make a copy of a saved character file.", "Alert");
			else
			{
				var file:FileBrowser = new FileBrowser();
				file.loadCallback = createCopyCallback;
				file.load("png");
			}
		}
		tabGroupGeneral.add(createCopyButton);

		var showAnimGhost:Checkbox = new Checkbox(10, createCopyButton.y + 30, "Animation Ghost");
		showAnimGhost.checked = false;
		showAnimGhost.onClicked = function()
		{
			animGhost.visible = showAnimGhost.checked;
		};
		tabGroupGeneral.add(showAnimGhost);

		charPosStepper = new Stepper(10, showAnimGhost.y + 40, 230, 20, charPos, 1, 0, stage.stageData.characters.length - 1);
		charPosStepper.onChanged = function() {
			charPos = charPosStepper.valueInt;
			charPosOffset = stage.stageData.characters[charPos].position;
			var inFlipPos:Bool = stage.stageData.characters[charPos].flip;
			if (inFlipPos && myCharacterData.facing != "center")
				myCharacter.flipX = !myCharacterData.flip;
			else
				myCharacter.flipX = myCharacterData.flip;
			animGhost.flipX = myCharacter.flipX;
			changeStage(stage.curStage);
		}
		if (myCharacterData.facing == "left")
		{
			for (i in 0...stage.stageData.characters.length)
			{
				if (stage.stageData.characters[i].flip)
				{
					charPosStepper.value = i;
					break;
				}
			}
			charPosStepper.onChanged();
		}
		tabGroupGeneral.add(charPosStepper);
		var charPosLabel:Label = new Label("Preview Position:", charPosStepper);
		tabGroupGeneral.add(charPosLabel);

		var stageList:Array<String> = Paths.listFilesSub("data/stages/", ".json");
		var stageDropdown:DropdownMenu = new DropdownMenu(10, charPosStepper.y + 40, 230, 20, stage.curStage, stageList, true);
		stageDropdown.onChanged = function() {
			changeStage(stageDropdown.value);
			charPosStepper.maxVal = stage.stageData.characters.length - 1;
			if (charPosStepper.value > charPos)
				charPosStepper.value = charPos;

			otherCharPosStepper.maxVal = stage.stageData.characters.length - 1;
			if (otherCharPosStepper.value > otherCharPos)
				otherCharPosStepper.value = otherCharPos;
		}
		tabGroupGeneral.add(stageDropdown);
		var stageLabel:Label = new Label("Preview Stage:", stageDropdown);
		tabGroupGeneral.add(stageLabel);

		var showOtherAnimGhost:Checkbox = new Checkbox(10, stageDropdown.y + 30, "Other Anim. Ghost");
		showOtherAnimGhost.checked = false;
		showOtherAnimGhost.onClicked = function()
		{
			otherAnimGhost.visible = showOtherAnimGhost.checked;
		};
		tabGroupGeneral.add(showOtherAnimGhost);

		otherCharPosStepper = new Stepper(10, showOtherAnimGhost.y + 40, 230, 20, charPos, 1, 0, stage.stageData.characters.length - 1);
		otherCharPosStepper.onChanged = function() {
			otherCharPos = otherCharPosStepper.valueInt;
			var inFlipPos:Bool = stage.stageData.characters[otherCharPos].flip;
			if (inFlipPos != otherAnimGhost.wasFlipped)
				otherAnimGhost.flip();
			changeStage(stage.curStage);
		}
		tabGroupGeneral.add(otherCharPosStepper);
		var otherCharPosLabel:Label = new Label("Preview Position:", otherCharPosStepper);
		tabGroupGeneral.add(otherCharPosLabel);

		var characterList:Array<String> = Paths.listFilesSub("data/characters/", ".json");
		characterList.remove("none");
		var otherCharacterDropdown:DropdownMenu = new DropdownMenu(10, otherCharPosStepper.y + 40, 230, 20, TitleState.defaultVariables.player2, characterList, true);
		otherCharacterDropdown.onChanged = function() {
			otherAnimGhost.changeCharacter(otherCharacterDropdown.value);
			var animList:Array<String> = [];
			for (a in otherAnimGhost.characterData.animations)
				animList.push(a.name);
			otherCharAnimDropdown.valueList = animList;
			otherCharAnimDropdown.value = otherAnimGhost.curAnimName;
		}
		tabGroupGeneral.add(otherCharacterDropdown);
		var otherCharacterLabel:Label = new Label("Character:", otherCharacterDropdown);
		tabGroupGeneral.add(otherCharacterLabel);

		otherCharAnimDropdown = new DropdownMenu(10, otherCharacterDropdown.y + 40, 230, 20, "idle", [], true);
		otherCharAnimDropdown.onChanged = function() {
			otherAnimGhost.playAnim(otherCharAnimDropdown.value, true);
		}
		otherCharacterDropdown.onChanged();
		tabGroupGeneral.add(otherCharAnimDropdown);
		var ootherCharAnimLabel:Label = new Label("Animation:", otherCharAnimDropdown);
		tabGroupGeneral.add(ootherCharAnimLabel);

		var bakeFlippedOffsets:TextButton = new TextButton(10, otherCharAnimDropdown.y + 30, 230, 20, "Bake Flipped Offsets");
		bakeFlippedOffsets.onClicked = function() {
			var prevAnim:Int = curCharAnim;
			playAnim(myCharacterData.firstAnimation, true);
			var baseFrameWidth = myCharacter.frameWidth;
			for (a in myCharacterData.animations)
			{
				playAnim(a.name, true);
				a.offsets[0] = -a.offsets[0];
				a.offsets[0] -= Std.int((baseFrameWidth - myCharacter.frameWidth) * myCharacterData.scale[0]);

				if (a.name.indexOf("singLEFT") > -1)
					a.name = a.name.replace("singLEFT", "singRIGHT");
				else if (a.name.indexOf("singRIGHT") > -1)
					a.name = a.name.replace("singRIGHT", "singLEFT");

			}

			for (a in myCharacterData.animations)		// Re-add the animations because otherwise the name change breaks them
			{
				switch (myCharType)
				{
					case "atlas":
						if (a.indices != null && a.indices.length > 0)
							atlas.anim.addByAnimIndices(a.name, a.indices, a.fps);

					case "tiles":
						if (a.indices != null && a.indices.length > 0)
						{
							myCharacter.animation.add(a.name, a.indices, a.fps, a.loop);
							animGhost.animation.add(a.name, a.indices, a.fps, a.loop);
						}

					default:
						if (a.indices != null && a.indices.length > 0)
						{
							myCharacter.animation.addByIndices(a.name, a.prefix, a.indices, "", a.fps, a.loop);
							animGhost.animation.addByIndices(a.name, a.prefix, a.indices, "", a.fps, a.loop);
						}
						else
						{
							myCharacter.animation.addByPrefix(a.name, a.prefix, a.fps, a.loop);
							animGhost.animation.addByPrefix(a.name, a.prefix, a.fps, a.loop);
						}
				}
			}

			if (myCharacterData.facing == "right")
				myCharacterData.facing = "left";
			else
				myCharacterData.facing = "right";
			charFacing.value = myCharacterData.facing;
			charFacing.onChanged();

			playAnim(myCharacterData.animations[prevAnim].name, true);
			refreshCharAnims(true);
		};
		tabGroupGeneral.add(bakeFlippedOffsets);

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
			var inFlipPos:Bool = stage.stageData.characters[charPos].flip;
			if (inFlipPos && myCharacterData.facing != "center")
				myCharacter.flipX = !myCharacterData.flip;
			else
				myCharacter.flipX = myCharacterData.flip;
			animGhost.flipX = myCharacter.flipX;
		};
		tabGroupProperties.add(charFlip);

		var tileCount:Array<Int> = [1, 1];
		if (myCharType == "tiles")
			tileCount = myCharacterData.tileCount;
		var charTileX:Stepper = new Stepper(10, charAntialias.y + 40, 115, 20, tileCount[0], 1, 1);
		var charTileY:Stepper = new Stepper(charTileX.x + 115, charTileX.y, 115, 20, tileCount[1], 1, 1);
		if (myCharType == "tiles")
		{
			charTileX.onChanged = function() { myCharacterData.tileCount[0] = Std.int(charTileX.value); refreshTileCharacterFrames(); }
			charTileY.onChanged = function() { myCharacterData.tileCount[1] = Std.int(charTileY.value); refreshTileCharacterFrames(); }
			tabGroupProperties.add(charTileX);
			tabGroupProperties.add(charTileY);
			var charTileLabel:Label = new Label("Tile Count:", charTileX);
			tabGroupProperties.add(charTileLabel);
		}

		var charDanceSpeed:Stepper = new Stepper(10, (myCharType == "tiles" ? charTileX.y + 40 : charAntialias.y + 40), 115, 20, myCharacterData.danceSpeed, 0.25, 0, 9999, 2);
		charDanceSpeed.onChanged = function() { myCharacterData.danceSpeed = charDanceSpeed.value; }
		tabGroupProperties.add(charDanceSpeed);
		var charDanceSpeedLabel:Label = new Label("Dance Speed:", charDanceSpeed);
		tabGroupProperties.add(charDanceSpeedLabel);

		charFacing = new DropdownMenu(125, charDanceSpeed.y, 115, 20, "right", ["right", "left", "center"]);
		charFacing.value = myCharacterData.facing;
		charFacing.onChanged = function() {
			myCharacterData.facing = charFacing.value;
			if (myCharacterData.facing == "left")
			{
				for (i in 0...stage.stageData.characters.length)
				{
					if (stage.stageData.characters[i].flip)
					{
						charPosStepper.value = i;
						break;
					}
				}
			}
			else
			{
				for (i in 0...stage.stageData.characters.length)
				{
					if (!stage.stageData.characters[i].flip)
					{
						charPosStepper.value = i;
						break;
					}
				}
			}
			charPosStepper.onChanged();
		};
		tabGroupProperties.add(charFacing);
		var charFacingLabel:Label = new Label("Facing:", charFacing);
		tabGroupProperties.add(charFacingLabel);

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
				if (myCharType != "atlas" && animGhost.animation.curAnim.name == myCharacterData.animations[curCharAnim].name)
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
				if (myCharType != "atlas" && animGhost.animation.curAnim.name == myCharacterData.animations[curCharAnim].name)
					playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			}
		};
		tabGroupProperties.add(charScaleY);
		var charScaleLabel:Label = new Label("Scale:", charScaleX);
		tabGroupProperties.add(charScaleLabel);

		camPosX = new Stepper(10, charScaleX.y + 40, 115, 20, myCharacterData.camPosition[0], 10);
		camPosX.onChanged = function() {myCharacterData.camPosition[0] = camPosX.valueInt;};
		tabGroupProperties.add(camPosX);
		camPosY = new Stepper(camPosX.x + 115, camPosX.y, 115, 20, myCharacterData.camPosition[1], 10);
		camPosY.onChanged = function() {myCharacterData.camPosition[1] = camPosY.valueInt;};
		tabGroupProperties.add(camPosY);
		var camPosLabel:Label = new Label("Camera Position:", camPosX);
		tabGroupProperties.add(camPosLabel);

		var camTestButton:TextButton = new TextButton(10, camPosX.y + 40, 115, 20, "Test");
		camTestButton.onClicked = function() {
			if (myCharacter.flipX == myCharacterData.flip)
			{
				camFollow.x = myCharacter.getMidpoint().x + myCharacterData.camPosition[0];
				camFollow.y = myCharacter.getMidpoint().y + myCharacterData.camPosition[1];
			}
			else
			{
				camFollow.x = myCharacter.getMidpoint().x - myCharacterData.camPosition[0];
				camFollow.y = myCharacter.getMidpoint().y + myCharacterData.camPosition[1];
			}
		};
		tabGroupProperties.add(camTestButton);

		var camSetButton:TextButton = new TextButton(camTestButton.x + 115, camTestButton.y, 115, 20, "Set");
		camSetButton.onClicked = function() {
			if (myCharacter.flipX == myCharacterData.flip)
				myCharacterData.camPosition = [Std.int(camFollow.x - myCharacter.getMidpoint().x), Std.int(camFollow.y - myCharacter.getMidpoint().y)];
			else
				myCharacterData.camPosition = [Std.int(camFollow.x - myCharacter.getMidpoint().x) * -1, Std.int(camFollow.y - myCharacter.getMidpoint().y)];

			myCharacterData.camPosition[0] = Std.int(Math.round(myCharacterData.camPosition[0] / 5) * 5);
			myCharacterData.camPosition[1] = Std.int(Math.round(myCharacterData.camPosition[1] / 5) * 5);
			camPosX.value = myCharacterData.camPosition[0];
			camPosY.value = myCharacterData.camPosition[1];
		};
		tabGroupProperties.add(camSetButton);

		var camTestLabel:Label = new Label("In-Game:", camTestButton);
		tabGroupProperties.add(camTestLabel);

		var camTestDeadButton:TextButton = new TextButton(10, camSetButton.y + 40, 115, 20, "Test");
		camTestDeadButton.onClicked = function() {
			camFollow.x = myCharacter.getGraphicMidpoint().x + myCharacterData.camPosition[0];
			camFollow.y = myCharacter.getGraphicMidpoint().y + myCharacterData.camPosition[1];
		};
		tabGroupProperties.add(camTestDeadButton);

		var camSetDeadButton:TextButton = new TextButton(camTestDeadButton.x + 115, camTestDeadButton.y, 115, 20, "Set");
		camSetDeadButton.onClicked = function() {
			myCharacterData.camPosition = [Std.int(camFollow.x - myCharacter.getGraphicMidpoint().x), Std.int(camFollow.y - myCharacter.getGraphicMidpoint().y)];

			camPosX.value = myCharacterData.camPosition[0];
			camPosY.value = myCharacterData.camPosition[1];
		};
		tabGroupProperties.add(camSetDeadButton);

		var camTestDeadLabel:Label = new Label("Game Over:", camTestDeadButton);
		tabGroupProperties.add(camTestDeadLabel);

		var iconList:Array<String> = HealthIcon.listIcons();
		if (curCharacter.indexOf("/") > -1)
		{
			for (i in HealthIcon.listIcons(curCharacter.substring(0, curCharacter.indexOf("/")+1)))
				iconList.push(curCharacter.substring(0, curCharacter.indexOf("/")+1) + i);
		}
		iconList.unshift("");
		var iconDropdown:DropdownMenu = new DropdownMenu(10, camTestDeadButton.y + 40, 230, 20, myCharacterData.icon, iconList, true);
		iconDropdown.onChanged = function() {
			myCharacterData.icon = iconDropdown.value;
		};
		tabGroupProperties.add(iconDropdown);
		var iconLabel:Label = new Label("Health Icon (Optional):", iconDropdown);
		tabGroupProperties.add(iconLabel);

		var idlesInput:InputText = new InputText(10, iconDropdown.y + 40, 115);
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

		var characterList:Array<String> = Paths.listFilesSub("data/characters/", ".json");
		characterList.unshift("");
		var gameOverCharDropdown:DropdownMenu = new DropdownMenu(10, autoAnimButton.y + 40, 230, 20, myCharacterData.gameOverCharacter, characterList, true);
		gameOverCharDropdown.onChanged = function() {
			myCharacterData.gameOverCharacter = gameOverCharDropdown.value;
		};
		tabGroupProperties.add(gameOverCharDropdown);
		var gameOverCharLabel:Label = new Label("Game Over Character (Optional):", gameOverCharDropdown);
		tabGroupProperties.add(gameOverCharLabel);

		var scriptList:Array<String> = [""];
		for (s in Paths.listFilesSub("data/characters/", ".hscript"))
			scriptList.push("characters/" + s);
		for (s in Paths.listFilesSub("data/scripts/", ".hscript"))
			scriptList.push("scripts/" + s);

		if (myCharacterData.script == "characters/" + curCharacter)
			myCharacterData.script = "";
		var scriptDropdown:DropdownMenu = new DropdownMenu(10, gameOverCharDropdown.y + 40, 230, 20, myCharacterData.script, scriptList, true);
		scriptDropdown.onChanged = function() {
			myCharacterData.script = scriptDropdown.value;
		};
		tabGroupProperties.add(scriptDropdown);
		var scriptLabel:Label = new Label("Script (Optional):", scriptDropdown);
		tabGroupProperties.add(scriptLabel);

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

		if (myCharType == "sparrow")
		{
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
		}
		else
		{
			animIndices = new InputText(10, animNameDropdown.y + 40);
			tabGroupAnims.add(animIndices);
			var animIndicesLabel:Label = new Label("Indices:", animIndices);
			tabGroupAnims.add(animIndicesLabel);

			var indRangeStart:Stepper = new Stepper(10, animIndices.y + 40, 115, 20, 0, 1, 0);
			tabGroupAnims.add(indRangeStart);
			var indRangeStartLabel:Label = new Label("Start:", indRangeStart);
			tabGroupAnims.add(indRangeStartLabel);

			var indRangeLength:Stepper = new Stepper(indRangeStart.x + 115, indRangeStart.y, 115, 20, 1, 1, 1);
			tabGroupAnims.add(indRangeLength);
			var indRangeLengthLabel:Label = new Label("Length:", indRangeLength);
			tabGroupAnims.add(indRangeLengthLabel);

			var rangeIndices:TextButton = new TextButton(10, indRangeStart.y + 30, 230, 20, "Generate Range");
			rangeIndices.onClicked = function()
			{
				var len:Int = Std.int(indRangeStart.value+indRangeLength.value);
				animIndices.text = "";
				for (i in Std.int(indRangeStart.value)...len)
				{
					animIndices.text += Std.string(i);
					if (i < len - 1)
						animIndices.text += ",";
				}
			};
			tabGroupAnims.add(rangeIndices);
		}

		animLooped = new Checkbox(10, (myCharType == "sparrow" ? animIndices.y + 70 : animIndices.y + 110), "Loop");
		animLooped.checked = false;
		tabGroupAnims.add(animLooped);

		animFPS = new Stepper(animLooped.x + 115, animLooped.y, 115, 20, 24, 1, 0);
		tabGroupAnims.add(animFPS);
		var animFPSLabel:Label = new Label("FPS:", animFPS);
		tabGroupAnims.add(animFPSLabel);

		animLoopedFrames = new Stepper(10, animLooped.y + 40, 115, 20, 0, 1, 0);
		tabGroupAnims.add(animLoopedFrames);
		var animLoopedFramesLabel:Label = new Label("Trailing frames:", animLoopedFrames);
		tabGroupAnims.add(animLoopedFramesLabel);

		animSustainFrame = new Stepper(animLoopedFrames.x + 115, animLoopedFrames.y, 115, 20, -1, 1, -1);
		tabGroupAnims.add(animSustainFrame);
		var animSustainFrameLabel:Label = new Label("Held frame:", animSustainFrame);
		tabGroupAnims.add(animSustainFrameLabel);

		animImportant = new Checkbox(10, animLoopedFrames.y + 30, "Prevents Idle");
		animImportant.checked = false;
		tabGroupAnims.add(animImportant);

		var nextAnimList:Array<String> = [""];
		if (charAnimList.length > 0)
			nextAnimList = nextAnimList.concat(charAnimList);
		animNextDropdown = new DropdownMenu(10, animImportant.y + 40, 230, 20, nextAnimList[0], nextAnimList, true);
		tabGroupAnims.add(animNextDropdown);
		var animNextLabel:Label = new Label("Next Animation (Optional):", animNextDropdown);
		tabGroupAnims.add(animNextLabel);

		var addAnimButton:TextButton = new TextButton(10, animNextDropdown.y + 30, 230, 20, "Add/Update Animation");
		addAnimButton.onClicked = function()
		{
			var cause:Int = -1;
			if (animName.text.trim() == "")
				cause = 0;
			if (myCharType == "sparrow" && allAnimData.indexOf(animPrefix.text) == -1)
				cause = 1;
			if (myCharType == "atlas" && animIndices.text == "")
				cause = 2;
			if (myCharType == "tiles" && animIndices.text == "")
				cause = 3;

			var causes:Array<String> = ["The animation name cannot be blank.", "The spritesheet does not contain an animation with that prefix.", "All animations for texture atlas character must have indices.", "All animations for tiles character must have indices."];

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
					loopedFrames: animLoopedFrames.valueInt,
					sustainFrame: animSustainFrame.valueInt,
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

				if (animImportant.checked)
					newAnim.important = animImportant.checked;

				if (animNextDropdown.value != "")
					newAnim.next = animNextDropdown.value;

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

				switch (myCharType)
				{
					case "atlas":
						atlas.anim.addByAnimIndices(newAnim.name, newAnim.indices, newAnim.fps);

					case "tiles":
						myCharacter.animation.add(newAnim.name, newAnim.indices, newAnim.fps, newAnim.loop);
						animGhost.animation.add(newAnim.name, newAnim.indices, newAnim.fps, newAnim.loop);

					default:
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
				var nextAnimList:Array<String> = [""];
				if (charAnimList.length > 0)
					nextAnimList = nextAnimList.concat(charAnimList);
				animNextDropdown.valueList = nextAnimList;
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
			@:privateAccess
			if (myCharType == "atlas")
			{
				if (atlas.isPlaying)
					atlas.pauseAnim();
				else
					atlas.playAnim(atlas.anim.name);
			}
			else if (myCharacter.animation.curAnim != null)
				myCharacter.animation.curAnim.paused = !myCharacter.animation.curAnim.paused;
		};
		tabGroupAnims.add(toggleAnimButton);

		var prevFrame:TextButton = new TextButton(10, toggleAnimButton.y + 30, 115, 20, "Prev");
		prevFrame.onClicked = function()
		{
			if (myCharType == "atlas")
			{
				if (atlas.anim.curFrame > 0)
					atlas.anim.curFrame--;
			}
			else if (myCharacter.animation.curAnim != null && myCharacter.animation.curAnim.curFrame > 0)
				myCharacter.animation.curAnim.curFrame--;
		};
		tabGroupAnims.add(prevFrame);

		var nextFrame:TextButton = new TextButton(prevFrame.x + 115, prevFrame.y, 115, 20, "Next");
		nextFrame.onClicked = function()
		{
			@:privateAccess
			if (myCharType == "atlas")
			{
				if (atlas.anim.curFrame < atlas.anim.frameLength - 1)
					atlas.anim.curFrame++;
			}
			else if (myCharacter.animation.curAnim != null && myCharacter.animation.curAnim.curFrame < myCharacter.animation.curAnim.numFrames - 1)
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
			myCharacterData.camPosition[0] += offX;
			myCharacterData.camPosition[1] += offY;
			camPosX.value = myCharacterData.camPosition[0];
			camPosY.value = myCharacterData.camPosition[1];

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

		if (myCharType == "atlas")
		{
			atlas.x = myCharacter.x - myCharacter.offset.x;
			atlas.y = myCharacter.y - myCharacter.offset.y;
			atlas.antialiasing = myCharacter.antialiasing;
			atlas.flipX = myCharacter.flipX;
			atlas.flipY = myCharacter.flipY;
			atlas.scale.x = myCharacter.scale.x;
			atlas.scale.y = myCharacter.scale.y;
		}

		super.update(elapsed);

		if (myCharacterData.animations.length > 0)
		{
			var curAnimFinished:Bool;
			@:privateAccess
			if (myCharType == "atlas")
				curAnimFinished = (atlas.anim.curFrame >= atlas.anim.frameLength - 1);
			else
				curAnimFinished = myCharacter.animation.curAnim.finished;
			if (curAnimFinished && myCharacterData.animations[curCharAnim].loopedFrames > 0)
			{
				playAnim(myCharacterData.animations[curCharAnim].name, true);
				@:privateAccess
				if (myCharType == "atlas")
					atlas.anim.curFrame = atlas.anim.frameLength - myCharacterData.animations[curCharAnim].loopedFrames;
				else
					myCharacter.animation.curAnim.curFrame = myCharacter.animation.curAnim.numFrames - myCharacterData.animations[curCharAnim].loopedFrames;
			}
		}

		var camPosString:String = "Camera X: "+Std.string(camFollow.x)+"\nCamera Y: "+Std.string(camFollow.y)+"\nCamera Z: "+Std.string(camGame.zoom);
		if (camPosText.text != camPosString)
		{
			camPosText.text = camPosString;
			camPosText.y = FlxG.height - camPosText.height - 10;
		}

		if (movingCamera)
		{
			camFollow.x += FlxG.mouse.drag.x / camGame.zoom;
			camFollow.y += FlxG.mouse.drag.y / camGame.zoom;

			if (FlxG.mouse.justReleasedRight)
				movingCamera = false;
		}
		else
		{
			if (FlxG.mouse.justPressedRight)
				movingCamera = true;
		}

		if (FlxG.mouse.wheel != 0 && !DropdownMenu.isOneActive)
			camGame.zoom = Math.max(0.05, camGame.zoom + (FlxG.mouse.wheel * 0.05));

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
			dragOffset[0] += FlxG.mouse.drag.x / camGame.zoom;
			dragOffset[1] += FlxG.mouse.drag.y / camGame.zoom;
			if (movingAnimOffset)
			{
				myCharacterData.animations[curCharAnim].offsets = [Std.int(dragStart[0] - dragOffset[0]), Std.int(dragStart[1] - dragOffset[1])];
				playAnim(myCharacterData.animations[curCharAnim].name, true);
				if (myCharType != "atlas" && animGhost.animation.curAnim.name == myCharacterData.animations[curCharAnim].name)
					playAnim(myCharacterData.animations[curCharAnim].name, true, true);
				updateCharAnim(curCharAnim);
			}
			else
			{
				myCharacterData.position = [Std.int(dragStart[0] + dragOffset[0]), Std.int(dragStart[1] + dragOffset[1])];
				myCharacter.x = myCharacterData.position[0] + charPosOffset[0];
				myCharacter.y = myCharacterData.position[1] + charPosOffset[1];
				animGhost.setPosition(myCharacter.x, myCharacter.y);
			}

			if (FlxG.mouse.justReleased)
				movingCharacter = false;
		}
		else
		{
			if (FlxG.mouse.justPressed)
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
							animLoopedFrames.value = animData.loopedFrames;
							animSustainFrame.value = animData.sustainFrame;
							if (animData.important == null)
								animImportant.checked = false;
							else
								animImportant.checked = animData.important;
							if (animData.next == null)
								animNextDropdown.value = "";
							else
								animNextDropdown.value = animData.next;
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
			else if (FlxG.mouse.justPressedRight)
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
		if (myCharType == "atlas")
		{
			if (atlas.anim != null)
				frameText += Std.string(atlas.anim.curFrame);
			else
				frameText += "0";
		}
		else
		{
			if (myCharacter.animation.curAnim != null)
				frameText += Std.string(myCharacter.animation.curAnim.curFrame);
			else
				frameText += "0";
		}
		if (curFrameText.text != frameText)
			curFrameText.text = frameText;

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new EditorMenuState());
	}

	function reloadAsset()
	{
		var asset:String = myCharacterData.asset;

		if (!Paths.imageExists(asset))
		{
			Application.current.window.alert("The image asset does not exist: " + Paths.imagePath(asset), "Alert");
			FlxG.switchState(new EditorMenuState());
			return;
		}

		allAnimData = "";
		allAnimPrefixes = [];
		if (Paths.exists("images/" + asset + ".json"))
		{
			myCharType = "atlas";
			myCharacter.makeGraphic(1, 1, FlxColor.TRANSPARENT);

			var assetArray = asset.replace("\\","/").split("/");
			assetArray.pop();
			atlas = new FlxAnimate(0, 0, Paths.atlas(assetArray.join("/")));
		}
		else if (Paths.sparrowExists(asset))
		{
			myCharType = "sparrow";
			myCharacter.frames = Paths.sparrow(asset);
			if (Paths.exists("images/" + asset + ".txt"))
				allAnimData = Paths.raw("images/" + asset + ".txt");
			else
				allAnimData = Paths.raw("images/" + asset + ".xml");
			allAnimPrefixes = Paths.sparrowAnimations(asset);
			if (animPrefixDropdown != null)
				animPrefixDropdown.valueList = allAnimPrefixes;
		}
		else
		{
			myCharType = "tiles";

			if (myCharacterData.tileCount == null || myCharacterData.tileCount.length < 2)
				myCharacterData.tileCount = [1, 1];

			refreshTileCharacterFrames();
		}
	}

	function reloadAnimations()
	{
		if (myCharacterData.animations.length > 0)
		{
			switch (myCharType)
			{
				case "atlas":
					var poppers:Array<CharacterAnimation> = [];
					for (anim in myCharacterData.animations)
					{
						if (anim.indices == null || anim.indices.length <= 0)
							poppers.push(anim);
						else
							atlas.anim.addByAnimIndices(anim.name, anim.indices, anim.fps);
					}

					for (p in poppers)
						myCharacterData.animations.remove(p);

				case "tiles":
					var poppers:Array<CharacterAnimation> = [];
					for (anim in myCharacterData.animations)
					{
						if (anim.indices == null || anim.indices.length <= 0)
							poppers.push(anim);
						else
						{
							myCharacter.animation.add(anim.name, anim.indices, anim.fps, anim.loop);
							animGhost.animation.add(anim.name, anim.indices, anim.fps, anim.loop);
						}
					}

					for (p in poppers)
						myCharacterData.animations.remove(p);

				default:
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
	}

	function refreshTileCharacterFrames()
	{
		var asset:String = myCharacterData.asset;

		myCharacter.frames = Paths.tiles(asset, myCharacterData.tileCount[0], myCharacterData.tileCount[1]);
		if (animGhost != null)
		{
			animGhost.frames = myCharacter.frames;

			if (myCharacterData.animations.length > 0)
			{
				for (a in myCharacterData.animations)
				{
					if (a.indices != null && a.indices.length > 0)
					{
						myCharacter.animation.add(a.name, a.indices, a.fps, a.loop);
						animGhost.animation.add(a.name, a.indices, a.fps, a.loop);
					}
				}
			}
		}
	}

	function resetCharPosition()
	{
		myCharacter.x = myCharacterData.position[0] + charPosOffset[0];
		myCharacter.y = myCharacterData.position[1] + charPosOffset[1];
		animGhost.x = myCharacter.x;
		animGhost.y = myCharacter.y;
	}

	function doMovement(xDir:Int, yDir:Int)
	{
		if (FlxG.keys.pressed.SHIFT && myCharacterData.animations.length > 0)
		{
			myCharacterData.animations[curCharAnim].offsets[0] -= xDir;
			myCharacterData.animations[curCharAnim].offsets[1] -= yDir;
			playAnim(myCharacterData.animations[curCharAnim].name, true);
			if (myCharType != "atlas" && animGhost.animation.curAnim.name == myCharacterData.animations[curCharAnim].name)
				playAnim(myCharacterData.animations[curCharAnim].name, true, true);
			updateCharAnim(curCharAnim);
		}
		else
		{
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
				if (myCharType == "atlas")
				{
					curCharAnim = charAnim;
					atlas.playAnim(animName, true, animData.loop);
					myCharacter.offset.x = animData.offsets[0];
					myCharacter.offset.y = animData.offsets[1];
				}
				else if (ghost)
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
			var nextAnimList:Array<String> = [""];
			if (charAnimList.length > 0)
				nextAnimList = nextAnimList.concat(charAnimList);
			animNextDropdown.valueList = nextAnimList;
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
		txt.y = 20 + ((anim - listOffset) * 25);
		txt.text = myCharacterData.animations[anim].name + " " + Std.string(myCharacterData.animations[anim].offsets);
		if (anim == curCharAnim)
			txt.text = "> " + txt.text;

		if (tabMenu.x > FlxG.width / 2)
			txt.x = 20;
		else
			txt.x = Std.int(FlxG.width - 20 - txt.width);
	}

	function createCopyCallback(fullPath:String)
	{
		var imageNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (imageNameArray.contains("images"))
		{
			while (imageNameArray[0] != "images")
				imageNameArray.remove(imageNameArray[0]);
			imageNameArray.remove(imageNameArray[0]);

			var finalImageName = imageNameArray.join('/').split('.png')[0];

			var data:String = Json.stringify({parent:curCharacter,asset:finalImageName}, null, "\t");
			if (Options.options.compactJsons)
				data = Json.stringify({parent:curCharacter,asset:finalImageName});

			if ((data != null) && (data.length > 0))
			{
				var file:FileBrowser = new FileBrowser();
				file.save(curCharacter + "-copy.json", data.trim());
			}
		}
	}

	function changeStage(newStage:String, ?replacing = true)
	{
		if (replacing)
		{
			for (piece in stage.stageData.pieces)
				remove(stage.pieces.get(piece.id));
			remove(myCharacter);
			remove(animGhost);
			remove(otherAnimGhost);
			if (myCharType == "atlas")
				remove(atlas);
		}

		stage = new Stage(newStage);
		if (charPos >= stage.stageData.characters.length)
			charPos = stage.stageData.characters.length - 1;
		if (otherCharPos >= stage.stageData.characters.length)
			otherCharPos = stage.stageData.characters.length - 1;

		for (piece in stage.stageData.pieces)
		{
			if (piece.layer <= stage.stageData.characters[charPos].layer)
				add(stage.pieces.get(piece.id));
		}

		otherAnimGhost.repositionCharacter(stage.stageData.characters[otherCharPos].position[0], stage.stageData.characters[otherCharPos].position[1]);
		add(otherAnimGhost);

		charPosOffset = stage.stageData.characters[charPos].position;
		add(animGhost);
		add(myCharacter);
		if (myCharType == "atlas")
			add(atlas);

		for (piece in stage.stageData.pieces)
		{
			if (piece.layer > stage.stageData.characters[charPos].layer)
				add(stage.pieces.get(piece.id));
		}

		resetCharPosition();
	}



	function saveCharacter()
	{
		var saveData:CharacterData = Reflect.copy(myCharacterData);
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

			if (a.loopedFrames <= 0)
				Reflect.deleteField(a, "loopedFrames");

			if (a.sustainFrame < 0)
				Reflect.deleteField(a, "sustainFrame");
		}

		if (saveData.icon.trim() == "")
			Reflect.deleteField(saveData, "icon");

		if (saveData.gameOverCharacter == "")
			Reflect.deleteField(saveData, "gameOverCharacter");

		if (saveData.script == "" || saveData.script == "characters/" + curCharacter)
			Reflect.deleteField(saveData, "script");

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
		file.loadCallback = EditorMenuState.loadCharacterCallback;
		file.load();
	}

	function changeCurCharacter(path:String)
	{
		var jsonNameArray:Array<String> = path.replace('\\','/').split('/');
		if (jsonNameArray.contains("characters"))
		{
			while (jsonNameArray[0] != "characters")
				jsonNameArray.remove(jsonNameArray[0]);
			var finalJsonName = jsonNameArray.join("/").split('.json')[0];
			curCharacter = finalJsonName;
		}
	}
}