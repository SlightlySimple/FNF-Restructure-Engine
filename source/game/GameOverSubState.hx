package game;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
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
	var camFollow:FlxObject;
	var camFollowTimer:FlxTimer;
	var transitioning:Bool = false;

	public static function resetStatics()
	{
		sfx = "fnf_loss_sfx";
		gameOverMusic = "gameOver";
		gameOverMusicEnd = "gameOverEnd";
		PauseSubState.music = "breakfast";
	}

	override public function new()
	{
		super();

		instance = this;

		deadCharacter = new Character(character.getScreenPosition().x - character.characterData.position[0], character.getScreenPosition().y - character.characterData.position[1], character.characterData.gameOverCharacter, character.wasFlipped);
		add(deadCharacter);

		if (sfx != "")
			FlxG.sound.play(Paths.sound(sfx));

		camFollow = new FlxObject(deadCharacter.getGraphicMidpoint().x + deadCharacter.characterData.camPosition[0], deadCharacter.getGraphicMidpoint().y + deadCharacter.characterData.camPosition[1], 1, 1);
		add(camFollow);
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		camFollowTimer = new FlxTimer();
		camFollowTimer.start(0.5, function(tmr:FlxTimer)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		});

		PlayState.instance.hscriptExec("gameOverCreate", []);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.hscriptExec("gameOverUpdate", [elapsed]);

		if (deadCharacter.curAnimName == deadCharacter.characterData.firstAnimation && deadCharacter.curAnimFinished && !transitioning)
		{
			if (gameOverMusic != "")
				FlxG.sound.playMusic(Paths.music(gameOverMusic));
			deadCharacter.playAnim(deadCharacterAnims[0]);
			PlayState.instance.hscriptExec("gameOverMusicStarted", []);
		}

		if (Options.keyJustPressed("ui_accept") && !transitioning)
			confirm();

		if (Options.keyJustPressed("ui_back") && !transitioning)
		{
			transitioning = true;
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			PlayState.instance.exitToMenu();
		}

		PlayState.instance.hscriptExec("gameOverUpdatePost", [elapsed]);
	}

	public function confirm()
	{
		transitioning = true;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if (gameOverMusicEnd != "")
			FlxG.sound.play(Paths.music(gameOverMusicEnd));
		deadCharacter.playAnim(deadCharacterAnims[1]);
		PlayState.instance.hscriptExec("gameOverConfirm", []);

		new FlxTimer().start(0.7, function(tmr:FlxTimer)
		{
			FlxTween.tween(deadCharacter, {alpha: 0}, 2, { onComplete: function(twn:FlxTween)
			{
				FlxG.switchState(new PlayState());
			}});
		});
	}
}