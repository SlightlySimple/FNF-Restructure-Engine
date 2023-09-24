package scripting;

import flixel.FlxG;
import flixel.FlxSprite;
import game.PlayState;

import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;

import lime.app.Application;

class LuaModule
{
	var script:String;
	var state:State;
	public static var luaObjects:Map<String, Any> = new Map<String, Any>();

	public static function assignObjectToLuaClass(obj:Any, className:String)
	{
		luaObjects[className] = obj;
	}

	public function new(file:String)
	{
		state = LuaL.newstate();
		LuaL.openlibs(state);
		Lua.init_callbacks(state);

		set("inPlayState", (FlxG.state == PlayState.instance));

		if (FlxG.state == PlayState.instance)
		{
			Lua_helper.add_callback(state, "hscriptExec", function(func:String, args:Array<Dynamic>)
			{
				PlayState.instance.hscriptExec(func, args);
			});

			Lua_helper.add_callback(state, "hscriptIdExec", function(id:String, func:String, args:Array<Dynamic>)
			{
				PlayState.instance.hscriptIdExec(id, func, args);
			});

			Lua_helper.add_callback(state, "assignObjectToLuaClass", function(obj:String, className:String)
			{
				if (obj.split(".").length > 1)
				{
					var keySplit:Array<String> = obj.split(".");
					var f:Any = PlayState.instance;
					while (keySplit.length > 0)
					{
						var curKey:String = keySplit.shift();
						if (curKey.split("[").length > 1)
							f = Reflect.getProperty(f, curKey.split("[")[0])[Std.parseInt(curKey.split("[")[1].split("]")[0])];
						else
							f = Reflect.getProperty(f, curKey);
					}
					assignObjectToLuaClass(f, className);
				}
				else if (Reflect.fields(PlayState.instance).contains(obj))
					assignObjectToLuaClass(Reflect.field(PlayState.instance, obj), className);
			});

			Lua_helper.add_callback(state, "addObject", function(id:String, layer:Int = 0)
			{
				if (luaObjects.exists(id))
				{
					if (layer >= PlayState.instance.allCharacters.length)
						PlayState.instance.add(luaObjects[id]);
					else
					{
						var ind:Int = PlayState.instance.allCharacters.length - layer - 1;
						PlayState.instance.insert(PlayState.instance.members.indexOf(PlayState.instance.allCharacters[ind]), luaObjects[id]);
					}
				}
			});
		}
		else
		{
			Lua_helper.add_callback(state, "hscriptExec", function(func:String, args:Array<Dynamic>) {});
			Lua_helper.add_callback(state, "hscriptIdExec", function(id:String, func:String, args:Array<Dynamic>) {});
			Lua_helper.add_callback(state, "assignObjectToLuaClass", function(obj:String, className:String) {});
			Lua_helper.add_callback(state, "addObject", function(id:String)
			{
				if (luaObjects.exists(id))
					FlxG.state.add(luaObjects[id]);
			});
		}

		Lua_helper.add_callback(state, "setOnClass", function(className:String, key:String, value:Any)
		{
			if (key.split(".").length > 1)
			{
				var keySplit:Array<String> = key.split(".");
				var f:Any = Type.resolveClass(className);
				while (keySplit.length > 1)
					f = Reflect.getProperty(f, keySplit.shift());
				Reflect.setProperty(f, keySplit[0], value);
			}
			else
				Reflect.setProperty(Type.resolveClass(className), key, value);
		});

		Lua_helper.add_callback(state, "getOnClass", function(className:String, key:String)
		{
			if (key.split(".").length > 1)
			{
				var keySplit:Array<String> = key.split(".");
				var f:Any = Type.resolveClass(className);
				while (keySplit.length > 0)
					f = Reflect.getProperty(f, keySplit.shift());
				return f;
			}
			return Reflect.getProperty(Type.resolveClass(className), key);
		});

		Lua_helper.add_callback(state, "setOnLuaClass", function(className:String, key:String, value:Any)
		{
			if (luaObjects.exists(className))
			{
				if (key.split(".").length > 1)
				{
					var keySplit:Array<String> = key.split(".");
					var f:Any = luaObjects[className];
					while (keySplit.length > 1)
						f = Reflect.getProperty(f, keySplit.shift());
					Reflect.setProperty(f, keySplit[0], value);
				}
				else
					Reflect.setProperty(luaObjects[className], key, value);
			}
		});

		Lua_helper.add_callback(state, "getOnLuaClass", function(className:String, key:String)
		{
			if (luaObjects.exists(className))
			{
				if (key.split(".").length > 1)
				{
					var keySplit:Array<String> = key.split(".");
					var f:Any = luaObjects[className];
					while (keySplit.length > 0)
						f = Reflect.getProperty(f, keySplit.shift());
					return f;
				}
				return Reflect.getProperty(luaObjects[className], key);
			}
			return null;
		});

		Lua_helper.add_callback(state, "execOnLuaClass", function(className:String, key:String, args:Array<Dynamic>)
		{
			if (luaObjects.exists(className))
				Reflect.callMethod(luaObjects[className], Reflect.getProperty(luaObjects[className], key), args);
		});

		Lua_helper.add_callback(state, "createInstance", function(className:String, inst:String, args:Array<Dynamic>)
		{
			var obj:Any = Type.createInstance(Type.resolveClass(inst), args);
			assignObjectToLuaClass(obj, className);
		});

		Lua_helper.add_callback(state, "PathsImage", function(path:String)
		{
			return Paths.imagePath(path);
		});

		Lua_helper.add_callback(state, "PathsIsSparrow", function(path:String)
		{
			return Paths.sparrowExists(path);
		});

		Lua_helper.add_callback(state, "LoadSparrow", function(id:String, path:String)
		{
			if (luaObjects.exists(id))
			{
				var s:FlxSprite = cast luaObjects[id];
				s.frames = Paths.sparrow(path);
			}
		});

		Lua_helper.add_callback(state, "PlaySound", function(sound:String, volume:Float = 1)
		{
			if (Paths.soundExists(sound))
				FlxG.sound.play(Paths.sound(sound), volume);
		});

		for (f in Paths.listFiles("lua/classes/", ".lua"))
			LuaL.dofile(state, Paths.lua("lua/classes/" + f));

		script = file;
		var status:Int = LuaL.dofile(state, Paths.lua(file));
	}

	public function exec(func:String, ?args:Array<Dynamic> = null):Dynamic
	{
		Lua.getglobal(state, func);

		if (args == null)
			args = [];

		for (arg in args)
			Convert.toLua(state, arg);

		var status:Int = Lua.pcall(state, args.length, 1, 0);
		if (status != Lua.LUA_OK) {
			Application.current.window.alert("Error running function "+func+" in lua script: "+execError(status), "Alert");
			return null;
		}

		var result:Dynamic = cast Convert.fromLua(state, -1);
		Lua.pop(state, 1);

		return result;
	}

	function execError(status:Int)
	{
		var err:String = Lua.tostring(state, -1);
		Lua.pop(state, 1);
		if (err == null || err == "")
		{
			switch (status)
			{
				case Lua.LUA_ERRRUN: err = "Runtime Error";
				case Lua.LUA_ERRMEM: err = "Memory Allocation Error";
				case Lua.LUA_ERRERR: err = "Critical Error";
				default: err = "Unknown Error";
			}
		}

		return err;
	}

	public function get(varName:String):Dynamic
	{
		Lua.getglobal(state, varName);
		var result:Dynamic = cast Convert.fromLua(state, -1);
		Lua.pop(state, 1);

		return result;
	}

	public function set(varName:String, val:Dynamic)
	{
		Convert.toLua(state, val);
		Lua.setglobal(state, varName);
	}

	public function register(funcName:String, func:Dynamic)
	{
		Lua_helper.add_callback(state, funcName, func);
	}
}