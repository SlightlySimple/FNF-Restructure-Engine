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
import flixel.system.FlxSound;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import haxe.ds.ArraySort;
import menus.EditorMenuState;
import data.ObjectData;
import data.Options;
import data.SMFile;
import data.Song;
import data.Noteskins;
import game.PlayState;
import objects.Character;
import objects.HealthIcon;
import objects.Note;
import scripting.HscriptHandler;

import lime.app.Application;
import lime.media.openal.AL;

import funkui.TabMenu;
import funkui.TextButton;
import funkui.InputText;
import funkui.Checkbox;
import funkui.Stepper;
import funkui.DropdownMenu;
import funkui.Label;
import funkui.ObjectMenu;
import funkui.ColorSwatch;

using StringTools;

class EditorSustainNote extends FlxSprite
{
	public var strumTime:Float;
	public var sustainLength:Float;
	public var beat:Float;
	public var endBeat:Float;
	public var column:Int;

	override public function new(strumTime:Float, column:Int, sustainLength:Float)
	{
		super();

		refreshVars(strumTime, column, sustainLength);
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
			visible = true;
		makeGraphic(Std.int(ChartEditorState.NOTE_SIZE / 2), noteHeight, FlxColor.GRAY);
		updateHitbox();
		x = Std.int((FlxG.width / 2) - (ChartEditorState.NOTE_SIZE * ChartEditorState.numColumns / 2) + (ChartEditorState.NOTE_SIZE * column) + (ChartEditorState.NOTE_SIZE / 4));
		y = Std.int(ChartEditorState.NOTE_SIZE * zoom * Conductor.stepFromTime(strumTime));
		if (downscroll)
		{
			y = -y;
			y -= height;
		}
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

class ChartEditorState extends MusicBeatState
{
	public static var NOTE_SIZE:Int = 240;
	public static var numColumns:Int = 8;
	var downscroll:Bool;

	public static var newChart:Bool = false;
	public static var songId:String = "";
	public static var songIdShort:String = "";
	public static var songFile:String = "";
	public var songFileShortened:String = "";

	var songData:SongData;
	var isSM:Bool = false;
	var smData:SMFile = null;
	var noteData:Array<Array<Dynamic>> = [];

	public var camFollow:FlxObject;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var mousePos:FlxObject;

	public static var filename:String = "";
	var filenameText:FlxText;

	var tracks:Array<FlxSound> = [];
	var trackList:Array<String> = [];
	var playbackRate:Float = 1;
	var songProgress:Float = 0;
	var prevSongProgress:Float = 0;
	var curSection:Int = 0;
	var prevSection:Int = 0;

	var zoom:Float = 1;
	var snap:Int = 16;
	var timeSinceLastAutosave:Float = 0;
	var autosavePaused:Bool = false;

	var sectionLines:FlxSpriteGroup;
	var sectionIcons:FlxTypedSpriteGroup<HealthIcon>;
	var strums:FlxSpriteGroup;
	var sustains:FlxTypedSpriteGroup<EditorSustainNote>;
	var notes:FlxTypedSpriteGroup<Note>;
	var ghostNotes:FlxTypedSpriteGroup<Note>;
	var bpmLines:FlxSpriteGroup;
	var eventLines:FlxSpriteGroup;
	var eventText:FlxTypedSpriteGroup<FlxText>;
	var eventTimeLine:FlxSprite;
	var infoText:FlxText;
	var curNotetype:String = "";
	var uniqueDivisions:Array<Int> = [];
	var strumColumns:Array<Int> = [];

	var makingNotes:Array<Float> = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1];

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

	var tabMenu:IsolatedTabMenu;
	var tabButtons:TabButtons;
	var suspendControls:Bool = false;

	var noteTick:Stepper;
	var noteTicks:Array<Array<Dynamic>> = [];

	var characterSettings:FlxSpriteGroup;
	var characterList:FlxSpriteGroup;
	var characterNotetypes:FlxSpriteGroup;
	var characterFileList:Array<String>;

	var trackSettings:FlxSpriteGroup;

	var sectionCamOnStepper:Stepper = null;
	var sectionLengthStepper:Stepper;
	var copyLastStepper:Stepper;
	var maintainSidesCheckbox:Checkbox;
	var defaultNoteP1Input:InputText;
	var defaultNoteP2Input:InputText;

	var bpmStepper:Stepper;
	var scrollSpeedStepper:Stepper;
	var noteTypeInput:InputText;
	var replaceTypeDropdown:DropdownMenu;
	var allCamsOnStepper:Stepper = null;

	var eventListDropdown:ObjectMenu;
	var eventTypeDropdown:DropdownMenu;
	var addEventButton:TextButton;
	var updateEventButton:TextButton;
	var moveEventButton:TextButton;
	var eventParams:FlxSpriteGroup;
	public var eventParamList:Dynamic;

	override public function create()
	{
		if (!FileSystem.exists("autosaves"))
			FileSystem.createDirectory("autosaves");
		timeSinceLastAutosave = 0;
		downscroll = Options.options.downscroll;

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
		else if (newChart)
		{
			songData =
			{
				song: songIdShort,
				useBeats: true,
				bpmMap: [[0, 120]],
				scrollSpeeds: [[0, 1]],
				altSpeedCalc: true,
				player1: TitleState.defaultVariables.player1,
				player2: TitleState.defaultVariables.player2,
				player3: TitleState.defaultVariables.gf,
				stage: TitleState.defaultVariables.stage,
				tracks: [["Inst", 0]],
				notes: [{camOn: 1, lengthInSteps: 16, sectionNotes: []}],
				eventFile: "_events",
				events: [],
				music: { pause: "", gameOver: "", gameOverEnd: "", results: "", resultsEnd: "" }
			}
			if (Paths.songExists(songId, "Voices"))
				songData.tracks.push(["Voices", 1]);
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

		numColumns = songData.columnDivisions.length;
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
			songProgress = Conductor.stepFromTime(PlayState.testingChartPos);
		}

		updateReplaceTypeList();

		sectionLines = new FlxSpriteGroup();
		add(sectionLines);

		sectionIcons = new FlxTypedSpriteGroup<HealthIcon>();
		add(sectionIcons);

		strums = new FlxSpriteGroup();
		strums.scrollFactor.set();
		add(strums);

		sustains = new FlxTypedSpriteGroup<EditorSustainNote>();
		add(sustains);

		notes = new FlxTypedSpriteGroup<Note>();
		add(notes);

		ghostNotes = new FlxTypedSpriteGroup<Note>();
		add(ghostNotes);

		selNoteBoxes = new FlxTypedSpriteGroup<NoteSelection>();
		add(selNoteBoxes);

		bpmLines = new FlxSpriteGroup();
		add(bpmLines);

		eventLines = new FlxSpriteGroup();
		add(eventLines);

		eventText = new FlxTypedSpriteGroup<FlxText>();
		add(eventText);

		var xx:Int = Std.int( (FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) );
		var ww:Int = Std.int(NOTE_SIZE * numColumns);
		eventTimeLine = new FlxSprite(xx, 0).makeGraphic(ww, 1, FlxColor.YELLOW);
		eventTimeLine.visible = false;
		add(eventTimeLine);

		selectionBox = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		selectionBox.alpha = 0.6;
		selectionBox.visible = false;
		add(selectionBox);

		filenameText = new FlxText(0, 50, FlxG.width / 2, "", 24);
		filenameText.font = "VCR OSD Mono";
		filenameText.borderStyle = OUTLINE;
		filenameText.borderColor = FlxColor.BLACK;
		filenameText.alignment = CENTER;
		filenameText.cameras = [camHUD];
		add(filenameText);
		refreshFilename();

		infoText = new FlxText(40, 40, FlxG.width - 80, "", 18);
		infoText.cameras = [camHUD];
		infoText.font = "VCR OSD Mono";
		infoText.alignment = RIGHT;
		add(infoText);

		refreshUniqueDivisions();
		refreshSectionLines();
		refreshSectionIcons();
		refreshStrums();
		refreshSustains();
		refreshNotes();
		refreshBPMLines();
		refreshEventLines();
		FlxG.sound.cache(Paths.sound("noteTick"));



		tabMenu = new IsolatedTabMenu(50, 50, 250, 600);
		tabMenu.cameras = [camHUD];
		add(tabMenu);

		tabButtons = new TabButtons(0, 0, 800, ["Settings", "Properties", "Characters", "Tracks", "Music", "Section", "Misc.", "Events", "Help"]);
		tabButtons.cameras = [camHUD];
		tabButtons.menu = tabMenu;
		add(tabButtons);



		var tabGroupSettings = new TabGroup();

		var loadChartButton:TextButton = new TextButton(10, 20, 115, 20, "Load");
		loadChartButton.onClicked = loadChart;
		tabGroupSettings.add(loadChartButton);

		var saveChartButton:TextButton = new TextButton(loadChartButton.x + 115, loadChartButton.y, 115, 20, "Save");
		saveChartButton.onClicked = saveChart;
		tabGroupSettings.add(saveChartButton);
		tabGroupSettings.add(new Label("Chart:", loadChartButton));

		var loadEventsButton:TextButton = new TextButton(10, saveChartButton.y + 40, 75, 20, "Load");
		loadEventsButton.onClicked = function() {loadEvents(false); };
		tabGroupSettings.add(loadEventsButton);

		var addEventsButton:TextButton = new TextButton(loadEventsButton.x + 75, loadEventsButton.y, 75, 20, "Add");
		addEventsButton.onClicked = function() {loadEvents(true); };
		tabGroupSettings.add(addEventsButton);

		var saveEventsButton:TextButton = new TextButton(addEventsButton.x + 75, addEventsButton.y, 75, 20, "Save");
		saveEventsButton.onClicked = saveEvents;
		tabGroupSettings.add(saveEventsButton);
		tabGroupSettings.add(new Label("Events:", loadEventsButton));

		var saveSMButton:TextButton = new TextButton(10, saveEventsButton.y + 30, 230, 20, "Save SM");
		saveSMButton.onClicked = saveSM;
		tabGroupSettings.add(saveSMButton);

		var testChartButton:TextButton = new TextButton(10, saveSMButton.y + 30, 230, 20, "Test Chart");
		tabGroupSettings.add(testChartButton);

		var testChartSide:Stepper = new Stepper(10, testChartButton.y + 40, 230, 20, 0, 1, 0, uniqueDivisions.length - 1);
		tabGroupSettings.add(testChartSide);
		tabGroupSettings.add(new Label("Chart Side:", testChartSide));

		testChartButton.onClicked = function() {
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
			PlayState.testingChartPos = Conductor.timeFromStep(songProgress);
			PlayState.testingChartSide = testChartSide.valueInt;
			PlayState.inStoryMode = false;
			PlayState.songId = songId;
			FlxG.mouse.visible = false;
			FlxG.switchState(new PlayState());
		}

		var jumpToStart:TextButton = new TextButton(10, testChartSide.y + 30, 230, 20, "Jump to Start");
		jumpToStart.onClicked = function() {
			songProgress = 0;
		}
		tabGroupSettings.add(jumpToStart);

		var clearNotesButton:TextButton = new TextButton(10, jumpToStart.y + 40, 115, 20, "Notes");
		clearNotesButton.onClicked = function() {
			var confirm:Confirm = new Confirm(300, 100, "Are you sure you want to delete all notes?\nThis can not be undone!", this);
			confirm.yesFunc = function() {
				noteData = [];
				selectedNotes = [];
				updateReplaceTypeList();
				refreshSelectedNotes();
				refreshNotes();
				refreshSustains();
			}
			confirm.cameras = [camHUD];
		}
		tabGroupSettings.add(clearNotesButton);

		var clearEventsButton:TextButton = new TextButton(clearNotesButton.x + 115, clearNotesButton.y, 115, 20, "Events");
		clearEventsButton.onClicked = function() {
			var confirm:Confirm = new Confirm(300, 100, "Are you sure you want to delete all events?\nThis can not be undone!", this);
			confirm.yesFunc = function() {
				songData.events = [];
				refreshEventLines();
				updateEventList();
			}
			confirm.cameras = [camHUD];
		}
		tabGroupSettings.add(clearEventsButton);
		tabGroupSettings.add(new Label("Clear:", clearNotesButton));

		var optimizeSectionsButton:TextButton = new TextButton(10, clearEventsButton.y + 30, 230, 20, "Optimize Sections");
		optimizeSectionsButton.onClicked = function() {
			var i:Int = 1;
			while (i < songData.notes.length)
			{
				var curSec:SectionData = songData.notes[i];
				var prevSec:SectionData = songData.notes[i-1];
				var defNotes:Array<String> = [curSec.defaultNoteP1, prevSec.defaultNoteP1, curSec.defaultNoteP2, prevSec.defaultNoteP2];
				for (i in 0...defNotes.length)
				{
					if (defNotes[i] == null)
						defNotes[i] = "";
				}

				if (curSec.camOn == prevSec.camOn && defNotes[0] == defNotes[1] && defNotes[2] == defNotes[3])
				{
					prevSec.lengthInSteps += curSec.lengthInSteps;
					songData.notes.remove(curSec);
					i--;
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
		tabGroupSettings.add(optimizeSectionsButton);

		var downscrollCheckbox:Checkbox = new Checkbox(35, optimizeSectionsButton.y + 30, "Reverse Scroll");
		downscrollCheckbox.checked = downscroll;
		downscrollCheckbox.onClicked = function() {
			downscroll = downscrollCheckbox.checked;

			refreshSectionLines();
			refreshSectionIcons();
			refreshStrums();
			repositionSustains();
			repositionNotes();
			refreshSelectedNotes();
			refreshBPMLines();
			refreshEventLines();
			refreshGhostNotes();
		}
		tabGroupSettings.add(downscrollCheckbox);

		noteTick = new Stepper(10, downscrollCheckbox.y + 40, 230, 20, -1, 1, -1, uniqueDivisions.length - 1);
		tabGroupSettings.add(noteTick);
		tabGroupSettings.add(new Label("Note Tick for Strumline:", noteTick));

		var playbackRateStepper:Stepper = new Stepper(10, noteTick.y + 40, 230, 20, 1, 0.05, 0.05, 9999, 2);
		playbackRateStepper.onChanged = function() { playbackRate = playbackRateStepper.value; correctTrackPitch(true); }
		tabGroupSettings.add(playbackRateStepper);
		tabGroupSettings.add(new Label("Playback Rate (Editor):", playbackRateStepper));

		tabMenu.addGroup(tabGroupSettings);



		var tabGroupProperties = new TabGroup();

		var songNameInput:InputText = new InputText(10, 20, songData.song);
		songNameInput.focusGained = function() { songNameInput.text = songData.song; suspendControls = true; }
		songNameInput.focusLost = function() { suspendControls = false; }
		songNameInput.callback = function(text:String, action:String) {
			songData.song = text;
		}
		tabGroupProperties.add(songNameInput);
		tabGroupProperties.add(new Label("Song Name:", songNameInput));

		var songArtistInput:InputText = new InputText(10, songNameInput.y + 40, songData.artist);
		songArtistInput.focusGained = function() { songArtistInput.text = songData.artist; suspendControls = true; }
		songArtistInput.focusLost = function() { suspendControls = false; }
		songArtistInput.callback = function(text:String, action:String) {
			songData.artist = text;
		}
		tabGroupProperties.add(songArtistInput);
		tabGroupProperties.add(new Label("Artist (Optional):", songArtistInput));

		var offsetStepper:Stepper = new Stepper(10, songArtistInput.y + 40, 115, 20, songData.offset);
		offsetStepper.onChanged = function() {
			songData.offset = offsetStepper.value;
		}
		tabGroupProperties.add(offsetStepper);
		tabGroupProperties.add(new Label("Offset (ms):", offsetStepper));

		var bakeOffsetButton:TextButton = new TextButton(offsetStepper.x + 115, offsetStepper.y, 115, 20, "Bake");
		bakeOffsetButton.onClicked = function () {
			for (note in noteData)
				note[0] -= songData.offset;

			refreshNotes();
			refreshSustains();
			refreshSelectedNotes();
			songData.offset = 0;
			offsetStepper.value = 0;
		}
		tabGroupProperties.add(bakeOffsetButton);

		var useBeatsCheckbox:Checkbox = new Checkbox(10, offsetStepper.y + 30, "New Chart Format", songData.useBeats);
		useBeatsCheckbox.onClicked = function() {
			songData.useBeats = useBeatsCheckbox.checked;
		}
		tabGroupProperties.add(useBeatsCheckbox);

		var useMustHitCheckbox:Checkbox = new Checkbox(10, useBeatsCheckbox.y + 30, "Use \"Must Hit Section\"", songData.useMustHit, 12);
		useMustHitCheckbox.onClicked = function() {
			songData.useMustHit = useMustHitCheckbox.checked;
		}
		tabGroupProperties.add(useMustHitCheckbox);

		var notetypeOverridesCamCheckbox:Checkbox = new Checkbox(10, useMustHitCheckbox.y + 30, "Notetypes Control Camera", songData.notetypeOverridesCam, 12);
		notetypeOverridesCamCheckbox.onClicked = function() {
			songData.notetypeOverridesCam = notetypeOverridesCamCheckbox.checked;
		}
		tabGroupProperties.add(notetypeOverridesCamCheckbox);

		var columnDivisionsInput:InputText = new InputText(10, notetypeOverridesCamCheckbox.y + 40, songData.columnDivisions.join(","));
		columnDivisionsInput.customFilterPattern = ~/[^0-9,]*/g;
		columnDivisionsInput.focusGained = function() {
			columnDivisionsInput.text = songData.columnDivisions.join(",");
			suspendControls = true;
		}
		columnDivisionsInput.focusLost = function() { suspendControls = false; }
		columnDivisionsInput.callback = function(text:String, action:String) {
			songData.columnDivisions = [];
			for (c in text.split(","))
				songData.columnDivisions.push(Std.parseInt(c));
			numColumns = songData.columnDivisions.length;

			refreshUniqueDivisions();
			noteTick.maxVal = uniqueDivisions.length - 1;
			testChartSide.maxVal = uniqueDivisions.length - 1;

			NOTE_SIZE = Std.int(480 / numColumns);
			if (NOTE_SIZE > 60)
				NOTE_SIZE = 60;

			refreshSectionLines();
			refreshSectionIcons();
			refreshStrums();
			refreshSustains(-1, true);
			refreshNotes(-1, true);
			refreshBPMLines();
			refreshEventLines();
		}
		tabGroupProperties.add(columnDivisionsInput);
		tabGroupProperties.add(new Label("Playable sections:", columnDivisionsInput));

		var columnDivisionNamesInput:InputText = new InputText(10, columnDivisionsInput.y + 40, songData.columnDivisionNames.join(","));
		columnDivisionNamesInput.focusGained = function() {
			columnDivisionNamesInput.text = songData.columnDivisionNames.join(",");
			suspendControls = true;
		}
		columnDivisionNamesInput.focusLost = function() { suspendControls = false; }
		columnDivisionNamesInput.callback = function(text:String, action:String) {
			songData.columnDivisionNames = text.split(",");
		}
		tabGroupProperties.add(columnDivisionNamesInput);
		tabGroupProperties.add(new Label("Section names:", columnDivisionNamesInput));

		var stageList:Array<String> = Paths.listFilesSub("data/stages/", ".json");
		var stageDropdown:DropdownMenu = new DropdownMenu(10, columnDivisionNamesInput.y + 40, 230, 20, songData.stage, stageList, true);
		stageDropdown.onChanged = function() {
			songData.stage = stageDropdown.value;
		};
		tabGroupProperties.add(stageDropdown);
		tabGroupProperties.add(new Label("Stage:", stageDropdown));

		var noteskinTypeInput:InputText = new InputText(10, stageDropdown.y + 40, songData.noteType.join(","));
		noteskinTypeInput.focusGained = function() { noteskinTypeInput.text = songData.noteType.join(","); suspendControls = true; }
		noteskinTypeInput.focusLost = function() {
			songData.noteType = noteskinTypeInput.text.split(",");
			if (songData.noteType.length < 1)
				songData.noteType = ["default"];

			notes.forEachAlive(function(note) {
				note.onNotetypeChanged(noteTypeFromColumn(note.column));
				note.setGraphicSize(NOTE_SIZE);
				note.updateHitbox();
			});
			refreshStrums();
			suspendControls = false;
		}
		tabGroupProperties.add(noteskinTypeInput);
		tabGroupProperties.add(new Label("Noteskin Types:", noteskinTypeInput));

		var uiSkinList:Array<String> = Paths.listFiles("images/ui/skins/", ".json");
		var uiSkinDropdown:DropdownMenu = new DropdownMenu(10, noteskinTypeInput.y + 40, 230, 20, songData.uiSkin, uiSkinList, true);
		uiSkinDropdown.onChanged = function() {
			songData.uiSkin = uiSkinDropdown.value;
		};
		tabGroupProperties.add(uiSkinDropdown);
		tabGroupProperties.add(new Label("UI Skin:", uiSkinDropdown));

		var skipCountdownCheckbox:Checkbox = new Checkbox(10, uiSkinDropdown.y + 30, "Skip Countdown", songData.skipCountdown);
		skipCountdownCheckbox.onClicked = function() {
			songData.skipCountdown = skipCountdownCheckbox.checked;
		}
		tabGroupProperties.add(skipCountdownCheckbox);

		var eventFileInput:InputText = new InputText(10, skipCountdownCheckbox.y + 40, songData.eventFile);
		eventFileInput.focusGained = function() { eventFileInput.text = songData.eventFile; suspendControls = true; }
		eventFileInput.focusLost = function() { suspendControls = false; }
		eventFileInput.callback = function(text:String, action:String) {
			songData.eventFile = text;
		}
		tabGroupProperties.add(eventFileInput);
		tabGroupProperties.add(new Label("Events File:", eventFileInput));

		tabMenu.addGroup(tabGroupProperties);



		var tabGroupCharacters = new TabGroup();
		characterFileList = Paths.listFilesSub("data/characters/", ".json");

		var charCount:Int = 2;
		while (Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
			charCount++;
		var characterCount:Stepper = new Stepper(10, 20, 230, 20, charCount, 1, 2);
		characterCount.onChanged = function() {
			var charCount:Int = 2;
			while (Reflect.hasField(songData, "player" + Std.string(charCount + 1)))
				charCount++;
			if (!Reflect.hasField(songData, "player" + Std.string(characterCount.valueInt)))
			{
				for (i in charCount...characterCount.valueInt)
					Reflect.setField(songData, "player" + Std.string(i+1), Reflect.field(songData, "player" + Std.string(i)));
			}
			else
			{
				for (i in characterCount.valueInt...charCount)
					Reflect.deleteField(songData, "player" + Std.string(i+1));
			}
			if (sectionCamOnStepper != null)
				sectionCamOnStepper.maxVal = characterCount.value;
			if (allCamsOnStepper != null)
				allCamsOnStepper.maxVal = characterCount.value;
			refreshCharacters();
		}
		tabGroupCharacters.add(characterCount);
		tabGroupCharacters.add(new Label("Number of characters:", characterCount));

		var characterColumns:InputText = new InputText(10, characterCount.y + 40, songData.singerColumns.join(","));
		characterColumns.customFilterPattern = ~/[^0-9,]*/g;
		characterColumns.focusGained = function() {
			characterColumns.text = songData.singerColumns.join(",");
			suspendControls = true;
		}
		characterColumns.focusLost = function() { suspendControls = false; }
		characterColumns.callback = function(text:String, action:String) {
			songData.singerColumns = [];
			for (c in text.split(","))
				songData.singerColumns.push(Std.parseInt(c));
			while (songData.singerColumns.length < numColumns)
				songData.singerColumns.push(songData.columnDivisions[songData.singerColumns.length]);
			if (songData.singerColumns.length > numColumns)
				songData.singerColumns.resize(numColumns);
		}
		tabGroupCharacters.add(characterColumns);
		tabGroupCharacters.add(new Label("Associated columns:", characterColumns));

		var characterTabSwap:TextButton = new TextButton(10, characterColumns.y + 30, 230, 20, "Character Notetypes");
		characterTabSwap.onClicked = function() {
			if (characterSettings.members.contains(characterList))
			{
				characterSettings.remove(characterList);
				characterSettings.add(characterNotetypes);
				characterTabSwap.textObject.text = "Characters";
			}
			else
			{
				characterSettings.remove(characterNotetypes);
				characterSettings.add(characterList);
				characterTabSwap.textObject.text = "Character Notetypes";
			}
		}
		tabGroupCharacters.add(characterTabSwap);

		characterSettings = new FlxSpriteGroup();
		characterList = new FlxSpriteGroup();
		characterNotetypes = new FlxSpriteGroup();
		refreshCharacters();
		tabGroupCharacters.add(characterSettings);
		characterSettings.add(characterList);

		tabMenu.addGroup(tabGroupCharacters);



		var tabGroupTracks = new TabGroup();

		if (isSM)
			refreshTracks();
		else
		{
			trackList = Paths.listFiles("songs/" + songId + "/", ".ogg");
			trackList = trackList.concat(Paths.listFiles("data/songs/" + songId + "/", ".ogg"));
			if (trackList.length <= 0)
			{
				Application.current.window.alert("The chart has no associated music files.\nCheck the folder \"songs/"+songId+"\" or create it if it doesn't exist", "Alert");
				FlxG.switchState(new EditorMenuState());
			}

			var trackCount:Stepper = new Stepper(10, 20, 230, 20, songData.tracks.length, 1, 1);
			trackCount.onChanged = function() {
				if (Std.int(trackCount.value) > songData.tracks.length)
				{
					while (Std.int(trackCount.value) > songData.tracks.length)
						songData.tracks.push([trackList[0], 0]);
				}
				else
					songData.tracks.resize(Std.int(trackCount.value));
				refreshTracks();
			}
			tabGroupTracks.add(trackCount);
			tabGroupTracks.add(new Label("Number of tracks:", trackCount));

			trackSettings = new FlxSpriteGroup();
			refreshTracks();
			tabGroupTracks.add(trackSettings);
		}

		tabMenu.addGroup(tabGroupTracks);



		var tabGroupMusic = new TabGroup();

		var musicList:Array<String> = Paths.listFilesSub("music/", ".ogg");
		musicList.unshift("");

		var pauseDropdown:DropdownMenu = new DropdownMenu(10, 20, 230, 20, songData.music.pause, musicList, true);
		pauseDropdown.onChanged = function() {
			songData.music.pause = pauseDropdown.value;
		};
		tabGroupMusic.add(pauseDropdown);
		tabGroupMusic.add(new Label("Pause Menu:", pauseDropdown));

		var gameOverDropdown:DropdownMenu = new DropdownMenu(10, pauseDropdown.y + 40, 230, 20, songData.music.gameOver, musicList, true);
		gameOverDropdown.onChanged = function() {
			songData.music.gameOver = gameOverDropdown.value;
		};
		tabGroupMusic.add(gameOverDropdown);
		tabGroupMusic.add(new Label("Game Over:", gameOverDropdown));

		var gameOverEndDropdown:DropdownMenu = new DropdownMenu(10, gameOverDropdown.y + 40, 230, 20, songData.music.gameOverEnd, musicList, true);
		gameOverEndDropdown.onChanged = function() {
			songData.music.gameOverEnd = gameOverEndDropdown.value;
		};
		tabGroupMusic.add(gameOverEndDropdown);
		tabGroupMusic.add(new Label("Game Over Confirm:", gameOverEndDropdown));

		var resultsDropdown:DropdownMenu = new DropdownMenu(10, gameOverEndDropdown.y + 40, 230, 20, songData.music.results, musicList, true);
		resultsDropdown.onChanged = function() {
			songData.music.results = resultsDropdown.value;
		};
		tabGroupMusic.add(resultsDropdown);
		tabGroupMusic.add(new Label("Results Screen:", resultsDropdown));

		var resultsEndDropdown:DropdownMenu = new DropdownMenu(10, resultsDropdown.y + 40, 230, 20, songData.music.resultsEnd, musicList, true);
		resultsEndDropdown.onChanged = function() {
			songData.music.resultsEnd = resultsEndDropdown.value;
		};
		tabGroupMusic.add(resultsEndDropdown);
		tabGroupMusic.add(new Label("Results Screen Confirm:", resultsEndDropdown));

		tabMenu.addGroup(tabGroupMusic);



		var tabGroupSections = new TabGroup();

		sectionCamOnStepper = new Stepper(10, 20, 230, 20, songData.notes[0].camOn + 1, 1, 1, charCount);
		sectionCamOnStepper.onChanged = function() {
			var sec:SectionData = songData.notes[curSection];
			sec.camOn = sectionCamOnStepper.valueInt - 1;
			refreshSectionIcons(curSection);
			refreshGhostNotes();
		}
		tabGroupSections.add(sectionCamOnStepper);
		tabGroupSections.add(new Label("Camera Focus Character:", sectionCamOnStepper));

		sectionLengthStepper = new Stepper(10, sectionCamOnStepper.y + 40, 230, 20, songData.notes[0].lengthInSteps, 1, 1);
		sectionLengthStepper.onChanged = function() {
			var sec:SectionData = songData.notes[curSection];
			sec.lengthInSteps = Std.int(sectionLengthStepper.value);
			songData = Song.timeSections(songData);
			refreshSectionLines();
			refreshSectionIcons();
		}
		tabGroupSections.add(sectionLengthStepper);
		tabGroupSections.add(new Label("Section length in steps:", sectionLengthStepper));

		var splitSectionButton:TextButton = new TextButton(10, sectionLengthStepper.y + 30, 230, 20, "Split Section");
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
				if (sec.defaultNoteP1 != null && sec.defaultNoteP1 != "")
					newSec.defaultNoteP1 = sec.defaultNoteP1;
				if (sec.defaultNoteP2 != null && sec.defaultNoteP2 != "")
					newSec.defaultNoteP2 = sec.defaultNoteP2;

				songData.notes.insert(curSection + 1, newSec);
				sec.lengthInSteps = newLengthInSteps;

				songData = Song.timeSections(songData);
				refreshSectionLines();
				refreshSectionIcons();
			}
		}
		tabGroupSections.add(splitSectionButton);

		copyLastStepper = new Stepper(10, splitSectionButton.y + 30, 230, 20, 0, 1);
		copyLastStepper.onChanged = refreshGhostNotes;
		tabGroupSections.add(copyLastStepper);

		var copyLeftButton:TextButton = new TextButton(10, copyLastStepper.y + 40, 75, 20, "Left");
		copyLeftButton.onClicked = function () {
			copyLast(0);
		}
		tabGroupSections.add(copyLeftButton);

		var copyRightButton:TextButton = new TextButton(copyLeftButton.x + 75, copyLeftButton.y, 75, 20, "Right");
		copyRightButton.onClicked = function () {
			copyLast(1);
		}
		tabGroupSections.add(copyRightButton);

		var copyBothButton:TextButton = new TextButton(copyRightButton.x + 75, copyRightButton.y, 75, 20, "Both");
		copyBothButton.onClicked = function () {
			copyLast(2);
		}
		tabGroupSections.add(copyBothButton);

		tabGroupSections.add(new Label("Copy Last:", copyLeftButton));

		maintainSidesCheckbox = new Checkbox(10, copyBothButton.y + 30, "Maintain Sides");
		maintainSidesCheckbox.checked = false;
		maintainSidesCheckbox.onClicked = refreshGhostNotes;
		tabGroupSections.add(maintainSidesCheckbox);

		var swapSectionButton:TextButton = new TextButton(10, maintainSidesCheckbox.y + 30, 230, 20, "Swap Section");
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
		tabGroupSections.add(swapSectionButton);

		var flipSectionButton:TextButton = new TextButton(10, swapSectionButton.y + 30, 230, 20, "Flip Section");
		flipSectionButton.onClicked = function () {
			var columnDivs:Array<Array<Int>> = [];
			var columnSwaps:Array<Int> = [];
			for (i in 0...songData.columnDivisions.length)
			{
				while (columnDivs.length <= songData.columnDivisions[i])
					columnDivs.push([]);
				columnDivs[songData.columnDivisions[i]].push(i);
			}

			for (c in columnDivs)
				c.reverse();

			for (i in 0...songData.columnDivisions.length)
			{
				columnSwaps.push(columnDivs[songData.columnDivisions[i]][0]);
				columnDivs[songData.columnDivisions[i]].shift();
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
		tabGroupSections.add(flipSectionButton);

		var clearLeftButton:TextButton = new TextButton(10, flipSectionButton.y + 40, 75, 20, "Left");
		clearLeftButton.onClicked = function() {
			clearCurrent(0);
			updateReplaceTypeList();
		}
		tabGroupSections.add(clearLeftButton);

		var clearRightButton:TextButton = new TextButton(clearLeftButton.x + 75, clearLeftButton.y, 75, 20, "Right");
		clearRightButton.onClicked = function() {
			clearCurrent(1);
			updateReplaceTypeList();
		}
		tabGroupSections.add(clearRightButton);

		var clearBothButton:TextButton = new TextButton(clearRightButton.x + 75, clearRightButton.y, 75, 20, "Both");
		clearBothButton.onClicked = function() {
			clearCurrent(2);
			updateReplaceTypeList();
		}
		tabGroupSections.add(clearBothButton);

		tabGroupSections.add(new Label("Clear Section:", clearLeftButton));

		var deleteSectionButton:TextButton = new TextButton(10, clearBothButton.y + 30, 230, 20, "Delete Section");
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
		tabGroupSections.add(deleteSectionButton);

		var noteTypeList:Array<String> = Paths.listFilesSub("data/notetypes/", ".json");
		noteTypeList.remove("default");
		noteTypeList.unshift("");

		defaultNoteP1Input = new InputText(10, deleteSectionButton.y + 40);
		defaultNoteP1Input.focusGained = function() { suspendControls = true; }
		defaultNoteP1Input.focusLost = function() { refreshSectionIcons(curSection); suspendControls = false; }
		defaultNoteP1Input.callback = function(text:String, action:String) {
			var sec:SectionData = songData.notes[curSection];
			if (defaultNoteP1Input.text == "")
				sec.defaultNoteP1 = null;
			else
				sec.defaultNoteP1 = defaultNoteP1Input.text;
		}
		tabGroupSections.add(defaultNoteP1Input);
		tabGroupSections.add(new Label("Default Notetype (Player 1):", defaultNoteP1Input));

		var defaultNoteP1Dropdown:DropdownMenu = new DropdownMenu(10, defaultNoteP1Input.y + 30, 230, 20, "", noteTypeList, 16, true);
		defaultNoteP1Dropdown.onChanged = function() {
			defaultNoteP1Input.text = defaultNoteP1Dropdown.value;
			defaultNoteP1Input.callback(defaultNoteP1Input.text, "");
			refreshSectionIcons(curSection);
		}
		tabGroupSections.add(defaultNoteP1Dropdown);

		defaultNoteP2Input = new InputText(10, defaultNoteP1Dropdown.y + 40);
		defaultNoteP2Input.focusGained = function() { suspendControls = true; }
		defaultNoteP2Input.focusLost = function() { refreshSectionIcons(curSection); suspendControls = false; }
		defaultNoteP2Input.callback = function(text:String, action:String) {
			var sec:SectionData = songData.notes[curSection];
			if (defaultNoteP2Input.text == "")
				sec.defaultNoteP2 = null;
			else
				sec.defaultNoteP2 = defaultNoteP2Input.text;
		}
		tabGroupSections.add(defaultNoteP2Input);
		tabGroupSections.add(new Label("Default Notetype (Player 2):", defaultNoteP2Input));

		var defaultNoteP2Dropdown:DropdownMenu = new DropdownMenu(10, defaultNoteP2Input.y + 30, 230, 20, "", noteTypeList, 16, true);
		defaultNoteP2Dropdown.onChanged = function() {
			defaultNoteP2Input.text = defaultNoteP2Dropdown.value;
			defaultNoteP2Input.callback(defaultNoteP2Input.text, "");
			refreshSectionIcons(curSection);
		}
		tabGroupSections.add(defaultNoteP2Dropdown);

		tabMenu.addGroup(tabGroupSections);



		var tabGroupMisc = new TabGroup();

		bpmStepper = new Stepper(10, 20, 230, 20, songData.bpmMap[0][1], 1, 0, 9999, 3);
		bpmStepper.onChanged = function () {
			var slot:Int = -1;
			for (i in 0...songData.bpmMap.length)
			{
				if (songData.bpmMap[i][0] == songProgress / 4)
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
					if (songData.bpmMap[i][0] < songProgress / 4)
						slot = i + 1;
				}
				songData.bpmMap.insert(slot, [songProgress / 4, bpmStepper.value]);
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
		}
		tabGroupMisc.add(bpmStepper);
		tabGroupMisc.add(new Label("BPM:", bpmStepper));

		scrollSpeedStepper = new Stepper(10, bpmStepper.y + 40, 230, 20, songData.scrollSpeeds[0][1], 0.05, 0, 10, 3);
		scrollSpeedStepper.onChanged = function () {
			var slot:Int = -1;
			for (i in 0...songData.scrollSpeeds.length)
			{
				if (songData.scrollSpeeds[i][0] * 4 == songProgress)
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
					if (songData.scrollSpeeds[i][0] < songProgress / 4)
						slot = i + 1;
				}
				songData.scrollSpeeds.insert(slot, [songProgress / 4, scrollSpeedStepper.value]);
			}

			refreshBPMLines();
		}
		tabGroupMisc.add(scrollSpeedStepper);
		tabGroupMisc.add(new Label("Scroll Speed:", scrollSpeedStepper));

		var scrollSpeedHalfButton:TextButton = new TextButton(10, scrollSpeedStepper.y + 30, 115, 20, "Half");
		scrollSpeedHalfButton.onClicked = function()
		{
			scrollSpeedStepper.value = scrollSpeedStepper.value / 2;
			scrollSpeedStepper.onChanged();
		}
		tabGroupMisc.add(scrollSpeedHalfButton);

		var scrollSpeedDoubleButton:TextButton = new TextButton(scrollSpeedHalfButton.x + 115, scrollSpeedHalfButton.y, 115, 20, "Double");
		scrollSpeedDoubleButton.onClicked = function()
		{
			scrollSpeedStepper.value = scrollSpeedStepper.value * 2;
			scrollSpeedStepper.onChanged();
		}
		tabGroupMisc.add(scrollSpeedDoubleButton);

		var scrollSpeedCalc:Checkbox = new Checkbox(10, scrollSpeedDoubleButton.y + 30, "Alternate Scroll\nSpeed Calculation");
		scrollSpeedCalc.checked = songData.altSpeedCalc;
		scrollSpeedCalc.onClicked = function() { songData.altSpeedCalc = scrollSpeedCalc.checked; }
		tabGroupMisc.add(scrollSpeedCalc);

		noteTypeInput = new InputText(10, scrollSpeedCalc.y + 50);
		noteTypeInput.focusGained = function() { suspendControls = true; }
		noteTypeInput.focusLost = function() { suspendControls = false; }
		tabGroupMisc.add(noteTypeInput);
		tabGroupMisc.add(new Label("Type of new Notes:", noteTypeInput));

		var noteTypeDropdown:DropdownMenu = new DropdownMenu(10, noteTypeInput.y + 30, 230, 20, "", noteTypeList, 16, true);
		noteTypeDropdown.onChanged = function() { noteTypeInput.text = noteTypeDropdown.value; }
		tabGroupMisc.add(noteTypeDropdown);

		replaceTypeDropdown = new DropdownMenu(10, noteTypeDropdown.y + 40, 230, 20, "", [""], 16, true);
		updateReplaceTypeList();
		tabGroupMisc.add(replaceTypeDropdown);
		tabGroupMisc.add(new Label("Type to alter:", replaceTypeDropdown));

		var removeTypeButton:TextButton = new TextButton(10, replaceTypeDropdown.y + 40, 115, 20, "Remove");
		removeTypeButton.onClicked = function()
		{
			var noteTypeString:String = replaceTypeDropdown.value;
			if (noteTypeString == "")
				noteTypeString = "default";

			var confirm:Confirm = new Confirm(350, 100, "Are you sure you want to delete all notes of type \""+noteTypeString+"\"?\nThis can not be undone!", this);
			confirm.yesFunc = function() {
				var poppers:Array<Array<Dynamic>> = [];
				for (n in noteData)
				{
					var s:SectionData = songData.notes[secFromTime(n[0])];
					var type:String = "";
					if (n.length > 3)
						type = n[3];
					if (type == "")
					{
						if (songData.columnDivisions[n[1]] == 0 && s.defaultNoteP1 != null && s.defaultNoteP1 != "")
							type = s.defaultNoteP1;
						if (songData.columnDivisions[n[1]] == 1 && s.defaultNoteP2 != null && s.defaultNoteP2 != "")
							type = s.defaultNoteP2;
					}
					if (type == replaceTypeDropdown.value)
						poppers.push(n);
				}
				for (p in poppers)
					noteData.remove(p);

				for (s in songData.notes)
				{
					if (s.defaultNoteP1 == replaceTypeDropdown.value)
						s.defaultNoteP1 = "";

					if (s.defaultNoteP2 == replaceTypeDropdown.value)
						s.defaultNoteP2 = "";
				}

				selectedNotes = [];
				updateReplaceTypeList();
				refreshSelectedNotes();
				refreshNotes();
				refreshSustains();
			}
			confirm.cameras = [camHUD];
		}
		tabGroupMisc.add(removeTypeButton);

		var replaceTypeButton:TextButton = new TextButton(removeTypeButton.x + 115, removeTypeButton.y, 115, 20, "Replace");
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
				if (s.defaultNoteP1 == replaceTypeDropdown.value)
					s.defaultNoteP1 = noteTypeInput.text;

				if (s.defaultNoteP2 == replaceTypeDropdown.value)
					s.defaultNoteP2 = noteTypeInput.text;
			}

			updateReplaceTypeList();
			refreshNotes();
		}
		tabGroupMisc.add(replaceTypeButton);
		tabGroupMisc.add(new Label("Change notes of type:", removeTypeButton));

		var autoSectionNotetypes:TextButton = new TextButton(10, replaceTypeButton.y + 30, 230, 20, "Assign Section NTs");
		autoSectionNotetypes.onClicked = function()
		{
			for (s in songData.notes)
			{
				var typesLeft:Array<String> = [];
				var typesRight:Array<String> = [];
				var emptyNotesLeft:Array<Int> = [];
				var emptyNotesRight:Array<Int> = [];

				for (i in 0...noteData.length)
				{
					if (timeInSec(noteData[i][0], songData.notes.indexOf(s)))
					{
						var t:String = "";
						if (noteData[i].length > 3)
							t = noteData[i][3];

						if (songData.columnDivisions[noteData[i][1]] == 1)
						{
							if (!typesLeft.contains(t))
								typesLeft.push(t);
							emptyNotesLeft.push(i);
						}
						else if (songData.columnDivisions[noteData[i][1]] == 0)
						{
							if (!typesRight.contains(t))
								typesRight.push(t);
							emptyNotesRight.push(i);
						}
					}
				}

				if (typesLeft.length == 1 && typesLeft[0] != "")
				{
					for (i in emptyNotesLeft)
						noteData[i].pop();
					s.defaultNoteP2 = typesLeft[0];
				}

				if (typesRight.length == 1 && typesRight[0] != "")
				{
					for (i in emptyNotesRight)
						noteData[i].pop();
					s.defaultNoteP1 = typesRight[0];
				}
			}
			refreshNotes();
		}
		tabGroupMisc.add(autoSectionNotetypes);

		var clearSectionNotetypes:TextButton = new TextButton(10, autoSectionNotetypes.y + 30, 230, 20, "Unassign Section NTs");
		clearSectionNotetypes.onClicked = function()
		{
			for (n in noteData)
			{
				if (n.length < 4 || n[3] == "")
				{
					var s:SectionData = songData.notes[secFromTime(n[0])];
					if (songData.columnDivisions[n[1]] == 0 && s.defaultNoteP1 != null && s.defaultNoteP1 != "")
					{
						if (n.length < 4)
							n.push(s.defaultNoteP1);
						else
							n[3] = s.defaultNoteP1;
					}

					if (songData.columnDivisions[n[1]] == 1 && s.defaultNoteP2 != null && s.defaultNoteP2 != "")
					{
						if (n.length < 4)
							n.push(s.defaultNoteP2);
						else
							n[3] = s.defaultNoteP2;
					}
				}
			}

			for (s in songData.notes)
			{
				s.defaultNoteP1 = "";
				s.defaultNoteP2 = "";
			}
			refreshNotes();
		}
		tabGroupMisc.add(clearSectionNotetypes);

		var beatStepper:Stepper = new Stepper(10, clearSectionNotetypes.y + 40, 230, 20, 1, 0.25, 0, 9999, 2);
		tabGroupMisc.add(beatStepper);
		tabGroupMisc.add(new Label("Beats:", beatStepper));

		var insertBeatsButton:TextButton = new TextButton(10, beatStepper.y + 30, 115, 20, "Insert");
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
		tabGroupMisc.add(insertBeatsButton);

		var removeBeatsButton:TextButton = new TextButton(insertBeatsButton.x + 115, insertBeatsButton.y, 115, 20, "Remove");
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
		tabGroupMisc.add(removeBeatsButton);

		allCamsOnStepper = new Stepper(10, removeBeatsButton.y + 40, 115, 20, 1, 1, 1, charCount);
		tabGroupMisc.add(allCamsOnStepper);
		var allCamsOnButton:TextButton = new TextButton(allCamsOnStepper.x + 115, allCamsOnStepper.y, 115, 20, "Apply");
		allCamsOnButton.onClicked = function() { allCamsOn(allCamsOnStepper.valueInt - 1); }
		tabGroupMisc.add(allCamsOnButton);
		tabGroupMisc.add(new Label("All section cameras on:", allCamsOnStepper));

		var copyCamsFromFileButton:TextButton = new TextButton(10, allCamsOnButton.y + 30, 230, 20, "Sections from file");
		copyCamsFromFileButton.onClicked = copyCamsFromFile;
		tabGroupMisc.add(copyCamsFromFileButton);

		var bpmNotice:FlxText = new FlxText(10, copyCamsFromFileButton.y + 30, 230, "BPM and Scroll Speeds apply on and after the current conductor time.", 18);
		bpmNotice.color = FlxColor.BLACK;
		bpmNotice.font = "VCR OSD Mono";
		tabGroupMisc.add(bpmNotice);

		tabMenu.addGroup(tabGroupMisc);



		var tabGroupEvents = new TabGroup();

		eventListDropdown = new ObjectMenu(10, 10, 230, 100, 0, [""], false);
		updateEventList();
		tabGroupEvents.add(eventListDropdown);

		var jumpToEvent:Checkbox = new Checkbox(10, eventListDropdown.y + 110, "Jump To Event");
		jumpToEvent.checked = true;
		tabGroupEvents.add(jumpToEvent);

		moveEventButton = new TextButton(10, jumpToEvent.y + 30, 230, 20, "Move Event");
		moveEventButton.onClicked = function() {
			if (eventListDropdown.value > 0)
			{
				songData.events[eventListDropdown.value-1].time = Conductor.timeFromStep(songProgress);
				songData.events[eventListDropdown.value-1].beat = songProgress / 4;
				updateEventList();
				refreshEventLines();
			}
		}
		tabGroupEvents.add(moveEventButton);

		var deleteEventButton:TextButton = new TextButton(10, moveEventButton.y + 30, 230, 20, "Delete Event");
		deleteEventButton.onClicked = function() {
			if (eventListDropdown.value > 0)
			{
				songData.events.splice(eventListDropdown.value - 1, 1);
				updateEventList();
				refreshEventLines();
			}
		}
		tabGroupEvents.add(deleteEventButton);

		var eventTypeList:Array<String> = Paths.listFilesSub("data/events/", ".json");
		for (f in Paths.listFiles("data/songs/" + songId + "/events/", ".json"))
			eventTypeList.push(songIdShort + "/" + f);

		eventTypeDropdown = new DropdownMenu(10, deleteEventButton.y + 40, 230, 20, eventTypeList[0], eventTypeList, 12, true);
		eventTypeDropdown.onChanged = function() { updateEventParams(); };
		tabGroupEvents.add(eventTypeDropdown);
		tabGroupEvents.add(new Label("Type:", eventTypeDropdown));

		eventListDropdown.onChanged = function() {
			if (eventListDropdown.value > 0)
			{
				if (jumpToEvent.checked)
					songProgress = songData.events[eventListDropdown.value - 1].beat * 4;
				eventTypeDropdown.value = songData.events[eventListDropdown.value - 1].type;
				updateEventParams(eventListDropdown.value - 1);

				var thisEventParams:Array<EventParams> = getEventParams(songData.events[eventListDropdown.value - 1].type);
				var time:String = "";
				var timeVal:Float = 0;
				for (p in thisEventParams)
				{
					if (p.time != null && p.time != "")
					{
						time = p.time;
						timeVal = Reflect.field(songData.events[eventListDropdown.value - 1].parameters, p.id);
					}
				}

				if (time != "")
				{
					eventTimeLine.visible = true;
					var beat:Float = songData.events[eventListDropdown.value - 1].beat;
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
			}
			else
				eventTimeLine.visible = false;

			eventText.forEachAlive(function(txt:FlxText)
				{
					if (eventText.members.indexOf(txt) + 1 == eventListDropdown.value)
						txt.color = FlxColor.GRAY;
					else
						txt.color = FlxColor.WHITE;
				}
			);
		};

		addEventButton = new TextButton(10, eventTypeDropdown.y + 30, 230, 20, "Add Event");
		addEventButton.onClicked = function() {
			var eventParamListCopy:Dynamic = Reflect.copy(eventParamList);
			songData.events.push({time: Conductor.timeFromStep(songProgress), beat: songProgress / 4, type: eventTypeDropdown.value, parameters: eventParamListCopy});
			updateEventList();
			refreshEventLines();
		}
		tabGroupEvents.add(addEventButton);

		updateEventButton = new TextButton(10, addEventButton.y + 30, 230, 20, "Update Event");
		updateEventButton.onClicked = function() {
			if (eventListDropdown.value > 0)
			{
				var v:Int = eventListDropdown.value;
				var eventParamListCopy:Dynamic = Reflect.copy(eventParamList);
				songData.events[eventListDropdown.value-1].type = eventTypeDropdown.value;
				songData.events[eventListDropdown.value-1].parameters = eventParamListCopy;
				updateEventList();
				refreshEventLines();
				eventListDropdown.value = v;
				eventListDropdown.onChanged();
			}
		}
		tabGroupEvents.add(updateEventButton);

		eventParams = new FlxSpriteGroup();
		updateEventParams();
		tabGroupEvents.add(eventParams);

		tabMenu.addGroup(tabGroupEvents);



		var tabGroupHelp = new TabGroup();

		var help:String = Paths.text("helpText").replace("\r","").split("!ChartEditor\n")[1].split("\n\n")[0];
		var helpText:FlxText = new FlxText(10, 10, 230, help + "\n", 12);
		helpText.color = FlxColor.BLACK;
		helpText.font = "VCR OSD Mono";
		tabGroupHelp.add(helpText);

		tabMenu.addGroup(tabGroupHelp);



		var extraColumns:Bool = false;
		for (n in noteData)
		{
			if (n[1] >= numColumns)
				extraColumns = true;
		}
		if (extraColumns)
			handleExtraColumns();
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
			saveChart();

		mousePos.x = FlxG.mouse.x;
		mousePos.y = FlxG.mouse.y + camFollow.y - (FlxG.height / 2);
		if (FlxG.mouse.justMoved)
		{
			curNotetype = "";
			notes.forEachAlive(function(note:Note)
				{
					if (note.overlaps(mousePos))
					{
						if (note.noteType != "default" && note.noteType != "")
							curNotetype = note.noteType;
						else
						{
							var sec:SectionData = songData.notes[secFromStep(Std.int(note.beat * 4))];
							if (songData.columnDivisions[note.column] == 0 && sec.defaultNoteP1 != null && sec.defaultNoteP1 != "")
								curNotetype = sec.defaultNoteP1;
							else if (songData.columnDivisions[note.column] == 1 && sec.defaultNoteP2 != null && sec.defaultNoteP2 != "")
								curNotetype = sec.defaultNoteP2;
						}
					}
				}
			);

			eventText.forEachAlive(function(txt:FlxText) {
				if (eventText.members.indexOf(txt) + 1 != eventListDropdown.value)
				{
					if (txt.overlaps(mousePos))
						txt.color = 0xFFAAAAAA;
					else
						txt.color = FlxColor.WHITE;
				}
			});
		}

		if (movingSelection)
		{
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
					var notify:Notify = new Notify(300, 100, "Two notes cannot occupy the same space.", this);
					notify.okFunc = function() {
						returnSelection();
						suspendSelection = false;
					}
					notify.cameras = [camHUD];
				}
				else if (willPopNotes)
				{
					suspendSelection = true;
					var confirm:Confirm = new Confirm(300, 120, "Some notes are outside valid columns and will get deleted.\nProceed?", this);
					confirm.yesFunc = function() {
						moveSelection(cellsX, cellsY, cellSizeY);
						suspendSelection = false;
					}
					confirm.noFunc = function() {
						returnSelection();
						suspendSelection = false;
					}
					confirm.cameras = [camHUD];
				}
				else
					moveSelection(cellsX, cellsY, cellSizeY);
				movingSelection = false;
			}
		}
		else if (selecting)
		{
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

		if (FlxG.keys.pressed.SHIFT && selectedNotes.length > 0)
		{
			var noteDirs:Array<Int> = [0, 0];
			if (FlxG.keys.justPressed.LEFT)
				noteDirs[0] = -1;
			if (FlxG.keys.justPressed.RIGHT)
				noteDirs[0] = 1;
			if (FlxG.keys.justPressed.UP)
				noteDirs[1] = -1;
			if (FlxG.keys.justPressed.DOWN)
				noteDirs[1] = 1;

			if (noteDirs[0] != 0 || noteDirs[1] != 0)
			{
				var cellSizeY:Float = (NOTE_SIZE * zoom) * (16 / snap);
				var willPopNotes:Bool = false;
				var posConflict:Bool = false;
				for (note in selectedNotes)
				{
					var column:Int = note.column + noteDirs[0];
					if (column < 0 || column >= numColumns)
						willPopNotes = true;
				}
				notes.forEachAlive(function(n:Note) {
					if (!selectedNotes.contains(n))
					{
						for (note in selectedNotes)
						{
							if (Math.floor(note.x + (noteDirs[0] * NOTE_SIZE)) == Math.floor(n.x) && Math.floor(note.y + (noteDirs[1] * cellSizeY)) == Math.floor(n.y))
								posConflict = true;
						}
					}
				});
				if (posConflict)
				{
					suspendSelection = true;
					var notify:Notify = new Notify(300, 100, "Two notes cannot occupy the same space.", this);
					notify.okFunc = function() {
						returnSelection();
						suspendSelection = false;
					}
					notify.cameras = [camHUD];
				}
				else if (willPopNotes)
				{
					suspendSelection = true;
					var confirm:Confirm = new Confirm(300, 120, "Some notes are outside valid columns and will get deleted.\nProceed?", this);
					confirm.yesFunc = function() {
						moveSelection(noteDirs[0], noteDirs[1], cellSizeY);
						suspendSelection = false;
					}
					confirm.noFunc = function() {
						returnSelection();
						suspendSelection = false;
					}
					confirm.cameras = [camHUD];
				}
				else
					moveSelection(noteDirs[0], noteDirs[1], cellSizeY);
				movingSelection = false;
			}
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.T && selectedNotes.length > 0)
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

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C && selectedNotes.length > 0)
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

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V && noteClipboard.length > 0)
		{
			var pastedNotes:Array<Array<Dynamic>> = [];
			var selectionArray:Array<Array<Float>> = [];
			for (n in noteClipboard)
			{
				var nClone:Array<Dynamic> = n.copy();
				nClone[0] += songProgress;
				nClone[2] += songProgress;
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
				var notify:Notify = new Notify(300, 100, "Some notes failed to copy due to overlap with existing notes.", this);
				notify.okFunc = function() { suspendSelection = false; }
				notify.cameras = [camHUD];
			}
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.A)
		{
			notes.forEachAlive(function(note:Note)
				{
					if (!selectedNotes.contains(note))
						selectedNotes.push(note);
				}
			);

			refreshSelectedNotes();
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.B && selectedNotes.length > 0)
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

		if (FlxG.keys.justPressed.DELETE && selectedNotes.length > 0)
		{
			suspendSelection = true;
			var confirm:Confirm = new Confirm(300, 100, "Are you sure you want to delete all selected notes?\nThis can not be undone!", this);
			confirm.yesFunc = function() {
				selNoteBoxes.forEachAlive(function(note:NoteSelection) {
					removeNote(note.strumTime, note.column);
				});

				selectedNotes = [];
				refreshSelectedNotes();

				updateReplaceTypeList();
				refreshNotes();
				refreshSustains();
				suspendSelection = false;
			}
			confirm.noFunc = function() {
				suspendSelection = false;
			}
			confirm.cameras = [camHUD];
		}

		if (Options.mouseJustPressed() && !DropdownMenu.isOneActive && !FlxG.mouse.overlaps(tabMenu) && !FlxG.mouse.overlaps(tabButtons))
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
				eventText.forEachAlive(function(txt:FlxText)
					{
						if (txt.overlaps(mousePos))
							myEvent = eventText.members.indexOf(txt);
					}
				);
				if (myEvent > -1)
				{
					tabButtons.selectTabByName("Events");
					eventListDropdown.value = myEvent+1;
					eventListDropdown.onChanged();
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

		if (Options.mouseJustPressed(true))
		{
			notes.forEachAlive(function(note:Note) {
				if (note.overlaps(mousePos))
				{
					var sec:Int = removeNote(note.strumTime, note.column);
					if (sec > -1)
					{
						updateReplaceTypeList();
						refreshNotes();
						refreshSustains();
						selectedNotes = [];
						refreshSelectedNotes();
					}
				}
			});
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
					if (tracks[0].time < tracks[i].length && Math.abs(tracks[0].time - tracks[i].time) > 50)
						tracks[i].time = tracks[0].time;
				}
			}

			var tickColumns:Array<Bool> = [];
			for (i in 0...numColumns)
			{
				if (noteTick.value >= 0)
				{
					if (songData.columnDivisions[i] == noteTick.valueInt)
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
					if (tickColumns[note[1]] && !note[2])
					{
						if (!hasTicked)
							FlxG.sound.play(Paths.sound("noteTick"));
						hasTicked = true;
						note[2] = true;
					}
				}
			}
		}
		else if (FlxG.mouse.wheel != 0 && !DropdownMenu.isOneActive && !ObjectMenu.isOneActive)
		{
			var scroll:Float = FlxG.mouse.wheel;
			if (downscroll)
				scroll = -scroll;
			if (songProgress - scroll >= 0 && songProgress - scroll <= Conductor.stepFromTime(tracks[0].length))
			{
				songProgress -= scroll * (16 / snap);
				songProgress = Math.max(0, Math.min(Conductor.stepFromTime(tracks[0].length), songProgress));
				snapSongProgress();
			}
		}
		curSection = secFromStep(Std.int(Math.floor(songProgress)));

		Conductor.songPosition = Conductor.timeFromStep(songProgress);
		camFollow.y = Std.int((songProgress * NOTE_SIZE * zoom) + (FlxG.height * 0.35));
		if (downscroll)
			camFollow.y = -camFollow.y;

		super.update(elapsed);

		if (((FlxG.keys.justPressed.UP && !downscroll) || (FlxG.keys.justPressed.DOWN && downscroll)) && !Stepper.isOneActive && !FlxG.keys.pressed.SHIFT)
		{
			curSection--;
			curSection = Std.int(Math.min(songData.notes.length-1, Math.max(0, curSection)));
			songProgress = stepFromSec(curSection);
			if (tracks[0].playing)
			{
				tracks[0].time = Math.max(0, Conductor.timeFromStep(songProgress) - songData.offset);
				correctTrackPitch();
			}
		}

		if (((FlxG.keys.justPressed.UP && downscroll) || (FlxG.keys.justPressed.DOWN && !downscroll)) && !Stepper.isOneActive && !FlxG.keys.pressed.SHIFT)
		{
			curSection++;
			curSection = Std.int(Math.min(songData.notes.length-1, Math.max(0, curSection)));
			songProgress = stepFromSec(curSection);
			if (tracks[0].playing)
			{
				tracks[0].time = Math.max(0, Conductor.timeFromStep(songProgress) - songData.offset);
				correctTrackPitch();
			}
		}

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
				for (t in tracks)
					t.play(true, Math.max(0, Conductor.timeFromStep(songProgress) - songData.offset));
				correctTrackPitch();
				noteTicks = [];
				for (note in noteData)
				{
					if (note[0] >= tracks[0].time + songData.offset)
						noteTicks.push([note[0], note[1], false]);
				}
			}
		}

		if (FlxG.keys.justPressed.ENTER && !suspendControls && !DropdownMenu.isOneActive)
		{
			if (!tracks[0].playing)
			{
				snapSongProgress();
				for (t in tracks)
					t.play(true, Math.max(0, Conductor.timeFromStep(songProgress) - songData.offset), Math.max(0, Conductor.timeFromStep(songProgress + (16 / snap)) - songData.offset));
				correctTrackPitch();
			}
		}

		if (!tracks[0].playing && !DropdownMenu.isOneActive && !Stepper.isOneActive)
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
						{
							if (note[2] > 0)
								doRefreshSustains = true;
							poppers.push(note);
						}
					}
					if (poppers.length > 0)
					{
						for (p in poppers)
							noteData.remove(p);
					}
					else
						makingNotes[i] = songProgress;
					updateReplaceTypeList();
					refreshNotes();
					if (doRefreshSustains)
						refreshSustains();
				}
				if (releasedArray[i] && makingNotes[i] > -1)
				{
					var curSec:Int = secFromStep(Std.int(Math.floor(makingNotes[i])));
					var newNote:Array<Dynamic> = [Conductor.timeFromStep(makingNotes[i]), i, Math.max(0, Conductor.timeFromStep(songProgress) - Conductor.timeFromStep(makingNotes[i]))];
					if (noteTypeInput.text != "")
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

					makingNotes[i] = -1;
					noteData.push(newNote);
					updateReplaceTypeList();
					refreshNotes();
					refreshSustains();
				}
			}
		}

		if (FlxG.keys.justPressed.A && !DropdownMenu.isOneActive && snap > 4 && !suspendControls && !FlxG.keys.pressed.CONTROL)
		{
			snap -= 4;
			snapSongProgress();
		}

		if (FlxG.keys.justPressed.S && !DropdownMenu.isOneActive && !suspendControls && !FlxG.keys.pressed.CONTROL)
		{
			snap += 4;
			snapSongProgress();
		}

		if (FlxG.keys.justPressed.Z && !DropdownMenu.isOneActive && zoom > 0.25 && !suspendControls)
		{
			zoom -= 0.25;

			refreshSectionLines();
			refreshSectionIcons();
			repositionSustains();
			repositionNotes();
			refreshBPMLines();
			refreshEventLines();
			refreshGhostNotes();
			refreshSelectedNotes();
		}

		if (FlxG.keys.justPressed.X && !DropdownMenu.isOneActive && !suspendControls)
		{
			zoom += 0.25;

			refreshSectionLines();
			refreshSectionIcons();
			repositionSustains();
			repositionNotes();
			refreshBPMLines();
			refreshEventLines();
			refreshGhostNotes();
			refreshSelectedNotes();
		}

		if (prevSongProgress != songProgress)
		{
			bpmStepper.value = Conductor.bpm;
			for (s in songData.scrollSpeeds)
			{
				if (songProgress / 4 >= s[0])
					scrollSpeedStepper.value = s[1];
			}
		}

		if (prevSection != curSection)
		{
			var sec:SectionData = songData.notes[curSection];
			sectionCamOnStepper.value = sec.camOn + 1;
			sectionLengthStepper.value = sec.lengthInSteps;
			defaultNoteP1Input.text = (sec.defaultNoteP1 == null ? "" : sec.defaultNoteP1);
			defaultNoteP2Input.text = (sec.defaultNoteP2 == null ? "" : sec.defaultNoteP2);
			refreshGhostNotes();
		}

		refreshInfoText();
		prevSongProgress = songProgress;
		prevSection = curSection;

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new EditorMenuState());
	}

	function refreshCharacters()
	{
		characterList.forEachAlive(function(thing:FlxSprite)
		{
			thing.kill();
			thing.destroy();
		});
		characterList.clear();

		characterNotetypes.forEachAlive(function(thing:FlxSprite)
		{
			thing.kill();
			thing.destroy();
		});
		characterNotetypes.clear();

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

		var yy:Int = 130;
		var newCharacterList:Array<FlxSprite> = [];
		var newCharacterNotetypes:Array<FlxSprite> = [];
		for (i in 0...charCount)
		{
			var charDropdown:DropdownMenu = new DropdownMenu(10, yy, 230, 20, Reflect.field(songData, "player" + Std.string(i+1)), characterFileList, 12, true);
			charDropdown.onChanged = function() {
				Reflect.setField(songData, "player" + Std.string(i+1), charDropdown.value);
				refreshSectionIcons();
			};
			newCharacterList.push(charDropdown);
			newCharacterList.push(new Label("Character "+Std.string(i+1)+":", charDropdown));

			var charNotetypesText:String = "";
			if (songData.notetypeSingers[i].length > 0)
				charNotetypesText = songData.notetypeSingers[i].join(",");
			var charNotetypes:InputText = new InputText(10, charDropdown.y, 230, charNotetypesText);
			charNotetypes.focusGained = function() {
				if (songData.notetypeSingers[i].length > 0)
					charNotetypes.text = songData.notetypeSingers[i].join(",");
				else
					charNotetypes.text = "";
				suspendControls = true;
			}
			charNotetypes.focusLost = function() { refreshSectionIcons(); suspendControls = false; }
			charNotetypes.callback = function(text:String, action:String) {
				if (text == "")
					songData.notetypeSingers[i] = [];
				else
					songData.notetypeSingers[i] = text.split(",");
			}
			newCharacterNotetypes.push(charNotetypes);
			newCharacterNotetypes.push(new Label("Character "+Std.string(i+1)+":", charDropdown));
			yy += 40;
		}

		for (i in 0...newCharacterList.length)
			characterList.add(newCharacterList[newCharacterList.length-1-i]);

		for (i in 0...newCharacterNotetypes.length)
			characterNotetypes.add(newCharacterNotetypes[newCharacterNotetypes.length-1-i]);
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

		if (tracks.length > 0)
		{
			for (t in tracks)
				t.destroy();

			trackSettings.forEachAlive(function(thing:FlxSprite)
			{
				thing.kill();
				thing.destroy();
			});
			trackSettings.clear();
		}
		tracks = [];

		for (t in songData.tracks)
		{
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

		var yy:Int = 60;
		var newTrackSettings:Array<FlxSprite> = [];
		for (i in 0...songData.tracks.length)
		{
			var trackDropdown:DropdownMenu = new DropdownMenu(10, yy, 115, 20, songData.tracks[i][0], trackList, true);
			newTrackSettings.push(trackDropdown);
			newTrackSettings.push(new Label("Track "+Std.string(i+1)+":", trackDropdown));

			var typeList:Array<String> = ["INST", "VOICES", "PLAYER", "OPPONENT"];
			var typeDropdown:DropdownMenu = new DropdownMenu(125, yy, 115, 20, typeList[songData.tracks[i][1]], typeList);
			typeDropdown.onChanged = function() {
				songData.tracks[i][1] = typeDropdown.valueInt;
			};
			newTrackSettings.push(typeDropdown);
			newTrackSettings.push(new Label("Type:", typeDropdown));
			yy += 40;

			var volStepper:Stepper = new Stepper(10, yy, 230, 20, tracks[i].volume * 10, 1, 0, 10);
			volStepper.onChanged = function() {
				tracks[i].volume = volStepper.value / 10;
			}
			trackDropdown.onChanged = function() {
				songData.tracks[i][0] = trackDropdown.value;
				tracks[i].loadEmbedded(Paths.song(songId, trackDropdown.value));
				tracks[i].volume = volStepper.value / 10;
			};
			newTrackSettings.push(volStepper);
			newTrackSettings.push(new Label("Volume (Editor):", volStepper));
			yy += 40;
		}

		for (i in 0...newTrackSettings.length)
			trackSettings.add(newTrackSettings[newTrackSettings.length-1-i]);
	}

	function correctTrackPitch(?forced:Bool = false)
	{
		if (playbackRate == 1 && !forced) return;

		for (t in tracks)
		{
			@:privateAccess
			if (t.playing)
				AL.sourcef(t._channel.__source.__backend.handle, AL.PITCH, playbackRate);
		}
	}

	function refreshSectionLines()
	{
		sectionLines.forEachAlive(function(line:FlxSprite)
		{
			line.kill();
			line.destroy();
		});
		sectionLines.clear();

		var divPositions:Array<Int> = [];
		var lastDiv:Int = songData.columnDivisions[0];
		for (i in 0...songData.columnDivisions.length)
		{
			if (songData.columnDivisions[i] != lastDiv)
				divPositions.push(i);
			lastDiv = songData.columnDivisions[i];
		}

		var yy:Int = 0;
		for (i in 0...songData.notes.length)
		{
			var xx:Int = Std.int( (FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) );
			var ww:Int = Std.int(NOTE_SIZE * numColumns);
			var line:FlxSprite = new FlxSprite(xx, yy).makeGraphic(ww, 1, FlxColor.WHITE);
			if (downscroll)
				line.y = -line.y;
			sectionLines.add(line);
			for (j in 0...numColumns + 1)
			{
				var tick:FlxSprite = new FlxSprite(xx + (j * NOTE_SIZE), yy - 10);
				if (divPositions.contains(j))
					tick.makeGraphic(1, Std.int(NOTE_SIZE * zoom * songData.notes[i].lengthInSteps), FlxColor.WHITE);
				else
					tick.makeGraphic(1, 20, FlxColor.WHITE);
				if (downscroll)
				{
					tick.y = -tick.y;
					tick.y -= tick.height;
				}
				sectionLines.add(tick);
			}

			yy += Std.int(NOTE_SIZE * zoom * songData.notes[i].lengthInSteps);
			if (i == songData.notes.length - 1)
			{
				var line2:FlxSprite = new FlxSprite(xx, yy).makeGraphic(ww, 1, FlxColor.WHITE);
				if (downscroll)
					line2.y = -line2.y;
				sectionLines.add(line2);
			}
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
					if (songData.notes[i].camOn == 0 && songData.notes[i].defaultNoteP1 != null && songData.notes[i].defaultNoteP1 != "" && iconTypes.contains(songData.notes[i].defaultNoteP1))
						iconName = iconNames[iconTypes.indexOf(songData.notes[i].defaultNoteP1)];
					if (songData.notes[i].camOn > 0 && songData.notes[i].defaultNoteP2 != null && songData.notes[i].defaultNoteP2 != "" && iconTypes.contains(songData.notes[i].defaultNoteP2))
						iconName = iconNames[iconTypes.indexOf(songData.notes[i].defaultNoteP2)];
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
			strum.kill();
			strum.destroy();
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

		eventText.forEachAlive(function(txt:FlxText)
		{
			txt.kill();
			txt.destroy();
		});
		eventText.clear();

		var doneBeats:Array<Float> = [];
		var doneText:Array<FlxText> = [];

		var xx:Int = Std.int( (FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) );
		var ww:Int = Std.int(NOTE_SIZE * numColumns);

		for (i in 0...songData.events.length)
		{
			var yy:Int = Std.int(songData.events[i].beat * 4 * zoom * NOTE_SIZE);
			var line:FlxSprite = new FlxSprite(xx, yy).makeGraphic(ww, 1, FlxColor.LIME);
			if (downscroll)
				line.y = -line.y;
			eventLines.add(line);

			var text:FlxText = new FlxText(xx + ww + 5, line.y - 10, FlxG.width - xx - ww - 10, Std.string(songData.events[i].type), 12);
			if (Reflect.fields(songData.events[i].parameters).length > 0)
				text.text += "\n" + Std.string(songData.events[i].parameters);
			text.font = "VCR OSD Mono";
			if (eventListDropdown != null && i == eventListDropdown.value - 1)
				text.color = FlxColor.GRAY;
			if (doneBeats.contains(songData.events[i].beat))
			{
				var ii:Int = doneBeats.indexOf(songData.events[i].beat);
				text.y = doneText[ii].y + doneText[ii].height;
				doneText[ii] = text;
			}
			else
			{
				doneBeats.push(songData.events[i].beat);
				doneText.push(text);
			}
			eventText.add(text);
		}
	}

	function refreshNotes(?whichSec:Int = -1, ?forceUpdate:Bool = false)
	{
		var totalNotes:Int = noteData.length;
		for (i in 0...makingNotes.length)
		{
			if (makingNotes[i] > -1)
				totalNotes++;
		}

		while (notes.members.length > totalNotes)
		{
			var popper:Note = notes.members[notes.members.length-1];
			notes.remove(popper, true);
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

			if (notes.members[i].column != noteData[i][1])
			{
				notes.members[i].column = noteData[i][1];
				notes.members[i].strumColumn = strumColumns[noteData[i][1]];
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

			var noteskinType:String = noteTypeFromColumn(noteData[i][1]);
			if (notes.members[i].noteskinType != noteskinType)
				updateThis = true;

			if (updateThis)
			{
				notes.members[i].updateTypeData();
				notes.members[i].onNotetypeChanged(noteskinType);

				notes.members[i].setGraphicSize(NOTE_SIZE);
				notes.members[i].updateHitbox();
				notes.members[i].x = Std.int((FlxG.width / 2) - (NOTE_SIZE * numColumns / 2) + (NOTE_SIZE * (noteData[i][1] % numColumns)));
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
		}
	}

	function refreshSustains(?whichSec:Int = -1, ?forceUpdate:Bool = false)
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
			var newNote:EditorSustainNote = new EditorSustainNote(0, 0, 0);
			sustains.add(newNote);
		}

		for (i in 0...noteData.length)
		{
			if (sustains.members[i].refreshVars(noteData[i][0], noteData[i][1], noteData[i][2]) || forceUpdate)
				sustains.members[i].refreshPosition(zoom, downscroll);
		}
	}

	function repositionNotes(?whichSec:Int = -1)
	{
		notes.forEachAlive(function(note:Note)
		{
			note.strumTime = Conductor.timeFromBeat(note.beat);
			if (whichSec <= -1 || timeInSec(note.strumTime, whichSec))
			{
				note.y = Std.int(NOTE_SIZE * zoom * note.beat * 4);
				if (downscroll)
					note.y = -note.y;
				note.y -= note.height / 2;
			}
		});
	}

	function repositionSustains(?whichSec:Int = -1)
	{
		sustains.forEachAlive(function(note:EditorSustainNote)
		{
			note.strumTime = Conductor.timeFromBeat(note.beat);
			note.sustainLength = Conductor.timeFromBeat(note.endBeat) - note.strumTime;
			if (whichSec <= -1 || timeInSec(note.strumTime, whichSec))
				note.refreshPosition(zoom, downscroll);
		});
	}

	function refreshGhostNotes()
	{
		ghostNotes.forEachAlive(function(note:Note)
		{
			note.kill();
			note.destroy();
		});
		ghostNotes.clear();

		if (copyLastStepper.value == 0 || tabButtons.curTabName != "Section")
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

	function refreshInfoText()
	{
		infoText.text = "Position: " + Std.string(Math.round(Conductor.songPosition) / 1000) + "/" + Std.string(tracks[0].length / 1000) +
		"\n(" + FlxStringUtil.formatTime(Conductor.songPosition / 1000) + ")" +
		"\nCurrent Section: " + Std.string(curSection+1) + "/" + Std.string(songData.notes.length) +
		"\nCurrent Beat: " + Std.string(Math.round(songProgress / 4 * 1000) / 1000) +
		"\nCurrent Step: " + Std.string(Math.round(songProgress * 1000) / 1000) +
		"\nCurrent BPM: " + Std.string(Conductor.bpm) +
		"\n\nZoom: " + Std.string(zoom) +
		"\nSnap: " + Std.string(snap);
		if (curNotetype != "")
			infoText.text += "\n\nNote Type: " + curNotetype;
	}

	function refreshUniqueDivisions()
	{
		uniqueDivisions = [];
		strumColumns = [];
		var strumColumnIndex:Array<Int> = [];
		for (i in songData.columnDivisions)
		{
			if (!uniqueDivisions.contains(i))
			{
				uniqueDivisions.push(i);
				strumColumnIndex.push(0);
			}
		}
		for (i in songData.columnDivisions)
		{
			strumColumns.push(strumColumnIndex[i]);
			strumColumnIndex[i]++;
		}
	}

	function noteTypeFromColumn(column:Int):String
	{
		var ind:Int = uniqueDivisions.indexOf(songData.columnDivisions[column]);
		if (ind > -1 && ind < songData.noteType.length)
			return songData.noteType[ind];
		return songData.noteType[0];
	}

	function removeNote(time:Float, col:Int):Int
	{
		var sec:Int = -1;
		var foundNote:Bool = false;
		for (n in noteData)
		{
			if (n[0] == time && n[1] == col && !foundNote)
			{
				foundNote = true;
				sec = secFromTime(n[0]);
				noteData.remove(n);
			}
		}

		return sec;
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

	function snapSongProgress()
	{
		songProgress *= snap / 16;
		songProgress = Math.round(songProgress);
		songProgress /= snap / 16;
	}

	function stepFromSec(sec:Int):Int
	{
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
			sectionNotes: []
		};

		songData.notes.push(newSection);
		songData = Song.timeSections(songData);
		refreshSectionLines();
		refreshSectionIcons(songData.notes.length - 1);
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
			if (s.defaultNoteP1 != null && !replaceTypeList.contains(s.defaultNoteP1))
				replaceTypeList.push(s.defaultNoteP1);

			if (s.defaultNoteP2 != null && !replaceTypeList.contains(s.defaultNoteP2))
				replaceTypeList.push(s.defaultNoteP2);
		}

		Note.refreshNoteTypes(replaceTypeList);

		if (replaceTypeDropdown != null)
		{
			replaceTypeDropdown.valueList = replaceTypeList;
			if (!replaceTypeList.contains(replaceTypeDropdown.value))
				replaceTypeDropdown.value = "";
		}
	}

	function updateEventList()
	{
		ArraySort.sort(songData.events, Song.sortEvents);

		var eventList:Array<String> = [""];
		for (ev in songData.events)
			eventList.push(Std.string(ev.beat) + " | " + ev.type);
		eventListDropdown.valueList = eventList;
		eventListDropdown.value = 0;
	}

	function getEventParams(eventId:String):Array<EventParams>
	{
		var thisEventPath:String = "events/" + eventId;
		if (eventId.startsWith(songIdShort) && !Paths.jsonExists(thisEventPath))
		{
			var newEventName:String = eventId.substr(songIdShort.length + 1);
			if (Paths.jsonExists("songs/" + songId + "/events/" + newEventName))
				thisEventPath = "songs/" + songId + "/events/" + newEventName;
		}
		var ret:Array<EventParams> = cast Paths.json(thisEventPath).parameters;
		return ret;
	}

	function updateEventParams(?eventValues:Int = -1)
	{
		eventParams.forEachAlive(function(thing:FlxSprite)
		{
			thing.kill();
			thing.destroy();
		});
		eventParams.clear();

		var yy:Int = 250;

		var thisEventParams:Array<EventParams> = getEventParams(eventTypeDropdown.value);
		eventParamList = {};
		var newThings:Array<FlxSprite> = [];
		var ii:Int = 0;
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
					var newThing:FlxText = new FlxText(10, yy, 230, p.label, 12);
					newThing.color = FlxColor.BLACK;
					newThing.font = "VCR OSD Mono";
					newThings.push(newThing);
					yy += Std.int(-20 + newThing.height);
					ii--;

				case "invis":
					yy -= 30;

				case "checkbox":
					var newThing:Checkbox = new Checkbox(10, yy, p.label);
					newThing.checked = pValue;
					newThing.onClicked = function() {Reflect.setField(eventParamList, p.id, newThing.checked);}
					newThings.push(newThing);

				case "dropdown":
					yy += 10;
					var newThing:DropdownMenu = new DropdownMenu(10, yy, 230, 20, pValue, p.options, true);
					newThing.onChanged = function() {Reflect.setField(eventParamList, p.id, newThing.value);}

					newThings.push(new Label(p.label, newThing));
					newThings.push(newThing);

				case "dropdownSpecial":
					yy += 10;
					var newOptions:Array<String> = (p.options.length > 1 ? Paths.listFilesSub(p.options[0]+"/"+p.options[1]+"/", ".json") : Paths.listFilesSub("data/"+p.options[0]+"/", ".json"));
					var newThing:DropdownMenu = new DropdownMenu(10, yy, 230, 20, pValue, newOptions, true);
					newThing.onChanged = function() {Reflect.setField(eventParamList, p.id, newThing.value);}

					newThings.push(new Label(p.label, newThing));
					newThings.push(newThing);

				case "stepper":
					if (p.label == "!prev")
					{
						yy -= 30;
						var xx:Float = newThings[newThings.length-2].x;
						var ww:Float = newThings[newThings.length-2].width;
						var newThing:Stepper = new Stepper(xx + ww, yy, ww, 20, pValue, p.increment, p.min, p.max, p.decimals);
						newThing.onChanged = function () {Reflect.setField(eventParamList, p.id, newThing.value);}
						newThings.push(newThing);

						newThings.push(new Label("", newThing));
					}
					else
					{
						yy += 10;
						var ww:Float = 1;
						if (i < thisEventParams.length-1)
						{
							for (j in i+1...thisEventParams.length)
							{
								if (thisEventParams[j].label == "!prev")
									ww++;
								else
									break;
							}
						}
						var newThing:Stepper = new Stepper(10, yy, Std.int(230 / ww), 20, pValue, p.increment, p.min, p.max, p.decimals);
						newThing.onChanged = function () {Reflect.setField(eventParamList, p.id, newThing.value);}
						newThings.push(newThing);

						newThings.push(new Label(p.label, newThing));
					}

				case "string":
					yy += 10;
					var newThing:InputText = new InputText(10, yy, 230, pValue);
					newThing.callback = function(text:String, action:String) {Reflect.setField(eventParamList, p.id, text);}
					newThing.focusGained = function() { suspendControls = true; }
					newThing.focusLost = function() { suspendControls = false; }
					newThings.push(newThing);

					newThings.push(new Label(p.label, newThing));

				case "color":
					var newThing:TextButton = new TextButton(10, yy, 230, p.label);
					newThing.onClicked = function() {
						persistentUpdate = false;
						openSubState(new EventColorSubState(this, p.id, thisEventParams[i+1].id, thisEventParams[i+2].id));
					}
					newThings.push(newThing);
			}
			yy += 30;
			ii++;
		}

		for (i in 0...newThings.length)
			eventParams.add(newThings[newThings.length-1-i]);

		addEventButton.y = tabMenu.y + yy;
		updateEventButton.y = addEventButton.y + 30;
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

	function handleExtraColumns()
	{
		var handler:NotifyBlank = new NotifyBlank(300, 150, "Some notes in this chart fall outside of valid columns.\nWhat do you want to do with them?", this);
		handler.cameras = [camHUD];

		var delete:TextButton = new TextButton(63, 100, 75, 20, "Delete");
		delete.onClicked = function() {
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

			handler.close();
		}
		handler.group.add(delete);

		var replace:TextButton = new TextButton(158, 100, 85, 20, "Replace");
		replace.onClicked = function() {
			handler.close();
			replaceExtraColumns();
		}
		handler.group.add(replace);
	}

	function replaceExtraColumns()
	{
		var totalColumns:Array<Int> = [];

		for (n in noteData)
		{
			if (n[1] >= songData.columnDivisions.length)
			{
				if (!totalColumns.contains(Std.int(Math.floor(n[1] / (songData.columnDivisions.length / 2)))))
					totalColumns.push(Std.int(Math.floor(n[1] / (songData.columnDivisions.length / 2))));
			}
		}

		var handler:NotifyBlank = new NotifyBlank(300, 40 + (totalColumns.length * 40), "", this);
		handler.cameras = [camHUD];

		var replacementDropdowns:Array<DropdownMenu> = [];
		var noteTypeList:Array<String> = Paths.listFilesSub("data/notetypes/", ".json");
		noteTypeList.remove("default");
		noteTypeList.unshift("");

		for (i in 0...totalColumns.length)
		{
			var replacementDropdown:DropdownMenu = new DropdownMenu(50, 25 + (i * 40), 200, 20, "", noteTypeList, true);
			replacementDropdowns.push(replacementDropdown);
			handler.group.add(new Label(Std.string(totalColumns[i] * (songData.columnDivisions.length / 2)) + "-" + Std.string((totalColumns[i] * (songData.columnDivisions.length / 2)) + (songData.columnDivisions.length / 2) - 1) + ":", replacementDropdown));
		}

		var accept:TextButton = new TextButton(113, 10 + (totalColumns.length * 40), 75, 20, "Accept");
		accept.onClicked = function() {
			for (n in noteData)
			{
				if (n[1] >= songData.columnDivisions.length)
				{
					var column:Int = Std.int(Math.floor(n[1] / (songData.columnDivisions.length / 2)));
					var replacement:String = replacementDropdowns[totalColumns.indexOf(column)].value;
					n[1] = n[1] % songData.columnDivisions.length;
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

			handler.close();
		}
		handler.group.add(accept);

		for (i in 0...replacementDropdowns.length)
		{
			var j:Int = (replacementDropdowns.length - i) - 1;
			handler.group.add(replacementDropdowns[j]);
		}
	}



	function prepareChartNoteData(songData:SongData, ?noteData:Array<Array<Dynamic>> = null):SongData
	{
		var savedData:SongData = Song.copy(songData);
		for (s in savedData.notes)
			s.sectionNotes = [];

		for (n in noteData)
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

		if (songData.artist.trim() != "")
			savedData.artist = songData.artist;

		if (songData.music.pause.trim() != "" || songData.music.gameOver.trim() != "" || songData.music.gameOverEnd.trim() != "" || songData.music.results.trim() != "" || songData.music.resultsEnd.trim() != "")
			savedData.music = songData.music;

		if (songData.eventFile != "_events")
			savedData.eventFile = songData.eventFile;

		if (songData.useBeats)
			savedData.useBeats = songData.useBeats;

		if (songData.altSpeedCalc)
			savedData.altSpeedCalc = songData.altSpeedCalc;

		if (songData.bpmMap.length > 1)
			savedData.bpmMap = songData.bpmMap;
		else
			savedData.bpm = songData.bpmMap[0][1];				// For ease of porting charts to other engines

		if (songData.scrollSpeeds.length > 1)
			savedData.scrollSpeeds = songData.scrollSpeeds;
		else
			savedData.speed = songData.scrollSpeeds[0][1];

		if (songData.skipCountdown)
			savedData.skipCountdown = songData.skipCountdown;

		var includeColumnDivisions:Bool = false;
		for (i in 0...songData.columnDivisions.length)
		{
			if (i >= 4 && songData.columnDivisions[i] != 0)
				includeColumnDivisions = true;
			if (i < 4 && songData.columnDivisions[i] != 1)
				includeColumnDivisions = true;
		}
		if (includeColumnDivisions || songData.columnDivisions.length != 8)
			savedData.columnDivisions = songData.columnDivisions;

		var includeColumnDivisionNames:Bool = false;
		if (songData.columnDivisionNames.length != 2)
			includeColumnDivisionNames = true;
		if (songData.columnDivisionNames.length > 0 && songData.columnDivisionNames[0] != "#fpSandboxSide0")
			includeColumnDivisionNames = true;
		if (songData.columnDivisionNames.length > 1 && songData.columnDivisionNames[1] != "#fpSandboxSide1")
			includeColumnDivisionNames = true;

		if (includeColumnDivisionNames)
			savedData.columnDivisionNames = songData.columnDivisionNames;

		var includeSingerColumns:Bool = false;
		for (i in 0...songData.singerColumns.length)
		{
			if (i >= 4 && songData.singerColumns[i] != 0)
				includeSingerColumns = true;
			if (i < 4 && songData.singerColumns[i] != 1)
				includeSingerColumns = true;
		}
		if (includeSingerColumns || songData.singerColumns.length != 8)
			savedData.singerColumns = songData.singerColumns;

		if (songData.noteType[0] != "default" || songData.noteType.length > 1)
			savedData.noteType = songData.noteType;

		if (songData.uiSkin != "default")
			savedData.uiSkin = songData.uiSkin;

		if (songData.tracks[0][0].toLowerCase() != "inst" || songData.tracks[0][1] != 0 || (songData.tracks.length > 1 && (songData.tracks[1][0].toLowerCase() != "voices" || songData.tracks[1][1] != 1)) || songData.tracks.length > 2)
			savedData.tracks = songData.tracks;

		var allNotetypes:Array<String> = [];
		for (s in songData.notes)
		{
			if (s.defaultNoteP1 != null && s.defaultNoteP1 != "" && !allNotetypes.contains(s.defaultNoteP1))
				allNotetypes.push(s.defaultNoteP1);
			if (s.defaultNoteP2 != null && s.defaultNoteP2 != "" && !allNotetypes.contains(s.defaultNoteP2))
				allNotetypes.push(s.defaultNoteP2);

			for (n in s.sectionNotes)
			{
				if (n.length > 3)
				{
					if (!allNotetypes.contains(n[3]))
						allNotetypes.push(n[3]);
				}
			}
		}
		if (allNotetypes.length > 0)
			savedData.allNotetypes = allNotetypes;

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

		var useMustHit:Bool = songData.useMustHit;
		if (!useMustHit)
			savedData.useMustHit = useMustHit;

		var uniqueDivisions:Array<Int> = [];
		for (i in songData.columnDivisions)
		{
			if (!uniqueDivisions.contains(i))
				uniqueDivisions.push(i);
		}
		if (uniqueDivisions.length != 2 || songData.columnDivisions.length % 2 != 0)
		{
			savedData.useMustHit = false;
			useMustHit = false;
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

			for (n in s.sectionNotes)
			{
				var newN:Array<Dynamic> = [n[0], n[1]];
				if (n.length > 2 && (n[2] > 0 || !songData.useBeats || n.length > 3))
					newN.push(n[2]);
				if (songData.useBeats)
				{
					if (newN.length > 2)
						newN[2] = Conductor.beatFromTime(newN[0] + newN[2]) - Conductor.beatFromTime(newN[0]);
					newN[0] = Conductor.beatFromTime(newN[0]) - (s.firstStep / 4.0);
				}
				if (n.length > 3)
				{
					if (allNotetypes.contains(n[3]))
						newN.push(allNotetypes.indexOf(n[3]) + 1);
				}
				if (newS.mustHitSection)
				{
					if (newN[1] % songData.columnDivisions.length >= songData.columnDivisions.length / 2)
						newN[1] -= songData.columnDivisions.length / 2;
					else
						newN[1] += songData.columnDivisions.length / 2;
				}
				newS.sectionNotes.push(newN);
			}

			if (songData.useBeats && i > 0)
			{
				var c:Int = i-1;
				while (savedData.notes[c].copyLast)
					c--;

				if (newS.sectionNotes.length > 0 && newS.lengthInSteps == savedData.notes[c].lengthInSteps && newS.sectionNotes.length == savedData.notes[c].sectionNotes.length)
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
						newS.copyLast = true;
					}
				}
			}

			if (s.defaultNoteP1 != null && s.defaultNoteP1 != "")
				newS.defaultNoteP1 = allNotetypes.indexOf(s.defaultNoteP1) + 1;
			if (s.defaultNoteP2 != null && s.defaultNoteP2 != "")
				newS.defaultNoteP2 = allNotetypes.indexOf(s.defaultNoteP2) + 1;
			savedData.notes.push(newS);
			i++;
		}

		return savedData;
	}

	function unpauseAutosave()
	{
		autosavePaused = false;
	}

	function unpauseAutosaveA(_)
	{
		autosavePaused = false;
	}

	function changeSaveName(path:String)
	{
		filename = path;
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
			filenameText.text = "Chart file has not been saved";
		else if (fn.contains(cwd))
			filenameText.text = fn.replace(cwd, "");
		else
			filenameText.text = "???/" + fn.substring(fn.lastIndexOf("/")+1, fn.length);
		filenameText.screenCenter(X);
	}

	function saveChart()
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
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = changeSaveName;
			file.failureCallback = unpauseAutosave;
			var defName:String = (filename == "" ? songId + ".json" : filename);
			file.save(defName, data.trim());
		}
	}

	function loadChart()
	{
		autosavePaused = true;

		var file:FileBrowser = new FileBrowser();
		file.loadCallback = loadChartCallback;
		file.failureCallback = unpauseAutosave;
		file.load("json;*.sm");
	}

	function loadChartCallback(fullPath:String)
	{
		var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (jsonNameArray.indexOf("songs") == -1 && jsonNameArray.indexOf("sm") == -1)
		{
			Application.current.window.alert("The file you have selected is not a chart.", "Alert");
			autosavePaused = false;
		}
		else
		{
			if (jsonNameArray.indexOf("sm") != -1)
			{
				while (jsonNameArray[0] != "sm")
					jsonNameArray.remove(jsonNameArray[0]);
				jsonNameArray.remove(jsonNameArray[0]);

				newChart = false;
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

				newChart = false;
				songId = songIdArray.join("/");
				songFile = jsonNameArray.join("/").split('.json')[0];
			}
			ChartEditorState.filename = fullPath;
			FlxG.switchState(new ChartEditorState());
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

	private function saveEvents()
	{
		autosavePaused = true;
		var savedEventData:Array<EventData> = [];
		for (e in songData.events)
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

		for (e in songData.events)
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

		var data:String = Json.stringify({eventData: savedEventData, events: savedEvents});

		if (data != null && data.length > 0)
		{
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = unpauseAutosaveA;
			file.failureCallback = unpauseAutosave;
			file.save(songData.eventFile + ".json", data.trim());
		}
	}

	function saveSM()
	{
		autosavePaused = true;

		var data:String = SMFile.save(songData, noteData);

		if (data != null && data.length > 0)
		{
			var file:FileBrowser = new FileBrowser();
			file.saveCallback = unpauseAutosaveA;
			file.failureCallback = unpauseAutosave;
			file.save(songId + ".sm", data.trim());
		}
	}



	var addingEvents:Bool = false;
	function loadEvents(add:Bool)
	{
		autosavePaused = true;
		addingEvents = add;

		var file:FileBrowser = new FileBrowser();
		file.loadCallback = loadEventsCallback;
		file.failureCallback = unpauseAutosave;
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

			var notify:NotifyBlank = new NotifyBlank(300, 200, notifyString, this);
			notify.cameras = [camHUD];

			var ok:TextButton = new TextButton(10, 170, 140, 20, "#ok");
			ok.onClicked = function() {
				notify.close();
			}
			notify.group.add(ok);

			var makeCustom:TextButton = new TextButton(150, 170, 140, 20, "Make Custom");
			makeCustom.onClicked = function() {
				for (e in unmatchedCustoms)
					songData.events.push(e);
				updateEventList();
				refreshEventLines();
				notify.close();
			}
			notify.group.add(makeCustom);
		}
	}

	function copyCamsFromFile()
	{
		autosavePaused = true;

		var file:FileBrowser = new FileBrowser();
		file.loadCallback = copyCamsFromFileCallback;
		file.failureCallback = unpauseAutosave;
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
}

class EventColorSubState extends FlxSubState
{
	override public function new(state:ChartEditorState, rVal:String, gVal:String, bVal:String)
	{
		super();

		var tabMenu:IsolatedTabMenu = new IsolatedTabMenu(0, 0, 300, 260);
		tabMenu.screenCenter();
		add(tabMenu);

		var tabGroupColor = new TabGroup();

		var ol1:FlxSprite = new FlxSprite(48, 8).makeGraphic(204, 34, FlxColor.BLACK);
		tabGroupColor.add(ol1);

		var ol2:FlxSprite = new FlxSprite(48, 48).makeGraphic(144, 144, FlxColor.BLACK);
		tabGroupColor.add(ol2);

		var ol3:FlxSprite = new FlxSprite(218, 48).makeGraphic(34, 144, FlxColor.BLACK);
		tabGroupColor.add(ol3);

		var colorThing:FlxSprite = new FlxSprite(50, 10).makeGraphic(200, 30, FlxColor.WHITE);
		colorThing.color = FlxColor.fromRGB(Reflect.field(state.eventParamList, rVal), Reflect.field(state.eventParamList, gVal), Reflect.field(state.eventParamList, bVal));
		tabGroupColor.add(colorThing);

		var colorSwatch:ColorSwatch = new ColorSwatch(50, 50, 140, 140, 30, colorThing.color);
		tabGroupColor.add(colorSwatch);

		var stepperR:Stepper = new Stepper(20, 200, 80, 20, colorThing.color.red, 5, 0, 255);
		var stepperG:Stepper = new Stepper(110, 200, 80, 20, colorThing.color.green, 5, 0, 255);
		var stepperB:Stepper = new Stepper(200, 200, 80, 20, colorThing.color.blue, 5, 0, 255);

		stepperR.onChanged = function() { colorSwatch.r = stepperR.valueInt; colorThing.color = colorSwatch.swatchColor; }
		tabGroupColor.add(stepperR);

		stepperG.onChanged = function() { colorSwatch.g = stepperG.valueInt; colorThing.color = colorSwatch.swatchColor; }
		tabGroupColor.add(stepperG);

		stepperB.onChanged = function() { colorSwatch.b = stepperB.valueInt; colorThing.color = colorSwatch.swatchColor; }
		tabGroupColor.add(stepperB);

		colorSwatch.onChanged = function() { colorThing.color = colorSwatch.swatchColor; stepperR.value = colorSwatch.r; stepperG.value = colorSwatch.g; stepperB.value = colorSwatch.b; }

		var acceptButton:TextButton = new TextButton(20, 230, 260, 20, "#accept");
		acceptButton.onClicked = function()
		{
			Reflect.setField(state.eventParamList, rVal, colorThing.color.red);
			Reflect.setField(state.eventParamList, gVal, colorThing.color.green);
			Reflect.setField(state.eventParamList, bVal, colorThing.color.blue);
			close();
		};
		tabGroupColor.add(acceptButton);

		tabMenu.addGroup(tabGroupColor);

		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}
}