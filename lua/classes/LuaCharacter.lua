function LuaCharacter(id)
	local obj = {}
	local objFunctions = {}

	objFunctions["flip"] = function()
		execOnLuaClass(id, "flip", {})
	end

	objFunctions["playAnim"] = function(anim, forced, important, canSwitchLeftRight)
		execOnLuaClass(id, "playAnim", {anim, forced or false, important or false, canSwitchLeftRight or true})
	end

	objFunctions["dance"] = function()
		execOnLuaClass(id, "dance", {})
	end

	objFunctions["changeCharacter"] = function(newChar)
		execOnLuaClass(id, "changeCharacter", {newChar})
	end

	objFunctions["repositionCharacter"] = function(x, y)
		execOnLuaClass(id, "repositionCharacter", {x, y})
	end

	objFunctions["scaleCharacter"] = function(x, y)
		execOnLuaClass(id, "scaleCharacter", {x, y})
	end

	setmetatable(obj, {
		__index = function(meta, key)
			if objFunctions[key] ~= nil then
				return objFunctions[key]
			end
			return getOnLuaClass(id, key)
		end,
		__newindex = function(meta, key, value)
			setOnLuaClass(id, key, value)
		end
	})

	return obj
end

if inPlayState then
	player1 = LuaCharacter("player1")
	assignObjectToLuaClass("player1", "player1")
	player2 = LuaCharacter("player2")
	assignObjectToLuaClass("player2", "player2")
	gf = LuaCharacter("gf")
	assignObjectToLuaClass("gf", "gf")
end