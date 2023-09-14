package menus;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import openfl.utils.Assets;
import haxe.ds.ArraySort;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;

import haxe.io.Bytes;
import lime.graphics.Image;
import openfl.display.BitmapData;

import funkui.TabMenu;
import funkui.TextButton;
import funkui.DropdownMenu;
import funkui.Checkbox;
import funkui.Label;
import funkui.Stepper;

import data.ObjectData;
import data.Options;
import data.ScoreSystems;
import data.SMFile;
import data.Song;
import game.PlayState;
import game.ResultsSubState;
import menus.UINavigation;
import objects.Alphabet;
import objects.HealthIcon;
import scripting.HscriptHandler;
import scripting.HscriptState;

using StringTools;

class FreeplaySandbox extends IsolatedTabMenu
{
	public static var characters:Array<String> = ["","",""];
	public static var stage:String = "";
	public static var chartSide:Int = 0;
	public static var playbackRate:Float = 1;

	public static var characterCount:Int = 3;
	public static var characterLabels:Array<String> = ["#fpSandboxCharacter0", "#fpSandboxCharacter1", "#fpSandboxCharacter2"];
	public static var characterList:Array<String> = [];
	public static var stageList:Array<String> = [];
	public static var sideList:Array<String> = ["#fpSandboxSide0", "#fpSandboxSide1"];

	public static function character(slot:Int, ?def:String = "")
	{
		if (PlayState.inStoryMode || PlayState.testingChart || slot >= characters.length)
			return def;
		return (characters[slot] == "" ? def : characters[slot]);
	}

	public static function reloadLists()
	{
		var exceptionList:Array<String> = Paths.textData("exceptionList").replace("\r","").replace("\\","/").split("\n");
		characterList = Paths.listFilesSub("data/characters/", ".json");
		stageList = Paths.listFilesSub("data/stages/", ".json");

		var cPoppers:Array<String> = [];
		var sPoppers:Array<String> = [];
		for (e in exceptionList)
		{
			if (e.startsWith("characters/"))
			{
				var filter:String = e.substr("characters/".length);
				var filterMode:Int = 0;
				if (filter.endsWith("*"))
				{
					filter = filter.substr(0, filter.length - 1);
					filterMode = 1;
				}

				for (c in characterList)
				{
					if ((filterMode == 0 && c.toLowerCase() == filter.toLowerCase()) || (filterMode == 1 && c.toLowerCase().startsWith(filter.toLowerCase())))
						cPoppers.push(c);
				}
			}
			else if (e.startsWith("stages/"))
			{
				var filter:String = e.substr("stages/".length);
				var filterMode:Int = 0;
				if (filter.endsWith("*"))
				{
					filter = filter.substr(0, filter.length - 1);
					filterMode = 1;
				}

				for (s in stageList)
				{
					if ((filterMode == 0 && s.toLowerCase() == filter.toLowerCase()) || (filterMode == 1 && s.toLowerCase().startsWith(filter.toLowerCase())))
						sPoppers.push(s);
				}
			}
		}

		for (p in cPoppers)
			characterList.remove(p);

		for (p in sPoppers)
			stageList.remove(p);

		characterList.unshift("");
		stageList.unshift("");
	}

	public static function resetCharacterCount()
	{
		characterCount = 3;
		characterLabels = ["#fpSandboxCharacter0", "#fpSandboxCharacter1", "#fpSandboxCharacter2"];
	}

	public static function setCharacterCount(?c:Int = null, ?l:Array<String> = null)
	{
		if (c == null || l == null)
			resetCharacterCount();
		else
		{
			characterCount = c;
			characterLabels = l.copy();
		}
	}



	override public function new(state:FlxState, reloadFunc:Void->Void, exitFunc:Void->Void)
	{
		if (characterCount > characters.length)
		{
			while (characterCount > characters.length)
				characters.push("");
		}

		super(0, 0, 300, 200 + (characterCount * 40));
		screenCenter();

		var tabGroup:TabGroup = new TabGroup();
		var yy:Int = 20;

		var charDropdowns:Array<DropdownMenu> = [];
		for (i in 0...characterCount)
		{
			var charDropdown:DropdownMenu = new DropdownMenu(10, yy, 280, 20, characters[i], characterList, true);
			charDropdown.onChanged = function() {
				characters[i] = charDropdown.value;
			}
			tabGroup.add(charDropdown);
			charDropdowns.push(charDropdown);
			var labelString:String = Lang.get("#fpSandboxCharacter", [Std.string(i+1)]);
			if (characterLabels != null && characterLabels.length > i)
				labelString = Lang.get(characterLabels[i], [Std.string(i+1)]);
			var charDropdownLabel:Label = new Label(labelString, charDropdown);
			tabGroup.add(charDropdownLabel);
			yy += 40;
		}

		var stageDropdown:DropdownMenu = new DropdownMenu(10, yy, 280, 20, stage, stageList, true);
		stageDropdown.onChanged = function() {
			stage = stageDropdown.value;
		}
		tabGroup.add(stageDropdown);
		var stageDropdownLabel:Label = new Label("#fpSandboxStage", stageDropdown);
		tabGroup.add(stageDropdownLabel);

		var sideListLang:Array<String> = [];
		for (s in sideList)
			sideListLang.push(Lang.get(s));
		var chartSideDropdown:DropdownMenu = new DropdownMenu(10, stageDropdown.y + 40, 280, 20, sideListLang[chartSide], sideListLang);
		chartSideDropdown.onChanged = function() {
			chartSide = chartSideDropdown.valueInt;
			reloadFunc();
		}
		tabGroup.add(chartSideDropdown);
		var stageDropdownLabel:Label = new Label("#fpSandboxSide", chartSideDropdown);
		tabGroup.add(stageDropdownLabel);

		var rateStepper:Stepper = new Stepper(10, chartSideDropdown.y + 40, 280, 20, playbackRate, 0.05, 0.05, 9999, 2);
		rateStepper.onChanged = function() {
			playbackRate = rateStepper.value;
		}
		tabGroup.add(rateStepper);
		var rateStepperLabel:Label = new Label("#fpSandboxRate", rateStepper);
		tabGroup.add(rateStepperLabel);

		var resetButton:TextButton = new TextButton(10, rateStepper.y + 30, 280, 20, "#fpSandboxReset");
		resetButton.onClicked = function()
		{
			for (i in 0...characters.length)
				characters[i] = "";
			stage = "";
			chartSide = 0;
			playbackRate = 1;

			for (c in charDropdowns)
				c.value = "";
			stageDropdown.value = "";
			chartSideDropdown.setValueByInt(0);
			rateStepper.value = 1;
			reloadFunc();
		};
		tabGroup.add(resetButton);

		var exitButton:TextButton = new TextButton(10, resetButton.y + 30, 280, 20, "#fpSandboxExit");
		exitButton.onClicked = function()
		{
			state.remove(this);
			exitFunc();
		};
		tabGroup.add(exitButton);

		addGroup(tabGroup);
	}
}

class FreeplayChartInfo extends FlxSpriteGroup
{
	var bg:FlxSprite;
	var text:FlxText;
	var infoMap:Map<String, Array<String>> = new Map<String, Array<String>>();

	var right:Bool = true;
	var bottom:Bool = true;

	override public function new(?alignX:String = "right", ?alignY:String = "bottom")
	{
		super();

		if (alignX == "left")
			right = false;

		if (alignY == "top")
			bottom = false;

		bg = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		text = new FlxText(5, 5, 0, "", 32);
		text.font = "VCR OSD Mono";
		if (right)
			text.alignment = RIGHT;
		add(text);
	}

	public function reload(songId:String, difficulty:String, ?side:Int = 0, ?artist:String = "")
	{
		if (Options.options.chartInfo && songId != "")
		{
			var label:String = songId.toLowerCase() + difficulty.toUpperCase();
			if (!infoMap.exists(label))
			{
				var chart:SongData = Song.loadSong(songId, difficulty, false);
				if (Paths.smExists(songId))
				{
					var smFile:SMFile = SMFile.load(songId);
					chart = smFile.songData[smFile.difficulties.indexOf(difficulty)];
				}
				var chartInfoArray:Array<String> = [];
				for (i in 0...FreeplaySandbox.sideList.length)
					chartInfoArray.push(Song.calcChartInfo(chart, i));
				infoMap[label] = chartInfoArray;
			}
			text.text = infoMap[label][side];
		}
		else
			text.text = "";

		if (artist != "")
			text.text += Lang.get("#fpArtist", [artist]) + "\n";
		if (text.text == "")
			bg.visible = false;
		else
		{
			bg.visible = true;
			if (right)
				x = FlxG.width - text.width - 10;
			else
			{
				x = 0;
				bg.scale.x = ((text.width + 10) / FlxG.width);
			}
			if (bottom)
				y = FlxG.height - text.height - 10;
			else
			{
				y = 0;
				bg.scale.y = ((text.height + 10) / FlxG.height);
			}
			bg.updateHitbox();
		}
	}
}

class FreeplayMenuState extends MusicBeatState
{
	static var menuState:Int = 0;
	var categories:Map<String, Array<String>>;
	var categoriesList:Array<String> = [];
	var category:String = "";
	static var curCategory:Int = 0;

	var weeks:Map<String, WeekData>;
	public var songList:Array<WeekSongData> = [];
	var songLists:Map<String, Array<String>> = new Map<String, Array<String>>();
	var songUnlocked:Array<Bool> = [];
	var artistList:Array<String> = [];
	var songButtons:FlxTypedSpriteGroup<Alphabet>;
	var songIcons:FlxSpriteGroup;
	public static var curSong:Int = 0;

	var nav:UINumeralNavigation;
	var nav2:UINumeralNavigation;
	public static var navSwitch:Bool = true;

	var infoBG:FlxSprite;
	var scoreText:FlxText;
	public var score:Int = 0;
	var displayScore:Int = 0;

	public static var difficulty:String = "normal";
	var difficultyText:FlxText;

	var chartInfo:FreeplayChartInfo;

	var sideLists:Map<String, Array<String>> = new Map<String, Array<String>>();

	var weekOrder:Array<String> = [];
	function sortWeeks(a:String, b:String):Int
	{
		if (weekOrder.contains(a) && weekOrder.contains(b))
		{
			if (weekOrder.indexOf(a) > weekOrder.indexOf(b))
				return 1;
			if (weekOrder.indexOf(a) < weekOrder.indexOf(b))
				return -1;
		}
		return 0;
	}

	override public function create()
	{
		super.create();
		HscriptHandler.curMenu = "freeplay";

		if (FlxG.save.data.unlockedWeeks == null)
			FlxG.save.data.unlockedWeeks = [];

		Util.menuMusic();

		var bg:FlxSprite = new FlxSprite(Paths.image('ui/' + MainMenuState.menuImages[2]));
		bg.color = MainMenuState.menuColors[2];
		add(bg);

		songButtons = new FlxTypedSpriteGroup<Alphabet>();
		add(songButtons);
		songIcons = new FlxSpriteGroup();
		add(songIcons);

		infoBG = new FlxSprite().makeGraphic(Std.int(FlxG.width), 66, FlxColor.BLACK);
		infoBG.alpha = 0.6;
		add(infoBG);

		scoreText = new FlxText(0, 5, 0, Lang.get("#fpScore", ["0"]), 32);
		scoreText.font = "VCR OSD Mono";
		add(scoreText);

		difficultyText = new FlxText(0, 41, 0, "", 24);
		difficultyText.font = "VCR OSD Mono";
		difficultyText.alignment = CENTER;
		add(difficultyText);

		scoreText.x = FlxG.width - scoreText.width - 5;
		difficultyText.x = scoreText.x;
		difficultyText.fieldWidth = scoreText.width;
		infoBG.x = scoreText.x - 6;

		chartInfo = new FreeplayChartInfo();
		add(chartInfo);

		categories = new Map<String, Array<String>>();
		categoriesList = [];
		var possibleCats:Array<String> = [];
		weeks = new Map<String, WeekData>();
		for (file in Paths.listFilesAndMods("data/weeks/", ".json"))
		{
			var newWeek:WeekData = StoryMenuState.parseWeek(file[0], true);
			if (newWeek.condition != "storyonly" && !(newWeek.startsLocked && !FlxG.save.data.unlockedWeeks.contains(file[0]) && newWeek.hiddenWhenLocked))
			{
				if (categories.exists(file[1]))
					categories.get(file[1]).push(file[0]);
				else
				{
					categories.set(file[1], [file[0]]);
					possibleCats.push(file[1]);
				}
			}
		}

		#if ALLOW_SM
		for (file in Paths.listFilesAndMods("sm/", ""))
		{
			if (categories.exists(file[1]))
			{
				if (!categories.get(file[1]).contains("!SM"))
					categories.get(file[1]).push("!SM");
			}
			else
			{
				categories.set(file[1], ["!SM"]);
				possibleCats.push(file[1]);
			}
		}
		#end

		if (possibleCats.contains("") && !PackagesState.excludeBase)
			categoriesList.push("");
		for (c in ModLoader.modListLoaded)
		{
			if (possibleCats.contains(c) || Paths.hscriptExists("data/states/" + c + "-freeplay"))
				categoriesList.push(c);
		}

		weekOrder = Paths.text("weekOrder").replace("\r","").split("\n");

		FreeplaySandbox.reloadLists();

		nav = new UINumeralNavigation(null, changeCategory, function() {
			if (Paths.hscriptExists("data/states/" + categoriesList[curCategory] + "-freeplay"))
				FlxG.switchState(new HscriptState("data/states/" + categoriesList[curCategory] + "-freeplay"));
			else
			{
				menuState = 1;
				clearMenuStuff();
				curSong = 0;
				reloadMenuStuff();
			}
		}, function() { FlxG.switchState(new MainMenuState()); }, changeCategory);
		add(nav);

		nav2 = new UINumeralNavigation(changeDifficulty, changeSelection, function() {
			if ((songList[curSong].songId != "" || (songList[curSong].hscript != null && songList[curSong].hscript != "")) && songUnlocked[curSong])
			{
				FlxG.sound.play(Paths.sound("ui/confirmMenu"));
				nav2.locked = true;

				if (songList[curSong].songId == "")
				{
					new FlxTimer().start(0.75, function(tmr:FlxTimer)
					{
						FlxG.sound.music.fadeOut(0.5, 0, function(twn:FlxTween) { FlxG.sound.music.stop(); });
						HscriptState.script = "data/states/" + songList[curSong].hscript;
						FlxG.switchState(new HscriptState());
					});
				}
				else
					gotoSong(songList[curSong].songId, difficulty);
			}
		}, function() {
			menuState = 0;
			clearMenuStuff();
			reloadMenuStuff();
		}, changeSelection);
		nav2.uiSounds = [true, false, true];
		add(nav2);

		if (categoriesList.length <= 1 || !navSwitch)
		{
			menuState = 1;
			remove(nav);
			nav2.back = nav.back;
		}
		reloadMenuStuff();
	}

	function clearMenuStuff()
	{
		songIcons.forEachAlive(function(icon:FlxSprite)
		{
			icon.kill();
			icon.destroy();
		});
		songIcons.clear();
	}

	function reloadMenuStuff()
	{
		switch (menuState)
		{
			case 0:
				nav.locked = false;
				nav2.locked = true;
				infoBG.visible = false;
				scoreText.visible = false;
				difficultyText.visible = false;

				chartInfo.visible = false;

				songButtons.x = 0;
				songButtons.y = 0;
				songIcons.x = 0;
				songIcons.y = 0;

				if (songButtons.members.length > categoriesList.length)
				{
					for (i in categoriesList.length...songButtons.members.length)
						songButtons.members[i].text = "";
				}

				for (i in 0...categoriesList.length)
				{
					var categoryName:String = TitleState.defaultVariables.game;
					var categoryIcon:Bytes = null;
					if (categoriesList[i] != "")
					{
						categoryName = ModLoader.getModMetaData(categoriesList[i]).title;
						categoryIcon = ModLoader.getModMetaData(categoriesList[i]).icon;
					}
					if (i >= songButtons.members.length)
						songButtons.add(new Alphabet(Std.int((i * 20) + 90), Std.int((i * 1.3 * 120) + (FlxG.height * 0.48)), "", "bold", Std.int(FlxG.width * 0.9)));
					var textButton:Alphabet = songButtons.members[i];
					textButton.text = categoryName;
					textButton.setFont("bold");
					var icon:FlxSprite = new FlxSprite(Std.int(textButton.x + textButton.width + 85), Std.int(textButton.y + 45));
					if (categoryIcon == null)
						icon.makeGraphic(1, 1, FlxColor.TRANSPARENT);
					else
					{
						icon.pixels = BitmapData.fromImage( Image.fromBytes(categoryIcon) );
						if (icon.width > 150 || icon.height > 150)
						{
							icon.setGraphicSize(150);
							icon.updateHitbox();
						}
						icon.x -= icon.width / 2;
						icon.y -= icon.height / 2;
					}
					songIcons.add(icon);
				}

				songButtons.setPosition(curCategory * -20, curCategory * 1.3 * -120);
				songIcons.setPosition(songButtons.x, songButtons.y);
				changeCategory();

			case 1:
				nav.locked = true;
				nav2.locked = false;
				if (curCategory < categoriesList.length)
					category = categoriesList[curCategory];
				infoBG.visible = true;
				scoreText.visible = true;
				difficultyText.visible = true;

				chartInfo.visible = true;

				songList = [];
				songUnlocked = [];
				artistList = [];
				songButtons.setPosition(0, 0);
				songIcons.setPosition(0, 0);
				if (!categories.exists(category))
				{
					menuState = 0;
					clearMenuStuff();
					reloadMenuStuff();
					return;
				}

				var weekNames:Array<String> = categories[category];
				if (!songLists.exists(category))
					songLists[category] = [];
				ArraySort.sort(weekNames, sortWeeks);
				var hasSM:Bool = false;
				if (weekNames.contains("!SM"))
				{
					hasSM = true;
					weekNames.remove("!SM");
				}

				var spot:Int = 0;
				if (weekNames.length > 0)
				{
					for (i in 0...weekNames.length)
					{
						if (!weeks.exists(weekNames[i]))
							weeks[weekNames[i]] = StoryMenuState.parseWeek(weekNames[i]);
						var newWeek:WeekData = weeks[weekNames[i]];
						var weekLocked:Bool = (newWeek.startsLocked && !FlxG.save.data.unlockedWeeks.contains(weekNames[i]));
						for (song in newWeek.songs)
						{
							if (song.difficulties == null || song.difficulties.length == 0)
								song.difficulties = newWeek.difficulties;
							songList.push(song);
							songUnlocked.push(!weekLocked);
							if (song.songId == "")
								artistList.push("");
							else
								artistList.push(Song.getSongArtist(song.songId, song.difficulties[0]));
							if (song.title == null)
								song.title = "";
							if (spot >= songLists[category].length)
							{
								var songName:String = (song.title == "" ? Song.getSongName(song.songId, song.difficulties[0]) : Lang.get(song.title));
								if (weekLocked)
									songName = Lang.get("#fpLocked");
								songLists[category].push(songName);
							}
							var fontName:String = "bold";
							if (song.songId == "" && (song.hscript == null || song.hscript == ""))
								fontName = "default";
							if (spot >= songButtons.members.length)
								songButtons.add(new Alphabet(Std.int((spot * 20) + 90), Std.int((spot * 1.3 * 120) + (FlxG.height * 0.48)), "", fontName, Std.int(FlxG.width * 0.9)));
							var textButton:Alphabet = songButtons.members[spot];
							textButton.text = songLists[category][spot];
							textButton.setFont(fontName);
							if (weekLocked)
							{
								var lock:FlxSprite = new FlxSprite(Std.int(textButton.x + textButton.width + 85), Std.int(textButton.y + 45), Paths.image("ui/lock"));
								lock.x -= lock.width / 2;
								lock.y -= lock.height / 2;
								songIcons.add(lock);
							}
							else
							{
								var icon:HealthIcon = new HealthIcon(Std.int(textButton.x + textButton.width + 85), Std.int(textButton.y + 45), song.icon);
								icon.x -= icon.width / 2;
								icon.y -= icon.height / 2;
								songIcons.add(icon);
							}
							spot++;
						}
					}
				}

				if (hasSM)
				{
					var smFolders:Array<String> = Paths.listFilesFromMod(category,"sm/","");

					for (fl in smFolders)
					{
						songList.push({songId: "", icon: TitleState.defaultVariables.noicon, difficulties: [""], characters: 3});
						songUnlocked.push(true);
						artistList.push("");
						if (spot >= songButtons.members.length)
							songButtons.add(new Alphabet(Std.int((spot * 20) + 90), Std.int((spot * 1.3 * 120) + (FlxG.height * 0.48)), "", "default", Std.int(FlxG.width * 0.9)));
						var textLabel:Alphabet = songButtons.members[spot];
						textLabel.text = fl;
						textLabel.setFont("default");
						spot++;

						var smFiles:Array<String> = Paths.listFilesFromMod(category,"sm/" + fl + "/","");
						for (f in smFiles)
						{
							var thisSM:String = Paths.listFilesFromMod(category,"sm/" + fl + "/" + f,".sm")[0];
							var thisSMFile:SMFile = SMFile.load(fl + "/" + f + "/" + thisSM);

							if (Assets.exists(Paths.smSong(fl + "/" + f + "/" + thisSM, thisSMFile.ogg)))
							{
								songList.push({songId: fl + "/" + f + "/" + thisSM, icon: TitleState.defaultVariables.noicon, difficulties: thisSMFile.difficulties, characters: 3});
								songUnlocked.push(true);
								artistList.push(thisSMFile.artist);
								if (spot >= songButtons.members.length)
									songButtons.add(new Alphabet(Std.int((spot * 20) + 90), Std.int((spot * 1.3 * 120) + (FlxG.height * 0.48)), "", "bold", Std.int(FlxG.width * 0.9)));
								var textButton:Alphabet = songButtons.members[spot];
								textButton.text = thisSMFile.title;
								textButton.setFont("bold");
								spot++;
							}
						}
					}
				}

				if (songButtons.members.length > spot)
				{
					for (i in spot...songButtons.members.length)
						songButtons.members[i].text = "";
				}

				songButtons.setPosition(curSong * -20, curSong * 1.3 * -120);
				songIcons.setPosition(songButtons.x, songButtons.y);
				changeSelection();
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Options.keyJustPressed("fullscreen") && !DropdownMenu.isOneActive)
			FlxG.fullscreen = !FlxG.fullscreen;

		if (menuState > 0)
		{
			songButtons.x = FlxMath.lerp(songButtons.x, curSong * -20, 0.16 * elapsed * 60);
			songButtons.y = FlxMath.lerp(songButtons.y, curSong * 1.3 * -120, 0.16 * elapsed * 60);
		}
		else
		{
			songButtons.x = FlxMath.lerp(songButtons.x, curCategory * -20, 0.16 * elapsed * 60);
			songButtons.y = FlxMath.lerp(songButtons.y, curCategory * 1.3 * -120, 0.16 * elapsed * 60);
		}
		songIcons.setPosition(songButtons.x, songButtons.y);

		if (displayScore != score)
		{
			displayScore = Std.int(Math.floor(FlxMath.lerp(displayScore, score, 0.4)));
			if (Math.abs(displayScore - score) <= 10)
				displayScore = score;

			scoreText.text = Lang.get("#fpScore", [Std.string(displayScore)]);
			scoreText.x = FlxG.width - scoreText.width - 5;
			difficultyText.x = scoreText.x;
			difficultyText.fieldWidth = scoreText.width;
			infoBG.x = scoreText.x - 6;
		}

		if (!(nav.locked && nav2.locked))
		{
			if (menuState > 0)
			{
				if (Options.keyJustPressed("ui_reset"))
				{
					persistentUpdate = false;
					openSubState(new FreeplayMenuResetSubState(songList[curSong].songId, difficulty, FreeplaySandbox.chartSide, getScore));
				}

				if (Options.keyJustPressed("sandbox"))
				{
					nav2.locked = true;
					FlxG.mouse.visible = true;
					add(new FreeplaySandbox(this, function() {
						reload();
					}, function() {
						nav2.locked = false;
						FlxG.mouse.visible = false;
					}));
				}
			}
		}
	}

	function getScore()
	{
		score = ScoreSystems.loadSongScore(songList[curSong].songId, difficulty, FreeplaySandbox.chartSide);
	}

	public static function gotoSong(song:String, diff:String, ?delay:Float = 0.75)
	{
		ResultsSubState.resetStatics();

		new FlxTimer().start(delay, function(tmr:FlxTimer)
		{
			FlxG.sound.music.fadeOut(0.5, 0, function(twn:FlxTween) { FlxG.sound.music.stop(); });

			PlayState.firstPlay = true;
			if (Std.isOfType(FlxG.state, HscriptState))
				HscriptState.setFromState();
			FlxG.switchState(new PlayState(false, song, diff));
		});
	}

	function changeCategory(change:Int = 0)
	{
		curCategory = Util.loop(curCategory + change, 0, categoriesList.length - 1);

		var i:Int = 0;
		songButtons.forEachAlive(function(button:Alphabet)
		{
			if (i == curCategory)
				button.alpha = 1;
			else
				button.alpha = 0.6;
			i++;
		});

		i = 0;
		songIcons.forEachAlive(function(icon:FlxSprite)
		{
			if (i == curCategory)
				icon.alpha = 1;
			else
				icon.alpha = 0.6;
			i++;
		});
	}

	function changeSelection(change:Int = 0)
	{
		curSong = Util.loop(curSong + change, 0, songList.length - 1);

		var i:Int = 0;
		songButtons.forEachAlive(function(button:Alphabet)
		{
			if (i == curSong && songUnlocked[i])
				button.alpha = 1;
			else
				button.alpha = 0.6;
			i++;
		});

		i = 0;
		songIcons.forEachAlive(function(icon:FlxSprite)
		{
			if (i == curSong)
				icon.alpha = 1;
			else
				icon.alpha = 0.6;
			i++;
		});

		if (songList[curSong].songId == "")
		{
			infoBG.visible = false;
			scoreText.visible = false;
			difficultyText.visible = false;
		}
		else
		{
			infoBG.visible = true;
			scoreText.visible = true;
			difficultyText.visible = songUnlocked[curSong];
			if (!songList[curSong].difficulties.contains(difficulty))
				difficulty = songList[curSong].difficulties[0];
			FreeplaySandbox.setCharacterCount(songList[curSong].characters, songList[curSong].characterLabels);
		}
		reload();
	}

	function changeDifficulty(change:Int = 0)
	{
		if (songList[curSong].songId == "")
			return;

		if (change != 0 && !songUnlocked[curSong])
			return;

		var songData:WeekSongData = songList[curSong];
		if (songData.difficulties.length <= 1)
			return;

		var diffInt:Int = songData.difficulties.indexOf(difficulty);
		diffInt = Util.loop(diffInt + change, 0, songData.difficulties.length - 1);
		difficulty = songData.difficulties[diffInt];

		reload();
	}

	function updateDifficultyText()
	{
		difficultyText.text = Lang.getNoHash(difficulty).toUpperCase();
		if (songList[curSong].difficulties.length > 1)
			difficultyText.text = "< " + difficultyText.text + " >";
	}

	function reload()
	{
		if (songList[curSong].songId != "")
		{
			updateDifficultyText();
			getScore();
		}
		reloadChartInfo();
	}

	function reloadChartInfo()
	{
		if (Paths.smExists(songList[curSong].songId))
		{
			var smFile:SMFile = SMFile.load(songList[curSong].songId, false);
			var divChart:SongData = smFile.songData[smFile.difficulties.indexOf(difficulty)];
			divChart = Song.correctDivisions(divChart);

			FreeplaySandbox.sideList = divChart.columnDivisionNames.copy();
		}
		else
			FreeplaySandbox.sideList = Song.getSongSideList(songList[curSong].songId, difficulty);
		if (FreeplaySandbox.chartSide >= FreeplaySandbox.sideList.length)
			FreeplaySandbox.chartSide = 0;

		chartInfo.reload(songList[curSong].songId, difficulty, FreeplaySandbox.chartSide, artistList[curSong]);
	}
}

class FreeplayMenuResetSubState extends FlxSubState
{
	var yes:Alphabet;
	var no:Alphabet;
	var option:Bool = false;

	override public function new(song:String, difficulty:String, side:Int, ?onOption:Void->Void = null)
	{
		super();

		FlxG.sound.play(Paths.sound("ui/cancelMenu"));

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		var confirmText:Alphabet = new Alphabet(0, 150, "Are you sure you want to reset your score for this song and difficulty?", "bold", Std.int(FlxG.width * 0.9), true, 0.75);
		confirmText.align = "center";
		confirmText.screenCenter(X);
		add(confirmText);

		yes = new Alphabet(0, 500, "");
		add(yes);

		no = new Alphabet(0, 500, "");
		add(no);

		updateText();

		for (m in members)
		{
			var s:FlxSprite = cast m;
			var a:Float = s.alpha;
			s.alpha = 0;
			FlxTween.tween(s, {alpha: a}, 0.5);
		}

		var nav:UINumeralNavigation = new UINumeralNavigation(function(a) {
			option = !option;
			updateText();
		}, null, function() {
			if (!option)
				ScoreSystems.resetSongScore(song, difficulty, side);
			if (onOption != null)
				onOption();
			close();
		});
		add(nav);
	}

	function updateText()
	{
		if (option)
		{
			yes.text = "Yes";
			no.text = "> No <";
		}
		else
		{
			yes.text = "> Yes <";
			no.text = "No";
		}
		yes.x = (FlxG.width / 3) - (yes.width / 2);
		no.x = (FlxG.width * 2 / 3) - (no.width / 2);
	}
}