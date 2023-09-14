package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.util.FlxAxes;
import data.Options;
import game.PlayState;

class AnimatedSprite extends FlxSprite
{
	var animOffsets:Map<String, Array<Int>>;
	var hasOffsets:Bool = false;

	public var idles:Array<String> = [];
	public var lastIdle:Int = 0;
	public var danceSpeed:Float = 1;

	@:noCompletion
	override function initVars():Void
	{
		super.initVars();

		animation = new AnimatedSpriteController(this);
	}

	override public function new(?x:Float = 0, ?y:Float = 0, ?frames:FlxFramesCollection = null)
	{
		super(x, y);
		if (frames != null)
			this.frames = frames;

		animOffsets = new Map<String, Array<Int>>();
	}

	public function addOffsets(anim:String, pos:Array<Int>)
	{
		animOffsets.set(anim, pos);
		hasOffsets = true;
	}

	public function updateOffsets()
	{
		if (hasOffsets && animation.curAnim != null)
		{
			if (animOffsets.exists(animation.curAnim.name))
			{
				var offsets:Array<Int> = animOffsets.get(animation.curAnim.name);
				offset.set(offsets[0], offsets[1]);
			}
			else
				offset.set();
		}
	}

	public function flip(axes:FlxAxes = X)
	{
		var anims:Array<String> = animation.getNameList();
		for (a in anims)
		{
			if (!animOffsets.exists(a))
				addOffsets(a, [0, 0]);
		}

		if (animation.curAnim != null)
		{
			var prevAnim:String = animation.curAnim.name;

			var baseFrameWidth = frameWidth;
			var baseFrameHeight = frameHeight;
			for (a in anims)
			{
				animation.play(a, true);
				var offsets:Array<Int> = animOffsets.get(a);

				if (axes.match(X | XY))
				{
					offsets[0] = -offsets[0];
					offsets[0] -= Std.int((baseFrameWidth - frameWidth) * scale.x);
				}

				if (axes.match(Y | XY))
				{
					offsets[1] = -offsets[1];
					offsets[1] -= Std.int((baseFrameHeight - frameHeight) * scale.y);
				}
			}

			if (axes.match(X | XY))
				flipX = !flipX;
			if (axes.match(Y | XY))
				flipY = !flipY;
			animation.play(prevAnim, true);
		}
	}

	public function beatHit()
	{
	}

	public function stepHit()
	{
		var state:MusicBeatState = cast FlxG.state;

		if (Options.options.distractions || PlayState.instance != state)
		{
			if (danceSpeed > 0 && idles.length > 0 && state.curStep % Std.int(Math.round(danceSpeed * 4)) == 0)
			{
				if (animation.curAnim == null || (idles.contains(animation.curAnim.name) || animation.curAnim.finished))
				{
					if (lastIdle < idles.length)
						animation.play(idles[lastIdle], idles.length > 1);
					lastIdle = (lastIdle + 1) % idles.length;
				}
			}
		}
	}
}

class AnimatedSpriteController extends FlxAnimationController
{
	public override function play(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		super.play(AnimName, Force, Reversed, Frame);

		if (Std.isOfType(_sprite, AnimatedSprite))
		{
			var an:AnimatedSprite = cast _sprite;
			an.updateOffsets();
		}
	}
}