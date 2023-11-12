package;

import flixel.FlxG;
import openfl.utils.Assets;
import sys.FileSystem;
import lime.app.Application;
import haxe.Json;
import haxe.xml.Access;
import flixel.system.FlxAssets;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import data.Options;
import game.PlayState;

using StringTools;

class Paths
{
	static var assets:Array<String> = [];
	static var DEFAULT_IMAGE:String = "assets/images/logo/default.png";

	public static function file(path:String, ext:String):String
	{
		if (Options.options != null && !Options.options.naughtiness && exists(path + "Censor" + ext))
			return "assets/" + path + "Censor" + ext;
		return "assets/" + path + ext;
	}

	public static function raw(path:String, ?includeAssets:Bool = true):String
	{
		var rawFileData:String = Assets.getText((includeAssets ? "assets/" : "") + path);
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

	public static function sound(path:String):String
	{
		return "assets/sounds/" + path + ".ogg";
	}

	public static function music(path:String):String
	{
		return "assets/music/" + path + ".ogg";
	}

	public static function hitsound():String
	{
		if (Options.options.hitsound == "None")
			return "";
		return "assets/hitsounds/" + Options.options.hitsound + ".ogg";
	}

	public static function song(path:String, file:String):String
	{
		if (exists("data/songs/" + path + "/" + file + ".ogg"))
			return "assets/data/songs/" + path + "/" + file + ".ogg";
		return "assets/songs/" + path + "/" + file + ".ogg";
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

	public static function sparrow(path:String):FlxFramesCollection
	{
		if (sparrowExists(path))
		{
			if (exists("images/" + path + ".txt") && !exists("images/" + path + ".xml"))
				return FlxAtlasFrames.fromSpriteSheetPacker(image(path), textImages(path));
			return FlxAtlasFrames.fromSparrow(image(path), file("images/" + path, ".xml"));
		}
		Application.current.window.alert("File \"images/" + path + ".xml\" does not exist", "Alert");
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
		#if ALLOW_MODS
		for (mod in ModLoader.modListLoaded)
		{
			if (FileSystem.exists("mods/" + mod + "/videos/" + path + ".mp4"))
				return "mods/" + mod + "/videos/" + path + ".mp4";
		}
		#end

		return "assets/videos/" + path + ".mp4";
	}

	public static function lua(path:String):String
	{
		#if ALLOW_MODS
		for (mod in ModLoader.modListLoaded)
		{
			if (FileSystem.exists("mods/" + mod + "/" + path + ".lua"))
				return "mods/" + mod + "/" + path + ".lua";
		}
		#end

		return "assets/" + path + ".lua";
	}

	public static function shader(path:String):String
	{
		return raw("shaders/" + path + ".frag");
	}

	public static function exists(path:String):Bool
	{
		if (assets.contains("assets/" + path))
			return true;
		if (Assets.exists("assets/" + path))
		{
			assets.push("assets/" + path);
			return true;
		}
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
		return exists("images/" + path + ".xml") || exists("images/" + path + ".txt");
	}

	public static function iconExists(path:String):Bool
	{
		if (path.indexOf("/") > -1)
		{
			var newPath:String = path.substring(0, path.lastIndexOf("/")+1) + "icon-" + path.substring(path.lastIndexOf("/")+1, path.length);
			if (exists("images/icons/" + newPath + ".png") || exists("images/icons/" + newPath + ".json"))
				return true;

			newPath = newPath.substring(0, newPath.indexOf("/")+1) + "icons/" + newPath.substring(newPath.indexOf("/")+1, newPath.length);
			if (exists("images/" + newPath + ".png") || exists("images/" + newPath + ".json"))
				return true;

			newPath = path.substring(0, path.indexOf("/")+1) + "icons/" + path.substring(path.indexOf("/")+1, path.length);
			if (exists("images/" + newPath + ".png") || exists("images/" + newPath + ".json"))
				return true;
		}
		else
		{
			if (exists("images/icons/icon-" + path + ".png") || exists("images/icons/icon-" + path + ".json"))
				return true;
		}
		return (exists("images/icons/" + path + ".png") || exists("images/icons/" + path + ".json"));
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

	public static function clearCache()
	{
		FlxG.bitmap.dumpCache();
	}

	public static function resolveStageAsset(id:String, path:String):String
	{
		if (id.indexOf("/") > 0)
		{
			var dir:String = id.substr(0, id.lastIndexOf("/")+1);
			if (imageExists(dir + "stages/" + id.replace(dir, "") + "/" + path))
				return dir + "stages/" + id.replace(dir, "") + "/" + path;
		}
		return "stages/" + id + "/" + path;
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
			for (mod in ModLoader.modListLoaded)
			{
				var modArray:Array<String> = [];
				if (FileSystem.isDirectory("mods/" + mod + "/" + path) && (curMod == "" || curMod == mod))
				{
					for (file in FileSystem.readDirectory("mods/" + mod + "/" + path))
					{
						for (ext in exts)
						{
							if (((ext != "" && file.toLowerCase().endsWith(ext.toLowerCase())) || (ext == "" && FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + file)))
							&& !modArray.contains(file.substr(0, file.length - ext.length)) && !returnArray.contains(file.substr(0, file.length - ext.length)))
								modArray.push(chain + file.substr(0, file.length - ext.length));
						}
					}

					for (dir in FileSystem.readDirectory("mods/" + mod + "/" + path))
					{
						if (FileSystem.isDirectory("mods/" + mod + "/" + path + "/" + dir))
							modArray = modArray.concat(listFilesExtSub(path + "/" + dir, exts, chain + dir + "/", mod));
					}
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

		#if ALLOW_MODS
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
		#end

		return returnArray;
	}
}