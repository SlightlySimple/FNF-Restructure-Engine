package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import data.ObjectData;
import data.Options;
import menus.MainMenuState;
import game.CharacterUnlockState;
import objects.Alphabet;
import objects.AnimatedSprite;
import objects.Character;
import scripting.HscriptHandler;

import lime.app.Application;
import Sys;

using StringTools;

typedef DefaultVariables =
{
	var game:String;
	var player1:String;
	var player2:String;
	var gf:String;
	var stage:String;
	var dead:String;
	var icon:String;
	var noicon:String;
	var story1:String;
	var story2:String;
	var story3:String;
	var storyimage:String;
}

typedef TitleSequence =
{
	var action:String;
	var value:Int;
	var text:String;
}

typedef TitleScreenData =
{
	var sequence:Array<Dynamic>;
	var pieces:Array<StagePiece>;
}

class TitleState extends MusicBeatState
{
	public static var defaultVariables:DefaultVariables;

	public static var initialized:Bool = false;
	public var titleScreenSequence:Array<Dynamic>;
	public var seqScreen:FlxSprite;
	public var introBeat:Int = -1;
	public var introText:FlxTypedSpriteGroup<Alphabet>;
	public var introTextY:Int = 200;
	public var specialTextFile:Array<String> = [];
	public var specialTextCensors:Array<Int> = [];
	public var skippedIntro:Bool = false;
	public var specialIntroText:Array<String> = [];

	public var titleScreenData:Array<StagePiece>;
	public var pieces:Map<String, FlxSprite>;
	public var myScript:HscriptHandler = null;

	public var transitioning:Bool = false;

	function checkDefaultField(field:String, folder:String, ?canBeBlank:Bool = false)
	{
		var prop:String = Reflect.getProperty(defaultVariables, field);
		if (!Paths.jsonExists(folder + prop) && !(prop == "" && canBeBlank))
		{
			Application.current.window.alert("data/" + folder + prop + ".json does not exist. Either create this file or change the \"" + field + "\" field in data/defaultVariables.json", "Alert");
			Sys.exit(0);
		}
	}

	function checkDefaultFieldImages(field:String, folder:String, ?canBeBlank:Bool = false)
	{
		var prop:String = Reflect.getProperty(defaultVariables, field);
		if (!Paths.imageExists(folder + prop) && !(prop == "" && canBeBlank))
		{
			Application.current.window.alert("images/" + folder + prop + ".png does not exist. Either create this file or change the \"" + field + "\" field in data/defaultVariables.json", "Alert");
			Sys.exit(0);
		}
	}

	function checkDefaultFieldIcon(field:String, folder:String, ?canBeBlank:Bool = false)
	{
		var prop:String = Reflect.getProperty(defaultVariables, field);
		if ((!Paths.imageExists(folder + prop) && !Paths.imageExists(folder + "icon-" + prop)) && !(prop == "" && canBeBlank))
		{
			Application.current.window.alert("images/" + folder + prop + ".png and images/" + folder + "icon-" + prop + ".png do not exist. Either create one of these files or change the \"" + field + "\" field in data/defaultVariables.json", "Alert");
			Sys.exit(0);
		}
	}

	override public function create()
	{
		super.create();

		if (!initialized)
		{
			defaultVariables = cast Paths.json("defaultVariables");

			checkDefaultField("player1", "characters/");
			checkDefaultField("player2", "characters/");
			checkDefaultField("gf", "characters/");
			checkDefaultField("stage", "stages/");
			checkDefaultField("dead", "characters/");
			checkDefaultFieldIcon("icon", "icons/");
			checkDefaultFieldIcon("noicon", "icons/");
			checkDefaultField("story1", "story_characters/", true);
			checkDefaultField("story2", "story_characters/", true);
			checkDefaultField("story3", "story_characters/", true);
			checkDefaultFieldImages("storyimage", "ui/story/weeks/");
		}



		titleScreenData = cast Paths.json("states/TitleState");
		titleScreenSequence = cast Paths.json("titleSequence");

		if (Paths.hscriptExists('data/states/TitleState'))
			myScript = new HscriptHandler('data/states/TitleState');

		seqScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(seqScreen);
		introText = new FlxTypedSpriteGroup<Alphabet>();
		add(introText);

		pieces = new Map<String, FlxSprite>();

		for (i in 0...titleScreenData.length)
		{
			if (titleScreenData[i].id == null || titleScreenData[i].id == "")
				titleScreenData[i].id = titleScreenData[i].asset;

			var stagePiece:StagePiece = titleScreenData[i];
			var piece:FlxSprite = null;

			switch (stagePiece.type)
			{
				case "static":
					piece = new FlxSprite(stagePiece.position[0], stagePiece.position[1], Paths.image("ui/title_screen/" + stagePiece.asset));
					if (stagePiece.scale != null && stagePiece.scale.length == 2)
					{
						piece.scale.x = stagePiece.scale[0];
						piece.scale.y = stagePiece.scale[1];
					}
					if (stagePiece.updateHitbox)
						piece.updateHitbox();

				case "animated":
					var aPiece:AnimatedSprite = null;
					aPiece = new AnimatedSprite(stagePiece.position[0], stagePiece.position[1], Paths.sparrow("ui/title_screen/" + stagePiece.asset));
					for (i in 0...stagePiece.animations.length)
					{
						var anim = stagePiece.animations[i];
						if (anim.indices != null && anim.indices.length > 0)
							aPiece.animation.addByIndices(anim.name, anim.prefix, Character.uncompactIndices(anim.indices), "", anim.fps, anim.loop);
						else
							aPiece.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
					}
					aPiece.animation.play(stagePiece.firstAnimation);

					if (stagePiece.idles != null)
						aPiece.idles = stagePiece.idles;
					if (stagePiece.beatAnimationSpeed != null)
						aPiece.danceSpeed = stagePiece.beatAnimationSpeed;

					if (stagePiece.scale != null && stagePiece.scale.length == 2)
					{
						aPiece.scale.x = stagePiece.scale[0];
						aPiece.scale.y = stagePiece.scale[1];
					}
					if (stagePiece.updateHitbox)
						aPiece.updateHitbox();
					piece = aPiece;
			}
			if (stagePiece.visible != null)
				piece.visible = stagePiece.visible;
			piece.antialiasing = stagePiece.antialias;
			if (stagePiece.alpha != null && stagePiece.alpha != 1)
				piece.alpha = stagePiece.alpha;
			if (stagePiece.blend != null && stagePiece.blend != "")
				piece.blend = stagePiece.blend;
			if (stagePiece.align != null && stagePiece.align != "")
			{
				if (stagePiece.align.endsWith("center"))
					piece.x -= piece.width / 2;
				else if (stagePiece.align.endsWith("right"))
					piece.x -= piece.width;

				if (stagePiece.align.startsWith("middle"))
					piece.y -= piece.height / 2;
				else if (stagePiece.align.startsWith("bottom"))
					piece.y -= piece.height;
			}
			pieces.set(stagePiece.id, piece);
			if (stagePiece.layer != null && stagePiece.layer > 0)
				add(piece);
			else
				insert(members.indexOf(seqScreen), piece);
		}

		specialTextFile = Paths.text("introText").replace("\r","").split("\n");
		specialTextCensors = [];
		if (!Options.options.naughtiness)
		{
			for (i in 0...specialTextFile.length)
			{
				var t:Array<String> = specialTextFile[i].split("--");
				if (t.length > 2 && t[2].toLowerCase() == "censor")
					specialTextCensors.push(i);
			}
		}

		var specialText:String = specialTextFile[FlxG.random.int(0, specialTextFile.length - 1, specialTextCensors)];
		specialIntroText = specialText.split("--");
		if (specialIntroText.length < 2)
			specialIntroText.push(specialIntroText[0]);

		if (!initialized)
		{
			Conductor.playMusic("freakyMenu", 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}

		if (myScript != null)
			myScript.execFunc("create", []);

		if (initialized)
			endIntro(false);
		initialized = true;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (myScript != null)
			myScript.execFunc("update", [elapsed]);

		if ((Options.keyJustPressed("ui_accept") || Options.mouseJustPressed()) && !transitioning)
		{
			if (skippedIntro)
			{
				FlxG.camera.flash(FlxColor.WHITE, 1);
				FlxG.sound.play(Paths.sound("ui/confirmMenu"));
				if (myScript != null)
					myScript.execFunc("onPressedEnter", []);

				transitioning = true;
				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					FlxG.switchState(new MainMenuState());
				});
			}
			else
				endIntro();
		}

		if (myScript != null)
			myScript.execFunc("updatePost", [elapsed]);
	}

	override public function beatHit()
	{
		super.beatHit();

		if (!skippedIntro)
		{
			if (introBeat < curBeat)
			{
				for (i in introBeat...curBeat)
				{
					if (i+1 < titleScreenSequence.length)
					{
						if (Std.isOfType(titleScreenSequence[i+1], Array))
						{
							var seqArray:Array<TitleSequence> = cast titleScreenSequence[i+1];
							for (seq in seqArray)
								titleScreenAction(seq);
						}
						else
						{
							var seq:TitleSequence = cast titleScreenSequence[i+1];
							titleScreenAction(seq);
						}
					}
					else
						endIntro();
				}
				introBeat = curBeat;
			}
		}

		if (myScript != null)
			myScript.execFunc("beatHit", []);
	}

	override public function stepHit()
	{
		for (m in members)
		{
			if (Std.isOfType(m, AnimatedSprite))
			{
				var s:AnimatedSprite = cast m;
				s.stepHit();
			}
		}

		if (myScript != null)
			myScript.execFunc("stepHit", []);
	}

	function titleScreenAction(seq:TitleSequence)
	{
		switch (seq.action)
		{
			case "refreshSpecialText":
				var specialText:String = specialTextFile[FlxG.random.int(0, specialTextFile.length - 1, specialTextCensors)];
				specialIntroText = specialText.split("--");
				if (specialIntroText.length < 2)
					specialIntroText.push(specialIntroText[0]);

			case "setIntroTextY":
				introTextY = seq.value;

			case "resetIntroTextY":
				introTextY = 200;

			case "toggleSprite":
				if (pieces.exists(seq.text))
					pieces[seq.text].visible = !pieces[seq.text].visible;

			case "addText" | "addIntroText":
				var yy:Int = introTextY;
				introText.forEachAlive(function(text:Alphabet) { yy += 60; });
				var alphaText:String = seq.text;
				if (seq.action == "addIntroText")
					alphaText = specialIntroText[seq.value];
				var text:Alphabet = new Alphabet(0, yy, Lang.get(alphaText));
				text.screenCenter(X);
				introText.add(text);

			case "wipeText":
				introText.forEachAlive(function(text:Alphabet)
				{
					text.kill();
					text.destroy();
				});
				introText.clear();
		}
	}

	public function endIntro(?skipping:Bool = true)
	{
		skippedIntro = true;
		if (skipping)
			FlxG.camera.flash(FlxColor.WHITE, 4);
		remove(seqScreen);
		remove(introText);

		if (skipping && Math.abs(FlxG.sound.music.time - Conductor.timeFromBeat(titleScreenSequence.length)) > 50)
			FlxG.sound.music.time = Conductor.timeFromBeat(titleScreenSequence.length);

		if (myScript != null)
			myScript.execFunc("endIntro", [skipping]);
	}
}