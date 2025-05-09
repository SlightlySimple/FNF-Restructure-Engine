package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import helpers.Cloner;
import data.Noteskins;
import data.ObjectData;
import data.Options;
import game.PlayState;
import shaders.ColorSwap;

typedef NoteHitData =
{
	var offset:Float;
	var rating:Int;
}

class Note extends FlxSprite
{
	public var data:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float;
	public var beat:Float;
	public var column:Int;
	public var strumColumn:Int;
	public var noteType:String = "default";
	public var missed:Bool = false;
	public var hitData:NoteHitData = null;
	public var typeData:NoteTypeData = null;
	public static var defaultTypeData:NoteTypeData = null;
	public static var noteTypes:Map<String, NoteTypeData> = null;
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

	public static function refreshNoteTypes(types:Array<String>, ?force:Bool = false)
	{
		if (defaultTypeData == null)
			defaultTypeData = cast Paths.json("notetypes/default");

		if (noteTypes == null || force)
			noteTypes = new Map<String, NoteTypeData>();

		for (t in types)
		{
			if (t != "default" && t != "" && !noteTypes.exists(t) && Paths.jsonExists("notetypes/" + t))
			{
				var typeData:NoteTypeData = cast Paths.json("notetypes/" + t);
				if (typeData.noteskinOverride == null)
					typeData.noteskinOverride = defaultTypeData.noteskinOverride;

				if (typeData.noteskinOverrideSustain == null)
					typeData.noteskinOverrideSustain = defaultTypeData.noteskinOverrideSustain;

				if (typeData.noSustains == null)
					typeData.noSustains = defaultTypeData.noSustains;

				if (typeData.hitSound == null)
					typeData.hitSound = defaultTypeData.hitSound;

				if (typeData.hitSoundVolume == null)
					typeData.hitSoundVolume = defaultTypeData.hitSoundVolume;

				if (typeData.placeSound == null)
					typeData.placeSound = defaultTypeData.placeSound;

				if (typeData.animationSuffix == null)
					typeData.animationSuffix = defaultTypeData.animationSuffix;

				if (typeData.animation == null)
					typeData.animation = defaultTypeData.animation;

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
		return cs[col];
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
		if (noteskinData.allowSplashes && noteskinData.splashes.scale < 0 && FlxG.state is PlayState && PlayState.instance.strumNotes.members.length > column)
			noteskinData.splashes.scale *= -PlayState.instance.strumNotes.members[column].noteskinData.scale;

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
		if (noteTypes == null)
			noteTypes = new Map<String, NoteTypeData>();

		if (noteTypes.exists(noteType))
			typeData = Cloner.clone(noteTypes[noteType]);
		else
			typeData = Cloner.clone(defaultTypeData);

		noteskinOverride = typeData.noteskinOverride;
		animationSuffix = typeData.animationSuffix;

		if (noteskinOverride == "")
			noteskinOverride = Noteskins.noteskinName;
	}

	public function assignAnims(strum:StrumNote)
	{
		hitAnim = strum.defaultCharAnims[0] + animationSuffix;
		missAnim = strum.defaultCharAnims[1] + animationSuffix;
		if (typeData.animation != null)
			hitAnim = typeData.animation + animationSuffix;
		if (typeData.animationMiss != null)
			missAnim = typeData.animationMiss + animationSuffix;
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

		var snappedH:Float = h;
		if (noteskinData.pixelPerfect)
			snappedH = Math.round(h / scale.y) * scale.y;
		if (calcX)
			x = strum.x - (xoff * snappedH);
		if (calcY)
			y = strum.y - (yoff * snappedH);
	}

	public function restartAnim()
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

		FlxTween.tween(this, {x: this.x - (xoff * 1400), y: this.y - (yoff * 1400)}, 0.5, {ease: FlxEase.expoIn});
	}
}

class SustainNote extends FlxSprite
{
	public static var noteGraphics:Map<String, FlxFramesCollection> = new Map<String, FlxFramesCollection>();

	public var data:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float;
	public var beat:Float;
	public var column:Int;
	public var strumColumn:Int;
	public var noteType:String = "default";
	public var sustainLength:Float;
	public var canBeHit:Bool = false;
	public var missed:Bool = false;
	public var isBeingHit:Bool = false;
	public var lastHitTime:Float = 0;
	public var hitTimer:Float = 0;
	public var hitLimit:Float = 100;
	public var passedHitLimit:Bool = false;

	public var typeData:NoteTypeData = null;
	public var noteskinOverride:String = "";
	public var noteskinType:String = "";
	public var noteskinData:NoteskinTypedef = null;
	public var noteColor:String = "";
	public var noteShape:String = "";
	public var parent:Note = null;
	public var noteAng:Float = 0;
	public var splash:FlxSprite = null;

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
		lastHitTime = strumTime;
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
			if (hh > 16384)			// For some reason, any graphic taller than this number will appear pitch black
				hh = 16384;

			makeGraphic(ww, hh, FlxColor.TRANSPARENT, true, key);
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

		scale.set(noteskinData.scale * StrumNote.noteScale, actualHeight / height);
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

		var oldScale:Float = 1;
		if (noteskinData != null)
			oldScale = noteskinData.scale;
		noteskinData = Noteskins.getData(noteskinOverride, noteskinType);
		if (!(FlxG.state is PlayState) && noteskinData.scale < 0)
			noteskinData.scale *= -oldScale;
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
		if (typeData.animation != null)
			hitAnim = typeData.animation + animationSuffix;
		if (typeData.animationMiss != null)
			missAnim = typeData.animationMiss + animationSuffix;
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

		var w:Float = width / 2;
		var snappedH:Float = h;
		if (noteskinData.pixelPerfect)
			snappedH = Math.round(h / scale.x) * scale.x;

		var cX:Float = strum.x + (strum.myW / 2) - (xoff * snappedH);
		var cY:Float = strum.y + (strum.myH / 2) - (yoff * snappedH);
		if (parent != null && parent.alive)
		{
			cX = parent.getGraphicMidpoint().x - parent.offset.x;
			cY = parent.getGraphicMidpoint().y - parent.offset.y;
		}
		if (calcX)
			x = cX + (yoff * w);
		if (calcY)
			y = cY - (xoff * w);
	}

	public function restartAnim()
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
		var w:Float = width / 2;

		FlxTween.tween(this, {x: this.x - (xoff * 1400) - (yoff * w), y: this.y - (yoff * 1400) + (xoff * w)}, 0.5, {ease: FlxEase.expoIn});
	}
}

class NoteSplash extends FlxSprite
{
	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (animation.curAnim.finished)
			kill();
	}
}