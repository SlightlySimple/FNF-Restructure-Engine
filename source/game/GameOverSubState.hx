package game;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import data.Options;
import menus.PauseSubState;
import objects.Character;

class GameOverSubState extends FlxSubState
{
	public static var instance:GameOverSubState;
	public static var character:Character = null;
	public static var sfx:String = "fnf_loss_sfx";
	public static var gameOverMusic:String = "gameOver";
	public static var gameOverMusicEnd:String = "gameOverEnd";

	var deadCharacter:Character;
	var deadCharacterAnims:Array<String> = ["deathLoop", "deathConfirm"];
	var fadeSprite:FlxSprite;
	var camFollow:FlxObject;
	var camFollowTimer:FlxTimer;
	var transitioning:Bool = false;
	var menuMusic:FlxSound = null;
	var playedMusic:Bool = false;

	public static function resetStatics()
	{
		sfx = "fnf_loss_sfx";
		gameOverMusic = "gameOver";
		gameOverMusicEnd = "gameOverEnd";
		PauseSubState.music = "breakfast";
		ResultsState.music = "results";
	}

	override public function new()
	{
		super();

		instance = this;
		FlxG.camera.bgColor = FlxColor.BLACK;

		fadeSprite = new FlxSprite().makeGraphic(5000, 5000, FlxColor.BLACK);
		fadeSprite.scrollFactor.set();
		fadeSprite.screenCenter();
		fadeSprite.alpha = 0;

		deadCharacter = new Character(character.getScreenPosition().x - character.characterData.position[0], character.getScreenPosition().y - character.characterData.position[1], character.characterData.gameOverCharacter, character.wasFlipped);
		if (character.scale.x != character.characterData.scale[0] || character.scale.y != character.characterData.scale[1])
			deadCharacter.scaleCharacter(character.scale.x / character.characterData.scale[0], character.scale.y / character.characterData.scale[1]);
		deadCharacter.playAnim("firstDeath");
		add(deadCharacter);

		if (sfx == "fnf_loss_sfx" && deadCharacter.characterData.gameOverSFX != "")
			sfx = deadCharacter.characterData.gameOverSFX;

		if (sfx != "")
			FlxG.sound.play(Paths.sound(sfx));

		camFollow = new FlxObject(deadCharacter.getGraphicMidpoint().x - deadCharacter.baseOffsets[0] + deadCharacter.characterData.camPositionGameOver[0], deadCharacter.getGraphicMidpoint().y - deadCharacter.baseOffsets[1] + deadCharacter.characterData.camPositionGameOver[1], 1, 1);
		add(camFollow);
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		camFollowTimer = new FlxTimer();
		camFollowTimer.start(0.5, function(tmr:FlxTimer)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		});

		if (gameOverMusic != "")
		{
			menuMusic = new FlxSound().loadEmbedded(Paths.music(gameOverMusic), true);
			FlxG.sound.list.add(menuMusic);
		}

		PlayState.instance.hscriptExec("gameOverCreate", []);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.hscriptExec("gameOverUpdate", [elapsed]);

		if (!transitioning)
		{
			if (!playedMusic && deadCharacter.curAnimFinished)
			{
				playedMusic = true;
				if (menuMusic != null)
					menuMusic.play();
				deadCharacter.playAnim(deadCharacterAnims[0]);
				PlayState.instance.hscriptExec("gameOverMusicStarted", []);
			}

			if (Options.keyJustPressed("ui_accept") || Options.mouseJustPressed())
				confirm();

			if (Options.keyJustPressed("ui_back") || Options.mouseJustPressed(true))
			{
				transitioning = true;
				if (menuMusic != null)
					menuMusic.stop();

				PlayState.instance.exitToMenu();
			}
		}

		PlayState.instance.hscriptExec("gameOverUpdatePost", [elapsed]);
	}

	public function confirm()
	{
		transitioning = true;
		if (fadeSprite != null)
			add(fadeSprite);
		if (menuMusic != null)
			menuMusic.stop();
		if (gameOverMusicEnd != "")
			FlxG.sound.play(Paths.music(gameOverMusicEnd));
		deadCharacter.playAnim(deadCharacterAnims[1]);
		PlayState.instance.hscriptExec("gameOverConfirm", []);

		new FlxTimer().start(0.7, function(tmr:FlxTimer) { FlxTween.tween(fadeSprite, {alpha: 1}, 2, { onComplete: function(twn:FlxTween) { FlxG.switchState(new PlayState()); }}); });
	}
}