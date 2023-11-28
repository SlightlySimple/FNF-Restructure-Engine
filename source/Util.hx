package;

import flixel.FlxG;
import flixel.FlxSprite;
import lime.app.Application;
import objects.AnimatedSprite;

using StringTools;

class Util
{
	public static var menuSong:String = "freakyMenu";

	public static function version():String
	{
		return Std.string(Application.current.meta.get('version'));
	}

	public static function menuMusic()
	{
		if (!FlxG.sound.music.playing)
			Conductor.playMusic(menuSong);
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

	public static function CreateSprite(asset:String, ?x:Float = 0, ?y:Float = 0, ?inSong:Bool = false):FlxSprite
	{
		if (inSong)
		{
			if (Paths.sparrowSongExists(asset))
				return new AnimatedSprite(x, y, Paths.sparrowSong(asset));

			return new FlxSprite(x, y, Paths.imageSong(asset));
		}

		if (Paths.sparrowExists(asset))
			return new AnimatedSprite(x, y, Paths.sparrow(asset));

		return new FlxSprite(x, y, Paths.image(asset));
	}

	public static function PlaySound(sound:String, ?volume:Float = 1.0)
	{
		if (Paths.soundExists(sound))
			FlxG.sound.play(Paths.sound(sound), volume);
	}
}