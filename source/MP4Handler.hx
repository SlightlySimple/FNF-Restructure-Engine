package;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.events.Event;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import vlc.VlcBitmap;

// THIS IS FOR TESTING
// DONT STEAL MY CODE >:(
class MP4Handler
{
	public static var video:Video;
	public static var netStream:NetStream;
	public static var finishCallback:Void->Void = null;
	public var sprite:FlxSprite;
	public var volume:Float = 1.0;
	#if desktop
	public static var vlcBitmap:VlcBitmap;
	#end

	public function new()
	{
		FlxG.autoPause = false;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}
	}

	public function playMP4(path:String, callback:Void->Void, ?outputTo:FlxSprite = null, ?repeat:Bool = false, ?isWindow:Bool = false, ?isFullscreen:Bool = false):Void
	{
		#if html5
		FlxG.autoPause = false;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}

		finishCallback = callback;

		video = new Video();
		video.x = 0;
		video.y = 0;

		FlxG.addChildBelowMouse(video);

		var nc = new NetConnection();
		nc.connect(null);

		netStream = new NetStream(nc);
		netStream.client = {onMetaData: client_onMetaData};

		nc.addEventListener("netStatus", netConnection_onNetStatus);

		netStream.play(path);
		#else
		finishCallback = callback;

		vlcBitmap = new VlcBitmap();
		vlcBitmap.set_height(FlxG.stage.stageHeight);
		vlcBitmap.set_width(FlxG.stage.stageHeight * (16 / 9));

		trace("Setting width to " + FlxG.stage.stageHeight * (16 / 9));
		trace("Setting height to " + FlxG.stage.stageHeight);

		vlcBitmap.onVideoReady = onVLCVideoReady;
		vlcBitmap.onComplete = onVLCComplete;
		vlcBitmap.onError = onVLCError;

		FlxG.stage.addEventListener(Event.ENTER_FRAME, update);

		if (repeat)
			vlcBitmap.repeat = -1;
		else
			vlcBitmap.repeat = 0;

		vlcBitmap.inWindow = isWindow;
		vlcBitmap.fullscreen = isFullscreen;

		FlxG.addChildBelowMouse(vlcBitmap);
		vlcBitmap.play(checkFile(path));
		if (outputTo != null)
		{
			// lol this is bad kek
			vlcBitmap.alpha = 0;

			sprite = outputTo;
		}
		#end
	}

	#if desktop
	function checkFile(fileName:String):String
	{
		var pDir = "";
		var appDir = "file:///" + Sys.getCwd() + "/";

		if (fileName.indexOf(":") == -1) // Not a path
			pDir = appDir;
		else if (fileName.indexOf("file://") == -1 || fileName.indexOf("http") == -1) // C:, D: etc? ..missing "file:///" ?
			pDir = "file:///";

		return pDir + fileName;
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function onVLCVideoReady()
	{
		trace("video loaded!");
		if (sprite != null)
			sprite.loadGraphic(vlcBitmap.bitmapData);	
	}

	public function onVLCComplete()
	{
		vlcBitmap.stop();

		// Clean player, just in case!
		vlcBitmap.dispose();

		if (FlxG.game.contains(vlcBitmap))
		{
			FlxG.game.removeChild(vlcBitmap);
		}

		trace("Big, Big Chungus, Big Chungus!");

		if (finishCallback != null)
			finishCallback();
	}

	function onVLCError()
	{
		if (finishCallback != null)
			finishCallback();
	}

	function update(e:Event)
	{
		vlcBitmap.volume = volume * ((FlxG.sound.volume <= 0.01 || FlxG.sound.muted) ? 0 : (FlxG.sound.volume * 0.5) + 0.5); // shitty volume fix
	}
	#end

	/////////////////////////////////////////////////////////////////////////////////////

	function client_onMetaData(path)
	{
		video.attachNetStream(netStream);

		video.width = FlxG.width;
		video.height = FlxG.height;
	}

	function netConnection_onNetStatus(path)
	{
		if (path.info.code == "NetStream.Play.Complete")
		{
			finishVideo();
		}
	}

	function finishVideo()
	{
		netStream.dispose();

		if (FlxG.game.contains(video))
		{
			FlxG.game.removeChild(video);
		}

		if (finishCallback != null)
			finishCallback();
	}

	// old html5 player
	/*
		var nc:NetConnection = new NetConnection();
		nc.connect(null);
		var ns:NetStream = new NetStream(nc);
		var myVideo:Video = new Video();
		myVideo.width = FlxG.width;
		myVideo.height = FlxG.height;
		myVideo.attachNetStream(ns);
		ns.play(path);
		return myVideo;
		ns.close();
	 */
}
