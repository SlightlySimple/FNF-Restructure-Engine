package menus.freeplay;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class FreeplayDifficultyDot extends FlxSprite
{
	var normalColors:Array<FlxColor> = [0xFF484848, 0xFFFFFFFF];
	var nightColors:Array<FlxColor> = [0xFF34296A, 0xFFC28AFF];

	var difficultyId:String;
	var colors:Array<FlxColor> = [];

	override public function new(id:String, num:Int)
	{
		super(30 * num);
		difficultyId = id;
		colors = (difficultyId == "erect" || difficultyId == "nightmare" || difficultyId == "challenge") ? nightColors : normalColors;

		loadGraphic(Paths.image("ui/freeplay/seperator"));
	}

	public function updateSelected(difficulty:String, ?instant:Bool = false)
	{
		FlxTween.cancelTweensOf(this);

		if (difficulty == difficultyId)
			color = colors[1];
		else if (instant)
			color = colors[0];
		else
			FlxTween.color(this, 0.5, color, colors[0], {ease: FlxEase.quartOut});
	}
}