package editors;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.frames.FlxFramesCollection;
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
import haxe.xml.Access;
import sys.FileSystem;
import sys.io.File;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import menus.EditorMenuState;
import flxanimate.FlxAnimate;

import newui.UIControl;
import newui.TopMenu;
import newui.Button;
import newui.Checkbox;
import newui.ColorPickSubstate;
import newui.Draggable;
import newui.InputText;
import newui.ObjectMenu;
import newui.PopupWindow;
import newui.Stepper;
import newui.DropdownMenu;

using StringTools;

class CharacterEditorState extends BaseEditorState
{
	public static var newCharacterImage:String = "";
	var charPos:Int = 1;
	var charPosOffset:Array<Int> = [0, 0];
	var charCameraOffset:Array<Int> = [0, 0];
	var otherCharPos:Int = 1;

	var character:FlxSprite;
	var characterGhost:FlxSprite = null;
	var assets:Map<String, FlxFramesCollection> = new Map<String, FlxFramesCollection>();
	var currentAsset:String = "";
	var myCharType:String = "sparrow";
	var atlas:FlxAnimate = null;
	var baseOffsets:Array<Float> = [0, 0];
	var baseFrameSize:Array<Int> = [0, 0];
	var posLocked:Bool = false;

	var allAnimData:String = "";
	var allAnimPrefixes:Array<String> = [];
	var otherCharacterGhost:Character;
	var stage:Stage = null;
	var stageID:String = "";
	var bg:FlxSprite;
	var platform:FlxSprite;

	var characterData:CharacterData;
	var dataLog:Array<CharacterData> = [];

	var camFollow:FlxObject;
	var mousePos:FlxPoint;

	var	movingCamera:Bool = false;
	var	movingCharacter:Bool = false;
	var	movingAnimOffset:Bool = false;
	var dragStart:Array<Int> = [0, 0];
	var dragOffset:Array<Float> = [0, 0];

	var displayHealthbarBG:FlxSprite;
	var displayHealthbar:FlxSprite;
	var displayIcon:HealthIcon;

	var charAnimList:Array<String>;
	var charAnims:ObjectMenu;
	var curCharAnim:Int = -1;

	var cameraBox:Draggable;
	var camPosText:FlxText;

	var showAnimGhost:Checkbox;
	var charPosDropdown:DropdownMenu = null;
	var charPosStepper:Stepper;
	var showOtherAnimGhost:Checkbox;
	var otherCharPosStepper:Stepper;
	var otherCharacterDropdown:DropdownMenu;
	var otherCharAnimDropdown:DropdownMenu;

	var firstAnimDropdown:DropdownMenu;

	var animName:InputText;
	var animAsset:InputText;
	var animPrefix:InputText;
	var animPrefixDropdown:DropdownMenu = null;
	var animIndices:InputText;
	var animOffsetX:Stepper;
	var animOffsetY:Stepper;
	var animLooped:Checkbox;
	var animFPS:Stepper;
	var animLoopedFrames:Stepper;
	var animSustainFrame:Stepper;
	var animImportant:Checkbox;
	var animNextDropdown:DropdownMenu;
	var curFrameText:FlxText;

	override public function create()
	{
		Character.parsedCharacters = new Map<String, CharacterData>();
		Character.parsedCharacterTypes = new Map<String, String>();

		mousePos = FlxPoint.get();

		super.create();
		filenameNew = "New Character";

		camFollow = new FlxObject();
		camGame.follow(camFollow, LOCKON, 1);
		camGame.zoom = 0.7;

		if (isNew)
		{
			characterData =
			{
				fixes: 1,
				asset: newCharacterImage,
				position: [0, 0],
				camPosition: [0, 0],
				camPositionGameOver: [0, 0],
				scale: [1, 1],
				antialias: true,
				offsetAlign: ["bottom", "center"],
				animations: [],
				firstAnimation: "",
				idles: [],
				danceSpeed: 1,
				flip: false,
				facing: "right",
				icon: "",
				healthbarColor: [255, 255, 255],
				gameOverCharacter: "",
				gameOverSFX: "",
				deathCounterText: "",
				script: ""
			}
		}
		else
			characterData = Character.parseCharacter(id);

		bg = new FlxSprite(0, 0, Paths.image("ui/editors/characterEditorBG"));
		bg.scale.set(1 / camGame.zoom, 1 / camGame.zoom);
		bg.scrollFactor.set();
		add(bg);

		platform = new FlxSprite(-75, 625, Paths.image("ui/editors/characterEditorPlatform"));
		add(platform);

		character = new FlxSprite();
		var hasAsset:Bool = reloadAsset();

		character.antialiasing = characterData.antialias;

		if (characterData.scale != null && characterData.scale.length == 2)
		{
			character.scale.x = characterData.scale[0];
			character.scale.y = characterData.scale[1];
		}
		else
			characterData.scale = [1, 1];
		character.updateHitbox();
		baseOffsets = [character.offset.x, character.offset.y];
		if (characterData.fixes == null || characterData.fixes < 1)
		{
			characterData.position[0] += Std.int(baseOffsets[0]);
			characterData.position[1] += Std.int(baseOffsets[1]);
			character.x += baseOffsets[0];
			character.y += baseOffsets[1];
			if (characterData.facing == "left")
				characterData.camPosition[0] += Std.int(baseOffsets[0]);
			else
				characterData.camPosition[0] -= Std.int(baseOffsets[0]);
			characterData.camPosition[1] -= Std.int(baseOffsets[1]);
			characterData.fixes = 1;
		}

		characterGhost = new FlxSprite(character.x, character.y);
		characterGhost.alpha = 0.5;
		characterGhost.visible = false;
		characterGhost.frames = character.frames;
		characterGhost.antialiasing = character.antialiasing;

		resetCharFlip();

		if (isNew && myCharType == "sparrow")
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
			characterData.animations.push({name: "idle", prefix: idleIndex, fps: 24, loop: false, loopedFrames: 0, sustainFrame: -1, offsets: [0, 0]});
			characterData.firstAnimation = "idle";
			characterData.idles = ["idle"];
		}
		if (hasAsset)
			reloadAnimations();

		characterGhost.scale.x = character.scale.x;
		characterGhost.scale.y = character.scale.y;
		characterGhost.updateHitbox();

		otherCharacterGhost = new Character(0, 0, TitleState.defaultVariables.player2);
		otherCharacterGhost.alpha = 0.5;
		otherCharacterGhost.visible = false;

		changeStage();



		displayHealthbarBG = new FlxSprite(0, 645).makeGraphic(300, 20, FlxColor.BLACK);
		displayHealthbarBG.cameras = [camHUD];
		displayHealthbarBG.screenCenter(X);
		add(displayHealthbarBG);

		displayHealthbar = new FlxSprite(displayHealthbarBG.x + 4, displayHealthbarBG.y + 4).makeGraphic(292, 12, FlxColor.WHITE);
		displayHealthbar.color = FlxColor.fromRGB(characterData.healthbarColor[0], characterData.healthbarColor[1], characterData.healthbarColor[2]);
		displayHealthbar.cameras = [camHUD];
		add(displayHealthbar);

		displayIcon = new HealthIcon();
		displayIcon.cameras = [camHUD];
		add(displayIcon);



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
				if (myCharType == "sparrow")
				{
					animPrefix.text = animData.prefix;
					animAsset.text = animData.asset;
				}
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

			character.updateHitbox();
			characterGhost.updateHitbox();
			baseOffsets = [character.offset.x, character.offset.y];

			playAnim(characterData.firstAnimation);
			playAnim(characterData.firstAnimation, false, true);
		}
		updateBaseFrameWidth();



		cameraBox = new Draggable(310, 615, "cameraBox");
		cameraBox.cameras = [camHUD];
		add(cameraBox);

		var hbox:HBox = new HBox(5, 5);
		hbox.spacing = 5;

		var camButton:Button = new Button(0, 0, "buttonCamera", function() {
			if (character.flipX == characterData.flip)
				characterData.camPosition = [Std.int(camFollow.x - character.getMidpoint().x), Std.int(camFollow.y - character.getMidpoint().y)];
			else
				characterData.camPosition = [Std.int(camFollow.x - character.getMidpoint().x) * -1, Std.int(camFollow.y - character.getMidpoint().y)];

			characterData.camPosition[0] = Std.int(Math.round(characterData.camPosition[0] / 5) * 5);
			characterData.camPosition[1] = Std.int(Math.round(characterData.camPosition[1] / 5) * 5);
		}, function() {
			if (character.flipX == characterData.flip)
			{
				camFollow.x = Math.round(character.getMidpoint().x + characterData.camPosition[0] + charCameraOffset[0]);
				camFollow.y = Math.round(character.getMidpoint().y + characterData.camPosition[1] + charCameraOffset[1]);
			}
			else
			{
				camFollow.x = Math.round(character.getMidpoint().x - characterData.camPosition[0] + charCameraOffset[0]);
				camFollow.y = Math.round(character.getMidpoint().y + characterData.camPosition[1] + charCameraOffset[1]);
			}
		});
		camButton.infoText = "Set the character's camera offset based on the camera's current location in the editor. Right click to teleport the camera to the current offset.";
		hbox.add(camButton);

		camPosText = new FlxText(0, 0, 0, "Camera X: 0\nCamera Y: 0\nCamera Z: 0");
		camPosText.setFormat("FNF Dialogue", 20, FlxColor.WHITE, LEFT, OUTLINE, 0xFF254949);
		camPosText.borderSize = 2;
		hbox.add(camPosText);

		cameraBox.add(hbox);



		createUI("CharacterEditor", [function() { return myCharType == "sparrow"; }, function() { return myCharType == "tiles"; }, function() { return myCharType == "atlas"; }]);



		var charTemplateBF:Button = cast element("charTemplateBF");
		charTemplateBF.onClicked = function() { fillTemplate("bf"); }

		var charTemplateGF:Button = cast element("charTemplateGF");
		charTemplateGF.onClicked = function() { fillTemplate("gf"); }

		var charTemplateDad:Button = cast element("charTemplateDad");
		charTemplateDad.onClicked = function() { fillTemplate("dad"); }

		var flipCharacter:Button = cast element("flipCharacter");
		flipCharacter.onClicked = function() {
			if (characterData.facing != "center")
			{
				var prevAnim:Int = curCharAnim;
				playAnim(characterData.firstAnimation, true);
				var baseFrameWidth = character.frameWidth;
				for (a in characterData.animations)
				{
					playAnim(a.name, true);
					a.offsets[0] = -a.offsets[0];
					switch (characterData.offsetAlign[1])
					{
						case "right":
							a.offsets[0] += Std.int((baseFrameWidth - character.frameWidth) * characterData.scale[0]);

						case "left":
							a.offsets[0] -= Std.int((baseFrameWidth - character.frameWidth) * characterData.scale[0]);
					}

					if (a.name.indexOf("singLEFT") > -1)
						a.name = a.name.replace("singLEFT", "singRIGHT");
					else if (a.name.indexOf("singRIGHT") > -1)
						a.name = a.name.replace("singRIGHT", "singLEFT");

				}

				reloadAnimations();

				if (characterData.facing == "right")
					characterData.facing = "left";
				else
					characterData.facing = "right";
				updateFacing();

				playAnim(characterData.animations[prevAnim].name, true);
				refreshCharAnims();
			}
		}



		var stageList:Array<String> = Paths.listFilesSub("data/stages/", ".json");
		stageList.unshift("");
		var stageDropdown:DropdownMenu = cast element("stageDropdown");
		var stageNames:Map<String, String> = Util.getStageNames(stageList);
		for (k in stageNames.keys())
			stageDropdown.valueText[k] = stageNames[k];
		stageDropdown.valueList = stageList;
		stageDropdown.value = stageID;
		stageDropdown.onChanged = function() {
			stageID = stageDropdown.value;
			changeStage();
			if (stageID == "")
			{
				charPosStepper.maxVal = 1;
				otherCharPosStepper.maxVal = 1;
			}
			else
			{
				charPosStepper.maxVal = stage.stageData.characters.length - 1;
				otherCharPosStepper.maxVal = stage.stageData.characters.length - 1;
			}

			if (charPosStepper.value > charPos)
				charPosStepper.value = charPos;

			if (otherCharPosStepper.value > otherCharPos)
				otherCharPosStepper.value = otherCharPos;
		}

		showAnimGhost = cast element("showAnimGhost");
		showAnimGhost.onClicked = function() { characterGhost.visible = showAnimGhost.checked; }

		var ghostAlpha:Stepper = cast element("ghostAlpha");
		ghostAlpha.value = characterGhost.alpha;
		ghostAlpha.onChanged = function() {
			characterGhost.alpha = ghostAlpha.value;
		}

		charPosStepper = cast element("charPosStepper");
		charPosStepper.value = charPos;
		charPosStepper.onChanged = function() {
			charPos = charPosStepper.valueInt;
			resetCharFlip();
			if (stageID != "")
			{
				charPosOffset = stage.stageData.characters[charPos].position;
				if (stage.stageData.characters[charPos].camPosAbsolute)
					charCameraOffset = [0, 0];
				else
					charCameraOffset = stage.stageData.characters[charPos].camPosition;
				changeStage();
			}
		}
		if (characterData.facing == "left")
		{
			charPosStepper.value = 0;
			charPosStepper.onChanged();
		}

		showOtherAnimGhost = cast element("showOtherAnimGhost");
		showOtherAnimGhost.onClicked = function()
		{
			otherCharacterGhost.visible = showOtherAnimGhost.checked;
		};

		var otherCharAlpha:Stepper = cast element("otherCharAlpha");
		otherCharAlpha.value = otherCharacterGhost.alpha;
		otherCharAlpha.onChanged = function() {
			otherCharacterGhost.alpha = otherCharAlpha.value;
		}

		otherCharPosStepper = cast element("otherCharPosStepper");
		otherCharPosStepper.value = charPos;
		otherCharPosStepper.onChanged = function() {
			otherCharPos = otherCharPosStepper.valueInt;
			if (stageID == "")
			{
				var inFlipPos:Bool = (otherCharPos == 0);
				if (inFlipPos != otherCharacterGhost.wasFlipped)
					otherCharacterGhost.flip();
			}
			else
			{
				var inFlipPos:Bool = stage.stageData.characters[otherCharPos].flip;
				if (inFlipPos != otherCharacterGhost.wasFlipped)
					otherCharacterGhost.flip();
				changeStage();
			}
		}
		otherCharPosStepper.onChanged();

		var characterList:Array<String> = Paths.listFilesSub("data/characters/", ".json");
		characterList.remove("none");
		otherCharacterDropdown = cast element("otherCharacterDropdown");
		otherCharacterDropdown.valueText = Util.getCharacterNames(characterList);
		otherCharacterDropdown.valueList = characterList;
		otherCharacterDropdown.value = TitleState.defaultVariables.player2;
		otherCharacterDropdown.onChanged = function() {
			otherCharacterGhost.changeCharacter(otherCharacterDropdown.value);
			var animList:Array<String> = [];
			for (a in otherCharacterGhost.characterData.animations)
				animList.push(a.name);
			otherCharAnimDropdown.valueList = animList;
			otherCharAnimDropdown.value = otherCharacterGhost.curAnimName;
		}

		otherCharAnimDropdown = cast element("otherCharAnimDropdown");
		otherCharAnimDropdown.onChanged = function() {
			otherCharacterGhost.playAnim(otherCharAnimDropdown.value, true);
		}
		otherCharacterDropdown.onChanged();



		var characterId:InputText = cast element("characterId");
		characterId.text = id;
		characterId.condition = function() { return id; }
		characterId.focusLost = function() {
			id = characterId.text;
			reloadIcon();
		}

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
				if (nameArray.indexOf("images") != -1)
				{
					while (nameArray[0] != "images")
						nameArray.remove(nameArray[0]);
					nameArray.remove(nameArray[0]);

					var finalName = nameArray.join("/");
					finalName = finalName.substr(0, finalName.length - 4);

					changeAsset(finalName);
				}
			}
			file.load("png");
		}

		if (myCharType == "tiles")
		{
			var charTileX:Stepper = cast element("charTileX");
			charTileX.value = characterData.tileCount[0];
			charTileX.condition = function() { return characterData.tileCount[0]; }
			charTileX.onChanged = function() { characterData.tileCount[0] = Std.int(charTileX.value); refreshTileCharacterFrames(); }

			var charTileY:Stepper = cast element("charTileY");
			charTileY.value = characterData.tileCount[1];
			charTileY.condition = function() { return characterData.tileCount[1]; }
			charTileY.onChanged = function() { characterData.tileCount[1] = Std.int(charTileY.value); refreshTileCharacterFrames(); }
		}

		var charX:Stepper = cast element("charX");
		charX.value = characterData.position[0];
		charX.condition = function() { return characterData.position[0]; };
		charX.onChanged = function() {
			characterData.position[0] = charX.valueInt;
			resetCharPosition();
		}

		var charY:Stepper = cast element("charY");
		charY.value = characterData.position[1];
		charY.condition = function() { return characterData.position[1]; };
		charY.onChanged = function() {
			characterData.position[1] = charY.valueInt;
			resetCharPosition();
		}

		var positionFixGF:Button = cast element("positionFixGF");
		positionFixGF.onClicked = function() {
			characterData.position[0] -= 140;
			characterData.position[1] += 80;
			resetCharPosition();
		}

		var charAntialias:Checkbox = cast element("charAntialias");
		charAntialias.condition = function() { return characterData.antialias; }
		charAntialias.onClicked = function() {
			characterData.antialias = charAntialias.checked;
			character.antialiasing = characterData.antialias;
			characterGhost.antialiasing = character.antialiasing;
		}

		var charFlip:Checkbox = cast element("charFlip");
		charFlip.condition = function() { return characterData.flip; }
		charFlip.onClicked = function() {
			characterData.flip = charFlip.checked;
			resetCharFlip();
		}

		var charFacingLeft:ToggleButton = cast element("charFacingLeft");
		charFacingLeft.condition = function() { return characterData.facing == "left"; }
		charFacingLeft.onClicked = function() { characterData.facing = "left"; updateFacing(); }

		var charFacingCenter:ToggleButton = cast element("charFacingCenter");
		charFacingCenter.condition = function() { return characterData.facing == "center"; }
		charFacingCenter.onClicked = function() { characterData.facing = "center"; updateFacing(); }

		var charFacingRight:ToggleButton = cast element("charFacingRight");
		charFacingRight.condition = function() { return characterData.facing == "right"; }
		charFacingRight.onClicked = function() { characterData.facing = "right"; updateFacing(); }

		var charScaleX:Stepper = cast element("charScaleX");
		charScaleX.value = characterData.scale[0];
		charScaleX.condition = function() { return characterData.scale[0]; };
		charScaleX.onChanged = function() {
			characterData.scale[0] = charScaleX.value;
			character.scale.x = characterData.scale[0];
			characterGhost.scale.x = character.scale.x;
			character.updateHitbox();
			characterGhost.updateHitbox();
			baseOffsets = [character.offset.x, character.offset.y];
			if (characterData.animations.length > 0)
			{
				playCurrentAnim();
				if (myCharType != "atlas" && characterGhost.animation.curAnim.name == characterData.animations[curCharAnim].name)
					playCurrentAnim(true);
			}
		};

		var charScaleY:Stepper = cast element("charScaleY");
		charScaleY.value = characterData.scale[1];
		charScaleY.condition = function() { return characterData.scale[1]; };
		charScaleY.onChanged = function() {
			characterData.scale[1] = charScaleY.value;
			character.scale.y = characterData.scale[1];
			characterGhost.scale.y = character.scale.y;
			character.updateHitbox();
			characterGhost.updateHitbox();
			baseOffsets = [character.offset.x, character.offset.y];
			if (characterData.animations.length > 0)
			{
				playCurrentAnim();
				if (myCharType != "atlas" && characterGhost.animation.curAnim.name == characterData.animations[curCharAnim].name)
					playCurrentAnim(true);
			}
		};

		var camPosX:Stepper = cast element("camPosX");
		camPosX.value = characterData.camPosition[0];
		camPosX.condition = function() { return characterData.camPosition[0]; };
		camPosX.onChanged = function() {characterData.camPosition[0] = camPosX.valueInt;};

		var camPosY:Stepper = cast element("camPosY");
		camPosY.value = characterData.camPosition[1];
		camPosY.condition = function() { return characterData.camPosition[1]; };
		camPosY.onChanged = function() {characterData.camPosition[1] = camPosY.valueInt;};

		var iconInput:InputText = cast element("iconInput");
		iconInput.text = (characterData.icon == null ? "" : characterData.icon);
		iconInput.condition = function() { return displayIcon.id; }
		iconInput.focusLost = function() {
			if (iconInput.text.trim() != "" && Paths.iconExists(iconInput.text))
				characterData.icon = iconInput.text;
			else
			{
				characterData.icon = "";
				iconInput.text = "";
			}
			reloadIcon();
		}
		reloadIcon();

		var loadIconButton:Button = cast element("loadIconButton");
		loadIconButton.onClicked = function() {
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = function(fullPath:String) {
				var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
				if (nameArray.indexOf("icons") != -1)
				{
					while (nameArray[0] != "images")
						nameArray.remove(nameArray[0]);
					nameArray.remove(nameArray[0]);
					nameArray.remove("icons");
					if (nameArray[nameArray.length - 1].startsWith("icon-"))
						nameArray[nameArray.length - 1] = nameArray[nameArray.length - 1].substr(5);

					var finalName = nameArray.join("/");
					if (finalName.endsWith(".json"))
						finalName = finalName.substr(0, finalName.length - 5);
					else
						finalName = finalName.substr(0, finalName.length - 4);
					characterData.icon = finalName;

					reloadIcon();
				}
			}
			file.load("png;*.json");
		}

		var healthbarColorSwatch:Button = cast element("healthbarColorSwatch");
		healthbarColorSwatch.onClicked = function() {
			new ColorPicker(FlxColor.fromRGB(characterData.healthbarColor[0], characterData.healthbarColor[1], characterData.healthbarColor[2]), function(clr:FlxColor) {
				characterData.healthbarColor = [clr.red, clr.green, clr.blue];
				displayHealthbar.color = clr;
			});
		}

		var healthbarColorPicker:Button = cast element("healthbarColorPicker");
		healthbarColorPicker.onClicked = function() {
			persistentUpdate = false;
			openSubState(new ColorPickSubstate(function(px:FlxColor) {
				displayHealthbar.color = px;
				characterData.healthbarColor = [px.red, px.green, px.blue];
			}));
		}

		var idles:TextButton = cast element("idles");
		idles.onClicked = function() {
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
		firstAnimDropdown.value = characterData.firstAnimation;
		firstAnimDropdown.condition = function() { return characterData.firstAnimation; }
		firstAnimDropdown.valueList = firstAnimList;
		firstAnimDropdown.onChanged = function() {
			characterData.firstAnimation = firstAnimDropdown.value;
			updateBaseFrameWidth();
		};

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
			else if (charAnimList.contains("firstDeath"))
				characterData.firstAnimation = "firstDeath";
			updateBaseFrameWidth();
		};

		var charDanceSpeed:Stepper = cast element("charDanceSpeed");
		charDanceSpeed.value = characterData.danceSpeed;
		charDanceSpeed.condition = function() { return characterData.danceSpeed; };
		charDanceSpeed.onChanged = function() { characterData.danceSpeed = charDanceSpeed.value; }

		var camPosDeadX:Stepper = cast element("camPosDeadX");
		camPosDeadX.value = characterData.camPositionGameOver[0];
		camPosDeadX.condition = function() { return characterData.camPositionGameOver[0]; };
		camPosDeadX.onChanged = function() {characterData.camPositionGameOver[0] = camPosDeadX.valueInt;};

		var camPosDeadY:Stepper = cast element("camPosDeadY");
		camPosDeadY.value = characterData.camPositionGameOver[1];
		camPosDeadY.condition = function() { return characterData.camPositionGameOver[1]; };
		camPosDeadY.onChanged = function() {characterData.camPositionGameOver[1] = camPosDeadY.valueInt;};

		var camTestDeadButton:TextButton = cast element("camTestDeadButton");
		camTestDeadButton.onClicked = function() {
			camFollow.x = Math.round(character.getGraphicMidpoint().x - baseOffsets[0] + characterData.camPositionGameOver[0]);
			camFollow.y = Math.round(character.getGraphicMidpoint().y - baseOffsets[1] + characterData.camPositionGameOver[1]);
		};

		var camSetDeadButton:TextButton = cast element("camSetDeadButton");
		camSetDeadButton.onClicked = function() {
			characterData.camPositionGameOver = [Std.int(camFollow.x - character.getGraphicMidpoint().x), Std.int(camFollow.y - character.getGraphicMidpoint().y)];
			characterData.camPositionGameOver[0] = Std.int(Math.round(characterData.camPositionGameOver[0] / 5) * 5);
			characterData.camPositionGameOver[1] = Std.int(Math.round(characterData.camPositionGameOver[1] / 5) * 5);
		};

		var characterList:Array<String> = Paths.listFilesSub("data/characters/", ".json");
		characterList.remove("none");
		characterList.unshift("_self");
		characterList.unshift("");
		var gameOverCharDropdown:DropdownMenu = cast element("gameOverCharDropdown");
		var characterNames:Map<String, String> = Util.getCharacterNames(characterList);
		for (k in characterNames.keys())
			gameOverCharDropdown.valueText[k] = characterNames[k];
		gameOverCharDropdown.valueList = characterList;
		gameOverCharDropdown.value = characterData.gameOverCharacter;
		gameOverCharDropdown.condition = function() { return characterData.gameOverCharacter; }
		gameOverCharDropdown.onChanged = function() {
			characterData.gameOverCharacter = gameOverCharDropdown.value;
		};

		var soundList:Array<String> = Paths.listFilesSub("sounds/", ".ogg");
		soundList.unshift("");

		var gameOverSFXDropdown:DropdownMenu = cast element("gameOverSFXDropdown");
		gameOverSFXDropdown.value = characterData.gameOverSFX;
		gameOverSFXDropdown.condition = function() { return characterData.gameOverSFX; }
		gameOverSFXDropdown.valueList = soundList;
		gameOverSFXDropdown.onChanged = function() {
			characterData.gameOverSFX = gameOverSFXDropdown.value;
		};

		var deathCounterInput:InputText = cast element("deathCounterInput");
		deathCounterInput.text = characterData.deathCounterText;
		deathCounterInput.condition = function() { return characterData.deathCounterText; }
		deathCounterInput.focusLost = function() {
			characterData.deathCounterText = deathCounterInput.text.trim();
		}

		var scriptList:Array<String> = [""];
		for (s in Paths.listFilesSub("data/characters/", ".hscript"))
			scriptList.push("characters/" + s);
		for (s in Paths.listFilesSub("data/scripts/", ".hscript"))
		{
			if (!s.startsWith("FlxSprite/") && !s.startsWith("FlxSpriteGroup/") && !s.startsWith("AnimatedSprite/"))
				scriptList.push("scripts/" + s);
		}

		if (characterData.script == "characters/" + id)
			characterData.script = "";
		var scriptDropdown:DropdownMenu = cast element("scriptDropdown");
		scriptDropdown.value = characterData.script;
		scriptDropdown.condition = function() { return characterData.script; }
		scriptDropdown.valueList = scriptList;
		scriptDropdown.onChanged = function() {
			characterData.script = scriptDropdown.value;
		};



		animName = cast element("animName");

		var commonAnimations:Array<String> = Paths.textData("commonAnimations").replace("\r","").split("\n");
		var animNameDropdown:DropdownMenu = cast element("animNameDropdown");
		animNameDropdown.value = commonAnimations[0];
		animNameDropdown.valueList = commonAnimations;
		animNameDropdown.onChanged = function() {
			animName.text = animNameDropdown.value;
		};

		animIndices = cast element("animIndices");

		if (myCharType != "tiles")
		{
			animPrefix = cast element("animPrefix");

			animPrefixDropdown = cast element("animPrefixDropdown");
			animPrefixDropdown.value = allAnimPrefixes[0];
			animPrefixDropdown.valueList = allAnimPrefixes;
			animPrefixDropdown.onChanged = function() {
				animPrefix.text = animPrefixDropdown.value;
			};
		}

		if (myCharType == "sparrow")
		{
			animAsset = cast element("animAsset");
			animAsset.focusLost = function() {
				if (animAsset.text.trim() != "" && Paths.sparrowExists(animAsset.text))
					allAnimPrefixes = Paths.sparrowAnimations(animAsset.text);
				else
					allAnimPrefixes = Paths.sparrowAnimations(characterData.asset);
				if (animPrefixDropdown != null)
					animPrefixDropdown.valueList = allAnimPrefixes;
			}

			var loadAnimAssetButton:Button = cast element("loadAnimAssetButton");
			loadAnimAssetButton.onClicked = function() {
				var file:FileBrowser = new FileBrowser();
				file.loadCallback = function(fullPath:String) {
					var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
					if (nameArray.indexOf("images") != -1)
					{
						while (nameArray[0] != "images")
							nameArray.remove(nameArray[0]);
						nameArray.remove(nameArray[0]);

						var finalName = nameArray.join("/");
						finalName = finalName.substr(0, finalName.length - 4);

						animAsset.text = finalName;
						animAsset.focusLost();
					}
				}
				file.load("png");
			}

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
		}
		else
		{
			var indRangeStart:Stepper = cast element("indRangeStart");
			var indRangeLength:Stepper = cast element("indRangeLength");

			var rangeIndices:TextButton = cast element("rangeIndices");
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
		}

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

		animLoopedFrames = cast element("animLoopedFrames");
		animLoopedFrames.condition = function() {
			if (characterData.animations.length > 0)
				return characterData.animations[curCharAnim].loopedFrames;
			return animLoopedFrames.value;
		}
		animLoopedFrames.onChanged = function() {
			if (characterData.animations.length > 0)
				characterData.animations[curCharAnim].loopedFrames = animLoopedFrames.valueInt;
		}

		animSustainFrame = cast element("animSustainFrame");
		animSustainFrame.condition = function() {
			if (characterData.animations.length > 0)
				return characterData.animations[curCharAnim].sustainFrame;
			return animSustainFrame.value;
		}
		animSustainFrame.onChanged = function() {
			if (characterData.animations.length > 0)
				characterData.animations[curCharAnim].sustainFrame = animSustainFrame.valueInt;
		}

		animImportant = cast element("animImportant");
		animImportant.condition = function() {
			if (characterData.animations.length > 0)
			{
				if (characterData.animations[curCharAnim].important != null)
					return characterData.animations[curCharAnim].important;
				return false;
			}
			return animImportant.checked;
		}
		animImportant.onClicked = function() {
			if (characterData.animations.length > 0)
				characterData.animations[curCharAnim].important = animImportant.checked;
		}

		var nextAnimList:Array<String> = [""];
		if (charAnimList.length > 0)
			nextAnimList = nextAnimList.concat(charAnimList);
		animNextDropdown = cast element("animNextDropdown");
		animNextDropdown.value = nextAnimList[0];
		animNextDropdown.condition = function() {
			if (characterData.animations.length > 0)
			{
				if (characterData.animations[curCharAnim].next != null)
					return characterData.animations[curCharAnim].next;
				return "";
			}
			return animNextDropdown.value;
		}
		animNextDropdown.valueList = nextAnimList;
		animNextDropdown.onChanged = function() {
			if (characterData.animations.length > 0)
				characterData.animations[curCharAnim].next = animNextDropdown.value;
		}

		var addAnimButton:TextButton = cast element("addAnimButton");
		addAnimButton.onClicked = function() {
			var cause:String = "";
			if (animName.text.trim() == "")
				cause = "The animation name cannot be blank.";
			if (myCharType == "sparrow" && animPrefix.text.trim() == "")
				cause = "The animation prefix cannot be blank.";
			if (myCharType == "sparrow" && allAnimData.indexOf(animPrefix.text) == -1 && animAsset.text.trim() == "")
				cause = "The sprite sheet does not contain an animation with that prefix.";
			if (myCharType == "atlas" && animPrefix.text.trim() == "" && animIndices.text.trim() == "")
				cause = "All animations for texture atlas characters must have a prefix or indices.";
			if (myCharType == "tiles" && animIndices.text.trim() == "")
				cause = "All animations for tiles characters must have indices.";

			if (cause != "")
				new Notify(cause);
			else
			{
				var newAnim:CharacterAnimation =
				{
					name: animName.text,
					asset: "",
					fps: animFPS.valueInt,
					loop: animLooped.checked,
					loopedFrames: animLoopedFrames.valueInt,
					sustainFrame: animSustainFrame.valueInt,
					important: animImportant.checked,
					offsets: [animOffsetX.valueInt, animOffsetY.valueInt]
				};

				if (myCharType == "sparrow" && animAsset.text.trim() != "" && Paths.sparrowExists(animAsset.text.trim()))
					newAnim.asset = animAsset.text.trim();

				if (myCharType != "tiles" && animPrefix.text.trim() != "")
					newAnim.prefix = animPrefix.text;

				newAnim.indices = [];
				if (animIndices.text != "")
				{
					var indicesSplit:Array<String> = animIndices.text.split(",");
					for (i in indicesSplit)
						newAnim.indices.push(Std.parseInt(i));
					newAnim.indices = Character.uncompactIndices(newAnim.indices);
				}

				if (animNextDropdown.value != "")
					newAnim.next = animNextDropdown.value;

				var animToReplace:Int = -1;
				for (i in 0...characterData.animations.length)
				{
					if (characterData.animations[i].name == newAnim.name)
						animToReplace = i;
				}

				if (animToReplace > -1)
				{
					if (newAnim.prefix != null)
						characterData.animations[animToReplace].prefix = newAnim.prefix;
					characterData.animations[animToReplace].indices = newAnim.indices;
				}
				else
				{
					characterData.animations.push(newAnim);
					animToReplace = characterData.animations.length - 1;
				}

				reloadSingleAnimation(animToReplace);
				refreshCharAnimList();
				playAnim(newAnim.name, true);
				if (characterGhost != null && characterGhost.animation.curAnim == null)
					playAnim(newAnim.name, true, true);
				refreshCharAnims();
				firstAnimDropdown.valueList = charAnimList;
				if (characterData.firstAnimation == "")
				{
					characterData.firstAnimation = newAnim.name;
					updateBaseFrameWidth();
				}
				var nextAnimList:Array<String> = [""];
				if (charAnimList.length > 0)
					nextAnimList = nextAnimList.concat(charAnimList);
				animNextDropdown.valueList = nextAnimList;
			}
		}

		var removeAnimButton:TextButton = cast element("removeAnimButton");
		removeAnimButton.onClicked = tryDeleteAnim;



		curFrameText = cast element("curFrameText");

		var toggleAnimButton:TextButton = cast element("toggleAnimButton");
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
			else if (character.animation.curAnim != null)
			{
				if (character.animation.curAnim.finished)
				{
					character.animation.curAnim.finished = false;
					character.animation.curAnim.paused = false;
				}
				else
					character.animation.curAnim.paused = !character.animation.curAnim.paused;
			}
		};

		var prevFrame:TextButton = cast element("prevFrame");
		prevFrame.onClicked = function()
		{
			if (myCharType == "atlas")
			{
				if (atlas.anim.curFrame > 0)
					atlas.anim.curFrame--;
			}
			else if (character.animation.curAnim != null && character.animation.curAnim.curFrame > 0)
				character.animation.curAnim.curFrame--;
		};

		var nextFrame:TextButton = cast element("nextFrame");
		nextFrame.onClicked = function()
		{
			@:privateAccess
			if (myCharType == "atlas")
			{
				if (atlas.anim.curFrame < atlas.anim.frameLength - 1)
					atlas.anim.curFrame++;
			}
			else if (character.animation.curAnim != null && character.animation.curAnim.curFrame < character.animation.curAnim.numFrames - 1)
				character.animation.curAnim.curFrame++;
		};

		var firstFrame:TextButton = cast element("firstFrame");
		firstFrame.onClicked = function()
		{
			if (myCharType == "atlas")
			{
				if (atlas.anim.curFrame > 0)
					atlas.anim.curFrame = 0;
			}
			else if (character.animation.curAnim != null && character.animation.curAnim.curFrame > 0)
				character.animation.curAnim.curFrame = 0;
		};

		var lastFrame:TextButton = cast element("lastFrame");
		lastFrame.onClicked = function()
		{
			@:privateAccess
			if (myCharType == "atlas")
			{
				if (atlas.anim.curFrame < atlas.anim.frameLength - 1)
					atlas.anim.curFrame = atlas.anim.frameLength - 1;
			}
			else if (character.animation.curAnim != null && character.animation.curAnim.curFrame < character.animation.curAnim.numFrames - 1)
				character.animation.curAnim.curFrame = character.animation.curAnim.numFrames - 1;
		};



		var offsetStepper:Stepper = cast element("offsetStepper");

		var offsetAddX:TextButton = cast element("offsetAddX");
		offsetAddX.onClicked = function() {
			for (a in characterData.animations)
				a.offsets[0] += Std.int(offsetStepper.value);

			updateOffsets();
			refreshCharAnims();
		}

		var offsetAddY:TextButton = cast element("offsetAddY");
		offsetAddY.onClicked = function() {
			for (a in characterData.animations)
				a.offsets[1] += Std.int(offsetStepper.value);

			updateOffsets();
			refreshCharAnims();
		}

		var offsetScaleX:TextButton = cast element("offsetScaleX");
		offsetScaleX.onClicked = function() {
			for (a in characterData.animations)
				a.offsets[0] = Std.int(a.offsets[0] * offsetStepper.value);

			updateOffsets();
			refreshCharAnims();
		}

		var offsetScaleY:TextButton = cast element("offsetScaleY");
		offsetScaleY.onClicked = function() {
			for (a in characterData.animations)
				a.offsets[1] = Std.int(a.offsets[1] * offsetStepper.value);

			updateOffsets();
			refreshCharAnims();
		}

		var offsetZero:TextButton = cast element("offsetZero");
		offsetZero.onClicked = function() {
			var offX:Int = characterData.animations[curCharAnim].offsets[0];
			var offY:Int = characterData.animations[curCharAnim].offsets[1];
			for (a in characterData.animations)
			{
				a.offsets[0] -= offX;
				a.offsets[1] -= offY;
			}
			characterData.position[0] -= offX;
			characterData.position[1] -= offY;
			if (characterData.facing == "left")
				characterData.camPosition[0] -= offX;
			else
				characterData.camPosition[0] += offX;
			characterData.camPosition[1] += offY;
			characterData.camPositionGameOver[0] += offX;
			characterData.camPositionGameOver[1] += offY;

			resetCharPosition();
			updateOffsets();
			refreshCharAnims();
		}

		if (myCharType != "atlas")
		{
			var resetAlignmentHorz = function() {
				for (a in characterData.animations)
				{
					var animData = character.animation.getByName(a.name);
					if (animData != null)
					{
						var animFrame = character.frames.frames[animData.frames[0]];
						if (animFrame != null)
						{
							switch (characterData.offsetAlign[1])
							{
								case "center": a.offsets[0] -= Std.int(Math.round(((baseFrameSize[0] - animFrame.sourceSize.x) * character.scale.x) / 2));
								case "right": a.offsets[0] -= Std.int(Math.round((baseFrameSize[0] - animFrame.sourceSize.x) * character.scale.x));
							}
						}
					}
				}
			}

			var resetAlignmentVert = function() {
				for (a in characterData.animations)
				{
					var animData = character.animation.getByName(a.name);
					if (animData != null)
					{
						var animFrame = character.frames.frames[animData.frames[0]];
						if (animFrame != null)
						{
							switch (characterData.offsetAlign[0])
							{
								case "middle": a.offsets[1] -= Std.int(Math.round(((baseFrameSize[1] - animFrame.sourceSize.y) * character.scale.y) / 2));
								case "bottom": a.offsets[1] -= Std.int(Math.round((baseFrameSize[1] - animFrame.sourceSize.y) * character.scale.y));
							}
						}
					}
				}
			}

			var alignmentLeft:ToggleButton = cast element("alignmentLeft");
			alignmentLeft.condition = function() { return characterData.offsetAlign[1] == "left"; }
			alignmentLeft.onClicked = function() {
				resetAlignmentHorz();
				characterData.offsetAlign[1] = "left";
				refreshCharAnims();
			}

			var alignmentCenter:ToggleButton = cast element("alignmentCenter");
			alignmentCenter.condition = function() { return characterData.offsetAlign[1] == "center"; }
			alignmentCenter.onClicked = function() {
				resetAlignmentHorz();
				characterData.offsetAlign[1] = "center";
				for (a in characterData.animations)
				{
					var animData = character.animation.getByName(a.name);
					if (animData != null)
					{
						var animFrame = character.frames.frames[animData.frames[0]];
						if (animFrame != null)
							a.offsets[0] += Std.int(Math.round(((baseFrameSize[0] - animFrame.sourceSize.x) * character.scale.x) / 2));
					}
				}
				refreshCharAnims();
			}

			var alignmentRight:ToggleButton = cast element("alignmentRight");
			alignmentRight.condition = function() { return characterData.offsetAlign[1] == "right"; }
			alignmentRight.onClicked = function() {
				resetAlignmentHorz();
				characterData.offsetAlign[1] = "right";
				for (a in characterData.animations)
				{
					var animData = character.animation.getByName(a.name);
					if (animData != null)
					{
						var animFrame = character.frames.frames[animData.frames[0]];
						if (animFrame != null)
							a.offsets[0] += Std.int(Math.round((baseFrameSize[0] - animFrame.sourceSize.x) * character.scale.x));
					}
				}
				refreshCharAnims();
			}

			var alignmentTop:ToggleButton = cast element("alignmentTop");
			alignmentTop.condition = function() { return characterData.offsetAlign[0] == "top"; }
			alignmentTop.onClicked = function() {
				resetAlignmentVert();
				characterData.offsetAlign[0] = "top";
				refreshCharAnims();
			}

			var alignmentMiddle:ToggleButton = cast element("alignmentMiddle");
			alignmentMiddle.condition = function() { return characterData.offsetAlign[0] == "middle"; }
			alignmentMiddle.onClicked = function() {
				resetAlignmentVert();
				characterData.offsetAlign[0] = "middle";
				for (a in characterData.animations)
				{
					var animData = character.animation.getByName(a.name);
					if (animData != null)
					{
						var animFrame = character.frames.frames[animData.frames[0]];
						if (animFrame != null)
							a.offsets[1] += Std.int(Math.round(((baseFrameSize[1] - animFrame.sourceSize.y) * character.scale.y) / 2));
					}
				}
				refreshCharAnims();
			}

			var alignmentBottom:ToggleButton = cast element("alignmentBottom");
			alignmentBottom.condition = function() { return characterData.offsetAlign[0] == "bottom"; }
			alignmentBottom.onClicked = function() {
				resetAlignmentVert();
				characterData.offsetAlign[0] = "bottom";
				for (a in characterData.animations)
				{
					var animData = character.animation.getByName(a.name);
					if (animData != null)
					{
						var animFrame = character.frames.frames[animData.frames[0]];
						if (animFrame != null)
							a.offsets[1] += Std.int(Math.round((baseFrameSize[1] - animFrame.sourceSize.y) * character.scale.y));
					}
				}
				refreshCharAnims();
			}
		}



		var help:String = Paths.text("helpText").replace("\r","").split("!CharacterEditor\n")[1].split("\n\n")[0];

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
					{
						label: "Create Copy",
						action: function() {
							if (id == "")
								new Notify("You can only make a copy of a saved character file.");
							else
							{
								var file:FileBrowser = new FileBrowser();
								file.loadCallback = function(fullPath:String) {
									var imageNameArray:Array<String> = fullPath.replace('\\','/').split('/');
									if (imageNameArray.contains("images"))
									{
										while (imageNameArray[0] != "images")
											imageNameArray.remove(imageNameArray[0]);
										imageNameArray.remove(imageNameArray[0]);

										var finalImageName = imageNameArray.join('/').split('.png')[0];

										var data:String = Json.stringify({parent:id,asset:finalImageName}, null, "\t");
										if (Options.options.compactJsons)
											data = Json.stringify({parent:id,asset:finalImageName});

										if (data != null && data.length > 0)
										{
											var file:FileBrowser = new FileBrowser();
											file.save(id + "-copy.json", data.trim());
										}
									}
								};
								file.load("png");
							}
						}
					},
					{
						label: "Convert from Base Game",
						action: convertFromBase
					},
					null,
					{
						label: "Help",
						action: function() { new Notify(help); },
						shortcut: [FlxKey.F1]
					},
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
					},
					{
						label: "Camera Panel",
						condition: function() { return members.contains(cameraBox); },
						action: function() {
							if (members.contains(cameraBox))
								remove(cameraBox, true);
							else
								insert(members.indexOf(topmenu), cameraBox);
						},
						icon: "bullet"
					},
					{
						label: "Icon & Health Bar",
						condition: function() { return displayIcon.visible; },
						action: function() {
							displayIcon.visible = !displayIcon.visible;
							displayHealthbar.visible = displayIcon.visible;
							displayHealthbarBG.visible = displayIcon.visible;
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

		camFollow.x = Math.round(character.getGraphicMidpoint().x - character.offset.x);
		camFollow.y = Math.round(character.getGraphicMidpoint().y - character.offset.y);
		dataLog = [Cloner.clone(characterData)];
	}

	override public function update(elapsed:Float)
	{
		mousePos.x = (((FlxG.mouse.x - (FlxG.width / 2)) / camGame.zoom) + (FlxG.width / 2)) + camFollow.x - (FlxG.width / 2);
		mousePos.y = (((FlxG.mouse.y - (FlxG.height / 2)) / camGame.zoom) + (FlxG.height / 2)) + camFollow.y - (FlxG.height / 2);

		if (FlxG.mouse.justMoved)
		{
			if (posLocked)
				UIControl.cursor = MouseCursor.ARROW;
			else if (myCharType == "atlas")
				UIControl.cursor = MouseCursor.HAND;
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

		if (myCharType == "atlas")
		{
			atlas.x = character.x - character.offset.x;
			atlas.y = character.y - character.offset.y;
			atlas.antialiasing = character.antialiasing;
			atlas.flipX = character.flipX;
			atlas.flipY = character.flipY;
			atlas.scale.x = character.scale.x;
			atlas.scale.y = character.scale.y;
		}

		super.update(elapsed);

		if (characterData.animations.length > 0)
		{
			var curAnimFinished:Bool;
			@:privateAccess
			if (myCharType == "atlas")
				curAnimFinished = (atlas.anim.curFrame >= atlas.anim.frameLength - 1);
			else
				curAnimFinished = (character.animation.curAnim != null && character.animation.curAnim.finished);
			if (curAnimFinished && characterData.animations[curCharAnim].loopedFrames > 0)
			{
				playCurrentAnim();
				@:privateAccess
				if (myCharType == "atlas")
					atlas.anim.curFrame = atlas.anim.frameLength - characterData.animations[curCharAnim].loopedFrames;
				else
					character.animation.curAnim.curFrame = character.animation.curAnim.numFrames - characterData.animations[curCharAnim].loopedFrames;
			}
		}

		var camPosString:String = "Camera X: "+Std.string(camFollow.x)+"\nCamera Y: "+Std.string(camFollow.y)+"\nCamera Z: "+Std.string(camGame.zoom);
		if (camPosText.text != camPosString)
			camPosText.text = camPosString;

		if (FlxG.mouse.wheel != 0 && !DropdownMenu.isOneActive)
		{
			camGame.zoom = Math.max(0.05, camGame.zoom + (FlxG.mouse.wheel * 0.05));
			camGame.zoom = Math.round(camGame.zoom * 100) / 100;
			bg.scale.set(1 / camGame.zoom, 1 / camGame.zoom);
		}

		if (movingCharacter)
		{
			UIControl.cursor = MouseCursor.HAND;
			dragOffset[0] += FlxG.mouse.deltaX / camGame.zoom;
			dragOffset[1] += FlxG.mouse.deltaY / camGame.zoom;
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
		else if (movingCamera)
		{
			dragOffset[0] += FlxG.mouse.deltaX / camGame.zoom;
			dragOffset[1] += FlxG.mouse.deltaY / camGame.zoom;
			camFollow.x = Math.round(dragStart[0] + dragOffset[0]);
			camFollow.y = Math.round(dragStart[1] + dragOffset[1]);

			if (Options.mouseJustReleased(true))
				movingCamera = false;
		}
		else
		{
			if (Options.mouseJustPressed())
			{
				if (!posLocked && UIControl.cursor == MouseCursor.HAND && !FlxG.mouse.overlaps(tabMenu, camHUD) && (!members.contains(infoBox) || !FlxG.mouse.overlaps(infoBox, camHUD)) && (!members.contains(cameraBox) || !FlxG.mouse.overlaps(cameraBox, camHUD)) && (!members.contains(charAnims) || !FlxG.mouse.overlaps(charAnims, camHUD)))
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
			else if (Options.mouseJustPressed(true) && !FlxG.mouse.overlaps(tabMenu, camHUD))
			{
				if ((!members.contains(cameraBox) || !FlxG.mouse.overlaps(cameraBox, camHUD)) && (!members.contains(charAnims) || !FlxG.mouse.overlaps(charAnims, camHUD)))
				{
					dragStart = [Std.int(camFollow.x), Std.int(camFollow.y)];
					dragOffset = [0, 0];
					movingCamera = true;
				}
			}
		}

		if (FlxG.keys.justPressed.DELETE)
			tryDeleteAnim();

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
			if (character.animation.curAnim != null)
				frameText += Std.string(character.animation.curAnim.curFrame);
			else
				frameText += "0";
		}
		if (curFrameText.text != frameText)
			curFrameText.text = frameText;

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}

	function createTemplateAnimation(name:String, condition:String->Bool, optional:Bool, ?loop:Bool = false)
	{
		var ind:Int = -1;
		for (i in 0...allAnimPrefixes.length)
		{
			if (condition(allAnimPrefixes[i].toLowerCase()))
			{
				ind = i;
				break;
			}
		}
		if (ind == -1 && !optional)
			ind = 0;
		if (ind > -1)
			characterData.animations.push({name: name, prefix: allAnimPrefixes[ind], fps: 24, loop: loop, loopedFrames: 0, sustainFrame: -1, offsets: [0, 0]});
	}

	function createTemplateAnimationTwoConditions(name:String, cond1:String->Bool, cond2:String->Bool, optional:Bool)
	{
		var ind:Int = -1;
		for (i in 0...allAnimPrefixes.length)
		{
			if (cond1(allAnimPrefixes[i].toLowerCase()))
			{
				ind = i;
				break;
			}
		}
		if (ind == -1)
		{
			for (i in 0...allAnimPrefixes.length)
			{
				if (cond2(allAnimPrefixes[i].toLowerCase()))
				{
					ind = i;
					break;
				}
			}
		}
		if (ind == -1 && !optional)
			ind = 0;
		if (ind > -1)
			characterData.animations.push({name: name, prefix: allAnimPrefixes[ind], fps: 24, loop: false, loopedFrames: 0, sustainFrame: -1, offsets: [0, 0]});
	}

	function createTemplateAnimationLeftRight(name:String, condition:String->Bool, optional:Bool)
	{
		var ind:Int = -1;
		for (i in 0...allAnimPrefixes.length)
		{
			if (condition(allAnimPrefixes[i].toLowerCase()))
			{
				ind = i;
				break;
			}
		}
		if (ind == -1 && !optional)
			ind = 0;
		if (ind > -1)
		{
			var len:Int = allAnimData.split(allAnimPrefixes[ind]).length - 1;
			var lenHalf:Int = Std.int(len / 2);
			characterData.animations.push({name: name + "Left", prefix: allAnimPrefixes[ind], indices: Character.uncompactIndices([-1, 0, lenHalf - 1]), fps: 24, loop: false, loopedFrames: 0, sustainFrame: -1, offsets: [0, 0]});
			characterData.animations.push({name: name + "Right", prefix: allAnimPrefixes[ind], indices: Character.uncompactIndices([-1, lenHalf, len - 1]), fps: 24, loop: false, loopedFrames: 0, sustainFrame: -1, offsets: [0, 0]});
		}
	}

	function fillTemplate(type)
	{
		if (type == "dad")
			otherCharacterDropdown.value = TitleState.defaultVariables.player2;
		else if (type == "gf")
			otherCharacterDropdown.value = TitleState.defaultVariables.gf;
		else
			otherCharacterDropdown.value = TitleState.defaultVariables.player1;
		otherCharacterDropdown.onChanged();
		showOtherAnimGhost.checked = true;
		showOtherAnimGhost.onClicked();
		if (type == "dad")
			characterData.facing = "right";
		else if (type == "gf")
			characterData.facing = "center";
		else
			characterData.facing = "left";
		updateFacing();
		otherCharPosStepper.value = charPosStepper.value;
		otherCharPosStepper.onChanged();
		if (type == "bf")
			characterData.flip = true;
		else
			characterData.flip = false;
		resetCharFlip();

		if (myCharType == "sparrow")
		{
			characterData.animations = [];

			if (type == "gf")
				createTemplateAnimationLeftRight("dance", function(prefix:String) { return (prefix.indexOf("idle") != -1 || prefix.indexOf("dance") != -1 || prefix.indexOf("dancing") != -1); }, false);
			else
				createTemplateAnimation("idle", function(prefix:String) { return (prefix.indexOf("idle") != -1 || prefix.indexOf("dance") != -1 || prefix.indexOf("dancing") != -1); }, false);
			for (dir in ["left", "down", "up", "right"])
				createTemplateAnimationTwoConditions("sing" + dir.toUpperCase(), function(prefix:String) { return (prefix.indexOf(dir) != -1 && prefix.indexOf("miss") == -1); }, function(prefix:String) { return (prefix.indexOf(dir) != -1); }, false);
			for (dir in ["left", "down", "up", "right"])
				createTemplateAnimation("sing" + dir.toUpperCase() + "miss", function(prefix:String) { return (prefix.indexOf(dir) != -1 && prefix.indexOf("miss") != -1); }, true);
			if (type == "gf")
			{
				createTemplateAnimation("cheer", function(prefix:String) { return (prefix.indexOf("hey") != -1 || prefix.indexOf("cheer") != -1); }, true);
				createTemplateAnimation("sad", function(prefix:String) { return (prefix.indexOf("sad") != -1); }, true);
			}
			else
				createTemplateAnimation("hey", function(prefix:String) { return (prefix.indexOf("hey") != -1 || prefix.indexOf("cheer") != -1); }, true);
			createTemplateAnimation("scared", function(prefix:String) { return (prefix.indexOf("scared") != -1 || prefix.indexOf("fear") != -1 || prefix.indexOf("shake") != -1 || prefix.indexOf("shaking") != -1); }, true, true);
			createTemplateAnimation("firstDeath", function(prefix:String) { return (prefix.indexOf("dies") != -1); }, true);
			createTemplateAnimation("deathLoop", function(prefix:String) { return ((prefix.indexOf("dead") != -1 || prefix.indexOf("death") != -1) && prefix.indexOf("loop") != -1); }, true, true);
			createTemplateAnimation("deathConfirm", function(prefix:String) { return ((prefix.indexOf("dead") != -1 || prefix.indexOf("death") != -1) && prefix.indexOf("confirm") != -1); }, true);

			if (type == "gf")
			{
				characterData.firstAnimation = "danceLeft";
				characterData.idles = ["danceLeft", "danceRight"];
			}
			else
			{
				characterData.firstAnimation = "idle";
				characterData.idles = ["idle"];
			}
			updateBaseFrameWidth();
			playAnim(characterData.firstAnimation, true);
		}
		reloadAnimations();
		refreshCharAnims();
		firstAnimDropdown.valueList = charAnimList;
		var nextAnimList:Array<String> = [""];
		if (charAnimList.length > 0)
			nextAnimList = nextAnimList.concat(charAnimList);
		animNextDropdown.valueList = nextAnimList;

		characterData.position[0] = Std.int(Math.round((platform.x + ((platform.width - character.frameWidth) / 2)) / 5) * 5);
		if (type == "dad")
			characterData.position[1] = Std.int(Math.round(((platform.y + platform.height - character.frameHeight) - 45) / 5) * 5);
		else if (type == "gf")
			characterData.position[1] = Std.int(Math.round(((platform.y + platform.height - character.frameHeight) - 80) / 5) * 5);
		else
			characterData.position[1] = Std.int(Math.round(((platform.y + platform.height - character.frameHeight) - 50) / 5) * 5);

		resetCharPosition();

		if (type == "dad")
			characterData.camPosition = [150, -100];
		else if (type == "gf")
			characterData.camPosition = [0, 0];
		else
			characterData.camPosition = [100, -100];

		if (charAnimList.contains("firstDeath"))
			characterData.gameOverCharacter = "_self";
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
							nameArray.remove(nameArray[0]);
						nameArray.remove(nameArray[0]);

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
		if (Paths.exists("images/" + asset + ".json"))
		{
			myCharType = "atlas";
			character.makeGraphic(1, 1, FlxColor.TRANSPARENT);

			var assetArray = asset.replace("\\","/").split("/");
			assetArray.pop();
			atlas = new FlxAnimate(0, 0, Paths.atlas(assetArray.join("/")));
			allAnimPrefixes = atlas.anim.frameNames();
			if (allAnimPrefixes.length <= 0)
				allAnimPrefixes = [""];
		}
		else if (Paths.sparrowExists(asset))
		{
			myCharType = "sparrow";
			character.frames = Paths.sparrow(asset);
			assets[""] = character.frames;
			character.frames.parent.destroyOnNoUse = false;
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

			if (characterData.tileCount == null || characterData.tileCount.length < 2)
				characterData.tileCount = [1, 1];

			refreshTileCharacterFrames();
		}

		return true;
	}

	function changeAsset(asset:String):Bool
	{
		var successful:Bool = false;
		if (Paths.imageExists(asset))
		{
			switch (myCharType)
			{
				case "sparrow":
					if (Paths.sparrowExists(asset))
					{
						characterData.asset = asset;
						allAnimData = "";
						allAnimPrefixes = [];
						character.frames = Paths.sparrow(asset);
						if (Paths.exists("images/" + asset + ".txt"))
							allAnimData = Paths.raw("images/" + asset + ".txt");
						else
							allAnimData = Paths.raw("images/" + asset + ".xml");
						allAnimPrefixes = Paths.sparrowAnimations(asset);
						if (animPrefixDropdown != null)
							animPrefixDropdown.valueList = allAnimPrefixes;
						successful = true;
					}

				case "tiles":
					characterData.asset = asset;
					refreshTileCharacterFrames();
					successful = true;

				case "atlas":
					if (Paths.exists("images/" + asset + ".json"))
					{
						characterData.asset = asset;
						if (atlas != null)
						{
							remove(atlas, true);
							atlas.destroy();
						}

						var assetArray = asset.replace("\\","/").split("/");
						assetArray.pop();
						atlas = new FlxAnimate(0, 0, Paths.atlas(assetArray.join("/")));
						successful = true;
					}

			}
		}

		if (successful)
		{
			characterGhost.frames = character.frames;
			reloadAnimations();
			refreshCharAnims();

			if (charAnimList.length > 0 && !charAnimList.contains(characterData.firstAnimation))
				characterData.firstAnimation = charAnimList[0];

			playAnim(characterData.firstAnimation);
			playAnim(characterData.firstAnimation, false, true);

			character.updateHitbox();
			characterGhost.updateHitbox();
			baseOffsets = [character.offset.x, character.offset.y];
			updateBaseFrameWidth();

			playAnim(characterData.firstAnimation);
			playAnim(characterData.firstAnimation, false, true);
		}

		return successful;
	}

	function reloadAnimations()
	{
		if (characterData.animations.length > 0)
		{
			var poppers:Array<CharacterAnimation> = [];
			for (i in 0...characterData.animations.length)
			{
				var anim:CharacterAnimation = characterData.animations[i];
				switch (myCharType)
				{
					case "atlas":
						reloadSingleAnimation(i);

					case "tiles":
						if (anim.indices != null && anim.indices.length > 0)
							reloadSingleAnimation(i);
						else
							poppers.push(anim);

					default:
						if (allAnimData.indexOf(anim.prefix) == -1 && anim.asset == "")
							poppers.push(anim);
						else
							reloadSingleAnimation(i);
				}
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
			switch (myCharType)
			{
				case "atlas":
					if (anim.indices != null && anim.indices.length > 0)
						atlas.anim.addByAnimIndices(anim.name, anim.indices, anim.fps);
					else
						atlas.anim.addByFrameName(anim.name, anim.prefix, anim.fps);

				case "tiles":
					if (anim.indices != null && anim.indices.length > 0)
					{
						character.animation.add(anim.name, anim.indices, anim.fps, anim.loop);
						characterGhost.animation.add(anim.name, anim.indices, anim.fps, anim.loop);
					}

				default:
					if (allAnimData.indexOf(anim.prefix) != -1 || anim.asset != "")
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
	}

	function refreshTileCharacterFrames()
	{
		if (myCharType == "tiles")
		{
			var asset:String = characterData.asset;

			character.frames = Paths.tiles(asset, characterData.tileCount[0], characterData.tileCount[1]);
			if (characterGhost != null)
			{
				characterGhost.frames = character.frames;
				reloadAnimations();
			}
		}
	}

	function reloadIcon()
	{
		if (characterData.icon == "")
		{
			displayIcon.reloadIcon(id);
			if (!Paths.iconExists(id) && Paths.iconExists(id.split("-")[0]))
				displayIcon.reloadIcon(id.split("-")[0]);
		}
		else
			displayIcon.reloadIcon(characterData.icon);
		displayIcon.screenCenter(X);
		displayIcon.y = 650 - (displayIcon.height / 2);
	}

	function resetCharPosition()
	{
		character.x = characterData.position[0] + charPosOffset[0];
		character.y = characterData.position[1] + charPosOffset[1];
		characterGhost.setPosition(character.x, character.y);
	}

	function resetCharFlip()
	{
		if (stageID == "")
		{
			var inFlipPos:Bool = (charPos == 0);
			if (inFlipPos && characterData.facing != "center")
				character.flipX = !characterData.flip;
			else
				character.flipX = characterData.flip;
		}
		else
		{
			var inFlipPos:Bool = stage.stageData.characters[charPos].flip;
			if (inFlipPos && characterData.facing != "center")
				character.flipX = !characterData.flip;
			else
				character.flipX = characterData.flip;
		}
		characterGhost.flipX = character.flipX;
	}

	function updateFacing()
	{
		if (stageID == "")
		{
			if (characterData.facing == "left")
				charPosStepper.value = 0;
			else
				charPosStepper.value = 1;
		}
		else
		{
			if (characterData.facing == "left")
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
		}
		charPosStepper.onChanged();
	}

	function playAnim(animName:String, forced:Bool = false, ?ghost:Bool = false)
	{
		var charAnim:Int = charAnimList.indexOf(animName);
		if (charAnim > -1)
		{
			var animData:CharacterAnimation = characterData.animations[charAnim];
			if (animData != null)
			{
				if (myCharType == "atlas")
				{
					curCharAnim = charAnim;
					charAnims.selected = curCharAnim;
					refreshCharAnims();
					atlas.playAnim(animName, true, animData.loop);
					updateOffsets();
				}
				else if (ghost)
				{
					characterGhost.animation.play(animName, forced);
					characterGhost.offset.x = animData.offsets[0] + baseOffsets[0];
					characterGhost.offset.y = animData.offsets[1] + baseOffsets[1];
				}
				else
				{
					curCharAnim = charAnim;
					charAnims.selected = curCharAnim;
					refreshCharAnims();

					if (animData.asset != null && currentAsset != animData.asset)
					{
						if (!assets.exists(animData.asset))
						{
							assets[animData.asset] = Paths.sparrow(animData.asset);
							assets[animData.asset].parent.destroyOnNoUse = false;
						}

						currentAsset = animData.asset;
						var oldWidth:Float = character.width;
						var oldHeight:Float = character.height;
						character.frames = assets[animData.asset];
						character.width = oldWidth;
						character.height = oldHeight;
						reloadAnimations();
					}

					character.animation.play(animName, forced);
					updateOffsets();
				}
			}
		}
	}

	function playCurrentAnim(?ghost:Bool = false)
	{
		if (myCharType == "atlas")
		{
			if (characterData.animations.length > curCharAnim)
				playAnim(characterData.animations[curCharAnim].name, true);
		}
		else if (ghost)
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
				if (myCharType == "atlas")
				{
					character.offset.x = animData.offsets[0];
					character.offset.y = animData.offsets[1];
				}
				else
				{
					character.offset.x = animData.offsets[0] + baseOffsets[0];
					character.offset.y = animData.offsets[1] + baseOffsets[1];

					if (baseFrameSize[1] > 0)
					{
						switch (characterData.offsetAlign[0])
						{
							case "bottom":
								character.offset.y -= (baseFrameSize[1] - character.frameHeight) * character.scale.y;

							case "middle":
								character.offset.y -= Math.round(((baseFrameSize[1] - character.frameHeight) * character.scale.y) / 2);
						}
					}
					if (baseFrameSize[0] > 0)
					{
						switch (characterData.offsetAlign[1])
						{
							case "right":
								character.offset.x -= (baseFrameSize[0] - character.frameWidth) * character.scale.x;

							case "center":
								character.offset.x -= Math.round(((baseFrameSize[0] - character.frameWidth) * character.scale.x) / 2);
						}
					}
				}
			}
		}
	}

	function updateBaseFrameWidth()
	{
		baseFrameSize = [0, 0];
		if (characterData.animations.length > 0 && charAnimList.contains(characterData.firstAnimation))
		{
			var animData = character.animation.getByName(characterData.firstAnimation);
			if (animData != null)
			{
				var animFrame = character.frames.frames[animData.frames[0]];
				if (animFrame != null)
					baseFrameSize = [Std.int(animFrame.sourceSize.x), Std.int(animFrame.sourceSize.y)];
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
			refreshCharAnimList();
			if (curCharAnim >= charAnimList.length)
			{
				curCharAnim = charAnimList.length - 1;
				charAnims.selected = curCharAnim;
			}
			charAnims.listOffset = Std.int(Math.min(charAnims.listOffset, characterData.animations.length - 1));
			if (charAnimList.length > 0)
				playAnim(characterData.animations[curCharAnim].name);
			refreshCharAnims();

			firstAnimDropdown.valueList = charAnimList;
			if (!charAnimList.contains(characterData.firstAnimation))
				characterData.firstAnimation = charAnimList[0];
			var nextAnimList:Array<String> = [""];
			if (charAnimList.length > 0)
				nextAnimList = nextAnimList.concat(charAnimList);
			animNextDropdown.valueList = nextAnimList;
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
		var prevAnims:Array<String> = [];
		if (characterData.animations.length > 0)
			prevAnims = [character.animation.curAnim.name, characterGhost.animation.curAnim.name];
		refreshTileCharacterFrames();
		reloadIcon();
		displayHealthbar.color = FlxColor.fromRGB(characterData.healthbarColor[0], characterData.healthbarColor[1], characterData.healthbarColor[2]);
		resetCharPosition();

		character.scale.set(characterData.scale[0], characterData.scale[1]);
		characterGhost.scale.set(characterData.scale[0], characterData.scale[1]);
		character.updateHitbox();
		characterGhost.updateHitbox();
		baseOffsets = [character.offset.x, character.offset.y];

		character.antialiasing = characterData.antialias;
		characterGhost.antialiasing = character.antialiasing;

		refreshCharAnims();
		reloadAnimations();
		updateFacing();
		resetCharFlip();

		if (characterData.animations.length > 0)
		{
			if (myCharType == "tiles")
			{
				playAnim(prevAnims[0], true);
				if (prevAnims[1] == prevAnims[0])
					playAnim(prevAnims[1], true, true);
			}
			else
			{
				playCurrentAnim();
				if (myCharType != "atlas" && characterGhost.animation.curAnim.name == characterData.animations[curCharAnim].name)
					playCurrentAnim(true);
			}
		}
	}

	var storedStages:Map<String, Stage> = new Map<String, Stage>();
	function cacheStage(stageId:String)
	{
		if (!storedStages.exists(stageId))
		{
			var s = new Stage(stageId);
			storedStages[stageId] = s;
		}
	}

	function changeStage()
	{
		if (stage != null)
		{
			for (piece in stage.stageData.pieces)
				remove(stage.pieces[piece.id], true);
		}
		remove(character, true);
		remove(characterGhost, true);
		remove(otherCharacterGhost, true);
		if (myCharType == "atlas")
			remove(atlas, true);

		if (stageID == "")
		{
			bg.visible = true;
			platform.visible = true;

			otherCharacterGhost.repositionCharacter(0, 0);
			add(otherCharacterGhost);
			charPosOffset = [0, 0];
			charCameraOffset = [0, 0];
			add(characterGhost);
			add(character);
			if (myCharType == "atlas")
				add(atlas);
		}
		else
		{
			bg.visible = false;
			platform.visible = false;

			if (!storedStages.exists(stageID))
				cacheStage(stageID);
			if (stage == null || stageID != stage.curStage)
				stage = storedStages[stageID];
			if (charPos >= stage.stageData.characters.length)
				charPos = stage.stageData.characters.length - 1;
			if (otherCharPos >= stage.stageData.characters.length)
				otherCharPos = stage.stageData.characters.length - 1;

			for (piece in stage.stageData.pieces)
			{
				if (piece.layer <= stage.stageData.characters[charPos].layer)
					add(stage.pieces.get(piece.id));
			}

			otherCharacterGhost.repositionCharacter(stage.stageData.characters[otherCharPos].position[0], stage.stageData.characters[otherCharPos].position[1]);
			add(otherCharacterGhost);

			charPosOffset = stage.stageData.characters[charPos].position;
			if (stage.stageData.characters[charPos].camPosAbsolute)
				charCameraOffset = [0, 0];
			else
				charCameraOffset = stage.stageData.characters[charPos].camPosition;
			add(characterGhost);
			add(character);
			if (myCharType == "atlas")
				add(atlas);

			for (piece in stage.stageData.pieces)
			{
				if (piece.layer > stage.stageData.characters[charPos].layer)
					add(stage.pieces.get(piece.id));
			}
		}

		resetCharPosition();
	}



	function _new()
	{
		var file:FileBrowser = new FileBrowser();
		file.label = "Choose a spritesheet or texture atlas for your character";
		file.loadCallback = function(fullPath:String)
		{
			var imageNameArray:Array<String> = fullPath.replace('\\','/').split('/');
			if (imageNameArray.indexOf("images") == -1)
				new Notify("The file you have selected is not a valid asset.");
			else
			{
				while (imageNameArray[0] != "images")
					imageNameArray.remove(imageNameArray[0]);
				imageNameArray.remove(imageNameArray[0]);

				var finalImageName = imageNameArray.join('/').split('.png')[0];

				CharacterEditorState.newCharacterImage = finalImageName;
				FlxG.switchState(new CharacterEditorState(true, "", ""));
			}
		};
		file.load("png");
	}

	function _open()
	{
		var file:FileBrowser = new FileBrowser();
		file.loadCallback = function(fullPath:String)
		{
			var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
			if (jsonNameArray.indexOf("characters") == -1)
				new Notify("The file you have selected is not a character.");
			else
			{
				while (jsonNameArray[0] != "characters")
					jsonNameArray.remove(jsonNameArray[0]);
				jsonNameArray.remove(jsonNameArray[0]);

				var finalJsonName = jsonNameArray.join("/").split('.json')[0];

				FlxG.switchState(new CharacterEditorState(false, finalJsonName, fullPath));
			}
		};
		file.load();
	}

	function _save(?browse:Bool = true)
	{
		var saveData:CharacterData = Cloner.clone(characterData);
		saveData.fixes = 1;

		if (saveData.scale[0] == 1 && saveData.scale[1] == 1)
			Reflect.deleteField(saveData, "scale");

		if (myCharType != "tiles" && saveData.tileCount != null)	// Just in case
			Reflect.deleteField(saveData, "tileCount");

		for (a in saveData.animations)
		{
			if (a.asset.trim() == "")
				Reflect.deleteField(a, "asset");

			if (a.loop == false)
				Reflect.deleteField(a, "loop");

			if (a.fps == 24)
				Reflect.deleteField(a, "fps");

			if (a.indices != null)
			{
				if (a.indices.length <= 0)
					Reflect.deleteField(a, "indices");
				else
					a.indices = Character.compactIndices(a.indices);
			}

			if (a.loopedFrames <= 0)
				Reflect.deleteField(a, "loopedFrames");

			if (a.sustainFrame < 0)
				Reflect.deleteField(a, "sustainFrame");

			if (!a.important)
				Reflect.deleteField(a, "important");

			if (a.next == "")
				Reflect.deleteField(a, "next");
		}

		if (saveData.icon.trim() == "" || saveData.icon == id)
			Reflect.deleteField(saveData, "icon");

		if (saveData.gameOverCharacter == "")
			Reflect.deleteField(saveData, "gameOverCharacter");

		if (saveData.gameOverSFX == "")
			Reflect.deleteField(saveData, "gameOverSFX");

		if (saveData.deathCounterText == "")
			Reflect.deleteField(saveData, "deathCounterText");

		if (saveData.script == "" || saveData.script == "characters/" + id)
			Reflect.deleteField(saveData, "script");

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
		if (jsonNameArray.contains("characters"))
		{
			while (jsonNameArray[0] != "characters")
				jsonNameArray.shift();
			jsonNameArray.shift();
			var finalJsonName = jsonNameArray.join("/").split('.json')[0];
			id = finalJsonName;
			reloadIcon();
		}
	}



	function convertFromBase()
	{
		var file:FileBrowser = new FileBrowser();
		file.label = "Choose a character json file that you want to convert";
		file.loadCallback = function(fullPath:String)
		{
			if (fullPath.indexOf("characters") > -1)
			{
				var pathArray:Array<String> = fullPath.replace('\\','/').split('/');
				var convertedCharacterId:String = pathArray[pathArray.length - 1];

				var character:Dynamic = Json.parse(File.getContent(fullPath));

				var file2:FileBrowser = new FileBrowser();
				file2.label = "Choose a png file in the folder for this character's sprite sheets";
				file2.loadCallback = function(imagePath:String)
				{
					var imagePathArray:Array<String> = imagePath.replace('\\','/').split('/');
					if (imagePathArray.contains("images"))
					{
						while (imagePathArray[imagePathArray.length - 1] != "images")
							imagePathArray.pop();
						var trueImagePath:String = imagePathArray.join("/");
						if (FileSystem.exists(trueImagePath + "/" + character.assetPath + ".xml") || FileSystem.exists(trueImagePath + "/" + character.assetPath + ".txt"))
						{
							var frames:Array<Dynamic> = [];

							if (FileSystem.exists(trueImagePath + "/" + character.assetPath + ".txt"))
							{
								var txtRaw:String = File.getContent(trueImagePath + "/" + character.assetPath + ".txt");
								var txtSplit:Array<String> = txtRaw.replace("\r","").replace("\t","").split("\n");
								for (f in txtSplit)
								{
									var fSplit:Array<String> = f.split(" = ");
									frames.push({name: fSplit[0], w: fSplit[1].split(" ")[2], h: fSplit[1].split(" ")[3]});
								}
							}
							else
							{
								var xmlRaw:String = File.getContent(trueImagePath + "/" + character.assetPath + ".xml");
								var data:Access = new Access(Xml.parse(xmlRaw).firstElement());
								for (texture in data.nodes.SubTexture)
								{
									var frame = {name: texture.att.name, w: texture.att.width, h: texture.att.height};
									if (texture.has.frameWidth)
									{
										frame.w = texture.att.frameWidth;
										frame.h = texture.att.frameHeight;
									}
									frames.push(frame);
								}
							}

							var file3:FileBrowser = new FileBrowser();
							file3.saveCallback = function(savePath:String)
							{
								var savePathArray:Array<String> = savePath.replace('\\','/').split('/');
								savePathArray.pop();
								var trueSavePath:String = savePathArray.join("/") + "/";

								var finalChar:CharacterData = {
									fixes: 1,
									asset: character.assetPath,
									position: [210, 765],
									camPosition: [150, -100],
									scale: [1, 1],
									antialias: true,
									animations: [],
									firstAnimation: "idle",
									idles: ["idle"],
									flip: false,
									facing: "right",
									icon: ""
								};

								if (character.offsets != null)
								{
									finalChar.position[0] += Std.int(character.offsets[0]);
									finalChar.position[1] += Std.int(character.offsets[1]);
								}

								if (character.cameraOffsets != null)
								{
									finalChar.camPosition[0] += Std.int(character.cameraOffsets[0]);
									finalChar.camPosition[1] += Std.int(character.cameraOffsets[1]);
								}

								if (character.scale != null)
									finalChar.scale = [character.scale, character.scale];

								if (character.isPixel != null)
									finalChar.antialias = !character.isPixel;

								if (character.startingAnimation != null)
									finalChar.firstAnimation = character.startingAnimation;

								if (character.flipX != null)
									finalChar.flip = character.flipX;

								if (character.danceEvery != null)
									finalChar.danceSpeed = character.danceEvery;

								if (character.healthIcon != null)
									finalChar.icon = character.healthIcon.id;

								var oldAnims:Array<Dynamic> = cast character.animations;
								var animNames:Array<String> = [];
								for (a in oldAnims)
								{
									var anim:CharacterAnimation = {name: a.name};
									if (anim.name.endsWith("-hold"))
										anim.name = anim.name.replace("-hold", "-loop");
									if (a.assetPath != null)
										anim.asset = a.assetPath;
									if (a.prefix != null)
										anim.prefix = a.prefix;
									if (a.offsets != null)
										anim.offsets = a.offsets;
									if (a.looped != null)
										anim.loop = a.looped;
									if (a.frameRate != null)
										anim.fps = a.frameRate;
									if (a.frameIndices != null)
										anim.indices = a.frameIndices;

									finalChar.animations.push(anim);
									animNames.push(anim.name);
								}
								if (animNames.contains("danceLeft") && animNames.contains("danceRight"))
									finalChar.idles = ["danceLeft", "danceRight"];

								var idlePrefix:String = frames[0].name;
								for (a in finalChar.animations)
								{
									if (a.name == finalChar.idles[0])
									{
										idlePrefix = a.prefix;
										break;
									}
								}

								var idleFrame:Array<Float> = [0, 0];
								for (f in frames)
								{
									if (StringTools.startsWith(f.name, idlePrefix))
									{
										idleFrame = [Std.parseFloat(f.w), Std.parseFloat(f.h)];
										break;
									}
								}

								finalChar.position[0] -= Std.int((idleFrame[0] / 2) * finalChar.scale[0]);
								finalChar.position[1] -= Std.int(idleFrame[1] * finalChar.scale[1]);
								finalChar.position[0] = Std.int(Math.round(finalChar.position[0] / 5) * 5);
								finalChar.position[1] = Std.int(Math.round(finalChar.position[1] / 5) * 5);

								File.saveContent(trueSavePath + convertedCharacterId, Json.stringify(finalChar));
							}
							file3.savePath("*.*");
						}
					}
				}
				file2.load("png");
			}
		}
		file.load("json");
	}
}