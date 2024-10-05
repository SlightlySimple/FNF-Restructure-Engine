package game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import data.Options;
import data.PlayableCharacter;
import objects.HealthIcon;

class CharacterUnlockState extends MusicBeatState
{
	var character:String;
	var transitioning:Bool = false;

	override public function new(character:String)
	{
		this.character = character;

		super();
	}

	override public function create()
	{
		super.create();

		if (FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		if (!FlxG.save.data.unlockedCharacters.contains(character))
		{
			FlxG.save.data.unlockedCharacters.push(character);
			FlxG.save.flush();
		}
		var unlockData:PlayableCharacterUnlockData = cast Paths.json("players/" + character).unlockData;

		var dialogContainer:FlxSpriteGroup = new FlxSpriteGroup();
		add(dialogContainer);

		var dialogText:FlxText = new FlxText(0, 0, 0, Lang.get("#characterUnlock.newCharacter", [Lang.get(unlockData.name)])).setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT);

		var dialogBG:FlxSprite = new FlxSprite().makeGraphic(Std.int(dialogText.width + 32), Std.int(dialogText.height + 32), FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(dialogBG, 0, 0, dialogBG.width, dialogBG.height, 16, 16, 0xFF4344F6);
		dialogBG.screenCenter();
		dialogBG.setPosition(Std.int(dialogBG.x), Std.int(dialogBG.y));
		dialogContainer.add(dialogBG);

		dialogText.x = dialogBG.x + 16;
		dialogText.y = dialogBG.y + 16;
		dialogContainer.add(dialogText);

		var healthIcon:HealthIcon = new HealthIcon(dialogBG.x + 427, dialogBG.y + 43, unlockData.icon);
		healthIcon.sc.set(0.5, 0.5);
		healthIcon.updateHitbox();
		healthIcon.x -= Math.round(healthIcon.width / 2);
		healthIcon.y -= Math.round(healthIcon.height / 2);
		healthIcon.flipX = true;
		dialogContainer.add(healthIcon);

		dialogContainer.scale.set(0, 0);
		var iconX:Float = healthIcon.x - (FlxG.width / 2);
		var iconY:Float = healthIcon.y - (FlxG.height / 2);
		FlxTween.num(0.0, 1.0, 0.75, {ease: FlxEase.elasticOut}, function(curScale:Float) {
			dialogContainer.scale.set(curScale, curScale);
			healthIcon.sc.set(0.5 * curScale, 0.5 * curScale);
			healthIcon.updateHitbox();
			healthIcon.setPosition((FlxG.width / 2) + (iconX * curScale), (FlxG.height / 2) + (iconY * curScale));
		});

		FlxG.sound.play(Paths.sound("ui/confirmMenu"));
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if ((Options.keyJustPressed("ui_accept") || Options.mouseJustPressed()) && !transitioning)
		{
			transitioning = true;
			FlxG.camera.fade(FlxColor.BLACK, 0.75, false, function() {
				unlockCharacter();
			});
		}
	}

	public static function unlockCharacter()
	{
		if (PlayState.charactersToUnlock.length > 0)
		{
			MusicBeatState.doTransOut = false;
			MusicBeatState.doTransIn = false;
			FlxG.switchState(new CharacterUnlockState(PlayState.charactersToUnlock.shift()));
		}
		else
			PlayState.GotoMenu(false);
	}
}