package data.converters;

import flixel.FlxG;
import haxe.Json;
import haxe.xml.Access;
import sys.FileSystem;
import sys.io.File;
import data.ObjectData;

import newui.UIControl;
import newui.Button;
import newui.InputText;
import newui.Label;
import newui.PopupWindow;

using StringTools;

class PsychConverter
{
	public static function convertCharacter()
	{
		var window:PopupWindow = null;
		var vbox:VBox = new VBox(35, 35);

		vbox.add(new Label("Old character .json:"));
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
			var convertedCharacterId:String = pathArray[pathArray.length - 1];

			if (FileSystem.exists(jsonInput.text))
			{
				var character:Dynamic = Json.parse(File.getContent(jsonInput.text));
				if (character.image != null)
				{
					var prevImageArray:Array<String> = StringTools.replace(character.image, '\\','/').split('/');
					var prevImage:String = prevImageArray[prevImageArray.length - 1];

					var imagePathArray:Array<String> = imageInput.text.replace('\\','/').split('/');
					imagePathArray.push(prevImage);

					var trueImagePath:String = imagePathArray.join("/");
					if (FileSystem.exists(trueImagePath + ".xml") || FileSystem.exists(trueImagePath + ".txt"))
					{
						var frames:Array<Dynamic> = [];

						if (FileSystem.exists(trueImagePath + ".txt"))
						{
							var txtRaw:String = File.getContent(trueImagePath + ".txt");
							var txtSplit:Array<String> = txtRaw.replace("\r","").replace("\t","").split("\n");
							for (f in txtSplit)
							{
								var fSplit:Array<String> = f.split(" = ");
								frames.push({name: fSplit[0], w: fSplit[1].split(" ")[2], h: fSplit[1].split(" ")[3]});
							}
						}
						else
						{
							var xmlRaw:String = File.getContent(trueImagePath + ".xml");
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
							position: character.position,
							camPosition: [Std.int(character.camera_position[0] + (character.flip_x ? 100 : 150)), Std.int(character.camera_position[1] - 100)],
							camPositionGameOver: [0, 0],
							scale: [character.scale, character.scale],
							antialias: !character.no_antialiasing,
							animations: [],
							firstAnimation: character.animations[0].anim,
							idles: ["idle"],
							danceSpeed: 2,
							flip: character.flip_x,
							facing: (character.flip_x ? "left" : "right"),
							icon: character.healthicon,
							healthbarColor: character.healthbar_colors
						};

						if (finalChar.icon == convertedCharacterId.replace(".json", ""))
							finalChar.icon = "";

						var allAnims:Array<String> = [];
						var dataAnims:Array<Dynamic> = cast character.animations;
						for (a in dataAnims)
						{
							var cAnim:CharacterAnimation = {
								name: a.anim,
								prefix: a.name,
								fps: a.fps,
								loop: a.loop,
								flipX: false,
								flipY: false,
								offsets: a.offsets
							}
							if (a.indices != null && a.indices.length > 0)
								cAnim.indices = a.indices;
							finalChar.animations.push(cAnim);
							if (cAnim.name == "danceLeft")
							{
								finalChar.idles = ["danceLeft", "danceRight"];
								finalChar.danceSpeed = 1;
								finalChar.firstAnimation = "danceLeft";
							}
							else if (cAnim.name == "idle")
								finalChar.firstAnimation = "idle";

							if (cAnim.name == "firstDeath")
								finalChar.gameOverCharacter = "_self";

							allAnims.push(cAnim.name);
						}

						var firstFrame = frames[0];
						var firstAnimFrame = null;
						var firstAnimFrameName = finalChar.animations[allAnims.indexOf(finalChar.firstAnimation)].prefix;
						for (f in frames)
						{
							if (f.name != null && StringTools.startsWith(f.name, firstAnimFrameName))
							{
								firstAnimFrame = f;
								break;
							}
						}
						if (firstFrame != firstAnimFrame)
						{
							finalChar.camPosition[0] += Std.int((Std.parseFloat(firstFrame.w) - Std.parseFloat(firstAnimFrame.w)) * finalChar.scale[0] * 0.5);
							finalChar.camPosition[1] += Std.int((Std.parseFloat(firstFrame.h) - Std.parseFloat(firstAnimFrame.h)) * finalChar.scale[1] * 0.5);
							if (finalChar.scale[0] != 1)
							{
								finalChar.position[0] += Std.int((Std.parseFloat(firstFrame.w) - Std.parseFloat(firstAnimFrame.w)) * (1 - finalChar.scale[0]) * 0.5);
								finalChar.position[1] += Std.int((Std.parseFloat(firstFrame.h) - Std.parseFloat(firstAnimFrame.h)) * (1 - finalChar.scale[1]) * 0.5);
								finalChar.camPosition[0] -= Std.int((Std.parseFloat(firstFrame.w) - Std.parseFloat(firstAnimFrame.w)) * (1 - finalChar.scale[0]) * 0.5);
								finalChar.camPosition[1] -= Std.int((Std.parseFloat(firstFrame.h) - Std.parseFloat(firstAnimFrame.h)) * (1 - finalChar.scale[1]) * 0.5);
							}
						}

						File.saveContent(trueSavePath + "/" + convertedCharacterId, Json.stringify(finalChar));

						if (FileSystem.exists(trueImagePath + ".png"))
							File.copy(trueImagePath + ".png", assetPastePath + "/" + prevImage + ".png");
						if (FileSystem.exists(trueImagePath + ".xml"))
							File.copy(trueImagePath + ".xml", assetPastePath + "/" + prevImage + ".xml");
						if (FileSystem.exists(trueImagePath + ".txt"))
							File.copy(trueImagePath + ".txt", assetPastePath + "/" + prevImage + ".txt");

						new Notify("Successfully converted the character \"" + convertedCharacterId.replace(".json", "") + "\" from Psych Engine");
					}
					else
						new Notify("The character's sprite sheet could not be located. Ensure that the sprite sheet has an associated .xml or .txt file");
				}
				else
					new Notify("The .json file does not seem to be a Psych Engine character");
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

		vbox.add(new Label("Old stage .json:"));
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
			var convertedStageId:String = pathArray[pathArray.length - 1];

			var stage:Dynamic = Json.parse(File.getContent(jsonInput.text));
			if (stage.boyfriend != null)
			{
				var trueSavePath:String = finalInput.text;

				var finalStage:StageData = {
					fixes: 1,
					characters: [{position: stage.boyfriend, camPosition: [0, 0], flip: true},
					{position: stage.opponent, camPosition: [0, 0], flip: false},
					{position: stage.girlfriend, camPosition: [0, 0], flip: false, scrollFactor: [0.95, 0.95]}],
					camZoom: stage.defaultZoom,
					camFollow: [Std.int(FlxG.width / 2), Std.int(FlxG.height / 2)],
					bgColor: [0, 0, 0],
					pixelPerfect: false,
					pieces: []
				}

				if (Reflect.hasField(stage, "camera_boyfriend"))
					finalStage.characters[0].camPosition = stage.camera_boyfriend;

				if (Reflect.hasField(stage, "camera_opponent"))
					finalStage.characters[1].camPosition = stage.camera_opponent;

				finalStage.characters[2].position[0] += 140;
				finalStage.characters[2].position[1] -= 80;

				if (Reflect.hasField(stage, "hide_girlfriend") && Reflect.field(stage, "hide_girlfriend"))
					finalStage.characters.pop();

				File.saveContent(trueSavePath + "/" + convertedStageId, Json.stringify(finalStage));

				new Notify("Successfully converted the stage \"" + convertedStageId.replace(".json", "") + "\" from Psych Engine");
			}
			else
				new Notify("The file does not seem to be a Psych Engine stage");
		});
		btnHbox.add(convert);

		var close:TextButton = new TextButton(0, 0, "Close", function() { window.close(); });
		btnHbox.add(close);

		vbox.add(btnHbox);

		window = PopupWindow.CreateWithGroup(vbox);
	}
}