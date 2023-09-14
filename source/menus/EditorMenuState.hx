package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;

import lime.app.Application;

import funkui.TabMenu;
import funkui.Checkbox;
import funkui.DropdownMenu;
import funkui.InputText;
import funkui.Label;
import funkui.TextButton;
import funkui.Stepper;
import data.Options;
import editors.CharacterEditorState;
import editors.ChartEditorState;
import editors.StageEditorState;
import editors.StoryCharacterEditorState;
import editors.WeekEditorState;
import game.PlayState;
import scripting.HscriptState;

using StringTools;

class EditorMenuState extends MusicBeatState
{
	var menuButtons:Array<FlxText> = [];
	#if ALLOW_MODS
	var menuButtonText:Array<String> = ["Create New Mod", "Chart Editor", "Character Editor", "Stage Editor", "Week Editor", "Story Character Editor"];
	#else
	var menuButtonText:Array<String> = ["Chart Editor", "Character Editor", "Stage Editor", "Week Editor", "Story Character Editor"];
	#end
	var customEditors:Array<String> = [];
	var curButton:Int = -1;

	var inMenu:Bool = false;
	var tabMenu:IsolatedTabMenu;

	override public function create()
	{
		super.create();

		if (FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		var bg:FlxSprite = new FlxSprite(Paths.image('ui/' + MainMenuState.menuImages[6]));
		bg.color = MainMenuState.menuColors[6];
		add(bg);

		if (Paths.textExists("editors"))
			customEditors = Paths.text("editors").replace("\r","").split("\n");
		if (customEditors.contains(null))
			customEditors = [];

		for (e in customEditors)
			menuButtonText.push(e.split("|")[1]);

		var yStart:Int = Std.int((FlxG.height - (menuButtonText.length * 50)) / 2);
		for (i in 0...menuButtonText.length)
		{
			var textButton:FlxText = new FlxText(0, yStart + (i * 50), 0, Lang.get(menuButtonText[i]), 36);
			textButton.font = "VCR OSD Mono";
			textButton.alignment = CENTER;
			textButton.screenCenter(X);
			add(textButton);
			menuButtons.push(textButton);
		}

		FlxG.mouse.visible = true;
	}

	override public function update(elapsed:Float)
	{
		if (!inMenu)
		{
			if (FlxG.mouse.justMoved)
			{
				curButton = -1;
				for (i in 0...menuButtons.length)
				{
					if (FlxG.mouse.overlaps(menuButtons[i]))
					{
						if (menuButtons[i].text == menuButtonText[i])
						{
							menuButtons[i].text = "> " + Lang.get(menuButtonText[i]) + " <";
							menuButtons[i].screenCenter(X);
						}
						curButton = i;
					}
					else if (menuButtons[i].text != menuButtonText[i])
					{
						menuButtons[i].text = Lang.get(menuButtonText[i]);
						menuButtons[i].screenCenter(X);
					}
				}
			}

			if (FlxG.mouse.justPressed && menuButtonText[curButton].trim() != "")
			{
				switch (menuButtonText[curButton].toLowerCase())
				{
					case "create new mod": inMenu = true; createNewMod();
					case "chart editor": inMenu = true; prepareChartEditor();
					case "character editor": inMenu = true; prepareCharacterEditor();
					case "stage editor": inMenu = true; prepareStageEditor();
					case "week editor": inMenu = true; prepareWeekEditor();
					case "story character editor": inMenu = true; prepareStoryCharacterEditor();
					default:
						for (e in customEditors)
						{
							if (e.split("|")[1].toLowerCase() == menuButtonText[curButton].toLowerCase())
								FlxG.switchState(new HscriptState("data/editors/" + e.split("|")[0]));
						}
				}
			}
		}

		super.update(elapsed);

		if (Options.keyJustPressed("ui_back"))
		{
			FlxG.mouse.visible = false;
			FlxG.switchState(new MainMenuState());
		}
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

		tabMenu = new IsolatedTabMenu(0, 0, 400, 190);
		tabMenu.screenCenter();
		add(tabMenu);

		var tabGroup:TabGroup = new TabGroup();

		var modNameInput:InputText = new InputText(10, 20, 380);
		tabGroup.add(modNameInput);
		var modNameLabel:Label = new Label("Mod Name:", modNameInput);
		tabGroup.add(modNameLabel);

		var modDescInput:InputText = new InputText(10, modNameInput.y + 40, 380);
		tabGroup.add(modDescInput);
		var modDescLabel:Label = new Label("Mod Description:", modDescInput);
		tabGroup.add(modDescLabel);

		var createDirs:DropdownMenu = new DropdownMenu(100, modDescInput.y + 40, 200, 20, "Simplified", ["None", "Simplified", "Extended"]);
		tabGroup.add(createDirs);
		var createDirsLabel:Label = new Label("Create Asset Folders", createDirs);
		tabGroup.add(createDirsLabel);

		var newModButton:TextButton = new TextButton(150, createDirs.y + 30, 100, 20, "Create");
		newModButton.onClicked = function()
		{
			if (modNameInput.text != "")
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
						dirs.push("/data");
						dirs.push("/data/characters");
						dirs.push("/data/songs");
						dirs.push("/data/stages");
						dirs.push("/data/weeks");
						dirs.push("/images");
						dirs.push("/images/characters");
						dirs.push("/images/icons");
						dirs.push("/images/stages");
						dirs.push("/images/ui");
						dirs.push("/images/ui/weeks");
						dirs.push("/songs");
						if (createDirs.valueInt == 2)
						{
							dirs.push("/data/autorun");
							dirs.push("/data/events");
							dirs.push("/data/notetypes");
							dirs.push("/data/scripts");
							dirs.push("/data/story_characters");
							dirs.push("/images/ui/difficulties");
							dirs.push("/images/ui/story_characters");
						}
					}

					for (d in dirs)
						FileSystem.createDirectory("mods/" + modFolderName + d);

					var modMeta:Dynamic = {
						title: modNameInput.text,
						description: modDescInput.text,
						api_version: "0.1.0",
						mod_version: "1.0.0",
						license: "CC BY 4.0,MIT"
					};
					var modMetaString:String = Json.stringify(modMeta, null, "\t");
					File.saveContent("mods/" + modFolderName + "/_polymod_meta.json", modMetaString);

					remove(tabMenu);
					inMenu = false;
				}
			}
		};
		tabGroup.add(newModButton);

		var cancelButton:TextButton = new TextButton(150, newModButton.y + 30, 100, 20, "Cancel");
		cancelButton.onClicked = function()
		{
			remove(tabMenu);
			inMenu = false;
		};
		tabGroup.add(cancelButton);

		tabMenu.addGroup(tabGroup);
	}

	function prepareEditorQuick(newClicked:Void->Void, loadClicked:Void->Void)
	{
		tabMenu = new IsolatedTabMenu(0, 0, 200, 100);
		tabMenu.screenCenter();
		add(tabMenu);

		var tabGroup:TabGroup = new TabGroup();

		var newButton:TextButton = new TextButton(10, 10, 180, 20, "New");
		newButton.onClicked = newClicked;
		tabGroup.add(newButton);

		var loadButton:TextButton = new TextButton(10, newButton.y + 30, 180, 20, "Load");
		loadButton.onClicked = loadClicked;
		tabGroup.add(loadButton);

		var cancelButton:TextButton = new TextButton(10, loadButton.y + 30, 180, 20, "Cancel");
		cancelButton.onClicked = function()
		{
			remove(tabMenu);
			inMenu = false;
		};
		tabGroup.add(cancelButton);

		tabMenu.addGroup(tabGroup);
	}

	function prepareChartEditor()
	{
		var newClicked = function()
		{
			var file:FileBrowser = new FileBrowser();
			file.label = "Choose an audio track that you want to chart";
			file.loadCallback = newChartCallback;
			file.load("ogg");
		};

		var loadClicked = function()
		{
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = loadChartCallback;
			file.load("json;*.sm");
		};

		prepareEditorQuick(newClicked, loadClicked);
	}

	function newChartCallback(fullPath:String)
	{
		var songNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (songNameArray.indexOf("songs") == -1)
			Application.current.window.alert("The file you have selected is not a song.", "Alert");
		else
		{
			while (songNameArray[0] != "songs")
				songNameArray.remove(songNameArray[0]);
			songNameArray.remove(songNameArray[0]);
			songNameArray.pop();

			ChartEditorState.filename = "";
			ChartEditorState.newChart = true;
			ChartEditorState.songId = songNameArray.join("/");
			FlxG.switchState(new ChartEditorState());
		}
	}

	function loadChartCallback(fullPath:String)
	{
		var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (jsonNameArray.indexOf("songs") == -1 && jsonNameArray.indexOf("sm") == -1)
			Application.current.window.alert("The file you have selected is not a chart.", "Alert");
		else
		{
			if (jsonNameArray.indexOf("sm") != -1)
			{
				while (jsonNameArray[0] != "sm")
					jsonNameArray.remove(jsonNameArray[0]);
				jsonNameArray.remove(jsonNameArray[0]);

				ChartEditorState.newChart = false;
				ChartEditorState.songFile = jsonNameArray.join("/").split('.sm')[0];
				ChartEditorState.songId = ChartEditorState.songFile;
			}
			else
			{
				while (jsonNameArray[0] != "songs")
					jsonNameArray.remove(jsonNameArray[0]);
				jsonNameArray.remove(jsonNameArray[0]);
				var songIdArray:Array<String> = [];
				for (j in 0...jsonNameArray.length-1)
					songIdArray.push(jsonNameArray[j]);

				ChartEditorState.newChart = false;
				ChartEditorState.songId = songIdArray.join("/");
				ChartEditorState.songFile = jsonNameArray.join("/").split('.json')[0];
			}
			ChartEditorState.filename = fullPath;
			FlxG.switchState(new ChartEditorState());
		}
	}

	function prepareCharacterEditor()
	{
		var newClicked = function()
		{
			var file:FileBrowser = new FileBrowser();
			file.label = "Choose a spritesheet or texture atlas for your character";
			file.loadCallback = newCharacterCallback;
			file.load("png");
		};

		var loadClicked = function()
		{
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = loadCharacterCallback;
			file.load();
		};

		prepareEditorQuick(newClicked, loadClicked);
	}

	function newCharacterCallback(fullPath:String)
	{
		var imageNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (imageNameArray.indexOf("images") == -1)
			Application.current.window.alert("The file you have selected is not a valid asset.", "Alert");
		else
		{
			while (imageNameArray[0] != "images")
				imageNameArray.remove(imageNameArray[0]);
			imageNameArray.remove(imageNameArray[0]);

			var finalImageName = imageNameArray.join('/').split('.png')[0];

			CharacterEditorState.newCharacter = true;
			CharacterEditorState.newCharacterImage = finalImageName;
			CharacterEditorState.curCharacter = "*";
			FlxG.switchState(new CharacterEditorState());
		}
	}

	public static function loadCharacterCallback(fullPath:String)
	{
		var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (jsonNameArray.indexOf("characters") == -1)
			Application.current.window.alert("The file you have selected is not a character.", "Alert");
		else
		{
			while (jsonNameArray[0] != "characters")
				jsonNameArray.remove(jsonNameArray[0]);
			jsonNameArray.remove(jsonNameArray[0]);

			var finalJsonName = jsonNameArray.join("/").split('.json')[0];

			CharacterEditorState.newCharacter = false;
			CharacterEditorState.curCharacter = finalJsonName;
			FlxG.switchState(new CharacterEditorState());
		}
	}

	function prepareStageEditor()
	{
		var newClicked = function()
		{
			var file:FileBrowser = new FileBrowser();
			file.label = "Choose an image in the folder for your stage assets";
			file.loadCallback = newStageCallback;
			file.load("png");
		};

		var loadClicked = function()
		{
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = loadStageCallback;
			file.load();
		};

		prepareEditorQuick(newClicked, loadClicked);
	}

	function newStageCallback(fullPath:String)
	{
		var imageNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (imageNameArray.indexOf("stages") == -1)
			Application.current.window.alert("The file you have selected is not a stage asset.", "Alert");
		else
		{
			while (imageNameArray[0] != "images")
				imageNameArray.remove(imageNameArray[0]);
			imageNameArray.remove(imageNameArray[0]);
			imageNameArray.remove("stages");
			imageNameArray.pop();

			StageEditorState.newStage = true;
			StageEditorState.curStage = imageNameArray.join("/");
			FlxG.switchState(new StageEditorState());
		}
	}

	public static function loadStageCallback(fullPath:String)
	{
		var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (jsonNameArray.indexOf("stages") == -1)
			Application.current.window.alert("The file you have selected is not a stage.", "Alert");
		else
		{
			while (jsonNameArray[0] != "stages")
				jsonNameArray.remove(jsonNameArray[0]);
			jsonNameArray.remove(jsonNameArray[0]);

			var finalJsonName = jsonNameArray.join("/").split('.json')[0];

			StageEditorState.newStage = false;
			StageEditorState.curStage = finalJsonName;
			FlxG.switchState(new StageEditorState());
		}
	}

	function prepareWeekEditor()
	{
		var newClicked = function()
		{
			WeekEditorState.newWeek = true;
			WeekEditorState.curWeek = "*";
			FlxG.switchState(new WeekEditorState());
		};

		var loadClicked = function()
		{
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = loadWeekCallback;
			file.load();
		};

		prepareEditorQuick(newClicked, loadClicked);
	}

	public static function loadWeekCallback(fullPath:String)
	{
		var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (jsonNameArray.indexOf("weeks") == -1)
			Application.current.window.alert("The file you have selected is not a week.", "Alert");
		else
		{
			while (jsonNameArray.length > 1)
				jsonNameArray.remove(jsonNameArray[0]);

			var finalJsonName = jsonNameArray[0].split('.json')[0];

			WeekEditorState.newWeek = false;
			WeekEditorState.curWeek = finalJsonName;
			FlxG.switchState(new WeekEditorState());
		}
	}

	function prepareStoryCharacterEditor()
	{
		var newClicked = function()
		{
			var file:FileBrowser = new FileBrowser();
			file.label = "Choose a spritesheet for your character";
			file.loadCallback = newStoryCharacterCallback;
			file.load("png");
		};

		var loadClicked = function()
		{
			var file:FileBrowser = new FileBrowser();
			file.loadCallback = loadStoryCharacterCallback;
			file.load();
		};

		prepareEditorQuick(newClicked, loadClicked);
	}

	function newStoryCharacterCallback(fullPath:String)
	{
		var imageNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (imageNameArray.indexOf("story_characters") == -1)
			Application.current.window.alert("The file you have selected is not a character asset.", "Alert");
		else
		{
			while (imageNameArray[0] != "story_characters")
				imageNameArray.remove(imageNameArray[0]);
			imageNameArray.remove(imageNameArray[0]);

			var finalImageName = imageNameArray.join('/').split('.png')[0];

			StoryCharacterEditorState.newCharacter = true;
			StoryCharacterEditorState.newCharacterImage = finalImageName;
			StoryCharacterEditorState.curCharacter = "*";
			FlxG.switchState(new StoryCharacterEditorState());
		}
	}

	public static function loadStoryCharacterCallback(fullPath:String)
	{
		var jsonNameArray:Array<String> = fullPath.replace('\\','/').split('/');
		if (jsonNameArray.indexOf("story_characters") == -1)
			Application.current.window.alert("The file you have selected is not a character.", "Alert");
		else
		{
			while (jsonNameArray[0] != "story_characters")
				jsonNameArray.remove(jsonNameArray[0]);
			jsonNameArray.remove(jsonNameArray[0]);

			var finalJsonName = jsonNameArray.join("/").split('.json')[0];

			StoryCharacterEditorState.newCharacter = false;
			StoryCharacterEditorState.curCharacter = finalJsonName;
			FlxG.switchState(new StoryCharacterEditorState());
		}
	}
}