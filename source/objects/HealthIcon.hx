package objects;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import data.ObjectData;
import data.Options;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var id:String = "";
	public var iconData:HealthIconData;
	public var allAnims:Array<String> = [];
	public var sc:FlxPoint;
	public var iconOffset:Int = 0;
	public var swapTo:String = "";

	public var stack:Array<IconStack> = [];

	public static function listIcons(?baseDir:String = ""):Array<String>
	{
		var ret:Array<String> = Paths.listFilesExtSub("images/"+baseDir+"icons/", [".png", ".json"]);
		for (i in 0...ret.length)
			ret[i] = ret[i].replace("icon-", "");
		return ret;
	}

	public static function iconExists(path:String):Bool
	{
		return (Paths.imageExists(path) || Paths.jsonImagesExists(path));
	}

	override public function new(x:Float = 0, y:Float = 0, char:String = null)
	{
		super(x, y);
		sc = new FlxPoint(1, 1);
		if (char == null)
			reloadIcon(TitleState.defaultVariables.icon);
		else
			reloadIcon(char);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		scale.set(sc.x * iconData.scale[0], sc.y * iconData.scale[1]);

		if (animation.curAnim != null && animation.curAnim.finished)
		{
			if (animation.curAnim.name.indexOf("_to_") > -1)
				playAnim(animation.curAnim.name.split("_to_")[1]);
		}
	}

	public function makeStack(newStack:Array<IconStack>)
	{
		stack = [];

		for (i in newStack)
		{
			var newIcon:HealthIcon = new HealthIcon(0, 0, i.id);
			i.sprite = newIcon;
			stack.push(i);
		}
	}

	public function reloadIcon(char:String, ?isSwap:Bool = false)
	{
		if (isSwap)
			swapTo = id;

		if (char == id)
			return;

		id = char;
		var iconDir:String = "icons/" + char;
		if (iconExists("icons/icon-" + char))
			iconDir = "icons/icon-" + char;
		if (char.indexOf("/") > -1 && !iconExists(iconDir))
		{
			var newPath:String = char.substring(0, char.lastIndexOf("/")+1) + "icon-" + char.substring(char.lastIndexOf("/")+1, char.length);
			if (iconExists("icons/" + newPath))
				iconDir = "icons/" + newPath;
			else
			{
				newPath = newPath.substring(0, newPath.indexOf("/")+1) + "icons/" + newPath.substring(newPath.indexOf("/")+1, newPath.length);
				if (iconExists(newPath))
					iconDir = newPath;
				else
				{
					newPath = char.substring(0, char.indexOf("/")+1) + "icons/" + char.substring(char.indexOf("/")+1, char.length);
					if (iconExists(newPath))
						iconDir = newPath;
				}
			}
		}
		if (Paths.jsonImagesExists(iconDir))
			iconData = cast Paths.jsonImages(iconDir);
		else
			iconData = { antialias: true, scale: [1, 1], offset: 26 };

		if (!isSwap)
		{
			if (iconData.swapTo == null)
				swapTo = "";
			else
				swapTo = iconData.swapTo;
		}

		if (iconData.antialias == null)
			iconData.antialias = true;

		antialiasing = iconData.antialias;

		if (iconData.asset == null)
			iconData.asset = iconDir;

		if (iconData.scale == null || iconData.scale.length < 2)
			iconData.scale = [1, 1];

		if (iconData.flip == null || iconData.flip.length < 2)
			iconData.flip = [false, false];

		if (iconData.offset == null)
			iconData.offset = 26;
		iconOffset = iconData.offset;

		if (iconData.centered == null)
			iconData.centered = false;

		var imagePath:String = iconData.asset;
		if (!Paths.imageExists(imagePath))
			imagePath = "icons/icon-" + TitleState.defaultVariables.noicon;

		if (iconData.stack != null)
		{
			makeGraphic(150, 150, FlxColor.TRANSPARENT);
			makeStack(iconData.stack);
		}
		else if (Paths.sparrowExists(imagePath))
		{
			frames = Paths.sparrow(imagePath);
			allAnims = [];
			for (i in 0...iconData.animations.length)
			{
				var anim = iconData.animations[i];
				if (anim.indices != null && anim.indices.length > 0)
					animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop, iconData.flip[0], iconData.flip[1]);
				else
					animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop, iconData.flip[0], iconData.flip[1]);
				allAnims.push(anim.name);
			}
		}
		else
		{
			var frameCount:Array<Int> = [1, 1];
			if (char == "none" || char == "")
				makeGraphic(150, 150, FlxColor.TRANSPARENT);
			else
			{
				var graphic:FlxGraphic = Paths.image(imagePath);
				frameCount = [Std.int(Math.round(graphic.width / graphic.height)), 1];
				if (iconData.frames != null && iconData.frames.length >= 2)
					frameCount = iconData.frames;
				loadGraphic(graphic, true, Std.int(graphic.width / frameCount[0]), Std.int(graphic.height / frameCount[1]));
			}

			if (iconData.animations == null)
			{
				switch (frameCount[0] + frameCount[1])
				{
					case 1:
						animation.add('idle', [0], 24, true, iconData.flip[0], iconData.flip[1]);
						allAnims = ['idle'];

					case 2:
						animation.add('idle', [0], 24, true, iconData.flip[0], iconData.flip[1]);
						animation.add('losing', [1], 24, true, iconData.flip[0], iconData.flip[1]);
						allAnims = ['idle', 'losing'];

					default:
						animation.add('idle', [0], 24, true, iconData.flip[0], iconData.flip[1]);
						animation.add('losing', [1], 24, true, iconData.flip[0], iconData.flip[1]);
						animation.add('winning', [2], 24, true, iconData.flip[0], iconData.flip[1]);
						allAnims = ['idle', 'losing', 'winning'];
				}
			}
			else
			{
				allAnims = [];
				for (i in 0...iconData.animations.length)
				{
					var anim = iconData.animations[i];
					if (anim.indices != null && anim.indices.length > 0)
						animation.add(anim.name, anim.indices, anim.fps, anim.loop, iconData.flip[0], iconData.flip[1]);
					allAnims.push(anim.name);
				}
			}
		}

		playAnim('idle');
		updateHitbox();
	}

	public function playAnim(anim:String)
	{
		for (i in stack)
			i.sprite.playAnim(anim);

		if (allAnims.contains(anim))
			animation.play(anim);
		else if (allAnims.contains(anim.split("_to_")[1]))
			animation.play(anim.split("_to_")[1]);
	}

	public function transitionTo(anim:String)
	{
		for (i in stack)
			i.sprite.transitionTo(anim);

		if (animation.curAnim != null)
		{
			if (!animation.curAnim.name.endsWith(anim))
			{
				var curState:String = animation.curAnim.name;
				if (curState.indexOf("_to_") > 0)
					curState.split("_to_")[1];

				playAnim(curState + "_to_" + anim);
			}
		}
	}

	public function swapIcon()
	{
		if (swapTo != "")
			reloadIcon(swapTo, true);
	}

	override public function updateHitbox()
	{
		scale.set(sc.x * iconData.scale[0], sc.y * iconData.scale[1]);

		super.updateHitbox();
	}

	override public function draw()
	{
		if (stack.length > 0)
		{
			for (i in stack)
			{
				var xx:Float = (x + (width / 2)) + (i.position[0] * sc.x);
				var yy:Float = (y + (height / 2)) + (i.position[1] * sc.y);
				if (flipX)
				{
					xx = (x + (width / 2)) - (i.position[0] * sc.x);
					i.sprite.flipX = true;
				}
				if (flipY)
				{
					yy = (y + (height / 2)) - (i.position[1] * sc.y);
					i.sprite.flipY = true;
				}
				i.sprite.setPosition(xx, yy);
				i.sprite.scale.set(sc.x * i.sprite.iconData.scale[0] * i.scale, sc.y * i.sprite.iconData.scale[0] * i.scale);
				i.sprite.offset.set(i.sprite.width / 2, i.sprite.height / 2);
				i.sprite.color = color;
				i.sprite.alpha = alpha;
				i.sprite.cameras = cameras;
				i.sprite.draw();
			}
		}
		else
			super.draw();
	}
}