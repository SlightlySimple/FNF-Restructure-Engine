package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.system.FlxAssets.FlxShader;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxRuntimeShader;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import haxe.Json;
import haxe.ds.ArraySort;
import lime.app.Application;
import data.ObjectData;
import data.Options;
import data.Song;
import game.PlayState;
import scripting.HscriptSprite;

using StringTools;

class Stage
{
	public var data:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var stageData:StageData;
	public var curStage:String = "stage";
	public var pieces:Map<String, FlxSprite>;
	var shaders:Array<FlxShader> = [];

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

		if (sData.parent != null)
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

		if (sData.pieces == null)
			Application.current.window.alert("Stage \"" + id + "\" is in the wrong format", "Alert");

		if (sData.fixes == null)
			sData.fixes = 0;

		if (sData.shaders == null)
			sData.shaders = [];

		if (sData.defaultCharacterShader == null)
			sData.defaultCharacterShader = 0;

		var i:Int = 0;
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

			if (sData.fixes == 0 && i == 2)
			{
				sData.fixes = 1;
				c.position[0] += 140;
				c.position[1] -= 80;
			}

			i++;
		}

		for (p in sData.pieces)
		{
			if (p.visible == null)
				p.visible = true;

			if (p.scale == null)
			{
				p.scale = [1, 1];
				p.updateHitbox = true;
			}

			if (p.velocity == null)
				p.velocity = [0, 0];

			if (p.velocityMultipliedByScroll == null)
				p.velocityMultipliedByScroll = false;

			if (p.align == null)
				p.align = "topleft";

			if (p.scrollFactor == null)
				p.scrollFactor = [1, 1];

			if (p.flip == null)
				p.flip = [false, false];

			if (p.color == null)
				p.color = [255, 255, 255];

			if (p.alpha == null)
				p.alpha = 1;

			if (p.blend == null)
				p.blend = "normal";

			if (p.tile == null)
				p.tile = [true, true];

			if (p.tileSpace == null)
				p.tileSpace = [0, 0];

			if (p.tileCount == null)
				p.tileCount = [1, 1];

			if (p.scriptClass != null)
			{
				if (p.scriptParameters == null)
					p.scriptParameters = {};

				var type:String = (p.type == "animated" ? "AnimatedSprite" : "FlxSprite");
				if (Paths.jsonExists("scripts/" + type + "/" + p.scriptClass))
				{
					var pieceParams:Array<EventParams> = cast Paths.json("scripts/" + type + "/" + p.scriptClass).parameters;
					if (pieceParams != null && pieceParams.length > 0)
					{
						for (param in pieceParams)
						{
							if (param.type != "label" && !Reflect.hasField(p.scriptParameters, param.id))
								Reflect.setField(p.scriptParameters, param.id, param.defaultValue);
						}
					}
				}
			}
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

	public function new(stage:String)
	{
		pieces = new Map<String, FlxSprite>();

		if (Paths.jsonExists("stages/" + stage))
			curStage = stage;
		else
			Application.current.window.alert("MISSING STAGE \"" + stage + "\"", "Alert");

		stageData = parseStage(curStage);

		for (s in stageData.shaders)
		{
			var shader:FlxRuntimeShader = new FlxRuntimeShader(Paths.shader(s.id));
			for (f in Reflect.fields(s.parameters))
			{
				var val:Dynamic = Reflect.field(s.parameters, f);
				if (Std.isOfType(val, Float) || Std.isOfType(val, Int))
					shader.setFloat(f, cast val);
			}
			shaders.push(shader);
		}

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
							piece = new HscriptSprite(stagePiece.scriptClass, [stagePiece.scriptParameters]).loadGraphic(image(stagePiece.asset));
							piece.setPosition(stagePiece.position[0], stagePiece.position[1]);
						}
						else
							piece = new FlxSprite(stagePiece.position[0], stagePiece.position[1], image(stagePiece.asset));
						if (stagePiece.scale != null && stagePiece.scale.length == 2)
							piece.scale.set(stagePiece.scale[0], stagePiece.scale[1]);
						if (stagePiece.updateHitbox)
							piece.updateHitbox();
						if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
							piece.scrollFactor.set(stagePiece.scrollFactor[0], stagePiece.scrollFactor[1]);
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
							aPiece = new HscriptAnimatedSprite(stagePiece.scriptClass, [stagePiece.scriptParameters]);
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
									aPiece.animation.add(anim.name, Character.uncompactIndices(anim.indices), anim.fps, anim.loop);
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
							aPiece.scale.set(stagePiece.scale[0], stagePiece.scale[1]);
						if (stagePiece.updateHitbox)
							aPiece.updateHitbox();
						piece = aPiece;

						if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
							piece.scrollFactor.set(stagePiece.scrollFactor[0], stagePiece.scrollFactor[1]);
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
						piece = new FlxBackdrop(image(stagePiece.asset), 1, 1, stagePiece.tile[0], stagePiece.tile[1], stagePiece.tileSpace[0], stagePiece.tileSpace[1]);
						piece.setPosition(stagePiece.position[0], stagePiece.position[1]);
						if (stagePiece.velocity != null && stagePiece.velocity.length == 2)
						{
							if (stagePiece.velocityMultipliedByScroll)
								piece.velocity.set(stagePiece.velocity[0] * stagePiece.scrollFactor[0], stagePiece.velocity[1] * stagePiece.scrollFactor[1]);
							else
								piece.velocity.set(stagePiece.velocity[0], stagePiece.velocity[1]);
						}
						if (stagePiece.scale != null && stagePiece.scale.length == 2)
							piece.scale.set(stagePiece.scale[0], stagePiece.scale[1]);
						if (stagePiece.updateHitbox)
							piece.updateHitbox();
						if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
							piece.scrollFactor.set(stagePiece.scrollFactor[0], stagePiece.scrollFactor[1]);
						if (stagePiece.flip != null && stagePiece.flip.length == 2)
						{
							piece.flipX = stagePiece.flip[0];
							piece.flipY = stagePiece.flip[1];
						}
					}
					else
						piece = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.TRANSPARENT);

				case "solid":
					piece = new FlxSprite(stagePiece.position[0], stagePiece.position[1]).makeGraphic(Std.int(stagePiece.scale[0]), Std.int(stagePiece.scale[1]), FlxColor.fromRGB(stagePiece.color[0], stagePiece.color[1], stagePiece.color[2]));
					if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
						piece.scrollFactor.set(stagePiece.scrollFactor[0], stagePiece.scrollFactor[1]);
					piece.active = false;
					piece.antialiasing = false;

				case "group":
					piece = new FlxSpriteGroup();
					if (stagePiece.scrollFactor != null && stagePiece.scrollFactor.length == 2)
						piece.scrollFactor.set(stagePiece.scrollFactor[0], stagePiece.scrollFactor[1]);
			}
			piece.pixelPerfect = stageData.pixelPerfect;
			piece.visible = stagePiece.visible;
			if (stagePiece.type != "solid")
			{
				piece.antialiasing = stagePiece.antialias;
				if (stagePiece.color != null && stagePiece.color.length > 2)
					piece.color = FlxColor.fromRGB(stagePiece.color[0], stagePiece.color[1], stagePiece.color[2]);
			}
			if (stagePiece.alpha != null && stagePiece.alpha != 1)
				piece.alpha = stagePiece.alpha;
			if (stagePiece.blend != null && stagePiece.blend != "")
				piece.blend = stagePiece.blend;
			if (stagePiece.shader != null && stagePiece.shader > 0)
				piece.shader = shaders[stagePiece.shader - 1];
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

	public function applyShaders(characters:Array<Character>)
	{
		if (stageData.defaultCharacterShader > 0)
		{
			for (c in characters)
				c.shader = shaders[stageData.defaultCharacterShader - 1];
		}

		for (i in 0...stageData.characters.length)
		{
			if (i < characters.length && stageData.characters[i].shader != null && stageData.characters[i].shader > 0)
				characters[i].shader = shaders[stageData.characters[i].shader - 1];
		}
	}

	public function removeShaders(characters:Array<Character>)
	{
		for (c in characters)
		{
			if (shaders.contains(c.shader))
				c.shader = null;
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

	public function imagePath(asset:String):String
	{
		for (s in stageData.searchDirs)
		{
			if (Paths.imageExists(s + asset))
				return s + asset;
		}
		return "";
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