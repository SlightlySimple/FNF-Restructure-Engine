package;

import flixel.FlxG;
import lime.app.Application;

using StringTools;

class Util
{
	public static function version():String
	{
		return Std.string(Application.current.meta.get('version'));
	}

	public static function menuMusic()
	{
		if (!FlxG.sound.music.playing)
			Conductor.playMusic("freakyMenu");
	}

	public static function splitFile(content:String):Array<String>
	{
		return content.replace("\r","").split("\n");
	}

	public static function generateIndices(a:Int, b:Int):Array<Int>
	{
		var i:Int = Std.int(Math.min(a,b));
		var ret:Array<Int> = [];

		if (i == a)
		{
			for (j in i...b+1)
				ret.push(j);
		}
		else
		{
			for (j in i...a+1)
				ret.push(j);
			ret.reverse();
		}
		return ret;
	}

	public static function loop(val:Int, min:Int, max:Int):Int
	{
		var ret:Int = val;

		while (ret < min)
			ret += (max - min) + 1;

		while (ret > max)
			ret -= (max - min) + 1;

		return ret;
	}
}