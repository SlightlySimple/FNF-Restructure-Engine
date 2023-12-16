#if ALLOW_MODS
package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.ds.ArraySort;
import sys.FileSystem;
import sys.io.File;

import lime.graphics.Image;
import openfl.display.BitmapData;

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
		antialiasing = true;

		if (packageId == "")
			loadGraphic(Paths.image("package/boxart"));
		else if (FileSystem.exists("packages/"+packageId+"/boxart.png"))
			pixels = BitmapData.fromImage( Image.fromBytes(File.getBytes("packages/"+packageId+"/boxart.png")) );
		else
		{
			makeGraphic(160, 240, FlxColor.GRAY);
			text = new FlxText(0, 0, 150, _package.name);
			text.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			text.antialiasing = true;
		}

		setGraphicSize(160, 240);
		updateHitbox();
		yoffset = offset.y;
	}

	override public function update(elapsed:Float)
	{
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

		if (hover && FlxG.mouse.justPressed && PackagesState.instance != null)
			PackagesState.instance.openPreview(packageId);
	}

	override public function draw()
	{
		super.draw();
		if (text != null)
		{
			text.x = x + 5;
			text.y = y + ((height-text.height)/2) - offset.y;
			text.draw();
		}
	}
}

class PackagesUIButton extends FlxSprite
{
	var text:FlxText;
	var action:Void->Void;

	public override function new(x:Float, y:Float, w:Int, h:Int, label:String, action:Void->Void)
	{
		super(x, y);
		makeGraphic(w, h, FlxColor.LIME);
		this.action = action;

		text = new FlxText(x, y, w, label);
		text.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		text.antialiasing = true;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(this))
			action();
	}

	override public function draw()
	{
		super.draw();

		text.x = x;
		text.y = y + ((height-text.height)/2);
		text.draw();
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
	var scrollBack:FlxSprite;
	var scrollCursor:FlxSprite;
	var scrolling:Bool = false;
	var maxY:Float = 0;

	var previewGroup:FlxSpriteGroup;
	var banner:FlxSprite;
	var logo:FlxSprite;
	var title:FlxText;
	var desc:FlxText;
	var playButton:PackagesUIButton;
	var shortcutButton:PackagesUIButton;
	var backButton:PackagesUIButton;

	override public function create()
	{
		super.create();
		instance = this;

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

		scrollBack = new FlxSprite(FlxG.width - 40, 50).makeGraphic(20, FlxG.height - 100, FlxColor.GRAY);
		if (maxY > 0)
			add(scrollBack);

		scrollCursor = new FlxSprite(FlxG.width - 40, 50).makeGraphic(20, 50, FlxColor.WHITE);
		if (maxY > 0)
			add(scrollCursor);

		previewGroup = new FlxSpriteGroup();

		banner = new FlxSprite();
		banner.antialiasing = true;
		previewGroup.add(banner);

		logo = new FlxSprite();
		logo.antialiasing = true;
		previewGroup.add(logo);

		title = new FlxText();
		title.setFormat("VCR OSD Mono", 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		title.antialiasing = true;
		previewGroup.add(title);

		desc = new FlxText(20, 0, FlxG.width - 40, "");
		desc.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		desc.antialiasing = true;
		previewGroup.add(desc);

		playButton = new PackagesUIButton(50, 0, 150, 30, "Play", function() {
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

		shortcutButton = new PackagesUIButton((FlxG.width - 300) / 2, 0, 300, 30, "Make Desktop Shortcut", function() {
			if (this.packageId != "")
			{
				if (FileSystem.exists("packages/" + packageId + "/icon.ico"))
					Sys.command("powershell",["$s=(New-Object -COM WScript.Shell).CreateShortcut('"+Sys.getCwd()+"\\"+packageId+".lnk');$s.TargetPath='"+Sys.programPath()+"';$s.WorkingDirectory='"+Sys.getCwd()+"';$s.iconlocation='"+Sys.getCwd()+"packages/"+packageId+"/icon.ico';$s.Arguments='-package "+packageId+"';$s.Save()"]);
				else
					Sys.command("powershell",["$s=(New-Object -COM WScript.Shell).CreateShortcut('"+Sys.getCwd()+"\\"+packageId+".lnk');$s.TargetPath='"+Sys.programPath()+"';$s.WorkingDirectory='"+Sys.getCwd()+"';$s.Arguments='-package "+packageId+"';$s.Save()"]);
			}
		});
		previewGroup.add(shortcutButton);

		backButton = new PackagesUIButton(FlxG.width - 200, 0, 150, 30, "Back", function() {
			remove(previewGroup, true);
			add(selectionGroup);
			scrollBack.visible = true;
			scrollCursor.visible = true;
		});
		previewGroup.add(backButton);
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (members.contains(selectionGroup) && maxY > 0)
		{
			if (scrolling)
			{
				scrollCursor.y = Math.max(scrollBack.y, Math.min(scrollBack.y + scrollBack.height - scrollCursor.height, FlxG.mouse.y - (scrollCursor.height / 2)));
				selectionGroup.y = FlxMath.remapToRange(scrollCursor.y, scrollBack.y, scrollBack.y + scrollBack.height - scrollCursor.height, 0, -maxY);
				if (FlxG.mouse.justReleased)
					scrolling = false;
			}
			else
			{
				if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(scrollBack))
					scrolling = true;
			}
		}
	}

	public function openPreview(packageId:String)
	{
		if (packageMap.exists(packageId))
		{
			this.packageId = packageId;
			remove(selectionGroup, true);
			scrollBack.visible = false;
			scrollCursor.visible = false;
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

			playButton.y = banner.height + 50;
			shortcutButton.y = playButton.y;
			backButton.y = playButton.y;

			desc.text = _package.description;
			desc.y = playButton.y + playButton.height + 20;
		}
	}
}
#end