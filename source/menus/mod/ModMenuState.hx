#if ALLOW_MODS
package menus.mod;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import polymod.Polymod;
import menus.UINavigation;
import data.Options;

import lime.system.System;
import lime.graphics.Image;
import openfl.display.BitmapData;

class ModMenuState extends MusicBeatState
{
	var modObjects:FlxTypedSpriteGroup<ModObject>;
	var goalY:Float = 15;

	var modName:FlxText;
	var modContributors:FlxTypedSpriteGroup<FlxText>;
	var modDescription:FlxText;
	var modVersion:FlxText;

	var modBG:FlxSprite;
	var modMenuButtons:FlxTypedSpriteGroup<ModMenuButton>;
	var modToggleButton:ModMenuButton;
	var modContributorsButton:ModMenuButton;
	var cursorL:ModMenuCurcor;
	var cursorR:ModMenuCurcor;

	var nav:UINumeralNavigation;

	var curSelected:Int = 0;
	var curButton:Int = 4;

	override public function create()
	{
		super.create();

		Util.menuMusic();

		var bg:FlxSprite = new FlxSprite(Paths.image("ui/" + MainMenuState.menuImages[5]));
		bg.color = MainMenuState.menuColors[5];
		bg.scrollFactor.set();
		add(bg);

		if (ModLoader.modList.length <= 0)
		{
			var noMods:FlxText = new FlxText(0, 0, FlxG.width - 300, Lang.get("#mods.noMods", [Options.keyString("ui_back")])).setFormat("FNF Dialogue", 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			noMods.borderSize = 2;
			noMods.screenCenter();
			add(noMods);

			return;
		}

		modObjects = new FlxTypedSpriteGroup<ModObject>(15, 15);
		add(modObjects);

		for (i in 0...ModLoader.modList.length)
		{
			if (!ModLoader.hiddenMods.contains(ModLoader.modList[i][0]))
			{
				var modObject:ModObject = new ModObject(0, i * 130, ModLoader.modList[i][0]);
				modObjects.add(modObject);
			}
		}

		modBG = new FlxSprite(modObjects.x + modObjects.width + 15, 85);
		modBG.makeGraphic(Std.int(FlxG.width - modBG.x - 15), Std.int(FlxG.height - 100), FlxColor.BLACK);
		modBG.alpha = 0.5;
		add(modBG);

		modName = new FlxText(modBG.x + 25, modBG.y + 15, modBG.width - 50, "").setFormat("FNF Dialogue", 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		modName.borderSize = 2;
		add(modName);

		modContributors = new FlxTypedSpriteGroup<FlxText>(modName.x, modName.y + 135);
		modContributors.visible = false;
		add(modContributors);

		modDescription = new FlxText(modName.x, modName.y + 135, modBG.width - 50, "").setFormat("FNF Dialogue", 28, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(modDescription);

		modVersion = new FlxText(modBG.x + 25, modBG.y + modBG.height - 90, modBG.width - 50, "1.0.0").setFormat("FNF Dialogue", 48, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		modVersion.y -= modVersion.height;
		modVersion.borderSize = 2;
		add(modVersion);

		modMenuButtons = new FlxTypedSpriteGroup<ModMenuButton>();
		add(modMenuButtons);


		modToggleButton = new ModMenuButton(modBG.x + modBG.width - 25, modBG.y + modBG.height - 25, "Enabled");
		modToggleButton.accept = function() {
			for (m in ModLoader.modList)
			{
				if (m[0] == modObjects.members[curSelected].modId)
				{
					m[1] = !m[1];

					if (m[1])
					{
						modToggleButton.back.color = FlxColor.LIME;
						modToggleButton.text.text = "Enabled";
					}
					else
					{
						modToggleButton.back.color = FlxColor.RED;
						modToggleButton.text.text = "Disabled";
					}
				}
			}
			ModLoader.saveModlist();
		}
		modToggleButton.x -= modToggleButton.width;
		modToggleButton.y -= modToggleButton.height;

		var modMoveDownButton:ModMenuButton = new ModMenuButton(modToggleButton.x - modToggleButton.width - 15, modToggleButton.y, "Move Down");
		modMoveDownButton.accept = function() {
			shiftMod(modObjects.members[curSelected].modId, 1);
		}
		modMoveDownButton.back.color = FlxColor.BLACK;

		var modMoveUpButton:ModMenuButton = new ModMenuButton(modMoveDownButton.x - modMoveDownButton.width - 15, modToggleButton.y, "Move Up");
		modMoveUpButton.accept = function() {
			shiftMod(modObjects.members[curSelected].modId, -1);
		}
		modMoveUpButton.back.color = FlxColor.BLACK;

		var modMoveToBottomButton:ModMenuButton = new ModMenuButton(modMoveDownButton.x, modMoveDownButton.y - modMoveDownButton.height - 15, "Move to Bottom");
		modMoveToBottomButton.accept = function() {
			shiftModFully(modObjects.members[curSelected].modId, 1);
		}
		modMoveToBottomButton.back.color = FlxColor.BLACK;

		var modMoveToTopButton:ModMenuButton = new ModMenuButton(modMoveUpButton.x, modMoveUpButton.y - modMoveUpButton.height - 15, "Move to Top");
		modMoveToTopButton.accept = function() {
			shiftModFully(modObjects.members[curSelected].modId, -1);
		}
		modMoveToTopButton.back.color = FlxColor.BLACK;

		modMenuButtons.add(modMoveToTopButton);
		modMenuButtons.add(modMoveToBottomButton);
		modMenuButtons.add(modMoveUpButton);
		modMenuButtons.add(modMoveDownButton);
		modMenuButtons.add(modToggleButton);

		var enableAllModsButton:ModMenuButton = new ModMenuButton(modBG.x, 15, "Enable All");
		enableAllModsButton.accept = function() {
			for (m in ModLoader.modList)
			{
				if (!ModLoader.hiddenMods.contains(m[0]))
					setModEnabled(m[0], true);
			}
		}
		enableAllModsButton.back.color = FlxColor.BLACK;
		modMenuButtons.add(enableAllModsButton);

		var disableAllModsButton:ModMenuButton = new ModMenuButton(enableAllModsButton.x + 275, 15, "Disable All");
		disableAllModsButton.accept = function() {
			for (m in ModLoader.modList)
			{
				if (!ModLoader.hiddenMods.contains(m[0]))
					setModEnabled(m[0], false);
			}
		}
		disableAllModsButton.back.color = FlxColor.BLACK;
		modMenuButtons.add(disableAllModsButton);

		var openModsFolderButton:ModMenuButton = new ModMenuButton(disableAllModsButton.x + 275, 15, "Open Mods Folder");
		openModsFolderButton.accept = function() {
			System.openFile("mods");
		}
		openModsFolderButton.back.color = FlxColor.BLACK;
		modMenuButtons.add(openModsFolderButton);

		var modDescriptionButton:ModMenuButton = new ModMenuButton(modBG.x + 100, modBG.y + 75, "Description");
		modDescriptionButton.accept = function() {
			modDescription.visible = true;
			modContributors.visible = false;
		}
		modDescriptionButton.back.color = FlxColor.BLACK;
		modMenuButtons.add(modDescriptionButton);

		modContributorsButton = new ModMenuButton(modBG.x + modBG.width - 100, modBG.y + 75, "Contributors");
		modContributorsButton.x -= modContributorsButton.width;
		modContributorsButton.accept = function() {
			modDescription.visible = false;
			modContributors.visible = true;
		}
		modContributorsButton.back.color = FlxColor.BLACK;
		modMenuButtons.add(modContributorsButton);

		cursorL = new ModMenuCurcor(">", 40, 1);
		add(cursorL);

		cursorR = new ModMenuCurcor("<", 40, 0);
		add(cursorR);

		nav = new UINumeralNavigation(changeButton, changeSelection, function() {
			if (modMenuButtons.members[curButton].enabled)
			{
				FlxG.sound.play(Paths.sound(nav.uiSoundFiles[1]));
				modMenuButtons.members[curButton].accept();
			}
		}, function() {
			ModLoader.saveModlist();
			FlxG.switchState(new MainMenuState());
		}, changeSelection);
		nav.uiSounds[1] = false;
		add(nav);

		changeSelection();
		changeButton();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (ModLoader.modList.length <= 0)
		{
			if (Options.keyJustPressed("ui_back"))
			{
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound("ui/cancelMenu"));
				FlxG.switchState(new MainMenuState());
			}

			return;
		}

		modObjects.y = FlxMath.lerp(modObjects.y, goalY, elapsed * 10);

		for (i in 0...modObjects.length)
			modObjects.members[i].y = FlxMath.lerp(modObjects.members[i].y, modObjects.y + (i * 130), elapsed * 10);
	}

	function refreshGoalY()
	{
		var yy:Float = goalY + (curSelected * 130);
		while (yy < FlxG.height / 3)
		{
			yy += 40;
			goalY += 40;
		}
		while (yy > FlxG.height * 2 / 3)
		{
			yy -= 40;
			goalY -= 40;
		}
		goalY = Math.min(15, Math.max(-(modObjects.height - FlxG.height + 15), goalY));
	}

	function changeSelection(?val:Int = 0)
	{
		curSelected = Util.loop(curSelected + val, 0, modObjects.members.length - 1);

		for (i in 0...modObjects.length)
		{
			if (i == curSelected)
				modObjects.members[i].select();
			else
				modObjects.members[i].unselect();
		}

		modName.text = modObjects.members[curSelected].mod.title;
		if (modObjects.members[curSelected].mod.contributors == null)
		{
			modContributorsButton.enabled = false;
			modDescription.visible = true;
			modContributors.visible = false;
		}
		else
		{
			modContributorsButton.enabled = true;

			modContributors.forEachAlive(function(txt:FlxText) {
				txt.kill();
				txt.destroy();
			});
			modContributors.clear();

			var yy:Float = 0;
			for (c in modObjects.members[curSelected].mod.contributors)
			{
				var contName:FlxText = new FlxText(0, yy, 0, c.name).setFormat("FNF Dialogue", 28, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
				contName.visible = modContributors.visible;
				if (contName.width > (modBG.width - 50) / 2)
					contName.fieldWidth = (modBG.width - 50) / 2;
				modContributors.add(contName);

				var contRole:FlxText = new FlxText(modBG.width - 50, yy, modBG.width - contName.width - 75, c.role).setFormat("FNF Dialogue", 28, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
				contRole.x -= contRole.width;
				contRole.visible = modContributors.visible;
				modContributors.add(contRole);

				yy += Math.max(contName.height, contRole.height) + 10;
			}
		}
		modDescription.text = modObjects.members[curSelected].mod.description;
		modVersion.text = modObjects.members[curSelected].mod.modVersion;

		for (m in ModLoader.modList)
		{
			if (m[0] == modObjects.members[curSelected].modId)
			{
				if (m[1])
				{
					modToggleButton.back.color = FlxColor.LIME;
					modToggleButton.text.text = "Enabled";
				}
				else
				{
					modToggleButton.back.color = FlxColor.RED;
					modToggleButton.text.text = "Disabled";
				}
			}
		}

		refreshGoalY();
	}

	function changeButton(?val:Int = 0)
	{
		curButton = Util.loop(curButton + val, 0, modMenuButtons.members.length - 1);

		cursorL.pos = [modMenuButtons.members[curButton].x + 30, modMenuButtons.members[curButton].y + (modMenuButtons.members[curButton].height / 2)];
		cursorR.pos = [modMenuButtons.members[curButton].x + modMenuButtons.members[curButton].width - 30, modMenuButtons.members[curButton].y + (modMenuButtons.members[curButton].height / 2)];
	}

	function setModEnabled(mod:String, enabled:Bool)
	{
		for (m in ModLoader.modList)
		{
			if (m[0] == mod)
			{
				m[1] = enabled;

				if (mod == modObjects.members[curSelected].modId)
				{
					if (m[1])
					{
						modToggleButton.back.color = FlxColor.LIME;
						modToggleButton.text.text = "Enabled";
					}
					else
					{
						modToggleButton.back.color = FlxColor.RED;
						modToggleButton.text.text = "Disabled";
					}
				}
			}
		}
	}

	function shiftMod(mod:String, amount:Int)
	{
		var modToMove:Array<Dynamic> = null;
		for (m in ModLoader.modList)
		{
			if (m[0] == mod)
				modToMove = m;
		}
		var newPos:Int = ModLoader.modList.indexOf(modToMove) + amount;
		if (newPos >= 0 && newPos < ModLoader.modList.length - 1 && ModLoader.hiddenMods.contains(ModLoader.modList[newPos][0]))
		{
			while (newPos >= 0 && newPos < ModLoader.modList.length - 1 && ModLoader.hiddenMods.contains(ModLoader.modList[newPos][0]))
				newPos += amount;
		}
		newPos = Std.int(Math.max(0, Math.min(ModLoader.modList.length - 1, newPos)));
		ModLoader.modList.remove(modToMove);
		ModLoader.modList.insert(newPos, modToMove);

		modObjects.sort(function(Order:Int, Obj1:ModObject, Obj2:ModObject) { return FlxSort.byValues(Order, Obj1.modIndex, Obj2.modIndex); });
		for (i in 0...modObjects.members.length)
		{
			if (modObjects.members[i].modId == mod)
			{
				curSelected = i;
				break;
			}
		}

		refreshGoalY();
	}

	function shiftModFully(mod:String, amount:Int)
	{
		var modToMove:Array<Dynamic> = null;
		for (m in ModLoader.modList)
		{
			if (m[0] == mod)
				modToMove = m;
		}
		ModLoader.modList.remove(modToMove);
		if (amount < 0)
			ModLoader.modList.insert(0, modToMove);
		else
			ModLoader.modList.push(modToMove);

		modObjects.sort(function(Order:Int, Obj1:ModObject, Obj2:ModObject) { return FlxSort.byValues(Order, Obj1.modIndex, Obj2.modIndex); });
		for (i in 0...modObjects.members.length)
		{
			if (modObjects.members[i].modId == mod)
			{
				curSelected = i;
				break;
			}
		}

		refreshGoalY();
	}
}

class ModMenuButton extends FlxSpriteGroup
{
	public var back:FlxSprite;
	public var text:FlxText;
	public var accept:Void->Void;
	public var enabled(default, set):Bool = true;

	override public function new(x:Float, y:Float, txt:String)
	{
		super(x, y);

		back = new FlxSprite().makeGraphic(230, 60, FlxColor.WHITE);
		back.alpha = 0.5;
		add(back);

		text = new FlxText(0, 0, 230, txt).setFormat("FNF Dialogue", 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		text.y += Std.int((back.height - text.height) / 2);
		add(text);
	}

	public function set_enabled(val:Bool):Bool
	{
		back.alpha = (val ? 0.5 : 0.2);
		text.alpha = (val ? 1 : 0.6);
		return enabled = val;
	}
}

class ModMenuCurcor extends FlxText
{
	public var pos:Array<Float> = [0, 0];

	override public function new(text:String, size:Int, _offset:Float)
	{
		super(0, 0, 0, text, size);
		setFormat("FNF Dialogue", size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		offset.set(width * _offset, height / 2);
		pixelPerfect = true;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		x = FlxMath.lerp(x, pos[0], (x == 0 ? 1 : FlxG.elapsed * 20));
		y = FlxMath.lerp(y, pos[1], (y == 0 ? 1 : FlxG.elapsed * 20));
	}

	override public function setPosition(x:Float = 0, y:Float = 0)
	{
		super.setPosition(x, y);
		pos = [x, y];
	}
}

class ModObject extends FlxSpriteGroup
{
	public var mod:ModMetadata;
	public var modId:String;
	public var modIndex(get, never):Int;

	var bg:FlxSprite;
	var icon:FlxSprite;
	var name:FlxText;
	var description:FlxText;

	override public function new(x:Float, y:Float, modId:String)
	{
		super(x, y);
		this.modId = modId;
		mod = ModLoader.getModMetaData(this.modId);

		bg = new FlxSprite().makeGraphic(450, 120, FlxColor.BLACK);
		add(bg);

		var xx:Int = 15;
		icon = new FlxSprite(15, 15);
		if (mod.icon == null)
			icon.makeGraphic(5, 5, FlxColor.TRANSPARENT);
		else
		{
			icon.pixels = BitmapData.fromImage(Image.fromBytes(mod.icon));
			icon.setGraphicSize(90);
			icon.updateHitbox();
			xx += 105;
		}
		add(icon);

		name = new FlxText(xx, 15, 0, mod.title).setFormat("FNF Dialogue", 28, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		if (name.width > bg.width - xx - 15)
		{
			while (name.width > bg.width - xx - 15)
				name.text = name.text.substr(0, name.text.length - 1);
			name.text = name.text.substr(0, name.text.length - 3) + "...";
		}
		add(name);

		description = new FlxText(xx, 45, Std.int(bg.width - xx - 15), mod.description).setFormat("FNF Dialogue", 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		if (description.height > 80)
		{
			while (description.height > 80)
				description.text = description.text.substr(0, description.text.length - 1);
			description.text = description.text.substr(0, description.text.length - 3) + "...";
		}
		add(description);
	}

	public function get_modIndex():Int
	{
		var i:Int = 0;
		for (m in ModLoader.modList)
		{
			if (m[0] == modId)
				return i;
			i++;
		}

		return -1;
	}

	public function select()
	{
		bg.alpha = 0.5;
		icon.alpha = 1;
		name.alpha = 1;
		description.alpha = 1;
	}

	public function unselect()
	{
		bg.alpha = 0.3;
		icon.alpha = 0.5;
		name.alpha = 0.5;
		description.alpha = 0.5;
	}
}
#end