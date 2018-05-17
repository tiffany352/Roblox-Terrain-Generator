local Maid = require(script.Parent.Maid)
local Sparse3D = require(script.Parent.Sparse3D)
local Sparse2D = require(script.Parent.Sparse2D)
local circleIntersect = require(script.Parent.CircleIntersect)

local ChunkManager2D = {}
ChunkManager2D.__index = ChunkManager2D

ChunkManager2D.chunkSize = 16*4

function ChunkManager2D.new(sampler, chunkClass)
	local self = {
		sampler = sampler,
		chunkClass = chunkClass,
		chunks = Sparse3D.new(Maid.new()),
		queued = {},
		anchors = {},
		added = Sparse2D.new(),
		removed = Sparse2D.new(),
		stats = {},
		loadRadius = 8,
		loadHeight = 8,
	}
	setmetatable(self, ChunkManager2D)

	self.heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
		self:heartbeat()
	end)

	return self
end

function ChunkManager2D:destroy()
	self.heartbeatConn:Disconnect()

	self.chunks.array:destroy()
end

function ChunkManager2D:reportStat(name, unit, value, timeSample)
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

function ChunkManager2D:worldToChunk(position)
	return Vector3.new(
		math.floor(position.x / self.chunkSize + 0.5),
		math.floor(position.y / self.chunkSize + 0.5),
		math.floor(position.z / self.chunkSize + 0.5)
	)
end

function ChunkManager2D:setAnchor(name, newRadius, newX, newY)
	if typeof(newX) == 'Vector3' then
		local v = self:worldToChunk(newX)
		newX = v.x
		newY = v.z
	end
	newRadius = newRadius or 0
	local oldRadius = 0
	local oldX = newX
	local oldY = newY
	local oldAnchor = self.anchors[name]
	if oldAnchor then
		oldRadius = oldAnchor.radius
		oldX = oldAnchor.x
		oldY = oldAnchor.y
		newX = newX or oldX
		newY = newY or oldY
	end
	local anchorAdded, anchorRemoved = circleIntersect(oldRadius, oldX, oldY, newRadius, newX, newY)
	for _,pos in pairs(anchorAdded) do
		self.added:set(pos, true)
	end
	for _,pos in pairs(anchorRemoved) do
		self.removed:set(pos, true)
	end
	if newRadius > 0 then
		self.anchors[name] = {
			radius = newRadius,
			x = newX,
			y = newY,
		}
	else
		self.anchors[name] = nil
	end
end

local function sortedInsert(array, value, lessThan)
	if #array == 0 then
		array[1] = value
		return
	end
	local start = 1
	local stop = #array

	while stop >= start do
		local pivot = math.floor(start + (stop - start) / 2)
		if lessThan(value, array[pivot]) then
			stop = pivot - 1
		else
			start = pivot + 1
		end
	end

	table.insert(array, stop + 1, value)
end

function ChunkManager2D:chunkDist(pos)
	local pos2D = Vector2.new(pos.x, pos.z)
	local closest = math.huge
	for name, anchor in pairs(self.anchors) do
		local x, y = anchor.x, anchor.y
		local anchorPos = Vector2.new(x, y)
		local dist = (anchorPos - pos2D).Magnitude
		if dist < closest then
			closest = dist
		end
	end

	return closest
end

function ChunkManager2D:heartbeat()
	debug.profilebegin("ChunkManager2D bookkeeping")
	local bookkeepingStart = tick()
	local player = game.Players.LocalPlayer
	if player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head")
		if hrp then
			self:setAnchor("playerPos", self.loadRadius, hrp.Position)
		end
	end

	local function distLessThan(a, b)
		return a.distance < b.distance
	end

	debug.profilebegin("Re-sorting queue")
	for i = 1, #self.queued do
		local entry = self.queued[i]
		entry.distance = self:chunkDist(entry.position)
	end
	table.sort(self.queued, distLessThan)
	debug.profileend()

	debug.profilebegin("Adding chunks to queue")
	for columnPos in self.added:iter() do
		for z = 0, self.loadHeight - 1 do
			local chunkPos = Vector3.new(columnPos.x, z, columnPos.y)
			local entry = {
				position = chunkPos,
				distance = self:chunkDist(chunkPos),
			}
			sortedInsert(self.queued, entry, distLessThan)
		end
	end
	debug.profileend()

	debug.profilebegin("Removing chunks")
	for columnPos in self.removed:iter() do
		for z = 0, self.loadHeight - 1 do
			local chunkPos = Vector3.new(columnPos.x, z, columnPos.y)
			self.chunks:set(chunkPos, nil)
		end
	end
	debug.profileend()

	debug.profilebegin("Removing chunks from queue")
	for i = #self.queued, 1, -1 do
		local pos = self.queued[i].position
		if self.removed:get(Vector2.new(pos.x, pos.z)) then
			table.remove(self.queued, i)
		end
	end
	debug.profileend()

	self.added = Sparse2D.new({})
	self.removed = Sparse2D.new({})

	local bookkeepingStop = tick()
	debug.profileend()
	self:reportStat("Bookkeeping", "ms", (bookkeepingStop - bookkeepingStart)*1000)

	local start = tick()
	local maxTime = 1.0 / 90
	local numProcessed = 0

	local _, nextChunk = next(self.queued)
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
		table.remove(self.queued, 1)
		_, nextChunk = next(self.queued)
	end

	self:reportStat("Queue Size", "chunks", #self.queued)
	self:reportStat("Chunks/Frame", "chunks", numProcessed)
end

return ChunkManager2D
