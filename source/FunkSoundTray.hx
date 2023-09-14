package;

import flixel.FlxG;
import flixel.system.ui.FlxSoundTray;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import openfl.utils.Assets;

class FunkSoundTray extends FlxSoundTray
{
	override public function new()
	{
		super();

		removeChildAt(1);

		var text:TextField = new TextField();
		text.width = _width;
		text.height = 30;
		text.selectable = false;

		var dtf:TextFormat = new TextFormat(Assets.getFont("assets/fonts/vcr.ttf").fontName, 12, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "VOLUME";
		text.y = 14;
	}

	override public function show(Silent:Bool = false)
	{
		if (!Silent)
			FlxG.sound.play(Paths.sound("ui/scrollMenu"));

		_timer = 1;
		y = 0;
		visible = true;
		active = true;
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

		if (FlxG.sound.muted)
			globalVolume = 0;

		for (i in 0..._bars.length)
		{
			if (i < globalVolume)
				_bars[i].alpha = 1;
			else
				_bars[i].alpha = 0.5;
		}
	}
}