package transitions;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

typedef Sticker =
{
	var x:Float;
	var y:Float;
	var scale:Float;
	var angle:Float;
	var graphic:String;
}

typedef StickerData =
{
	var stickers:Dynamic;
	var sounds:Array<String>;
}

class StickerSubState extends FlxSubState
{
	public static var stickerSet:String = "stickers-set-1";
	public static var stickers:Array<Sticker> = [];

	public static function switchState(newState:FlxState)
	{
		var state:FlxState = FlxG.state;
		if (state.subState != null)
		{
			while (state.subState != null)
				state = state.subState;
		}

		state.openSubState(new StickerSubState(newState));
	}

	override public function new(?next:FlxState = null)
	{
		super();

		camera = new FlxCamera();
		camera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camera, false);

		var stickerData:StickerData = cast Paths.jsonImages("ui/stickers/" + stickerSet + "/stickers");
		if (stickerData.sounds != null && stickerData.sounds.length > 0)
		{
			for (sound in stickerData.sounds)
				FlxG.sound.cache(Paths.sound("ui/stickers/" + sound));
		}

		if (next != null)
		{
			var stickerTypes:Array<String> = Reflect.fields(stickerData.stickers);

			var stickerGraphics:Map<String, FlxSprite> = new Map<String, FlxSprite>();

			var xx:Float = -100;
			var yy:Float = -100;
			while (yy <= FlxG.height)
			{
				var stickerType:String = FlxG.random.getObject(stickerTypes);
				var stickerGraphic:String = FlxG.random.getObject(Reflect.field(stickerData.stickers, stickerType));
				stickers.push({x: xx, y: yy, scale: 1, angle: FlxG.random.int(-60, 70), graphic: stickerSet + "/" + stickerGraphic});
				if (!stickerGraphics.exists(stickerGraphic))
					stickerGraphics[stickerGraphic] = new FlxSprite(0, 0, Paths.image("ui/stickers/" + stickerSet + "/" + stickerGraphic));
				xx += stickerGraphics[stickerGraphic].frameWidth / 2;
				if (xx >= FlxG.width)
				{
					xx = -100;
					yy += FlxG.random.float(70, 120);
				}
			}

			FlxG.random.shuffle(stickers);

			for (s in stickers)
			{
				var spr:FlxSprite = new FlxSprite(s.x, s.y, Paths.image("ui/stickers/" + s.graphic));
				spr.angle = s.angle;
				spr.alpha = 0.001;
				add(spr);

				var tm:Float = stickers.indexOf(s) / stickers.length;
				new FlxTimer().start(tm * 0.9, function(tmr:FlxTimer) {
					spr.alpha = 1;
					if (stickerData.sounds != null && stickerData.sounds.length > 0)
					{
						var sound:String = FlxG.random.getObject(stickerData.sounds);
						FlxG.sound.play(Paths.sound("ui/stickers/" + sound));
					}

					var frameTimer:Int = FlxG.random.int(0, 2);
					new FlxTimer().start(frameTimer / 24, function(tmr:FlxTimer) {
						spr.scale.x = spr.scale.y = FlxG.random.float(0.97, 1.02);
						s.scale = spr.scale.x;
					});
				});
			}

			new FlxTimer().start(0.9, function(tmr:FlxTimer) {
				MusicBeatState.doTransIn = false;
				MusicBeatState.doTransOut = false;
				FlxG.switchState(next);
			});
		}
		else
		{
			for (s in stickers)
			{
				var spr:FlxSprite = new FlxSprite(s.x, s.y, Paths.image("ui/stickers/" + s.graphic));
				spr.scale.x = spr.scale.y = s.scale;
				spr.angle = s.angle;
				add(spr);

				var tm:Float = (stickers.length - stickers.indexOf(s)) / stickers.length;
				new FlxTimer().start(tm * 0.9, function(tmr:FlxTimer) {
					if (stickerData.sounds != null && stickerData.sounds.length > 0)
					{
						var sound:String = FlxG.random.getObject(stickerData.sounds);
						FlxG.sound.play(Paths.sound("ui/stickers/" + sound));
					}
					remove(spr, true);
					spr.kill();
					spr.destroy();
				});
			}

			new FlxTimer().start(0.9, function(tmr:FlxTimer) {
				stickers = [];
				stickerSet = "stickers-set-1";
				close();
			});
		}
	}
}