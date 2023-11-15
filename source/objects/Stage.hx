package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import haxe.Json;
import haxe.ds.ArraySort;
import data.ObjectData;
import data.Options;
import game.PlayState;
import scripting.HscriptSprite;

using StringTools;

class Stage
{
	public var stageData:StageData;
	public var curStage:String = "stage";
	public var pieces:Map<String, FlxSprite>;

	public static function sortStagePieces(a:StagePiece, b:StagePiece):Int
	{
		if (a.layer < b.layer)
			return -1;
		if (a.layer > b.layer)
			return 1;
		return 0;
	}

	public static function parseStage(id:String, ?data:Dynamic = null):StageData
	{
		if (data == null)
			data = Paths.json("stages/" + id);
		var sData:StageData = cast data;

		if (data.boyfriend != null)			// This is a Psych Engine stage and must be converted to the Slightly Engine format
		{
			sData = {
				characters: [{position: data.boyfriend, camPosition: [0, 0], flip: true},
				{position: data.opponent, camPosition: [0, 0], flip: false},
				{position: data.girlfriend, camPosition: [0, 0], flip: false, scrollFactor: [0.95, 0.95]}],
				camZoom: data.defaultZoom,
				camFollow: [Std.int(FlxG.width / 2), Std.int(FlxG.height / 2)],
				bgColor: [0, 0, 0],
				pixelPerfect: false,
				pieces: []
			}

			if (Reflect.hasField(data, "camera_boyfriend"))
				sData.characters[0].camPosition = data.camera_boyfriend;

			if (Reflect.hasField(data, "camera_opponent"))
				sData.characters[1].camPosition = data.camera_opponent;

			if (Reflect.hasField(data, "hide_girlfriend") && Reflect.field(data, "hide_girlfriend"))
				sData.characters.pop();
		}
		else if (sData.parent != null)
		{
			var oldStageData:StageData = sData;
			if (Paths.jsonExists("stages/" + sData.parent))
			{
				sData = cast Paths.json("stages/" + sData.parent);

				if (oldStageData.script != null && oldStageData.script != "")
					sData.script = oldStageData.script;

				if (oldStageData.searchDirs != null && oldStageData.searchDirs.length > 0)
					sData.searchDirs = oldStageData.searchDirs;

				if (oldStageData.characters != null && oldStageData.characters.length >= 2)
					sData.characters = oldStageData.characters;

				if (oldStageData.camZoom != null && oldStageData.camZoom != 0)
					sData.camZoom = oldStageData.camZoom;

				if (oldStageData.bgColor != null && oldStageData.bgColor.length >= 3)
					sData.bgColor = oldStageData.bgColor;
			}
			else
				sData = cast Paths.json("stages/" + TitleState.defaultVariables.stage);
		}

		for (c in sData.characters)
		{
			if (c.layer == null)
				c.layer = sData.characters.length - sData.characters.indexOf(c) - 1;

			if (c.camPosition == null || c.camPosition.length < 2)
				c.camPosition = [0, 0];

			if (c.camPosAbsolute == null)
				c.camPosAbsolute = false;

			if (c.scale == null || c.scale.length < 2)
				c.scale = [1, 1];

			if (c.scrollFactor == null || c.scrollFactor.length < 2)
				c.scrollFactor = [1, 1];
		}

		ArraySort.sort(sData.pieces, sortStagePieces);

		if (sData.searchDirs == null || sData.searchDirs.length <= 0)
		{
			sData.searchDirs = ["stages/" + id + "/"];
			if (id.indexOf("/") > -1)
			{
				var dir:String = id.substr(0, id.lastIndexOf("/")+1);
				sData.searchDirs.unshift(dir + "stages/" + id.replace(dir, "") + "/");
			}
		}
		for (i in 0...sData.searchDirs.length)
		{
			if (!sData.searchDirs[i].endsWith("/"))
				sData.searchDirs[i] += "/";
		}

		if (sData.pixelPerfect == null)
			sData.pixelPerfect = false;

		if (sData.camZoom == null || sData.camZoom == 0)
			sData.camZoom = 1;

		if (sData.camFollow == null || sData.camFollow.length < 2)
			sData.camFollow = [Std.int(FlxG.width / 2), Std.int(FlxG.height / 2)];

		if (sData.bgColor == null || sData.bgColor.length < 3)
			sData.bgColor = [0, 0, 0];

		if (sData.script == null || sData.script == "")
			sData.script = "stages/" + id;

		return sData;
	}

	public static function getBlend(blend:String):BlendMode
	{
		switch (blend.toLowerCase())
		{
			case "add": return BlendMode.ADD;
			case "alpha": return BlendMode.ALPHA;
			case "darken": return BlendMode.DARKEN;
			case "difference": return BlendMode.DIFFERENCE;
			case "erase": return BlendMode.ERASE;
			case "hardlight": return BlendMode.HARDLIGHT;
			case "invert": return BlendMode.INVERT;
			case "layer": return BlendMode.LAYER;
			case "lighten": return BlendMode.LIGHTEN;
			case "multiply": return BlendMode.MULTIPLY;
			case "overlay": return BlendMode.OVERLAY;
			case "screen": return BlendMode.SCREEN;
			case "shader": return BlendMode.SHADER;
			case "subtract": return BlendMode.SUBTRACT;
		}

		return BlendMode.NORMAL;
	}

	public function new(stage:String)
	{
		pieces = new Map<String, FlxSprite>();

		if (Paths.jsonExists("stages/" + stage))
			curStage = stage;
		stageData = parseStage(curStage);

		for (i in 0...stageData.pieces.length)
		{
			if (stageData.pieces[i].id == null || stageData.pieces[i].id == "")
				stageData.pieces[i].id = stageData.pieces[i].asset;

			var stagePiece:StagePiece = stageData.pieces[i];
			if (stagePiece.visible == null)
				stagePiece.visible = true;
			var piece:FlxSprite = null;

			switch (stagePiece.type)
			{
				case "static":
					if (imageExists(stagePiece.asset))
					{
						if (FlxG.state == PlayState.instance && stagePiece.scriptClass != null && stagePiece.scriptClass != "")
						{
							piece = new HscriptSprite(stagePiece.scriptClass, []).loadGraphic(image(stagePiece.asset));
							piece.setPosition(stagePiece.position[0], stagePiece.position[1]);
						}
						else
							piece = new FlxSprite(stagePiece.position[0], stagePiece.position[1], image(stagePiece.asset));
						if (stagePiece.scale != null && stagePiece.scale.length == 2)
						{
							piece.scale.x = stagePiece.scale[0];
							piece.scale.y = stagePiece.scale[1];
						}
						if (stagePiece.updateHitbox)
							piece.updateHitbox();
						if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
						{
							piece.scrollFactor.x = stagePiece.scrollFactor[0];
							piece.scrollFactor.y = stagePiece.scrollFactor[1];
						}
						if (stagePiece.flip != null && stagePiece.flip.length == 2)
						{
							piece.flipX = stagePiece.flip[0];
							piece.flipY = stagePiece.flip[1];
						}
					}
					else
						piece = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.TRANSPARENT);
					if (!Std.isOfType(piece, HscriptSprite))
						piece.active = false;

				case "animated":
					if (imageExists(stagePiece.asset))
					{
						var isSparrow:Bool = false;
						var pieceFrames = null;
						if (sparrowExists(stagePiece.asset))
						{
							pieceFrames = sparrow(stagePiece.asset);
							isSparrow = true;
						}
						else
							pieceFrames = tiles(stagePiece.asset, stagePiece.tileCount[0], stagePiece.tileCount[1]);

						var aPiece:AnimatedSprite = null;
						if (FlxG.state == PlayState.instance && stagePiece.scriptClass != null && stagePiece.scriptClass != "")
						{
							aPiece = new HscriptAnimatedSprite(stagePiece.scriptClass, []);
							aPiece.frames = pieceFrames;
							aPiece.setPosition(stagePiece.position[0], stagePiece.position[1]);
						}
						else
							aPiece = new AnimatedSprite(stagePiece.position[0], stagePiece.position[1], pieceFrames);
						for (anim in stagePiece.animations)
						{
							if (isSparrow)
								aPiece.addAnim(anim.name, anim.prefix, anim.fps, anim.loop, anim.indices);
							else
							{
								if (anim.indices != null && anim.indices.length > 0)
									aPiece.animation.add(anim.name, anim.indices, anim.fps, anim.loop);
							}
							if (anim.offsets != null && anim.offsets.length == 2)
								aPiece.addOffsets(anim.name, anim.offsets);
						}
						aPiece.animation.play(stagePiece.firstAnimation);

						if (stagePiece.idles != null)
							aPiece.idles = stagePiece.idles;
						if (stagePiece.beatAnimationSpeed != null)
							aPiece.danceSpeed = stagePiece.beatAnimationSpeed;

						if (stagePiece.scale != null && stagePiece.scale.length == 2)
						{
							aPiece.scale.x = stagePiece.scale[0];
							aPiece.scale.y = stagePiece.scale[1];
						}
						if (stagePiece.updateHitbox)
							aPiece.updateHitbox();
						piece = aPiece;

						if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
						{
							piece.scrollFactor.x = stagePiece.scrollFactor[0];
							piece.scrollFactor.y = stagePiece.scrollFactor[1];
						}
						if (stagePiece.flip != null && stagePiece.flip.length == 2)
						{
							piece.flipX = stagePiece.flip[0];
							piece.flipY = stagePiece.flip[1];
						}
					}
					else
						piece = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.TRANSPARENT);

				case "tiled":
					if (imageExists(stagePiece.asset))
					{
						piece = new FlxBackdrop(image(stagePiece.asset), 1, 1, stagePiece.tile[0], stagePiece.tile[1]);
						piece.x = stagePiece.position[0];
						piece.y = stagePiece.position[1];
						if (stagePiece.scale != null && stagePiece.scale.length == 2)
						{
							piece.scale.x = stagePiece.scale[0];
							piece.scale.y = stagePiece.scale[1];
						}
						if (stagePiece.updateHitbox)
							piece.updateHitbox();
						if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
						{
							piece.scrollFactor.x = stagePiece.scrollFactor[0];
							piece.scrollFactor.y = stagePiece.scrollFactor[1];
						}
						if (stagePiece.flip != null && stagePiece.flip.length == 2)
						{
							piece.flipX = stagePiece.flip[0];
							piece.flipY = stagePiece.flip[1];
						}
					}
					else
						piece = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.TRANSPARENT);

				case "group":
					piece = new FlxSpriteGroup();
					if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
					{
						piece.scrollFactor.x = stagePiece.scrollFactor[0];
						piece.scrollFactor.y = stagePiece.scrollFactor[1];
					}
			}
			piece.pixelPerfect = stageData.pixelPerfect;
			piece.visible = stagePiece.visible;
			piece.antialiasing = stagePiece.antialias;
			if (stagePiece.alpha != null && stagePiece.alpha != 1)
				piece.alpha = stagePiece.alpha;
			if (stagePiece.blend != null && stagePiece.blend != "")
				piece.blend = stagePiece.blend;
			if (stagePiece.align != null && stagePiece.align != "")
			{
				if (stagePiece.align.endsWith("center"))
					piece.x -= piece.width / 2;
				else if (stagePiece.align.endsWith("right"))
					piece.x -= piece.width;

				if (stagePiece.align.startsWith("middle"))
					piece.y -= piece.height / 2;
				else if (stagePiece.align.startsWith("bottom"))
					piece.y -= piece.height;
			}
			pieces.set(stagePiece.id, piece);
		}
	}

	public function image(asset:String):FlxGraphic
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.imageExists(s + asset))
				return Paths.image(s + asset);
		}
		return null;
	}

	public function imageExists(asset:String):Bool
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.imageExists(s + asset))
				return true;
		}
		return false;
	}

	public function sparrow(asset:String):FlxFramesCollection
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.sparrowExists(s + asset))
				return Paths.sparrow(s + asset);
		}
		return null;
	}

	public function sparrowExists(asset:String):Bool
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.sparrowExists(s + asset))
				return true;
		}
		return false;
	}

	public function tiles(asset:String, tilesX:Int, tilesY:Int):FlxFramesCollection
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.imageExists(s + asset))
				return Paths.tiles(s + asset, tilesX, tilesY);
		}
		return null;
	}

	public function beatHit()
	{
	}

	public function stepHit()
	{
		for (p in stageData.pieces)
		{
			if (p.type == "group")
			{
				var g:FlxSpriteGroup = cast pieces.get(p.id);
				for (m in g.members)
				{
					if (Std.isOfType(m, AnimatedSprite))
					{
						var s:AnimatedSprite = cast m;
						s.stepHit();
					}

					if (Std.isOfType(m, Character))
					{
						var c:Character = cast m;
						c.stepHit();
					}
				}
			}
		}
	}
}