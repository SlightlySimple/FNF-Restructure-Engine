package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;
import openfl.ui.MouseCursor;
import openfl.events.KeyboardEvent;
import data.Options;
import helpers.DeepEquals;

using StringTools;

typedef TopMenuList =
{
	var label:String;
	var options:Array<TopMenuOption>;
}

typedef TopMenuOption =
{
	var label:String;
	var ?options:Array<TopMenuOption>;
	var ?icon:String;
	var ?action:Void->Void;
	var ?condition:Void->Bool;
	var ?shortcut:Array<FlxKey>;
}

class TopMenu extends FlxSpriteGroup
{
	var options:Array<TopMenuList>;
	var keySequence:Array<FlxKey> = [];

	var buttons:Array<FlxSprite> = [];
	var buttonText:Array<FlxText> = [];
	var hovered:Int = -1;

	public static var busy:Bool = false;
	public var dropdown:TopMenuDropdown = null;

	public override function new(options:Array<TopMenuList>)
	{
		super();
		this.options = options;

		Main.fpsOnRight = true;

		var xx:Float = 0;
		for (o in options)
		{
			var txt:FlxText = new FlxText(xx + 10, 0, 0, o.label, 16);
			txt.color = FlxColor.BLACK;
			txt.font = "Monsterrat";
			buttonText.push(txt);

			var btn:FlxSprite = new FlxSprite(xx).makeGraphic(Std.int(txt.width + 20), 25, FlxColor.WHITE);
			btn.active = false;
			buttons.push(btn);
			xx += btn.width;
		}

		add(new FlxSprite().makeGraphic(Std.int(xx), 30, 0xFF254949));
		for (b in buttons)
			add(b);
		for (t in buttonText)
			add(t);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	public override function destroy()
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		super.destroy();
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		var lastHovered:Int = hovered;

		if (FlxG.mouse.justMoved)
		{
			hovered = -1;
			for (i in 0...buttons.length)
			{
				if (buttons[i].overlapsPoint(FlxG.mouse.getWorldPosition(camera, buttons[i]._point), true, camera))
				{
					hovered = i;
					UIControl.cursor = MouseCursor.BUTTON;
					buttons[i].color = 0xFF254949;
					buttonText[i].color = FlxColor.WHITE;
				}
				else
				{
					buttons[i].color = FlxColor.WHITE;
					buttonText[i].color = FlxColor.BLACK;
				}
			}
		}

		if (hovered > -1 && ((dropdown != null && lastHovered != hovered) || Options.mouseJustPressed()))
		{
			if (dropdown != null)
			{
				remove(dropdown, true);
				dropdown.destroy();
			}
			if (Options.mouseJustPressed())
				FlxG.sound.play(Paths.sound("ui/editors/keyboard1"));
			dropdown = new TopMenuDropdown(buttons[hovered].x, 25, options[hovered].options);
			dropdown.menu = this;
			busy = true;
			add(dropdown);
		}
	}

	public function resetHover()
	{
		for (i in 0...buttons.length)
		{
			{
				buttons[i].color = FlxColor.WHITE;
				buttonText[i].color = FlxColor.BLACK;
			}
		}
	}

	function onKeyDown(e:KeyboardEvent)
	{
		if (DropdownMenu.isOneActive || InputText.isOneActive) return;
		if (dropdown != null) return;

		var key:FlxKey = cast e.keyCode;
		if (!keySequence.contains(key))
			keySequence.push(key);

		for (o in options)
			onKeyDownRecursive(o.options);
	}

	function onKeyDownRecursive(opt:Array<TopMenuOption>)
	{
		for (_o in opt)
		{
			if (_o != null)
			{
				if (_o.options != null)
					onKeyDownRecursive(_o.options);
				else if (_o.shortcut != null && DeepEquals.deepEquals(keySequence, _o.shortcut))
					_o.action();
			}
		}
	}

	function onKeyUp(e:KeyboardEvent)
	{
		var key:FlxKey = cast e.keyCode;
		keySequence.remove(key);
	}
}

class TopMenuDropdown extends FlxSpriteGroup
{
	var options:Array<TopMenuOption>;

	var buttons:Array<FlxSprite> = [];
	var buttonText:Array<FlxText> = [];
	var buttonText2:Array<FlxText> = [];
	var hovered:Int = -1;

	public var menu:TopMenu = null;
	public var prev:TopMenuDropdown = null;
	public var next:TopMenuDropdown = null;

	public override function new(x:Float, y:Float, options:Array<TopMenuOption>)
	{
		super(x, y);
		this.options = options.copy();
		while (this.options.contains(null))
			this.options.remove(null);

		var icons:Array<FlxSprite> = [];

		var yy:Float = 2;
		var ww:Float = 0;
		for (o in options)
		{
			if (o == null)
				yy += 2;
			else
			{
				var txt:FlxText = new FlxText(40, yy, 0, o.label, 16);
				txt.color = FlxColor.BLACK;
				txt.font = "Monsterrat";
				buttonText.push(txt);

				var str:String = "";
				if (o.options != null)
					str = ">";
				else if (o.shortcut != null)
				{
					for (i in 0...o.shortcut.length)
					{
						str += o.shortcut[i].toString().replace("CONTROL", "CTRL");
						if (i < o.shortcut.length - 1)
							str += " + ";
					}
				}
				var txt2:FlxText = new FlxText(0, yy, 0, str, 16);
				if (o.options == null)
					txt2.alpha = 0.5;
				txt2.color = FlxColor.BLACK;
				txt2.font = "Monsterrat";
				buttonText2.push(txt2);

				if (o.icon != null)
				{
					var condMet:Bool = true;
					if (o.condition != null)
						condMet = o.condition();
					if (condMet)
					{
						var icon:FlxSprite = new FlxSprite(20, yy + 12, Paths.image("ui/editors/" + o.icon));
						icon.x -= Std.int(icon.width / 2);
						icon.y -= Std.int(icon.height / 2);
						icon.active = false;
						icons.push(icon);
					}
				}

				if (txt.x + txt.width + txt2.width + 50 > ww)
					ww = txt.x + txt.width + txt2.width + 50;
				yy += 25;
			}
		}

		yy = 2;
		for (o in options)
		{
			if (o == null)
				yy += 2;
			else
			{
				var btn:FlxSprite = new FlxSprite(2, yy).makeGraphic(Std.int(ww) - 4, 25, FlxColor.WHITE);
				btn.active = false;
				buttons.push(btn);
				yy += 25;
			}
		}

		add(new FlxSprite().makeGraphic(Std.int(ww), Std.int(yy + 2), 0xFF254949));
		for (b in buttons)
			add(b);
		for (t in buttonText)
			add(t);
		for (t in buttonText2)
		{
			t.x = Std.int(ww - t.width) - 20;
			add(t);
		}
		for (i in icons)
			add(i);

		for (m in members)
		{
			var a:Float = m.alpha;
			m.alpha = 0;
			FlxTween.tween(m, {alpha: a}, 0.1);
		}
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		var prevHovered:Int = hovered;
		if (FlxG.mouse.justMoved)
		{
			hovered = -1;
			for (i in 0...buttons.length)
			{
				if (buttons[i].overlapsPoint(FlxG.mouse.getWorldPosition(camera, buttons[i]._point), true, camera))
				{
					hovered = i;
					UIControl.cursor = MouseCursor.BUTTON;
					buttons[i].color = 0xFF254949;
					buttonText[i].color = FlxColor.WHITE;
					buttonText2[i].color = FlxColor.WHITE;
					if (hovered != prevHovered && next != null)
					{
						remove(next, true);
						next.destroy();
						next = null;
					}
					if (options[hovered].options != null && next == null)
					{
						next = new TopMenuDropdown(buttons[hovered].x + buttons[hovered].width - x, buttons[hovered].y - y, options[hovered].options);
						next.menu = menu;
						next.prev = this;
						add(next);
					}
				}
				else
				{
					buttons[i].color = FlxColor.WHITE;
					buttonText[i].color = FlxColor.BLACK;
					buttonText2[i].color = FlxColor.BLACK;
				}
			}
		}

		if (Options.mouseJustPressed())
		{
			if (hovered > -1 && options[hovered].action != null)
			{
				FlxG.sound.play(Paths.sound("ui/editors/keyboard2"));
				options[hovered].action();
			}
			if (menu != null)
			{
				menu.resetHover();
				menu.remove(this, true);
				menu.dropdown = null;
			}
			else
				FlxG.state.remove(this, true);
			TopMenu.busy = false;
			destroy();
		}
	}
}