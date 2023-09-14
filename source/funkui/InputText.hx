package funkui;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUIInputText;
import flash.events.KeyboardEvent;
import lime.system.Clipboard;

using StringTools;

class InputText extends FlxUIInputText
{
	override public function new(X:Float = 0, Y:Float = 0, Width:Int = 230, ?Text:String, size:Int = 18, TextColor:Int = FlxColor.BLACK, BackgroundColor:Int = FlxColor.WHITE, EmbeddedFont:Bool = true)
	{
		super(X, Y, Width, Text, size, TextColor, BackgroundColor, EmbeddedFont);

		font = "VCR OSD Mono";
	}

	override private function onKeyDown(e:KeyboardEvent):Void
	{
		var key:Int = e.keyCode;

		if (hasFocus && FlxG.keys.pressed.CONTROL)
		{
			switch (key)
			{
				// Ctrl + X
				case 88:
					Clipboard.text = text;
					text = "";
					caretIndex = 0;
					onChange("input");
					return;

				// Ctrl + C
				case 67:
					Clipboard.text = text;
					return;

				// Ctrl + V
				case 86:
					if (Clipboard.text != null)
					{
						var tt:String = Clipboard.text.replace("\r", "\\r").replace("\n", "\\n").replace("\t", " ");
						text = insertSubstring(text, tt, caretIndex);
						caretIndex += tt.length;
						onChange("input");
						return;
					}
			}
		}

		super.onKeyDown(e);
	}
}