package objects;

import flash.display.BitmapData;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

class FunkBar extends FlxBar
{
	public var emptyColor:FlxColor;
	public var fillColor:FlxColor;
	public var borderColor:FlxColor;

	public var borderWidth:Int = 1;
	public var centerPosition(get, never):Float;

	override public function createFilledBar(empty:FlxColor, fill:FlxColor, showBorder:Bool = false, border:FlxColor = FlxColor.WHITE):FunkBar
	{
		super.createFilledBar(empty, fill, showBorder, border);
		emptyColor = empty;
		fillColor = fill;
		borderColor = border;
		
		return this;
	}

	public function recreateFilledBar():FunkBar
	{
		createFilledBar(emptyColor, fillColor, true, borderColor);

		return this;
	}

	override public function createColoredEmptyBar(empty:FlxColor, showBorder:Bool = false, border:FlxColor = FlxColor.WHITE):FunkBar
	{
		if (FlxG.renderTile)
		{
			var emptyKey:String = "empty: " + barWidth + "x" + barHeight + ":" + empty.toHexString();
			if (showBorder)
				emptyKey += ",border: " + border.toHexString();

			if (!FlxG.bitmap.checkCache(emptyKey))
			{
				var emptyBar:BitmapData = null;

				if (showBorder)
				{
					emptyBar = new BitmapData(barWidth, barHeight, true, border);
					emptyBar.fillRect(new Rectangle(borderWidth, borderWidth, barWidth - (borderWidth*2), barHeight - (borderWidth*2)), empty);
				}
				else
					emptyBar = new BitmapData(barWidth, barHeight, true, empty);

				FlxG.bitmap.add(emptyBar, false, emptyKey);
			}

			frames = FlxG.bitmap.get(emptyKey).imageFrame;
		}
		else
		{
			if (showBorder)
			{
				_emptyBar = new BitmapData(barWidth, barHeight, true, border);
				_emptyBar.fillRect(new Rectangle(borderWidth, borderWidth, barWidth - (borderWidth*2), barHeight - (borderWidth*2)), empty);
			}
			else
				_emptyBar = new BitmapData(barWidth, barHeight, true, empty);

			_emptyBarRect.setTo(0, 0, barWidth, barHeight);
			updateEmptyBar();
		}

		return this;
	}

	override public function createColoredFilledBar(fill:FlxColor, showBorder:Bool = false, border:FlxColor = FlxColor.WHITE):FunkBar
	{
		if (FlxG.renderTile)
		{
			var filledKey:String = "filled: " + barWidth + "x" + barHeight + ":" + fill.toHexString();
			if (showBorder)
				filledKey += ",border: " + border.toHexString();

			if (!FlxG.bitmap.checkCache(filledKey))
			{
				var filledBar:BitmapData = null;

				if (showBorder)
				{
					filledBar = new BitmapData(barWidth, barHeight, true, border);
					filledBar.fillRect(new Rectangle(borderWidth, borderWidth, barWidth - (borderWidth*2), barHeight - (borderWidth*2)), fill);
				}
				else
					filledBar = new BitmapData(barWidth, barHeight, true, fill);

				FlxG.bitmap.add(filledBar, false, filledKey);
			}

			frontFrames = FlxG.bitmap.get(filledKey).imageFrame;
		}
		else
		{
			if (showBorder)
			{
				_filledBar = new BitmapData(barWidth, barHeight, true, border);
				_filledBar.fillRect(new Rectangle(borderWidth, borderWidth, barWidth - (borderWidth*2), barHeight - (borderWidth*2)), fill);
			}
			else
				_filledBar = new BitmapData(barWidth, barHeight, true, fill);

			_filledBarRect.setTo(0, 0, barWidth, barHeight);
			updateFilledBar();
		}
		return this;
	}

	public function get_centerPosition():Float
	{
		var perc:Float = percent / 100;
		if ((fillDirection == LEFT_TO_RIGHT && flipX) || (fillDirection == RIGHT_TO_LEFT && !flipX))
			perc = 1 - perc;
		return (x + borderWidth) + ((width - (borderWidth * 2)) * perc);
	}
}