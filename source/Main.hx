package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.input.keyboard.FlxKey;
import openfl.display.Sprite;

import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.events.UncaughtErrorEvent;
import lime.app.Application;
import lime.math.Rectangle;
import sys.FileSystem;
import sys.io.File;

class Main extends Sprite
{
	static var fps_mems:Array<FPS_Mem> = [];
	public static var fpsVisible(default, set):Bool = true;
	public static var fpsOnRight(default, set):Bool = false;
	public static var windowTitle:String = "Friday Night Funkin: Restructure Engine";
	public static var screenshotKeys:Array<FlxKey> = [FlxKey.F3];
	public static var fullscreenKeys:Array<FlxKey> = [FlxKey.F11];

	public function new()
	{
		super();

		FlxG.fixedTimestep = false;

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		Application.current.window.onClose.add(onClose);

		var game:FlxGame = new FlxGame(0, 0, VersionCheckerState, 1, 120, 120, true, false);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, takeScreenshot);
		@:privateAccess
		game._customSoundTray = FunkSoundTray;
		addChild(game);

		fps_mems.push(new FPS_Mem(11, 11, 0x000000));
		fps_mems.push(new FPS_Mem(9, 11, 0x000000));
		fps_mems.push(new FPS_Mem(11, 9, 0x000000));
		fps_mems.push(new FPS_Mem(9, 9, 0x000000));
		fps_mems.push(new FPS_Mem(10, 10, 0xffffff));

		for (f in fps_mems)
			addChild(f);
	}

	public static function set_fpsVisible(val:Bool):Bool
	{
		fpsVisible = val;
		for (f in fps_mems)
			f.visible = val;
		return val;
	}

	public static function set_fpsOnRight(val:Bool):Bool
	{
		fpsOnRight = val;
		for (f in fps_mems)
			f.onRight = val;
		return val;
	}

	function fourDigitNumber(i:Int):String
	{
		if (i < 10)
			return "000" + Std.string(i);
		if (i < 100)
			return "00" + Std.string(i);
		if (i < 1000)
			return "0" + Std.string(i);
		return Std.string(i);
	}

	function getScreenshotName():String
	{
		var screenNumber:Int = 1;
		if (FileSystem.exists("screenshot0001.png"))
		{
			while (FileSystem.exists("screenshot"+fourDigitNumber(screenNumber)+".png"))
				screenNumber++;
		}
		return "screenshot"+fourDigitNumber(screenNumber)+".png";
	}

	function takeScreenshot(event:KeyboardEvent)
	{
		var _key:FlxKey = cast event.keyCode;
		if (screenshotKeys.contains(_key))
		{
			var screen = Application.current.window.readPixels(new Rectangle(0, 0, Application.current.window.width, Application.current.window.height));
			var screenBytes = screen.encode();
			File.saveBytes(getScreenshotName(), screenBytes);
			FlxG.sound.play(Paths.sound("ui/screenshot"));
		}
		else if (fullscreenKeys.contains(_key))
			FlxG.fullscreen = !FlxG.fullscreen;
	}

	public static var onCloseCallback:Void->Bool = null;
	function onClose()
	{
		if (onCloseCallback != null)
		{
			var ret = onCloseCallback();
			if (ret)
				Application.current.window.onClose.cancel();
		}
	}

	function onCrash(e:UncaughtErrorEvent)
	{
		Application.current.window.alert("Uncaught Error: " + e.error, "Error!");
	}
}
