package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import game.PlayState;

class SongArtist extends FlxSpriteGroup
{
	override public function new(song:String, artist:String, charter:String)
	{
		super(0, 150);

		var text:FlxText = new FlxText(10, 10, 0, song + "\n\n").setFormat(PlayState.instance.uiFont, 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		if (artist != "")
			text.text += Lang.get("#game.artist", [artist]);
		if (charter != "")
		{
			if (artist != "")
				text.text += "\n";
			text.text += Lang.get("#game.charter", [charter]);
		}

		var bg:FlxSprite = new FlxSprite().makeGraphic(Std.int(text.width + 20), Std.int(text.height + 20), FlxColor.WHITE);
		bg.alpha = 0.5;
		add(bg);

		add(text);

		if (FlxG.state == PlayState.instance)
		{
			cameras = [PlayState.instance.camOther];
			PlayState.instance.add(this);
		}

		x -= width;
		doTween();
	}

	public function doTween()
	{
		FlxTween.tween(this, {x: 0}, 0.5, {ease: FlxEase.quintOut, onComplete: function(twn:FlxTween) {
			new FlxTimer().start(3, function(tmr:FlxTimer) {
				FlxTween.tween(this, {x: -width}, 0.5, {ease: FlxEase.quintIn, onComplete: function(twn:FlxTween) {
					PlayState.instance.remove(this, true);
					PlayState.instance.songArtist = null;
					destroy();
				}});
			});
		}});
	}
}