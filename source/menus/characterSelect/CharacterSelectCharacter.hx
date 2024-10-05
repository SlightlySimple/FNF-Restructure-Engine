package menus.characterSelect;

import flixel.FlxSprite;
import flxanimate.FlxAnimate;

class CharacterSelectCharacter extends FlxSprite
{
	var character:String = "";

	var atlas:FlxAnimate;
	var usingAtlas:Bool = false;
	var animOffsets:Map<String, Array<Int>> = new Map<String, Array<Int>>();

	public var curAnim(get, never):String;
	public var curAnimFinished(get, never):Bool;

	override public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		atlas = new FlxAnimate(0, 0, Paths.atlas("ui/character_select/characters/bf/bfChill"));
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (usingAtlas)
			atlas.update(elapsed);

		if (curAnimFinished && (curAnim == "slidein" || curAnim == "cannot select Label"))
			playAnim("idle");
	}

	public function setCharacter(char:String, asset:String)
	{
		if (character != char)
		{
			character = char;

			if (Paths.sparrowExists("ui/character_select/" + asset))
			{
				usingAtlas = false;
				frames = Paths.sparrow("ui/character_select/" + asset);
				var offsetFile:Array<String> = Util.splitFile(Paths.textImages("ui/character_select/" + asset));
				var pos:Array<String> = offsetFile[0].split(",");
				setPosition(Std.parseInt(pos[0]), Std.parseInt(pos[1]));
				animOffsets.clear();
				for (i in 1...offsetFile.length)
				{
					var offset:Array<String> = offsetFile[i].split(",");
					animOffsets[offset[0]] = [Std.parseInt(offset[1]), Std.parseInt(offset[2])];
				}

				for (a in ["slidein", "slideout", "idle", "select", "confirm", "deselect", "unlock", "death", "cannot select Label"])
					animation.addByPrefix(a, a + "0", 24, false);
			}
			else
			{
				usingAtlas = true;
				setPosition(0, 0);
				offset.set();
				atlas.loadAtlas(Paths.atlas("ui/character_select/" + asset));

				for (a in ["slidein", "slideout", "idle", "select", "confirm", "deselect", "unlock", "death", "cannot select Label"])
					atlas.anim.addByFrameName(a, a, 24);
			}
		}
	}

	public function playAnim(anim:String)
	{
		if (usingAtlas)
			atlas.playAnim(anim);
		else
		{
			animation.play(anim, true);
			if (animOffsets.exists(anim))
				offset.set(animOffsets[anim][0], animOffsets[anim][1]);
			else
				offset.set();
		}
	}

	public function get_curAnim():String
	{
		if (usingAtlas)
			return atlas.curAnim;
		return animation.curAnim.name;
	}

	public function get_curAnimFinished():Bool
	{
		@:privateAccess
		if (usingAtlas)
			return atlas.anim.curFrame >= atlas.anim.frameLength - 1;
		return animation.curAnim.finished;
	}

	override public function draw()
	{
		if (usingAtlas)
		{
			atlas.setPosition(x, y);
			atlas.scrollFactor.set(scrollFactor.x, scrollFactor.y);
			atlas.draw();
		}
		else
			super.draw();
	}
}