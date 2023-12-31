package editors;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import data.ObjectData;
import data.Options;
import objects.AnimatedSprite;
import objects.Character;
import objects.Stage;
import haxe.Json;
import menus.EditorMenuState;
import shaders.ColorFade;

import lime.app.Application;

import funkui.TabMenu;
import funkui.Checkbox;
import funkui.ColorSwatch;
import funkui.DropdownMenu;
import funkui.InputText;
import funkui.Label;
import funkui.ObjectMenu;
import funkui.Stepper;
import funkui.TextButton;

using StringTools;

class StageEditorState extends MusicBeatState
{
	public static var newStage:Bool = false;
	public static var curStage:String = "";

	var myStage:Array<FlxSprite> = [];
	var myStageGroup:FlxSpriteGroup;
	public var stageData:StageData;
	var selectionShader:ColorFade;

	var camFollow:FlxObject;
	public var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var camPosText:FlxText;

	var	movingCamera:Bool = false;
	var	movingPiece:Bool = false;
	var movingCharacter:Bool = false;
	var dragStart:Array<Int> = [0, 0];
	var dragOffset:Array<Float> = [0, 0];

	var curStagePiece:Int = 0;

	var allCharacters:Array<Character> = [];

	var tabMenu:IsolatedTabMenu;

	var posLocked:Checkbox;
	var gridSnapX:Stepper;
	var gridSnapY:Stepper;

	var characterCount:Stepper;
	var characterId:Stepper;
	var charIndex:DropdownMenu;
	var charAnim:DropdownMenu;
	var charPositionText:FlxText;
	var charFlip:Checkbox;
	var charLayer:Stepper;
	var charScaleX:Stepper;
	var charScaleY:Stepper;
	var charScrollX:Stepper;
	var charScrollY:Stepper;
	var charCamX:Stepper;
	var charCamY:Stepper;
	var charCamAbsolute:Checkbox;

	var pieceList:ObjectMenu = null;
	var pieceId:InputText;
	var typesList:Array<Array<String>> = [[],[]];
	var typeDropdown:DropdownMenu;
	var imageDropdown:DropdownMenu;
	var pieceScrollX:Stepper;
	var pieceScrollY:Stepper;
	var pieceFlipX:Checkbox;
	var pieceFlipY:Checkbox;
	var pieceVisible:Checkbox;
	var pieceScaleX:Stepper;
	var pieceScaleY:Stepper;
	var pieceUpdateHitbox:Checkbox;
	var pieceAlign:DropdownMenu;
	var alignList:Array<String> = [
		"topleft",
		"topcenter",
		"topright",
		"middleleft",
		"middlecenter",
		"middleright",
		"bottomleft",
		"bottomcenter",
		"bottomright"
	];
	var pieceLayer:Stepper;
	var pieceAntialias:Checkbox;
	var pieceTileX:Checkbox;
	var pieceTileY:Checkbox;
	var pieceTileCountX:Stepper;
	var pieceTileCountY:Stepper;
	var pieceAlpha:Stepper;
	var pieceBlend:DropdownMenu;
	var blendList:Array<String> = [
		"normal",
		"add",
		"alpha",
		"darken",
		"difference",
		"erase",
		"hardlight",
		"invert",
		"layer",
		"lighten",
		"multiply",
		"overlay",
		"screen",
		"shader",
		"subtract"
	];

	var animName:InputText;
	var animPrefix:InputText;
	var animPrefixes:DropdownMenu;
	var animIndices:InputText;
	var animLooped:Checkbox;
	var animFPS:Stepper;
	var animOffsetX:Stepper;
	var animOffsetY:Stepper;
	var curAnimDropdown:DropdownMenu;
	var firstAnimDropdown:DropdownMenu;
	var beatAnimInput:InputText;
	var beatAnimSpeed:Stepper;

	override public function create()
	{
		camGame = new FlxCamera();
		FlxG.cameras.add(camGame);

		camFollow = new FlxObject();
		camFollow.screenCenter();
		camGame.follow(camFollow, LOCKON, 1);

		camHUD = new FlxCamera();
		camHUD.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camHUD, false);

		super.create();
		selectionShader = new ColorFade();
		selectionShader.color = FlxColor.LIME;
		selectionShader.amount = 0.25;

		if (newStage)
		{
			stageData =
			{
				searchDirs: ["stages/" + curStage + "/"],
				characters: [{position: [500, 0], camPosition: [0, 0], flip: true, scale: [1, 1], scrollFactor: [1, 1], layer: 2},
				{position: [0, 0], camPosition: [0, 0], flip: false, scale: [1, 1], scrollFactor: [1, 1], layer: 1},
				{position: [250, 0], camPosition: [0, 0], flip: false, scale: [1, 1], scrollFactor: [0.95, 0.95], layer: 0}],
				camZoom: 1,
				camFollow: [Std.int(FlxG.width / 2), Std.int(FlxG.height / 2)],
				bgColor: [0, 0, 0],
				pixelPerfect: false,
				pieces: []
			}
			if (curStage.indexOf("/") > -1)
			{
				var dir:String = curStage.substr(0, curStage.lastIndexOf("/")+1);
				stageData.searchDirs.unshift(dir + "stages/" + curStage.replace(dir, "") + "/");
			}
		}
		else
			stageData = Stage.parseStage(curStage, Paths.json("stages/" + curStage));

		camFollow.x = stageData.camFollow[0];
		camFollow.y = stageData.camFollow[1];
		camGame.bgColor = FlxColor.fromRGB(stageData.bgColor[0], stageData.bgColor[1], stageData.bgColor[2]);

		myStageGroup = new FlxSpriteGroup();
		add(myStageGroup);

		for (i in 0...stageData.characters.length)
			spawnCharacter();

		myStage = [];
		refreshStage();
		refreshSelectionShader();

		camPosText = new FlxText(10, 10, 0, "", 16);
		camPosText.font = "VCR OSD Mono";
		camPosText.borderColor = FlxColor.BLACK;
		camPosText.borderStyle = OUTLINE;
		camPosText.cameras = [camHUD];
		add(camPosText);



		tabMenu = new IsolatedTabMenu(50, 50, 250, 510);
		tabMenu.cameras = [camHUD];
		tabMenu.onTabChanged = refreshSelectionShader;
		add(tabMenu);

		var tabButtons:TabButtons = new TabButtons(0, 0, 550, ["Settings", "Characters", "Pieces", "Properties", "Animations", "Help"]);
		tabButtons.cameras = [camHUD];
		tabButtons.menu = tabMenu;
		add(tabButtons);



		var tabGroupSettings = new TabGroup();

		var loadButton:TextButton = new TextButton(10, 10, 115, 20, "Load");
		loadButton.onClicked = loadStage;
		tabGroupSettings.add(loadButton);

		var saveButton:TextButton = new TextButton(loadButton.x + 115, loadButton.y, 115, 20, "Save");
		saveButton.onClicked = saveStage;
		tabGroupSettings.add(saveButton);

		posLocked = new Checkbox(10, saveButton.y + 30, "Lock Positions", true);
		tabGroupSettings.add(posLocked);

		var camZoomStepper:Stepper = new Stepper(10, posLocked.y + 40, 230, 20, stageData.camZoom, 0.05, 0.001, 9999, 3);
		camZoomStepper.onChanged = function()
		{
			stageData.camZoom = camZoomStepper.value;
			camGame.zoom = stageData.camZoom;
		}
		tabGroupSettings.add(camZoomStepper);
		var camZoomLabel:Label = new Label("Camera Zoom:", camZoomStepper);
		tabGroupSettings.add(camZoomLabel);
		camGame.zoom = stageData.camZoom;

		var camFollowXStepper:Stepper = new Stepper(10, camZoomStepper.y + 40, 115, 20, stageData.camFollow[0], 10);
		camFollowXStepper.onChanged = function() { stageData.camFollow[0] = camFollowXStepper.valueInt; }
		tabGroupSettings.add(camFollowXStepper);
		var camFollowYStepper:Stepper = new Stepper(camFollowXStepper.x + 115, camFollowXStepper.y, 115, 20, stageData.camFollow[1], 10);
		camFollowYStepper.onChanged = function() { stageData.camFollow[1] = camFollowYStepper.valueInt; }
		tabGroupSettings.add(camFollowYStepper);
		var camFollowStepperLabel:Label = new Label("Camera Starting Position:", camFollowXStepper);
		tabGroupSettings.add(camFollowStepperLabel);

		var camTestButton:TextButton = new TextButton(10, camFollowYStepper.y + 30, 115, 20, "Test");
		camTestButton.onClicked = function() {
			camFollow.x = stageData.camFollow[0];
			camFollow.y = stageData.camFollow[1];
		};
		tabGroupSettings.add(camTestButton);

		var camSetButton:TextButton = new TextButton(camTestButton.x + 115, camTestButton.y, 115, 20, "Set");
		camSetButton.onClicked = function() {
			stageData.camFollow = [snapToGrid(camFollow.x, X), snapToGrid(camFollow.y, Y)];
			camFollowXStepper.value = stageData.camFollow[0];
			camFollowYStepper.value = stageData.camFollow[1];
		};
		tabGroupSettings.add(camSetButton);

		var pixelPerfectCheckbox:Checkbox = new Checkbox(10, camSetButton.y + 30, "Pixel Perfect", stageData.pixelPerfect);
		pixelPerfectCheckbox.onClicked = function() {
			stageData.pixelPerfect = pixelPerfectCheckbox.checked;
			for (m in myStageGroup.members)
				m.pixelPerfect = stageData.pixelPerfect;
		}
		tabGroupSettings.add(pixelPerfectCheckbox);

		var searchDirsInput:InputText = new InputText(10, pixelPerfectCheckbox.y + 40, stageData.searchDirs.join(","));
		searchDirsInput.focusGained = function() {
			searchDirsInput.text = stageData.searchDirs.join(",");
		}
		searchDirsInput.focusLost = function() {
			searchDirsInput.text = stageData.searchDirs.join(",");
		}
		searchDirsInput.callback = function(text:String, action:String) {
			stageData.searchDirs = text.split(",");

			if (stageData.searchDirs.length == 1 && stageData.searchDirs[0].trim() == "")
				stageData.searchDirs = [];
			else
			{
				for (i in 0...stageData.searchDirs.length)
				{
					if (!stageData.searchDirs[i].endsWith("/"))
						stageData.searchDirs[i] += "/";
				}
			}
		}
		tabGroupSettings.add(searchDirsInput);
		var searchDirsInputLabel:Label = new Label("Asset Directories:", searchDirsInput);
		tabGroupSettings.add(searchDirsInputLabel);

		var scriptList:Array<String> = [""];
		for (s in Paths.listFilesSub("data/stages/", ".hscript"))
			scriptList.push("stages/" + s);
		for (s in Paths.listFilesSub("data/scripts/", ".hscript"))
			scriptList.push("scripts/" + s);

		if (stageData.script == "stages/" + curStage)
			stageData.script = "";
		var scriptDropdown:DropdownMenu = new DropdownMenu(10, searchDirsInput.y + 40, 230, 20, stageData.script, scriptList, true);
		scriptDropdown.onChanged = function() {
			stageData.script = scriptDropdown.value;
		};
		tabGroupSettings.add(scriptDropdown);
		var scriptLabel:Label = new Label("Script (Optional):", scriptDropdown);
		tabGroupSettings.add(scriptLabel);

		var bgColor:TextButton = new TextButton(10, scriptDropdown.y + 30, 230, 20, "Background Color");
		bgColor.onClicked = function() {
			persistentUpdate = false;
			openSubState(new StageColorSubState(this));
		};
		tabGroupSettings.add(bgColor);

		gridSnapX = new Stepper(10, bgColor.y + 40, 115, 20, 10, 1, 1);
		tabGroupSettings.add(gridSnapX);
		gridSnapY = new Stepper(gridSnapX.x + 115, gridSnapX.y, 115, 20, 10, 1, 1);
		tabGroupSettings.add(gridSnapY);
		var gridSnapLabel:Label = new Label("Grid Snapping:", gridSnapX);
		tabGroupSettings.add(gridSnapLabel);

		tabMenu.addGroup(tabGroupSettings);



		var tabGroupCharacters = new TabGroup();

		characterCount = new Stepper(10, 20, 230, 20, stageData.characters.length, 1, 2);
		characterCount.onChanged = updateCharacterCount;
		tabGroupCharacters.add(characterCount);
		var characterCountLabel:Label = new Label("Character Slots:", characterCount);
		tabGroupCharacters.add(characterCountLabel);

		characterId = new Stepper(10, characterCount.y + 40, 230, 20, 0, 1, 0, stageData.characters.length-1);
		characterId.onChanged = function() {updateCharacterTab(); refreshSelectionShader();};
		tabGroupCharacters.add(characterId);
		var characterIdLabel:Label = new Label("Character ID:", characterId);
		tabGroupCharacters.add(characterIdLabel);

		var characterList:Array<String> = Paths.listFilesSub("data/characters/", ".json");
		charIndex = new DropdownMenu(10, characterId.y + 40, 230, 20, allCharacters[0].curCharacter, characterList, true);
		charIndex.onChanged = function() {
			if (charIndex.value != allCharacters[characterId.valueInt].curCharacter)
			{
				allCharacters[characterId.valueInt].changeCharacter(charIndex.value);
				allCharacters[characterId.valueInt].repositionCharacter(stageData.characters[characterId.valueInt].position[0], stageData.characters[characterId.valueInt].position[1]);

				var animList:Array<String> = [];
				for (a in allCharacters[characterId.valueInt].characterData.animations)
					animList.push(a.name);
				charAnim.valueList = animList;
				charAnim.value = allCharacters[characterId.valueInt].curAnimName;
			}
		}
		tabGroupCharacters.add(charIndex);
		var charIndexLabel:Label = new Label("Preview Character:", charIndex);
		tabGroupCharacters.add(charIndexLabel);

		charAnim = new DropdownMenu(10, charIndex.y + 40, 230, 20, "idle", [], true);
		charAnim.onChanged = function() {
			allCharacters[characterId.valueInt].playAnim(charAnim.value, true);
		}
		tabGroupCharacters.add(charAnim);
		var charAnimLabel:Label = new Label("Preview Animation:", charAnim);
		tabGroupCharacters.add(charAnimLabel);

		charPositionText = new FlxText(10, charAnim.y + 30, 0, "Position:", 16);
		charPositionText.color = FlxColor.BLACK;
		charPositionText.font = "VCR OSD Mono";
		tabGroupCharacters.add(charPositionText);
		updateCharacterPositionText();

		charFlip = new Checkbox(10, charPositionText.y + 40, "Left");
		charFlip.checked = stageData.characters[0].flip;
		charFlip.onClicked = function() {
			stageData.characters[characterId.valueInt].flip = charFlip.checked;
			if (allCharacters[characterId.valueInt].wasFlipped != charFlip.checked)
				allCharacters[characterId.valueInt].flip();
		}
		tabGroupCharacters.add(charFlip);

		charLayer = new Stepper(charFlip.x + 115, charFlip.y, 115, 20, stageData.characters[0].layer, 1, 0, stageData.characters.length-1);
		charLayer.onChanged = function() { stageData.characters[characterId.valueInt].layer = charLayer.valueInt; postSpawnCharacter(allCharacters[characterId.valueInt]); }
		tabGroupCharacters.add(charLayer);
		var charLayerLabel:Label = new Label("Layer:", charLayer);
		tabGroupCharacters.add(charLayerLabel);

		charScaleX = new Stepper(10, charLayer.y + 40, 115, 20, stageData.characters[0].scale[0], 0.05, 0, 9999, 3);
		charScaleX.onChanged = function() {
			stageData.characters[characterId.valueInt].scale[0] = charScaleX.value;
			allCharacters[characterId.valueInt].scaleCharacter(charScaleX.value, charScaleY.value);
		}
		tabGroupCharacters.add(charScaleX);
		charScaleY = new Stepper(charScaleX.x + 115, charScaleX.y, 115, 20, stageData.characters[0].scale[1], 0.05, 0, 9999, 3);
		charScaleY.onChanged = function() {
			stageData.characters[characterId.valueInt].scale[1] = charScaleY.value;
			allCharacters[characterId.valueInt].scaleCharacter(charScaleX.value, charScaleY.value);
		}
		tabGroupCharacters.add(charScaleY);
		var charScaleLabel:Label = new Label("Scale:", charScaleX);
		tabGroupCharacters.add(charScaleLabel);

		charScrollX = new Stepper(10, charScaleX.y + 40, 115, 20, stageData.characters[0].scrollFactor[0], 0.05, 0, 9999, 3);
		charScrollX.onChanged = function() { stageData.characters[characterId.valueInt].scrollFactor[0] = charScrollX.value; allCharacters[characterId.valueInt].scrollFactor.x = charScrollX.value; }
		tabGroupCharacters.add(charScrollX);
		charScrollY = new Stepper(charScrollX.x + 115, charScrollX.y, 115, 20, stageData.characters[0].scrollFactor[1], 0.05, 0, 9999, 3);
		charScrollY.onChanged = function() { stageData.characters[characterId.valueInt].scrollFactor[1] = charScrollY.value; allCharacters[characterId.valueInt].scrollFactor.y = charScrollY.value; }
		tabGroupCharacters.add(charScrollY);
		var charScrollLabel:Label = new Label("Scroll Factor:", charScrollX);
		tabGroupCharacters.add(charScrollLabel);

		charCamX = new Stepper(10, charScrollX.y + 40, 115, 20, stageData.characters[0].camPosition[0], 10);
		charCamX.onChanged = function() { stageData.characters[characterId.valueInt].camPosition[0] = charCamX.valueInt; }
		tabGroupCharacters.add(charCamX);
		charCamY = new Stepper(charCamX.x + 115, charCamX.y, 115, 20, stageData.characters[0].camPosition[1], 10);
		charCamY.onChanged = function() { stageData.characters[characterId.valueInt].camPosition[1] = charCamY.valueInt; }
		tabGroupCharacters.add(charCamY);
		var charCamLabel:Label = new Label("Camera Offset:", charCamX);
		tabGroupCharacters.add(charCamLabel);

		charCamAbsolute = new Checkbox(10, charCamX.y + 30, "Absolute");
		charCamAbsolute.checked = stageData.characters[0].camPosAbsolute;
		charCamAbsolute.onClicked = function() { stageData.characters[characterId.valueInt].camPosAbsolute = charCamAbsolute.checked; }
		tabGroupCharacters.add(charCamAbsolute);

		var camTestCharButton:TextButton = new TextButton(10, charCamAbsolute.y + 30, 115, 20, "Test");
		camTestCharButton.onClicked = function() {
			if (stageData.characters[characterId.valueInt].camPosAbsolute)
			{
				camFollow.x = stageData.characters[characterId.valueInt].camPosition[0];
				camFollow.y = stageData.characters[characterId.valueInt].camPosition[1];
			}
			else
			{
				camFollow.x = allCharacters[characterId.valueInt].getMidpoint().x + (allCharacters[characterId.valueInt].characterData.camPosition[0] * (stageData.characters[characterId.valueInt].flip ? -1 : 1)) + stageData.characters[characterId.valueInt].camPosition[0];
				camFollow.y = allCharacters[characterId.valueInt].getMidpoint().y + allCharacters[characterId.valueInt].characterData.camPosition[1] + stageData.characters[characterId.valueInt].camPosition[1];
			}
		};
		tabGroupCharacters.add(camTestCharButton);

		var camSetCharButton:TextButton = new TextButton(camTestCharButton.x + 115, camTestCharButton.y, 115, 20, "Set");
		camSetCharButton.onClicked = function() {
			if (stageData.characters[characterId.valueInt].camPosAbsolute)
				stageData.characters[characterId.valueInt].camPosition = [Std.int(camFollow.x), Std.int(camFollow.y)];
			else
			{
				var followPos:Array<Int> = [Std.int(camFollow.x), Std.int(camFollow.y)];
				followPos[0] -= Std.int(allCharacters[characterId.valueInt].characterData.camPosition[0] * (stageData.characters[characterId.valueInt].flip ? -1 : 1));
				followPos[0] -= Std.int(allCharacters[characterId.valueInt].getMidpoint().x);
				followPos[1] -= Std.int(allCharacters[characterId.valueInt].characterData.camPosition[1]);
				followPos[1] -= Std.int(allCharacters[characterId.valueInt].getMidpoint().y);
				stageData.characters[characterId.valueInt].camPosition = followPos;
			}

			charCamX.value = stageData.characters[characterId.valueInt].camPosition[0];
			charCamY.value = stageData.characters[characterId.valueInt].camPosition[1];
		};
		tabGroupCharacters.add(camSetCharButton);

		tabMenu.addGroup(tabGroupCharacters);



		var tabGroupPieces = new TabGroup();

		pieceList = new ObjectMenu(10, 10, 230, 200, 0, []);
		pieceList.onChanged = function() {
			curStagePiece = pieceList.value;

			updatePieceTabVisibility();
			updatePieceTab();
			updateAnimationTab();
			refreshSelectionShader();
		}
		tabGroupPieces.add(pieceList);
		refreshStagePieces();

		var movePieceUpButton:TextButton = new TextButton(10, pieceList.y + 220, 115, 20, "Move Up");
		movePieceUpButton.onClicked = function() {
			if (curStagePiece > 0)
				movePiece(-1);
		};
		tabGroupPieces.add(movePieceUpButton);

		var movePieceDownButton:TextButton = new TextButton(movePieceUpButton.x + 115, movePieceUpButton.y, 115, 20, "Move Down");
		movePieceDownButton.onClicked = function() {
			if (curStagePiece < stageData.pieces.length - 1)
				movePiece(1);
		};
		tabGroupPieces.add(movePieceDownButton);
		var movePieceLabel:Label = new Label("Move Piece:", movePieceUpButton);
		tabGroupPieces.add(movePieceLabel);

		pieceId = new InputText(10, movePieceDownButton.y + 40);
		tabGroupPieces.add(pieceId);
		var pieceIdLabel:Label = new Label("ID (Optional):", pieceId);
		tabGroupPieces.add(pieceIdLabel);

		typesList = [[],[]];
		for (t in Paths.text("stagePieceTypes").replace("\r","").split("\n"))
		{
			var type:Array<String> = t.split("|");
			var pass:Bool = false;
			switch (type[1])
			{
				case "static": pass = Paths.hscriptExists("data/scripts/FlxSprite/" + type[0]);
				case "animated": pass = Paths.hscriptExists("data/scripts/AnimatedSprite/" + type[0]);
				case "group": pass = Paths.hscriptExists("data/scripts/FlxSpriteGroup/" + type[0]);
				case "basetype": pass = true;
			}
			if (pass)
			{
				typesList[0].push(type[0]);
				typesList[1].push(type[1]);
			}
		}

		typeDropdown = new DropdownMenu(10, pieceId.y + 40, 230, 20, typesList[0][0], typesList[0]);
		tabGroupPieces.add(typeDropdown);
		var typeLabel:Label = new Label("Type:", typeDropdown);
		tabGroupPieces.add(typeLabel);

		var imageList:Array<String> = [];
		for (s in stageData.searchDirs)
			imageList = imageList.concat(Paths.listFilesSub("images/" + s, ".png"));
		imageDropdown = new DropdownMenu(10, typeDropdown.y + 40, 230, 20, imageList[0], imageList, true);
		tabGroupPieces.add(imageDropdown);
		var imageLabel:Label = new Label("Asset:", imageDropdown);
		tabGroupPieces.add(imageLabel);

		var addPieceButton:TextButton = new TextButton(10, imageDropdown.y + 30, 230, 20, "Add Piece");
		addPieceButton.onClicked = function() { addPiece(false); };
		tabGroupPieces.add(addPieceButton);

		var insertPieceButton:TextButton = new TextButton(10, addPieceButton.y + 30, 230, 20, "Insert Piece");
		insertPieceButton.onClicked = function() { addPiece(true); };
		tabGroupPieces.add(insertPieceButton);

		tabMenu.addGroup(tabGroupPieces);



		var tabGroupProperties = new TabGroup();

		pieceScrollX = new Stepper(10, 20, 115, 20, 1, 0.05, 0, 9999, 3);
		pieceScrollX.onChanged = updateCurrentPiece;
		tabGroupProperties.add(pieceScrollX);
		pieceScrollY = new Stepper(pieceScrollX.x + 115, pieceScrollX.y, 115, 20, 1, 0.05, 0, 9999, 3);
		pieceScrollY.onChanged = updateCurrentPiece;
		tabGroupProperties.add(pieceScrollY);
		var pieceScrollLabel:Label = new Label("Scroll Factor:", pieceScrollX);
		tabGroupProperties.add(pieceScrollLabel);

		pieceVisible = new Checkbox(10, pieceScrollX.y + 30, "Starts Visible", true);
		pieceVisible.onClicked = updateCurrentPiece;
		tabGroupProperties.add(pieceVisible);

		pieceFlipX = new Checkbox(10, pieceVisible.y + 30, "Flip X", false);
		pieceFlipX.onClicked = updateCurrentPiece;
		tabGroupProperties.add(pieceFlipX);

		pieceFlipY = new Checkbox(pieceFlipX.x + 115, pieceFlipX.y, "Flip Y", false);
		pieceFlipY.onClicked = updateCurrentPiece;
		tabGroupProperties.add(pieceFlipY);

		pieceScaleX = new Stepper(10, pieceFlipX.y + 40, 115, 20, 1, 0.05, 0, 9999, 3);
		pieceScaleX.onChanged = updateCurrentPiece;
		tabGroupProperties.add(pieceScaleX);
		pieceScaleY = new Stepper(pieceScaleX.x + 115, pieceScaleX.y, 115, 20, 1, 0.05, 0, 9999, 3);
		pieceScaleY.onChanged = updateCurrentPiece;
		tabGroupProperties.add(pieceScaleY);
		var pieceScaleLabel:Label = new Label("Scale:", pieceScaleX);
		tabGroupProperties.add(pieceScaleLabel);

		pieceUpdateHitbox = new Checkbox(10, pieceScaleX.y + 30, "Update Hitbox", true);
		pieceUpdateHitbox.onClicked = updateCurrentPiece;
		tabGroupProperties.add(pieceUpdateHitbox);

		pieceAlign = new DropdownMenu(10, pieceUpdateHitbox.y + 40, 115, 20, alignList[0], alignList);
		pieceAlign.onChanged = updateCurrentPiece;
		tabGroupProperties.add(pieceAlign);
		var pieceAlignLabel:Label = new Label("Alignment:", pieceAlign);
		tabGroupProperties.add(pieceAlignLabel);

		pieceLayer = new Stepper(pieceAlign.x + 115, pieceAlign.y, 115, 20, 0, 1, 0, stageData.characters.length);
		pieceLayer.onChanged = updateCurrentPiecePosition;
		tabGroupProperties.add(pieceLayer);
		var pieceLayerLabel:Label = new Label("Layer:", pieceLayer);
		tabGroupProperties.add(pieceLayerLabel);

		pieceAntialias = new Checkbox(10, pieceAlign.y + 30, "Antialias", true);
		pieceAntialias.onClicked = updateCurrentPiece;
		tabGroupProperties.add(pieceAntialias);

		pieceTileX = new Checkbox(10, pieceAntialias.y + 30, "Tile X", true);
		pieceTileX.onClicked = updateCurrentPiece;
		tabGroupProperties.add(pieceTileX);
		pieceTileY = new Checkbox(pieceTileX.x + 115, pieceTileX.y, "Tile Y", true);
		pieceTileY.onClicked = updateCurrentPiece;
		tabGroupProperties.add(pieceTileY);

		pieceTileCountX = new Stepper(10, pieceTileX.y + 40, 115, 20, 1, 1, 1);
		pieceTileCountX.onChanged = updateCurrentPiece;
		tabGroupProperties.add(pieceTileCountX);
		pieceTileCountY = new Stepper(pieceTileCountX.x + 115, pieceTileCountX.y, 115, 20, 1, 1, 1);
		pieceTileCountY.onChanged = updateCurrentPiece;
		tabGroupProperties.add(pieceTileCountY);
		var pieceTileCountLabel:Label = new Label("Tile Count:", pieceTileCountX);
		tabGroupProperties.add(pieceTileCountLabel);

		pieceAlpha = new Stepper(10, pieceTileCountX.y + 40, 115, 20, 1, 0.1, 0, 1, 3);
		pieceAlpha.onChanged = updateCurrentPiece;
		tabGroupProperties.add(pieceAlpha);
		var pieceAlphaLabel:Label = new Label("Alpha:", pieceAlpha);
		tabGroupProperties.add(pieceAlphaLabel);

		pieceBlend = new DropdownMenu(pieceAlpha.x + 115, pieceAlpha.y, 115, 20, blendList[0], blendList);
		pieceBlend.onChanged = updateCurrentPiece;
		tabGroupProperties.add(pieceBlend);
		var pieceBlendLabel:Label = new Label("Blend Mode:", pieceBlend);
		tabGroupProperties.add(pieceBlendLabel);

		tabMenu.addGroup(tabGroupProperties);
		updatePieceTabVisibility();



		var tabGroupAnims = new TabGroup();

		animName = new InputText(10, 20);
		tabGroupAnims.add(animName);
		var animNameLabel:Label = new Label("Animation Name:", animName);
		tabGroupAnims.add(animNameLabel);

		animPrefix = new InputText(10, animName.y + 40);
		tabGroupAnims.add(animPrefix);
		var animPrefixLabel:Label = new Label("Prefix:", animPrefix);
		tabGroupAnims.add(animPrefixLabel);

		animPrefixes = new DropdownMenu(10, animPrefix.y + 30, 230, 20, "", [""], true);
		animPrefixes.onChanged = function() {
			animPrefix.text = animPrefixes.value;
		}
		tabGroupAnims.add(animPrefixes);

		animIndices = new InputText(10, animPrefixes.y + 40);
		tabGroupAnims.add(animIndices);
		var animIndicesLabel:Label = new Label("Indices (Optional):", animIndices);
		tabGroupAnims.add(animIndicesLabel);

		animLooped = new Checkbox(10, animIndices.y + 40, "Loop");
		animLooped.checked = false;
		tabGroupAnims.add(animLooped);

		animFPS = new Stepper(animLooped.x + 115, animLooped.y, 115, 20, 24, 1, 0, 9999);
		tabGroupAnims.add(animFPS);
		var animFPSLabel:Label = new Label("FPS:", animFPS);
		tabGroupAnims.add(animFPSLabel);

		animOffsetX = new Stepper(10, animLooped.y + 40, 115, 20);
		tabGroupAnims.add(animOffsetX);
		animOffsetY = new Stepper(animOffsetX.x + 115, animOffsetX.y, 115, 20);
		tabGroupAnims.add(animOffsetY);
		var animOffsetLabel:Label = new Label("Offsets:", animOffsetX);
		tabGroupAnims.add(animOffsetLabel);

		var addAnimButton:TextButton = new TextButton(10, animOffsetX.y + 30, 230, 20, "Add/Update Animation");
		addAnimButton.onClicked = function()
		{
			if (stageData.pieces[curStagePiece].type == "animated")
			{
				if (!sparrowExists(stageData.pieces[curStagePiece].asset) && animIndices.text.trim() == "")
					return;

				var newAnim:StageAnimation =
				{
					name: animName.text,
					prefix: animPrefix.text,
					fps: animFPS.valueInt,
					loop: animLooped.checked
				};

				if (animIndices.text.trim() != "")
				{
					newAnim.indices = [];
					var indicesSplit:Array<String> = animIndices.text.trim().split(",");
					for (i in indicesSplit)
						newAnim.indices.push(Std.parseInt(i));
				}

				if (animOffsetX.value != 0 || animOffsetY.value != 0)
					newAnim.offsets = [animOffsetX.valueInt, animOffsetY.valueInt];

				var animToReplace:Int = -1;
				for (i in 0...stageData.pieces[curStagePiece].animations.length)
				{
					if (stageData.pieces[curStagePiece].animations[i].name == newAnim.name)
						animToReplace = i;
				}

				if (animToReplace > -1)
					stageData.pieces[curStagePiece].animations[animToReplace] = newAnim;
				else
					stageData.pieces[curStagePiece].animations.push(newAnim);

				if (sparrowExists(stageData.pieces[curStagePiece].asset))
				{
					if (newAnim.indices != null && newAnim.indices.length > 0)
						myStage[curStagePiece].animation.addByIndices(newAnim.name, newAnim.prefix, newAnim.indices, "", newAnim.fps, newAnim.loop);
					else
						myStage[curStagePiece].animation.addByPrefix(newAnim.name, newAnim.prefix, newAnim.fps, newAnim.loop);
				}
				else
					myStage[curStagePiece].animation.add(newAnim.name, newAnim.indices, newAnim.fps, newAnim.loop);

				var aPiece:AnimatedSprite = cast myStage[curStagePiece];
				if (animOffsetX.value != 0 || animOffsetY.value != 0)
					aPiece.addOffsets(newAnim.name, newAnim.offsets);
				else if (animToReplace > -1)
					aPiece.addOffsets(newAnim.name, [0, 0]);

				myStage[curStagePiece].animation.play(newAnim.name, true);
				var pieceAnimList:Array<String> = [];
				for (anim in stageData.pieces[curStagePiece].animations)
					pieceAnimList.push(anim.name);
				curAnimDropdown.valueList = pieceAnimList;
				curAnimDropdown.value = newAnim.name;
				firstAnimDropdown.valueList = pieceAnimList;
				if (stageData.pieces[curStagePiece].firstAnimation == "")
				{
					stageData.pieces[curStagePiece].firstAnimation = newAnim.name;
					firstAnimDropdown.value = newAnim.name;
				}
			}
		};
		tabGroupAnims.add(addAnimButton);

		curAnimDropdown = new DropdownMenu(10, addAnimButton.y + 40, 230, 20, "", [""], true);
		curAnimDropdown.onChanged = function() {
			if (curAnimDropdown.value != "")
			{
				myStage[curStagePiece].animation.play(curAnimDropdown.value, true);

				var animData:StageAnimation = null;
				for (anim in stageData.pieces[curStagePiece].animations)
				{
					if (curAnimDropdown.value == anim.name)
						animData = anim;
				}

				animName.text = animData.name;
				animPrefix.text = animData.prefix;
				if (animData.indices != null && animData.indices.length > 0)
					animIndices.text = animData.indices.join(",");
				else
					animIndices.text = "";
				animLooped.checked = animData.loop;
				animFPS.value = animData.fps;
				if (animData.offsets != null && animData.offsets.length == 2)
				{
					animOffsetX.value = animData.offsets[0];
					animOffsetY.value = animData.offsets[1];
				}
				else
				{
					animOffsetX.value = 0;
					animOffsetY.value = 0;
				}
			}
		}
		tabGroupAnims.add(curAnimDropdown);
		var curAnimDropdownLabel:Label = new Label("Current Animation:", curAnimDropdown);
		tabGroupAnims.add(curAnimDropdownLabel);

		firstAnimDropdown = new DropdownMenu(10, curAnimDropdown.y + 40, 230, 20, "", [""], true);
		firstAnimDropdown.onChanged = function() {
			if (firstAnimDropdown.value != "")
				stageData.pieces[curStagePiece].firstAnimation = firstAnimDropdown.value;
		}
		tabGroupAnims.add(firstAnimDropdown);
		var firstAnimDropdownLabel:Label = new Label("First Animation:", firstAnimDropdown);
		tabGroupAnims.add(firstAnimDropdownLabel);

		beatAnimInput = new InputText(10, firstAnimDropdown.y + 40);
		beatAnimInput.focusLost = function() {
			if (stageData.pieces[curStagePiece].idles == null)
				beatAnimInput.text = "";
			else
				beatAnimInput.text = stageData.pieces[curStagePiece].idles.join(",");
		}
		beatAnimInput.callback = function(text:String, action:String) {
			if (stageData.pieces[curStagePiece].type == "animated")
			{
				if (text.trim() == "")
				{
					if (Reflect.hasField(stageData.pieces[curStagePiece], "idles"))
						Reflect.deleteField(stageData.pieces[curStagePiece], "idles");
				}
				else
				{
					stageData.pieces[curStagePiece].idles = text.split(",");
					var poppers:Array<String> = [];
					var pieceAnimLowerList:Array<String> = [];
					for (a in firstAnimDropdown.valueList)
						pieceAnimLowerList.push(a.toLowerCase());

					for (i in 0...stageData.pieces[curStagePiece].idles.length)
					{
						if (!pieceAnimLowerList.contains(stageData.pieces[curStagePiece].idles[i].toLowerCase()))
							poppers.push(stageData.pieces[curStagePiece].idles[i]);
						else if (!firstAnimDropdown.valueList.contains(stageData.pieces[curStagePiece].idles[i]))
							stageData.pieces[curStagePiece].idles[i] = firstAnimDropdown.valueList[pieceAnimLowerList.indexOf(stageData.pieces[curStagePiece].idles[i].toLowerCase())];
					}

					for (p in poppers)
						stageData.pieces[curStagePiece].idles.remove(p);
				}
			}
		}
		tabGroupAnims.add(beatAnimInput);
		var beatAnimInputLabel:Label = new Label("Beat Animations (Optional):", beatAnimInput);
		tabGroupAnims.add(beatAnimInputLabel);

		beatAnimSpeed = new Stepper(10, beatAnimInput.y + 40, 230, 20, 1, 0.25, 0.25, 9999, 2);
		beatAnimSpeed.onChanged = function() {
			if (stageData.pieces[curStagePiece].type == "animated")
			{
				if (beatAnimSpeed.value == 1)
					Reflect.deleteField(stageData.pieces[curStagePiece], "beatAnimationSpeed");
				else
					stageData.pieces[curStagePiece].beatAnimationSpeed = beatAnimSpeed.value;
			}
		}
		tabGroupAnims.add(beatAnimSpeed);
		var beatAnimSpeedLabel:Label = new Label("Beat Count:", beatAnimSpeed);
		tabGroupAnims.add(beatAnimSpeedLabel);

		tabMenu.addGroup(tabGroupAnims);
		updateAnimationTab();



		var tabGroupHelp = new TabGroup();

		var help:String = Paths.text("helpText").replace("\r","").split("!StageEditor\n")[1].split("\n\n")[0];
		var helpText:FlxText = new FlxText(10, 10, 230, help + "\n", 12);
		helpText.color = FlxColor.BLACK;
		helpText.font = "VCR OSD Mono";
		tabGroupHelp.add(helpText);

		tabMenu.addGroup(tabGroupHelp);
	}

	function addToStageGroup(pos:Int, spr:FlxSprite)
	{
		var prevScrollFactor:Array<Float> = [spr.scrollFactor.x, spr.scrollFactor.y];
		myStageGroup.insert(pos, spr);
		spr.scrollFactor.set(prevScrollFactor[0], prevScrollFactor[1]);
		spr.pixelPerfect = stageData.pixelPerfect;
	}

	function snapToGrid(val:Float, axis:FlxAxes):Int
	{
		if (axis == Y)
			return Std.int(Math.round(val / gridSnapY.value) * gridSnapY.value);
		return Std.int(Math.round(val / gridSnapX.value) * gridSnapX.value);
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
			saveStage();

		super.update(elapsed);

		var camPosString:String = "Camera X: "+Std.string(camFollow.x)+"\nCamera Y: "+Std.string(camFollow.y)+"\nCamera Z: "+Std.string(camGame.zoom);
		if (tabMenu.curTab == 1)
			camPosString += "\nCharacter X: " + Std.string(allCharacters[characterId.valueInt].x) + "\nCharacter Y: " + Std.string(allCharacters[characterId.valueInt].y);
		else if (stageData.pieces.length > 0)
			camPosString += "\nPiece X: " + Std.string(myStage[curStagePiece].x) + "\nPiece Y: " + Std.string(myStage[curStagePiece].y) + "\nPiece Width: " + Std.string(myStage[curStagePiece].width) + "\nPiece Height: " + Std.string(myStage[curStagePiece].height);
		if (camPosText.text != camPosString)
		{
			camPosText.text = camPosString;
			camPosText.y = FlxG.height - camPosText.height - 10;
		}

		if (movingCamera)
		{
			camFollow.x += FlxG.mouse.drag.x / camGame.zoom;
			camFollow.y += FlxG.mouse.drag.y / camGame.zoom;

			if (Options.mouseJustReleased(true))
				movingCamera = false;
		}
		else
		{
			if (Options.mouseJustPressed(true))
				movingCamera = true;
		}

		if (FlxG.mouse.wheel != 0 && !DropdownMenu.isOneActive && !ObjectMenu.isOneActive)
			camGame.zoom = Math.max(0.05, camGame.zoom + (FlxG.mouse.wheel * 0.05));

		if (movingCharacter)
		{
			dragOffset[0] += FlxG.mouse.drag.x / camGame.zoom;
			dragOffset[1] += FlxG.mouse.drag.y / camGame.zoom;
			stageData.characters[characterId.valueInt].position = [snapToGrid(dragStart[0] + dragOffset[0], X), snapToGrid(dragStart[1] + dragOffset[1], Y)];
			allCharacters[characterId.valueInt].repositionCharacter(stageData.characters[characterId.valueInt].position[0], stageData.characters[characterId.valueInt].position[1]);
			updateCharacterPositionText();

			if (Options.mouseJustReleased())
				movingCharacter = false;
		}
		else if (movingPiece)
		{
			dragOffset[0] += FlxG.mouse.drag.x / camGame.zoom;
			dragOffset[1] += FlxG.mouse.drag.y / camGame.zoom;
			stageData.pieces[curStagePiece].position = [snapToGrid(dragStart[0] + dragOffset[0], X), snapToGrid(dragStart[1] + dragOffset[1], Y)];
			myStage[curStagePiece].setPosition(stageData.pieces[curStagePiece].position[0], stageData.pieces[curStagePiece].position[1]);
			alignPiece(curStagePiece);

			if (Options.mouseJustReleased())
				movingPiece = false;
		}
		else if (Options.mouseJustPressed() && !DropdownMenu.isOneActive)
		{
			if (tabMenu.curTab == 1)
			{
				if (!posLocked.checked && !FlxG.mouse.overlaps(tabMenu, camHUD))
				{
					dragStart = Reflect.copy(stageData.characters[characterId.valueInt].position);
					dragOffset = [0, 0];
					movingCharacter = true;
				}
			}
			else if (stageData.pieces.length > 0 && !posLocked.checked && !FlxG.mouse.overlaps(tabMenu, camHUD))
			{
				dragStart = Reflect.copy(stageData.pieces[curStagePiece].position);
				dragOffset = [0, 0];
				movingPiece = true;
			}
		}

		if ((stageData.pieces.length > 0 || tabMenu.curTab == 1) && !posLocked.checked)
		{
			if (FlxG.keys.justPressed.LEFT)
				doMovement(-gridSnapX.valueInt, 0);

			if (FlxG.keys.justPressed.RIGHT)
				doMovement(gridSnapX.valueInt, 0);

			if (FlxG.keys.justPressed.UP)
				doMovement(0, -gridSnapY.valueInt);

			if (FlxG.keys.justPressed.DOWN)
				doMovement(0, gridSnapY.valueInt);
		}

		if (FlxG.keys.justPressed.DELETE && stageData.pieces.length > 0)
		{
			var confirm:Confirm = new Confirm(300, 100, "Are you sure you want to delete the current piece?", this);
			confirm.yesFunc = function() {
				deletePiece();
			}
			confirm.cameras = [camHUD];
		}

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new EditorMenuState());
	}

	function addPiece(?insert:Bool = false)
	{
		var pieceToReplace:Int = -1;
		var checkId = imageDropdown.value;
		if (pieceId.text != null && pieceId.text != "")
			checkId = pieceId.text;
		for (i in 0...stageData.pieces.length)
		{
			var matchId:String = stageData.pieces[i].asset;
			if (stageData.pieces[i].id != null && stageData.pieces[i].id != "")
				matchId = stageData.pieces[i].id;
			if (checkId == matchId)
				pieceToReplace = i;
		}

		if (pieceToReplace > -1)
		{
			var notify:Notify = new Notify(300, 100, "A piece with that " + (pieceId.text == "" ? "asset" : "id") + " already exists.", this);
			notify.cameras = [camHUD];
		}
		else if ((typeDropdown.value == "group" || typesList[1][typeDropdown.valueInt] == "group") && pieceId.text == "")
		{
			var notify:Notify = new Notify(300, 100, "A piece of type 'group' must have an id.", this);
			notify.cameras = [camHUD];
		}
		else
		{
			var newPiece:StagePiece =
			{
				type: (typesList[1][typeDropdown.valueInt] == "basetype" ? typeDropdown.value : typesList[1][typeDropdown.valueInt]),
				asset: imageDropdown.value,
				position: [0, 0],
				antialias: pieceAntialias.checked,
				layer: pieceLayer.valueInt
			};

			if (pieceId.text != "")
				newPiece.id = pieceId.text;

			if (stageData.pieces.length > 0 && curStagePiece < stageData.pieces.length)
				newPiece.position = [stageData.pieces[curStagePiece].position[0], stageData.pieces[curStagePiece].position[1]];

			if (typesList[1][typeDropdown.valueInt] != "basetype")
				newPiece.scriptClass = typeDropdown.value;

			if (newPiece.type == "animated")
			{
				newPiece.animations = [];
				newPiece.firstAnimation = "";
				if (!sparrowExists(newPiece.asset))
					newPiece.tileCount = [1, 1];
			}

			if (insert)
				stageData.pieces.insert(curStagePiece, newPiece);
			else
			{
				stageData.pieces.push(newPiece);
				curStagePiece = stageData.pieces.length - 1;
				pieceList.value = curStagePiece;
			}

			addToStage(curStagePiece, false);
			updateCurrentPiece();
			refreshStagePieces();
			updatePieceTabVisibility();
			updateAnimationTab();
			refreshSelectionShader();
		}
	}

	function updateCurrentPiece()
	{
		if (stageData.pieces.length <= 0) return;

		var piece:StagePiece = stageData.pieces[curStagePiece];

		piece.antialias = pieceAntialias.checked;
		piece.layer = pieceLayer.valueInt;

		if (pieceVisible.checked)
			Reflect.deleteField(piece, "visible");
		else
			piece.visible = false;

		if (pieceScaleX.value != 1 || pieceScaleY.value != 1)
		{
			piece.scale = [pieceScaleX.value, pieceScaleY.value];
			piece.updateHitbox = pieceUpdateHitbox.checked;
		}
		else
		{
			Reflect.deleteField(piece, "scale");
			Reflect.deleteField(piece, "updateHitbox");
		}

		if (pieceAlign.value != alignList[0])
			piece.align = pieceAlign.value;
		else
			Reflect.deleteField(piece, "align");

		if (pieceScrollX.value != 1 || pieceScrollY.value != 1)
			piece.scrollFactor = [pieceScrollX.value, pieceScrollY.value];
		else
			Reflect.deleteField(piece, "scrollFactor");

		if (pieceFlipX.checked || pieceFlipY.checked)
			piece.flip = [pieceFlipX.checked, pieceFlipY.checked];
		else
			Reflect.deleteField(piece, "flip");

		if (pieceAlpha.value != 1)
			piece.alpha = pieceAlpha.value;
		else
			Reflect.deleteField(piece, "alpha");

		if (pieceBlend.value != blendList[0])
			piece.blend = pieceBlend.value;
		else
			Reflect.deleteField(piece, "blend");

		if (piece.type == "tiled")
			piece.tile = [pieceTileX.checked, pieceTileY.checked];
		else
			Reflect.deleteField(piece, "tile");

		if (piece.type == "animated" && !sparrowExists(piece.asset))
			piece.tileCount = [pieceTileCountX.valueInt, pieceTileCountY.valueInt];
		else
			Reflect.deleteField(piece, "tileCount");

		assignPieceParams(curStagePiece);
	}

	function updateCurrentPiecePosition()
	{
		if (stageData.pieces.length <= 0) return;

		var piece:StagePiece = stageData.pieces[curStagePiece];
		piece.layer = pieceLayer.valueInt;

		updatePiece(curStagePiece);
	}

	function updateCharacterPositionText()
	{
		charPositionText.text = "Position: " + Std.string(stageData.characters[characterId.valueInt].position);
	}

	function doMovement(xDir:Int, yDir:Int)
	{
		if (tabMenu.curTab == 1)
		{
			stageData.characters[characterId.valueInt].position[0] += xDir;
			stageData.characters[characterId.valueInt].position[1] += yDir;
			allCharacters[characterId.valueInt].repositionCharacter(stageData.characters[characterId.valueInt].position[0], stageData.characters[characterId.valueInt].position[1]);
			updateCharacterPositionText();
		}
		else
		{
			stageData.pieces[curStagePiece].position[0] += xDir;
			stageData.pieces[curStagePiece].position[1] += yDir;
			myStage[curStagePiece].x = stageData.pieces[curStagePiece].position[0];
			myStage[curStagePiece].y = stageData.pieces[curStagePiece].position[1];
			alignPiece(curStagePiece);
		}
	}

	function deletePiece()
	{
		var toRemove:FlxSprite = myStage.splice(curStagePiece, 1)[0];
		remove(toRemove, true);
		toRemove.kill();
		toRemove.destroy();

		stageData.pieces.remove(stageData.pieces[curStagePiece]);
		if (curStagePiece > 0 && stageData.pieces.length >= curStagePiece)
			curStagePiece--;

		refreshStage();
		refreshStagePieces();
		updatePieceTabVisibility();
		refreshSelectionShader();
	}

	function updateCharacterCount()
	{
		if (characterCount.valueInt < stageData.characters.length)
		{
			stageData.characters.resize(characterCount.valueInt);
			while (allCharacters.length > stageData.characters.length)
			{
				remove(allCharacters[allCharacters.length-1], true);
				allCharacters[allCharacters.length-1].kill();
				allCharacters[allCharacters.length-1].destroy();
				allCharacters.pop();
			}
			for (i in 0...stageData.characters.length)
			{
				if (stageData.characters[i].layer > characterCount.valueInt-1)
					stageData.characters[i].layer = characterCount.valueInt-1;
			}
			if (characterCount.valueInt-1 < characterId.valueInt)
			{
				characterId.value = characterCount.value-1;
				characterId.onChanged();
			}
		}
		else
		{
			while (characterCount.valueInt > stageData.characters.length)
			{
				var oldChar:StageCharacter = stageData.characters[stageData.characters.length-1];
				var char:StageCharacter = Reflect.copy(oldChar);
				char.position = oldChar.position.copy();
				char.camPosition = oldChar.camPosition.copy();
				char.scale = oldChar.scale.copy();
				char.scrollFactor = oldChar.scrollFactor.copy();

				stageData.characters.push(char);
			}

			while (allCharacters.length < stageData.characters.length)
				spawnCharacter();
		}
		characterId.maxVal = characterCount.value-1;
		charLayer.maxVal = characterCount.value-1;
		pieceLayer.maxVal = characterCount.value;
	}

	function updateCharacterTab()
	{
		charIndex.value = allCharacters[characterId.valueInt].curCharacter;

		var animList:Array<String> = [];
		for (a in allCharacters[characterId.valueInt].characterData.animations)
			animList.push(a.name);
		charAnim.valueList = animList;
		charAnim.value = allCharacters[characterId.valueInt].curAnimName;

		updateCharacterPositionText();
		var c:StageCharacter = stageData.characters[characterId.valueInt];
		charFlip.checked = c.flip;
		charLayer.value = c.layer;
		charScaleX.value = c.scale[0];
		charScaleY.value = c.scale[1];
		charScrollX.value = c.scrollFactor[0];
		charScrollY.value = c.scrollFactor[1];
		charCamX.value = c.camPosition[0];
		charCamY.value = c.camPosition[1];
		charCamAbsolute.checked = c.camPosAbsolute;
	}

	function updatePieceTabVisibility()
	{
		if (stageData.pieces.length > 0 && curStagePiece < stageData.pieces.length)
		{
			pieceVisible.visible = (stageData.pieces[curStagePiece].type != "group");
			pieceScaleX.visible = (stageData.pieces[curStagePiece].type != "group");
			pieceScaleY.visible = (stageData.pieces[curStagePiece].type != "group");
			pieceUpdateHitbox.visible = (stageData.pieces[curStagePiece].type != "group");
			pieceAlign.visible = (stageData.pieces[curStagePiece].type != "group" && stageData.pieces[curStagePiece].type != "tiled");
			pieceAntialias.visible = (stageData.pieces[curStagePiece].type != "group");
			pieceTileX.visible = (stageData.pieces[curStagePiece].type == "tiled");
			pieceTileY.visible = (stageData.pieces[curStagePiece].type == "tiled");
			pieceTileCountX.visible = (stageData.pieces[curStagePiece].type == "animated" && !sparrowExists(stageData.pieces[curStagePiece].asset));
			pieceTileCountY.visible = pieceTileCountX.visible;
			pieceAlpha.visible = (stageData.pieces[curStagePiece].type != "group");
			pieceBlend.visible = (stageData.pieces[curStagePiece].type != "group");
		}
		else
		{
			pieceVisible.visible = false;
			pieceScaleX.visible = false;
			pieceScaleY.visible = false;
			pieceUpdateHitbox.visible = false;
			pieceAlign.visible = false;
			pieceAntialias.visible = false;
			pieceTileX.visible = false;
			pieceTileY.visible = false;
			pieceTileCountX.visible = false;
			pieceTileCountY.visible = false;
			pieceAlpha.visible = false;
			pieceBlend.visible = false;
		}
	}

	function updatePieceTab()
	{
		if (stageData.pieces[curStagePiece].id == null)
			pieceId.text = "";
		else
			pieceId.text = stageData.pieces[curStagePiece].id;

		if (stageData.pieces[curStagePiece].scriptClass != null && typeDropdown.valueList.contains(stageData.pieces[curStagePiece].scriptClass))
			typeDropdown.value = stageData.pieces[curStagePiece].scriptClass;
		else
			typeDropdown.value = stageData.pieces[curStagePiece].type;

		imageDropdown.value = stageData.pieces[curStagePiece].asset;

		if (stageData.pieces[curStagePiece].scale != null && stageData.pieces[curStagePiece].scale.length == 2)
		{
			pieceScaleX.value = stageData.pieces[curStagePiece].scale[0];
			pieceScaleY.value = stageData.pieces[curStagePiece].scale[1];
		}
		else
		{
			pieceScaleX.value = 1;
			pieceScaleY.value = 1;
		}

		if (stageData.pieces[curStagePiece].scrollFactor != null && stageData.pieces[curStagePiece].scrollFactor.length == 2)
		{
			pieceScrollX.value = stageData.pieces[curStagePiece].scrollFactor[0];
			pieceScrollY.value = stageData.pieces[curStagePiece].scrollFactor[1];
		}
		else
		{
			pieceScrollX.value = 1;
			pieceScrollY.value = 1;
		}

		if (stageData.pieces[curStagePiece].flip != null && stageData.pieces[curStagePiece].flip.length == 2)
		{
			pieceFlipX.checked = stageData.pieces[curStagePiece].flip[0];
			pieceFlipY.checked = stageData.pieces[curStagePiece].flip[1];
		}
		else
		{
			pieceFlipX.checked = false;
			pieceFlipY.checked = false;
		}

		pieceLayer.value = stageData.pieces[curStagePiece].layer;

		if (stageData.pieces[curStagePiece].visible == null)
			pieceVisible.checked = true;
		else
			pieceVisible.checked = stageData.pieces[curStagePiece].visible;

		if (stageData.pieces[curStagePiece].updateHitbox != null)
			pieceUpdateHitbox.checked = stageData.pieces[curStagePiece].updateHitbox;

		if (stageData.pieces[curStagePiece].align == null || stageData.pieces[curStagePiece].align == "")
			pieceAlign.value = alignList[0];
		else
			pieceAlign.value = stageData.pieces[curStagePiece].align;

		pieceAntialias.checked = stageData.pieces[curStagePiece].antialias;

		if (stageData.pieces[curStagePiece].tile != null && stageData.pieces[curStagePiece].tile.length == 2)
		{
			pieceTileX.checked = stageData.pieces[curStagePiece].tile[0];
			pieceTileY.checked = stageData.pieces[curStagePiece].tile[1];
		}

		if (stageData.pieces[curStagePiece].tileCount != null && stageData.pieces[curStagePiece].tileCount.length == 2)
		{
			pieceTileCountX.value = stageData.pieces[curStagePiece].tileCount[0];
			pieceTileCountY.value = stageData.pieces[curStagePiece].tileCount[1];
		}

		if (stageData.pieces[curStagePiece].alpha == null)
			pieceAlpha.value = 1;
		else
			pieceAlpha.value = stageData.pieces[curStagePiece].alpha;

		if (stageData.pieces[curStagePiece].blend == null || stageData.pieces[curStagePiece].blend == "")
			pieceBlend.value = blendList[0];
		else
			pieceBlend.value = stageData.pieces[curStagePiece].blend;
	}

	function updateAnimationTab()
	{
		if (stageData.pieces.length > 0 && stageData.pieces[curStagePiece].type == "animated")
		{
			if (sparrowExists(stageData.pieces[curStagePiece].asset))
				animPrefixes.valueList = sparrowAnimations(stageData.pieces[curStagePiece].asset);
			else
				animPrefixes.valueList = [""];
			if (stageData.pieces[curStagePiece].animations.length > 0)
			{
				var pieceAnimList:Array<String> = [];
				var animData:StageAnimation = null;

				if (!sparrowExists(stageData.pieces[curStagePiece].asset))
				{
					for (anim in stageData.pieces[curStagePiece].animations)
					{
						if (!myStage[curStagePiece].animation.getNameList().contains(anim.name))
							myStage[curStagePiece].animation.add(anim.name, anim.indices, anim.fps, anim.loop);
						if (anim.name == stageData.pieces[curStagePiece].firstAnimation && myStage[curStagePiece].animation.curAnim == null)
							myStage[curStagePiece].animation.play(stageData.pieces[curStagePiece].firstAnimation);
					}
				}

				for (anim in stageData.pieces[curStagePiece].animations)
				{
					pieceAnimList.push(anim.name);
					if (myStage[curStagePiece].animation.curAnim.name == anim.name)
						animData = anim;
				}

				curAnimDropdown.valueList = pieceAnimList;
				curAnimDropdown.value = animData.name;
				firstAnimDropdown.valueList = pieceAnimList;
				firstAnimDropdown.value = stageData.pieces[curStagePiece].firstAnimation;
				if (stageData.pieces[curStagePiece].idles == null)
					beatAnimInput.text = "";
				else
					beatAnimInput.text = stageData.pieces[curStagePiece].idles.join(",");
				if (stageData.pieces[curStagePiece].beatAnimationSpeed == null)
					beatAnimSpeed.value = 1;
				else
					beatAnimSpeed.value = stageData.pieces[curStagePiece].beatAnimationSpeed;

				animName.text = animData.name;
				if (sparrowExists(stageData.pieces[curStagePiece].asset))
					animPrefix.text = animData.prefix;
				else
					animPrefix.text = "";
				if (animData.indices != null && animData.indices.length > 0)
					animIndices.text = animData.indices.join(",");
				else
					animIndices.text = "";
				animLooped.checked = animData.loop;
				animFPS.value = animData.fps;
				if (animData.offsets != null && animData.offsets.length == 2)
				{
					animOffsetX.value = animData.offsets[0];
					animOffsetY.value = animData.offsets[1];
				}
				else
				{
					animOffsetX.value = 0;
					animOffsetY.value = 0;
				}
			}
			else
			{
				curAnimDropdown.valueList = [""];
				curAnimDropdown.value = "";
				firstAnimDropdown.valueList = [""];
				firstAnimDropdown.value = "";
				beatAnimInput.text = "";
			}
		}
		else
		{
			curAnimDropdown.valueList = [""];
			curAnimDropdown.value = "";
			firstAnimDropdown.valueList = [""];
			firstAnimDropdown.value = "";
			beatAnimInput.text = "";
		}
	}

	function refreshSelectionShader()
	{
		if (tabMenu != null && tabMenu.curTab == 1)
		{
			for (i in 0...allCharacters.length)
			{
				if (i == characterId.valueInt)
					allCharacters[i].shader = selectionShader.shader;
				else
					allCharacters[i].shader = null;
			}
			if (myStage.length > 0)
			{
				for (p in myStage)
					p.shader = null;
			}
		}
		else
		{
			if (myStage.length > 0)
			{
				for (i in 0...myStage.length)
				{
					if (i == curStagePiece)
						myStage[i].shader = selectionShader.shader;
					else
						myStage[i].shader = null;
				}
			}
			if (allCharacters.length > 0)
			{
				for (p in allCharacters)
					p.shader = null;
			}
		}
	}

	function refreshStage()
	{
		for (piece in myStage)
		{
			remove(piece, true);
			piece.kill();
			piece.destroy();
		}
		myStage = [];

		for (c in allCharacters)
			postSpawnCharacter(c);

		var poppers:Array<StagePiece> = [];
		for (i in 0...stageData.pieces.length)
		{
			if (stageData.pieces[i].type == "group" || imageExists(stageData.pieces[i].asset))
				addToStage(i);
			else
				poppers.push(stageData.pieces[i]);
		}
		for (p in poppers)
			stageData.pieces.remove(p);
	}

	function spawnCharacter()
	{
		var c:StageCharacter = stageData.characters[allCharacters.length];
		var def:String = TitleState.defaultVariables.player2;
		switch (allCharacters.length)
		{
			case 0: def = TitleState.defaultVariables.player1;
			case 2: def = TitleState.defaultVariables.gf;
		}
		var newC:Character = new Character(c.position[0], c.position[1], def, c.flip);
		newC.scaleCharacter(c.scale[0], c.scale[1]);
		newC.scrollFactor.set(c.scrollFactor[0], c.scrollFactor[1]);
		allCharacters.push(newC);
		postSpawnCharacter(newC);
	}

	function postSpawnCharacter(char:Character)
	{
		if (myStageGroup.members.contains(char))
			myStageGroup.remove(char, true);

		var charData:StageCharacter = stageData.characters[allCharacters.indexOf(char)];

		var ind:Int = myStageGroup.members.length;
		for (i in 0...allCharacters.length)
		{
			if (allCharacters[i] != char && charData.layer < stageData.characters[i].layer && myStageGroup.members.contains(allCharacters[i]) && ind > myStageGroup.members.indexOf(allCharacters[i]))
				ind = myStageGroup.members.indexOf(allCharacters[i]);
		}

		for (piece in stageData.pieces)
		{
			if (charData.layer < piece.layer && myStage.length >= stageData.pieces.indexOf(piece) && myStageGroup.members.contains(myStage[stageData.pieces.indexOf(piece)]) && ind > myStageGroup.members.indexOf(myStage[stageData.pieces.indexOf(piece)]))
				ind = myStageGroup.members.indexOf(myStage[stageData.pieces.indexOf(piece)]);
		}
		addToStageGroup(ind, char);
	}

	function addToStage(index:Int, ?allowSplice:Bool = true)
	{
		var stagePiece:StagePiece = stageData.pieces[index];
		if (index < myStage.length && allowSplice)
		{
			var toRemove:FlxSprite = myStage.splice(index, 1)[0];
			remove(toRemove, true);
			toRemove.kill();
			toRemove.destroy();
		}

		var piece:FlxSprite = null;

		switch (stagePiece.type)
		{
			case "static":
				piece = new FlxSprite(image(stagePiece.asset));
				piece.active = false;

			case "animated":
				var isSparrow:Bool = false;
				var pieceFrames = null;
				if (sparrowExists(stagePiece.asset))
				{
					pieceFrames = sparrow(stagePiece.asset);
					isSparrow = true;
				}
				else
					pieceFrames = tiles(stagePiece.asset, stagePiece.tileCount[0], stagePiece.tileCount[1]);

				var aPiece:AnimatedSprite = new AnimatedSprite(pieceFrames);
				var animList:Array<String> = [];
				for (anim in stagePiece.animations)
				{
					if (isSparrow)
					{
						if (anim.indices != null && anim.indices.length > 0)
							aPiece.animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
						else
							aPiece.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
					}
					else
						aPiece.animation.add(anim.name, anim.indices, anim.fps, anim.loop);
					if (anim.offsets != null && anim.offsets.length == 2)
						aPiece.addOffsets(anim.name, anim.offsets);
					animList.push(anim.name);
				}
				if (animList.length > 0 && !animList.contains(stagePiece.firstAnimation))
					stagePiece.firstAnimation = animList[0];
				if (stagePiece.firstAnimation != null && stagePiece.firstAnimation != "")
					aPiece.animation.play(stagePiece.firstAnimation);

				piece = aPiece;

			case "tiled":
				if (stagePiece.tile == null || stagePiece.tile.length != 2)
					stagePiece.tile = [true, true];
				piece = new FlxBackdrop(image(stagePiece.asset), 1, 1, stagePiece.tile[0], stagePiece.tile[1]);

			case "group":
				piece = new FlxSpriteGroup();
		}
		myStage.insert(index, piece);
		assignPieceParams(index);
		updatePiece(index);
	}

	function assignPieceParams(pieceId:Int)
	{
		var stagePiece:StagePiece = stageData.pieces[pieceId];
		var piece:FlxSprite = myStage[pieceId];

		piece.setPosition(stagePiece.position[0], stagePiece.position[1]);

		if (!stagePiece.updateHitbox)
		{
			piece.scale.set(1, 1);
			piece.updateHitbox();
		}

		if (stagePiece.scale != null && stagePiece.scale.length == 2)
			piece.scale.set(stagePiece.scale[0], stagePiece.scale[1]);
		else
			piece.scale.set(1, 1);

		if (stagePiece.updateHitbox)
			piece.updateHitbox();

		if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
			piece.scrollFactor.set(stagePiece.scrollFactor[0], stagePiece.scrollFactor[1]);
		else
			piece.scrollFactor.set(1, 1);

		if (stagePiece.flip != null && stagePiece.flip.length == 2)
		{
			piece.flipX = stagePiece.flip[0];
			piece.flipY = stagePiece.flip[1];
		}
		else
			piece.flipX = piece.flipY = false;

		if (stagePiece.visible == null || stagePiece.visible == true)
			piece.alpha = 1;
		else
			piece.alpha = 0.3;

		piece.antialiasing = stagePiece.antialias;

		if (stagePiece.alpha != null && stagePiece.alpha != 1)
			piece.alpha *= stagePiece.alpha;

		if (stagePiece.blend != null && stagePiece.blend != "")
			piece.blend = stagePiece.blend;
		else
			piece.blend = "normal";

		if (stagePiece.type == "animated" && !sparrowExists(stagePiece.asset))
			piece.frames = tiles(stagePiece.asset, stagePiece.tileCount[0], stagePiece.tileCount[1]);

		alignPiece(pieceId);
	}

	function updateAllPieces()
	{
		for (i in 0...stageData.pieces.length)
		{
			if (i < myStage.length)
			{
				var stagePiece:StagePiece = stageData.pieces[i];
				var piece:FlxSprite = myStage[i];

				if (myStageGroup.members.contains(piece))
					myStageGroup.remove(piece, true);
			}
		}

		for (i in 0...stageData.pieces.length)
		{
			if (i < myStage.length)
			{
				var stagePiece:StagePiece = stageData.pieces[i];
				var piece:FlxSprite = myStage[i];

				var ind:Int = myStageGroup.members.length;
				for (i in 0...allCharacters.length)
				{
					if (stagePiece.layer <= stageData.characters[i].layer && myStageGroup.members.contains(allCharacters[i]) && ind > myStageGroup.members.indexOf(allCharacters[i]))
						ind = myStageGroup.members.indexOf(allCharacters[i]);
				}
				addToStageGroup(ind, piece);
			}
		}
	}

	function updatePiece(pieceId:Int)
	{
		var stagePiece:StagePiece = stageData.pieces[pieceId];
		var piece:FlxSprite = myStage[pieceId];

		if (myStageGroup.members.contains(piece))
			myStageGroup.remove(piece, true);

		var insertIndex:Int = -1;
		for (i in 0...myStage.length)
		{
			var j:Int = myStage.length-i-1;
			if (j > pieceId && stageData.pieces[j].layer == stagePiece.layer)
				insertIndex = j;
		}

		if (insertIndex >= 0 && myStageGroup.members.contains(myStage[insertIndex]))
			addToStageGroup(myStageGroup.members.indexOf(myStage[insertIndex]), piece);
		else
		{
			var ind:Int = myStageGroup.members.length;
			for (i in 0...allCharacters.length)
			{
				if (stagePiece.layer <= stageData.characters[i].layer && myStageGroup.members.contains(allCharacters[i]) && ind > myStageGroup.members.indexOf(allCharacters[i]))
					ind = myStageGroup.members.indexOf(allCharacters[i]);
			}
			addToStageGroup(ind, piece);
		}
	}

	function movePiece(dir:Int)
	{
		if (dir > 0 && stageData.pieces[curStagePiece+dir].layer > stageData.pieces[curStagePiece].layer) return;
		if (dir < 0 && stageData.pieces[curStagePiece+dir].layer < stageData.pieces[curStagePiece].layer) return;

		var movePiece:StagePiece = stageData.pieces.splice(curStagePiece, 1)[0];
		var movePieceSprite:FlxSprite = myStage.splice(curStagePiece, 1)[0];
		curStagePiece += dir;
		stageData.pieces.insert(curStagePiece, movePiece);
		myStage.insert(curStagePiece, movePieceSprite);
		pieceList.value = curStagePiece;
		updateAllPieces();
		refreshStagePieces();
		refreshSelectionShader();
	}

	function alignPiece(pieceId:Int)
	{
		var stagePiece:StagePiece = stageData.pieces[pieceId];
		var piece:FlxSprite = myStage[pieceId];
		if (stagePiece.align != null && stagePiece.align != "")
		{
			if (stagePiece.align.endsWith("center"))
				piece.x -= piece.width / 2;
			else if (stagePiece.align.endsWith("right"))
				piece.x -= piece.width;

			if (stagePiece.align.startsWith("middle"))
				piece.y -= piece.height / 2;
			else if (stagePiece.align.startsWith("bottom"))
				piece.y -= piece.height;
		}
	}

	function refreshStagePieces()
	{
		var pieceValueList:Array<String> = [];
		for (p in stageData.pieces)
		{
			var checkId = p.asset;
			if (p.id != null && p.id != "")
				checkId = p.id;
			pieceValueList.push(checkId);
		}
		if (pieceList != null)
			pieceList.valueList = pieceValueList;
	}

	function image(asset:String):FlxGraphic
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.imageExists(s + asset))
				return Paths.image(s + asset);
		}
		return null;
	}

	function imageExists(asset:String):Bool
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.imageExists(s + asset))
				return true;
		}
		return false;
	}

	function sparrow(asset:String):FlxFramesCollection
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.sparrowExists(s + asset))
				return Paths.sparrow(s + asset);
		}
		return null;
	}

	function sparrowExists(asset:String):Bool
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.sparrowExists(s + asset))
				return true;
		}
		return false;
	}

	function sparrowAnimations(asset:String):Array<String>
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.sparrowExists(s + asset))
				return Paths.sparrowAnimations(s + asset);
		}
		return [];
	}

	function tiles(asset:String, tilesX:Int, tilesY:Int):FlxFramesCollection
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.imageExists(s + asset))
				return Paths.tiles(s + asset, tilesX, tilesY);
		}
		return null;
	}



	function saveStage()
	{
		var saveData:StageData = Reflect.copy(stageData);
		saveData.characters = [];
		for (c in stageData.characters)
			saveData.characters.push(Reflect.copy(c));

		if (saveData.script == "" || saveData.script == "stages/" + curStage)
			Reflect.deleteField(saveData, "script");

		if (!saveData.pixelPerfect)
			Reflect.deleteField(saveData, "pixelPerfect");

		if (saveData.bgColor[0] == 0 && saveData.bgColor[1] == 0 && saveData.bgColor[2] == 0)
			Reflect.deleteField(saveData, "bgColor");

		var searchDirs:Array<String> = saveData.searchDirs.copy();
		searchDirs.remove("stages/" + curStage + "/");
		if (curStage.indexOf("/") > -1)
		{
			var dir:String = curStage.substr(0, curStage.lastIndexOf("/")+1);
			searchDirs.remove(dir + "stages/" + curStage.replace(dir, "") + "/");
		}
		if (searchDirs.length <= 0)
			Reflect.deleteField(saveData, "searchDirs");

		for (c in saveData.characters)
		{
			if (c.layer == saveData.characters.length - saveData.characters.indexOf(c) - 1)
				Reflect.deleteField(c, "layer");

			if (c.camPosition[0] == 0 && c.camPosition[1] == 0)
				Reflect.deleteField(c, "camPosition");

			if (!c.camPosAbsolute)
				Reflect.deleteField(c, "camPosAbsolute");

			if (c.scale[0] == 1 && c.scale[1] == 1)
				Reflect.deleteField(c, "scale");

			if (c.scrollFactor[0] == 1 && c.scrollFactor[1] == 1)
				Reflect.deleteField(c, "scrollFactor");
		}

		var data:String = Json.stringify(saveData, null, "\t");
		if (Options.options.compactJsons)
			data = Json.stringify(saveData);

		if ((data != null) && (data.length > 0))
		{
			var file:FileBrowser = new FileBrowser();
			file.save(curStage + ".json", data.trim());
		}
	}

	function loadStage()
	{
		var file:FileBrowser = new FileBrowser();
		file.loadCallback = EditorMenuState.loadStageCallback;
		file.load();
	}
}

class StageColorSubState extends FlxSubState
{
	override public function new(state:StageEditorState)
	{
		super();

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
		colorThing.color = FlxColor.fromRGB(state.stageData.bgColor[0], state.stageData.bgColor[1], state.stageData.bgColor[2]);
		tabGroupColor.add(colorThing);

		var colorSwatch:ColorSwatch = new ColorSwatch(50, 50, 140, 140, 30, colorThing.color);
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
			state.stageData.bgColor = [colorThing.color.red, colorThing.color.green, colorThing.color.blue];
			state.camGame.bgColor = colorThing.color;
			close();
		};
		tabGroupColor.add(acceptButton);

		tabMenu.addGroup(tabGroupColor);

		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}
}