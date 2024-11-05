package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;

import lime.app.Application;

import data.Options;
import editors.CharacterEditorState;
import editors.ChartEditorState;
import editors.StageEditorState;
import editors.StoryCharacterEditorState;
import editors.WeekEditorState;
import menus.UINavigation;
import game.PlayState;
import scripting.HscriptState;

import newui.UIControl;
import newui.PopupWindow;
import newui.Checkbox;
import newui.DropdownMenu;
import newui.InputText;
import newui.Label;
import newui.Button;

using StringTools;

class EditorMenuState extends MusicBeatState
{
	var menuButtons:Array<FlxText> = [];
	#if ALLOW_MODS
	var menuButtonText:Array<String> = ["Create New Mod", "Create New Package", "Restructure Engine Wiki", "Chart Editor", "Character Editor", "Stage Editor", "Week Editor", "Story Character Editor"];
	#else
	var menuButtonText:Array<String> = ["Restructure Engine Wiki", "Chart Editor", "Character Editor", "Stage Editor", "Week Editor", "Story Character Editor"];
	#end
	var customEditors:Array<String> = [];
	var curButton(default, set):Int = 0;

	var nav:UINumeralNavigation;

	override public function create()
	{
		super.create();

		Main.fpsOnRight = false;
		Application.current.window.title = Main.windowTitle;

		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music("editors/" + Options.options.editorMusic), 0.4);

		var bg:FlxSprite = new FlxSprite(Paths.image('ui/' + MainMenuState.menuImages[6]));
		bg.color = MainMenuState.menuColors[6];
		add(bg);

		if (Paths.textExists("editors"))
			customEditors = Paths.text("editors").replace("\r","").split("\n");
		if (customEditors.contains(null))
			customEditors = [];

		for (e in customEditors)
			menuButtonText.push(e.split("|")[1]);

		var yStart:Int = Std.int((FlxG.height - (menuButtonText.length * 40)) / 2);
		for (i in 0...menuButtonText.length)
		{
			var textButton:FlxText = new FlxText(0, yStart + (i * 40), 0, Lang.get(menuButtonText[i]));
			textButton.setFormat("FNF Dialogue", 36, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			textButton.borderSize = 2;
			textButton.screenCenter(X);
			add(textButton);
			menuButtons.push(textButton);
		}

		nav = new UINumeralNavigation(null, scrollCurButton, function() {
			switch (menuButtonText[curButton].toLowerCase())
			{
				case "create new mod": createNewMod();
				case "create new package": createNewPackage();
				case "restructure engine wiki": FlxG.openURL("https://github.com/SlightlySimple/FNF-Restructure-Engine/wiki");
				case "chart editor": prepareChartEditor();
				case "character editor": prepareCharacterEditor();
				case "stage editor": prepareStageEditor();
				case "week editor": prepareWeekEditor();
				case "story character editor": prepareStoryCharacterEditor();
				default:
					for (e in customEditors)
					{
						if (e.split("|")[1].toLowerCase() == menuButtonText[curButton].toLowerCase())
							FlxG.switchState(new HscriptEditorState(true, "", "", "data/editors/" + e.split("|")[0]));
					}
			}
		}, function() {
			FlxG.mouse.visible = false;
			FlxG.sound.music.fadeOut(0.5, 0, function(twn) { FlxG.sound.music.stop(); });
			FlxG.switchState(new MainMenuState());
		}, scrollCurButton);
		nav.leftClick = nav.accept;
		nav.rightClick = nav.back;
		nav.uiSounds = [false, false, false];
		add(nav);

		FlxG.mouse.visible = true;
	}

	override public function update(elapsed:Float)
	{
		UIControl.cursor = MouseCursor.ARROW;
		if (!nav.locked)
		{
			if (FlxG.mouse.justMoved)
			{
				for (i in 0...menuButtons.length)
				{
					if (FlxG.mouse.overlaps(menuButtons[i]))
					{
						curButton = i;
						UIControl.cursor = MouseCursor.BUTTON;
					}
				}
			}
		}

		super.update(elapsed);

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}

	function set_curButton(val:Int):Int
	{
		for (i in 0...menuButtons.length)
		{
			if (i == val)
			{
				if (menuButtons[i].text == menuButtonText[i])
				{
					menuButtons[i].text = "> " + Lang.get(menuButtonText[i]) + " <";
					menuButtons[i].screenCenter(X);
				}
			}
			else if (menuButtons[i].text != menuButtonText[i])
			{
				menuButtons[i].text = Lang.get(menuButtonText[i]);
				menuButtons[i].screenCenter(X);
			}
		}
		return curButton = val;
	}

	function scrollCurButton(?val:Int = 0)
	{
		curButton = Util.loop(curButton + val, 0, menuButtonText.length - 1);
	}

	function createNewMod()
	{
		var validChars:Array<String> = [];

		for (c in "a".code..."z".code+1)
			validChars.push(String.fromCharCode(c));

		for (c in "A".code..."Z".code+1)
			validChars.push(String.fromCharCode(c));

		for (c in "0".code..."9".code+1)
			validChars.push(String.fromCharCode(c));
		validChars.push("-");
		validChars.push("_");



		var window:PopupWindow = null;
		var vbox:VBox = new VBox(35, 35);

		var modNameInput:InputText = new InputText(0, 0);
		vbox.add(new Label("Mod Name:"));
		vbox.add(modNameInput);

		var modDescInput:InputText = new InputText(0, 0);
		vbox.add(new Label("Mod Description:"));
		vbox.add(modDescInput);

		var createDirs:DropdownMenu = new DropdownMenu(0, 0, "Simplified", ["None", "Simplified", "Extended"]);
		vbox.add(new Label("Create Asset Folders:"));
		vbox.add(createDirs);

		var subDirInput:InputText = new InputText(0, 0);
		vbox.add(new Label("Asset Subfolder:"));
		vbox.add(subDirInput);

		var buttons:HBox = new HBox();

		var newModButton:TextButton = new TextButton(0, 0, "Create");
		newModButton.onClicked = function()
		{
			if (modNameInput.text.trim() != "")
			{
				var modFolderNameArray:Array<String> = modNameInput.text.replace("-", " ").replace(".", " ").replace("'", " ").replace("\"", " ").split(" ");
				modFolderNameArray[0] = modFolderNameArray[0].toLowerCase();
				var tempModFolderName:String = modFolderNameArray.join("");
				var modFolderName:String = "";
				for (i in 0...tempModFolderName.length)
				{
					if (validChars.contains(tempModFolderName.charAt(i)))
						modFolderName += tempModFolderName.charAt(i);
				}
				if (FileSystem.exists("mods/" + modFolderName))
					Application.current.window.alert("The mod you are trying to create already exists. Please choose a different name.", "Alert");
				else
				{
					var dirs:Array<String> = [""];
					if (createDirs.valueInt > 0)
					{
						var subdir:String = "";
						if (subDirInput.text.trim() != "")
							subdir = "/" + subDirInput.text.replace(" ","-");
						dirs.push("/data");
						dirs.push("/data/characters");
						if (!dirs.contains("/data/characters"+subdir))
							dirs.push("/data/characters"+subdir);
						dirs.push("/data/songs"+subdir);
						if (!dirs.contains("/data/songs"+subdir))
							dirs.push("/data/songs"+subdir);
						dirs.push("/data/stages"+subdir);
						if (!dirs.contains("/data/stages"+subdir))
							dirs.push("/data/stages"+subdir);
						dirs.push("/data/weeks"+subdir);
						if (!dirs.contains("/data/weeks"+subdir))
							dirs.push("/data/weeks"+subdir);
						dirs.push("/images");
						if (!dirs.contains("/images"+subdir))
							dirs.push("/images"+subdir);
						dirs.push("/images"+subdir+"/characters");
						dirs.push("/images"+subdir+"/icons");
						dirs.push("/images"+subdir+"/stages");
						dirs.push("/images/ui");
						dirs.push("/images/ui/story");
						dirs.push("/images/ui/story/weeks");
						if (!dirs.contains("/images/ui/story/weeks"+subdir))
							dirs.push("/images/ui/story/weeks"+subdir);
						dirs.push("/images/ui/freeplay");
						dirs.push("/images/ui/freeplay/icons");
						if (!dirs.contains("/images/ui/freeplay/icons"+subdir))
							dirs.push("/images/ui/freeplay/icons"+subdir);
						if (createDirs.valueInt == 2)
						{
							dirs.push("/data/autorun");
							dirs.push("/data/events");
							dirs.push("/data/lang");
							dirs.push("/data/notetypes");
							dirs.push("/data/scripts");
							dirs.push("/data/story_characters");
							dirs.push("/images/ui/story/difficulties");
							dirs.push("/images/ui/story/characters");
							dirs.push("/images/ui/freeplay/difficulties");
							dirs.push("/songs");
							if (!dirs.contains("/songs"+subdir))
								dirs.push("/songs"+subdir);
						}
					}

					for (d in dirs)
						FileSystem.createDirectory("mods/" + modFolderName + d);

					var modMeta:Dynamic = {
						title: modNameInput.text,
						description: modDescInput.text,
						contributors: [{name: "", role: ""}],
						api_version: "0.1.0",
						mod_version: "1.0.0",
						license: "CC BY 4.0,MIT"
					};
					var modMetaString:String = Json.stringify(modMeta, null, "\t");
					File.saveContent("mods/" + modFolderName + "/_polymod_meta.json", modMetaString);

					window.close();
				}
			}
		}
		buttons.add(newModButton);

		var cancelButton:TextButton = new TextButton(0, 0, "Cancel");
		cancelButton.onClicked = function() { window.close(); }
		buttons.add(cancelButton);

		vbox.add(buttons);

		window = new PopupWindow("popupBG", 30, Std.int(vbox.width + 70), Std.int(vbox.height + 70));
		window.group.add(vbox);
	}

	function createNewPackage()
	{
		var validChars:Array<String> = [];

		for (c in "a".code..."z".code+1)
			validChars.push(String.fromCharCode(c));

		for (c in "A".code..."Z".code+1)
			validChars.push(String.fromCharCode(c));

		for (c in "0".code..."9".code+1)
			validChars.push(String.fromCharCode(c));
		validChars.push("-");
		validChars.push("_");



		var window:PopupWindow = null;
		var vbox:VBox = new VBox(35, 35);

		var packageNameInput:InputText = new InputText(0, 0);
		vbox.add(new Label("Package Name:"));
		vbox.add(packageNameInput);

		var packageDescInput:InputText = new InputText(0, 0);
		vbox.add(new Label("Package Description:"));
		vbox.add(packageDescInput);

		var packageWindowTitleInput:InputText = new InputText(0, 0);
		vbox.add(new Label("Window Title:"));
		vbox.add(packageWindowTitleInput);

		var packageModsInput:InputText = new InputText(0, 0);
		vbox.add(new Label("Package Mods:"));
		vbox.add(packageModsInput);

		var modList:Array<String> = [];
		for (file in FileSystem.readDirectory("mods"))
		{
			if (FileSystem.exists("mods/" + file + "/_polymod_meta.json"))
				modList.push(file);
		}
		var packageModsDropdown:DropdownMenu = new DropdownMenu(0, 0, modList[0], modList, true);
		packageModsDropdown.onChanged = function() {
			if (packageModsInput.text.trim() == "")
				packageModsInput.text = packageModsDropdown.value;
			else
				packageModsInput.text += "," + packageModsDropdown.value;
		}
		vbox.add(packageModsDropdown);

		var packageIncludeBase:Checkbox = new Checkbox(0, 0, "Include Base Game", false);
		vbox.add(packageIncludeBase);

		var packageAllowModTools:Checkbox = new Checkbox(0, 0, "Allow Access to Editors Menu", false);
		vbox.add(packageAllowModTools);

		var packageCreateMenuMod:Checkbox = new Checkbox(0, 0, "Create Menu Mod", false);
		vbox.add(packageCreateMenuMod);

		var buttons:HBox = new HBox();

		var newModButton:TextButton = new TextButton(0, 0, "Create");
		newModButton.onClicked = function()
		{
			if (packageNameInput.text.trim() != "")
			{
				var packageFolderNameArray:Array<String> = packageNameInput.text.replace("-", " ").replace(".", " ").replace("'", " ").replace("\"", " ").split(" ");
				packageFolderNameArray[0] = packageFolderNameArray[0].toLowerCase();
				var tempPackageFolderName:String = packageFolderNameArray.join("");
				var packageFolderName:String = "";
				for (i in 0...tempPackageFolderName.length)
				{
					if (validChars.contains(tempPackageFolderName.charAt(i)))
						packageFolderName += tempPackageFolderName.charAt(i);
				}
				if (FileSystem.exists("packages/" + packageFolderName))
					Application.current.window.alert("The package you are trying to create already exists. Please choose a different name.", "Alert");
				else
				{
					if (!FileSystem.exists("packages"))
						FileSystem.createDirectory("packages");
					FileSystem.createDirectory("packages/" + packageFolderName);

					var packageData:Dynamic = {
						name: packageNameInput.text,
						mods: packageModsInput.text.split(",")
					};
					if (packageDescInput.text.trim() != "")
						packageData.description = packageDescInput.text;
					if (packageWindowTitleInput.text.trim() != "")
						packageData.windowName = packageWindowTitleInput.text;
					if (!packageIncludeBase.checked)
						packageData.excludeBase = true;
					if (packageAllowModTools.checked)
						packageData.allowModTools = true;

					if (packageCreateMenuMod.checked)
					{
						if (FileSystem.exists("mods/" + packageFolderName + "Menu"))
							Application.current.window.alert("Failed to create menu mod. The name for it is already taken.", "Alert");
						else
						{
							FileSystem.createDirectory("mods/" + packageFolderName + "Menu");
							var modMeta:Dynamic = {
								title: "",
								description: "",
								api_version: "0.1.0",
								mod_version: "1.0.0",
								license: "CC BY 4.0,MIT",
								start_disabled: true,
								hidden: true
							};
							var modMetaString:String = Json.stringify(modMeta, null, "\t");
							File.saveContent("mods/" + packageFolderName + "Menu/_polymod_meta.json", modMetaString);
							packageData.mods.push(packageFolderName + "Menu");
						}
					}

					var packageDataString:String = Json.stringify(packageData, null, "\t");
					File.saveContent("packages/" + packageFolderName + "/data.json", packageDataString);

					window.close();
				}
			}
		}
		buttons.add(newModButton);

		var cancelButton:TextButton = new TextButton(0, 0, "Cancel");
		cancelButton.onClicked = function() { window.close(); }
		buttons.add(cancelButton);

		vbox.add(buttons);

		window = new PopupWindow("popupBG", 30, Std.int(vbox.width + 70), Std.int(vbox.height + 70));
		window.group.add(vbox);
	}

	function prepareChartEditor()
	{
		ChartEditorState.isNew = true;
		ChartEditorState.songId = "test";
		FlxG.sound.music.fadeOut(0.5, 0, function(twn) { FlxG.sound.music.stop(); });
		ChartEditorState.filename = "";
		FlxG.switchState(new ChartEditorState());
	}

	function prepareCharacterEditor()
	{
		CharacterEditorState.newCharacterImage = "characters/dad/daddyDearest";
		FlxG.switchState(new CharacterEditorState(true, "", ""));
	}

	function prepareStageEditor()
	{
		FlxG.switchState(new StageEditorState(true, "", ""));
	}

	function prepareWeekEditor()
	{
		FlxG.switchState(new WeekEditorState(true, "", ""));
	}

	function prepareStoryCharacterEditor()
	{
		StoryCharacterEditorState.newCharacterImage = "ui/story/characters/Dad";
		FlxG.switchState(new StoryCharacterEditorState(true, "", ""));
	}
}