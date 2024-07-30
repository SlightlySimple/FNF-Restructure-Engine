package newui;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import data.Options;

import lime.app.Application;
import lime.graphics.Image;
import lime.math.Rectangle;

class ColorPickSubstate extends FlxSubState
{
	var screen:Image;
	var func:FlxColor->Void;

	override public function new(func:FlxColor->Void)
	{
		super();
		this.func = func;

		FlxG.mouse.visible = false;
		screen = Application.current.window.readPixels(new Rectangle(0, 0, Application.current.window.width, Application.current.window.height));
		FlxG.mouse.visible = true;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var screenScale:Float = Math.min(screen.width / FlxG.width, screen.height / FlxG.height);
		var mouseX:Float = FlxG.mouse.x * screenScale;
		var mouseY:Float = FlxG.mouse.y * screenScale;
		if (screen.width / FlxG.width > screen.height / FlxG.height)
			mouseX += (screen.width - (screen.height * (FlxG.width / FlxG.height))) / 2;
		else
			mouseY += (screen.height - (screen.width / (FlxG.width / FlxG.height))) / 2;

		var px:FlxColor = cast screen.getPixel(Std.int(mouseX), Std.int(mouseY), 1);
		func(px);

		if (Options.mouseJustPressed())
			close();
	}
}