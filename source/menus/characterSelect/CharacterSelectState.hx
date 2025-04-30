package menus.characterSelect;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
import flxanimate.FlxAnimate;
import menus.UINavigation;
import data.Options;
import data.PlayableCharacter;
import objects.AnimatedSprite;

class CharacterSelectState extends MusicBeatState
{
	public static var player:String = "bf";
	var playerData:PlayableCharacterSelect;

	var curSelected:Int = 0;
	var characters:Array<String> = [];
	var charactersHidden:Array<String> = [];

	var blueFade:FlxRuntimeShader;
	var blueFadeFilter:ShaderFilter;

	var grpCursors:FlxSpriteGroup;
	var cursor:FlxSprite;
	var cursorBlue:FlxSprite;
	var cursorDarkBlue:FlxSprite;
	var cursorConfirmed:AnimatedSprite;
	var cursorDenied:AnimatedSprite;

	var cursorX:Int = 0;
	var cursorY:Int = 0;
	var cursorFactor:Float = 110;
	var cursorOffsetX:Float = -16;
	var cursorOffsetY:Float = -48;
	var cursorLocIntended:FlxPoint = new FlxPoint(0, 0);
	var lerpAmnt:Float = 0.95;

	var barthing:FlxAnimate;
	var dipshitBlur:AnimatedSprite;
	var dipshitBacking:AnimatedSprite;
	var chooseDipshit:FlxSprite;

	var grpIcons:FlxTypedSpriteGroup<CharacterSelectIcon>;
	var nametag:CharacterSelectNametag;
	var bf:CharacterSelectCharacter;
	var gf:CharacterSelectCharacter;
	var speakers:FlxAnimate;

	var camFollow:FlxObject;
	var autoFollow:Bool = false;
	var nav:UINumeralNavigation;
	var canCancel:Bool = false;
	var exitTimer:FlxTimer = new FlxTimer();

	override public function create()
	{
		super.create();

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		camFollow.screenCenter();
		FlxG.camera.follow(camFollow, LOCKON);

		camFollow.y -= 150;
		FlxTween.tween(camFollow, {y: camFollow.y + 150}, 1.5, {ease: FlxEase.expoOut, onComplete: function(twn:FlxTween) { autoFollow = true; FlxG.camera.follow(camFollow, LOCKON, 0.01); }});

		blueFade = new FlxRuntimeShader(Paths.shader("BlueFade"));
		blueFade.setFloat("fadeAmt", 1.0);
		blueFadeFilter = new ShaderFilter(blueFade);

		for (i in 0...9)
			characters.push("");

		for (c in Paths.listFilesSub("data/players/", ".json"))
		{
			var charSelect:PlayableCharacterSelect = cast Paths.json("players/" + c).charSelect;
			var position:Int = 0;
			if (charSelect.position != null && charSelect.position > 0)
				position = charSelect.position;
			if (position < characters.length && characters[position] != "")
			{
				while (position < characters.length && characters[position] != "")
					position++;
			}

			if (position >= characters.length)
			{
				charactersHidden.push(c);
				if (FlxG.save.data.unlockedCharactersSeen.contains(c))
					characters.push(c);
				else
					characters.push("");
			}
			else
			{
				charactersHidden[position] = c;
				if (FlxG.save.data.unlockedCharactersSeen.contains(c))
					characters[position] = c;
			}
		}

		curSelected = characters.indexOf(player);
		playerData = cast Paths.json("players/" + player).charSelect;

		var bg:FlxSprite = new FlxSprite(-153, -140, Paths.image("ui/character_select/charSelectBG"));
		bg.scrollFactor.set(0.1, 0.1);
		add(bg);

		var crowd:FlxAnimate = new FlxAnimate(0, 0, Paths.atlas("ui/character_select/crowd"));
		crowd.anim.addByFrameName("idle", "", 24);
		crowd.playAnim("idle", true, true);
		crowd.scrollFactor.set(0.3, 0.3);
		add(crowd);

		var stageSpr:AnimatedSprite = new AnimatedSprite(-40, 391, Paths.sparrow("ui/character_select/charSelectStage"));
		stageSpr.addAnim("idle", "stage full instance 1", 24, true);
		stageSpr.playAnim("idle");
		add(stageSpr);

		var curtains:FlxSprite = new FlxSprite(-47, -49, Paths.image("ui/character_select/curtains"));
		curtains.scrollFactor.set(1.4, 1.4);
		add(curtains);

		barthing = new FlxAnimate(0, 0, Paths.atlas("ui/character_select/barThing"));
		barthing.anim.addByFrameName("idle", "", 24);
		barthing.playAnim("idle", true, true);
		barthing.blend = MULTIPLY;
		barthing.scrollFactor.set();
		add(barthing);

		barthing.y += 80;
		FlxTween.tween(barthing, {y: barthing.y - 80}, 1.3, {ease: FlxEase.expoOut});

		var charLight:FlxSprite = new FlxSprite(800, 250, Paths.image("ui/character_select/charLight"));
		add(charLight);

		var charLightGF:FlxSprite = new FlxSprite(180, 240, Paths.image("ui/character_select/charLight"));
		add(charLightGF);

		gf = new CharacterSelectCharacter();
		refreshGF();
		add(gf);

		bf = new CharacterSelectCharacter();
		refreshBF();
		add(bf);

		speakers = new FlxAnimate(0, 0, Paths.atlas("ui/character_select/charSelectSpeakers"));
		speakers.anim.addByFrameName("idle", "", 24);
		speakers.playAnim("idle", true, true);
		speakers.scrollFactor.set(1.8, 1.8);
		add(speakers);

		var fgBlur:FlxSprite = new FlxSprite(-125, 170, Paths.image("ui/character_select/foregroundBlur"));
		fgBlur.blend = MULTIPLY;
		add(fgBlur);

		dipshitBlur = new AnimatedSprite(419, -65, Paths.sparrow("ui/character_select/dipshitBlur"));
		dipshitBlur.animation.addByPrefix('idle', "CHOOSE vertical offset instance 1", 24, true);
		dipshitBlur.blend = ADD;
		dipshitBlur.playAnim("idle");
		dipshitBlur.scrollFactor.set();
		add(dipshitBlur);

		dipshitBlur.y += 220;
		FlxTween.tween(dipshitBlur, {y: dipshitBlur.y - 220}, 1.2, {ease: FlxEase.expoOut});

		dipshitBacking = new AnimatedSprite(423, -17, Paths.sparrow("ui/character_select/dipshitBacking"));
		dipshitBacking.addAnim('idle', "CHOOSE horizontal offset instance 1", 24, true);
		dipshitBacking.blend = ADD;
		dipshitBacking.playAnim("idle");
		dipshitBacking.scrollFactor.set();
		add(dipshitBacking);

		dipshitBacking.y += 210;
		FlxTween.tween(dipshitBacking, {y: dipshitBacking.y - 210}, 1.1, {ease: FlxEase.expoOut});

		chooseDipshit = new FlxSprite(426, -13, Paths.image("ui/character_select/chooseDipshit"));
		chooseDipshit.scrollFactor.set();
		add(chooseDipshit);

		chooseDipshit.y += 200;
		FlxTween.tween(chooseDipshit, {y: chooseDipshit.y - 200}, 1, {ease: FlxEase.expoOut});

		nametag = new CharacterSelectNametag(1008, 100);
		nametag.scrollFactor.set();
		add(nametag);

		grpCursors = new FlxSpriteGroup();
		grpCursors.scrollFactor.set();
		add(grpCursors);

		cursorDarkBlue = new FlxSprite(Paths.image("ui/character_select/charSelector"));
		cursorDarkBlue.color = 0xFF3C74F7;
		cursorDarkBlue.blend = SCREEN;
		grpCursors.add(cursorDarkBlue);

		cursorBlue = new FlxSprite(Paths.image("ui/character_select/charSelector"));
		cursorBlue.color = 0xFF3EBBFF;
		cursorBlue.blend = SCREEN;
		grpCursors.add(cursorBlue);

		cursor = new FlxSprite(Paths.image("ui/character_select/charSelector"));
		cursor.color = 0xFFFFFF00;
		FlxTween.color(cursor, 0.2, 0xFFFFFF00, 0xFFFFCC00, {type: PINGPONG});
		grpCursors.add(cursor);

		cursorConfirmed = new AnimatedSprite(Paths.sparrow("ui/character_select/charSelectorConfirm"));
		cursorConfirmed.scrollFactor.set();
		cursorConfirmed.addAnim("idle", "cursor ACCEPTED instance 1", 24, true);
		cursorConfirmed.visible = false;
		add(cursorConfirmed);

		cursorDenied = new AnimatedSprite(Paths.sparrow("ui/character_select/charSelectorDenied"));
		cursorDenied.scrollFactor.set();
		cursorDenied.addAnim("idle", "cursor DENIED instance 1", 24, false);
		cursorDenied.visible = false;
		cursorDenied.animation.finishCallback = function(anim:String) { cursorDenied.visible = false; }
		add(cursorDenied);

		grpIcons = new FlxTypedSpriteGroup<CharacterSelectIcon>(450, 120);
		grpIcons.scrollFactor.set();
		add(grpIcons);

		for (i in 0...characters.length)
		{
			var xx:Float = (i % 3) * 107;
			var yy:Float = Math.floor(i / 3) * 127;

			var icon:CharacterSelectIcon = new CharacterSelectIcon(xx, yy, i, characters[i]);
			grpIcons.add(icon);
		}

		nav = new UINumeralNavigation(changeSelectionH, changeSelectionV, function() {
			grpIcons.members[curSelected].onClicked();
			if (characters[curSelected] != "")
			{
				nav.locked = true;
				canCancel = true;
				FlxG.sound.play(Paths.sound("ui/character_select/CS_confirm"));

				cursorConfirmed.visible = true;
				cursorConfirmed.setPosition(cursor.x - 2, cursor.y - 4);
				cursorConfirmed.playAnim("idle", true);

				grpCursors.visible = false;

				FlxTween.tween(FlxG.sound.music, {pitch: 0.1}, 1, {ease: FlxEase.quadInOut});
				FlxTween.tween(FlxG.sound.music, {volume: 0.0}, 1.5, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) { FlxG.sound.music.pitch = 1; FlxG.sound.music.stop(); }});

				bf.playAnim("select");
				gf.playAnim("confirm");

				exitTimer.start(1.5, function(tmr:FlxTimer) { goToFreeplay(); });
			}
			else
			{
				FlxG.sound.play(Paths.sound("ui/character_select/CS_locked"));

				cursorDenied.visible = true;
				cursorDenied.setPosition(cursor.x - 2, cursor.y - 4);
				cursorDenied.playAnim("idle", true);

				bf.playAnim("cannot select Label");
			}
		});
		nav.uiSounds = [false, false, false];
		nav.locked = true;
		add(nav);

		onChangedSelection();

		if (FlxG.save.data.characterSelectIntro == null)
			FlxG.save.data.characterSelectIntro = false;

		if (FlxG.save.data.characterSelectIntro)
		{
			introSequence();

			var transitionGradient:FlxSprite = new FlxSprite(Paths.image("ui/freeplay/transitionGradient"));
			transitionGradient.scale.set(1280, 1);
			transitionGradient.flipY = true;
			transitionGradient.updateHitbox();
			FlxTween.tween(transitionGradient, {y: -720}, 1, {ease: FlxEase.expoOut});
			add(transitionGradient);

			FlxG.camera.setFilters([blueFadeFilter]);
			FlxTween.num(0.0, 1.0, 0.8, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) { FlxG.camera.setFilters([]); }}, function(num:Float) { blueFade.setFloat("fadeAmt", num); });
		}
		else
		{
			var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			black.scrollFactor.set();
			add(black);

			var video:MP4Handler = new MP4Handler();
			video.playMP4(Paths.video("introSelect"), function() {
				FlxG.camera.flash();
				remove(black, true);
				FlxG.sound.play(Paths.sound("ui/character_select/CS_Lights"));
				FlxG.save.data.characterSelectIntro = true;
				FlxG.save.flush();
				introSequence();
			});
		}
	}

	function introSequence(?timer:Bool = true)
	{
		var needsToUnlock:String = "";
		var unlockedCharacters:Array<String> = FlxG.save.data.unlockedCharacters;
		var unlockedCharactersSeen:Array<String> = FlxG.save.data.unlockedCharactersSeen;
		for (c in unlockedCharacters)
		{
			if (!unlockedCharactersSeen.contains(c))
			{
				needsToUnlock = c;
				break;
			}
		}

		if (needsToUnlock != "")
		{
			if (timer)
			{
				new FlxTimer().start(2, function(tmr:FlxTimer) {
					unlockCharacter(needsToUnlock);
				});
			}
			else
				unlockCharacter(needsToUnlock);
		}
		else
		{
			nav.locked = false;
			Conductor.playMusic("stayFunky", 1);
		}
	}

	function unlockCharacter(char:String)
	{
		var position:Int = charactersHidden.indexOf(char);

		grpIcons.members[curSelected].onUnselected();
		curSelected = position;
		FlxG.sound.play(Paths.sound("ui/character_select/CS_select"), 0.7);
		onChangedSelection();

		new FlxTimer().start(0.5, function(tmr:FlxTimer) {
			grpIcons.members[curSelected].unlock();

			new FlxTimer().start(36 / 24, function(tmr:FlxTimer) {
				bf.playAnim("death");
				bf.visible = false;

				var death:FlxSprite = new FlxSprite(bf.x - bf.offset.x, bf.y - bf.offset.y);
				death.frames = bf.frames;
				death.animation.addByPrefix("death", "death", 24, false);
				insert(members.indexOf(bf) + 1, death);
				death.animation.play("death", true);
				death.animation.finishCallback = function(anim:String) {
					remove(death, true);
					death.kill();
					death.destroy();
				}
			});

			new FlxTimer().start(75 / 24, function(tmr:FlxTimer) {
				FlxG.camera.flash(0xFFFFFFFF, 0.1);

				characters[curSelected] = char;
				player = characters[curSelected];
				playerData = cast Paths.json("players/" + player).charSelect;

				grpIcons.members[curSelected].setCharacter(player);
				grpIcons.members[curSelected].bop();
				nametag.setCharacter(player);
				refreshBF();
				refreshGF();

				if (bf.hasAnim("unlock"))
					bf.playAnim("unlock");
				else
					bf.playAnim("slidein");
				bf.visible = true;

				FlxG.save.data.unlockedCharactersSeen.push(char);
				FlxG.save.flush();
				introSequence(false);
			});
		});
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		cursorLocIntended.x = (cursorFactor * cursorX) + (FlxG.width / 2) - cursor.width / 2;
		cursorLocIntended.y = (cursorFactor * cursorY) + (FlxG.height / 2) - cursor.height / 2;

		cursorLocIntended.x += cursorOffsetX;
		cursorLocIntended.y += cursorOffsetY;

		cursor.x = FlxMath.lerp(cursor.x, cursorLocIntended.x, lerpAmnt * 60 * elapsed);
		cursor.y = FlxMath.lerp(cursor.y, cursorLocIntended.y, lerpAmnt * 60 * elapsed);

		cursorBlue.x = FlxMath.lerp(cursorBlue.x, cursor.x, lerpAmnt * 0.4 * 60 * elapsed);
		cursorBlue.y = FlxMath.lerp(cursorBlue.y, cursor.y, lerpAmnt * 0.4 * 60 * elapsed);

		cursorDarkBlue.x = FlxMath.lerp(cursorDarkBlue.x, cursorLocIntended.x, lerpAmnt * 0.2 * 60 * elapsed);
		cursorDarkBlue.y = FlxMath.lerp(cursorDarkBlue.y, cursorLocIntended.y, lerpAmnt * 0.2 * 60 * elapsed);

		if (autoFollow)
			camFollow.setPosition((FlxG.width / 2) + (cursorX * 10), (FlxG.height / 2) + (cursorY * 10));

		if (canCancel && Options.keyJustPressed("ui_back"))
		{
			nav.locked = false;
			canCancel = false;
			exitTimer.cancel();

			cursorConfirmed.visible = false;
			grpCursors.visible = true;
			grpIcons.members[curSelected].onUnclicked();

			FlxTween.cancelTweensOf(FlxG.sound.music);
			bf.playAnim("deselect");
			gf.playAnim("deselect");
			FlxTween.tween(FlxG.sound.music, {pitch: 1.0, volume: 1.0}, 1, {ease: FlxEase.quartInOut});
		}
	}

	public override function beatHit()
	{
		super.beatHit();

		if (!nav.locked)
		{
			if (bf.curAnim == "idle" || bf.curAnimFinished)
				bf.playAnim("idle");

			if (curBeat % 2 == 0 && (gf.curAnim == "idle" || gf.curAnimFinished))
				gf.playAnim("idle");
			speakers.playAnim("idle");
		}
	}

	function changeSelectionH(?val:Int = 0)
	{
		grpIcons.members[curSelected].onUnselected();

		var min:Int = Std.int(Math.max(0, Math.floor(curSelected / 3) * 3));
		var max:Int = Std.int(Math.min(characters.length, (Math.floor(curSelected / 3) + 1) * 3));

		curSelected = Util.loop(curSelected + val, min, max - 1);
		FlxG.sound.play(Paths.sound("ui/character_select/CS_select"), 0.7);
		onChangedSelection();
	}

	function changeSelectionV(?val:Int = 0)
	{
		grpIcons.members[curSelected].onUnselected();

		var curRow:Float = Math.floor(curSelected / 3);
		var curColumn:Int = curSelected % 3;
		var totalRows:Float = Math.ceil(characters.length / 3);

		curRow = Util.loop(Std.int(curRow + val), 0, Std.int(totalRows - 1));

		curSelected = Std.int(curRow * 3) + curColumn;
		if (curSelected >= characters.length)
			curSelected = curColumn;
		FlxG.sound.play(Paths.sound("ui/character_select/CS_select"), 0.7);
		onChangedSelection();
	}

	function onChangedSelection()
	{
		cursorX = (curSelected % 3) - 1;
		cursorY = Std.int(Math.floor(curSelected / 3) - 1);

		if (characters[curSelected] != "")
		{
			player = characters[curSelected];
			playerData = cast Paths.json("players/" + player).charSelect;
		}

		grpIcons.members[curSelected].onSelected();
		nametag.setCharacter(characters[curSelected]);
		bf.playAnim("slideout");
		new FlxTimer().start(1 / 24, function(tmr:FlxTimer) {
			refreshBF();
			refreshGF();
		});
	}

	function goToFreeplay()
	{
		canCancel = false;

		FlxTween.tween(cursor, {alpha: 0}, 0.8, {ease: FlxEase.expoOut});
		FlxTween.tween(cursorBlue, {alpha: 0}, 0.8, {ease: FlxEase.expoOut});
		FlxTween.tween(cursorDarkBlue, {alpha: 0}, 0.8, {ease: FlxEase.expoOut});
		FlxTween.tween(cursorConfirmed, {alpha: 0}, 0.8, {ease: FlxEase.expoOut});

		FlxTween.tween(barthing, {y: barthing.y + 80}, 0.8, {ease: FlxEase.backIn});
		FlxTween.tween(dipshitBacking, {y: dipshitBacking.y + 210}, 0.8, {ease: FlxEase.backIn});
		FlxTween.tween(chooseDipshit, {y: chooseDipshit.y + 200}, 0.8, {ease: FlxEase.backIn});
		FlxTween.tween(dipshitBlur, {y: dipshitBlur.y + 220}, 0.8, {ease: FlxEase.backIn});
		for (icon in grpIcons.members)
			FlxTween.tween(icon, {y: icon.y + 300}, 0.8, {ease: FlxEase.backIn});

		var transitionGradient:FlxSprite = new FlxSprite(0, -720, Paths.image("ui/freeplay/transitionGradient"));
		transitionGradient.scale.set(1280, 1);
		transitionGradient.flipY = true;
		transitionGradient.updateHitbox();
		FlxTween.tween(transitionGradient, {y: -150}, 0.8, {ease: FlxEase.backIn});
		add(transitionGradient);

		FlxG.camera.setFilters([blueFadeFilter]);
		FlxTween.num(1.0, 0.0, 0.8, {ease: FlxEase.quadIn}, function(num:Float) { blueFade.setFloat("fadeAmt", num); });

		FlxG.camera.follow(camFollow, LOCKON);
		autoFollow = false;
		FlxTween.tween(camFollow, {y: camFollow.y - 150}, 0.8, {ease: FlxEase.backIn, onComplete: function(twn:FlxTween) {
			MusicBeatState.doTransOut = false;
			MusicBeatState.doTransIn = false;
			FlxG.switchState(new MainMenuState());
		}});
	}

	function refreshBF()
	{
		if (characters[curSelected] == "")
			bf.setCharacter("", "lockedChill");
		else
			bf.setCharacter(player, "characters/" + player + "/" + (playerData.playerAtlas == null ? player + "Chill" : playerData.playerAtlas));
		bf.playAnim("slidein");
	}

	function refreshGF()
	{
		if (characters[curSelected] == "")
			gf.visible = false;
		else
		{
			gf.visible = true;
			gf.setCharacter(player, "characters/" + player + "/" + (playerData.gf.assetPath == null ? "gfChill" : playerData.gf.assetPath));
		}
		gf.playAnim("idle");
	}
}