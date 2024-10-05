package menus.freeplay;

import flixel.FlxSprite;
import flixel.util.FlxColor;

class FreeplayCharacterIcon extends FlxSprite
{
	override public function new(x:Float, y:Float, char:String)
	{
		super(x, y);
		antialiasing = false;
		scale.set(2, 2);
		refreshCharacter(char);
	}

	public function refreshCharacter(char:String)
	{
		if (char == "lock")
			loadGraphic(Paths.image("ui/freeplay/lock"));
		else if (char == "none")
			makeGraphic(32, 32, FlxColor.TRANSPARENT);
		else if (Paths.sparrowExists("ui/freeplay/icons/" + char + "pixel"))
		{
			frames = Paths.sparrow("ui/freeplay/icons/" + char + "pixel");
			var allAnimData:String = "";
			if (Paths.exists("images/ui/freeplay/icons/" + char + "pixel.txt"))
				allAnimData = Paths.raw("images/ui/freeplay/icons/" + char + "pixel.txt");
			else
				allAnimData = Paths.raw("images/ui/freeplay/icons/" + char + "pixel.xml");

			animation.addByPrefix("idle", "idle0", 10, true);

			if (allAnimData.indexOf("confirm0") > -1)
				animation.addByPrefix("confirm", "confirm0", 10, false);

			if (allAnimData.indexOf("confirm-hold0") > -1)
				animation.addByPrefix("confirm-hold", "confirm-hold0", 10, true);

			animation.play("idle");
		}
		else
			loadGraphic(Paths.image("ui/freeplay/icons/" + char + "pixel"));
	}

	public function confirm()
	{
		if (animation.exists("confirm"))
		{
			animation.play("confirm");
			if (animation.exists("confirm-hold"))
				animation.finishCallback = function(anim:String) { animation.play("confirm-hold"); }
		}
	}
}