package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.FlxCamera;
import data.Options;
import menus.MainMenuState;
import transitions.StickerSubState;
import scripting.HscriptHandler;

class MusicBeatState extends FlxState
{
	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	override public function create()
	{
		super.create();
		persistentUpdate = true;
		FlxG.camera.bgColor = FlxColor.BLACK;

		if (doTransIn)
		{
			if (Paths.hscriptExists("data/scripts/" + customTransition))
			{
				var transitionScript:HscriptHandler = new HscriptHandler("data/scripts/" + customTransition);
				transitionScript.execFunc("transitionIn", []);
			}
			else
			{
				var state:FlxState = this;
				if (state.subState != null)
				{
					while (state.subState != null)
						state = state.subState;
				}
				state.add(new FunkinTransition(this, false));
			}
		}
		else
			doTransIn = true;

		customTransition = "";

		if (!Std.isOfType(FlxG.state, MainMenuState) && StickerSubState.stickers.length > 0)
			openSubState(new StickerSubState());
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.update(elapsed);

		if (Std.int(Math.floor(Conductor.stepFromTime(Conductor.songPosition))) != curStep)
		{
			curStep = Std.int(Math.floor(Conductor.stepFromTime(Conductor.songPosition)));
			stepHit();
		}

		if (Std.int(Math.floor(Conductor.beatFromTime(Conductor.songPosition))) != curBeat)
		{
			curBeat = Std.int(Math.floor(Conductor.beatFromTime(Conductor.songPosition)));
			beatHit();
		}
	}

	public static var wasMute:Bool = false;
	override public function onFocusLost()
	{
		if (Options.options != null && !Options.options.autoPause && Options.options.autoMute)
		{
			MusicBeatState.wasMute = FlxG.sound.muted;
			FlxG.sound.muted = true;
		}
	}

	override public function onFocus()
	{
		if (Options.options != null && !Options.options.autoPause && Options.options.autoMute)
			FlxG.sound.muted = MusicBeatState.wasMute;
	}

	public function beatHit() {}

	public function stepHit() {}

	public static var doTransIn:Bool = true;
	public static var doTransOut:Bool = true;
	var transStarted:Bool = false;
	public var transComplete:Bool = false;
	public static var customTransition:String = "";

	override public function switchTo(nextState:FlxState):Bool
	{
		if (!doTransOut)
		{
			doTransOut = true;
			return true;
		}

		if (!transStarted)
			startTransOut(nextState);

		return transComplete;
	}

	function startTransOut(nextState:FlxState)
	{
		transStarted = true;
		if (Paths.hscriptExists("data/scripts/" + customTransition))
		{
			var transitionScript:HscriptHandler = new HscriptHandler("data/scripts/" + customTransition);
			transitionScript.variables.set("finishTransition", function() {
				transComplete = true;
				Paths.clearCache();
				FlxG.switchState(nextState);
			});
			transitionScript.execFunc("transitionOut", []);
		}
		else
			add(new FunkinTransition(this, true, nextState));
	}
}

class MusicBeatSubState extends FlxSubState
{
	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.update(elapsed);

		if (Std.int(Math.floor(Conductor.stepFromTime(Conductor.songPosition))) != curStep)
		{
			curStep = Std.int(Math.floor(Conductor.stepFromTime(Conductor.songPosition)));
			stepHit();
		}

		if (Std.int(Math.floor(Conductor.beatFromTime(Conductor.songPosition))) != curBeat)
		{
			curBeat = Std.int(Math.floor(Conductor.beatFromTime(Conductor.songPosition)));
			beatHit();
		}
	}

	public function beatHit() {}

	public function stepHit() {}
}

class FunkinTransition extends FlxSprite
{
	var camTrans:FlxCamera;
	var loading:FlxSprite;

	override public function new(parent:MusicBeatState, out:Bool, ?nextState:FlxState = null)
	{
		super();

		loading = new FlxSprite(0, 0, Paths.image("ui/loading"));
		loading.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
		loading.updateHitbox();
		loading.visible = false;

		if (out)
			pixels = FlxGradient.createGradientBitmapData(Std.int(FlxG.width), Std.int(FlxG.height * 2), [FlxColor.BLACK, FlxColor.BLACK, FlxColor.TRANSPARENT]);
		else
			pixels = FlxGradient.createGradientBitmapData(Std.int(FlxG.width), Std.int(FlxG.height * 2), [FlxColor.TRANSPARENT, FlxColor.BLACK, FlxColor.BLACK]);
		scrollFactor.set();
		if (out)
			y = -height;
		else
			y = -FlxG.height;

		if (out)
		{
			FlxTween.tween(this, {y: 0}, 0.7, {onComplete: function(twn:FlxTween)
			{
				loading.visible = true;
				parent.transComplete = true;
				Paths.clearCache();
				FlxG.switchState(nextState);
			}});
		}
		else
		{
			FlxTween.tween(this, {y: FlxG.height}, 0.7, {onComplete: function(twn:FlxTween)
			{
				destroy();
			}});
		}

		camTrans = new FlxCamera();
		camTrans.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camTrans, false);

		camera = camTrans;
	}

	override public function draw()
	{
		super.draw();
		loading.cameras = cameras;
		if (loading.visible)
			loading.draw();
	}
}