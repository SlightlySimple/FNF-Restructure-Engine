package editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

import newui.UIControl;
import newui.DropdownMenu;
import newui.InfoBox;
import newui.TabMenu;
import newui.PopupWindow;

using StringTools;

class BaseEditorState extends MusicBeatState
{
	var isNew:Bool = false;
	var id:String = "";

	var unsaved:Bool = false;
	var undoPosition:Int = 0;
	var pauseUndo:Bool = false;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	var filename:String = "";
	var filenameNew:String = "";
	var filenameText:String = "";

	var ui:UIControl;
	var infoBox:InfoBox;
	var tabMenu:TabMenu;

	override public function new(isNew:Bool, id:String, filename:String)
	{
		this.isNew = isNew;
		this.id = id;
		this.filename = filename;
		super();
	}

	override public function create()
	{
		camGame = new FlxCamera();
		FlxG.cameras.add(camGame);

		camHUD = new FlxCamera();
		camHUD.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camHUD, false);

		super.create();

		Main.onCloseCallback = function() {
			_confirm("quit", function() { Sys.exit(0); });
			return true;
		}
	}

	override public function destroy()
	{
		Main.onCloseCallback = null;

		super.destroy();
	}

	function createUI(file:String, ?conditions:Array<Void->Bool> = null)
	{
		ui = new UIControl(file, conditions);

		infoBox = new InfoBox(990, 50);
		infoBox.cameras = [camHUD];
		add(infoBox);
		UIControl.infoText = "Hover over an option in the editor panel to see what it does.";

		tabMenu = cast element("tabMenu");
		tabMenu.cameras = [camHUD];
		add(tabMenu);

		refreshFilename();
	}

	function element(id:String):FlxSprite
	{
		return ui.element(id);
	}

	function refreshFilename()
	{
		var cwd:String = Sys.getCwd().replace("\\","/");
		var fn:String = filename.replace("\\", "/");

		if (fn.trim() == "")
			filenameText = filenameNew;
		else if (fn.contains(cwd))
			filenameText = fn.replace(cwd, "");
		else
			filenameText = "???/" + fn.substring(fn.lastIndexOf("/")+1, fn.length);

		if (unsaved)
			filenameText = "*" + filenameText;
		Application.current.window.title = filenameText + " - " + Main.windowTitle;
	}

	function changeSaveName(path:String)
	{
		filename = path;
		unsaved = false;
		refreshFilename();
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
}