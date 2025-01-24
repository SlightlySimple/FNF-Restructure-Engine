package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import data.Options;

using StringTools;

class Alphabet extends FlxSpriteGroup
{
	public var text(default, set):String = "";
	public var font:String = "bold";
	public var maxWidth:Int = 0;
	public var wordWrap:Bool = false;
	public var align(default, set):String = "left";
	public var textScale:Float = 1;

	override public function new(x:Int, y:Int, text:String, ?font:String = "bold", ?maxWidth:Int = 0, ?wordWrap:Bool = false, ?textScale:Float = 1.0)
	{
		super(x, y);

		this.font = font;
		this.maxWidth = maxWidth;
		this.wordWrap = wordWrap;
		this.textScale = textScale;

		this.text = text;
	}

	function rebuildText()
	{
		forEachAlive(function(letter:FlxSprite) {
			letter.visible = false;
			letter.active = false;
			letter.setPosition(x, y);
			letter.setGraphicSize(1, 1);
			letter.updateHitbox();
		});

		if (text.trim().length > 0)
		{
			var predictedWidth:Int = Std.int(text.length * 50 * textScale);
			var xs:Float = textScale;
			if (maxWidth > 0 && predictedWidth > maxWidth && !wordWrap)
				xs = maxWidth / predictedWidth;

			var fontFrames:FlxFramesCollection = Paths.sparrow("ui/fonts/" + font);
			var xx:Int = 0;
			var yy:Int = 0;
			var lines:Array<Array<FlxSprite>> = [[]];
			for (i in 0...text.length)
			{
				if (i >= members.length)
				{
					while (i >= members.length)
						add(new AnimatedSprite(0, 0, fontFrames));
				}
				var letter:FlxSprite = members[i];

				var char:String = text.charAt(i);
				if (char == " ")
				{
					letter.visible = letter.active = false;
					if (wordWrap)
					{
						var xx2 = xx;
						for (j in i...text.length)
						{
							if (text.charAt(j) == " ")
								xx2 += Std.int(40 * xs);
							else
							{
								var letterFrame:FlxFrame = fontFrames.framesHash.get(getAnimPrefix(text.charAt(j)) + "0000");
								if (letterFrame != null)
									xx2 += Std.int(letterFrame.frame.width * xs);
							}
							if (j > i && (text.charAt(j) == " " || text.charAt(j) == "\n"))
								break;
						}
						if (xx2 >= maxWidth)
						{
							xx = 0;
							yy += 60;
							lines.push([]);
						}
						else
							xx += Std.int(40 * xs);
					}
					else
						xx += Std.int(40 * xs);
				}
				else if (char == "\n")
				{
					letter.visible = letter.active = false;
					xx = 0;
					yy += 60;
					lines.push([]);
				}
				else
				{
					letter.setPosition(x + xx, y + yy);
					letter.visible = letter.active = true;
					letter.animation.addByPrefix("me", getAnimPrefix(char), 24, true);
					letter.animation.play("me");
					letter.scale.set(xs, textScale);
					letter.updateHitbox();
					if (char == "-")
						letter.y += 20 * textScale;
					else if (char == "." || char == "," || char == "_")
						letter.y += 40 * textScale;
					else if (char != char.toUpperCase() && font != "bold")
						letter.y += (60 * textScale) - letter.height;
					xx += Std.int(letter.width);

					lines[lines.length-1].push(letter);
				}
			}

			var lineWidths:Array<Float> = [];
			var lineMax:Float = 0;
			for (l in lines)
			{
				var w:Float = l[l.length-1].x + l[l.length-1].width - l[0].x;
				if (w > lineMax)
					lineMax = w;
				lineWidths.push(w);
			}
			switch (align)
			{
				case "center":
					for (i in 0...lines.length)
					{
						for (l in lines[i])
							l.x += (lineMax - lineWidths[i]) / 2;
					}

				case "right":
					for (i in 0...lines.length)
					{
						for (l in lines[i])
							l.x += lineMax - lineWidths[i];
					}
			}
		}
	}

	public function setFont(font:String)
	{
		if (this.font != font)
		{
			this.font = font;
			var fontFrames:FlxFramesCollection = Paths.sparrow("ui/fonts/" + font);

			forEachAlive(function(letter:FlxSprite) { letter.frames = fontFrames; });

			rebuildText();
		}
	}

	function getAnimPrefix(char:String):String
	{
		switch (char)
		{
			case "'": return "-apostraphie-";
			case "\\": return "-back slash-";
			case ",": return "-comma-";
			case "-": return "-dash-";
			case "!": return "-exclamation point-";
			case "/": return "-forward slash-";
			case ".": return "-period-";
			case "?": return "-question mark-";
			case "\"": return "-start quote-";
		}

		if (font == "bold")
			return char.toUpperCase();
		return char;
	}

	public function set_text(newVal:String):String
	{
		text = newVal;
		rebuildText();
		return text = newVal;
	}

	public function set_align(newVal:String):String
	{
		align = newVal;
		rebuildText();
		return align = newVal;
	}
}

class TypedAlphabet extends Alphabet
{
	var index:Int = 0;
	var timer:Float = 0;

	public var delay:Float = 0.05;
	public var paused:Bool = true;
	public var sounds:Array<FlxSound> = [];
	public var finishSounds = false;
	public var completeCallback:Void->Void;

	public function resetText(text:String)
	{
		this.text = text;
		index = 0;
		paused = true;

		forEachAlive(function(letter:FlxSprite) { letter.visible = false; });
	}

	public function start(delay:Float, ?forceRestart:Bool = true)
	{
		if (forceRestart)
		{
			index = 0;
			forEachAlive(function(letter:FlxSprite) { letter.visible = false; });
		}

		this.delay = delay;
		timer = delay;
		paused = false;
	}

	public function skip()
	{
		index = text.length;
		forEachAlive(function(letter:FlxSprite) { letter.visible = letter.active; });
		onComplete();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!paused)
		{
			if (index <= text.length)
			{
				timer -= elapsed;
				if (timer <= 0)
				{
					for (i in 0...index)			// Just in case
						members[i].visible = members[i].active;
					index++;
					timer = delay;

					if (sounds != null && sounds.length > 0)
					{
						if (!finishSounds)
						{
							for (sound in sounds)
								sound.stop();
						}

						FlxG.random.getObject(sounds).play(!finishSounds);
					}
				}
			}
			else
				onComplete();
		}
	}

	function onComplete()
	{
		paused = true;
		timer = 0;

		if (sounds != null && sounds.length > 0)
		{
			for (sound in sounds)
				sound.stop();
		}

		if (completeCallback != null)
			completeCallback();
	}
}