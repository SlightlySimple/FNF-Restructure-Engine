package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import lime.app.Application;
import lime.media.AudioBuffer;
import sys.io.File;
import haxe.Json;
import haxe.io.Bytes;
import data.ObjectData;
import data.ScoreSystems;
import game.PlayState;
import game.results.ResultsState;
import menus.story.StoryMenuState;
import objects.AnimatedSprite;
import scripting.HscriptState;

using StringTools;

class Util
{
	public static var favoriteSongs:Array<FavoriteSongData> = [];

	public static var menuSong:String = "freakyMenu";

	public static function version():String
	{
		return Std.string(Application.current.meta.get('version'));
	}

	public static function menuMusic()
	{
		if (!FlxG.sound.music.playing)
			Conductor.playMusic(menuSong, 0.7);
	}

	public static function gotoSong(song:String, diff:String, ?difficultyList:Array<String> = null, ?variant:String = "bf", ?variantScore:Bool = false, ?delay:Float = 0.75)
	{
		ResultsState.resetStatics();

		new FlxTimer().start(delay, function(tmr:FlxTimer)
		{
			FlxG.sound.music.fadeOut(0.5, 0, function(twn:FlxTween) { FlxG.sound.music.stop(); });

			PlayState.firstPlay = true;
			PlayState.variantScore = variantScore;
			if (Std.isOfType(FlxG.state, HscriptState))
				HscriptState.setFromState();
			var diffs:Array<String> = [diff];
			if (difficultyList != null && difficultyList.length > 1)
			{
				diffs = difficultyList.copy();
				if (diffs[0] == "normal" && diffs[diffs.length - 1] == "easy")
				{
					diffs.pop();
					diffs.unshift("easy");
				}
				if (!diffs.contains(diff))
					diffs.push(diff);
			}
			FlxG.switchState(new PlayState(false, song, diff, diffs, null, variant));
		});
	}

	public static function gotoWeek(week:String, diff:String, ?difficultyList:Array<String> = null, ?delay:Float = 1)
	{
		ResultsState.resetStatics();
		ScoreSystems.resetWeekData();

		new FlxTimer().start(delay, function(tmr:FlxTimer)
		{
			FlxG.sound.music.fadeOut(0.5, 0, function(twn:FlxTween) { FlxG.sound.music.stop(); });
			PlayState.firstPlay = true;
			PlayState.variantScore = false;
			var weekD:WeekData = StoryMenuState.parseWeek(week, true);
			if (weekD.hscript != null && weekD.hscript != "")
			{
				HscriptState.script = "data/states/" + weekD.hscript;
				FlxG.switchState(new HscriptState());
			}
			else
			{
				if (Std.isOfType(FlxG.state, HscriptState))
					HscriptState.setFromState();
				var diffs:Array<String> = [diff];
				if (difficultyList != null && difficultyList.length > 1)
				{
					diffs = difficultyList.copy();
					if (diffs[0] == "normal" && diffs[diffs.length - 1] == "easy")
					{
						diffs.pop();
						diffs.unshift("easy");
					}
					if (!diffs.contains(diff))
						diffs.push(diff);
				}
				FlxG.switchState(new PlayState(true, "", diff, diffs, week, 0, weekD.songs[0].variant));
			}
		});
	}

	public static function favoriteSong(song:WeekSongData, ?title:String = "", ?artist:String = "", ?group:String = ""):Bool
	{
		var existingSong:FavoriteSongData = null;

		for (s in favoriteSongs)
		{
			if (s.song.songId == song.songId)
			{
				existingSong = s;
				break;
			}
		}

		if (existingSong == null)
		{
			var fav:FavoriteSongData = {
				song: song,
				title: title,
				artist: artist,
				group: group
			}

			favoriteSongs.push(fav);
			File.saveContent("assets/data/favorites.json", Json.stringify(favoriteSongs));
			return true;
		}

		favoriteSongs.remove(existingSong);
		File.saveContent("assets/data/favorites.json", Json.stringify(favoriteSongs));
		return false;
	}

	public static function properCaseString(str:String):String
	{
		var fancyNameBase:Array<String> = str.split("/");
		var fancyNames:Array<String> = [];
		for (n in fancyNameBase)
		{
			var fancyName:String = n.charAt(0).toUpperCase();
			if (n.length > 1)
			{
				for (i in 1...n.length)
				{
					if (n.charAt(i).toUpperCase() == n.charAt(i))
						fancyName += " ";
					fancyName += n.charAt(i);
				}
			}
			fancyNames.push(fancyName);
		}
		var finalName:String = "";
		for (i in 0...fancyNames.length)
		{
			if (i == fancyNames.length - 1)
				finalName += fancyNames[i];
			else
				finalName += "(" + fancyNames[i] + ") ";
		}
		return finalName;
	}

	public static function splitFile(content:String):Array<String>
	{
		return content.replace("\r","").split("\n");
	}

	public static function pixelEase(steps:Float):Float->Float
	{
		return function(val:Float) { return Math.round(val * steps) / steps; }
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

	public static function colorFromArray(rgb:Array<Int>):FlxColor
	{
		return FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
	}

	public static function audioData(sound:FlxSound):Array<Array<Array<Int>>>
	{
		@:privateAccess
		var buffer:AudioBuffer = sound._sound.__buffer;
		var bytes:Bytes = buffer.data.toBytes();

		var khz:Float = buffer.sampleRate / 1000;
		var channels:Int = buffer.channels;

		var samples:Float = sound.length * khz;
		var samplesPerRow:Float = khz;

		var waveData1:Array<Array<Int>> = [];
		var waveData2:Array<Array<Int>> = [];

		var i:Float = 0;
		var j:Float = 0;
		var min1:Int = 65535;
		var max1:Int = -65535;
		var min2:Int = 65535;
		var max2:Int = -65535;
		while (i <= samples)
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

		return [waveData1, waveData2];
	}

	public static function getCharacterNames(ids:Array<String>):Map<String, String>
	{
		var ret:Map<String, String> = new Map<String, String>();
		for (id in ids)
		{
			var hash:String = "#character." + id.replace("/", ".");
			if (Lang.get(hash) != hash)
				ret[id] = Lang.get(hash);
		}
		return ret;
	}

	public static function getStageNames(ids:Array<String>):Map<String, String>
	{
		var ret:Map<String, String> = new Map<String, String>();
		for (id in ids)
		{
			var hash:String = "#stage." + id.replace("/", ".");
			if (Lang.get(hash) != hash)
				ret[id] = Lang.get(hash);
		}
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