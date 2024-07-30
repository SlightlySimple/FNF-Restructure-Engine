package helpers;

import flixel.system.FlxSound;
import flixel.util.FlxColor;

import lime.media.AudioBuffer;
import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class Waveform
{
	public static function generateWaveform(sound:FlxSound, start:Float, end:Float, width:Int, height:Int):BitmapData
	{
		var waveform:BitmapData = new BitmapData(width, height, true, 0x00000000);

		@:privateAccess
		var buffer:AudioBuffer = sound._sound.__buffer;
		var bytes:Bytes = buffer.data.toBytes();

		var khz:Float = buffer.sampleRate / 1000;
		var channels:Int = buffer.channels;

		var samples:Float = (end - start) * khz;
		var samplesPerRow:Float = samples / height;

		var waveData1:Array<Array<Int>> = [];
		var waveData2:Array<Array<Int>> = [];

		var i:Float = start * khz;
		var j:Float = 0;
		var min1:Int = 65535;
		var max1:Int = -65535;
		var min2:Int = 65535;
		var max2:Int = -65535;
		while (i <= (start * khz) + samples)
		{
			if (i < bytes.length - 1)
			{
				var byte:Int = bytes.getUInt16(Std.int(Math.floor(i) * channels * 2));
				if (byte > 65535 / 2)
					byte -= 65535;

				if (byte < min1)
					min1 = byte;

				if (byte > max1)
					max1 = byte;

				if (channels >= 2)
				{
					byte = bytes.getUInt16(Std.int(Math.floor(i) * channels * 2) + 2);
					if (byte > 65535 / 2)
						byte -= 65535;

					if (byte < min2)
						min2 = byte;

					if (byte > max2)
						max2 = byte;
				}
				else
				{
					min2 = min1;
					max2 = max1;
				}
			}
			if (j >= samplesPerRow)
			{
				waveData1.push([min1, max1]);
				waveData2.push([min2, max2]);
				min1 = 65535;
				max1 = -65535;
				min2 = 65535;
				max2 = -65535;
				j -= samplesPerRow;
			}
			i++;
			j++;
		}

		for (i in 0...waveData1.length)
		{
			var _x:Float = (-waveData1[i][1] * width) / 65536;
			var size:Float = ((-waveData1[i][0] + waveData1[i][1]) * width) / 65536;
			waveform.fillRect(new Rectangle(((width / 2) + _x) / 2, i, Std.int(Math.max(1, size / 2)), 1), FlxColor.WHITE);
		}

		for (i in 0...waveData2.length)
		{
			var _x:Float = (-waveData2[i][1] * width) / 65536;
			var size:Float = ((-waveData2[i][0] + waveData2[i][1]) * width) / 65536;
			waveform.fillRect(new Rectangle((((width / 2) + _x) / 2) + width / 2, i, Std.int(Math.max(1, size / 2)), 1), FlxColor.WHITE);
		}

		return waveform;
	}
}