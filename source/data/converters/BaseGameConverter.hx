package data.converters;

import haxe.Json;
import haxe.xml.Access;
import haxe.ds.ArraySort;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import sys.FileSystem;
import sys.io.File;
import data.ObjectData;
import data.Song;
import editors.chart.ChartEditorState;
import scripting.HscriptHandler;

import newui.PopupWindow;

using StringTools;

class BaseGameConverter
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
									if (a.flipX != null)
										anim.flipX = a.flipX;
									if (a.flipY != null)
										anim.flipY = a.flipY;
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
				file2.label = "Choose a png file in the folder for this stages's props";
				file2.loadCallback = function(imagePath:String)
				{
					pathArray = imagePath.replace('\\','/').split('/');
					while (pathArray[0] != "images")
						pathArray.shift();
					pathArray.shift();
					pathArray.pop();
					var finalAssetPath:String = pathArray.join("/");

					pathArray = imagePath.replace('\\','/').split('/');
					pathArray.pop();
					var assetCopyPath1:String = pathArray.join("/");
					while (pathArray[pathArray.length - 1] != "images")
						pathArray.pop();
					var assetCopyPath2:String = pathArray.join("/");

					var file3:FileBrowser = new FileBrowser();
					file3.label = "Save a file in the new folder for this stage's props";
					file3.saveCallback = function(assetSavePath:String)
					{
						pathArray = assetSavePath.replace('\\','/').split('/');
						while (pathArray[0] != "images")
							pathArray.shift();
						pathArray.shift();
						pathArray.pop();
						var finalAssetSavePath:String = pathArray.join("/");

						pathArray = assetSavePath.replace('\\','/').split('/');
						pathArray.pop();
						var assetPastePath:String = pathArray.join("/");

						var file4:FileBrowser = new FileBrowser();
						file4.saveCallback = function(savePath:String)
						{
							var assetList:Array<String> = [];

							var savePathArray:Array<String> = savePath.replace('\\','/').split('/');
							savePathArray.pop();
							var trueSavePath:String = savePathArray.join("/") + "/";

							var finalStage:StageData = {
								searchDirs: [finalAssetSavePath],
								fixes: 1,
								characters: [],
								camZoom: stage.cameraZoom,
								camFollow: [640, 360],
								bgColor: [0, 0, 0],
								pixelPerfect: false,
								pieces: []
							};

							var charZ:Map<String, Float> = new Map<String, Float>();
							var charList:Array<String> = ["bf", "gf", "dad"];
							charZ["bf"] = stage.characters.bf.zIndex;
							charZ["gf"] = stage.characters.gf.zIndex;
							charZ["dad"] = stage.characters.dad.zIndex;
							ArraySort.sort(charList, function(a:String, b:String) {
								if (charZ[a] < charZ[b])
									return -1;
								if (charZ[a] > charZ[b])
									return 1;
								return 0;
							});

							for (c in ["bf", "dad", "gf"])
							{
								var oldChar = Reflect.field(stage.characters, c);
								var oldPos:Array<Float> = cast oldChar.position;

								var stageChar:StageCharacter = {
									layer: charList.indexOf(c),
									position: [Std.int(Math.round((oldPos[0] - 210) / 5) * 5), Std.int(Math.round((oldPos[1] - 765) / 5) * 5)],
									flip: (c == "bf")
								};

								if (oldChar.cameraOffsets != null)
								{
									var oldCamPos:Array<Float> = cast oldChar.cameraOffsets;
									stageChar.camPosition = [Std.int(oldCamPos[0]), Std.int(oldCamPos[1])];
									if (c == "bf")
									{
										stageChar.camPosition[0] += 150;
										stageChar.camPosition[1] += 100;
									}
									else if (c == "dad")
									{
										stageChar.camPosition[0] -= 150;
										stageChar.camPosition[1] += 100;
									}
								}

								finalStage.characters.push(stageChar);
							}

							var oldPieces:Array<Dynamic> = cast stage.props;
							ArraySort.sort(oldPieces, function(a:Dynamic, b:Dynamic) {
								if (a.zIndex < b.zIndex)
									return -1;
								if (a.zIndex > b.zIndex)
									return 1;
								return 0;
							});

							for (p in oldPieces)
							{
								var stagePiece:StagePiece = {
									id: p.name,
									type: "static",
									asset: p.assetPath,
									position: p.position,
									layer: 0,
									antialias: !p.isPixel,
									flip: [false, false]
								};

								if (stagePiece.asset.replace("\\", "/").startsWith(finalAssetPath))
									stagePiece.asset = stagePiece.asset.substr(finalAssetPath.length + 1);
								if (stagePiece.id == stagePiece.asset)
									Reflect.deleteField(stagePiece, "id");

								for (c in charList)
								{
									if (p.zIndex > charZ[c])
										stagePiece.layer++;
								}

								if (p.scale != null)
								{
									stagePiece.scale = p.scale;
									stagePiece.updateHitbox = true;
								}

								if (p.scroll != null)
									stagePiece.scrollFactor = p.scroll;

								if (p.flipX != null)
									stagePiece.flip[0] = p.flipX;
								if (p.flipY != null)
									stagePiece.flip[0] = p.flipY;

								if (p.alpha != null)
									stagePiece.alpha = p.alpha;

								if (p.blend != null)
									stagePiece.blend = p.blend;

								if (p.color != null)
								{
									var pieceColor:FlxColor = FlxColor.fromString(p.color);
									stagePiece.color = [pieceColor.red, pieceColor.green, pieceColor.blue];
								}

								if (stagePiece.asset.charAt(0) == "#")
								{
									var pieceColor:FlxColor = FlxColor.fromString(stagePiece.asset);
									stagePiece.type = "solid";
									stagePiece.color = [pieceColor.red, pieceColor.green, pieceColor.blue];
								}
								else if (p.animations != null)
								{
									var pAnims:Array<Dynamic> = cast p.animations;
									if (pAnims.length > 0)
									{
										stagePiece.type = "animated";
										stagePiece.animations = [];
										var animNames:Array<String> = [];
										for (a in pAnims)
										{
											var stagePieceAnim:StageAnimation = {
												name: a.name,
												prefix: a.prefix,
												fps: a.frameRate,
												loop: a.looped
											};
											if (a.frameRate == null)
												stagePieceAnim.fps = 24;
											if (a.looped == null)
												stagePieceAnim.loop = false;
											if (a.frameIndices != null)
												stagePieceAnim.indices = a.frameIndices;

											stagePiece.animations.push(stagePieceAnim);
											animNames.push(stagePieceAnim.name);
										}
										if (p.startingAnimation != null)
											stagePiece.firstAnimation = p.startingAnimation;
										if (p.danceEvery != null && p.danceEvery > 0)
										{
											if (animNames.contains("idle"))
												stagePiece.idles = ["idle"];
											else if (animNames.contains("danceLeft") && animNames.contains("danceRight"))
												stagePiece.idles = ["danceLeft", "danceRight"];
											stagePiece.beatAnimationSpeed = p.danceEvery;
										}
									}
								}

								if (stagePiece.type == "static" || stagePiece.type == "animated")
								{
									if (!assetList.contains(stagePiece.asset + ".png"))
									assetList.push(stagePiece.asset + ".png");
									if (stagePiece.type == "animated" && !assetList.contains(stagePiece.asset + ".xml"))
										assetList.push(stagePiece.asset + ".xml");
								}

								finalStage.pieces.push(stagePiece);
							}

							File.saveContent(trueSavePath + convertedStageId, Json.stringify(finalStage));

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
						}
						file4.savePath("*.*");
					}
					file3.savePath("*.*");
				}
				file2.load("png");
			}
		}
		file.load("json");
	}

	public static function convertChart(callback:Void->Void)
	{
		var baseStages:Map<String, String> = new Map<String, String>();
		for (stage in Util.splitFile(Paths.text("baseStages")))
		{
			var stageSplit:Array<String> = stage.split("|");
			baseStages[stageSplit[0]] = stageSplit[1];
		}

		var file:FileBrowser = new FileBrowser();
		file.label = "Choose a \"-chart\" file that you want to convert";
		file.loadCallback = function(fullPath:String) {
			if (fullPath.indexOf("-chart") > -1 && FileSystem.exists(fullPath.replace("-chart", "-metadata")))
			{
				var pathArray:Array<String> = fullPath.replace('\\','/').split('/');
				var convertedSongId:String = pathArray[pathArray.length - 1].split("-chart")[0];

				var chart:Dynamic = Json.parse(File.getContent(fullPath));
				var metadata:Dynamic = Json.parse(File.getContent(fullPath.replace("-chart", "-metadata")));

				var trackSuffix:String = "";
				if (Reflect.hasField(metadata.playData.characters, "instrumental"))
					trackSuffix = metadata.playData.characters.instrumental;

				var p1:String = metadata.playData.characters.player;
				var p1Old:String = p1;
				if (!Paths.jsonExists("characters/" + p1) && Paths.jsonExists("characters/" + p1.split("-")[0]))
					p1 = p1.split("-")[0];
				var p2:String = metadata.playData.characters.opponent;
				if (!Paths.jsonExists("characters/" + p2) && Paths.jsonExists("characters/" + p2.split("-")[0]))
					p2 = p2.split("-")[0];
				var gf:String = metadata.playData.characters.girlfriend;
				if (!Paths.jsonExists("characters/" + gf) && Paths.jsonExists("characters/" + gf.split("-")[0]))
					gf = gf.split("-")[0];

				var noteStyle:String = "funkin";
				if (metadata.playData.noteStyle != null)
					noteStyle = metadata.playData.noteStyle;

				var file2:FileBrowser = new FileBrowser();
				file2.label = "Choose an ogg file in the folder for this chart's music";
				file2.loadCallback = function(musicPath:String) {
					var musicPathArray:Array<String> = musicPath.replace('\\','/').split('/');
					musicPathArray.pop();
					var trueMusicPath:String = musicPathArray.join("/") + "/";

					var tracks:Array<Array<Dynamic>> = [["Inst", 0]];
					if (FileSystem.exists(trueMusicPath + "Inst-" + trackSuffix + ".ogg"))
						tracks[0][0] += "-" + trackSuffix;

					if (FileSystem.exists(trueMusicPath + "Voices-" + trackSuffix + ".ogg"))
						tracks.push(["Voices-" + trackSuffix, 1]);
					else if (FileSystem.exists(trueMusicPath + "Voices.ogg"))
						tracks.push(["Voices", 1]);

					if (FileSystem.exists(trueMusicPath + "Voices-" + p1Old.split("-")[0] + "-" + trackSuffix + ".ogg"))
						tracks.push(["Voices-" + p1Old.split("-")[0] + "-" + trackSuffix, 2]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p1Old + "-" + trackSuffix + ".ogg"))
						tracks.push(["Voices-" + p1Old + "-" + trackSuffix, 2]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p1Old.split("-")[0] + ".ogg"))
						tracks.push(["Voices-" + p1Old.split("-")[0], 2]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p1Old + ".ogg"))
						tracks.push(["Voices-" + p1Old, 2]);

					if (FileSystem.exists(trueMusicPath + "Voices-" + p2.split("-")[0] + "-" + trackSuffix + ".ogg"))
						tracks.push(["Voices-" + p2.split("-")[0] + "-" + trackSuffix, 3]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p2 + "-" + trackSuffix + ".ogg"))
						tracks.push(["Voices-" + p2 + "-" + trackSuffix, 3]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p2.split("-")[0] + ".ogg"))
						tracks.push(["Voices-" + p2.split("-")[0], 3]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p2 + ".ogg"))
						tracks.push(["Voices-" + p2, 3]);

					var file3:FileBrowser = new FileBrowser();
					file3.saveCallback = function(savePath:String) {
						var savePathArray:Array<String> = savePath.replace('\\','/').split('/');
						savePathArray.pop();
						var trueSavePath:String = savePathArray.join("/") + "/";

						var offset:Float = 0;
						if (metadata.offsets != null)
							offset = metadata.offsets.instrumental;

						var bpmMap:Array<Array<Float>> = [];
						var timeChanges:Array<Dynamic> = cast metadata.timeChanges;
						var sortedTimeChanges:Array<Array<Float>> = [];
						for (t in timeChanges)
							sortedTimeChanges.push([Math.max(0, t.t), t.bpm]);
						ArraySort.sort(sortedTimeChanges, function(a:Array<Float>, b:Array<Float>) {
							if (a[0] < b[0])
								return -1;
							if (a[0] > b[0])
								return 1;
							return 0;
						});

						var totalBeats:Float = 0;
						var lastTime:Float = 0;
						var lastBPM:Float = sortedTimeChanges[0][1];
						for (t in sortedTimeChanges)
						{
							totalBeats += ((t[0] - lastTime) / 1000) * (lastBPM / 60);
							bpmMap.push([totalBeats, t[1]]);
							lastTime = t[0];
							lastBPM = t[1];
						}

						var timingStruct:TimingStruct = new TimingStruct();
						timingStruct.recalculateTimings(bpmMap);

						var metaFile:String = "_meta";
						if (trackSuffix != "")
							metaFile += "_" + trackSuffix;

						var eventFile:String = "_events";
						if (trackSuffix != "")
							eventFile += "_" + trackSuffix;

						var convertedEvents:Array<Dynamic> = cast chart.events;
						var camEvents:Array<Array<Dynamic>> = [];
						for (e in convertedEvents)
						{
							if (e.e == "FocusCamera")
							{
								if (Reflect.hasField(e.v, "char"))
									camEvents.push([e.t, e.v.char]);
								else
									camEvents.push([e.t, e.v]);
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

						var chartMeta:SongData = {
							song: metadata.songName,
							artist: metadata.artist,
							charter: "",
							preview: [0, 32],
							tracks: tracks,
							offset: offset,
							characters: [p1, p2, gf],
							stage: metadata.playData.stage,
							eventFile: eventFile
						};

						if (bpmMap.length > 1)
							chartMeta.bpmMap = bpmMap;
						else
							chartMeta.bpm = bpmMap[0][1];

						if (baseStages.exists(chartMeta.stage))
							chartMeta.stage = baseStages[chartMeta.stage];

						if (metadata.charter != null)
							chartMeta.charter = metadata.charter;

						var difficulties:Array<String> = cast metadata.playData.difficulties;
						for (d in difficulties)
						{
							var speed:Float = Reflect.field(chart.scrollSpeed, "default");
							if (Reflect.hasField(chart.scrollSpeed, d))
								speed = Reflect.field(chart.scrollSpeed, d);

							var newChart:SongData = {
								song: metadata.songName,
								artist: metadata.artist,
								charter: "",
								preview: [0, 32],
								ratings: [0, 0],
								tracks: tracks,
								offset: offset,
								characters: [p1, p2, gf],
								stage: metadata.playData.stage,
								bpmMap: bpmMap,
								speed: speed,
								notes: [],
								metaFile: metaFile,
								eventFile: eventFile
							};

							if (baseStages.exists(newChart.stage))
								newChart.stage = baseStages[newChart.stage];

							if (metadata.charter != null)
								newChart.charter = metadata.charter;

							if (metadata.playData.ratings != null && Reflect.hasField(metadata.playData.ratings, d))
								newChart.ratings = [Reflect.field(metadata.playData.ratings, d), 0];

							if (noteStyle != "funkin")
							{
								newChart.noteType = [noteStyle];
								newChart.uiSkin = noteStyle;
							}

							var track:FlxSound = new FlxSound().loadEmbedded(flash.media.Sound.fromFile(trueMusicPath + tracks[0][0] + ".ogg"));
							for (i in 0...camEvents.length)
							{
								var newSection:SectionData = {sectionNotes: [], lengthInSteps: 64, camOn: 0};
								if (i < camEvents.length - 1)
									newSection.lengthInSteps = Std.int(Math.round(timingStruct.stepFromTime(camEvents[i + 1][0])) - Math.round(timingStruct.stepFromTime(camEvents[i][0])));
								else
									newSection.lengthInSteps = Std.int(Math.ceil(timingStruct.stepFromTime(track.length)) - Math.round(timingStruct.stepFromTime(camEvents[i][0])));

								if (camEvents[i][1] == "1" || camEvents[i][1] == 1)
									newSection.camOn = 1;

								newChart.notes.push(newSection);
							}

							if (newChart.notes.length <= 0)
							{
								var totalSections:Int = Std.int(Math.ceil(timingStruct.beatFromTime(track.length) / 4));
								for (i in 0...totalSections)
									newChart.notes.push({sectionNotes: [], lengthInSteps: 16, camOn: 0});
							}

							var newNotes:Array<Dynamic> = cast Reflect.field(chart.notes, d);
							var firstNote:Float = -1;

							for (n in newNotes)
							{
								var column:Int = Std.int(n.d) - 4;
								if (column < 0)
									column += 8;

								var len:Float = 0;
								if (n.l != null)
									len = n.l;

								var kind:String = "";
								if (Reflect.hasField(n, "k"))
									kind = n.k;
								if (kind == "normal")
									kind = "";

								if (firstNote == -1 || n.t < firstNote)
									firstNote = n.t;
								newChart.notes[0].sectionNotes.push([n.t, column, len, kind]);
							}

							var firstBeat:Float = Math.max(0, Math.floor(timingStruct.beatFromTime(firstNote)));
							newChart.preview = [firstBeat, firstBeat + 32];
							chartMeta.preview = [firstBeat, firstBeat + 32];

							var parsedData:SongData = Song.parseSongData(newChart, false, false);
							parsedData.useBeats = true;
							File.saveContent(trueSavePath + convertedSongId + "-" + d + ".json", Json.stringify({song: ChartEditorState.prepareChartSave(parsedData)}));
						}

						File.saveContent(trueSavePath + metaFile + ".json", Json.stringify(chartMeta));

						ArraySort.sort(convertedEvents, function(a:Dynamic, b:Dynamic) {
							if (a.t < b.t)
								return -1;
							if (a.t > b.t)
								return 1;
							return 0;
						});
						var newEvents:Array<EventData> = convertChartEvents(convertedSongId, convertedEvents, timingStruct);
						if (newEvents.length > 0)
							File.saveContent(trueSavePath + eventFile + ".json", ChartEditorState.prepareEventsSave(newEvents));

						callback();
					}
					file3.failureCallback = callback;
					file3.savePath("*.*");
				}
				file2.failureCallback = callback;
				file2.load("ogg");
			}
		}
		file.failureCallback = callback;
		file.load("json");
	}

	static function convertChartEvents(convertedSongId:String, events:Array<Dynamic>, timingStruct:TimingStruct):Array<EventData>
	{
		var ret:Array<EventData> = [];

		var eventConverters:Array<HscriptHandlerSimple> = [];
		for (c in Paths.listFiles('data/baseEvents/', '.hscript'))
			eventConverters.push(new HscriptHandlerSimple('data/baseEvents/' + c));

		for (c in eventConverters)
			c.setVar("songId", convertedSongId);

		var unmatchedEvents:Array<String> = [];

		for (event in events)
		{
			var eventValue:Dynamic = null;
			for (c in eventConverters)
			{
				var returnValue:Dynamic = c.execFuncReturn("convertEvent", [event, timingStruct]);
				if (eventValue == null && returnValue != null)
					eventValue = returnValue;
			}

			if (eventValue != null)
			{
				if (Std.isOfType(eventValue, Array))
				{
					var eventValueArray:Array<EventData> = cast eventValue;
					for (a in eventValueArray)
					{
						var newEvent:EventData = {time: event.t, beat: timingStruct.beatFromTime(event.t), type: a.type, parameters: a.parameters};
						if (a.beat != null)
						{
							newEvent.beat = a.beat;
							newEvent.time = timingStruct.timeFromBeat(a.beat);
						}
						ChartEditorState.checkConvertedEventParameters(newEvent);
						ret.push(newEvent);
					}
				}
				else
				{
					var newEvent:EventData = {time: event.t, beat: timingStruct.beatFromTime(event.t), type: eventValue.type, parameters: eventValue.parameters};
					if (eventValue.beat != null)
					{
						newEvent.beat = eventValue.beat;
						newEvent.time = timingStruct.timeFromBeat(eventValue.beat);
					}
					ChartEditorState.checkConvertedEventParameters(newEvent);
					ret.push(newEvent);
				}
			}
			else
			{
				if (!unmatchedEvents.contains(event.e))
					unmatchedEvents.push(event.e);
			}
		}

		if (unmatchedEvents.length > 0)
		{
			var notifyString:String = "The following events have no equivalent:\n\n";
			for (e in unmatchedEvents)
				notifyString += e + "\n";

			new Notify(notifyString);
		}

		return ret;
	}
}