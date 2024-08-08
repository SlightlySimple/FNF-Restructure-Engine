package menus.freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;

import data.Options;
import data.SMFile;
import data.Song;

class FreeplayChartInfo extends FlxSpriteGroup
{
	var bg:FlxSprite;
	var text:FlxText;
	var infoMap:Map<String, Array<String>> = new Map<String, Array<String>>();

	var right:Bool = true;
	var bottom:Bool = true;

	override public function new(?alignX:String = "right", ?alignY:String = "bottom")
	{
		super();

		if (alignX == "left")
			right = false;

		if (alignY == "top")
			bottom = false;

		bg = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		text = new FlxText(5, 5, 0, "", 32);
		text.font = "VCR OSD Mono";
		if (right)
			text.alignment = RIGHT;
		add(text);
	}

	public function reload(songId:String, difficulty:String, ?side:Int = 0, ?artist:String = "")
	{
		if (Options.options.chartInfo && songId != "")
		{
			var label:String = songId.toLowerCase() + difficulty.toUpperCase();
			if (!infoMap.exists(label))
			{
				var chart:SongData = Song.loadSong(songId, difficulty, false);
				if (Paths.smExists(songId))
				{
					var smFile:SMFile = SMFile.load(songId);
					chart = smFile.songData[smFile.difficulties.indexOf(difficulty)];
				}
				var chartInfoArray:Array<String> = [];
				for (i in 0...FreeplaySandbox.sideList.length)
					chartInfoArray.push(Song.calcChartInfo(chart, i));
				infoMap[label] = chartInfoArray;
			}
			text.text = infoMap[label][side];
		}
		else
			text.text = "";

		if (artist != "")
			text.text += Lang.get("#freeplay.songInfo.artist", [artist]) + "\n";
		if (text.text == "")
			bg.visible = false;
		else
		{
			bg.visible = true;
			if (right)
				x = FlxG.width - text.width - 10;
			else
			{
				x = 0;
				bg.scale.x = ((text.width + 10) / FlxG.width);
			}
			if (bottom)
				y = FlxG.height - text.height - 10;
			else
			{
				y = 0;
				bg.scale.y = ((text.height + 10) / FlxG.height);
			}
			bg.updateHitbox();
		}
	}
}