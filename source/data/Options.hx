package data;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import menus.OptionsMenuState;

class Options
{
	public static var save:FlxSave;
	public static var options:Dynamic;

	public static function initOptions()
	{
		save = new FlxSave();
		save.bind("options");

		refreshOptions();
	}

	public static function getOptionsData():Array<OptionsMenuCategory>
	{
		var ret:Array<OptionsMenuCategory> = [];
		for (f in Paths.listFiles("data/options/", ".json"))
		{
			var c:OptionsMenuCategory = cast Paths.json("options/" + f);
			ret.push(c);
		}
		return ret;
	}

	public static function refreshOptions()
	{
		if (save.data.keys == null)
			save.data.keys = {};

		if (save.data.noteColors == null)
			save.data.noteColors = {};

		if (save.data.judgementOffset == null)
			save.data.judgementOffset = [0, 0];

		if (save.data.comboOffset == null)
			save.data.comboOffset = [0, 0];

		var cats:Array<OptionsMenuCategory> = getOptionsData();
		for (c in cats)
		{
			for (o in c.contents)
			{
				switch (o.type)
				{
					case "control":
						if (!Reflect.hasField(save.data.keys, o.variable))
							Reflect.setProperty(save.data.keys, o.variable, [FlxKey.fromString(o.defValue[0]), FlxKey.fromString(o.defValue[1])]);

					case "color":
						if (!Reflect.hasField(save.data, o.variable))
							Reflect.setProperty(save.data, o.variable, FlxColor.fromString(o.defValue));

					default:
						if (o.type != "label" && o.type != "function" && !Reflect.hasField(save.data, o.variable))
							Reflect.setProperty(save.data, o.variable, o.defValue);
				}
			}
		}

		save.flush();
		options = save.data;
		Noteskins.noteskinName = options.noteskin;
		Main.fpsVisible = options.fps;
		FlxG.updateFramerate = options.framerate;
		FlxG.drawFramerate = options.framerate;
	}

	public static function refreshSaveData()
	{
		for (f in Reflect.fields(options))
			Reflect.setProperty(save.data, f, Reflect.getProperty(options, f));

		save.flush();
	}

	public static function getKeys(keys:String):Array<FlxKey>
	{
		if (options.keys == null)
			return [];

		if (Reflect.getProperty(options.keys, keys) == null)
			return [];

		var keysArray:Array<FlxKey> = Reflect.getProperty(options.keys, keys);
		if (keysArray[0] == FlxKey.NONE)
			return [keysArray[1]];
		if (keysArray[1] == FlxKey.NONE)
			return [keysArray[0]];
		return keysArray;
	}

	public static function keyPressed(keys:String):Bool
	{
		if (options.keys == null)
			return false;

		if (Reflect.getProperty(options.keys, keys) == null)
			return false;

		return FlxG.keys.anyPressed(getKeys(keys));
	}

	public static function keyJustPressed(keys:String):Bool
	{
		if (options.keys == null)
			return false;

		if (Reflect.getProperty(options.keys, keys) == null)
			return false;

		return FlxG.keys.anyJustPressed(getKeys(keys));
	}

	public static function keyJustReleased(keys:String):Bool
	{
		if (options.keys == null)
			return false;

		if (Reflect.getProperty(options.keys, keys) == null)
			return false;

		return FlxG.keys.anyJustReleased(getKeys(keys));
	}

	public static function keyString(keys:String):String
	{
		if (options.keys == null)
			return "NONE";

		if (Reflect.getProperty(options.keys, keys) == null)
			return "NONE";

		var keysArray:Array<FlxKey> = Reflect.getProperty(options.keys, keys);
		if (keysArray[0] == FlxKey.NONE)
			return keysArray[1].toString();
		if (keysArray[1] == FlxKey.NONE)
			return keysArray[0].toString();
		return keysArray[0].toString() + " or " + keysArray[1].toString();
	}

	public static function noteColorExists(col:String):Bool
	{
		if (options.noteColors == null)
			return false;

		if (Reflect.getProperty(options.noteColors, col) == null)
			return false;

		return true;
	}

	public static function noteColor(col:String):Array<Dynamic>
	{
		if (!noteColorExists(col))
			return [0, true, 0, 0];

		return Reflect.getProperty(options.noteColors, col);
	}

	public static function noteColorArray(col:String):Array<Float>
	{
		return [noteColor(col)[0], noteColor(col)[2], noteColor(col)[3]];
	}
}