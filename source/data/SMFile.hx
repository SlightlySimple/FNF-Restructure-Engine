package data;

import data.Song;

using StringTools;

class SMFile
{
	public var title:String;
	public var artist:String;
	public var ogg:String;

	public var songData:Array<SongData> = [];
	public var difficulties:Array<String> = [];

	public function new()
	{
	}

	static public function load(file:String, ?shouldParse:Bool = true):SMFile
	{
		var fileData:String = Paths.sm(file);
		var newSM = new SMFile();

		newSM.title = fileData.split("#TITLE:")[1].split(";")[0];
		newSM.artist = fileData.split("#ARTIST:")[1].split(";")[0];
		newSM.ogg = fileData.split("#MUSIC:")[1].split(";")[0];

		var bpmList:String = fileData.split("#BPMS:")[1].split(";")[0];
		bpmList = bpmList.replace("\r","").replace("\n","").replace("\t","").replace(" ","");
		var bpmArray:Array<String> = bpmList.split(",");
		var bpmMap:Array<Array<Float>> = [];
		for (bpm in bpmArray)
		{
			var bpmSplit:Array<String> = bpm.split("=");
			bpmMap.push([Std.parseFloat(bpmSplit[0]), Std.parseFloat(bpmSplit[1])]);
		}

		var smTimingStruct:TimingStruct = new TimingStruct();
		smTimingStruct.recalculateTimings(bpmMap);

		var stopList:String = fileData.split("#STOPS:")[1].split(";")[0];
		stopList = stopList.replace("\r","").replace("\n","").replace("\t","").replace(" ","");
		var stopArray:Array<String> = stopList.split(",");
		if (fileData.indexOf("#STOPS:;") > -1)
			stopArray = [];
		var stopMap:Array<Array<Float>> = [];
		var timeOfAllStops:Float = 0;
		for (stop in stopArray)
		{
			var stopSplit:Array<String> = stop.split("=");
			var stopBeat:Float = Std.parseFloat(stopSplit[0]);
			var stopTime:Float = smTimingStruct.timeFromBeat(stopBeat);
			var stopLen:Float = smTimingStruct.beatFromTime(stopTime + (Std.parseFloat(stopSplit[1]) * 1000), stopTime) - stopBeat;
			stopMap.push([stopBeat + timeOfAllStops, stopLen]);
			timeOfAllStops += stopLen;
		}

		for (i in 0...bpmMap.length)
		{
			for (s in stopMap)
			{
				if (bpmMap[i][0] > s[0])
					bpmMap[i][0] += s[1];
			}
		}
		smTimingStruct.recalculateTimings(bpmMap);

		var offset:Float = Std.parseFloat(fileData.split("#OFFSET:")[1].split(";")[0]) * 1000;

		var scrollSpeeds:Array<Array<Float>> = [[0, 1]];

		for (s in stopMap)
		{
			var slot:Int = 0;
			for (i in 0...scrollSpeeds.length)
			{
				if (s[0] >= scrollSpeeds[i][0])
					slot = i;
			}
			slot++;
			scrollSpeeds.insert(slot, [s[0] + s[1], 1]);
			scrollSpeeds.insert(slot, [s[0], 0]);
		}

		var noteLists:Array<String> = fileData.split("#NOTES:");
		noteLists.shift();
		for (_n in 0...noteLists.length)
		{
			var thisSongData:SongData =
			{
				song: newSM.title,
				artist: newSM.artist,
				bpm: bpmMap[0][1],
				bpmMap: bpmMap,
				speed: scrollSpeeds[0][1],
				scrollSpeeds: scrollSpeeds,
				altSpeedCalc: true,
				player1: TitleState.defaultVariables.player1,
				player2: "none",
				player3: TitleState.defaultVariables.gf,
				stage: TitleState.defaultVariables.stage,
				needsVoices: false,
				tracks: [[newSM.ogg, 0]],
				notes: [],
				events: [],
				offset: offset
			}

			var notes:Array<String> = noteLists[_n].split(";")[0].replace("\r","").split("\n");
			var chartType:Int = 0;
			var diff:String = "";
			var editDiff:String = "";
			for (i in 0...5)
			{
				if (i == 2)
					editDiff = notes[0].replace(" ","").replace("\t","").replace(":","").toLowerCase();
				if (i == 3)
					diff = notes[0].replace(" ","").replace("\t","").replace(":","").toLowerCase();
				if (notes[0].indexOf("dance-double") > -1)
					chartType = 1;
				notes.shift();
			}
			if (diff == "edit")
				diff = editDiff;
			if (chartType == 1)
			{
				thisSongData.player2 = TitleState.defaultVariables.player2;
				diff += "-double";
			}
			else
				thisSongData.columnDivisions = [0,0,0,0];
			newSM.difficulties.push(diff);

			if (!notes[0].startsWith("0") && !notes[0].startsWith("1") && !notes[0].startsWith("2") && !notes[0].startsWith("4") && !notes[0].startsWith("M"))
			{
				while(!notes[0].startsWith("0") && !notes[0].startsWith("1") && !notes[0].startsWith("2") && !notes[0].startsWith("4") && !notes[0].startsWith("M"))
					notes.shift();
			}

			var sections:Array<Array<String>> = [];
			var newSection:Array<String> = [];

			for (n in notes)
			{
				if (n.length > 0)
				{
					if (n.startsWith(","))
					{
						sections.push(newSection);
						newSection = [];
					}
					else if (chartType == 1)
						newSection.push(n.substr(0,8));
					else
						newSection.push(n.substr(0,4));
				}
			}
			sections.push(newSection);

			var holdStarts:Array<Array<Array<Dynamic>>> = [[],[],[],[]];
			var holdEnds:Array<Array<Float>> = [[],[],[],[]];
			if (chartType == 1)
			{
				holdStarts = [[],[],[],[],[],[],[],[]];
				holdEnds = [[],[],[],[],[],[],[],[]];
			}

			var chartEnd:Float = 0;
			for (s in 0...sections.length)
			{
				var secData:SectionData =
				{
					sectionNotes: [],
					lengthInSteps: 16,
					camOn: 0
				}

				for (i in 0...sections[s].length)
				{
					var beatOfLine:Float = (i / sections[s].length) * 4;
					beatOfLine += s * 4;
					for (ss in stopMap)
					{
						if (beatOfLine > ss[0])
							beatOfLine += ss[1];
					}
					if (chartEnd < beatOfLine)
						chartEnd = beatOfLine;
					for (c in 0...holdStarts.length)
					{
						switch (sections[s][i].charAt(c))
						{
							case "1":
								secData.sectionNotes.push([smTimingStruct.timeFromBeat(beatOfLine),c,0]);
							case "M":
								secData.sectionNotes.push([smTimingStruct.timeFromBeat(beatOfLine),c,0,"mine"]);
							case "2":
								holdStarts[c].push([s,beatOfLine,false]);
							case "4":
								holdStarts[c].push([s,beatOfLine,true]);
							case "3":
								holdEnds[c].push(beatOfLine);
						}
					}
				}

				thisSongData.notes.push(secData);
			}
			if (Std.int(Math.ceil(chartEnd / 4)) < 1000)
			{
				while (thisSongData.notes.length < Std.int(Math.ceil(chartEnd / 4)))
					thisSongData.notes.push({sectionNotes: [], lengthInSteps: 16, camOn: 0});
			}

			for (c in 0...holdStarts.length)
			{
				for (i in 0...holdStarts[c].length)
				{
					var startBeat:Float = holdStarts[c][i][1];
					var endBeat:Float = holdEnds[c][i];
					var sec:Int = Std.int(Math.floor(holdStarts[c][i][0]));
					if (holdStarts[c][i][2])
						thisSongData.notes[sec].sectionNotes.push([smTimingStruct.timeFromBeat(startBeat),c,smTimingStruct.timeFromBeat(endBeat) - smTimingStruct.timeFromBeat(startBeat),"roll"]);
					else
						thisSongData.notes[sec].sectionNotes.push([smTimingStruct.timeFromBeat(startBeat),c,smTimingStruct.timeFromBeat(endBeat) - smTimingStruct.timeFromBeat(startBeat)]);
				}
			}

			var pathArray:Array<String> = file.replace("\\","/").split("/");
			pathArray.pop();
			if (Paths.exists("sm/" + pathArray.join("/") + "/_data.json"))
			{
				var baseData:SongData = cast Paths.jsonDirect("sm/" + pathArray.join("/") + "/_data");

				if (baseData.player1 != null)
					thisSongData.player1 = baseData.player1;

				if (baseData.player2 != null)
					thisSongData.player2 = baseData.player2;

				if (baseData.player3 != null)
					thisSongData.player3 = baseData.player3;

				if (baseData.stage != null)
					thisSongData.stage = baseData.stage;

				if (baseData.uiSkin != null)
					thisSongData.uiSkin = baseData.uiSkin;

				if (baseData.noteType != null)
					thisSongData.noteType = baseData.noteType;
			}

			if (Paths.exists("sm/" + pathArray.join("/") + "/_events.json"))
			{
				thisSongData.events = Song.loadEvents("sm/" + pathArray.join("/") + "/_events", true);
				thisSongData.events = Song.correctEvents(thisSongData.events, smTimingStruct);
			}

			if (shouldParse)
				newSM.songData.push(Song.parseSongData(thisSongData, true, true));
			else
				newSM.songData.push(thisSongData);
		}

		return newSM;
	}

	static public function save(data:SongData, notes:Array<Array<Dynamic>>):String
	{
		var fileData:String = "";
		fileData += "#TITLE:" + data.song + ";\n";
		fileData += "#SUBTITLE:;\n#ARTIST:" + (data.artist == null ? "" : data.artist) + ";\n#TITLETRANSLIT:;\n#SUBTITLETRANSLIT:;\n#ARTISTTRANSLIT:;\n#GENRE:;\n#CREDIT:;\n";
		fileData += "#MUSIC:" + data.song.toLowerCase().replace(" ","-") + ".ogg;\n";
		fileData += "#BANNER:;\n#BACKGROUND:;\n#CDTITLE:;\n#SAMPLESTART:0.000;\n#SAMPLELENGTH:0.000;\n#SELECTABLE:YES;\n";
		fileData += "#OFFSET:" + Std.string( data.offset / 1000.0 ) + ";\n";
		fileData += "#BPMS:";
		for (i in 0...data.bpmMap.length)
		{
			fileData += Std.string(data.bpmMap[i][0]) + "=" + Std.string(data.bpmMap[i][1]);
			if (i < data.bpmMap.length - 1)
				fileData += ",";
		}
		fileData += ";\n";
		fileData += "#STOPS:;\n#BGCHANGES:;\n#FGCHANGES:;\n";

		var smTimingStruct:TimingStruct = new TimingStruct();
		smTimingStruct.recalculateTimings(data.bpmMap);
		var quickNotes:Array<Array<Dynamic>> = [];

		var allStarts:Array<Array<Float>> = [];

		for (n in notes)
		{
			var beat:Float = smTimingStruct.beatFromTime(n[0]);
			var column:Float = n[1];
			allStarts.push([beat, column]);
		}

		for (n in notes)
		{
			var beat:Float = smTimingStruct.beatFromTime(n[0]);
			var column:Float = n[1];
			var type:String = "";
			if (n.length > 3)
				type = n[3];
			if (type == "mine")
				quickNotes.push([beat, column, "M"]);
			else if (n[2] <= 0)
				quickNotes.push([beat, column, "1"]);
			else
			{
				var endBeat:Float = smTimingStruct.beatFromTime(n[0] + n[2]);
				if (allStarts.filter(function(a) return a[0] == endBeat && a[1] == column).length > 0)
				{
					if (endBeat - beat > 0.125)
					{
						if (type == "roll")
							quickNotes.push([beat, column, "4"]);
						else
							quickNotes.push([beat, column, "2"]);
						quickNotes.push([endBeat - 0.125, column, "3"]);
					}
					else
						quickNotes.push([beat, column, "1"]);
				}
				else
				{
					if (type == "roll")
						quickNotes.push([beat, column, "4"]);
					else
						quickNotes.push([beat, column, "2"]);
					quickNotes.push([endBeat, column, "3"]);
				}
			}
		}

		var allSections:Array<Array<Array<Dynamic>>> = [];
		for (n in quickNotes)
		{
			var s:Int = Std.int(Math.floor(n[0] / 4));
			if (Math.round((n[0] - (s * 4)) * 48) >= 192)		// This should never happen unless there's a charting error
				s += 1;
			else if (Math.round((n[0] - (s * 4)) * 48) < 0 && s > 0)
				s -= 1;
			while (allSections.length <= s)
				allSections.push([]);
			allSections[s].push([n[0] - (s * 4), n[1], n[2]]);
		}

		var chartTypes:Array<String> = ["","","","dance-single","pump-single","dance-solo","kb7-single","dance-double","","pump-double"];
		var diffs:Array<String> = ["Beginner","Easy","Medium","Hard","Challenge"];
		var diffIndex:Int = diffs.length - 1;

		var uniqueDivisions:Array<Int> = [];
		for (i in data.columnDivisions)
		{
			if (!uniqueDivisions.contains(i))
				uniqueDivisions.push(i);
		}
		uniqueDivisions.sort((a, b) -> a - b);

		if (uniqueDivisions.length > 1)
		{
			for (d in uniqueDivisions)
			{
				if (diffIndex >= 0)
				{
					var chartDiv:Array<Int> = [];
					for (i in 0...data.columnDivisions.length)
					{
						if (data.columnDivisions[i] == d)
							chartDiv.push(i);
					}

					if (chartTypes.length >= chartDiv.length && chartTypes[chartDiv.length-1] != "")
					{
						fileData += "//--------------- "+chartTypes[chartDiv.length-1]+" (Player "+Std.string(d+1)+") ----------------\n";
						fileData += "#NOTES:\n     "+chartTypes[chartDiv.length-1]+":\n     :\n     "+diffs[diffIndex]+":\n     1:\n     0,0,0,0,0:\n";
						fileData += createSMSection(chartDiv, allSections);
						diffIndex--;
					}
				}
			}
		}

		var chartDiv:Array<Int> = [];
		for (i in 0...data.columnDivisions.length)
			chartDiv.push(i);

		if (chartTypes.length >= chartDiv.length && chartTypes[chartDiv.length-1] != "")
		{
			fileData += "//--------------- "+chartTypes[chartDiv.length-1]+" ----------------\n";
			fileData += "#NOTES:\n     "+chartTypes[chartDiv.length-1]+":\n     :\n     "+diffs[diffs.length-1]+":\n     1:\n     0,0,0,0,0:\n";
			fileData += createSMSection(chartDiv, allSections);
		}

		return fileData;
	}

	static function createSMSection(columns:Array<Int>, sections:Array<Array<Array<Dynamic>>>):String
	{
		var fileData = "";
		var size:Int = columns.length;

		for (s in sections)
		{
			var secSize:Int = 0;
			var goodSecSize:Bool = false;
			while (!goodSecSize)
			{
				secSize += 4;
				goodSecSize = true;
				if (secSize < 192)
				{
					for (n in s)
					{
						if (Math.round((n[0] * secSize) / 4) != (n[0] * secSize) / 4)
						goodSecSize = false;
					}
				}
			}

			var newSec:Array<Array<String>> = [];
			for (i in 0...secSize)
			{
				var subSec:Array<String> = [];
				for (j in 0...size)
					subSec.push("0");
				newSec.push(subSec);
			}
			for (n in s)
			{
				if (columns.contains(Std.int(n[1])))
				{
					var c:Int = columns.indexOf(Std.int(n[1]));
					newSec[Std.int(Math.round((n[0] * secSize) / 4))][c] = n[2];
				}
			}

			for (line in newSec)
			{
				for (ch in line)
					fileData += ch;
				fileData += "\n";
			}
			fileData += ",\n";
		}
		for (i in 0...4)
		{
			for (j in 0...size)
				fileData += "0";
			fileData += "\n";
		}
		fileData += ";\n";

		return fileData;
	}
}