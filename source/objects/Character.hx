package objects;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flxanimate.FlxAnimate;
import data.ObjectData;
import data.Options;
import game.PlayState;
import lime.app.Application;

using StringTools;

class Character extends FlxSprite
{
	public var characterData:CharacterData = null;
	public var curCharacter:String = TitleState.defaultVariables.player1;
	public var camPosition:CharacterCamPosition = {x: 0, y: 0, abs: false};
	var animChain:Map<String, String>;
	var animData:Map<String, CharacterAnimation>;
	public var icon:HealthIcon = null;

	var myCharType:String = "sparrow";
	var atlas:FlxAnimate = null;
	public var curAnim:CharacterAnimation;
	public var curAnimName:String = "";
	public var curAnimFrame:Int = 0;
	public var curAnimFinished:Bool = false;
	public var sad:String = "sad";

	public var lastIdle:Int = 0;
	public var canDance:Bool = true;
	public var inLoop:Bool = false;
	public var sustain:Bool = false;
	public var importantAnim:Bool = false;
	public var danceSpeed:Float = 1;
	public var holdTimer:Float = 0;
	public var idleSuffix:String = "";
	public var wasFlipped:Bool = false;
	public var flipOffsets:Bool = false;
	public var baseFrameWidth:Int = 0;

	public static function compactIndices(ind:Array<Int>):Array<Int>
	{
		if (ind.length > 2)
		{
			var start:Int = 0;
			var end:Int = 0;
			var seqDir:Int = 1;
			if (ind.length >= 2 && ind[1] == ind[0] - 1)
				seqDir = -1;

			for (i in 1...ind.length)
			{
				if (seqDir != 0 && ind[i] != ind[i-1]+seqDir)
					seqDir = 0;
			}
			if (seqDir != 0)
				return [-1,ind[0],ind[ind.length-1]];
		}
		return ind;
	}

	public static function uncompactIndices(ind:Array<Int>):Array<Int>
	{
		if (ind.length == 3 && ind[0] == -1)
			return Util.generateIndices(ind[1], ind[2]);
		return ind;
	}

	public static var parsedCharacters:Map<String, CharacterData> = new Map<String, CharacterData>();
	public static function parseCharacter(id:String):CharacterData
	{
		var data:Dynamic = Paths.json("characters/" + id);
		var cData:CharacterData = cast data;
		if (data.image != null)			// This is a Psych Engine character and must be converted to the Restructure Engine format
		{
			cData = {
				asset: data.image,
				position: data.position,
				camPosition: [Std.int(data.camera_position[0] + 150), Std.int(data.camera_position[1] - 100)],
				camPositionGameOver: [0, 0],
				scale: [data.scale, data.scale],
				antialias: !data.no_antialiasing,
				animations: [],
				firstAnimation: data.animations[0].anim,
				idles: ["idle"],
				danceSpeed: 2,
				flip: data.flip_x,
				facing: "right",
				icon: data.healthicon
			}
			if (cData.icon == id)
				cData.icon = "";

			var dataAnims:Array<Dynamic> = cast data.animations;
			for (a in dataAnims)
			{
				var cAnim:CharacterAnimation = {
					name: a.anim,
					prefix: a.name,
					fps: a.fps,
					loop: a.loop,
					offsets: a.offsets
				}
				if (a.indices != null && a.indices.length > 0)
					cAnim.indices = a.indices;
				cData.animations.push(cAnim);
				if (cAnim.name == "danceLeft")
				{
					cData.idles = ["danceLeft", "danceRight"];
					cData.danceSpeed = 1;
					cData.firstAnimation = "danceLeft";
				}
				else if (cAnim.name == "idle")
					cData.firstAnimation = "idle";
			}
		}
		else if (cData.parent != null)
		{
			var oldCharData:CharacterData = cData;
			if (Paths.jsonExists("characters/" + cData.parent))
			{
				cData = cast Paths.json("characters/" + cData.parent);

				if (oldCharData.script != null && oldCharData.script != "")
					cData.script = oldCharData.script;

				if (oldCharData.asset != null && oldCharData.asset != "")
					cData.asset = oldCharData.asset;

				if (oldCharData.camPosition != null && oldCharData.camPosition.length >= 2)
					cData.camPosition = oldCharData.camPosition;

				if (oldCharData.camPositionGameOver != null && oldCharData.camPositionGameOver.length >= 2)
					cData.camPositionGameOver = oldCharData.camPositionGameOver;

				if (oldCharData.gameOverCharacter != null && oldCharData.gameOverCharacter != "")
					cData.gameOverCharacter = oldCharData.gameOverCharacter;

				if (oldCharData.gameOverSFX != null && oldCharData.gameOverSFX != "")
					cData.gameOverSFX = oldCharData.gameOverSFX;

				if (oldCharData.deathCounterText != null && oldCharData.deathCounterText != "")
					cData.deathCounterText = oldCharData.deathCounterText;

				if (oldCharData.icon != null && oldCharData.icon != "")
					cData.icon = oldCharData.icon;
			}
			else
				cData = cast Paths.json("characters/" + TitleState.defaultVariables.player1);
		}

		if (cData.script == null || cData.script == "")
			cData.script = "characters/" + id;

		if (cData.scale == null || cData.scale.length < 2)
			cData.scale = [1, 1];

		if (cData.camPositionGameOver == null || cData.camPositionGameOver.length < 2)
			cData.camPositionGameOver = [cData.camPosition[0], cData.camPosition[1]];

		if (cData.gameOverCharacter == null)
			cData.gameOverCharacter = "";

		if (cData.gameOverSFX == null)
			cData.gameOverSFX = "";

		if (cData.deathCounterText == null)
			cData.deathCounterText = "";

		if (cData.icon == null)
			cData.icon = "";

		if (id.indexOf("/") > -1)
		{
			var dir:String = id.substr(0, id.lastIndexOf("/")+1);
			if (!Paths.imageExists(cData.asset) && !Paths.imageExists("characters/" + cData.asset))
			{
				if (Paths.imageExists(dir + cData.asset))
					cData.asset = dir + cData.asset;
				else if (Paths.imageExists("characters/" + dir + cData.asset))
					cData.asset = "characters/" + dir + cData.asset;
				else if (Paths.imageExists(dir + "characters/" + cData.asset))
					cData.asset = dir + "characters/" + cData.asset;
				else if (cData.asset.startsWith("characters/") && Paths.imageExists("characters/" + dir + cData.asset.substr(11)))
					cData.asset = "characters/" + dir + cData.asset.substr(11);
			}

			if (cData.icon != "" && cData.icon.indexOf("/") == -1 && !Paths.iconExists(cData.icon) && Paths.iconExists(dir + cData.icon))
			{
				cData.icon = dir + cData.icon;
				if (cData.icon == id)
					cData.icon = "";
			}
		}

		if (!Paths.imageExists(cData.asset))
		{
			if (Paths.imageExists("characters/" + cData.asset))
				cData.asset = "characters/" + cData.asset;
			else if (cData.asset.indexOf("/") > -1 && Paths.imageExists(cData.asset.substr(0, cData.asset.indexOf("/")+1) + "characters/" + cData.asset.substr(cData.asset.indexOf("/")+1)))
				cData.asset = cData.asset.substr(0, cData.asset.indexOf("/")+1) + "characters/" + cData.asset.substr(cData.asset.indexOf("/")+1);
		}

		var allAnims:Array<String> = [];
		for (a in cData.animations)
		{
			allAnims.push(a.name);

			if (a.loop == null)
				a.loop = false;

			if (a.fps == null)
				a.fps = 24;

			if (a.indices != null)
				a.indices = uncompactIndices(a.indices);

			if (a.loopedFrames == null)
				a.loopedFrames = 0;

			if (a.sustainFrame == null)
				a.sustainFrame = -1;
		}

		var asset:String = cData.asset;
		if (!Paths.sparrowExists(asset) && (cData.tileCount == null || cData.tileCount.length < 2))
			cData.tileCount = [1, 1];

		if (cData.flip == null)
			cData.flip = false;

		if (cData.idles == null)
		{
			if (allAnims.contains("danceLeft") && allAnims.contains("danceRight"))
				cData.idles = ["danceLeft", "danceRight"];
			else if (allAnims.contains("idle"))
				cData.idles = ["idle"];
			else
				cData.idles = [];
		}

		if (cData.danceSpeed == null)
			cData.danceSpeed = 1;

		if (cData.facing == null || cData.facing == "")
			cData.facing = "right";

		return cData;
	}

	override public function new(x:Float = 0, y:Float = 0, char:String = null, ?shouldFlip:Bool = false)
	{
		super(x, y);

		if (char == null)
			changeCharacter(TitleState.defaultVariables.player1);
		else
			changeCharacter(char);
		if (shouldFlip)
			flip();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (characterData.asset != "")
		{
			@:privateAccess
			if (myCharType == "atlas")
			{
				atlas.update(elapsed);
				curAnimFrame = atlas.anim.curFrame;
				curAnimFinished = (atlas.anim.curFrame >= atlas.anim.frameLength - 1);
			}
			else
			{
				curAnimName = animation.curAnim.name;
				curAnimFrame = animation.curAnim.curFrame;
				curAnimFinished = animation.curAnim.finished;
			}

			holdTimer -= elapsed * 1000;

			if (sustain && curAnim.sustainFrame != null && curAnim.sustainFrame >= 0)
			{
				if (curAnimFrame >= curAnim.sustainFrame)
				{
					if (myCharType == "atlas")
					{
						atlas.anim.curFrame = curAnim.sustainFrame;
						atlas.pauseAnim();
					}
					else
					{
						animation.curAnim.curFrame = curAnim.sustainFrame;
						animation.curAnim.paused = true;
					}
				}
			}

			if (curAnimFinished)
			{
				if (importantAnim)
					importantAnim = false;

				if (curAnim.loopedFrames > 0)
				{
					playAnim(curAnimName, true, false, false);
					inLoop = true;
					@:privateAccess
					if (myCharType == "atlas")
						atlas.anim.curFrame = atlas.anim.frameLength - curAnim.loopedFrames;
					else
						animation.curAnim.curFrame = animation.curAnim.numFrames - curAnim.loopedFrames;
				}
				else if (animChain.exists(curAnimName) && animData.exists(animChain.get(curAnimName)))
					playAnim(animChain.get(curAnimName));
				else if (animData.exists(curAnimName + "-loop"))
					playAnim(curAnimName + "-loop", false, false, false);
			}
		}
	}

	public function changeCharacter(char:String)
	{
		if (characterData != null)
		{
			x -= characterData.position[0];
			y -= characterData.position[1];

			scale.x /= characterData.scale[0];
			scale.y /= characterData.scale[1];

			danceSpeed /= characterData.danceSpeed;

			if (atlas != null)
			{
				atlas.kill();
				atlas = null;
			}
		}

		animChain = new Map<String, String>();
		animData = new Map<String, CharacterAnimation>();

		if (Paths.jsonExists("characters/" + char))
			curCharacter = char;
		if (!parsedCharacters.exists(curCharacter))
			parsedCharacters[curCharacter] = parseCharacter(curCharacter);
		characterData = parsedCharacters[curCharacter];

		if (characterData.gameOverCharacter == null || characterData.gameOverCharacter == "")
		{
			if (Paths.jsonExists("characters/" + curCharacter + "-dead"))
				characterData.gameOverCharacter = curCharacter + "-dead";
			else
				characterData.gameOverCharacter = TitleState.defaultVariables.dead;
		}
		else if (characterData.gameOverCharacter == "_self")
			characterData.gameOverCharacter = curCharacter;

		if (characterData.icon == null || characterData.icon == "")
		{
			characterData.icon = curCharacter;
			if (!Paths.iconExists(characterData.icon) && Paths.iconExists(characterData.icon.split("-")[0]))
				characterData.icon = characterData.icon.split("-")[0];
		}

		danceSpeed *= characterData.danceSpeed;

		x += characterData.position[0];
		y += characterData.position[1];

		scale.x *= characterData.scale[0];
		scale.y *= characterData.scale[1];

		switch (characterData.facing)
		{
			case "right": flipOffsets = wasFlipped; flipX = (wasFlipped ? !characterData.flip : characterData.flip);
			case "left": flipOffsets = !wasFlipped; flipX = (wasFlipped ? !characterData.flip : characterData.flip);
			case "center": flipOffsets = false; flipX = characterData.flip;
		}

		antialiasing = characterData.antialias;

		if (icon != null)
			icon.reloadIcon(characterData.icon);

		var asset:String = characterData.asset;

		myCharType = "sparrow";
		if (characterData.asset == "")
			makeGraphic(1, 1, FlxColor.TRANSPARENT);
		else if (Paths.exists("images/" + asset + ".json"))
		{
			myCharType = "atlas";
			makeGraphic(1, 1, FlxColor.TRANSPARENT);

			var assetArray = characterData.asset.replace("\\","/").split("/");
			assetArray.pop();
			atlas = new FlxAnimate(x, y, Paths.atlas(assetArray.join("/")));
			for (i in 0...characterData.animations.length)
			{
				var anim = characterData.animations[i];
				if (anim.indices != null && anim.indices.length > 0)
				{
					atlas.anim.addByAnimIndices(anim.name, anim.indices, anim.fps);
					if (anim.next != null && anim.next != "")
						animChain.set(anim.name, anim.next);
					animData.set(anim.name, anim);
				}
			}

			atlas.flipX = flipX;
			atlas.scale = scale;

			if (animData.exists(characterData.firstAnimation))
				playAnim(characterData.firstAnimation, true);
			else if (characterData.animations.length > 0)
				playAnim(characterData.animations[0].name, true);
			baseFrameWidth = 1;
			atlas.antialiasing = antialiasing;
		}
		else if (Paths.sparrowExists(asset))
		{
			frames = Paths.sparrow(asset);
			for (i in 0...characterData.animations.length)
			{
				var anim = characterData.animations[i];
				if (anim.indices != null && anim.indices.length > 0)
					animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
				else
					animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
				if (anim.next != null && anim.next != "")
					animChain.set(anim.name, anim.next);
				animData.set(anim.name, anim);
			}

			if (animData.exists(characterData.firstAnimation))
				playAnim(characterData.firstAnimation);
			else if (characterData.animations.length > 0)
				playAnim(characterData.animations[0].name);
			baseFrameWidth = frameWidth;

			updateHitbox();
			updateOffsets();
		}
		else if (Paths.imageExists(asset))
		{
			myCharType = "tiles";

			frames = Paths.tiles(asset, characterData.tileCount[0], characterData.tileCount[1]);
			for (i in 0...characterData.animations.length)
			{
				var anim = characterData.animations[i];
				if (anim.indices != null && anim.indices.length > 0)
				{
					animation.add(anim.name, anim.indices, anim.fps, anim.loop);
					if (anim.next != null && anim.next != "")
						animChain.set(anim.name, anim.next);
					animData.set(anim.name, anim);
				}
			}

			if (animData.exists(characterData.firstAnimation))
				playAnim(characterData.firstAnimation);
			else if (characterData.animations.length > 0)
				playAnim(characterData.animations[0].name);
			baseFrameWidth = frameWidth;

			updateHitbox();
			updateOffsets();
		}
		else
		{
			Application.current.window.alert("Missing character asset: " + Paths.imagePath(asset), "Alert");
			characterData.asset = "";
		}
	}

	public function flip()
	{
		wasFlipped = !wasFlipped;

		switch (characterData.facing)
		{
			case "right": flipOffsets = wasFlipped; flipX = (wasFlipped ? !characterData.flip : characterData.flip);
			case "left": flipOffsets = !wasFlipped; flipX = (wasFlipped ? !characterData.flip : characterData.flip);
			case "center": flipOffsets = false; flipX = characterData.flip;
		}

		updateOffsets();
	}

	override public function draw()
	{
		if (myCharType == "atlas")
		{
			atlas.visible = visible;
			atlas.color = color;
			atlas.alpha = alpha;
			atlas.scale = scale;
			atlas.antialiasing = antialiasing;
			atlas.cameras = cameras;
			atlas.x = x - offset.x;
			atlas.y = y - offset.y;
			atlas.scrollFactor = scrollFactor;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.draw();
		}
		else
			super.draw();
	}

	public function repositionCharacter(x:Int, y:Int)
	{
		this.x = x + characterData.position[0];
		this.y = y + characterData.position[1];
	}

	public function scaleCharacter(x:Float, y:Float)
	{
		scale.x = x * characterData.scale[0];
		scale.y = y * characterData.scale[1];
		updateOffsets();
	}

	public function hasAnim(anim:String, canSwitchLeftRight:Bool = true):Bool
	{
		var trueAnim:String = anim;
		if (flipOffsets && canSwitchLeftRight)
		{
			if (anim.indexOf("singLEFT") > -1)
				trueAnim = anim.replace("singLEFT", "singRIGHT");
			else if (anim.indexOf("singRIGHT") > -1)
				trueAnim = anim.replace("singRIGHT", "singLEFT");
		}

		return animData.exists(trueAnim);
	}

	public function playAnim(anim:String, forced:Bool = false, important:Bool = false, canSwitchLeftRight:Bool = true)
	{
		if (characterData.animations.length <= 0) return;

		var trueAnim:String = anim;
		if (flipOffsets && canSwitchLeftRight)
		{
			if (anim.indexOf("singLEFT") > -1)
				trueAnim = anim.replace("singLEFT", "singRIGHT");
			else if (anim.indexOf("singRIGHT") > -1)
				trueAnim = anim.replace("singRIGHT", "singLEFT");
		}

		if (!animData.exists(trueAnim) && trueAnim.indexOf("-") > -1)
		{
			while (!animData.exists(trueAnim) && trueAnim.indexOf("-") > -1)
				trueAnim = trueAnim.substr(0, trueAnim.lastIndexOf("-"));
		}

		if (animData.exists(trueAnim))
		{
			curAnim = animData[trueAnim];
			importantAnim = (important || curAnim.important);

			if (myCharType == "atlas")
			{
				@:privateAccess
				if (forced || inLoop || trueAnim != curAnimName || atlas.anim.curFrame >= atlas.anim.frameLength - 1)
					atlas.playAnim(trueAnim, true, curAnim.loop);
				curAnimName = trueAnim;
			}
			else if (characterData.asset != "")
			{
				animation.play(trueAnim, (forced || inLoop));
				curAnimName = animation.curAnim.name;
			}
			curAnimFrame = 0;
			curAnimFinished = false;
			updateOffsets();
		}
		inLoop = false;
	}

	function updateOffsets()
	{
		if (curAnim == null || curAnim.offsets == null || curAnim.offsets.length < 2) return;

		offset.x = curAnim.offsets[0];
		offset.y = curAnim.offsets[1];

		if (myCharType == "atlas")
		{
			if (flipOffsets)
				offset.x = -offset.x;
		}
		else
		{
			if (flipOffsets && baseFrameWidth > 0)
			{
				offset.x = -offset.x;
				offset.x -= (baseFrameWidth - frameWidth) * scale.x;
			}
		}

		if (scale.x != characterData.scale[0])
			offset.x *= scale.x / characterData.scale[0];
		if (scale.y != characterData.scale[1])
			offset.y *= scale.y / characterData.scale[1];
	}

	public function sustainEnd()
	{
		@:privateAccess
		if (sustain)
		{
			if (myCharType == "atlas")
				atlas.playAnim(atlas.anim.name);
			else if (animation.curAnim != null)
				animation.curAnim.paused = false;
			sustain = false;
		}
	}

	public function dance()
	{
		if (characterData.idles.length <= 0)
			return;

		if (characterData.asset != "" && canDance && !importantAnim && (!curAnimName.split("-")[0].endsWith("miss") || curAnimFinished))
		{
			if (lastIdle < characterData.idles.length)
				playAnim(characterData.idles[lastIdle] + idleSuffix, characterData.idles.length > 1);
			lastIdle = (lastIdle + 1) % characterData.idles.length;
		}
	}

	public function beatHit()
	{
	}

	public function stepHit()
	{
		if (danceSpeed > 0 && holdTimer <= 0 && PlayState.instance.curStep % Std.int(Math.round(danceSpeed * 4)) == 0)
			dance();
	}
}