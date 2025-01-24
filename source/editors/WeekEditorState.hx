package editors;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxSpriteUtil;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.addons.display.FlxRuntimeShader;
import helpers.DeepEquals;
import helpers.Cloner;
import data.ObjectData;
import data.Options;
import data.Song;
import menus.EditorMenuState;
import menus.MainMenuState;
import menus.story.StoryMenuState;
import menus.story.StoryMenuCharacter;
import menus.freeplay.FreeplayCapsule;
import objects.Alphabet;
import objects.Character;
import objects.HealthIcon;
import haxe.Json;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import lime.app.Application;

import newui.UIControl;
import newui.TopMenu;
import newui.DropdownMenu;
import newui.Button;
import newui.Checkbox;
import newui.ColorPickSubstate;
import newui.InputText;
import newui.Label;
import newui.PopupWindow;
import newui.Stepper;

using StringTools;

class WeekEditorState extends BaseEditorState
{
	public var weekData:WeekData;
	var dataLog:Array<WeekData> = [];

	var settingsStuff:FlxSpriteGroup;
	var storyStuff:FlxSpriteGroup;

	var allSongs:Array<String> = [];
	var allScripts:Array<String> = [];

	var curSong:Int = 0;
	var hoveredCapsule:Int = -1;
	var grpCapsules:FlxTypedSpriteGroup<FreeplayCapsule>;

	public var bgYellow:FlxSprite;
	var banner:FlxSprite;
	var imageButton:FlxSprite;
	var menuCharacters:FlxTypedSpriteGroup<StoryMenuCharacter>;
	var weekTitle:FlxText;

	override public function create()
	{
		super.create();
		filenameNew = "New Week";

		settingsStuff = new FlxSpriteGroup();
		add(settingsStuff);
		storyStuff = new FlxSpriteGroup();

		var pinkBack:FlxSprite = new FlxSprite(Paths.image("ui/freeplay/pinkBack"));
		pinkBack.color = 0xFFFFD863;
		settingsStuff.add(pinkBack);

		var orangeBackShit:FlxSprite = new FlxSprite(84, 440).makeGraphic(Std.int(pinkBack.width), 75, 0xFFFEDA00);
		settingsStuff.add(orangeBackShit);

		var alsoOrangeLOL:FlxSprite = new FlxSprite(0, orangeBackShit.y).makeGraphic(100, Std.int(orangeBackShit.height), 0xFFFFD400);
		settingsStuff.add(alsoOrangeLOL);

		FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);

		var bgDad:FlxSprite = new FlxSprite(pinkBack.width * 0.75, 0, Paths.image("ui/freeplay/characters/bf/freeplayBGdad"));
		bgDad.setGraphicSize(0, FlxG.height);
		bgDad.updateHitbox();
		var bgDadShader:FlxRuntimeShader = new FlxRuntimeShader(Paths.shader("AngleMask"), null);
		bgDadShader.data.endPosition.value = [90, 100];
		bgDadShader.data.extraTint.value = [1, 1, 1];
		bgDad.shader = bgDadShader;
		settingsStuff.add(bgDad);

		if (isNew)
		{
			weekData =
			{
				image: TitleState.defaultVariables.storyimage,
				title: "",
				color: [249, 207, 81],
				characters: [[TitleState.defaultVariables.story1, 0, 0], [TitleState.defaultVariables.story2, Math.round((FlxG.width / 3) / 5) * 5, 0], [TitleState.defaultVariables.story3, Math.round((FlxG.width * 2 / 3) / 5) * 5, 0]],
				songs: [],
				difficulties: ["normal", "hard", "easy"],
				difficultiesLocked: [],
				condition: "",
				startsLocked: false,
				startsLockedInFreeplay: false,
				weekToUnlock: "",
				hiddenWhenLocked: false
			}
		}
		else
			weekData = StoryMenuState.parseWeek(id, Paths.json("weeks/" + id));

		allSongs = [""];
		for (songFolder in Paths.listFilesSub("data/songs/", ""))
		{
			if ((Paths.listFiles("songs/" + songFolder + "/", ".ogg").length > 0 || Paths.listFiles("data/songs/" + songFolder + "/", ".ogg").length > 0) && !allSongs.contains(songFolder))
				allSongs.push(songFolder);
		}

		allScripts = [""];
		for (f in Paths.listFilesSub("data/states/", ".hscript"))
		{
			if (!f.endsWith("-story") && !f.endsWith("-freeplay") && !["TitleState", "MainMenuState", "CreditsMenuState", "ResultsState"].contains(f))
				allScripts.push(f);
		}

		grpCapsules = new FlxTypedSpriteGroup<FreeplayCapsule>();
		settingsStuff.add(grpCapsules);
		refreshSongs();

		var overhangStuff:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 64, FlxColor.BLACK);
		settingsStuff.add(overhangStuff);

		bgYellow = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, FlxColor.WHITE);
		storyStuff.add(bgYellow);

		banner = new FlxSprite(0, 56);
		storyStuff.add(banner);

		imageButton = new FlxSprite(0, 480);
		refreshImageButton();
		storyStuff.add(imageButton);

		menuCharacters = new FlxTypedSpriteGroup<StoryMenuCharacter>();
		storyStuff.add(menuCharacters);
		for (i in 0...3)
		{
			var char:StoryMenuCharacter = new StoryMenuCharacter(i);
			menuCharacters.add(char);
		}
		refreshWeekBanner();
		refreshMenuCharacters();

		weekTitle = new FlxText(0, 10, FlxG.width - 10, Lang.get(weekData.title), 32);
		weekTitle.alpha = 0.7;
		weekTitle.font = "VCR OSD Mono";
		weekTitle.alignment = RIGHT;
		storyStuff.add(weekTitle);



		createUI("WeekEditor");

		tabMenu.onTabChanged = function() {
			remove(settingsStuff, true);
			remove(storyStuff, true);
			switch (tabMenu.curTabName)
			{
				case "Story": add(storyStuff);
				default: add(settingsStuff);
			}
		}



		var visibleInStory:Checkbox = cast element("visibleInStory");
		visibleInStory.condition = function() {
			return (weekData.condition == "" || weekData.condition.toLowerCase() == "storyonly");
		}

		var visibleInFreeplay:Checkbox = cast element("visibleInFreeplay");
		visibleInFreeplay.condition = function() {
			return (weekData.condition == "" || weekData.condition.toLowerCase() == "freeplayonly");
		}

		visibleInStory.onClicked = function() {
			if (visibleInStory.checked && visibleInFreeplay.checked)
				weekData.condition = "";
			else if (visibleInStory.checked)
				weekData.condition = "storyOnly";
			else
				weekData.condition = "freePlayOnly";
		}

		visibleInFreeplay.onClicked = function() {
			if (visibleInStory.checked && visibleInFreeplay.checked)
				weekData.condition = "";
			else if (visibleInFreeplay.checked)
				weekData.condition = "freePlayOnly";
			else
				weekData.condition = "storyOnly";
		}

		var difficulties:TextButton = cast element("difficulties");
		difficulties.onClicked = function()
		{
			var window:PopupWindow = null;
			var vbox:VBox = new VBox(35, 35);

			var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
			var scroll:VBox = menu.vbox;

			for (i in 0...weekData.difficulties.length)
			{
				var diffHbox:HBox = new HBox();
				var difficulty:InputText = new InputText(0, 0);
				difficulty.text = weekData.difficulties[i];
				difficulty.forceCase = 2;
				difficulty.customFilterPattern = ~/[^a-zA-Z,]*/g;
				difficulty.focusLost = function() {
					if (weekData.difficultiesLocked.contains(weekData.difficulties[i]))
					{
						weekData.difficultiesLocked.remove(weekData.difficulties[i]);
						weekData.difficultiesLocked.push(difficulty.text);
					}
					weekData.difficulties[i] = difficulty.text;
				}
				diffHbox.add(difficulty);

				var diffLocked:Checkbox = new Checkbox(0, 0, "Locked until Week is Beaten");
				diffLocked.checked = (weekData.difficultiesLocked.contains(weekData.difficulties[i]));
				diffLocked.condition = function() { return (weekData.difficultiesLocked.contains(weekData.difficulties[i])); }
				diffLocked.onClicked = function() {
					if (diffLocked.checked && weekData.difficultiesLocked.length < weekData.difficulties.length - 1 && !weekData.difficultiesLocked.contains(weekData.difficulties[i]))
						weekData.difficultiesLocked.push(weekData.difficulties[i]);
					if (!diffLocked.checked && weekData.difficultiesLocked.contains(weekData.difficulties[i]))
						weekData.difficultiesLocked.remove(weekData.difficulties[i]);
				}
				diffHbox.add(diffLocked);

				if (weekData.difficulties.length > 1)
				{
					var _remove:Button = new Button(0, 0, "buttonTrash");
					_remove.onClicked = function() {
						weekData.difficulties.splice(i, 1);
						window.close();
						new FlxTimer().start(0.01, function(tmr:FlxTimer) { difficulties.onClicked(); });
					}
					diffHbox.add(_remove);
				}

				scroll.add(diffHbox);
			}

			vbox.add(menu);

			var applyToSongs:TextButton = new TextButton(0, 0, "Apply to Songs", Button.LONG);
			applyToSongs.onClicked = function() {
				for (song in weekData.songs)
					song.difficulties = weekData.difficulties.copy();
			}
			vbox.add(applyToSongs);

			var _add:TextButton = new TextButton(0, 0, "Add");
			_add.onClicked = function() {
				weekData.difficulties.push(weekData.difficulties[weekData.difficulties.length-1]);
				window.close();
				new FlxTimer().start(0.01, function(tmr:FlxTimer) { difficulties.onClicked(); });
			}
			vbox.add(_add);

			var accept:TextButton = new TextButton(0, 0, "Accept", function() { window.close(); });
			vbox.add(accept);

			window = PopupWindow.CreateWithGroup(vbox);
		}

		var startsLockedCheck:Checkbox = cast element("startsLockedCheck");
		startsLockedCheck.checked = weekData.startsLocked;
		startsLockedCheck.condition = function() { return weekData.startsLocked; }
		startsLockedCheck.onClicked = function() { weekData.startsLocked = startsLockedCheck.checked; }

		var startsLockedInFreeplayCheck:Checkbox = cast element("startsLockedInFreeplayCheck");
		startsLockedInFreeplayCheck.checked = weekData.startsLockedInFreeplay;
		startsLockedInFreeplayCheck.condition = function() { return weekData.startsLockedInFreeplay; }
		startsLockedInFreeplayCheck.onClicked = function() { weekData.startsLockedInFreeplay = startsLockedCheck.checked; }

		if (weekData.weekToUnlock == null)
			weekData.weekToUnlock = "";
		var weekList:Array<String> = Paths.listFilesSub("data/weeks/", ".json");
		weekList.unshift("");
		var weekToUnlockDropdown:DropdownMenu = cast element("weekToUnlockDropdown");
		weekToUnlockDropdown.valueList = weekList;
		weekToUnlockDropdown.value = weekData.weekToUnlock;
		weekToUnlockDropdown.condition = function() { return weekData.weekToUnlock; }
		weekToUnlockDropdown.onChanged = function() { weekData.weekToUnlock = weekToUnlockDropdown.value; }

		var hiddenWhenLockedCheck:Checkbox = cast element("hiddenWhenLockedCheck");
		hiddenWhenLockedCheck.checked = weekData.hiddenWhenLocked;
		hiddenWhenLockedCheck.condition = function() { return weekData.hiddenWhenLocked; }
		hiddenWhenLockedCheck.onClicked = function() { weekData.hiddenWhenLocked = hiddenWhenLockedCheck.checked; }



		var addSong:TextButton = cast element("addSong");
		addSong.onClicked = function() {
			if (weekData.songs.length > 0)
				weekData.songs.push({songId: weekData.songs[curSong].songId, iconNew: weekData.songs[curSong].iconNew, difficulties: weekData.songs[curSong].difficulties.copy(), title: "", characters: 3, characterLabels: ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"]});
			else
				weekData.songs.push({songId: "test", iconNew: "none", difficulties: weekData.difficulties.copy(), title: "", characters: 3, characterLabels: ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"]});
			curSong = weekData.songs.length - 1;
			refreshSongs();
		}

		var insertSong:TextButton = cast element("insertSong");
		insertSong.onClicked = function() {
			if (weekData.songs.length > 0)
			{
				var newSong:WeekSongData = {songId: weekData.songs[curSong].songId, iconNew: weekData.songs[curSong].iconNew, difficulties: weekData.songs[curSong].difficulties.copy(), title: "", characters: 3, characterLabels: ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"]};
				weekData.songs.insert(curSong, newSong);
				refreshSongs();
			}
		}

		var removeSong:TextButton = cast element("removeSong");
		removeSong.onClicked = function() {
			if (weekData.songs.length > 0)
			{
				weekData.songs.splice(curSong, 1);
				if (curSong > 0)
					curSong--;
				refreshSongs();
			}
		}

		var prevSong:TextButton = cast element("prevSong");
		prevSong.onClicked = function() {
			changeSelection(-1);
		}

		var nextSong:TextButton = cast element("nextSong");
		nextSong.onClicked = function() {
			changeSelection(1);
		}

		var moveUp:TextButton = cast element("moveUp");
		moveUp.onClicked = function() {
			if (weekData.songs.length > 0 && curSong > 0)
			{
				var movingSong:WeekSongData = weekData.songs[curSong];
				weekData.songs.splice(curSong, 1);
				curSong--;
				weekData.songs.insert(curSong, movingSong);
				refreshSongs();
			}
		}

		var moveDown:TextButton = cast element("moveDown");
		moveDown.onClicked = function() {
			if (weekData.songs.length > 0 && curSong < weekData.songs.length - 1)
			{
				var movingSong:WeekSongData = weekData.songs[curSong];
				weekData.songs.splice(curSong, 1);
				curSong++;
				weekData.songs.insert(curSong, movingSong);
				refreshSongs();
			}
		}

		var songDropdown:DropdownMenu = cast element("songDropdown");
		songDropdown.valueList = allSongs;
		songDropdown.value = allSongs[1];
		songDropdown.condition = function() {
			if (weekData.songs.length > 0)
				return weekData.songs[curSong].songId;
			return songDropdown.value;
		}
		songDropdown.onChanged = function() {
			if (weekData.songs.length > 0)
			{
				weekData.songs[curSong].songId = songDropdown.value;
				refreshSongs();
			}
		}

		var iconNewInput:InputText = cast element("iconNewInput");
		iconNewInput.condition = function() {
			if (weekData.songs.length > 0)
				return weekData.songs[curSong].iconNew;
			return iconNewInput.text;
		}
		iconNewInput.focusLost = function() {
			if (weekData.songs.length > 0)
			{
				if (iconNewInput.text.trim() != "" && Paths.imageExists("ui/freeplay/icons/" + iconNewInput.text + "pixel"))
					weekData.songs[curSong].iconNew = iconNewInput.text;
				else
					weekData.songs[curSong].iconNew = "none";
				refreshSongs();
			}
		}

		var loadNewIconButton:Button = cast element("loadNewIconButton");
		loadNewIconButton.onClicked = function() {
			if (weekData.songs.length > 0)
			{
				var file:FileBrowser = new FileBrowser();
				file.loadCallback = function(fullPath:String) {
					var nameArray:Array<String> = fullPath.replace('\\','/').split('/');
					if (nameArray.indexOf("icons") != -1)
					{
						while (nameArray[0] != "icons")
							nameArray.shift();
						nameArray.shift();

						var finalName = nameArray.join("/");
						finalName = finalName.substr(0, finalName.length - 9);
						weekData.songs[curSong].iconNew = finalName;
						refreshSongs();
					}
				}
				file.load("png;*.json");
			}
		}

		var songTitle:InputText = cast element("songTitle");
		songTitle.condition = function() {
			if (weekData.songs.length > 0 && weekData.songs[curSong].title != null)
				return weekData.songs[curSong].title;
			return songTitle.text;
		}
		songTitle.focusLost = function() {
			if (weekData.songs.length > 0)
			{
				weekData.songs[curSong].title = songTitle.text;
				refreshSongs();
			}
		}

		var allVariants:Array<String> = Paths.listFilesSub("data/players/", ".json");

		var songVariant:DropdownMenu = cast element("songVariant");
		songVariant.valueList = allVariants;
		songVariant.condition = function() {
			if (weekData.songs.length > 0 && weekData.songs[curSong].variant != null)
				return weekData.songs[curSong].variant;
			return "bf";
		}
		songVariant.onChanged = function() {
			if (weekData.songs.length > 0)
			{
				weekData.songs[curSong].variant = songVariant.value;
				refreshSongs();
			}
		}

		var songAlbums:TextButton = cast element("songAlbums");
		songAlbums.onClicked = function()
		{
			if (weekData.songs.length > 0)
			{
				if (weekData.songs[curSong].albums == null)
					weekData.songs[curSong].albums = [];

				var window:PopupWindow = null;
				var vbox:VBox = new VBox(35, 35);

				var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
				var scroll:VBox = menu.vbox;

				var albums:Array<String> = [""];
				for (album in Paths.listFilesSub("images/ui/freeplay/albums", ""))
					albums.push(album);

				var difficulties:Array<String> = [""];
				for (diff in weekData.songs[curSong].difficulties)
					difficulties.push(diff);

				for (i in 0...weekData.songs[curSong].albums.length)
				{
					var albumHbox:HBox = new HBox();
					albumHbox.add(new Label("Album " + Std.string(i + 1) + ":"));
					var album:DropdownMenu = new DropdownMenu(0, 0, weekData.songs[curSong].albums[i][1], albums, "None");
					album.onChanged = function() { weekData.songs[curSong].albums[i][1] = album.value; }
					albumHbox.add(album);
					var _remove:Button = new Button(0, 0, "buttonTrash");
					_remove.onClicked = function() {
						weekData.songs[curSong].albums.splice(i, 1);
						window.close();
						new FlxTimer().start(0.01, function(tmr:FlxTimer) { songAlbums.onClicked(); });
					}
					albumHbox.add(_remove);
					scroll.add(albumHbox);

					var difficultyHbox:HBox = new HBox();
					difficultyHbox.add(new Label("Difficulty:"));
					var difficulty:DropdownMenu = new DropdownMenu(0, 0, weekData.songs[curSong].albums[i][0], difficulties, "Default");
					difficulty.onChanged = function() { weekData.songs[curSong].albums[i][0] = difficulty.value; }
					difficultyHbox.add(difficulty);
					scroll.add(difficultyHbox);
				}

				if (weekData.songs[curSong].albums.length > 0)
					vbox.add(menu);

				var _add:TextButton = new TextButton(0, 0, "Add");
				_add.onClicked = function() {
					if (weekData.songs[curSong].albums.length > 0)
						weekData.songs[curSong].albums.push(weekData.songs[curSong].albums[weekData.songs[curSong].albums.length-1].copy());
					else
						weekData.songs[curSong].albums.push(["",""]);
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { songAlbums.onClicked(); });
				}
				vbox.add(_add);

				var accept:TextButton = new TextButton(0, 0, "Accept");
				accept.onClicked = function() { window.close(); }
				vbox.add(accept);

				window = PopupWindow.CreateWithGroup(vbox);
			}
		}

		var songDifficulties:TextButton = cast element("songDifficulties");
		songDifficulties.onClicked = function()
		{
			if (weekData.songs.length > 0)
			{
				var window:PopupWindow = null;
				var vbox:VBox = new VBox(35, 35);

				var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
				var scroll:VBox = menu.vbox;

				for (i in 0...weekData.songs[curSong].difficulties.length)
				{
					var diffHbox:HBox = new HBox();
					var difficulty:InputText = new InputText(0, 0);
					difficulty.text = weekData.songs[curSong].difficulties[i];
					difficulty.forceCase = 2;
					difficulty.customFilterPattern = ~/[^a-zA-Z,]*/g;
					difficulty.focusLost = function() { weekData.songs[curSong].difficulties[i] = difficulty.text; }
					diffHbox.add(difficulty);
					if (weekData.songs[curSong].difficulties.length > 1)
					{
						var _remove:Button = new Button(0, 0, "buttonTrash");
						_remove.onClicked = function() {
							weekData.songs[curSong].difficulties.splice(i, 1);
							window.close();
							new FlxTimer().start(0.01, function(tmr:FlxTimer) { songDifficulties.onClicked(); });
						}
						diffHbox.add(_remove);
					}
					scroll.add(diffHbox);
				}

				vbox.add(menu);

				var sameAsWeek:TextButton = new TextButton(0, 0, "Same as Week", Button.LONG);
				sameAsWeek.onClicked = function() {
					weekData.songs[curSong].difficulties = weekData.difficulties.copy();
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { songDifficulties.onClicked(); });
				}
				vbox.add(sameAsWeek);

				var _add:TextButton = new TextButton(0, 0, "Add");
				_add.onClicked = function() {
					weekData.songs[curSong].difficulties.push(weekData.songs[curSong].difficulties[weekData.songs[curSong].difficulties.length-1]);
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { songDifficulties.onClicked(); });
				}
				vbox.add(_add);

				var accept:TextButton = new TextButton(0, 0, "Accept");
				accept.onClicked = function() { window.close(); }
				vbox.add(accept);

				window = PopupWindow.CreateWithGroup(vbox);
			}
		}

		var songCharLabels:TextButton = cast element("songCharLabels");
		songCharLabels.onClicked = function()
		{
			if (weekData.songs.length > 0)
			{
				if (weekData.songs[curSong].characterLabels.length > weekData.songs[curSong].characters)
					weekData.songs[curSong].characterLabels.resize(weekData.songs[curSong].characters);

				if (weekData.songs[curSong].characterLabels.length < weekData.songs[curSong].characters)
				{
					while (weekData.songs[curSong].characterLabels.length < weekData.songs[curSong].characters)
					{
						if (weekData.songs[curSong].characterLabels.length < 3)
							weekData.songs[curSong].characterLabels.push("#freeplay.sandbox.character" + Std.string(weekData.songs[curSong].characterLabels.length));
						else
							weekData.songs[curSong].characterLabels.push("Singer " + Std.string(weekData.songs[curSong].characterLabels.length + 1) + ":");
					}
				}

				var window:PopupWindow = null;
				var vbox:VBox = new VBox(35, 35);

				var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
				var scroll:VBox = menu.vbox;

				for (i in 0...weekData.songs[curSong].characterLabels.length)
				{
					var charHbox:HBox = new HBox();
					var charLabel:InputText = new InputText(0, 0);
					charLabel.text = weekData.songs[curSong].characterLabels[i];
					charLabel.focusLost = function() { weekData.songs[curSong].characterLabels[i] = charLabel.text; }
					charHbox.add(charLabel);
					if (weekData.songs[curSong].characterLabels.length > 3)
					{
						var _remove:Button = new Button(0, 0, "buttonTrash");
						_remove.onClicked = function() {
							weekData.songs[curSong].characterLabels.splice(i, 1);
							weekData.songs[curSong].characters = weekData.songs[curSong].characterLabels.length;
							window.close();
							new FlxTimer().start(0.01, function(tmr:FlxTimer) { songCharLabels.onClicked(); });
						}
						charHbox.add(_remove);
					}
					scroll.add(charHbox);
				}

				vbox.add(menu);

				var _default:TextButton = new TextButton(0, 0, "Default", Button.LONG);
				_default.onClicked = function() {
					weekData.songs[curSong].characterLabels = ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"];
					weekData.songs[curSong].characters = weekData.songs[curSong].characterLabels.length;
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { songCharLabels.onClicked(); });
				}
				vbox.add(_default);

				var _add:TextButton = new TextButton(0, 0, "Add");
				_add.onClicked = function() {
					weekData.songs[curSong].characterLabels.push(weekData.songs[curSong].characterLabels[weekData.songs[curSong].characterLabels.length-1]);
					weekData.songs[curSong].characters = weekData.songs[curSong].characterLabels.length;
					window.close();
					new FlxTimer().start(0.01, function(tmr:FlxTimer) { songCharLabels.onClicked(); });
				}
				vbox.add(_add);

				var accept:TextButton = new TextButton(0, 0, "Accept", function() { window.close(); });
				vbox.add(accept);

				window = PopupWindow.CreateWithGroup(vbox);
			}
		}

		var songScriptDropdown:DropdownMenu = cast element("songScriptDropdown");
		songScriptDropdown.valueList = allScripts;
		songScriptDropdown.condition = function() {
			if (weekData.songs.length > 0 && weekData.songs[curSong].hscript != null)
				return weekData.songs[curSong].hscript;
			return songScriptDropdown.value;
		}
		songScriptDropdown.onChanged = function() {
			if (weekData.songs.length > 0)
				weekData.songs[curSong].hscript = songScriptDropdown.value;
		}

		var makeAutoFile:Button = cast element("makeAutoFile");
		makeAutoFile.onClicked = function() {
			if (weekData.songs.length > 0)
			{
				var _auto:WeekSongData = {
					songId: weekData.songs[curSong].songId,
					iconNew: weekData.songs[curSong].iconNew,
					difficulties: weekData.songs[curSong].difficulties
				}

				if (weekData.songs[curSong].title != null && weekData.songs[curSong].title.trim() != "")
					_auto.title = weekData.songs[curSong].title;

				if (!DeepEquals.deepEquals(weekData.songs[curSong].characterLabels, ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"]))
				{
					_auto.characters = weekData.songs[curSong].characters;
					_auto.characterLabels = weekData.songs[curSong].characterLabels;
				}

				Reflect.deleteField(_auto, "songId");
				var data:String = Json.stringify(_auto);
				var file:FileBrowser = new FileBrowser();
				file.save("_auto.json", data.trim());
			}
		}

		var makeVariantFile:Button = cast element("makeVariantFile");
		makeVariantFile.onClicked = function() {
			if (weekData.songs.length > 0)
			{
				var window:PopupWindow = null;
				var vbox:VBox = new VBox(35, 35);

				var allowVariantOnBase:Checkbox = new Checkbox(0, 0, "Allow the variant's instrumental to be used on the base song", true);
				vbox.add(allowVariantOnBase);

				var lockedOnBase:Checkbox = new Checkbox(0, 0, "Lock the variant's instrumental from the base song until the variant is beaten", true);
				vbox.add(lockedOnBase);

				var create:TextButton = new TextButton(0, 0, "Create", function() {
					window.close();

					var _variant:WeekSongData = {
						songId: weekData.songs[curSong].songId,
						iconNew: weekData.songs[curSong].iconNew,
						allowVariantOnBase: allowVariantOnBase.checked,
						lockedOnBase: lockedOnBase.checked
					}

					if (!DeepEquals.deepEquals(weekData.songs[curSong].difficulties, weekData.difficulties))
						_variant.difficulties = weekData.songs[curSong].difficulties;

					if (weekData.songs[curSong].albums != null && weekData.songs[curSong].albums.length > 0)
						_variant.albums = weekData.songs[curSong].albums;

					if (weekData.songs[curSong].title != null && weekData.songs[curSong].title.trim() != "")
						_variant.title = weekData.songs[curSong].title;

					if (!DeepEquals.deepEquals(weekData.songs[curSong].characterLabels, ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"]))
					{
						_variant.characters = weekData.songs[curSong].characters;
						_variant.characterLabels = weekData.songs[curSong].characterLabels;
					}

					Reflect.deleteField(_variant, "songId");
					var data:String = Json.stringify(_variant);
					var file:FileBrowser = new FileBrowser();
					file.save("_variant.json", data.trim());
				});
				vbox.add(create);

				window = PopupWindow.CreateWithGroup(vbox);
			}
		}



		var weekName:InputText = cast element("weekName");
		weekName.text = weekData.title;
		weekName.condition = function() { return weekData.title; }
		weekName.focusLost = function() {
			weekData.title = weekName.text;
			weekTitle.text = Lang.get(weekData.title);
		}

		var imageList:Array<String> = Paths.listFilesSub("images/ui/story/weeks/", ".png");
		var weekImageDropdown:DropdownMenu = cast element("weekImageDropdown");
		weekImageDropdown.valueList = imageList;
		weekImageDropdown.value = weekData.image;
		weekImageDropdown.condition = function() { return weekData.image; }
		weekImageDropdown.onChanged = function() {
			weekData.image = weekImageDropdown.value;
			refreshImageButton();
		};

		var bannerList:Array<String> = Paths.listFilesSub("images/ui/story/banners/", ".png");
		bannerList.unshift("");
		if (weekData.banner == null)
			weekData.banner = "";
		var bannerImageDropdown:DropdownMenu = cast element("bannerImageDropdown");
		bannerImageDropdown.valueList = bannerList;
		bannerImageDropdown.value = weekData.banner;
		bannerImageDropdown.condition = function() { return weekData.banner; }
		bannerImageDropdown.onChanged = function() {
			weekData.banner = bannerImageDropdown.value;
			refreshWeekBanner();
		}

		var menuColor:Button = cast element("menuColor");
		menuColor.onClicked = function() {
			new ColorPicker(FlxColor.fromRGB(weekData.color[0], weekData.color[1], weekData.color[2]), function(clr:FlxColor) {
				weekData.color = [clr.red, clr.green, clr.blue];
				refreshWeekBanner();
			});
		}

		var menuColorPicker:Button = cast element("menuColorPicker");
		menuColorPicker.onClicked = function() {
			persistentUpdate = false;
			openSubState(new ColorPickSubstate(function(px:FlxColor) {
				weekData.color = [px.red, px.green, px.blue];
				refreshWeekBanner();
			}));
		}

		var menuColorDefault:TextButton = cast element("menuColorDefault");
		menuColorDefault.onClicked = function() {
			weekData.color = [249, 207, 81];
			refreshWeekBanner();
		}

		var characterList:Array<String> = Paths.listFilesSub("data/story_characters/", ".json");
		characterList.unshift("");

		for (i in 0...3)
		{
			var charDropdown:DropdownMenu = cast element("charDropdown" + Std.string(i));
			charDropdown.valueList = characterList;
			charDropdown.value = weekData.characters[i][0];
			charDropdown.condition = function() { return weekData.characters[i][0]; }
			charDropdown.onChanged = function() {
				weekData.characters[i][0] = charDropdown.value;
				refreshMenuCharacter(i);
			}

			var charOffsetX:Stepper = cast element("charOffsetX" + Std.string(i));
			charOffsetX.value = weekData.characters[i][1];
			charOffsetX.condition = function() { return weekData.characters[i][1]; }
			charOffsetX.onChanged = function() {
				weekData.characters[i][1] = charOffsetX.value;
				refreshMenuCharacter(i);
			}

			var charOffsetY:Stepper = cast element("charOffsetY" + Std.string(i));
			charOffsetY.value = weekData.characters[i][2];
			charOffsetY.condition = function() { return weekData.characters[i][2]; }
			charOffsetY.onChanged = function() {
				weekData.characters[i][2] = charOffsetY.value;
				refreshMenuCharacter(i);
			}
		}

		var scriptDropdown:DropdownMenu = cast element("scriptDropdown");
		scriptDropdown.valueList = allScripts;
		scriptDropdown.value = (weekData.hscript == null ? "" : weekData.hscript);
		scriptDropdown.condition = function() { return (weekData.hscript == null ? "" : weekData.hscript); }
		scriptDropdown.onChanged = function() { weekData.hscript = scriptDropdown.value; }



		var tabOptions:Array<TopMenuOption> = [];
		for (t in tabMenu.tabs)
			tabOptions.push({label: t, action: function() { tabMenu.selectTabByName(t); }, condition: function() { return tabMenu.curTabName == t; }, icon: "bullet"});

		var topmenu:TopMenu;
		topmenu = new TopMenu([
			{
				label: "File",
				options: [
					{
						label: "New",
						action: function() { _confirm("make a new week", _new); },
						shortcut: [FlxKey.CONTROL, FlxKey.N],
						icon: "new"
					},
					{
						label: "Open",
						action: function() { _confirm("load another week", _open); },
						shortcut: [FlxKey.CONTROL, FlxKey.O],
						icon: "open"
					},
					{
						label: "Save",
						action: function() { _save(false); },
						shortcut: [FlxKey.CONTROL, FlxKey.S],
						icon: "save"
					},
					{
						label: "Save As...",
						action: function() { _save(true); },
						shortcut: [FlxKey.CONTROL, FlxKey.SHIFT, FlxKey.S],
						icon: "save"
					},
					null,
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
					}
				]
			},
			{
				label: "View",
				options: [
					{
						label: "Information Panel",
						condition: function() { return members.contains(infoBox); },
						action: function() {
							if (members.contains(infoBox))
								remove(infoBox, true);
							else
								insert(members.indexOf(topmenu), infoBox);
						},
						icon: "bullet"
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

		dataLog = [Cloner.clone(weekData)];
	}

	override public function update(elapsed:Float)
	{
		UIControl.cursor = MouseCursor.ARROW;

		if (!DeepEquals.deepEquals(weekData, dataLog[undoPosition]))
		{
			if (undoPosition < dataLog.length - 1)
				dataLog.resize(undoPosition + 1);
			dataLog.push(Cloner.clone(weekData));
			unsaved = true;
			undoPosition = dataLog.length - 1;
			refreshFilename();
		}

		super.update(elapsed);

		if (FlxG.mouse.justMoved)
		{
			hoveredCapsule = -1;
			if (tabMenu.curTabName != "Story" && !DropdownMenu.isOneActive && !FlxG.mouse.overlaps(tabMenu, camHUD))
			{
				var i:Int = 0;
				grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
					if (FlxG.mouse.overlaps(capsule) && hoveredCapsule == -1)
					{
						hoveredCapsule = i;
						UIControl.cursor = MouseCursor.BUTTON;
					}
					i++;
				});
			}
		}

		if (Options.mouseJustPressed() && hoveredCapsule > -1)
		{
			curSong = hoveredCapsule;
			changeSelection();
		}

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}

	function refreshSongs()
	{
		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) { capsule.kill(); });

		if (weekData.songs.length > 0)
		{
			for (i in 0...weekData.songs.length)
			{
				if (!allSongs.contains(weekData.songs[i].songId))
					weekData.songs[i].songId = allSongs[1];

				var diffs:Array<String> = weekData.songs[i].difficulties;
				var songName:String = "None";
				if (weekData.songs[i].songId != "")
					songName = Song.getSongName(weekData.songs[i].songId, diffs[0], weekData.songs[i].variant);
				if (weekData.songs[i].title != null && weekData.songs[i].title != "")
					songName = Lang.get(weekData.songs[i].title);

				var capsule:FreeplayCapsule = grpCapsules.recycle(FreeplayCapsule);
				capsule.songId = weekData.songs[i].songId;
				capsule.songInfo = weekData.songs[i];
				capsule.icon = weekData.songs[i].iconNew;
				capsule.text = songName;
				capsule.lit = true;
				capsule.weekType = 0;
				capsule.curQuickInfo = null;
				grpCapsules.add(capsule);
			}
		}
		changeSelection();
	}

	function changeSelection(change:Int = 0)
	{
		if (!DropdownMenu.isOneActive)
		{
			var oldCurSong:Int = curSong;

			curSong += change;
			if (curSong < 0)
				curSong = weekData.songs.length - 1;
			if (curSong >= weekData.songs.length)
				curSong = 0;
		}

		var i:Int = -curSong;
		grpCapsules.forEachAlive(function(capsule:FreeplayCapsule) {
			i++;
			capsule.index = i;
		});
	}

	function refreshImageButton()
	{
		imageButton.loadGraphic(Paths.image("ui/story/weeks/" + weekData.image));
		imageButton.screenCenter(X);
	}

	function refreshWeekBanner()
	{
		if (weekData.banner != null && weekData.banner != "")
		{
			banner.loadGraphic(Paths.image("ui/story/banners/" + weekData.banner));
			banner.setGraphicSize(1280);
			banner.updateHitbox();
			banner.visible = true;
			bgYellow.visible = false;
		}
		else
		{
			banner.visible = false;
			bgYellow.visible = true;
		}
		bgYellow.color = FlxColor.fromRGB(weekData.color[0], weekData.color[1], weekData.color[2]);

		menuCharacters.forEachAlive(function(char:StoryMenuCharacter)
		{
			if (char.characterData.matchColor)
				char.color = bgYellow.color;
			else
				char.color = FlxColor.WHITE;
		});
	}

	function refreshMenuCharacters()
	{
		for (i in 0...weekData.characters.length)
			refreshMenuCharacter(i);
	}

	function refreshMenuCharacter(index:Int)
	{
		if (index >= 0 && index < weekData.characters.length && index < menuCharacters.members.length)
		{
			var char:StoryMenuCharacter = menuCharacters.members[index];
			if (weekData.characters[index][0] == "")
				char.visible = false;
			else
			{
				char.visible = true;
				char.setPosition(weekData.characters[index][1], 56 + weekData.characters[index][2]);
				char.refreshCharacter(weekData.characters[index][0]);
				if (char.characterData.matchColor)
					char.color = bgYellow.color;
				else
					char.color = FlxColor.WHITE;
			}
		}
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
			weekData = Cloner.clone(dataLog[undoPosition]);
			postUndoRedo();
		}
	}

	function redo()
	{
		if (undoPosition < dataLog.length - 1)
		{
			undoPosition++;
			if (!unsaved)
			{
				unsaved = true;
				refreshFilename();
			}
			weekData = Cloner.clone(dataLog[undoPosition]);
			postUndoRedo();
		}
	}

	function postUndoRedo()
	{
		refreshSongs();
		refreshImageButton();
		refreshWeekBanner();
		refreshMenuCharacters();
		weekTitle.text = Lang.get(weekData.title);
	}



	function _new()
	{
		FlxG.switchState(new WeekEditorState(true, "", ""));
	}

	function _open()
	{
		var file:FileBrowser = new FileBrowser();
		file.loadCallback = function(fullPath:String)
		{
			var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
			if (jsonNameArray.indexOf("weeks") == -1)
				new Notify("The file you have selected is not a week.");
			else
			{
				while (jsonNameArray[0] != "weeks")
					jsonNameArray.shift();
				jsonNameArray.shift();

				var finalJsonName = jsonNameArray.join("/").split('.json')[0];

				FlxG.switchState(new WeekEditorState(false, finalJsonName, fullPath));
			}
		}
		file.load();
	}

	function _save(?browse:Bool = true)
	{
		var saveData:WeekData = Cloner.clone(weekData);

		if (DeepEquals.deepEquals(saveData.color, [249, 207, 81]))
			Reflect.deleteField(saveData, "color");

		if (saveData.hscript != null && saveData.hscript.trim() == "")
			Reflect.deleteField(saveData, "hscript");

		for (s in saveData.songs)
		{
			if (s.difficulties.length <= 0 || DeepEquals.deepEquals(s.difficulties, saveData.difficulties))
				Reflect.deleteField(s, "difficulties");

			if (s.albums != null && s.albums.length <= 0)
				Reflect.deleteField(s, "albums");

			if (s.variant != null && s.variant == "bf")
				Reflect.deleteField(s, "variant");

			if (s.title != null && s.title.trim() == "")
				Reflect.deleteField(s, "title");

			if (s.hscript != null && s.hscript.trim() == "")
				Reflect.deleteField(s, "hscript");

			if (s.characters == 3)
				Reflect.deleteField(s, "characters");

			if (s.characterLabels.length <= 0)
				Reflect.deleteField(s, "characterLabels");

			if (DeepEquals.deepEquals(s.characterLabels, ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"]))
				Reflect.deleteField(s, "characterLabels");
		}

		if (DeepEquals.deepEquals(saveData.difficulties, ["normal", "hard", "easy"]))
			Reflect.deleteField(saveData, "difficulties");

		if (saveData.difficultiesLocked.length <= 0)
			Reflect.deleteField(saveData, "difficultiesLocked");

		var data:String = Json.stringify(saveData, null, "\t");
		if (Options.options.compactJsons)
			data = Json.stringify(saveData);

		if (data != null && data.length > 0)
		{
			if (browse || filename == "")
			{
				var file:FileBrowser = new FileBrowser();
				file.saveCallback = changeSaveName;
				file.save(id + ".json", data.trim());
			}
			else
			{
				FileBrowser.saveAs(filename, data.trim());
				unsaved = false;
				refreshFilename();
			}
		}
	}
}