package menus.freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.addons.effects.FlxTrail;
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.BitmapFilterQuality;

import data.Options;
import data.ObjectData;
import data.Song;
import menus.freeplay.FreeplayMenuSubState;
import objects.AnimatedSprite;

class FreeplayCapsule extends FlxSpriteGroup
{
	public var index(default, set):Int = 0;
	public var text(default, set):String = "";
	public var icon(default, set):String = "none";
	public var lit(default, set):Bool = true;
	public var filter:String = "";
	public var tracks:Map<String, FreeplayTrack> = new Map<String, FreeplayTrack>();

	public var songId:String = "";		// This can be either the category ID or the song ID, but having one variable is simpler
	public var songUnlocked:Bool = true;
	public var songArtist:String = "";
	public var songInfo:WeekSongData = null;
	public var songAlbums:Map<String, String> = new Map<String, String>();
	public var rank(default, set):Int = -1;
	public var favorited:Bool = false;

	public var capsule:AnimatedSprite;
	var txt:FlxText;
	var txtBlur:FlxText;
	var iconGraphic:FlxSprite;
	var favIcon:AnimatedSprite;
	var favIconBlurred:AnimatedSprite;
	public var ranking:AnimatedSprite;
	public var blurredRanking:AnimatedSprite;
	var sparkle:AnimatedSprite;
	var sparkleTimer:FlxTimer;

	public var quickInfo:Map<String, SongQuickInfo> = new Map<String, SongQuickInfo>();
	public var curQuickInfo(default, set):SongQuickInfo = null;
	public var chartSide(default, set):Int = 0;
	public var weekType(default, set):Int = 0;
	var bpmText:FlxSprite;
	var bpmNum:FreeplayCapsuleNum;
	var difficultyText:FlxSprite;
	public var difficultyNum:FreeplayCapsuleNum;
	var weekTypeText:AnimatedSprite;
	var weekTypeNum:FreeplayCapsuleNum;

	var maxTxtWidth(default, set):Int = 290;

	var txtMoving:Bool = false;
	var txtMinX:Float = 0;
	var txtMaxX:Float = 0;
	var txtW:Float = 0;
	var txtTimer:Float = 0;

	public var anim:String = "";
	var animFrame:Int = 0;
	var animFrameProgress:Float = 0;

	var animEnterX:Array<Float> = [0.9, 0.4, 0.16, 0.16, 0.22, 0.22, 0.245];
	var animExitX:Array<Float> = [0.245, 0.75, 0.98, 0.98, 1.2];
	var animExitScaleX:Array<Float> = [1.7, 1.8, 0.85, 0.85, 0.97, 0.97, 1];

	public override function new()
	{
		super();

		capsule = new AnimatedSprite(Paths.sparrow("ui/freeplay/capsule/freeplayCapsule"));
		capsule.addAnim("selected", "mp3 capsule w backing0", 24, true);
		capsule.addOffsets("selected", [0, 0]);
		capsule.addAnim("unselected", "mp3 capsule w backing NOT SELECTED", 24, true);
		capsule.addOffsets("unselected", [-5, 0]);
		capsule.playAnim("unselected");
		capsule.scale.set(0.8, 0.8);
		add(capsule);

		var blur:FlxRuntimeShader = new FlxRuntimeShader(Paths.shader("gaussianBlur"), null);
		blur.data._amount.value = [1];
		var blur2:FlxRuntimeShader = new FlxRuntimeShader(Paths.shader("gaussianBlur"), null);
		blur2.data._amount.value = [1.2];

		txtBlur = new FlxText(156, 45, 0, "", 32);
		txtBlur.font = "5by7";
		txtBlur.color = 0xFF00CCFF;
		txtBlur.shader = blur;
		add(txtBlur);

		txt = new FlxText(156, 45, 0, "", 32);
		txt.font = "5by7";
		add(txt);

		ranking = new AnimatedSprite(420, 41, Paths.sparrow("ui/freeplay/capsule/rankbadges"));
		blurredRanking = new AnimatedSprite(420, 41, Paths.sparrow("ui/freeplay/capsule/rankbadges"));
		for (r in [ranking, blurredRanking])
		{
			r.addAnim('LOSS', 'LOSS rank0', 24, false);
			r.addAnim('GOOD', 'GOOD rank0', 24, false);
			r.addAnim('GREAT', 'GREAT rank0', 24, false);
			r.addAnim('EXCELLENT', 'EXCELLENT rank0', 24, false);
			r.addAnim('PERFECT', 'PERFECT rank0', 24, false);
			r.addAnim('PERFECTSICK', 'PERFECT rank GOLD', 24, false);
			r.playAnim("LOSS");
			r.blend = ADD;
			r.scale.set(0.9, 0.9);
			r.alpha = 0;
			add(r);
		}
		blurredRanking.shader = blur;

		sparkle = new AnimatedSprite(ranking.x, ranking.y, Paths.sparrow("ui/freeplay/capsule/sparkle"));
		sparkle.addAnim('sparkle', 'sparkle', 24, false);
		sparkle.playAnim('sparkle', true);
		sparkle.scale.set(0.8, 0.8);
		sparkle.blend = ADD;
		sparkle.alpha = 0;
		add(sparkle);
		sparkleTimer = new FlxTimer().start(1, sparkleEffect);

		iconGraphic = new FlxSprite(160, 35);
		iconGraphic.makeGraphic(32, 32, FlxColor.TRANSPARENT);
		iconGraphic.antialiasing = false;
		iconGraphic.active = false;
		add(iconGraphic);

		favIcon = new AnimatedSprite(405, 40, Paths.sparrow("ui/freeplay/capsule/favHeart"));
		favIconBlurred = new AnimatedSprite(favIcon.x, favIcon.y, Paths.sparrow("ui/freeplay/capsule/favHeart"));
		for (f in [favIconBlurred, favIcon])
		{
			f.addAnim('fav', 'favorite heart', 24, false);
			f.playAnim('fav');
			f.setGraphicSize(50, 50);
			f.alpha = 0;
			f.blend = ADD;
			add(f);
		}
		favIconBlurred.shader = blur2;

		bpmText = new FlxSprite(144, 87, Paths.image("ui/freeplay/capsule/bpmtext"));
		bpmText.active = false;
		bpmText.scale.set(0.9, 0.9);
		add(bpmText);

		bpmNum = new FreeplayCapsuleNum(185, 88, true);
		add(bpmNum);

		difficultyText = new FlxSprite(414, 87, Paths.image("ui/freeplay/capsule/difficultytext"));
		difficultyText.active = false;
		difficultyText.scale.set(0.9, 0.9);
		add(difficultyText);

		difficultyNum = new FreeplayCapsuleNum(466, 32, false);
		add(difficultyNum);

		weekTypeText = new AnimatedSprite(291, 87, Paths.sparrow("ui/freeplay/capsule/weektypes"));
		weekTypeText.addAnim("WEEK", "WEEK text", 24, false);
		weekTypeText.addAnim("WEEKEND", "WEEKEND text", 24, false);
		weekTypeText.active = false;
		weekTypeText.scale.set(0.9, 0.9);
		add(weekTypeText);

		weekTypeNum = new FreeplayCapsuleNum(355, 88, true);
		add(weekTypeNum);
	}

	override public function destroy()
	{
		if (sparkleTimer != null)
		{
			sparkleTimer.cancel();
			sparkleTimer.destroy();
		}
		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (impactThing != null)
			impactThing.angle = capsule.angle;

		switch (anim)
		{
			case "enter":
				capsule.scale.x = animExitScaleX[Std.int(Math.min(animFrame, animExitScaleX.length - 1))];
				capsule.scale.y = 1 / capsule.scale.x;
				x = FlxG.width * animEnterX[Std.int(Math.min(animFrame, animEnterX.length - 1))];

				capsule.scale.x *= 0.8;
				capsule.scale.y *= 0.8;

				animFrameProgress += elapsed;
				if (animFrameProgress >= 1 / 24)
				{
					while (animFrameProgress >= 1 / 24)
					{
						animFrame++;
						animFrameProgress -= 1 / 24;
					}
				}

				if (animFrame >= animEnterX.length)
					anim = "";

			case "exit":
				capsule.scale.x = animExitScaleX[Std.int(Math.min(animFrame, animExitScaleX.length - 1))];
				capsule.scale.y = 1 / capsule.scale.x;
				x = FlxG.width * animExitX[Std.int(Math.min(animFrame, animExitX.length - 1))];

				capsule.scale.x *= 0.8;
				capsule.scale.y *= 0.8;

				animFrameProgress += elapsed;
				if (animFrameProgress >= 1 / 24)
				{
					while (animFrameProgress >= 1 / 24)
					{
						animFrame++;
						animFrameProgress -= 1 / 24;
					}
				}

			case "":
				x = FlxMath.lerp(x, 270 + 60 * Math.sin(index), 0.3);
				y = FlxMath.lerp(y, intendedY(), 0.4);

				if (txtMoving)
				{
					if (index == 1)
					{
						if (txtTimer <= 0.3)
							txt.x = x + txtMaxX;
						else if (txtTimer <= 2.3)
						{
							var tweenVal:Float = (txtTimer - 0.3) / 2;
							txt.x = x + txtMaxX + ((txtMinX - txtMaxX) * FlxEase.sineInOut(tweenVal));
						}
						else if (txtTimer <= 2.6)
							txt.x = x + txtMinX;
						else if (txtTimer <= 4.6)
						{
							var tweenVal:Float = (txtTimer - 2.6) / 2;
							txt.x = x + txtMinX + ((txtMaxX - txtMinX) * FlxEase.sineInOut(tweenVal));
						}
						else
							txtTimer = 0;
						txtTimer += elapsed;
					}
					else
					{
						txt.x = x + txtMaxX;
						txtTimer = -0.3;
					}

					txtBlur.x = txt.x;

					var rect:FlxRect = new FlxRect(-((txt.x - x) - txtMinX), 0, txtW, txt.height);
					txt.clipRect = rect;
					txtBlur.clipRect = rect;
				}
		}
	}

	public function updateFavorited(?canBeFavorited:Bool = true, ?anim:Bool = false)
	{
		favorited = false;
		if (canBeFavorited)
		{
			for (s in Util.favoriteSongs)
			{
				if (s.song.songId == songId)
				{
					favorited = true;
					break;
				}
			}
		}

		if (anim)
		{
			if (favorited)
			{
				favIcon.alpha = 1;
				favIcon.animation.play("fav");
				favIcon.animation.finishCallback = null;
				FlxG.sound.play(Paths.sound("freeplay/fav"));
			}
			else
			{
				favIcon.animation.play("fav", true, true, 9);
				new FlxTimer().start((favIcon.animation.curAnim.numFrames - 9) / 24, function(tmr:FlxTimer) { favIcon.alpha = 0; updateSelected(); });
				FlxG.sound.play(Paths.sound("freeplay/unfav"));
			}
		}
		else
		{
			favIcon.alpha = (favorited ? 1 : 0);
			favIcon.animation.play("fav");
			favIcon.animation.finish();
		}
		updateSelected();
	}

	function intendedY():Float
	{
		if (index < 0)
			return index * (height * 0.8 + 10) + 20;
		return index * (height * 0.8 + 10) + 120;
	}

	public function snapToPosition()
	{
		setPosition(270 + 60 * Math.sin(index), intendedY());
	}

	public function doAnim(anim:String)
	{
		this.anim = anim;
		animFrame = 0;
		animFrameProgress = 0;
	}

	function resetMovingText()
	{
		if (txt.width > maxTxtWidth)
		{
			txtMoving = true;
			txtMinX = 156;
			txtMaxX = txtMinX - (txt.width - maxTxtWidth);
			txtW = maxTxtWidth;
			txtTimer = -0.3;

			var rect:FlxRect = new FlxRect(0, 0, txtW, txt.height);
			txt.clipRect = rect;
			txtBlur.clipRect = rect;
		}
		else
		{
			txtMoving = false;
			txt.x = x + 156;
			txtBlur.x = x + 156;
			txt.clipRect = null;
			txtBlur.clipRect = null;
		}
	}

	function sparkleEffect(timer:FlxTimer)
	{
		sparkle.setPosition(FlxG.random.float(ranking.x - 20, ranking.x + 3), FlxG.random.float(ranking.y - 29, ranking.y + 4));
		sparkle.playAnim('sparkle', true);
		sparkleTimer = new FlxTimer().start(FlxG.random.float(1.2, 4.5), sparkleEffect);
	}

	var flickerState:Bool = false;
	public function confirmAnim()
	{
		new FlxTimer().start(1 / 24, function(tmr:FlxTimer) {
			if (flickerState)
			{
				txt.blend = ADD;
				txtBlur.blend = ADD;
				txtBlur.color = 0xFFFFFFFF;
				txt.color = 0xFFFFFFFF;
				txt.textField.filters = [new openfl.filters.GlowFilter(0xFFFFFF, 1, 5, 5, 210, BitmapFilterQuality.MEDIUM)];
			}
			else
			{
				txtBlur.color = 0xFF00aadd;
				txt.color = 0xFFDDDDDD;
				txt.textField.filters = [new openfl.filters.GlowFilter(0xDDDDDD, 1, 5, 5, 210, BitmapFilterQuality.MEDIUM)];
			}
			flickerState = !flickerState;
		}, (Options.options.flashingLights ? 19 : 2));
	}

	var impactThing:AnimatedSprite;
	public var evilTrail:FlxTrail;

	public function fadeAnim()
	{
		impactThing = new AnimatedSprite(capsule.frames);
		impactThing.frame = capsule.frame;
		impactThing.updateHitbox();
		impactThing.alpha = 0;
		insert(members.indexOf(capsule), impactThing);
		FlxTween.tween(impactThing.scale, {x: 2.5, y: 2.5}, 0.5);

		evilTrail = new FlxTrail(impactThing, null, 15, 2, 0.01, 0.069);
		evilTrail.blend = ADD;
		FlxTween.tween(evilTrail, {alpha: 0}, 0.6, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween) { remove(evilTrail, true); }
		});
		insert(members.indexOf(impactThing), evilTrail);

		switch (rank)
		{
			case 0: evilTrail.color = 0xFF6044FF;
			case 1: evilTrail.color = 0xFFEF8764;
			case 2: evilTrail.color = 0xFFEAF6FF;
			case 3: evilTrail.color = 0xFFFDCB42;
			case 4: evilTrail.color = 0xFFFF58B4;
			case 5: evilTrail.color = 0xFFFFB619;
		}
	}

	function updateSelected()
	{
		if (ranking != null && ranking.alpha > 0)
		{
			ranking.color = (capsule.animation.curAnim.name == "selected" ? FlxColor.WHITE : 0xFFAAAAAA);
			ranking.alpha = (capsule.animation.curAnim.name == "selected" ? 1 : 0.7);
		}

		if (favIcon.alpha > 0)
		{
			favIcon.alpha = (capsule.animation.curAnim.name == "selected" ? 1 : 0.6);
			favIconBlurred.alpha = (capsule.animation.curAnim.name == "selected" ? 1 : 0);
			if (ranking != null && ranking.alpha > 0)
				maxTxtWidth = 210;
			else
				maxTxtWidth = 245;
		}
		else
		{
			favIconBlurred.alpha = 0;
			if (ranking.alpha > 0)
				maxTxtWidth = 245;
			else
				maxTxtWidth = 290;
		}
	}

	function set_maxTxtWidth(val:Int):Int
	{
		if (val != maxTxtWidth)
		{
			maxTxtWidth = val;
			resetMovingText();
		}
		return val;
	}

	public function set_index(val:Int):Int
	{
		if (val == 1 && songUnlocked)
		{
			capsule.playAnim("selected");
			if (txt != null)
			{
				txt.alpha = 1;
				txtBlur.alpha = 1;
			}
		}
		else
		{
			capsule.playAnim("unselected");
			if (txt != null)
			{
				FlxTween.cancelTweensOf(txt);
				if (txt.color == txtBlur.color)
					txt.alpha = 1;
				else
					txt.alpha = 0.6;
				txtBlur.alpha = 0;
			}
		}
		updateSelected();
		return index = val;
	}

	public function set_text(val:String):String
	{
		if (txt != null)
		{
			txt.text = val;
			txtBlur.text = val;
			txt.x = x + 156;
			txtBlur.x = x + 156;
			resetMovingText();
		}
		return text = val;
	}

	public function set_icon(val:String):String
	{
		if (iconGraphic != null)
		{
			if (!songUnlocked)
			{
				iconGraphic.loadGraphic(Paths.image("ui/freeplay/lock"));
				iconGraphic.scale.set(2, 2);
				iconGraphic.x = x + 260 - (iconGraphic.width * 2);
				iconGraphic.origin.x = 100;
			}
			else if (val == "none")
				iconGraphic.makeGraphic(32, 32, FlxColor.TRANSPARENT);
			else
			{
				iconGraphic.loadGraphic(Paths.image("ui/freeplay/icons/" + val + "pixel"));
				iconGraphic.scale.set(2, 2);
				iconGraphic.x = x + 260 - (iconGraphic.width * 2);
				iconGraphic.origin.x = 100;
			}
		}
		return icon = val;
	}

	public function set_lit(val:Bool):Bool
	{
		if (txt != null)
		{
			if (val)
				txt.color = FlxColor.WHITE;
			else
				txt.color = txtBlur.color;
		}
		return lit = val;
	}

	public function set_rank(val:Int):Int
	{
		if (val != rank)
		{
			sparkle.alpha = 0;
			switch (val)
			{
				case 0: ranking.alpha = 1; ranking.playAnim("LOSS");
				case 1: ranking.alpha = 1; ranking.playAnim("GOOD");
				case 2: ranking.alpha = 1; ranking.playAnim("GREAT");
				case 3: ranking.alpha = 1; ranking.playAnim("EXCELLENT");
				case 4: ranking.alpha = 1; ranking.playAnim("PERFECT");
				case 5: ranking.alpha = 1; ranking.playAnim("PERFECTSICK"); sparkle.alpha = 0.7;
				default: ranking.alpha = 0;
			}
			blurredRanking.alpha = ranking.alpha;
			blurredRanking.playAnim(ranking.animation.curAnim.name);
			if (ranking.alpha > 0)
				favIcon.x = x + 370;
			else
				favIcon.x = x + 405;
			favIconBlurred.x = favIcon.x;
			updateSelected();
		}
		return rank = val;
	}

	public function set_curQuickInfo(val:SongQuickInfo):SongQuickInfo
	{
		if (val == null)
		{
			bpmText.alpha = 0;
			difficultyText.alpha = 0;
			bpmNum.value = "";
			difficultyNum.value = "";
		}
		else
		{
			bpmText.alpha = 1;
			difficultyText.alpha = 1;

			if (val.bpmRange[0] == val.bpmRange[1])
				bpmNum.value = Std.string(val.bpmRange[0]);
			else
				bpmNum.value = Std.string(val.bpmRange[0]) + "-" + Std.string(val.bpmRange[1]);
			bpmNum.x = x + 234 - (bpmNum.value.length * 11);
			bpmText.x = x + 188 - (bpmNum.value.length * 11);

			var rating:String = "0";
			if (val.ratings.length > chartSide)
				rating = Std.string(val.ratings[chartSide]);
			if (rating.length < 2)
				rating = "0" + rating;
			difficultyNum.value = rating;
		}

		return curQuickInfo = val;
	}

	public function set_weekType(val:Int):Int
	{
		if (val == 0)
		{
			weekTypeText.alpha = 0;
			weekTypeNum.value = "";
		}
		else
		{
			weekTypeText.alpha = 1;
			if (val < 0)
			{
				weekTypeText.playAnim("WEEKEND");
				weekTypeNum.x = x + 390;
			}
			else
			{
				weekTypeText.playAnim("WEEK");
				weekTypeNum.x = x + 355;
			}
			weekTypeNum.value = Std.string(Math.abs(val));
		}

		return weekType = val;
	}

	public function set_chartSide(val:Int):Int
	{
		if (curQuickInfo != null)
		{
			var rating:String = "0";
			if (curQuickInfo.ratings.length > val)
				rating = Std.string(curQuickInfo.ratings[val]);
			if (rating.length < 2)
				rating = "0" + rating;
			difficultyNum.value = rating;
		}

		return chartSide = val;
	}
}

class FreeplayCapsuleNum extends FlxSpriteGroup
{
	public var value(default, set):String = "";
	var small:Bool = true;

	override public function new(x:Float, y:Float, small:Bool)
	{
		super(x, y);
		this.small = small;
	}

	public function set_value(val:String):String
	{
		if (value != val)
		{
			if (members.length < val.length)
			{
				while (members.length < val.length)
				{
					if (small)
					{
						var num:AnimatedSprite = new AnimatedSprite(members.length * 11, 0, Paths.sparrow("ui/freeplay/capsule/smallnumbers"));
						num.addAnim("0", "ZERO", 24, false);
						num.addAnim("1", "ONE", 24, false);
						num.addOffsets("1", [-4, 0]);
						num.addAnim("2", "TWO", 24, false);
						num.addAnim("3", "THREE", 24, false);
						num.addOffsets("3", [-1, 0]);
						num.addAnim("4", "FOUR", 24, false);
						num.addAnim("5", "FIVE", 24, false);
						num.addAnim("6", "SIX", 24, false);
						num.addAnim("7", "SEVEN", 24, false);
						num.addAnim("8", "EIGHT", 24, false);
						num.addAnim("9", "NINE", 24, false);
						num.addAnim(".", "DOT", 24, false);
						num.addAnim("-", "DASH", 24, false);
						num.addOffsets("-", [-1, 0]);
						num.scale.set(0.9, 0.9);
						num.active = false;
						add(num);
					}
					else
					{
						var num:AnimatedSprite = new AnimatedSprite(members.length * 30, 0, Paths.sparrow("ui/freeplay/capsule/bignumbers"));
						num.addAnim("0", "ZERO", 24, false);
						num.addAnim("1", "ONE", 24, false);
						num.addOffsets("1", [-4, 0]);
						num.addAnim("2", "TWO", 24, false);
						num.addAnim("3", "THREE", 24, false);
						num.addOffsets("3", [-1, 0]);
						num.addAnim("4", "FOUR", 24, false);
						num.addAnim("5", "FIVE", 24, false);
						num.addAnim("6", "SIX", 24, false);
						num.addAnim("7", "SEVEN", 24, false);
						num.addAnim("8", "EIGHT", 24, false);
						num.addAnim("9", "NINE", 24, false);
						num.scale.set(0.9, 0.9);
						num.active = false;
						add(num);
					}
				}
			}

			if (members.length > val.length)
			{
				for (i in val.length...members.length)
					members[i].alpha = 0;
			}

			for (i in 0...val.length)
			{
				members[i].alpha = 1;
				members[i].animation.play(val.charAt(i));
			}
		}

		return value = val;
	}
}