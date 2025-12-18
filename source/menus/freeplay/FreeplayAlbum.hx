package menus.freeplay;

import flixel.FlxG;
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

		cover = new FlxSprite(951, 282, Paths.image("ui/freeplay/albums/volume1/volume1"));
		cover.active = false;
		cover.angle = 10;
		add(cover);

		title = new AnimatedSprite(FlxG.width - 355, 500, Paths.sparrow("ui/freeplay/albums/volume1/volume1-text"));
		title.addAnim("idle", "idle", 24, true);
		title.addAnim("switch", "switch", 24, false);
		title.playAnim("idle");
		add(title);
		title.animation.finishCallback = function(name) {
			if (name == "switch") title.playAnim("idle");
		};
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
			if (val.trim() != "" && Paths.imageExists("ui/freeplay/albums/" + val + "/" + val))
			{
				if (visible)
					doAnim("switch");
				else
					doAnim("enter");

				visible = true;
				cover.loadGraphic(Paths.image("ui/freeplay/albums/" + val + "/" + val));
				cover.updateHitbox();
				title.frames = Paths.sparrow("ui/freeplay/albums/" + val + "/" + val + "-text");
				title.addAnim("idle", "idle", 24, true);
				title.addAnim("switch", "switch", 24, false);
				title.playAnim("switch");
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