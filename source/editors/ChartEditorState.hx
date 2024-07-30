package editors;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import flixel.math.FlxRect;
import flixel.input.keyboard.FlxKey;
import helpers.DeepEquals;
import helpers.Cloner;
import flixel.system.FlxSound;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import haxe.ds.ArraySort;
import lime.app.Application;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import menus.EditorMenuState;
import data.ObjectData;
import data.Options;
import data.SMFile;
import data.Song;
import data.TimingStruct;
import data.Noteskins;
import game.PlayState;
import objects.AnimatedSprite;
import objects.Character;
import objects.HealthIcon;
import objects.Note;
import objects.StrumNote;
import scripting.HscriptHandler;
import helpers.Waveform;

import newui.UIControl;
import newui.InfoBox;
import newui.TopMenu;
import newui.TabMenu;
import newui.Button;
import newui.Label;
import newui.InputText;
import newui.Checkbox;
import newui.Stepper;
import newui.Draggable;
import newui.DropdownMenu;
import newui.PopupWindow;

using StringTools;

class EditorSustainNote extends FlxSprite
{
	public var strumTime:Float = 0;
	public var sustainLength:Float = 0;
	public var beat:Float = 0;
	public var endBeat:Float = 0;
	public var column:Int = 0;
	public var strumColumn:Int = 0;
	public var noteType(default, set):String;
	public var noteskinType:String = "default";

	public var noteDraw:SustainNote;
	public var drawScale:Float = 1;

	override public function new(strumTime:Float, column:Int, sustainLength:Float, ?noteType:String = "", ?noteskinType:String = "default")
	{
		super();
		this.strumTime = strumTime;
		this.column = column;
		this.sustainLength = sustainLength;
		beat = Conductor.beatFromTime(strumTime);
		endBeat = Conductor.beatFromTime(strumTime + sustainLength);
		this.noteskinType = noteskinType;
		noteDraw = new SustainNote(strumTime, column, sustainLength, 1, "", noteskinType);
		drawScale = ChartEditorState.NOTE_SIZE / (noteDraw.noteskinData.noteSize / noteDraw.noteskinData.scale);
		this.noteType = noteType;
	}

	public function refreshVars(strumTime:Float, column:Int, sustainLength:Float):Bool
	{
		var ret:Bool = false;
		if (this.strumTime == 0 && this.column == 0)		// Since these are the default values, they have to be hardcoded to always update a note that has them
			ret = true;

		if (this.strumTime != strumTime)
		{
			this.strumTime = strumTime;
			ret = true;
		}

		if (this.column != column)
		{
			this.column = column;
			ret = true;
		}

		if (this.sustainLength != sustainLength)
		{
			this.sustainLength = sustainLength;
			ret = true;
		}

		if (ret)
		{
			beat = Conductor.beatFromTime(strumTime);
			endBeat = Conductor.beatFromTime(strumTime + sustainLength);
		}
		return ret;
	}

	public function refreshPosition(?zoom:Float = 1, ?downscroll:Bool = false)
	{
		var noteHeight:Int = Std.int((Conductor.stepFromTime(strumTime + sustainLength) - Conductor.stepFromTime(strumTime)) * ChartEditorState.NOTE_SIZE * zoom);
		if (noteHeight < 1)
		{
			noteHeight = 1;
			visible = false;
		}
		else
		{
			visible = true;
			x = Std.int((FlxG.width / 2) - (ChartEditorState.NOTE_SIZE * ChartEditorState.numColumns / 2) + (ChartEditorState.NOTE_SIZE * column) + (ChartEditorState.NOTE_SIZE / 2));
			y = Std.int(ChartEditorState.NOTE_SIZE * zoom * Conductor.stepFromTime(strumTime));
			if (downscroll)
			{
				y = -y;
				y -= noteHeight;
			}

			noteDraw.strumTime = strumTime;
			noteDraw.beat = beat;
			noteDraw.column = column;
			noteDraw.strumColumn = strumColumn;
			noteDraw.sustainLength = sustainLength;
			noteDraw.onNotetypeChanged(noteskinType);
			if (noteDraw.noteskinData.noteSize != null)
				drawScale = ChartEditorState.NOTE_SIZE / (noteDraw.noteskinData.noteSize / noteDraw.noteskinData.scale);
			noteDraw.actualHeight = noteHeight * (noteDraw.noteskinData.scale * StrumNote.noteScale) / drawScale;
			noteDraw.rebuildSustain();
			noteDraw.scale.set(drawScale, noteHeight / noteDraw.frameHeight);
			noteDraw.updateHitbox();
			noteDraw.flipX = downscroll;
			noteDraw.flipY = downscroll;
		}
	}

	override public function draw()
	{
		if (visible)
		{
			noteDraw.x = x - (noteDraw.width / 2);
			noteDraw.y = y;
			noteDraw.alpha = noteDraw.alph;
			noteDraw.cameras = cameras;
			noteDraw.draw();
		}
	}

	public function set_noteType(val:String):String
	{
		if (noteDraw.noteType != val)
		{
			noteDraw.noteType = val;
			noteDraw.updateTypeData();
		}
		return noteType = val;
	}
}

class NoteSelection extends FlxSprite
{
	public var strumTime:Float;
	public var beat:Float;
	public var column:Int;

	override public function new(note:Note)
	{
		super();

		this.strumTime = note.strumTime;
		this.beat = note.beat;
		this.column = note.column;
		alpha = 0.4;
		makeGraphic(ChartEditorState.NOTE_SIZE, ChartEditorState.NOTE_SIZE, FlxColor.GRAY);
	}

	public function refreshPosition(?zoom:Float = 1, ?downscroll:Bool = false):NoteSelection
	{
		x = Std.int((FlxG.width / 2) - (ChartEditorState.NOTE_SIZE * ChartEditorState.numColumns / 2) + (ChartEditorState.NOTE_SIZE * column));
		y = Std.int(ChartEditorState.NOTE_SIZE * zoom * Conductor.stepFromTime(strumTime));
		if (downscroll)
			y = -y;
		y -= height / 2;

		return this;
	}
}

class ChartEditorNoteMinimap extends FlxSpriteGroup
{
	var borderSize:Int = 35;
	var quantization:Array<Dynamic> = [
		[4, FlxColor.RED],
		[8, FlxColor.BLUE],
		[12, FlxColor.PURPLE],
		[16, FlxColor.YELLOW],
		[24, 0xFFFF80E0],
		[32, FlxColor.ORANGE],
		[48, FlxColor.CYAN],
		[64, FlxColor.LIME]
	];

	var bg:FlxSprite;
	var minimap:FlxSprite;
	var strumline:FlxSprite;
	public var hovered:Bool = false;

	override public function new()
	{
		super(FlxG.width - 36, 0);
		antialiasing = false;

		bg = new FlxSprite(0, borderSize - 1).makeGraphic(32, FlxG.height - ((borderSize - 1) * 2), FlxColor.WHITE);
		bg.antialiasing = false;
		bg.active = false;
		add(bg);

		minimap = new FlxSprite(1);
		minimap.antialiasing = false;
		minimap.active = false;
		add(minimap);

		strumline = new FlxSprite(1).makeGraphic(30, 6, FlxColor.ORANGE);
		strumline.alpha = 0.6;
		strumline.antialiasing = false;
		strumline.active = false;
		add(strumline);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var editor:ChartEditorState = cast FlxG.state;

		if (minimap.height > FlxG.height - (borderSize * 2))
		{
			if (editor.downscroll)
			{
				minimap.y = -Math.round((1 - (Conductor.songPosition / editor.tracks[0].length)) * (minimap.height - (FlxG.height - (borderSize * 2)))) + borderSize;
				var minimapY = -Math.round((Conductor.songPosition / editor.tracks[0].length) * (minimap.height - (FlxG.height - (borderSize * 2)))) + borderSize;
				minimap.clipRect = new FlxRect(0, -minimapY + borderSize, minimap.width, FlxG.height - (borderSize * 2));
			}
			else
			{
				minimap.y = -Math.round((Conductor.songPosition / editor.tracks[0].length) * (minimap.height - (FlxG.height - (borderSize * 2)))) + borderSize;
				minimap.clipRect = new FlxRect(0, -minimap.y + borderSize, minimap.width, FlxG.height - (borderSize * 2));
			}
		}
		else
			minimap.y = borderSize;

		strumline.y = borderSize + Math.round((Conductor.songPosition / editor.tracks[0].length) * ((FlxG.height - (borderSize * 2)) - strumline.height));
		if (editor.downscroll)
			strumline.y = FlxG.height - strumline.height - strumline.y;

		if (FlxG.mouse.justMoved)
		{
			if (UIControl.mouseOver(bg))
			{
				if (!hovered)
					hovered = true;
			}
			else if (hovered && !Options.mousePressed())
				hovered = false;
		}

		if (hovered)
		{
			UIControl.cursor = MouseCursor.BUTTON;
			if (Options.mousePressed())
			{
				if (editor.downscroll)
					editor.songProgress = Conductor.stepFromTime((Math.max(0, Math.min(FlxG.height - (borderSize * 2), (FlxG.height - borderSize) - FlxG.mouse.y)) / (FlxG.height - (borderSize * 2))) * editor.tracks[0].length);
				else
					editor.songProgress = Conductor.stepFromTime((Math.max(0, Math.min(FlxG.height - (borderSize * 2), FlxG.mouse.y - borderSize)) / (FlxG.height - (borderSize * 2))) * editor.tracks[0].length);
				editor.snapSongProgress();
				editor.correctTrackPositions();
			}
		}
	}

	public function refresh()
	{
		var editor:ChartEditorState = cast FlxG.state;

		minimap.makeGraphic(30, Std.int(Math.max(FlxG.height - 50, Conductor.stepFromTime(editor.tracks[0].length) / 2.5)), FlxColor.BLACK);
		FlxSpriteUtil.drawRect(minimap, 0, 0, 30, Std.int(minimap.height), FlxColor.BLACK);

		var columns:Array<Int> = [];

		for (i in 0...editor.songData.columns.length + 1)
			columns.push(3 + Std.int(i / editor.songData.columns.length * 24));

		for (n in editor.noteData)
		{
			if (n.length > 2 && n[2] > 0)
			{
				var pos:Int = Std.int(Math.round((n[0] / editor.tracks[0].length) * minimap.height));
				var size:Int = Std.int(Math.max(1, Math.round((n[2] / editor.tracks[0].length) * minimap.height)));
				var column:Int = Std.int(n[1]);

				if (pos >= 0 && pos < height)
					FlxSpriteUtil.drawRect(minimap, columns[column], pos, Std.int(Math.max(1, columns[column+1] - columns[column])), size, FlxColor.GREEN);
			}
		}

		for (n in editor.noteData)
		{
			var pos:Int = Std.int(Math.round((n[0] / editor.tracks[0].length) * minimap.height));
			var column:Int = Std.int(n[1]);

			var noteColor:FlxColor = FlxColor.WHITE;
			var beatRow:Float = Math.round(Conductor.beatFromTime(n[0]) * 48);
			for (q in quantization)
			{
				if (beatRow % (192 / q[0]) == 0)
				{
					noteColor = q[1];
					break;
				}
			}

			if (pos >= 0 && pos < height)
				FlxSpriteUtil.drawRect(minimap, columns[column], pos, Std.int(Math.max(1, columns[column+1] - columns[column])), 1, noteColor);
		}

		minimap.flipY = editor.downscroll;
	}
}

class ChartEditorState extends MusicBeatState
{
	public static var NOTE_SIZE:Int = 240;
	public static var numColumns:Int = 8;
	public var downscroll:Bool = false;

	public static var isNew:Bool = false;
	public static var songId:String = "";
	public static var songIdShort:String = "";
	public static var songFile:String = "";
	public var songFileShortened:String = "";

	public var songData:SongData;
	var isSM:Bool = false;
	var smData:SMFile = null;
	public var noteData:Array<Array<Dynamic>> = [];

	var dataLog1:Array<SongData> = [];
	var dataLog2:Array<Array<Array<Dynamic>>> = [];
	var unsaved:Bool = false;
	var undoPosition:Int = 0;
	var pauseUndo:Bool = false;

	public var camFollow:FlxObject;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var mousePos:FlxObject;

	public static var filename:String = "";
	var filenameText:String = "";

	public var tracks:Array<FlxSound> = [];
	var trackList:Array<String> = [];
	var playbackRate:Float = 1;
	public var songProgress:Float = 0;
	var prevSongProgress:Float = 0;
	var curSection:Int = 0;
	var prevSection:Int = 0;

	var zoom:Float = 1;
	var snap:Int = 16;
	var timeSinceLastAutosave:Float = 0;
	var autosavePaused:Bool = false;

	var beatLines:FlxSpriteGroup;
	var waveform:FlxSpriteGroup;
	var waveformVisible:Bool = false;
	var waveformTrack:Array<Int> = [0];
	var sectionLines:FlxSpriteGroup;
	var sectionIcons:FlxTypedSpriteGroup<HealthIcon>;
	var songEndLine:FlxSprite = null;
	var strums:FlxSpriteGroup;
	var addStrumButton:FlxSprite;
	var makingSustains:FlxTypedSpriteGroup<EditorSustainNote>;
	var sustains:FlxTypedSpriteGroup<EditorSustainNote>;
	var notes:FlxTypedSpriteGroup<Note>;
	var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;
	var ghostNote:Note;
	var ghostNotes:FlxTypedSpriteGroup<Note>;
	var sustainWidget:FlxSprite;
	var sustainWidgetNote:Int = -1;
	var sustainWidgetAdjusting:Bool = false;
	var sustainWidgetLimit:Float = -1;
	var bpmLines:FlxSpriteGroup;
	var eventLines:FlxSpriteGroup;
	var eventIcons:FlxSpriteGroup;
	var eventTimeLine:FlxSprite;
	var ghostEvent:AnimatedSprite;
	var curStrum:Int = -1;
	var uniqueDivisions:Array<Int> = [];
	var strumColumns:Array<Int> = [];
	var curEvent(default, set):Int = -1;

	var makingNotes:Array<Float> = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
	var makingNoteMouse:Array<Float> = [-1, -1];
	static var allowMakingNoteMouse:Bool = true;
	var notePlaceSound:String = "ui/editors/charting/noteLay";
	var notePlaceAllowSustains:Bool = true;
	var allowEditingStrumline:Bool = false;

	var hoverText(default, set):String = "";
	var hoverTextDisplay:FlxSpriteGroup;
	var hoverTextBG:FlxSprite;
	var hoverTextObject:FlxText;

	var cellX:Int = 0;
	var cellY:Int = 0;
	var selectedNotes:Array<Note> = [];
	var selecting:Bool = false;
	var suspendSelection:Bool = false;
	var movingSelection:Bool = false;
	var cellsX:Int = 0;
	var cellsY:Int = 0;
	var selectionPos:Array<Int> = [0, 0];
	var selectionBox:FlxSprite;
	var selNoteBoxes:FlxTypedSpriteGroup<NoteSelection>;
	var noteClipboard:Array<Array<Dynamic>> = [];

	var noteMinimap:ChartEditorNoteMinimap;

	var infoBox:InfoBox;

	var timeBox:Draggable;
	var timeText:FlxText;

	var tabMenu:TabMenu;
	var suspendControls:Bool = false;

	var beatTickEnabled:Bool = false;
	var beatTickVolume:Float = 0.5;
	var beatTickBarLength:Int = 4;

	var noteTickEnabled:Bool = false;
	var noteTickVolume:Float = 0.5;
	var noteTick:Int = -1;
	var noteTickFilter:Array<String> = [];
	var noteTicks:Array<Array<Dynamic>> = [];

	var characterFileList:Array<String> = [];
	var characterNames:Map<String, String>;
	var stageNames:Map<String, String>;

	var sectionTab:VBoxScrollable;
	var sectionCamOnStepper:Stepper = null;
	var sectionLengthStepper:Stepper;
	var copyLastStepper:Stepper;
	var maintainSidesCheckbox:Checkbox;
	var defaultNotetypesVbox:VBox;

	var noteTypeInput:InputText;
	var replaceTypeDropdown:DropdownMenu;
	var allCamsOnStepper:Stepper = null;

	var eventTypeNames:Map<String, String> = new Map<String, String>();
	var eventParamNames:Map<String, String> = new Map<String, String>();
	var eventTypeParams:Map<String, EventTypeData> = new Map<String, EventTypeData>();

	var eventsTab:VBoxScrollable;
	var curEventText:Label;
	var eventTypeDropdown:DropdownMenu;
	var addEventButton:TextButton;
	var eventPropertiesText:Label;
	public var eventParamList:Dynamic;
	var eventParams:Array<FlxSprite> = [];

	var topmenu:TopMenu;
	var testChartSide:Int = 0;

	override public function create()
	{
		if (!FileSystem.exists("autosaves"))
			FileSystem.createDirectory("autosaves");
		timeSinceLastAutosave = 0;
		downscroll = Options.options.downscroll;
		SustainNote.noteGraphics.clear();

		camGame = new FlxCamera();
		FlxG.cameras.add(camGame);

		camFollow = new FlxObject();
		camFollow.screenCenter();
		camGame.follow(camFollow, LOCKON, 1);

		camHUD = new FlxCamera();
		camHUD.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camHUD, false);

		mousePos = new FlxObject();

		super.create();

		var bg:FlxSprite = new FlxSprite(Paths.image('ui/menuDesat'));
		bg.color = 0x202020;
		bg.scrollFactor.set();
		add(bg);

		songIdShort = songId.substring(songId.lastIndexOf("/")+1, songId.length);
		if (PlayState.testingChart)
		{
			songData = Song.copy(PlayState.testingChartData);
			PlayState.testingChartData = null;
		}
		else if (isNew)
		{
			songData =
			{
				song: songIdShort,
				artist: "",
				charter: "",
				preview: [0, 32],
				ratings: [0, 0],
				useBeats: true,
				bpmMap: [[0, 150]],
				scrollSpeeds: [[0, 1]],
				altSpeedCalc: true,
				player1: TitleState.defaultVariables.player1,
				player2: TitleState.defaultVariables.player2,
				player3: TitleState.defaultVariables.gf,
				stage: TitleState.defaultVariables.stage,
				tracks: [["Inst", 0, 0]],
				notes: [{camOn: 1, lengthInSteps: 16, defaultNotetypes: ["", ""], sectionNotes: []}],
				eventFile: "_events",
				events: [],
				music: { pause: "", gameOver: "", gameOverEnd: "", results: "" }
			}
			if (Paths.songExists(songId, "Voices"))
				songData.tracks.push(["Voices", 1, 0]);
			else if (Paths.songExists(songId, "Voices-" + songData.player1))
				songData.tracks.push(["Voices-" + songData.player1, 2, 0]);
			songData = Song.parseSongData(songData);
			songFileShortened = songId;
		}
		else if (Paths.smExists(songId))
		{
			smData = SMFile.load(songId);
			songData = smData.songData[0];
			isSM = true;
		}
		else
		{
			songData = Song.loadSongDirect("songs/" + songFile, false);
			var songArray:Array<String> = songFile.split('/');
			songFileShortened = songArray[songArray.length - 1];
		}

		numColumns = songData.columns.length;
		NOTE_SIZE = Std.int(480 / numColumns);
		if (NOTE_SIZE > 60)
			NOTE_SIZE = 60;
		Conductor.recalculateTimings(songData.bpmMap);

		for (s in songData.notes)
		{
			for (n in s.sectionNotes)
			{
				var newN:Array<Dynamic> = n.copy();
				noteData.push(newN);
			}
			s.sectionNotes = [];
		}

		Conductor.overrideSongPosition = true;
		if (PlayState.testingChart)
		{
			PlayState.testingChart = false;
			songProgress = Conductor.stepFromTime(PlayState.testingChartPos + songData.offset);
			testChartSide = PlayState.testingChartSide;
		}

		updateReplaceTypeList();

		beatLines = new FlxSpriteGroup();
		add(beatLines);

		waveform = new FlxSpriteGroup();
		add(waveform);

		sectionLines = new FlxSpriteGroup();
		add(sectionLines);

		sectionIcons = new FlxTypedSpriteGroup<HealthIcon>();
		add(sectionIcons);

		strums = new FlxSpriteGroup();
		strums.scrollFactor.set();
		add(strums);

		ghostNote = new Note(0, 0, "", songData.noteType[0]);
		ghostNote.setGraphicSize(NOTE_SIZE);
		ghostNote.updateHitbox();
		ghostNote.alpha = 0.5;
		ghostNote.visible = false;
		add(ghostNote);

		makingSustains = new FlxTypedSpriteGroup<EditorSustainNote>();
		add(makingSustains);
		refreshMakingSustains();

		sustains = new FlxTypedSpriteGroup<EditorSustainNote>();
		add(sustains);

		sustainWidget = new FlxSprite(Paths.image("ui/editors/sustainWidget"));
		sustainWidget.setGraphicSize(NOTE_SIZE);
		sustainWidget.updateHitbox();
		sustainWidget.alpha = 0.5;
		sustainWidget.visible = false;
		add(sustainWidget);

		notes = new FlxTypedSpriteGroup<Note>();
		add(notes);

		noteSplashes = new FlxTypedSpriteGroup<NoteSplash>();
		add(noteSplashes);

		ghostNotes = new FlxTypedSpriteGroup<Note>();
		add(ghostNotes);

		selNoteBoxes = new FlxTypedSpriteGroup<NoteSelection>();
		add(selNoteBoxes);

		bpmLines = new FlxSpriteGroup();
		add(bpmLines);

		eventLines = new FlxSpriteGroup();
		add(eventLines);

		eventIcons = new FlxSpriteGroup();
		add(eventIcons);

		ghostEvent = new AnimatedSprite(Paths.tiles("ui/editors/eventIcon", 1, 3));
		ghostEvent.alpha = 0.5;
		ghostEvent.visible = false;
		add(ghostEvent);

		var xx:Int = Std.int( (FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) );
		var ww:Int = Std.int(NOTE_SIZE * numColumns);

		songEndLine = new FlxSprite(xx, 0).makeGraphic(ww, 2, FlxColor.RED);
		add(songEndLine);

		eventTimeLine = new FlxSprite(xx, 0).makeGraphic(ww, 1, FlxColor.YELLOW);
		eventTimeLine.visible = false;
		add(eventTimeLine);

		selectionBox = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		selectionBox.alpha = 0.6;
		selectionBox.visible = false;
		add(selectionBox);

		var key:String = "ChartEditor_AddStrumButton";
		if (FlxG.bitmap.get(key) == null)
		{
			var img:BitmapData = new BitmapData(60, 60, true, FlxColor.TRANSPARENT);
			img.fillRect(new Rectangle(25, 10, 10, 40), FlxColor.WHITE);
			img.fillRect(new Rectangle(10, 25, 40, 10), FlxColor.WHITE);
			FlxGraphic.fromBitmapData(img, false, key);
		}
		addStrumButton = new FlxSprite(0, 0, FlxG.bitmap.get(key));

		if (!isSM)
		{
			trackList = Paths.listFiles("songs/" + songId + "/", ".ogg");
			trackList = trackList.concat(Paths.listFiles("data/songs/" + songId + "/", ".ogg"));
			if (trackList.length <= 0)
			{
				var newTrack:FlxSound = new FlxSound().loadEmbedded(Paths.song("test", "Inst"));		// This is just to prevent a crash
				FlxG.sound.list.add(newTrack);
				tracks.push(newTrack);

				new Notify("The chart has no associated music files.\nCheck the folder \"songs/"+songId+"\" or \"data/songs/"+songId+"\" or create it if it doesn't exist.", function() { FlxG.switchState(new EditorMenuState()); });
			}
		}

		noteMinimap = new ChartEditorNoteMinimap();
		noteMinimap.cameras = [camHUD];
		add(noteMinimap);

		var eventTypeList:Array<String> = Paths.listFilesSub("data/events/", ".json");
		for (f in Paths.listFiles("data/songs/" + songId + "/events/", ".json"))
			eventTypeList.push(songIdShort + "/" + f);

		for (ev in eventTypeList)
		{
			if (ev.startsWith(songIdShort + "/"))
				eventTypeNames[ev] = Util.properCaseString(ev.replace(songIdShort + "/", "songEvent/"));
			else
				eventTypeNames[ev] = Util.properCaseString(ev);

			var thisEventPath:String = "events/" + ev;
			if (ev.startsWith(songIdShort) && !Paths.jsonExists(thisEventPath))
			{
				var newEventName:String = ev.substr(songIdShort.length + 1);
				if (Paths.jsonExists("songs/" + songId + "/events/" + newEventName))
					thisEventPath = "songs/" + songId + "/events/" + newEventName;
			}
			eventTypeParams[ev] = cast Paths.json(thisEventPath);
		}

		refreshTracks();
		refreshUniqueDivisions();
		refreshSectionLines();
		refreshSectionIcons();
		refreshStrums();
		refreshNotes();
		refreshSustains();
		refreshBPMLines();
		refreshEventLines();

		FlxG.sound.cache(Paths.sound("ui/editors/charting/metronome1"));
		FlxG.sound.cache(Paths.sound("ui/editors/charting/metronome2"));
		FlxG.sound.cache(Paths.sound("ui/editors/charting/noteTick"));
		FlxG.sound.cache(Paths.sound("ui/editors/charting/noteLay"));
		FlxG.sound.cache(Paths.sound("ui/editors/charting/noteErase"));
		FlxG.sound.cache(Paths.sound("ui/editors/charting/notePlace"));
		FlxG.sound.cache(Paths.sound("ui/editors/charting/noteStretch"));
		FlxG.sound.cache(Paths.sound("ui/editors/charting/noteShrink"));



		var timeVbox:VBox = new VBox(15, 35);

		timeText = new FlxText(0, 0, 0, "");
		timeText.setFormat("FNF Dialogue", 18, FlxColor.BLACK, LEFT);
		refreshTimeText();
		timeVbox.add(timeText);

		var playbackRateStepper:Stepper = new Stepper(0, 0, "Playback Rate:", 1, 0.05, 0.05, 9999, 2);
		playbackRateStepper.infoText = "How fast or slow the song is played in the editor.";
		playbackRateStepper.onChanged = function() { playbackRate = playbackRateStepper.value; correctTrackPitch(); }
		timeVbox.add(playbackRateStepper);

		timeBox = new Draggable(0, 250, "", 30);
		timeBox.cameras = [camHUD];
		timeBox.back.loadGraphic(PopupWindow.getNineSlice("popupBG", 30, Std.int(timeVbox.width + 80), Std.int(timeVbox.height + 60)));
		timeBox.x = Std.int(FlxG.width - timeBox.width - 40);
		timeBox.add(timeVbox);
		add(timeBox);



		infoBox = new InfoBox(960, 50);
		infoBox.cameras = [camHUD];
		add(infoBox);
		UIControl.infoText = "Hover over an option in the editor panel to see what it does.";



		var ui:UIControl = new UIControl("ChartEditor", [function() { return isSM; }]);

		tabMenu = cast ui.element("tabMenu");
		tabMenu.cameras = [camHUD];
		add(tabMenu);

		refreshFilename();



		var optimizeSectionsButton:TextButton = cast ui.element("optimizeSectionsButton");
		optimizeSectionsButton.onClicked = function() {
			var firstNote:Float = tracks[0].length;
			if (noteData.length > 0)
			{
				for (n in noteData)
				{
					if (n[0] < firstNote)
						firstNote = n[0];
				}
			}
			else
				firstNote = 0;
			var firstSecWithNotes:Int = secFromTime(firstNote);

			var i:Int = 1;
			while (i < songData.notes.length)
			{
				if (i != firstSecWithNotes)
				{
					var curSec:SectionData = songData.notes[i];
					var prevSec:SectionData = songData.notes[i-1];

					if (curSec.camOn == prevSec.camOn && DeepEquals.deepEquals(curSec.defaultNotetypes, prevSec.defaultNotetypes))
					{
						prevSec.lengthInSteps += curSec.lengthInSteps;
						songData.notes.remove(curSec);
						i--;
						firstSecWithNotes--;
					}
				}
				i++;
			}

			if (songData.notes.length > 1 && songData.notes[songData.notes.length-1].lengthInSteps > songData.notes[songData.notes.length-2].lengthInSteps)
			{
				songData.notes.push(Reflect.copy(songData.notes[songData.notes.length-1]));
				songData.notes[songData.notes.length-1].lengthInSteps = songData.notes[songData.notes.length-2].lengthInSteps - songData.notes[songData.notes.length-3].lengthInSteps;
				songData.notes[songData.notes.length-2].lengthInSteps = songData.notes[songData.notes.length-3].lengthInSteps;
			}

			songData = Song.timeSections(songData);
			refreshSectionLines();
			refreshSectionIcons();
		}



		var songNameInput:InputText = cast ui.element("songNameInput");
		songNameInput.condition = function() { return songData.song; }
		songNameInput.focusGained = function() { suspendControls = true; }
		songNameInput.focusLost = function() { songData.song = songNameInput.text; suspendControls = false; }

		var songArtistInput:InputText = cast ui.element("songArtistInput");
		songArtistInput.condition = function() { return songData.artist; }
		songArtistInput.focusGained = function() { suspendControls = true; }
		songArtistInput.focusLost = function() { songData.artist = songArtistInput.text; suspendControls = false; }

		var songCharterInput:InputText = cast ui.element("songCharterInput");
		songCharterInput.condition = function() { return songData.charter; }
		songCharterInput.focusGained = function() { suspendControls = true; }
		songCharterInput.focusLost = function() { songData.charter = songCharterInput.text; suspendControls = false; }

		if (!isSM)
		{
			var tracksButton:TextButton = cast ui.element("tracksButton");
			tracksButton.onClicked = function() {
				var typeList:Array<String> = ["None (Instrumental)", "All"];
				var charCount:Int = 2;
				while (Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
					charCount++;

				for (i in 0...charCount)
				{
					var charName:String = Reflect.field(songData, "player" + Std.string(i + 1));
					if (characterNames.exists(charName))
						charName = characterNames[charName];
					typeList.push("Character " + Std.string(i + 1) + " (" + charName + ")");
				}

				var window:PopupWindow = null;
				var vbox:VBox = new VBox(35, 35);

				var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
				var scroll:VBox = menu.vbox;

				for (i in 0...songData.tracks.length)
				{
					var trackName:String = songData.tracks[i][0];
					var trackHbox:HBox = new HBox();
					trackHbox.add(new Label("Track "+Std.string(i+1)+":"));
					var trackDropdown:DropdownMenu = new DropdownMenu(0, 0, trackName, trackList, true);
					trackHbox.add(trackDropdown);
					scroll.add(trackHbox);

					var typeHbox:HBox = new HBox();
					typeHbox.add(new Label("Singer:"));
					var typeDropdown:DropdownMenu = new DropdownMenu(0, 0, typeList[songData.tracks[i][1]], typeList);
					typeDropdown.onChanged = function() {
						songData.tracks[i][1] = typeDropdown.valueInt;
					};
					typeHbox.add(typeDropdown);
					scroll.add(typeHbox);

					if (i > 0)
					{
						var trackOffsetStepper:Stepper = new Stepper(0, 0, "Offset:", songData.tracks[i][2]);
						trackOffsetStepper.condition = function() { return songData.tracks[i][2]; }
						trackOffsetStepper.onChanged = function() { songData.tracks[i][2] = trackOffsetStepper.value; }
						scroll.add(trackOffsetStepper);
					}

					var volStepper:Stepper = new Stepper(0, 0, "Volume:", tracks[i].volume * 10, 1, 0, 10);
					volStepper.onChanged = function() {
						tracks[i].volume = volStepper.value / 10;
					}
					trackDropdown.onChanged = function() {
						songData.tracks[i][0] = trackDropdown.value;
						tracks[i].loadEmbedded(Paths.song(songId, trackDropdown.value));
						tracks[i].volume = volStepper.value / 10;
					};
					scroll.add(volStepper);
				}

				vbox.add(menu);

				var hbox:HBox = new HBox();

				var _add:TextButton = new TextButton(0, 0, "Add");
				_add.onClicked = function() {
					songData.tracks.push([trackList[0], 0, 0]);
					refreshTracks();
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { tracksButton.onClicked(); });
				}
				hbox.add(_add);

				var _remove:TextButton = new TextButton(0, 0, "Remove");
				_remove.onClicked = function() {
					if (songData.tracks.length > 1)
					{
						songData.tracks.pop();
						refreshTracks();
						window.close();
						new FlxTimer().start(0.01, function(tmr:FlxTimer) { tracksButton.onClicked(); });
					}
				}
				hbox.add(_remove);

				vbox.add(hbox);

				var accept:TextButton = new TextButton(0, 0, "Accept");
				accept.onClicked = function() {
					window.close();
					refreshTracks();
				}
				vbox.add(accept);

				window = PopupWindow.CreateWithGroup(vbox);
			}
		}

		var offsetStepper:Stepper = cast ui.element("offsetStepper");
		offsetStepper.value = songData.offset;
		offsetStepper.condition = function() { return songData.offset; }
		offsetStepper.onChanged = function() {
			songData.offset = offsetStepper.value;
			refreshWaveform();
		}

		var bakeOffsetButton:TextButton = cast ui.element("bakeOffsetButton");
		bakeOffsetButton.onClicked = function () {
			for (note in noteData)
				note[0] -= songData.offset;

			refreshNotes();
			refreshSustains();
			refreshSelectedNotes();
			songData.offset = 0;
			refreshWaveform();
		}

		var useBeatsCheckbox:Checkbox = cast ui.element("useBeatsCheckbox");
		useBeatsCheckbox.checked = songData.useBeats;
		useBeatsCheckbox.condition = function() { return songData.useBeats; }
		useBeatsCheckbox.onClicked = function() { songData.useBeats = useBeatsCheckbox.checked; }

		var charactersButton:TextButton = cast ui.element("charactersButton");
		charactersButton.onClicked = function() {
			var charCount:Int = 2;
			while (Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
				charCount++;

			var window:PopupWindow = null;
			var vbox:VBox = new VBox(35, 35);

			var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
			var scroll:VBox = menu.vbox;

			for (i in 0...charCount)
			{
				var char:String = Reflect.field(songData, "player" + Std.string(i + 1));
				var characterHbox:HBox = new HBox();
				characterHbox.add(new Label("Character " + Std.string(i + 1) + ":"));
				var charDropdown:DropdownMenu = new DropdownMenu(0, 0, "", [""], true);
				charDropdown.valueText = characterNames;
				charDropdown.valueList = characterFileList;
				charDropdown.value = char;
				charDropdown.onChanged = function() {
					Reflect.setField(songData, "player" + Std.string(i+1), charDropdown.value);
				};
				characterHbox.add(charDropdown);
				scroll.add(characterHbox);

				var charNotetypesText:String = "";
				if (songData.notetypeSingers[i].length > 0)
					charNotetypesText = songData.notetypeSingers[i].join(",");

				var charNotetypesHbox:HBox = new HBox();
				charNotetypesHbox.add(new Label("Note Types:"));
				var charNotetypes:InputText = new InputText(0, 0, charNotetypesText);
				charNotetypes.focusLost = function() {
					if (songData.notetypeSingers[i].length > 0)
						charNotetypes.text = songData.notetypeSingers[i].join(",");
					else
						charNotetypes.text = "";
				}
				charNotetypes.callback = function(text:String, action:String) {
					if (text == "")
						songData.notetypeSingers[i] = [];
					else
						songData.notetypeSingers[i] = text.split(",");
				}
				charNotetypesHbox.add(charNotetypes);
				scroll.add(charNotetypesHbox);
			}

			vbox.add(menu);

			var hbox:HBox = new HBox();

			var _add:TextButton = new TextButton(0, 0, "Add");
			_add.onClicked = function() {
				if (!Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
					Reflect.setField(songData, "player" + Std.string(charCount + 1), Reflect.field(songData, "player" + Std.string(charCount)));
				refreshCharacters();
				window.close();
				new FlxTimer().start(0.01, function(tmr:FlxTimer) { charactersButton.onClicked(); });
			}
			hbox.add(_add);

			var _remove:TextButton = new TextButton(0, 0, "Remove");
			_remove.onClicked = function() {
				if (charCount > 2)
				{
					if (Reflect.hasField(songData, "player" + Std.string(charCount)))
						Reflect.deleteField(songData, "player" + Std.string(charCount));
					refreshCharacters();
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { charactersButton.onClicked(); });
				}
			}
			hbox.add(_remove);

			vbox.add(hbox);

			var accept:TextButton = new TextButton(0, 0, "Accept");
			accept.onClicked = function() {
				window.close();
				refreshSectionIcons();
			}
			vbox.add(accept);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		var useMustHitCheckbox:Checkbox = cast ui.element("useMustHitCheckbox");
		useMustHitCheckbox.checked = songData.useMustHit;
		useMustHitCheckbox.condition = function() { return songData.useMustHit; }
		useMustHitCheckbox.onClicked = function() { songData.useMustHit = useMustHitCheckbox.checked; }

		var notetypeOverridesCamCheckbox:Checkbox = cast ui.element("notetypeOverridesCamCheckbox");
		notetypeOverridesCamCheckbox.checked = songData.notetypeOverridesCam;
		notetypeOverridesCamCheckbox.condition = function() { return songData.notetypeOverridesCam; }
		notetypeOverridesCamCheckbox.onClicked = function() { songData.notetypeOverridesCam = notetypeOverridesCamCheckbox.checked; }

		var columnDivisionNamesButton:TextButton = cast ui.element("columnDivisionNamesButton");
		columnDivisionNamesButton.onClicked = function() {
			fixColumnDivisionNames();

			var window:PopupWindow = null;
			var vbox:VBox = new VBox(35, 35);

			var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
			var scroll:VBox = menu.vbox;

			for (i in 0...songData.columnDivisionNames.length)
			{
				var nameHbox:HBox = new HBox();
				nameHbox.add(new Label("Chart Side "+Std.string(i+1)+":"));
				var nameInput:InputText = new InputText(0, 0, songData.columnDivisionNames[i]);
				nameInput.condition = function() { return songData.columnDivisionNames[i]; }
				nameInput.focusLost = function() { songData.columnDivisionNames[i] = nameInput.text; }
				nameHbox.add(nameInput);
				var nameLabel:Label = new Label("");
				nameLabel.text = Lang.get(nameInput.text);
				nameInput.callback = function(text, action) { nameLabel.text = Lang.get(text); }
				nameHbox.add(nameLabel);
				scroll.add(nameHbox);
			}

			vbox.add(menu);

			var accept:TextButton = new TextButton(0, 0, "Accept", function() { window.close(); });
			vbox.add(accept);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		var stageList:Array<String> = Paths.listFilesSub("data/stages/", ".json");
		stageNames = Util.getStageNames(stageList);
		var stageDropdown:DropdownMenu = cast ui.element("stageDropdown");
		stageDropdown.valueText = stageNames;
		stageDropdown.valueList = stageList;
		stageDropdown.value = songData.stage;
		stageDropdown.condition = function() { return songData.stage; }
		stageDropdown.onChanged = function() { songData.stage = stageDropdown.value; };

		var noteskinTypeButton:TextButton = cast ui.element("noteskinTypeButton");
		noteskinTypeButton.onClicked = function() {
			var noteskinTypeList:Array<String> = Paths.listFiles("images/noteskins/Arrows/", ".json");

			var window:PopupWindow = null;
			var vbox:VBox = new VBox(35, 35);

			var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
			var scroll:VBox = menu.vbox;

			for (i in 0...songData.noteType.length)
			{
				var typeHbox:HBox = new HBox();
				typeHbox.add(new Label("Noteskin Type "+Std.string(i+1)+":"));
				var typeDropdown:DropdownMenu = new DropdownMenu(0, 0, songData.noteType[i], noteskinTypeList, true);
				typeDropdown.onChanged = function() { songData.noteType[i] = typeDropdown.value; };
				typeHbox.add(typeDropdown);
				if (songData.noteType.length > 1)
				{
					var _remove:Button = new Button(0, 0, "buttonTrash");
					_remove.onClicked = function() {
						songData.noteType.splice(i, 1);
						window.close();
						new FlxTimer().start(0.01, function(tmr:FlxTimer) { noteskinTypeButton.onClicked(); });
					}
					typeHbox.add(_remove);
				}
				scroll.add(typeHbox);
			}

			vbox.add(menu);

			var _add:TextButton = new TextButton(0, 0, "Add");
			_add.onClicked = function() {
				if (songData.noteType.length < uniqueDivisions.length)
				{
					songData.noteType.push(songData.noteType[songData.noteType.length - 1]);
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { noteskinTypeButton.onClicked(); });
				}
			}
			vbox.add(_add);

			var accept:TextButton = new TextButton(0, 0, "Accept");
			accept.onClicked = function() {
				window.close();
				refreshStrums();
				refreshNotes();
				refreshSustains();
			}
			vbox.add(accept);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		var uiSkinList:Array<String> = Paths.listFiles("images/ui/skins/", ".json");
		var uiSkinDropdown:DropdownMenu = cast ui.element("uiSkinDropdown");
		uiSkinDropdown.valueList = uiSkinList;
		uiSkinDropdown.value = songData.uiSkin;
		uiSkinDropdown.condition = function() { return songData.uiSkin; }
		uiSkinDropdown.onChanged = function() { songData.uiSkin = uiSkinDropdown.value; };

		var skipCountdownCheckbox:Checkbox = cast ui.element("skipCountdownCheckbox");
		skipCountdownCheckbox.checked = songData.skipCountdown;
		skipCountdownCheckbox.condition = function() { return songData.skipCountdown; }
		skipCountdownCheckbox.onClicked = function() { songData.skipCountdown = skipCountdownCheckbox.checked; }

		var eventFileInput:InputText = cast ui.element("eventFileInput");
		eventFileInput.text = songData.eventFile;
		eventFileInput.condition = function() { return songData.eventFile; }
		eventFileInput.focusGained = function() { suspendControls = true; }
		eventFileInput.focusLost = function() { songData.eventFile = eventFileInput.text; suspendControls = false; }

		characterFileList = Paths.listFilesSub("data/characters/", ".json");
		characterNames = Util.getCharacterNames(characterFileList);
		var charCount:Int = 2;
		while (Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
			charCount++;



		var musicList:Array<String> = Paths.listFilesSub("music/", ".ogg");
		musicList.unshift("");

		var pauseDropdown:DropdownMenu = cast ui.element("pauseDropdown");
		pauseDropdown.valueList = musicList;
		pauseDropdown.value = songData.music.pause;
		pauseDropdown.condition = function() {
			if (songData.music.pause == null)
				return "";
			return songData.music.pause;
		}
		pauseDropdown.onChanged = function() { songData.music.pause = pauseDropdown.value; };

		var gameOverDropdown:DropdownMenu = cast ui.element("gameOverDropdown");
		gameOverDropdown.valueList = musicList;
		gameOverDropdown.value = songData.music.gameOver;
		gameOverDropdown.condition = function() {
			if (songData.music.gameOver == null)
				return "";
			return songData.music.gameOver;
		}
		gameOverDropdown.onChanged = function() { songData.music.gameOver = gameOverDropdown.value; };

		var gameOverEndDropdown:DropdownMenu = cast ui.element("gameOverEndDropdown");
		gameOverEndDropdown.valueList = musicList;
		gameOverEndDropdown.value = songData.music.gameOverEnd;
		gameOverEndDropdown.condition = function() {
			if (songData.music.gameOverEnd == null)
				return "";
			return songData.music.gameOverEnd;
		}
		gameOverEndDropdown.onChanged = function() { songData.music.gameOverEnd = gameOverEndDropdown.value; };

		var resultsDropdown:DropdownMenu = cast ui.element("resultsDropdown");
		resultsDropdown.valueList = musicList;
		resultsDropdown.value = songData.music.results;
		resultsDropdown.condition = function() {
			if (songData.music.results == null)
				return "";
			return songData.music.results;
		}
		resultsDropdown.onChanged = function() { songData.music.results = resultsDropdown.value; };



		sectionTab = cast ui.element("sectionTab");

		sectionCamOnStepper = cast ui.element("sectionCamOnStepper");
		sectionCamOnStepper.value = songData.notes[0].camOn + 1;
		sectionCamOnStepper.maxVal = charCount;
		sectionCamOnStepper.condition = function() { return songData.notes[curSection].camOn + 1; }
		sectionCamOnStepper.onChanged = function() {
			var sec:SectionData = songData.notes[curSection];
			sec.camOn = sectionCamOnStepper.valueInt - 1;
			refreshSectionIcons(curSection);
			refreshGhostNotes();
		}

		for (i in 0...3)
		{
			var sectionCamOn:ToggleButton = cast ui.element("sectionCamOn" + Std.string(i));
			sectionCamOn.condition = function() { return songData.notes[curSection].camOn == i; }
			sectionCamOn.onClicked = function() {
				if (i <= sectionCamOnStepper.maxVal)
				{
					var sec:SectionData = songData.notes[curSection];
					sec.camOn = i;
					refreshSectionIcons(curSection);
					refreshGhostNotes();
				}
			}
		}

		sectionLengthStepper = cast ui.element("sectionLengthStepper");
		sectionLengthStepper.value = songData.notes[0].lengthInSteps;
		sectionLengthStepper.condition = function() { return songData.notes[curSection].lengthInSteps; }
		sectionLengthStepper.onChanged = function() {
			var sec:SectionData = songData.notes[curSection];
			sec.lengthInSteps = Std.int(sectionLengthStepper.value);
			songData = Song.timeSections(songData);
			refreshSectionLines();
			refreshSectionIcons();
		}

		var splitSectionButton:TextButton = cast ui.element("splitSectionButton");
		splitSectionButton.onClicked = function () {
			var sec:SectionData = songData.notes[curSection];
			var oldLengthInSteps:Int = sec.lengthInSteps;
			var newLengthInSteps:Int = Std.int(songProgress) - sec.firstStep;
			if (newLengthInSteps > 0)
			{
				var newSec:SectionData = {
					sectionNotes: [],
					lengthInSteps: oldLengthInSteps - newLengthInSteps,
					camOn: sec.camOn
				}
				if (sec.defaultNotetypes != null)
					newSec.defaultNotetypes = sec.defaultNotetypes;

				songData.notes.insert(curSection + 1, newSec);
				sec.lengthInSteps = newLengthInSteps;

				songData = Song.timeSections(songData);
				refreshSectionLines();
				refreshSectionIcons();
			}
		}

		copyLastStepper = cast ui.element("copyLastStepper");
		copyLastStepper.onChanged = refreshGhostNotes;

		for (i in 0...3)
		{
			var copyLastButton:TextButton = cast ui.element("copyLastButton" + Std.string(i));
			copyLastButton.onClicked = function () {
				copyLast(i);
			}
		}

		maintainSidesCheckbox = cast ui.element("maintainSidesCheckbox");
		maintainSidesCheckbox.checked = false;
		maintainSidesCheckbox.onClicked = refreshGhostNotes;

		var swapSectionButton:TextButton = cast ui.element("swapSectionButton");
		swapSectionButton.onClicked = function () {
			for (n in noteData)
			{
				if (timeInSec(n[0], curSection))
				{
					if (n[1] >= numColumns / 2)
						n[1] -= numColumns / 2;
					else
						n[1] += numColumns / 2;
				}
			}

			selectedNotes = [];
			refreshSelectedNotes();
			refreshNotes();
			refreshSustains();
		}

		var flipSectionButton:TextButton = cast ui.element("flipSectionButton");
		flipSectionButton.onClicked = function () {
			var columnDivs:Array<Array<Int>> = [];
			var columnSwaps:Array<Int> = [];
			for (i in 0...songData.columns.length)
			{
				while (columnDivs.length <= songData.columns[i].division)
					columnDivs.push([]);
				columnDivs[songData.columns[i].division].push(i);
			}

			for (c in columnDivs)
				c.reverse();

			for (i in 0...songData.columns.length)
			{
				columnSwaps.push(columnDivs[songData.columns[i].division][0]);
				columnDivs[songData.columns[i].division].shift();
			}

			for (n in noteData)
			{
				if (timeInSec(n[0], curSection))
					n[1] = columnSwaps[Std.int(n[1])];
			}

			selectedNotes = [];
			refreshSelectedNotes();
			refreshNotes();
			refreshSustains();
		}

		for (i in 0...3)
		{
			var clearNotesButton:TextButton = cast ui.element("clearNotesButton" + Std.string(i));
			clearNotesButton.onClicked = function () {
				clearCurrent(i);
				updateReplaceTypeList();
			}
		}

		var deleteSectionButton:TextButton = cast ui.element("deleteSectionButton");
		deleteSectionButton.onClicked = function() {
			if (curSection < songData.notes.length-1)
			{
				var poppers:Array<Array<Dynamic>> = [];
				for (n in noteData)
				{
					if (timeInSec(n[0], curSection))
						poppers.push(n);
					else if (Conductor.stepFromTime(n[0]) >= songData.notes[curSection].lastStep)
						n[0] -= Conductor.timeFromStep(songData.notes[curSection].lastStep) - Conductor.timeFromStep(songData.notes[curSection].firstStep);
				}
				for (p in poppers)
					noteData.remove(p);

				songData.notes.splice(curSection, 1);
				songData = Song.timeSections(songData);

				refreshSectionLines();
				refreshSectionIcons();
				selectedNotes = [];
				refreshSelectedNotes();
				refreshNotes();
				refreshSustains();
			}
		}

		defaultNotetypesVbox = cast ui.element("defaultNotetypesVbox");

		refreshDefaultNoteInputs();



		var ratingList:TextButton = cast ui.element("ratingList");
		ratingList.onClicked = function() {
			if (songData.ratings.length > uniqueDivisions.length)
				songData.ratings.resize(uniqueDivisions.length);

			if (songData.ratings.length < uniqueDivisions.length)
			{
				while (songData.ratings.length < uniqueDivisions.length)
					songData.ratings.push(0);
			}

			var window:PopupWindow = null;
			var vbox:VBox = new VBox(35, 35);

			var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
			var scroll:VBox = menu.vbox;

			for (i in 0...songData.ratings.length)
			{
				var ratingStepperLabel:String = "Side " + Std.string(i) + ":";
				if (i < songData.columnDivisionNames.length)
					ratingStepperLabel = Lang.get(songData.columnDivisionNames[i]);
				if (!ratingStepperLabel.endsWith(":"))
					ratingStepperLabel += ":";
				var ratingStepper:Stepper = new Stepper(0, 0, ratingStepperLabel, songData.ratings[i], 1, 0, 99);
				ratingStepper.condition = function() { return songData.ratings[i]; }
				ratingStepper.onChanged = function() { songData.ratings[i] = ratingStepper.valueInt; }
				scroll.add(ratingStepper);
			}

			vbox.add(menu);

			var calcRatings:TextButton = new TextButton(0, 0, "Calculate Ratings", Button.LONG, function() {
				songData.ratings = Song.calcChartRatings(songData, noteData);
			});
			vbox.add(calcRatings);

			var accept:TextButton = new TextButton(0, 0, "Accept", function() { window.close(); });
			vbox.add(accept);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		var previewStartStepper:Stepper = cast ui.element("previewStartStepper");
		previewStartStepper.condition = function() { return songData.preview[0]; }
		previewStartStepper.onChanged = function() {
			songData.preview[0] = previewStartStepper.value;
			if (songData.preview[1] <= songData.preview[0])
				songData.preview[1] = songData.preview[0] + 1;
		}

		var previewStartZero:TextButton = cast ui.element("previewStartZero");
		previewStartZero.onClicked = function() { previewStartStepper.value = 0; previewStartStepper.onChanged(); }

		var previewStartCurrent:TextButton = cast ui.element("previewStartCurrent");
		previewStartCurrent.onClicked = function() { previewStartStepper.value = songProgress / 4; previewStartStepper.onChanged(); }

		var previewEndStepper:Stepper = cast ui.element("previewEndStepper");
		previewEndStepper.condition = function() { return songData.preview[1]; }
		previewEndStepper.onChanged = function() {
			songData.preview[1] = previewEndStepper.value;
			if (songData.preview[0] >= songData.preview[1])
				songData.preview[0] = songData.preview[1] - 1;
		}

		var previewEndCurrent:TextButton = cast ui.element("previewEndCurrent");
		previewEndCurrent.onClicked = function() { previewEndStepper.value = songProgress / 4; previewEndStepper.onChanged(); }

		var bpmOnBeatStepper:Stepper = cast ui.element("bpmOnBeatStepper");

		var bpmOnBeatZero:TextButton = cast ui.element("bpmOnBeatZero");
		bpmOnBeatZero.onClicked = function() { bpmOnBeatStepper.value = 0; }

		var bpmOnBeatCurrent:TextButton = cast ui.element("bpmOnBeatCurrent");
		bpmOnBeatCurrent.onClicked = function() { bpmOnBeatStepper.value = songProgress / 4; }

		var bpmStepper:Stepper = cast ui.element("bpmStepper");
		bpmStepper.value = songData.bpmMap[0][1];
		bpmStepper.condition = function() { return Conductor.bpm; }
		bpmStepper.onChanged = function () {
			var slot:Int = -1;
			for (i in 0...songData.bpmMap.length)
			{
				if (songData.bpmMap[i][0] == bpmOnBeatStepper.value)
					slot = i;
			}
			if (slot >= 0)
			{
				if (slot >= 1 && songData.bpmMap[slot-1][1] == bpmStepper.value)
					songData.bpmMap.remove(songData.bpmMap[slot]);
				else
					songData.bpmMap[slot][1] = bpmStepper.value;
			}
			else
			{
				slot = 0;
				for (i in 0...songData.bpmMap.length)
				{
					if (songData.bpmMap[i][0] < bpmOnBeatStepper.value)
						slot = i + 1;
				}
				songData.bpmMap.insert(slot, [bpmOnBeatStepper.value, bpmStepper.value]);
			}

			for (note in noteData)
			{
				if (note[2] > 0)
					note[2] = Conductor.stepFromTime(note[0] + note[2]);
				note[0] = Conductor.stepFromTime(note[0]);
			}

			Conductor.recalculateTimings(songData.bpmMap);
			Conductor.recalculateBPM();

			for (note in noteData)
			{
				if (note[2] > 0)
					note[2] = Conductor.timeFromStep(note[2]) - Conductor.timeFromStep(note[0]);
				note[0] = Conductor.timeFromStep(note[0]);
			}

			for (e in songData.events)
				e.time = Conductor.timeFromBeat(e.beat);

			repositionSustains();
			repositionNotes();
			refreshBPMLines();
			refreshWaveform();
			refreshSongEndLine();
		}

		var scrollSpeedStepper:Stepper = cast ui.element("scrollSpeedStepper");
		scrollSpeedStepper.value = songData.scrollSpeeds[0][1];
		scrollSpeedStepper.condition = function() {
			var spd:Float = songData.scrollSpeeds[0][1];
			for (s in songData.scrollSpeeds)
			{
				if (songProgress / 4 >= s[0])
					spd = s[1];
			}
			return spd;
		}
		scrollSpeedStepper.onChanged = function () {
			var slot:Int = -1;
			for (i in 0...songData.scrollSpeeds.length)
			{
				if (songData.scrollSpeeds[i][0] == bpmOnBeatStepper.value)
					slot = i;
			}
			if (slot >= 0)
			{
				if (slot >= 1 && songData.scrollSpeeds[slot-1][1] == scrollSpeedStepper.value)
					songData.scrollSpeeds.remove(songData.scrollSpeeds[slot]);
				else
					songData.scrollSpeeds[slot][1] = scrollSpeedStepper.value;
			}
			else
			{
				slot = 0;
				for (i in 0...songData.scrollSpeeds.length)
				{
					if (songData.scrollSpeeds[i][0] < bpmOnBeatStepper.value)
						slot = i + 1;
				}
				songData.scrollSpeeds.insert(slot, [bpmOnBeatStepper.value, scrollSpeedStepper.value]);
			}

			refreshBPMLines();
		}

		var scrollSpeedHalfButton:TextButton = cast ui.element("scrollSpeedHalfButton");
		scrollSpeedHalfButton.onClicked = function()
		{
			scrollSpeedStepper.value = scrollSpeedStepper.value / 2;
			scrollSpeedStepper.onChanged();
		}

		var scrollSpeedDoubleButton:TextButton = cast ui.element("scrollSpeedDoubleButton");
		scrollSpeedDoubleButton.onClicked = function()
		{
			scrollSpeedStepper.value = scrollSpeedStepper.value * 2;
			scrollSpeedStepper.onChanged();
		}

		var scrollSpeedCalc:Checkbox = cast ui.element("scrollSpeedCalc");
		scrollSpeedCalc.checked = songData.altSpeedCalc;
		scrollSpeedCalc.condition = function() { return songData.altSpeedCalc; }
		scrollSpeedCalc.onClicked = function() { songData.altSpeedCalc = scrollSpeedCalc.checked; }

		noteTypeInput = cast ui.element("noteTypeInput");
		noteTypeInput.focusGained = function() { suspendControls = true; }
		noteTypeInput.focusLost = function() { suspendControls = false; updateReplaceTypeList(); }

		var noteTypeList:Array<String> = Paths.listFilesSub("data/notetypes/", ".json");
		noteTypeList.remove("default");
		noteTypeList.unshift("");

		var noteTypeDropdown:DropdownMenu = cast ui.element("noteTypeDropdown");
		noteTypeDropdown.valueList = noteTypeList;
		noteTypeDropdown.onChanged = function() { noteTypeInput.text = noteTypeDropdown.value; updateReplaceTypeList(); }

		replaceTypeDropdown = cast ui.element("replaceTypeDropdown");
		updateReplaceTypeList();

		var selectTypeButton:TextButton = cast ui.element("selectTypeButton");
		selectTypeButton.onClicked = function()
		{
			selectedNotes = [];
			var selectedIndexes:Array<Int> = [];

			var i:Int = 0;
			for (n in noteData)
			{
				var s:SectionData = songData.notes[secFromTime(n[0])];
				var type:String = "";
				if (n.length > 3)
					type = n[3];
				if (type == "")
				{
					if (s.defaultNotetypes[songData.columns[n[1]].division] != "")
						type = s.defaultNotetypes[songData.columns[n[1]].division];
				}
				if (type == replaceTypeDropdown.value)
					selectedIndexes.push(i);
				i++;
			}

			for (i in selectedIndexes)
				selectedNotes.push(notes.members[i]);
			refreshSelectedNotes();
		}

		var removeTypeButton:TextButton = cast ui.element("removeTypeButton");
		removeTypeButton.onClicked = function()
		{
			var noteTypeString:String = replaceTypeDropdown.value;
			if (noteTypeString == "")
				noteTypeString = "default";

			new Confirm("Are you sure you want to delete all notes of type \""+noteTypeString+"\"?", function() {
				var poppers:Array<Array<Dynamic>> = [];
				for (n in noteData)
				{
					var s:SectionData = songData.notes[secFromTime(n[0])];
					var type:String = "";
					if (n.length > 3)
						type = n[3];
					if (type == "")
					{
						if (s.defaultNotetypes[songData.columns[n[1]].division] != "")
							type = s.defaultNotetypes[songData.columns[n[1]].division];
					}
					if (type == replaceTypeDropdown.value)
						poppers.push(n);
				}
				for (p in poppers)
					noteData.remove(p);

				for (s in songData.notes)
				{
					for (i in 0...s.defaultNotetypes.length)
					{
						if (s.defaultNotetypes[i] == replaceTypeDropdown.value)
							s.defaultNotetypes[i] = "";
					}
				}

				selectedNotes = [];
				updateReplaceTypeList();
				refreshSelectedNotes();
				refreshNotes();
				refreshSustains();
			});
		}

		var replaceTypeButton:TextButton = cast ui.element("replaceTypeButton");
		replaceTypeButton.onClicked = function()
		{
			for (n in noteData)
			{
				var type:String = "";
				if (n.length > 3)
					type = n[3];
				if (type == replaceTypeDropdown.value)
				{
					if (noteTypeInput.text == "")
					{
						if (n.length > 3)
							n.pop();
					}
					else
					{
						if (n.length > 3)
							n[3] = noteTypeInput.text;
						else
							n.push(noteTypeInput.text);
					}
				}
			}

			for (s in songData.notes)
			{
				for (i in 0...s.defaultNotetypes.length)
				{
					if (s.defaultNotetypes[i] == replaceTypeDropdown.value)
						s.defaultNotetypes[i] = noteTypeInput.text;
				}
			}

			updateReplaceTypeList();
			refreshNotes();
			refreshSustains();
		}

		var autoSectionNotetypes:TextButton = cast ui.element("autoSectionNotetypes");
		autoSectionNotetypes.onClicked = function()
		{
			for (s in songData.notes)
			{
				var types:Array<Array<String>> = [];
				var emptyNotes:Array<Array<Int>> = [];
				for (i in 0...s.defaultNotetypes.length)
				{
					types.push([]);
					emptyNotes.push([]);
				}

				for (i in 0...noteData.length)
				{
					if (timeInSec(noteData[i][0], songData.notes.indexOf(s)))
					{
						var t:String = "";
						if (noteData[i].length > 3)
							t = noteData[i][3];

						if (!types[songData.columns[noteData[i][1]].division].contains(t))
							types[songData.columns[noteData[i][1]].division].push(t);
						emptyNotes[songData.columns[noteData[i][1]].division].push(i);
					}
				}

				for (i in 0...types.length)
				{
					if (types[i].length == 1 && types[i][0] != "")
					{
						for (i in emptyNotes[i])
							noteData[i].pop();
						s.defaultNotetypes[i] = types[i][0];
					}
				}
			}
			refreshNotes();
		}

		var clearSectionNotetypes:TextButton = cast ui.element("clearSectionNotetypes");
		clearSectionNotetypes.onClicked = function()
		{
			for (n in noteData)
			{
				if (n.length < 4 || n[3] == "")
				{
					var s:SectionData = songData.notes[secFromTime(n[0])];
					if (s.defaultNotetypes[songData.columns[n[1]].division] != "")
					{
						if (n.length < 4)
							n.push(s.defaultNotetypes[songData.columns[n[1]].division]);
						else
							n[3] = s.defaultNotetypes[songData.columns[n[1]].division];
					}
				}
			}

			for (s in songData.notes)
			{
				for (i in 0...s.defaultNotetypes.length)
					s.defaultNotetypes[i] == "";
			}
			refreshNotes();
		}

		var beatStepper:Stepper = cast ui.element("beatStepper");

		var insertBeatsButton:TextButton = cast ui.element("insertBeatsButton");
		insertBeatsButton.onClicked = function()
		{
			for (note in noteData)
			{
				if (note[0] >= Conductor.timeFromStep(songProgress))
				{
					if (note[2] > 0)
						note[2] = Conductor.beatFromTime(note[0] + note[2]) + beatStepper.value;
					note[0] = Conductor.beatFromTime(note[0]) + beatStepper.value;
					if (note[2] > 0)
						note[2] = Conductor.timeFromBeat(note[2]) - Conductor.timeFromBeat(note[0]);
					note[0] = Conductor.timeFromBeat(note[0]);
				}
			}

			selectedNotes = [];
			refreshSelectedNotes();
			refreshSustains();
			refreshNotes();
		}

		var removeBeatsButton:TextButton = cast ui.element("removeBeatsButton");
		removeBeatsButton.onClicked = function()
		{
			var poppers:Array<Array<Dynamic>> = [];
			for (note in noteData)
			{
				if (note[0] >= Conductor.timeFromStep(songProgress))
				{
					if (note[0] < Conductor.timeFromStep(songProgress + (beatStepper.value * 4)))
						poppers.push(note);
					else
					{
						if (note[2] > 0)
							note[2] = Conductor.beatFromTime(note[0] + note[2]) - beatStepper.value;
						note[0] = Conductor.beatFromTime(note[0]) - beatStepper.value;
						if (note[2] > 0)
							note[2] = Conductor.timeFromBeat(note[2]) - Conductor.timeFromBeat(note[0]);
						note[0] = Conductor.timeFromBeat(note[0]);
					}
				}
			}

			for (p in poppers)
				noteData.remove(p);

			selectedNotes = [];
			refreshSelectedNotes();
			refreshSustains();
			refreshNotes();
		}

		allCamsOnStepper = cast ui.element("allCamsOnStepper");
		allCamsOnStepper.maxVal = charCount;

		var allCamsOnButton:TextButton = cast ui.element("allCamsOnButton");
		allCamsOnButton.onClicked = function() { allCamsOn(allCamsOnStepper.valueInt - 1); }

		var copyCamsFromFileButton:TextButton = cast ui.element("copyCamsFromFileButton");
		copyCamsFromFileButton.onClicked = copyCamsFromFile;



		eventsTab = cast ui.element("eventsTab");

		curEventText = cast ui.element("curEventText");
		curEventText.size -= 4;
		curEventText.text = "None";
		updateEventList();

		var selectEventButton:TextButton = cast ui.element("selectEventButton");
		selectEventButton.onClicked = function() {
			var vbox:VBox = new VBox(35, 35);
			var window:PopupWindow = null;

			var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
			var scroll:VBox = menu.vbox;

			var noEventButton:TextButton = new TextButton(0, 0, "None", Button.LONG);
			noEventButton.onClicked = function() {
				window.close();
				curEvent = -1;
			}
			scroll.add(noEventButton);

			for (i in 0...songData.events.length)
			{
				var typeName:String = songData.events[i].type;
				if (eventTypeNames.exists(typeName))
					typeName = eventTypeNames[typeName];
				var eventButton:TextButton = new TextButton(0, 0, Std.string(songData.events[i].beat) + " | " + typeName, Button.LONG);
				eventButton.onClicked = function() {
					window.close();
					curEvent = i;
				}
				scroll.add(eventButton);
			}

			vbox.add(menu);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		var prevEventButton:Button = cast ui.element("prevEventButton");
		prevEventButton.onClicked = function() {
			if (curEvent > -1)
				curEvent--;
		}

		var nextEventButton:Button = cast ui.element("nextEventButton");
		nextEventButton.onClicked = function() {
			if (curEvent < songData.events.length - 1)
				curEvent++;
		}

		var jumpToEventButton:TextButton = cast ui.element("jumpToEventButton");
		jumpToEventButton.onClicked = function() {
			if (curEvent > -1)
				songProgress = songData.events[curEvent].beat * 4;
		}

		var moveEventButton:TextButton = cast ui.element("moveEventButton");
		moveEventButton.onClicked = function() {
			if (curEvent >= 0)
			{
				songData.events[curEvent].time = Conductor.timeFromStep(songProgress);
				songData.events[curEvent].beat = songProgress / 4;
				updateEventList();
				refreshEventLines();
				curEvent = curEvent;
			}
		}

		var deleteEventButton:TextButton = cast ui.element("deleteEventButton");
		deleteEventButton.onClicked = function() {
			if (curEvent >= 0)
			{
				songData.events.splice(curEvent, 1);
				updateEventList();
				refreshEventLines();
				curEvent = curEvent;
			}
		}

		eventTypeDropdown = cast ui.element("eventTypeDropdown");
		eventTypeDropdown.valueText = eventTypeNames;
		eventTypeDropdown.valueList = eventTypeList;
		eventTypeDropdown.value = eventTypeList[0];
		eventTypeDropdown.onChanged = function() {
			if (curEvent > -1)
				curEvent = -1;
			updateEventParams();
		};

		addEventButton = cast ui.element("addEventButton");
		addEventButton.onClicked = function() {
			var eventParamListCopy:Dynamic = Reflect.copy(eventParamList);
			songData.events.push({time: Conductor.timeFromStep(songProgress), beat: songProgress / 4, type: eventTypeDropdown.value, parameters: eventParamListCopy});
			updateEventList();
			refreshEventLines();
		}

		eventPropertiesText = cast ui.element("eventPropertiesText");

		updateEventParams();



		hoverTextDisplay = new FlxSpriteGroup();
		hoverTextDisplay.cameras = [camHUD];
		hoverTextDisplay.visible = false;
		add(hoverTextDisplay);

		hoverTextBG = new FlxSprite().makeGraphic(10, 10, FlxColor.WHITE);
		hoverTextDisplay.add(hoverTextBG);

		hoverTextObject = new FlxText(0, 0, "", 16);
		hoverTextObject.color = FlxColor.BLACK;
		hoverTextObject.font = "Monsterrat";
		hoverTextDisplay.add(hoverTextObject);



		var help:String = Paths.text("helpText").replace("\r","").split("!ChartEditor\n")[1].split("\n\n")[0];

		var tabOptions:Array<TopMenuOption> = [];
		for (t in tabMenu.tabs)
			tabOptions.push({label: t, action: function() { tabMenu.selectTabByName(t); }, condition: function() { return tabMenu.curTabName == t; }, icon: "bullet"});

		var beatCounts:Array<Int> = [4, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192];
		var beatOptions:Array<TopMenuOption> = [];
		for (b in beatCounts)
		{
			beatOptions.push({
				label: Std.string(b) + "th",
				action: function() {
					selectedNotes = [];

					notes.forEachAlive(function(note:Note)
						{
							var beatRow = Math.round(note.beat * 48);
							var noteBeat:Int = 0;
							for (_b in beatCounts)
							{
								if (beatRow % (192 / _b) == 0)
								{
									noteBeat = _b;
									break;
								}
							}
							if (!selectedNotes.contains(note) && noteBeat == b)
								selectedNotes.push(note);
						}
					);

					refreshSelectedNotes();
				}
			});
		}

		var showTickSettingsMenu:Void->Void = null;
		showTickSettingsMenu = function() {
			fixColumnDivisionNames();

			var window:PopupWindow = null;
			var vbox:VBox = new VBox(35, 35);

			vbox.add(new Label("Beat Tick"));

			var beatTickVolumeStepper:Stepper = new Stepper(0, 0, "Volume:", beatTickVolume * 10, 1, 0, 10);
			beatTickVolumeStepper.onChanged = function() { beatTickVolume = beatTickVolumeStepper.value / 10; }
			vbox.add(beatTickVolumeStepper);

			var barLengthStepper:Stepper = new Stepper(0, 0, "Bar Length:", beatTickBarLength, 1, 0);
			barLengthStepper.onChanged = function() { beatTickBarLength = barLengthStepper.valueInt; }
			vbox.add(barLengthStepper);

			vbox.add(new Label("Note Tick"));

			var noteTickVolumeStepper:Stepper = new Stepper(0, 0, "Volume:", noteTickVolume * 10, 1, 0, 10);
			noteTickVolumeStepper.onChanged = function() { noteTickVolume = noteTickVolumeStepper.value / 10; }
			vbox.add(noteTickVolumeStepper);

			vbox.add(new Label("Strumline to tick notes of:"));

			var sides:Array<String> = ["All"];
			for (s in songData.columnDivisionNames)
				sides.push(Lang.get(s));
			var sideDropdown:DropdownMenu = new DropdownMenu(0, 0, sides[noteTick + 1], sides);
			sideDropdown.onChanged = function() { noteTick = sideDropdown.valueInt - 1; }
			vbox.add(sideDropdown);

			vbox.add(new Label("Types of notes to tick:"));

			if (noteTickFilter.length > 0)
			{
				var menu:VBoxScrollable = new VBoxScrollable(0, 0, 250);
				var scroll:VBox = menu.vbox;

				for (i in 0...noteTickFilter.length)
				{
					var typeHbox:HBox = new HBox();
					typeHbox.add(new Label("Note Type "+Std.string(i+1)+":"));
					var typeDropdown:DropdownMenu = new DropdownMenu(0, 0, noteTickFilter[i], replaceTypeDropdown.valueList, "Default");
					typeDropdown.onChanged = function() { noteTickFilter[i] = typeDropdown.value; };
					typeHbox.add(typeDropdown);
					scroll.add(typeHbox);
				}

				vbox.add(menu);
			}
			else
				vbox.add(new Label("All"));

			var hbox:HBox = new HBox();

			var _add:TextButton = new TextButton(0, 0, "Add");
			_add.onClicked = function() {
				if (noteTickFilter.length > 0)
					noteTickFilter.push(noteTickFilter[noteTickFilter.length - 1]);
				else
					noteTickFilter.push("");
				window.close();
				new FlxTimer().start(0.01, function(tmr:FlxTimer) { showTickSettingsMenu(); });
			}
			hbox.add(_add);

			var _remove:TextButton = new TextButton(0, 0, "Remove");
			_remove.onClicked = function() {
				if (noteTickFilter.length > 0)
				{
					noteTickFilter.pop();
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { showTickSettingsMenu(); });
				}
			}
			hbox.add(_remove);

			vbox.add(hbox);

			var accept:TextButton = new TextButton(0, 0, "Accept", function() { window.close(); });
			vbox.add(accept);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		topmenu = new TopMenu([
			{
				label: "File",
				options: [
					{
						label: "New",
						action: function() { _confirm("make a new chart", _new); },
						shortcut: [FlxKey.CONTROL, FlxKey.N],
						icon: "new"
					},
					{
						label: "Open",
						action: function() { _confirm("load another chart", _open); },
						shortcut: [FlxKey.CONTROL, FlxKey.O],
						icon: "open"
					},
					{
						label: "Open Events",
						action: function() { loadEvents(false); },
						icon: "open"
					},
					{
						label: "Open & Add Events",
						action: function() { loadEvents(true); },
						icon: "open"
					},
					{
						label: "Save",
						action: function() {
							_save(false);
							if (songData.events.length > 0)
								_saveEvents(false);
						},
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
						label: "Save Events As...",
						action: function() { _saveEvents(true); },
						icon: "save"
					},
					{
						label: "Save As StepMania Chart",
						action: saveSM,
						icon: "save"
					},
					{
						label: "Convert from Base Game",
						action: convertFromBase
					},
					null,
					{
						label: "Test Chart",
						options: [
							{
								label: "From Start",
								action: function() {
									PlayState.testingChart = true;
									PlayState.testingChartData = Song.copy(songData);
									for (s in PlayState.testingChartData.notes)
										s.sectionNotes = [];
									for (n in noteData)
									{
										var newN:Array<Dynamic> = n.copy();
										var s:Int = secFromTime(newN[0]);
										PlayState.testingChartData.notes[s].sectionNotes.push(newN);
									}
									PlayState.testingChartFromPos = false;
									PlayState.testingChartPos = Conductor.timeFromStep(songProgress) - songData.offset;
									PlayState.testingChartSide = testChartSide;
									PlayState.inStoryMode = false;
									PlayState.songId = songId;
									FlxG.mouse.visible = false;
									FlxG.switchState(new PlayState());
								}
							},
							{
								label: "From Current Time",
								action: function() {
									PlayState.testingChart = true;
									PlayState.testingChartData = Song.copy(songData);
									for (s in PlayState.testingChartData.notes)
										s.sectionNotes = [];
									for (n in noteData)
									{
										var newN:Array<Dynamic> = n.copy();
										var s:Int = secFromTime(newN[0]);
										PlayState.testingChartData.notes[s].sectionNotes.push(newN);
									}
									PlayState.testingChartFromPos = true;
									PlayState.testingChartPos = Conductor.timeFromStep(songProgress) - songData.offset;
									PlayState.testingChartSide = testChartSide;
									PlayState.inStoryMode = false;
									PlayState.songId = songId;
									FlxG.mouse.visible = false;
									FlxG.switchState(new PlayState());
								}
							},
							{
								label: "On Side...",
								action: function() {
									fixColumnDivisionNames();

									var window:PopupWindow = null;
									var vbox:VBox = new VBox(35, 35);

									var sides:Array<String> = [];
									for (s in songData.columnDivisionNames)
										sides.push(Lang.get(s));
									var sideDropdown:DropdownMenu = new DropdownMenu(0, 0, sides[testChartSide], sides);
									sideDropdown.onChanged = function() { testChartSide = sideDropdown.valueInt; }
									vbox.add(sideDropdown);

									var accept:TextButton = new TextButton(0, 0, "Accept", function() { window.close(); });
									vbox.add(accept);

									window = PopupWindow.CreateWithGroup(vbox);
								}
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
						label: "Cut Notes",
						action: function() {
							if (selectedNotes.length > 0)
							{
								var firstStep:Float = -1;
								for (note in selectedNotes)
								{
									if (firstStep == -1 || Conductor.stepFromTime(note.strumTime) < firstStep)
										firstStep = Conductor.stepFromTime(note.strumTime);
								}

								noteClipboard = [];
								for (note in selectedNotes)
								{
									var n = noteData[notes.members.indexOf(note)];

									var nClone:Array<Dynamic> = n.copy();
									nClone[2] = Conductor.stepFromTime(nClone[0] + nClone[2]);
									nClone[0] = Conductor.stepFromTime(nClone[0]);
									nClone[1] = n[1];
									noteClipboard.push(nClone);
								}

								for (n in noteClipboard)
								{
									n[0] -= firstStep;
									n[2] -= firstStep;
								}

								selNoteBoxes.forEachAlive(function(note:NoteSelection) {
									removeNote(note.strumTime, note.column);
								});

								selectedNotes = [];
								refreshSelectedNotes();

								updateReplaceTypeList();
								refreshNotes();
								refreshSustains();
							}
						},
						shortcut: [FlxKey.CONTROL, FlxKey.X]
					},
					{
						label: "Copy Notes",
						action: function() {
							if (selectedNotes.length > 0)
							{
								var firstStep:Float = -1;
								for (note in selectedNotes)
								{
									if (firstStep == -1 || Conductor.stepFromTime(note.strumTime) < firstStep)
										firstStep = Conductor.stepFromTime(note.strumTime);
								}

								noteClipboard = [];
								for (note in selectedNotes)
								{
									var n = noteData[notes.members.indexOf(note)];

									var nClone:Array<Dynamic> = n.copy();
									nClone[2] = Conductor.stepFromTime(nClone[0] + nClone[2]);
									nClone[0] = Conductor.stepFromTime(nClone[0]);
									nClone[1] = n[1];
									noteClipboard.push(nClone);
								}

								for (n in noteClipboard)
								{
									n[0] -= firstStep;
									n[2] -= firstStep;
								}
							}
						},
						shortcut: [FlxKey.CONTROL, FlxKey.C]
					},
					{
						label: "Paste Notes",
						options: [
							{
								label: "At Mouse Location",
								action: function() {
									if (noteClipboard.length > 0)
									{
										var startTime:Float = ghostNote.beat * 4;
										var min:Int = numColumns + 1;
										var max:Int = 0;
										for (n in noteClipboard)
										{
											if (n[1] < min)
												min = n[1];
											if (n[1] > max)
												max = n[1];
										}
										max -= min;
										var startColumn:Int = Std.int(Math.min(numColumns - 1 - max, ghostNote.column));

										var pastedNotes:Array<Array<Dynamic>> = [];
										var selectionArray:Array<Array<Float>> = [];
										for (n in noteClipboard)
										{
											var nClone:Array<Dynamic> = n.copy();
											nClone[0] += startTime;
											nClone[2] += startTime;
											nClone[0] = Conductor.timeFromStep(nClone[0]);
											nClone[2] = Conductor.timeFromStep(nClone[2]) - nClone[0];
											nClone[1] = nClone[1] - min + startColumn;
											pastedNotes.push(nClone);
										}

										var poppers:Array<Array<Dynamic>> = [];
										for (n in noteData)
										{
											for (note in pastedNotes)
											{
												if (n[0] == note[0] && n[1] == note[1])
													poppers.push(note);
											}
										}

										var poppedNotes:Bool = false;
										if (poppers.length > 0)
										{
											poppedNotes = true;
											for (p in poppers)
												pastedNotes.remove(p);
										}

										for (n in pastedNotes)
										{
											selectionArray.push([n[0], n[1]]);
											noteData.push(n);
										}

										refreshNotes();
										refreshSustains();
										selectedNotes = [];
										notes.forEachAlive(function(n:Note) {
											for (a in selectionArray)
											{
												if (!selectedNotes.contains(n) && n.strumTime == a[0] && n.column == Std.int(a[1]))
													selectedNotes.push(n);
											}
										});
										refreshSelectedNotes();

										if (poppedNotes)
										{
											suspendSelection = true;
											new Notify("Some notes failed to copy due to overlap with existing notes.", function() { suspendSelection = false; });
										}
									}
								},
								shortcut: [FlxKey.CONTROL, FlxKey.V]
							},
							{
								label: "At Strum Location",
								action: function() {
									if (noteClipboard.length > 0)
									{
										var startTime:Float = songProgress;
										var pastedNotes:Array<Array<Dynamic>> = [];
										var selectionArray:Array<Array<Float>> = [];
										for (n in noteClipboard)
										{
											var nClone:Array<Dynamic> = n.copy();
											nClone[0] += startTime;
											nClone[2] += startTime;
											nClone[0] = Conductor.timeFromStep(nClone[0]);
											nClone[2] = Conductor.timeFromStep(nClone[2]) - nClone[0];
											pastedNotes.push(nClone);
										}

										var poppers:Array<Array<Dynamic>> = [];
										for (n in noteData)
										{
											for (note in pastedNotes)
											{
												if (n[0] == note[0] && n[1] == note[1])
													poppers.push(note);
											}
										}

										var poppedNotes:Bool = false;
										if (poppers.length > 0)
										{
											poppedNotes = true;
											for (p in poppers)
												pastedNotes.remove(p);
										}

										for (n in pastedNotes)
										{
											selectionArray.push([n[0], n[1]]);
											noteData.push(n);
										}

										refreshNotes();
										refreshSustains();
										selectedNotes = [];
										notes.forEachAlive(function(n:Note) {
											for (a in selectionArray)
											{
												if (!selectedNotes.contains(n) && n.strumTime == a[0] && n.column == Std.int(a[1]))
													selectedNotes.push(n);
											}
										});
										refreshSelectedNotes();

										if (poppedNotes)
										{
											suspendSelection = true;
											new Notify("Some notes failed to copy due to overlap with existing notes.", function() { suspendSelection = false; });
										}
									}
								},
								shortcut: [FlxKey.CONTROL, FlxKey.SHIFT, FlxKey.V]
							}
						]
					},
					null,
					{
						label: "Select All Notes",
						action: function() {
							notes.forEachAlive(function(note:Note)
								{
									if (!selectedNotes.contains(note))
										selectedNotes.push(note);
								}
							);

							refreshSelectedNotes();
						},
						shortcut: [FlxKey.CONTROL, FlxKey.A]
					},
					{
						label: "Select Notes Before Strumline",
						action: function() {
							selectedNotes = [];

							notes.forEachAlive(function(note:Note)
								{
									if (note.beat <= songProgress / 4)
										selectedNotes.push(note);
								}
							);

							refreshSelectedNotes();
						},
						shortcut: [FlxKey.SHIFT, FlxKey.HOME]
					},
					{
						label: "Select Notes After Strumline",
						action: function() {
							selectedNotes = [];

							notes.forEachAlive(function(note:Note)
								{
									if (note.beat >= songProgress / 4)
										selectedNotes.push(note);
								}
							);

							refreshSelectedNotes();
						},
						shortcut: [FlxKey.SHIFT, FlxKey.END]
					},
					{
						label: "Select Notes in Current Section",
						action: function () {
							selectedNotes = [];

							notes.forEachAlive(function(note:Note)
								{
									if (!selectedNotes.contains(note) && timeInSec(note.strumTime, curSection))
										selectedNotes.push(note);
								}
							);

							refreshSelectedNotes();
						}
					},
					{
						label: "Select Notes by Beat",
						options: beatOptions
					},
					null,
					{
						label: "Snap Selected Notes",
						action: function() {
							if (selectedNotes.length > 0)
							{
								for (note in selectedNotes)
								{
									var n = noteData[notes.members.indexOf(note)];

									n[0] = Conductor.beatFromTime(n[0]);
									n[0] = Math.round(n[0] * (snap / 4)) / (snap / 4);
									n[0] = Conductor.timeFromBeat(n[0]);

									if (n.length > 2)
									{
										n[2] = Conductor.beatFromTime(n[0] + n[2]);
										n[2] = Math.round(n[2] * (snap / 4)) / (snap / 4);
										n[2] = Conductor.timeFromBeat(n[2]) - n[0];
									}
								}

								refreshNotes();
								refreshSustains();
								refreshSelectedNotes();
							}
						},
						shortcut: [FlxKey.CONTROL, FlxKey.B]
					},
					{
						label: "Flip Selected Notes",
						action: function() {
							if (selectedNotes.length > 0)
							{
								var min:Int = numColumns + 1;
								var max:Int = 0;
								for (note in selectedNotes)
								{
									var n = noteData[notes.members.indexOf(note)];
									if (n[1] < min)
										min = n[1];
									if (n[1] > max)
										max = n[1];
								}
								max -= min;

								for (note in selectedNotes)
								{
									var n = noteData[notes.members.indexOf(note)];
									n[1] -= min;
									n[1] = max - n[1] + min;
								}

								refreshNotes();
								refreshSustains();
								refreshSelectedNotes();
							}
						},
						shortcut: [FlxKey.CONTROL, FlxKey.F]
					},
					{
						label: "Move Selected Notes...",
						options: [
							{
								label: "One Unit Left",
								action: function() {
									if (selectedNotes.length > 0)
										moveSelectionOneCell(-1, 0);
								},
								shortcut: [FlxKey.SHIFT, FlxKey.LEFT]
							},
							{
								label: "One Unit Right",
								action: function() {
									if (selectedNotes.length > 0)
										moveSelectionOneCell(1, 0);
								},
								shortcut: [FlxKey.SHIFT, FlxKey.RIGHT]
							},
							{
								label: "One Unit Up",
								action: function() {
									if (selectedNotes.length > 0)
										moveSelectionOneCell(0, -1);
								},
								shortcut: [FlxKey.SHIFT, FlxKey.UP]
							},
							{
								label: "One Unit Down",
								action: function() {
									if (selectedNotes.length > 0)
										moveSelectionOneCell(0, 1);
								},
								shortcut: [FlxKey.SHIFT, FlxKey.DOWN]
							}
						]
					},
					{
						label: "Change Type of Selected Notes",
						action: function() {
							if (selectedNotes.length > 0)
							{
								for (note in selectedNotes)
								{
									var n = noteData[notes.members.indexOf(note)];

									if (noteTypeInput.text != "")
									{
										if (n.length > 3)
											n[3] = noteTypeInput.text;
										else
											n.push(noteTypeInput.text);
									}
									else if (n.length > 3)
										n.pop();
								}

								updateReplaceTypeList();
								refreshNotes();
								refreshSustains();
								refreshSelectedNotes();
							}
						},
						shortcut: [FlxKey.CONTROL, FlxKey.T]
					},
					{
						label: "Delete Selected Notes",
						action: function() {
							if (selectedNotes.length > 0)
							{
								selNoteBoxes.forEachAlive(function(note:NoteSelection) {
									removeNote(note.strumTime, note.column);
								});

								selectedNotes = [];
								refreshSelectedNotes();

								updateReplaceTypeList();
								refreshNotes();
								refreshSustains();
							}
						},
						shortcut: [FlxKey.DELETE]
					},
					null,
					{
						label: "Delete All Notes",
						action: function() {
							noteData = [];
							selectedNotes = [];
							updateReplaceTypeList();
							refreshSelectedNotes();
							refreshNotes();
							refreshSustains();
						}
					},
					{
						label: "Delete All Events",
						action: function() {
							new Confirm("Are you sure you want to delete all events?", function() {
								songData.events = [];
								refreshEventLines();
								updateEventList();
							});
						}
					}
				]
			},
			{
				label: "View",
				options: [
					{
						label: "Reverse Scroll",
						condition: function() { return downscroll; },
						action: function() {
							downscroll = !downscroll;

							refreshWaveform();
							refreshSongEndLine();
							refreshSectionLines();
							refreshSectionIcons();
							refreshStrums();
							repositionSustains();
							repositionNotes();
							refreshSelectedNotes();
							refreshBPMLines();
							refreshEventLines();
							refreshGhostNotes();
						},
						icon: "bullet"
					},
					null,
					{
						label: "Zoom In",
						action: function() {
							if (!DropdownMenu.isOneActive && !suspendControls)
							{
								zoom += 0.25;

								refreshWaveform();
								refreshSongEndLine();
								refreshSectionLines();
								refreshSectionIcons();
								repositionSustains();
								repositionNotes();
								refreshBPMLines();
								refreshEventLines();
								refreshGhostNotes();
								refreshSelectedNotes();
							}
						},
						shortcut: [FlxKey.X]
					},
					{
						label: "Zoom Out",
						action: function() {
							if (!DropdownMenu.isOneActive && zoom > 0.25 && !suspendControls)
							{
								zoom -= 0.25;

								refreshWaveform();
								refreshSongEndLine();
								refreshSectionLines();
								refreshSectionIcons();
								repositionSustains();
								repositionNotes();
								refreshBPMLines();
								refreshEventLines();
								refreshGhostNotes();
								refreshSelectedNotes();
							}
						},
						shortcut: [FlxKey.Z]
					},
					null,
					{
						label: "Jump to Start",
						action: function() {
							songProgress = 0;
						},
						shortcut: [FlxKey.HOME]
					},
					{
						label: "Jump to End",
						action: function() {
							songProgress = Conductor.stepFromTime(tracks[0].length) - (16 / snap);
							snapSongProgress();
						},
						shortcut: [FlxKey.END]
					},
					{
						label: "Jump One Section Up",
						action: function() { jumpOneSection(-1); },
						shortcut: [FlxKey.UP]
					},
					{
						label: "Jump One Section Down",
						action: function() { jumpOneSection(1); },
						shortcut: [FlxKey.DOWN]
					},
					null,
					{
						label: "Waveform",
						condition: function() { return waveformVisible; },
						action: function() {
							waveformVisible = !waveformVisible;
							refreshWaveform();
						},
						icon: "bullet"
					},
					{
						label: "Waveform Settings...",
						action: function() {
							var trackNameList:Array<String> = [];
							for (i in 0...songData.tracks.length)
								trackNameList.push(Std.string(i + 1) + " - " + songData.tracks[i][0]);

							var window:PopupWindow = null;
							var vbox:VBox = new VBox(35, 35);

							var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
							var scroll:VBox = menu.vbox;

							for (i in 0...waveformTrack.length)
							{
								var waveformTrackHbox:HBox = new HBox();
								waveformTrackHbox.add(new Label("Waveform "+Std.string(i+1)+" Track:"));
								var waveformTrackDropdown:DropdownMenu = new DropdownMenu(0, 0, trackNameList[waveformTrack[i]], trackNameList);
								waveformTrackDropdown.onChanged = function() {
									waveformTrack[i] = waveformTrackDropdown.valueInt;
								};
								waveformTrackHbox.add(waveformTrackDropdown);
								scroll.add(waveformTrackHbox);
							}

							vbox.add(menu);

							var accept:TextButton = new TextButton(0, 0, "Accept");
							accept.onClicked = function() {
								window.close();
								refreshWaveform();
							}
							vbox.add(accept);

							window = PopupWindow.CreateWithGroup(vbox);
						}
					},
					null,
					{
						label: "Beat Lines",
						condition: function() { return beatLines.visible; },
						action: function() { beatLines.visible = !beatLines.visible; },
						icon: "bullet"
					},
					{
						label: "Information Panel",
						condition: function() { return members.contains(infoBox); },
						action: function() {
							if (members.contains(infoBox))
								remove(infoBox, true);
							else
								insert(members.indexOf(hoverTextDisplay), infoBox);
						},
						icon: "bullet"
					},
					{
						label: "Position & Time Panel",
						condition: function() { return members.contains(timeBox); },
						action: function() {
							if (members.contains(timeBox))
								remove(timeBox, true);
							else
								insert(members.indexOf(hoverTextDisplay), timeBox);
						},
						icon: "bullet"
					}
				]
			},
			{
				label: "Settings",
				options: [
					{
						label: "Increase Note Snap",
						action: function() {
							if (!DropdownMenu.isOneActive && !suspendControls)
							{
								snap += 4;
								snapSongProgress();
							}
						},
						shortcut: [FlxKey.S]
					},
					{
						label: "Decrease Note Snap",
						action: function() {
							if (!DropdownMenu.isOneActive && snap > 4 && !suspendControls)
							{
								snap -= 4;
								snapSongProgress();
							}
						},
						shortcut: [FlxKey.A]
					},
					null,
					{
						label: "Allow Placing Notes & Events with Mouse",
						condition: function() { return allowMakingNoteMouse; },
						action: function() {
							allowMakingNoteMouse = !allowMakingNoteMouse;
							if (!allowMakingNoteMouse)
							{
								ghostNote.visible = false;
								sustainWidget.visible = false;
								ghostEvent.visible = false;
							}
						},
						shortcut: [FlxKey.P],
						icon: "bullet"
					},
					{
						label: "Allow Strumline to be Edited",
						condition: function() { return allowEditingStrumline; },
						action: function() {
							allowEditingStrumline = !allowEditingStrumline;
							strums.members[strums.members.length - 1].visible = allowEditingStrumline;
						},
						icon: "bullet"
					},
					null,
					{
						label: "Beat Tick",
						condition: function() { return beatTickEnabled; },
						action: function() { beatTickEnabled = !beatTickEnabled; },
						icon: "bullet"
					},
					{
						label: "Note Tick",
						condition: function() { return noteTickEnabled; },
						action: function() { noteTickEnabled = !noteTickEnabled; },
						icon: "bullet"
					},
					{
						label: "Tick Settings...",
						action: showTickSettingsMenu
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

		Main.onCloseCallback = function() {
			_confirm("quit", function() { Sys.exit(0); });
			return true;
		}



		dataLog1 = [Cloner.clone(songData)];
		dataLog2 = [Cloner.clone(noteData)];



		var extraColumns:Bool = false;
		for (n in noteData)
		{
			if (n[1] >= numColumns)
				extraColumns = true;
		}
		if (extraColumns)
			handleExtraColumns();
	}

	override public function destroy()
	{
		Main.onCloseCallback = null;

		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		UIControl.cursor = MouseCursor.ARROW;

		if (!pauseUndo && (!DeepEquals.deepEquals(songData, dataLog1[undoPosition]) || !DeepEquals.deepEquals(noteData, dataLog2[undoPosition])))
		{
			if (undoPosition < dataLog1.length - 1)
			{
				dataLog1.resize(undoPosition + 1);
				dataLog2.resize(undoPosition + 1);
			}
			dataLog1.push(Cloner.clone(songData));
			dataLog2.push(Cloner.clone(noteData));
			unsaved = true;
			undoPosition = dataLog1.length - 1;
			refreshFilename();
		}

		if (allowMakingNoteMouse)
			sustainWidget.visible = (noteData.length > 0 && FlxG.keys.pressed.CONTROL);

		mousePos.x = FlxG.mouse.x;
		mousePos.y = FlxG.mouse.y + camFollow.y - (FlxG.height / 2);
		if (FlxG.mouse.justMoved)
		{
			curStrum = -1;
			if (allowEditingStrumline || FlxG.keys.pressed.ALT)
			{
				strums.forEachAlive(function(note:FlxSprite)
					{
						if (FlxG.mouse.overlaps(note))
						{
							curStrum = strums.members.indexOf(note);
							note.alpha = 1;
							UIControl.cursor = MouseCursor.BUTTON;
						}
						else
							note.alpha = 0.5;
					}
				);
			}

			var foundNote:Bool = false;
			hoverText = "";
			if (curStrum < 0)
			{
				if (noteData.length > 0)
				{
					notes.forEachAlive(function(note:Note) {
						if (note.overlaps(mousePos))
						{
							foundNote = true;
							if (selectedNotes.contains(note))
								UIControl.cursor = MouseCursor.HAND;
							else
								UIControl.cursor = MouseCursor.BUTTON;

							if (note.noteType != "default" && note.noteType != "")
								hoverText = note.noteType;
							else
							{
								var sec:SectionData = songData.notes[secFromStep(Std.int(note.beat * 4))];
								if (sec.defaultNotetypes[songData.columns[note.column].division] != "")
									hoverText = sec.defaultNotetypes[songData.columns[note.column].division];
							}
						}
					});

					if (!foundNote && !sustainWidgetAdjusting)
					{
						sustains.forEachAlive(function(note:EditorSustainNote) {
							if (note.noteDraw.overlaps(mousePos))
							{
								sustainWidget.setPosition(note.x - (sustainWidget.width / 2), note.y + (downscroll ? 0 : note.noteDraw.height) - (sustainWidget.height / 2));
								sustainWidgetNote = sustains.members.indexOf(note);
							}
						});

						if (sustainWidget.visible && sustainWidget.overlaps(mousePos))
							UIControl.cursor = MouseCursor.HAND;
					}
				}

				eventIcons.forEachAlive(function(event:FlxSprite) {
					if (event.overlaps(mousePos))
					{
						if (eventIcons.members.indexOf(event) != curEvent)
							event.animation.play("hovered");
						UIControl.cursor = MouseCursor.BUTTON;
						var eventData:EventData = songData.events[eventIcons.members.indexOf(event)];
						hoverText = eventData.type;
						if (eventTypeNames.exists(hoverText))
							hoverText = eventTypeNames[hoverText];
						if (eventTypeParams.exists(eventData.type))
						{
							for (p in eventTypeParams[eventData.type].parameters)
							{
								if (p.type != "label")
								{
									var val:String = Std.string(Reflect.field(eventData.parameters, p.id));
									if (eventParamNames.exists(val))
										val = eventParamNames[val];
									hoverText += "\n" + p.label + ": " + val;
								}
							}
						}
					}
					else if (eventIcons.members.indexOf(event) != curEvent)
						event.animation.play("idle");
				});
			}

			hoverTextDisplay.setPosition(FlxG.mouse.x, Math.max(0, Math.min(FlxG.height - hoverTextDisplay.height, FlxG.mouse.y + 30)));

			var cellXPrev:Int = cellX;
			var cellYPrev:Int = cellY;
			cellX = Std.int(Math.floor((mousePos.x - ((FlxG.width / 2) - (NOTE_SIZE * numColumns / 2))) / NOTE_SIZE));
			cellX = Std.int(Math.min(numColumns - 1, Math.max(0, cellX)));
			var cellSizeY:Float = (NOTE_SIZE * zoom) * (16 / snap);
			cellY = Std.int(Math.round(mousePos.y / cellSizeY));
			if (downscroll)
				cellY = -cellY;
			if (cellY < 0)
				cellY = 0;
			if (cellX != cellXPrev || cellY != cellYPrev)
			{
				ghostNote.setPosition(((FlxG.width / 2) - (NOTE_SIZE * numColumns / 2)) + (cellX * NOTE_SIZE), ((downscroll ? -cellY : cellY) * cellSizeY) - (ghostNote.height / 2));
				ghostNote.beat = cellY / (snap / 4);
				ghostNote.strumTime = Conductor.timeFromBeat(ghostNote.beat);
				ghostNote.column = cellX;
				ghostNote.strumColumn = strumColumns[cellX];

				if (allowMakingNoteMouse)
				{
					var noteType:String = noteTypeInput.text;
					ghostNote.noteType = noteType;
					ghostNote.updateTypeData();

					ghostNote.onNotetypeChanged(noteTypeFromColumn(cellX));
					ghostNote.setGraphicSize(NOTE_SIZE);
					ghostNote.updateHitbox();
					if (makingNoteMouse[0] > -1)
						refreshMakingSustains();

					ghostEvent.x = (FlxG.width / 2) + (NOTE_SIZE * numColumns / 2) + 1;
					ghostEvent.y = ((downscroll ? -cellY : cellY) * cellSizeY) - (ghostEvent.height / 2);
					for (e in songData.events)
					{
						if (e.beat == ghostNote.beat)
							ghostEvent.x += ghostEvent.width;
					}
				}
			}
			if (allowMakingNoteMouse)
			{
				ghostNote.visible = (ghostNote.overlaps(mousePos) && !foundNote && !selecting && !movingSelection && !TopMenu.busy && !DropdownMenu.isOneActive && !(sustainWidget.visible && sustainWidget.overlaps(mousePos)));
				if (ghostNote.visible)
					UIControl.cursor = MouseCursor.BUTTON;

				ghostEvent.visible = (ghostEvent.overlaps(mousePos) && tabMenu.curTabName == "Events" && !selecting && !movingSelection && !TopMenu.busy && !DropdownMenu.isOneActive);
				if (ghostEvent.visible)
					UIControl.cursor = MouseCursor.BUTTON;
			}
		}

		if (movingSelection)
		{
			UIControl.cursor = MouseCursor.HAND;
			var cellsXPrev:Int = cellsX;
			var cellsYPrev:Int = cellsY;
			cellsX = Std.int(Math.round((mousePos.x - selectionPos[0]) / NOTE_SIZE));
			var cellSizeY:Float = (NOTE_SIZE * zoom) * (16 / snap);
			cellsY = Std.int(Math.round((mousePos.y - selectionPos[1]) / cellSizeY));
			if (FlxG.mouse.justMoved && (cellsX != cellsXPrev || cellsY != cellsYPrev))
			{
				for (n in selectedNotes)
				{
					n.x = Std.int((FlxG.width / 2) - (NOTE_SIZE * (numColumns / 2)) + (NOTE_SIZE * ((n.column % numColumns) + cellsX)));
					n.y = Std.int(NOTE_SIZE * zoom * Conductor.stepFromTime(n.strumTime));
					if (downscroll)
						n.y = -n.y;
					n.y -= n.height / 2;
					n.y += cellsY * cellSizeY;
				}
				var childSustains:Array<EditorSustainNote> = [];
				for (n in selectedNotes)
					childSustains.push(sustains.members[notes.members.indexOf(n)]);
				for (s in childSustains)
				{
					s.refreshPosition(zoom, downscroll);
					s.x += cellsX * NOTE_SIZE;
					s.y += cellsY * cellSizeY;
				}
				selNoteBoxes.forEachAlive(function(n:NoteSelection) {
					n.refreshPosition(zoom, downscroll);
					n.x += cellsX * NOTE_SIZE;
					n.y += cellsY * cellSizeY;
				});
			}

			if (Options.mouseJustReleased())
			{
				var willPopNotes:Bool = false;
				var posConflict:Bool = false;
				for (note in selectedNotes)
				{
					var column:Int = note.column + cellsX;
					if (column < 0 || column >= numColumns)
						willPopNotes = true;
				}
				notes.forEachAlive(function(n:Note) {
					if (!selectedNotes.contains(n))
					{
						for (note in selectedNotes)
						{
							if (Math.floor(note.x) == Math.floor(n.x) && Math.floor(note.y) == Math.floor(n.y))
								posConflict = true;
						}
					}
				});
				if (posConflict)
				{
					suspendSelection = true;
					new Notify("Two notes cannot occupy the same space.", function() {
						returnSelection();
						suspendSelection = false;
					});
				}
				else if (willPopNotes)
				{
					suspendSelection = true;
					new Confirm("Some notes are outside valid columns and will get deleted.\nProceed?", function() {
						moveSelection(cellsX, cellsY, cellSizeY);
						suspendSelection = false;
					}, function() {
						returnSelection();
						suspendSelection = false;
					});
				}
				else
					moveSelection(cellsX, cellsY, cellSizeY);
				movingSelection = false;
			}
		}
		else if (selecting)
		{
			UIControl.cursor = MouseCursor.ARROW;
			if (mousePos.x >= selectionPos[0])
			{
				selectionBox.x = selectionPos[0];
				selectionBox.scale.x = (mousePos.x - selectionPos[0]) + 1;
			}
			else
			{
				selectionBox.x = mousePos.x;
				selectionBox.scale.x = (selectionPos[0] - mousePos.x) + 1;
			}

			if (mousePos.y >= selectionPos[1])
			{
				selectionBox.y = selectionPos[1];
				selectionBox.scale.y = (mousePos.y - selectionPos[1]) + 1;
			}
			else
			{
				selectionBox.y = mousePos.y;
				selectionBox.scale.y = (selectionPos[1] - mousePos.y) + 1;
			}
			selectionBox.updateHitbox();

			if (Options.mouseJustReleased())
			{
				notes.forEachAlive(function(note:Note)
					{
						if (note.overlaps(selectionBox) && !selectedNotes.contains(note))
							selectedNotes.push(note);
					}
				);

				selecting = false;
				selectionBox.visible = false;
				refreshSelectedNotes();
			}
		}
		else if (sustainWidgetAdjusting)
		{
			UIControl.cursor = MouseCursor.HAND;
			var beat:Float = cellY / (snap / 4);
			var time:Float = Conductor.timeFromBeat(beat) - noteData[sustainWidgetNote][0];
			if (sustainWidgetLimit > -1)
				time = Math.min(Conductor.timeFromBeat(beat), sustainWidgetLimit) - noteData[sustainWidgetNote][0];
			if (Conductor.timeFromBeat(beat) > noteData[sustainWidgetNote][0] && noteData[sustainWidgetNote][2] != time)
			{
				if (time > noteData[sustainWidgetNote][2])
					FlxG.sound.play(Paths.sound("ui/editors/charting/noteStretch"), 0.5);
				else
					FlxG.sound.play(Paths.sound("ui/editors/charting/noteShrink"), 0.5);
				noteData[sustainWidgetNote][2] = time;
				refreshSustains();
			}
			sustainWidget.y = sustains.members[sustainWidgetNote].y + (downscroll ? 0 : sustains.members[sustainWidgetNote].noteDraw.height) - (sustainWidget.height / 2);

			if (Options.mouseJustReleased())
			{
				sustainWidgetAdjusting = false;
				pauseUndo = false;
				FlxG.sound.play(Paths.sound("ui/editors/charting/notePlace"), 0.5);
			}
		}
		else if (makingNoteMouse[0] > -1)
		{
			UIControl.cursor = MouseCursor.HAND;
			if (Options.mouseJustReleased())
			{
				placeNote(makingNoteMouse[0], ghostNote.beat * 4, Std.int(makingNoteMouse[1]));
				makingNoteMouse = [-1, -1];
				refreshMakingSustains();
			}
		}

		if (Options.mouseJustPressed() && !DropdownMenu.isOneActive && !TopMenu.busy && !FlxG.mouse.overlaps(tabMenu) && !FlxG.mouse.overlaps(topmenu) && !FlxG.mouse.overlaps(infoBox) && !FlxG.mouse.overlaps(timeBox) && !noteMinimap.hovered)
		{
			var myNote:Note = null;
			notes.forEachAlive(function(note:Note) {
				if (note.overlaps(mousePos))
					myNote = note;
			});
			if (myNote != null)
			{
				if (selectedNotes.contains(myNote))
				{
					movingSelection = true;
					selectionPos = [Std.int(mousePos.x), Std.int(mousePos.y)];
				}
				else
				{
					if (!FlxG.keys.pressed.SHIFT)
						selectedNotes = [];
					selectedNotes.push(myNote);
					refreshSelectedNotes();
				}
			}
			else
			{
				var myEvent:Int = -1;
				eventIcons.forEachAlive(function(event:FlxSprite)
					{
						if (event.overlaps(mousePos))
							myEvent = eventIcons.members.indexOf(event);
					}
				);
				if (myEvent > -1)
				{
					tabMenu.selectTabByName("Events");
					curEvent = myEvent;
				}
				else
				{
					if (curEvent > -1)
						curEvent = -1;

					if (curStrum > -1)
					{
						if (FlxG.keys.pressed.ALT)
						{
							if (!FlxG.keys.pressed.SHIFT)
								selectedNotes = [];
							notes.forEachAlive(function(note:Note)
								{
									if (!selectedNotes.contains(note) && note.column == curStrum)
										selectedNotes.push(note);
								}
							);

							refreshSelectedNotes();
						}
						else if (curStrum == strums.members.length - 1)
						{
							var c:SongColumnData = Reflect.copy(songData.columns[songData.columns.length - 1]);
							c.anim = Song.defaultSingAnimations[songData.columns.length % Song.defaultSingAnimations.length];
							c.missAnim = c.anim + "miss";
							songData.columns.push(c);

							numColumns = songData.columns.length;

							refreshUniqueDivisions();

							NOTE_SIZE = Std.int(480 / numColumns);
							if (NOTE_SIZE > 60)
								NOTE_SIZE = 60;

							refreshSongEndLine();
							refreshSectionLines();
							refreshSectionIcons();
							refreshStrums();
							refreshNotes(true);
							refreshSustains(true);
							refreshBPMLines();
							refreshEventLines();
						}
						else
						{
							var singerList:Array<String> = [];
							var charCount:Int = 2;
							while (Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
								charCount++;

							for (i in 0...charCount)
							{
								var charName:String = Reflect.field(songData, "player" + Std.string(i + 1));
								if (characterNames.exists(charName))
									charName = characterNames[charName];
								singerList.push("Character " + Std.string(i + 1) + " (" + charName + ")");
							}

							fixColumnDivisionNames();
							var divisionList:Array<String> = songData.columnDivisionNames.copy();
							for (i in 0...divisionList.length)
								divisionList[i] = Lang.get(divisionList[i]);
							divisionList.push("New Side...");

							var window:PopupWindow = null;
							var vbox:VBox = new VBox(35, 35);

							var divisionHbox:HBox = new HBox();
							divisionHbox.add(new Label("Chart Side:"));
							var division:DropdownMenu = new DropdownMenu(0, 0, divisionList[songData.columns[curStrum].division], divisionList);
							divisionHbox.add(division);
							vbox.add(divisionHbox);

							var singerHbox:HBox = new HBox();
							singerHbox.add(new Label("Singer:"));
							var singer:DropdownMenu = new DropdownMenu(0, 0, singerList[songData.columns[curStrum].singer], singerList);
							singerHbox.add(singer);
							vbox.add(singerHbox);

							var animHbox:HBox = new HBox();
							animHbox.add(new Label("Character Animation:"));
							var anim:InputText = new InputText(0, 0, songData.columns[curStrum].anim);
							animHbox.add(anim);
							var animReset:TextButton = new TextButton(0, 0, "Reset", Button.SHORT);
							animReset.onClicked = function() { anim.text = Song.defaultSingAnimations[curStrum % Song.defaultSingAnimations.length]; }
							animHbox.add(animReset);
							vbox.add(animHbox);

							var missAnimHbox:HBox = new HBox();
							missAnimHbox.add(new Label("Character Miss Animation:"));
							var missAnim:InputText = new InputText(0, 0, songData.columns[curStrum].missAnim);
							missAnimHbox.add(missAnim);
							var missAnimReset:TextButton = new TextButton(0, 0, "Reset", Button.SHORT);
							missAnimReset.onClicked = function() { missAnim.text = anim.text + "miss"; }
							missAnimHbox.add(missAnimReset);
							vbox.add(missAnimHbox);

							var ok:TextButton = new TextButton(0, 0, "#ok", Button.SHORT);
							ok.onClicked = function() {
								songData.columns[curStrum].division = division.valueInt;
								songData.columns[curStrum].singer = singer.valueInt;
								songData.columns[curStrum].anim = anim.text;
								songData.columns[curStrum].missAnim = missAnim.text;

								window.close();

								numColumns = songData.columns.length;

								refreshUniqueDivisions();

								NOTE_SIZE = Std.int(480 / numColumns);
								if (NOTE_SIZE > 60)
									NOTE_SIZE = 60;

								refreshSongEndLine();
								refreshSectionLines();
								refreshSectionIcons();
								refreshStrums();
								refreshNotes(true);
								refreshSustains(true);
								refreshBPMLines();
								refreshEventLines();
							}
							vbox.add(ok);

							window = PopupWindow.CreateWithGroup(vbox);
						}
					}
					else if (sustainWidget.visible && sustainWidget.overlaps(mousePos) && sustainWidgetNote >= 0 && sustainWidgetNote < noteData.length)
					{
						sustainWidgetAdjusting = true;
						pauseUndo = true;
						sustainWidgetLimit = -1;
						for (n in noteData)
						{
							if (n != noteData[sustainWidgetNote] && n[1] == noteData[sustainWidgetNote][1] && n[0] > noteData[sustainWidgetNote][0] && (sustainWidgetLimit == -1 || n[0] < sustainWidgetLimit))
								sustainWidgetLimit = Conductor.timeFromStep(Conductor.stepFromTime(n[0]) - 1);
						}
						if (sustainWidgetLimit >= 0 && sustainWidgetLimit < noteData[sustainWidgetNote][0])
						{
							sustainWidgetAdjusting = false;
							pauseUndo = false;
						}
						else
							FlxG.sound.play(Paths.sound("ui/editors/charting/noteStretch"), 0.5);
					}
					else if (ghostNote.visible && makingNotes.filter(function(val:Float) { return val == -1; }).length == makingNotes.length)
					{
						FlxG.sound.play(Paths.sound(notePlaceSound), 0.5);
						makingNoteMouse = [ghostNote.beat * 4, ghostNote.column];
						updateReplaceTypeList();
						refreshNotes();
					}
					else if (ghostEvent.visible && makingNotes.filter(function(val:Float) { return val == -1; }).length == makingNotes.length)
					{
						FlxG.sound.play(Paths.sound("ui/editors/ClickDown"), 0.5);
						ghostEvent.x += ghostEvent.width;
						var eventParamListCopy:Dynamic = Reflect.copy(eventParamList);
						songData.events.push({time: Conductor.timeFromBeat(ghostNote.beat), beat: ghostNote.beat, type: eventTypeDropdown.value, parameters: eventParamListCopy});
						updateEventList();
						refreshEventLines();
					}
					else if (!selecting && !suspendSelection)
					{
						selecting = true;
						selectionPos = [Std.int(mousePos.x), Std.int(mousePos.y)];
						selectionBox.scale.set(1, 1);
						selectionBox.updateHitbox();
						selectionBox.visible = true;
						if (!FlxG.keys.pressed.SHIFT)
						{
							selectedNotes = [];
							refreshSelectedNotes();
						}
					}
				}
			}
		}

		if (Options.mouseJustPressed(true))
		{
			var foundNote:Note = null;
			notes.forEachAlive(function(note:Note) {
				if (note.overlaps(mousePos) && foundNote == null)
					foundNote = note;
			});

			if (foundNote != null)
			{
				if (selectedNotes.contains(foundNote))
				{
					var noteTypes:Array<String> = replaceTypeDropdown.valueList.copy();
					if (!noteTypes.contains(noteTypeInput.text.trim()))
						noteTypes.push(noteTypeInput.text.trim());

					var noteTypeOptions:Array<TopMenuOption> = [];
					for (t in noteTypes)
					{
						noteTypeOptions.push({
							label: (t.trim() == "" ? "Default" : t.trim()),
							action: function() {
								if (selectedNotes.length > 0)
								{
									for (note in selectedNotes)
									{
										var n = noteData[notes.members.indexOf(note)];

										if (t.trim() != "")
										{
											if (n.length > 3)
												n[3] = t;
											else
												n.push(t);
										}
										else if (n.length > 3)
											n.pop();
									}

									updateReplaceTypeList();
									refreshNotes();
									refreshSustains();
									refreshSelectedNotes();
								}
							}
						});
					}

					var dropdown:TopMenuDropdown = new TopMenuDropdown(FlxG.mouse.x, FlxG.mouse.y, [
						{
							label: "Change Type",
							options: noteTypeOptions
						},
						{
							label: "Delete",
							action: function() {
								selNoteBoxes.forEachAlive(function(note:NoteSelection) {
									removeNote(note.strumTime, note.column);
								});

								selectedNotes = [];
								refreshSelectedNotes();

								updateReplaceTypeList();
								refreshNotes();
								refreshSustains();
							}
						}
					]);
					dropdown.cameras = [camHUD];
					add(dropdown);
					TopMenu.busy = true;
				}
				else
				{
					removeNote(foundNote.strumTime, foundNote.column);

					updateReplaceTypeList();
					refreshNotes();
					refreshSustains();
					selectedNotes = [];
					refreshSelectedNotes();
					FlxG.sound.play(Paths.sound("ui/editors/charting/noteErase"), 0.5);
				}
			}
			else
			{
				var myEvent:Int = -1;
				eventIcons.forEachAlive(function(event:FlxSprite)
					{
						if (event.overlaps(mousePos))
							myEvent = eventIcons.members.indexOf(event);
					}
				);
				if (myEvent > -1)
				{
					var dropdown:TopMenuDropdown = new TopMenuDropdown(FlxG.mouse.x, FlxG.mouse.y, [
						{
							label: "Edit",
							action: function() {
								editEventParams(myEvent);
							}
						},
						{
							label: "Delete",
							action: function() {
								songData.events.splice(myEvent, 1);
								updateEventList();
								refreshEventLines();
								curEvent = curEvent;
							}
						}
					]);
					dropdown.cameras = [camHUD];
					add(dropdown);
					TopMenu.busy = true;
				}
				else if (allowEditingStrumline && curStrum > -1 && curStrum < strums.members.length - 1)
				{
					songData.columns.splice(curStrum, 1);

					numColumns = songData.columns.length;

					refreshUniqueDivisions();

					NOTE_SIZE = Std.int(480 / numColumns);
					if (NOTE_SIZE > 60)
						NOTE_SIZE = 60;

					refreshSongEndLine();
					refreshSectionLines();
					refreshSectionIcons();
					refreshStrums();
					refreshNotes(true);
					refreshSustains(true);
					refreshBPMLines();
					refreshEventLines();
				}
			}
		}

		if (!autosavePaused && !isSM)
		{
			timeSinceLastAutosave += elapsed;
			if (Options.options.autosaveSecs > 0 && timeSinceLastAutosave >= Options.options.autosaveSecs)
			{
				var data:String = Json.stringify({song: prepareChartNoteData(songData, noteData)});

				File.saveContent("autosaves/" + songIdShort + ".json", data.trim());
				timeSinceLastAutosave = 0;
			}
		}

		if (tracks[0].playing)
		{
			songProgress = Math.max(0, Conductor.stepFromTime(tracks[0].time + songData.offset));
			if (tracks.length > 1)
			{
				for (i in 1...tracks.length)
				{
					if (tracks[0].time - songData.tracks[i][2] < tracks[i].length && Math.abs((tracks[0].time - songData.tracks[i][2]) - tracks[i].time) > 50)
						tracks[i].time = tracks[0].time - songData.tracks[i][2];
				}
			}

			var tickColumns:Array<Bool> = [];
			for (i in 0...numColumns)
			{
				if (noteTickEnabled)
				{
					if (noteTick < 0 || songData.columns[i].division == noteTick)
						tickColumns.push(true);
					else
						tickColumns.push(false);
				}
				else
					tickColumns.push(false);
			}
			var hasTicked:Bool = false;
			for (note in noteTicks)
			{
				if (tracks[0].time + songData.offset >= note[0])
				{
					if (tickColumns[note[1]] && !note[3])
					{
						if (!hasTicked && (noteTickFilter.length <= 0 || noteTickFilter.contains(note[2])))
						{
							FlxG.sound.play(Paths.sound("ui/editors/charting/noteTick"), noteTickVolume);
							hasTicked = true;
						}
						note[3] = true;
					}
				}
			}
		}
		else if (FlxG.mouse.wheel != 0 && !DropdownMenu.isOneActive)
		{
			var scroll:Float = FlxG.mouse.wheel;
			if (downscroll)
				scroll = -scroll;
			if (songProgress - scroll >= 0 && songProgress - scroll <= Conductor.stepFromTime(tracks[0].length + songData.offset))
			{
				songProgress -= scroll * (16 / snap);
				songProgress = Math.max(0, Math.min(Conductor.stepFromTime(tracks[0].length + songData.offset), songProgress));
				snapSongProgress();
			}
		}
		curSection = secFromStep(Std.int(Math.floor(songProgress)));

		Conductor.songPosition = Conductor.timeFromStep(songProgress);
		camFollow.y = Std.int((songProgress * NOTE_SIZE * zoom) + (FlxG.height * 0.35));
		if (downscroll)
			camFollow.y = -camFollow.y;

		super.update(elapsed);

		if (songProgress >= songData.notes[songData.notes.length-1].lastStep)
			makeNewSection();

		if (FlxG.keys.justPressed.SPACE && !suspendControls && !DropdownMenu.isOneActive)
		{
			if (tracks[0].playing)
			{
				for (t in tracks)
					t.stop();
				snapSongProgress();
			}
			else
			{
				tracks[0].onComplete = function() {
					for (t in tracks)
						t.stop();
					songProgress = Conductor.stepFromTime(tracks[0].length) - (16 / snap);
					snapSongProgress();
				};
				for (t in tracks)
					t.play(true, Math.max(0, Conductor.timeFromStep(songProgress) - songData.offset - songData.tracks[tracks.indexOf(t)][2]));
				noteTicks = [];
				for (note in noteData)
				{
					var type:String = "";
					if (note.length > 3)
						type = note[3];
					if (type.trim() == "")
					{
						var sec:SectionData = songData.notes[secFromTime(note[0])];
						if (sec.defaultNotetypes[songData.columns[note[1]].division] != "")
							type = sec.defaultNotetypes[songData.columns[note[1]].division];
					}
					if (note[0] >= tracks[0].time + songData.offset)
						noteTicks.push([note[0], note[1], type, false]);
				}
			}
		}

		if (FlxG.keys.justPressed.ENTER && !suspendControls && !DropdownMenu.isOneActive)
		{
			if (!tracks[0].playing)
			{
				snapSongProgress();
				tracks[0].onComplete = function() {
					for (t in tracks)
						t.stop();
					snapSongProgress();
				};
				for (t in tracks)
					t.play(true, Math.max(0, Conductor.timeFromStep(songProgress) - songData.offset - songData.tracks[tracks.indexOf(t)][2]), Math.max(0, Conductor.timeFromStep(songProgress + (16 / snap)) - songData.offset));
			}
		}

		if (!tracks[0].playing && !DropdownMenu.isOneActive && !Stepper.isOneActive && makingNoteMouse[0] < 0)
		{
			var pressedArray:Array<Bool> = [FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT, FlxG.keys.justPressed.NINE, FlxG.keys.justPressed.ZERO];
			var releasedArray:Array<Bool> = [FlxG.keys.justReleased.ONE, FlxG.keys.justReleased.TWO, FlxG.keys.justReleased.THREE, FlxG.keys.justReleased.FOUR, FlxG.keys.justReleased.FIVE, FlxG.keys.justReleased.SIX, FlxG.keys.justReleased.SEVEN, FlxG.keys.justReleased.EIGHT, FlxG.keys.justReleased.NINE, FlxG.keys.justReleased.ZERO];
			if (pressedArray.length > numColumns)
			{
				pressedArray.resize(numColumns);
				releasedArray.resize(numColumns);
			}
			for (i in 0...pressedArray.length)
			{
				if (pressedArray[i] && !suspendControls && makingNotes[i] <= -1)
				{
					var poppers:Array<Array<Dynamic>> = [];
					var doRefreshSustains:Bool = false;
					for (note in noteData)
					{
						if (Math.round(Conductor.stepFromTime(note[0])*100)/100 == Math.round(songProgress*100)/100 && note[1] == i)
							poppers.push(note);
					}
					if (poppers.length > 0)
					{
						for (p in poppers)
							noteData.remove(p);
						FlxG.sound.play(Paths.sound("ui/editors/charting/noteErase"), 0.5);
					}
					else
					{
						makingNotes[i] = songProgress;
						FlxG.sound.play(Paths.sound(notePlaceSound), 0.5);
					}
					updateReplaceTypeList();
					refreshNotes();
					refreshSustains();
				}
				if (releasedArray[i] && makingNotes[i] > -1)
				{
					placeNote(makingNotes[i], songProgress, i);
					makingNotes[i] = -1;
					refreshMakingSustains();
				}
			}
		}

		if (prevSongProgress != songProgress)
		{
			if (makingNotes.filter(function(val:Float) { return val == -1; }).length != makingNotes.length)
				refreshMakingSustains();
		}

		if (prevSection != curSection)
			refreshGhostNotes();

		refreshTimeText();
		prevSongProgress = songProgress;
		prevSection = curSection;

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}

	override public function beatHit()
	{
		super.beatHit();

		if (beatTickEnabled && tracks[0].playing)
		{
			if (beatTickBarLength > 0 && curBeat % beatTickBarLength == 0)
				FlxG.sound.play(Paths.sound("ui/editors/charting/metronome1"), beatTickVolume);
			else
				FlxG.sound.play(Paths.sound("ui/editors/charting/metronome2"), beatTickVolume);
		}
	}

	function refreshCharacters()
	{
		var charCount:Int = 2;
		while (Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
			charCount++;

		if (songData.notetypeSingers.length > charCount)
			songData.notetypeSingers.resize(charCount);
		else if (songData.notetypeSingers.length < charCount)
		{
			while (songData.notetypeSingers.length < charCount)
				songData.notetypeSingers.push([]);
		}

		if (sectionCamOnStepper != null)
			sectionCamOnStepper.maxVal = charCount;
		if (allCamsOnStepper != null)
			allCamsOnStepper.maxVal = charCount;
	}

	function refreshTracks()
	{
		if (isSM)
		{
			FlxG.sound.cache(Paths.smSong(songId, smData.ogg));
			var newTrack:FlxSound = new FlxSound().loadEmbedded(Paths.smSong(songId, smData.ogg));
			newTrack.makeEvent = false;
			FlxG.sound.list.add(newTrack);
			tracks.push(newTrack);

			return;
		}

		if (trackList.length <= 0)
			return;

		if (tracks.length > songData.tracks.length)
		{
			while (tracks.length > songData.tracks.length)
			{
				var t = tracks.pop();
				t.destroy();
			}
		}

		if (tracks.length < songData.tracks.length)
		{
			while (tracks.length < songData.tracks.length)
			{
				var t:Array<Dynamic> = songData.tracks[tracks.length];

				var newTrack:FlxSound = new FlxSound();
				newTrack.makeEvent = false;
				if (trackList.filter(function(a) return a.toLowerCase() == t[0].toLowerCase()).length <= 0)
					t[0] = trackList[0];
				newTrack.loadEmbedded(Paths.song(songId, t[0]));
				if (t[1] > 0)
					newTrack.volume = 0.5;
				else
					newTrack.volume = 0.2;
				FlxG.sound.list.add(newTrack);
				tracks.push(newTrack);
			}
		}

		refreshSongEndLine();
		refreshWaveform();
	}

	public function correctTrackPositions()
	{
		if (tracks[0].playing)
		{
			for (t in tracks)
				t.time = Math.max(0, Conductor.timeFromStep(songProgress) - songData.offset - songData.tracks[tracks.indexOf(t)][2]);
		}
	}

	function correctTrackPitch()
	{
		for (t in tracks)
			t.pitch = playbackRate;
	}

	function refreshWaveform()
	{
		var waveCount:Int = 0;
		if (waveformVisible)
		{
			for (i in 0...songData.bpmMap.length)
			{
				var startBeat:Float = songData.bpmMap[i][0];
				var endBeat:Float = Conductor.beatFromTime(tracks[0].length);
				if (i < songData.bpmMap.length-1)
					endBeat = songData.bpmMap[i+1][0];
				waveCount += Std.int(Math.ceil((endBeat - startBeat) / 16));
			}

			var divPositions:Array<Int> = [];
			var divWaveforms:Array<Float> = [];
			var lastDiv:Int = songData.columns[0].division;
			var divW:Float = 0;
			for (i in 0...songData.columns.length)
			{
				if (songData.columns[i].division != lastDiv)
				{
					divPositions.push(i);
					divWaveforms.push(divW);
					divW = 0;
				}
				divW += NOTE_SIZE;
				lastDiv = songData.columns[i].division;
			}
			divWaveforms.push(divW);

			waveCount *= divWaveforms.length;
			if (waveformTrack.length < divWaveforms.length)
			{
				while (waveformTrack.length < divWaveforms.length)
					waveformTrack.push(0);
			}

			while (waveform.members.length < waveCount)
			{
				var wave:FlxSprite = new FlxSprite();
				wave.antialiasing = false;
				wave.active = false;
				wave.color = FlxColor.CYAN;
				wave.alpha = 0.6;
				waveform.add(wave);
			}

			if (waveform.members.length > waveCount)
			{
				for (i in waveCount...waveform.members.length)
					waveform.members[i].visible = false;
			}

			var waveSprite:Int = 0;
			var xx:Float = strums.members[0].x;
			var _t:Int = 0;
			for (wav in divWaveforms)
			{
				for (i in 0...songData.bpmMap.length)
				{
					var startBeat:Float = songData.bpmMap[i][0];
					var endBeat:Float = Conductor.beatFromTime(tracks[0].length);
					if (i < songData.bpmMap.length-1)
						endBeat = songData.bpmMap[i+1][0];
					var len:Float = endBeat - startBeat;
					var waveSubCount:Int = Std.int(Math.ceil(len / 16));
					var curBeat:Float = startBeat;
					for (j in 0...waveSubCount)
					{
						var _y:Float = NOTE_SIZE * zoom * curBeat * 4;
						var h:Float = NOTE_SIZE * zoom * Math.min(64, (endBeat - curBeat) * 4);
						var start:Float = Conductor.timeFromBeat(curBeat) - songData.offset - songData.tracks[waveformTrack[_t]][2];
						var end:Float = Conductor.timeFromBeat(Math.min(curBeat + 16, endBeat)) - songData.offset - songData.tracks[waveformTrack[_t]][2];

						var wave:FlxSprite = waveform.members[waveSprite];
						wave.visible = true;
						wave.setPosition(xx, downscroll ? -_y : _y);
						wave.pixels = Waveform.generateWaveform(tracks[waveformTrack[_t]], start, end, Std.int(wav), Std.int(h));
						if (downscroll)
						{
							wave.flipY = true;
							wave.y -= h;
						}
						else
							wave.flipY = false;
						curBeat += 16;
						waveSprite++;
					}
				}
				xx += wav;
				_t++;
			}
		}
		else
			waveform.forEachAlive(function(s:FlxSprite) { s.visible = false; });
	}

	function refreshSongEndLine()
	{
		if (tracks.length > 0)
		{
			if (beatLines != null)
			{
				beatLines.forEachAlive(function(line:FlxSprite)
				{
					line.kill();
					line.destroy();
				});
				beatLines.clear();

				var beats:Int = Std.int(Math.floor(Conductor.beatFromTime(tracks[0].length)));
				for (i in 0...beats)
				{
					var line:FlxSprite = new FlxSprite(songEndLine.x, i * NOTE_SIZE * zoom * 4).makeGraphic(NOTE_SIZE * numColumns, 1, FlxColor.GRAY);
					if (downscroll)
						line.y = -line.y;
					beatLines.add(line);
				}
			}

			if (songEndLine != null)
			{
				songEndLine.y = Std.int(NOTE_SIZE * zoom * Conductor.stepFromTime(tracks[0].length + songData.offset));
				if (downscroll)
					songEndLine.y = -songEndLine.y;
			}
		}
	}

	function refreshSectionLines()
	{
		var divPositions:Array<Int> = [0];
		var lastDiv:Int = songData.columns[0].division;
		for (i in 0...songData.columns.length)
		{
			if (songData.columns[i].division != lastDiv)
				divPositions.push(i);
			lastDiv = songData.columns[i].division;
		}
		divPositions.push(songData.columns.length);

		var ticks:Array<Array<Int>> = [];

		var yy:Int = 0;
		for (i in 0...songData.notes.length)
		{
			var xx:Int = Std.int( (FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) );
			var ww:Int = Std.int(NOTE_SIZE * numColumns);
			if (downscroll)
				ticks.push([xx, -yy, ww, 1]);
			else
				ticks.push([xx, yy, ww, 1]);
			for (j in 0...numColumns + 1)
			{
				var tick:Array<Int> = [xx + (j * NOTE_SIZE), yy - 10, 1];
				if (divPositions.contains(j))
					tick.push(Std.int(NOTE_SIZE * zoom * songData.notes[i].lengthInSteps) + 10);
				else
					tick.push(20);
				if (downscroll)
				{
					tick[1] = -tick[1];
					tick[1] -= tick[3];
				}
				ticks.push(tick);
			}

			yy += Std.int(NOTE_SIZE * zoom * songData.notes[i].lengthInSteps);
			if (i == songData.notes.length - 1)
			{
				if (downscroll)
					ticks.push([xx, -yy, ww, 1]);
				else
					ticks.push([xx, yy, ww, 1]);
			}
		}

		if (sectionLines.members.length < ticks.length)
		{
			while (sectionLines.members.length < ticks.length)
			{
				var s:FlxSprite = new FlxSprite(0, 0).makeGraphic(2, 2, FlxColor.WHITE);
				s.antialiasing = false;
				s.active = false;
				sectionLines.add(s);
			}
		}

		if (sectionLines.members.length > ticks.length)
		{
			for (i in ticks.length...sectionLines.members.length)
				sectionLines.members[i].visible = false;
		}

		for (i in 0...ticks.length)
		{
			sectionLines.members[i].visible = true;
			sectionLines.members[i].setPosition(ticks[i][0], ticks[i][1]);
			sectionLines.members[i].setGraphicSize(ticks[i][2], ticks[i][3]);
			sectionLines.members[i].updateHitbox();
		}
	}

	function refreshSectionIcons(?whichSec:Int = -1)
	{
		while (sectionIcons.members.length < songData.notes.length)
		{
			var icon:HealthIcon = new HealthIcon(0, 0, "none");
			icon.sc.set(0.5, 0.5);
			icon.updateHitbox();
			sectionIcons.add(icon);
		}

		var yy:Int = 0;

		var allSingerTypes:Array<String> = [];
		for (s in songData.notetypeSingers)
		{
			for (ss in s)
				allSingerTypes.push(ss);
		}

		var iconNames:Array<String> = [];
		var iconTypes:Array<String> = [];
		for (i in 0...songData.notetypeSingers.length)
		{
			var iconName:String = TitleState.defaultVariables.icon;
			if (Paths.jsonExists("characters/" + Reflect.field(songData, "player" + Std.string(i+1))))
				iconName = Character.parseCharacter(Reflect.field(songData, "player" + Std.string(i+1))).icon;
			if (iconName == null || iconName == "")
				iconName = Reflect.field(songData, "player" + Std.string(i+1));
			iconNames.push(iconName);

			var iconType:String = "";
			for (s in songData.notetypeSingers[i])
			{
				if (allSingerTypes.indexOf(s) == allSingerTypes.lastIndexOf(s))
					iconType = s;
			}
			iconTypes.push(iconType);
		}
		var xx:Int = Std.int( (FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) );
		var ww:Int = Std.int(NOTE_SIZE * numColumns);

		for (i in 0...sectionIcons.members.length)
		{
			if (i >= songData.notes.length)
				sectionIcons.members[i].visible = false;
			else if (whichSec < 0 || whichSec == i)
			{
				var iconName:String = iconNames[songData.notes[i].camOn];
				if (songData.notetypeOverridesCam)
				{
					var singerColumn:Int = 0;
					for (j in 0...songData.columns.length)
					{
						if (songData.columns[j].singer == songData.notes[i].camOn)
						{
							singerColumn = j;
							break;
						}
					}

					if (songData.notes[i].defaultNotetypes[songData.columns[singerColumn].division] != "" && iconTypes.contains(songData.notes[i].defaultNotetypes[songData.columns[singerColumn].division]))
						iconName = iconNames[iconTypes.indexOf(songData.notes[i].defaultNotetypes[songData.columns[singerColumn].division])];
				}
				var icon:HealthIcon = sectionIcons.members[i];
				icon.visible = true;
				icon.setPosition(xx, yy);
				if (icon.id != iconName)
				{
					icon.reloadIcon(iconName);
					icon.sc.set(0.5, 0.5);
					icon.updateHitbox();
				}
				if (downscroll)
					icon.y = -icon.y;
				icon.y -= icon.height / 2;

				if (songData.notes[i].camOn == 0)
					icon.x += ww;
				else
					icon.x -= icon.width;
				sectionIcons.add(icon);
			}
			if (i < songData.notes.length)
				yy += Std.int(NOTE_SIZE * zoom * songData.notes[i].lengthInSteps);
		}
	}

	function refreshStrums()
	{
		strums.forEachAlive(function(strum:FlxSprite)
		{
			if (strum != addStrumButton)
			{
				strum.kill();
				strum.destroy();
			}
		});
		strums.clear();

		var xx:Int = Std.int( (FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) );
		for (i in 0...numColumns)
		{
			var strum:FlxSprite = new FlxSprite(xx + (i * NOTE_SIZE), Std.int(FlxG.height / 2));
			var noteType:NoteskinTypedef = Noteskins.getData(Noteskins.noteskinName, noteTypeFromColumn(i));
			Noteskins.addSlotAnims(strum, noteType, strumColumns[i]);
			strum.animation.play("static");
			strum.updateHitbox();
			strum.setGraphicSize(NOTE_SIZE);
			strum.updateHitbox();
			strum.y -= strum.height / 2;
			if (downscroll)
				strum.y += FlxG.height * 0.35;
			else
				strum.y -= FlxG.height * 0.35;
			strum.alpha = 0.5;
			strum.angle = noteType.slots[strumColumns[i] % noteType.slots.length].unbakedAngle;
			strum.antialiasing = noteType.antialias;
			strums.add(strum);
		}

		addStrumButton.x = xx + (strums.members.length * NOTE_SIZE);
		addStrumButton.y = strums.members[0].y;
		addStrumButton.setGraphicSize(NOTE_SIZE);
		addStrumButton.updateHitbox();
		addStrumButton.visible = allowEditingStrumline;
		addStrumButton.alpha = 0.5;
		strums.add(addStrumButton);
	}

	function refreshBPMLines()
	{
		bpmLines.forEachAlive(function(line:FlxSprite)
		{
			line.kill();
			line.destroy();
		});
		bpmLines.clear();

		var xx:Int = Std.int( (FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) );
		var ww:Int = Std.int(NOTE_SIZE * numColumns);

		var takenYs:Array<Int> = [];
		for (i in 0...songData.bpmMap.length)
		{
			var yy:Int = Std.int(songData.bpmMap[i][0] * zoom * 4 * NOTE_SIZE);
			var line:FlxSprite = new FlxSprite(xx, yy).makeGraphic(ww, 1, FlxColor.BLUE);
			if (downscroll)
				line.y = -line.y;
			bpmLines.add(line);
			var text:FlxText = new FlxText(0, line.y - 20, xx - 5, "BPM: " + Std.string(songData.bpmMap[i][1]), 12);
			text.font = "VCR OSD Mono";
			text.alignment = RIGHT;
			bpmLines.add(text);
			takenYs.push(yy);
		}

		for (i in 0...songData.scrollSpeeds.length)
		{
			var yy:Int = Std.int(songData.scrollSpeeds[i][0] * 4 * zoom * NOTE_SIZE);
			var ww2:Int = ww;
			if (takenYs.contains(yy))
				ww2 = Std.int(ww2 / 2);
			var line:FlxSprite = new FlxSprite(xx, yy).makeGraphic(ww2, 1, FlxColor.RED);
			if (downscroll)
				line.y = -line.y;
			bpmLines.add(line);
			var text:FlxText = new FlxText(0, line.y, xx - 5, "Speed: " + Std.string(songData.scrollSpeeds[i][1]), 12);
			text.font = "VCR OSD Mono";
			text.alignment = RIGHT;
			bpmLines.add(text);
		}
	}

	function refreshEventLines()
	{
		eventLines.forEachAlive(function(line:FlxSprite)
		{
			line.kill();
			line.destroy();
		});
		eventLines.clear();

		eventIcons.forEachAlive(function(event:FlxSprite)
		{
			event.kill();
			event.destroy();
		});
		eventIcons.clear();

		var doneBeats:Array<Float> = [];
		var doneEvents:Array<FlxSprite> = [];

		var xx:Int = Std.int( (FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) );
		var ww:Int = Std.int(NOTE_SIZE * numColumns);

		for (i in 0...songData.events.length)
		{
			var yy:Int = Std.int(songData.events[i].beat * 4 * zoom * NOTE_SIZE);
			var line:FlxSprite = new FlxSprite(xx, yy).makeGraphic(ww, 1, FlxColor.LIME);
			if (downscroll)
				line.y = -line.y;
			eventLines.add(line);

			var event:FlxSprite = new FlxSprite(xx + ww + 1, line.y);
			var eventIcon:String = "eventIcon";
			if (eventTypeParams.exists(songData.events[i].type) && eventTypeParams[songData.events[i].type].icon != null)
				eventIcon = eventTypeParams[songData.events[i].type].icon;
			event.frames = Paths.tiles("ui/editors/" + eventIcon, 1, 3);
			event.animation.add("idle", [0]);
			event.animation.add("hovered", [1]);
			event.animation.add("selected", [2]);
			event.updateHitbox();
			event.y -= Std.int(event.height / 2);
			if (i == curEvent)
				event.animation.play("selected");
			if (doneBeats.contains(songData.events[i].beat))
			{
				var ii:Int = doneBeats.indexOf(songData.events[i].beat);
				event.x = doneEvents[ii].x + doneEvents[ii].width;
				doneEvents[ii] = event;
			}
			else
			{
				doneBeats.push(songData.events[i].beat);
				doneEvents.push(event);
			}
			eventIcons.add(event);
		}
	}

	function refreshNotes(?forceUpdate:Bool = false)
	{
		var totalNotes:Int = noteData.length;
		if (makingNoteMouse[0] > -1)
			totalNotes++;
		for (i in 0...makingNotes.length)
		{
			if (makingNotes[i] > -1)
				totalNotes++;
		}

		while (notes.members.length > totalNotes)
		{
			var popper:Note = notes.members[notes.members.length-1];
			notes.remove(popper, true);
			if (selectedNotes.contains(popper))
				selectedNotes.remove(popper);
			popper.kill();
			popper.destroy();
		}

		while (notes.members.length < totalNotes)
		{
			var newNote:Note = new Note(0, 0, "", songData.noteType[0]);
			notes.add(newNote);
		}

		for (i in 0...noteData.length)
		{
			var updateThis:Bool = forceUpdate;
			if (notes.members[i].beat == 0 && notes.members[i].column == 0)		// Since these are the default values, they have to be hardcoded to always update a note that has them
				updateThis = true;

			if (notes.members[i].beat != Conductor.beatFromTime(noteData[i][0]))
			{
				notes.members[i].strumTime = noteData[i][0];
				notes.members[i].beat = Conductor.beatFromTime(noteData[i][0]);
				updateThis = true;
			}

			if (notes.members[i].column != noteData[i][1] % numColumns)
			{
				notes.members[i].column = Std.int(noteData[i][1] % numColumns);
				notes.members[i].strumColumn = strumColumns[notes.members[i].column];
				updateThis = true;
			}

			var noteType:String = "";
			if (noteData[i].length > 3)
				noteType = noteData[i][3];
			if (notes.members[i].noteType != noteType)
			{
				notes.members[i].noteType = noteType;
				updateThis = true;
			}

			var noteskinType:String = noteTypeFromColumn(notes.members[i].column);
			if (notes.members[i].noteskinType != noteskinType)
				updateThis = true;

			if (updateThis)
			{
				notes.members[i].updateTypeData();
				notes.members[i].onNotetypeChanged(noteskinType);

				notes.members[i].setGraphicSize(NOTE_SIZE);
				notes.members[i].updateHitbox();
				notes.members[i].x = Std.int((FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) + (NOTE_SIZE * notes.members[i].column));
				notes.members[i].y = Std.int(NOTE_SIZE * zoom * Conductor.stepFromTime(noteData[i][0]));
				if (downscroll)
					notes.members[i].y = -notes.members[i].y;
				notes.members[i].y -= notes.members[i].height / 2;
			}
		}

		if (totalNotes > noteData.length)
		{
			var j:Int = noteData.length;
			for (i in 0...makingNotes.length)
			{
				if (makingNotes[i] > -1)
				{
					notes.members[j].strumTime = Conductor.timeFromStep(makingNotes[i]);
					notes.members[j].beat = makingNotes[i] / 4;
					notes.members[j].column = i;
					notes.members[j].strumColumn = strumColumns[i];

					var noteType:String = noteTypeInput.text;
					notes.members[j].noteType = noteType;
					notes.members[j].updateTypeData();

					notes.members[j].onNotetypeChanged(noteTypeFromColumn(i));

					notes.members[j].setGraphicSize(NOTE_SIZE);
					notes.members[j].updateHitbox();
					notes.members[j].x = Std.int((FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) + (NOTE_SIZE * i));
					notes.members[j].y = Std.int(NOTE_SIZE * zoom * makingNotes[i]);
					if (downscroll)
						notes.members[j].y = -notes.members[j].y;
					notes.members[j].y -= notes.members[j].height / 2;
					j++;
				}
			}

			if (makingNoteMouse[0] > -1)
			{
				notes.members[j].strumTime = Conductor.timeFromStep(makingNoteMouse[0]);
				notes.members[j].beat = makingNoteMouse[0] / 4;
				notes.members[j].column = Std.int(makingNoteMouse[1]);
				notes.members[j].strumColumn = strumColumns[notes.members[j].column];

				var noteType:String = noteTypeInput.text;
				notes.members[j].noteType = noteType;
				notes.members[j].updateTypeData();

				notes.members[j].onNotetypeChanged(noteTypeFromColumn(notes.members[j].column));

				notes.members[j].setGraphicSize(NOTE_SIZE);
				notes.members[j].updateHitbox();
				notes.members[j].x = Std.int((FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) + (NOTE_SIZE * makingNoteMouse[1]));
				notes.members[j].y = Std.int(NOTE_SIZE * zoom * makingNoteMouse[0]);
				if (downscroll)
					notes.members[j].y = -notes.members[j].y;
				notes.members[j].y -= notes.members[j].height / 2;
				j++;
			}
		}

		noteMinimap.refresh();
	}

	function refreshSustains(?forceUpdate:Bool = false)
	{
		while (sustains.members.length > noteData.length)
		{
			var popper:EditorSustainNote = sustains.members[sustains.members.length-1];
			sustains.remove(popper, true);
			popper.kill();
			popper.destroy();
		}

		while (sustains.members.length < noteData.length)
		{
			var newNote:EditorSustainNote = new EditorSustainNote(0, 0, 0, "", songData.noteType[0]);
			sustains.add(newNote);
		}

		for (i in 0...noteData.length)
		{
			var updateThis:Bool = forceUpdate;
			if (sustains.members[i].beat == 0 && sustains.members[i].column == 0)		// Since these are the default values, they have to be hardcoded to always update a note that has them
				updateThis = true;

			if (sustains.members[i].beat != Conductor.beatFromTime(noteData[i][0]))
			{
				sustains.members[i].strumTime = noteData[i][0];
				sustains.members[i].beat = Conductor.beatFromTime(noteData[i][0]);
				updateThis = true;
			}

			if (sustains.members[i].sustainLength != noteData[i][2])
			{
				sustains.members[i].sustainLength = noteData[i][2];
				updateThis = true;
			}

			if (sustains.members[i].endBeat != Conductor.beatFromTime(noteData[i][0] + noteData[i][2]))
			{
				sustains.members[i].endBeat = Conductor.beatFromTime(noteData[i][0] + noteData[i][2]);
				updateThis = true;
			}

			if (sustains.members[i].column != noteData[i][1] % numColumns)
			{
				sustains.members[i].column = Std.int(noteData[i][1] % numColumns);
				sustains.members[i].strumColumn = strumColumns[sustains.members[i].column];
				updateThis = true;
			}
			sustains.members[i].drawScale = strums.members[sustains.members[i].column].scale.x;

			var noteType:String = "";
			if (noteData[i].length > 3)
				noteType = noteData[i][3];
			if (sustains.members[i].noteType != noteType)
			{
				sustains.members[i].noteType = noteType;
				updateThis = true;
			}

			var noteskinType:String = noteTypeFromColumn(sustains.members[i].column);
			if (sustains.members[i].noteskinType != noteskinType)
			{
				sustains.members[i].noteskinType = noteskinType;
				updateThis = true;
			}

			if (updateThis)
				sustains.members[i].refreshPosition(zoom, downscroll);
		}
	}

	function repositionNotes()
	{
		notes.forEachAlive(function(note:Note)
		{
			note.strumTime = Conductor.timeFromBeat(note.beat);
			note.y = Std.int(NOTE_SIZE * zoom * note.beat * 4);
			if (downscroll)
				note.y = -note.y;
			note.y -= note.height / 2;
		});

		noteMinimap.refresh();
	}

	function repositionSustains()
	{
		sustains.forEachAlive(function(note:EditorSustainNote)
		{
			note.strumTime = Conductor.timeFromBeat(note.beat);
			note.sustainLength = Conductor.timeFromBeat(note.endBeat) - note.strumTime;
			note.refreshPosition(zoom, downscroll);
		});
	}

	function refreshMakingSustains()
	{
		if (makingSustains.members.length < makingNotes.length + 1)
		{
			for (i in makingSustains.members.length...makingNotes.length + 1)
			{
				var newNote:EditorSustainNote = new EditorSustainNote(0, 0, 0);
				makingSustains.add(newNote);
			}
		}

		for (i in 0...makingNotes.length)
		{
			if (makingNotes[i] > -1)
			{
				var start:Float = Conductor.timeFromStep(makingNotes[i]);
				var len:Float = Math.max(1, Conductor.timeFromStep(songProgress) - start);
				if (!notePlaceAllowSustains)
					len = 0;

				if (len > 1)
				{
					makingSustains.members[i].visible = true;
					makingSustains.members[i].strumColumn = strumColumns[i];
					makingSustains.members[i].drawScale = strums.members[i].scale.x;

					var noteType:String = noteTypeInput.text;
					makingSustains.members[i].noteskinType = noteTypeFromColumn(i);
					makingSustains.members[i].noteType = noteType;

					if (makingSustains.members[i].refreshVars(start, i, len))
					{
						if (makingSustains.members[i].noteDraw.sustainLength > makingSustains.members[i].sustainLength)
							FlxG.sound.play(Paths.sound("ui/editors/charting/noteShrink"), 0.5);
						else
							FlxG.sound.play(Paths.sound("ui/editors/charting/noteStretch"), 0.5);
						makingSustains.members[i].refreshPosition(zoom, downscroll);
					}
				}
				else
					makingSustains.members[i].visible = false;
			}
			else
				makingSustains.members[i].visible = false;
		}

		var makingSustainMouse:EditorSustainNote = makingSustains.members[makingSustains.members.length - 1];
		if (makingNoteMouse[0] > -1)
		{
			var start:Float = Conductor.timeFromStep(makingNoteMouse[0]);
			var len:Float = Math.max(1, ghostNote.strumTime - start);
			if (!notePlaceAllowSustains)
				len = 0;
			if (len > 1)
			{
				makingSustainMouse.visible = true;
				makingSustainMouse.strumColumn = strumColumns[Std.int(makingNoteMouse[1])];
				makingSustainMouse.drawScale = strums.members[Std.int(makingNoteMouse[1])].scale.x;

				var noteType:String = noteTypeInput.text;
				makingSustainMouse.noteskinType = noteTypeFromColumn(Std.int(makingNoteMouse[1]));
				makingSustainMouse.noteType = noteType;

				if (makingSustainMouse.refreshVars(start, Std.int(makingNoteMouse[1]), len))
				{
					if (makingSustainMouse.noteDraw.sustainLength > makingSustainMouse.sustainLength)
						FlxG.sound.play(Paths.sound("ui/editors/charting/noteShrink"), 0.5);
					else
						FlxG.sound.play(Paths.sound("ui/editors/charting/noteStretch"), 0.5);
					makingSustainMouse.refreshPosition(zoom, downscroll);
				}
			}
			else
				makingSustainMouse.visible = false;
		}
		else
			makingSustainMouse.visible = false;
	}

	function refreshGhostNotes()
	{
		ghostNotes.forEachAlive(function(note:Note)
		{
			note.kill();
			note.destroy();
		});
		ghostNotes.clear();

		if (copyLastStepper.value == 0 || tabMenu.curTabName != "Section")
			return;

		var ghostSec:Int = Std.int(curSection - copyLastStepper.value);
		if (ghostSec >= 0 && ghostSec < songData.notes.length)
		{
			var sec:SectionData = songData.notes[ghostSec];
			var curSec:SectionData = songData.notes[curSection];
			for (note in noteData)
			{
				if (timeInSec(note[0], ghostSec))
				{
					var noteType:String = "";
					if (note.length > 3)
						noteType = note[3];
					var column:Int = getColumn(getColumn(note[1], ghostSec), curSection);
					if (maintainSidesCheckbox.checked)
						column = note[1];
					var newNote:Note = new Note(note[0], column, noteType, noteTypeFromColumn(column));
					newNote.setGraphicSize(NOTE_SIZE);
					newNote.updateHitbox();
					newNote.alpha = 0.5;
					newNote.x = Std.int((FlxG.width / 2) - (NOTE_SIZE * (numColumns / 2)) + (NOTE_SIZE * column));
					newNote.y = Std.int(NOTE_SIZE * zoom * (Conductor.stepFromTime(note[0]) - sec.firstStep + curSec.firstStep));
					if (downscroll)
						newNote.y = -newNote.y;
					newNote.y -= newNote.height / 2;
					ghostNotes.add(newNote);
				}
			}
		}
	}

	function refreshSelectedNotes()
	{
		selNoteBoxes.forEachAlive(function(note:NoteSelection)
		{
			note.kill();
			note.destroy();
		});
		selNoteBoxes.clear();

		for (n in selectedNotes)
			selNoteBoxes.add(new NoteSelection(n).refreshPosition(zoom, downscroll));
	}

	function refreshTimeText()
	{
		timeText.text = "Position: " + Std.string(Math.round(Conductor.songPosition) / 1000) + "/" + Std.string(tracks[0].length / 1000) +
		"\nTime: " + FlxStringUtil.formatTime(Conductor.songPosition / 1000) + "/" + FlxStringUtil.formatTime(tracks[0].length / 1000) +
		"\nCurrent Section: " + Std.string(curSection+1) + "/" + Std.string(songData.notes.length) +
		"\nCurrent Beat: " + Std.string(Math.round(songProgress / 4 * 1000) / 1000) +
		"\nCurrent Step: " + Std.string(Math.round(songProgress * 1000) / 1000) +
		"\nCurrent BPM: " + Std.string(Conductor.bpm) +
		"\n\nZoom: " + Std.string(zoom) +
		"\nSnap: " + Std.string(snap);
	}

	function refreshUniqueDivisions()
	{
		uniqueDivisions = [];
		strumColumns = [];
		var strumColumnIndex:Array<Int> = [];
		for (i in songData.columns)
		{
			if (!uniqueDivisions.contains(i.division))
			{
				uniqueDivisions.push(i.division);
				strumColumnIndex.push(0);
			}
		}
		for (i in songData.columns)
		{
			strumColumns.push(strumColumnIndex[i.division]);
			strumColumnIndex[i.division]++;
		}

		for (s in songData.notes)
		{
			if (s.defaultNotetypes == null)
				s.defaultNotetypes = [];
			if (s.defaultNotetypes.length > uniqueDivisions.length)
				s.defaultNotetypes.resize(uniqueDivisions.length);
			if (s.defaultNotetypes.length < uniqueDivisions.length)
			{
				while (s.defaultNotetypes.length < uniqueDivisions.length)
					s.defaultNotetypes.push("");
			}
		}

		if (defaultNotetypesVbox != null)
			refreshDefaultNoteInputs();
	}

	function fixColumnDivisionNames()
	{
		if (songData.columnDivisionNames.length > uniqueDivisions.length)
			songData.columnDivisionNames.resize(uniqueDivisions.length);

		if (songData.columnDivisionNames.length < uniqueDivisions.length)
		{
			while (songData.columnDivisionNames.length < uniqueDivisions.length)
			{
				if (songData.columnDivisionNames.length < 2)
					songData.columnDivisionNames.push("#freeplay.sandbox.side." + Std.string(songData.columnDivisionNames.length));
				else
					songData.columnDivisionNames.push("Singer " + Std.string(songData.columnDivisionNames.length + 1));
			}
		}
	}

	function refreshDefaultNoteInputs()
	{
		defaultNotetypesVbox.forEachAlive(function(item:FlxSprite) {
			item.kill();
			item.destroy();
		});
		defaultNotetypesVbox.clear();

		var noteTypeList:Array<String> = Paths.listFilesSub("data/notetypes/", ".json");
		noteTypeList.remove("default");
		noteTypeList.unshift("");

		for (i in 0...uniqueDivisions.length)
		{
			var defaultNotetypeLabel:Label = new Label("Default Notetype (" + Lang.get(songData.columnDivisionNames[i]) + "):");
			defaultNotetypesVbox.add(defaultNotetypeLabel);

			var defaultNotetypeInput:InputText = new InputText(0, 0);
			defaultNotetypeInput.condition = function() { return songData.notes[curSection].defaultNotetypes[i]; }
			defaultNotetypeInput.focusGained = function() { suspendControls = true; }
			defaultNotetypeInput.focusLost = function() {
				songData.notes[curSection].defaultNotetypes[i] = defaultNotetypeInput.text;
				refreshSectionIcons(curSection);
				suspendControls = false;
			}
			defaultNotetypeInput.infoText = "The note type that notes on the " + Lang.get(songData.columnDivisionNames[i]) + " side of this section should use if the note doesn't have a unique type of it's own.";
			defaultNotetypesVbox.add(defaultNotetypeInput);

			var defaultNotetypeDropdown:DropdownMenu = new DropdownMenu(0, 0, noteTypeList[0], noteTypeList, "Default", true);
			defaultNotetypeDropdown.valueList = noteTypeList;
			defaultNotetypeDropdown.onChanged = function() {
				songData.notes[curSection].defaultNotetypes[i] = defaultNotetypeDropdown.value;
				refreshSectionIcons(curSection);
			}
			defaultNotetypeDropdown.infoText = "Select a note type from this list to automatically put it in the above box.";
			defaultNotetypesVbox.add(defaultNotetypeDropdown);
		}

		sectionTab.repositionAll();
	}

	function noteTypeFromColumn(column:Int):String
	{
		var ind:Int = uniqueDivisions.indexOf(songData.columns[column].division);
		if (ind > -1 && ind < songData.noteType.length)
			return songData.noteType[ind];
		return songData.noteType[0];
	}

	function placeNote(start:Float, end:Float, col:Int)
	{
		var newNote:Array<Dynamic> = [Conductor.timeFromStep(start), col, Math.max(0, Conductor.timeFromStep(end) - Conductor.timeFromStep(start))];
		if (!notePlaceAllowSustains)
			newNote[2] = 0;
		if (noteTypeInput.text != null && noteTypeInput.text.trim() != "")
			newNote.push(noteTypeInput.text);

		// There are two cases that need to be accounted for: The note may be a sustain intersected by another note, or the note may be intersecting another sustain
		// In either case, we need to shorten the intersected sustain note
		for (n in noteData)
		{
			if (n[1] == newNote[1])
			{
				if (n[2] > 0 && newNote[0] > n[0] && newNote[0] <= n[0] + n[2])
				{
					if (Conductor.beatFromTime(newNote[0]) - Conductor.beatFromTime(n[0]) < 0.125)
						n[2] = 0;
					else
						n[2] = Conductor.timeFromBeat(Conductor.beatFromTime(newNote[0]) - 0.125) - n[0];
				}
				else if (newNote[2] > 0 && n[0] > newNote[0] && n[0] <= newNote[0] + newNote[2])
				{
					if (Conductor.beatFromTime(n[0]) - Conductor.beatFromTime(newNote[0]) < 0.125)
						newNote[2] = 0;
					else
						newNote[2] = Conductor.timeFromBeat(Conductor.beatFromTime(n[0]) - 0.125) - newNote[0];
				}
			}
		}

		noteData.push(newNote);
		updateReplaceTypeList();
		refreshNotes();
		refreshSustains();
		if (newNote[2] > 0)
			FlxG.sound.play(Paths.sound("ui/editors/charting/notePlace"), 0.5);
	}

	function removeNote(time:Float, col:Int)
	{
		var foundNote:Bool = false;
		for (n in noteData)
		{
			if (n[0] == time && n[1] == col && !foundNote)
			{
				foundNote = true;
				noteData.remove(n);
			}
		}
	}

	function moveSelection(cellsX:Int, cellsY:Int, cellSizeY:Float)
	{
		cellsY *= (downscroll ? -1 : 1);

		var poppers:Array<Array<Dynamic>> = [];
		var poppers2:Array<Note> = [];
		for (note in selectedNotes)
		{
			var n = noteData[notes.members.indexOf(note)];

			n[2] = Conductor.stepFromTime(n[0] + n[2]);
			n[0] = Conductor.stepFromTime(n[0]);
			n[0] += (cellsY * (cellSizeY / (NOTE_SIZE * zoom)));
			n[2] += (cellsY * (cellSizeY / (NOTE_SIZE * zoom)));
			n[0] = Conductor.timeFromStep(n[0]);
			n[2] = Conductor.timeFromStep(n[2]) - n[0];
			n[1] += cellsX;
			if (n[1] < 0 || n[1] >= numColumns)
			{
				poppers.push(n);
				poppers2.push(note);
			}
		}
		for (p in poppers)
			noteData.remove(p);
		for (p in poppers2)
			selectedNotes.remove(p);

		updateReplaceTypeList();
		refreshNotes();
		refreshSustains();
		refreshSelectedNotes();
	}

	function returnSelection()
	{
		for (n in selectedNotes)
		{
			n.x = Std.int((FlxG.width / 2) - (NOTE_SIZE * (numColumns / 2)) + (NOTE_SIZE * (n.column % numColumns)));
			n.y = Std.int(NOTE_SIZE * zoom * Conductor.stepFromTime(n.strumTime));
			if (downscroll)
				n.y = -n.y;
			n.y -= n.height / 2;
		}
		var childSustains:Array<EditorSustainNote> = [];
		for (n in selectedNotes)
			childSustains.push(sustains.members[notes.members.indexOf(n)]);
		for (s in childSustains)
			s.refreshPosition(zoom, downscroll);
		selNoteBoxes.forEachAlive(function(n:NoteSelection) {
			n.refreshPosition(zoom, downscroll);
		});
	}

	function moveSelectionOneCell(dirX:Int, dirY:Int)
	{
		var cellSizeY:Float = (NOTE_SIZE * zoom) * (16 / snap);
		var willPopNotes:Bool = false;
		var posConflict:Bool = false;
		for (note in selectedNotes)
		{
			var column:Int = note.column + dirX;
			if (column < 0 || column >= numColumns)
				willPopNotes = true;
		}
		notes.forEachAlive(function(n:Note) {
			if (!selectedNotes.contains(n))
			{
				for (note in selectedNotes)
				{
					if (Math.floor(note.x + (dirX * NOTE_SIZE)) == Math.floor(n.x) && Math.floor(note.y + (dirY * cellSizeY)) == Math.floor(n.y))
						posConflict = true;
				}
			}
		});
		if (posConflict)
		{
			suspendSelection = true;
			new Notify("Two notes cannot occupy the same space.", function() {
				returnSelection();
				suspendSelection = false;
			});
		}
		else if (willPopNotes)
		{
			suspendSelection = true;
			new Confirm("Some notes are outside valid columns and will get deleted.\nProceed?", function() {
				moveSelection(dirX, dirY, cellSizeY);
				suspendSelection = false;
			}, function() {
				returnSelection();
				suspendSelection = false;
			});
		}
		else
			moveSelection(dirX, dirY, cellSizeY);
		movingSelection = false;
	}

	public function snapSongProgress()
	{
		songProgress *= snap / 16;
		songProgress = Math.round(songProgress);
		songProgress /= snap / 16;
	}

	function stepFromSec(sec:Int):Int
	{
		if (sec >= songData.notes.length)
			return songData.notes[songData.notes.length-1].lastStep;
		return songData.notes[sec].firstStep;
	}

	function secFromStep(step:Float):Int
	{
		for (s in 0...songData.notes.length)
		{
			if (songData.notes[s].firstStep <= step && songData.notes[s].lastStep > step)
				return s;
		}

		return 0;
	}

	function secFromTime(time:Float):Int
	{
		return secFromStep(Conductor.stepFromTime(time));
	}

	function timeInSec(time:Float, sec:Int):Bool
	{
		return stepInSec(Conductor.stepFromTime(time), sec);
	}

	function stepInSec(step:Float, sec:Int):Bool
	{
		return (songData.notes[sec].firstStep <= step && songData.notes[sec].lastStep > step);
	}

	function makeNewSection()
	{
		var newSection:SectionData = {
			camOn: songData.notes[songData.notes.length-1].camOn,
			lengthInSteps: songData.notes[songData.notes.length-1].lengthInSteps,
			sectionNotes: [],
			defaultNotetypes: songData.notes[songData.notes.length-1].defaultNotetypes.copy()
		};

		songData.notes.push(newSection);
		songData = Song.timeSections(songData);
		refreshSectionLines();
		refreshSectionIcons(songData.notes.length - 1);
	}

	function jumpOneSection(direction:Int)
	{
		if (!Stepper.isOneActive)
		{
			var dir:Int = (downscroll ? -direction : direction);

			if (dir == -1)
			{
				if (tracks[0].playing || songProgress == stepFromSec(curSection))
				{
					curSection--;
					curSection = Std.int(Math.min(songData.notes.length-1, Math.max(0, curSection)));
				}
				songProgress = stepFromSec(curSection);
				if (tracks[0].playing)
				{
					for (t in tracks)
						t.time = Math.max(0, Conductor.timeFromStep(songProgress) - songData.offset - songData.tracks[tracks.indexOf(t)][2]);
				}
			}
			else
			{
				if (Conductor.timeFromStep(stepFromSec(curSection+1)) <= tracks[0].length)
				{
					curSection++;
					curSection = Std.int(Math.min(songData.notes.length, Math.max(0, curSection)));
					songProgress = stepFromSec(curSection);
					if (tracks[0].playing)
					{
						for (t in tracks)
							t.time = Math.max(0, Conductor.timeFromStep(songProgress) - songData.offset - songData.tracks[tracks.indexOf(t)][2]);
					}
				}
			}
		}
	}

	function set_hoverText(val:String):String
	{
		if (hoverTextDisplay != null)
		{
			if (val.trim() == "")
				hoverTextDisplay.visible = false;
			else
			{
				hoverTextDisplay.visible = true;
				hoverTextObject.text = val.trim();
				hoverTextBG.setGraphicSize(Std.int(hoverTextObject.width), Std.int(hoverTextObject.height));
				hoverTextBG.updateHitbox();
			}
		}
		return hoverText = val;
	}

	function updateReplaceTypeList()
	{
		var replaceTypeList:Array<String> = [""];
		if (noteTypeInput != null && !replaceTypeList.contains(noteTypeInput.text))
			replaceTypeList.push(noteTypeInput.text);

		for (n in noteData)
		{
			if (n.length > 3)
			{
				if (!replaceTypeList.contains(n[3]))
					replaceTypeList.push(n[3]);
			}
		}

		for (s in songData.notes)
		{
			for (t in s.defaultNotetypes)
			{
				if (!replaceTypeList.contains(t))
					replaceTypeList.push(t);
			}
		}

		Note.refreshNoteTypes(replaceTypeList);
		if (noteTypeInput != null && Note.noteTypes.exists(noteTypeInput.text))
		{
			if (Note.noteTypes[noteTypeInput.text].placeSound != "")
				notePlaceSound = Note.noteTypes[noteTypeInput.text].placeSound;
			else
				notePlaceSound = "ui/editors/charting/noteLay";
			notePlaceAllowSustains = !Note.noteTypes[noteTypeInput.text].noSustains;
		}
		else
		{
			notePlaceSound = "ui/editors/charting/noteLay";
			notePlaceAllowSustains = true;
		}

		if (replaceTypeDropdown != null)
		{
			replaceTypeDropdown.valueList = replaceTypeList;
			if (!replaceTypeList.contains(replaceTypeDropdown.value))
				replaceTypeDropdown.value = "";
		}
	}

	function set_curEvent(val:Int):Int
	{
		curEvent = val;

		if (curEvent >= 0)
		{
			eventTypeDropdown.value = songData.events[curEvent].type;
			var typeName:String = songData.events[curEvent].type;
			if (eventTypeNames.exists(typeName))
				typeName = eventTypeNames[typeName];
			curEventText.text = Std.string(songData.events[curEvent].beat) + " | " + typeName;

			var thisEventParams:Array<EventParams> = getEventParams(songData.events[curEvent].type);
			var time:String = "";
			var timeVal:Float = 0;
			for (p in thisEventParams)
			{
				if (p.time != null && p.time != "")
				{
					time = p.time;
					timeVal = Reflect.field(songData.events[curEvent].parameters, p.id);
				}
			}

			if (time != "")
			{
				eventTimeLine.visible = true;
				var beat:Float = songData.events[curEvent].beat;
				switch (time)
				{
					case "seconds":
						beat = Conductor.beatFromTime(Conductor.timeFromBeat(beat) + (timeVal * 1000));

					case "beats":
						beat += timeVal;

					case "steps":
						beat += timeVal / 4;
				}
				eventTimeLine.y = Std.int(beat * 4 * zoom * NOTE_SIZE);
				if (downscroll)
					eventTimeLine.y = -eventTimeLine.y;
			}
			else
				eventTimeLine.visible = false;

			updateEventParams(curEvent);
		}
		else
		{
			eventTimeLine.visible = false;
			curEventText.text = "None";
		}
		eventIcons.forEachAlive(function(event:FlxSprite)
			{
				if (eventIcons.members.indexOf(event) == curEvent)
					event.animation.play("selected");
				else
					event.animation.play("idle");
			}
		);

		return val;
	}

	function updateEventList()
	{
		ArraySort.sort(songData.events, Song.sortEvents);

		var eventList:Array<String> = [""];
		for (ev in songData.events)
			eventList.push(Std.string(ev.beat) + " | " + ev.type);
		if (curEvent >= songData.events.length)
			curEvent = songData.events.length - 1;
	}

	function getEventParams(eventId:String):Array<EventParams>
	{
		if (eventTypeParams.exists(eventId))
			return eventTypeParams[eventId].parameters;
		return [];
	}

	var dropdownSpecial:Map<String, Array<String>> = new Map<String, Array<String>>();

	function updateEventParams(?eventValues:Int = -1)
	{
		for (e in eventParams)
		{
			eventsTab.vbox.remove(e, true);
			e.kill();
			e.destroy();
		}
		eventParams = [];

		var thisEventParams:Array<EventParams> = getEventParams(eventTypeDropdown.value);
		eventParamList = {};
		var ii:Int = 0;
		eventPropertiesText.visible = (thisEventParams.length > 0);
		for (i in 0...thisEventParams.length)
		{
			var p:EventParams = thisEventParams[i];
			if (p.id == null && p.type != "label")
				p.id = Std.string(ii);
			var pValue:Dynamic = p.defaultValue;
			if (eventValues > -1 && p.type != "label")
				pValue = Reflect.field(songData.events[eventValues].parameters, p.id);

			if (p.type != "label")
				Reflect.setField(eventParamList, p.id, pValue);

			switch (p.type)
			{
				case "label":
					var newThing:FlxText = new FlxText(0, 0, 230, p.label);
					newThing.setFormat("FNF Dialogue", 18, FlxColor.WHITE, CENTER, OUTLINE, 0xFF254949);
					eventParams.push(newThing);
					ii--;

				case "checkbox":
					var newThing:Checkbox = new Checkbox(0, 0, p.label);
					if (p.infoText != null)
						newThing.infoText = p.infoText;
					newThing.checked = pValue;
					newThing.onClicked = function() { Reflect.setField(eventParamList, p.id, newThing.checked); }
					eventParams.push(newThing);

				case "dropdown":
					var str:String = pValue;
					var options:Array<String> = p.options.copy();
					if (options.contains("!players"))
					{
						var charCount:Int = 2;
						while (Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
							charCount++;
						for (i in 0...charCount)
						{
							options.insert(options.indexOf("!players"), i == 2 ? "gf" : "player" + Std.string(i + 1));
							var charName:String = Reflect.field(songData, "player" + Std.string(i + 1));
							if (characterNames.exists(charName))
								charName = characterNames[charName];
							eventParamNames[i == 2 ? "gf" : "player" + Std.string(i + 1)] = "Character " + Std.string(i + 1) + " (" + charName + ")";
						}
						options.remove("!players");
					}
					for (o in options)
					{
						if (!eventParamNames.exists(o))
							eventParamNames[o] = Util.properCaseString(o);
					}
					var newThing:DropdownMenu = new DropdownMenu(0, 0, "", [""], true);
					if (p.infoText != null)
						newThing.infoText = p.infoText;
					newThing.valueText = eventParamNames;
					newThing.valueList = options;
					newThing.value = str;
					newThing.onChanged = function() {Reflect.setField(eventParamList, p.id, newThing.value);}

					eventParams.push(new Label(p.label));
					eventParams.push(newThing);

				case "dropdownSpecial":
					if (!dropdownSpecial.exists(p.options[0] + "-" + p.options[1]))
						dropdownSpecial[p.options[0] + "-" + p.options[1]] = Paths.listFilesSub(p.options[0] + "/", p.options[1]);
					var str:String = pValue;
					var newThing:DropdownMenu = new DropdownMenu(0, 0, "", [""], true);
					if (p.infoText != null)
						newThing.infoText = p.infoText;
					if (p.options[0] == "data/characters" && p.options[1] == ".json")
						newThing.valueText = characterNames;
					if (p.options[0] == "data/stages" && p.options[1] == ".json")
						newThing.valueText = stageNames;
					newThing.valueList = dropdownSpecial[p.options[0] + "-" + p.options[1]];
					newThing.value = str;
					newThing.onChanged = function() { Reflect.setField(eventParamList, p.id, newThing.value); }

					eventParams.push(new Label(p.label));
					eventParams.push(newThing);

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
					if (p.infoText != null)
						newThing.infoText = p.infoText;
					newThing.onChanged = function () { Reflect.setField(eventParamList, p.id, newThing.value); }
					eventParams.push(newThing);

				case "string":
					var str:String = pValue;
					var newThing:InputText = new InputText(0, 0, str);
					if (p.infoText != null)
						newThing.infoText = p.infoText;
					newThing.focusGained = function() { suspendControls = true; }
					newThing.focusLost = function() { Reflect.setField(eventParamList, p.id, newThing.text); suspendControls = false; }

					eventParams.push(new Label(p.label));
					eventParams.push(newThing);

				case "color":
					var newThing:TextButton = new TextButton(0, 0, p.label, Button.LONG);
					if (p.infoText != null)
						newThing.infoText = p.infoText;
					newThing.onClicked = function() {
						new ColorPicker(FlxColor.fromRGB(Std.int(Reflect.field(eventParamList, p.id)), Std.int(Reflect.field(eventParamList, thisEventParams[i+1].id)), Std.int(Reflect.field(eventParamList, thisEventParams[i+2].id))), function(clr:FlxColor) {
							Reflect.setField(eventParamList, p.id, clr.red);
							Reflect.setField(eventParamList, thisEventParams[i+1].id, clr.green);
							Reflect.setField(eventParamList, thisEventParams[i+2].id, clr.blue);
						});
					}
					eventParams.push(newThing);

				case "ease":
					var newThing:TextButton = new TextButton(0, 0, p.label, "buttonPopupMenu");
					if (p.infoText != null)
						newThing.infoText = p.infoText;
					newThing.onClicked = function() {
						new EasePicker(Reflect.field(eventParamList, p.id), function(ease:String) {
							Reflect.setField(eventParamList, p.id, ease);
						});
					}
					eventParams.push(newThing);
			}
			ii++;
		}

		for (e in eventParams)
			eventsTab.vbox.add(e);
	}

	function editEventParams(eventValues:Int)
	{
		var thisEvent:EventData = songData.events[eventValues];

		var window:PopupWindow = null;
		var vbox:VBox = new VBox(35, 35);

		var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
		var scroll:VBox = menu.vbox;

		var thisEventParams:Array<EventParams> = getEventParams(thisEvent.type);
		var ii:Int = 0;
		for (i in 0...thisEventParams.length)
		{
			var p:EventParams = thisEventParams[i];
			if (p.id == null && p.type != "label")
				p.id = Std.string(ii);
			var pValue:Dynamic = null;
			if (p.type != "label")
				pValue = Reflect.field(songData.events[eventValues].parameters, p.id);

			switch (p.type)
			{
				case "label":
					var newThing:FlxText = new FlxText(0, 0, 230, p.label);
					newThing.setFormat("FNF Dialogue", 18, FlxColor.WHITE, CENTER, OUTLINE, 0xFF254949);
					scroll.add(newThing);
					ii--;

				case "checkbox":
					var newThing:Checkbox = new Checkbox(0, 0, p.label);
					newThing.checked = pValue;
					newThing.condition = function() { return Reflect.field(songData.events[eventValues].parameters, p.id); }
					newThing.onClicked = function() { Reflect.setField(songData.events[eventValues].parameters, p.id, newThing.checked); }

					scroll.add(newThing);

				case "dropdown":
					var str:String = pValue;
					var options:Array<String> = p.options.copy();
					if (options.contains("!players"))
					{
						var charCount:Int = 2;
						while (Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
							charCount++;
						for (i in 0...charCount)
						{
							options.insert(options.indexOf("!players"), i == 2 ? "gf" : "player"+Std.string(i+1));
							var charName:String = Reflect.field(songData, "player" + Std.string(i + 1));
							if (characterNames.exists(charName))
								charName = characterNames[charName];
							eventParamNames[i == 2 ? "gf" : "player" + Std.string(i + 1)] = "Character " + Std.string(i + 1) + " (" + charName + ")";
						}
						options.remove("!players");
					}
					for (o in options)
					{
						if (!eventParamNames.exists(o))
							eventParamNames[o] = Util.properCaseString(o);
					}
					var newThing:DropdownMenu = new DropdownMenu(0, 0, "", [""], true);
					newThing.valueText = eventParamNames;
					newThing.valueList = options;
					newThing.value = str;
					newThing.condition = function() { return Reflect.field(songData.events[eventValues].parameters, p.id); }
					newThing.onChanged = function() { Reflect.setField(songData.events[eventValues].parameters, p.id, newThing.value); }

					scroll.add(new Label(p.label));
					scroll.add(newThing);

				case "dropdownSpecial":
					if (!dropdownSpecial.exists(p.options[0] + "-" + p.options[1]))
						dropdownSpecial[p.options[0] + "-" + p.options[1]] = Paths.listFilesSub(p.options[0] + "/", p.options[1]);
					var str:String = pValue;
					var newThing:DropdownMenu = new DropdownMenu(0, 0, "", [""], true);
					if (p.options[0] == "data/characters" && p.options[1] == ".json")
						newThing.valueText = characterNames;
					if (p.options[0] == "data/stages" && p.options[1] == ".json")
						newThing.valueText = stageNames;
					newThing.valueList = dropdownSpecial[p.options[0] + "-" + p.options[1]];
					newThing.value = str;
					newThing.condition = function() { return Reflect.field(songData.events[eventValues].parameters, p.id); }
					newThing.onChanged = function() { Reflect.setField(songData.events[eventValues].parameters, p.id, newThing.value); }

					scroll.add(new Label(p.label));
					scroll.add(newThing);

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
					newThing.condition = function() { return Reflect.field(songData.events[eventValues].parameters, p.id); }
					newThing.onChanged = function() { Reflect.setField(songData.events[eventValues].parameters, p.id, newThing.value); }
					scroll.add(newThing);

				case "string":
					var str:String = pValue;
					var newThing:InputText = new InputText(0, 0, str);
					newThing.condition = function() { return Reflect.field(songData.events[eventValues].parameters, p.id); }
					newThing.focusLost = function() { Reflect.setField(songData.events[eventValues].parameters, p.id, newThing.text); }

					scroll.add(new Label(p.label));
					scroll.add(newThing);

				case "color":
					var newThing:TextButton = new TextButton(0, 0, p.label, Button.LONG);

					newThing.onClicked = function() {
						new ColorPicker(FlxColor.fromRGB(Std.int(Reflect.field(songData.events[eventValues].parameters, p.id)), Std.int(Reflect.field(songData.events[eventValues].parameters, thisEventParams[i+1].id)),Std.int(Reflect.field(songData.events[eventValues].parameters, thisEventParams[i+2].id))), function(clr:FlxColor) {
							Reflect.setField(songData.events[eventValues].parameters, p.id, clr.red);
							Reflect.setField(songData.events[eventValues].parameters, thisEventParams[i+1].id, clr.green);
							Reflect.setField(songData.events[eventValues].parameters, thisEventParams[i+2].id, clr.blue);
						});
					}

					scroll.add(newThing);

				case "ease":
					var newThing:TextButton = new TextButton(0, 0, p.label, "buttonPopupMenu");
					newThing.onClicked = function() {
						new EasePicker(Reflect.field(songData.events[eventValues].parameters, p.id), function(ease:String) {
							Reflect.setField(songData.events[eventValues].parameters, p.id, ease);
						});
					}
					scroll.add(newThing);
			}
			ii++;
		}

		vbox.add(scroll);

		var ok:TextButton = new TextButton(0, 0, "#ok", Button.SHORT, function() { window.close(); });
		vbox.add(ok);

		window = PopupWindow.CreateWithGroup(vbox);
	}

	function getColumn(n:Int, sec:Int):Int
	{
		var column:Int = n;
		if (songData.notes[sec].camOn == 0)
		{
			if (column % numColumns >= numColumns / 2)
				column -= Std.int(numColumns / 2);
			else
				column += Std.int(numColumns / 2);
		}
		return column;
	}

	function copyLast(?sides:Int = 0)
	{
		var ghostSec:Int = Std.int(curSection - copyLastStepper.value);
		if (ghostSec >= 0 && ghostSec < songData.notes.length && copyLastStepper.value != 0)
		{
			var sec:SectionData = songData.notes[ghostSec];
			var curSec:SectionData = songData.notes[curSection];
			var newNotes:Array<Array<Dynamic>> = [];
			for (note in noteData)
			{
				if (timeInSec(note[0], ghostSec))
				{
					var column:Int = getColumn(getColumn(note[1], ghostSec), curSection);
					if (maintainSidesCheckbox.checked)
						column = note[1];
					if ((sides == 0 && column < numColumns / 2) || (sides == 1 && column >= numColumns / 2) || sides == 2)
					{
						var newNote:Array<Dynamic> = note.copy();
						newNote[1] = column;

						var noteStep:Float = Conductor.stepFromTime(note[0]) - sec.firstStep + curSec.firstStep;
						var noteEndStep:Float = Conductor.stepFromTime(note[0] + note[2]) - sec.firstStep + curSec.firstStep;

						newNote[0] = Conductor.timeFromStep(noteStep);
						if (note[2] > 0)
							newNote[2] = Conductor.timeFromStep(noteEndStep) - Conductor.timeFromStep(noteStep);
						newNotes.push(newNote);
					}
				}
			}
			for (n in newNotes)
				noteData.push(n);

			refreshNotes();
			refreshSustains();
		}
	}

	function clearCurrent(?sides:Int = 0)
	{
		var poppers:Array<Array<Dynamic>> = [];
		for (n in noteData)
		{
			if (timeInSec(n[0], curSection) && ((sides == 0 && n[1] < numColumns / 2) || (sides == 1 && n[1] >= numColumns / 2) || sides == 2))
				poppers.push(n);
		}
		for (p in poppers)
			noteData.remove(p);

		refreshNotes();
		refreshSustains();
	}

	function allCamsOn(?character:Int = 0)
	{
		for (sec in songData.notes)
			sec.camOn = character;

		refreshSectionIcons();
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
			songData = Cloner.clone(dataLog1[undoPosition]);
			noteData = Cloner.clone(dataLog2[undoPosition]);
			postUndoRedo();
		}
	}

	function redo()
	{
		if (undoPosition < dataLog1.length - 1)
		{
			undoPosition++;
			if (!unsaved)
			{
				unsaved = true;
				refreshFilename();
			}
			songData = Cloner.clone(dataLog1[undoPosition]);
			noteData = Cloner.clone(dataLog2[undoPosition]);
			postUndoRedo();
		}
	}

	function postUndoRedo()
	{
		Conductor.recalculateTimings(songData.bpmMap);
		Conductor.recalculateBPM();

		updateReplaceTypeList();
		refreshUniqueDivisions();
		refreshTracks();
		refreshSectionLines();
		refreshSectionIcons();
		refreshStrums();
		refreshNotes();
		refreshSustains();
		refreshBPMLines();
		refreshEventLines();
		refreshGhostNotes();
		refreshSelectedNotes();
		updateEventParams(curEvent);
	}

	function handleExtraColumns()
	{
		var choices:Array<Array<Dynamic>> = [["Delete", function() {
			var poppers:Array<Array<Dynamic>> = [];
			for (n in noteData)
			{
				if (n[1] >= numColumns)
					poppers.push(n);
			}
			for (p in poppers)
				noteData.remove(p);

			refreshNotes();
			refreshSustains();
		}], ["Replace", function() {
			new FlxTimer().start(0.01, function(tmr:FlxTimer) { replaceExtraColumns(); });
		}]];

		new ChoiceWindow("Some notes in this chart fall outside of valid columns.\nWhat do you want to do with them?", choices);
	}

	function replaceExtraColumns()
	{
		var window:PopupWindow = null;
		var vbox:VBox = new VBox(35, 35);

		var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
		var scroll:VBox = menu.vbox;

		var totalColumns:Array<Int> = [];

		for (n in noteData)
		{
			if (n[1] >= songData.columns.length)
			{
				if (!totalColumns.contains(Std.int(Math.floor(n[1] / (songData.columns.length / 2)))))
					totalColumns.push(Std.int(Math.floor(n[1] / (songData.columns.length / 2))));
			}
		}

		var replacementDropdowns:Array<DropdownMenu> = [];
		var noteTypeList:Array<String> = Paths.listFilesSub("data/notetypes/", ".json");
		noteTypeList.remove("default");
		noteTypeList.unshift("");

		for (i in 0...totalColumns.length)
		{
			var replacementHbox:HBox = new HBox();
			replacementHbox.add(new Label(Std.string(totalColumns[i] * (songData.columns.length / 2)) + " - " + Std.string((totalColumns[i] * (songData.columns.length / 2)) + (songData.columns.length / 2) - 1) + ":"));
			var replacementDropdown:DropdownMenu = new DropdownMenu(0, 0, "", noteTypeList, "Default", true);
			replacementDropdowns.push(replacementDropdown);
			replacementHbox.add(replacementDropdown);
			scroll.add(replacementHbox);
		}

		vbox.add(menu);

		var accept:TextButton = new TextButton(0, 0, "Accept");
		accept.onClicked = function() {
			for (n in noteData)
			{
				if (n[1] >= songData.columns.length)
				{
					var column:Int = Std.int(Math.floor(n[1] / (songData.columns.length / 2)));
					var replacement:String = replacementDropdowns[totalColumns.indexOf(column)].value;
					n[1] = n[1] % songData.columns.length;
					if (replacement != "")
					{
						if (n.length < 4)
							n.push("");
						n[3] = replacement;
					}
				}
			}

			updateReplaceTypeList();
			refreshNotes();
			refreshSustains();

			window.close();
		}
		vbox.add(accept);

		window = PopupWindow.CreateWithGroup(vbox);
	}



	function prepareChartNoteData(songData:SongData, ?noteData:Array<Array<Dynamic>> = null):SongData
	{
		var savedData:SongData = Song.copy(songData);
		for (s in savedData.notes)
			s.sectionNotes = [];

		var notes:Array<Array<Dynamic>> = noteData.copy();
		ArraySort.sort(notes, function(a:Array<Dynamic>, b:Array<Dynamic>) {
			if (a[0] < b[0])
				return -1;
			if (a[0] > b[0])
				return 1;
			if (a[1] < b[1])
				return -1;
			if (a[1] > b[1])
				return 1;
			return 0;
		});
		for (n in notes)
		{
			var s:Int = secFromTime(n[0]);
			var newN:Array<Dynamic> = n.copy();
			savedData.notes[s].sectionNotes.push(newN);
		}

		return prepareChartSave(savedData);
	}

	public static function prepareChartSave(songData:SongData):SongData
	{
		var savedData:SongData = 
		{
			song: songData.song,
			artist: songData.artist,
			charter: songData.charter,
			preview: songData.preview,
			ratings: songData.ratings,
			offset: songData.offset,
			player1: songData.player1,
			player2: songData.player2,
			stage: songData.stage,
			needsVoices: (songData.tracks.length > 1),
			notes: []
		}

		if (Reflect.hasField(songData, "player3"))
		{
			var i:Int = 3;
			while (Reflect.hasField(songData, "player" + Std.string(i)))
			{
				Reflect.setField(savedData, "player" + Std.string(i), Reflect.field(songData, "player" + Std.string(i)));
				i++;
			}
		}

		if (songData.music != null)
		{
			if (songData.music.pause.trim() != "" || songData.music.gameOver.trim() != "" || songData.music.gameOverEnd.trim() != "" || songData.music.results.trim() != "")
				savedData.music = songData.music;
		}

		if (songData.eventFile != null && songData.eventFile != "_events")
			savedData.eventFile = songData.eventFile;

		if (songData.useBeats)
			savedData.useBeats = songData.useBeats;

		if (songData.altSpeedCalc)
			savedData.altSpeedCalc = songData.altSpeedCalc;

		if (songData.bpmMap.length > 1)
			savedData.bpmMap = songData.bpmMap;
		else
			savedData.bpm = songData.bpmMap[0][1];

		var timingStruct:TimingStruct = new TimingStruct();
		timingStruct.recalculateTimings(songData.bpmMap);

		if (songData.scrollSpeeds.length > 1)
			savedData.scrollSpeeds = songData.scrollSpeeds;
		else
			savedData.speed = songData.scrollSpeeds[0][1];

		if (songData.skipCountdown)
			savedData.skipCountdown = songData.skipCountdown;

		if (songData.columns != null)
		{
			var includeColumnDivisions:Bool = false;
			for (i in 0...songData.columns.length)
			{
				if (i >= 4 && (songData.columns[i].division != 0 || songData.columns[i].singer != 0))
					includeColumnDivisions = true;
				if (i < 4 && (songData.columns[i].division != 1 || songData.columns[i].singer != 1))
					includeColumnDivisions = true;
			}

			if (includeColumnDivisions || songData.columns.length != 8)
			{
				savedData.columns = [];
				for (i in 0...songData.columns.length)
				{
					var c:SongColumnData = songData.columns[i];
					var _c:SongColumnData = {division: c.division};
					if (c.singer != c.division)
						_c.singer = c.singer;
					if (c.anim != Song.defaultSingAnimations[i % Song.defaultSingAnimations.length])
						_c.anim = c.anim;
					if (c.missAnim != c.anim + "miss")
						_c.missAnim = c.missAnim;
					savedData.columns.push(_c);
				}
			}
		}

		if (songData.columnDivisionNames != null)
		{
			var includeColumnDivisionNames:Bool = false;
			if (songData.columnDivisionNames.length != 2)
				includeColumnDivisionNames = true;
			if (songData.columnDivisionNames.length > 0 && songData.columnDivisionNames[0] != "#freeplay.sandbox.side.0")
				includeColumnDivisionNames = true;
			if (songData.columnDivisionNames.length > 1 && songData.columnDivisionNames[1] != "#freeplay.sandbox.side.1")
				includeColumnDivisionNames = true;

			if (includeColumnDivisionNames)
				savedData.columnDivisionNames = songData.columnDivisionNames;
		}

		if (songData.noteType != null && songData.noteType[0] != "default" || songData.noteType.length > 1)
			savedData.noteType = songData.noteType;

		if (songData.uiSkin != null && songData.uiSkin != "default")
			savedData.uiSkin = songData.uiSkin;

		if (songData.tracks[0][0].toLowerCase() != "inst" || songData.tracks[0][1] != 0 || (songData.tracks.length > 1 && (songData.tracks[1][0].toLowerCase() != "voices" || songData.tracks[1][1] != 1)) || songData.tracks.length > 2)
			savedData.tracks = songData.tracks;

		var allNotetypes:Array<String> = [];
		for (s in songData.notes)
		{
			if (s.defaultNotetypes != null)
			{
				for (t in s.defaultNotetypes)
				{
					if (t != "" && !allNotetypes.contains(t))
						allNotetypes.push(t);
				}
			}

			for (n in s.sectionNotes)
			{
				if (n.length > 3)
				{
					if (!allNotetypes.contains(n[3]))
						allNotetypes.push(n[3]);
				}
			}
		}
		if (allNotetypes.length > 0 && songData.useBeats)
			savedData.allNotetypes = allNotetypes;

		if (songData.notetypeSingers != null)
		{
			var includeSingers:Bool = false;
			for (n in songData.notetypeSingers)
			{
				if (n.length > 0)
					includeSingers = true;
			}
			if (includeSingers)
			{
				savedData.notetypeSingers = songData.notetypeSingers;
				if (!songData.notetypeOverridesCam)
					savedData.notetypeOverridesCam = songData.notetypeOverridesCam;
			}
		}

		var useMustHit:Bool = songData.useMustHit;
		if (!useMustHit)
			savedData.useMustHit = useMustHit;

		if (songData.columns != null)
		{
			var uniqueDivisions:Array<Int> = [];
			for (i in songData.columns)
			{
				if (!uniqueDivisions.contains(i.division))
					uniqueDivisions.push(i.division);
			}
			if (uniqueDivisions.length != 2 || songData.columns.length % 2 != 0)
			{
				savedData.useMustHit = false;
				useMustHit = false;
			}
		}

		var i:Int = 0;
		for (s in songData.notes)
		{
			var newS:SectionData = 
			{
				sectionNotes: [],
				lengthInSteps: s.lengthInSteps
			}

			if (s.camOn > 1 || !useMustHit)
				newS.camOn = s.camOn;
			else
				newS.mustHitSection = (s.camOn == 0);

			if (songData.scrollSpeeds.length > 1 && s.firstStep != null && s.lastStep != null)
			{
				if (savedData.scrollSpeeds != null)
					Reflect.deleteField(savedData, "scrollSpeeds");
				for (sp in songData.scrollSpeeds)
				{
					if (sp[0] >= s.firstStep / 4 && sp[0] < s.lastStep / 4)
					{
						if (newS.scrollSpeeds == null)
							newS.scrollSpeeds = [];
						newS.scrollSpeeds.push([sp[0] - (s.firstStep / 4), sp[1]]);
					}
				}
			}

			var useThirdBeats:Bool = false;
			for (n in s.sectionNotes)
			{
				var newN:Array<Dynamic> = [n[0], n[1]];
				if (n.length > 2 && (n[2] > 0 || !songData.useBeats || n.length > 3))
					newN.push(n[2]);
				if (songData.useBeats)
				{
					if (newN.length > 2)
						newN[2] = timingStruct.beatFromTime(newN[0] + newN[2]) - timingStruct.beatFromTime(newN[0]);
					newN[0] = timingStruct.beatFromTime(newN[0]) - (s.firstStep / 4.0);
					if (newN[0] * 128 != Math.round(newN[0] * 128))
						useThirdBeats = true;
					if (n.length > 3)
					{
						if (allNotetypes.contains(n[3]))
							newN.push(allNotetypes.indexOf(n[3]) + 1);
					}
				}
				else if (n.length > 3)
					newN.push(n[3]);
				if (newS.mustHitSection)
				{
					if (newN[1] % songData.columns.length >= songData.columns.length / 2)
						newN[1] -= songData.columns.length / 2;
					else
						newN[1] += songData.columns.length / 2;
				}
				newS.sectionNotes.push(newN);
			}

			if (useThirdBeats)
			{
				newS.beatMultiplier = 3;
				for (j in 0...newS.sectionNotes.length)
				{
					newS.sectionNotes[j][0] = Math.round(newS.sectionNotes[j][0] * newS.beatMultiplier * 192) / 192;
					if (newS.sectionNotes[j].length > 2)
						newS.sectionNotes[j][2] = Math.round(newS.sectionNotes[j][2] * newS.beatMultiplier * 192) / 192;
				}
			}

			if (songData.useBeats && i > 0)
			{
				var c:Int = i-1;
				while (savedData.notes[c].copyLast)
					c--;

				if (newS.sectionNotes.length > 0 && newS.lengthInSteps == savedData.notes[c].lengthInSteps && newS.beatMultiplier == savedData.notes[c].beatMultiplier && newS.sectionNotes.length == savedData.notes[c].sectionNotes.length)
				{
					var matches:Int = 0;
					for (a in newS.sectionNotes)
					{
						var t1:String = "";
						if (a.length > 3)
							t1 = a[3];
						var matched:Bool = false;
						for (b in savedData.notes[c].sectionNotes)
						{
							var t2:String = "";
							if (b.length > 3)
								t2 = b[3];
							if (!matched && a[0] == b[0] && a[1] == b[1] && a[2] == b[2] && t1 == t2)
							{
								matched = true;
								matches++;
							}
						}
					}
					if (matches == newS.sectionNotes.length)
					{
						Reflect.deleteField(newS, "sectionNotes");
						Reflect.deleteField(newS, "lengthInSteps");
						if (Reflect.hasField(newS, "beatMultiplier"))
							Reflect.deleteField(newS, "beatMultiplier");
						newS.copyLast = true;
					}
				}
			}

			if (s.defaultNotetypes != null)
			{
				if (s.defaultNotetypes.filter(function(a) return a != "").length > 0)
				{
					newS.defaultNotetypes = s.defaultNotetypes.copy();
					if (songData.useBeats)
					{
						for (t in 0...newS.defaultNotetypes.length)
							newS.defaultNotetypes[t] = allNotetypes.indexOf(s.defaultNotetypes[t]) + 1;
					}
				}
			}

			savedData.notes.push(newS);
			i++;
		}

		return savedData;
	}

	function prepareEventsSave(events:Array<EventData>):String
	{
		var savedEventData:Array<EventData> = [];
		for (e in events)
		{
			var newE:EventData = {type: e.type, parameters: e.parameters};
			var contains:Bool = false;
			for (ev in savedEventData)
			{
				if (e.type == ev.type && DynamicMatches(e.parameters, ev.parameters))
					contains = true;
			}
			if (!contains)
				savedEventData.push(newE);
		}

		var savedEvents:Array<Array<Float>> = [];

		for (e in events)
		{
			var index:Int = -1;
			for (i in 0...savedEventData.length)
			{
				if (e.type == savedEventData[i].type && DynamicMatches(e.parameters, savedEventData[i].parameters))
				{
					index = i;
					break;
				}
			}

			if (index > -1)
				savedEvents.push([e.beat, index]);
		}

		return Json.stringify({eventData: savedEventData, events: savedEvents});
	}

	function changeSaveName(path:String)
	{
		filename = path;
		unsaved = false;
		refreshFilename();
		var jsonNameArray:Array<String> = path.replace('\\','/').split('/');
		var finalJsonName = jsonNameArray[jsonNameArray.length-1].split('.json')[0];
		songFileShortened = finalJsonName;

		autosavePaused = false;
	}

	function refreshFilename()
	{
		var cwd:String = Sys.getCwd().replace("\\","/");
		var fn:String = filename.replace("\\", "/");

		if (fn.trim() == "")
			filenameText = "New Chart";
		else if (fn.contains(cwd))
			filenameText = fn.replace(cwd, "");
		else
			filenameText = "???/" + fn.substring(fn.lastIndexOf("/")+1, fn.length);

		if (unsaved)
			filenameText = "*" + filenameText;
		Application.current.window.title = filenameText + " - " + Main.windowTitle;
	}

	function _new()
	{
		autosavePaused = true;

		var file:FileBrowser = new FileBrowser();
		file.label = "Choose an audio track that you want to chart";
		file.loadCallback = function(fullPath:String)
		{
			var songNameArray:Array<String> = fullPath.replace('\\','/').split('/');
			if (songNameArray.indexOf("songs") == -1)
			{
				new Notify("The file you have selected is not a song.");
				autosavePaused = false;
			}
			else
			{
				while (songNameArray[0] != "songs")
					songNameArray.shift();
				songNameArray.shift();
				songNameArray.pop();

				ChartEditorState.filename = "";
				ChartEditorState.isNew = true;
				ChartEditorState.songId = songNameArray.join("/");
				FlxG.sound.music.fadeOut(0.5, 0, function(twn) { FlxG.sound.music.stop(); });
				FlxG.switchState(new ChartEditorState());
			}
		};
		file.failureCallback = function() { autosavePaused = false; };
		file.load("ogg");
	}

	function _open()
	{
		autosavePaused = true;

		var file:FileBrowser = new FileBrowser();
		file.loadCallback = function(fullPath:String)
		{
			var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
			if (jsonNameArray.indexOf("songs") == -1 && jsonNameArray.indexOf("sm") == -1)
			{
				new Notify("The file you have selected is not a chart.");
				autosavePaused = false;
			}
			else
			{
				if (jsonNameArray.indexOf("sm") != -1)
				{
					while (jsonNameArray[0] != "sm")
						jsonNameArray.remove(jsonNameArray[0]);
					jsonNameArray.remove(jsonNameArray[0]);

					isNew = false;
					songFile = jsonNameArray.join("/").split('.sm')[0];
					songId = ChartEditorState.songFile;
				}
				else
				{
					while (jsonNameArray[0] != "songs")
						jsonNameArray.remove(jsonNameArray[0]);
					jsonNameArray.remove(jsonNameArray[0]);
					var songIdArray:Array<String> = [];
					for (j in 0...jsonNameArray.length-1)
						songIdArray.push(jsonNameArray[j]);

					isNew = false;
					songId = songIdArray.join("/");
					songFile = jsonNameArray.join("/").split('.json')[0];
				}
				ChartEditorState.filename = fullPath;
				FlxG.switchState(new ChartEditorState());
			}
		};
		file.failureCallback = function() { autosavePaused = false; };
		file.load("json;*.sm");
	}

	function _save(?browse:Bool = true)
	{
		autosavePaused = true;

		var songLengthInSections:Int = 0;
		for (i in 0...songData.notes.length)
		{
			if (songData.notes[i].firstStep < Conductor.stepFromTime(tracks[0].length))
				songLengthInSections = i;
		}
		songLengthInSections++;
		if (songData.notes.length > songLengthInSections)
			songData.notes.resize(songLengthInSections);

		var savedData:SongData = prepareChartNoteData(songData, noteData);

		var data:String = Json.stringify({song: savedData});

		if (data != null && data.length > 0)
		{
			if (browse || filename == "" || filename.endsWith(".sm"))
			{
				var file:FileBrowser = new FileBrowser();
				file.saveCallback = changeSaveName;
				file.failureCallback = function() { autosavePaused = false; };
				var defName:String = (filename == "" ? songId + ".json" : filename);
				file.save(defName, data.trim());
			}
			else
			{
				FileBrowser.saveAs(filename, data.trim());
				unsaved = false;
				refreshFilename();
				autosavePaused = false;
			}
		}
	}

	function DynamicMatches(a1:Dynamic, a2:Dynamic):Bool
	{
		for (f in Reflect.fields(a1))
		{
			if (!Reflect.hasField(a2, f))
				return false;
		}

		for (f in Reflect.fields(a2))
		{
			if (!Reflect.hasField(a1, f))
				return false;
			if (Reflect.field(a1, f) != Reflect.field(a2, f))
				return false;
		}

		return true;
	}

	function _saveEvents(?browse:Bool = true)
	{
		autosavePaused = true;
		var data:String = prepareEventsSave(songData.events);

		if (data != null && data.length > 0)
		{
			if (browse || filename == "")
			{
				var file:FileBrowser = new FileBrowser();
				file.saveCallback = function(path:String) { autosavePaused = false; };
				file.failureCallback = function() { autosavePaused = false; };
				file.save(songData.eventFile + ".json", data.trim());
			}
			else
			{
				var eventsFilename:String = filename.replace("\\","/");
				eventsFilename = eventsFilename.substring(0, eventsFilename.lastIndexOf("/")+1) + songData.eventFile + ".json";
				FileBrowser.saveAs(eventsFilename, data.trim());
				unsaved = false;
				refreshFilename();
				autosavePaused = false;
			}
		}
	}

	function saveSM()
	{
		autosavePaused = true;

		var data:String = SMFile.save(songData, noteData);

		if (data != null && data.length > 0)
		{
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = function(path:String) { autosavePaused = false; };
			file.failureCallback = function() { autosavePaused = false; };
			file.save(songId + ".sm", data.trim());
		}
	}

	function _confirm(message:String, action:Void->Void)
	{
		if (unsaved)
		{
			DropdownMenu.isOneActive = false;
			new Confirm("Are you sure you want to "+message+"?\nUnsaved changes will be lost!", action);
		}
		else
			action();
	}



	var addingEvents:Bool = false;
	function loadEvents(add:Bool)
	{
		autosavePaused = true;
		addingEvents = add;

		var file:FileBrowser = new FileBrowser();
		file.loadCallback = loadEventsCallback;
		file.failureCallback = function() { autosavePaused = false; };
		file.load();
	}

	function loadEventsCallback(fullPath:String)
	{
		autosavePaused = false;

		if (!addingEvents)
			songData.events = [];
		var eventsNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		while (eventsNameArray[0] != "songs")
			eventsNameArray.remove(eventsNameArray[0]);

		if (Reflect.hasField(Paths.json(eventsNameArray.join("/").split('.json')[0]), "song"))
			loadPsychEvents(Paths.json(eventsNameArray.join("/").split('.json')[0]).song);
		else
		{
			var eventList:Array<EventData> = Song.loadEvents(eventsNameArray.join("/").split('.json')[0]);
			for (ev in eventList)
				songData.events.push(ev);
		}

		refreshEventLines();
		updateEventList();
	}

	function loadPsychEvents(data:Dynamic)
	{
		var psychEventConverters:Array<HscriptHandlerSimple> = [];
		for (c in Paths.listFiles('data/psychEvents/', '.hscript'))
			psychEventConverters.push(new HscriptHandlerSimple('data/psychEvents/' + c));

		for (c in psychEventConverters)
		{
			c.setVar("songId", songId);
			c.setVar("songIdShort", songIdShort);
		}

		var psychEvents:Array<Array<Dynamic>> = [];
		if (Reflect.hasField(data, "events"))
			psychEvents = cast data.events;

		if (Reflect.hasField(data, "notes"))
		{
			var dataNotes:Array<SectionData> = cast data.notes;
			if (dataNotes.length > 0)
			{
				for (sec in dataNotes)
				{
					for (note in sec.sectionNotes)
					{
						if (note[1] < 0)
							psychEvents.push([note[0], [[note[2], note[3], note[4]]]]);
					}
				}
			}
		}

		var unmatchedEvents:Array<String> = [];
		var unmatchedCustoms:Array<EventData> = [];
		for (eventArray in psychEvents)
		{
			var trueEventArray:Array<Array<String>> = cast eventArray[1];
			for (event in trueEventArray)
			{
				var eventValue:Dynamic = null;
				for (c in psychEventConverters)
				{
					var returnValue:Dynamic = c.execFuncReturn("convertEvent", event);
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
							var newEvent:EventData = {time: eventArray[0], beat: Conductor.beatFromTime(eventArray[0]), type: a.type, parameters: a.parameters};
							if (Std.isOfType(a.parameters, Array))
							{
								var newParameters:Dynamic = {};
								for (i in 0...a.parameters.length)
									Reflect.setField(newParameters, Std.string(i), a.parameters[i]);
								newEvent.parameters = newParameters;
							}
							songData.events.push(newEvent);
						}
					}
					else
					{
						var newEvent:EventData = {time: eventArray[0], beat: Conductor.beatFromTime(eventArray[0]), type: eventValue.type, parameters: eventValue.parameters};
						if (Std.isOfType(eventValue.parameters, Array))
						{
							var newParameters:Dynamic = {};
							for (i in 0...eventValue.parameters.length)
								Reflect.setField(newParameters, Std.string(i), eventValue.parameters[i]);
							newEvent.parameters = newParameters;
						}
						songData.events.push(newEvent);
					}
				}
				else
				{
					if (!unmatchedEvents.contains(event[0]))
						unmatchedEvents.push(event[0]);
					var newEvent:EventData = {time: eventArray[0], beat: Conductor.beatFromTime(eventArray[0]), type: "custom", parameters: {type: event[0], param1: event[1], param2: event[2], param3: ""}};
					unmatchedCustoms.push(newEvent);
				}
			}
		}

		if (unmatchedEvents.length > 0)
		{
			var notifyString:String = "The following events have no equivalent:\n\n";
			for (e in unmatchedEvents)
				notifyString += e + "\n";

			new ChoiceWindow(notifyString, [["#ok", null], ["Make Custom", function() {
				for (e in unmatchedCustoms)
					songData.events.push(e);
				updateEventList();
				refreshEventLines();
			}]]);
		}
	}

	function copyCamsFromFile()
	{
		autosavePaused = true;

		var file:FileBrowser = new FileBrowser();
		file.loadCallback = copyCamsFromFileCallback;
		file.failureCallback = function() { autosavePaused = false; };
		file.load();
	}

	function copyCamsFromFileCallback(fullPath:String):Void
	{
		autosavePaused = false;

		var sectionsNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		while (sectionsNameArray[0] != "songs")
			sectionsNameArray.remove(sectionsNameArray[0]);

		var newSections:Array<SectionData> = cast Paths.json(sectionsNameArray.join("/").split('.json')[0]).song.notes;
		if (newSections.length > songData.notes.length)
		{
			for (i in songData.notes.length...newSections.length)
				songData.notes.push({sectionNotes: [], lengthInSteps: 16, camOn: 0});
		}
		else if (newSections.length < songData.notes.length)
		{
			for (i in newSections.length...songData.notes.length)
			{
				var newSection:SectionData = {
					camOn: newSections[newSections.length-1].camOn,
					lengthInSteps: newSections[newSections.length-1].lengthInSteps,
					sectionNotes: []
				};
				newSections.push(newSection);
			}
		}
		for (i in 0...newSections.length)
		{
			if (i > 0 && newSections[i].copyLast)
				newSections[i].lengthInSteps = newSections[i-1].lengthInSteps;
		}

		for (i in 0...songData.notes.length)
		{
			if (Reflect.hasField(newSections[i], "mustHitSection"))
				songData.notes[i].camOn = (newSections[i].mustHitSection ? 0 : 1);
			else
				songData.notes[i].camOn = newSections[i].camOn;
			songData.notes[i].lengthInSteps = newSections[i].lengthInSteps;
		}

		songData = Song.timeSections(songData);
		refreshSectionLines();
		refreshSectionIcons();
	}



	function convertFromBase()
	{
		autosavePaused = true;

		var baseStages:Map<String, String> = new Map<String, String>();
		for (stage in Util.splitFile(Paths.text("baseStages")))
		{
			var stageSplit:Array<String> = stage.split("|");
			baseStages[stageSplit[0]] = stageSplit[1];
		}

		var file:FileBrowser = new FileBrowser();
		file.label = "Choose a \"-chart\" file that you want to convert";
		file.loadCallback = function(fullPath:String)
		{
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
				file2.loadCallback = function(musicPath:String)
				{
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

					if (FileSystem.exists(trueMusicPath + "Voices-" + p1.split("-")[0] + "-" + trackSuffix + ".ogg"))
						tracks.push(["Voices-" + p1.split("-")[0] + "-" + trackSuffix, 2]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p1 + "-" + trackSuffix + ".ogg"))
						tracks.push(["Voices-" + p1 + "-" + trackSuffix, 2]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p1.split("-")[0] + ".ogg"))
						tracks.push(["Voices-" + p1.split("-")[0], 2]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p1 + ".ogg"))
						tracks.push(["Voices-" + p1, 2]);

					if (FileSystem.exists(trueMusicPath + "Voices-" + p2.split("-")[0] + "-" + trackSuffix + ".ogg"))
						tracks.push(["Voices-" + p2.split("-")[0] + "-" + trackSuffix, 3]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p2 + "-" + trackSuffix + ".ogg"))
						tracks.push(["Voices-" + p2 + "-" + trackSuffix, 3]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p2.split("-")[0] + ".ogg"))
						tracks.push(["Voices-" + p2.split("-")[0], 3]);
					else if (FileSystem.exists(trueMusicPath + "Voices-" + p2 + ".ogg"))
						tracks.push(["Voices-" + p2, 3]);

					var file3:FileBrowser = new FileBrowser();
					file3.saveCallback = function(savePath:String)
					{
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
								player1: p1,
								player2: p2,
								player3: gf,
								stage: metadata.playData.stage,
								bpmMap: bpmMap,
								speed: speed,
								notes: [],
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

							var parsedData:SongData = Song.parseSongData(newChart, false, false);
							parsedData.useBeats = true;
							File.saveContent(trueSavePath + convertedSongId + "-" + d + ".json", Json.stringify({song: prepareChartSave(parsedData)}));
						}

						ArraySort.sort(convertedEvents, function(a:Dynamic, b:Dynamic) {
							if (a.t < b.t)
								return -1;
							if (a.t > b.t)
								return 1;
							return 0;
						});
						var newEvents:Array<EventData> = convertEventsFromBase(convertedSongId, convertedEvents, timingStruct);
						if (newEvents.length > 0)
							File.saveContent(trueSavePath + eventFile + ".json", prepareEventsSave(newEvents));

						autosavePaused = false;
					}
					file3.failureCallback = function() { autosavePaused = false; };
					file3.savePath("*.*");
				}
				file2.failureCallback = function() { autosavePaused = false; };
				file2.load("ogg");
			}
		}
		file.failureCallback = function() { autosavePaused = false; };
		file.load("json");
	}

	function convertEventsFromBase(convertedSongId:String, events:Array<Dynamic>, timingStruct:TimingStruct):Array<EventData>
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