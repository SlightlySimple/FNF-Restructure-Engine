package menus.story;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

import data.ScoreSystems;
import menus.UINavigation;
import objects.Alphabet;

class StoryMenuResetSubState extends FlxSubState
{
	var yes:Alphabet;
	var no:Alphabet;
	var option:Bool = false;

	override public function new(week:String, difficulty:String, ?onOption:Void->Void = null)
	{
		super();

		FlxG.sound.play(Paths.sound("ui/cancelMenu"));

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		var confirmText:Alphabet = new Alphabet(0, 150, Lang.get("#story.resetWarning"), "bold", Std.int(FlxG.width * 0.9), true, 0.75);
		confirmText.align = "center";
		confirmText.screenCenter(X);
		add(confirmText);

		yes = new Alphabet(0, 500, "");
		add(yes);

		no = new Alphabet(0, 500, "");
		add(no);

		updateText();

		for (m in members)
		{
			var s:FlxSprite = cast m;
			var a:Float = s.alpha;
			s.alpha = 0;
			FlxTween.tween(s, {alpha: a}, 0.5);
		}

		var nav:UINumeralNavigation = new UINumeralNavigation(function(a) {
			option = !option;
			updateText();
		}, null, function() {
			if (!option)
				ScoreSystems.resetWeekScore(week, difficulty);
			if (onOption != null)
				onOption();
			close();
		});
		add(nav);
	}

	function updateText()
	{
		if (option)
		{
			yes.text = Lang.get("#yes");
			no.text = "> " + Lang.get("#no") + " <";
		}
		else
		{
			yes.text = "> " + Lang.get("#yes") + " <";
			no.text = Lang.get("#no");
		}
		yes.x = (FlxG.width / 3) - (yes.width / 2);
		no.x = (FlxG.width * 2 / 3) - (no.width / 2);
	}
}