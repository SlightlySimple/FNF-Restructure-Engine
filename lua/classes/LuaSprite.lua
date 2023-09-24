function LuaSprite(id)
	local obj = {}
	local objFunctions = {}
	local objRecursive = {}

	objFunctions["loadGraphic"] = function(path)
		execOnLuaClass(id, "loadGraphic", {PathsImage(path)})
	end

	objFunctions["loadFrames"] = function(path)
		LoadSparrow(id, path)
	end

	objFunctions["screenCenter"] = function(axis)
		axis = axis or "XY"
		if axis == "XY" or axis == "X" then
			setOnLuaClass(id, "x", (1280 - getOnLuaClass(id, "width")) / 2)
		end

		if axis == "XY" or axis == "Y" then
			setOnLuaClass(id, "y", (720 - getOnLuaClass(id, "height")) / 2)
		end
	end

	objFunctions["add"] = function(layer)
		addObject(id, layer or 0)
	end

	objFunctions["addAnim"] = function(name, prefix, fps, loop, indices)
		fps = fps or 24
		loop = loop or true
		indices = indices or {}
		execOnLuaClass(id, "addAnim", {name, prefix, fps, loop, indices})
	end

	objFunctions["addOffsets"] = function(name, offsets)
		execOnLuaClass(id, "addOffsets", {name, offsets})
	end

	objFunctions["playAnim"] = function(name, force, rev, frame)
		force = force or false
		rev = rev or false
		frame = frame or 0
		execOnLuaClass(id, "playAnim", {name, force, rev, frame})
	end

	objRecursive["scaleX"] = "scale.x"
	objRecursive["scaleY"] = "scale.y"
	objRecursive["scrollFactorX"] = "scrollFactor.x"
	objRecursive["scrollFactorY"] = "scrollFactor.y"

	setmetatable(obj, {
		__index = function(meta, key)
			if objFunctions[key] ~= nil then
				return objFunctions[key]
			elseif objRecursive[key] ~= nil then
				return getOnLuaClass(id, objRecursive[key])
			end
			return getOnLuaClass(id, key)
		end,
		__newindex = function(meta, key, value)
			if objRecursive[key] ~= nil then
				setOnLuaClass(id, objRecursive[key], value)
			else
				setOnLuaClass(id, key, value)
			end
		end
	})

	return obj
end

function CreateSprite(id, graphic, x, y)
	s = LuaSprite(id)
	x = x or 0
	y = y or 0
	if PathsIsSparrow(graphic) then
		createInstance(id, "objects.AnimatedSprite", {x, y})
		s.loadFrames(graphic)
	else
		createInstance(id, "flixel.FlxSprite", {x, y})
		s.loadGraphic(graphic)
	end
	return s
end