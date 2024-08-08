package menus.freeplay;

import flixel.FlxG;
import flixel.system.FlxSound;
import flxanimate.FlxAnimate;

class FreeplayBoyfriend extends FlxAnimate
{
	public var idleTimer:Float = 0;
	var animName:String = "";
	public var state:Int = 0;		// I'm too lazy to make a macro for this shit so Imma say it here: 0 - Default, 1 - Accept, 2 - Gettin Spooked, 3 - Watchin TV, 4 - Fist Pump Loop
	var spooked:Bool = false;

	var animOffsets:Map<String, Array<Int>> = new Map<String, Array<Int>>();

	override public function new(x:Float, y:Float)
	{
		super(x, y, Paths.atlas("ui/freeplay/freeplay-boyfriend"));
		for (k in anim.symbolDictionary.keys())
			anim.addBySymbol(k, k, 0, 0, 24);

		animOffsets["boyfriend dj intro"] = [7, 3];
		animOffsets["bf dj afk"] = [649, 58];

		playAnim("Boyfriend DJ");

		anim.callback = function() {
			if (animName == "Boyfriend DJ watchin tv OG")
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
		if (state == 0 && animName == "Boyfriend DJ")
		{
			idleTimer += elapsed;
			if (idleTimer >= 60 && !spooked)
				state = 2;
			if (idleTimer >= 180)
				state = 3;
		}

		@:privateAccess
		if (anim.curFrame >= anim.frameLength - 1)
		{
			switch (state)
			{
				case 0:
					if (animName == "boyfriend dj intro")
						playAnim("Boyfriend DJ");

				case 2:
					if (animName == "Boyfriend DJ")
					{
						playAnim("bf dj afk");
						spooked = true;
					}
					else
						state = 0;

				case 3:
					if (animName == "Boyfriend DJ")
						playAnim("Boyfriend DJ watchin tv OG");
					else if (animName == "Boyfriend DJ watchin tv OG")
					{
						var frame:Int = FlxG.random.bool(33) ? 112 : 166;
						if (FlxG.random.bool(5) || forceRemote)
							frame = 60;

						isPlaying = true;
						anim.curFrame = frame;
					}
			}
		}

		if (state == 4)
		{
			if (animName != "Boyfriend DJ fist pump")
				playAnim("Boyfriend DJ fist pump");
			if (animName == "Boyfriend DJ fist pump" && anim.curFrame >= 4)
				anim.curFrame = 0;
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.SPACE)
			state = 3;

		if (FlxG.keys.justPressed.SEVEN && cartoon != "")
			FlxG.openURL("https://www.newgrounds.com/portal/view/" + cartoon);
	}

	override public function playAnim(?Name:String, ForceRestart:Bool = false, Looped:Bool = false, Reverse:Bool = false, flipX:Bool = false, flipY:Bool = false)
	{
		animName = Name;
		super.playAnim(Name, ForceRestart, Looped, Reverse, flipX, flipY);
		if (animOffsets.exists(animName))
			offset.set(animOffsets[animName][0], animOffsets[animName][1]);
		else
			offset.set(0, 0);
	}

	public function beatHit()
	{
		@:privateAccess
		if (state == 0 && (animName == "Boyfriend DJ" || anim.curFrame >= anim.frameLength - 1))
			playAnim("Boyfriend DJ");
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