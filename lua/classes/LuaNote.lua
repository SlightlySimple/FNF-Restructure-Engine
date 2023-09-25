noteIDs = {}

function onNoteSpawned(note)
	local nID = "note_" .. #noteIDs
	_G[nID] = LuaClass(nID)
	assignObjectToLuaClass("notes.members["..note.."]", nID)
	table.insert(noteIDs, nID)
	noteSpawned(_G[nID])
end