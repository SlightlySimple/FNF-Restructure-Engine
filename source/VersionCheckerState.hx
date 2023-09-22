package;

import flixel.FlxG;
import flixel.text.FlxText;
import haxe.xml.Access;

class VersionCheckerState extends MusicBeatState
{
	override public function create()
	{
		super.create();

		var http = new haxe.Http("https://raw.githubusercontent.com/SlightlySimple/FNF-Restructure-Engine/master/Project.xml");

		http.onData = function (data:String) {
			var access:Access = new Access(Xml.parse(data).firstElement());
			var app = access.nodes.app[0];
			var version:String = app.att.version;

			if (version == Util.version())
			{
				MusicBeatState.doTransIn = false;
				MusicBeatState.doTransOut = false;
				FlxG.switchState(new InitState());
			}
			else
			{
				var outdatedText:FlxText = new FlxText(0, 0, 0, "Your Restructure Engine version is outdated.\nYour version is "+Util.version()+" and the latest version is "+version+".\n\nPress ENTER to go to the GitHub page. Press ESCAPE to play the game.", 24);
				outdatedText.font = "VCR OSD Mono";
				outdatedText.alignment = CENTER;
				outdatedText.screenCenter();
				add(outdatedText);
			}
		}

		http.onError = function (error) {
			MusicBeatState.doTransIn = false;
			MusicBeatState.doTransOut = false;
			FlxG.switchState(new InitState());
		}

		http.request();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER)
			FlxG.openURL("https://github.com/SlightlySimple/FNF-Restructure-Engine/releases");

		if (FlxG.keys.justPressed.ESCAPE)
		{
			MusicBeatState.doTransIn = false;
			MusicBeatState.doTransOut = false;
			FlxG.switchState(new InitState());
		}
	}
}