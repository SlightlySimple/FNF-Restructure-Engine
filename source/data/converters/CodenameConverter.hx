package data.converters;

import haxe.Json;
import haxe.xml.Access;
import haxe.ds.ArraySort;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import sys.FileSystem;
import sys.io.File;
import data.ObjectData;
import data.Song;
import objects.Character;
import editors.chart.ChartEditorState;

import newui.UIControl;
import newui.Button;
import newui.InputText;
import newui.Label;
import newui.PopupWindow;

using StringTools;

class CodenameConverter
{
	public static function convertCharacter()
	{
		var window:PopupWindow = null;
		var vbox:VBox = new VBox(35, 35);

		vbox.add(new Label("Old character .xml:"));
		var jsonHBox:HBox = new HBox();
		var jsonInput:InputText = new InputText(0, 0, "");
		jsonHBox.add(jsonInput);
		var jsonBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = function(fullPath:String) {
				jsonInput.text = fullPath.replace('\\','/');
			}
			file.load("xml");
		});
		jsonHBox.add(jsonBrowse);
		vbox.add(jsonHBox);

		vbox.add(new Label("Old character sprite sheet folder (ex. \"images/characters\"):"));
		var imageHBox:HBox = new HBox();
		var imageInput:InputText = new InputText(0, 0, "");
		imageHBox.add(imageInput);
		var imageBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = function(fullPath:String) {
				var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
				nameArray.pop();

				var finalName = nameArray.join("/");
				imageInput.text = finalName;
			}
			file.load("png");
		});
		imageHBox.add(imageBrowse);
		vbox.add(imageHBox);

		vbox.add(new Label("New character sprite sheet folder (ex. \"images/characters\"):"));
		var finalImageHBox:HBox = new HBox();
		var finalImageInput:InputText = new InputText(0, 0, "");
		finalImageHBox.add(finalImageInput);
		var finalImageBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = function(fullPath:String) {
				var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
				nameArray.pop();

				if (nameArray.contains("images"))
				{
					var finalName = nameArray.join("/");
					finalImageInput.text = finalName;
				}
				else
					new Notify("The file path does not contain an \"images\" folder");
			}
			file.savePath("*.*");
		});
		finalImageHBox.add(finalImageBrowse);
		vbox.add(finalImageHBox);

		vbox.add(new Label("New character .json folder (ex. \"data/characters\"):"));
		var finalHBox:HBox = new HBox();
		var finalInput:InputText = new InputText(0, 0, "");
		finalHBox.add(finalInput);
		var finalBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = function(fullPath:String) {
				var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
				nameArray.pop();

				if (nameArray.contains("characters"))
				{
					var finalName = nameArray.join("/");
					finalInput.text = finalName;
				}
				else
					new Notify("The file path does not contain a \"characters\" folder");
			}
			file.savePath("*.*");
		});
		finalHBox.add(finalBrowse);
		vbox.add(finalHBox);

		var btnHbox:HBox = new HBox();

		var convert:TextButton = new TextButton(0, 0, "Convert", function() {
			var pathArray:Array<String> = jsonInput.text.replace('\\','/').split('/');
			var convertedCharacterId:String = pathArray[pathArray.length - 1].replace(".xml", ".json");

			if (FileSystem.exists(jsonInput.text))
			{
				var character:Access = new Access(Xml.parse(File.getContent(jsonInput.text)).firstElement());

				var prevImageArray:Array<String> = StringTools.replace(character.att.sprite, '\\','/').split('/');
				var prevImage:String = prevImageArray[prevImageArray.length - 1];

				var imagePathArray:Array<String> = imageInput.text.replace('\\','/').split('/');
				imagePathArray.push(prevImage);

				var trueImagePath:String = imagePathArray.join("/");

				pathArray = finalImageInput.text.replace('\\','/').split('/');
				while (pathArray[0] != "images")
					pathArray.shift();
				pathArray.shift();
				var finalAssetSavePath:String = pathArray.join("/");

				var assetPastePath:String = finalImageInput.text;
				var trueSavePath:String = finalInput.text;

				var finalChar:CharacterData = {
					fixes: 0,
					asset: finalAssetSavePath + "/" + prevImage,
					position: [0, 0],
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

				if (character.has.x)
					finalChar.position[0] = Std.parseInt(character.att.x);
				if (character.has.y)
					finalChar.position[1] = Std.parseInt(character.att.y);
				if (character.has.flipX)
					finalChar.flip = (character.att.flipX == "true");
				if (character.has.isPlayer && character.att.isPlayer == "true")
				{
					finalChar.facing = "left";
					finalChar.camPosition[0] = 100;
				}
				if (character.has.scale)
					finalChar.scale = [Std.parseFloat(character.att.scale), Std.parseFloat(character.att.scale)];
				if (character.has.camx)
					finalChar.camPosition[0] = Std.parseInt(character.att.camx);
				if (character.has.camy)
					finalChar.camPosition[1] = Std.parseInt(character.att.camy);
				if (character.has.icon)
					finalChar.icon = character.att.icon;
				if (character.has.antialiasing)
					finalChar.antialias = (character.att.antialiasing == "true");
				if (character.has.color)
				{
					var healthbarColor:FlxColor = FlxColor.fromString(character.att.color);
					finalChar.healthbarColor = [healthbarColor.red, healthbarColor.green, healthbarColor.blue];
				}

				for (a in character.nodes.anim)
				{
					var anim:CharacterAnimation = {name: a.att.name, offsets: [0, 0]};
					if (a.has.anim)
						anim.prefix = a.att.anim;
					if (a.has.x)
						anim.offsets[0] = Std.parseInt(a.att.x);
					if (a.has.y)
						anim.offsets[1] = Std.parseInt(a.att.y);
					if (a.has.fps)
						anim.fps = Std.parseInt(a.att.fps);
					if (a.has.loop)
						anim.loop = (a.att.loop == "true");
					if (a.has.indices)
					{
						var _ind:String = a.att.indices;
						if (_ind.indexOf("..") > 0)
							_ind = "-1," + _ind.replace("..", ",");
						var _indArray:Array<Int> = [];
						for (_in in _ind.split(","))
							_indArray.push(Std.parseInt(_in));
						anim.indices = Character.uncompactIndices(_indArray);
					}

					finalChar.animations.push(anim);
					if (anim.name == "danceLeft")
					{
						finalChar.idles = ["danceLeft", "danceRight"];
						finalChar.firstAnimation = "danceLeft";
					}
				}

				File.saveContent(trueSavePath + "/" + convertedCharacterId, Json.stringify(finalChar));

				if (FileSystem.exists(trueImagePath + ".png"))
					File.copy(trueImagePath + ".png", assetPastePath + "/" + prevImage + ".png");
				if (FileSystem.exists(trueImagePath + ".xml"))
					File.copy(trueImagePath + ".xml", assetPastePath + "/" + prevImage + ".xml");
				if (FileSystem.exists(trueImagePath + ".txt"))
					File.copy(trueImagePath + ".txt", assetPastePath + "/" + prevImage + ".txt");

				new Notify("Successfully converted the character \"" + convertedCharacterId.replace(".json", "") + "\" from Codename Engine");
			}
		});
		btnHbox.add(convert);

		var close:TextButton = new TextButton(0, 0, "Close", function() { window.close(); });
		btnHbox.add(close);

		vbox.add(btnHbox);

		window = PopupWindow.CreateWithGroup(vbox);
	}

	public static function convertStage()
	{
		var window:PopupWindow = null;
		var vbox:VBox = new VBox(35, 35);

		vbox.add(new Label("Old stage .xml:"));
		var jsonHBox:HBox = new HBox();
		var jsonInput:InputText = new InputText(0, 0, "");
		jsonHBox.add(jsonInput);
		var jsonBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = function(fullPath:String) {
				jsonInput.text = fullPath.replace('\\','/');
			}
			file.load("xml");
		});
		jsonHBox.add(jsonBrowse);
		vbox.add(jsonHBox);

		vbox.add(new Label("Old stage sprite folder:"));
		var imageHBox:HBox = new HBox();
		var imageInput:InputText = new InputText(0, 0, "");
		imageHBox.add(imageInput);
		var imageBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = function(fullPath:String) {
				var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
				nameArray.pop();

				var finalName = nameArray.join("/");
				imageInput.text = finalName;
			}
			file.load("png");
		});
		imageHBox.add(imageBrowse);
		vbox.add(imageHBox);

		vbox.add(new Label("New stage sprite folder (ex. \"images/stages/stageNameHere\"):"));
		var finalImageHBox:HBox = new HBox();
		var finalImageInput:InputText = new InputText(0, 0, "");
		finalImageHBox.add(finalImageInput);
		var finalImageBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = function(fullPath:String) {
				var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
				nameArray.pop();

				if (nameArray.contains("images"))
				{
					var finalName = nameArray.join("/");
					finalImageInput.text = finalName;
				}
				else
					new Notify("The file path does not contain an \"images\" folder");
			}
			file.savePath("*.*");
		});
		finalImageHBox.add(finalImageBrowse);
		vbox.add(finalImageHBox);

		vbox.add(new Label("New stage .json folder (ex. \"data/stages\"):"));
		var finalHBox:HBox = new HBox();
		var finalInput:InputText = new InputText(0, 0, "");
		finalHBox.add(finalInput);
		var finalBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = function(fullPath:String) {
				var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
				nameArray.pop();

				if (nameArray.contains("stages"))
				{
					var finalName = nameArray.join("/");
					finalInput.text = finalName;
				}
				else
					new Notify("The file path does not contain a \"stages\" folder");
			}
			file.savePath("*.*");
		});
		finalHBox.add(finalBrowse);
		vbox.add(finalHBox);

		var btnHbox:HBox = new HBox();

		var convert:TextButton = new TextButton(0, 0, "Convert", function() {
			var pathArray:Array<String> = jsonInput.text.replace('\\','/').split('/');
			var convertedStageId:String = pathArray[pathArray.length - 1].replace(".xml", ".json");

			if (FileSystem.exists(jsonInput.text))
			{
				var stage:Xml = Xml.parse(File.getContent(jsonInput.text)).firstElement();

				pathArray = imageInput.text.replace('\\','/').split('/');
				while (pathArray[0] != "images")
					pathArray.shift();
				pathArray.shift();
				var finalAssetPath:String = pathArray.join("/");

				pathArray = imageInput.text.replace('\\','/').split('/');

				var assetCopyPath1:String = pathArray.join("/");
				while (pathArray[pathArray.length - 1] != "images")
					pathArray.pop();
				var assetCopyPath2:String = pathArray.join("/");

				pathArray = finalImageInput.text.replace('\\','/').split('/');
				while (pathArray[0] != "images")
					pathArray.shift();
				pathArray.shift();
				var finalAssetSavePath:String = pathArray.join("/");

				var assetPastePath:String = finalImageInput.text;

				var assetList:Array<String> = [];

				var trueSavePath:String = finalInput.text;

				var finalStage:StageData = {
					searchDirs: [finalAssetSavePath + "/"],
					fixes: 1,
					characters: [{position: [770, 100], camPosition: [0, 0], flip: true},
					{position: [100, 100], camPosition: [0, 0], flip: false},
					{position: [400, 130], camPosition: [0, 0], flip: false, scrollFactor: [0.95, 0.95]}],
					camZoom: 1,
					camFollow: [640, 360],
					bgColor: [0, 0, 0],
					pixelPerfect: false,
					pieces: []
				};

				if (stage.get("startCamPosX") != null)
					finalStage.camFollow[0] = Std.parseInt(stage.get("startCamPosX"));
				if (stage.get("startCamPosY") != null)
					finalStage.camFollow[1] = Std.parseInt(stage.get("startCamPosY"));
				if (stage.get("zoom") != null)
					finalStage.camZoom = Std.parseFloat(stage.get("zoom"));

				var curLayer:Int = 0;
				for (e in stage.elements())
				{
					var characterId:Int = -1;
					switch (e.nodeName)
					{
						case "high-memory":
							for (_e in e.elements())
							{
								var stagePiece:StagePiece = parseStageSprite(_e, curLayer);
								finalStage.pieces.push(stagePiece);

								if (stagePiece.asset != "")
								{
									if (!assetList.contains(stagePiece.asset + ".png"))
										assetList.push(stagePiece.asset + ".png");
									if (stagePiece.type == "animated" && !assetList.contains(stagePiece.asset + ".xml"))
										assetList.push(stagePiece.asset + ".xml");
								}
							}

						case "boyfriend" | "bf" | "player":
							characterId = 0;

						case "dad" | "opponent":
							characterId = 1;

						case "girlfriend" | "gf":
							characterId = 2;

						case "sprite" | "spr" | "sparrow":
							var stagePiece:StagePiece = parseStageSprite(e, curLayer);
							finalStage.pieces.push(stagePiece);

							if (stagePiece.asset != "")
							{
								if (!assetList.contains(stagePiece.asset + ".png"))
									assetList.push(stagePiece.asset + ".png");
								if (stagePiece.type == "animated" && !assetList.contains(stagePiece.asset + ".xml"))
									assetList.push(stagePiece.asset + ".xml");
							}
					}

					if (characterId >= 0)
					{
						if (e.get("x") != null)
							finalStage.characters[characterId].position[0] = Std.parseInt(e.get("x"));
						if (e.get("y") != null)
							finalStage.characters[characterId].position[1] = Std.parseInt(e.get("y"));
						if (e.get("camxoffset") != null)
							finalStage.characters[characterId].camPosition[0] = Std.parseInt(e.get("camxoffset"));
						if (e.get("camyoffset") != null)
							finalStage.characters[characterId].camPosition[1] = Std.parseInt(e.get("camyoffset"));
						if (e.get("scale") != null)
							finalStage.characters[characterId].scale = [Std.parseFloat(e.get("scale")), Std.parseFloat(e.get("scale"))];
						if (e.get("scroll") != null)
							finalStage.characters[characterId].scrollFactor = [Std.parseFloat(e.get("scroll")), Std.parseFloat(e.get("scroll"))];
						finalStage.characters[characterId].layer = curLayer;
						curLayer++;
					}
				}

				finalStage.characters[2].position[0] += 140;
				finalStage.characters[2].position[1] -= 80;

				File.saveContent(trueSavePath + "/" + convertedStageId, Json.stringify(finalStage));

				if (!FileSystem.isDirectory(assetPastePath))
					FileSystem.createDirectory(assetPastePath);

				for (asset in assetList)
				{
					if (asset.indexOf("/") > -1 || asset.indexOf("\\") > -1)
					{
						var assetDirSplit:Array<String> = asset.replace("\\", "/").split("/");
						assetDirSplit.pop();
						var assetDir:String = assetDirSplit.join("/");
						if (!FileSystem.isDirectory(assetPastePath + "/" + assetDir))
							FileSystem.createDirectory(assetPastePath + "/" + assetDir);
					}

					if (FileSystem.exists(assetCopyPath1 + "/" + asset))
						File.copy(assetCopyPath1 + "/" + asset, assetPastePath + "/" + asset);
					else if (FileSystem.exists(assetCopyPath2 + "/" + asset))
						File.copy(assetCopyPath2 + "/" + asset, assetPastePath + "/" + asset);
				}

				new Notify("Successfully converted the stage \"" + convertedStageId.replace(".json", "") + "\" from Codename Engine");
			}
		});
		btnHbox.add(convert);

		var close:TextButton = new TextButton(0, 0, "Close", function() { window.close(); });
		btnHbox.add(close);

		vbox.add(btnHbox);

		window = PopupWindow.CreateWithGroup(vbox);
	}

	static function parseStageSprite(e:Xml, layer:Int):StagePiece
	{
		var stagePiece:StagePiece = {
			id: "",
			type: "static",
			asset: "",
			position: [0, 0],
			layer: layer,
			antialias: true,
			flip: [false, false]
		};

		if (e.get("name") != null)
			stagePiece.id = e.get("name");
		if (e.get("sprite") != null)
			stagePiece.asset = e.get("sprite");
		if (e.get("x") != null)
			stagePiece.position[0] = Std.parseInt(e.get("x"));
		if (e.get("y") != null)
			stagePiece.position[1] = Std.parseInt(e.get("y"));
		if (e.get("scale") != null)
		{
			stagePiece.scale = [Std.parseFloat(e.get("scale")), Std.parseFloat(e.get("scale"))];
			if (e.get("updateHitbox") != null)
				stagePiece.updateHitbox = (e.get("updateHitbox") == "true");
			else
				stagePiece.updateHitbox = false;
		}
		if (e.get("antialiasing") != null)
			stagePiece.antialias = (e.get("antialiasing") == "true");

		var animated:Bool = false;
		var type:String = "onbeat";
		if (e.get("type") != null)
		{
			if (e.get("type") == "loop" || e.get("type") == "onbeat")
			{
				animated = true;
				type = e.get("type");
			}
		}
		var elem:Int = 0;
		for (_e in e.elements())
			elem++;

		if (elem > 0)
			animated = true;

		if (animated)
		{
			stagePiece.type = "animated";
			stagePiece.animations = [];
			stagePiece.idles = [];
			var animNames:Array<String> = [];

			for (_e in e.elements())
			{
				var stagePieceAnim:StageAnimation = {
					name: "",
					prefix: "",
					fps: 24,
					loop: false
				};

				if (_e.get("name") != null)
					stagePieceAnim.name = _e.get("name");
				if (_e.get("anim") != null)
					stagePieceAnim.prefix = _e.get("anim");
				if (_e.get("fps") != null)
					stagePieceAnim.fps = Std.parseInt(_e.get("fps"));
				if (_e.get("loop") != null)
					stagePieceAnim.loop = (_e.get("loop") == "true");
				if (_e.get("indices") != null)
				{
					var _ind:String = _e.get("indices");
					if (_ind.indexOf("..") > 0)
						_ind = "-1," + _ind.replace("..", ",");
					var _indArray:Array<Int> = [];
					for (_in in _ind.split(","))
						_indArray.push(Std.parseInt(_in));
					stagePieceAnim.indices = Character.uncompactIndices(_indArray);
				}

				stagePiece.animations.push(stagePieceAnim);
				animNames.push(stagePieceAnim.name);
			}

			if (stagePiece.animations.length <= 0)
			{
				var stagePieceAnim:StageAnimation = {
					name: "idle",
					prefix: "",
					fps: 24,
					loop: (type == "loop")
				};
				stagePiece.animations.push(stagePieceAnim);
				animNames.push(stagePieceAnim.name);
			}
			stagePiece.firstAnimation = animNames[0];
			if (type == "onbeat")
			{
				if (animNames.contains("idle"))
					stagePiece.idles = ["idle"];
				else if (animNames.contains("danceLeft") && animNames.contains("danceRight"))
					stagePiece.idles = ["danceLeft", "danceRight"];
				stagePiece.beatAnimationSpeed = 1;
				if (e.get("beatInterval") != null)
					stagePiece.beatAnimationSpeed = Std.parseFloat(e.get("beatInterval"));
			}
		}

		return stagePiece;
	}

	public static function convertChart(callback:Void->Void)
	{
		var window:PopupWindow = null;
		var vbox:VBox = new VBox(35, 35);

		vbox.add(new Label("Old chart meta.json (ex. \"songs/songname/meta.json\"):"));
		var jsonHBox:HBox = new HBox();
		var jsonInput:InputText = new InputText(0, 0, "");
		jsonHBox.add(jsonInput);
		var jsonBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = function(fullPath:String) {
				jsonInput.text = fullPath.replace('\\','/');
			}
			file.load("json");
		});
		jsonHBox.add(jsonBrowse);
		vbox.add(jsonHBox);

		vbox.add(new Label("New chart .json folder (ex. \"data/songs/songname\"):"));
		var finalHBox:HBox = new HBox();
		var finalInput:InputText = new InputText(0, 0, "");
		finalHBox.add(finalInput);
		var finalBrowse:Button = new Button(0, 0, "buttonLoad", function() {
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = function(fullPath:String) {
				var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
				nameArray.pop();

				if (nameArray.contains("songs"))
				{
					var finalName = nameArray.join("/");
					finalInput.text = finalName;
				}
				else
					new Notify("The file path does not contain a \"songs\" folder");
			}
			file.savePath("*.*");
		});
		finalHBox.add(finalBrowse);
		vbox.add(finalHBox);

		var btnHbox:HBox = new HBox();

		var convert:TextButton = new TextButton(0, 0, "Convert", function() {
			if (jsonInput.text.indexOf("meta.json") > -1)
			{
				var pathArray:Array<String> = jsonInput.text.replace('\\','/').split('/');
				pathArray.pop();
				var convertedSongId:String = pathArray[pathArray.length - 1].toLowerCase().replace(" ", "-");
				var songFolder:String = pathArray.join("/");
				var metadata:Dynamic = Json.parse(File.getContent(jsonInput.text));

				var trueSavePath:String = finalInput.text;

				var difficulties:Array<String> = cast metadata.difficulties;
				if (difficulties == null)
				{
					difficulties = [];
					for (file in FileSystem.readDirectory(songFolder + "/charts/"))
					{
						if (file.toLowerCase().endsWith(".json"))
							difficulties.push(file.substr(0, file.length - 5));
					}
				}

				for (d in difficulties)
				{
					var chart:Dynamic = Json.parse(File.getContent(songFolder + "/charts/" + d.toLowerCase() + ".json"));

					var camEvents:Array<Array<Dynamic>> = [];
					var convertedEvents:Array<Dynamic> = [];
					if (FileSystem.exists(songFolder + "/events.json"))
						convertedEvents = cast Json.parse(File.getContent(songFolder + "/events.json")).events;
					else if (chart.events != null && chart.events.length > 0)
						convertedEvents = cast chart.events;

					for (e in convertedEvents)
					{
						if (e.name == "Camera Movement")
						{
							var p:Array<Int> = cast e.params;
							camEvents.push([e.time, p[0]]);
						}
					}
					if (camEvents[0][0] > 0)
						camEvents.unshift([0, camEvents[0][1]]);
					ArraySort.sort(camEvents, function(a:Array<Dynamic>, b:Array<Dynamic>) {
						if (a[0] < b[0])
							return -1;
						if (a[0] > b[0])
							return 1;
						return 0;
					});

					var tracks:Array<Array<Dynamic>> = [["Inst", 0]];
					var strumLines:Array<Dynamic> = cast chart.strumLines;
					if (strumLines.length > 1)
					{
						tracks.push(["Voices" + strumLines[1].vocalsSuffix, 2]);
						if (strumLines[1].vocalsSuffix != strumLines[0].vocalsSuffix)
							tracks.push(["Voices" + strumLines[0].vocalsSuffix, 3]);
					}

					var newChart:SongData = {
						song: metadata.displayName,
						artist: "",
						charter: "",
						preview: [0, 32],
						ratings: [0, 0],
						tracks: tracks,
						offset: 0,
						characters: ["none", "none"],
						stage: chart.stage,
						bpmMap: [],
						speed: chart.scrollSpeed,
						columns: [],
						notes: [],
						metaFile: "",
						eventFile: "_events"
					};

					if (strumLines.length > 1)
					{
						newChart.characters = [strumLines[1].characters[0], strumLines[0].characters[0]];
						if (strumLines.length > 2)
						{
							for (i in 2...strumLines.length)
								newChart.characters.push(strumLines[i].characters[0]);
						}
					}

					var bpmMap:Array<Array<Float>> = [];
					var timeChanges:Array<Array<Float>> = [[0, metadata.bpm]];
					for (e in convertedEvents)
					{
						if (e.name == "BPM Change")
						{
							var p:Array<Int> = cast e.params;
							timeChanges.push([e.time, p[0]]);
						}
					}
					ArraySort.sort(timeChanges, function(a:Array<Float>, b:Array<Float>) {
						if (a[0] < b[0])
							return -1;
						if (a[0] > b[0])
							return 1;
						return 0;
					});

					var totalBeats:Float = 0;
					var lastTime:Float = 0;
					var lastBPM:Float = timeChanges[0][1];
					for (t in timeChanges)
					{
						totalBeats += ((t[0] - lastTime) / 1000) * (lastBPM / 60);
						bpmMap.push([totalBeats, t[1]]);
						lastTime = t[0];
						lastBPM = t[1];
					}

					newChart.bpmMap = bpmMap;
					var timingStruct:TimingStruct = new TimingStruct();
					timingStruct.recalculateTimings(newChart.bpmMap);

					var track:FlxSound = new FlxSound().loadEmbedded(songFolder + "/song/Inst.ogg");
					for (i in 0...camEvents.length)
					{
						var newSection:SectionData = {sectionNotes: [], lengthInSteps: 64, camOn: 0};
						if (i < camEvents.length - 1)
							newSection.lengthInSteps = Std.int(Math.round(timingStruct.stepFromTime(camEvents[i + 1][0])) - Math.round(timingStruct.stepFromTime(camEvents[i][0])));
						else
						{
							newSection.lengthInSteps = Std.int(Math.ceil(timingStruct.stepFromTime(track.length)) - Math.round(timingStruct.stepFromTime(camEvents[i][0])));
							if (newSection.lengthInSteps < 4)
								newSection.lengthInSteps = 4;
						}

						newSection.camOn = (camEvents[i][1] == 1 ? 0 : 1);

						if (newSection.lengthInSteps > 0)
							newChart.notes.push(newSection);
					}

					if (newChart.notes.length <= 0)
					{
						var totalSections:Int = Std.int(Math.ceil(timingStruct.beatFromTime(track.length) / 4));
						if (totalSections < 1)
							totalSections = 1;
						for (i in 0...totalSections)
							newChart.notes.push({sectionNotes: [], lengthInSteps: 16, camOn: 0});
					}

					var noteTypes:Array<String> = [];
					if (chart.noteTypes != null)
						noteTypes = cast chart.noteTypes;
					noteTypes.unshift("");

					var firstNote:Float = -1;
					var firstColumn:Int = 0;
					for (i in 0...strumLines.length)
					{
						var newNotes:Array<Dynamic> = cast strumLines[i].notes;

						if (newNotes != null && newNotes.length > 0)
						{
							for (n in newNotes)
							{
								var column:Int = Std.int(n.id) + firstColumn;

								var len:Float = 0;
								if (n.sLen != null)
									len = n.sLen;

								var kind:String = "";
								if (n.type != null && n.type < noteTypes.length)
									kind = noteTypes[Std.int(n.type)];

								if (firstNote == -1 || n.time < firstNote)
									firstNote = n.time;
								newChart.notes[0].sectionNotes.push([n.time, column, len, kind]);
							}

							var strumCount:Int = 4;
							if (strumLines[i].keyCount != null)
								strumCount = strumLines[i].keyCount;

							for (j in 0...strumCount)
							{
								if (i < 2)
									newChart.columns.push({division: 1 - i});
								else
									newChart.columns.push({division: i});
							}

							firstColumn += strumCount;
						}
					}

					var firstBeat:Float = Math.max(0, Math.floor(timingStruct.beatFromTime(firstNote)));
					newChart.preview = [firstBeat, firstBeat + 32];

					var parsedData:SongData = Song.parseSongData(newChart, false, false);
					parsedData.useBeats = true;
					File.saveContent(trueSavePath + "/" + convertedSongId + "-" + d.toLowerCase() + ".json", Json.stringify({song: ChartEditorState.prepareChartSave(parsedData)}));

					for (t in tracks)
					{
						if (FileSystem.exists(songFolder + "/song/" + t[0] + ".ogg") && !FileSystem.exists(trueSavePath + "/" + t[0] + ".ogg"))
							File.copy(songFolder + "/song/" + t[0] + ".ogg", trueSavePath + "/" + t[0] + ".ogg");
					}
				}
				new Notify("Successfully converted the song \"" + convertedSongId + "\" from Codename Engine");
			}
			else
				new Notify("The first file has to be a \"meta.json\" file from a Codename Engine chart");
		});
		btnHbox.add(convert);

		var close:TextButton = new TextButton(0, 0, "Close", function() { window.close(); callback(); });
		btnHbox.add(close);

		vbox.add(btnHbox);

		window = PopupWindow.CreateWithGroup(vbox);
	}
}