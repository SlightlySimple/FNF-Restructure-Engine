package newui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.FlxSubState;
import data.Options;
import lime.system.Clipboard;

import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

import newui.UIControl;
import newui.Button;

class PopupWindow extends FlxSubState
{
	var mainGroup:Draggable;
	public var group:FlxSpriteGroup;

	public static function CreateWithGroup(group:FlxSpriteGroup, ?borderSize:Int = 35):PopupWindow
	{
		var window:PopupWindow = new PopupWindow("popupBG", 30, Std.int(group.width + (borderSize * 2)), Std.int(group.height + (borderSize * 2)));
		window.group.add(group);

		return window;
	}

	override public function new(graphic:String, borderSize:Int, width:Int, height:Int)
	{
		if (DropdownMenu.isOneActive)
			DropdownMenu.currentActive.close();

		super();

		var bgColor:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bgColor.alpha = 0.4;
		add(bgColor);

		mainGroup = new Draggable(0, 0, "", borderSize);
		mainGroup.back.loadGraphic(getNineSlice(graphic, borderSize, width, height));
		add(mainGroup);
		mainGroup.screenCenter();
		mainGroup.setPosition(Math.round(mainGroup.x), Math.round(mainGroup.y));

		group = new FlxSpriteGroup();

		mainGroup.add(group);

		var state:FlxState = FlxG.state;
		if (state.subState != null)
		{
			while (state.subState != null)
				state = state.subState;
		}
		state.persistentUpdate = false;
		state.openSubState(this);

		FlxG.sound.play(Paths.sound("ui/editors/openWindow"), 0.5);
		closeCallback = function() { FlxG.sound.play(Paths.sound("ui/editors/exitWindow"), 0.5); }

		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}

	override public function update(elapsed:Float)
	{
		UIControl.cursor = MouseCursor.ARROW;

		super.update(elapsed);

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}

	public static function createThreeSlice(img:BitmapData, src:BitmapData, borderSize:Int, x:Int, y:Int, height:Int)
	{
		var centerSizeH:Int = Std.int(src.height - (borderSize * 2));
		var totalSizeH:Int = Std.int(src.height);
		var finalCenterSizeH:Int = height - borderSize - borderSize;
		var finalCenterRatioH:Float = finalCenterSizeH / centerSizeH;

		// Top
		var mat:Matrix = new Matrix();
		mat.tx = x;
		mat.ty = y;
		var rect:Rectangle = new Rectangle(x, y, src.width, borderSize);
		img.draw(src, mat, rect, true);

		// Bottom
		rect.y = y + height - borderSize;
		mat.ty = y + height - totalSizeH;
		img.draw(src, mat, rect, true);

		// Middle
		mat.identity();
		mat.scale(1, finalCenterRatioH);
		mat.tx = x;
		mat.ty = y - (borderSize * finalCenterRatioH) + borderSize;
		rect.x = x;
		rect.y = y + borderSize;
		rect.width = src.width;
		rect.height = finalCenterSizeH;
		img.draw(src, mat, rect, true);
	}

	public static function getNineSlice(graphic:String, borderSize:Int, width:Int, height:Int):FlxGraphic
	{
		var key:String = "NineSlice_" + graphic + "_" + Std.string(width) + "_" + Std.string(height);
		if (FlxG.bitmap.get(key) == null)
		{
			var img:BitmapData = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
			createNineSlice(img, Paths.image("ui/editors/" + graphic).bitmap, borderSize, 0, 0, width, height);
			FlxGraphic.fromBitmapData(img, false, key);
		}

		return FlxG.bitmap.get(key);
	}

	static function createNineSlice(img:BitmapData, src:BitmapData, borderSize:Int, x:Int, y:Int, width:Int, height:Int)
	{
		var centerSizeW:Int = Std.int(src.width - (borderSize * 2));
		var centerSizeH:Int = Std.int(src.height - (borderSize * 2));
		var totalSizeW:Int = Std.int(src.width);
		var totalSizeH:Int = Std.int(src.height);
		var finalCenterSizeW:Int = width - borderSize - borderSize;
		var finalCenterSizeH:Int = height - borderSize - borderSize;
		var finalCenterRatioW:Float = finalCenterSizeW / centerSizeW;
		var finalCenterRatioH:Float = finalCenterSizeH / centerSizeH;

		// Top left corner
		var mat:Matrix = new Matrix();
		mat.tx = x;
		mat.ty = y;
		var rect:Rectangle = new Rectangle(x, y, borderSize, borderSize);
		img.draw(src, mat, rect);

		// Top right corner
		rect.x = x + width - borderSize;
		mat.tx = x + width - totalSizeW;
		img.draw(src, mat, rect);

		// Bottom right corner
		rect.y = y + height - borderSize;
		mat.ty = y + height - totalSizeH;
		img.draw(src, mat, rect);

		// Bottom left corner
		rect.x = x;
		mat.tx = x;
		img.draw(src, mat, rect);

		// Top
		mat.identity();
		mat.scale(finalCenterRatioW, 1);
		mat.tx = x - (borderSize * finalCenterRatioW) + borderSize;
		mat.ty = y;
		rect.x = x + borderSize;
		rect.width = finalCenterSizeW;
		rect.y = y;
		img.draw(src, mat, rect, true);

		// Bottom
		rect.y = y + height - borderSize;
		mat.ty = y + height - totalSizeH;
		img.draw(src, mat, rect, true);

		// Left
		mat.identity();
		mat.scale(1, finalCenterRatioH);
		mat.tx = x;
		mat.ty = y - (borderSize * finalCenterRatioH) + borderSize;
		rect.x = x;
		rect.width = borderSize;
		rect.y = y + borderSize;
		rect.height = finalCenterSizeH;
		img.draw(src, mat, rect, true);

		// Right
		rect.x = x + width - borderSize;
		mat.tx = x + width - totalSizeW;
		img.draw(src, mat, rect, true);

		// Middle
		mat.identity();
		mat.scale(finalCenterRatioW, finalCenterRatioH);
		mat.tx = x - (borderSize * finalCenterRatioW) + borderSize;
		mat.ty = y - (borderSize * finalCenterRatioH) + borderSize;
		rect.x = x + borderSize;
		rect.y = y + borderSize;
		rect.width = finalCenterSizeW;
		rect.height = finalCenterSizeH;
		img.draw(src, mat, rect, true);
	}
}

class ChoiceWindow extends PopupWindow
{
	override public function new(txt:String, ?choices:Array<Array<Dynamic>> = null)
	{
		var vbox:VBox = new VBox(35, 35);

		var text:FlxText = new FlxText(0, 0, 0, txt);
		text.setFormat("FNF Dialogue", 24, FlxColor.BLACK, CENTER);
		if (text.width > 800)
			text.fieldWidth = 800;
		vbox.add(text);

		var hbox:HBox = new HBox();
		hbox.spacing = 50;

		var btnImage:String = Button.SHORT;

		for (c in choices)
		{
			var text:String = cast c[0];
			if (text.length > 4)
				btnImage = Button.DEFAULT;
		}

		for (c in choices)
		{
			var text:String = cast c[0];
			var outcome:Void->Void = cast c[1];

			var btn:TextButton = new TextButton(0, 0, text, btnImage);
			btn.onClicked = function() {
				if (outcome != null)
					outcome();
				close();
			}
			hbox.add(btn);
		}

		vbox.add(hbox);

		super("popupBG", 30, Std.int(vbox.width + 70), Std.int(vbox.height + 70));

		group.add(vbox);
	}
}

class Notify extends ChoiceWindow
{
	override public function new(txt:String, ?okFunc:Void->Void = null)
	{
		super(txt, [["#ok", okFunc]]);
	}
}

class Confirm extends ChoiceWindow
{
	override public function new(txt:String, ?yesFunc:Void->Void = null, ?noFunc:Void->Void = null)
	{
		super(txt, [["#yes", yesFunc], ["#no", noFunc]]);
	}
}

class ColorPicker extends PopupWindow
{
	var swatch:ColorSwatch;
	var hexLabel:Label;

	override public function new(initialColor:FlxColor, acceptFunc:FlxColor->Void, ?cancelFunc:Void->Void = null)
	{
		var vbox:VBox = new VBox(35, 35);

		var hbox:HBox = new HBox();
		hbox.spacing = 30;

		swatch = new ColorSwatch(0, 0, 125, 125, initialColor);
		hbox.add(swatch);

		var colorGroup:FlxSpriteGroup = new FlxSpriteGroup();

		var border:FlxSprite = new FlxSprite().makeGraphic(50, 125, 0xFF254949);
		colorGroup.add(border);

		var color:FlxSprite = new FlxSprite(2, 2).makeGraphic(46, 121, FlxColor.WHITE);
		color.color = swatch.swatchColor;
		colorGroup.add(color);

		hbox.add(colorGroup);

		var mode:TextButton = new TextButton(0, 0, "HSV", Button.SHORT);
		hbox.add(mode);

		vbox.add(hbox);

		var hbox2:HBox = new HBox();

		var r:Stepper = new Stepper(0, 0, "R:", initialColor.red, 5, 0, 255, 0);
		r.onChanged = function() {
			if (swatch.mode == "rgb")
				swatch.r = r.valueInt;
			else
				swatch.h = r.value * 359 / 255;
			color.color = swatch.swatchColor;
			updateHexLabel();
		};
		hbox2.add(r);

		var g:Stepper = new Stepper(0, 0, "G:", initialColor.green, 5, 0, 255, 0);
		g.onChanged = function() {
			if (swatch.mode == "rgb")
				swatch.g = g.valueInt;
			else
				swatch.s = g.value / 255;
			color.color = swatch.swatchColor;
			updateHexLabel();
		};
		hbox2.add(g);

		var b:Stepper = new Stepper(0, 0, "B:", initialColor.blue, 5, 0, 255, 0);
		b.onChanged = function() {
			if (swatch.mode == "rgb")
				swatch.b = b.valueInt;
			else
				swatch.v = b.value / 255;
			color.color = swatch.swatchColor;
			updateHexLabel();
		};
		hbox2.add(b);

		mode.onClicked = function() {
			if (swatch.mode == "rgb")
			{
				mode.textObject.text = "RGB";
				swatch.mode = "hsv";
				r.labelText.text = "H:";
				g.labelText.text = "S:";
				b.labelText.text = "V:";
			}
			else
			{
				mode.textObject.text = "HSV";
				swatch.mode = "rgb";
				r.labelText.text = "R:";
				g.labelText.text = "G:";
				b.labelText.text = "B:";
			}
			swatch.onChanged();
		}

		vbox.add(hbox2);

		hexLabel = new Label("#FFFFFF");
		vbox.add(hexLabel);
		updateHexLabel();

		swatch.onChanged = function() {
			color.color = swatch.swatchColor;
			updateHexLabel();
			if (swatch.mode == "rgb")
			{
				r.value = swatch.r;
				g.value = swatch.g;
				b.value = swatch.b;
			}
			else
			{
				r.value = Std.int(swatch.h * 255 / 359);
				g.value = Std.int(swatch.s * 255);
				b.value = Std.int(swatch.v * 255);
			}
		};

		var buttons:HBox = new HBox();

		var copy:TextButton = new TextButton(0, 0, "Copy RGB", function() { Clipboard.text = Std.string(swatch.r) + "," + Std.string(swatch.g) + "," + Std.string(swatch.b); });
		buttons.add(copy);

		var copyHex:TextButton = new TextButton(0, 0, "Copy Hex", function() { Clipboard.text = hexLabel.text; });
		buttons.add(copyHex);

		var paste:TextButton = new TextButton(0, 0, "Paste", function() {
			if (Clipboard.text != null)
			{
				if (Clipboard.text.indexOf(",") > -1)
				{
					var rgb:Array<String> = Clipboard.text.split(",");
					if (rgb.length > 2)
						swatch.swatchColor = FlxColor.fromRGB(Std.parseInt(rgb[0]), Std.parseInt(rgb[1]), Std.parseInt(rgb[2]));
				}
				else
				{
					var rgb:FlxColor = FlxColor.fromString(Clipboard.text);
					swatch.swatchColor = rgb;
				}
				swatch.onChanged();
				swatch.resetCursorPositions();
			}
		});
		buttons.add(paste);

		vbox.add(buttons);

		var buttons2:HBox = new HBox();

		var accept:TextButton = new TextButton(0, 0, "Accept", function() {
			acceptFunc(swatch.swatchColor);
			close();
		});
		buttons2.add(accept);

		var cancel:TextButton = new TextButton(0, 0, "Cancel", function() {
			if (cancelFunc != null)
				cancelFunc();
			close();
		});
		buttons2.add(cancel);

		vbox.add(buttons2);

		super("popupBG", 30, Std.int(vbox.width + 70), Std.int(vbox.height + 70));

		group.add(vbox);
	}

	function updateHexLabel()
	{
		hexLabel.text = "#" + StringTools.hex(swatch.swatchColor.red, 2) + StringTools.hex(swatch.swatchColor.green, 2) + StringTools.hex(swatch.swatchColor.blue, 2);
	}
}

class EasePicker extends PopupWindow
{
	static var eases:Array<Array<Dynamic>> = [[FlxEase.linear, "Linear", "linear"],
		[FlxEase.quadIn, "Quad In", "quadIn"],
		[FlxEase.quadOut, "Quad Out", "quadOut"],
		[FlxEase.quadInOut, "Quad In-Out", "quadInOut"],
		[FlxEase.cubeIn, "Cube In", "cubeIn"],
		[FlxEase.cubeOut, "Cube Out", "cubeOut"],
		[FlxEase.cubeInOut, "Cube In-Out", "cubeInOut"],
		[FlxEase.quartIn, "Quart In", "quartIn"],
		[FlxEase.quartOut, "Quart Out", "quartOut"],
		[FlxEase.quartInOut, "Quart In-Out", "quartInOut"],
		[FlxEase.quintIn, "Quint In", "quintIn"],
		[FlxEase.quintOut, "Quint Out", "quintOut"],
		[FlxEase.quintInOut, "Quint In-Out", "quintInOut"],
		[FlxEase.smoothStepIn, "Smooth Step In", "smoothStepIn"],
		[FlxEase.smoothStepOut, "Smooth Step Out", "smoothStepOut"],
		[FlxEase.smoothStepInOut, "Smooth Step In-Out", "smoothStepInOut"],
		[FlxEase.smootherStepIn, "Smoother Step In", "smootherStepIn"],
		[FlxEase.smootherStepOut, "Smoother Step Out", "smootherStepOut"],
		[FlxEase.smootherStepInOut, "Smoother Step In-Out", "smootherStepInOut"],
		[FlxEase.sineIn, "Sine In", "sineIn"],
		[FlxEase.sineOut, "Sine Out", "sineOut"],
		[FlxEase.sineInOut, "Sine In-Out", "sineInOut"],
		[FlxEase.bounceIn, "Bounce In", "bounceIn"],
		[FlxEase.bounceOut, "Bounce Out", "bounceOut"],
		[FlxEase.bounceInOut, "Bounce In-Out", "bounceInOut"],
		[FlxEase.circIn, "Circ In", "circIn"],
		[FlxEase.circOut, "Circ Out", "circOut"],
		[FlxEase.circInOut, "Circ In-Out", "circInOut"],
		[FlxEase.expoIn, "Expo In", "expoIn"],
		[FlxEase.expoOut, "Expo Out", "expoOut"],
		[FlxEase.expoInOut, "Expo In-Out", "expoInOut"],
		[FlxEase.backIn, "Back In", "backIn"],
		[FlxEase.backOut, "Back Out", "backOut"],
		[FlxEase.backInOut, "Back In-Out", "backInOut"],
		[FlxEase.elasticIn, "Elastic In", "elasticIn"],
		[FlxEase.elasticOut, "Elastic Out", "elasticOut"],
		[FlxEase.elasticInOut, "Elastic In-Out", "elasticInOut"]
	];

	var ease:Int = 0;
	var hoveredEase:Int = -1;

	var easeButtons:Array<FlxSprite> = [];
	var easeLabels:Array<FlxText> = [];

	override public function new(initialEase:String, acceptFunc:String->Void, ?cancelFunc:Void->Void = null)
	{
		var size:Int = 150;
		for (i in 0...eases.length)
		{
			if (eases[i][2] == initialEase)
				ease = i;
		}

		var vbox:VBox = new VBox(35, 35);

		var menu:VBoxScrollable = new VBoxScrollable(0, 0, 500);
		var scroll:VBox = menu.vbox;
		var hbox:HBox = new HBox();
		var ind:Int = 0;

		for (e in eases)
		{
			var sprGroup:FlxSpriteGroup = new FlxSpriteGroup();
			var bg:FlxSprite = new FlxSprite().makeGraphic(size + 8, Std.int(size * 1.6) + 8);
			bg.active = false;
			bg.antialiasing = false;
			bg.color = 0xFF254949;
			sprGroup.add(bg);
			easeButtons.push(bg);

			var dat:BitmapData = new BitmapData(size, Std.int(size * 1.6), true, FlxColor.WHITE);
			var halfsize:Int = Std.int(size * 0.3);

			var lastY:Int = size;
			for (i in 0...size)
			{
				var yy:Int = Std.int(size - (e[0](i / size) * size));
				if (yy > lastY)
					dat.fillRect(new Rectangle(i, lastY + halfsize, 1, Math.max(1, yy - lastY)), FlxColor.RED);
				else
					dat.fillRect(new Rectangle(i, yy + halfsize, 1, Math.max(1, lastY - yy)), FlxColor.RED);
				lastY = yy;
			}

			dat.fillRect(new Rectangle(0, halfsize, size, 1), FlxColor.GREEN);
			dat.fillRect(new Rectangle(0, halfsize + size, size, 1), FlxColor.GREEN);

			var display:VBox = new VBox();

			var spr:FlxSprite = new FlxSprite(4, 4);
			spr.pixels = dat;
			spr.antialiasing = false;
			sprGroup.add(spr);
			display.add(sprGroup);

			var label:FlxText = new FlxText(0, 0, 0, e[1]).setFormat("FNF Dialogue", 16, FlxColor.WHITE, LEFT, OUTLINE, 0xFF254949);
			easeLabels.push(label);
			display.add(label);
			hbox.add(display);

			ind++;
			if (ind >= 6)
			{
				scroll.add(hbox);
				hbox = new HBox();
				ind = 0;
			}
		}
		scroll.add(hbox);

		vbox.add(menu);

		var buttons:HBox = new HBox();

		var accept:TextButton = new TextButton(0, 0, "Accept", function() {
			acceptFunc(eases[ease][2]);
			close();
		});
		buttons.add(accept);

		var cancel:TextButton = new TextButton(0, 0, "Cancel", function() {
			if (cancelFunc != null)
				cancelFunc();
			close();
		});
		buttons.add(cancel);

		vbox.add(buttons);

		super("popupBG", 30, Std.int(vbox.width + 70), Std.int(vbox.height + 70));

		group.add(vbox);

		updateHighlightedEase();
	}

	function updateHighlightedEase()
	{
		for (i in 0...easeLabels.length)
		{
			if (i == ease)
			{
				easeButtons[i].color = 0xFF7FAEAE;
				easeLabels[i].borderColor = 0xFF7FAEAE;
			}
			else
			{
				easeButtons[i].color = 0xFF254949;
				easeLabels[i].borderColor = 0xFF254949;
			}
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justMoved)
		{
			hoveredEase = -1;
			for (i in 0...easeButtons.length)
			{
				if (i != ease)
				{
					if (UIControl.mouseOver(easeButtons[i]))
					{
						UIControl.cursor = MouseCursor.BUTTON;
						hoveredEase = i;
						easeButtons[i].color = 0xFF437C7C;
					}
					else
						easeButtons[i].color = 0xFF254949;
				}
			}
		}

		if (Options.mouseJustPressed() && hoveredEase > -1)
		{
			ease = hoveredEase;
			updateHighlightedEase();
		}

		if (FlxG.mouse.justMoved)
			Mouse.cursor = UIControl.cursor;
	}
}