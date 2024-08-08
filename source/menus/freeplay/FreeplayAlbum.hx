package menus.freeplay;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

import objects.AnimatedSprite;

using StringTools;

class FreeplayAlbum extends FlxSpriteGroup
{
	var cover:FlxSprite;
	var title:AnimatedSprite;

	public var album(default, set):String = "";

	var anim:String = "";
	var animFrame:Int = 0;
	var animFrameProgress:Float = 0;

	var animEnter:Array<Array<Float>> = [[1313,423,219,1064,857.5,0],[1264,410,155,1064,857.5,0],[1164,408,122,1064,857.5,0],[1072,414,6,1064,550.5,1],[],[1079,414,9,1064,557.5,0],[],[1081,413,10,1064,557.5,0],[],[],[1082,413,10,1064,557.5,0]];
	var animSwitch:Array<Array<Float>> = [[1082,421,10,1064,550.5,1],[],[1082,413,10,1064,557.5,0]];

	override public function new()
	{
		super(0, 0);

		cover = new FlxSprite(951, 282, Paths.image("ui/freeplay/albums/volume1/art"));
		cover.active = false;
		cover.angle = 10;
		add(cover);

		title = new AnimatedSprite(947, 491, Paths.tiles("ui/freeplay/albums/volume1/title", 1, 2));
		title.active = false;
		title.animation.add("idle", [0, 1], 0);
		title.animation.play("idle");
		add(title);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (anim != "")
		{
			var animFrames:Array<Array<Float>> = [];
			switch (anim)
			{
				case "enter": animFrames = animEnter;
				case "switch": animFrames = animSwitch;
			}

			if (animFrames[animFrame].length > 0)
			{
				cover.x = x + animFrames[animFrame][0] - (cover.width / 2);
				cover.y = y + animFrames[animFrame][1] - (cover.height / 2);
				cover.angle = animFrames[animFrame][2];
				title.x = x + animFrames[animFrame][3] - (title.width / 2);
				title.y = y + animFrames[animFrame][4] - (title.height / 2);
				title.animation.curAnim.curFrame = Std.int(animFrames[animFrame][5]);
			}

			animFrameProgress += elapsed;
			if (animFrameProgress >= 1 / 24)
			{
				while (animFrameProgress >= 1 / 24)
				{
					animFrame++;
					animFrameProgress -= 1 / 24;
				}
			}

			if (animFrame >= animFrames.length)
				anim = "";
		}
	}

	public function set_album(val:String):String
	{
		if (val != album)
		{
			if (val.trim() != "" && Paths.imageExists("ui/freeplay/albums/" + val + "/art"))
			{
				if (visible)
					doAnim("switch");
				else
					doAnim("enter");

				visible = true;
				cover.loadGraphic(Paths.image("ui/freeplay/albums/" + val + "/art"));
				cover.updateHitbox();
				title.frames = Paths.tiles("ui/freeplay/albums/" + val + "/title", 1, 2);
				title.animation.add("idle", [0, 1], 0);
				title.animation.play("idle");
				title.updateHitbox();
			}
			else
				visible = false;
		}

		return album = val;
	}

	function doAnim(anim:String)
	{
		this.anim = anim;
		animFrame = 0;
		animFrameProgress = 0;
	}
}