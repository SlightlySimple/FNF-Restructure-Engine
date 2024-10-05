package menus.freeplay;

import flixel.FlxG;
import flixel.system.FlxSound;
import flxanimate.FlxAnimate;
import data.PlayableCharacter;
import menus.characterSelect.CharacterSelectState;

class FreeplayDJ extends FlxAnimate
{
	public var data:PlayableCharacterDJ;

	public var idleTimer:Float = 0;
	var animName:String = "";
	public var state:Int = IDLE;
	var spooked:Bool = false;

	var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	override public function new(x:Float, y:Float)
	{
		data = Paths.json("players/" + CharacterSelectState.player).freeplayDJ;

		super(x, y, Paths.atlas("ui/freeplay/characters/" + CharacterSelectState.player + "/" + data.assetPath));

		for (a in data.animations)
		{
			anim.addBySymbol(a.name, a.prefix, 0, 0, 24);
			animOffsets[a.name] = a.offsets;
		}

		playAnim("idle");

		anim.callback = function() {
			if (animName == "cartoon")
			{
				switch (anim.curFrame)
				{
					case 80: FlxG.sound.play(Paths.sound("freeplay/remote_click"));
					case 85: runTvLogic();
				}
			}
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (state == WATCHING_TV && !animOffsets.exists("cartoon"))
			state = IDLE;

		if (state == IDLE && animName == "idle")
		{
			idleTimer += elapsed;
			if (idleTimer >= 60 && !spooked)
				state = EASTER_EGG;
			if (idleTimer >= 180 && animOffsets.exists("cartoon"))
				state = WATCHING_TV;
		}

		@:privateAccess
		if (anim.curFrame >= anim.frameLength - 1)
		{
			switch (state)
			{
				case IDLE:
					if (animName == "intro")
						playAnim("idle");

				case EASTER_EGG:
					if (animName == "idle")
					{
						playAnim("idleEasterEgg");
						spooked = true;
					}
					else
						state = IDLE;

				case WATCHING_TV:
					if (animName == "idle")
						playAnim("cartoon");
					else if (animName == "cartoon")
					{
						var frame:Int = FlxG.random.bool(33) ? 112 : 166;
						if (FlxG.random.bool(5) || forceRemote)
							frame = 60;

						isPlaying = true;
						anim.curFrame = frame;
					}

				case NEW_CHARACTER:
					playAnim("newUnlock");
			}
		}

		if (state == RANKING)
		{
			if (anim.curFrame >= 4)
				anim.curFrame = 0;
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.SPACE)
			state = WATCHING_TV;

		if (FlxG.keys.justPressed.SEVEN && cartoon != "")
			FlxG.openURL("https://www.newgrounds.com/portal/view/" + cartoon);
	}

	override public function playAnim(?Name:String, ForceRestart:Bool = false, Looped:Bool = false, Reverse:Bool = false, flipX:Bool = false, flipY:Bool = false)
	{
		animName = Name;
		super.playAnim(Name, ForceRestart, Looped, Reverse, flipX, flipY);
		if (animOffsets.exists(animName))
			offset.set(animOffsets[animName][0] - 640, animOffsets[animName][1] - 360);
		else
			offset.set(-640, -360);
	}

	public function beatHit()
	{
		@:privateAccess
		if (state == IDLE && (animName == "idle" || anim.curFrame >= anim.frameLength - 1))
			playAnim("idle");
	}

	static var cartoons:Array<String> = [];
	var cartoon:String = "";
	var cartoonSnd:FlxSound = null;
	var forceRemote:Bool = false;

	function runTvLogic()
	{
		if (cartoons.length <= 0)
			cartoons = Paths.listFilesSub("sounds/freeplay/cartoons", ".ogg");

		if (cartoonSnd == null)
			FlxG.sound.play(Paths.sound("freeplay/tv_on"), loadCartoon);
		else
		{
			FlxG.sound.play(Paths.sound("freeplay/channel_switch"), function() {
				cartoonSnd.destroy();
				loadCartoon();
			});
		}
	}

	function loadCartoon()
	{
		forceRemote = false;
		FlxG.sound.music.fadeOut(1, 0.4);

		cartoon = FlxG.random.getObject(cartoons);
		cartoonSnd = new FlxSound().loadEmbedded(Paths.sound("freeplay/cartoons/" + cartoon));
		FlxG.sound.list.add(cartoonSnd);
		cartoonSnd.play();
		cartoonSnd.time = FlxG.random.float(0, Math.max(cartoonSnd.length - 5000, 0));
		cartoonSnd.onComplete = function() { forceRemote = true; };
	}

	public function stopTv()
	{
		if (cartoonSnd != null)
		{
			FlxG.sound.music.fadeIn(0.5, FlxG.sound.music.volume, 0.7);
			cartoonSnd.destroy();
		}
	}
}

enum abstract FreeplayDJState(Int) from Int to Int
{
	var IDLE = 0;
	var ACCEPT = 1;
	var EASTER_EGG = 2;
	var WATCHING_TV = 3;
	var RANKING = 4;
	var NEW_CHARACTER = 5;
}