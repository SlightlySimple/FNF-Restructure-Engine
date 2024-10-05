package menus.characterSelect;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.BitmapFilter;
import openfl.filters.DropShadowFilter;
import objects.FilteredSprite;
import flxanimate.FlxAnimate;

class CharacterSelectIcon extends FilteredSprite
{
	var character:String = "";

	var lock:FlxAnimate;
	static var lockColors:Array<FlxColor> = [];
	var selectedFilters:Array<BitmapFilter> = [
		new DropShadowFilter(0, 0, 0xFFFFFF, 1, 2, 2, 19, 1, false, false, false),
		new DropShadowFilter(5, 45, 0x000000, 1, 2, 2, 1, 1, false, false, false)
	];

	static var animFrames:Array<Array<Float>> = [];
	var anim:Bool = false;
	var animFrame:Int = 0;
	var animTimer:Float = 0;

	override public function new(x:Float, y:Float, id:Int, character:String)
	{
		super(x, y);

		if (animFrames.length <= 0)
		{
			var animFramesFile:Array<String> = Util.splitFile(Paths.text("characterSelect/iconBopInfo"));
			for (c in animFramesFile)
			{
				var nums:Array<String> = c.split(" ");
				var numsFloat:Array<Float> = [];
				for (num in nums)
					numsFloat.push(Std.parseFloat(num));
				animFrames.push(numsFloat);
			}
		}

		if (lockColors.length <= 0)
		{
			var lockColorsFile:Array<String> = Util.splitFile(Paths.text("characterSelect/lockColors"));
			for (c in lockColorsFile)
			{
				var lockColorsRGB:Array<String> = c.split(",");
				lockColors.push(FlxColor.fromRGB(Std.parseInt(lockColorsRGB[0]), Std.parseInt(lockColorsRGB[1]), Std.parseInt(lockColorsRGB[2])));
			}
		}

		lock = new FlxAnimate(x, y, Paths.atlas("ui/character_select/lock"));
		lock.anim.addByFrameName("idle", "idle", 24);
		lock.anim.addByFrameName("selected", "selected", 24);
		lock.anim.addByFrameName("clicked", "clicked", 24);
		lock.anim.addByFrameName("unlock", "unlock", 24);
		lock.playAnim("idle");

		var lockShader:FlxRuntimeShader = new FlxRuntimeShader(Paths.shader("colormap"));
		lockShader.data.image.input = Paths.image("ui/character_select/lock/colormap").bitmap;
		var colorID:Int = id;
		if (colorID >= lockColors.length)
			colorID = lockColors.length - 1;
		var lockColor:FlxColor = lockColors[colorID];
		lockShader.data.rgb.value = [lockColor.redFloat, lockColor.greenFloat, lockColor.blueFloat];
		lock.shader = lockShader;

		if (character != "")
			setCharacter(character);
		antialiasing = false;
	}

	public function setCharacter(char:String)
	{
		if (character != char)
		{
			character = char;

			frames = Paths.sparrow("ui/freeplay/icons/" + character + "pixel");
			animation.addByPrefix('idle', 'idle0', 10, true);
			animation.addByPrefix('confirm', 'confirm0', 10, false);
			animation.play("idle");
			setGraphicSize(128, 128);
			updateHitbox();
			scale.set(2, 2);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (character == "")
			lock.update(elapsed);

		if (anim)
		{
			animTimer += elapsed;
			if (animTimer >= 1 / 24)
			{
				while (animTimer >= 1 / 24)
				{
					animTimer -= 1 / 24;
					animFrame++;
				}
				if (animFrame >= 13)
					filters = selectedFilters;

				if (animFrame >= animFrames.length)
				{
					anim = false;
					scale.set(2.6, 2.6);
				}
				else
				{
					var refFrame:Array<Float> = animFrames[animFrames.length - 1];
					var curFrame:Array<Float> = animFrames[animFrame];

					var scaleXDiff:Float = curFrame[3] - refFrame[4];
					var scaleYDiff:Float = curFrame[4] - refFrame[4];

					scale.set(2.6, 2.6);
					scale.add(scaleXDiff, scaleYDiff);
				}
			}
		}
	}

	public function onSelected()
	{
		if (character == "")
			lock.playAnim("selected");
		else
		{
			scale.set(2.6, 2.6);
			filters = selectedFilters;
		}
	}

	public function onUnselected()
	{
		if (character == "")
			lock.playAnim("idle");
		else
		{
			scale.set(2, 2);
			filters = [];
		}
	}

	public function onClicked()
	{
		if (character == "")
			lock.playAnim("clicked");
		else
			animation.play("confirm");
	}

	public function onUnclicked()
	{
		if (character == "")
			lock.playAnim("selected");
		else
			animation.play("idle");
	}

	public function unlock()
	{
		if (character == "")
		{
			lock.playAnim("unlock");
			FlxG.sound.play(Paths.sound("ui/character_select/CS_unlock"), 0.7);
		}
	}

	public function bop()
	{
		anim = true;
		animFrame = 0;
		animTimer = 0;
	}

	override public function draw()
	{
		if (character == "")
		{
			lock.setPosition(x, y);
			lock.scrollFactor.set(scrollFactor.x, scrollFactor.y);
			lock.draw();
		}
		else
			super.draw();
	}
}