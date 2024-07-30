#if ALLOW_MODS
package menus;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import polymod.Polymod;
import data.Options;

import lime.system.System;
import lime.graphics.Image;
import openfl.display.BitmapData;

import newui.UIControl;
import newui.Checkbox;
import newui.Button;
import newui.ScrollBar;

using StringTools;

class ModObject extends FlxSpriteGroup
{
	var bg:FlxSprite;
	var mod:ModMetadata;
	public var modId:String;
	public var grabbed:Bool = false;

	override public function new(x:Float, y:Float, modId:String)
	{
		super(x, y);
		this.modId = modId;
		mod = ModLoader.getModMetaData(this.modId);

		bg = new FlxSprite().makeGraphic(Std.int(FlxG.width - 60), 180, FlxColor.BLACK);
		updateBG();
		add(bg);

		var xx:Int = 15;
		var modIcon:FlxSprite = new FlxSprite(15, 15);
		if (mod.icon == null)
			modIcon.makeGraphic(5, 5, FlxColor.TRANSPARENT);
		else
		{
			modIcon.pixels = BitmapData.fromImage( Image.fromBytes(mod.icon) );
			modIcon.setGraphicSize(150);
			modIcon.updateHitbox();
			xx += 165;
		}
		add(modIcon);

		var modName:FlxText = new FlxText(xx, 15, Std.int(bg.width - xx - 15), mod.title, 30);
		modName.font = "FNF Dialogue";
		add(modName);

		var desc:String = mod.description;
		var modDesc:FlxText = new FlxText(xx, 50, Std.int(bg.width - xx - 200), desc, 20);
		modDesc.font = "FNF Dialogue";
		add(modDesc);

		correctHeight(true);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (grabbed)
		{
			bg.scale.x += (0.98 - bg.scale.x) * elapsed * 10;
			bg.scale.y += (0.9 - bg.scale.y) * elapsed * 10;
		}
		else
		{
			bg.scale.x += (1 - bg.scale.x) * elapsed * 10;
			bg.scale.y += (1 - bg.scale.y) * elapsed * 10;
		}
	}

	public function updateBG()
	{
		for (m in ModLoader.modList)
			if (m[0] == modId)
				bg.alpha = (m[1] ? 0.6 : 0.4);
	}

	public function correctHeight(?instant:Bool = false)
	{
		var yy:Float = 60;
		for (i in 0...ModLoader.modList.length)
		{
			if (ModLoader.modList[i][0] == modId)
				break;
			if (!ModLoader.hiddenMods.contains(ModLoader.modList[i][0]))
				yy += 200;
		}

		if (instant)
			y = yy;
		else if (yy != y)
		{
			FlxTween.cancelTweensOf(this, ["y"]);
			FlxTween.tween(this, {y: yy}, 0.45, {ease: FlxEase.circOut});
		}
	}
}

class ModMenuState extends MusicBeatState
{
	var modObjects:FlxTypedSpriteGroup<ModObject>;
	var modObjectUI:FlxSpriteGroup;
	var modCheckbox:Checkbox;
	var scrollbar:ScrollBar;
	var curMod:String = "";
	var hovered:ModObject = null;
	var grabbed:Bool = false;
	var grabIndex:Int = 0;
	var grabOffset:Float = 0;

	var camFollow:FlxObject;
	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var mousePos:FlxObject;

	override public function create()
	{
		camGame = new FlxCamera();
		FlxG.cameras.add(camGame);

		camFollow = new FlxObject();
		camFollow.screenCenter();
		camGame.follow(camFollow, LOCKON, 1);

		camHUD = new FlxCamera();
		camHUD.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camHUD, false);

		mousePos = new FlxObject();

		super.create();

		Util.menuMusic();

		var bg:FlxSprite = new FlxSprite(Paths.image('ui/' + MainMenuState.menuImages[5]));
		bg.color = MainMenuState.menuColors[5];
		bg.scrollFactor.set();
		add(bg);

		modObjects = new FlxTypedSpriteGroup<ModObject>();
		add(modObjects);

		if (ModLoader.modList.length <= 0)
		{
			var noMods:FlxText = new FlxText(0, 0, FlxG.width - 300, Lang.get("#mods.noMods", [Options.keyString("ui_back")]), 32);
			noMods.font = "VCR OSD Mono";
			noMods.alignment = CENTER;
			noMods.borderStyle = OUTLINE;
			noMods.borderSize = 2;
			noMods.borderColor = FlxColor.BLACK;
			noMods.screenCenter();
			noMods.scrollFactor.set();
			add(noMods);

			return;
		}

		for (i in 0...ModLoader.modList.length)
		{
			var modObject:ModObject = new ModObject(30, 0, ModLoader.modList[i][0]);
			if (!ModLoader.hiddenMods.contains(ModLoader.modList[i][0]))
				modObjects.add(modObject);
		}

		curMod = ModLoader.modList[0][0];

		modObjectUI = new FlxSpriteGroup(0, 30);
		modObjectUI.cameras = [camHUD];
		add(modObjectUI);

		var vbox:VBox = new VBox(FlxG.width - 150, 15);

		modCheckbox = new Checkbox(0, 0, "Enabled");
		modCheckbox.checked = ModLoader.modList[0][1];
		modCheckbox.onClicked = function() { setModEnabled(curMod, modCheckbox.checked); };

		var moveToTopButton:TextButton = new TextButton(0, 0, "Top");
		moveToTopButton.onClicked = function() { shiftModFully(curMod, -1); };

		var moveToBottomButton:TextButton = new TextButton(0, 0, "Bottom");
		moveToBottomButton.onClicked = function() { shiftModFully(curMod, 1); };

		vbox.add(moveToTopButton);
		vbox.add(modCheckbox);
		vbox.add(moveToBottomButton);
		modObjectUI.add(vbox);

		scrollbar = new ScrollBar(FlxG.width - 25, 60, FlxG.height - 120);
		scrollbar.onChanged = function() {
			var minY:Float = FlxG.height / 2;
			var maxY:Float = ((ModLoader.modList.length - ModLoader.hiddenMods.length - 3) * 200) + (FlxG.height / 2);
			camFollow.y = minY + ((maxY - minY) * scrollbar.scroll);
		}
		scrollbar.cameras = [camHUD];
		add(scrollbar);

		var disclaimerBG:FlxSprite = new FlxSprite(0, FlxG.height - 30).makeGraphic(820, 30, FlxColor.BLACK);
		disclaimerBG.screenCenter(X);
		disclaimerBG.alpha = 0.6;
		disclaimerBG.cameras = [camHUD];
		add(disclaimerBG);

		var disclaimer:FlxText = new FlxText(disclaimerBG.x, disclaimerBG.y, Std.int(disclaimerBG.width), Lang.get("#mods.disclaimer"), 24);
		disclaimer.font = "VCR OSD Mono";
		disclaimer.alignment = CENTER;
		disclaimer.cameras = [camHUD];
		add(disclaimer);

		var hbox:HBox = new HBox(0, 10);
		hbox.cameras = [camHUD];

		var enableAll:TextButton = new TextButton(0, 0, "Enable All");
		enableAll.onClicked = function() {
			for (m in ModLoader.modList)
				setModEnabled(m[0], true);
		};
		hbox.add(enableAll);

		var disableAll:TextButton = new TextButton(0, 0, "Disable All");
		disableAll.onClicked = function() {
			for (m in ModLoader.modList)
				setModEnabled(m[0], false);
		};
		hbox.add(disableAll);

		var openFolder:TextButton = new TextButton(0, 0, "Open Mods Folder", Button.LONG);
		openFolder.onClicked = function() {
			System.openFile("mods");
		};
		hbox.add(openFolder);

		add(hbox);
		hbox.screenCenter(X);

		FlxG.mouse.visible = true;
	}

	function updateModObject(mod:String)
	{
		modObjects.forEachAlive(function(obj:ModObject) {
			if (obj.modId == mod)
			{
				obj.updateBG();
				obj.correctHeight();
			}
		});
	}

	function updateAllModObjects()
	{
		modObjects.forEachAlive(function(obj:ModObject) {
			obj.updateBG();
			obj.correctHeight();
		});
	}

	override public function update(elapsed:Float)
	{
		UIControl.cursor = MouseCursor.ARROW;
		mousePos.x = FlxG.mouse.x;
		mousePos.y = FlxG.mouse.y + camFollow.y - (FlxG.height / 2);

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

		if (grabbed)
		{
			UIControl.cursor = MouseCursor.HAND;
			var grabShift:Int = Std.int((mousePos.y - grabOffset) / 200);

			if (grabIndex < grabShift)
			{
				while (grabIndex < grabShift)
				{
					shiftMod(curMod, 1);
					grabIndex++;
				}
			}
			else if (grabIndex > grabShift)
			{
				while (grabIndex > grabShift)
				{
					shiftMod(curMod, -1);
					grabIndex--;
				}
			}

			if (Options.mouseJustReleased())
			{
				grabbed = false;
				hovered.grabbed = false;
			}
		}
		else
		{
			if (FlxG.mouse.justMoved)
			{
				modObjects.forEachAlive(function(obj:ModObject) {
					if (obj.overlaps(mousePos))
					{
						if (UIControl.cursor == MouseCursor.ARROW)
							UIControl.cursor = MouseCursor.HAND;
						curMod = obj.modId;
						hovered = obj;
						for (m in ModLoader.modList)
						{
							if (m[0] == curMod)
								modCheckbox.checked = m[1];
						}
					}
				});
			}

			if (Options.mouseJustPressed() && hovered.overlaps(mousePos) && !FlxG.mouse.overlaps(modObjectUI))
			{
				grabOffset = mousePos.y;
				grabIndex = 0;
				grabbed = true;
				hovered.grabbed = true;
			}
		}

		if (hovered != null)
			modObjectUI.y = hovered.y - camFollow.y + (FlxG.height / 2);

		var change:Float = FlxG.mouse.wheel;
		if (change == 0)
		{
			if (Options.keyJustPressed("ui_up"))
				change = 1;

			if (Options.keyJustPressed("ui_down"))
				change = -1;
		}

		if (change != 0)
		{
			camFollow.y -= change * 200;
			camFollow.y = Math.max(FlxG.height / 2, Math.min(((ModLoader.modList.length - ModLoader.hiddenMods.length - 3) * 200) + (FlxG.height / 2), camFollow.y));

			var minY:Float = FlxG.height / 2;
			var maxY:Float = ((ModLoader.modList.length - ModLoader.hiddenMods.length - 3) * 200) + (FlxG.height / 2);
			scrollbar.scroll = (camFollow.y - minY) / (maxY - minY);
		}

		if (Options.keyJustPressed("ui_back"))
		{
			ModLoader.saveModlist();
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound("ui/cancelMenu"));
			FlxG.switchState(new MainMenuState());
		}

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}

	function setModEnabled(mod:String, enabled:Bool)
	{
		for (m in ModLoader.modList)
		{
			if (m[0] == mod)
			{
				m[1] = enabled;
				updateModObject(mod);
			}
		}
		ModLoader.saveModlist();
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

		updateAllModObjects();
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

		updateAllModObjects();
	}
}
#end