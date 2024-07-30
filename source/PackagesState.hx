#if ALLOW_MODS
package;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.ds.ArraySort;
import sys.FileSystem;
import sys.io.File;

import newui.UIControl;
import newui.Button;
import newui.ScrollBar;

import lime.graphics.Image;
import openfl.display.BitmapData;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

using StringTools;

typedef ModPackage =
{
	var ?appendTo:String;
	var name:String;
	var description:String;
	var mods:Array<String>;
	var ?windowName:String;
	var excludeBase:Null<Bool>;
	var allowModTools:Null<Bool>;
}

class PackageBoxart extends FlxSprite
{
	var id:Int;
	var packageId:String;
	var _package:ModPackage;
	var text:FlxText = null;

	var xx:Int;
	var yy:Int;
	var yoffset:Float;

	var hover:Bool = false;

	override public function new(id:Int, packageId:String, _package:ModPackage)
	{
		xx = id % 7;
		yy = Std.int(Math.floor(id / 7));
		super(50 + (xx * 170), 50 + (yy * 250));

		this.id = id;
		this.packageId = packageId;
		this._package = _package;

		if (packageId == "")
			loadGraphic(Paths.image("package/boxart"));
		else if (FileSystem.exists("packages/"+packageId+"/boxart.png"))
			pixels = BitmapData.fromImage( Image.fromBytes(File.getBytes("packages/"+packageId+"/boxart.png")) );
		else
		{
			makeGraphic(160, 240, FlxColor.GRAY);
			text = new FlxText(0, 0, 150, _package.name);
			text.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		}

		setGraphicSize(160, 240);
		updateHitbox();
		yoffset = offset.y;
	}

	override public function update(elapsed:Float)
	{
		if (cameras[0].alpha < 0.9) return;

		super.update(elapsed);

		if (FlxG.mouse.overlaps(this) && !hover)
		{
			hover = true;
			FlxTween.cancelTweensOf(this);
			FlxTween.tween(offset, {y: yoffset + 10}, 0.15, {ease: FlxEase.sineOut});
		}

		if (!FlxG.mouse.overlaps(this) && hover)
		{
			hover = false;
			FlxTween.cancelTweensOf(this);
			FlxTween.tween(offset, {y: yoffset}, 0.15, {ease: FlxEase.sineOut});
		}

		if (hover)
		{
			UIControl.cursor = MouseCursor.BUTTON;
			if (FlxG.mouse.justPressed && PackagesState.instance != null)
				PackagesState.instance.openPreview(packageId);
		}
	}

	override public function draw()
	{
		super.draw();
		if (text != null)
		{
			text.x = x + 5;
			text.y = y + ((height-text.height)/2) - offset.y;
			text.cameras = cameras;
			text.draw();
		}
	}
}

class PackagesState extends MusicBeatState
{
	public static var instance:PackagesState = null;
	public static var done:Bool = false;
	public static var excludeBase:Bool = false;
	public static var allowModTools:Bool = true;

	public static function getPackages():Array<String>
	{
		if (!FileSystem.isDirectory("packages"))
			return [];

		var p:Array<String> = [];

		for (file in FileSystem.readDirectory("packages"))
		{
			if (FileSystem.isDirectory("packages/" + file))
				p.push(file);
		}
		ArraySort.sort(p, function(a:String, b:String) {
			if (a < b)
				return -1;
			if (a > b)
				return 1;
			return 0;
		});
		return p;
	}

	public static function loadPackage(packageName:String):ModPackage
	{
		var ret:ModPackage = cast haxe.Json.parse(File.getContent("packages/" + packageName + "/data.json"));
		for (p in getPackages())
		{
			var _p:ModPackage = cast haxe.Json.parse(File.getContent("packages/" + p + "/data.json"));
			if (_p.appendTo == packageName)
			{
				for (m in _p.mods)
					ret.mods.push(m);
			}
		}

		return ret;
	}



	var packages:Array<String> = [];
	var packageMap:Map<String, ModPackage> = new Map<String, ModPackage>();
	var packageId:String;

	var selectionGroup:FlxTypedSpriteGroup<PackageBoxart>;
	var scrollBar:ScrollBar;
	var maxY:Float = 0;

	var cam1:FlxCamera;
	var cam2:FlxCamera;

	var previewGroup:FlxSpriteGroup;
	var banner:FlxSprite;
	var logo:FlxSprite;
	var title:FlxText;
	var desc:FlxText;
	var descScrollBar:ScrollBar;
	var descY:Float = 0;
	var playButton:TextButton;
	var shortcutButton:TextButton;
	var backButton:TextButton;

	override public function create()
	{
		super.create();
		instance = this;

		cam1 = new FlxCamera();
		cam1.bgColor = FlxColor.TRANSPARENT;
		cam1.zoom = 0.6;
		cam1.alpha = 0;
		FlxG.cameras.add(cam1, false);

		cam2 = new FlxCamera();
		cam2.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(cam2, false);

		packages = getPackages();
		packages.unshift("");
		var poppers:Array<String> = [];

		for (p in packages)
		{
			if (p == "")
				packageMap[p] = {name: "Friday Night Funkin", description: "", mods: [], excludeBase: false, allowModTools: true};
			else
			{
				var packageData:ModPackage = cast haxe.Json.parse(File.getContent("packages/" + p + "/data.json"));
				if (FileSystem.exists("packages/" + p + "/description.txt"))
					packageData.description = File.getContent("packages/" + p + "/description.txt").replace("\r","");
				packageMap[p] = packageData;
				if (packageData.appendTo != null && packageData.appendTo != "")
					poppers.push(p);
			}
		}

		for (p in poppers)
		{
			if (packageMap.exists(packageMap[p].appendTo))
			{
				for (m in packageMap[p].mods)
					packageMap[packageMap[p].appendTo].mods.push(m);
			}
			packages.remove(p);
		}

		FlxG.mouse.visible = true;

		selectionGroup = new FlxTypedSpriteGroup<PackageBoxart>();
		selectionGroup.cameras = [cam2];
		add(selectionGroup);

		var i:Int = 0;
		for (p in packages)
		{
			var pack:PackageBoxart = new PackageBoxart(i, p, packageMap[p]);
			selectionGroup.add(pack);
			if (pack.y + pack.height + 50 > maxY)
				maxY = pack.y + pack.height + 50;
			i++;
		}

		maxY -= FlxG.height;

		scrollBar = new ScrollBar(FlxG.width - 40, 50, FlxG.height - 100);
		scrollBar.onChanged = function() {
			selectionGroup.y = scrollBar.scroll * -maxY;
		}
		scrollBar.cameras = [cam2];
		if (maxY > 0)
			add(scrollBar);

		banner = new FlxSprite();
		banner.cameras = [cam1];
		add(banner);

		logo = new FlxSprite();
		logo.cameras = [cam1];
		add(logo);

		title = new FlxText().setFormat("VCR OSD Mono", 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		title.cameras = [cam1];
		add(title);

		desc = new FlxText(50, 0, FlxG.width - 100, "").setFormat("VCR OSD Mono", 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		desc.cameras = [cam1];
		add(desc);

		previewGroup = new FlxSpriteGroup();
		previewGroup.cameras = [cam1];

		playButton = new TextButton(50, 0, "Play", function() {
			FlxG.mouse.visible = false;
			done = true;
			if (this.packageId != "")
			{
				ModLoader.packagePath = this.packageId;
				ModLoader.packageData = packageMap[this.packageId];
			}
			MusicBeatState.doTransIn = false;
			MusicBeatState.doTransOut = false;
			FlxG.switchState(new InitState());
		});
		previewGroup.add(playButton);

		shortcutButton = new TextButton(0, 0, "Make Desktop Shortcut", Button.LONG, function() {
			if (this.packageId != "")
			{
				if (FileSystem.exists("packages/" + packageId + "/icon.ico"))
					Sys.command("powershell",["$s=(New-Object -COM WScript.Shell).CreateShortcut('"+Sys.getCwd()+"\\"+packageId+".lnk');$s.TargetPath='"+Sys.programPath()+"';$s.WorkingDirectory='"+Sys.getCwd()+"';$s.iconlocation='"+Sys.getCwd()+"packages/"+packageId+"/icon.ico';$s.Arguments='-package "+packageId+"';$s.Save()"]);
				else
					Sys.command("powershell",["$s=(New-Object -COM WScript.Shell).CreateShortcut('"+Sys.getCwd()+"\\"+packageId+".lnk');$s.TargetPath='"+Sys.programPath()+"';$s.WorkingDirectory='"+Sys.getCwd()+"';$s.Arguments='-package "+packageId+"';$s.Save()"]);
			}
		});
		shortcutButton.screenCenter(X);
		previewGroup.add(shortcutButton);

		backButton = new TextButton(FlxG.width - 50, 0, "Back", function() {
			remove(previewGroup, true);
			backButton.button.animation.play("idle");
			backButton.hovered = false;
			scrollBar.visible = true;

			FlxTween.tween(cam1, {zoom: 0.6, alpha: 0}, 0.5, {ease: FlxEase.expoOut});
			FlxTween.tween(cam2, {zoom: 1, alpha: 1}, 0.5, {ease: FlxEase.expoOut});
			FlxG.sound.play(Paths.sound("ui/editors/exitWindow"), 0.5);
		});
		backButton.x -= backButton.width;
		previewGroup.add(backButton);

		descScrollBar = new ScrollBar(FlxG.width - 40, playButton.height + 20, FlxG.height - 400);
		descScrollBar.onChanged = function() {
			if (descScrollBar.visible)
			{
				desc.y = descY - (descScrollBar.scroll * (desc.height - descScrollBar.height));
				desc.clipRect = new FlxRect(0, descScrollBar.scroll * (desc.height - descScrollBar.height), desc.width, descScrollBar.height);
			}
		}
		previewGroup.add(descScrollBar);
	}

	public override function update(elapsed:Float)
	{
		UIControl.cursor = MouseCursor.ARROW;

		super.update(elapsed);

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}

	public function openPreview(packageId:String)
	{
		if (packageMap.exists(packageId))
		{
			this.packageId = packageId;
			scrollBar.visible = false;
			add(previewGroup);

			var _package:ModPackage = packageMap[packageId];

			if (packageId == "")
				banner.loadGraphic(Paths.image("package/banner"));
			else if (FileSystem.exists("packages/"+packageId+"/banner.png"))
				banner.pixels = BitmapData.fromImage( Image.fromBytes(File.getBytes("packages/"+packageId+"/banner.png")) );
			else
				banner.makeGraphic(1280, 250, FlxColor.TRANSPARENT);
			banner.setGraphicSize(1280);
			banner.updateHitbox();

			if (packageId == "")
			{
				title.text = "";
				logo.loadGraphic(Paths.image("package/logo"));
			}
			else if (FileSystem.exists("packages/"+packageId+"/logo.png"))
			{
				title.text = "";
				logo.pixels = BitmapData.fromImage( Image.fromBytes(File.getBytes("packages/"+packageId+"/logo.png")) );
			}
			else
			{
				title.text = _package.name;
				title.screenCenter(X);
				title.y = (banner.height - title.height) / 2;
				logo.makeGraphic(1, 1, FlxColor.TRANSPARENT);
			}
			logo.setGraphicSize(0, Std.int(banner.height));
			logo.updateHitbox();
			logo.screenCenter(X);

			previewGroup.y = banner.height + 50;

			desc.text = _package.description;
			desc.y = playButton.y + playButton.height + 20;
			descY = desc.y;
			descScrollBar.visible = (desc.text.trim() != "" && desc.height > descScrollBar.height);
			descScrollBar.scroll = 0;
			if (descScrollBar.visible)
				desc.clipRect = new FlxRect(0, descScrollBar.scroll * (desc.height - descScrollBar.height), desc.width, descScrollBar.height);
			else
				desc.clipRect = null;

			FlxTween.tween(cam2, {zoom: 1.5, alpha: 0}, 0.5, {ease: FlxEase.expoOut});
			FlxTween.tween(cam1, {zoom: 1, alpha: 1}, 0.5, {ease: FlxEase.expoOut});
			FlxG.sound.play(Paths.sound("ui/editors/openWindow"), 0.5);
		}
	}
}
#end