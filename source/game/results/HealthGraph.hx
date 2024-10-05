package game.results;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import data.Options;

class HealthGraph extends BitmapData
{
	override public function new(width:Int, height:Int, data:Array<Array<Float>>)
	{
		super(width, height, true, 0x80000000);

		var maxWValue:Float = data[data.length - 1][0];

		for (i in 0...data.length - 1)
		{
			var d = data[i];
			var e = data[i+1];

			var xx = Std.int((d[0] / maxWValue) * width);
			var yy = Std.int(((100 - d[1]) / 100) * height);
			var xxNext = Std.int((e[0] / maxWValue) * width);
			var ww = Std.int( xxNext - xx );
			var hh = Std.int( height - yy );
			fillRect(new Rectangle(xx, yy, ww, hh), Options.options.healthBarColorR);
		}
	}
}