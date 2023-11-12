package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import data.Noteskins;
import data.ObjectData;
import data.Options;
import game.PlayState;
import shaders.ColorSwap;

class Note extends FlxSprite
{
	public var strumTime:Float;
	public var beat:Float;
	public var column:Int;
	public var strumColumn:Int;
	public var noteType:String = "default";
	public var missed:Bool = false;
	public var typeData:NoteTypeData = null;
	public static var defaultTypeData:NoteTypeData = null;
	public static var noteTypes:Map<String, NoteTypeData>;
	public var noteskinOverride:String = "";
	public var noteskinType:String = "";
	public var noteskinData:NoteskinTypedef = null;
	public var noteColor:String = "";
	public var noteShape:String = "";
	public var child:SustainNote = null;
	public var noteAng:Float = 0;
	public var isLift:Bool = false;

	public var baseAngle:Int = 0;
	public var alph:Float = 1;
	public var downscroll:Bool = false;
	public var calcVis:Bool = true;
	public var calcAlpha:Bool = true;
	public var calcAngle:Bool = true;
	public var calcX:Bool = true;
	public var calcY:Bool = true;
	public var calcNoteAng:Bool = true;
	public static var cs:Map<String, ColorSwap> = new Map<String, ColorSwap>();

	public var hitAnim:String = "";
	public var missAnim:String = "";
	public var animationSuffix:String = "";
	public var singers:Array<Character> = [];

	public static function refreshNoteTypes(types:Array<String>)
	{
		if (defaultTypeData == null)
			defaultTypeData = cast Paths.json("notetypes/default");

		noteTypes = new Map<String, NoteTypeData>();
		for (t in types)
		{
			if (t != "default" && t != "" && Paths.jsonExists("notetypes/" + t))
			{
				var typeData:NoteTypeData = cast Paths.json("notetypes/" + t);
				if (typeData.noteskinOverride == null)
					typeData.noteskinOverride = defaultTypeData.noteskinOverride;

				if (typeData.noteskinOverrideSustain == null)
					typeData.noteskinOverrideSustain = defaultTypeData.noteskinOverrideSustain;

				if (typeData.hitSound == null)
					typeData.hitSound = defaultTypeData.hitSound;

				if (typeData.hitSoundVolume == null)
					typeData.hitSoundVolume = defaultTypeData.hitSoundVolume;

				if (typeData.animationSuffix == null)
					typeData.animationSuffix = defaultTypeData.animationSuffix;

				if (typeData.healthValues == null)
					typeData.healthValues = defaultTypeData.healthValues;

				if (typeData.alwaysSplash == null)
					typeData.alwaysSplash = defaultTypeData.alwaysSplash;

				if (typeData.splashMin == null)
					typeData.splashMin = defaultTypeData.splashMin;
				noteTypes[t] = typeData;
			}
		}
	}

	public static function getShader(col:String)
	{
		if (!Options.noteColorExists(col))
			return null;

		var colArray:Array<Dynamic> = Options.noteColor(col);
		if (colArray[0] == 0 && colArray[1] == true && colArray[2] == 0 && colArray[3] == 0)
			return null;

		if (!cs.exists(col))
		{
			var colswap:ColorSwap = new ColorSwap();
			colswap.setHSV(Options.noteColorArray(col));
			colswap.hAdd = colArray[1];
			cs[col] = colswap;
		}
		return cs[col].shader;
	}

	override public function new(strumTime:Float, column:Int, ?noteType:String = "", ?noteskinType:String = "default", ?strumColumn:Null<Int> = null)
	{
		super();

		this.strumTime = strumTime;
		beat = Conductor.beatFromTime(strumTime);
		this.column = column;
		this.strumColumn = strumColumn;
		if (strumColumn == null)
			this.strumColumn = column;
		downscroll = Options.options.downscroll;

		this.noteType = noteType;
		updateTypeData();

		onNotetypeChanged(noteskinType);
	}

	public function onNotetypeChanged(newNoteType:String)
	{
		noteskinType = newNoteType;
		frames = null;

		noteskinData = Noteskins.getData(noteskinOverride, noteskinType);
		noteColor = Noteskins.getNoteColor(noteskinData, strumColumn, beat);
		noteShape = Noteskins.getNoteShape(noteskinData, strumColumn);
		var noteAngle = Noteskins.addNoteAnim(this, noteskinData, noteColor, noteShape);
		baseAngle = Std.int(-noteskinData.slots[strumColumn % noteskinData.slots.length].angle + noteskinData.slots[strumColumn % noteskinData.slots.length].unbakedAngle + noteAngle);

		angle = baseAngle;
		antialiasing = noteskinData.antialias;

		if (noteskinData.scale < 0 && FlxG.state is PlayState && PlayState.instance.strumNotes.members.length > column)
			noteskinData.scale *= -PlayState.instance.strumNotes.members[column].noteskinData.scale;
		scale.set(noteskinData.scale * StrumNote.noteScale, noteskinData.scale * StrumNote.noteScale);
		shader = getShader(noteColor);
		animation.play("idle");

		updateHitbox();

		if (animation.curAnim.numFrames > 1)
			active = true;
		else
			active = false;
	}

	public function updateTypeData()
	{
		if (defaultTypeData == null)
			defaultTypeData = cast Paths.json("notetypes/default");

		if (noteTypes.exists(noteType))
			typeData = Reflect.copy(noteTypes[noteType]);
		else
			typeData = Reflect.copy(defaultTypeData);

		noteskinOverride = typeData.noteskinOverride;
		animationSuffix = typeData.animationSuffix;

		if (noteskinOverride == "")
			noteskinOverride = Noteskins.noteskinName;
	}

	public function assignAnims(strum:StrumNote)
	{
		hitAnim = strum.defaultCharAnims[0] + animationSuffix;
		missAnim = strum.defaultCharAnims[1] + animationSuffix;
	}

	public function offsetByStrum(strum:StrumNote)
	{
		offset.x -= (strum.myW - width) / 2;
		offset.y -= (strum.myH - height) / 2;
	}

	public function calcPos(strum:StrumNote, h:Float)
	{
		var xoff:Float = 0;
		var yoff:Float = 0;
		switch (noteAng)
		{
			case 0: xoff = 1; yoff = 0;
			case 90: xoff = 0; yoff = 1;
			case 180: xoff = -1; yoff = 0;
			case 270: xoff = 0; yoff = -1;
			default: xoff = Math.cos(noteAng * Math.PI / 180); yoff = Math.sin(noteAng * Math.PI / 180);
		}

		if (calcX)
			x = strum.x - (xoff * h);
		if (calcY)
			y = strum.y - (yoff * h);
	}
}

class SustainNote extends FlxSprite
{
	public static var noteGraphics:Map<String, FlxFramesCollection> = new Map<String, FlxFramesCollection>();

	public var strumTime:Float;
	public var beat:Float;
	public var column:Int;
	public var strumColumn:Int;
	public var noteType:String = "default";
	public var sustainLength:Float;
	public var canBeHit:Bool = false;
	public var missed:Bool = false;
	public var isBeingHit:Bool = false;
	public var hitTimer:Float = 0;
	public var hitLimit:Float = 100;

	public var typeData:NoteTypeData = null;
	public var noteskinOverride:String = "";
	public var noteskinType:String = "";
	public var noteskinData:NoteskinTypedef = null;
	public var noteColor:String = "";
	public var noteShape:String = "";
	public var parent:Note = null;
	public var noteAng:Float = 0;

	public var alph:Float = 1;
	public var gap:Int = 1;
	public var downscroll:Bool = false;
	public var calcVis:Bool = true;
	public var calcAlpha:Bool = true;
	public var calcX:Bool = true;
	public var calcY:Bool = true;
	public var calcNoteAng:Bool = true;

	public var clipHeight:Float = 0;
	public var clipAmount:Float = 0.5;
	public var actualHeight:Float;

	public var hitAnim:String = "";
	public var missAnim:String = "";
	public var animationSuffix:String = "";
	public var singers:Array<Character> = [];

	override public function new(strumTime:Float, column:Int, sustainLength:Float, actualHeight:Float, ?noteType:String = "", ?noteskinType:String = "default", ?strumColumn:Null<Int> = null)
	{
		super();

		this.strumTime = strumTime;
		beat = Conductor.beatFromTime(strumTime);
		this.column = column;
		this.strumColumn = strumColumn;
		if (strumColumn == null)
			this.strumColumn = column;
		this.sustainLength = sustainLength;
		this.actualHeight = actualHeight;
		downscroll = Options.options.downscroll;

		this.noteType = noteType;
		updateTypeData();

		onNotetypeChanged(noteskinType);
	}

	public function rebuildSustain()
	{
		var key:String = Std.int(actualHeight) + ":SustainNote" + noteskinType + "-" + noteColor + "-" + noteShape;
		if (noteGraphics.exists(key))
			frames = noteGraphics[key];
		else
		{
			var sustainPiece:FlxSprite = new FlxSprite();
			sustainPiece.antialiasing = false;
			Noteskins.addSustainAnim(sustainPiece, "hold", noteskinData, noteColor, noteShape);
			sustainPiece.animation.play("hold");
			sustainPiece.updateHitbox();

			var sustainEnd:FlxSprite = new FlxSprite();
			sustainEnd.antialiasing = false;
			Noteskins.addSustainAnim(sustainEnd, "holdEnd", noteskinData, noteColor, noteShape);
			sustainEnd.animation.play("holdEnd");
			sustainEnd.updateHitbox();

			if (noteskinData.scale < 0 && FlxG.state is PlayState && PlayState.instance.strumNotes.members.length > column)
				noteskinData.scale *= -PlayState.instance.strumNotes.members[column].noteskinData.scale;
			var ww:Int = Std.int(Math.max(sustainPiece.width, sustainEnd.width));
			var hh:Int = Std.int(actualHeight / (noteskinData.scale * StrumNote.noteScale));

			makeGraphic(ww, hh, FlxColor.TRANSPARENT, false, key);
			var yy:Int = Std.int(height - sustainEnd.height);
			if (sustainEnd.width < ww - 2)
				stamp(sustainEnd, Std.int((ww - sustainEnd.width) / 2), yy);
			else
				stamp(sustainEnd, 0, yy);
			while (yy > 0)
			{
				yy -= Std.int(sustainPiece.height - gap);
				if (sustainPiece.width < ww - 2)
					stamp(sustainPiece, Std.int((ww - sustainPiece.width) / 2), yy);
				else
					stamp(sustainPiece, 0, yy);
			}

			noteGraphics[key] = frames;
			FlxG.bitmap.get(key).destroyOnNoUse = false;
			sustainPiece.kill();
			sustainPiece.destroy();
			sustainEnd.kill();
			sustainEnd.destroy();
		}

		scale.set(noteskinData.scale * StrumNote.noteScale, noteskinData.scale * StrumNote.noteScale);
		updateHitbox();
		origin.set();
		offset.set();

		shader = Note.getShader(noteColor);
		flipX = Options.options.flipSustains;
		active = false;
	}

	override public function draw()
	{
		if (clipHeight > 0)
		{
			var rect = new FlxRect(0, clipHeight / scale.y, (width * 2) / scale.x, (height * 2) / scale.y);
			clipRect = rect;
		}
		super.draw();
	}

	public function onNotetypeChanged(newNoteType:String)
	{
		noteskinType = newNoteType;

		noteskinData = Noteskins.getData(noteskinOverride, noteskinType);
		noteColor = Noteskins.getNoteColor(noteskinData, strumColumn, beat);
		noteShape = Noteskins.getNoteShape(noteskinData, strumColumn);
		alph = noteskinData.sustainOpacity;
		gap = noteskinData.sustainGap;
		antialiasing = noteskinData.antialias;

		rebuildSustain();
	}

	public function updateTypeData()
	{
		var defaultTypeData = Note.defaultTypeData;

		if (Note.noteTypes.exists(noteType))
			typeData = Reflect.copy(Note.noteTypes[noteType]);
		else
			typeData = Reflect.copy(defaultTypeData);

		animationSuffix = typeData.animationSuffix;
		noteskinOverride = typeData.noteskinOverrideSustain;

		if (noteskinOverride == "")
			noteskinOverride = Noteskins.noteskinName;
	}

	public function assignAnims(strum:StrumNote)
	{
		hitAnim = strum.defaultCharAnims[0] + animationSuffix;
		missAnim = strum.defaultCharAnims[1] + animationSuffix;
	}

	public function calcPos(strum:StrumNote, h:Float)
	{
		var xoff:Float = 0;
		var yoff:Float = 0;
		switch (noteAng)
		{
			case 0: xoff = 1; yoff = 0;
			case 90: xoff = 0; yoff = 1;
			case 180: xoff = -1; yoff = 0;
			case 270: xoff = 0; yoff = -1;
			default: xoff = Math.cos(noteAng * Math.PI / 180); yoff = Math.sin(noteAng * Math.PI / 180);
		}

		var cX:Float = (strum.x + strum.myW / 2) - (xoff * h);
		var cY:Float = (strum.y + strum.myH / 2) - (yoff * h);
		if (parent != null && parent.alive)
		{
			cX = parent.getGraphicMidpoint().x - parent.offset.x;
			cY = parent.getGraphicMidpoint().y - parent.offset.y;
		}
		if (calcX)
			x = cX + (yoff * (width / 2));
		if (calcY)
			y = cY - (xoff * (width / 2));
	}
}

class NoteSplash extends FlxSprite
{
	override public function new()
	{
		super();
	}

	public function refreshSplash(x:Float, y:Float, asset:String, ?grid:Array<Int> = null)
	{
		this.x = x;
		this.y = y;
		if (Paths.sparrowExists("ui/note_splashes/" + asset))
			frames = Paths.sparrow("ui/note_splashes/" + asset);
		else
			frames = Paths.tiles("ui/note_splashes/" + asset, grid[0], grid[1]);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (animation.curAnim.finished)
			kill();
	}
}