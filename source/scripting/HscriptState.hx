package scripting;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import game.PlayState;
import menus.MainMenuState;
import editors.BaseEditorState;
import newui.UIControl;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

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

	override public function closeSubState()
	{
		super.closeSubState();

		myScript.execFunc("closeSubState", []);
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
		if (Std.isOfType(FlxG.state, MainMenuState))
			MainMenuState.curSubstate = script;

		if (!Paths.hscriptExists(script) && Paths.hscriptExists("data/states/" + script))
			script = "data/states/" + script;

		myScript = new HscriptHandler(script, false);
		myScript.setVar("this", this);
		if (Std.isOfType(FlxG.state, PlayState))
			myScript.setVar("game", PlayState.instance);

		myScript.setVar("add", add);
		myScript.setVar("insert", insert);
		myScript.setVar("remove", remove);

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

	override public function closeSubState()
	{
		super.closeSubState();

		myScript.execFunc("closeSubState", []);
	}
}

class HscriptEditorState extends BaseEditorState
{
	public static var instance:HscriptEditorState;
	public static var script:String = "";
	public var myScript:HscriptHandler;

	override public function new(isNew:Bool, id:String, filename:String, ?_script:String = null)
	{
		if (_script != null)
			script = _script;
		super(isNew, id, filename);
	}

	override public function create()
	{
		instance = this;

		super.create();

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
		UIControl.cursor = MouseCursor.ARROW;

		myScript.execFunc("update", [elapsed]);

		if (!myScript.valid() && FlxG.keys.justPressed.BACKSPACE)
			FlxG.switchState(new HscriptEditorState(isNew, id, filename));

		super.update(elapsed);

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;

		myScript.execFunc("updatePost", [elapsed]);
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