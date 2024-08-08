package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxRect;
import flixel.addons.ui.FlxInputText;
import openfl.ui.MouseCursor;
import flash.events.KeyboardEvent;
import flash.geom.Rectangle;
import lime.system.Clipboard;
import data.Options;

using StringTools;

class InputText extends FlxInputText
{
	public var infoText:String = "";

	var fieldBorder:FlxSprite;
	var bg:FlxSprite;
	var selectionBox:FlxSprite;
	var selectionFormat:FlxTextFormat;

	var selectionStart:Int = 0;
	var selectionEnd:Int = 0;
	var selectionMin(get, null):Int;
	var selectionMax(get, null):Int;

	public var hovered:Bool = false;
	public var condition:Void->String = null;

	public static var isOneActive(get, null):Bool = false;
	public static var currentActive:InputText = null;

	public static function get_isOneActive():Bool
	{
		return currentActive != null;
	}

	override public function new(x:Float, y:Float, ?width:Int = 230, ?text:String = "")
	{
		super(x, y, width, "", 20, FlxColor.BLACK, FlxColor.TRANSPARENT, true);

		fieldBorder = new FlxSprite().makeGraphic(width, 30, 0xFF254949);
		bg = new FlxSprite().makeGraphic(width - 4, 26, FlxColor.WHITE);

		selectionBox = new FlxSprite().makeGraphic(1, 26, 0xFF5A78FF);
		selectionFormat = new FlxTextFormat(FlxColor.WHITE);

		font = "FNF Dialogue";
		this.text = text;
	}

	override public function update(elapsed:Float)
	{
		if (DropdownMenu.isOneActive) return;

		if (visible && FlxG.mouse.justMoved)
		{
			if (UIControl.mouseOver(this))
			{
				if (!hovered)
				{
					hovered = true;
					if (infoText != "")
						UIControl.infoText = infoText;
				}
			}
			else if (hovered)
				hovered = false;
		}

		var hadFocus:Bool = hasFocus;
		if (hovered)
		{
			UIControl.cursor = MouseCursor.IBEAM;
			if (Options.mouseJustPressed())
			{
				selectionStart = getCaretIndex();
				hasFocus = true;
				currentActive = this;
				if (!hadFocus && focusGained != null)
					focusGained();
			}
		}
		else if (Options.mouseJustPressed())
		{
			hasFocus = false;
			if (currentActive == this)
				currentActive = null;
			clearFormats();
			if (hadFocus && focusLost != null)
				focusLost();
		}

		if (condition != null && !hasFocus)
		{
			var newVal:String = condition();
			if (text != newVal)
				text = newVal;
		}

		if (hasFocus && Options.mousePressed())
		{
			selectionEnd = getCaretIndex();
			caretIndex = getCaretIndex();
			onSelectionChanged();
		}
	}

	override private function onKeyDown(e:KeyboardEvent)
	{
		var key:Int = e.keyCode;

		if (hasFocus)
		{
			if (FlxG.keys.pressed.CONTROL)
			{
				switch (key)
				{
					// Ctrl + A
					case 65:
						selectionStart = 0;
						selectionEnd = text.length;
						onSelectionChanged();
						return;

					// Ctrl + X
					case 88:
						if (selectionMax > selectionMin)
						{
							Clipboard.text = text.substring(selectionMin, selectionMax);
							text = text.substring(0, selectionMin) + text.substring(selectionMax);
							caretIndex = selectionMin;
							selectionStart = caretIndex;
							selectionEnd = caretIndex;
							onSelectionChanged();
							onChange(FlxInputText.BACKSPACE_ACTION);
						}
						return;

					// Ctrl + C
					case 67:
						if (selectionMax > selectionMin)
							Clipboard.text = text.substring(selectionMin, selectionMax);
						return;

					// Ctrl + V
					case 86:
						if (Clipboard.text != null)
						{
							if (selectionMax > selectionMin)
							{
								text = text.substring(0, selectionMin) + text.substring(selectionMax);
								caretIndex = selectionMin;
								selectionStart = caretIndex;
								selectionEnd = caretIndex;
								onSelectionChanged();
								onChange(FlxInputText.BACKSPACE_ACTION);
							}

							var tt:String = Clipboard.text.replace("\r", "\\r").replace("\n", "\\n").replace("\t", " ");
							text = insertSubstring(text, tt, caretIndex);
							caretIndex += tt.length;
							onChange(FlxInputText.INPUT_ACTION);
							return;
						}
				}
			}

			switch (key)
			{
				// Do nothing for Shift, Ctrl, Esc, and flixel console hotkey
				case 16 | 17 | 27: return;

				// Left arrow
				case 37:
					if (FlxG.keys.pressed.SHIFT)
					{
						if (selectionEnd > 0)
						{
							selectionEnd--;
							caretIndex = selectionEnd;
							onSelectionChanged();
							text = text; // forces scroll update
						}
					}
					else if (caretIndex > 0)
					{
						caretIndex--;
						selectionStart = caretIndex;
						selectionEnd = caretIndex;
						onSelectionChanged();
						text = text; // forces scroll update
					}

				// Right arrow
				case 39:
					if (FlxG.keys.pressed.SHIFT)
					{
						if (selectionEnd < text.length)
						{
							selectionEnd++;
							caretIndex = selectionEnd;
							onSelectionChanged();
							text = text; // forces scroll update
						}
					}
					else if (caretIndex < text.length)
					{
						caretIndex++;
						selectionStart = caretIndex;
						selectionEnd = caretIndex;
						onSelectionChanged();
						text = text; // forces scroll update
					}

				// End key
				case 35:
					caretIndex = text.length;
					selectionStart = caretIndex;
					selectionEnd = caretIndex;
					onSelectionChanged();
					text = text; // forces scroll update

				// Home key
				case 36:
					caretIndex = 0;
					selectionStart = caretIndex;
					selectionEnd = caretIndex;
					onSelectionChanged();
					text = text;

				// Backspace
				case 8:
					if (selectionMax > selectionMin)
					{
						text = text.substring(0, selectionMin) + text.substring(selectionMax);
						caretIndex = selectionMin;
						selectionStart = caretIndex;
						selectionEnd = caretIndex;
						onSelectionChanged();
						onChange(FlxInputText.BACKSPACE_ACTION);
					}
					else if (caretIndex > 0)
					{
						caretIndex--;
						text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
						onChange(FlxInputText.BACKSPACE_ACTION);
					}

				// Delete
				case 46:
					if (selectionMax > selectionMin)
					{
						text = text.substring(0, selectionMin) + text.substring(selectionMax);
						caretIndex = selectionMin;
						selectionStart = caretIndex;
						selectionEnd = caretIndex;
						onSelectionChanged();
						onChange(FlxInputText.BACKSPACE_ACTION);
					}
					else if (text.length > 0 && caretIndex < text.length)
					{
						text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
						onChange(FlxInputText.DELETE_ACTION);
					}

				// Enter
				case 13: onChange(FlxInputText.ENTER_ACTION);

				// For some reason it's impossible to type a space if shift is held, so I'm adding it manually
				case 32:
					var newText:String = " ";

					if (newText.length > 0 && (maxLength == 0 || (text.length + newText.length) < maxLength))
					{
						if (selectionMax > selectionMin)
						{
							text = text.substring(0, selectionMin) + text.substring(selectionMax);
							caretIndex = selectionMin;
							selectionStart = caretIndex;
							selectionEnd = caretIndex;
							onSelectionChanged();
							onChange(FlxInputText.BACKSPACE_ACTION);
						}

						text = insertSubstring(text, newText, caretIndex);
						caretIndex++;
						onChange(FlxInputText.INPUT_ACTION);
					}

				// Actually add some text
				default:
					if (e.charCode == 0) // non-printable characters crash String.fromCharCode
						return;

					var newText:String = filter(String.fromCharCode(e.charCode));

					if (newText.length > 0 && (maxLength == 0 || (text.length + newText.length) < maxLength))
					{
						if (selectionMax > selectionMin)
						{
							text = text.substring(0, selectionMin) + text.substring(selectionMax);
							caretIndex = selectionMin;
							selectionStart = caretIndex;
							selectionEnd = caretIndex;
							onSelectionChanged();
							onChange(FlxInputText.BACKSPACE_ACTION);
						}

						text = insertSubstring(text, newText, caretIndex);
						caretIndex++;
						onChange(FlxInputText.INPUT_ACTION);
					}
			}
		}
	}

	override public function draw():Void
	{
		fieldBorder.setPosition(x, y);
		drawSprite(fieldBorder);
		bg.setPosition(x + 2, y + 2);
		drawSprite(bg);

		if (hasFocus && selectionStart != selectionEnd)
		{
			selectionBox.setPosition(Math.max(x + 2, caretX(selectionMin)), y + 2);
			selectionBox.scale.set(Math.max(1, caretX(selectionMax) - selectionBox.x + 1), 1);
			selectionBox.updateHitbox();
			drawSprite(selectionBox);
		}

		super.draw();
	}

	function caretX(index:Int):Float
	{
		var ret:Float = 0;

		var offx:Float = 0;
		var alignStr:FlxTextAlign = getAlignStr();

		switch (alignStr)
		{
			case RIGHT:
				offx = textField.width - 2 - textField.textWidth - 2;
				if (offx < 0)
					offx = 0;

			case CENTER:
				#if !js
				offx = (textField.width - 2 - textField.textWidth) / 2 + textField.scrollH / 2;
				#end
				if (offx <= 1)
					offx = 0;

			default:
				offx = 0;
		}

		if (index != -1)
		{
			var boundaries:Rectangle = null;

			if (index < text.length)
			{
				boundaries = getCharBoundaries(index);
				if (boundaries != null)
					ret = offx + boundaries.left + x;
			}
			else
			{
				boundaries = getCharBoundaries(index - 1);
				if (boundaries != null)
					ret = offx + boundaries.right + x;
				else if (text.length == 0)
					ret = x + offx + 2;
			}
		}

		ret -= textField.scrollH;

		if (lines == 1 && ret > x + width)
			return x + width - 2;

		return ret;
	}

	function onSelectionChanged()
	{
		clearFormats();
		if (selectionStart != selectionEnd)
			addFormat(selectionFormat, selectionMin, selectionMax);
	}

	function get_selectionMin():Int
	{
		return Std.int(Math.min(selectionStart, selectionEnd));
	}

	function get_selectionMax():Int
	{
		return Std.int(Math.max(selectionStart, selectionEnd));
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		fieldBorder.clipRect = rect;
		bg.clipRect = rect;
		selectionBox.clipRect = rect;
		caret.clipRect = rect;

		return super.set_clipRect(rect);
	}

	override public function destroy()
	{
		fieldBorder = FlxDestroyUtil.destroy(fieldBorder);
		bg = FlxDestroyUtil.destroy(bg);

		super.destroy();
	}
}