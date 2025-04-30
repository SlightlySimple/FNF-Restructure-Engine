package menus;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import data.Options;

class UINavigation extends FlxBasic
{
	public var right:Void->Void = null;
	public var left:Void->Void = null;
	public var down:Void->Void = null;
	public var up:Void->Void = null;
	public var accept:Void->Void = null;
	public var back:Void->Void = null;
	public var scroll:Int->Void = null;
	public var leftClick:Void->Void = null;
	public var rightClick:Void->Void = null;
	public var leftClickIsAccept:Bool = true;
	public var rightClickIsBack:Bool = true;

	public var uiSounds:Array<Bool> = [true, true, true];
	public var uiSoundFiles:Array<String> = ["ui/scrollMenu", "ui/confirmMenu", "ui/cancelMenu"];
	public var locked(default, set):Bool = false;
	var lockedFrames:Int = 0;

	override public function new(?right:Void->Void = null, ?left:Void->Void = null, ?down:Void->Void = null, ?up:Void->Void = null, ?accept:Void->Void = null, ?back:Void->Void = null, ?scroll:Int->Void = null, ?leftClick:Void->Void = null, ?rightClick:Void->Void = null)
	{
		super();

		this.right = right;
		this.left = left;
		this.down = down;
		this.up = up;
		this.accept = accept;
		this.back = back;
		this.scroll = scroll;
		this.leftClick = leftClick;
		this.rightClick = rightClick;
	}

	override public function update(elapsed:Float)
	{
		if (locked) return;

		if (lockedFrames > 0)
		{
			lockedFrames--;
			return;
		}

		super.update(elapsed);

		if (right != null && Options.keyJustPressed("ui_right"))
		{
			if (uiSounds[0])
				FlxG.sound.play(Paths.sound(uiSoundFiles[0]));
			right();
		}

		if (left != null && Options.keyJustPressed("ui_left"))
		{
			if (uiSounds[0])
				FlxG.sound.play(Paths.sound(uiSoundFiles[0]));
			left();
		}

		if (down != null && Options.keyJustPressed("ui_down"))
		{
			if (uiSounds[0])
				FlxG.sound.play(Paths.sound(uiSoundFiles[0]));
			down();
		}

		if (up != null && Options.keyJustPressed("ui_up"))
		{
			if (uiSounds[0])
				FlxG.sound.play(Paths.sound(uiSoundFiles[0]));
			up();
		}

		if (accept != null && Options.keyJustPressed("ui_accept"))
		{
			if (uiSounds[1])
				FlxG.sound.play(Paths.sound(uiSoundFiles[1]));
			accept();
		}

		if (back != null && Options.keyJustPressed("ui_back"))
		{
			if (uiSounds[2])
				FlxG.sound.play(Paths.sound(uiSoundFiles[2]));
			back();
		}

		if (scroll != null && FlxG.mouse.wheel != 0)
		{
			if (uiSounds[0])
				FlxG.sound.play(Paths.sound(uiSoundFiles[0]));
			scroll(-FlxG.mouse.wheel);
		}

		if ((leftClick != null || (leftClickIsAccept && accept != null)) && Options.mouseJustPressed())
		{
			if (uiSounds[1])
				FlxG.sound.play(Paths.sound(uiSoundFiles[1]));
			if (leftClick != null)
				leftClick();
			else if (leftClickIsAccept && accept != null)
				accept();
		}

		if ((rightClick != null || (rightClickIsBack && back != null)) &&Options.mouseJustPressed(true))
		{
			if (uiSounds[2])
				FlxG.sound.play(Paths.sound(uiSoundFiles[2]));
			if (rightClick != null)
				rightClick();
			else if (rightClickIsBack && back != null)
				back();
		}
	}

	public function set_locked(val:Bool):Bool
	{
		if (!locked && val)
			lockedFrames = 1;

		return locked = val;
	}
}

class UINumeralNavigation extends UINavigation
{
	override public function new(?rightleft:Int->Void = null, ?downup:Int->Void = null, ?accept:Void->Void = null, ?back:Void->Void = null, ?scroll:Int->Void = null, ?leftClick:Void->Void = null, ?rightClick:Void->Void = null)
	{
		super(null, null, null, null, accept, back, scroll, leftClick, rightClick);

		if (rightleft != null)
		{
			right = function() {rightleft(1);}
			left = function() {rightleft(-1);}
		}

		if (downup != null)
		{
			down = function() {downup(1);}
			up = function() {downup(-1);}
		}
	}
}

class UIMenu extends FlxSpriteGroup
{
	public var selection(default, set):Int = 0;

	public var onIdle:FlxSprite->Void = null;
	public var onHover:FlxSprite->Void = null;
	public var onSelected:FlxSprite->Void = null;
	public var onNotSelected:FlxSprite->Void = null;

	override public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);

		onIdle = function(s:FlxSprite) { s.animation.play("idle"); };
		onHover = function(s:FlxSprite) { s.animation.play("hover"); };
		onSelected = function(s:FlxSprite) { s.animation.play("selected"); };
		onNotSelected = function(s:FlxSprite) { s.animation.play("notSelected"); };
	}

	override public function add(s:FlxSprite):FlxSprite
	{
		var ret:FlxSprite = super.add(s);
		if (members.indexOf(s) == selection)
			onHover(s);
		else
			onIdle(s);
		return ret;
	}

	public function set_selection(s:Int):Int
	{
		if (s >= 0 && s < members.length)
		{
			if (s != selection)
			{
				if (selection < members.length)
					onIdle(members[selection]);
				onHover(members[s]);
			}
			selection = s;
			return s;
		}
		return selection;
	}

	public function select()
	{
		for (i in 0...members.length)
		{
			if (i == selection)
				onSelected(members[i]);
			else
				onNotSelected(members[i]);
		}
	}
}