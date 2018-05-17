local Maid = require(script.Parent.Maid)
local Sparse3D = require(script.Parent.Sparse3D)
local Heap = require(script.Parent.Heap)
local boxIntersect = require(script.Parent.BoxIntersect)

local function distLessThan(a, b)
	return a.distance < b.distance
end

local ChunkManager3D = {}
ChunkManager3D.__index = ChunkManager3D

ChunkManager3D.chunkSize = 16*4

function ChunkManager3D.new(sampler, chunkClass)
	local self = {
		sampler = sampler,
		chunkClass = chunkClass,
		chunks = Sparse3D.new(Maid.new()),
		queued = Heap.new(distLessThan),
		anchors = {},
		stats = {},
		added = Sparse3D.new(),
		removed = Sparse3D.new(),
		loadRadius = 8,
	}
	setmetatable(self, ChunkManager3D)

	self.heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
		self:heartbeat()
	end)

	return self
end

function ChunkManager3D:destroy()
	self.heartbeatConn:Disconnect()

	self.chunks.array:destroy()
end

function ChunkManager3D:reportStat(name, unit, value, timeSample)
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

function ChunkManager3D:worldToChunk(position)
	return Vector3.new(
		math.floor(position.x / self.chunkSize + 0.5),
		math.floor(position.y / self.chunkSize + 0.5),
		math.floor(position.z / self.chunkSize + 0.5)
	)
end

function ChunkManager3D:setAnchor(name, newRadius, newPos)
	newPos = self:worldToChunk(newPos)
	newRadius = newRadius or 0
	local oldRadius = 0
	local oldPos = newPos
	local oldAnchor = self.anchors[name]
	if oldAnchor then
		oldRadius = oldAnchor.radius
		oldPos = oldAnchor.pos
	end
	local anchorAdded, anchorRemoved = boxIntersect(oldRadius, oldPos, newRadius, newPos)
	for _,pos in pairs(anchorAdded) do
		self.added:set(pos, true)
	end
	for _,pos in pairs(anchorRemoved) do
		self.removed:set(pos, true)
	end
	if newRadius > 0 then
		self.anchors[name] = {
			radius = newRadius,
			pos = newPos
		}
	else
		self.anchors[name] = nil
	end
end

function ChunkManager3D:chunkDist(pos)
	local closest = math.huge
	for name, anchor in pairs(self.anchors) do
		local dist = (anchor.pos - pos).Magnitude
		if dist < closest then
			closest = dist
		end
	end

	return closest
end

function ChunkManager3D:heartbeat()
	debug.profilebegin("ChunkManager3D bookkeeping")
	local bookkeepingStart = tick()
	local player = game.Players.LocalPlayer
	if player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head")
		if hrp then
			self:setAnchor("playerPos", self.loadRadius, hrp.Position)
		end
	end

	debug.profilebegin("Recalculating queue priority")
	for i = 1, #self.queued.array do
		local entry = self.queued.array[i]
		entry.distance = self:chunkDist(entry.position)
	end
	debug.profileend()

	debug.profilebegin("Adding chunks to queue")
	for chunkPos in self.added:iter() do
		local entry = {
			position = chunkPos,
			distance = self:chunkDist(chunkPos),
		}
		self.queued.array[#self.queued.array + 1] = entry
	end
	debug.profileend()

	debug.profilebegin("Removing chunks")
	for chunkPos in self.removed:iter() do
		self.chunks:set(chunkPos, nil)
	end
	debug.profileend()

	debug.profilebegin("Removing chunks from queue")
	for i = #self.queued.array, 1, -1 do
		local pos = self.queued.array[i].position
		if self.removed:get(pos) then
			local arr = self.queued.array
			arr[i], arr[#arr] = arr[#arr], nil
		end
	end
	debug.profileend()

	debug.profilebegin("Sorting queue")
	self.queued:build()
	debug.profileend()

	self.added = Sparse3D.new({})
	self.removed = Sparse3D.new({})

	local bookkeepingStop = tick()
	debug.profileend()
	self:reportStat("Bookkeeping", "ms", (bookkeepingStop - bookkeepingStart)*1000)

	local start = tick()
	local maxTime = 1.0 / 90
	local numProcessed = 0

	local nextChunk = self.queued:extractMin()
	while nextChunk and tick() - start < maxTime do
		local chunkPos = nextChunk.position
		if not self.chunks:get(chunkPos) then
			local chunkStart = tick()
			local newChunk = self.chunkClass.new(self.sampler, chunkPos, self.chunkSize)
			local chunkFinish = tick()
			self:reportStat("Time/Chunk", "ms", (chunkFinish - chunkStart)*1000, 3.0)
			self.chunks:set(chunkPos, newChunk)
		end
		numProcessed = numProcessed + 1
		nextChunk = self.queued:extractMin()
	end

	self:reportStat("Queue Size", "chunks", #self.queued.array)
	self:reportStat("Chunks/Frame", "chunks", numProcessed)
end

return ChunkManager3D
