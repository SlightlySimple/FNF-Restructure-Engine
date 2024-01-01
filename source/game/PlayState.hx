package game;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;
import openfl.utils.Assets;
import openfl.events.KeyboardEvent;
import haxe.ds.ArraySort;
import lime.app.Application;
import lime.media.openal.AL;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import data.Noteskins;
import data.ObjectData;
import data.Options;
import data.ScoreSystems;
import data.Song;
import data.SMFile;
import data.TimingStruct;
import editors.ChartEditorState;
import objects.AnimatedSprite;
import objects.Character;
import objects.FunkBar;
import objects.HealthIcon;
import objects.Note;
import objects.RatingPopup;
import objects.SongArtist;
import objects.Stage;
import objects.StrumNote;
import menus.MainMenuState;
import menus.StoryMenuState;
import menus.FreeplayMenuState;
import menus.PauseSubState;
import menus.OptionsMenuState;
import scripting.HscriptHandler;
import scripting.HscriptSprite;
import scripting.HscriptState;
import scripting.LuaModule;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState = null;
	public static var firstPlay:Bool = true;

	public static var testingChart:Bool = false;
	public static var testingChartData:SongData = null;
	public static var testingChartPos:Float = 0;

	public static var songId:String = "";
	public static var songIdShort:String = "";
	public static var difficulty:String = "normal";
	public static var deaths:Int = 0;
	public var songData:SongData = null;
	public var songName:String = "";
	public var isSM:Bool = false;
	public var smData:SMFile = null;
	public var uniqueDivisions:Array<Int> = [];
	public var strumColumns:Array<Int> = [];
	public var notesSpawn:Array<NoteData> = [];
	public var notes:FlxTypedSpriteGroup<Note>;
	public var sustainNotes:FlxTypedSpriteGroup<SustainNote>;
	public var strumNotes:FlxTypedSpriteGroup<StrumNote>;
	public var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;
	public var laneBackgrounds:FlxSpriteGroup;
	public var noteType:Array<String> = [];
	public var uiSkin:UISkin;
	public var missSounds:Array<String> = ["missnote1", "missnote2", "missnote3"];

	public var noteModFunctions:Array<(Note,Float)->Void> = [];
	public var sustainModFunctions:Array<(SustainNote,Float)->Void> = [];

	public var songStartPos:Float = 0;
	public var songEndPos:Float = 0;
	public var canSkipStart:Bool = false;
	public var skipStartText:FlxText;

	public var camFollow:FlxObject;
	public var camFollowPos:FlxObject;
	public var camFollowRate:Float = 0.04;
	public static var prevCamFollow:FlxObject = null;
	public var camFocus:Character = null;
	public var updateCamFocus:Bool = true;
	public var overrideCamFocus:Bool = false;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;
	public var camZoom:Float = 1;

	public var camBumpSequence:Array<Bool> = [true,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false];
	public var camBumpSequenceProgress:Int = 0;
	public var camBumpRate(default, set):Float = 4;
	public var camBumpOnBeat:Bool = false;
	public var camBumpLast:Int = -1;

	public var paused:Bool = false;
	public static var botplay:Bool = false;
	public var botplayText:FlxText;
	public var chartSide:Int = 0;
	public var playerColumns:Array<Int> = [];
	public var canSaveScore:Bool = true;

	public var tracks:Array<FlxSound> = [];
	var trackTypes:Array<Int> = [];
	var songProgress:Float;
	var songProgressVisual:Float = -1;
	var songLengthVisual:Float = 0;
	public var playbackRate:Float = 1;
	var curSection:Int = 0;
	public var totalOffset:Float = 0;

	public static var storyWeek:Array<String> = [];
	public static var storyWeekName:String = "";
	public static var storyProgress:Int = 0;
	public static var inStoryMode:Bool = false;

	public var scores:ScoreSystems = null;
	public var scoreTxt:FlxText;
	public var judgementCounter:FlxText;
	public var ratingPopups:FlxTypedSpriteGroup<RatingPopup>;

	public var stage:Stage = null;
	public var allCharacters:Array<Character> = [];
	public var allReactors:Array<Character> = [];
	public var notetypeSingers:Map<String, Array<Character>> = new Map<String, Array<Character>>();
	public var player1:Character = null;
	public var player2:Character = null;
	public var gf:Character = null;

	public var myScripts:Map<String, HscriptHandler>;
	public var myLuaScripts:Map<String, LuaModule>;

	public var numKeys:Int = 4;
	public var keysArray:Array<Array<FlxKey>>;
	var holdArray:Array<Bool>;
	public var suspendControls(default, set):Bool = false;

	var health:Float = 50;
	var healthGraphInfo:Array<Array<Float>> = [];
	var healthBar:FunkBar;
	var healthIconP1:HealthIcon;
	var healthIconP2:HealthIcon;
	var healthIcons(default, set):Array<HealthIcon> = [];
	public var iconBumpRate:Float = 1;
	var songProgressBar:FunkBar;
	var songProgressText:FlxText;

	var msText:FlxText;

	override public function new(?_inStoryMode:Bool = null, ?_songId:String = null, ?_difficulty:String = null, ?_storyWeekName:String = null, ?_storyProgress:Int = null)
	{
		if (_inStoryMode != null)
			inStoryMode = _inStoryMode;

		if (_songId != null)
		{
			songId = _songId;
			deaths = 0;
		}

		if (_difficulty != null)
		{
			difficulty = _difficulty;
			deaths = 0;
		}

		if (inStoryMode && _storyWeekName != null)
		{
			storyWeekName = _storyWeekName;
			storyWeek = [];
			var songArray:Array<WeekSongData> = StoryMenuState.convertWeek(storyWeekName, true).songs;
			for (s in songArray)
			{
				if (s.songId != null && s.songId != "")
					storyWeek.push(s.songId);
			}
		}

		if (_storyProgress != null)
		{
			storyProgress = _storyProgress;
			deaths = 0;
		}

		super();
	}

	override public function create()
	{
		instance = this;
		if (storyProgress == 0 || !inStoryMode)
			botplay = Options.options.botplay;
		SustainNote.noteGraphics.clear();

		if (inStoryMode)
			songId = storyWeek[storyProgress];
		else if (!testingChart)
			playbackRate = FreeplaySandbox.playbackRate;
		songIdShort = songId.substring(songId.lastIndexOf("/")+1, songId.length);

		if (testingChart)
			songData = Song.copy(testingChartData);
		else if (Paths.smExists(songId))
		{
			smData = SMFile.load(songId);
			songData = smData.songData[smData.difficulties.indexOf(difficulty)];
			isSM = true;
		}
		else
			songData = Song.loadSong(songId, difficulty);

		songName = Song.getSongNameFromData(songId, songData);
		skipCountdown = songData.skipCountdown;
		Conductor.recalculateTimings(songData.bpmMap);
		numKeys = Std.int(Math.ceil(songData.columnDivisions.length / 2));
		if (numKeys <= 0)
			numKeys = 4;

		totalOffset = songData.offset - Options.options.offset;

		noteType = songData.noteType;
		uiSkin = cast Paths.jsonImages('ui/skins/' + songData.uiSkin);
		RatingPopup.sparrows = new Map<String, Bool>();

		for (n in noteType)
		{
			var skindef:NoteskinTypedef = Noteskins.getData(Noteskins.noteskinName, n);
			for (asset in skindef.assets)
			{
				if (Paths.imageExists("noteskins/" + skindef.skinName + "/" + asset[0]))
					Paths.cacheGraphic("noteskins/" + skindef.skinName + "/" + asset[0]);
				else
					Paths.cacheGraphic("noteskins/" + asset[0]);
			}
		}

		for (s in uiSkin.countdown)
		{
			if (s.asset != null && Paths.imageExists("ui/skins/" + songData.uiSkin + "/" + s.asset))
				Paths.cacheGraphic("ui/skins/" + songData.uiSkin + "/" + s.asset);
		}

		for (s in uiSkin.judgements)
		{
			if (s.asset != null && Paths.imageExists("ui/skins/" + songData.uiSkin + "/" + s.asset))
				Paths.cacheGraphic("ui/skins/" + songData.uiSkin + "/" + s.asset);
		}

		if (uiSkin.combo.asset != null && Paths.imageExists("ui/skins/" + songData.uiSkin + "/" + uiSkin.combo.asset))
			Paths.cacheGraphic("ui/skins/" + songData.uiSkin + "/" + uiSkin.combo.asset);

		for (s in uiSkin.numbers)
		{
			if (s.asset != null && Paths.imageExists("ui/skins/" + songData.uiSkin + "/" + s.asset))
				Paths.cacheGraphic("ui/skins/" + songData.uiSkin + "/" + s.asset);
		}

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
		if (uniqueDivisions.length > noteType.length)
			uniqueDivisions.resize(noteType.length);

		if (!inStoryMode && !testingChart)
		{
			if (FreeplaySandbox.stage != "")
				songData.stage = FreeplaySandbox.stage;
			chartSide = FreeplaySandbox.chartSide;
		}
		playerColumns = [];
		for (i in 0...songData.columnDivisions.length)
		{
			if (songData.columnDivisions[i] == chartSide)
				playerColumns.push(i);
		}

		GameOverSubState.resetStatics();

		if (songData.music.pause != null && songData.music.pause != "")
			PauseSubState.music = songData.music.pause;

		if (songData.music.gameOver != null && songData.music.gameOver != "")
			GameOverSubState.gameOverMusic = songData.music.gameOver;

		if (songData.music.gameOverEnd != null && songData.music.gameOverEnd != "")
			GameOverSubState.gameOverMusicEnd = songData.music.gameOverEnd;

		if (songData.music.results != null && songData.music.results != "")
			ResultsSubState.music = songData.music.results;

		if (songData.music.resultsEnd != null && songData.music.resultsEnd != "")
			ResultsSubState.musicEnd = songData.music.resultsEnd;

		camFollow = new FlxObject();
		camFollowPos = new FlxObject();

		camHUD = new FlxCamera();
		camHUD.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camHUD, false);

		camOther = new FlxCamera();
		camOther.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camOther, false);

		super.create();

		var curStage:String = TitleState.defaultVariables.stage;
		if (songData.stage != null && songData.stage != "")
			curStage = songData.stage;

		changeStage(curStage, false);

		var i:Int = 1;
		while (Reflect.hasField(songData, "player" + Std.string(i)))
		{
			spawnCharacter(Reflect.field(songData, "player" + Std.string(i)));
			i++;
		}

		player1 = allCharacters[0];
		player2 = allCharacters[1];
		if (allCharacters.length > 2)
		{
			gf = allCharacters[2];
			allReactors.push(gf);
		}

		for (s in songData.notetypeSingers)
		{
			for (n in s)
			{
				if (notetypeSingers.exists(n))
					notetypeSingers[n].push(allCharacters[songData.notetypeSingers.indexOf(s)]);
				else
					notetypeSingers[n] = [allCharacters[songData.notetypeSingers.indexOf(s)]];
			}
		}

		var songPath:String = Paths.song(songId, songData.tracks[0][0]);
		if (isSM)
			songPath = Paths.smSong(songId, smData.ogg);

		if (!Assets.exists(songPath))
		{
			Application.current.window.alert("The song could not be loaded. Check that the file exists: " + songPath, "Alert");
			gotoMenuState(false);
		}

		songProgress = 0;
		Conductor.overrideSongPosition = true;
		if (isSM)
		{
			FlxG.sound.cache(Paths.smSong(songId, smData.ogg));
			var newTrack:FlxSound = new FlxSound().loadEmbedded(Paths.smSong(songId, smData.ogg), false, true);
			if (playbackRate < 1)
				newTrack.makeEvent = false;
			FlxG.sound.list.add(newTrack);
			tracks.push(newTrack);
			trackTypes.push(0);
		}
		else
		{
			for (t in songData.tracks)
			{
				var tPath:String = "";
				if (t[1] == 2 && Paths.songExists(songId, t[0] + "_" + player1.curCharacter))
					tPath = "_" + player1.curCharacter;
				else if (t[1] == 3 && Paths.songExists(songId, t[0] + "_" + player2.curCharacter))
					tPath = "_" + player2.curCharacter;
				FlxG.sound.cache(Paths.song(songId, t[0] + tPath));
				var newTrack:FlxSound = new FlxSound().loadEmbedded(Paths.song(songId, t[0] + tPath), false, true);
				if (playbackRate < 1)
					newTrack.makeEvent = false;
				FlxG.sound.list.add(newTrack);
				tracks.push(newTrack);
				trackTypes.push(t[1]);
			}
		}

		var noteTypes:Array<String> = generateSong();
		Note.refreshNoteTypes(noteTypes, true);
		for (n in noteTypes)
		{
			if (Note.noteTypes.exists(n) && Note.noteTypes[n].singers != null && !notetypeSingers.exists(n))
			{
				notetypeSingers[n] = [];
				for (s in Note.noteTypes[n].singers)
				{
					if (allCharacters.length > s)
						notetypeSingers[n].push(allCharacters[s]);
				}
			}
		}

		FlxG.camera.zoom = camZoom;
		camFollow.x = stage.stageData.camFollow[0];
		camFollow.y = stage.stageData.camFollow[1];

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		camFollowPos.x = camFollow.x;
		camFollowPos.y = camFollow.y;
		FlxG.camera.follow(camFollowPos, LOCKON);
		FlxG.camera.focusOn(camFollowPos.getPosition());

		laneBackgrounds = new FlxSpriteGroup();
		laneBackgrounds.cameras = [camHUD];
		add(laneBackgrounds);

		ratingPopups = new FlxTypedSpriteGroup<RatingPopup>();
		ratingPopups.cameras = [camHUD];
		add(ratingPopups);

		strumNotes = new FlxTypedSpriteGroup<StrumNote>();
		strumNotes.cameras = [camHUD];
		add(strumNotes);

		spawnStrumNotes();
		setupScrollSpeeds();

		if (Options.options.middlescroll)
			spawnLaneBackgrounds([[playerColumns[0], playerColumns[playerColumns.length - 1]]]);
		else
		{
			var laneBGs:Array<Array<Int>> = [];
			var start:Int = 0;
			var lastNum:Int = songData.columnDivisions[0];
			for (i in 0...songData.columnDivisions.length)
			{
				if (songData.columnDivisions[i] != lastNum)
				{
					laneBGs.push([start, i - 1]);
					start = i;
					lastNum = songData.columnDivisions[i];
				}
			}
			laneBGs.push([start, songData.columnDivisions.length - 1]);
			spawnLaneBackgrounds(laneBGs);
		}

		sustainNotes = new FlxTypedSpriteGroup<SustainNote>();
		sustainNotes.cameras = [camHUD];
		add(sustainNotes);

		notes = new FlxTypedSpriteGroup<Note>();
		notes.cameras = [camHUD];
		add(notes);

		noteSplashes = new FlxTypedSpriteGroup<NoteSplash>();
		noteSplashes.cameras = [camHUD];
		add(noteSplashes);

		for (n in noteType)
		{
			var skindef:NoteskinTypedef = Noteskins.getData(Noteskins.noteskinName, n);
			Paths.cacheGraphic("ui/note_splashes/" + skindef.splashAsset);
		}

		keysArray = [Options.options.keys.note_left, Options.options.keys.note_down, Options.options.keys.note_up, Options.options.keys.note_right];
		holdArray = [];
		for (i in songData.columnDivisions)
		{
			if (i == chartSide)
				holdArray.push(false);
		}

		health = 50;

		healthBar = new FunkBar(0, FlxG.height * 0.9, (strumNotes.members[playerColumns[0]].singers[0].wasFlipped ? RIGHT_TO_LEFT : LEFT_TO_RIGHT), 600, 20, this, "health", 0, 100);
		healthBar.borderWidth = 4;
		healthBar.createFilledBar(Options.options.healthBarColorL, Options.options.healthBarColorR, true, FlxColor.BLACK);
		if (Options.options.downscroll)
			healthBar.y = FlxG.height * 0.1;
		healthBar.screenCenter(X);
		healthBar.cameras = [camHUD];
		healthBar.visible = Options.options.healthBar;
		add(healthBar);

		var iconCharacters:Array<Character> = [];
		for (i in 0...strumNotes.members.length)
		{
			if (!playerColumns.contains(i))
			{
				iconCharacters.push(strumNotes.members[i].singers[0]);
				break;
			}
		}
		iconCharacters.push(strumNotes.members[playerColumns[0]].singers[0]);
		if (iconCharacters.length < 2)
		{
			if (iconCharacters.contains(player2))
				iconCharacters.unshift(player1);
			else
				iconCharacters.unshift(player2);
		}

		var p1:Character = (chartSide > 0 ? iconCharacters[0] : iconCharacters[1]);
		healthIconP1 = new HealthIcon(0, healthBar.y, p1.characterData.icon);
		healthIconP1.cameras = [camHUD];
		healthIconP1.visible = Options.options.healthBar && Options.options.healthIcons;
		p1.icon = healthIconP1;
		add(healthIconP1);

		var p2:Character = (chartSide == 0 ? iconCharacters[0] : iconCharacters[1]);
		healthIconP2 = new HealthIcon(0, healthBar.y, p2.characterData.icon);
		healthIconP2.cameras = [camHUD];
		healthIconP2.visible = Options.options.healthBar && Options.options.healthIcons;
		p2.icon = healthIconP2;
		add(healthIconP2);

		if (healthBar.fillDirection == LEFT_TO_RIGHT)
			healthIcons = [healthIconP1, healthIconP2];
		else
			healthIcons = [healthIconP2, healthIconP1];
		if (chartSide > 0)
		{
			healthIcons.reverse();
			healthIcons = healthIcons;
		}

		switch (Options.options.scorePos)
		{
			case 1:
				scoreTxt = new FlxText(10, healthBar.y + 30, 0, "");

			case 2:
				scoreTxt = new FlxText(0, healthBar.y + 30, FlxG.width - 10, "");
				scoreTxt.alignment = RIGHT;

			default:
				scoreTxt = new FlxText(0, healthBar.y + 30, FlxG.width, "");
				scoreTxt.alignment = CENTER;
		}
		scoreTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, scoreTxt.alignment, OUTLINE, FlxColor.BLACK);
		scoreTxt.cameras = [camHUD];
		add(scoreTxt);

		songLengthVisual = tracks[0].length;
		if (Options.options.progressBar == 2)
			songLengthVisual = Conductor.timeFromBeat(songEndPos) - Conductor.timeFromBeat(songStartPos);

		var progressBarW:Int = 500 + Std.int(Math.max(0, getSongProgressText().length - 40) * 10);
		songProgressBar = new FunkBar(0, 25, LEFT_TO_RIGHT, progressBarW, 25, this, "songProgressVisual", 0, Math.max(1, songLengthVisual));
		if (Options.options.downscroll)
			songProgressBar.y = FlxG.height - 50;
		songProgressBar.createFilledBar(Options.options.progressBarColorR, Options.options.progressBarColorL, true, FlxColor.BLACK);
		songProgressBar.cameras = [camHUD];
		songProgressBar.screenCenter(X);
		songProgressBar.visible = (Options.options.progressBar > 0);
		songProgressBar.alpha = 0;
		add(songProgressBar);

		songProgressText = new FlxText(songProgressBar.x, songProgressBar.y + 2, songProgressBar.width, songName).setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		songProgressText.cameras = [camHUD];
		songProgressText.visible = (Options.options.progressBar > 0);
		songProgressText.alpha = 0;
		add(songProgressText);

		skipStartText = new FlxText(0, FlxG.height * 0.75, 0, Lang.get("#skipIntro", [Options.keyString("introSkip")])).setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		skipStartText.screenCenter(X);
		skipStartText.cameras = [camHUD];
		skipStartText.alpha = 0;
		add(skipStartText);

		if (Conductor.timeFromBeat(songStartPos) >= 3000 && Conductor.timeFromBeat(songStartPos) < tracks[0].length && !inStoryMode && !testingChart)
			canSkipStart = true;

		countdownTickGroup = new FlxTypedSpriteGroup<CountdownPopup>();
		countdownTickGroup.scrollFactor.set();

		for (i in 0...uiSkin.countdownSounds.length)
		{
			if (uiSkin.countdownSounds[i] != "")
				FlxG.sound.cache(Paths.sound(uiSkin.countdownSounds[i]));
		}

		for (m in missSounds)
			FlxG.sound.cache(Paths.sound(m));
		if (Paths.hitsound() != "")
			FlxG.sound.cache(Paths.hitsound());

		scores = new ScoreSystems();

		if (Options.options.judgementCounter == 2)
		{
			judgementCounter = new FlxText(0, 0, FlxG.width - 10, "");
			judgementCounter.alignment = RIGHT;
		}
		else
			judgementCounter = new FlxText(10, 0, 0, "");
		judgementCounter.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, judgementCounter.alignment, OUTLINE, FlxColor.BLACK);
		updateJudgementCounter();
		judgementCounter.screenCenter(Y);
		if (Options.options.judgementCounter == Options.options.scorePos)
			judgementCounter.y -= FlxG.height / 6;
		judgementCounter.cameras = [camHUD];
		judgementCounter.visible = Options.options.judgementCounter > 0;
		add(judgementCounter);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyReleased);

		msText = new FlxText(0, Std.int(FlxG.height * 2 / 3), 0, '', 24);
		msText.borderColor = FlxColor.BLACK;
		msText.borderStyle = OUTLINE;
		msText.cameras = [camHUD];
		msText.alpha = 0;
		add(msText);

		botplayText = new FlxText(0, 250, 0, Lang.get("#botplay"), 32);
		botplayText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		botplayText.cameras = [camHUD];
		botplayText.screenCenter(X);
		if (botplay)
			add(botplayText);

		if (testingChart)
		{
			var playtestText:FlxText = new FlxText(0, 300, 0, Lang.get("#playtest"), 32);
			playtestText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			playtestText.cameras = [camHUD];
			playtestText.screenCenter(X);
			add(playtestText);
		}

		myScripts = new Map<String, HscriptHandler>();
		myLuaScripts = new Map<String, LuaModule>();
		var autorunScripts:Array<String> = Paths.listFiles('data/autorun/', '.hscript');
		if (autorunScripts.length > 0)
		{
			for (a in autorunScripts)
				hscriptAdd('AUTORUN_' + a, 'data/autorun/' + a);
		}
		if (isSM)
		{
			var pathArray:Array<String> = songId.replace("\\","/").split("/");
			pathArray.pop();
			var songScripts:Array<String> = Paths.listFiles('sm/' + pathArray.join("/") + '/', '.hscript');
			if (songScripts.length > 0)
			{
				for (s in songScripts)
					hscriptAdd('SONG_' + s, 'sm/' + pathArray.join("/") + '/' + s);
			}
		}
		else
		{
			var songScripts:Array<String> = Paths.listFiles('data/songs/' + songId + '/', '.hscript');
			if (songScripts.length > 0)
			{
				for (s in songScripts)
					hscriptAdd('SONG_' + s, 'data/songs/' + songId + '/' + s);
			}
			if (songId.indexOf("/") != -1)
			{
				var songIdStart:String = songId.substring(0, songId.indexOf("/"));
				var weekScripts:Array<String> = Paths.listFiles('data/songs/' + songIdStart + '/', '.hscript');
				if (weekScripts.length > 0)
				{
					for (s in weekScripts)
						hscriptAdd('WEEK_' + s, 'data/songs/' + songIdStart + '/' + s);
				}
			}
		}
		hscriptAdd('player1', 'data/' + player1.characterData.script, false, player1);
		hscriptAdd('player2', 'data/' + player2.characterData.script, false, player2);
		if (gf != null)
			hscriptAdd('gf', 'data/' + gf.characterData.script, false, gf);
		hscriptAdd('stage', 'data/' + stage.stageData.script);
		hscriptIdSet('stage', 'stage', stage);
		hscriptAdd('NOTESKIN', 'images/noteskins/' + Noteskins.noteskinName);
		for (i in 0...noteTypes.length)
		{
			if (noteTypes[i] != "")
				hscriptAdd('NOTETYPE_' + noteTypes[i].replace("/","_"), 'data/notetypes/' + noteTypes[i]);
		}
		if (songData.events.length > 0)
		{
			for (i in 0...songData.events.length)
			{
				if (songData.events[i].type.startsWith(songIdShort) && Paths.hscriptExists('data/songs/' + songId + '/events/' + songData.events[i].typeShort))
					hscriptAdd('EVENT_' + songData.events[i].type.replace("/","_"), 'data/songs/' + songId + '/events/' + songData.events[i].typeShort);
				else
					hscriptAdd('EVENT_' + songData.events[i].type.replace("/","_"), 'data/events/' + songData.events[i].type);
			}
		}

		hscriptExec("create");
		if (allCharacters.length > 3)
		{
			for (i in 3...allCharacters.length)
			{
				hscriptAdd('player' + Std.string(i+1), 'data/' + allCharacters[i].characterData.script, false, allCharacters[i]);
				hscriptIdExec('player' + Std.string(i+1), "create");
			}
		}
		updateScoreText();
		spawnNotes();

		startCountdown();
	}

	public function set_healthIcons(val:Array<HealthIcon>):Array<HealthIcon>
	{
		healthIcons = val;
		val[0].flipX = false;
		val[1].flipX = !val[1].iconData.centered;
		return val;
	}

	function noteTypeFromColumn(column:Int):String
	{
		if (uniqueDivisions.indexOf(songData.columnDivisions[column]) > -1)
			return noteType[uniqueDivisions.indexOf(songData.columnDivisions[column])];
		return noteType[0];
	}

	override public function update(elapsed:Float)
	{
		if (countdownStarted)
		{
			if (tracks[0].playing)
			{
				if (Math.abs((songProgress - totalOffset) - tracks[0].time) > (100 * Math.min(1, playbackRate)))		// Rewind the song if lag is detected so the player doesn't get unfair misses
				{
					tracks[0].time = songProgress - totalOffset;
					if (tracks.length > 1)
					{
						for (i in 1...tracks.length)
						{
							if (tracks[0].time < tracks[i].length)
								tracks[i].time = tracks[0].time;
						}
					}
					correctTrackPitch();
				}

				if (canSkipStart)
				{
					if (Options.keyJustPressed("introSkip"))
					{
						tracks[0].time = Conductor.timeFromBeat(songStartPos - 4);
						if (tracks.length > 1)
						{
							for (i in 1...tracks.length)
							{
								if (tracks[0].time < tracks[i].length)
									tracks[i].time = tracks[0].time;
							}
						}
						songProgress = tracks[0].time + totalOffset;
						Conductor.songPosition = songProgress;
						scriptExec("skippedStart");
						correctTrackPitch();
					}
					if (tracks[0].time >= Conductor.timeFromBeat(songStartPos - 4))
					{
						canSkipStart = false;
						FlxTween.tween(skipStartText, {alpha: 0}, 0.2);
					}
				}

				if (tracks.length > 1)							// Keep all tracks in sync
				{
					for (i in 1...tracks.length)
					{
						if (tracks[0].time < tracks[i].length && Math.abs(tracks[0].time - tracks[i].time) > (50 * Math.min(1, playbackRate)))
						{
							tracks[i].time = tracks[0].time;
							correctTrackPitch();
						}
					}
				}
				songProgress = tracks[0].time + totalOffset;
			}
			else
				songProgress += elapsed * 1000 * playbackRate;

			if (!endingSong)
			{
				if (health != healthGraphInfo[healthGraphInfo.length - 1][1])
					healthGraphInfo.push( [tracks[0].time, health] );
			}
		}

		if (camFollowRate > 0)
		{
			camFollowPos.x = FlxMath.lerp(camFollowPos.x, camFollow.x, camFollowRate * 60 * elapsed);
			camFollowPos.y = FlxMath.lerp(camFollowPos.y, camFollow.y, camFollowRate * 60 * elapsed);
		}
		else
			snapCamera();

		Conductor.songPosition = songProgress;
		if (tracks[0].playing)
		{
			songProgressVisual = tracks[0].time;
			if (Options.options.progressBar == 2)
				songProgressVisual = Math.max(-1, songProgressVisual - Conductor.timeFromBeat(songStartPos));
		}
		super.update(elapsed);
		scores.update(elapsed);

		scriptExec("update", [elapsed]);

		if (songProgressBar.alpha == 0 && songProgressVisual >= 0 && songProgressVisual < songLengthVisual)
		{
			FlxTween.tween(songProgressBar, {alpha: 1}, 0.2);
			FlxTween.tween(songProgressText, {alpha: 1}, 0.2);
		}

		if (songProgressBar.alpha == 1 && songProgressVisual >= songLengthVisual)
		{
			FlxTween.tween(songProgressBar, {alpha: 0}, 0.2);
			FlxTween.tween(songProgressText, {alpha: 0}, 0.2);
		}

		if (getSongProgressText() != songProgressText.text)
			songProgressText.text = getSongProgressText();

		if (msText.alpha > 0)
			msText.alpha -= elapsed / (Conductor.beatLength / 1000);

		if (countdownStarted)
		{
			var poppers:Array<Note> = [];
			var poppers2:Array<SustainNote> = [];
			for (i in 0...songData.columnDivisions.length)
			{
				if (i < noteArray.length)
				{
					var note:Note = noteArray[i];
					if (getScrollPosition(note.strumTime, songProgress, note.column) <= FlxG.height)
					{
						hscriptExec("onNoteAdded", [note]);
						notes.add(note);
						luaExec("onNoteAdded", [notes.members.indexOf(note)]);
						poppers.push(note);
						if (note.child != null)
						{
							hscriptExec("onSustainAdded", [note.child, note]);
							sustainNotes.add(note.child);
							luaExec("onSustainAdded", [sustainNotes.members.indexOf(note.child), notes.members.indexOf(note)]);
							poppers2.push(note.child);
						}
					}
				}
			}

			for (p in poppers)
				noteArray.remove(p);

			for (p in poppers2)
				sustainArray.remove(p);

			if (songData.events.length > 0)
			{
				var poppers:Array<EventData> = [];
				for (i in 0...songData.events.length)
				{
					if (songProgress >= songData.events[i].time)
					{
						doEvent(songData.events[i]);
						poppers.push(songData.events[i]);
					}
				}

				for (p in poppers)
					songData.events.remove(p);
			}

			if (!endingSong && camFocus != null && !overrideCamFocus)
			{
				if (camFocus.camPosition.abs)
				{
					camFollow.x = camFocus.camPosition.x;
					camFollow.y = camFocus.camPosition.y;
				}
				else
				{
					camFollow.x = camFocus.getMidpoint().x + (camFocus.characterData.camPosition[0] * ((camFocus.wasFlipped && camFocus.characterData.facing != "center") ? -1 : 1)) + camFocus.camPosition.x;
					camFollow.y = camFocus.getMidpoint().y + camFocus.characterData.camPosition[1] + camFocus.camPosition.y;
				}
			}
		}

		notes.forEachAlive(function(note:Note)
			{
				if (note.calcVis)
					note.visible = strumNotes.members[note.column].visible;
				if (note.calcAlpha)
					note.alpha = note.alph * strumNotes.members[note.column].alpha;
				if (note.calcNoteAng)
				{
					note.noteAng = strumNotes.members[note.column].noteAng + 270;
					if (note.downscroll)
						note.noteAng -= 180;
				}
				if (note.calcAngle)
					note.angle = note.baseAngle + strumNotes.members[note.column].ang;

				var noteHeight:Float = getScrollPosition(note.strumTime, songProgress, note.column);
				note.calcPos(strumNotes.members[note.column], noteHeight);

				if (noteModFunctions.length > 0)
				{
					for (n in noteModFunctions)
						n(note, noteHeight);
				}

				if (!playerColumns.contains(note.column))
				{
					if (note.strumTime - songProgress <= 0 && !note.typeData.p2ShouldMiss)
						opponentNoteHit(note);

					if (noteHeight < -100 - StrumNote.noteSize)
					{
						note.kill();
						note.destroy();
					}
				}
				else
				{
					if (note.strumTime - songProgress <= 0 && ((!note.typeData.p1ShouldMiss && botplay) || (note.typeData.p1ShouldMiss && holdArray[playerColumns.indexOf(note.column)])))
						noteHit(note);

					if (note.strumTime - songProgress < -ScoreSystems.judgeMS[4] && !note.missed)
					{
						noteMissed(note);
						if (note.typeData.healthValues.miss < 0)
						{
							if (note.singers.contains(player1))
								setTrackVolume([1, 2], 0);
							else
								setTrackVolume([1, 3], 0);
						}
					}

					if (noteHeight < -100 - StrumNote.noteSize && note.missed)
					{
						note.kill();
						note.destroy();
					}
				}
			}
		);

		sustainNotes.forEachAlive(function(note:SustainNote)
			{
				if (note.calcVis)
					note.visible = strumNotes.members[note.column].visible;
				if (note.calcAlpha)
					note.alpha = note.alph * strumNotes.members[note.column].alpha;
				if (note.calcNoteAng)
				{
					note.noteAng = strumNotes.members[note.column].noteAng + 270;
					if (note.downscroll)
						note.noteAng -= 180;
					note.angle = note.noteAng - 270;
				}

				var noteHeight:Float = getScrollPosition(note.strumTime, songProgress, note.column);
				note.calcPos(strumNotes.members[note.column], noteHeight);

				if (sustainModFunctions.length > 0)
				{
					for (n in sustainModFunctions)
						n(note, noteHeight);
				}

				if (!playerColumns.contains(note.column))
				{
					if (note.strumTime - songProgress <= 0 && !note.typeData.p2ShouldMiss)
						opponentSustainHit(note);

					if (note.strumTime + note.sustainLength - songProgress < -100 - StrumNote.noteSize)
					{
						note.kill();
						note.destroy();
					}
				}
				else
				{
					if (note.strumTime - songProgress <= 0)
					{
						if ((botplay || note.passedHitLimit || holdArray[playerColumns.indexOf(note.column)]) && note.canBeHit && !note.missed)
							sustainHit(note);
						else
						{
							note.isBeingHit = false;
							note.hitTimer += elapsed * 1000;
							if (note.hitTimer >= note.hitLimit && !note.missed)
								sustainMissed(note);

							if (note.strumTime + note.sustainLength - songProgress <= -note.hitLimit)
							{
								note.kill();
								note.destroy();
							}
						}

						if (note.missed)
						{
							if (note.singers.contains(player1))
								setTrackVolume([1, 2], 0);
							else
								setTrackVolume([1, 3], 0);
						}
					}
				}
			}
		);

		health = Math.min(100, health);

		var hby:Int = Std.int(healthBar.y + healthBar.borderWidth);
		healthIcons[0].x = healthBar.centerPosition - (healthIcons[0].width - healthIcons[0].iconOffset);
		healthIcons[0].y = hby - (healthIcons[0].height / 2);
		healthIcons[1].x = healthBar.centerPosition - healthIcons[1].iconOffset;
		healthIcons[1].y = hby - (healthIcons[1].height / 2);

		var hPerc:Float = chartSide > 0 ? healthBar.percent : 100 - healthBar.percent;
		if (hPerc > 80)
		{
			healthIconP1.transitionTo("losing");
			healthIconP2.transitionTo("winning");
		}
		else if (hPerc < 20)
		{
			healthIconP1.transitionTo("winning");
			healthIconP2.transitionTo("losing");
		}
		else
		{
			healthIconP1.transitionTo("idle");
			healthIconP2.transitionTo("idle");
		}

		if (health <= 0 && !paused)
			gameOver();

		if (Options.keyJustPressed("pause"))
			pauseGame();

		if (Options.keyJustPressed("restart"))
			restartSong();

		scriptExec("updatePost", [elapsed]);
	}

	public function snapCamera()
	{
		camFollowPos.x = camFollow.x;
		camFollowPos.y = camFollow.y;
	}

	public function sortNotes(a:NoteData, b:NoteData):Int
	{
		if (a.strumTime < b.strumTime)
			return -1;
		if (a.strumTime > b.strumTime)
			return 1;
		return 0;
	}

	public function generateSong():Array<String>
	{
		songStartPos = tracks[0].length;
		songEndPos = 0;

		notesSpawn = [];
		var noteTypes:Array<String> = [];

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

		for (section in songData.notes)
		{
			for (note in section.sectionNotes)
			{
				var typeOfNote:String = "";
				if (note.length > 3)
					typeOfNote = note[3];
				if (!noteTypes.contains(typeOfNote))
					noteTypes.push(typeOfNote);

				var newNote:NoteData =
				{
					strumTime: note[0],
					sustainLength: note[2],
					column: note[1],
					type: typeOfNote
				}
				if (section.mustHitSection)
				{
					if (newNote.column >= numKeys)
						newNote.column -= numKeys;
					else
						newNote.column += numKeys;
				}

				if (Options.options.mirrorMode)
					newNote.column = columnSwaps[newNote.column];

				if (section.defaultNoteP1 != null && section.defaultNoteP1 != "")
				{
					if (songData.columnDivisions[newNote.column] == 0 && newNote.type == "")
						newNote.type = section.defaultNoteP1;

					if (!noteTypes.contains(section.defaultNoteP1))
						noteTypes.push(section.defaultNoteP1);
				}
				if (section.defaultNoteP2 != null && section.defaultNoteP2 != "")
				{
					if (songData.columnDivisions[newNote.column] == 1 && newNote.type == "")
						newNote.type = section.defaultNoteP2;

					if (!noteTypes.contains(section.defaultNoteP2))
						noteTypes.push(section.defaultNoteP2);
				}

				if (newNote.strumTime - totalOffset < songStartPos)
					songStartPos = newNote.strumTime - totalOffset;

				if (newNote.strumTime + newNote.sustainLength - totalOffset > songEndPos)
					songEndPos = newNote.strumTime + newNote.sustainLength - totalOffset;

				if ((!testingChart || newNote.strumTime >= testingChartPos) && newNote.strumTime < tracks[0].length)
					notesSpawn.push(newNote);
			}
		}

		ArraySort.sort(notesSpawn, sortNotes);

		var skindef:NoteskinTypedef;
		for (t in noteTypes)
		{
			if (t != "" && Paths.jsonExists("notetypes/" + t))
			{
				var typeData:NoteTypeData = cast Paths.json("notetypes/" + t);
				if (typeData.noteskinOverride != null && typeData.noteskinOverride != "")
				{
					for (n in noteType)
					{
						skindef = Noteskins.getData(typeData.noteskinOverride, n);
						for (asset in skindef.assets)
						{
							if (Paths.imageExists("noteskins/" + skindef.skinName + "/" + asset[0]))
								Paths.cacheGraphic("noteskins/" + skindef.skinName + "/" + asset[0]);
							else
								Paths.cacheGraphic("noteskins/" + asset[0]);
						}
					}
				}
				if (typeData.noteskinOverrideSustain != null && typeData.noteskinOverrideSustain != "")
				{
					for (n in noteType)
					{
						skindef = Noteskins.getData(typeData.noteskinOverrideSustain, n);
						for (asset in skindef.assets)
						{
							if (Paths.imageExists("noteskins/" + skindef.skinName + "/" + asset[0]))
								Paths.cacheGraphic("noteskins/" + skindef.skinName + "/" + asset[0]);
							else
								Paths.cacheGraphic("noteskins/" + asset[0]);
						}
					}
				}
				if (typeData.hitSound != null && typeData.hitSound != "")
					FlxG.sound.cache(Paths.sound(typeData.hitSound));
			}
		}

		songStartPos = Conductor.beatFromTime(songStartPos);
		songEndPos = Conductor.beatFromTime(songEndPos);

		return noteTypes;
	}

	var noteArray:Array<Note> = [];
	var sustainArray:Array<SustainNote> = [];

	public function spawnNotes()
	{
		for (note in notesSpawn)
		{
			var thisNoteType:String = noteTypeFromColumn(note.column);
			var newNote:Note = new Note(note.strumTime, note.column, note.type, thisNoteType, strumColumns[note.column]);
			newNote.assignAnims(strumNotes.members[newNote.column]);
			newNote.offsetByStrum(strumNotes.members[newNote.column]);
			newNote.singers = strumNotes.members[newNote.column].singers.copy();
			if (notetypeSingers.exists(note.type))
				newNote.singers = notetypeSingers[note.type].copy();
			hscriptExec("onNoteSpawned", [newNote]);
			noteArray.push(newNote);
			luaExec("onNoteSpawned", [noteArray.indexOf(newNote)]);
			if (note.sustainLength > 0 && !newNote.typeData.noSustains)
			{
				var susLength:Float = getScrollPosition(note.strumTime + note.sustainLength, 0, note.column) - getScrollPosition(note.strumTime, 0, note.column);
				var newSustain:SustainNote = new SustainNote(note.strumTime, note.column, note.sustainLength, susLength, note.type, thisNoteType, strumColumns[note.column]);
				newSustain.assignAnims(strumNotes.members[newSustain.column]);
				newSustain.singers = newNote.singers;
				newNote.child = newSustain;
				newSustain.parent = newNote;
				hscriptExec("onSustainSpawned", [newSustain, newNote]);
				sustainArray.push(newSustain);
				luaExec("onSustainSpawned", [sustainArray.indexOf(newSustain), noteArray.indexOf(newNote)]);
			}
		}

		notesSpawn = [];
	}

	public function spawnCharacter(char:String):Character
	{
		var c:Character = new Character(0, 0, FreeplaySandbox.character(allCharacters.length, char));
		allCharacters.push(c);
		postSpawnCharacter(c);

		return c;
	}

	public function postSpawnCharacter(char:Character)
	{
		if (allCharacters.contains(char))
		{
			if (members.contains(char))
				remove(char, true);

			var slot:Int = Std.int(Math.min(allCharacters.indexOf(char), stage.stageData.characters.length-1));
			slotCharacter(char, slot);
			var charData:StageCharacter = stage.stageData.characters[slot];

			var ind:Int = members.length;
			for (i in 0...allCharacters.length)
			{
				var charDataCompare:StageCharacter = stage.stageData.characters[Std.int(Math.min(i, stage.stageData.characters.length-1))];
				if (allCharacters[i] != char && charData.layer < charDataCompare.layer && members.contains(allCharacters[i]) && ind > members.indexOf(allCharacters[i]))
					ind = members.indexOf(allCharacters[i]);
			}

			for (piece in stage.stageData.pieces)
			{
				if (charData.layer < piece.layer && members.contains(stage.pieces.get(piece.id)) && ind > members.indexOf(stage.pieces.get(piece.id)))
					ind = members.indexOf(stage.pieces.get(piece.id));
			}
			if (ind > members.length)
				ind = members.length;
			insert(ind, char);
		}
	}

	public function slotCharacter(char:Character, slot:Int)
	{
		var charData:StageCharacter = stage.stageData.characters[slot];
		if (char.wasFlipped != charData.flip)
			char.flip();
		char.repositionCharacter(charData.position[0], charData.position[1]);
		char.scaleCharacter(charData.scale[0], charData.scale[1]);
		char.scrollFactor.set(charData.scrollFactor[0], charData.scrollFactor[1]);
		char.pixelPerfect = stage.stageData.pixelPerfect;
		char.camPosition.x = charData.camPosition[0];
		char.camPosition.y = charData.camPosition[1];
		char.camPosition.abs = charData.camPosAbsolute;
	}

	function spawnStrumNotes()
	{
		strumNotes.forEachAlive(function(note:StrumNote) {
			note.kill();
			note.destroy();
		});
		strumNotes.clear();

		for (i in 0...songData.columnDivisions.length)
		{
			var thisNoteType:String = noteTypeFromColumn(i);
			var strum:StrumNote = new StrumNote(i, thisNoteType, strumColumns[i]);
			if (!playerColumns.contains(i))
				strum.isPlayer = false;
			strum.resetPosition(Options.options.downscroll, Options.options.middlescroll, songData.columnDivisions);
			strum.singers = [allCharacters[songData.singerColumns[strum.column]]];
			strumNotes.add(strum);
		}
	}

	function spawnLaneBackgrounds(strums:Array<Array<Int>>)
	{
		laneBackgrounds.forEachAlive(function(lane:FlxSprite) {
			lane.kill();
			lane.destroy();
		});
		laneBackgrounds.clear();

		for (s in strums)
		{
			var ww:Float = strumNotes.members[s[1]].x + strumNotes.members[s[1]].width - strumNotes.members[s[0]].x;
			ww += Options.options.laneBorder * 2;
			var lane:FlxSprite = new FlxSprite(strumNotes.members[s[0]].x - Options.options.laneBorder, -100).makeGraphic(Std.int(ww), Std.int(FlxG.height + 200), FlxColor.BLACK);
			lane.alpha = Options.options.laneOpacity;
			laneBackgrounds.add(lane);
		}
	}

	function setupScrollSpeeds()
	{
		var scrollSpeeds:Array<ScrollSpeed> = [];

		var i:Int = 0;
		for (s in songData.scrollSpeeds)
		{
			var newSpd:ScrollSpeed = {startTime: Conductor.timeFromBeat(s[0]), startPosition: 0, speed: s[1] * Options.options.scrollSpeed};
			if (Options.options.scrollSpeedType == 0 && s[1] != 0)
				newSpd.speed = Options.options.scrollSpeed;
			if (i > 0)
			{
				if (songData.altSpeedCalc && Options.options.scrollSpeedType != 0)
					newSpd.startPosition = scrollSpeeds[i-1].startPosition + ((Conductor.stepFromTime(newSpd.startTime) - Conductor.stepFromTime(scrollSpeeds[i-1].startTime)) * scrollSpeeds[i-1].speed);
				else
					newSpd.startPosition = scrollSpeeds[i-1].startPosition + ((newSpd.startTime - scrollSpeeds[i-1].startTime) * scrollSpeeds[i-1].speed * 0.45);
			}
			scrollSpeeds.push(newSpd);
			i++;
		}

		strumNotes.forEachAlive(function(n:StrumNote) { n.scrollSpeeds = scrollSpeeds; });
	}

	function getScrollPosition(ms:Float, songTime:Float, ?column:Int = 0):Float
	{
		var scrollSpeeds = strumNotes.members[column].scrollSpeeds;
		var spd:ScrollSpeed = scrollSpeeds[0];
		if (scrollSpeeds.length > 1)
		{
			for (s in scrollSpeeds)
			{
				if (s.startTime <= ms)
					spd = s;
			}

			var spd2:ScrollSpeed = scrollSpeeds[0];
			for (s in scrollSpeeds)
			{
				if (s.startTime <= songTime)
					spd2 = s;
			}

			var dist:Float = ms - spd.startTime;
			var dist2:Float = songTime - spd2.startTime;

			if (songData.altSpeedCalc && Options.options.scrollSpeedType != 0)
			{
				dist = Conductor.stepFromTime(ms) - Conductor.stepFromTime(spd.startTime);
				dist2 = Conductor.stepFromTime(songTime) - Conductor.stepFromTime(spd2.startTime);

				return ((spd.startPosition + (dist * spd.speed)) - (spd2.startPosition + (dist2 * spd2.speed))) * StrumNote.noteSize;
			}

			return ((spd.startPosition + (dist * spd.speed * 0.45)) - (spd2.startPosition + (dist2 * spd2.speed * 0.45))) * StrumNote.noteScale;
		}
		else if (songData.altSpeedCalc && Options.options.scrollSpeedType != 0)
		{
			var dist:Float = Conductor.stepFromTime(ms);
			var dist2:Float = Conductor.stepFromTime(songTime);

			return ((dist * spd.speed) - (dist2 * spd.speed)) * StrumNote.noteSize;
		}
		return (ms - songTime) * spd.speed * 0.45 * StrumNote.noteScale;
	}

	public var customGameOver:Bool = false;
	function gameOver()
	{
		paused = true;
		deaths++;

		for (t in tracks)
			t.stop();
		FlxTween.completeTweensOf(FlxG.camera);

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyReleased);

		if (Options.options.instantRetry)
		{
			MusicBeatState.doTransOut = false;
			FlxG.switchState(new PlayState());
		}
		else
		{
			GameOverSubState.character = strumNotes.members[playerColumns[0]].singers[0];
			hscriptExec("gameOver", [GameOverSubState.character]);
			luaExec("gameOver", [GameOverSubState.character.curCharacter]);
			if (customGameOver)
			{
				for (note in noteArray)
				{
					note.kill();
					note.destroy();
				}
				noteArray = [];

				for (note in sustainArray)
				{
					note.kill();
					note.destroy();
				}
				sustainArray = [];

				notes.forEachAlive(function(note:Note) {
					note.kill();
					note.destroy();
				});
				notes.clear();

				sustainNotes.forEachAlive(function(note:SustainNote) {
					note.kill();
					note.destroy();
				});
				sustainNotes.clear();

				countdownStarted = false;
			}
			else
			{
				persistentUpdate = false;
				persistentDraw = false;
				openSubState(new GameOverSubState());
			}
		}
	}

	function pauseGame()
	{
		if (!countdownStarted || endingSong)
			return;

		paused = true;
		if (countdownTimer != null)
			countdownTimer.active = false;
		for (t in tracks)
			t.pause();
		persistentUpdate = false;
		PauseSubState.deathCounterText = strumNotes.members[playerColumns[0]].singers[0].characterData.deathCounterText;
		openSubState(new PauseSubState());
	}

	override public function onFocusLost()
	{
		super.onFocusLost();
		if (!Options.options.autoPause && !paused)
			pauseGame();
	}

	public function hscriptAdd(id:String, ?file:String = "", ?forced:Bool = false, ?thisChar:Character = null)
	{
		var fullFile:String = file;
		if (file == "")
			fullFile = id;
		if (!Paths.hscriptExists(fullFile) && Paths.hscriptExists("data/scripts/" + fullFile))
			fullFile = "data/scripts/" + fullFile;
		if (Paths.hscriptExists(fullFile) && (!myScripts.exists(id) || forced))
		{
			var newScript = new HscriptHandler(fullFile);
			myScripts[id] = newScript;
			newScript.setVar("game", instance);
			newScript.setVar("scriptId", id);
			if (thisChar != null)
				newScript.setVar("thisChar", thisChar);
			newScript.setVar("playingChar", strumNotes.members[playerColumns[0]].singers[0]);
		}
		else if (myScripts.exists(id) && forced)
			myScripts.remove(id);
	}

	public function hscriptRemove(id:String)
	{
		if (myScripts.exists(id))
			myScripts.remove(id);
	}

	public function hscriptExists(id:String):Bool
	{
		return myScripts.exists(id);
	}

	public function hscriptExec(func:String, ?args:Array<Dynamic> = null)
	{
		for (sc in myScripts.iterator())
			sc.execFunc(func, (args == null ? [] : args));
	}

	public function hscriptSet(vari:String, val:Dynamic)
	{
		for (sc in myScripts.iterator())
			sc.variables[vari] = val;
	}

	public function hscriptIdExec(id:String, func:String, ?args:Array<Dynamic> = null)
	{
		if (myScripts.exists(id))
			myScripts.get(id).execFunc(func, (args == null ? [] : args));
	}

	public function hscriptIdSet(id:String, vari:String, val:Dynamic)
	{
		if (myScripts.exists(id))
			myScripts[id].variables[vari] = val;
	}

	public function hscriptIdGet(id:String, vari:String):Dynamic
	{
		if (myScripts.exists(id))
			return myScripts[id].variables[vari];
		return null;
	}

	public function luaAdd(id:String, file:String):LuaModule
	{
		myLuaScripts[id] = new LuaModule(file);
		return myLuaScripts[id];
	}

	public function luaRemove(id:String)
	{
		if (myLuaScripts.exists(id))
			myLuaScripts.remove(id);
	}

	public function luaExists(id:String):Bool
	{
		return myLuaScripts.exists(id);
	}

	public function luaExec(func:String, ?args:Array<Dynamic> = null)
	{
		for (sc in myLuaScripts.iterator())
			sc.exec(func, (args == null ? [] : args));
	}

	public function luaSet(vari:String, val:Dynamic)
	{
		for (sc in myLuaScripts.iterator())
			sc.set(vari, val);
	}

	public function luaIdExec(id:String, func:String, ?args:Array<Dynamic> = null)
	{
		if (myLuaScripts.exists(id))
			myLuaScripts.get(id).exec(func, (args == null ? [] : args));
	}

	public function luaIdSet(id:String, vari:String, val:Dynamic)
	{
		if (myLuaScripts.exists(id))
			myLuaScripts[id].set(vari, val);
	}

	public function luaIdGet(id:String, vari:String):Dynamic
	{
		if (myLuaScripts.exists(id))
			return myLuaScripts[id].get(vari);
		return null;
	}

	public function scriptExec(func:String, ?args:Array<Dynamic> = null)
	{
		hscriptExec(func, args);
		luaExec(func, args);
	}

	function allTracksOfType(types:Array<Int>):Array<FlxSound>
	{
		var returnArray:Array<FlxSound> = [];
		for (i in 0...tracks.length)
		{
			if (types.contains(trackTypes[i]))
				returnArray.push(tracks[i]);
		}
		return returnArray;
	}

	function setTrackVolume(types:Array<Int>, volume:Float)
	{
		for (t in allTracksOfType(types))
			t.volume = volume;
	}

	function updateScoreText()
	{
		var separator:String = (scoreTxt.alignment == CENTER ? " | " : "\n");
		var scoreTextArray:Array<String> = [Lang.get("#score", [Std.string(scores.score)])];
		if (Options.options.nps)
		{
			if (scoreTxt.alignment == CENTER)
				scoreTextArray.push(Lang.get("#npsCombined", [Std.string(scores.nps), Std.string(scores.maxNps)]));
			else
			{
				scoreTextArray.push(Lang.get("#nps", [Std.string(scores.nps)]));
				scoreTextArray.push(Lang.get("#maxNps", [Std.string(scores.maxNps)]));
			}
		}
		if (Options.options.accuracy)
		{
			scoreTextArray.push(Lang.get("#accuracy", [Std.string(Math.fround(scores.accuracy * 100) / 100)]));
			scoreTextArray.push(scores.rating);
		}
		scoreTxt.text = scoreTextArray.join(separator);
		scriptExec("updateScoreText", [scoreTxt.text, separator]);

		if (scoreTxt.alignment != CENTER)
		{
			scoreTxt.screenCenter(Y);
			if (judgementCounter.visible && judgementCounter.alignment == scoreTxt.alignment)
				scoreTxt.y += FlxG.height / 6;
		}
	}

	function updateJudgementCounter()
	{
		judgementCounter.text = scores.writeJudgementCounter();
	}

	function getSongProgressText():String
	{
		var txt:String = songName;
		if (Options.options.bpmDisplay)
			txt += " " + Lang.get("#bpmDisplay", [Std.string(Math.round(Conductor.bpm * playbackRate * 100) / 100)]);
		txt += " (" + FlxStringUtil.formatTime(Math.min(songLengthVisual / 1000.0, Math.max(0, (songLengthVisual - songProgressVisual) / 1000.0)) / playbackRate) + ")";

		return txt;
	}

	public function skipTo(time:Float)
	{
		if (tracks[0].playing)
		{
			if (time >= Conductor.timeFromBeat(songStartPos))
			{
				var poppers:Array<Note> = [];
				var poppers2:Array<SustainNote> = [];
				for (note in noteArray)
				{
					if (note.strumTime - totalOffset < time)
					{
						poppers.push(note);
						if (note.child != null)
							poppers2.push(note.child);
					}
				}

				for (p in poppers)
				{
					noteArray.remove(p);
					p.kill();
					p.destroy();
				}

				for (p in poppers2)
				{
					sustainArray.remove(p);
					p.kill();
					p.destroy();
				}

				notes.forEachAlive(function(note:Note) {
					if (note.strumTime - totalOffset < time)
					{
						note.kill();
						note.destroy();
					}
				});

				sustainNotes.forEachAlive(function(note:SustainNote) {
					if (note.strumTime - totalOffset < time)
					{
						note.kill();
						note.destroy();
					}
				});

				canSaveScore = false;
			}
			songProgress = time;
		}
	}

	public function doEvent(event:EventData)
	{
		var eventScript:String = 'EVENT_' + event.type.replace("/","_");
		if (!myScripts.exists(eventScript))
		{
			if (event.type.startsWith(songId) && Paths.hscriptExists('data/songs/' + songId + '/events/' + event.typeShort))
				hscriptAdd(eventScript, 'data/songs/' + songId + '/events/' + event.typeShort);
			else
				hscriptAdd(eventScript, 'data/events/' + event.type);
			hscriptIdExec(eventScript, "create", []);
		}

		hscriptIdExec(eventScript, "onEvent", [event]);
		hscriptExec("onAnyEvent", [event]);
		luaExec("onAnyEvent", [event.time, event.beat, event.type, event.parameters]);
	}

	public static var optionsMenuStatus:Int = 0;

	override function closeSubState()
	{
		if (paused)
		{
			switch (optionsMenuStatus)
			{
				case 1:
					optionsMenuStatus = 2;
					openSubState(new OptionsMenuSubState(1));

				case 2:
					optionsMenuStatus = 0;
					openSubState(new PauseSubState(2));

				default:
					paused = false;
					if (countdownTimer != null)
						countdownTimer.active = true;
					for (t in tracks)
						t.resume();
					correctTrackPitch();
					persistentUpdate = true;
			}
		}

		super.closeSubState();
	}

	public function getCurSection():Int
	{
		for (s in 0...songData.notes.length)
		{
			if (songData.notes[s].firstStep <= curStep && songData.notes[s].lastStep > curStep)
				return s;
		}

		return 0;
	}

	public var bumpTweenMain:FlxTween = null;
	public var bumpTweenHUD:FlxTween = null;

	public function bumpCamera(?mainIntensity:Float = 0, ?hudIntensity:Float = 0, ?timeMultiplier:Float = 1)
	{
		if (Options.options.cameraBump)
		{
			if (bumpTweenMain != null)
				bumpTweenMain.cancel();
			if (bumpTweenHUD != null)
				bumpTweenHUD.cancel();

			var tweenList:Array<FlxTween> = [];
			@:privateAccess
			FlxTween.globalManager.forEachTweensOf(FlxG.camera, ["zoom"], function(twn:FlxTween) { tweenList.push(twn); });
			if (tweenList.length == 0)
			{
				FlxG.camera.zoom = camZoom + (mainIntensity == 0 ? 0.015 : mainIntensity);
				bumpTweenMain = FlxTween.tween(FlxG.camera, {zoom: camZoom}, (Conductor.beatLength / 1000) * timeMultiplier, { ease: FlxEase.quadOut });
			}

			tweenList = [];
			@:privateAccess
			FlxTween.globalManager.forEachTweensOf(camHUD, ["zoom"], function(twn:FlxTween) { tweenList.push(twn); });
			if (tweenList.length == 0)
			{
				camHUD.zoom = 1 + (hudIntensity == 0 ? 0.03 : hudIntensity);
				bumpTweenHUD = FlxTween.tween(camHUD, {zoom: 1}, (Conductor.beatLength / 1000) * timeMultiplier, { ease: FlxEase.quadOut });
			}
		}
	}

	public function set_camBumpRate(newVal:Float):Float
	{
		camBumpSequence = [];
		if (newVal > 0)
		{
			for (i in 0...Std.int(newVal*4))
				camBumpSequence.push(false);
			camBumpSequence[0] = true;
		}
		return camBumpRate = newVal;
	}

	override public function stepHit()
	{
		if (!endingSong)
		{
			stage.stepHit();
			for (m in members)
			{
				if (Std.isOfType(m, AnimatedSprite))
				{
					var s:AnimatedSprite = cast m;
					s.stepHit();
				}

				if (Std.isOfType(m, Character))
				{
					var c:Character = cast m;
					c.stepHit();
				}

				if (Std.isOfType(m, HscriptSprite))
				{
					var s:HscriptSprite = cast m;
					s.stepHit();
				}

				if (Std.isOfType(m, HscriptSpriteGroup))
				{
					var s:HscriptSpriteGroup = cast m;
					s.stepHit();
				}
			}

			if (camBumpSequence.length > 0 && curStep >= 0)
			{
				if (camBumpSequenceProgress >= camBumpSequence.length)
					camBumpSequenceProgress = camBumpSequenceProgress % camBumpSequence.length;
				if (camBumpOnBeat && camBumpSequence[camBumpSequenceProgress])
					bumpCamera();

				camBumpSequenceProgress += curStep - camBumpLast;
				camBumpLast = curStep;
			}

			if (iconBumpRate > 0 && curStep % Std.int(Math.round(iconBumpRate * 4)) == 0)
			{
				for (i in healthIcons)
				{
					i.sc.set(1.2, 1.2);
					FlxTween.tween(i.sc, {x: 1, y: 1}, Conductor.stepLength / 1000, { ease: FlxEase.quadOut });
				}
			}
		}

		scriptExec("stepHit");
	}

	override public function beatHit()
	{
		if (!endingSong)
		{
			stage.beatHit();
			for (m in members)
			{
				if (Std.isOfType(m, Character))
				{
					var c:Character = cast m;
					c.beatHit();
				}

				if (Std.isOfType(m, HscriptSprite))
				{
					var s:HscriptSprite = cast m;
					s.beatHit();
				}

				if (Std.isOfType(m, HscriptSpriteGroup))
				{
					var s:HscriptSpriteGroup = cast m;
					s.beatHit();
				}
			}

			if (updateCamFocus)
			{
				curSection = getCurSection();
				if (curSection < songData.notes.length)
				{
					var sec:SectionData = songData.notes[curSection];
					if (sec.camOn < allCharacters.length)
					{
						camFocus = allCharacters[sec.camOn];
						if (songData.notetypeOverridesCam)
						{
							if (sec.camOn == 0 && sec.defaultNoteP1 != null && notetypeSingers.exists(sec.defaultNoteP1) && notetypeSingers[sec.defaultNoteP1].length == 1)
								camFocus = notetypeSingers[sec.defaultNoteP1][0];
							else if (sec.camOn == 1 && sec.defaultNoteP2 != null && notetypeSingers.exists(sec.defaultNoteP2) && notetypeSingers[sec.defaultNoteP2].length == 1)
								camFocus = notetypeSingers[sec.defaultNoteP2][0];
						}
					}
				}
			}
		}

		scriptExec("beatHit");
	}

	public var canStartCountdown:Bool = true;
	public var skipCountdown:Bool = false;
	public var countdownStarted:Bool = false;
	public var countdownProgress:Int = 0;
	public var countdownMultiplier:Float = 1;
	public var countdownTimer:FlxTimer = null;
	public var countdownTickSprites:Array<CountdownPopup> = [];
	public var countdownTickGroup:FlxTypedSpriteGroup<CountdownPopup>;
	public function startCountdown()
	{
		if (!countdownStarted)
		{
			if (!testingChart)
				scriptExec("startCountdown");
			if (canStartCountdown || testingChart)
			{
				countdownStarted = true;
				PlayState.firstPlay = false;
				var countdownBeatLength:Float = Conductor.beatLength * countdownMultiplier;
				songProgress = (countdownBeatLength * -5) + totalOffset;
				if (testingChart)
					songProgress += testingChartPos;
				healthGraphInfo = [[0, health]];
				insert(members.length, countdownTickGroup);				// The reason we do this instead of "add" is to ensure the group is on the top layer rather than replacing a null object
				if (skipCountdown && !testingChart)
				{
					songProgress = (countdownBeatLength * -1) + totalOffset;
					countdownTimer = new FlxTimer().start((countdownBeatLength / 1000.0) / playbackRate, function(tmr:FlxTimer)
					{
						countdownProgress = 4;
						playSong();
						countdownTimer = null;

						scriptExec("countdownTick");
					});
				}
				else
				{
					for (i in 0...uiSkin.countdownSounds.length)
					{
						if (uiSkin.countdownSounds[i] != "")
							FlxG.sound.cache(Paths.sound(uiSkin.countdownSounds[i]));
					}

					countdownTimer = new FlxTimer().start((countdownBeatLength / 1000.0) / playbackRate, function(tmr:FlxTimer)
					{
						songProgress = (countdownBeatLength * (-4 + countdownProgress)) + totalOffset;
						if (testingChart)
							songProgress += testingChartPos;

						if (countdownProgress < uiSkin.countdown.length && uiSkin.countdown[countdownProgress].asset != null)
						{
							var countdownTickSprite:CountdownPopup = new CountdownPopup(countdownProgress, songData.uiSkin, uiSkin);
							countdownTickGroup.add(countdownTickSprite);
							countdownTickSprites.push(countdownTickSprite);
						}
						else
							countdownTickSprites.push(null);

						if (countdownProgress < uiSkin.countdownSounds.length && uiSkin.countdownSounds[countdownProgress] != "")
							FlxG.sound.play(Paths.sound(uiSkin.countdownSounds[countdownProgress]));

						if (countdownProgress == 4)
						{
							playSong();
							countdownTimer = null;
						}

						scriptExec("countdownTick");
						countdownProgress++;
					}, 5);
				}
			}
		}
	}

	public var songArtist:SongArtist = null;
	function playSong()
	{
		for (t in tracks)
			t.play();
		correctTrackPitch();
		tracks[0].onComplete = songFinished;
		songProgress = totalOffset;
		if (testingChart)
			songProgress += testingChartPos;

		if (canSkipStart)
			FlxTween.tween(skipStartText, {alpha: 1}, 0.2);

		if (songData.artist != "")
			songArtist = new SongArtist(songName, songData.artist);

		scriptExec("playSong");
	}

	function correctTrackPitch()
	{
		for (t in tracks)
		{
			@:privateAccess
			if (t.playing)
				AL.sourcef(t._channel.__source.__backend.handle, AL.PITCH, playbackRate);
		}
	}

	public var endingSong:Bool = false;
	function songFinished()
	{
		tracks[0].onComplete = null;
		healthGraphInfo.push( [tracks[0].length, health] );
		scores.results.songLength = tracks[0].length;
		endingSong = true;

		for (t in tracks)
			t.stop();
		FlxTween.tween(songProgressBar, {alpha: 0}, 0.2);
		FlxTween.tween(songProgressText, {alpha: 0}, 0.2);

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyReleased);

		saveScores();
		endSong();
	}

	function saveScores()
	{
		if (testingChart)
			return;

		if (botplay || playbackRate < 1)
			canSaveScore = false;

		if (ResultsSubState.songNames.length > storyProgress)
			ResultsSubState.songNames[storyProgress] = songName;
		else
			ResultsSubState.songNames.push(songName);
		if (canSaveScore)
			ScoreSystems.saveSongScore(songId, difficulty, scores.score, chartSide);
		if (ResultsSubState.healthData.length > storyProgress)
			ResultsSubState.healthData[storyProgress] = healthGraphInfo;
		else
			ResultsSubState.healthData.push(healthGraphInfo);

		if (inStoryMode)
		{
			if (canSaveScore)
				ScoreSystems.onWeekSongBeaten(scores);
			if (PlayState.storyProgress + 1 >= storyWeek.length)
			{
				if (canSaveScore)
					ScoreSystems.saveWeekScore(storyWeekName, difficulty);
				StoryMenuState.unlockWeeks(storyWeekName);
			}
		}
	}

	public var canEndSong:Bool = true;
	public var doNextSongTrans:Bool = false;
	public function endSong()
	{
		scriptExec("endSong");
		if (canEndSong)
		{
			ResultsSubState.sideName = songData.columnDivisionNames[chartSide];
			if (testingChart)
				gotoMenuState();
			else if (inStoryMode)
			{
				PlayState.storyProgress++;
				deaths = 0;
				if (PlayState.storyProgress >= storyWeek.length)
				{
					paused = true;
					persistentUpdate = false;
					openSubState(new ResultsSubState(scores));
				}
				else
				{
					if (!doNextSongTrans)
					{
						prevCamFollow = camFollow;
						MusicBeatState.doTransIn = false;
						MusicBeatState.doTransOut = false;
					}

					PlayState.firstPlay = true;
					FlxG.switchState(new PlayState());
				}
			}
			else
			{
				paused = true;
				persistentUpdate = false;
				openSubState(new ResultsSubState(scores));
			}
		}
	}

	public function restartSong()
	{
		paused = true;
		persistentUpdate = false;

		tracks[0].onComplete = null;

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyReleased);

		FlxG.switchState(new PlayState());
	}

	public function exitToMenu()
	{
		tracks[0].onComplete = null;

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyReleased);

		gotoMenuState();
	}

	public static var fromState:String = "";
	public function gotoMenuState(?doHscript:Bool = true)
	{
		if (doHscript && !testingChart)
			scriptExec("gotoMenuState");

		if (testingChart)
		{
			FlxG.mouse.visible = true;
			FlxG.switchState(new ChartEditorState());
		}
		else if (fromState != "")
		{
			var goingTo:String = fromState;
			fromState = "";
			FlxG.switchState(new HscriptState(goingTo));
		}
		else
		{
			switch (HscriptHandler.curMenu)
			{
				case "story": FlxG.switchState(new StoryMenuState());
				case "freeplay": FlxG.switchState(new FreeplayMenuState());
				default: FlxG.switchState(new MainMenuState());
			}
		}
	}

	function onKeyPressed(event:KeyboardEvent)
	{
		var _key:FlxKey = cast event.keyCode;
		if (!paused)
		{
			hscriptExec("onKeyPressed", [_key]);
			luaExec("onKeyPressed", [_key.toString()]);
		}

		if (paused || botplay || !countdownStarted || endingSong || suspendControls) return;

		var hitNote:Int = -1;
		for (i in 0...keysArray.length)
		{
			for (j in 0...keysArray[i].length)
			{
				if (_key == keysArray[i][j] && hitNote == -1)
					hitNote = i;
			}
		}

		if (hitNote < 0)
			return;
		if (holdArray[hitNote])
			return;
		holdArray[hitNote] = true;
		strumNotes.members[playerColumns[hitNote]].playAnim("press");

		var note:Note = null;
		var noteDist:Float = -ScoreSystems.judgeMS[4];
		notes.forEachAlive(function(thisNote:Note)
			{
				if (thisNote.column == playerColumns[hitNote] && Math.abs(thisNote.strumTime - songProgress) <= ScoreSystems.judgeMS[4] && !thisNote.isLift)
				{
					if ((noteDist == -ScoreSystems.judgeMS[4] || Math.abs(thisNote.strumTime - songProgress) < noteDist) && noteCanHit(thisNote))
					{
						note = thisNote;
						noteDist = thisNote.strumTime - songProgress;
					}
				}
			}
		);

		if (note == null)
			scriptExec("noNoteHit", [hitNote]);
		else
			noteHit(note);
	}

	function onKeyReleased(event:KeyboardEvent)
	{
		var _key:FlxKey = cast event.keyCode;
		hscriptExec("onKeyReleased", [_key]);
		luaExec("onKeyReleased", [_key.toString()]);

		if (botplay || !countdownStarted) return;

		var hitNote:Int = -1;
		for (i in 0...keysArray.length)
		{
			for (j in 0...keysArray[i].length)
			{
				if (_key == keysArray[i][j] && hitNote == -1)
					hitNote = i;
			}
		}

		if (hitNote < 0)
			return;
		if (!holdArray[hitNote])
			return;
		holdArray[hitNote] = false;
		strumNotes.members[playerColumns[hitNote]].playAnim("static");

		var note:Note = null;
		var noteDist:Float = -ScoreSystems.judgeMS[4];
		notes.forEachAlive(function(thisNote:Note)
			{
				if (thisNote.isLift && thisNote.column == playerColumns[hitNote] && Math.abs(thisNote.strumTime - songProgress) <= ScoreSystems.judgeMS[4])
				{
					if ((noteDist == -ScoreSystems.judgeMS[4] || Math.abs(thisNote.strumTime - songProgress) < noteDist) && noteCanHit(thisNote))
					{
						note = thisNote;
						noteDist = thisNote.strumTime - songProgress;
					}
				}
			}
		);

		if (note != null)
			noteHit(note);
	}

	public function set_suspendControls(newVal:Bool):Bool
	{
		if (newVal && !botplay && countdownStarted)
		{
			for (i in 0...keysArray.length)
			{
				if (holdArray[i])
				{
					holdArray[i] = false;
					if (i < playerColumns.length)
						strumNotes.members[playerColumns[i]].playAnim("static");
				}
			}
		}
		return suspendControls = newVal;
	}



	// Player notes

	function noteCanHit(note:Note):Bool
	{
		if (note.typeData.p1ShouldMiss)
		{
			var rating:Int = scores.justJudgeNote(Math.abs(note.strumTime - songProgress) / playbackRate);
			if (note.typeData.healthValues.judgements[rating] == 0)
				return false;
		}
		return !note.missed;
	}

	function noteHit(note:Note)
	{
		var rating:Int = scores.justJudgeNote(Math.abs(note.strumTime - songProgress) / playbackRate);
		if (note.typeData.p1ShouldMiss)
		{
			if (note.typeData.healthValues.judgements[rating] == 0)
				return;
			if (note.typeData.hitSound != "")
				FlxG.sound.play(Paths.sound(note.typeData.hitSound), note.typeData.hitSoundVolume);
			scores.missNote(-1);
		}
		else
		{
			if (note.typeData.hitSound != "")
				FlxG.sound.play(Paths.sound(note.typeData.hitSound), note.typeData.hitSoundVolume);
			else if (Paths.hitsound() != "")
				FlxG.sound.play(Paths.hitsound(), Options.options.hitvolume);
			rating = scores.hitNote((note.strumTime - totalOffset) / playbackRate, (note.strumTime - songProgress) / playbackRate);
		}

		health += note.typeData.healthValues.judgements[rating];
		updateJudgementCounter();

		var comboType:Int = Options.options.comboType;
		if (comboType > 0)
		{
			if (!Options.options.comboAccumulate)
			{
				ratingPopups.forEachAlive(function(thing:FlxSprite)
				{
					thing.kill();
					thing.destroy();
				});
				ratingPopups.clear();
			}

			var ratingPopup:RatingPopup = new RatingPopup();
			ratingPopup.refresh(0, 4 - rating, songData.uiSkin, uiSkin);
			if (!note.typeData.p1ShouldMiss)
				ratingPopups.insert(ratingPopups.members.length, ratingPopup);

			var comboDigits:Array<Int> = [];
			var combo:Int = scores.combo;
			while (combo > 0)
			{
				comboDigits.unshift(combo % 10);
				combo = Std.int(Math.floor(combo / 10));
			}
			while (comboDigits.length < 3)
				comboDigits.unshift(0);

			if (Options.options.comboPopup && uiSkin.combo.asset != null)
			{
				var comboPopup:RatingPopup = new RatingPopup();
				comboPopup.refresh(1, 0, songData.uiSkin, uiSkin);
				comboPopup.x += (43 * comboDigits.length);
				ratingPopups.insert(ratingPopups.members.length, comboPopup);
			}

			for (i in 0...comboDigits.length)
			{
				var digit:RatingPopup = new RatingPopup();
				digit.refresh(2, comboDigits[i], songData.uiSkin, uiSkin);
				digit.x += (43 * i);
				ratingPopups.insert(ratingPopups.members.length, digit);
			}
		}

		if ((Options.options.splashes || note.typeData.alwaysSplash) && note.noteskinData.allowSplashes && rating <= note.typeData.splashMin)
		{
			var newSplash:NoteSplash = noteSplashes.recycle(NoteSplash);
			newSplash.refreshSplash(strumNotes.members[note.column].x, strumNotes.members[note.column].y, note.noteskinData.splashAsset, note.noteskinData.splashGridSize);
			newSplash.shader = note.shader;
			newSplash.antialiasing = note.noteskinData.antialias;
			Noteskins.doSplash(newSplash, note.noteskinData, note.noteColor);
			newSplash.updateHitbox();
			newSplash.x += (strumNotes.members[note.column].width - newSplash.width) / 2;
			newSplash.y += (strumNotes.members[note.column].height - newSplash.height) / 2;
			noteSplashes.add(newSplash);
			hscriptExec("noteSplash", [note, newSplash]);
		}

		if (Options.options.msText)
		{
			msText.text = Std.string(Math.fround(((note.strumTime - songProgress) / playbackRate) * 100) / 100) + 'ms';
			msText.alpha = 1;
			msText.screenCenter(X);
			var ratingColors:Array<FlxColor> = [Options.options.colorMV, Options.options.colorSK, Options.options.colorGD, Options.options.colorBD, Options.options.colorSH];
			msText.color = ratingColors[rating];
		}

		if (note.child != null)
			note.child.canBeHit = true;

		updateScoreText();

		onNoteHit(note);
	}

	function sustainHit(note:SustainNote)
	{
		note.isBeingHit = true;
		note.hitTimer = 0;

		onSustainHit(note);
	}

	function noteMissed(note:Note)
	{
		health += note.typeData.healthValues.miss;
		if (note.typeData.healthValues.miss < 0)
		{
			for (s in note.singers)
				s.playAnim(note.missAnim, true);
			if (scores.combo > 5 && allReactors.length > 0)
			{
				for (r in allReactors)
					r.playAnim(r.sad);
			}
			scores.missNote((note.strumTime - totalOffset) / playbackRate);
			updateJudgementCounter();

			FlxG.sound.play(Paths.sound(FlxG.random.getObject(missSounds)), Options.options.missvolume);
		}

		note.missed = true;
		note.alph /= 2;

		updateScoreText();

		hscriptExec("noteMissed", [note]);
		luaExec("noteMissed", [notes.members.indexOf(note)]);
	}

	function sustainMissed(note:SustainNote)
	{
		health += note.typeData.healthValues.miss;
		if (note.typeData.healthValues.miss < 0)
		{
			for (s in note.singers)
				s.playAnim(note.missAnim, true);
			if (scores.combo > 5 && allReactors.length > 0)
			{
				for (r in allReactors)
					r.playAnim(r.sad);
			}
			scores.missNote(-1);
			updateJudgementCounter();

			FlxG.sound.play(Paths.sound(FlxG.random.getObject(missSounds)), Options.options.missvolume);
		}

		note.missed = true;
		note.alph /= 2;

		updateScoreText();

		hscriptExec("sustainMissed", [note]);
		luaExec("noteMissed", [sustainNotes.members.indexOf(note)]);
	}



	// Opponent notes

	function opponentNoteHit(note:Note)
	{
		camBumpOnBeat = true;
		onNoteHit(note);
	}

	function opponentSustainHit(note:SustainNote)
	{
		onSustainHit(note);
	}



	// Shared note code

	function onNoteHit(note:Note)
	{
		for (s in note.singers)
		{
			s.holdTimer = Conductor.beatLength;
			s.playAnim(note.hitAnim, true);
		}
		strumNotes.members[note.column].playAnim("confirm", true, note.noteColor);

		var vol:Float = (note.typeData.p1ShouldMiss ? 0 : 1);
		if (!playerColumns.contains(note.column))
			vol = 1;
		if (note.column < numKeys)
			setTrackVolume([1, 3], vol);
		else
			setTrackVolume([1, 2], vol);

		hscriptExec("noteHit", [note]);
		luaExec("noteHit", [notes.members.indexOf(note)]);

		note.kill();
		note.destroy();
	}

	function onSustainHit(note:SustainNote)
	{
		strumNotes.members[note.column].playAnim("confirm", true, note.noteColor);
		for (s in note.singers)
		{
			if (s.curAnimName.endsWith("miss"))
				s.playAnim(note.hitAnim);
			if (s.holdTimer < Conductor.stepLength)
				s.holdTimer = Conductor.stepLength;
			s.sustain = true;
		}
		if (note.column < numKeys)
			setTrackVolume([1, 3], 1);
		else
			setTrackVolume([1, 2], 1);

		hscriptExec("sustainHit", [note]);
		luaExec("sustainHit", [sustainNotes.members.indexOf(note)]);

		if (!note.passedHitLimit && note.strumTime + note.sustainLength - songProgress <= (note.hitLimit * playbackRate))
			note.passedHitLimit = true;

		if (note.strumTime + note.sustainLength - songProgress <= 0)
		{
			if (playerColumns.contains(note.column))
			{
				scores.sustains++;
				updateJudgementCounter();
				if (!holdArray[playerColumns.indexOf(note.column)])
					strumNotes.members[note.column].doUnstick = true;
			}
			for (s in note.singers)
				s.sustainEnd();
			note.kill();
			note.destroy();
		}
		else
		{
			var noteHeight:Float = getScrollPosition(note.strumTime, songProgress, note.column);
			note.clipHeight = Math.max(0, -noteHeight + (strumNotes.members[note.column].myH * (note.clipAmount - 0.5)));
		}
	}



	var storedStages:Map<String, Stage> = new Map<String, Stage>();
	function cacheStage(stageId:String)
	{
		if (!storedStages.exists(stageId))
		{
			var s = new Stage(stageId);
			for (piece in s.stageData.pieces)
			{
				if (piece.type != "group" && s.imageExists(piece.asset))
					Paths.cacheGraphic(s.imagePath(piece.asset));
			}

			storedStages[stageId] = s;
		}
	}

	function changeStage(newStage:String, ?replacing = true)
	{
		if (replacing)
		{
			for (piece in stage.stageData.pieces)
				remove(stage.pieces[piece.id], true);
		}

		if (!storedStages.exists(newStage))
			cacheStage(newStage);
		stage = storedStages[newStage];

		camZoom = stage.stageData.camZoom;
		if (replacing)
		{
			FlxTween.cancelTweensOf(FlxG.camera, ["zoom"]);
			FlxTween.tween(FlxG.camera, {zoom: camZoom}, Conductor.beatLength / 1000, { ease: FlxEase.quadOut });
		}

		FlxG.camera.bgColor = FlxColor.fromRGB(stage.stageData.bgColor[0], stage.stageData.bgColor[1], stage.stageData.bgColor[2]);

		for (c in allCharacters)
			postSpawnCharacter(c);

		for (piece in stage.stageData.pieces)
		{
			var ind:Int = members.length;
			for (i in 0...allCharacters.length)
			{
				var slot:Int = Std.int(Math.min(1, stage.stageData.characters.length-1));
				if (piece.layer <= stage.stageData.characters[slot].layer && members.contains(allCharacters[i]) && ind > members.indexOf(allCharacters[i]))
					ind = members.indexOf(allCharacters[i]);
			}
			insert(ind, stage.pieces.get(piece.id));
		}
	}
}
