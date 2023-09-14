package;

import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import data.Noteskins;
import data.Options;
import data.ScoreSystems;
import menus.OptionsMenuState;

class InitState extends MusicBeatState
{
	var doingSetup:Bool = false;
	var setupText:FlxText;
	var setupOptionY:FlxText;
	var setupOptionN:FlxText;
	var selectedSetupOption:Bool = false;

	override public function create()
	{
		super.create();

		#if ALLOW_MODS
		if (PackagesState.getPackages().length > 0 && !PackagesState.done && !Sys.args().contains("-package"))
		{
			MusicBeatState.doTransIn = false;
			MusicBeatState.doTransOut = false;
			FlxG.switchState(new PackagesState());
			return;
		}
		#end

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			#if ALLOW_MODS
			ModLoader.initMods();
			#end
			Options.initOptions();
			Noteskins.loadNoteskins();
			ScoreSystems.initScores();
			Lang.init();

			FlxG.autoPause = Options.options.autoPause;
			FlxG.sound.muteKeys = Options.getKeys("mute");
			FlxG.sound.volumeUpKeys = Options.getKeys("vol_up");
			FlxG.sound.volumeDownKeys = Options.getKeys("vol_down");
			FlxG.sound.cache(Paths.music("freakyMenu"));
			Main.screenshotKeys = Options.getKeys("screenshot");

			if (FlxG.save.data.setupOptions == null)
				FlxG.save.data.setupOptions = false;

			if (FlxG.save.data.setupOptions)
			{
				MusicBeatState.doTransIn = false;
				MusicBeatState.doTransOut = false;
				FlxG.switchState(new TitleState());
			}
			else
			{
				doingSetup = true;

				setupText = new FlxText(0, 200, FlxG.width - 400, Lang.get("#firstTimeNotice"), 40);
				setupText.screenCenter(X);
				setupText.setFormat("VCR OSD Mono", 40, FlxColor.WHITE, CENTER);
				add(setupText);

				setupOptionY = new FlxText(0, 450, 0, "", 64);
				setupOptionY.font = "VCR OSD Mono";
				add(setupOptionY);

				setupOptionN = new FlxText(0, 450, 0, "", 64);
				setupOptionN.font = "VCR OSD Mono";
				add(setupOptionN);

				setupText.alpha = 0;
				FlxTween.tween(setupText, {alpha: 1}, 1);
				setupOptionY.alpha = 0;
				FlxTween.tween(setupOptionY, {alpha: 1}, 1);
				setupOptionN.alpha = 0;
				FlxTween.tween(setupOptionN, {alpha: 1}, 1);

				updateSetupOptions();
			}
		});
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (doingSetup)
		{
			if ((Options.keyJustPressed("ui_left") || Options.keyJustPressed("ui_right")))
			{
				FlxG.sound.play(Paths.sound("ui/scrollMenu"));
				selectedSetupOption = !selectedSetupOption;
				updateSetupOptions();
			}

			if (Options.keyJustPressed("ui_accept"))
			{
				FlxG.sound.play(Paths.sound("ui/confirmMenu"));
				doingSetup = false;
				new FlxTimer().start(0.75, function(tmr:FlxTimer) {
					if (selectedSetupOption)
					{
						FlxG.save.data.setupOptions = true;
						FlxG.save.flush();
						MusicBeatState.doTransIn = false;
						FlxG.switchState(new TitleState());
					}
					else
					{
						remove(setupText);
						remove(setupOptionY);
						remove(setupOptionN);

						persistentUpdate = false;
						openSubState(new OptionsMenuSubState(2));
					}
				});
			}
		}
	}

	function updateSetupOptions()
	{
		if (selectedSetupOption)
		{
			setupOptionY.text = Lang.get("#yes");
			setupOptionN.text = "> "+Lang.get("#no")+" <";
		}
		else
		{
			setupOptionY.text = "> "+Lang.get("#yes")+" <";
			setupOptionN.text = Lang.get("#no");
		}
		setupOptionY.x = (FlxG.width / 3) - (setupOptionY.width / 2);
		setupOptionN.x = (FlxG.width * 2 / 3) - (setupOptionN.width / 2);
	}
}