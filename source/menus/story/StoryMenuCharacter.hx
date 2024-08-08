package menus.story;

import flixel.FlxG;
import flixel.FlxSprite;

import data.ObjectData;
import objects.Character;

class StoryMenuCharacter extends FlxSprite
{
	public var characterData:WeekCharacterData = null;
	public var curCharacter:String = "";
	var animOffsets:Map<String, Array<Int>>;

	var pos:Int = 0;
	public var lastIdle:Int = 0;
	public var danceSpeed:Float = 1;

	override public function new(pos:Int)
	{
		super();
		this.pos = pos;
		animOffsets = new Map<String, Array<Int>>();
		refreshCharacter(TitleState.defaultVariables.story2);
	}

	public static function parseCharacter(id:String):WeekCharacterData
	{
		var data:Dynamic = Paths.json("story_characters/" + id);
		var cData:WeekCharacterData = cast data;

		if (data.image != null)			// This is a Psych Engine character and must be converted to the Restructure Engine format
		{
			var oldPosition:Array<Float> = cast data.position;
			cData = {
				asset: "ui/story/characters/" + data.image,
				position: [Std.int(oldPosition[0] + Math.round(FlxG.width  * 0.25) - 150), Std.int(oldPosition[1])],
				scale: [data.scale, data.scale],
				antialias: true,
				animations: [{name: "idle", prefix: data.idle_anim, fps: 24, loop: false, offsets: [0, 0]}, {name: "hey", prefix: data.confirm_anim, fps: 24, loop: false, offsets: [0, 0]}],
				firstAnimation: "idle",
				idles: ["idle"],
				danceSpeed: 1,
				flip: false,
				matchColor: false
			}
		}

		if (!Paths.imageExists(cData.asset) && Paths.imageExists("ui/story_characters/" + cData.asset))
			cData.asset = "ui/story_characters/" + cData.asset;

		var allAnims:Array<String> = [];
		for (a in cData.animations)
		{
			allAnims.push(a.name);

			if (a.loop == null)
				a.loop = false;

			if (a.fps == null)
				a.fps = 24;

			if (a.indices != null)
				a.indices = Character.uncompactIndices(a.indices);
		}

		if (cData.danceSpeed == null)
			cData.danceSpeed = 1;

		if (cData.scale == null)
			cData.scale = [1, 1];

		if (cData.flip == null)
			cData.flip = false;

		if (cData.matchColor == null)
			cData.matchColor = true;

		if (cData.idles == null)
		{
			if (allAnims.contains("danceLeft") && allAnims.contains("danceRight"))
				cData.idles = ["danceLeft", "danceRight"];
			else if (allAnims.contains("idle"))
				cData.idles = ["idle"];
			else
				cData.idles = [];
		}

		return cData;
	}

	public function refreshCharacter(char:String)
	{
		if (char != curCharacter)
		{
			curCharacter = char;
			if (!Paths.jsonExists("story_characters/" + char))
				curCharacter = TitleState.defaultVariables.story2;

			if (characterData != null)
			{
				danceSpeed = 1;
				animOffsets.clear();
			}

			characterData = parseCharacter(curCharacter);

			frames = Paths.sparrow(characterData.asset);
			for (i in 0...characterData.animations.length)
			{
				var anim = characterData.animations[i];
				if (anim.indices != null && anim.indices.length > 0)
					animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
				else
					animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
				animOffsets.set(anim.name, anim.offsets);
			}

			danceSpeed = characterData.danceSpeed;

			flipX = characterData.flip;

			if (characterData.scale != null && characterData.scale.length == 2)
				scale.set(characterData.scale[0], characterData.scale[1]);
			else
				scale.set(1, 1);
			updateHitbox();

			playAnim(characterData.firstAnimation);

			antialiasing = characterData.antialias;
		}

		x += characterData.position[0];
		y += characterData.position[1];
	}

	public function playAnim(animName:String, forced:Bool = false)
	{
		if (animOffsets.exists(animName))
		{
			animation.play(animName, forced);
			offset.x = animOffsets.get(animName)[0];
			offset.y = animOffsets.get(animName)[1];
		}
	}

	public function dance()
	{
		if (characterData.idles.length <= 0)
			return;

		if (lastIdle < characterData.idles.length)
			playAnim(characterData.idles[lastIdle], true);
		lastIdle = (lastIdle + 1) % characterData.idles.length;
	}
}