package scripting;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import game.PlayState;
import objects.AnimatedSprite;

class HscriptSprite extends FlxSprite
{
	public var myScript:HscriptHandler;

	override public function new(script:String, parameters:Array<Dynamic>)
	{
		super();

		myScript = new HscriptHandler("data/scripts/FlxSprite/" + script);
		myScript.setVar("this", this);
		if (Std.isOfType(FlxG.state, PlayState))
			myScript.setVar("game", PlayState.instance);
		myScript.execFunc("new", parameters);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		myScript.execFunc("update", [elapsed]);
	}

	override public function revive()
	{
		super.revive();

		myScript.execFunc("revive", []);
	}

	public function beatHit()
	{
		myScript.execFunc("beatHit", []);
	}

	public function stepHit()
	{
		myScript.execFunc("stepHit", []);
	}

	public function execFunc(func:String, args:Array<Dynamic>)
	{
		myScript.execFunc(func, args);
	}

	public function setVar(vari:String, val:Dynamic)
	{
		myScript.setVar(vari, val);
	}

	public function getVar(vari:String):Dynamic
	{
		return myScript.getVar(vari);
	}
}

class HscriptAnimatedSprite extends AnimatedSprite
{
	public var myScript:HscriptHandler;

	override public function new(script:String, parameters:Array<Dynamic>)
	{
		super();

		myScript = new HscriptHandler("data/scripts/AnimatedSprite/" + script);
		myScript.setVar("this", this);
		if (Std.isOfType(FlxG.state, PlayState))
			myScript.setVar("game", PlayState.instance);
		myScript.execFunc("new", parameters);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		myScript.execFunc("update", [elapsed]);
	}

	override public function revive()
	{
		super.revive();

		myScript.execFunc("revive", []);
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

	public function execFunc(func:String, args:Array<Dynamic>)
	{
		myScript.execFunc(func, args);
	}

	public function setVar(vari:String, val:Dynamic)
	{
		myScript.setVar(vari, val);
	}

	public function getVar(vari:String):Dynamic
	{
		return myScript.getVar(vari);
	}
}

class HscriptSpriteGroup extends FlxSpriteGroup
{
	public var myScript:HscriptHandler;

	override public function new(script:String, parameters:Array<Dynamic>)
	{
		super();

		myScript = new HscriptHandler("data/scripts/FlxSpriteGroup/" + script);
		myScript.setVar("this", this);
		if (Std.isOfType(FlxG.state, PlayState))
			myScript.setVar("game", PlayState.instance);
		myScript.execFunc("new", parameters);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		myScript.execFunc("update", [elapsed]);
	}

	override public function revive()
	{
		super.revive();

		myScript.execFunc("revive", []);
	}

	public function beatHit()
	{
		myScript.execFunc("beatHit", []);
	}

	public function stepHit()
	{
		myScript.execFunc("stepHit", []);
	}

	public function execFunc(func:String, args:Array<Dynamic>)
	{
		myScript.execFunc(func, args);
	}

	public function setVar(vari:String, val:Dynamic)
	{
		myScript.setVar(vari, val);
	}

	public function getVar(vari:String):Dynamic
	{
		return myScript.getVar(vari);
	}
}