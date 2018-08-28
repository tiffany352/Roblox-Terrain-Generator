local Sparse2D = require(script.Parent.Sparse2D)
local Job = require(script.Parent.Job)
local squareIntersect = require(script.Parent.squareIntersect)
local squareDist = require(script.Parent.squareDist)
local sortedInsert = require(script.Parent.sortedInsert)

local ChunkLoader2D = {}
ChunkLoader2D.__index = ChunkLoader2D

function ChunkLoader2D.new(manager)
	local self = {
		loadRadius = 8, --chunks
		loadHeight = 8, --chunks
		jobBudget = 8.0, --ms
		jobTimeout = 1000.0, --ms
		distFunc = squareDist, --function(x, y, z) -> number
		intersectFunc = squareIntersect, --function(oldRadius, oldX, oldY, newRadius, newX, newY) -> added[], removed[]

		queued = {},
		manager = manager,
		anchors = {},
		added = Sparse2D.new(),
		removed = Sparse2D.new(),
	}
	setmetatable(self, ChunkLoader2D)

	self.heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
		if not self.currentJob or self.currentJob:expired() then
			self.currentJob = Job.new(function(job) self:runJob(job) end, self.jobTimeout, "ChunkLoader2D")
		end
		self.currentJob:tick(self.jobBudget)
	end)

	return self
end

function ChunkLoader2D:destroy()
	self.heartbeatConn:Disconnect()
end

function ChunkLoader2D:worldToChunk(position)
	local chunkSize = self.manager.chunkSize
	return Vector3.new(
		math.floor(position.x / chunkSize + 0.5),
		math.floor(position.y / chunkSize + 0.5),
		math.floor(position.z / chunkSize + 0.5)
	)
end

function ChunkLoader2D:setAnchor(name, newRadius, newX, newY)
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
	local anchorAdded, anchorRemoved = self.intersectFunc(oldRadius, oldX, oldY, newRadius, newX, newY)
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

function ChunkLoader2D:chunkDist(pos)
	local closest = math.huge
	for name, anchor in pairs(self.anchors) do
		local x, y = anchor.x, anchor.y
		local dist = self.distFunc(x - pos.x, y - pos.z)
		if dist < closest then
			closest = dist
		end
	end

	return closest
end

function ChunkLoader2D:runJob(job)
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

	for i = 1, #self.queued do
		job:breath("Sorting queue")
		local entry = self.queued[i]
		entry.distance = self:chunkDist(entry.position)
	end
	table.sort(self.queued, distLessThan)

	for columnPos in self.added:iter() do
		job:breath("Inserting new entries into queue")
		for z = 0, self.loadHeight - 1 do
			local chunkPos = Vector3.new(columnPos.x, z, columnPos.y)
			local entry = {
				position = chunkPos,
				distance = self:chunkDist(chunkPos),
			}
			sortedInsert(self.queued, entry, distLessThan)
		end
	end

	for columnPos in self.removed:iter() do
		job:breath("Destroying chunks")
		for z = 0, self.loadHeight - 1 do
			local chunkPos = Vector3.new(columnPos.x, z, columnPos.y)
			self.manager.chunks:set(chunkPos, nil)
		end
	end

	for i = #self.queued, 1, -1 do
		job:breath("Cleaning queue")
		local pos = self.queued[i].position
		if self.removed:get(Vector2.new(pos.x, pos.z)) then
			table.remove(self.queued, i)
		end
	end

	self.added = Sparse2D.new({})
	self.removed = Sparse2D.new({})

	local _, nextChunk = next(self.queued)
	while nextChunk do
		job:breath("Generating chunks")
		local chunkPos = nextChunk.position
		if not self.manager.chunks:get(chunkPos) then
			debug.profilebegin("Single chunk")
			local chunkStart = tick()
			local newChunk = self.manager.chunkClass.new(self.manager.sampler, chunkPos, self.manager.chunkSize)
			local chunkFinish = tick()
			debug.profileend()
			self.manager:reportStat("Time/Chunk", "ms", (chunkFinish - chunkStart)*1000, 3.0)
			self.manager.chunks:set(chunkPos, newChunk)
		end
		table.remove(self.queued, 1)
		_, nextChunk = next(self.queued)
	end
end

return ChunkLoader2D
