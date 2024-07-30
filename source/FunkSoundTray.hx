package;

import flixel.FlxG;
import flixel.system.ui.FlxSoundTray;
import flash.display.Bitmap;
import flash.Lib;
import openfl.utils.Assets;

typedef SoundTrayData =
{
	var barsX:Int;
	var barsY:Int;
	var barsSpacing:Int;
	var barsStack:Bool;
	var bgAlpha:Float;
}

class FunkSoundTray extends FlxSoundTray
{
	var trackedVolume:Float = 1;
	var data:SoundTrayData;

	override public function new()
	{
		super();
		trackedVolume = FlxG.sound.volume;

		rebuildSoundTray();
	}

	public function rebuildSoundTray()
	{
		x = 0;
		y = 0;
		data = cast Paths.json("soundtray");

		removeChildren();

		var tmp:Bitmap = new Bitmap(Assets.getBitmapData(Paths.imagePath("ui/soundtray/volumebox")));
		tmp.scaleX = 0.3;
		tmp.scaleY = 0.3;
		addChild(tmp);

		var bx:Int = data.barsX;
		var by:Int = data.barsY;
		var bs:Int = data.barsSpacing;

		if (data.bgAlpha > 0)
		{
			tmp = new Bitmap(Assets.getBitmapData(Paths.imagePath("ui/soundtray/bars_10")));
			tmp.x = bx + (10 * bs);
			tmp.y = by;
			tmp.scaleX = 0.3;
			tmp.scaleY = 0.3;
			tmp.alpha = data.bgAlpha;
			addChild(tmp);
		}

		_bars = [];
		for (i in 0...10)
		{
			tmp = new Bitmap(Assets.getBitmapData(Paths.imagePath("ui/soundtray/bars_" + Std.string(i + 1))));
			tmp.x = bx + (i * bs);
			tmp.y = by;
			tmp.scaleX = 0.3;
			tmp.scaleY = 0.3;
			addChild(tmp);
			_bars.push(tmp);
		}

		screenCenter();
		y = -height;
		visible = false;
	}

	override public function show(Silent:Bool = false)
	{
		if (!Silent)
		{
			if (FlxG.sound.volume >= 0.98)
				FlxG.sound.play(Paths.sound("soundtray/VolMAX"));
			else if (FlxG.sound.volume < trackedVolume)
				FlxG.sound.play(Paths.sound("soundtray/Voldown"));
			else
				FlxG.sound.play(Paths.sound("soundtray/Volup"));
		}
		trackedVolume = FlxG.sound.volume;

		_timer = 1;
		y = 0;
		visible = true;
		active = true;
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

		if (FlxG.sound.muted)
			globalVolume = 0;

		for (i in 0..._bars.length)
		{
			if (data.barsStack)
			{
				if (i <= globalVolume - 1)
					_bars[i].visible = true;
				else
					_bars[i].visible = false;
			}
			else
			{
				if (i == globalVolume - 1)
					_bars[i].visible = true;
				else
					_bars[i].visible = false;
			}
		}
	}

	override public function screenCenter()
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - width) - FlxG.game.x);
	}
}