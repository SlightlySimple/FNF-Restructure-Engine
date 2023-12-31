package data;

import data.ObjectData;
import objects.Note;
import haxe.ds.ArraySort;
import flixel.util.FlxStringUtil;
import lime.app.Application;

using StringTools;

typedef NoteData =
{
	var strumTime:Float;
	var sustainLength:Float;
	var column:Int;
	var type:String;
}

typedef SectionData =
{
	var ?copyLast:Null<Bool>;
	var sectionNotes:Array<Array<Dynamic>>;
	var lengthInSteps:Null<Int>;
	var ?firstStep:Null<Int>;
	var ?lastStep:Null<Int>;
	var ?mustHitSection:Null<Bool>;
	var ?camOn:Null<Int>;
	var ?scrollSpeeds:Array<Array<Float>>;

	var ?defaultNoteP1:Dynamic;
	var ?defaultNoteP2:Dynamic;

	var ?bpm:Float;
	var ?changeBPM:Bool;
	var ?altAnim:Bool;
}

typedef EventData =
{
	var ?time:Null<Float>;
	var ?beat:Null<Float>;
	var ?type:String;
	var ?typeShort:String;
	var ?parameters:Dynamic;
}

typedef EventParams =
{
	var ?id:String;
	var label:String;
	var type:String;
	var ?time:String;
	var defaultValue:Dynamic;
	var options:Array<String>;
	var min:Float;
	var max:Float;
	var increment:Float;
	var decimals:Int;
}

typedef SongMusicData =
{
	var pause:String;
	var gameOver:String;
	var gameOverEnd:String;
	var results:String;
	var resultsEnd:String;
}

typedef SongData =
{
	var song:String;
	var ?artist:String;
	var ?useBeats:Bool;
	var ?useMustHit:Null<Bool>;
	var ?skipCountdown:Null<Bool>;
	var ?bpm:Float;
	var ?bpmMap:Array<Array<Float>>;
	var ?offset:Null<Float>;
	var ?speed:Null<Float>;
	var ?scrollSpeeds:Array<Array<Float>>;
	var ?altSpeedCalc:Null<Bool>;
	var ?eventFile:String;
	var ?columnDivisions:Array<Int>;
	var ?columnDivisionNames:Array<String>;
	var ?allNotetypes:Array<String>;
	var ?notetypeSingers:Array<Array<String>>;
	var ?notetypeOverridesCam:Null<Bool>;
	var player1:String;
	var player2:String;
	var ?player3:String;
	var ?characterPrefix:String;
	var ?characterSuffix:String;
	var ?singerColumns:Array<Int>;
	var ?gf:String;
	var ?gfVersion:String;
	var stage:String;
	var ?tracks:Array<Array<Dynamic>>;
	var ?needsVoices:Null<Bool>;
	var notes:Array<SectionData>;
	var ?noteType:Array<String>;
	var ?uiSkin:String;
	var ?events:Array<EventData>;
	var ?music:SongMusicData;
}

class Song
{
	public static function sortEvents(a:EventData, b:EventData):Int
	{
		if (a.beat < b.beat)
			return -1;
		if (a.beat > b.beat)
			return 1;
		return 0;
	}

	public static function copy(song:SongData):SongData
	{
		var retSong:SongData = Reflect.copy(song);
		retSong.notes = [];
		for (s in song.notes)
		{
			var sec:SectionData = Reflect.copy(s);
			sec.sectionNotes = [];
			for (n in s.sectionNotes)
				sec.sectionNotes.push(n.copy());
			retSong.notes.push(Reflect.copy(sec));
		}

		retSong.events = [];
		for (e in song.events)
			retSong.events.push(Reflect.copy(e));

		return retSong;
	}

	public static function chartPath(id:String, ?difficulty:String = "normal", ?alert:Bool = true):String
	{
		var idShort:String = id.substring(id.lastIndexOf("/")+1, id.length);

		var fileChecks:Array<String> = [id + "/" + idShort + "-" + difficulty, id + "/" + difficulty, id + "/" + idShort];
		for (f in fileChecks)
		{
			if (Paths.jsonExists("songs/" + f))
			{
				return "songs/" + f;
				break;
			}
		}

		for (f in Paths.listFiles("data/songs/" + id + "/", ".json"))
		{
			if (Reflect.hasField(Paths.json("songs/" + id + "/" + f), "song"))
			{
				return "songs/" + id + "/" + f;
				break;
			}
		}

		if (alert && !Paths.smExists(id) && id != "")
			Application.current.window.alert("Unable to find chart file for song id \"" + id + "\"", "Alert");
		return "";
	}

	public static function loadSong(id:String, difficulty:String, ?shouldCorrectEvents:Bool = true, ?shouldParse:Bool = true):SongData
	{
		return loadSongDirect(chartPath(id, difficulty), true, shouldCorrectEvents, shouldParse);
	}

	public static function getSongName(id:String, ?difficulty:String = "normal"):String
	{
		var filename:String = chartPath(id, difficulty);

		var data:SongData = null;
		if (Paths.jsonExists(filename))
			data = cast Paths.json(filename).song;

		if (data != null)
		{
			if (data.song.startsWith("#"))
				return Lang.get(data.song);
		}

		if (Lang.getNoHash(id) != id)
			return Lang.getNoHash(id);

		if (data != null)
			return data.song;

		return id;
	}

	public static function getSongNameFromData(id:String, data:SongData):String
	{
		if (data.song.startsWith("#"))
			return Lang.get(data.song);

		if (Lang.getNoHash(id) != id)
			return Lang.getNoHash(id);

		return data.song;
	}

	public static function getSongArtist(id:String, ?difficulty:String = "normal"):String
	{
		var filename:String = chartPath(id, difficulty);

		var data:SongData = null;
		if (Paths.jsonExists(filename))
		{
			data = cast Paths.json(filename).song;
			if (data != null && data.artist != null)
				return data.artist;
		}

		filename = filename.substring(0, filename.lastIndexOf("/")+1) + "_data";
		if (Paths.jsonExists(filename))
		{
			data = cast Paths.json(filename);
			if (data != null && data.artist != null)
				return data.artist;
		}

		filename = filename.substring(0, filename.lastIndexOf("/"));
		filename = filename.substring(0, filename.lastIndexOf("/")+1) + "_data";
		if (Paths.jsonExists(filename))
		{
			data = cast Paths.json(filename);
			if (data != null && data.artist != null)
				return data.artist;
		}

		return "";
	}

	public static function getSongSideList(id:String, ?difficulty:String = "normal"):Array<String>
	{
		var filename:String = chartPath(id, difficulty);

		var data:SongData = null;
		if (Paths.jsonExists(filename))
			data = cast Paths.json(filename).song;

		if (data != null)
		{
			data = correctDivisions(data);
			return data.columnDivisionNames.copy();
		}

		return [];
	}

	public static function loadSongDirect(filename:String, ?deleteOutsideNotes:Bool = true, ?shouldCorrectEvents:Bool = true, ?shouldParse:Bool = true):SongData
	{
		// Generate a base chart so the game doesn't just crash if it can't find the file
		var retSong:SongData = 
		{
			song: filename,
			artist: "",
			eventFile: "_events",
			bpmMap: [[0, 120]],
			scrollSpeeds: [[0, 1]],
			player1: TitleState.defaultVariables.player1,
			player2: TitleState.defaultVariables.player2,
			player3: TitleState.defaultVariables.gf,
			stage: TitleState.defaultVariables.stage,
			tracks: [["Inst", 0], ["Voices", 1]],
			notes: [{mustHitSection: false, lengthInSteps: 16, sectionNotes: []}]
		}
		if ( Paths.jsonExists(filename) )
			retSong = cast Paths.json(filename).song;

		// Load in external song data if it exists
		var dataPaths:Array<String> = [];
		var dataPathArray:Array<String> = filename.split("/");
		dataPathArray.pop();
		dataPathArray.push("_data");
		var dataPath:String = dataPathArray.join("/");
		if ( Paths.jsonExists(dataPath) )
			dataPaths.unshift(dataPath);

		dataPathArray.pop();
		dataPathArray.pop();
		dataPathArray.push("_data");
		dataPath = dataPathArray.join("/");
		if ( Paths.jsonExists(dataPath) )
			dataPaths.unshift(dataPath);

		if (dataPaths.length > 0)
			retSong = applyDataFile(retSong, combineDataFile(dataPaths));

		if (retSong.eventFile == null || retSong.eventFile == "")
			retSong.eventFile = "_events";

		// Load in events. Parts of this system are a holdover from when events could be saved in chart files
		retSong.events = [];
		var eventsPathArray:Array<String> = filename.split("/");
		eventsPathArray.pop();
		eventsPathArray.push(retSong.eventFile);
		var eventsPath:String = eventsPathArray.join("/");
		if ( Paths.jsonExists(eventsPath) )
			retSong.events = loadEvents(eventsPath);

		if (shouldParse)
			return parseSongData(retSong, deleteOutsideNotes, shouldCorrectEvents);
		return retSong;
	}

	static function combineDataFile(files:Array<String>):SongData
	{
		var data:Dynamic = {};

		for (f in files)
		{
			var baseData:Dynamic = Paths.json(f);
			for (k in Reflect.fields(baseData))
				Reflect.setField(data, k, Reflect.field(baseData, k));
		}

		return cast data;
	}

	static function applyDataFile(song:SongData, baseData:SongData):SongData
	{
		var retSong:SongData = song;

		if (retSong.song == null || retSong.song == "")
			retSong.song = baseData.song;

		if (retSong.artist == null || retSong.artist == "")
			retSong.artist = baseData.artist;

		if (retSong.skipCountdown == null)
			retSong.skipCountdown = baseData.skipCountdown;

		if (retSong.eventFile == null || retSong.eventFile == "")
			retSong.eventFile = baseData.eventFile;

		if (retSong.offset == null)
			retSong.offset = baseData.offset;

		if (retSong.player1 == null || retSong.player1 == "")
			retSong.player1 = baseData.player1;

		if (retSong.player2 == null || retSong.player2 == "")
			retSong.player2 = baseData.player2;

		if ((retSong.player3 == null || retSong.player3 == "") && (baseData.player3 != null && baseData.player3 != ""))
			retSong.player3 = baseData.player3;

		var i:Int = 4;
		while (Reflect.hasField(retSong, "player" + Std.string(i)) || Reflect.hasField(baseData, "player" + Std.string(i)))
		{
			if (Reflect.hasField(baseData, "player" + Std.string(i)) && !Reflect.hasField(retSong, "player" + Std.string(i)))
				Reflect.setField(retSong, "player" + Std.string(i), Reflect.field(baseData, "player" + Std.string(i)));
			i++;
		}

		if (retSong.characterPrefix == null || retSong.characterPrefix == "")
			retSong.characterPrefix = baseData.characterPrefix;

		if (retSong.characterSuffix == null || retSong.characterSuffix == "")
			retSong.characterSuffix = baseData.characterSuffix;

		if (retSong.stage == null || retSong.stage == "")
			retSong.stage = baseData.stage;

		if (retSong.uiSkin == null || retSong.uiSkin == "")
			retSong.uiSkin = baseData.uiSkin;

		if (retSong.noteType == null || retSong.noteType.length < 1)
			retSong.noteType = baseData.noteType;

		if (retSong.columnDivisions == null)
			retSong.columnDivisions = baseData.columnDivisions;

		if (retSong.columnDivisionNames == null)
			retSong.columnDivisionNames = baseData.columnDivisionNames;

		if (retSong.singerColumns == null)
			retSong.singerColumns = baseData.singerColumns;

		if (retSong.bpmMap == null || retSong.bpmMap.length == 0)
			retSong.bpmMap = baseData.bpmMap;

		if (retSong.scrollSpeeds == null || retSong.scrollSpeeds.length == 0)
			retSong.scrollSpeeds = baseData.scrollSpeeds;

		if (retSong.altSpeedCalc == null)
			retSong.altSpeedCalc = baseData.altSpeedCalc;

		if (retSong.tracks == null)
			retSong.tracks = baseData.tracks;

		if (retSong.allNotetypes == null)
			retSong.allNotetypes = baseData.allNotetypes;

		if (retSong.notetypeSingers == null)
			retSong.notetypeSingers = baseData.notetypeSingers;

		if (retSong.notetypeOverridesCam == null)
			retSong.notetypeOverridesCam = baseData.notetypeOverridesCam;

		if (retSong.music == null)
			retSong.music = baseData.music;

		return retSong;
	}

	public static function parseSongData(data:SongData, ?deleteOutsideNotes:Bool = true, ?shouldCorrectEvents:Bool = true):SongData
	{	// This function applies both to the play state and the chart editor, useful for saving charts to make the files smaller
		var retSong:SongData = data;

		if (retSong.song == null)
			retSong.song = "";

		if (retSong.artist == null)
			retSong.artist = "";

		if (retSong.skipCountdown == null)
			retSong.skipCountdown = false;

		if (retSong.offset == null)
			retSong.offset = 0;

		if (retSong.player1 == null || retSong.player1 == "")
			retSong.player1 = TitleState.defaultVariables.player1;

		if (retSong.player2 == null || retSong.player2 == "")
			retSong.player2 = TitleState.defaultVariables.player2;

		if (retSong.player3 == null || retSong.player3 == "")		// Compatibility with other chart formats
		{
			if (retSong.gfVersion != null && retSong.gfVersion != "")
				retSong.player3 = retSong.gfVersion;
			else if (retSong.gf != null && retSong.gf != "")
				retSong.player3 = retSong.gf;
		}

		if (retSong.characterPrefix == null)
			retSong.characterPrefix = "";

		if (retSong.characterSuffix == null)
			retSong.characterSuffix = "";

		if (retSong.stage == null || retSong.stage == "")
			retSong.stage = TitleState.defaultVariables.stage;

		var charCount:Int = 3;
		while (Reflect.hasField(retSong, "player" + Std.string(charCount + 1)))
			charCount++;

		if (retSong.notetypeSingers == null)
			retSong.notetypeSingers = [];

		while (retSong.notetypeSingers.length < charCount)
			retSong.notetypeSingers.push([]);

		if (retSong.notetypeOverridesCam == null)
			retSong.notetypeOverridesCam = true;

		if (retSong.music == null)
			retSong.music = { pause: "", gameOver: "", gameOverEnd: "", results: "", resultsEnd: "" };

		if (retSong.characterPrefix != "" || retSong.characterSuffix != "")
		{
			for (i in 0...charCount)
			{
				var p:String = Reflect.field(retSong, "player" + Std.string(i + 1));
				if (!((p.startsWith(retSong.characterPrefix) || retSong.characterPrefix == "") && (p.endsWith(retSong.characterSuffix) || retSong.characterSuffix == "")) && Paths.jsonExists("characters/" + retSong.characterPrefix + p + retSong.characterSuffix))
					Reflect.setField(retSong, "player" + Std.string(i + 1), retSong.characterPrefix + p + retSong.characterSuffix);
			}
		}

		if (!Paths.jsonExists("stages/" + retSong.stage))
		{
			if (Paths.jsonExists("stages/" + retSong.characterPrefix + retSong.stage + retSong.characterSuffix))
				retSong.stage = retSong.characterPrefix + retSong.stage + retSong.characterSuffix;
			else
			{
				for (f in Paths.listFilesSub("data/stages/", ".json"))
				{
					if (f.indexOf("/") > -1 && f.split("/")[f.split("/").length-1] == retSong.stage)
						retSong.stage = f;
				}
			}
		}

		if (retSong.uiSkin == null || retSong.uiSkin == "")
			retSong.uiSkin = "default";

		if (retSong.noteType == null || retSong.noteType.length < 1)
			retSong.noteType = ["default"];

		if (retSong.tracks == null)
		{
			retSong.tracks = [["Inst", 0]];
			if (retSong.needsVoices)
				retSong.tracks.push(["Voices", 1]);
		}

		if (retSong.useMustHit == null)
			retSong.useMustHit = true;

		retSong = correctDivisions(retSong);

		var columns:Int = retSong.columnDivisions.length;

		if (retSong.singerColumns == null)
			retSong.singerColumns = [];
		while (retSong.singerColumns.length < columns)
			retSong.singerColumns.push(retSong.columnDivisions[retSong.singerColumns.length]);
		if (retSong.singerColumns.length > columns)
			retSong.singerColumns.resize(columns);

		if (retSong.bpmMap == null || retSong.bpmMap.length == 0)
		{
			retSong.bpmMap = [[0, retSong.bpm]];

			for (i in 0...retSong.notes.length)
			{
				if (retSong.notes[i].changeBPM)
				{
					if (i > 0)
						retSong.bpmMap.push([i * 4, retSong.notes[i].bpm]);
					else
						retSong.bpmMap[0][1] = retSong.notes[i].bpm;
				}
			}
		}

		var poppers:Array<Array<Float>> = [];
		var bpmLast:Float = -1;
		for (b in retSong.bpmMap)
		{
			if (b[0] > 0 && bpmLast == b[1])
				poppers.push(b);
			else
				bpmLast = b[1];
		}
		for (p in poppers)
			retSong.bpmMap.remove(p);

		if (retSong.altSpeedCalc == null)
			retSong.altSpeedCalc = false;

		var songTimingStruct:TimingStruct = new TimingStruct();
		songTimingStruct.recalculateTimings(retSong.bpmMap);
		if (shouldCorrectEvents)			// This can be very resource intensive on songs with lots of events so make sure we're not doing it in the menus
			retSong.events = correctEvents(retSong.events, songTimingStruct);

		if (retSong.useBeats && retSong.notes.length > 1)
		{
			for (i in 1...retSong.notes.length)
			{
				if (retSong.notes[i].copyLast)
				{
					var c:Int = i;
					while (retSong.notes[c].copyLast)
						c--;

					retSong.notes[i].lengthInSteps = retSong.notes[c].lengthInSteps;
					retSong.notes[i].sectionNotes = [];
					for (a in retSong.notes[c].sectionNotes)
					{
						var b:Array<Dynamic> = [];
						for (aa in a)
							b.push(aa);
						retSong.notes[i].sectionNotes.push(b);
					}
					Reflect.deleteField(retSong.notes[i], "copyLast");
				}
			}
		}

		retSong = timeSections(retSong);
		if (retSong.useBeats)
			retSong = convertBeats(retSong, songTimingStruct);

		if (retSong.scrollSpeeds == null || retSong.scrollSpeeds.length == 0)
		{
			if (retSong.speed == null)
			{
				retSong.scrollSpeeds = [];
				for (s in retSong.notes)
				{
					if (s.scrollSpeeds != null && s.scrollSpeeds.length > 0)
					{
						for (sp in s.scrollSpeeds)
							retSong.scrollSpeeds.push([sp[0] + (s.firstStep / 4), sp[1]]);
						s.scrollSpeeds = [];
					}
				}
			}
			else
				retSong.scrollSpeeds = [[0, retSong.speed]];
		}

		// Do a buncha cleanup on the sections themselves
		var quickNotes:Array<Array<Float>> = [];
		for (s in retSong.notes)
		{
			if (s.altAnim)
			{
				if (s.defaultNoteP2 == null || s.defaultNoteP2 == "")
					s.defaultNoteP2 = "altAnimation";
			}

			if (retSong.allNotetypes != null)
			{
				if (Std.isOfType(s.defaultNoteP1, Int))
					s.defaultNoteP1 = retSong.allNotetypes[Std.int(s.defaultNoteP1-1)];

				if (Std.isOfType(s.defaultNoteP2, Int))
					s.defaultNoteP2 = retSong.allNotetypes[Std.int(s.defaultNoteP2-1)];
			}

			var poppers:Array<Array<Dynamic>> = [];
			for (n in s.sectionNotes)
			{
				if (n.length > 4)
				{
					while (n.length > 4)
						n.pop();
				}
				if (n.length > 3)
				{
					if (Std.isOfType(n[3], Bool))		// The Ugh charts in base game have a value of "true" for any note where Tankman needs to express his feelings
					{
						if (n[3])
							n[3] = "altAnimation";
						else
							n.pop();
					}

					if (Std.isOfType(n[3], Int) && retSong.allNotetypes != null)
					{
						if (n[3] > 0)
							n[3] = retSong.allNotetypes[Std.int(n[3]-1)];
					}

					if (!Std.isOfType(n[3], String))
						n[3] = Std.string(n[3]);
					else if (n[3] == "")
						n.pop();
				}

				if (n[1] < 0 || (n[1] >= retSong.columnDivisions.length && deleteOutsideNotes))
					poppers.push(n);

				for (quickNote in quickNotes)
				{
					if (Math.abs(quickNote[0] - n[0]) < 15 && quickNote[1] == n[1])
						poppers.push(n);
				}
				quickNotes.push([n[0], n[1]]);
			}
			for (p in poppers)
				s.sectionNotes.remove(p);
		}

		retSong = cleanNotes(retSong, songTimingStruct);

		return retSong;
	}

	public static function correctDivisions(data:SongData):SongData
	{
		if (data.columnDivisions == null)
		{
			data.columnDivisions = [];
			var columns:Int = 8;

			while (data.columnDivisions.length < columns)
			{
				if (data.columnDivisions.length >= columns / 2)
					data.columnDivisions.push(0);
				else
					data.columnDivisions.push(1);
			}
			if (data.columnDivisions.length > columns)
				data.columnDivisions.resize(columns);
		}

		if (data.columnDivisionNames == null)
			data.columnDivisionNames = ["#fpSandboxSide0", "#fpSandboxSide1"];

		var uniqueDivisions:Array<Int> = [];
		for (i in data.columnDivisions)
		{
			if (!uniqueDivisions.contains(i))
				uniqueDivisions.push(i);
		}

		if (data.columnDivisionNames.length < uniqueDivisions.length)
		{
			while (data.columnDivisionNames.length < uniqueDivisions.length)
				data.columnDivisionNames.push("Singer " + Std.string(data.columnDivisionNames.length + 1));
		}
		if (data.columnDivisionNames.length > uniqueDivisions.length)
			data.columnDivisionNames.resize(uniqueDivisions.length);

		return data;
	}

	public static function loadEvents(path:String, ?pathIsDirect:Bool = false):Array<EventData>
	{
		var eventList:Array<EventData> = [];
		var eventStuff:Dynamic;
		if (pathIsDirect)
			eventStuff = Paths.jsonDirect(path);
		else
			eventStuff = Paths.json(path);

		if (Reflect.hasField(eventStuff, "eventData"))
		{
			var eventArray:Array<Array<Float>> = cast eventStuff.events;
			var eventData:Array<EventData> = cast eventStuff.eventData;
			for (e in eventArray)
			{
				if (e[1] < eventData.length && eventData[Std.int(e[1])].type != null)
				{
					var newEvent:EventData = Reflect.copy(eventData[Std.int(e[1])]);
					newEvent.beat = e[0];
					eventList.push(newEvent);
				}
			}
		}
		else
			eventList = cast eventStuff.events;

		return eventList;
	}

	public static function correctEvents(events:Array<EventData>, songTimingStruct:TimingStruct):Array<EventData>
	{
		var retEvents:Array<EventData> = events;

		for (i in 0...retEvents.length)
		{
			if (retEvents[i].time == null && retEvents[i].beat != null)
				retEvents[i].time = songTimingStruct.timeFromBeat(retEvents[i].beat);

			if (retEvents[i].beat == null && retEvents[i].time != null)
				retEvents[i].beat = songTimingStruct.beatFromTime(retEvents[i].time);

			retEvents[i].typeShort = retEvents[i].type.split('/')[retEvents[i].type.split('/').length-1];

			if (Paths.jsonExists("events/" + retEvents[i].type))
			{
				var eventParams:Array<EventParams> = cast Paths.json("events/" + retEvents[i].type).parameters;
				if (eventParams != null)
				{
					var poppers:Array<EventParams> = [];
					for (p in eventParams)
					{
						if (p.type == "label")
							poppers.push(p);
					}
					for (p in poppers)
						eventParams.remove(p);

					var doAlert:Bool = false;
					for (p in eventParams)
					{
						if (p.id == null)
						{
							p.id = Std.string(eventParams.indexOf(p));
							doAlert = true;
						}
					}
					if (doAlert)
						Application.current.window.alert("Event file \"events/"+retEvents[i].type+".json\" is using deprecated format", "Alert");

					if (Std.isOfType(retEvents[i].parameters, Array))
					{
						var newParameters:Dynamic = {};
						for (j in 0...retEvents[i].parameters.length)
						{
							if (j < eventParams.length)
								Reflect.setField(newParameters, eventParams[j].id, retEvents[i].parameters[j]);
						}
						retEvents[i].parameters = newParameters;
					}
		
					for (p in eventParams)
					{
						if (!Reflect.hasField(retEvents[i].parameters, p.id))
							Reflect.setField(retEvents[i].parameters, p.id, p.defaultValue);
					}
				}
			}
		}

		ArraySort.sort(retEvents, sortEvents);
		return retEvents;
	}

	public static function timeSections(chart:SongData):SongData
	{
		for (s in chart.notes)
		{
			if (s.lengthInSteps == null)
				s.lengthInSteps = 16;

			var i:Int = chart.notes.indexOf(s);
			if (i == 0)
				s.firstStep = 0;
			else
				s.firstStep = chart.notes[i-1].firstStep + chart.notes[i-1].lengthInSteps;
			s.lastStep = s.firstStep + s.lengthInSteps;
		}

		return chart;
	}

	public static function convertBeats(chart:SongData, timing:TimingStruct):SongData
	{
		for (s in chart.notes)
		{
			for (n in s.sectionNotes)
			{
				if (n.length < 3)
					n[2] = 0;
				n[2] = timing.timeFromBeat((s.firstStep / 4.0) + n[0] + n[2]) - timing.timeFromBeat((s.firstStep / 4.0) + n[0]);
				n[0] = timing.timeFromBeat((s.firstStep / 4.0) + n[0]);
			}
		}

		return chart;
	}

	public static function cleanNotes(chart:SongData, timing:TimingStruct):SongData
	{
		var allNotes:Array<Array<Dynamic>> = [];
		var allStarts:Array<Array<Float>> = [];

		for (sec in chart.notes)
		{
			for (note in sec.sectionNotes)
			{
				if (Reflect.hasField(sec, "mustHitSection"))
				{
					if (sec.mustHitSection)
					{
						if (note[1] % chart.columnDivisions.length >= chart.columnDivisions.length / 2)
							note[1] -= chart.columnDivisions.length / 2;
						else
							note[1] += chart.columnDivisions.length / 2;
					}
				}
				allStarts.push([note[0], note[1]]);
				allNotes.push(note);
			}

			sec.sectionNotes = [];
		}

		for (sec in chart.notes)
		{
			if (Reflect.hasField(sec, "mustHitSection"))
			{
				if (sec.mustHitSection)
					sec.camOn = 0;
				else
					sec.camOn = 1;
				Reflect.deleteField(sec, "mustHitSection");
			}
		}

		for (note in allNotes)
		{
			if (note[2] > 0)
			{
				for (s in allStarts)
				{
					if (s[0] > note[0] && s[0] <= note[0] + note[2] && s[1] == note[1])
					{
						if (timing.beatFromTime(s[0]) - timing.beatFromTime(note[0]) < 0.125)
							note[2] = 0;
						else
							note[2] = timing.timeFromBeat(timing.beatFromTime(s[0]) - 0.125) - note[0];
					}
				}
			}
			if (note[2] < 0)
				note[2] = 0;

			var noteStep:Float = timing.stepFromTime(note[0]);
			var secIndex:Int = -1;

			for (i in 0...chart.notes.length)
			{
				if (secIndex < 0)
				{
					if ((noteStep >= chart.notes[i].firstStep && noteStep < chart.notes[i].lastStep) || i == chart.notes.length-1)
						secIndex = i;
				}
			}
			chart.notes[secIndex].sectionNotes.push(note);
		}

		return chart;
	}

	public static function calcChartInfo(chart:SongData, ?chartSide:Int = 0):String
	{
		var allNotes:Array<Float> = [];
		var noteCombos:Array<Int> = [0, 0, 0, 0];
		var types:Array<String> = [];
		var mineTypes:Array<String> = [];
		var mines:Int = 0;
		var holds:Int = 0;
		var rolls:Int = 0;
		var songStart:Float = 99999;
		var songLength:Float = 0;

		var validColumns:Array<Int> = [];
		for (i in 0...chart.columnDivisions.length)
		{
			if (chart.columnDivisions[i] == chartSide)
				validColumns.push(i);
		}
		var numKeys:Int = validColumns.length;

		for (s in chart.notes)
		{
			if (s.defaultNoteP1 != null && s.defaultNoteP1 != "" && !types.contains(s.defaultNoteP1))
			{
				types.push(s.defaultNoteP1);
				if (Paths.jsonExists("notetypes/" + s.defaultNoteP1))
				{
					var typeData:NoteTypeData = cast Paths.json("notetypes/" + s.defaultNoteP1);
					if (typeData.p1ShouldMiss)
						mineTypes.push(s.defaultNoteP1);
				}
			}

			if (s.defaultNoteP2 != null && s.defaultNoteP2 != "" && !types.contains(s.defaultNoteP2))
			{
				types.push(s.defaultNoteP2);
				if (Paths.jsonExists("notetypes/" + s.defaultNoteP2))
				{
					var typeData:NoteTypeData = cast Paths.json("notetypes/" + s.defaultNoteP2);
					if (typeData.p1ShouldMiss)
						mineTypes.push(s.defaultNoteP2);
				}
			}

			for (n in s.sectionNotes)
			{
				var type:String = "";
				if (n.length > 3)
					type = n[3];
				if (!types.contains(type))
				{
					types.push(type);
					if (type != "" && Paths.jsonExists("notetypes/" + type))
					{
						var typeData:NoteTypeData = cast Paths.json("notetypes/" + type);
						if (typeData.p1ShouldMiss)
							mineTypes.push(type);
					}
				}
			}

			for (n in s.sectionNotes)
			{
				var column:Int = n[1];
				if (s.mustHitSection)
				{
					if (column >= Std.int(chart.columnDivisions.length / 2))
						column -= Std.int(chart.columnDivisions.length / 2);
					else
						column += Std.int(chart.columnDivisions.length / 2);
				}

				var type:String = "";
				if (types.length > 1)
				{
					if (n.length > 3)
						type = n[3];
					if (type == "")
					{
						if (column >= Std.int(chart.columnDivisions.length / 2))
						{
							if (s.defaultNoteP1 != null && s.defaultNoteP1 != "")
								type = s.defaultNoteP1;
						}
						else
						{
							if (s.defaultNoteP2 != null && s.defaultNoteP2 != "")
								type = s.defaultNoteP2;
						}
					}
				}

				if (validColumns.contains(column))
				{
					if (n[0] < songStart)
						songStart = n[0];
					if (n[0] + n[2] > songLength)
						songLength = n[0] + n[2];
					if (mineTypes.contains(type))
						mines++;
					else
					{
						allNotes.push(n[0]);
						if (n[2] > 0)
						{
							if (type == "roll")
								rolls++;
							else
								holds++;
						}
					}
				}
			}
		}

		if (songStart > 99990)
			return "";

		var doneNotes:Array<Float> = [];
		for (n in allNotes)
		{
			noteCombos[0]++;
			if (doneNotes.indexOf(n) == -1)
			{
				var noteCount:Int = allNotes.filter(function(a) return a == n).length;
				if (noteCount > 1 && noteCount <= 4)
					noteCombos[noteCount-1]++;
				doneNotes.push(n);
			}
		}

		return (numKeys == 4 ? "" : Lang.get("#fpKeys", [Std.string(numKeys)]) + "\n")
		+ Lang.get("#fpSongLength", [FlxStringUtil.formatTime((songLength - songStart) / 1000.0)]) + "\n"
		+ Lang.get("#fpSongNotes", [Std.string(noteCombos[0])]) + "\n"
		+ (noteCombos[1] > 0 ? Lang.get("#fpSongDoubles", [Std.string(noteCombos[1])]) + "\n" : "")
		+ (noteCombos[2] > 0 ? Lang.get("#fpSongTriples", [Std.string(noteCombos[2])]) + "\n" : "")
		+ (noteCombos[3] > 0 ? Lang.get("#fpSongQuads", [Std.string(noteCombos[3])]) + "\n" : "")
		+ Lang.get("#fpSongSustains", [Std.string(holds)]) + "\n"
		+ (rolls > 0 ? Lang.get("#fpSongRolls", [Std.string(rolls)]) + "\n" : "")
		+ (mines > 0 ? Lang.get("#fpSongMines", [Std.string(mines)]) + "\n" : "");
	}
}