package menus.freeplay;

import flixel.FlxG;

typedef FreeplayTrack =
{
	var name:String;
	var timings:Array<Array<Float>>;
	var start:Float;
	var end:Float;
}

class FreeplayMusicManager
{
	var curTrack:FreeplayTrack = null;
	var defaultTrack:FreeplayTrack = null;
	var randomTrack:FreeplayTrack = null;

	public function new()
	{
		defaultTrack = {name: Paths.music(Util.menuSong), timings: [[0, Std.parseFloat(Paths.raw("music/" + Util.menuSong + ".bpm"))]], start: -1, end: -1};
		randomTrack = {name: Paths.music("freeplayRandom"), timings: [[0, Std.parseFloat(Paths.raw("music/freeplayRandom.bpm"))]], start: -1, end: -1};
		curTrack = defaultTrack;
	}

	public function switchTrack(newTrack:FreeplayTrack, ?forced:Bool = false)
	{
		if (curTrack.name != newTrack.name || forced)
		{
			curTrack = newTrack;
			FlxG.sound.music.stop();
			FlxG.sound.playMusic(curTrack.name, 0);
			FlxG.sound.music.fadeIn(0.5, 0, 0.7);

			if (curTrack.end > curTrack.start)
			{
				FlxG.sound.music.time = curTrack.start;
				FlxG.sound.music.loopTime = curTrack.start;
				FlxG.sound.music.endTime = curTrack.end;
				Conductor.songPosition = FlxG.sound.music.time;
			}
			else
			{
				FlxG.sound.music.loopTime = 0;
				FlxG.sound.music.endTime = null;
				Conductor.songPosition = 0;
			}
			Conductor.overrideSongPosition = false;
			Conductor.recalculateTimings(curTrack.timings);
		}
	}

	public function switchToDefaultTrack(?forced:Bool = false)
	{
		if (curTrack.name != defaultTrack.name || !FlxG.sound.music.playing || forced)
		{
			curTrack = defaultTrack;
			FlxG.sound.music.stop();
			Util.menuMusic();
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.fadeIn(0.5, 0, 0.7);
		}
	}

	public function switchToRandomTrack(?forced:Bool = false)
	{
		switchTrack(randomTrack, forced);
	}

	public function menuMusic()
	{
		if (curTrack.name != Paths.music(Util.menuSong))
		{
			FlxG.sound.music.stop();
			Conductor.playMusic(Util.menuSong, 0.7);
		}
	}
}