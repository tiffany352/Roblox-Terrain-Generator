local Maid = require(script.Parent.Maid)
local Sparse3D = require(script.Parent.Sparse3D)

local ChunkManager = {}
ChunkManager.__index = ChunkManager

function ChunkManager.new(sampler, chunkClass)
	local self = {
		chunkSize = 16*4, --studs

		sampler = sampler,
		chunkClass = chunkClass,
		chunks = Sparse3D.new(Maid.new()),
		stats = {},
	}
	setmetatable(self, ChunkManager)

	return self
end

function ChunkManager:destroy()
	self.chunks.array:destroy()
end

function ChunkManager:reportStat(name, unit, value, timeSample)
	local stat = self.stats[name] or {}
	self.stats[name] = stat
	stat.values = stat.values or {}
	stat.unit = unit
	timeSample = timeSample or 10.0
	stat.timeSample = timeSample

	local now = tick()
	stat.values[#stat.values+1] = {
		value = value,
		sampleTime = now,
	}
	while stat.values[1].sampleTime < now - timeSample do
		table.remove(stat.values, 1)
	end
end

return ChunkManager
