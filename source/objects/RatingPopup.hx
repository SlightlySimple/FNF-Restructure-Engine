package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import data.ObjectData;
import data.Options;

class RatingPopup extends FlxSprite
{
	var skinName:String;
	var skin:UISkin;

	public static var sparrows:Map<String, Bool>;

	public function refresh(type:Int, value:Int, skinName:String, skin:UISkin):RatingPopup
	{
		var comboType:Int = Options.options.comboType;

		this.skin = skin;
		this.skinName = skinName;
		alpha = 1;

		switch (type)
		{
			case 0:
				setPosition((FlxG.width * 0.55) + 100, 275);
				staticOrAnimatedGraphic(skin.judgements[value]);

				if (comboType == 2)
				{
					acceleration.y = 550;
					velocity.set(-FlxG.random.int(0, 10), -FlxG.random.int(140, 175));
				}

				doPosition(skin.judgements[value]);
				doScale(skin.judgements[value]);
				x -= width / 2;
				y -= height / 2;

				x += Options.options.judgementOffset[0];
				y += Options.options.judgementOffset[1];

			case 1:
				setPosition((FlxG.width * 0.55) - 90, FlxG.height * 0.4 + 80);
				staticOrAnimatedGraphic(skin.combo);

				if (comboType == 2)
				{
					acceleration.y = 600;
					velocity.set(FlxG.random.int(1, 10), -150);
				}

				doPosition(skin.combo);
				doScale(skin.combo);

				x += Options.options.comboOffset[0];
				y += Options.options.comboOffset[1];

			case 2:
				staticOrAnimatedGraphic(skin.numbers[value]);
				doScale(skin.numbers[value]);

				screenCenter(Y);
				x = (FlxG.width * 0.55) - 90;
				y += 80;
				doPosition(skin.numbers[value]);

				if (comboType == 2)
				{
					acceleration.y = FlxG.random.int(200, 300);
					velocity.set(FlxG.random.float(-5, 5), -FlxG.random.int(140, 160));
				}

				x += Options.options.comboOffset[0];
				y += Options.options.comboOffset[1];
		}

		if (type < 3)
		{
			if (comboType == 2)
			{
				if (type == 2)
					FlxTween.tween(this, {alpha: 0}, 0.2, {startDelay: Conductor.beatSeconds * 2, onComplete: function(twn:FlxTween) { destroy(); }});
				else
					FlxTween.tween(this, {alpha: 0}, 0.2, {startDelay: Conductor.beatSeconds, onComplete: function(twn:FlxTween) { destroy(); }});
			}
			else
			{
				y += 15;
				FlxTween.tween(this, {y: y - 15}, 0.1, {ease: FlxEase.quadOut});
				FlxTween.tween(this, {alpha: 0}, 0.2, {startDelay: Conductor.stepSeconds * 2, onComplete: function(twn:FlxTween) { destroy(); }});
			}
		}

		return this;
	}

	function staticOrAnimatedGraphic(_graphic:UISprite)
	{
		var key:String = "ui/skins/" + skinName + "/" + _graphic.asset;
		if (!sparrows.exists(key))
			sparrows[key] = Paths.sparrowExists(key);	// This check is somewhat resource intensive, so we store it's return value each time to ensure we only have to do it once per asset
		if (sparrows[key])
		{
			frames = Paths.sparrow(key);
			animation.addByPrefix("idle", _graphic.animation, _graphic.fps, _graphic.loop);
			animation.play("idle");
		}
		else
			loadGraphic(Paths.image(key));

		if (_graphic.antialias == null)
			antialiasing = skin.antialias;
		else
			antialiasing = _graphic.antialias;
	}

	function doPosition(_graphic:UISprite)
	{
		if (_graphic.position != null && _graphic.position.length >= 2)
		{
			x += _graphic.position[0];
			y += _graphic.position[1];
		}
	}

	function doScale(_graphic:UISprite)
	{
		if (_graphic.scale != null && _graphic.scale.length >= 2)
		{
			scale.set(_graphic.scale[0], _graphic.scale[1]);
			updateHitbox();
		}
	}
}

class CountdownPopup extends RatingPopup
{
	override public function new(value:Int, skinName:String, skin:UISkin)
	{
		super();
		refresh(3, 0, skinName, skin);

		staticOrAnimatedGraphic(skin.countdown[value]);
		doScale(skin.countdown[value]);
		screenCenter();
		doPosition(skin.countdown[value]);

		FlxTween.tween(this, {y: y + 100, alpha: 0}, Conductor.beatSeconds, { ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween) { destroy(); } });
	}
}