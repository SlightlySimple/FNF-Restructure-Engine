package data.converters;

import flixel.FlxG;
import haxe.Json;
import haxe.xml.Access;
import sys.FileSystem;
import sys.io.File;
import data.ObjectData;

using StringTools;

class PsychConverter
{
	public static function convertCharacter()
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
						if (FileSystem.exists(trueImagePath + "/" + character.image + ".xml") || FileSystem.exists(trueImagePath + "/" + character.image + ".txt"))
						{
							var frames:Array<Dynamic> = [];

							if (FileSystem.exists(trueImagePath + "/" + character.image + ".txt"))
							{
								var txtRaw:String = File.getContent(trueImagePath + "/" + character.image + ".txt");
								var txtSplit:Array<String> = txtRaw.replace("\r","").replace("\t","").split("\n");
								for (f in txtSplit)
								{
									var fSplit:Array<String> = f.split(" = ");
									frames.push({name: fSplit[0], w: fSplit[1].split(" ")[2], h: fSplit[1].split(" ")[3]});
								}
							}
							else
							{
								var xmlRaw:String = File.getContent(trueImagePath + "/" + character.image + ".xml");
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
									fixes: 0,
									asset: character.image,
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

	public static function convertStage()
	{
		var file:FileBrowser = new FileBrowser();
		file.label = "Choose a stage json file that you want to convert";
		file.loadCallback = function(fullPath:String)
		{
			if (fullPath.indexOf("stages") > -1)
			{
				var pathArray:Array<String> = fullPath.replace('\\','/').split('/');
				var convertedStageId:String = pathArray[pathArray.length - 1];

				var stage:Dynamic = Json.parse(File.getContent(fullPath));

				var file2:FileBrowser = new FileBrowser();
				file2.saveCallback = function(savePath:String)
				{
					var savePathArray:Array<String> = savePath.replace('\\','/').split('/');
					savePathArray.pop();
					var trueSavePath:String = savePathArray.join("/") + "/";

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

					File.saveContent(trueSavePath + convertedStageId, Json.stringify(finalStage));
				}
				file2.savePath("*.*");
			}
		}
		file.load("json");
	}
}