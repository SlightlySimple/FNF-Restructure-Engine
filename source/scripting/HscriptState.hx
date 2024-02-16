package scripting;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import game.PlayState;

using StringTools;

class HscriptState extends MusicBeatState
{
	public static var instance:HscriptState;
	public static var script:String = "";
	public var myScript:HscriptHandler;

	public static function setFromState()
	{
		if (script.endsWith("-story") || script.endsWith("-freeplay"))
			PlayState.fromState = script;
	}

	override public function new(?_script:String = null)
	{
		if (_script != null)
			script = _script;
		super();
	}

	override public function create()
	{
		instance = this;

		if (!Paths.hscriptExists(script) && Paths.hscriptExists("data/states/" + script))
			script = "data/states/" + script;
		myScript = new HscriptHandler(script);
		myScript.execFunc("create", []);

		if (!myScript.valid())
		{
			var refreshText:FlxText = new FlxText(0, 0, FlxG.width - 100, "There was an error parsing the script.\nPress BACKSPACE to reload the state after the error has been resolved.", 32);
			refreshText.alignment = CENTER;
			refreshText.screenCenter();
			add(refreshText);
		}

		super.create();
	}

	override public function destroy()
	{
		myScript.execFunc("destroy", []);

		if (MP4Handler.vlcBitmap != null && MP4Handler.vlcBitmap.isPlaying)
			MP4Handler.vlcBitmap.stop();

		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		myScript.execFunc("update", [elapsed]);

		if (!myScript.valid() && FlxG.keys.justPressed.BACKSPACE)
			FlxG.switchState(new HscriptState());
	}

	override public function beatHit()
	{
		super.beatHit();

		myScript.execFunc("beatHit", []);
	}

	override public function stepHit()
	{
		super.stepHit();

		myScript.execFunc("stepHit", []);
	}
}

class HscriptSubState extends FlxSubState
{
	public static var instance:HscriptSubState;
	public static var script:String = "";
	public var myScript:HscriptHandler;

	override public function new(?_script:String = null)
	{
		if (_script != null)
			script = _script;
		super();

		instance = this;

		if (!Paths.hscriptExists(script) && Paths.hscriptExists("data/states/" + script))
			script = "data/states/" + script;
		myScript = new HscriptHandler(script);
		myScript.execFunc("new", []);

		if (!myScript.valid())
		{
			var refreshText:FlxText = new FlxText(0, 0, FlxG.width - 100, "There was an error parsing the script.\nPress BACKSPACE to close the state.", 32);
			refreshText.alignment = CENTER;
			refreshText.screenCenter();
			add(refreshText);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		myScript.execFunc("update", [elapsed]);

		if (!myScript.valid() && FlxG.keys.justPressed.BACKSPACE)
			close();
	}
}