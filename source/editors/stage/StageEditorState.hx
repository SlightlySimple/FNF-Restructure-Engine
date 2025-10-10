package editors.stage;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import helpers.DeepEquals;
import helpers.Cloner;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import data.ObjectData;
import data.Options;
import data.converters.BaseGameConverter;
import data.converters.PsychConverter;
import data.converters.CodenameConverter;
import data.Song;
import objects.AnimatedSprite;
import objects.Character;
import objects.Stage;
import haxe.Json;
import sys.io.File;
import menus.EditorMenuState;

import lime.app.Application;

import newui.UIControl;
import newui.InfoBox;
import newui.TopMenu;
import newui.TabMenu;
import newui.Button;
import newui.Label;
import newui.ColorPickSubstate;
import newui.Draggable;
import newui.InputText;
import newui.Checkbox;
import newui.Stepper;
import newui.DropdownMenu;
import newui.PopupWindow;

using StringTools;

class StageEditorState extends BaseEditorState
{
	var cameraZoom:Float = 0.7;

	var myStage:Array<StageEditorPiece> = [];
	var allCharacters:Array<Character> = [];
	var myStageGroup:FlxSpriteGroup;
	var hoveredObject:FlxSprite = null;

	public var stageData:StageData;
	var dataLog:Array<StageData> = [];

	var camFollow:FlxObject;
	var mousePos:FlxPoint;

	var	movingCamera:Bool = false;
	var	movingPiece:Bool = false;
	var dragStart:Array<Array<Int>> = [];
	var dragOffset:Array<Float> = [0, 0];
	var posLocked:Bool = false;

	var stagePieceList:Array<Array<Dynamic>>;
	var stagePieces:Draggable;
	var stagePieceButtons:FlxSpriteGroup = null;
	var stagePieceButtonBG:FlxSprite;
	var stagePieceBar:FlxSprite;
	var stagePieceText:FlxTypedSpriteGroup<FlxText> = null;
	var hoveredStagePiece:Int = -1;
	var hoveredStageButton:Int = -1;
	var selectedStagePieces:Array<Int> = [];
	var curStagePiece:Int = -1;
	var curCharacter:Int = -1;
	var listOffset:Int = -1;

	var stageShaders:Array<StageEditorShader> = [];

	var cameraBox:Draggable;
	var camPosText:FlxText;

	var piecePosBox:Draggable;
	var piecePosText:FlxText;

	var gridSnapX:Int = 5;
	var gridSnapY:Int = 5;

	var charAnim:DropdownMenu;

	var pieceProperties:VBoxScrollable;
	var piecePropertiesBlank:Label;
	var piecePropertiesSlot:VBox;
	var piecePropertiesGroup:VBox;
	var piecePropertiesSubSlot:VBox;
	var piecePropertiesSubGroup:VBox;
	var piecePropertiesNonSolidSlot:VBox;
	var piecePropertiesNonSolidGroup:VBox;
	var piecePropertiesSolidSlot:VBox;
	var piecePropertiesSolidGroup:VBox;
	var piecePropertiesNonTiledSlot:VBox;
	var piecePropertiesNonTiledGroup:VBox;
	var piecePropertiesTiledSlot:VBox;
	var piecePropertiesTiledGroup:VBox;
	var piecePropertiesAnimatedTiledSlot:VBox;
	var piecePropertiesAnimatedTiledGroup:VBox;
	var piecePropertiesCharacterGroup:VBox;
	var pieceParams:Array<FlxSprite> = [];

	var pieceId:InputText;
	var typesList:Array<Array<String>> = [[],[]];
	var typeDropdown:DropdownMenu;
	var imageDropdown:DropdownMenu;
	var pieceX:Stepper;
	var pieceY:Stepper;
	var pieceParamNames:Map<String, String> = new Map<String, String>();

	var pieceAnimations:VBoxScrollable;
	var pieceAnimationsBlank:Label;
	var pieceAnimationsSlot:VBox;
	var pieceAnimationsGroup:VBox;

	var allAnimData:String = "";
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

	var topmenu:TopMenu;

	override public function create()
	{
		mousePos = FlxPoint.get();

		super.create();
		filenameNew = "New Stage";

		camFollow = new FlxObject();
		camFollow.screenCenter();
		camGame.follow(camFollow, LOCKON, 1);

		if (isNew)
		{
			stageData =
			{
				fixes: 1,
				searchDirs: [],
				characters: [
					{position: [500, 0], camPosition: [0, 0], flip: true, scale: [1, 1], scrollFactor: [1, 1], layer: 2},
					{position: [0, 0], camPosition: [0, 0], flip: false, scale: [1, 1], scrollFactor: [1, 1], layer: 1},
					{position: [250, 0], camPosition: [0, 0], flip: false, scale: [1, 1], scrollFactor: [0.95, 0.95], layer: 0}
				],
				pieces: [],
				camZoom: 1,
				camFollow: [Std.int(FlxG.width / 2), Std.int(FlxG.height / 2)],
				bgColor: [0, 0, 0],
				script: "",
				pixelPerfect: false
			}
		}
		else
			stageData = Stage.parseStage(id, Paths.json("stages/" + id));

		camFollow.x = stageData.camFollow[0];
		camFollow.y = stageData.camFollow[1];
		camGame.bgColor = FlxColor.fromRGB(stageData.bgColor[0], stageData.bgColor[1], stageData.bgColor[2]);

		myStageGroup = new FlxSpriteGroup();
		add(myStageGroup);

		myStage = [];
		refreshStage();
		refreshSelectionShader();



		stagePieces = new Draggable(990, 250, "pieceBox", 50);
		stagePieces.cameras = [camHUD];
		add(stagePieces);

		stagePieceButtons = new FlxSpriteGroup();

		var pieceMoveBottomGraphic:FlxSprite = new FlxSprite(Std.int(stagePieces.width / 2) - 60, Std.int(stagePieces.height - 50), Paths.image("ui/editors/pieceMoveBottom"));
		pieceMoveBottomGraphic.color = FlxColor.BLACK;
		stagePieceButtons.add(pieceMoveBottomGraphic);

		var pieceMoveDownGraphic:FlxSprite = new FlxSprite(pieceMoveBottomGraphic.x + 30, pieceMoveBottomGraphic.y, Paths.image("ui/editors/pieceMoveDown"));
		pieceMoveDownGraphic.color = FlxColor.BLACK;
		stagePieceButtons.add(pieceMoveDownGraphic);

		var pieceMoveUpGraphic:FlxSprite = new FlxSprite(pieceMoveDownGraphic.x + 30, pieceMoveDownGraphic.y, Paths.image("ui/editors/pieceMoveUp"));
		pieceMoveUpGraphic.color = FlxColor.BLACK;
		stagePieceButtons.add(pieceMoveUpGraphic);

		var pieceMoveTopGraphic:FlxSprite = new FlxSprite(pieceMoveUpGraphic.x + 30, pieceMoveUpGraphic.y, Paths.image("ui/editors/pieceMoveTop"));
		pieceMoveTopGraphic.color = FlxColor.BLACK;
		stagePieceButtons.add(pieceMoveTopGraphic);

		stagePieceButtonBG = new FlxSprite(0, pieceMoveBottomGraphic.y).makeGraphic(30, 30, 0xFF254949);
		stagePieceButtonBG.visible = false;
		stagePieces.add(stagePieceButtonBG);
		stagePieces.add(stagePieceButtons);

		stagePieceBar = new FlxSprite(20, 0).makeGraphic(240, 24, 0xFF254949);
		stagePieceBar.visible = false;
		stagePieces.add(stagePieceBar);

		stagePieceText = new FlxTypedSpriteGroup<FlxText>();
		stagePieces.add(stagePieceText);

		for (i in 0...16)
		{
			var txt:FlxText = new FlxText(20, 50 + (i * 20), 240, "").setFormat("FNF Dialogue", 20, FlxColor.BLACK, CENTER);
			txt.wordWrap = false;
			stagePieceText.add(txt);
		}
		refreshStagePieces();
		recalculateLayers();



		cameraBox = new Draggable(310, 615, "cameraBox");
		cameraBox.cameras = [camHUD];
		add(cameraBox);

		var hbox:HBox = new HBox(5, 5);
		hbox.spacing = 5;

		var camButton:Button = new Button(0, 0, "buttonCamera", function() { stageData.camFollow = [snapToGrid(camFollow.x, X), snapToGrid(camFollow.y, Y)]; }, function() {
			camFollow.x = stageData.camFollow[0];
			camFollow.y = stageData.camFollow[1];
		});
		camButton.infoText = "Set the camera's starting position based on the camera's current location in the editor. Right click to teleport the camera to the starting position.";
		hbox.add(camButton);

		camPosText = new FlxText(0, 0, 0, "Camera X: 0\nCamera Y: 0\nCamera Z: 0");
		camPosText.setFormat("FNF Dialogue", 20, FlxColor.WHITE, LEFT, OUTLINE, 0xFF254949);
		camPosText.borderSize = 2;
		hbox.add(camPosText);

		cameraBox.add(hbox);



		piecePosBox = new Draggable(760, 615, "cameraBox");
		piecePosBox.cameras = [camHUD];
		add(piecePosBox);

		hbox = new HBox(5, 5);

		piecePosText = new FlxText(0, 0, 0, "No Piece Selected");
		piecePosText.setFormat("FNF Dialogue", 17, FlxColor.WHITE, LEFT, OUTLINE, 0xFF254949);
		piecePosText.borderSize = 2;
		hbox.add(piecePosText);

		piecePosBox.add(hbox);



		createUI("StageEditor");



		var camZoomStepper:Stepper = cast element("camZoomStepper");
		camZoomStepper.value = stageData.camZoom;
		camZoomStepper.condition = function() { return stageData.camZoom; }
		camZoomStepper.onChanged = function()
		{
			stageData.camZoom = camZoomStepper.value;
			cameraZoom = stageData.camZoom;
		}
		cameraZoom = stageData.camZoom;
		camGame.zoom = stageData.camZoom;

		var camFollowXStepper:Stepper = cast element("camFollowXStepper");
		camFollowXStepper.value = stageData.camFollow[0];
		camFollowXStepper.condition = function() { return stageData.camFollow[0]; }
		camFollowXStepper.onChanged = function() { stageData.camFollow[0] = camFollowXStepper.valueInt; }

		var camFollowYStepper:Stepper = cast element("camFollowYStepper");
		camFollowYStepper.value = stageData.camFollow[1];
		camFollowYStepper.condition = function() { return stageData.camFollow[1]; }
		camFollowYStepper.onChanged = function() { stageData.camFollow[1] = camFollowYStepper.valueInt; }

		var camCenterOnChars:Button = cast element("camCenterOnChars");
		camCenterOnChars.onClicked = function() {
			var coords:Array<Float> = [allCharacters[0].getGraphicMidpoint().x, allCharacters[0].getGraphicMidpoint().y, allCharacters[1].getGraphicMidpoint().x, allCharacters[1].getGraphicMidpoint().y];
			var pos1:Array<Float> = [Math.min(coords[0], coords[2]), Math.min(coords[1], coords[3])];
			var pos2:Array<Float> = [Math.max(coords[0], coords[2]), Math.max(coords[1], coords[3])];
			stageData.camFollow[0] = Std.int(Math.round((pos1[0] + ((pos2[0] - pos1[0]) / 2)) / 5) * 5);
			stageData.camFollow[1] = Std.int(Math.round((pos1[1] + ((pos2[1] - pos1[1]) / 2)) / 5) * 5);
			if (allCharacters.length > 2)
				stageData.camFollow[1] = Std.int(Math.round((allCharacters[2].getMidpoint().y + allCharacters[2].characterData.camPosition[1]) / 5) * 5);
		}

		var camCenterOnGF:Button = cast element("camCenterOnGF");
		camCenterOnGF.onClicked = function() {
			if (allCharacters.length > 2)
			{
				stageData.camFollow[0] = Std.int(Math.round((allCharacters[2].getMidpoint().x + (allCharacters[2].characterData.camPosition[0] * (stageData.characters[2].flip ? -1 : 1))) / 5) * 5);
				stageData.camFollow[1] = Std.int(Math.round((allCharacters[2].getMidpoint().y + allCharacters[2].characterData.camPosition[1]) / 5) * 5);
			}
		}

		var pixelPerfectCheckbox:Checkbox = cast element("pixelPerfectCheckbox");
		pixelPerfectCheckbox.checked = stageData.pixelPerfect;
		pixelPerfectCheckbox.condition = function() { return stageData.pixelPerfect; }
		pixelPerfectCheckbox.onClicked = function() {
			stageData.pixelPerfect = pixelPerfectCheckbox.checked;
			for (m in myStageGroup.members)
				m.pixelPerfect = stageData.pixelPerfect;
		}

		var searchDirsButton:TextButton = cast element("searchDirsButton");
		searchDirsButton.onClicked = function() {
			var window:PopupWindow = null;
			var vbox:VBox = new VBox(35, 35);

			var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
			var scroll:VBox = menu.vbox;

			for (i in 0...stageData.searchDirs.length)
			{
				var dirHbox:HBox = new HBox();
				var dir:InputText = new InputText(0, 0, stageData.searchDirs[i]);
				dir.focusLost = function() {
					if (dir.text.trim() != "" && !dir.text.endsWith("/"))
						dir.text += "/";
					stageData.searchDirs[i] = dir.text;
				}
				dirHbox.add(dir);
				var dirBrowse:Button = new Button(0, 0, "buttonLoad", function() {
					var file:FileBrowser = new FileBrowser();
					file.loadCallback = function(fullPath:String) {
						var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
						if (nameArray.indexOf("images") != -1)
						{
							while (nameArray[0] != "images")
								nameArray.shift();
							nameArray.shift();
							nameArray.pop();

							var finalName = nameArray.join("/") + "/";
							dir.text = finalName;
							dir.focusLost();
						}
					}
					file.load("png");
				});
				dirHbox.add(dirBrowse);
				var _remove:Button = new Button(0, 0, "buttonTrash");
				_remove.onClicked = function() {
					stageData.searchDirs.splice(i, 1);
					window.close();
					new FlxTimer().start(0.02, function(tmr:FlxTimer) { searchDirsButton.onClicked(); });
				}
				dirHbox.add(_remove);
				scroll.add(dirHbox);
			}

			if (stageData.searchDirs.length > 0)
				vbox.add(menu);

			var _add:TextButton = new TextButton(0, 0, "Add");
			_add.onClicked = function() {
				stageData.searchDirs.push("");
				window.close();
				new FlxTimer().start(0.02, function(tmr:FlxTimer) { searchDirsButton.onClicked(); });
			}
			vbox.add(_add);

			var accept:TextButton = new TextButton(0, 0, "Accept");
			accept.onClicked = function() {
				searchDirsChanged();
				window.close();
			}
			vbox.add(accept);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		var scriptList:Array<String> = [""];
		for (s in Paths.listFilesSub("data/stages/", ".hscript"))
			scriptList.push("stages/" + s);
		for (s in Paths.listFilesSub("data/scripts/", ".hscript"))
			scriptList.push("scripts/" + s);

		if (stageData.script == "stages/" + id)
			stageData.script = "";
		var scriptDropdown:DropdownMenu = cast element("scriptDropdown");
		scriptDropdown.valueList = scriptList;
		scriptDropdown.value = stageData.script;
		scriptDropdown.condition = function() { return stageData.script; }
		scriptDropdown.onChanged = function() {
			stageData.script = scriptDropdown.value;
		}

		var bgColor:Button = cast element("bgColor");
		bgColor.onClicked = function() {
			new ColorPicker(FlxColor.fromRGB(stageData.bgColor[0], stageData.bgColor[1], stageData.bgColor[2]), function(clr:FlxColor) {
				stageData.bgColor = [clr.red, clr.green, clr.blue];
				camGame.bgColor = clr;
			});
		}

		var bgColorPicker:Button = cast element("bgColorPicker");
		bgColorPicker.onClicked = function() {
			persistentUpdate = false;
			openSubState(new ColorPickSubstate(function(px:FlxColor) {
				stageData.bgColor = [px.red, px.green, px.blue];
				camGame.bgColor = FlxColor.fromRGB(px.red, px.green, px.blue);		// For some reason if I set this directly it winds up being transparent?????????????????????
			}));
		}

		var generalProperties:VBoxScrollable = cast element("generalProperties");
		var stageShadersSlot:VBox = cast element("stageShadersSlot");

		var defaultCharacterShader:DropdownMenu = cast element("defaultCharacterShader");
		defaultCharacterShader.onChanged = function() {
			stageData.defaultCharacterShader = defaultCharacterShader.valueInt;
			refreshAllShaders();
		}
		defaultCharacterShader.condition = function() {
			if (stageData.defaultCharacterShader != null)
				return defaultCharacterShader.valueList[stageData.defaultCharacterShader];
			return defaultCharacterShader.value;
		}

		var charShader:DropdownMenu = cast element("charShader");
		charShader.onChanged = function() {
			if (curCharacter > -1)
			{
				stageData.characters[curCharacter].shader = charShader.valueInt;
				refreshAllShaders();
			}
		}
		charShader.condition = function() {
			if (curCharacter > -1)
			{
				if (stageData.characters[curCharacter].shader != null && charShader.valueList.length > stageData.characters[curCharacter].shader)
					return charShader.valueList[stageData.characters[curCharacter].shader];
				return "";
			}
			return charShader.value;
		}

		var pieceShader:DropdownMenu = cast element("pieceShader");
		pieceShader.onChanged = function() {
			if (curStagePiece > -1)
			{
				stageData.pieces[curStagePiece].shader = pieceShader.valueInt;
				refreshAllShaders();
			}
		}
		pieceShader.condition = function() {
			if (curStagePiece > -1)
			{
				if (stageData.pieces[curStagePiece].shader != null && pieceShader.valueList.length > stageData.pieces[curStagePiece].shader)
					return pieceShader.valueList[stageData.pieces[curStagePiece].shader];
				return "";
			}
			return pieceShader.value;
		}

		var stageShaderListRefresh:Void->Void;
		stageShaderListRefresh = function() {
			stageShadersSlot.forEachAlive(function(element:FlxSprite) {
				element.kill();
				element.destroy();
			});
			stageShadersSlot.clear();

			if (stageData.shaders == null)
				stageData.shaders = [];

			for (s in stageData.shaders)
			{
				var hb:HBox = new HBox();

				var btn:TextButton = new TextButton(0, 0, Std.string(stageData.shaders.indexOf(s) + 1) + " - " + s.id);
				btn.onClicked = function() {
					var window:PopupWindow = null;
					var vbox:VBox = new VBox(35, 35);

					var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
					var scroll:VBox = menu.vbox;

					var thisShaderData:EventTypeData = cast Paths.json("stageShaders/" + s.id);
					var thisShaderParams:Array<EventParams> = thisShaderData.parameters;
					for (i in 0...thisShaderParams.length)
					{
						var p:EventParams = thisShaderParams[i];
						var pValue:Dynamic = null;
						if (p.type != "label")
							pValue = Reflect.field(s.parameters, p.id);

						switch (p.type)
						{
							case "stepper":
								var label:String = p.label;
								if (!label.endsWith(":"))
									label += ":";
								var min:Null<Float> = p.min;
								if (min == null)
									min = -9999;
								var max:Null<Float> = p.max;
								if (max == null)
									max = 9999;
								var newThing:Stepper = new Stepper(0, 0, label, pValue, p.increment, min, max, p.decimals);
								newThing.condition = function() { return Reflect.field(s.parameters, p.id); }
								newThing.onChanged = function() { Reflect.setField(s.parameters, p.id, newThing.value); stageShaders[stageData.shaders.indexOf(s)].setData(s); }
								scroll.add(newThing);
						}
					}

					vbox.add(scroll);

					var ok:TextButton = new TextButton(0, 0, "#ok", Button.SHORT, function() { window.close(); });
					vbox.add(ok);

					window = PopupWindow.CreateWithGroup(vbox);
				}
				hb.add(btn);

				var _remove:Button = new Button(0, 0, "buttonTrash");
				_remove.onClicked = function() {
					stageData.shaders.remove(s);
					refreshAllShaders();
					new FlxTimer().start(0.02, function(tmr) { stageShaderListRefresh(); });
				}
				hb.add(_remove);

				stageShadersSlot.add(hb);
			}

			var stageShaderOptions:Array<String> = [""];
			for (s in stageData.shaders)
				stageShaderOptions.push(Std.string(stageData.shaders.indexOf(s) + 1) + " - " + s.id);

			defaultCharacterShader.valueList = stageShaderOptions;
			charShader.valueList = stageShaderOptions;
			pieceShader.valueList = stageShaderOptions;

			generalProperties.repositionAll();
		}

		stageShaderListRefresh();

		var shaderTypeList:Array<String> = Paths.listFilesSub("data/stageShaders/", ".json");
		var stageShaderType:DropdownMenu = cast element("stageShaderType");
		stageShaderType.valueList = shaderTypeList;
		stageShaderType.value = shaderTypeList[0];

		var stageShadersAdd:Button = cast element("stageShadersAdd");
		stageShadersAdd.onClicked = function() {
			if (stageData.shaders == null)
				stageData.shaders = [];
			var params:Dynamic = {};
			var baseParams:EventTypeData = cast Paths.json("stageShaders/" + stageShaderType.value);
			for (p in baseParams.parameters)
				Reflect.setField(params, p.id, p.defaultValue);
			stageData.shaders.push({id: stageShaderType.value, parameters: params});

			refreshStageShaders();
			stageShaderListRefresh();
		}

		refreshStageShaders();
		refreshAllShaders();



		var characterList:Array<String> = Paths.listFilesSub("data/characters/", ".json");
		var charIndex:DropdownMenu = cast element("charIndex");
		charIndex.valueText = Util.getCharacterNames(characterList);
		charIndex.valueList = characterList;
		charIndex.value = allCharacters[0].curCharacter;
		charIndex.condition = function() {
			if (curCharacter > -1)
				return allCharacters[curCharacter].curCharacter;
			return charIndex.value;
		}
		charIndex.onChanged = function() {
			if (charIndex.value != allCharacters[curCharacter].curCharacter)
			{
				allCharacters[curCharacter].changeCharacter(charIndex.value);
				allCharacters[curCharacter].repositionCharacter(stageData.characters[curCharacter].position[0], stageData.characters[curCharacter].position[1]);

				updateCharacterTab();
			}
		}

		charAnim = cast element("charAnim");
		charAnim.condition = function() {
			if (curCharacter > -1)
				return allCharacters[curCharacter].curAnimName;
			return charAnim.value;
		}
		charAnim.onChanged = function() {
			allCharacters[curCharacter].playAnim(charAnim.value, true);
		}

		var charX:Stepper = cast element("charX");
		charX.value = stageData.characters[0].position[0];
		charX.condition = function() {
			if (curCharacter > -1)
				return stageData.characters[curCharacter].position[0];
			return charX.value;
		}
		charX.onChanged = function() {
			stageData.characters[curCharacter].position[0] = charX.valueInt;
			allCharacters[curCharacter].repositionCharacter(stageData.characters[curCharacter].position[0], stageData.characters[curCharacter].position[1]);
		}

		var charY:Stepper = cast element("charY");
		charY.value = stageData.characters[0].position[1];
		charY.condition = function() {
			if (curCharacter > -1)
				return stageData.characters[curCharacter].position[1];
			return charY.value;
		}
		charY.onChanged = function() {
			stageData.characters[curCharacter].position[1] = charY.valueInt;
			allCharacters[curCharacter].repositionCharacter(stageData.characters[curCharacter].position[0], stageData.characters[curCharacter].position[1]);
		}

		var charFacingLeft:ToggleButton = cast element("charFacingLeft");
		charFacingLeft.condition = function() { return stageData.characters[curCharacter].flip; }
		charFacingLeft.onClicked = function() {
			stageData.characters[curCharacter].flip = true;
			if (!allCharacters[curCharacter].wasFlipped)
				allCharacters[curCharacter].flip();
		}

		var charFacingRight:ToggleButton = cast element("charFacingRight");
		charFacingRight.condition = function() { return !stageData.characters[curCharacter].flip; }
		charFacingRight.onClicked = function() {
			stageData.characters[curCharacter].flip = false;
			if (allCharacters[curCharacter].wasFlipped)
				allCharacters[curCharacter].flip();
		}

		var charScaleX:Stepper = cast element("charScaleX");
		charScaleX.value = stageData.characters[0].scale[0];
		charScaleX.condition = function() {
			if (curCharacter > -1)
				return stageData.characters[curCharacter].scale[0];
			return charScaleX.value;
		}

		var charScaleY:Stepper = cast element("charScaleY");
		charScaleY.value = stageData.characters[0].scale[1];
		charScaleY.condition = function() {
			if (curCharacter > -1)
				return stageData.characters[curCharacter].scale[1];
			return charScaleY.value;
		}

		charScaleX.onChanged = function() {
			stageData.characters[curCharacter].scale[0] = charScaleX.value;
			allCharacters[curCharacter].scaleCharacter(charScaleX.value, charScaleY.value);
		}
		charScaleY.onChanged = function() {
			stageData.characters[curCharacter].scale[1] = charScaleY.value;
			allCharacters[curCharacter].scaleCharacter(charScaleX.value, charScaleY.value);
		}

		var charScrollX:Stepper = cast element("charScrollX");
		charScrollX.value = stageData.characters[0].scrollFactor[0];
		charScrollX.condition = function() {
			if (curCharacter > -1)
				return stageData.characters[curCharacter].scrollFactor[0];
			return charScrollX.value;
		}
		charScrollX.onChanged = function() { stageData.characters[curCharacter].scrollFactor[0] = charScrollX.value; allCharacters[curCharacter].scrollFactor.x = charScrollX.value; }

		var charScrollY:Stepper = cast element("charScrollY");
		charScrollY.value = stageData.characters[0].scrollFactor[1];
		charScrollY.condition = function() {
			if (curCharacter > -1)
				return stageData.characters[curCharacter].scrollFactor[1];
			return charScrollY.value;
		}
		charScrollY.onChanged = function() { stageData.characters[curCharacter].scrollFactor[1] = charScrollY.value; allCharacters[curCharacter].scrollFactor.y = charScrollY.value; }

		var charCamX:Stepper = cast element("charCamX");
		charCamX.value = stageData.characters[0].camPosition[0];
		charCamX.condition = function() {
			if (curCharacter > -1)
				return stageData.characters[curCharacter].camPosition[0];
			return charCamX.value;
		}
		charCamX.onChanged = function() { stageData.characters[curCharacter].camPosition[0] = charCamX.valueInt; }

		var charCamY:Stepper = cast element("charCamY");
		charCamY.value = stageData.characters[0].camPosition[1];
		charCamY.condition = function() {
			if (curCharacter > -1)
				return stageData.characters[curCharacter].camPosition[1];
			return charCamY.value;
		}
		charCamY.onChanged = function() { stageData.characters[curCharacter].camPosition[1] = charCamY.valueInt; }

		var charCamAbsolute:Checkbox = cast element("charCamAbsolute");
		charCamAbsolute.checked = stageData.characters[0].camPosAbsolute;
		charCamAbsolute.condition = function() {
			if (curCharacter > -1)
				return stageData.characters[curCharacter].camPosAbsolute;
			return charCamAbsolute.checked;
		}
		charCamAbsolute.onClicked = function() { stageData.characters[curCharacter].camPosAbsolute = charCamAbsolute.checked; }

		var camTestCharButton:TextButton = cast element("camTestCharButton");
		camTestCharButton.onClicked = function() {
			if (stageData.characters[curCharacter].camPosAbsolute)
			{
				camFollow.x = stageData.characters[curCharacter].camPosition[0];
				camFollow.y = stageData.characters[curCharacter].camPosition[1];
			}
			else
			{
				camFollow.x = allCharacters[curCharacter].getMidpoint().x + (allCharacters[curCharacter].characterData.camPosition[0] * (stageData.characters[curCharacter].flip ? -1 : 1)) + stageData.characters[curCharacter].camPosition[0];
				camFollow.y = allCharacters[curCharacter].getMidpoint().y + allCharacters[curCharacter].characterData.camPosition[1] + stageData.characters[curCharacter].camPosition[1];
			}
		};

		var camSetCharButton:TextButton = cast element("camSetCharButton");
		camSetCharButton.onClicked = function() {
			if (stageData.characters[curCharacter].camPosAbsolute)
				stageData.characters[curCharacter].camPosition = [Std.int(camFollow.x), Std.int(camFollow.y)];
			else
			{
				var followPos:Array<Int> = [Std.int(camFollow.x), Std.int(camFollow.y)];
				followPos[0] -= Std.int(allCharacters[curCharacter].characterData.camPosition[0] * (stageData.characters[curCharacter].flip ? -1 : 1));
				followPos[0] -= Std.int(allCharacters[curCharacter].getMidpoint().x);
				followPos[1] -= Std.int(allCharacters[curCharacter].characterData.camPosition[1]);
				followPos[1] -= Std.int(allCharacters[curCharacter].getMidpoint().y);
				stageData.characters[curCharacter].camPosition = followPos;
			}

			stageData.characters[curCharacter].camPosition[0] = Math.round(stageData.characters[curCharacter].camPosition[0] / 5) * 5;
			stageData.characters[curCharacter].camPosition[1] = Math.round(stageData.characters[curCharacter].camPosition[1] / 5) * 5;
		};



		pieceProperties = cast element("pieceProperties");
		piecePropertiesBlank = cast element("piecePropertiesBlank");
		piecePropertiesSlot = cast element("piecePropertiesSlot");
		piecePropertiesGroup = cast element("piecePropertiesGroup");
		piecePropertiesSubSlot = cast element("piecePropertiesSubSlot");
		piecePropertiesSubGroup = cast element("piecePropertiesSubGroup");
		piecePropertiesNonSolidSlot = cast element("piecePropertiesNonSolidSlot");
		piecePropertiesNonSolidGroup = cast element("piecePropertiesNonSolidGroup");
		piecePropertiesSolidSlot = cast element("piecePropertiesSolidSlot");
		piecePropertiesSolidGroup = cast element("piecePropertiesSolidGroup");
		piecePropertiesNonTiledSlot = cast element("piecePropertiesNonTiledSlot");
		piecePropertiesNonTiledGroup = cast element("piecePropertiesNonTiledGroup");
		piecePropertiesTiledSlot = cast element("piecePropertiesTiledSlot");
		piecePropertiesTiledGroup = cast element("piecePropertiesTiledGroup");
		piecePropertiesAnimatedTiledSlot = cast element("piecePropertiesAnimatedTiledSlot");
		piecePropertiesAnimatedTiledGroup = cast element("piecePropertiesAnimatedTiledGroup");
		piecePropertiesCharacterGroup = cast element("piecePropertiesCharacterGroup");

		pieceId = cast element("pieceId");

		typesList = [["static", "animated", "tiled", "solid", "character", "group"], ["basetype", "basetype", "basetype", "basetype", "basetype", "basetype"]];
		for (f in Paths.listFilesSub("data/scripts/FlxSprite/", ".json"))
		{
			if (Paths.hscriptExists("data/scripts/FlxSprite/" + f))
			{
				typesList[0].push(f);
				typesList[1].push("static");
			}
		}
		for (f in Paths.listFilesSub("data/scripts/AnimatedSprite/", ".json"))
		{
			if (Paths.hscriptExists("data/scripts/AnimatedSprite/" + f))
			{
				typesList[0].push(f);
				typesList[1].push("animated");
			}
		}

		typeDropdown = cast element("typeDropdown");
		typeDropdown.valueList = typesList[0];
		typeDropdown.value = typesList[0][0];

		imageDropdown = cast element("imageDropdown");
		searchDirsChanged();
		if (imageDropdown.valueList.length > 0)
			imageDropdown.value = imageDropdown.valueList[0];
		imageDropdown.onChanged = function() {
			if (sparrowExists(imageDropdown.value))
				typeDropdown.value = "animated";
			else
				typeDropdown.value = "static";
		}

		var addPieceButton:TextButton = cast element("addPieceButton");
		addPieceButton.onClicked = function() { addPiece(); };

		var addPieceBehindCharacters:TextButton = cast element("addPieceBehindCharacters");
		addPieceBehindCharacters.onClicked = function() { addPiece(false, true); };

		var insertPieceButton:TextButton = cast element("insertPieceButton");
		insertPieceButton.onClicked = function() { addPiece(true); };

		var deletePieceButton:TextButton = cast element("deletePieceButton");
		deletePieceButton.onClicked = function() { confirmDeletePiece(); };



		pieceX = cast element("pieceX");
		pieceX.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].position[0];
			return pieceX.value;
		}
		pieceX.onChanged = function() {
			stageData.pieces[curStagePiece].position[0] = pieceX.valueInt;
			assignPieceParams(curStagePiece);
		}

		pieceY = cast element("pieceY");
		pieceY.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].position[1];
			return pieceY.value;
		}
		pieceY.onChanged = function() {
			stageData.pieces[curStagePiece].position[1] = pieceY.valueInt;
			assignPieceParams(curStagePiece);
		}

		var pieceScrollX:Stepper = cast element("pieceScrollX");
		pieceScrollX.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].scrollFactor[0];
			return pieceScrollX.value;
		}
		pieceScrollX.onChanged = function() {
			stageData.pieces[curStagePiece].scrollFactor[0] = pieceScrollX.value;
			assignPieceParams(curStagePiece);
		}

		var pieceScrollY:Stepper = cast element("pieceScrollY");
		pieceScrollY.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].scrollFactor[1];
			return pieceScrollY.value;
		}
		pieceScrollY.onChanged = function() {
			stageData.pieces[curStagePiece].scrollFactor[1] = pieceScrollY.value;
			assignPieceParams(curStagePiece);
		}

		var pieceVisible:Checkbox = cast element("pieceVisible");
		pieceVisible.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].visible;
			return pieceVisible.checked;
		}
		pieceVisible.onClicked = function() {
			stageData.pieces[curStagePiece].visible = pieceVisible.checked;
			assignPieceParams(curStagePiece);
		}

		var pieceFlipX:Checkbox = cast element("pieceFlipX");
		pieceFlipX.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].flip[0];
			return pieceFlipX.checked;
		}
		pieceFlipX.onClicked = function() {
			stageData.pieces[curStagePiece].flip[0] = pieceFlipX.checked;
			assignPieceParams(curStagePiece);
		}

		var pieceFlipY:Checkbox = cast element("pieceFlipY");
		pieceFlipY.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].flip[1];
			return pieceFlipY.checked;
		}
		pieceFlipY.onClicked = function() {
			stageData.pieces[curStagePiece].flip[1] = pieceFlipY.checked;
			assignPieceParams(curStagePiece);
		}

		var pieceScaleX:Stepper = cast element("pieceScaleX");
		pieceScaleX.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].scale[0];
			return pieceScaleX.value;
		}
		pieceScaleX.onChanged = function() {
			stageData.pieces[curStagePiece].scale[0] = pieceScaleX.value;
			assignPieceParams(curStagePiece);
		}

		var pieceScaleY:Stepper = cast element("pieceScaleY");
		pieceScaleY.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].scale[1];
			return pieceScaleY.value;
		}
		pieceScaleY.onChanged = function() {
			stageData.pieces[curStagePiece].scale[1] = pieceScaleY.value;
			assignPieceParams(curStagePiece);
		}

		var pieceSizeX:Stepper = cast element("pieceSizeX");
		pieceSizeX.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].scale[0];
			return pieceSizeX.value;
		}
		pieceSizeX.onChanged = function() {
			stageData.pieces[curStagePiece].scale[0] = pieceSizeX.value;
			assignPieceParams(curStagePiece);
		}

		var pieceSizeY:Stepper = cast element("pieceSizeY");
		pieceSizeY.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].scale[1];
			return pieceSizeY.value;
		}
		pieceSizeY.onChanged = function() {
			stageData.pieces[curStagePiece].scale[1] = pieceSizeY.value;
			assignPieceParams(curStagePiece);
		}

		var pieceUpdateHitbox:Checkbox = cast element("pieceUpdateHitbox");
		pieceUpdateHitbox.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].updateHitbox;
			return pieceUpdateHitbox.checked;
		}
		pieceUpdateHitbox.onClicked = function() {
			stageData.pieces[curStagePiece].updateHitbox = pieceUpdateHitbox.checked;
			assignPieceParams(curStagePiece);
		}

		var alignmentLeft:ToggleButton = cast element("alignmentLeft");
		alignmentLeft.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].align.endsWith("left");
			return false;
		}
		alignmentLeft.onClicked = function() {
			if (stageData.pieces[curStagePiece].align.startsWith("top"))
				stageData.pieces[curStagePiece].align = "topleft";
			else if (stageData.pieces[curStagePiece].align.startsWith("top"))
				stageData.pieces[curStagePiece].align = "bottomleft";
			else
				stageData.pieces[curStagePiece].align = "middleleft";

			assignPieceParams(curStagePiece);
		}

		var alignmentCenter:ToggleButton = cast element("alignmentCenter");
		alignmentCenter.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].align.endsWith("center");
			return false;
		}
		alignmentCenter.onClicked = function() {
			if (stageData.pieces[curStagePiece].align.startsWith("top"))
				stageData.pieces[curStagePiece].align = "topcenter";
			else if (stageData.pieces[curStagePiece].align.startsWith("top"))
				stageData.pieces[curStagePiece].align = "bottomcenter";
			else
				stageData.pieces[curStagePiece].align = "middlecenter";

			assignPieceParams(curStagePiece);
		}

		var alignmentRight:ToggleButton = cast element("alignmentRight");
		alignmentRight.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].align.endsWith("right");
			return false;
		}
		alignmentRight.onClicked = function() {
			if (stageData.pieces[curStagePiece].align.startsWith("top"))
				stageData.pieces[curStagePiece].align = "topright";
			else if (stageData.pieces[curStagePiece].align.startsWith("top"))
				stageData.pieces[curStagePiece].align = "bottomright";
			else
				stageData.pieces[curStagePiece].align = "middleright";

			assignPieceParams(curStagePiece);
		}

		var alignmentTop:ToggleButton = cast element("alignmentTop");
		alignmentTop.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].align.startsWith("top");
			return false;
		}
		alignmentTop.onClicked = function() {
			if (stageData.pieces[curStagePiece].align.endsWith("left"))
				stageData.pieces[curStagePiece].align = "topleft";
			else if (stageData.pieces[curStagePiece].align.endsWith("right"))
				stageData.pieces[curStagePiece].align = "topright";
			else
				stageData.pieces[curStagePiece].align = "topcenter";

			assignPieceParams(curStagePiece);
		}

		var alignmentMiddle:ToggleButton = cast element("alignmentMiddle");
		alignmentMiddle.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].align.startsWith("middle");
			return false;
		}
		alignmentMiddle.onClicked = function() {
			if (stageData.pieces[curStagePiece].align.endsWith("left"))
				stageData.pieces[curStagePiece].align = "middleleft";
			else if (stageData.pieces[curStagePiece].align.endsWith("right"))
				stageData.pieces[curStagePiece].align = "middleright";
			else
				stageData.pieces[curStagePiece].align = "middlecenter";

			assignPieceParams(curStagePiece);
		}

		var alignmentBottom:ToggleButton = cast element("alignmentBottom");
		alignmentBottom.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].align.startsWith("bottom");
			return false;
		}
		alignmentBottom.onClicked = function() {
			if (stageData.pieces[curStagePiece].align.endsWith("left"))
				stageData.pieces[curStagePiece].align = "bottomleft";
			else if (stageData.pieces[curStagePiece].align.endsWith("right"))
				stageData.pieces[curStagePiece].align = "bottomright";
			else
				stageData.pieces[curStagePiece].align = "bottomcenter";

			assignPieceParams(curStagePiece);
		}

		var pieceAntialias:Checkbox = cast element("pieceAntialias");
		pieceAntialias.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].antialias;
			return pieceAntialias.checked;
		}
		pieceAntialias.onClicked = function() {
			stageData.pieces[curStagePiece].antialias = pieceAntialias.checked;
			assignPieceParams(curStagePiece);
		}

		var pieceTileX:Checkbox = cast element("pieceTileX");
		pieceTileX.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].tile[0];
			return pieceTileX.checked;
		}
		pieceTileX.onClicked = function() {
			stageData.pieces[curStagePiece].tile[0] = pieceTileX.checked;
			assignPieceParams(curStagePiece);
		}

		var pieceTileY:Checkbox = cast element("pieceTileY");
		pieceTileY.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].tile[1];
			return pieceTileY.checked;
		}
		pieceTileY.onClicked = function() {
			stageData.pieces[curStagePiece].tile[1] = pieceTileY.checked;
			assignPieceParams(curStagePiece);
		}

		var pieceTileSpacingX:Stepper = cast element("pieceTileSpacingX");
		pieceTileSpacingX.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].tileSpace[0];
			return pieceTileSpacingX.value;
		}
		pieceTileSpacingX.onChanged = function() {
			stageData.pieces[curStagePiece].tileSpace[0] = pieceTileSpacingX.valueInt;
			assignPieceParams(curStagePiece);
		}

		var pieceTileSpacingY:Stepper = cast element("pieceTileSpacingY");
		pieceTileSpacingY.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].tileSpace[1];
			return pieceTileSpacingY.value;
		}
		pieceTileSpacingY.onChanged = function() {
			stageData.pieces[curStagePiece].tileSpace[1] = pieceTileSpacingY.valueInt;
			assignPieceParams(curStagePiece);
		}

		var pieceVelocityX:Stepper = cast element("pieceVelocityX");
		pieceVelocityX.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].velocity[0];
			return pieceVelocityX.value;
		}
		pieceVelocityX.onChanged = function() {
			stageData.pieces[curStagePiece].velocity[0] = pieceVelocityX.valueInt;
		}

		var pieceVelocityY:Stepper = cast element("pieceVelocityY");
		pieceVelocityY.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].velocity[1];
			return pieceVelocityY.value;
		}
		pieceVelocityY.onChanged = function() {
			stageData.pieces[curStagePiece].velocity[1] = pieceVelocityY.valueInt;
		}

		var pieceVelocityMultByScroll:Checkbox = cast element("pieceVelocityMultByScroll");
		pieceVelocityMultByScroll.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].velocityMultipliedByScroll;
			return pieceVelocityMultByScroll.checked;
		}
		pieceVelocityMultByScroll.onClicked = function() {
			stageData.pieces[curStagePiece].velocityMultipliedByScroll = pieceVelocityMultByScroll.checked;
		}

		var pieceTileCountX:Stepper = cast element("pieceTileCountX");
		pieceTileCountX.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].tileCount[0];
			return pieceTileCountX.value;
		}
		pieceTileCountX.onChanged = function() {
			stageData.pieces[curStagePiece].tileCount[0] = pieceTileCountX.valueInt;
			assignPieceParams(curStagePiece);
		}

		var pieceTileCountY:Stepper = cast element("pieceTileCountY");
		pieceTileCountY.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].tileCount[1];
			return pieceTileCountY.value;
		}
		pieceTileCountY.onChanged = function() {
			stageData.pieces[curStagePiece].tileCount[1] = pieceTileCountY.valueInt;
			assignPieceParams(curStagePiece);
		}

		var pieceColor:Button = cast element("pieceColor");
		pieceColor.onClicked = function() {
			new ColorPicker(FlxColor.fromRGB(stageData.pieces[curStagePiece].color[0], stageData.pieces[curStagePiece].color[1], stageData.pieces[curStagePiece].color[2]), function(clr:FlxColor) {
				stageData.pieces[curStagePiece].color = [clr.red, clr.green, clr.blue];
				assignPieceParams(curStagePiece);
			});
		}

		var pieceColorPicker:Button = cast element("pieceColorPicker");
		pieceColorPicker.onClicked = function() {
			persistentUpdate = false;
			openSubState(new ColorPickSubstate(function(px:FlxColor) {
				stageData.pieces[curStagePiece].color = [px.red, px.green, px.blue];
				assignPieceParams(curStagePiece);
			}));
		}

		var pieceAlpha:Stepper = cast element("pieceAlpha");
		pieceAlpha.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].alpha;
			return pieceAlpha.value;
		}
		pieceAlpha.onChanged = function() {
			stageData.pieces[curStagePiece].alpha = pieceAlpha.value;
			assignPieceParams(curStagePiece);
		}

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

		var pieceBlend:DropdownMenu = cast element("pieceBlend");
		pieceBlend.valueList = blendList;
		pieceBlend.value = "normal";
		pieceBlend.condition = function() {
			if (curStagePiece > -1)
				return stageData.pieces[curStagePiece].blend;
			return pieceBlend.value;
		}
		pieceBlend.onChanged = function() {
			stageData.pieces[curStagePiece].blend = pieceBlend.value;
			assignPieceParams(curStagePiece);
		}



		pieceAnimations = cast element("pieceAnimations");
		pieceAnimationsBlank = cast element("pieceAnimationsBlank");
		pieceAnimationsSlot = cast element("pieceAnimationsSlot");
		pieceAnimationsGroup = cast element("pieceAnimationsGroup");

		animName = cast element("animName");

		animPrefix = cast element("animPrefix");

		animPrefixes = cast element("animPrefixes");
		animPrefixes.onChanged = function() {
			animPrefix.text = animPrefixes.value;
		}

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

		animLooped = cast element("animLooped");
		animFPS = cast element("animFPS");

		animOffsetX = cast element("animOffsetX");
		animOffsetY = cast element("animOffsetY");

		var addAnimButton:TextButton = cast element("addAnimButton");
		addAnimButton.onClicked = function() {
			if (curStagePiece > -1 && stageData.pieces[curStagePiece].type == "animated")
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
					newAnim.indices = Character.compactIndices(newAnim.indices);
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
						myStage[curStagePiece].animation.addByIndices(newAnim.name, newAnim.prefix, Character.uncompactIndices(newAnim.indices), "", newAnim.fps, newAnim.loop);
					else
						myStage[curStagePiece].animation.addByPrefix(newAnim.name, newAnim.prefix, newAnim.fps, newAnim.loop);
				}
				else
					myStage[curStagePiece].animation.add(newAnim.name, Character.uncompactIndices(newAnim.indices), newAnim.fps, newAnim.loop);

				if (animOffsetX.value != 0 || animOffsetY.value != 0)
					myStage[curStagePiece].addOffsets(newAnim.name, newAnim.offsets);
				else if (animToReplace > -1)
					myStage[curStagePiece].addOffsets(newAnim.name, [0, 0]);

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

		curAnimDropdown = cast element("curAnimDropdown");
		curAnimDropdown.onChanged = function() {
			if (curStagePiece > -1 && curAnimDropdown.value != "")
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

		var deleteAnimButton:TextButton = cast element("deleteAnimButton");
		deleteAnimButton.onClicked = function()
		{
			if (curStagePiece > -1 && stageData.pieces[curStagePiece].type == "animated")
			{
				if (stageData.pieces[curStagePiece].animations.length < 1)
					return;

				var animToReplace:Int = -1;
				for (i in 0...stageData.pieces[curStagePiece].animations.length)
				{
					if (stageData.pieces[curStagePiece].animations[i].name == curAnimDropdown.value)
						animToReplace = i;
				}

				if (animToReplace > -1)
				{
					stageData.pieces[curStagePiece].animations.splice(animToReplace, 1);
					var pieceAnimList:Array<String> = [];
					for (anim in stageData.pieces[curStagePiece].animations)
						pieceAnimList.push(anim.name);
					curAnimDropdown.valueList = pieceAnimList;
					firstAnimDropdown.valueList = pieceAnimList;
					if (pieceAnimList.length > 0 && !pieceAnimList.contains(firstAnimDropdown.value))
					{
						firstAnimDropdown.value = pieceAnimList[0];
						firstAnimDropdown.onChanged();
					}
					if (pieceAnimList.length > 0 && !pieceAnimList.contains(curAnimDropdown.value))
					{
						curAnimDropdown.value = pieceAnimList[0];
						curAnimDropdown.onChanged();
					}
				}
			}
		};

		firstAnimDropdown = cast element("firstAnimDropdown");
		firstAnimDropdown.onChanged = function() {
			if (curStagePiece > -1 && firstAnimDropdown.value != "")
				stageData.pieces[curStagePiece].firstAnimation = firstAnimDropdown.value;
		}

		var beatAnimButton:TextButton = cast element("beatAnimButton");
		beatAnimButton.onClicked = function() {
			var window:PopupWindow = null;
			var vbox:VBox = new VBox(35, 35);

			var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
			var scroll:VBox = menu.vbox;

			for (i in 0...stageData.pieces[curStagePiece].idles.length)
			{
				var animHbox:HBox = new HBox();
				var anim:DropdownMenu = new DropdownMenu(0, 0, stageData.pieces[curStagePiece].idles[i], firstAnimDropdown.valueList, true);
				anim.onChanged = function() { stageData.pieces[curStagePiece].idles[i] = anim.value; }
				animHbox.add(anim);
				var _remove:Button = new Button(0, 0, "buttonTrash");
				_remove.onClicked = function() {
					stageData.pieces[curStagePiece].idles.splice(i, 1);
					window.close();
					new FlxTimer().start(0.02, function(tmr:FlxTimer) { beatAnimButton.onClicked(); });
				}
				animHbox.add(_remove);
				scroll.add(animHbox);
			}

			if (stageData.pieces[curStagePiece].idles.length > 0)
				vbox.add(menu);

			var _add:TextButton = new TextButton(0, 0, "Add");
			_add.onClicked = function() {
				if (stageData.pieces[curStagePiece].idles.length > 0)
					stageData.pieces[curStagePiece].idles.push(stageData.pieces[curStagePiece].idles[stageData.pieces[curStagePiece].idles.length - 1]);
				else
					stageData.pieces[curStagePiece].idles.push(firstAnimDropdown.valueList[0]);
				window.close();
				new FlxTimer().start(0.02, function(tmr:FlxTimer) { beatAnimButton.onClicked(); });
			}
			vbox.add(_add);

			var accept:TextButton = new TextButton(0, 0, "Accept", function() { window.close(); });
			vbox.add(accept);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		var beatAnimSpeed:Stepper = cast element("beatAnimSpeed");
		beatAnimSpeed.condition = function() {
			if (curStagePiece > -1 && stageData.pieces[curStagePiece].beatAnimationSpeed != null)
				return stageData.pieces[curStagePiece].beatAnimationSpeed;
			return 1;
		}
		beatAnimSpeed.onChanged = function() {
			if (curStagePiece > -1 && stageData.pieces[curStagePiece].type == "animated")
			{
				if (beatAnimSpeed.value == 1)
					Reflect.deleteField(stageData.pieces[curStagePiece], "beatAnimationSpeed");
				else
					stageData.pieces[curStagePiece].beatAnimationSpeed = beatAnimSpeed.value;
			}
		}

		updatePieceTabVisibility();
		updateAnimationTab();



		var help:String = Paths.text("helpText").replace("\r","").split("!StageEditor\n")[1].split("\n\n")[0];

		var tabOptions:Array<TopMenuOption> = [];
		for (t in tabMenu.tabs)
			tabOptions.push({label: t, action: function() { tabMenu.selectTabByName(t); }, condition: function() { return tabMenu.curTabName == t; }, icon: "bullet"});

		topmenu = new TopMenu([
			{
				label: "File",
				options: [
					{
						label: "New",
						action: function() { _confirm("make a new stage", _new); },
						shortcut: [FlxKey.CONTROL, FlxKey.N],
						icon: "new"
					},
					{
						label: "Open",
						action: function() { _confirm("load another stage", _open); },
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
						label: "Convert from...",
						options: [
							{
								label: "Base Game",
								action: BaseGameConverter.convertStage
							},
							{
								label: "Psych Engine",
								action: PsychConverter.convertStage
							},
							{
								label: "Codename Engine",
								action: CodenameConverter.convertStage
							}
						]
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
					},
					{
						label: "Grid Snapping...",
						action: function() {
							var window:PopupWindow = null;
							var vbox:VBox = new VBox(35, 35);

							var gridSnapXStepper:Stepper = new Stepper(0, 0, "X:", gridSnapX, 1, 1);
							vbox.add(gridSnapXStepper);

							var gridSnapYStepper:Stepper = new Stepper(0, 0, "Y:", gridSnapY, 1, 1);
							vbox.add(gridSnapYStepper);

							var accept:TextButton = new TextButton(0, 0, "Accept");
							accept.onClicked = function() {
								window.close();
								gridSnapX = gridSnapXStepper.valueInt;
								gridSnapY = gridSnapYStepper.valueInt;
								pieceX.stepVal = gridSnapX;
								pieceY.stepVal = gridSnapY;
							}
							vbox.add(accept);

							window = PopupWindow.CreateWithGroup(vbox);
						}
					}
				]
			},
			{
				label: "View",
				options: [
					{
						label: "Zoom In",
						action: function() {
							cameraZoom = cameraZoom + 0.05;
							cameraZoom = Math.round(cameraZoom * 1000) / 1000;
						},
						shortcut: [FlxKey.SHIFT, FlxKey.X]
					},
					{
						label: "Zoom Out",
						action: function() {
							cameraZoom = Math.max(0.05, cameraZoom - 0.05);
							cameraZoom = Math.round(cameraZoom * 1000) / 1000;
						},
						shortcut: [FlxKey.SHIFT, FlxKey.Z]
					},
					null,
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
						label: "Stage Pieces Panel",
						condition: function() { return members.contains(stagePieces); },
						action: function() {
							if (members.contains(stagePieces))
								remove(stagePieces, true);
							else
								insert(members.indexOf(topmenu), stagePieces);
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
						label: "Piece Position Panel",
						condition: function() { return members.contains(piecePosBox); },
						action: function() {
							if (members.contains(piecePosBox))
								remove(piecePosBox, true);
							else
								insert(members.indexOf(topmenu), piecePosBox);
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

		dataLog = [Cloner.clone(stageData)];
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
			return Std.int(Math.round(val / gridSnapY) * gridSnapY);
		return Std.int(Math.round(val / gridSnapX) * gridSnapX);
	}

	override public function update(elapsed:Float)
	{
		UIControl.cursor = MouseCursor.ARROW;

		mousePos.x = (((FlxG.mouse.x - (FlxG.width / 2)) / camGame.zoom) + (FlxG.width / 2)) + camFollow.x - (FlxG.width / 2);
		mousePos.y = (((FlxG.mouse.y - (FlxG.height / 2)) / camGame.zoom) + (FlxG.height / 2)) + camFollow.y - (FlxG.height / 2);

		if (!pauseUndo && !DeepEquals.deepEquals(stageData, dataLog[undoPosition]))
		{
			if (undoPosition < dataLog.length - 1)
				dataLog.resize(undoPosition + 1);
			dataLog.push(Cloner.clone(stageData));
			unsaved = true;
			undoPosition = dataLog.length - 1;
			refreshFilename();
		}

		if (!movingPiece && !TopMenu.busy && !DropdownMenu.isOneActive && FlxG.mouse.justMoved)
		{
			hoveredStagePiece = -1;
			hoveredStageButton = -1;
			if (members.contains(stagePieces))
			{
				stagePieceBar.visible = false;
				var i:Int = 0;
				stagePieceText.forEachAlive(function(anim:FlxText) {
					if (anim.visible && FlxG.mouse.overlaps(anim, camHUD) && hoveredStagePiece == -1)
					{
						anim.color = FlxColor.WHITE;
						hoveredStagePiece = i;
						stagePieceBar.visible = true;
						stagePieceBar.y = anim.y;
					}
					else
						anim.color = FlxColor.BLACK;
					i++;
				});

				if (hoveredStagePiece < 0)
				{
					stagePieceButtonBG.visible = false;
					i = 0;
					stagePieceButtons.forEachAlive(function(anim:FlxSprite) {
						if (selectedStagePieces.length == 1)
						{
							if (FlxG.mouse.overlaps(anim, camHUD))
							{
								anim.color = FlxColor.WHITE;
								hoveredStageButton = i;
								stagePieceButtonBG.visible = true;
								stagePieceButtonBG.x = anim.x;
							}
							else
								anim.color = FlxColor.BLACK;
						}
						i++;
					});
				}
			}

			var prevHoveredObject:FlxSprite = hoveredObject;
			hoveredObject = null;
			if (!FlxG.mouse.overlaps(tabMenu, camHUD) && !FlxG.mouse.overlaps(topmenu, camHUD) && (!members.contains(infoBox) || !FlxG.mouse.overlaps(infoBox, camHUD)) && (!members.contains(stagePieces) || !FlxG.mouse.overlaps(stagePieces, camHUD)) && (!members.contains(cameraBox) || !FlxG.mouse.overlaps(cameraBox, camHUD)) && (!members.contains(piecePosBox) || !FlxG.mouse.overlaps(piecePosBox, camHUD)))
			{
				var hoveredIndex:Int = -1;
				for (s in myStage)
				{
					if (myStageGroup.members.indexOf(s) > hoveredIndex)
					{
						if (s.backdrop == null && s.pixelsOverlapPoint(mousePos, Std.int(64 * s.alpha), camGame))
						{
							hoveredObject = s;
							hoveredIndex = myStageGroup.members.indexOf(s);
							var index:Int = myStage.indexOf(s);
							if (selectedStagePieces.contains(index) && !FlxG.keys.pressed.SHIFT)
								UIControl.cursor = MouseCursor.HAND;
							else
								UIControl.cursor = MouseCursor.BUTTON;
						}
					}
				}

				for (s in allCharacters)
				{
					if (myStageGroup.members.indexOf(s) > hoveredIndex)
					{
						if (s.pixelsOverlapPoint(mousePos, Std.int(64 * s.alpha), camGame))
						{
							hoveredObject = s;
							hoveredIndex = myStageGroup.members.indexOf(s);
							var index:Int = -allCharacters.indexOf(s) - 1;
							if (selectedStagePieces.contains(index) && !FlxG.keys.pressed.SHIFT)
								UIControl.cursor = MouseCursor.HAND;
							else
								UIControl.cursor = MouseCursor.BUTTON;
						}
					}
				}
			}

			if (hoveredObject != prevHoveredObject)
			{
				if (prevHoveredObject != null)
				{
					var index:Int = 0;
					if (myStage.contains(cast prevHoveredObject))
					{
						index = myStage.indexOf(cast prevHoveredObject);
						if (!selectedStagePieces.contains(index))
						{
							var sp:StageEditorPiece = cast prevHoveredObject;
							sp.highlightState = 0;
						}
					}
					else
					{
						var c:Character = cast prevHoveredObject;
						if (allCharacters.contains(c))
							index = -allCharacters.indexOf(c) - 1;
						if (!selectedStagePieces.contains(index))
							prevHoveredObject.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
					}
				}
				if (hoveredObject != null)
				{
					var index:Int = 0;
					if (myStage.contains(cast hoveredObject))
					{
						index = myStage.indexOf(cast hoveredObject);
						if (!selectedStagePieces.contains(index))
						{
							var sp:StageEditorPiece = cast hoveredObject;
							sp.highlightState = 1;
						}
					}
					else
					{
						var c:Character = cast hoveredObject;
						if (allCharacters.contains(c))
							index = -allCharacters.indexOf(c) - 1;
						if (!selectedStagePieces.contains(index))
							hoveredObject.setColorTransform(1, 1, 1, 1, 0, Std.int(255 * 0.15), 0, 0);
					}
				}
			}
		}

		var camPosString:String = "Camera X: " + Std.string(Math.round(camFollow.x)) + "\nCamera Y: " + Std.string(Math.round(camFollow.y)) + "\nCamera Z: " + Std.string(cameraZoom);
		if (camPosText.text != camPosString)
			camPosText.text = camPosString;

		var piecePosString:String = "No Piece Selected";
		if (selectedStagePieces.length > 0)
		{
			var minX:Float = -1;
			var minY:Float = -1;
			var maxX:Float = -1;
			var maxY:Float = -1;
			for (s in selectedStagePieces)
			{
				var p:FlxSprite = (s >= 0 ? myStage[s] : allCharacters[-s - 1]);
				if (minX == -1 || p.x < minX)
					minX = p.x;
				if (minY == -1 || p.y < minY)
					minY = p.y;
				if (maxX == -1 || p.x + p.width > maxX)
					maxX = p.x + p.width;
				if (maxY == -1 || p.y + p.height > maxY)
					maxY = p.y + p.height;
			}
			piecePosString = "X: " + Std.string(minX) + "\nY: " + Std.string(minY) + "\nWidth: " + Std.string(maxX - minX) + "\nHeight: " + Std.string(maxY - minY);
		}
		if (piecePosText.text != piecePosString)
			piecePosText.text = piecePosString;

		if (movingCamera)
		{
			camFollow.x += FlxG.mouse.deltaX / camGame.zoom;
			camFollow.y += FlxG.mouse.deltaY / camGame.zoom;

			if (Options.mouseJustReleased(true))
				movingCamera = false;
		}
		else
		{
			if (Options.mouseJustPressed(true) && !FlxG.mouse.overlaps(tabMenu, camHUD))
				movingCamera = true;
		}

		if (FlxG.mouse.wheel != 0 && !DropdownMenu.isOneActive)
		{
			cameraZoom = Math.max(0.05, cameraZoom + (FlxG.mouse.wheel * 0.05));
			cameraZoom = Math.round(cameraZoom * 1000) / 1000;
		}
		camGame.zoom = FlxMath.lerp(camGame.zoom, cameraZoom, elapsed * 10);

		if (movingPiece)
		{
			UIControl.cursor = MouseCursor.HAND;
			if (FlxG.mouse.justMoved)
			{
				dragOffset[0] += FlxG.mouse.deltaX / camGame.zoom;
				dragOffset[1] += FlxG.mouse.deltaY / camGame.zoom;
				for (i in 0...selectedStagePieces.length)
				{
					var s:Int = selectedStagePieces[i];
					if (s >= 0)
					{
						stageData.pieces[s].position = [dragStart[i][0] + snapToGrid(dragOffset[0], X), dragStart[i][1] + snapToGrid(dragOffset[1], Y)];
						myStage[s].setPosition(stageData.pieces[s].position[0], stageData.pieces[s].position[1]);
						alignPiece(s);
					}
					else
					{
						stageData.characters[-s - 1].position = [dragStart[i][0] + snapToGrid(dragOffset[0], X), dragStart[i][1] + snapToGrid(dragOffset[1], Y)];
						allCharacters[-s - 1].repositionCharacter(stageData.characters[-s - 1].position[0], stageData.characters[-s - 1].position[1]);
					}
				}
			}

			if (Options.mouseJustReleased())
			{
				pauseUndo = false;
				movingPiece = false;
			}
		}
		else if (Options.mouseJustPressed() && !DropdownMenu.isOneActive && !FlxG.mouse.overlaps(tabMenu, camHUD) && !FlxG.mouse.overlaps(topmenu, camHUD))
		{
			var selectedObjects:Array<FlxSprite> = [];
			for (s in selectedStagePieces)
			{
				if (s >= 0)
					selectedObjects.push(myStage[s]);
				else
					selectedObjects.push(allCharacters[-s - 1]);
			}

			if (hoveredStagePiece > -1)
			{
				if (hoveredStagePiece == 15)
				{
					if (stagePieceList.length > 15 + listOffset)
					{
						listOffset++;
						refreshStagePieces();
					}
				}
				else if (hoveredStagePiece == 0)
				{
					if (listOffset >= 0)
					{
						listOffset--;
						refreshStagePieces();
					}
				}
				else
				{
					if (stagePieceText.members[hoveredStagePiece].ID >= 0)
					{
						curStagePiece = stagePieceText.members[hoveredStagePiece].ID;
						curCharacter = -1;

						if (!FlxG.keys.pressed.SHIFT)
							selectedStagePieces = [];
						if (!selectedStagePieces.contains(stagePieceText.members[hoveredStagePiece].ID))
							selectedStagePieces.push(stagePieceText.members[hoveredStagePiece].ID);
					}
					else
					{
						curStagePiece = -1;
						curCharacter = -stagePieceText.members[hoveredStagePiece].ID - 1;

						if (!FlxG.keys.pressed.SHIFT)
							selectedStagePieces = [];
						if (!selectedStagePieces.contains(stagePieceText.members[hoveredStagePiece].ID))
							selectedStagePieces.push(stagePieceText.members[hoveredStagePiece].ID);
						updateCharacterTab();
					}

					refreshStagePieces();
					updatePieceTabVisibility();
					updatePieceTab();
					updateAnimationTab();
					refreshSelectionShader();
				}
			}
			else if (hoveredStageButton > -1)
			{
				switch (hoveredStageButton)
				{
					case 0: movePieceFully(1);
					case 1: movePiece(1);
					case 2: movePiece(-1);
					case 3: movePieceFully(-1);
				}
			}
			else if (FlxG.keys.pressed.SHIFT && selectedObjects.contains(hoveredObject))
			{
				if (Std.isOfType(hoveredObject, Character))
				{
					var hoveredCharacter:Character = cast hoveredObject;
					if (allCharacters.contains(hoveredCharacter))
					{
						if (curCharacter == allCharacters.indexOf(hoveredCharacter))
							curCharacter = -1;

						if (selectedStagePieces.contains(-allCharacters.indexOf(hoveredCharacter) - 1))
							selectedStagePieces.remove(-allCharacters.indexOf(hoveredCharacter) - 1);
					}
				}
				else
				{
					if (myStage.contains(cast hoveredObject))
					{
						if (curStagePiece == myStage.indexOf(cast hoveredObject))
							curStagePiece = -1;

						if (selectedStagePieces.contains(myStage.indexOf(cast hoveredObject)))
							selectedStagePieces.remove(myStage.indexOf(cast hoveredObject));
					}
				}

				refreshStagePieces();
				updatePieceTabVisibility();
				updatePieceTab();
				updateCharacterTab();
				updateAnimationTab();
				refreshSelectionShader();
			}
			else if (!selectedObjects.contains(hoveredObject))
			{
				if (Std.isOfType(hoveredObject, Character))
				{
					var oldStagePiece:Int = curCharacter;

					var hoveredCharacter:Character = cast hoveredObject;
					if (allCharacters.contains(hoveredCharacter))
						curCharacter = allCharacters.indexOf(hoveredCharacter);

					if (!FlxG.keys.pressed.SHIFT)
						selectedStagePieces = [];
					if (allCharacters.contains(hoveredCharacter) && !selectedStagePieces.contains(-allCharacters.indexOf(hoveredCharacter) - 1))
						selectedStagePieces.push(-allCharacters.indexOf(hoveredCharacter) - 1);

					if (curCharacter != oldStagePiece)
					{
						curStagePiece = -1;
						refreshStagePieces();
						updatePieceTabVisibility();
						updateCharacterTab();
						updateAnimationTab();
						refreshSelectionShader();
					}
				}
				else
				{
					var oldStagePiece:Int = curStagePiece;

					if (myStage.contains(cast hoveredObject))
						curStagePiece = myStage.indexOf(cast hoveredObject);
					else
						curStagePiece = -1;

					if (!FlxG.keys.pressed.SHIFT)
						selectedStagePieces = [];
					if (myStage.contains(cast hoveredObject) && !selectedStagePieces.contains(myStage.indexOf(cast hoveredObject)))
						selectedStagePieces.push(myStage.indexOf(cast hoveredObject));

					if (curStagePiece != oldStagePiece || curCharacter > -1)
					{
						curCharacter = -1;
						refreshStagePieces();
						updatePieceTabVisibility();
						updatePieceTab();
						updateAnimationTab();
						refreshSelectionShader();
					}
				}
			}

			selectedObjects = [];
			for (s in selectedStagePieces)
			{
				if (s >= 0)
					selectedObjects.push(myStage[s]);
				else
					selectedObjects.push(allCharacters[-s - 1]);
			}

			if (selectedObjects.contains(hoveredObject) && !FlxG.keys.pressed.SHIFT)
			{
				if (!posLocked)
				{
					dragStart = [];
					for (s in selectedStagePieces)
					{
						if (s >= 0)
							dragStart.push(Reflect.copy(stageData.pieces[s].position));
						else
							dragStart.push(Reflect.copy(stageData.characters[-s - 1].position));
					}
					dragOffset = [0, 0];
					movingPiece = true;
					pauseUndo = true;
				}
			}
		}

		super.update(elapsed);
		if (hoveredStagePiece > -1 || hoveredStageButton > -1)
			UIControl.cursor = MouseCursor.BUTTON;

		if (FlxG.keys.justPressed.DELETE)
			confirmDeletePiece();

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}

	function addPiece(?insert:Bool = false, ?behindCharacters:Bool = false)
	{
		if (typeDropdown.value == "character")
		{
			var char:StageCharacter =
			{
				position: [0, 0],
				layer: stageData.characters.length,
				flip: false,
				scale: [1, 1],
				scrollFactor: [1, 1],
				camPosition: [0, 0],
				camPosAbsolute: false
			}

			if (curCharacter > -1)
			{
				char.position = stageData.characters[curCharacter].position.copy();
				char.flip = stageData.characters[curCharacter].flip;
				char.scale = stageData.characters[curCharacter].scale.copy();
				char.scrollFactor = stageData.characters[curCharacter].scrollFactor.copy();
				char.camPosition = stageData.characters[curCharacter].camPosition.copy();
				char.camPosAbsolute = stageData.characters[curCharacter].camPosAbsolute;
			}

			if (insert && (curCharacter > -1 || curStagePiece > -1))
			{
				if (curCharacter > -1)
					char.layer = stageData.characters[curCharacter].layer;
				else if (curStagePiece > -1)
					char.layer = stageData.pieces[curStagePiece].layer;

				var index:Int = 0;
				for (i in 0...stagePieceList.length)
				{
					if ((curStagePiece > -1 && stagePieceList[i][1] == curStagePiece) || (curCharacter > -1 && stagePieceList[i][1] == -curCharacter - 1))
					{
						index = i;
						break;
					}
				}

				for (i in index...stagePieceList.length)
				{
					if (stagePieceList[i][1] < 0)
						stageData.characters[Std.int(-stagePieceList[i][1] - 1)].layer++;
					else
						stageData.pieces[stagePieceList[i][1]].layer++;
				}
			}

			stageData.characters.push(char);
			curCharacter = stageData.characters.length - 1;
			curStagePiece = -1;
			selectedStagePieces = [-curCharacter - 1];

			spawnCharacter();
			refreshStagePieces();
			updatePieceTabVisibility();
			updateAnimationTab();
			refreshSelectionShader();
		}
		else
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
				new Notify("A piece with that " + (pieceId.text == "" ? "asset" : "id") + " already exists.");
			else if ((typeDropdown.value != "solid" && typesList[1][typeDropdown.valueInt] != "solid") && (typeDropdown.value != "group" && typesList[1][typeDropdown.valueInt] != "group") && imageDropdown.value == "")
				new Notify("A piece must have an asset.");
			else if ((typeDropdown.value == "solid" || typesList[1][typeDropdown.valueInt] == "solid") && pieceId.text == "")
				new Notify("A piece of type 'solid' must have an id.");
			else if ((typeDropdown.value == "group" || typesList[1][typeDropdown.valueInt] == "group") && pieceId.text == "")
				new Notify("A piece of type 'group' must have an id.");
			else
			{
				var newPiece:StagePiece =
				{
					type: (typesList[1][typeDropdown.valueInt] == "basetype" ? typeDropdown.value : typesList[1][typeDropdown.valueInt]),
					asset: imageDropdown.value,
					position: [0, 0],
					velocity: [0, 0],
					velocityMultipliedByScroll: false,
					antialias: true,
					layer: stageData.characters.length,
					align: "topleft",
					visible: true,
					scale: [1, 1],
					updateHitbox: true,
					scrollFactor: [1, 1],
					flip: [false, false],
					color: [255, 255, 255],
					alpha: 1,
					blend: "normal",
					tile: [true, true],
					tileSpace: [0, 0],
					tileCount: [1, 1]
				};

				if (pieceId.text != "")
					newPiece.id = pieceId.text;

				if (curStagePiece > -1 && stageData.pieces.length > 0 && curStagePiece < stageData.pieces.length)
				{
					newPiece.position = stageData.pieces[curStagePiece].position.copy();
					newPiece.velocity = stageData.pieces[curStagePiece].velocity.copy();
					newPiece.velocityMultipliedByScroll = stageData.pieces[curStagePiece].velocityMultipliedByScroll;
					newPiece.antialias = stageData.pieces[curStagePiece].antialias;
					newPiece.visible = stageData.pieces[curStagePiece].visible;
					newPiece.scale = stageData.pieces[curStagePiece].scale.copy();
					newPiece.updateHitbox = stageData.pieces[curStagePiece].updateHitbox;
					newPiece.scrollFactor = stageData.pieces[curStagePiece].scrollFactor.copy();
					newPiece.flip = stageData.pieces[curStagePiece].flip.copy();
					newPiece.align = stageData.pieces[curStagePiece].align;
					newPiece.color = stageData.pieces[curStagePiece].color.copy();
					newPiece.alpha = stageData.pieces[curStagePiece].alpha;
					newPiece.blend = stageData.pieces[curStagePiece].blend;
					newPiece.tile = stageData.pieces[curStagePiece].tile.copy();
					newPiece.tileSpace = stageData.pieces[curStagePiece].tileSpace.copy();
					newPiece.tileCount = stageData.pieces[curStagePiece].tileCount.copy();
				}

				if (typesList[1][typeDropdown.valueInt] != "basetype")
				{
					newPiece.scriptClass = typeDropdown.value;
					newPiece.scriptParameters = {};

					var type:String = (newPiece.type == "animated" ? "AnimatedSprite" : "FlxSprite");
					if (Paths.jsonExists("scripts/" + type + "/" + newPiece.scriptClass))
					{
						var pieceParams:Array<EventParams> = cast Paths.json("scripts/" + type + "/" + newPiece.scriptClass).parameters;
						if (pieceParams != null && pieceParams.length > 0)
						{
							for (param in pieceParams)
							{
								if (param.type != "label")
									Reflect.setField(newPiece.scriptParameters, param.id, param.defaultValue);
							}
						}
					}
				}

				if (newPiece.type == "animated")
				{
					newPiece.animations = [];
					newPiece.idles = [];
					newPiece.firstAnimation = "";
				}

				var slot:Int = stageData.pieces.length;

				if (behindCharacters)
				{
					newPiece.layer = 0;
					for (i in 0...stageData.pieces.length)
					{
						if (stageData.pieces[i].layer > newPiece.layer)
						{
							slot = i;
							break;
						}
					}
				}
				else if (curCharacter > -1 && insert)
				{
					newPiece.layer = stageData.characters[curCharacter].layer;
					for (i in 0...stageData.pieces.length)
					{
						if (stageData.pieces[i].layer > newPiece.layer)
						{
							slot = i;
							break;
						}
					}
				}
				else if (curStagePiece > -1 && insert)
				{
					slot = curStagePiece;
					newPiece.layer = stageData.pieces[curStagePiece].layer;
				}

				stageData.pieces.insert(slot, newPiece);
				curStagePiece = slot;
				curCharacter = -1;
				selectedStagePieces = [slot];

				addToStage(curStagePiece, false);
				assignPieceParams(curStagePiece);
				refreshStagePieces();
				updatePieceTabVisibility();
				updateAnimationTab();
				refreshSelectionShader();
			}
		}
	}

	function confirmDeletePiece()
	{
		if (selectedStagePieces.length > 0)
			new Confirm("Are you sure you want to delete the selected piece" + (selectedStagePieces.length > 1 ? "s" : "") + "?", deletePiece);
	}

	function deletePiece()
	{
		selectedStagePieces.sort(function(a:Int, b:Int) { return b - a; });
		for (s in selectedStagePieces)
		{
			if (s < 0 && stageData.characters.length > 2)
			{
				var layer:Int = stageData.characters[-s - 1].layer;

				for (c in stageData.characters)
				{
					if (c.layer > layer)
						c.layer--;
				}

				for (p in stageData.pieces)
				{
					if (p.layer > layer)
						p.layer--;
				}

				var toRemove:Character = allCharacters.splice(-s - 1, 1)[0];
				myStageGroup.remove(toRemove, true);
				toRemove.kill();
				toRemove.destroy();

				stageData.characters.splice(-s - 1, 1);

			}
			else if (s >= 0)
			{
				var toRemove:FlxSprite = myStage.splice(s, 1)[0];
				myStageGroup.remove(toRemove, true);
				toRemove.kill();
				toRemove.destroy();

				stageData.pieces.splice(s, 1);
			}
		}
		selectedStagePieces = [];

		refreshStagePieces();
		updatePieceTabVisibility();
		refreshSelectionShader();
	}

	var dropdownSpecial:Map<String, Array<String>> = new Map<String, Array<String>>();

	function updatePieceTabVisibility()
	{
		if (selectedStagePieces.length == 1)
		{
			if (curCharacter > -1 && stageData.characters.length > 0 && curCharacter < stageData.characters.length)
			{
				for (e in pieceParams)
				{
					pieceProperties.vbox.remove(e, true);
					e.kill();
					e.destroy();
				}
				pieceParams = [];

				if (piecePropertiesSlot.members.contains(piecePropertiesBlank))
					piecePropertiesSlot.remove(piecePropertiesBlank, true);
				if (piecePropertiesSlot.members.contains(piecePropertiesGroup))
					piecePropertiesSlot.remove(piecePropertiesGroup, true);
				if (!piecePropertiesSlot.members.contains(piecePropertiesCharacterGroup))
					piecePropertiesSlot.add(piecePropertiesCharacterGroup);

				piecePropertiesCharacterGroup.repositionAll();
				piecePropertiesSlot.repositionAll();
			}
			else if (curStagePiece > -1 && stageData.pieces.length > 0 && curStagePiece < stageData.pieces.length)
			{
				if (piecePropertiesSlot.members.contains(piecePropertiesBlank))
					piecePropertiesSlot.remove(piecePropertiesBlank, true);
				if (piecePropertiesSlot.members.contains(piecePropertiesCharacterGroup))
					piecePropertiesSlot.remove(piecePropertiesCharacterGroup, true);
				if (!piecePropertiesSlot.members.contains(piecePropertiesGroup))
					piecePropertiesSlot.add(piecePropertiesGroup);

				if (stageData.pieces[curStagePiece].type == "group")
				{
					if (piecePropertiesSubSlot.members.contains(piecePropertiesSubGroup))
						piecePropertiesSubSlot.remove(piecePropertiesSubGroup, true);
				}
				else
				{
					if (!piecePropertiesSubSlot.members.contains(piecePropertiesSubGroup))
						piecePropertiesSubSlot.add(piecePropertiesSubGroup);
				}

				if (stageData.pieces[curStagePiece].type == "solid")
				{
					if (piecePropertiesNonSolidSlot.members.contains(piecePropertiesNonSolidGroup))
						piecePropertiesNonSolidSlot.remove(piecePropertiesNonSolidGroup, true);
					if (!piecePropertiesSolidSlot.members.contains(piecePropertiesSolidGroup))
						piecePropertiesSolidSlot.add(piecePropertiesSolidGroup);
				}
				else
				{
					if (piecePropertiesSolidSlot.members.contains(piecePropertiesSolidGroup))
						piecePropertiesSolidSlot.remove(piecePropertiesSolidGroup, true);
					if (!piecePropertiesNonSolidSlot.members.contains(piecePropertiesNonSolidGroup))
						piecePropertiesNonSolidSlot.add(piecePropertiesNonSolidGroup);
				}

				if (stageData.pieces[curStagePiece].type == "tiled")
				{
					if (piecePropertiesNonTiledSlot.members.contains(piecePropertiesNonTiledGroup))
						piecePropertiesNonTiledSlot.remove(piecePropertiesNonTiledGroup, true);
					if (!piecePropertiesTiledSlot.members.contains(piecePropertiesTiledGroup))
						piecePropertiesTiledSlot.add(piecePropertiesTiledGroup);
				}
				else
				{
					if (piecePropertiesTiledSlot.members.contains(piecePropertiesTiledGroup))
						piecePropertiesTiledSlot.remove(piecePropertiesTiledGroup, true);
					if (!piecePropertiesNonTiledSlot.members.contains(piecePropertiesNonTiledGroup))
						piecePropertiesNonTiledSlot.add(piecePropertiesNonTiledGroup);
				}

				if (stageData.pieces[curStagePiece].type == "animated" && !sparrowExists(stageData.pieces[curStagePiece].asset))
				{
					if (!piecePropertiesAnimatedTiledSlot.members.contains(piecePropertiesAnimatedTiledGroup))
						piecePropertiesAnimatedTiledSlot.add(piecePropertiesAnimatedTiledGroup);
				}
				else
				{
					if (piecePropertiesAnimatedTiledSlot.members.contains(piecePropertiesAnimatedTiledGroup))
						piecePropertiesAnimatedTiledSlot.remove(piecePropertiesAnimatedTiledGroup, true);
				}

				for (e in pieceParams)
				{
					pieceProperties.vbox.remove(e, true);
					e.kill();
					e.destroy();
				}
				pieceParams = [];

				if (stageData.pieces[curStagePiece].scriptClass != null && Paths.jsonExists("scripts/" + (stageData.pieces[curStagePiece].type == "animated" ? "AnimatedSprite" : "FlxSprite") + "/" + stageData.pieces[curStagePiece].scriptClass))
				{
					var thisPieceParams:Array<EventParams> = cast Paths.json("scripts/" + (stageData.pieces[curStagePiece].type == "animated" ? "AnimatedSprite" : "FlxSprite") + "/" + stageData.pieces[curStagePiece].scriptClass).parameters;
					var ii:Int = 0;
					for (i in 0...thisPieceParams.length)
					{
						var p:EventParams = thisPieceParams[i];
						var pValue:Dynamic = p.defaultValue;
						if (p.type != "label" && Reflect.hasField(stageData.pieces[curStagePiece].scriptParameters, p.id))
							pValue = Reflect.field(stageData.pieces[curStagePiece].scriptParameters, p.id);

						switch (p.type)
						{
							case "label":
								var newThing:FlxText = new FlxText(0, 0, 230, p.label);
								newThing.setFormat("FNF Dialogue", 18, FlxColor.WHITE, CENTER, OUTLINE, 0xFF254949);
								pieceParams.push(newThing);
								ii--;

							case "checkbox":
								var newThing:Checkbox = new Checkbox(0, 0, p.label);
								newThing.checked = pValue;
								newThing.condition = function() { return Reflect.field(stageData.pieces[curStagePiece].scriptParameters, p.id); }
								newThing.onClicked = function() { Reflect.setField(stageData.pieces[curStagePiece].scriptParameters, p.id, newThing.checked); }

								pieceParams.push(newThing);

							case "dropdown":
								var str:String = pValue;
								var options:Array<String> = p.options.copy();
								for (o in options)
								{
									if (!pieceParamNames.exists(o))
										pieceParamNames[o] = Util.properCaseString(o);
								}
								var newThing:DropdownMenu = new DropdownMenu(0, 0, "", [""], true);
								newThing.valueText = pieceParamNames;
								newThing.valueList = options;
								newThing.value = str;
								newThing.condition = function() { return Reflect.field(stageData.pieces[curStagePiece].scriptParameters, p.id); }
								newThing.onChanged = function() { Reflect.setField(stageData.pieces[curStagePiece].scriptParameters, p.id, newThing.value); }

								pieceParams.push(new Label(p.label));
								pieceParams.push(newThing);

							case "dropdownSpecial":
								if (!dropdownSpecial.exists(p.options[0] + "-" + p.options[1]))
									dropdownSpecial[p.options[0] + "-" + p.options[1]] = Paths.listFilesSub(p.options[0] + "/", p.options[1]);
								var str:String = pValue;
								var newThing:DropdownMenu = new DropdownMenu(0, 0, str, dropdownSpecial[p.options[0] + "-" + p.options[1]], true);
								newThing.condition = function() { return Reflect.field(stageData.pieces[curStagePiece].scriptParameters, p.id); }
								newThing.onChanged = function() { Reflect.setField(stageData.pieces[curStagePiece].scriptParameters, p.id, newThing.value); }

								pieceParams.push(new Label(p.label));
								pieceParams.push(newThing);

							case "stepper":
								var label:String = p.label;
								if (!label.endsWith(":"))
									label += ":";
								var newThing:Stepper = new Stepper(0, 0, label, pValue, p.increment, p.min, p.max, p.decimals);
								newThing.condition = function() { return Reflect.field(stageData.pieces[curStagePiece].scriptParameters, p.id); }
								newThing.onChanged = function() { Reflect.setField(stageData.pieces[curStagePiece].scriptParameters, p.id, newThing.value); }
								pieceParams.push(newThing);

							case "string":
								var str:String = pValue;
								var newThing:InputText = new InputText(0, 0, str);
								newThing.condition = function() { return Reflect.field(stageData.pieces[curStagePiece].scriptParameters, p.id); }
								newThing.focusLost = function() { Reflect.setField(stageData.pieces[curStagePiece].scriptParameters, p.id, newThing.text); }

								pieceParams.push(new Label(p.label));
								pieceParams.push(newThing);

							case "color":
								var newThing:TextButton = new TextButton(0, 0, p.label, Button.LONG);

								newThing.onClicked = function() {
									new ColorPicker(FlxColor.fromRGB(Std.int(Reflect.field(stageData.pieces[curStagePiece].scriptParameters, p.id)), Std.int(Reflect.field(stageData.pieces[curStagePiece].scriptParameters, thisPieceParams[i+1].id)),Std.int(Reflect.field(stageData.pieces[curStagePiece].scriptParameters, thisPieceParams[i+2].id))), function(clr:FlxColor) {
										Reflect.setField(stageData.pieces[curStagePiece].scriptParameters, p.id, clr.red);
										Reflect.setField(stageData.pieces[curStagePiece].scriptParameters, thisPieceParams[i+1].id, clr.green);
										Reflect.setField(stageData.pieces[curStagePiece].scriptParameters, thisPieceParams[i+2].id, clr.blue);
									});
								}

								pieceParams.push(newThing);
						}
						ii++;
					}

					for (e in pieceParams)
						pieceProperties.vbox.add(e);
				}

				piecePropertiesSubGroup.repositionAll();
				piecePropertiesSubSlot.repositionAll();
				piecePropertiesGroup.repositionAll();
			}
		}
		else
		{
			for (e in pieceParams)
			{
				pieceProperties.vbox.remove(e, true);
				e.kill();
				e.destroy();
			}
			pieceParams = [];

			if (piecePropertiesSlot.members.contains(piecePropertiesGroup))
				piecePropertiesSlot.remove(piecePropertiesGroup, true);
			if (piecePropertiesSlot.members.contains(piecePropertiesCharacterGroup))
				piecePropertiesSlot.remove(piecePropertiesCharacterGroup, true);
			if (!piecePropertiesSlot.members.contains(piecePropertiesBlank))
				piecePropertiesSlot.add(piecePropertiesBlank);
		}
		piecePropertiesSlot.repositionAll();
		pieceProperties.repositionAll();

		if (selectedStagePieces.length == 1 && curStagePiece > -1 && stageData.pieces.length > 0 && curStagePiece < stageData.pieces.length && stageData.pieces[curStagePiece].type == "animated")
		{
			if (pieceAnimationsSlot.members.contains(pieceAnimationsBlank))
				pieceAnimationsSlot.remove(pieceAnimationsBlank, true);
			if (!pieceAnimationsSlot.members.contains(pieceAnimationsGroup))
				pieceAnimationsSlot.add(pieceAnimationsGroup);
			pieceAnimationsGroup.repositionAll();
		}
		else
		{
			if (pieceAnimationsSlot.members.contains(pieceAnimationsGroup))
				pieceAnimationsSlot.remove(pieceAnimationsGroup, true);
			if (!pieceAnimationsSlot.members.contains(pieceAnimationsBlank))
				pieceAnimationsSlot.add(pieceAnimationsBlank);
		}
		pieceAnimationsSlot.repositionAll();
		pieceAnimations.repositionAll();
	}

	function updateCharacterTab()
	{
		var animList:Array<String> = [];
		if (curCharacter > -1)
		{
			for (a in allCharacters[curCharacter].characterData.animations)
				animList.push(a.name);
		}
		charAnim.valueList = animList;
	}

	function updatePieceTab()
	{
		if (curStagePiece <= -1)
			return;

		if (stageData.pieces[curStagePiece].id == null)
			pieceId.text = "";
		else
			pieceId.text = stageData.pieces[curStagePiece].id;

		if (stageData.pieces[curStagePiece].scriptClass != null && typesList[0].contains(stageData.pieces[curStagePiece].scriptClass))
			typeDropdown.value = stageData.pieces[curStagePiece].scriptClass;
		else
			typeDropdown.value = stageData.pieces[curStagePiece].type;

		imageDropdown.value = stageData.pieces[curStagePiece].asset;
	}

	function updateAnimationTab()
	{
		if (curStagePiece > -1 && stageData.pieces.length > 0 && stageData.pieces[curStagePiece].type == "animated")
		{
			if (sparrowExists(stageData.pieces[curStagePiece].asset))
			{
				animPrefixes.valueList = sparrowAnimations(stageData.pieces[curStagePiece].asset);
				if (assetExists(stageData.pieces[curStagePiece].asset + ".txt"))
					allAnimData = raw(stageData.pieces[curStagePiece].asset + ".txt");
				else
					allAnimData = raw(stageData.pieces[curStagePiece].asset + ".xml");
			}
			else
			{
				animPrefixes.valueList = [""];
				allAnimData = "";
			}
			if (stageData.pieces[curStagePiece].animations.length > 0)
			{
				var pieceAnimList:Array<String> = [];
				var animData:StageAnimation = null;

				if (!sparrowExists(stageData.pieces[curStagePiece].asset))
				{
					for (anim in stageData.pieces[curStagePiece].animations)
					{
						if (!myStage[curStagePiece].animation.getNameList().contains(anim.name))
							myStage[curStagePiece].animation.add(anim.name, Character.uncompactIndices(anim.indices), anim.fps, anim.loop);
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
			}
		}
		else
		{
			curAnimDropdown.valueList = [""];
			curAnimDropdown.value = "";
			firstAnimDropdown.valueList = [""];
			firstAnimDropdown.value = "";
		}
	}

	function searchDirsChanged()
	{
		var imageList:Array<String> = [];
		for (s in stageData.searchDirs)
			imageList = imageList.concat(Paths.listFilesSub("images/" + s, ".png"));

		if (imageList.length > 0)
			imageDropdown.valueList = imageList;
		else
			imageDropdown.valueList = [""];
	}

	function refreshSelectionShader()
	{
		if (allCharacters.length > 0)
		{
			for (i in 0...allCharacters.length)
			{
				if (selectedStagePieces.contains(-i - 1))
					allCharacters[i].setColorTransform(1, 1, 1, 1, 0, Std.int(255 * 0.25), 0, 0);
				else
					allCharacters[i].setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
			}
		}

		if (myStage.length > 0)
		{
			for (i in 0...myStage.length)
			{
				if (selectedStagePieces.contains(i))
					myStage[i].highlightState = 2;
				else
					myStage[i].highlightState = 0;
			}
		}
	}

	function refreshStage()
	{
		for (piece in myStage)
		{
			myStageGroup.remove(piece, true);
			piece.kill();
			piece.destroy();
		}
		myStage = [];

		while (allCharacters.length > stageData.characters.length)
		{
			var c:Character = allCharacters.pop();
			myStageGroup.remove(c, true);
			c.kill();
			c.destroy();
		}

		if (allCharacters.length < stageData.characters.length)
		{
			for (i in allCharacters.length...stageData.characters.length)
				spawnCharacter();
		}

		var poppers:Array<StagePiece> = [];
		for (i in 0...stageData.pieces.length)
		{
			if (stageData.pieces[i].type == "solid" || stageData.pieces[i].type == "group" || imageExists(stageData.pieces[i].asset))
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
		if (c.character != null && c.character != "")
			def = c.character;
		var newC:Character = new Character(c.position[0], c.position[1], def, c.flip);
		newC.scaleCharacter(c.scale[0], c.scale[1]);
		newC.scrollFactor.set(c.scrollFactor[0], c.scrollFactor[1]);
		allCharacters.push(newC);
		postSpawnCharacter(newC);
	}

	function applyCharacterValues(char:Character)
	{
		var c:StageCharacter = stageData.characters[allCharacters.indexOf(char)];
		char.repositionCharacter(c.position[0], c.position[1]);
		if (char.wasFlipped != c.flip)
			char.flip();
		char.scaleCharacter(c.scale[0], c.scale[1]);
		char.scrollFactor.set(c.scrollFactor[0], c.scrollFactor[1]);
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

		var piece:StageEditorPiece = null;

		switch (stagePiece.type)
		{
			case "static":
				piece = new StageEditorPiece();
				piece.loadGraphic(image(stagePiece.asset));
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

				piece = new StageEditorPiece(pieceFrames);
				var animList:Array<String> = [];
				for (anim in stagePiece.animations)
				{
					if (isSparrow)
					{
						if (anim.indices != null && anim.indices.length > 0)
							piece.animation.addByIndices(anim.name, anim.prefix, Character.uncompactIndices(anim.indices), "", anim.fps, anim.loop);
						else
							piece.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
					}
					else
						piece.animation.add(anim.name, Character.uncompactIndices(anim.indices), anim.fps, anim.loop);
					if (anim.offsets != null && anim.offsets.length == 2)
						piece.addOffsets(anim.name, anim.offsets);
					animList.push(anim.name);
				}
				if (animList.length > 0 && !animList.contains(stagePiece.firstAnimation))
					stagePiece.firstAnimation = animList[0];
				if (stagePiece.firstAnimation != null && stagePiece.firstAnimation != "")
					piece.animation.play(stagePiece.firstAnimation);

			case "tiled":
				if (stagePiece.tile == null || stagePiece.tile.length != 2)
					stagePiece.tile = [true, true];
				if (stagePiece.tileSpace == null || stagePiece.tileSpace.length != 2)
					stagePiece.tileSpace = [0, 0];
				piece = new StageEditorPiece().makeBackdrop(image(stagePiece.asset), 1, 1, stagePiece.tile[0], stagePiece.tile[1], stagePiece.tileSpace[0], stagePiece.tileSpace[1]);

			case "solid":
				piece = new StageEditorPiece();
				piece.makeGraphic(1, 1, FlxColor.WHITE);
				piece.active = false;
				piece.antialiasing = false;

			case "group":
				piece = new StageEditorPiece();
				piece.makeGraphic(1, 1, FlxColor.TRANSPARENT);
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

		if (stagePiece.updateHitbox || stagePiece.type == "solid")
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

		if (stagePiece.type != "solid")
			piece.antialiasing = stagePiece.antialias;

		if (stagePiece.color != null && stagePiece.color.length > 2)
			piece.color = FlxColor.fromRGB(stagePiece.color[0], stagePiece.color[1], stagePiece.color[2]);

		if (stagePiece.alpha != null && stagePiece.alpha != 1)
			piece.alpha *= stagePiece.alpha;

		if (stagePiece.blend != null && stagePiece.blend != "")
			piece.blend = stagePiece.blend;
		else
			piece.blend = "normal";

		if (stagePiece.type == "animated" && !sparrowExists(stagePiece.asset))
			piece.frames = tiles(stagePiece.asset, stagePiece.tileCount[0], stagePiece.tileCount[1]);

		@:privateAccess
		if (stagePiece.type == "tiled")
		{
			var sPiece:StageEditorPiece = cast piece;
			var tPiece:FlxBackdrop = sPiece.backdrop;
			tPiece._repeatX = stagePiece.tile[0];
			tPiece._repeatY = stagePiece.tile[1];
			tPiece._spaceX = stagePiece.tileSpace[0];
			tPiece._spaceY = stagePiece.tileSpace[1];
			tPiece.loadFrame(tPiece._tileFrame);
		}

		alignPiece(pieceId);
	}

	function updateAllPieces()
	{
		for (i in 0...stageData.pieces.length)
		{
			if (i < myStage.length)
			{
				var piece:FlxSprite = myStage[i];

				if (myStageGroup.members.contains(piece))
					myStageGroup.remove(piece, true);
			}
		}

		for (i in 0...stageData.characters.length)
		{
			if (i < allCharacters.length)
			{
				var piece:Character = allCharacters[i];

				if (myStageGroup.members.contains(piece))
					myStageGroup.remove(piece, true);
			}
		}

		for (i in 0...stageData.characters.length)
		{
			if (i < allCharacters.length)
			{
				var stagePiece:StageCharacter = stageData.characters[i];
				var piece:Character = allCharacters[i];

				var ind:Int = myStageGroup.members.length;
				for (j in 0...allCharacters.length)
				{
					if (stagePiece.layer < stageData.characters[j].layer && myStageGroup.members.contains(allCharacters[j]) && ind > myStageGroup.members.indexOf(allCharacters[j]))
						ind = myStageGroup.members.indexOf(allCharacters[j]);
				}
				addToStageGroup(ind, piece);
			}
		}

		for (i in 0...stageData.pieces.length)
		{
			if (i < myStage.length)
			{
				var stagePiece:StagePiece = stageData.pieces[i];
				var piece:FlxSprite = myStage[i];

				var ind:Int = myStageGroup.members.length;
				for (j in 0...allCharacters.length)
				{
					if (stagePiece.layer <= stageData.characters[j].layer && myStageGroup.members.contains(allCharacters[j]) && ind > myStageGroup.members.indexOf(allCharacters[j]))
						ind = myStageGroup.members.indexOf(allCharacters[j]);
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
		if (curCharacter > -1)
		{
			var index:Int = 0;
			for (i in 0...stagePieceList.length)
			{
				if (stagePieceList[i][1] == -curCharacter - 1)
					index = i;
			}

			if (index + dir < 0 || index + dir >= stagePieceList.length) return;

			var next:Int = stagePieceList[index + dir][1];
			if (next >= 0)
			{
				var c:StageCharacter = stageData.characters[curCharacter];
				if (dir > 0)
					stageData.pieces[next].layer = c.layer;
				else
					stageData.pieces[next].layer = c.layer + 1;
			}
			else
			{
				var c:StageCharacter = stageData.characters[-next - 1];
				var oldLayer:Int = stageData.characters[curCharacter].layer;
				stageData.characters[curCharacter].layer = c.layer;
				c.layer = oldLayer;
			}

			updateAllPieces();
			refreshStagePieces();
			refreshSelectionShader();
		}
		else if (curStagePiece > -1)
		{
			var index:Int = 0;
			for (i in 0...stagePieceList.length)
			{
				if (stagePieceList[i][1] == curStagePiece)
					index = i;
			}

			if (index + dir < 0 || index + dir >= stagePieceList.length) return;

			var next:Int = stagePieceList[index + dir][1];
			if (next >= 0)
			{
				var movePiece:StagePiece = stageData.pieces.splice(curStagePiece, 1)[0];
				var movePieceSprite:StageEditorPiece = myStage.splice(curStagePiece, 1)[0];

				if (curStagePiece + dir >= 0 && curStagePiece + dir <= stageData.pieces.length)
					curStagePiece += dir;

				stageData.pieces.insert(curStagePiece, movePiece);
				myStage.insert(curStagePiece, movePieceSprite);
			}
			else
			{
				var c:StageCharacter = stageData.characters[-next - 1];
				if (dir > 0)
					stageData.pieces[curStagePiece].layer = c.layer + 1;
				else
					stageData.pieces[curStagePiece].layer = c.layer;
			}

			selectedStagePieces = [curStagePiece];
			updateAllPieces();
			refreshStagePieces();
			refreshSelectionShader();
		}
	}

	function movePieceFully(dir:Int)
	{
		if (curCharacter > -1)
		{
			var index:Int = 0;
			for (i in 0...stagePieceList.length)
			{
				if (stagePieceList[i][1] == -curCharacter - 1)
					index = i;
			}

			while (index + dir >= 0 && index + dir < stagePieceList.length)
			{
				var next:Int = stagePieceList[index + dir][1];
				if (next >= 0)
				{
					var c:StageCharacter = stageData.characters[curCharacter];
					if (dir > 0)
						stageData.pieces[next].layer = c.layer;
					else
						stageData.pieces[next].layer = c.layer + 1;
				}
				else
				{
					var c:StageCharacter = stageData.characters[-next - 1];
					var oldLayer:Int = stageData.characters[curCharacter].layer;
					stageData.characters[curCharacter].layer = c.layer;
					c.layer = oldLayer;
				}
				index += dir;
			}

			updateAllPieces();
			refreshStagePieces();
			refreshSelectionShader();
		}
		else if (curStagePiece > -1)
		{
			var index:Int = 0;
			for (i in 0...stagePieceList.length)
			{
				if (stagePieceList[i][1] == curStagePiece)
					index = i;
			}

			while (index + dir >= 0 && index + dir < stagePieceList.length)
			{
				var next:Int = stagePieceList[index + dir][1];
				if (next >= 0)
				{
					var movePiece:StagePiece = stageData.pieces.splice(curStagePiece, 1)[0];
					var movePieceSprite:StageEditorPiece = myStage.splice(curStagePiece, 1)[0];

					if (curStagePiece + dir >= 0 && curStagePiece + dir <= stageData.pieces.length)
						curStagePiece += dir;

					stageData.pieces.insert(curStagePiece, movePiece);
					myStage.insert(curStagePiece, movePieceSprite);
				}
				else
				{
					var c:StageCharacter = stageData.characters[-next - 1];
					if (dir > 0)
						stageData.pieces[curStagePiece].layer = c.layer + 1;
					else
						stageData.pieces[curStagePiece].layer = c.layer;
				}
				index += dir;
			}

			selectedStagePieces = [curStagePiece];
			updateAllPieces();
			refreshStagePieces();
			refreshSelectionShader();
		}
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

	function refreshStagePieceList()
	{
		stagePieceList = [];
		for (i in 0...stageData.characters.length + 1)
		{
			for (p in stageData.pieces)
			{
				if (p.layer == i)
				{
					var checkId = p.asset;
					if (p.id != null && p.id.trim() != "")
						checkId = p.id;
					stagePieceList.push([checkId, stageData.pieces.indexOf(p)]);
				}
			}

			for (p in stageData.characters)
			{
				if (p.layer == i)
					stagePieceList.push(["Character " + Std.string(stageData.characters.indexOf(p) + 1), -stageData.characters.indexOf(p) - 1]);
			}
		}
	}

	function recalculateLayers()
	{
		var layer:Int = 0;
		for (p in stagePieceList)
		{
			if (p[1] < 0)
			{
				stageData.characters[Std.int(-p[1] - 1)].layer = layer;
				layer++;
			}
			else
				stageData.pieces[p[1]].layer = layer;
		}
	}

	function refreshStageShaders()
	{
		while (stageShaders.length < stageData.shaders.length)
		{
			var newShader:StageEditorShader = new StageEditorShader();
			newShader.setData(stageData.shaders[stageShaders.length]);
			stageShaders.push(newShader);
		}
	}

	function refreshAllShaders()
	{
		for (c in stageData.characters)
		{
			if (c.shader == null)
				c.shader = 0;
			if (c.shader - 1 >= stageData.shaders.length)
				c.shader = 0;

			if (c.shader > 0)
				allCharacters[stageData.characters.indexOf(c)].shader = stageShaders[c.shader - 1].shader;
			else if (stageData.defaultCharacterShader != null && stageData.defaultCharacterShader > 0)
				allCharacters[stageData.characters.indexOf(c)].shader = stageShaders[stageData.defaultCharacterShader - 1].shader;
			else
				allCharacters[stageData.characters.indexOf(c)].shader = null;
		}

		for (p in stageData.pieces)
		{
			if (p.shader == null)
				p.shader = 0;
			if (p.shader - 1 >= stageData.shaders.length)
				p.shader = 0;

			if (p.shader > 0)
				myStage[stageData.pieces.indexOf(p)].shader = stageShaders[p.shader - 1].shader;
			else
				myStage[stageData.pieces.indexOf(p)].shader = null;
		}
	}

	function refreshStagePieces()
	{
		refreshStagePieceList();

		if (selectedStagePieces.length == 1)
			stagePieceButtons.visible = true;
		else
			stagePieceButtons.visible = false;

		for (i in 0...stagePieceText.members.length)
			updateStagePiece(i);
	}

	function updateStagePiece(anim:Int)
	{
		if (stagePieceText != null && anim >= 0 && anim < stagePieceText.members.length)
		{
			var txt:FlxText = stagePieceText.members[anim];
			switch (anim)
			{
				case 0:
					if (listOffset >= 0)
					{
						txt.visible = true;
						txt.flipY = true;
						txt.text = "V";
					}
					else
						txt.visible = false;

				case 15:
					if (stagePieceList.length > anim + listOffset)
					{
						txt.visible = true;
						txt.text = "V";
					}
					else
						txt.visible = false;

				default:
					if (stagePieceList.length > anim + listOffset)
					{
						txt.visible = true;
						txt.text = stagePieceList[anim + listOffset][0];
						txt.ID = stagePieceList[anim + listOffset][1];
						if (selectedStagePieces.contains(txt.ID))
							txt.text = "> " + txt.text;
					}
					else
						txt.visible = false;
			}
		}
	}

	function undo()
	{
		if (undoPosition > 0)
		{
			undoPosition--;
			if (!unsaved)
			{
				unsaved = true;
				refreshFilename();
			}
			stageData = Cloner.clone(dataLog[undoPosition]);
			postUndoRedo();
		}
	}

	function redo()
	{
		if (undoPosition < dataLog.length - 1)
		{
			undoPosition++;
			if (!unsaved)
			{
				unsaved = true;
				refreshFilename();
			}
			stageData = Cloner.clone(dataLog[undoPosition]);
			postUndoRedo();
		}
	}

	function postUndoRedo()
	{
		pauseUndo = true;

		camGame.bgColor = FlxColor.fromRGB(stageData.bgColor[0], stageData.bgColor[1], stageData.bgColor[2]);
		refreshStage();
		for (c in allCharacters)
		{
			applyCharacterValues(c);
			postSpawnCharacter(c);
		}
		refreshStagePieces();
		refreshAllShaders();
		refreshSelectionShader();

		pauseUndo = false;
	}

	function assetExists(asset:String):Bool
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.exists("images/" + s + asset))
				return true;
		}
		return false;
	}

	function raw(asset:String):String
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.exists("images/" + s + asset))
				return Paths.raw("images/" + s + asset);
		}
		return "";
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



	function _new()
	{
		FlxG.switchState(new StageEditorState(true, "", ""));
	}

	function _open()
	{
		var file:FileBrowser = new FileBrowser();
		file.loadCallback = function(fullPath:String)
		{
			var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
			if (jsonNameArray.indexOf("stages") == -1)
				Application.current.window.alert("The file you have selected is not a stage.", "Alert");
			else
			{
				while (jsonNameArray[0] != "stages")
					jsonNameArray.remove(jsonNameArray[0]);
				jsonNameArray.remove(jsonNameArray[0]);

				var finalJsonName = jsonNameArray.join("/").split('.json')[0];

				FlxG.switchState(new StageEditorState(false, finalJsonName, fullPath));
			}
		}
		file.load();
	}

	function _save(?browse:Bool = true)
	{
		var saveData:StageData = Cloner.clone(stageData);

		if (saveData.script == "" || saveData.script == "stages/" + id)
			Reflect.deleteField(saveData, "script");

		if (!saveData.pixelPerfect)
			Reflect.deleteField(saveData, "pixelPerfect");

		if (saveData.bgColor[0] == 0 && saveData.bgColor[1] == 0 && saveData.bgColor[2] == 0)
			Reflect.deleteField(saveData, "bgColor");

		if (saveData.shaders != null && saveData.shaders.length <= 0)
			Reflect.deleteField(saveData, "shaders");

		if (saveData.defaultCharacterShader != null && saveData.defaultCharacterShader == 0)
			Reflect.deleteField(saveData, "defaultCharacterShader");

		for (c in saveData.characters)
		{
			c.character = allCharacters[saveData.characters.indexOf(c)].curCharacter;

			if (c.camPosition[0] == 0 && c.camPosition[1] == 0)
				Reflect.deleteField(c, "camPosition");

			if (!c.camPosAbsolute)
				Reflect.deleteField(c, "camPosAbsolute");

			if (c.scale[0] == 1 && c.scale[1] == 1)
				Reflect.deleteField(c, "scale");

			if (c.scrollFactor[0] == 1 && c.scrollFactor[1] == 1)
				Reflect.deleteField(c, "scrollFactor");

			if (c.shader == 0)
				Reflect.deleteField(c, "shader");
		}

		for (p in saveData.pieces)
		{
			if (p.visible)
				Reflect.deleteField(p, "visible");

			if (p.scale[0] == 1 && p.scale[1] == 1)
			{
				Reflect.deleteField(p, "scale");
				Reflect.deleteField(p, "updateHitbox");
			}

			if (p.align == "topleft")
				Reflect.deleteField(p, "align");

			if (p.scrollFactor[0] == 1 && p.scrollFactor[1] == 1)
				Reflect.deleteField(p, "scrollFactor");

			if (p.flip[0] == false && p.flip[1] == false)
				Reflect.deleteField(p, "flip");

			if (DeepEquals.deepEquals(p.color, [255, 255, 255]))
				Reflect.deleteField(p, "color");

			if (p.alpha == 1)
				Reflect.deleteField(p, "alpha");

			if (p.blend == "normal")
				Reflect.deleteField(p, "blend");

			if (p.shader == 0)
				Reflect.deleteField(p, "shader");

			if (p.type != "tiled")
			{
				Reflect.deleteField(p, "tile");
				Reflect.deleteField(p, "tileSpace");
				Reflect.deleteField(p, "velocity");
				Reflect.deleteField(p, "velocityMultipliedByScroll");
			}

			if (p.type != "animated" || sparrowExists(p.asset))
				Reflect.deleteField(p, "tileCount");
		}

		var data:String = Json.stringify(saveData, null, "\t");
		if (Options.options.compactJsons)
			data = Json.stringify(saveData);

		if (data != null && data.length > 0)
		{
			if (browse || filename == "")
			{
				var file:FileBrowser = new FileBrowser();
				file.saveCallback = changeSaveName;
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
}