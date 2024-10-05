package menus.characterSelect;

import flixel.FlxSprite;
import flixel.addons.display.FlxRuntimeShader;
import flixel.util.FlxTimer;

class CharacterSelectNametag extends FlxSprite
{
	public var xx:Float = 0;
	public var yy:Float = 0;
	var mosaic:FlxRuntimeShader;
	var character:String = "";

	override public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		loadGraphic(Paths.image("ui/character_select/lockedNametag"));
		xx = x;
		yy = y;
		scale.set(0.77, 0.77);
		mosaic = new FlxRuntimeShader(Paths.shader("mosaic"));
		mosaic.setFloatArray("uBlocksize", [1, 1]);
		shader = mosaic;
		resetPosition();
	}

	function resetPosition()
	{
		setPosition(xx - width / 2, yy - height / 2);
	}

	public function setCharacter(char:String)
	{
		if (character != char)
		{
			character = char;

			mosaic.setFloatArray("uBlocksize", [width / 10, height / 10]);
			new FlxTimer().start(1 / 30, function(tmr:FlxTimer) { mosaic.setFloatArray("uBlocksize", [width / 73, height / 6]); });
			new FlxTimer().start(2 / 30, function(tmr:FlxTimer) { mosaic.setFloatArray("uBlocksize", [width / 10, height / 10]); });
			new FlxTimer().start(4 / 30, function(tmr:FlxTimer) {
				if (character == "")
					loadGraphic(Paths.image("ui/character_select/lockedNametag"));
				else
					loadGraphic(Paths.image("ui/character_select/characters/" + character + "/" + character + "Nametag"));
				scale.set(1, 1);
				updateHitbox();
				scale.set(0.77, 0.77);
				resetPosition();
				mosaic.setFloatArray("uBlocksize", [1, 1]);
			});
			new FlxTimer().start(5 / 30, function(tmr:FlxTimer) { mosaic.setFloatArray("uBlocksize", [width / 27, height / 26]); });
			new FlxTimer().start(6 / 30, function(tmr:FlxTimer) { mosaic.setFloatArray("uBlocksize", [width / 10, height / 10]); });
			new FlxTimer().start(7 / 30, function(tmr:FlxTimer) { mosaic.setFloatArray("uBlocksize", [1, 1]); });
		}
	}
}