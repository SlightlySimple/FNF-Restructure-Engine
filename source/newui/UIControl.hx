package newui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.ui.MouseCursor;
import data.Options;

import newui.TabMenu;
import newui.Button;

using StringTools;

class UIControl
{
	public static var infoText:String = "";
	public static var cursor:MouseCursor = MouseCursor.ARROW;

	public var elements:Map<String, FlxSprite>;
	var tabMenu:TabMenu;
	var conditions:Array<Void->Bool> = [];

	public static function mouseOver(sprite:FlxSprite):Bool
	{
		@:privateAccess
		var point:FlxPoint = FlxG.mouse.getWorldPosition(sprite.camera, sprite._point);
		if (sprite.clipRect == null)
			return sprite.overlapsPoint(point, true, sprite.camera);
		var ww:Float = sprite.clipRect.x + sprite.clipRect.width;
		var hh:Float = sprite.clipRect.y + sprite.clipRect.height;
		if (ww <= 0 || hh <= 0)
			return false;
		if (sprite.overlapsPoint(point, true, sprite.camera))
		{
			if ((point.x >= sprite.x + Math.max(0, sprite.clipRect.x)) && (point.x < sprite.x + Math.min(sprite.width, ww)) && (point.y >= sprite.y + Math.max(0, sprite.clipRect.y)) && (point.y < sprite.y + Math.min(sprite.height, hh)))
				return true;
		}
		return false;
	}

	public function new(file:String, ?conditions:Array<Void->Bool> = null)
	{
		elements = new Map<String, FlxSprite>();
		if (conditions != null)
			this.conditions = conditions;

		var dat:String = Paths.raw("data/editors/" + file + ".xml");
		var data:Xml = Xml.parse(dat).firstElement();

		parseElements(data);
	}

	public function element(id:String):FlxSprite
	{
		if (!elements.exists(id))
		{
			lime.app.Application.current.window.alert("Element not found: \"" + id + "\"", "Alert");
			return null;
		}
		return elements[id];
	}

	function parseTab(data:Xml):TabGroup
	{
		var tab:TabGroup = new TabGroup();

		var list:Array<FlxSprite> = parseElements(data);

		for (e in list)
		{
			e.x = Std.int((270 - e.width) / 2);
			tab.add(e);
		}

		return tab;
	}

	function parseElements(data:Xml):Array<FlxSprite>
	{
		var list:Array<FlxSprite> = [];

		for (e in data.elements())
		{
			var _e:FlxSprite = null;

			switch (e.nodeName)
			{
				case "button":
					var image:String = Button.DEFAULT;
					if (e.get("image") != null)
					{
						switch (e.get("image"))
						{
							case "DEFAULT": image = Button.DEFAULT;
							case "SHORT": image = Button.SHORT;
							case "LONG": image = Button.LONG;
							default: image = e.get("image");
						}
					}

					var item:Button = new Button(0, 0, image);
					if (e.get("infoText") != null)
						item.infoText = e.get("infoText").replace("\\n","\n");
					_e = item;

				case "textbutton":
					var image:String = Button.DEFAULT;
					if (e.get("image") != null)
					{
						switch (e.get("image"))
						{
							case "DEFAULT": image = Button.DEFAULT;
							case "SHORT": image = Button.SHORT;
							case "LONG": image = Button.LONG;
							default: image = e.get("image");
						}
					}

					var icon:String = "";
					if (e.get("icon") != null)
						icon = e.get("icon");

					var text:String = "";
					if (e.get("text") != null)
						text = e.get("text");

					var item:TextButton = new TextButton(0, 0, text, image, icon);
					if (e.get("textBorder") != null)
						item.textObject.borderColor = FlxColor.fromString(e.get("textBorder"));
					if (e.get("infoText") != null)
						item.infoText = e.get("infoText").replace("\\n","\n");
					_e = item;

				case "togglebutton":
					var image:String = Button.DEFAULT;
					if (e.get("image") != null)
					{
						switch (e.get("image"))
						{
							case "DEFAULT": image = Button.DEFAULT;
							case "SHORT": image = Button.SHORT;
							case "LONG": image = Button.LONG;
							default: image = e.get("image");
						}
					}

					var text:String = "";
					if (e.get("text") != null)
						text = e.get("text");

					var onText:String = "";
					if (e.get("onText") != null)
						onText = e.get("onText");

					var onTextBorder:FlxColor = FlxColor.TRANSPARENT;
					if (e.get("onTextBorder") != null)
						onTextBorder = FlxColor.fromString(e.get("onTextBorder"));

					var offText:String = "";
					if (e.get("offText") != null)
						offText = e.get("offText");

					var offTextBorder:FlxColor = FlxColor.TRANSPARENT;
					if (e.get("offTextBorder") != null)
						offTextBorder = FlxColor.fromString(e.get("offTextBorder"));

					var item:ToggleButton = new ToggleButton(0, 0, text, image, onText, onTextBorder, offText, offTextBorder);
					if (e.get("textBorder") != null)
						item.textObject.borderColor = FlxColor.fromString(e.get("textBorder"));
					if (e.get("infoText") != null)
						item.infoText = e.get("infoText").replace("\\n","\n");
					_e = item;

				case "checkbox":
					var text:String = "";
					if (e.get("text") != null)
						text = e.get("text");

					var checked:Bool = false;
					if (e.get("checked") != null)
						checked = (e.get("checked") == "true");

					var item:Checkbox = new Checkbox(0, 0, text, checked);
					if (e.get("infoText") != null)
						item.infoText = e.get("infoText").replace("\\n","\n");
					_e = item;

				case "stepper":
					var text:String = "";
					if (e.get("text") != null)
						text = e.get("text");

					var _default:Float = 0;
					if (e.get("default") != null)
						_default = Std.parseFloat(e.get("default"));

					var step:Float = 1;
					if (e.get("step") != null)
						step = Std.parseFloat(e.get("step"));

					var min:Float = -9999;
					if (e.get("min") != null)
						min = Std.parseFloat(e.get("min"));

					var max:Float = 9999;
					if (e.get("max") != null)
						max = Std.parseFloat(e.get("max"));

					var decimals:Int = 0;
					if (e.get("decimals") != null)
						decimals = Std.parseInt(e.get("decimals"));

					var item:Stepper = new Stepper(0, 0, text, _default, step, min, max, decimals);
					if (e.get("infoText") != null)
						item.infoText = e.get("infoText").replace("\\n","\n");
					_e = item;

				case "dropdown":
					var text:String = "";
					if (e.get("text") != null)
						text = e.get("text");

					var blank:String = "";
					if (e.get("blank") != null)
						blank = e.get("blank");

					var allowSearch:Bool = false;
					if (e.get("allowSearch") != null)
						allowSearch = (e.get("allowSearch") == "true");

					var item:DropdownMenu = new DropdownMenu(0, 0, text, [""], blank, allowSearch);
					if (e.get("infoText") != null)
						item.infoText = e.get("infoText").replace("\\n","\n");
					_e = item;

				case "input":
					var text:String = "";
					if (e.get("text") != null)
						text = e.get("text");

					var width:Int = 235;
					if (e.get("width") != null)
						width = Std.parseInt(e.get("width"));

					var item:InputText = new InputText(0, 0, width, text);
					if (e.get("infoText") != null)
						item.infoText = e.get("infoText").replace("\\n","\n");
					_e = item;

				case "label":
					var text:String = "";
					if (e.get("text") != null)
						text = e.get("text");

					_e = new Label(text);

				case "hbox": _e = parseHbox(e);

				case "vbox":
					var _y:Int = 0;
					if (e.get("y") != null)
						_y = Std.parseInt(e.get("y"));

					var item:VBox = new VBox(0, _y);

					var list:Array<FlxSprite> = parseElements(e);
					for (element in list)
						item.add(element);

					_e = item;

				case "vboxscroll":
					var _y:Int = 0;
					if (e.get("y") != null)
						_y = Std.parseInt(e.get("y"));

					var h:Int = 550;
					if (e.get("h") != null)
						h = Std.parseInt(e.get("h"));

					var item:VBoxScrollable = new VBoxScrollable(0, _y, h);

					var list:Array<FlxSprite> = parseElements(e);
					for (element in list)
						item.vbox.add(element);

					_e = item;

				case "tab": tabMenu.addGroup(parseTab(e), e.get("name"));

				case "tabmenu":
					var _x:Int = 5;
					if (e.get("x") != null)
						_x = Std.parseInt(e.get("x"));

					var _y:Int = 55;
					if (e.get("y") != null)
						_y = Std.parseInt(e.get("y"));

					var item:TabMenu = new TabMenu(_x, _y);
					_e = item;
					this.tabMenu = item;

					list = list.concat(parseElements(e));

				case "if":
					var condition:Int = Std.parseInt(e.get("condition"));
					var inverted:Bool = false;
					if (e.get("inverted") != null)
						inverted = (e.get("inverted") == "true");

					if (condition < conditions.length)
					{
						if (conditions[condition]() == !inverted)
							list = list.concat(parseElements(e));
					}

				default: _e = new Button(0, 0);
			}

			if (_e != null)
			{
				list.push(_e);
				if (e.get("id") != null)
					elements[e.get("id")] = _e;
			}
		}

		return list;
	}

	function parseHbox(data:Xml):FlxSpriteGroup
	{
		var hbox:FlxSpriteGroup = new FlxSpriteGroup();
		var xx:Int = 0;
		if (data.get("x") != null)
			xx = Std.parseInt(data.get("x"));

		var height:Int = 0;

		var spacing:Int = 10;
		if (data.get("spacing") != null)
			spacing = Std.parseInt(data.get("spacing"));

		var list:Array<FlxSprite> = parseElements(data);
		for (e in list)
		{
			if (Std.int(e.height) > height)
				height = Std.int(e.height);
		}

		for (e in list)
		{
			e.x = xx;
			e.y = Std.int((height - e.height) / 2);
			xx += Std.int(e.width) + spacing;
			hbox.add(e);
		}

		return hbox;
	}
}

class HBox extends FlxSpriteGroup
{
	public var spacing:Int = 10;
	public var modCallback:Void->Void = null;

	override public function add(Sprite:FlxSprite):FlxSprite
	{
		if (members.length > 0)
			Sprite.x += Std.int(members[members.length - 1].x + members[members.length - 1].width - x) + spacing;
		Sprite.y = 0;
		var ret:FlxSprite = super.add(Sprite);

		for (m in members)
			m.y = y + Std.int((height - m.height) / 2);

		if (modCallback != null)
			modCallback();

		return ret;
	}

	override function get_width():Float
	{
		if (length == 0)
			return 0;

		var w:Float = 0;

		for (member in _sprites)
		{
			if (member == null)
				continue;

			w += member.width;
			if (member.height > 0 && _sprites.indexOf(member) < _sprites.length - 1)
				w += spacing;
		}

		return w;
	}

	override function get_height():Float
	{
		if (length == 0)
			return 0;

		var h:Float = 0;

		for (member in _sprites)
		{
			if (member == null)
				continue;

			if (member.height > h)
				h = member.height;
		}

		return h;
	}
}

class VBox extends FlxSpriteGroup
{
	public var spacing:Int = 10;
	public var modCallback:Void->Void = null;

	override public function add(Sprite:FlxSprite):FlxSprite
	{
		if (members.length > 0)
			Sprite.y += Std.int(members[members.length - 1].y + members[members.length - 1].height - y) + spacing;
		Sprite.x = 0;
		var ret:FlxSprite = super.add(Sprite);

		for (m in members)
			m.x = x + Std.int((width - m.width) / 2);

		if (modCallback != null)
			modCallback();

		return ret;
	}

	public function repositionAll()
	{
		if (members.length > 0)
		{
			var yy:Int = Std.int(y);
			for (i in 0...members.length)
			{
				members[i].x = x + Std.int((width - members[i].width) / 2);
				members[i].y = yy;
				if (members[i].height > 0)
					yy += Std.int(members[i].height) + spacing;
			}
		}

		if (modCallback != null)
			modCallback();
	}

	override function get_width():Float
	{
		if (length == 0)
			return 0;

		var w:Float = 0;

		for (member in _sprites)
		{
			if (member == null)
				continue;

			if (member.width > w)
				w = member.width;
		}

		return w;
	}

	override function get_height():Float
	{
		if (length == 0)
			return 0;

		var h:Float = 0;

		for (member in _sprites)
		{
			if (member == null)
				continue;

			h += member.height;
			if (member.height > 0 && _sprites.indexOf(member) < _sprites.length - 1)
				h += spacing;
		}

		return h;
	}
}

class VBoxScrollable extends FlxSpriteGroup
{
	public var vbox:VBox;
	var scroll:Float = 0;
	var maxScroll:Float = 0;
	var h:Float = 0;

	var scrollBar:ScrollBar;

	override public function new(x:Float, y:Float, h:Float)
	{
		super(x, y);
		this.h = h;

		scrollBar = new ScrollBar(0, 0, h);
		scrollBar.onChanged = function() {
			scroll = scrollBar.scroll * maxScroll;
			vbox.y = Std.int(scrollBar.y - scroll);
			vbox.clipRect = new FlxRect(0, scroll, 5000, h);
		};

		vbox = new VBox(scrollBar.width + 5);
		vbox.clipRect = new FlxRect(0, 0, 5000, h);
		add(vbox);

		vbox.modCallback = function() {
			maxScroll = Math.max(0, vbox.height - h);
			if (maxScroll == 0)
				scrollBar.visible = false;
			else
				scrollBar.visible = true;

			scrollBar.onChanged();
		}

		add(scrollBar);
	}

	public function repositionAll()
	{
		vbox.repositionAll();
		vbox.clipRect = vbox.clipRect;
	}

	override function get_height():Float
	{
		if (length == 0)
			return 0;

		return Math.min(h, vbox.height);
	}
}