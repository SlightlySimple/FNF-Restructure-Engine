LuaConductor = {}

setmetatable(LuaConductor, {
	__index = function(meta, key)
		return getOnClass("Conductor", key)
	end
})