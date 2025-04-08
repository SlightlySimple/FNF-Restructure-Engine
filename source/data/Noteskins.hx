package data;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import objects.Note;
import objects.StrumNote;

using StringTools;

typedef NoteskinAnimation =
{
	var ?asset:Null<Int>;
	var name:String;
	var ?prefix:String;
	var fps:Int;
	var loop:Bool;
	var ?indices:Array<Int>;
	var ?offsets:Array<Int>;
}

typedef NoteskinSlot =
{
	var color:String;
	var ?shape:String;
	var staticAnim:String;
	var pressAnim:String;
	var angle:Int;
	var ?unbakedAngle:Null<Int>;
}

typedef NoteskinColor =
{
	var color:String;
	var ?shape:String;
	var noteAnim:String;
	var holdAnim:String;
	var endAnim:String;
	var slotAnim:String;
	var angle:Int;
}

typedef NoteskinQuant =
{
	var beat:Int;
	var color:String;
}

typedef NoteskinSplashColor =
{
	var color:String;
	var alpha:Float;
	var ?blend:String;
	var anims:Array<String>;
	var holdAnim:String;
	var holdEndAnims:Array<String>;
}

typedef NoteskinTypedef =
{
	var ?force:Null<Bool>;
	var ?fallback:String;
	var ?skinName:String;
	var ?id:String;
	var ?assets:Array<Array<Dynamic>>;
	var antialias:Bool;
	var pixelPerfect:Null<Bool>;
	var scale:Float;
	var noteSize:Null<Int>;
	var ?colorStrums:Null<Bool>;
	var sustainOpacity:Null<Float>;
	var sustainGap:Null<Int>;
	var animations:Array<NoteskinAnimation>;
	var slots:Array<NoteskinSlot>;
	var colors:Array<NoteskinColor>;
	var quantization:Array<NoteskinQuant>;
	var allowSplashes:Bool;
	var ?splashes:NoteskinSplashes;
}

typedef NoteskinSplashes =
{
	var ?assets:Array<Array<Dynamic>>;
	var antialias:Null<Bool>;
	var scale:Null<Float>;
	var sustainScale:Null<Float>;
	var sustainEndScale:Null<Float>;
	var animations:Array<NoteskinAnimation>;
	var colors:Array<NoteskinSplashColor>;
}

typedef NoteskinData =
{
	var types:Array<String>;
	var typeDefs:Array<NoteskinTypedef>;
	var notSelectable:Bool;
}

class Noteskins
{
	public static var noteskinName:String = "Arrows";
	public static var noteskinNames:Array<String> = [];
	public static var noteskinData:Map<String, NoteskinData>;
	public static var sparrows:Map<String, Bool>;

	public static function loadNoteskins()
	{
		noteskinData = new Map<String, NoteskinData>();
		noteskinNames = Paths.listFiles("images/noteskins/", "");

		for (i in 0...noteskinNames.length)
		{
			var skinTypes:Array<String> = Paths.listFiles("images/noteskins/" + noteskinNames[i] + "/", ".json");
			var newNoteskin:NoteskinData = { types: skinTypes, typeDefs: [], notSelectable: false };
			if (Paths.jsonImagesExists("noteskins/" + noteskinNames[i]))
			{
				var skinData:NoteskinData = cast Paths.jsonImages("noteskins/" + noteskinNames[i]);
				newNoteskin.notSelectable = skinData.notSelectable;
			}
			for (type in skinTypes)
			{
				var typeDef:NoteskinTypedef = cast Paths.jsonImages("noteskins/" + noteskinNames[i] + "/" + type);
				typeDef.skinName = noteskinNames[i];
				typeDef.id = type;

				if (typeDef.pixelPerfect == null)
					typeDef.pixelPerfect = false;

				if (typeDef.colorStrums == null)
					typeDef.colorStrums = true;

				if (typeDef.sustainOpacity == null || typeDef.sustainOpacity <= 0)
					typeDef.sustainOpacity = 0.6;

				if (typeDef.sustainGap == null)
					typeDef.sustainGap = 1;

				if (typeDef.assets == null || typeDef.assets.length <= 0)
					typeDef.assets = [[type]];

				for (i in 0...typeDef.animations.length)
				{
					if (typeDef.animations[i].asset == null)
						typeDef.animations[i].asset = 0;
				}
				for (i in 0...typeDef.slots.length)
				{
					if (typeDef.slots[i].shape == null)
						typeDef.slots[i].shape = "";
					if (typeDef.slots[i].unbakedAngle == null)
						typeDef.slots[i].unbakedAngle = 0;
				}
				for (i in 0...typeDef.colors.length)
				{
					if (typeDef.colors[i].shape == null)
						typeDef.colors[i].shape = "";
				}
				newNoteskin.typeDefs.push(typeDef);

				if (typeDef.splashes == null)
					typeDef.allowSplashes = false;
				else
				{
					typeDef.allowSplashes = true;

					if (typeDef.splashes.antialias == null)
						typeDef.splashes.antialias = typeDef.antialias;

					if (typeDef.splashes.scale == null)
						typeDef.splashes.scale = typeDef.scale;

					if (typeDef.splashes.sustainEndScale == null)
						typeDef.splashes.sustainEndScale = typeDef.splashes.scale;

					if (typeDef.splashes.sustainScale == null)
						typeDef.splashes.sustainScale = typeDef.splashes.sustainEndScale;

					for (i in 0...typeDef.splashes.animations.length)
					{
						if (typeDef.splashes.animations[i].asset == null)
							typeDef.splashes.animations[i].asset = 0;
					}
				}
			}
			noteskinData.set(noteskinNames[i], newNoteskin);
		}
		sparrows = new Map<String, Bool>();
	}

	public static function noteskinOptions()
	{
		var ret:Array<String> = [];
		for (s in Paths.listFiles("images/noteskins/", ""))
		{
			if (Paths.jsonImagesExists("noteskins/" + s))
			{
				var skinData:NoteskinData = cast Paths.jsonImages("noteskins/" + s);
				if (!skinData.notSelectable)
					ret.push(s);
			}
			else
				ret.push(s);
		}
		return ret;
	}

	public static function getTypedef(data:NoteskinData, type:String):NoteskinTypedef
	{
		for (def in data.typeDefs)
		{
			if (def.id == type)
				return def;
		}

		return null;
	}

	public static function getData(skin:String, type:String):NoteskinTypedef
	{
		var readingSkin:String = noteskinName;
		if (noteskinData.exists(noteskinName + "--" + skin) && skin != noteskinName)
			readingSkin = noteskinName + "--" + skin;
		else if (noteskinData.exists(skin) && skin != noteskinName)
			readingSkin = skin;

		var skinData:NoteskinData = noteskinData[readingSkin];

		if (skinData.types.contains(type))
			return getTypedef(skinData, type);

		if (noteskinData[noteskinNames[0]].types.contains(type))
		{
			var td:NoteskinTypedef = getTypedef(noteskinData[noteskinNames[0]], type);
			if (td.force)
				return td;
			if (td.fallback != null && skinData.types.contains(td.fallback))
				return getTypedef(skinData, td.fallback);
		}

		return getTypedef(skinData, skinData.types[0]);
	}

	public static function getAsset(skindef:NoteskinTypedef, ?assetIndex:Int = 0):Array<Dynamic>
	{
		var assetArray:Array<Array<Dynamic>> = skindef.assets;
		if (assetIndex < assetArray.length)
			return assetArray[assetIndex];
		return assetArray[0];
	}

	public static function getFrames(skindef:NoteskinTypedef, ?assetIndex:Int = 0):FlxFramesCollection
	{
		var asset:Array<Dynamic> = getAsset(skindef, assetIndex);
		var path:String = "noteskins/" + asset[0];
		if (Paths.imageExists("noteskins/" + skindef.skinName + "/" + asset[0]))
			path = "noteskins/" + skindef.skinName + "/" + asset[0];
		if (!sparrows.exists(path))
			sparrows[path] = Paths.sparrowExists(path);	// This check is somewhat resource intensive, so we store it's return value each time to ensure we only have to do it once per asset
		if (sparrows[path])
			return Paths.sparrow(path);
		return Paths.tiles(path, asset[1], asset[2]);
	}

	public static function addAnimation(note:FlxSprite, animName:String, skindef:NoteskinTypedef, animation:String)
	{
		var animData:NoteskinAnimation = null;
		for (i in 0...skindef.animations.length)
		{
			if (animation == skindef.animations[i].name)
				animData = skindef.animations[i];
		}

		if (note.frames == null)
			note.frames = getFrames(skindef, animData.asset);

		if (animData.prefix != null && animData.prefix != "")
			note.animation.addByPrefix(animName, animData.prefix, animData.fps, animData.loop);
		else
			note.animation.add(animName, animData.indices, animData.fps, animData.loop);
	}

	public static function getNoteColor(skindef:NoteskinTypedef, column:Int, beat:Float):String
	{
		var totalColumns:Int = skindef.slots.length;
		var color:String = skindef.slots[column % totalColumns].color;

		if (Options.options.quantization && skindef.quantization != null)
		{
			var beatRow = Math.round(beat * 48);
			for (q in skindef.quantization)
			{
				if (beatRow % (192 / q.beat) == 0)
					return q.color;
			}
			return skindef.quantization[skindef.quantization.length - 1].color;
		}

		return color;
	}

	public static function getNoteShape(skindef:NoteskinTypedef, column:Int):String
	{
		var totalColumns:Int = skindef.slots.length;
		var shape:String = skindef.slots[column % totalColumns].shape;

		return shape;
	}

	public static function addNoteAnim(note:FlxSprite, skindef:NoteskinTypedef, color:String, shape:String):Int
	{
		var colorAnim:Int = 0;
		var animName:String = "idle";

		for (i in 0...skindef.colors.length)
		{
			if (skindef.colors[i].color == color && skindef.colors[i].shape == shape)
				colorAnim = i;
		}

		var whichAnim:String = skindef.colors[colorAnim].noteAnim;

		addAnimation(note, animName, skindef, whichAnim);
		return cast skindef.colors[colorAnim].angle;
	}

	public static function addSustainAnim(note:FlxSprite, type:String, skindef:NoteskinTypedef, color:String, shape:String):Int
	{
		var colorAnim:Int = 0;

		for (i in 0...skindef.colors.length)
		{
			if (skindef.colors[i].color == color && skindef.colors[i].shape == shape)
				colorAnim = i;
		}

		var whichAnim:String = skindef.colors[colorAnim].holdAnim;
		if (type == "holdEnd")
			whichAnim = skindef.colors[colorAnim].endAnim;

		addAnimation(note, type, skindef, whichAnim);
		return cast skindef.colors[colorAnim].angle;
	}

	public static function addSlotAnims(note:FlxSprite, skindef:NoteskinTypedef, column:Int)
	{
		var totalColumns:Int = skindef.slots.length;
		addAnimation(note, "static", skindef, skindef.slots[column % totalColumns].staticAnim);
		addAnimation(note, "press", skindef, skindef.slots[column % totalColumns].pressAnim);

		for (c in skindef.colors)
		{
			if (c.shape == skindef.slots[column % totalColumns].shape)
				addAnimation(note, "confirm" + c.color, skindef, c.slotAnim);
		}
	}



	public static function getSplashAsset(skindef:NoteskinTypedef, ?assetIndex:Int = 0):Array<Dynamic>
	{
		var assetArray:Array<Array<Dynamic>> = skindef.splashes.assets;
		if (assetIndex < assetArray.length)
			return assetArray[assetIndex];
		return assetArray[0];
	}

	public static function getSplashFrames(skindef:NoteskinTypedef, ?assetIndex:Int = 0):FlxFramesCollection
	{
		var asset:Array<Dynamic> = getSplashAsset(skindef, assetIndex);
		var path:String = "ui/note_splashes/" + asset[0];
		if (!sparrows.exists(path))
			sparrows[path] = Paths.sparrowExists(path);	// This check is somewhat resource intensive, so we store it's return value each time to ensure we only have to do it once per asset
		if (sparrows[path])
			return Paths.sparrow(path);
		return Paths.tiles(path, asset[1], asset[2]);
	}

	public static function doSplash(splash:FlxSprite, skindef:NoteskinTypedef, color:String, ?isSustain:Bool = false):Bool
	{
		splash.antialiasing = skindef.splashes.antialias;

		var colorAnim:Int = 0;

		for (i in 0...skindef.splashes.colors.length)
		{
			if (skindef.splashes.colors[i].color == color)
				colorAnim = i;
		}

		splash.alpha = skindef.splashes.colors[colorAnim].alpha;
		if (skindef.splashes.colors[colorAnim].blend != null)
			splash.blend = skindef.splashes.colors[colorAnim].blend;
		else
			splash.blend = "normal";
		if (isSustain)
			splash.scale.set(skindef.splashes.sustainEndScale * StrumNote.noteScale, skindef.splashes.sustainEndScale * StrumNote.noteScale);
		else
			splash.scale.set(skindef.splashes.scale * StrumNote.noteScale, skindef.splashes.scale * StrumNote.noteScale);
		var animArray:Array<String> = (isSustain ? skindef.splashes.colors[colorAnim].holdEndAnims : skindef.splashes.colors[colorAnim].anims);
		if (animArray != null && animArray.length > 0)
		{
			var whichAnim:String = FlxG.random.getObject(animArray);

			var animData:NoteskinAnimation = null;
			for (i in 0...skindef.splashes.animations.length)
			{
				if (whichAnim == skindef.splashes.animations[i].name)
					animData = skindef.splashes.animations[i];
			}

			splash.frames = getSplashFrames(skindef, animData.asset);
			if (animData.prefix != null && animData.prefix != "")
				splash.animation.addByPrefix("idle", animData.prefix, animData.fps, false);
			else
				splash.animation.add("idle", animData.indices, animData.fps, false);
			splash.animation.play("idle");
			splash.animation.finishCallback = function(anim:String) { splash.kill(); }
			splash.updateHitbox();

			if (animData.offsets != null)
			{
				splash.offset.set(animData.offsets[0], animData.offsets[1]);
				splash.origin.set(animData.offsets[0], animData.offsets[1]);
			}
			else
			{
				splash.x -= splash.width / 2;
				splash.y -= splash.height / 2;
			}

			return true;
		}
		return false;
	}

	public static function doSustainSplash(splash:FlxSprite, skindef:NoteskinTypedef, color:String):Bool
	{
		splash.antialiasing = skindef.splashes.antialias;

		var colorAnim:Int = 0;

		for (i in 0...skindef.splashes.colors.length)
		{
			if (skindef.splashes.colors[i].color == color)
				colorAnim = i;
		}

		splash.scale.set(skindef.splashes.sustainScale * StrumNote.noteScale, skindef.splashes.sustainEndScale * StrumNote.noteScale);
		var whichAnim:String = skindef.splashes.colors[colorAnim].holdAnim;

		if (whichAnim != null)
		{
			var animData:NoteskinAnimation = null;
			for (i in 0...skindef.splashes.animations.length)
			{
				if (whichAnim == skindef.splashes.animations[i].name)
					animData = skindef.splashes.animations[i];
			}

			splash.frames = getSplashFrames(skindef, animData.asset);
			if (animData.prefix != null && animData.prefix != "")
				splash.animation.addByPrefix("idle", animData.prefix, animData.fps, animData.loop);
			else
				splash.animation.add("idle", animData.indices, animData.fps, animData.loop);
			splash.animation.play("idle");
			splash.updateHitbox();

			if (animData.offsets != null)
			{
				splash.offset.set(animData.offsets[0], animData.offsets[1]);
				splash.origin.set(animData.offsets[0], animData.offsets[1]);
			}
			else
			{
				splash.x -= splash.width / 2;
				splash.y -= splash.height / 2;
			}

			return true;
		}
		return false;
	}
}