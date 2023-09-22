package scripting;

import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;

import lime.app.Application;

class LuaModule
{
	var script:String;
	var state:State;

	public function new(file:String)
	{
		state = LuaL.newstate();
		LuaL.openlibs(state);

		script = file;
		LuaL.dofile(state, Paths.lua(file));
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

		return result;
	}

	public function set(varName:String, val:Dynamic)
	{
		Convert.toLua(state, val);
		Lua.setglobal(state, varName);
	}
}