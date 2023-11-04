package editors;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import data.ObjectData;
import data.Options;
import data.Song;
import menus.EditorMenuState;
import menus.MainMenuState;
import menus.StoryMenuState;
import objects.Alphabet;
import objects.Character;
import objects.HealthIcon;
import haxe.Json;
import lime.app.Application;

import funkui.TabMenu;
import funkui.DropdownMenu;
import funkui.TextButton;
import funkui.InputText;
import funkui.Stepper;
import funkui.Checkbox;
import funkui.Label;

using StringTools;

class WeekEditorState extends MusicBeatState
{
	public static var newWeek:Bool = false;
	public static var curWeek:String = "";

	var weekData:WeekData;

	public var camFollow:FlxObject;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;

	var settingsStuff:FlxSpriteGroup;
	var storyStuff:FlxSpriteGroup;

	var allSongs:Array<String> = [];
	var allIcons:Array<String> = [];
	var allScripts:Array<String> = [];

	var curSong:Int = 0;
	var songList:FlxTypedSpriteGroup<Alphabet>;
	var songIcons:FlxTypedSpriteGroup<HealthIcon>;

	var weekName:InputText;
	var bgYellow:FlxSprite;
	var banner:FlxSprite;
	var imageButton:FlxSprite;
	var menuCharacters:FlxTypedSpriteGroup<MenuCharacter>;

	var tabMenu:TabMenu;

	var suspendControls:Bool = false;
	var songDropdown:DropdownMenu;
	var iconInput:InputText;
	var iconDropdown:DropdownMenu;
	var songTitle:InputText;
	var songDiffs:InputText;
	var songCharCount:Stepper;
	var songCharLabels:InputText;
	var songScriptDropdown:DropdownMenu;

	override public function create()
	{
		camGame = new FlxCamera();
		FlxG.cameras.add(camGame);

		camFollow = new FlxObject();
		camFollow.screenCenter();
		camGame.follow(camFollow, LOCKON, 1);

		camHUD = new FlxCamera();
		camHUD.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camHUD, false);

		super.create();

		settingsStuff = new FlxSpriteGroup();
		add(settingsStuff);
		storyStuff = new FlxSpriteGroup();
		add(storyStuff);

		var bg:FlxSprite = new FlxSprite(Paths.image('ui/' + MainMenuState.menuImages[2]));
		settingsStuff.add(bg);

		if (newWeek)
		{
			weekData =
			{
				image: TitleState.defaultVariables.storyimage,
				title: "",
				characters: [TitleState.defaultVariables.story1, TitleState.defaultVariables.story2, TitleState.defaultVariables.story3],
				songs: [],
				startsLocked: false,
				weekToUnlock: "",
				hiddenWhenLocked: false
			}
		}
		else
			weekData = StoryMenuState.convertWeek(curWeek, Paths.json("weeks/" + curWeek));

		allSongs = [""];
		for (songFolder in Paths.listFilesSub("songs/", ""))
		{
			if (Paths.exists("songs/" + songFolder + "/Inst.ogg"))
				allSongs.push(songFolder);
		}
		for (songFolder in Paths.listFilesSub("data/songs/", ""))
		{
			if (Paths.exists("data/songs/" + songFolder + "/Inst.ogg"))
				allSongs.push(songFolder);
		}
		allIcons = HealthIcon.listIcons();
		allIcons.unshift("none");

		allScripts = Paths.listFilesSub("data/states/", ".hscript");
		allScripts.unshift("");

		songList = new FlxTypedSpriteGroup<Alphabet>();
		settingsStuff.add(songList);
		songIcons = new FlxTypedSpriteGroup<HealthIcon>();
		settingsStuff.add(songIcons);
		refreshSongs();

		bgYellow = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, FlxColor.WHITE);
		storyStuff.add(bgYellow);

		banner = new FlxSprite(0, 56);
		refreshWeekBanner();
		storyStuff.add(banner);

		weekName = new InputText(10, 10, FlxG.width - 20, "", 32);
		weekName.alignment = RIGHT;
		weekName.callback = function(text:String, action:String) {
			weekData.title = text;
		}
		storyStuff.add(weekName);

		imageButton = new FlxSprite(0, 480);
		refreshImageButton();
		storyStuff.add(imageButton);

		menuCharacters = new FlxTypedSpriteGroup<MenuCharacter>();
		storyStuff.add(menuCharacters);
		for (i in 0...3)
		{
			var char:MenuCharacter = new MenuCharacter(i);
			menuCharacters.add(char);
		}
		refreshMenuCharacters();



		tabMenu = new TabMenu(50, 50, 250, 400, ["Settings", "Songs", "Story"]);
		tabMenu.cameras = [camHUD];
		tabMenu.onTabChanged = function() {
			remove(settingsStuff);
			remove(storyStuff);
			switch (tabMenu.curTab)
			{
				case 2:
					add(storyStuff);
					weekName.text = weekData.title;
					tabMenu.y = 300;

				default: add(settingsStuff); tabMenu.y = 50;
			}
		}
		add(tabMenu);



		var tabGroupSettings = new TabGroup();

		var loadButton:TextButton = new TextButton(10, 10, 115, 20, "Load");
		loadButton.onClicked = loadWeek;
		tabGroupSettings.add(loadButton);

		var saveButton:TextButton = new TextButton(loadButton.x + 115, loadButton.y, 115, 20, "Save");
		saveButton.onClicked = saveWeek;
		tabGroupSettings.add(saveButton);

		if (weekData.condition == null)
			weekData.condition = "";
		var conditionDropdown:DropdownMenu = new DropdownMenu(10, saveButton.y + 40, 230, 20, weekData.condition, ["", "storyOnly", "freePlayOnly"]);
		conditionDropdown.onChanged = function() {
			weekData.condition = conditionDropdown.value;
		};
		tabGroupSettings.add(conditionDropdown);
		var conditionLabel:Label = new Label("Condition:", conditionDropdown);
		tabGroupSettings.add(conditionLabel);

		var diffs:InputText = new InputText(10, conditionDropdown.y + 40);
		diffs.forceCase = 2;
		diffs.customFilterPattern = ~/[^a-zA-Z,]*/g;
		diffs.focusGained = function() {
			suspendControls = true;
			if (weekData.difficulties != null && weekData.difficulties.length > 0)
				diffs.text = weekData.difficulties.join(",");
			else
				diffs.text = "";
		}
		diffs.focusLost = function() { suspendControls = false; }
		diffs.callback = function(text:String, action:String) {
			if (text == "")
				weekData.difficulties = null;
			else
				weekData.difficulties = text.split(",");
		}
		tabGroupSettings.add(diffs);
		var diffsLabel:Label = new Label("Difficulties (Optional):", diffs);
		tabGroupSettings.add(diffsLabel);

		var startsLockedCheck:Checkbox = new Checkbox(10, diffs.y + 30, "Starts Locked");
		startsLockedCheck.checked = weekData.startsLocked;
		startsLockedCheck.onClicked = function() {
			weekData.startsLocked = startsLockedCheck.checked;
		}
		tabGroupSettings.add(startsLockedCheck);

		if (weekData.weekToUnlock == null)
			weekData.weekToUnlock = "";
		var weekList:Array<String> = Paths.listFilesSub("data/weeks/", ".json");
		weekList.unshift("");
		var weekToUnlockDropdown:DropdownMenu = new DropdownMenu(10, startsLockedCheck.y + 40, 230, 20, weekData.weekToUnlock, weekList, true);
		weekToUnlockDropdown.onChanged = function() {
			weekData.weekToUnlock = weekToUnlockDropdown.value;
		};
		tabGroupSettings.add(weekToUnlockDropdown);
		var weekToUnlockLabel:Label = new Label("Week to Unlock (Optional):", weekToUnlockDropdown);
		tabGroupSettings.add(weekToUnlockLabel);

		var hiddenWhenLockedCheck:Checkbox = new Checkbox(10, weekToUnlockDropdown.y + 30, "Hidden When Locked");
		hiddenWhenLockedCheck.checked = weekData.hiddenWhenLocked;
		hiddenWhenLockedCheck.onClicked = function() {
			weekData.hiddenWhenLocked = hiddenWhenLockedCheck.checked;
		}
		tabGroupSettings.add(hiddenWhenLockedCheck);

		tabMenu.addGroup(tabGroupSettings);



		var tabGroupSong = new TabGroup();

		var addSong:TextButton = new TextButton(10, 20, 75, 20, "Add");
		addSong.onClicked = function() {
			if (weekData.songs.length > 0)
				weekData.songs.push({songId: weekData.songs[curSong].songId, icon: weekData.songs[curSong].icon, characters: 3, characterLabels: ["#fpSandboxCharacter0", "#fpSandboxCharacter1", "#fpSandboxCharacter2"]});
			else
				weekData.songs.push({songId: songDropdown.value, icon: iconInput.text, characters: 3, characterLabels: ["#fpSandboxCharacter0", "#fpSandboxCharacter1", "#fpSandboxCharacter2"]});
			curSong = weekData.songs.length - 1;
			refreshSongs();
		}
		tabGroupSong.add(addSong);
		var insertSong:TextButton = new TextButton(addSong.x + 75, addSong.y, 75, 20, "Insert");
		insertSong.onClicked = function() {
			if (weekData.songs.length > 0)
			{
				var newSong:WeekSongData = {songId: weekData.songs[curSong].songId, icon: weekData.songs[curSong].icon, characters: 3, characterLabels: ["#fpSandboxCharacter0", "#fpSandboxCharacter1", "#fpSandboxCharacter2"]};
				weekData.songs.insert(curSong, newSong);
				refreshSongs();
			}
		}
		tabGroupSong.add(insertSong);
		var removeSong:TextButton = new TextButton(insertSong.x + 75, insertSong.y, 75, 20, "Remove");
		removeSong.onClicked = function() {
			if (weekData.songs.length > 0)
			{
				weekData.songs.splice(curSong, 1);
				if (curSong > 0)
					curSong--;
				refreshSongs();
			}
		}
		tabGroupSong.add(removeSong);
		var insertAndRemoveLabel:Label = new Label("Song:", addSong);
		tabGroupSong.add(insertAndRemoveLabel);

		var moveUp:TextButton = new TextButton(10, removeSong.y + 40, 115, 20, "Move Up");
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
		tabGroupSong.add(moveUp);
		var moveDown:TextButton = new TextButton(moveUp.x + 115, moveUp.y, 115, 20, "Move Down");
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
		tabGroupSong.add(moveDown);
		var reorderLabel:Label = new Label("Song Order:", moveUp);
		tabGroupSong.add(reorderLabel);
		

		songDropdown = new DropdownMenu(10, moveDown.y + 40, 230, 20, allSongs[1], allSongs, true);
		songDropdown.onChanged = function() {
			if (weekData.songs.length > 0)
			{
				weekData.songs[curSong].songId = songDropdown.value;
				var songData:SongData = Song.loadSong(songDropdown.value, (weekData.songs[curSong].difficulties == null ? "normal" : weekData.songs[curSong].difficulties[0]), false);
				if (Paths.jsonExists("characters/" + songData.player2))
				{
					var iconName:String = Character.parseCharacter(songData.player2).icon;
					if (iconName == null || iconName == "")
					{
						iconName = songData.player2;
						if (!Paths.iconExists(iconName) && Paths.iconExists(iconName.split("-")[0]))
							iconName = iconName.split("-")[0];
					}
					if (Paths.iconExists(iconName))
					{
						weekData.songs[curSong].icon = iconName;
						iconInput.text = iconName;
					}
				}
				refreshSongs();
			}
		}
		tabGroupSong.add(songDropdown);
		var songLabel:Label = new Label("Song ID:", songDropdown);
		tabGroupSong.add(songLabel);

		iconInput = new InputText(10, songDropdown.y + 40, 230);
		iconInput.focusGained = function() {
			suspendControls = true;
			if (weekData.songs.length > 0)
			{
				if (weekData.songs[curSong].icon != null)
					iconInput.text = weekData.songs[curSong].icon;
				else
					iconInput.text = "";
			}
		}
		iconInput.focusLost = function() { suspendControls = false; refreshSongs(); }
		iconInput.callback = function(text:String, action:String) {
			if (weekData.songs.length > 0)
			{
				if (text.trim() != "" && Paths.iconExists(text))
					weekData.songs[curSong].icon = text;
				else
					weekData.songs[curSong].icon = allIcons[0];
			}
		}
		tabGroupSong.add(iconInput);
		iconDropdown = new DropdownMenu(10, iconInput.y + 30, 230, 20, allIcons[0], allIcons, true);
		iconDropdown.onChanged = function() {
			if (weekData.songs.length > 0)
			{
				iconInput.text = iconDropdown.value;
				iconInput.callback(iconInput.text, "");
				iconInput.focusLost();
			}
		}
		tabGroupSong.add(iconDropdown);
		var iconLabel:Label = new Label("Icon:", iconInput);
		tabGroupSong.add(iconLabel);

		songTitle = new InputText(10, iconDropdown.y + 40, 230);
		songTitle.focusGained = function() {
			suspendControls = true;
			if (weekData.songs.length > 0)
			{
				if (weekData.songs[curSong].title != null)
					songTitle.text = weekData.songs[curSong].title;
				else
					songTitle.text = "";
			}
		}
		songTitle.focusLost = function() { suspendControls = false; refreshSongs(); }
		songTitle.callback = function(text:String, action:String) {
			if (weekData.songs.length > 0)
			{
				if (text.trim() != "")
					weekData.songs[curSong].title = text;
				else if (Reflect.hasField(weekData.songs[curSong], "title"))
					Reflect.deleteField(weekData.songs[curSong], "title");
			}
		}
		tabGroupSong.add(songTitle);
		var songTitleLabel:Label = new Label("Title (Optional):", songTitle);
		tabGroupSong.add(songTitleLabel);

		songDiffs = new InputText(10, songTitle.y + 40, 230);
		songDiffs.forceCase = 2;
		songDiffs.customFilterPattern = ~/[^a-zA-Z,]*/g;
		songDiffs.focusGained = function() {
			suspendControls = true;
			if (weekData.songs.length > 0)
			{
				if (weekData.songs[curSong].difficulties != null && weekData.songs[curSong].difficulties.length > 0)
					songDiffs.text = weekData.songs[curSong].difficulties.join(",");
				else
					songDiffs.text = "";
			}
		}
		songDiffs.focusLost = function() { suspendControls = false; }
		songDiffs.callback = function(text:String, action:String) {
			if (weekData.songs.length > 0)
			{
				if (text != "")
					weekData.songs[curSong].difficulties = text.split(",");
				else if (Reflect.hasField(weekData.songs[curSong], "difficulties"))
					Reflect.deleteField(weekData.songs[curSong], "difficulties");
			}
		}
		tabGroupSong.add(songDiffs);
		var songDiffsLabel:Label = new Label("Difficulties (Optional):", songDiffs);
		tabGroupSong.add(songDiffsLabel);

		songCharCount = new Stepper(10, songDiffs.y + 40, 230, 20, 3, 1, 3);
		songCharCount.onChanged = function() {
			if (weekData.songs.length > 0)
				weekData.songs[curSong].characters = Std.int(songCharCount.value);
		}
		tabGroupSong.add(songCharCount);
		var songCharCountLabel:Label = new Label("Character Count:", songCharCount);
		tabGroupSong.add(songCharCountLabel);

		songCharLabels = new InputText(10, songCharCount.y + 40, 230);
		songCharLabels.focusGained = function() {
			suspendControls = true;
			if (weekData.songs.length > 0)
			{
				if (weekData.songs[curSong].characterLabels != null && weekData.songs[curSong].characterLabels.length > 0)
				{
					var cLabels:Array<String> = weekData.songs[curSong].characterLabels;
					if (cLabels.length == 3 && cLabels[0] == "#fpSandboxCharacter0" && cLabels[1] == "#fpSandboxCharacter1" && cLabels[2] == "#fpSandboxCharacter2")
						songCharLabels.text = "";
					else
						songCharLabels.text = weekData.songs[curSong].characterLabels.join(",");
				}
				else
					songCharLabels.text = "";
			}
		}
		songCharLabels.focusLost = function() { suspendControls = false; }
		songCharLabels.callback = function(text:String, action:String) {
			if (weekData.songs.length > 0)
			{
				if (text == "")
					weekData.songs[curSong].characterLabels = ["#fpSandboxCharacter0", "#fpSandboxCharacter1", "#fpSandboxCharacter2"];
				else
					weekData.songs[curSong].characterLabels = text.split(",");
			}
		}
		tabGroupSong.add(songCharLabels);
		var songCharLabelsLabel:Label = new Label("Character Labels:", songCharLabels);
		tabGroupSong.add(songCharLabelsLabel);

		songScriptDropdown = new DropdownMenu(10, songCharLabels.y + 40, 230, 20, "", allScripts, true);
		songScriptDropdown.onChanged = function() {
			if (songScriptDropdown.value != "")
				weekData.songs[curSong].hscript = songScriptDropdown.value;
			else if (Reflect.hasField(weekData.songs[curSong], "hscript"))
				Reflect.deleteField(weekData.songs[curSong], "hscript");
		};
		tabGroupSong.add(songScriptDropdown);
		var scriptLabel:Label = new Label("Custom State (Optional):", songScriptDropdown);
		tabGroupSong.add(scriptLabel);

		refreshSongTab(false);
		tabMenu.addGroup(tabGroupSong);



		var tabGroupStory = new TabGroup();

		var imageList:Array<String> = Paths.listFilesSub("images/ui/weeks/", ".png");
		var weekImageDropdown:DropdownMenu = new DropdownMenu(10, 20, 230, 20, weekData.image, imageList, true);
		weekImageDropdown.onChanged = function() {
			weekData.image = weekImageDropdown.value;
			refreshImageButton();
		};
		tabGroupStory.add(weekImageDropdown);
		var weekImageLabel:Label = new Label("Week Button Image:", weekImageDropdown);
		tabGroupStory.add(weekImageLabel);

		var bannerList:Array<String> = Paths.listFilesSub("images/ui/story_banners/", ".png");
		bannerList.unshift("");
		if (weekData.banner == null)
			weekData.banner = "";
		var bannerImageDropdown:DropdownMenu = new DropdownMenu(10, weekImageDropdown.y + 40, 230, 20, weekData.banner, bannerList, true);
		bannerImageDropdown.onChanged = function() {
			weekData.banner = bannerImageDropdown.value;
			refreshWeekBanner();
		};
		tabGroupStory.add(bannerImageDropdown);
		var bannerImageLabel:Label = new Label("Week Banner (Optional):", bannerImageDropdown);
		tabGroupStory.add(bannerImageLabel);

		var color:Array<Int> = weekData.color;
		if (weekData.color == null)
			color = [249, 207, 81];
		var menuColorR:Stepper = new Stepper(10, bannerImageDropdown.y + 40, 75, 20, color[0], 1, 0, 255);
		tabGroupStory.add(menuColorR);
		var menuColorG:Stepper = new Stepper(menuColorR.x + 75, menuColorR.y, 75, 20, color[1], 1, 0, 255);
		tabGroupStory.add(menuColorG);
		var menuColorB:Stepper = new Stepper(menuColorG.x + 75, menuColorG.y, 75, 20, color[2], 1, 0, 255);
		tabGroupStory.add(menuColorB);
		var menuColorLabel:Label = new Label("Week Background Color:", menuColorR);
		tabGroupStory.add(menuColorLabel);

		menuColorR.onChanged = function() {
			if (menuColorR.value == 249 && menuColorG.value == 207 && menuColorB.value == 81)
			{
				if (Reflect.hasField(weekData, "color"))
					Reflect.deleteField(weekData, "color");
				bgYellow.color = 0xFFF9CF51;
			}
			else
			{
				weekData.color = [Std.int(menuColorR.value), Std.int(menuColorG.value), Std.int(menuColorB.value)];
				bgYellow.color = FlxColor.fromRGB(weekData.color[0], weekData.color[1], weekData.color[2]);
			}
		}
		menuColorG.onChanged = menuColorR.onChanged;
		menuColorB.onChanged = menuColorR.onChanged;
		menuColorR.onChanged();

		var characterList:Array<String> = Paths.listFilesSub("data/story_characters/", ".json");
		characterList.unshift("");
		var charLeftDropdown:DropdownMenu = new DropdownMenu(10, menuColorR.y + 40, 230, 20, weekData.characters[0], characterList, true);
		charLeftDropdown.onChanged = function() {
			weekData.characters[0] = charLeftDropdown.value;
			refreshMenuCharacters();
		};
		tabGroupStory.add(charLeftDropdown);
		var charLeftLabel:Label = new Label("Left Character:", charLeftDropdown);
		tabGroupStory.add(charLeftLabel);

		var charCenterDropdown:DropdownMenu = new DropdownMenu(10, charLeftDropdown.y + 40, 230, 20, weekData.characters[1], characterList, true);
		charCenterDropdown.onChanged = function() {
			weekData.characters[1] = charCenterDropdown.value;
			refreshMenuCharacters();
		};
		tabGroupStory.add(charCenterDropdown);
		var charCenterLabel:Label = new Label("Center Character:", charCenterDropdown);
		tabGroupStory.add(charCenterLabel);

		var charRightDropdown:DropdownMenu = new DropdownMenu(10, charCenterDropdown.y + 40, 230, 20, weekData.characters[2], characterList, true);
		charRightDropdown.onChanged = function() {
			weekData.characters[2] = charRightDropdown.value;
			refreshMenuCharacters();
		};
		tabGroupStory.add(charRightDropdown);
		var charRightLabel:Label = new Label("Right Character:", charRightDropdown);
		tabGroupStory.add(charRightLabel);

		var scriptDropdown:DropdownMenu = new DropdownMenu(10, charRightDropdown.y + 40, 230, 20, (weekData.hscript == null ? "" : weekData.hscript), allScripts, true);
		scriptDropdown.onChanged = function() {
			if (scriptDropdown.value != "")
				weekData.hscript = scriptDropdown.value;
			else if (Reflect.hasField(weekData, "hscript"))
				Reflect.deleteField(weekData, "hscript");
		};
		tabGroupStory.add(scriptDropdown);
		var scriptLabel:Label = new Label("Custom State (Optional):", scriptDropdown);
		tabGroupStory.add(scriptLabel);

		tabMenu.addGroup(tabGroupStory);
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
			saveWeek();

		super.update(elapsed);

		if (tabMenu.curTab < 2 && weekData.songs.length > 0)
		{
			songList.x = FlxMath.lerp(songList.x, curSong * -20, 0.16 * elapsed * 60);
			songList.y = FlxMath.lerp(songList.y, curSong * 1.3 * -120, 0.16 * elapsed * 60);
			songIcons.setPosition(songList.x, songList.y);

			if (!suspendControls)
			{
				if (FlxG.mouse.wheel != 0)
					changeSelection(-FlxG.mouse.wheel);

				if (Options.keyJustPressed("ui_up"))
					changeSelection(-1);

				if (Options.keyJustPressed("ui_down"))
					changeSelection(1);
			}
		}

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new EditorMenuState());
	}

	function refreshSongs()
	{
		songList.forEachAlive(function(txt:Alphabet)
		{
			txt.kill();
			txt.destroy();
		});
		songList.clear();

		songIcons.forEachAlive(function(icon:HealthIcon)
		{
			icon.kill();
			icon.destroy();
		});
		songIcons.clear();

		if (weekData.songs.length > 0)
		{
			for (i in 0...weekData.songs.length)
			{
				if (!allSongs.contains(weekData.songs[i].songId))
					weekData.songs[i].songId = allSongs[1];
				if (!Paths.iconExists(weekData.songs[i].icon))
					weekData.songs[i].icon = allIcons[0];
				if (Paths.iconExists(weekData.songs[i].icon) && !allIcons.contains(weekData.songs[i].icon) && weekData.songs[i].icon.indexOf("/") > 0)
				{
					for (h in HealthIcon.listIcons(weekData.songs[i].icon.substring(0, weekData.songs[i].icon.indexOf("/")+1)))
						allIcons.push(weekData.songs[i].icon.substring(0, weekData.songs[i].icon.indexOf("/")+1) + h);
					if (iconDropdown != null)
						iconDropdown.valueList = allIcons.copy();
				}

				var diffs:Array<String> = (weekData.songs[i].difficulties == null || weekData.songs[i].difficulties.length < 1 ? ["normal"] : weekData.songs[i].difficulties);
				var songName:String = "None";
				if (weekData.songs[i].songId != "")
					songName = Song.getSongName(weekData.songs[i].songId, diffs[0]);
				if (weekData.songs[i].title != null && weekData.songs[i].title != "")
					songName = Lang.get(weekData.songs[i].title);
				var textButton:Alphabet = new Alphabet(Std.int((i * 20) + 340), Std.int((i * 1.3 * 120) + (FlxG.height * 0.48)), songName, "bold", Std.int(FlxG.width * 0.9) - 250);
				songList.add(textButton);

				var icon:HealthIcon = new HealthIcon(Std.int(textButton.x - songList.x + textButton.width + 85), Std.int(textButton.y - songList.y + 45), weekData.songs[i].icon);
				icon.x -= icon.width / 2;
				icon.y -= icon.height / 2;
				songIcons.add(icon);
			}
		}
		changeSelection();
	}

	function changeSelection(change:Int = 0)
	{
		if (DropdownMenu.isOneActive)
			return;

		var oldCurSong:Int = curSong;

		curSong += change;
		if (curSong < 0)
			curSong = weekData.songs.length - 1;
		if (curSong >= weekData.songs.length)
			curSong = 0;

		if (oldCurSong != curSong)
			FlxG.sound.play(Paths.sound("ui/scrollMenu"));

		var i:Int = 0;
		songList.forEachAlive(function(button:Alphabet)
		{
			if (i == curSong)
				button.alpha = 1;
			else
				button.alpha = 0.6;
			i++;
		});

		i = 0;
		songIcons.forEachAlive(function(icon:HealthIcon)
		{
			if (i == curSong)
				icon.alpha = 1;
			else
				icon.alpha = 0.6;
			i++;
		});

		if (oldCurSong != curSong)
			refreshSongTab();
	}

	function refreshSongTab(?fillInputText:Bool = true)
	{
		if (weekData.songs.length > 0)
		{
			songDropdown.value = weekData.songs[curSong].songId;
			if (fillInputText)
			{
				iconInput.focusGained();
				songTitle.focusGained();
				songDiffs.focusGained();
				songCharLabels.focusGained();
				suspendControls = false;
			}
			songCharCount.value = weekData.songs[curSong].characters;
			songScriptDropdown.value = (weekData.songs[curSong].hscript == null ? "" : weekData.songs[curSong].hscript);
		}
	}

	function refreshImageButton()
	{
		imageButton.loadGraphic(Paths.image("ui/weeks/" + weekData.image));
		imageButton.screenCenter(X);
	}

	function refreshWeekBanner()
	{
		if (weekData.banner != null && weekData.banner != "")
		{
			banner.loadGraphic(Paths.image("ui/story_banners/" + weekData.banner));
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
	}

	function refreshMenuCharacters()
	{
		for (i in 0...weekData.characters.length)
		{
			if (weekData.characters[i] == "")
				menuCharacters.members[i].visible = false;
			else
			{
				menuCharacters.members[i].visible = true;
				menuCharacters.members[i].refreshCharacter(weekData.characters[i]);
			}
		}
	}



	function saveWeek()
	{
		var saveData:WeekData = Reflect.copy(weekData);
		saveData.songs = [];
		for (s in weekData.songs)
			saveData.songs.push(Reflect.copy(s));

		for (s in saveData.songs)
		{
			if (s.characters == 3)
				Reflect.deleteField(s, "characters");

			if (s.characterLabels.length <= 0)
				Reflect.deleteField(s, "characterLabels");

			if (s.characterLabels.length == 3 && s.characterLabels[0] == "#fpSandboxCharacter0" && s.characterLabels[1] == "#fpSandboxCharacter1" && s.characterLabels[2] == "#fpSandboxCharacter2")
				Reflect.deleteField(s, "characterLabels");
		}

		var data:String = Json.stringify(saveData, null, "\t");
		if (Options.options.compactJsons)
			data = Json.stringify(saveData);

		if ((data != null) && (data.length > 0))
		{
			var file:FileBrowser = new FileBrowser();
			file.save(curWeek + ".json", data.trim());
		}
	}

	function loadWeek()
	{
		var file:FileBrowser = new FileBrowser();
		file.loadCallback = EditorMenuState.loadWeekCallback;
		file.load();
	}
}