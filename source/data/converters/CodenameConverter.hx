package data.converters;

import haxe.Json;
import haxe.ds.ArraySort;
import flixel.system.FlxSound;
import sys.FileSystem;
import sys.io.File;
import data.ObjectData;
import data.Song;
import editors.chart.ChartEditorState;

using StringTools;

class CodenameConverter
{
	public static function convertChart(callback:Void->Void)
	{
		var file:FileBrowser = new FileBrowser();
		file.label = "Choose a \"meta.json\" file belonging to the chart that you want to convert";
		file.loadCallback = function(fullPath:String) {
			if (fullPath.indexOf("meta.json") > -1)
			{
				var pathArray:Array<String> = fullPath.replace('\\','/').split('/');
				pathArray.pop();
				var convertedSongId:String = pathArray[pathArray.length - 1].toLowerCase().replace(" ", "-");
				var songFolder:String = pathArray.join("/");
				var metadata:Dynamic = Json.parse(File.getContent(fullPath));

				var file2:FileBrowser = new FileBrowser();
				file2.saveCallback = function(savePath:String) {
					var savePathArray:Array<String> = savePath.replace('\\','/').split('/');
					savePathArray.pop();
					var trueSavePath:String = savePathArray.join("/") + "/";

					var difficulties:Array<String> = cast metadata.difficulties;
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
							player1: "none",
							player2: "none",
							stage: chart.stage,
							bpmMap: [[0, metadata.bpm]],
							speed: chart.scrollSpeed,
							notes: [],
							metaFile: "",
							eventFile: "_events"
						};

						if (strumLines.length > 1)
						{
							newChart.player1 = strumLines[1].characters[0];
							newChart.player2 = strumLines[0].characters[0];
							if (strumLines.length > 2)
								newChart.player3 = strumLines[2].characters[0];
						}

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

						var firstNote:Float = -1;
						if (strumLines.length > 1)
						{
							var newNotes:Array<Dynamic> = cast strumLines[0].notes;

							for (n in newNotes)
							{
								var column:Int = Std.int(n.id);

								var len:Float = 0;
								if (n.sLen != null)
									len = n.sLen;

								var kind:String = "";
								if (n.type != null)
									kind = Std.string(n.type);

								if (firstNote == -1 || n.time < firstNote)
									firstNote = n.time;
								newChart.notes[0].sectionNotes.push([n.time, column, len, kind]);
							}

							newNotes = cast strumLines[1].notes;

							for (n in newNotes)
							{
								var column:Int = Std.int(n.id) + 4;

								var len:Float = 0;
								if (n.sLen != null)
									len = n.sLen;

								var kind:String = "";
								if (n.type != null)
									kind = Std.string(n.type);

								if (firstNote == -1 || n.time < firstNote)
									firstNote = n.time;
								newChart.notes[0].sectionNotes.push([n.time, column, len, kind]);
							}
						}

						var firstBeat:Float = Math.max(0, Math.floor(timingStruct.beatFromTime(firstNote)));
						newChart.preview = [firstBeat, firstBeat + 32];

						var parsedData:SongData = Song.parseSongData(newChart, false, false);
						parsedData.useBeats = true;
						File.saveContent(trueSavePath + convertedSongId + "-" + d.toLowerCase() + ".json", Json.stringify({song: ChartEditorState.prepareChartSave(parsedData)}));
					}

					callback();
				}
				file2.failureCallback = callback;
				file2.savePath("*.*");
			}
		}
		file.failureCallback = callback;
		file.load("json");
	}
}