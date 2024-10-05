package scripting;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxStrip;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxFilterFrames;
import flixel.system.FlxSound;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.text.FlxBitmapText;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.addons.text.FlxTypeText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import flixel.util.FlxAxes;
import flixel.ui.FlxBar;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.addons.effects.FlxTrail;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxRuntimeShader;
import flixel.input.keyboard.FlxKey;
import haxe.Json;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;
import openfl.filters.BlurFilter;
import openfl.filters.GlowFilter;
import openfl.ui.MouseCursor;
import flxanimate.FlxAnimate;
import data.Options;
import data.ScoreSystems;
import data.Song;
import game.PlayState;
import game.GameOverSubState;
import game.results.ResultsState;
import menus.MainMenuState;
import menus.story.StoryMenuState;
import menus.freeplay.FreeplayMenuSubState;
import menus.freeplay.FreeplaySandbox;
import menus.freeplay.FreeplayChartInfo;
import menus.PauseSubState;
import menus.UINavigation;
import objects.Alphabet;
import objects.AnimatedSprite;
import objects.BackgroundChart;
import objects.Character;
import objects.FunkBar;
import objects.HealthIcon;
import objects.Note;
import objects.Stage;
import objects.StrumNote;
import scripting.HscriptSprite;
import scripting.HscriptState;
import shaders.ColorFade;
import shaders.ColorInvert;
import shaders.ColorSwap;
import shaders.ColorSwapRGBA;
import shaders.RuntimeScreenspaceShader;

import hscript.Parser as HSParser;
import hscript.Interp as HSInterp;
import lime.app.Application;

using StringTools;

class ScriptedClass
{
	public var baseClass:Class<Dynamic>;
	public var script:String;

	public function new(baseClass:Class<Dynamic>, script:String)
	{
		this.baseClass = baseClass;
		this.script = script;
	}
}

class CustomInterp extends HSInterp
{
	override function cnew(cl:String, args:Array<Dynamic>):Dynamic
	{
		if (variables.exists(cl))
		{
			if (Std.isOfType(variables.get(cl), ScriptedClass))
			{
				var scriptedClass:ScriptedClass = cast variables.get(cl);
				return Type.createInstance(scriptedClass.baseClass, [scriptedClass.script, args]);
			}
		}
		return super.cnew(cl, args);
	}
}



class HscriptColor			// FlxColor can't be used with hscript directly so we gotta make our own
{
	public static var BLACK = FlxColor.BLACK;
	public static var BLUE = FlxColor.BLUE;
	public static var BROWN = FlxColor.BROWN;
	public static var CYAN = FlxColor.CYAN;
	public static var GRAY = FlxColor.GRAY;
	public static var GREEN = FlxColor.GREEN;
	public static var LIME = FlxColor.LIME;
	public static var MAGENTA = FlxColor.MAGENTA;
	public static var ORANGE = FlxColor.ORANGE;
	public static var PINK = FlxColor.PINK;
	public static var PURPLE = FlxColor.PURPLE;
	public static var RED = FlxColor.RED;
	public static var TRANSPARENT = FlxColor.TRANSPARENT;
	public static var WHITE = FlxColor.WHITE;
	public static var YELLOW = FlxColor.YELLOW;

	public static function fromRGB(r:Int, g:Int, b:Int, ?a:Int = 255):FlxColor
	{
		return FlxColor.fromRGB(r, g, b, a);
	}

	public static function fromHSB(h:Float, s:Float, b:Float, a:Float = 1):FlxColor
	{
		return FlxColor.fromHSB(h, s, b, a);
	}

	public static function fromHSL(h:Float, s:Float, l:Float, a:Float = 1):FlxColor
	{
		return FlxColor.fromHSL(h, s, l, a);
	}

	public static function fromString(col:String):FlxColor
	{
		return FlxColor.fromString(col);
	}

	public static function red(color:FlxColor):Int
	{
		return color.red;
	}

	public static function green(color:FlxColor):Int
	{
		return color.green;
	}

	public static function blue(color:FlxColor):Int
	{
		return color.blue;
	}

	public static function alpha(color:FlxColor):Int
	{
		return color.alpha;
	}

	public static function redFloat(color:FlxColor):Float
	{
		return color.redFloat;
	}

	public static function greenFloat(color:FlxColor):Float
	{
		return color.greenFloat;
	}

	public static function blueFloat(color:FlxColor):Float
	{
		return color.blueFloat;
	}

	public static function alphaFloat(color:FlxColor):Float
	{
		return color.alphaFloat;
	}

	public static function hue(color:FlxColor):Float
	{
		return color.hue;
	}

	public static function saturation(color:FlxColor):Float
	{
		return color.saturation;
	}

	public static function brightness(color:FlxColor):Float
	{
		return color.brightness;
	}

	public static function lightness(color:FlxColor):Float
	{
		return color.lightness;
	}

	public static inline function interpolate(Color1:FlxColor, Color2:FlxColor, Factor:Float = 0.5):FlxColor
	{
		return FlxColor.interpolate(Color1, Color2, Factor);
	}
}

class HscriptBlendMode
{
	public static var NORMAL = BlendMode.NORMAL;
	public static var ADD = BlendMode.ADD;
	public static var ALPHA = BlendMode.ALPHA;
	public static var DARKEN = BlendMode.DARKEN;
	public static var DIFFERENCE = BlendMode.DIFFERENCE;
	public static var ERASE = BlendMode.ERASE;
	public static var HARDLIGHT = BlendMode.HARDLIGHT;
	public static var INVERT = BlendMode.INVERT;
	public static var LAYER = BlendMode.LAYER;
	public static var LIGHTEN = BlendMode.LIGHTEN;
	public static var MULTIPLY = BlendMode.MULTIPLY;
	public static var OVERLAY = BlendMode.OVERLAY;
	public static var SCREEN = BlendMode.SCREEN;
	public static var SHADER = BlendMode.SHADER;
	public static var SUBTRACT = BlendMode.SUBTRACT;
}

class HscriptKey
{
	public static var ANY = FlxKey.ANY;
	public static var NONE = FlxKey.NONE;
	public static var A = FlxKey.A;
	public static var B = FlxKey.B;
	public static var C = FlxKey.C;
	public static var D = FlxKey.D;
	public static var E = FlxKey.E;
	public static var F = FlxKey.F;
	public static var G = FlxKey.G;
	public static var H = FlxKey.H;
	public static var I = FlxKey.I;
	public static var J = FlxKey.J;
	public static var K = FlxKey.K;
	public static var L = FlxKey.L;
	public static var M = FlxKey.M;
	public static var N = FlxKey.N;
	public static var O = FlxKey.O;
	public static var P = FlxKey.P;
	public static var Q = FlxKey.Q;
	public static var R = FlxKey.R;
	public static var S = FlxKey.S;
	public static var T = FlxKey.T;
	public static var U = FlxKey.U;
	public static var V = FlxKey.V;
	public static var W = FlxKey.W;
	public static var X = FlxKey.X;
	public static var Y = FlxKey.Y;
	public static var Z = FlxKey.Z;
	public static var ZERO = FlxKey.ZERO;
	public static var ONE = FlxKey.ONE;
	public static var TWO = FlxKey.TWO;
	public static var THREE = FlxKey.THREE;
	public static var FOUR = FlxKey.FOUR;
	public static var FIVE = FlxKey.FIVE;
	public static var SIX = FlxKey.SIX;
	public static var SEVEN = FlxKey.SEVEN;
	public static var EIGHT = FlxKey.EIGHT;
	public static var NINE = FlxKey.NINE;
	public static var PAGEUP = FlxKey.PAGEUP;
	public static var PAGEDOWN = FlxKey.PAGEDOWN;
	public static var HOME = FlxKey.HOME;
	public static var END = FlxKey.END;
	public static var INSERT = FlxKey.INSERT;
	public static var ESCAPE = FlxKey.ESCAPE;
	public static var MINUS = FlxKey.MINUS;
	public static var PLUS = FlxKey.PLUS;
	public static var DELETE = FlxKey.DELETE;
	public static var BACKSPACE = FlxKey.BACKSPACE;
	public static var LBRACKET = FlxKey.LBRACKET;
	public static var RBRACKET = FlxKey.RBRACKET;
	public static var BACKSLASH = FlxKey.BACKSLASH;
	public static var CAPSLOCK = FlxKey.CAPSLOCK;
	public static var SEMICOLON = FlxKey.SEMICOLON;
	public static var QUOTE = FlxKey.QUOTE;
	public static var ENTER = FlxKey.ENTER;
	public static var SHIFT = FlxKey.SHIFT;
	public static var COMMA = FlxKey.COMMA;
	public static var PERIOD = FlxKey.PERIOD;
	public static var SLASH = FlxKey.SLASH;
	public static var GRAVEACCENT = FlxKey.GRAVEACCENT;
	public static var CONTROL = FlxKey.CONTROL;
	public static var ALT = FlxKey.ALT;
	public static var SPACE = FlxKey.SPACE;
	public static var UP = FlxKey.UP;
	public static var DOWN = FlxKey.DOWN;
	public static var LEFT = FlxKey.LEFT;
	public static var RIGHT = FlxKey.RIGHT;
	public static var TAB = FlxKey.TAB;
	public static var PRINTSCREEN = FlxKey.PRINTSCREEN;
	public static var F1 = FlxKey.F1;
	public static var F2 = FlxKey.F2;
	public static var F3 = FlxKey.F3;
	public static var F4 = FlxKey.F4;
	public static var F5 = FlxKey.F5;
	public static var F6 = FlxKey.F6;
	public static var F7 = FlxKey.F7;
	public static var F8 = FlxKey.F8;
	public static var F9 = FlxKey.F9;
	public static var F10 = FlxKey.F10;
	public static var F11 = FlxKey.F11;
	public static var F12 = FlxKey.F12;
	public static var NUMPADZERO = FlxKey.NUMPADZERO;
	public static var NUMPADONE = FlxKey.NUMPADONE;
	public static var NUMPADTWO = FlxKey.NUMPADTWO;
	public static var NUMPADTHREE = FlxKey.NUMPADTHREE;
	public static var NUMPADFOUR = FlxKey.NUMPADFOUR;
	public static var NUMPADFIVE = FlxKey.NUMPADFIVE;
	public static var NUMPADSIX = FlxKey.NUMPADSIX;
	public static var NUMPADSEVEN = FlxKey.NUMPADSEVEN;
	public static var NUMPADEIGHT = FlxKey.NUMPADEIGHT;
	public static var NUMPADNINE = FlxKey.NUMPADNINE;
	public static var NUMPADMINUS = FlxKey.NUMPADMINUS;
	public static var NUMPADPLUS = FlxKey.NUMPADPLUS;
	public static var NUMPADPERIOD = FlxKey.NUMPADPERIOD;
	public static var NUMPADMULTIPLY = FlxKey.NUMPADMULTIPLY;

	public static function fromString(s:String):FlxKey
	{
		return FlxKey.fromString(s);
	}
}

class HscriptJson
{
	public static function stringify(value:Dynamic, ?replacer:(key:Dynamic, value:Dynamic) -> Dynamic, ?space:String):String {
		return Json.stringify(value, replacer, space);
	}

	public static function parse(text:String):Dynamic {
		return Json.parse(text);
	}
}

class HscriptTextAlign
{
	public static var LEFT:String = "left";
	public static var CENTER:String = "center";
	public static var RIGHT:String = "right";
	public static var JUSTIFY:String = "justify";
}

class HscriptMouseCursor
{
	public static var ARROW = MouseCursor.ARROW;
	public static var AUTO = MouseCursor.AUTO;
	public static var BUTTON = MouseCursor.BUTTON;
	public static var HAND = MouseCursor.HAND;
	public static var IBEAM = MouseCursor.IBEAM;
	public static var __CROSSHAIR = "crosshair";
	public static var __CUSTOM = "custom";
	public static var __MOVE = "move";
	public static var __RESIZE_NESW = "resize_nesw";
	public static var __RESIZE_NS = "resize_ns";
	public static var __RESIZE_NWSE = "resize_nwse";
	public static var __RESIZE_WE = "resize_we";
	public static var __WAIT = "wait";
	public static var __WAIT_ARROW = "waitarrow";
}



class HscriptHandler
{
	var script:String = "";
	var interp:CustomInterp = null;
	var errorFuncs:Array<String> = [];
	public static var persistent:Dynamic = {};
	public static var _static:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var variables(get, null):Map<String, Dynamic>;

	public static function parseClass(theClass:String)
	{
		if (theClass.startsWith("menus.Options"))		// Dirty backwards compatibility hack, bleh
			return Type.resolveClass(theClass.replace("menus.Options", "menus.options.Options"));
		return Type.resolveClass(theClass);
	}

	public static function parseScriptedClass(theClass:String)
	{
		if (Paths.hscriptExists("data/scripts/FlxSprite/" + theClass.replace(".", "/")))
			return new ScriptedClass(HscriptSprite, theClass.replace(".", "/"));
		if (Paths.hscriptExists("data/scripts/AnimatedSprite/" + theClass.replace(".", "/")))
			return new ScriptedClass(HscriptAnimatedSprite, theClass.replace(".", "/"));
		if (Paths.hscriptExists("data/scripts/FlxSpriteGroup/" + theClass.replace(".", "/")))
			return new ScriptedClass(HscriptSpriteGroup, theClass.replace(".", "/"));
		return null;
	}

	public static var curMenu:String = "main";
	public static function GotoMenu()
	{
		switch (curMenu)
		{
			case "story": FlxG.switchState(new StoryMenuState());
			default: FlxG.switchState(new MainMenuState());
		}
	}

	public static function doScriptedClass(code:CustomInterp, classFolder:String, scriptedClass:String)
	{
		var scriptedClasses:Array<String> = Paths.listFiles("data/scripts/" + classFolder, ".hscript");
		if (scriptedClasses.length > 0)
		{
			for (s in scriptedClasses)
				code.variables.set(s, new ScriptedClass(Type.resolveClass("scripting." + scriptedClass), s));
		}
	}

	public static function CreateStrip(x:Float, y:Float, vertices:Array<Float>, indices:Array<Int>, uvtData:Array<Float>):FlxStrip
	{
		var strip:FlxStrip = new FlxStrip(x, y);
		strip.vertices = DrawData.ofArray(vertices);
		strip.indices = DrawData.ofArray(indices);
		strip.uvtData = DrawData.ofArray(uvtData);
		return strip;
	}

	public static function ModifyStrip(strip:FlxStrip, mod:String, slot:Int, type:String, val:Float)
	{
		switch (mod)
		{
			case "uv":
				switch (type)
				{
					case "add":
						strip.uvtData[slot] += val;

					default:
						strip.uvtData[slot] = val;
				}

			default:
				switch (type)
				{
					case "add":
						strip.vertices[slot] += val;

					default:
						strip.vertices[slot] = val;
				}
		}
	}

	public function new(scriptFile:String, ?doAddFunctions:Bool = true)
	{
		script = scriptFile;
		if (!_static.exists(script))
			_static[script] = {};

		var myCode:String = Paths.hscript(script);
		while (myCode.indexOf("import ") > -1)
		{
			var startInd:Int = myCode.indexOf("import ");
			var endInd:Int = myCode.indexOf(";", startInd + 7);

			var classString:String = myCode.substring(startInd + 7, endInd);
			var classParts:Array<String> = classString.split(".");
			if (Paths.hscriptExists("data/scripts/FlxSprite/" + classParts.join("/")) || Paths.hscriptExists("data/scripts/AnimatedSprite/" + classParts.join("/")) || Paths.hscriptExists("data/scripts/FlxSpriteGroup/" + classParts.join("/")))
				myCode = myCode.substring(0, startInd) + classParts[classParts.length-1] + " = parseScriptedClass(\"" + classString + "\")" + myCode.substring(endInd, myCode.length);
			else
				myCode = myCode.substring(0, startInd) + "var " + classParts[classParts.length-1] + " = parseClass(\"" + classString + "\")" + myCode.substring(endInd, myCode.length);
		}

		var parser:HSParser = new HSParser();
		parser.allowTypes = true;
		var program = null;
		try {
			program = parser.parseString(myCode);
		} catch (e:Dynamic) {
			Application.current.window.alert("Error on line " + Std.string(e.line) + " of script file " + script + ".hscript:\n\n" + e.toString(), "Error");
		}

		if (program != null)
		{
			interp = new CustomInterp();

			HscriptHandler.doScriptedClass(interp, "FlxSprite", "HscriptSprite");
			HscriptHandler.doScriptedClass(interp, "AnimatedSprite", "HscriptAnimatedSprite");
			HscriptHandler.doScriptedClass(interp, "FlxSpriteGroup", "HscriptSpriteGroup");

			refreshVariables(doAddFunctions);

			interp.execute(program);
		}
	}

	public function valid():Bool
	{
		return (interp != null);
	}

	public function refreshVariables(?doAddFunctions:Bool = true)
	{
		if (interp == null)
			return;

		interp.variables.set("Math", Math);
		interp.variables.set("StringMap", haxe.ds.StringMap);
		interp.variables.set("IntMap", haxe.ds.IntMap);
		interp.variables.set("EnumValueMap", haxe.ds.EnumValueMap);
		interp.variables.set("ObjectMap", haxe.ds.ObjectMap);
		interp.variables.set("Reflect", Reflect);
		interp.variables.set("Json", HscriptJson);
		interp.variables.set("Type", Type);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("Lang", Lang);
		interp.variables.set("Options", Options);
		interp.variables.set("Util", Util);
		interp.variables.set("CreateSprite", Util.CreateSprite);
		interp.variables.set("PlaySound", Util.PlaySound);
		interp.variables.set("FlxG", FlxG);
		interp.variables.set("FlxG.random.bool", FlxG.random.bool);
		interp.variables.set("FlxG.sound.cache", FlxG.sound.cache);
		interp.variables.set("FlxObject", FlxObject);
		interp.variables.set("FlxSprite", FlxSprite);
		interp.variables.set("AnimatedSprite", AnimatedSprite);
		interp.variables.set("FlxSpriteGroup", FlxSpriteGroup);
		interp.variables.set("FlxTypedSpriteGroup", FlxTypedSpriteGroup);
		interp.variables.set("FlxSpriteUtil", FlxSpriteUtil);
		interp.variables.set("FlxFramesCollection", FlxFramesCollection);
		interp.variables.set("FlxFilterFrames", FlxFilterFrames);
		interp.variables.set("CreateStrip", CreateStrip);
		interp.variables.set("ModifyStrip", ModifyStrip);
		interp.variables.set("FlxSound", FlxSound);
		interp.variables.set("FlxCamera", FlxCamera);
		interp.variables.set("FlxCameraFollowStyle", FlxCameraFollowStyle);
		interp.variables.set("FlxMath", FlxMath);
		interp.variables.set("FlxPoint", FlxPoint);
		interp.variables.set("FlxText", FlxText);
		interp.variables.set("FlxTextBorderStyle", FlxTextBorderStyle);
		interp.variables.set("FlxBitmapText", FlxBitmapText);
		interp.variables.set("FlxBitmapFont", FlxBitmapFont);
		interp.variables.set("SHADOW", FlxTextBorderStyle.SHADOW);
		interp.variables.set("OUTLINE", FlxTextBorderStyle.OUTLINE);
		interp.variables.set("OUTLINE_FAST", FlxTextBorderStyle.OUTLINE_FAST);
		interp.variables.set("FlxTextAlign", HscriptTextAlign);
		interp.variables.set("LEFT", HscriptTextAlign.LEFT);
		interp.variables.set("CENTER", HscriptTextAlign.CENTER);
		interp.variables.set("RIGHT", HscriptTextAlign.RIGHT);
		interp.variables.set("JUSTIFY", HscriptTextAlign.JUSTIFY);
		interp.variables.set("FlxTypeText", FlxTypeText);
		interp.variables.set("FlxColor", HscriptColor);
		interp.variables.set("FlxTween", FlxTween);
		interp.variables.set("FlxEase", FlxEase);
		interp.variables.set("FlxTimer", FlxTimer);
		interp.variables.set("FlxAxes", FlxAxes);
		interp.variables.set("BlendMode", HscriptBlendMode);
		interp.variables.set("FlxKey", HscriptKey);
		interp.variables.set("MouseCursor", HscriptMouseCursor);
		interp.variables.set("X", FlxAxes.X);
		interp.variables.set("Y", FlxAxes.Y);
		interp.variables.set("XY", FlxAxes.XY);
		interp.variables.set("FlxBar", FlxBar);
		interp.variables.set("FunkBar", FunkBar);
		interp.variables.set("LEFT_TO_RIGHT", FlxBarFillDirection.LEFT_TO_RIGHT);
		interp.variables.set("RIGHT_TO_LEFT", FlxBarFillDirection.RIGHT_TO_LEFT);
		interp.variables.set("TOP_TO_BOTTOM", FlxBarFillDirection.TOP_TO_BOTTOM);
		interp.variables.set("BOTTOM_TO_TOP", FlxBarFillDirection.BOTTOM_TO_TOP);
		interp.variables.set("FlxEmitter", FlxEmitter);
		interp.variables.set("FlxParticle", FlxParticle);
		interp.variables.set("FlxTrail", FlxTrail);
		interp.variables.set("FlxBackdrop", FlxBackdrop);
		interp.variables.set("FlxAnimate", FlxAnimate);
		interp.variables.set("Std", Std);
		interp.variables.set("MP4Handler", MP4Handler);
		interp.variables.set("ColorSwap", ColorSwap);
		interp.variables.set("ColorSwapRGBA", ColorSwapRGBA);
		interp.variables.set("ColorFade", ColorFade);
		interp.variables.set("ColorInvert", ColorInvert);
		interp.variables.set("FlxRuntimeShader", FlxRuntimeShader);
		interp.variables.set("RuntimeScreenspaceShader", RuntimeScreenspaceShader);
		interp.variables.set("ShaderFilter", ShaderFilter);
		interp.variables.set("BlurFilter", BlurFilter);
		interp.variables.set("GlowFilter", GlowFilter);
		interp.variables.set("Paths", Paths);
		interp.variables.set("parseClass", HscriptHandler.parseClass);
		interp.variables.set("parseScriptedClass", HscriptHandler.parseScriptedClass);
		interp.variables.set("persistent", HscriptHandler.persistent);
		interp.variables.set("static", HscriptHandler._static[script]);
		interp.variables.set("Character", Character);
		interp.variables.set("Stage", Stage);
		interp.variables.set("Song", Song);
		interp.variables.set("Note", Note);
		interp.variables.set("StrumNote", StrumNote);
		interp.variables.set("BackgroundChart", BackgroundChart);
		interp.variables.set("HealthIcon", HealthIcon);
		interp.variables.set("HscriptSprite", HscriptSprite);
		interp.variables.set("HscriptAnimatedSprite", HscriptAnimatedSprite);
		interp.variables.set("HscriptSpriteGroup", HscriptSpriteGroup);
		interp.variables.set("LuaModule", LuaModule);

		interp.variables.set("Alphabet", Alphabet);
		interp.variables.set("TypedAlphabet", TypedAlphabet);
		interp.variables.set("Conductor", Conductor);
		interp.variables.set("TitleState", TitleState);
		interp.variables.set("PlayState", PlayState);
		interp.variables.set("GameOverSubState", GameOverSubState);
		interp.variables.set("HscriptState", HscriptState);
		interp.variables.set("HscriptSubState", HscriptSubState);
		interp.variables.set("HscriptEditorState", HscriptEditorState);
		interp.variables.set("curMenu", curMenu);
		interp.variables.set("GotoMenu", GotoMenu);
		interp.variables.set("MainMenuState", MainMenuState);
		interp.variables.set("StoryMenuState", StoryMenuState);
		interp.variables.set("FreeplayMenuSubState", FreeplayMenuSubState);
		interp.variables.set("FreeplaySandbox", FreeplaySandbox);
		interp.variables.set("FreeplayChartInfo", FreeplayChartInfo);
		interp.variables.set("PauseSubState", PauseSubState);
		interp.variables.set("UINavigation", UINavigation);
		interp.variables.set("UINumeralNavigation", UINumeralNavigation);
		interp.variables.set("UIMenu", UIMenu);
		interp.variables.set("ScoreSystems", ScoreSystems);
		interp.variables.set("ResultsState", ResultsState);

		if (doAddFunctions)
		{
			interp.variables.set("add", FlxG.state.add);
			interp.variables.set("insert", FlxG.state.insert);
			interp.variables.set("remove", FlxG.state.remove);
		}
	}

	public function get_variables():Map<String, Dynamic>
	{
		return (interp == null) ? null : interp.variables;
	}

	public function execFunc(func:String, args:Array<Dynamic>)
	{
		if (interp == null)
			return;

		if (interp.variables.exists(func))
		{
			var execMe = interp.variables.get(func);
			if (Reflect.isFunction(execMe))
			{
				try {
					Reflect.callMethod(this, execMe, args);
				} catch (e:Dynamic) {
					if (!errorFuncs.contains(func))		// This is to prevent an infinite loop when there's an error in the update function or anything called from the update function
					{
						errorFuncs.push(func);
						Application.current.window.alert("Error running function " + func + " in script file " + script + ".hscript:\n\n" + e.toString(), "Error");
					}
				}
			}
		}
	}

	public function execFuncReturn(func:String, args:Array<Dynamic>):Dynamic
	{
		if (interp == null)
			return null;

		if (interp.variables.exists(func))
		{
			var execMe = interp.variables.get(func);
			if (Reflect.isFunction(execMe))
				return Reflect.callMethod(this, execMe, args);
		}
		return null;
	}

	public function setVar(vari:String, val:Dynamic)
	{
		if (interp == null)
			return;

		interp.variables[vari] = val;
	}

	public function getVar(vari:String):Dynamic
	{
		if (interp == null)
			return null;

		return interp.variables[vari];
	}

	public function addVar(vari:String, val:Dynamic)
	{
		if (interp == null)
			return;

		interp.variables[vari] += val;
	}

	public function toggleVar(vari:String)
	{
		if (interp == null)
			return;

		interp.variables[vari] = !interp.variables[vari];
	}
}

class HscriptHandlerSimple
{
	var interp:CustomInterp;

	public function new(scriptFile:String)
	{
		var myCode:String = Paths.hscript(scriptFile);
		var parser:HSParser = new HSParser();
		parser.allowTypes = true;
		var program = parser.parseString(myCode);

		interp = new CustomInterp();
		refreshVariables();
		interp.execute(program);
	}

	public function refreshVariables()
	{
		interp.variables.set("Math", Math);
		interp.variables.set("Reflect", Reflect);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("FlxG.random", FlxG.random);
		interp.variables.set("FlxG.random.bool", FlxG.random.bool);
		interp.variables.set("FlxMath", FlxMath);
		interp.variables.set("Std", Std);
		interp.variables.set("Paths", Paths);
		interp.variables.set("Conductor", Conductor);
	}

	public function execFunc(func:String, args:Array<Dynamic>)
	{
		if (interp.variables.exists(func))
		{
			var execMe = interp.variables.get(func);
			if (Reflect.isFunction(execMe))
				Reflect.callMethod(this, execMe, args);
		}
	}

	public function execFuncReturn(func:String, args:Array<Dynamic>):Dynamic
	{
		if (interp.variables.exists(func))
		{
			var execMe = interp.variables.get(func);
			if (Reflect.isFunction(execMe))
				return Reflect.callMethod(this, execMe, args);
		}
		return null;
	}

	public function setVar(vari:String, val:Dynamic)
	{
		interp.variables[vari] = val;
	}

	public function getVar(vari:String):Dynamic
	{
		return interp.variables[vari];
	}
}