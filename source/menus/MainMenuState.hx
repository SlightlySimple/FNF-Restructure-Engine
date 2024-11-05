package menus;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import data.Options;
import menus.UINavigation;
import menus.mod.ModMenuState;
import menus.freeplay.FreeplayMenuSubState;
import scripting.HscriptHandler;
import scripting.HscriptState;
import transitions.StickerSubState;

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
	public static var curSubstate:String = "";

	public var nav:UINumeralNavigation;

	override public function create()
	{
		super.create();

		HscriptHandler.curMenu = "main";
		if (ModLoader.modListFile != "modList" || ModLoader.packageData != null)
			menuButtonText.remove("mods");

		if (curSubstate == "")
			Util.menuMusic();

		if (Paths.hscriptExists('data/states/MainMenuState'))
			myScript = new HscriptHandler('data/states/MainMenuState');

		nav = new UINumeralNavigation(null, changeSelection, accept, back, changeSelection, accept);
		add(nav);

		if (myScript != null)
			myScript.execFunc("create", []);

		changeSelection();

		if (curSubstate == "freeplay")
		{
			nav.locked = true;
			persistentUpdate = false;
			openSubState(new FreeplayMenuSubState());
		}
		else if (curSubstate != "")
		{
			nav.locked = true;
			persistentUpdate = false;
			openSubState(new HscriptSubState(curSubstate));
		}

		if (StickerSubState.stickers.length > 0)
		{
			if (_requestedSubState != null)
			{
				_requestedSubState.persistentUpdate = true;
				_requestedSubState.openSubState(new StickerSubState());
			}
			else
				openSubState(new StickerSubState());
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (myScript != null)
			myScript.execFunc("update", [elapsed]);

		if (!nav.locked && PackagesState.allowModTools && Options.keyJustPressed("editorMenu"))
		{
			FlxTween.cancelTweensOf(FlxG.sound.music);
			FlxG.sound.music.fadeOut(0.5, 0, function(twn) { FlxG.sound.music.stop(); });
			FlxG.switchState(new EditorMenuState());
		}
	}

	function changeSelection(change:Int = 0)
	{
		curOption = Util.loop(curOption + change, 0, menuButtonText.length - 1);
		if (myScript != null)
			myScript.execFunc("changeSelection", [change]);
	}

	function accept()
	{
		if (myScript != null)
			myScript.execFunc("onAccept", []);
		nav.locked = true;
		new FlxTimer().start(1, function(tmr:FlxTimer) { proceed(); });
	}

	function back()
	{
		nav.locked = true;
		FlxG.switchState(new TitleState());
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

	override public function closeSubState()
	{
		super.closeSubState();
		curSubstate = "";

		if (myScript != null)
			myScript.execFunc("closeSubState", []);
	}
}