package menus;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import data.Options;
import menus.UINavigation;
import scripting.HscriptHandler;

class MainMenuState extends MusicBeatState
{
	public static var menuImages:Array<String> = ["menuBG", "menuBGMagenta", "menuBGBlue", "menuBGBlue", "menuBGBlue", "menuBGBlue", "menuDesat"];
	public static var menuColors:Array<FlxColor> = [FlxColor.WHITE, FlxColor.WHITE, FlxColor.WHITE, FlxColor.WHITE, FlxColor.WHITE, FlxColor.WHITE, 0x404040];

	public var myScript:HscriptHandler = null;

	#if ALLOW_MODS
	var menuButtonText:Array<String> = ["story_mode", "freeplay", "options", "credits", "mods", "quit"];
	#else
	var menuButtonText:Array<String> = ["story_mode", "freeplay", "options", "credits", "quit"];
	#end
	static var curOption:Int = 0;

	public var nav:UINumeralNavigation;

	override public function create()
	{
		super.create();
		HscriptHandler.curMenu = "main";
		if (ModLoader.modListFile != "modList" || ModLoader.packageData != null)
			menuButtonText.remove("mods");

		Util.menuMusic();

		if (Paths.hscriptExists('data/states/MainMenuState'))
			myScript = new HscriptHandler('data/states/MainMenuState');

		nav = new UINumeralNavigation(null, changeSelection, function() {
			if (myScript != null)
				myScript.execFunc("onAccept", []);
			nav.locked = true;
			new FlxTimer().start(1, function(tmr:FlxTimer) { proceed(); });
		});
		add(nav);

		if (myScript != null)
			myScript.execFunc("create", []);

		changeSelection();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (myScript != null)
			myScript.execFunc("update", [elapsed]);

		if (Options.keyJustPressed("fullscreen"))
			FlxG.fullscreen = !FlxG.fullscreen;

		if (PackagesState.allowModTools && Options.keyJustPressed("editorMenu"))
			FlxG.switchState(new EditorMenuState());
	}

	function changeSelection(change:Int = 0)
	{
		curOption = Util.loop(curOption + change, 0, menuButtonText.length - 1);
		if (myScript != null)
			myScript.execFunc("changeSelection", [change]);
	}

	function proceed()
	{
		if (myScript != null)
			myScript.execFunc("proceed", []);

		#if ALLOW_MODS
		if (curOption >= 0 && curOption < menuButtonText.length)
		{
			if (menuButtonText[curOption] == "mods")
				FlxG.switchState(new ModMenuState());
		}
		#end
	}

	override public function beatHit()
	{
		super.beatHit();

		if (myScript != null)
			myScript.execFunc("beatHit", []);
	}

	override public function stepHit()
	{
		super.stepHit();

		if (myScript != null)
			myScript.execFunc("stepHit", []);
	}
}