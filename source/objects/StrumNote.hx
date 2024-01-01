package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import data.Noteskins;
import data.ObjectData;
import data.Options;
import game.PlayState;
import shaders.ColorSwap;

using StringTools;

class StrumNote extends FlxSprite
{
	public var column:Int;
	public var strumColumn:Int;
	public var scrollSpeeds:Array<ScrollSpeed> = [];
	public var noteskinOverride:String = "";
	public var noteskinType:String = "";
	public var noteskinData:NoteskinTypedef = null;
	public var availableColors:Array<String> = [];
	public var defaultColor:String = "";
	public var numKeys:Int = 4;
	public var isPlayer:Bool = true;
	public var singers:Array<Character> = [];
	public var defaultCharAnims:Array<String> = ["", ""];

	public static var noteSize:Int = 112;
	public static var noteH:Int = 0;
	public static var noteScale:Float = 1;
	public var myW:Int = 0;
	public var myH:Int = 0;
	public var baseAngle:Int = 0;
	public var unbakedAngle:Int = 0;
	public var ang:Float = 0;
	public var noteAng:Float = 0;
	public var allowShader:Bool = true;
	public var doUnstick:Bool = false;

	public var isMod:Bool = false;
	public var modBaseX:Float = 0;
	public var modBaseY:Float = 0;
	public var modX:Float = 0;
	public var modY:Float = 0;

	override public function new(column:Int, ?noteskinType:String = "default", ?strumColumn:Null<Int> = null)
	{
		super();

		this.column = column;
		this.strumColumn = strumColumn;
		if (strumColumn == null)
			this.strumColumn = column;
		noteScale = Options.options.noteScale;

		if (noteskinOverride == "")
			noteskinOverride = Noteskins.noteskinName;

		switch (strumColumn % 4)
		{
			case 0: defaultCharAnims = ["singLEFT", "singLEFTmiss"];
			case 1: defaultCharAnims = ["singDOWN", "singDOWNmiss"];
			case 2: defaultCharAnims = ["singUP", "singUPmiss"];
			case 3: defaultCharAnims = ["singRIGHT", "singRIGHTmiss"];
		}
		onNotetypeChanged(noteskinType);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		angle = baseAngle + unbakedAngle + ang;

		if (isMod)
		{
			x = modBaseX + modX;
			y = modBaseY + (modY * (Options.options.downscroll ? -1 : 1));
		}

		if ((!isPlayer || PlayState.botplay || doUnstick || Options.options.strumAnims == 1) && animation.curAnim.finished && animation.curAnim.name != "static")
		{
			doUnstick = false;
			playAnim("static");
		}
	}

	public function playAnim(animName:String, forced:Bool = false, ?ignoreOptions:Bool = false, ?color:String = "")
	{
		if (Options.options.strumAnims == 0 && animName != "static" && !ignoreOptions)
			return;

		var aaName:String = animName;
		switch (animName)
		{
			case "confirm":
				if (availableColors.contains(color))
				{
					aaName += color;
					if (noteskinData.colorStrums && allowShader)
						shader = Note.getShader(color);
				}
				else
				{
					aaName += defaultColor;
					if (noteskinData.colorStrums && allowShader)
						shader = Note.getShader(defaultColor);
				}
			case "press":
				if (noteskinData.colorStrums && allowShader)
					shader = Note.getShader(defaultColor);
			default:
				if (allowShader)
					shader = null;
		}
		animation.play(aaName, forced);
		updateHitbox();
		offset.x = (frameWidth - myW) / 2;
		offset.y = (frameHeight - myH) / 2;

		if (animName == "confirm")
		{
			var noteColor:String = aaName.replace("confirm", "");

			var colorAnim:Int = -1;

			for (i in 0...noteskinData.colors.length)
			{
				if (noteskinData.colors[i].color == noteColor && noteskinData.colors[i].shape == noteskinData.slots[strumColumn % noteskinData.slots.length].shape)
					colorAnim = i;
			}
			baseAngle = Std.int(-noteskinData.slots[strumColumn % noteskinData.slots.length].angle + noteskinData.colors[colorAnim].angle);
		}
		else
			baseAngle = 0;

		angle = baseAngle + unbakedAngle + ang;
	}

	public function onNotetypeChanged(newNoteType:String)
	{
		noteskinType = newNoteType;
		frames = null;

		noteskinData = Noteskins.getData(noteskinOverride, noteskinType);
		if (!noteskinData.colorStrums && allowShader)
			shader = null;
		defaultColor = noteskinData.slots[strumColumn % noteskinData.slots.length].color;
		availableColors = [];
		for (c in noteskinData.colors)
		{
			if (!availableColors.contains(c.color))
				availableColors.push(c.color);
		}
		Noteskins.addSlotAnims(this, noteskinData, strumColumn);
		antialiasing = noteskinData.antialias;

		scale.x = noteskinData.scale * noteScale;
		scale.y = noteskinData.scale * noteScale;
		noteSize = Std.int(noteskinData.noteSize * noteScale);
		unbakedAngle = noteskinData.slots[strumColumn % noteskinData.slots.length].unbakedAngle;

		playAnim("static");
		updateHitbox();
		myW = Std.int(width);
		myH = Std.int(height);
		noteH = myH;
	}

	public function resetPosition(ds:Bool, ms:Bool, columnDivisions:Array<Int>)
	{
		var uniqueDivisions:Array<Int> = [];
		for (i in columnDivisions)
		{
			if (!uniqueDivisions.contains(i))
				uniqueDivisions.push(i);
		}
		var myDivision:Int = 0;
		numKeys = 0;
		for (i in 0...columnDivisions.length)
		{
			if (columnDivisions[i] == columnDivisions[column])
			{
				if (i < column)
					myDivision++;
				numKeys++;
			}
		}

		visible = true;
		if (ms)
		{
			x = FlxG.width / 2 - (noteSize * (numKeys / 2));
			if (!isPlayer)
				visible = false;
		}
		else
		{
			x = FlxG.width / (uniqueDivisions.length * 2) - (noteSize * (numKeys / 2));
			x += (FlxG.width / (uniqueDivisions.length * 2)) * uniqueDivisions.indexOf(columnDivisions[column]) * 2;
		}
		x += (noteSize - width) / 2;
		x += noteSize * myDivision;

		if (ds)
			y = FlxG.height - height - 50;
		else
			y = 50;

		modBaseX = x;
		modBaseY = y;
	}
}