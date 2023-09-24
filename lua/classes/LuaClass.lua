function LuaClass(id)
	local obj = {}

	setmetatable(obj, {
		__index = function(meta, key)
			return getOnLuaClass(id, key)
		end,
		__newindex = function(meta, key, value)
			setOnLuaClass(id, key, value)
		end
	})

	return obj
end