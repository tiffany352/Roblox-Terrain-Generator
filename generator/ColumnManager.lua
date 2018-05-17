local ColumnManager = {}
ColumnManager.__index = ColumnManager

function ColumnManager.new()
	local self = {
		columns = {},
		added = {},
	}
	setmetatable(self, ColumnManager)

	return self
end

local function keyFor(pos)
	assert(typeof(pos) == 'Vector2')
	local x = math.floor(pos.x + 0.5)
	local y = math.floor(pos.y + 0.5)
	return string.format("%d,%d", x, y)
end

local function posFromKey(key)
	local x, y = key:match("(%-?%d+),(%-?%d+)")
	return Vector2.new(tonumber(x), tonumber(y))
end

function ColumnManager:get(pos)
	return self.columns[keyFor(pos)]
end

function ColumnManager:getOrCreate(pos)
	local key = keyFor(pos)
	local col = self.columns[key]
	if not col then
		col = {
			marked = false,
		}
		self.columns[key] = col
		self.added[#self.added+1] = pos
	end
	return col
end

function ColumnManager:writeCircle(pos, radius)
	for y = -radius, radius do
		local quarterTurn = math.pi / 2
		local w = math.floor(math.cos(y / radius * quarterTurn) * radius + 0.5)
		for x = -w, w do
			self:getOrCreate(pos + Vector2.new(x, y)).marked = true
		end
	end
end

function ColumnManager:commit()
	local removed = {}
	local added = self.added
	self.added = {}

	for key, column in pairs(self.columns) do
		if not column.marked then
			removed[#removed+1] = posFromKey(key)
			self.columns[key] = nil
		else
			column.marked = false
		end
	end

	return added, removed
end

return ColumnManager
