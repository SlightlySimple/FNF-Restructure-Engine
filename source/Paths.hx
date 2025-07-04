package;

import flixel.FlxG;
import openfl.utils.Assets;
import openfl.system.System;
import openfl.display.BitmapData;
import flash.geom.Rectangle;
import sys.FileSystem;
import sys.io.File;
import lime.app.Application;
import haxe.Json;
import haxe.xml.Access;
import flixel.system.FlxAssets;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import data.Options;
import game.PlayState;

using StringTools;

class Paths
{
	static var assets:Array<String> = [];
	static var cachedTextAssets:Map<String, String> = new Map<String, String>();
	static var censorCheck:Array<String> = [];
	static var sparrowCheck:Map<String, String> = new Map<String, String>();
	static var DEFAULT_IMAGE:String = "assets/images/logo/default.png";

	public static function file(path:String, ext:String, ?allowCensor:Bool = true):String
	{
		if (Options.options != null)
		{
			if (Options.options.language != "")
			{
				if (allowCensor && !Options.options.naughtiness && exists("languages/" + Options.options.language + "/" + path + "Censor" + ext, true))
					return "assets/languages/" + Options.options.language + "/" + path + "Censor" + ext;
				if (exists("languages/" + Options.options.language + "/" + path + ext, true))
					return "assets/languages/" + Options.options.language + "/" + path + ext;
			}
			if (allowCensor && !Options.options.naughtiness && exists(path + "Censor" + ext, true))
				return "assets/" + path + "Censor" + ext;
		}
		return "assets/" + path + ext;
	}

	public static function modFile(path:String, ext:String):String
	{
		#if ALLOW_MODS
		for (mod in ModLoader.modListLoaded)
		{
			if (Options.options != null)
			{
				if (Options.options.language != "")
				{
					if (!Options.options.naughtiness && FileSystem.exists("mods/" + mod + "/languages/" + Options.options.language + "/" + path + "Censor" + ext))
						return "mods/" + mod + "/languages/" + Options.options.language + "/" + path + "Censor" + ext;
					if (FileSystem.exists("mods/" + mod + "/languages/" + Options.options.language + "/" + path + ext))
						return "mods/" + mod + "/languages/" + Options.options.language + "/" + path + ext;
				}
				if (!Options.options.naughtiness && FileSystem.exists("mods/" + mod + "/" + path + "Censor" + ext))
					return "mods/" + mod + "/" + path + "Censor" + ext;
			}
			if (FileSystem.exists("mods/" + mod + "/" + path + ext))
				return "mods/" + mod + "/" + path + ext;
		}
		#end

		return file(path, ext);
	}

	public static function raw(path:String, ?includeAssets:Bool = true):String
	{
		var finalPath:String = (includeAssets ? "assets/" : "") + path;
		if (cachedTextAssets.exists(finalPath))
			return cachedTextAssets[finalPath];
		var rawFileData:String = Assets.getText(finalPath);
		cachedTextAssets[finalPath] = rawFileData;
		return rawFileData;
	}

	public static function rawFromMod(path:String, mod:String):String
	{
		var truePath:String = "assets/"+path;
		if (mod.trim() != "")
			truePath = "mods/"+mod+"/"+path;
		var rawFileData:String = File.getContent(truePath);
		return rawFileData;
	}

	public static function text(path:String):String
	{
		return raw(file("data/" + path, ".txt"), false);
	}

	public static function textData(path:String):String
	{
		return raw("data/" + path + ".txt");
	}

	public static function textImages(path:String):String
	{
		return raw("images/" + path + ".txt");
	}

	public static function json(path:String):Dynamic
	{
		return jsonDirect("data/" + path);
	}

	public static function jsonImages(path:String):Dynamic
	{
		return jsonDirect("images/" + path);
	}

	public static function jsonDirect(path:String):Dynamic
	{
		var rawFileData:String = raw(file(path, ".json"), false);
		var ret:Dynamic = null;
		try { ret = Json.parse(rawFileData); }
		catch(e) { Application.current.window.alert("There was an error parsing the file \""+path+".json\":\n" + e.message, "Alert"); return null; }
		return ret;
	}

	public static function sm(path:String):String
	{
		return raw("sm/" + path + ".sm");
	}

	public static function image(path:String):FlxGraphic
	{
		if (FlxG.bitmap.checkCache(imagePath(path)))
			return FlxG.bitmap.get(imagePath(path));
		if (imageExists(path))
			return FlxG.bitmap.add(Assets.getBitmapData(imagePath(path)), false, imagePath(path));
		return FlxGraphic.fromAssetKey(DEFAULT_IMAGE);
	}

	public static function imagePath(path:String):String
	{
		return file("images/" + path, ".png");
	}

	public static function imageSong(path:String):FlxGraphic
	{
		if (FlxG.bitmap.checkCache(imageSongPath(path)))
			return FlxG.bitmap.get(imageSongPath(path));
		if (imageSongExists(path))
			return FlxG.bitmap.add(Assets.getBitmapData(imageSongPath(path)), false, imageSongPath(path));
		return FlxGraphic.fromAssetKey(DEFAULT_IMAGE);
	}

	public static function imageSongPath(path:String):String
	{
		if (FlxG.state is PlayState)
			return file("data/songs/" + PlayState.songId + "/images/" + path, ".png");
		return "";
	}

	public static function sound(path:String):String
	{
		return file("sounds/" + path, ".ogg");
	}

	public static function music(path:String):String
	{
		return file("music/" + path, ".ogg");
	}

	public static function hitsound():String
	{
		if (Options.options.hitsound == "None")
			return "";
		return "assets/hitsounds/" + Options.options.hitsound + ".ogg";
	}

	public static function song(path:String, asset:String):String
	{
		if (exists("data/songs/" + path + "/" + asset + ".ogg"))
			return file("data/songs/" + path + "/" + asset, ".ogg");
		return file("songs/" + path + "/" + asset, ".ogg");
	}

	public static function smSong(folder:String, path:String):String
	{
		var pathArray:Array<String> = folder.replace("\\","/").split("/");
		pathArray.pop();
		return "assets/sm/" + pathArray.join("/") + "/" + path.replace(".mp3",".ogg");
	}

	public static function tiles(path:String, tilesX:Int, tilesY:Int):FlxTileFrames
	{
		var graphic:FlxGraphic = image(path);
		var w:Int = Std.int(graphic.width / tilesX);
		var h:Int = Std.int(graphic.height / tilesY);
		return FlxTileFrames.fromGraphic(graphic, FlxPoint.get(w, h));
	}

	static function fromSparrow(Source:FlxGraphicAsset, Description:String):FlxAtlasFrames		// This is an exact copy of the function from FlxAtlasFrames without the Assets check
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(Source);
		if (graphic == null)
			return null;

		// No need to parse data again
		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
		if (frames != null)
			return frames;

		if (graphic == null || Description == null)
			return null;

		frames = new FlxAtlasFrames(graphic);

		var data:Access = new Access(Xml.parse(Description).firstElement());

		for (texture in data.nodes.SubTexture)
		{
			var name = texture.att.name;
			var trimmed = texture.has.frameX;
			var rotated = (texture.has.rotated && texture.att.rotated == "true");
			var flipX = (texture.has.flipX && texture.att.flipX == "true");
			var flipY = (texture.has.flipY && texture.att.flipY == "true");

			var rect = FlxRect.get(Std.parseFloat(texture.att.x), Std.parseFloat(texture.att.y), Std.parseFloat(texture.att.width),
				Std.parseFloat(texture.att.height));

			var size = if (trimmed)
			{
				new Rectangle(Std.parseInt(texture.att.frameX), Std.parseInt(texture.att.frameY), Std.parseInt(texture.att.frameWidth),
					Std.parseInt(texture.att.frameHeight));
			}
			else
			{
				new Rectangle(0, 0, rect.width, rect.height);
			}

			var angle = rotated ? FlxFrameAngle.ANGLE_NEG_90 : FlxFrameAngle.ANGLE_0;

			var offset = FlxPoint.get(-size.left, -size.top);
			var sourceSize = FlxPoint.get(size.width, size.height);

			if (rotated && !trimmed)
				sourceSize.set(size.height, size.width);

			frames.addAtlasFrame(rect, sourceSize, offset, name, angle, flipX, flipY);
		}

		return frames;
	}

	public static function sparrow(path:String):FlxFramesCollection
	{
		if (sparrowCheck.exists(path))
		{
			if (sparrowCheck[path] == "txt")
				return FlxAtlasFrames.fromSpriteSheetPacker(image(path), textImages(path));
			return fromSparrow(image(path), raw(file("images/" + path, ".xml"), false));
		}

		if (sparrowExists(path))
		{
			if (exists("images/" + path + ".txt") && !exists("images/" + path + ".xml"))
			{
				sparrowCheck[path] = "txt";
				return FlxAtlasFrames.fromSpriteSheetPacker(image(path), textImages(path));
			}
			sparrowCheck[path] = "xml";
			return fromSparrow(image(path), raw(file("images/" + path, ".xml"), false));
		}
		Application.current.window.alert("File \"images/" + path + ".xml\" does not exist", "Alert");
		var graphic:FlxGraphic = FlxGraphic.fromAssetKey(DEFAULT_IMAGE);
		return FlxTileFrames.fromGraphic(graphic, FlxPoint.get(Std.int(graphic.width), Std.int(graphic.height)));
	}

	public static function sparrowSong(path:String):FlxFramesCollection
	{
		var basePath:String = "data/songs/" + PlayState.songId + "/images/" + path;
		if (sparrowSongExists(path))
		{
			if (exists(basePath + ".txt") && !exists(basePath + ".xml"))
				return FlxAtlasFrames.fromSpriteSheetPacker(imageSong(path), raw(basePath + ".txt"));
			return fromSparrow(imageSong(path), raw(file(basePath, ".xml"), false));
		}
		Application.current.window.alert("File \"data/songs/" + PlayState.songId + "/images/" + path + ".xml\" does not exist", "Alert");
		var graphic:FlxGraphic = FlxGraphic.fromAssetKey(DEFAULT_IMAGE);
		return FlxTileFrames.fromGraphic(graphic, FlxPoint.get(Std.int(graphic.width), Std.int(graphic.height)));
	}

	public static function sparrowFrames(path:String):Array<String>
	{
		var returnArray:Array<String> = [];
		if (exists("images/" + path + ".txt") && !exists("images/" + path + ".xml"))
		{
			var data:String = raw("images/" + path + ".txt");
			data = data.replace("\r","").replace("\t","");
			var trimmedAnimData:Array<String> = data.split("\n");
			for (t in trimmedAnimData)
			{
				var newAnim:String = t.split(" = ")[0];
				returnArray.push(newAnim);
			}
		}
		else
		{
			var textData:String = Paths.raw("images/" + path + ".xml");
			var data:Access = new Access(Xml.parse(textData).firstElement());
			for (texture in data.nodes.SubTexture)
			{
				var newAnim:String = texture.att.name;
				returnArray.push(newAnim);
			}
		}
		return returnArray;
	}

	public static function sparrowAnimations(path:String):Array<String>
	{
		var returnArray:Array<String> = [];
		if (exists("images/" + path + ".txt") && !exists("images/" + path + ".xml"))
		{
			var data:String = raw("images/" + path + ".txt");
			data = data.replace("\r","").replace("\t","");
			var trimmedAnimData:Array<String> = data.split("\n");
			for (t in trimmedAnimData)
			{
				var newAnim:String = t.split(" = ")[0];
				newAnim = newAnim.substr(0, newAnim.lastIndexOf("_")+1);
				if (!returnArray.contains(newAnim))
					returnArray.push(newAnim);
			}
		}
		else
		{
			var textData:String = Paths.raw("images/" + path + ".xml");
			var data:Access = new Access(Xml.parse(textData).firstElement());
			for (texture in data.nodes.SubTexture)
			{
				var newAnim:String = texture.att.name;
				newAnim = newAnim.substr(0, newAnim.length-4);
				if (!returnArray.contains(newAnim))
					returnArray.push(newAnim);
			}
		}
		for (i in 0...returnArray.length)
		{
			for (p in returnArray)
			{
				if (p.indexOf(returnArray[i]) == 0 && p != returnArray[i])
					returnArray[i] += "0";
			}
		}
		return returnArray;
	}

	public static function atlas(path:String):String
	{
		return "assets/images/" + path;
	}

	public static function icon(path:String):String
	{
		if (path.indexOf("/") > -1)
		{
			var newPath:String = path.substring(0, path.lastIndexOf("/")+1) + "icon-" + path.substring(path.lastIndexOf("/")+1, path.length);
			if (exists("images/icons/" + newPath + ".png"))
				return "assets/images/icons/" + newPath + ".png";

			newPath = newPath.substring(0, newPath.indexOf("/")+1) + "icons/" + newPath.substring(newPath.indexOf("/")+1, newPath.length);
			if (exists("images/" + newPath + ".png"))
				return "assets/images/" + newPath + ".png";

			newPath = path.substring(0, path.indexOf("/")+1) + "icons/" + path.substring(path.indexOf("/")+1, path.length);
			if (exists("images/" + newPath + ".png"))
				return "assets/images/" + newPath + ".png";
		}
		else
		{
			if (exists("images/icons/icon-" + path + ".png"))
				return "assets/images/icons/icon-" + path + ".png";
		}
		return "assets/images/icons/" + path + ".png";
	}

	public static function hscript(path:String):Dynamic
	{
		var rawFileData:String = Assets.getText("assets/" + path + ".hscript");
		return rawFileData;
	}

	public static function font(path:String):String
	{
		var p:String = path;
		if (path.toLowerCase().endsWith(".ttf") || path.toLowerCase().endsWith(".otf"))
		p = path.substr(0, path.length - 4);

		#if ALLOW_MODS
		for (mod in ModLoader.modListLoaded)
		{
			if (FileSystem.exists("mods/" + mod + "/fonts/" + p + ".ttf"))
				return "mods/" + mod + "/fonts/" + p + ".ttf";
			if (FileSystem.exists("mods/" + mod + "/fonts/" + p + ".otf"))
				return "mods/" + mod + "/fonts/" + p + ".otf";
		}
		#end

		if (FileSystem.exists("assets/fonts/" + p + ".ttf"))
			return "assets/fonts/" + p + ".ttf";
		return "assets/fonts/" + p + ".otf";
	}

	public static function video(path:String):String
	{
		return modFile("videos/" + path, ".mp4");
	}

	public static function lua(path:String):String
	{
		return modFile(path, ".lua");
	}

	public static function shader(path:String, ?isVert:Bool = false):String
	{
		return raw("shaders/" + path + (isVert ? ".vert" : ".frag"));
	}

	public static function shaderImage(path:String, ?absolute:Bool = false):BitmapData
	{
		if (absolute)
			return BitmapData.fromFile(modFile(path, ".png"));
		return BitmapData.fromFile(modFile("images/" + path, ".png"));
	}

	public static function exists(path:String, ?isCensorCheck:Bool = false):Bool
	{
		if (isCensorCheck && censorCheck.contains("assets/" + path))
			return false;

		if (assets.contains("assets/" + path))
			return true;
		if (Assets.exists("assets/" + path))
		{
			assets.push("assets/" + path);
			return true;
		}
		if (isCensorCheck)
			censorCheck.push("assets/" + path);

		return false;
	}

	public static function textExists(path:String):Bool
	{
		return exists("data/" + path + ".txt");
	}

	public static function textImagesExists(path:String):Bool
	{
		return exists("images/" + path + ".txt");
	}

	public static function jsonExists(path:String):Bool
	{
		return exists("data/" + path + ".json");
	}

	public static function jsonImagesExists(path:String):Bool
	{
		return exists("images/" + path + ".json");
	}

	public static function smExists(path:String):Bool
	{
		return exists("sm/" + path + ".sm");
	}

	public static function imageExists(path:String):Bool
	{
		return exists("images/" + path + ".png");
	}

	public static function imageSongExists(path:String):Bool
	{
		if (FlxG.state is PlayState)
			return exists("data/songs/" + PlayState.songId + "/images/" + path + ".png");
		return false;
	}

	public static function soundExists(path:String):Bool
	{
		return exists("sounds/" + path + ".ogg");
	}

	public static function musicExists(path:String):Bool
	{
		return exists("music/" + path + ".ogg");
	}

	public static function songExists(path:String, file:String):Bool
	{
		return exists("data/songs/" + path + "/" + file + ".ogg") || exists("songs/" + path + "/" + file + ".ogg");
	}

	public static function sparrowExists(path:String):Bool
	{
		if (sparrowCheck.exists(path))
			return true;
		return exists("images/" + path + ".xml") || exists("images/" + path + ".txt");
	}

	public static function sparrowSongExists(path:String):Bool
	{
		if (FlxG.state is PlayState)
			return exists("data/songs/" + PlayState.songId + "/images/" + path + ".xml") || exists("data/songs/" + PlayState.songId + "/images/" + path + ".txt");
		return false;
	}

	public static function iconExists(path:String, ?includeJSON:Bool = true):Bool
	{
		if (path.indexOf("/") > -1)
		{
			var newPath:String = path.substring(0, path.lastIndexOf("/")+1) + "icon-" + path.substring(path.lastIndexOf("/")+1, path.length);
			if (exists("images/icons/" + newPath + ".png") || (includeJSON && exists("images/icons/" + newPath + ".json")))
				return true;

			newPath = newPath.substring(0, newPath.indexOf("/")+1) + "icons/" + newPath.substring(newPath.indexOf("/")+1, newPath.length);
			if (exists("images/" + newPath + ".png") || (includeJSON && exists("images/" + newPath + ".json")))
				return true;

			newPath = path.substring(0, path.indexOf("/")+1) + "icons/" + path.substring(path.indexOf("/")+1, path.length);
			if (exists("images/" + newPath + ".png") || (includeJSON && exists("images/" + newPath + ".json")))
				return true;
		}
		else
		{
			if (exists("images/icons/icon-" + path + ".png") || (includeJSON && exists("images/icons/icon-" + path + ".json")))
				return true;
		}
		return (exists("images/icons/" + path + ".png") || (includeJSON && exists("images/icons/" + path + ".json")));
	}

	public static function hscriptExists(path:String):Bool
	{
		return exists(path + ".hscript");
	}

	public static function cacheGraphic(graphic:String)
	{
		if (imageExists(graphic))
		{
			var cachedGraphic = FlxG.bitmap.add(Assets.getBitmapData(imagePath(graphic)), false, imagePath(graphic));
			cachedGraphic.destroyOnNoUse = false;
		}
	}

	public static function cacheGraphicDirect(graphic:String)
	{
		if (exists(graphic))
		{
			var cachedGraphic = FlxG.bitmap.add(Assets.getBitmapData(graphic), false, graphic);
			cachedGraphic.destroyOnNoUse = false;
		}
	}

	public static function clearCache()
	{
		cachedTextAssets.clear();
		FlxG.bitmap.dumpCache();
		Assets.cache.clear();
		System.gc();
	}

	static function listFilesSort(a:String, b:String):Int
	{
		var upperA:String = a.toUpperCase();
		var upperB:String = b.toUpperCase();

		if (upperA.split("/").length < upperB.split("/").length)
			return -1;
		if (upperA.split("/").length > upperB.split("/").length)
			return 1;

		if (upperA != upperB)
		{
			while (upperA.charAt(0) == upperB.charAt(0))
			{
				upperA = upperA.substr(1);
				upperB = upperB.substr(1);
			}

			while (upperA.charAt(upperA.length-1) == upperB.charAt(upperB.length-1))
			{
				upperA = upperA.substr(0, upperA.length-1);
				upperB = upperB.substr(0, upperB.length-1);
			}

			if (Std.parseInt(upperA) != null && Std.parseInt(upperB) != null)
			{
				if (Std.parseInt(upperA) < Std.parseInt(upperB))
					return -1;
				if (Std.parseInt(upperA) > Std.parseInt(upperB))
					return 1;
			}
		}

		if (upperA < upperB)
			return -1;
		if (upperA > upperB)
			return 1;
		return 0;
	}

	public static function listFiles(path:String, ext:String):Array<String>
	{
		var returnArray:Array<String> = [];

		var baseArray:Array<String> = [];
		if (FileSystem.isDirectory("assets/" + path))
		{
			for (file in FileSystem.readDirectory("assets/" + path))
			{
				if ((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("assets/" + path + "/" + file)))
					baseArray.push(file.substr(0, file.length - ext.length));
			}
		}
		baseArray.sort(listFilesSort);
		returnArray = returnArray.concat(baseArray);

		#if ALLOW_MODS
		if (ModLoader.packageData != null && FileSystem.isDirectory("packages/" + ModLoader.packagePath + "/content/" + path))
		{
			var packageArray:Array<String> = [];
			for (file in FileSystem.readDirectory("packages/" + ModLoader.packagePath + "/content/" + path))
			{
				if (((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("packages/" + ModLoader.packagePath + "/content/" + path + "/" + file))) && !returnArray.contains(file.substr(0, file.length - ext.length)))
					packageArray.push(file.substr(0, file.length - ext.length));
			}
			packageArray.sort(listFilesSort);
			returnArray = returnArray.concat(packageArray);
		}

		for (mod in ModLoader.modListLoaded)
		{
			var modArray:Array<String> = [];
			if (FileSystem.isDirectory("mods/" + mod + "/" + path))
			{
				for (file in FileSystem.readDirectory("mods/" + mod + "/" + path))
				{
					if (((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + file))) && !returnArray.contains(file.substr(0, file.length - ext.length)))
						modArray.push(file.substr(0, file.length - ext.length));
				}
			}
			modArray.sort(listFilesSort);
			returnArray = returnArray.concat(modArray);
		}
		#end

		return returnArray;
	}

	public static function listFilesSub(path:String, ext:String, ?chain:String = "", ?baseOnly:Bool = false, ?curMod:String = ""):Array<String>
	{
		return listFilesExtSub(path, [ext], chain, baseOnly, curMod);
	}

	public static function listFilesExtSub(path:String, exts:Array<String>, ?chain:String = "", ?baseOnly:Bool = false, ?curMod:String = ""):Array<String>
	{
		var returnArray:Array<String> = [];

		var baseArray:Array<String> = [];
		if (FileSystem.isDirectory("assets/" + path) && (curMod == "" || baseOnly))
		{
			for (file in FileSystem.readDirectory("assets/" + path))
			{
				for (ext in exts)
				{
					if (((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("assets/" + path + "/" + file)))
					&& !baseArray.contains(file.substr(0, file.length - ext.length)))
						baseArray.push(chain + file.substr(0, file.length - ext.length));
				}
			}

			for (dir in FileSystem.readDirectory("assets/" + path))
			{
				if (FileSystem.isDirectory("assets/" + path + "/" + dir))
					baseArray = baseArray.concat(listFilesExtSub(path + "/" + dir, exts, chain + dir + "/", true));
			}
		}
		baseArray.sort(listFilesSort);
		returnArray = returnArray.concat(baseArray);

		#if ALLOW_MODS
		if (!baseOnly)
		{
			if (curMod == "")
			{
				for (mod in ModLoader.modListLoaded)
				{
					var modArray:Array<String> = [];
					if (FileSystem.isDirectory("mods/" + mod + "/" + path))
					{
						var dirs:Array<String> = [];
						for (file in FileSystem.readDirectory("mods/" + mod + "/" + path))
						{
							for (ext in exts)
							{
								if (((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + file)))
								&& !modArray.contains(file.substr(0, file.length - ext.length)) && !returnArray.contains(file.substr(0, file.length - ext.length)))
									modArray.push(chain + file.substr(0, file.length - ext.length));
							}

							if (FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + file))
								dirs.push(file);
						}

						for (dir in dirs)
							modArray = modArray.concat(listFilesExtSub(path + "/" + dir, exts, chain + dir + "/", mod));
					}
					modArray.sort(listFilesSort);
					returnArray = returnArray.concat(modArray);
				}
			}
			else
			{
				var modArray:Array<String> = [];
				if (FileSystem.isDirectory("mods/" + curMod + "/" + path))
				{
					var dirs:Array<String> = [];
					for (file in FileSystem.readDirectory("mods/" + curMod + "/" + path))
					{
						for (ext in exts)
						{
							if (((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("mods/" + curMod + "/" + path + "/" + file)))
							&& !modArray.contains(file.substr(0, file.length - ext.length)) && !returnArray.contains(file.substr(0, file.length - ext.length)))
								modArray.push(chain + file.substr(0, file.length - ext.length));
						}

						if (FileSystem.isDirectory("mods/" + curMod + "/" + path + "/" + file))
							dirs.push(file);
					}

					for (dir in dirs)
						modArray = modArray.concat(listFilesExtSub(path + "/" + dir, exts, chain + dir + "/", curMod));
				}
				modArray.sort(listFilesSort);
				returnArray = returnArray.concat(modArray);
			}
		}
		#end

		return returnArray;
	}

	static function listFilesAndModsSort(a:Array<String>, b:Array<String>):Int
	{
		return listFilesSort(a[0], b[0]);
	}

	public static function listFilesAndMods(path:String, ext:String):Array<Array<String>>
	{
		var returnArray:Array<Array<String>> = [];

		var baseArray:Array<Array<String>> = [];
		if (FileSystem.isDirectory("assets/" + path))
		{
			for (file in FileSystem.readDirectory("assets/" + path))
			{
				if ((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("assets/" + path + "/" + file)))
					baseArray.push([file.substr(0, file.length - ext.length), ""]);
			}
		}
		baseArray.sort(listFilesAndModsSort);
		returnArray = returnArray.concat(baseArray);

		#if ALLOW_MODS
		for (mod in ModLoader.modListLoaded)
		{
			var modArray:Array<Array<String>> = [];
			if (FileSystem.isDirectory("mods/" + mod + "/" + path))
			{
				for (file in FileSystem.readDirectory("mods/" + mod + "/" + path))
				{
					if ((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + file)))
					{
						if (returnArray.filter(function(a) return a[0] == file.substr(0, file.length - ext.length)).length <= 0)
							modArray.push([file.substr(0, file.length - ext.length), mod]);
					}
				}
			}
			modArray.sort(listFilesAndModsSort);
			returnArray = returnArray.concat(modArray);
		}
		#end

		return returnArray;
	}

	public static function listFilesAndModsSub(path:String, ext:String, ?chain:String = "", ?baseOnly:Bool = false, ?curMod:String = ""):Array<Array<String>>
	{
		var returnArray:Array<Array<String>> = [];

		var baseArray:Array<Array<String>> = [];
		if (FileSystem.isDirectory("assets/" + path) && (curMod == "" || baseOnly))
		{
			for (file in FileSystem.readDirectory("assets/" + path))
			{
				if ((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("assets/" + path + "/" + file)))
				{
					if (baseArray.filter(function(a) return a[0] == file.substr(0, file.length - ext.length)).length <= 0)
						baseArray.push([chain + file.substr(0, file.length - ext.length), ""]);
				}
			}

			for (dir in FileSystem.readDirectory("assets/" + path))
			{
				if (FileSystem.isDirectory("assets/" + path + "/" + dir))
					baseArray = baseArray.concat(listFilesAndModsSub(path + "/" + dir, ext, chain + dir + "/", true));
			}
		}
		baseArray.sort(listFilesAndModsSort);
		returnArray = returnArray.concat(baseArray);

		#if ALLOW_MODS
		if (!baseOnly)
		{
			for (mod in ModLoader.modListLoaded)
			{
				var modArray:Array<Array<String>> = [];
				if (FileSystem.isDirectory("mods/" + mod + "/" + path) && (curMod == "" || curMod == mod))
				{
					for (file in FileSystem.readDirectory("mods/" + mod + "/" + path))
					{
						if ((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + file)))
						{
							if (modArray.filter(function(a) return a[0] == file.substr(0, file.length - ext.length)).length <= 0 && returnArray.filter(function(a) return a[0] == file.substr(0, file.length - ext.length)).length <= 0)
								modArray.push([chain + file.substr(0, file.length - ext.length), mod]);
						}
					}

					for (dir in FileSystem.readDirectory("mods/" + mod + "/" + path))
					{
						if (FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + dir))
							modArray = modArray.concat(listFilesAndModsSub(path + "/" + dir, ext, chain + dir + "/", mod));
					}
				}
				modArray.sort(listFilesAndModsSort);
				returnArray = returnArray.concat(modArray);
			}
		}
		#end

		return returnArray;
	}

	public static function listFilesFromMod(mod:String, path:String, ext:String):Array<String>
	{
		var returnArray:Array<String> = [];

		#if ALLOW_MODS
		var modArray:Array<String> = [];
		if (FileSystem.isDirectory("mods/" + mod + "/" + path))
		{
			for (file in FileSystem.readDirectory("mods/" + mod + "/" + path))
			{
				if (((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + file))) && !returnArray.contains(file.substr(0, file.length - ext.length)))
					modArray.push(file.substr(0, file.length - ext.length));
			}
		}
		modArray.sort(listFilesSort);
		returnArray = returnArray.concat(modArray);
		#end

		return returnArray;
	}

	public static function listFilesFromModSub(mod:String, path:String, ext:String, ?chain:String = ""):Array<String>
	{
		var returnArray:Array<String> = [];

		if (mod == "")
		{
			var baseArray:Array<String> = [];
			if (FileSystem.isDirectory("assets/" + path))
			{
				for (file in FileSystem.readDirectory("assets/" + path))
				{
					if ((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("assets/" + path + "/" + file)))
					{
						if (baseArray.filter(function(a) return a == file.substr(0, file.length - ext.length)).length <= 0)
							baseArray.push(chain + file.substr(0, file.length - ext.length));
					}
				}

				for (dir in FileSystem.readDirectory("assets/" + path))
				{
					if (FileSystem.isDirectory("assets/" + path + "/" + dir))
						baseArray = baseArray.concat(listFilesFromModSub("", path + "/" + dir, ext, chain + dir + "/"));
				}
			}
			baseArray.sort(listFilesSort);
			returnArray = returnArray.concat(baseArray);
		}
		#if ALLOW_MODS
		else
		{
			var modArray:Array<String> = [];
			if (FileSystem.isDirectory("mods/" + mod + "/" + path))
			{
				for (file in FileSystem.readDirectory("mods/" + mod + "/" + path))
				{
					if (((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + file))) && !returnArray.contains(file.substr(0, file.length - ext.length)))
						modArray.push(chain + file.substr(0, file.length - ext.length));
				}

				for (dir in FileSystem.readDirectory("mods/" + mod + "/" + path))
				{
					if (FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + dir))
						modArray = modArray.concat(listFilesFromModSub(mod, path + "/" + dir, ext, chain + dir + "/"));
				}
			}
			modArray.sort(listFilesSort);
			returnArray = returnArray.concat(modArray);
		}
		#end

		return returnArray;
	}
}