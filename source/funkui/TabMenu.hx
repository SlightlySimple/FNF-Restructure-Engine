package funkui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.ds.ArraySort;

class TabMenu extends FlxSpriteGroup
{
	var tabButtons:FlxSpriteGroup;
	var tabButtonText:FlxTypedSpriteGroup<FlxText>;
	public var curTab:Int = -1;
	public var curTabName:String = "";
	var hoveredTab:Int = -1;

	var tabGroups:Array<TabGroup> = [];
	public var onTabChanged:Void->Void = null;

	override public function new(x:Float, y:Float, w:Float, h:Float, tabs:Array<String>, ?fontSize:Int = 12)
	{
		super(x, y);

		var back:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(w), Std.int(h+30), 0xFFC0FFFF);
		add(back);

		var front:FlxSprite = new FlxSprite(5, 30).makeGraphic(Std.int(w-10), Std.int(h-5), FlxColor.WHITE);
		add(front);

		tabButtons = new FlxSpriteGroup();
		add(tabButtons);

		tabButtonText = new FlxTypedSpriteGroup<FlxText>();
		add(tabButtonText);

		for (i in 0...tabs.length)
		{
			var newButton:FlxSprite = new FlxSprite(5 + ((w / tabs.length) * i), 5).makeGraphic(Std.int((w / tabs.length)-10), 20, FlxColor.WHITE);
			tabButtons.add(newButton);

			var newButtonText:FlxText = new FlxText(5 + ((w / tabs.length) * i), 5, (w / tabs.length)-10, Lang.get(tabs[i]), fontSize);
			newButtonText.color = FlxColor.BLACK;
			newButtonText.font = "VCR OSD Mono";
			newButtonText.alignment = CENTER;
			tabButtonText.add(newButtonText);
		}
	}

	public function selectTab(tab:Int)
	{
		if (curTab > -1)
			remove(members[members.length-1]);

		tabGroups[tab].x = 0;
		tabGroups[tab].y = 30;
		add(tabGroups[tab]);
		curTab = tab;
		curTabName = tabButtonText.members[curTab].text;

		for (i in 0...tabButtons.members.length)
		{
			if (i == curTab)
				tabButtons.members[i].setGraphicSize(Std.int(tabButtons.members[i].width), 25);
			else
				tabButtons.members[i].setGraphicSize(Std.int(tabButtons.members[i].width), 20);
			tabButtons.members[i].updateHitbox();
		}

		if (onTabChanged != null)
			onTabChanged();
	}

	public function addGroup(group:TabGroup)
	{
		tabGroups.push(group);
		if (curTab < 0)
			selectTab(0);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justMoved)
		{
			hoveredTab = -1;
			for (i in 0...tabButtons.members.length)
			{
				if (tabButtons.members[i].overlapsPoint(FlxG.mouse.getWorldPosition(camera, tabButtons.members[i]._point), true, camera) && i != curTab)
					hoveredTab = i;
			}
		}

		if (hoveredTab > -1 && FlxG.mouse.justPressed)
			selectTab(hoveredTab);
	}
}


class IsolatedTabMenu extends FlxSpriteGroup
{
	public var curTab:Int = -1;

	var tabGroups:Array<TabGroup> = [];
	public var onTabChanged:Void->Void = null;

	override public function new(x:Float, y:Float, w:Float, h:Float)
	{
		super(x, y);

		var back:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(w), Std.int(h), 0xFFC0FFFF);
		add(back);

		var front:FlxSprite = new FlxSprite(5, 5).makeGraphic(Std.int(w-10), Std.int(h-10), FlxColor.WHITE);
		add(front);
	}

	public function selectTab(tab:Int)
	{
		if (curTab > -1)
			remove(members[members.length-1]);

		tabGroups[tab].x = 0;
		tabGroups[tab].y = 0;
		add(tabGroups[tab]);
		curTab = tab;

		if (onTabChanged != null)
			onTabChanged();
	}

	public function addGroup(group:TabGroup)
	{
		tabGroups.push(group);
		if (curTab < 0)
			selectTab(0);
	}
}

class TabButtons extends FlxSpriteGroup
{
	var tabButtons:FlxSpriteGroup;
	var tabButtonText:FlxTypedSpriteGroup<FlxText>;
	public var curTab:Int = 0;
	public var curTabName:String = "";
	var hoveredTab:Int = -1;

	public var menu:IsolatedTabMenu = null;

	override public function new(x:Float, y:Float, w:Float, tabs:Array<String>, ?fontSize:Int = 12)
	{
		super(x, y);

		var back:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(w), 30, 0xFFC0FFFF);
		add(back);

		tabButtons = new FlxSpriteGroup();
		add(tabButtons);

		tabButtonText = new FlxTypedSpriteGroup<FlxText>();
		add(tabButtonText);

		for (i in 0...tabs.length)
		{
			var newButton:FlxSprite = new FlxSprite(5 + ((w / tabs.length) * i), 5).makeGraphic(Std.int((w / tabs.length)-10), 20, FlxColor.WHITE);
			tabButtons.add(newButton);

			var newButtonText:FlxText = new FlxText(5 + ((w / tabs.length) * i), 5, (w / tabs.length)-10, Lang.get(tabs[i]), fontSize);
			newButtonText.color = FlxColor.BLACK;
			newButtonText.font = "VCR OSD Mono";
			newButtonText.alignment = CENTER;
			tabButtonText.add(newButtonText);
		}
		selectTab(0);
	}

	public function selectTab(tab:Int)
	{
		curTab = tab;
		curTabName = tabButtonText.members[curTab].text;

		for (i in 0...tabButtonText.members.length)
		{
			if (i == curTab)
				tabButtonText.members[i].color = FlxColor.GRAY;
			else
				tabButtonText.members[i].color = FlxColor.BLACK;
		}

		if (menu != null)
			menu.selectTab(tab);
	}

	public function selectTabByName(tab:String)
	{
		for (i in 0...tabButtonText.members.length)
		{
			if (tabButtonText.members[i].text == tab)
			{
				selectTab(i);
				break;
			}
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justMoved)
		{
			hoveredTab = -1;
			for (i in 0...tabButtons.members.length)
			{
				if (tabButtons.members[i].overlapsPoint(FlxG.mouse.getWorldPosition(camera, tabButtons.members[i]._point), true, camera) && i != curTab)
					hoveredTab = i;
			}
		}

		if (hoveredTab > -1 && FlxG.mouse.justPressed)
			selectTab(hoveredTab);
	}
}

class TabGroup extends FlxSpriteGroup
{
	function sortDropdowns(a:FlxSprite, b:FlxSprite):Int
	{
		if (Std.isOfType(a, DropdownMenu) && !Std.isOfType(b, DropdownMenu))
			return 1;
		if (Std.isOfType(b, DropdownMenu) && !Std.isOfType(a, DropdownMenu))
			return -1;
		if (Std.isOfType(a, DropdownMenu) && Std.isOfType(b, DropdownMenu))
		{
			if (a.y < b.y)
				return 1;
			if (a.y > b.y)
				return -1;
		}
		return 0;
	}

	public override function add(Sprite:FlxSprite):FlxSprite
	{
		var ret:FlxSprite = super.add(Sprite);
		ArraySort.sort(members, sortDropdowns);
		return ret;
	}
}



class Confirm extends IsolatedTabMenu
{
	public var yesFunc:Void->Void = null;
	public var noFunc:Void->Void = null;

	override public function new(w:Float, h:Float, txt:String, grp:FlxGroup)
	{
		super(0, 0, w, h);
		screenCenter();
		grp.add(this);
		var group:TabGroup = new TabGroup();

		var text:FlxText = new FlxText(0, 0, 300, Lang.get(txt), 18);
		text.color = FlxColor.BLACK;
		text.font = "VCR OSD Mono";
		text.alignment = CENTER;
		group.add(text);

		var yes:TextButton = new TextButton((w/3)-25, h - 30, 50, 20, "#yes");
		yes.onClicked = function() {
			if (yesFunc != null)
				yesFunc();
			grp.remove(this);
		}
		group.add(yes);

		var no:TextButton = new TextButton((w*2/3)-25, h - 30, 50, 20, "#no");
		no.onClicked = function() {
			if (noFunc != null)
				noFunc();
			grp.remove(this);
		}
		group.add(no);

		addGroup(group);
	}
}

class Notify extends IsolatedTabMenu
{
	public var okFunc:Void->Void = null;

	override public function new(w:Float, h:Float, txt:String, grp:FlxGroup)
	{
		super(0, 0, w, h);
		screenCenter();
		grp.add(this);
		var group:TabGroup = new TabGroup();

		var text:FlxText = new FlxText(0, 0, 300, txt, 18);
		text.color = FlxColor.BLACK;
		text.font = "VCR OSD Mono";
		text.alignment = CENTER;
		group.add(text);

		var ok:TextButton = new TextButton((w/2)-25, h - 30, 50, 20, "#ok");
		ok.onClicked = function() {
			if (okFunc != null)
				okFunc();
			grp.remove(this);
		}
		group.add(ok);

		addGroup(group);
	}
}