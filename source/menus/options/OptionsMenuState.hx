package menus.options;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;

class OptionsMenuState extends MusicBeatState
{
	override public function create()
	{
		var bg:FlxSprite = new FlxSprite(Paths.image("ui/" + MainMenuState.menuImages[3]));
		bg.color = MainMenuState.menuColors[3];
		bg.active = false;
		add(bg);

		add(new OptionsMenu());

		super.create();
	}
}

class OptionsMenuSubState extends FlxSubState
{
	var from:Int = 0;

	override public function new(from:Int = 0)
	{
		super();
		this.from = from;
	}

	override public function create()
	{
		super.create();
		var menu = new OptionsMenu(from);
		switch (from)
		{
			case 1: menu.exitCallback = function() { close(); }
			case 2: menu.exitCallback = function() { FlxG.save.data.setupOptions = true; FlxG.save.flush(); MusicBeatState.doTransIn = false; FlxG.switchState(new TitleState()); }
			default: menu.exitCallback = function() { FlxG.switchState(new MainMenuState()); }
		}
		add(menu);
	}
}