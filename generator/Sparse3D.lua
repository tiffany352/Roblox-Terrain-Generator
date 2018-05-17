local Sparse3D = {}
Sparse3D.__index = Sparse3D

function Sparse3D.new(backingArray)
	local self = {
		array = backingArray or {},
	}
	setmetatable(self, Sparse3D)

	return self
end

local function key(pos)
	return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
end

function Sparse3D:get(pos)
	assert(typeof(pos) == 'Vector3', string.format("Expected Vector3 for #1, got %q", typeof(pos)))
	return self.array[key(pos)]
end

function Sparse3D:set(pos, value)
	assert(typeof(pos) == 'Vector3', string.format("Expected Vector3 for #1, got %q", typeof(pos)))
	self.array[key(pos)] = value
end

function Sparse3D:iter()
	return coroutine.wrap(function()
		for key, value in pairs(self.array.iter and self.array:iter() or pairs(self.array)) do
			local x, y, z = key:match("^(-?%d+),(-?%d+),(-?%d+)$")
			x = tonumber(x)
			y = tonumber(y)
			z = tonumber(z)
			coroutine.yield(Vector3.new(x, y, z), value)
		end
	end)
end

return Sparse3D
