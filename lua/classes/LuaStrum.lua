for i=0,getOnClass("game.PlayState", "instance.strumNotes.length") do
	local rID = "strum_" .. i
	_G[rID] = LuaClass(rID)
	assignObjectToLuaClass("strumNotes.members["..i.."]", rID)
end