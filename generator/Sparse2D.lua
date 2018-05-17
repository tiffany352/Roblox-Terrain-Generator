local Sparse2D = {}
Sparse2D.__index = Sparse2D

function Sparse2D.new(backingArray)
	local self = {
		array = backingArray or {},
	}
	setmetatable(self, Sparse2D)

	return self
end

local function key(pos)
	assert(math.floor(pos.x) == pos.x)
	assert(math.floor(pos.y) == pos.y)
	return string.format("%d,%d", pos.x, pos.y)
end

function Sparse2D:get(pos)
	assert(typeof(pos) == 'Vector2', string.format("Expected Vector2 for #1, got %q", typeof(pos)))
	return self.array[key(pos)]
end

function Sparse2D:set(pos, value)
	assert(typeof(pos) == 'Vector2', string.format("Expected Vector2 for #1, got %q", typeof(pos)))
	self.array[key(pos)] = value
end

function Sparse2D:iter()
	return coroutine.wrap(function()
		if self.array.iter then
			for key, value in self.array:iter() do
				local x, y = key:match("^(-?%d+),(-?%d+)$")
				x = tonumber(x) or error("expected number")
				y = tonumber(y) or error("expected number")
				coroutine.yield(Vector2.new(x, y), value)
			end
		else
			for key, value in pairs(self.array) do
				local x, y = key:match("^(-?%d+),(-?%d+)$")
				x = tonumber(x) or error("expected number")
				y = tonumber(y) or error("expected number")
				coroutine.yield(Vector2.new(x, y), value)
			end
		end
	end)
end

return Sparse2D
