package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import data.Options;

import newui.Button;

class TabMenu extends FlxSpriteGroup
{
	var back:FlxSprite;
	var tabLabel:FlxSprite;
	var tabLabelText:FlxText;

	public var curTab:Int = -1;
	public var curTabName:String = "";
	public var curTabGroup:TabGroup = null;

	public var tabs:Array<String> = [];
	var tabGroups:Array<TabGroup> = [];
	public var onTabChanged:Void->Void = null;

	var dragging:Bool = false;

	override public function new(x:Float, y:Float)
	{
		super(x, y);

		back = new FlxSprite(0, 60, Paths.image("ui/editors/menuBG"));
		tabLabel = new FlxSprite(Paths.image("ui/editors/tabLabel"));

		var tabLeft:Button = new Button(0, 0, "tabLeft", function() { cycleTab(-1); });
		var tabRight:Button = new Button(0, 0, "tabRight", function() { cycleTab(1); });

		back.x = Math.round(tabLeft.width / 2);
		tabLabel.x = Math.round(back.x + (back.width - tabLabel.width) / 2);
		tabLeft.y = Math.round((tabLabel.height - tabLeft.height) / 2);
		tabRight.x = Math.round(back.x + back.width - (tabRight.width / 2));
		tabRight.y = Math.round((tabLabel.height - tabRight.height) / 2);

		tabLabelText = new FlxText(Std.int(tabLabel.x), Std.int(tabLabel.y), Std.int(tabLabel.width), "A");
		tabLabelText.setFormat("FNF Dialogue", 32, FlxColor.WHITE, CENTER, OUTLINE, 0xFF254949);
		tabLabelText.borderSize = 4;
		tabLabelText.y += Std.int((tabLabel.height - tabLabelText.height - 10) / 2);

		add(back);
		add(tabLabel);
		add(tabLabelText);
		add(tabLeft);
		add(tabRight);
	}

	public function selectTab(tab:Int)
	{
		if (curTabGroup != null)
			remove(curTabGroup, true);

		curTab = tab;
		curTabGroup = tabGroups[curTab];
		curTabGroup.x = back.x - x;
		curTabGroup.y = back.y - y;
		add(curTabGroup);
		curTabName = tabs[curTab];
		tabLabelText.text = curTabName;

		if (onTabChanged != null)
			onTabChanged();
	}

	public function cycleTab(dir:Int)
	{
		selectTab(Util.loop(curTab + dir, 0, tabs.length - 1));
	}

	public function selectTabByName(name:String)
	{
		if (tabs.contains(name))
			selectTab(tabs.indexOf(name));
	}

	public function addGroup(group:TabGroup, name:String)
	{
		tabs.push(name);
		tabGroups.push(group);
		if (curTab < 0)
			selectTab(0);
	}

	override public function update(elapsed:Float)
	{
		if (TopMenu.busy) return;

		if (FlxG.mouse.justMoved && overlapsPoint(FlxG.mouse.getWorldPosition(camera, _point), true, camera))
			UIControl.cursor = MouseCursor.ARROW;

		super.update(elapsed);

		if (dragging)
		{
			UIControl.cursor = MouseCursor.HAND;
			x += FlxG.mouse.deltaX;
			y += FlxG.mouse.deltaY;
			x = Math.max(0, Math.min(FlxG.width - width, x));
			y = Math.max(0, Math.min(FlxG.height - height, y));

			if (!Options.mousePressed())
				dragging = false;
		}
		else if (tabLabel.overlapsPoint(FlxG.mouse.getWorldPosition(camera, tabLabel._point), true, camera))
		{
			UIControl.cursor = MouseCursor.HAND;
			UIControl.infoText = "Click + Drag to move this menu around.\nRight click to select a different tab.";

			if (Options.mouseJustPressed())
				dragging = true;

			if (Options.mouseJustPressed(true))
				new TabMenuSubState(this);
		}
	}
}

class TabGroup extends FlxSpriteGroup
{
}

class TabMenuSubState extends FlxSubState
{
	override public function new(menu:TabMenu)
	{
		super();

		var bgColor:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bgColor.alpha = 0.4;
		add(bgColor);

		var yy:Int = Std.int((FlxG.height - (50 * menu.tabs.length)) / 2);

		for (i in 0...menu.tabs.length)
		{
			var button:TextButton = new TextButton(0, yy, menu.tabs[i], Button.LONG, function() {
				menu.selectTab(i);
				close();
			});
			button.screenCenter(X);
			button.x = Math.round(button.x);
			add(button);
			yy += 50;
		}

		var grp:MusicBeatState = cast FlxG.state;
		grp.persistentUpdate = false;
		grp.openSubState(this);

		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}

	override public function update(elapsed:Float)
	{
		UIControl.cursor = MouseCursor.ARROW;

		super.update(elapsed);

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}
}