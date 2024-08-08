package menus.story;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

import data.Options;

class StoryWeekButton extends FlxSprite
{
	var colors:Array<FlxColor> = [FlxColor.WHITE, 0xFF33ffff];

	override public function new(x:Int, y:Int, image:String)
	{
		super(x, y);
		loadGraphic(Paths.image("ui/story/weeks/" + image));
	}

	public function flicker()
	{
		if (!Options.options.flashingLights)
			return;

		new FlxTimer().start(0.05, function(tmr:FlxTimer)
		{
			if (color == colors[0])
				color = colors[1];
			else
				color = colors[0];
		}, 0);
	}
}