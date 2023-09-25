sustainIDs = {}

function onSustainSpawned(note)
	local nID = "sustain_" .. #sustainIDs
	_G[nID] = LuaClass(nID)
	assignObjectToLuaClass("sustainNotes.members["..note.."]", nID)
	table.insert(sustainIDs, nID)
	sustainSpawned(_G[nID])
end