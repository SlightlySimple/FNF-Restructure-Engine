package data;

import data.ObjectData;
import objects.Note;
import helpers.Cloner;
import haxe.ds.ArraySort;
import flixel.util.FlxStringUtil;
import lime.app.Application;
import menus.freeplay.FreeplayMenuSubState;

using StringTools;

typedef SongData =
{
	var song:String;
	var artist:String;
	var charter:String;
	var preview:Array<Float>;
	var ?ratings:Array<Int>;
	var ?useBeats:Bool;
	var ?useMustHit:Null<Bool>;
	var ?skipCountdown:Null<Bool>;
	var ?bpm:Float;
	var ?bpmMap:Array<Array<Float>>;
	var ?offset:Null<Float>;
	var ?speed:Null<Float>;
	var ?scrollSpeeds:Array<Array<Float>>;
	var ?altSpeedCalc:Null<Bool>;
	var ?metaFile:String;
	var ?eventFile:String;
	var ?columns:Array<SongColumnData>;
	var ?columnDivisions:Array<Int>;
	var ?columnDivisionNames:Array<String>;
	var ?allNotetypes:Array<String>;
	var ?notetypeSingers:Array<Array<String>>;
	var ?notetypeOverridesCam:Null<Bool>;
	var ?characters:Array<String>;
	var ?player1:String;
	var ?player2:String;
	var ?player3:String;
	var ?characterPrefix:String;
	var ?characterSuffix:String;
	var ?singerColumns:Array<Int>;
	var ?gf:String;
	var ?gfVersion:String;
	var stage:String;
	var ?tracks:Array<Array<Dynamic>>;
	var ?needsVoices:Null<Bool>;
	var ?notes:Array<SectionData>;
	var ?noteType:Array<String>;
	var ?uiSkin:String;
	var ?events:Array<EventData>;
	var ?music:SongMusicData;
}

typedef SongMusicData =
{
	var pause:String;
	var gameOver:String;
	var gameOverEnd:String;
	var results:String;
}

typedef SongColumnData =
{
	var division:Int;
	var ?singer:Int;
	var ?anim:String;
	var ?missAnim:String;
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
	var ?beatMultiplier:Null<Int>;

	var ?defaultNotetypes:Array<Dynamic>;
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

typedef NoteData =
{
	var strumTime:Float;
	var sustainLength:Float;
	var column:Int;
	var type:String;
}

typedef EventTypeData =
{
	var icon:String;
	var parameters:Array<EventParams>;
}

typedef EventParams =
{
	var ?id:String;
	var label:String;
	var infoText:String;
	var type:String;
	var ?time:String;
	var defaultValue:Dynamic;
	var options:Array<String>;
	var min:Float;
	var max:Float;
	var increment:Float;
	var decimals:Int;
}

typedef SongQuickInfo =
{
	var name:String;
	var bpmRange:Array<Float>;
	var ratings:Array<Int>;
}

class Song
{
	public static var defaultSingAnimations:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

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

	public static function chartPath(id:String, ?difficulty:String = "normal", ?variant:String = "bf", ?alert:Bool = true):String
	{
		var idShort:String = id.substring(id.lastIndexOf("/") + 1, id.length);

		var fileChecks:Array<String> = [id + "/" + variant + "/" + idShort + "-" + difficulty, id + "/" + variant + "/" + difficulty, id + "/" + variant + "/" + idShort, id + "/" + idShort + "-" + difficulty, id + "/" + difficulty, id + "/" + idShort];
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

	public static function loadSong(id:String, difficulty:String, ?variant:String = "bf", ?shouldCorrectEvents:Bool = true, ?shouldParse:Bool = true):SongData
	{
		return loadSongDirect(chartPath(id, difficulty, variant), true, shouldCorrectEvents, shouldParse);
	}

	public static function getSongName(id:String, ?difficulty:String = "normal", ?variant:String = "bf"):String
	{
		var filename:String = chartPath(id, difficulty, variant);

		var data:SongData = null;
		if (Paths.jsonExists(filename))
		{
			data = cast Paths.json(filename).song;
			data = applyDataAndMeta(data, filename);
		}

		if (data != null)
		{
			if (data.song.startsWith("#"))
				return Lang.get(data.song);

			return data.song;
		}

		return id;
	}

	public static function getSongNameFromData(id:String, ?difficulty:String = "normal", data:SongData):String
	{
		if (data.song.startsWith("#"))
			return Lang.get(data.song);

		return data.song;
	}

	public static function getSongArtist(id:String, ?difficulty:String = "normal", ?variant:String = "bf"):String
	{
		var filename:String = chartPath(id, difficulty, variant);

		var data:SongData = null;
		if (Paths.jsonExists(filename))
		{
			data = cast Paths.json(filename).song;
			data = applyDataAndMeta(data, filename);
		}

		if (data != null && data.artist != null)
			return data.artist;

		return "";
	}

	public static function getSongSideList(id:String, ?difficulty:String = "normal", ?variant:String = "bf"):Array<String>
	{
		var filename:String = chartPath(id, difficulty, variant);

		var data:SongData = null;
		if (Paths.jsonExists(filename))
		{
			data = cast Paths.json(filename).song;
			data = applyDataAndMeta(data, filename);
		}

		if (data != null)
		{
			data = correctDivisions(data);
			return data.columnDivisionNames.copy();
		}

		return [];
	}

	public static function getSongVariantList(id:String, ?difficulty:String = "normal", ?variant:String = "bf"):Array<String>
	{
		var variants:Array<String> = [""];
		var track:String = "Inst";

		var filename:String = chartPath(id, difficulty, variant);

		var data:SongData = null;
		if (Paths.jsonExists(filename))
		{
			data = cast Paths.json(filename).song;
			data = applyDataAndMeta(data, filename);
		}

		if (data != null)
		{
			if (data.tracks != null && data.tracks.length > 0)
				track = data.tracks[0][0];
		}

		for (file in Paths.listFilesSub("data/songs/" + id + "/", ".json"))
		{
			if (file.startsWith("_variant_"))
			{
				var variant:String = file.substr("_variant_".length);
				if (!variants.contains(variant) && Paths.songExists(id, track + "-" + variant))
				{
					var variantInfo:WeekSongData = cast Paths.json("songs/" + id + "/" + file);
					if (variantInfo.allowVariantOnBase)
					{
						var songBeaten:Bool = true;
						if (variantInfo.lockedOnBase)
							songBeaten = ScoreSystems.songVariantBeaten(id, variant);
						if (songBeaten)
							variants.push(variant);
					}
				}
			}
		}

		return variants;
	}

	public static function getSongQuickInfo(id:String, difficulty:String, ?variant:String = "bf"):SongQuickInfo
	{
		var filename:String = chartPath(id, difficulty, variant);

		var data:SongData = null;
		if (Paths.jsonExists(filename))
		{
			data = cast Paths.json(filename).song;
			data = applyDataAndMeta(data, filename);
		}

		if (data != null)
		{
			var quickInfo:SongQuickInfo = {name: getSongNameFromData(id, difficulty, data), bpmRange: [], ratings: [0, 0]};
			if (data.ratings != null)
				quickInfo.ratings = data.ratings;
			if (data.bpmMap != null)
			{
				var bpmMin:Float = -1;
				var bpmMax:Float = -1;
				for (bpm in data.bpmMap)
				{
					if (bpmMin == -1 || bpm[1] < bpmMin)
						bpmMin = bpm[1];
					if (bpmMax == -1 || bpm[1] > bpmMax)
						bpmMax = bpm[1];
				}
				quickInfo.bpmRange = [bpmMin, bpmMax];
			}
			else if (data.bpm != null)
			{
				var bpmMin:Float = data.bpm;
				var bpmMax:Float = data.bpm;
				for (section in data.notes)
				{
					if (section.bpm != null && section.changeBPM)
					{
						if (section.bpm < bpmMin)
							bpmMin = section.bpm;
						if (section.bpm > bpmMax)
							bpmMax = section.bpm;
					}
				}
				quickInfo.bpmRange = [bpmMin, bpmMax];
			}

			return quickInfo;
		}

		return null;
	}

	public static function getFreeplayTrackFromSong(id:String, ?difficulty:String = "normal", ?variant:String = "bf"):FreeplayTrack
	{
		var ret:FreeplayTrack = {name: "Inst", timings: [], start: -1, end: -1};

		var filename:String = chartPath(id, difficulty, variant);

		var data:SongData = null;
		if (Paths.jsonExists(filename))
		{
			data = cast Paths.json(filename).song;
			data = applyDataAndMeta(data, filename);
		}

		if (data != null)
		{
			if (data.tracks != null && data.tracks.length > 0)
				ret.name = data.tracks[0][0];

			if (data.bpmMap != null && data.bpmMap.length > 0)
				ret.timings = data.bpmMap;
			else if (data.bpm != null)
				ret.timings = [[0, data.bpm]];

			var songTimingStruct:TimingStruct = new TimingStruct();
			songTimingStruct.recalculateTimings(ret.timings);

			var preview:Array<Float> = [0, 32];
			if (data.preview != null)
				preview = data.preview;
			else
			{
				var i:Int = 0;
				var steps:Float = 0;
				for (s in data.notes)
				{
					if (s.sectionNotes.length > 0)
						break;
					i++;
					if (s.lengthInSteps != null)
						steps += s.lengthInSteps;
					else
						steps += 16;
				}

				preview[0] += steps / 4;
				preview[1] += steps / 4;
			}

			ret.start = songTimingStruct.timeFromBeat(Math.min(preview[0], preview[1]));
			ret.end = songTimingStruct.timeFromBeat(Math.max(preview[0], preview[1]));
		}

		ret.name = Paths.song(id, ret.name);
		return ret;
	}



	public static function loadSongDirect(filename:String, ?deleteOutsideNotes:Bool = true, ?shouldCorrectEvents:Bool = true, ?shouldParse:Bool = true):SongData
	{
		// Generate a base chart so the game doesn't just crash if it can't find the file
		var retSong:SongData = 
		{
			song: filename,
			artist: "",
			charter: "",
			preview: [0, 32],
			ratings: [0, 0],
			eventFile: "_events",
			bpmMap: [[0, 120]],
			scrollSpeeds: [[0, 1]],
			player1: TitleState.defaultVariables.player1,
			player2: TitleState.defaultVariables.player2,
			player3: TitleState.defaultVariables.gf,
			stage: TitleState.defaultVariables.stage,
			tracks: [["Inst", 0, 0], ["Voices", 1, 0]],
			notes: [{mustHitSection: false, lengthInSteps: 16, sectionNotes: []}]
		}
		if (Paths.jsonExists(filename))
			retSong = cast Paths.json(filename).song;

		// Load in external song data if it exists
		retSong = applyDataAndMeta(retSong, filename);

		if (retSong.eventFile == null || retSong.eventFile == "")
			retSong.eventFile = "_events";

		// Load in events. Parts of this system are a holdover from when events could be saved in chart files
		retSong.events = [];
		var eventsPathArray:Array<String> = filename.split("/");
		eventsPathArray.pop();
		eventsPathArray.push(retSong.eventFile);
		var eventsPath:String = eventsPathArray.join("/");
		if (Paths.jsonExists(eventsPath))
			retSong.events = loadEvents(eventsPath);

		if (shouldParse)
			return parseSongData(retSong, deleteOutsideNotes, shouldCorrectEvents);
		return retSong;
	}

	static function applyDataAndMeta(song:SongData, filename:String):SongData
	{
		var retSong:SongData = song;

		var dataPaths:Array<String> = [];
		var dataPathArray:Array<String> = filename.split("/");
		dataPathArray.pop();
		dataPathArray.push("_data");
		var dataPath:String = dataPathArray.join("/");
		if (Paths.jsonExists(dataPath))
			dataPaths.unshift(dataPath);

		dataPathArray.pop();
		dataPathArray.pop();
		dataPathArray.push("_data");
		dataPath = dataPathArray.join("/");
		if (Paths.jsonExists(dataPath))
			dataPaths.unshift(dataPath);

		if (dataPaths.length > 0)
			retSong = applyDataFile(retSong, combineDataFile(dataPaths));

		if (retSong.metaFile != null && retSong.metaFile != "")
		{
			var metaPathArray:Array<String> = filename.split("/");
			metaPathArray.pop();
			metaPathArray.push(retSong.metaFile);
			var metaPath:String = metaPathArray.join("/");
			retSong = applyMetaFile(retSong, Paths.json(metaPath));
		}

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

		if (retSong.charter == null || retSong.charter == "")
			retSong.charter = baseData.charter;

		if (retSong.preview == null || retSong.preview.length < 2)
			retSong.preview = baseData.preview;

		if (retSong.skipCountdown == null)
			retSong.skipCountdown = baseData.skipCountdown;

		if (retSong.metaFile == null || retSong.metaFile == "")
			retSong.metaFile = baseData.metaFile;

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

		if (retSong.columns == null)
			retSong.columns = baseData.columns;

		if (retSong.columnDivisionNames == null)
			retSong.columnDivisionNames = baseData.columnDivisionNames;

		if (retSong.bpmMap == null || retSong.bpmMap.length == 0)
			retSong.bpmMap = baseData.bpmMap;

		if (retSong.scrollSpeeds == null || retSong.scrollSpeeds.length == 0)
			retSong.scrollSpeeds = baseData.scrollSpeeds;

		if (retSong.altSpeedCalc == null)
			retSong.altSpeedCalc = baseData.altSpeedCalc;

		if (retSong.tracks == null)
			retSong.tracks = baseData.tracks;

		if (retSong.notetypeSingers == null)
			retSong.notetypeSingers = baseData.notetypeSingers;

		if (retSong.notetypeOverridesCam == null)
			retSong.notetypeOverridesCam = baseData.notetypeOverridesCam;

		if (retSong.music == null)
			retSong.music = baseData.music;

		return retSong;
	}

	static function applyMetaFile(song:SongData, baseData:SongData):SongData
	{
		var retSong:SongData = song;

		if (baseData.song != null)
			retSong.song = baseData.song;

		if (baseData.artist != null)
			retSong.artist = baseData.artist;

		if (baseData.charter != null)
			retSong.charter = baseData.charter;

		if (baseData.preview != null && baseData.preview.length >= 2)
			retSong.preview = baseData.preview;

		if (baseData.skipCountdown != null)
			retSong.skipCountdown = baseData.skipCountdown;

		if (baseData.eventFile != null)
			retSong.eventFile = baseData.eventFile;

		if (baseData.offset != null)
			retSong.offset = baseData.offset;

		if (baseData.characters != null)
		{
			for (i in 0...baseData.characters.length)
			{
				if (baseData.characters[i] != null && baseData.characters[i] != "")
					Reflect.setField(retSong, "player" + Std.string(i + 1), baseData.characters[i]);
			}
		}
		else
		{
			if (baseData.player1 != null && baseData.player1 != "")
				retSong.player1 = baseData.player1;

			if (baseData.player2 != null && baseData.player2 != "")
				retSong.player2 = baseData.player2;

			if (baseData.player3 != null && baseData.player3 != "")
				retSong.player3 = baseData.player3;

			var i:Int = 4;
			while (Reflect.hasField(retSong, "player" + Std.string(i)) || Reflect.hasField(baseData, "player" + Std.string(i)))
			{
				if (Reflect.hasField(baseData, "player" + Std.string(i)))
					Reflect.setField(retSong, "player" + Std.string(i), Reflect.field(baseData, "player" + Std.string(i)));
				i++;
			}
		}

		if (baseData.characterPrefix != null)
			retSong.characterPrefix = baseData.characterPrefix;

		if (baseData.characterSuffix != null)
			retSong.characterSuffix = baseData.characterSuffix;

		if (baseData.stage != null && baseData.stage != "")
			retSong.stage = baseData.stage;

		if (baseData.uiSkin != null && baseData.uiSkin != "")
			retSong.uiSkin = baseData.uiSkin;

		if (baseData.noteType != null && baseData.noteType.length > 0)
			retSong.noteType = baseData.noteType;

		if (baseData.columnDivisionNames != null)
			retSong.columnDivisionNames = baseData.columnDivisionNames;

		if (baseData.bpmMap != null && baseData.bpmMap.length > 0)
			retSong.bpmMap = baseData.bpmMap;
		else if (baseData.bpm != null)
			retSong.bpmMap = [[0, baseData.bpm]];

		if (baseData.scrollSpeeds != null && baseData.scrollSpeeds.length > 0)
			retSong.scrollSpeeds = baseData.scrollSpeeds;
		else if (baseData.speed != null)
			retSong.scrollSpeeds = [[0, baseData.speed]];

		if (baseData.altSpeedCalc != null)
			retSong.altSpeedCalc = baseData.altSpeedCalc;

		if (baseData.tracks != null)
			retSong.tracks = baseData.tracks;

		if (baseData.notetypeSingers != null)
			retSong.notetypeSingers = baseData.notetypeSingers;

		if (baseData.notetypeOverridesCam != null)
			retSong.notetypeOverridesCam = baseData.notetypeOverridesCam;

		if (baseData.music != null)
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

		if (retSong.charter == null)
			retSong.charter = "";

		if (retSong.preview == null)
			retSong.preview = [];

		if (retSong.ratings == null)
			retSong.ratings = [0, 0];

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
			retSong.music = { pause: "", gameOver: "", gameOverEnd: "", results: "" };

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
			retSong.tracks = [["Inst", 0, 0]];
			if (retSong.needsVoices)
				retSong.tracks.push(["Voices", 1, 0]);
		}

		for (t in retSong.tracks)
		{
			if (t.length == 2)
				t.push(0);
		}

		if (retSong.tracks[0][2] != 0)
			retSong.tracks[0][2] = 0;

		if (retSong.useMustHit == null)
			retSong.useMustHit = true;

		retSong = correctDivisions(retSong);

		var columns:Int = retSong.columns.length;
		for (i in 0...retSong.columns.length)
		{
			if (retSong.columns[i].singer == null)
				retSong.columns[i].singer = retSong.columns[i].division;
			if (retSong.columns[i].anim == null)
				retSong.columns[i].anim = defaultSingAnimations[i % defaultSingAnimations.length];
			if (retSong.columns[i].missAnim == null)
				retSong.columns[i].missAnim = retSong.columns[i].anim + "miss";
		}

		if (retSong.bpmMap == null || retSong.bpmMap.length == 0)
		{
			retSong.bpmMap = [[0, retSong.bpm]];
			var totalSteps:Int = 0;

			for (i in 0...retSong.notes.length)
			{
				if (retSong.notes[i].changeBPM)
				{
					if (i > 0)
						retSong.bpmMap.push([totalSteps / 4.0, retSong.notes[i].bpm]);
					else
						retSong.bpmMap[0][1] = retSong.notes[i].bpm;
				}

				if (retSong.notes[i].lengthInSteps == null)
					totalSteps += 16;
				else
					totalSteps += retSong.notes[i].lengthInSteps;
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
					if (retSong.notes[c].beatMultiplier != null)
						retSong.notes[i].beatMultiplier = retSong.notes[c].beatMultiplier;
					Reflect.deleteField(retSong.notes[i], "copyLast");
				}
			}
		}

		retSong = timeSections(retSong);
		if (retSong.useBeats)
			retSong = convertBeats(retSong, songTimingStruct);

		if (retSong.preview.length < 2)
		{
			var i:Int = 0;
			var steps:Float = 0;
			for (s in retSong.notes)
			{
				if (s.sectionNotes.length > 0)
					break;
				i++;
				if (s.lengthInSteps != null)
					steps += s.lengthInSteps;
				else
					steps += 16;
			}

			retSong.preview[0] = steps / 4;
			retSong.preview[1] = retSong.preview[0] + 32;
		}

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
			if (s.defaultNotetypes == null)
			{
				s.defaultNotetypes = [];

				var uniqueDivisions:Array<Int> = [];
				for (i in retSong.columns)
				{
					if (!uniqueDivisions.contains(i.division))
						uniqueDivisions.push(i.division);
				}

				for (i in 0...uniqueDivisions.length)
					s.defaultNotetypes.push("");

				if (s.defaultNoteP1 != null)
					s.defaultNotetypes[0] = s.defaultNoteP1;

				if (s.defaultNoteP2 != null && s.defaultNotetypes.length > 1)
					s.defaultNotetypes[1] = s.defaultNoteP2;
			}

			if (s.altAnim)
			{
				if (s.defaultNotetypes.length > 1 && s.defaultNotetypes[1] == "")
					s.defaultNotetypes[1] = "altAnimation";
			}

			if (retSong.allNotetypes != null)
			{
				for (i in 0...s.defaultNotetypes.length)
				{
					if (Std.isOfType(s.defaultNotetypes[i], Int))
						s.defaultNotetypes[i] = retSong.allNotetypes[Std.int(s.defaultNotetypes[i] - 1)];
				}
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

				if (n[1] < 0 || (n[1] >= retSong.columns.length && deleteOutsideNotes))
					poppers.push(n);

				if (!poppers.contains(n))
				{
					if (quickNotes.length > n[1])
					{
						if (quickNotes[n[1]].filter(function(quickNote:Float) { return Math.abs(quickNote - n[0]) < 15; }).length > 0)
							poppers.push(n);
					}
				}

				if (!poppers.contains(n))
				{
					if (quickNotes.length <= n[1])
					{
						while (quickNotes.length <= n[1])
							quickNotes.push([]);
					}
					quickNotes[n[1]].push(n[0]);
				}
			}
			for (p in poppers)
				s.sectionNotes.remove(p);
		}

		retSong = cleanNotes(retSong, songTimingStruct);

		return retSong;
	}

	public static function correctDivisions(data:SongData):SongData
	{
		if (data.columns == null)
		{
			data.columns = [];
			if (data.columnDivisions == null)
			{
				var columns:Int = 8;
				while (data.columns.length < columns)
				{
					if (data.columns.length >= columns / 2)
						data.columns.push({division: 0, singer: 0});
					else
						data.columns.push({division: 1, singer: 1});
				}
			}
			else
			{
				for (i in 0...data.columnDivisions.length)
				{
					var c:SongColumnData = {division: data.columnDivisions[i]};
					if (data.singerColumns != null && data.singerColumns.length > i)
						c.singer = data.singerColumns[i];
					data.columns.push(c);
				}
			}
		}

		if (data.columnDivisionNames == null)
			data.columnDivisionNames = ["#freeplay.sandbox.side.0", "#freeplay.sandbox.side.1"];

		var uniqueDivisions:Array<Int> = [];
		for (i in data.columns)
		{
			if (!uniqueDivisions.contains(i.division))
				uniqueDivisions.push(i.division);
		}

		if (data.columnDivisionNames.length < uniqueDivisions.length)
		{
			while (data.columnDivisionNames.length < uniqueDivisions.length)
				data.columnDivisionNames.push("Singer " + Std.string(data.columnDivisionNames.length + 1));
		}
		if (data.columnDivisionNames.length > uniqueDivisions.length)
			data.columnDivisionNames.resize(uniqueDivisions.length);

		if (data.ratings == null)
			data.ratings = [];
		if (data.ratings.length < uniqueDivisions.length)
		{
			while (data.ratings.length < uniqueDivisions.length)
				data.ratings.push(0);
		}

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
					var newEvent:EventData = Cloner.clone(eventData[Std.int(e[1])]);
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
			var beatMultiplier:Int = 1;
			if (s.beatMultiplier != null)
				beatMultiplier = s.beatMultiplier;
			for (n in s.sectionNotes)
			{
				if (n.length < 3)
					n[2] = 0;
				n[2] = timing.timeFromBeat((s.firstStep / 4.0) + (n[0] / beatMultiplier) + (n[2] / beatMultiplier)) - timing.timeFromBeat((s.firstStep / 4.0) + (n[0] / beatMultiplier));
				n[0] = timing.timeFromBeat((s.firstStep / 4.0) + (n[0]) / beatMultiplier);
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
						if (note[1] % chart.columns.length >= chart.columns.length / 2)
							note[1] -= chart.columns.length / 2;
						else
							note[1] += chart.columns.length / 2;
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
		for (i in 0...chart.columns.length)
		{
			if (chart.columns[i].division == chartSide)
				validColumns.push(i);
		}
		var numKeys:Int = validColumns.length;

		for (s in chart.notes)
		{
			if (s.defaultNotetypes != null)
			{
				for (t in s.defaultNotetypes)
				{
					if (t != "" && !types.contains(t))
					{
						types.push(t);
						if (Paths.jsonExists("notetypes/" + t))
						{
							var typeData:NoteTypeData = cast Paths.json("notetypes/" + t);
							if (typeData.p1ShouldMiss)
								mineTypes.push(t);
						}
					}
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
					if (column >= Std.int(chart.columns.length / 2))
						column -= Std.int(chart.columns.length / 2);
					else
						column += Std.int(chart.columns.length / 2);
				}

				var type:String = "";
				if (types.length > 1)
				{
					if (n.length > 3)
						type = n[3];
					if (type == "")
					{
						if (s.defaultNotetypes != null)
						{
							if (s.defaultNotetypes[chart.columns[column].division] != "")
								type = s.defaultNotetypes[chart.columns[column].division];
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

		return (numKeys == 4 ? "" : Lang.get("#freeplay.songInfo.numKeys", [Std.string(numKeys)]) + "\n")
		+ Lang.get("#freeplay.songInfo.length", [FlxStringUtil.formatTime((songLength - songStart) / 1000.0)]) + "\n"
		+ Lang.get("#freeplay.songInfo.notes", [Std.string(noteCombos[0])]) + "\n"
		+ (noteCombos[1] > 0 ? Lang.get("#freeplay.songInfo.noteCombos.1", [Std.string(noteCombos[1])]) + "\n" : "")
		+ (noteCombos[2] > 0 ? Lang.get("#freeplay.songInfo.noteCombos.2", [Std.string(noteCombos[2])]) + "\n" : "")
		+ (noteCombos[3] > 0 ? Lang.get("#freeplay.songInfo.noteCombos.3", [Std.string(noteCombos[3])]) + "\n" : "")
		+ Lang.get("#freeplay.songInfo.sustains", [Std.string(holds)]) + "\n"
		+ (rolls > 0 ? Lang.get("#freeplay.songInfo.rolls", [Std.string(rolls)]) + "\n" : "")
		+ (mines > 0 ? Lang.get("#freeplay.songInfo.mines", [Std.string(mines)]) + "\n" : "");
	}

	public static function calcChartRatings(song:SongData, notes:Array<Array<Dynamic>>):Array<Int>
	{
		var ret:Array<Int> = [];
		var divisions:Array<Array<Int>> = [];

		for (d in song.columns)
		{
			while (divisions.length <= d.division)
				divisions.push([]);
			divisions[d.division].push(song.columns.indexOf(d));
		}

		var i:Int = 0;
		for (division in divisions)
		{
			var start:Float = -1;
			var end:Float = -1;

			for (n in notes)
			{
				if ((start == -1 || n[0] < start) && division.contains(n[1]))
					start = n[0];

				if ((end == -1 || n[0] > end) && division.contains(n[1]))
					end = n[0];
			}

			if (start > -1 && end > -1)
			{
				var npsList:Array<Float> = [];
				var ind:Float = start;
				var sustain:Float = 1;
				var lastVal:Float = 0;
				while (ind < end)
				{
					var nList:Array<Int> = [];
					var leftHand:Array<Int> = [];
					var rightHand:Array<Int> = [];
					for (n in notes)
					{
						if (n[0] >= ind && n[0] < ind + 1000 && division.contains(n[1]))
						{
							nList.push(1);
							if (division.indexOf(n[1]) >= Math.floor(division.length / 2))
								rightHand.push(1);
							else
								leftHand.push(1);
						}
					}
					var handBias:Float = 0;
					if (nList.length > 0)
					{
						var handMin:Float = Math.min(leftHand.length, rightHand.length);
						var handMax:Float = Math.max(leftHand.length, rightHand.length);
						handBias = handMin / handMax;
						handBias = 1 - handBias;
					}
					if (lastVal > 0 && nList.length >= lastVal - 2)
						sustain *= 1.025;
					else
						sustain = 1;
					lastVal = nList.length;
					npsList.push(nList.length * sustain * ((handBias / 2) + 1));
					ind += 1000;
				}

				var npsMin:Float = -1;
				var npsMax:Float = -1;
				for (n in npsList)
				{
					if (n > 0)
					{
						if (npsMin == -1 || n < npsMin)
							npsMin = n;
						if (npsMax == -1 || n > npsMax)
							npsMax = n;
					}
				}

				var diff:Float = 0;
				var div:Float = 0;
				for (n in npsList)
				{
					if (n > 0)
						div++;
					diff += biasEquation(n, npsMin, npsMax);
				}
				if (div > 0)
				{
					diff /= div;
					diff = Math.round(diff);
				}

				ret.push(Std.int(diff));
			}
			else
				ret.push(0);
			i++;
		}

		return ret;
	}

	static function biasEquation(val:Float, min:Float, max:Float):Float
	{
		var ret:Float = ((val - min) / (max - min));
		ret = 1 - ((1 - ret) * (1 - ret));
		return (ret * (max - min)) + min;
	}
}