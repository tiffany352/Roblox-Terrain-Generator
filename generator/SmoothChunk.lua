local Terrain = workspace.Terrain

local Grass = Enum.Material.Grass
local Air = Enum.Material.Air
local Rock = Enum.Material.Slate

local SmoothChunk = {}
SmoothChunk.__index = SmoothChunk

SmoothChunk.Type = {
	Terrain = 'Terrain',
	Air = 'Air',
}

function SmoothChunk.new(sampler, position, chunkSize)
	local self = {
		position = position,
		chunkSize = chunkSize,
		sampler = sampler,
	}
	setmetatable(self, SmoothChunk)

	--[[self.debugPart = Instance.new("Part")
	self.debugPart.Anchored = true
	self.debugPart.CanCollide = false
	self.debugPart.Material = Enum.Material.Neon
	self.debugPart.Transparency = 0.9
	local worldPos = self.position * self.chunkSize
	self.debugPart.CFrame = CFrame.new(worldPos + Vector3.new(1,1,1)*self.chunkSize / 2)
	self.debugPart.Size = Vector3.new(1,1,1) * self.chunkSize
	self.debugPart.TopSurface = 'Smooth'
	self.debugPart.BottomSurface = 'Smooth'
	self.debugPart.Parent = workspace]]

	self:generate()

	return self
end

function SmoothChunk:generate()
	debug.profilebegin("Generating chunk")

	self:generateTerrain()

	debug.profileend()
end

function SmoothChunk:generateTerrain()
	local samples = {}
	local sampleFreq = self.sampler.frequency
	local numSamples = self.chunkSize / sampleFreq + 1
	local worldPos = self.position * self.chunkSize
	local sizeCells = self.chunkSize / 4
	local region = Region3.new(worldPos, worldPos + Vector3.new(sizeCells, sizeCells, sizeCells) * 4):ExpandToGrid(4)

	local seaLevel = 0

	debug.profilebegin("Building samples")
	local allAir = worldPos.y > seaLevel
	local allSolid = true
	for x = 0, numSamples-1 do
		for y = 0, numSamples-1 do
			for z = 0, numSamples-1 do
				local samplePos = worldPos + Vector3.new(x*sampleFreq, y*sampleFreq, z*sampleFreq)
				local result = self.sampler:sample(samplePos)
				if result / 400 > 0.0 then
					allAir = false
				else
					allSolid = false
				end
				samples[x*numSamples*numSamples + y*numSamples + z] = result
			end
		end
	end
	debug.profileend()

	if allAir then
		self.type = self.Type.Air
		return
	elseif allSolid then
		self.type = self.Type.Terrain
		Terrain:FillRegion(region, 4, Enum.Material.Grass)
		return
	else
		self.type = self.Type.Terrain
	end

	local material = {}
	local occupancy = {}

	local cellsPerSample = sampleFreq / 4
	local sizeYZ = numSamples*numSamples
	local outerCount = self.chunkSize / sampleFreq - 1
	local innerCount = cellsPerSample - 1

	debug.profilebegin("Populating array")
	for x = 1, sizeCells do
		local materialX = {}
		local occupancyX = {}
		material[x] = materialX
		occupancy[x] = occupancyX
		for y = 1, sizeCells do
			local materialY = {}
			local occupancyY = {}
			materialX[y] = materialY
			occupancyX[y] = occupancyY
			for z = 1, sizeCells do
				materialY[z] = Air
				occupancyY[z] = 'poison'
			end
		end
	end
	debug.profileend()

	debug.profilebegin("Rasterizing")
	for minX = 0, outerCount do
		local cellX = minX * cellsPerSample
		local maxX = minX + 1
		local minXSizeYZ = minX * sizeYZ
		local maxXSizeYZ = maxX * sizeYZ
		for minY = 0, outerCount do
			local cellY = minY * cellsPerSample
			local maxY = minY + 1
			local minYSizeZ = minY * numSamples
			local maxYSizeZ = maxY * numSamples
			for minZ = 0, outerCount do
				local cellZ = minZ * cellsPerSample
				local maxZ = minZ + 1

				local x0y0z0 = samples[minXSizeYZ + minYSizeZ + minZ]
				local x1y0z0 = samples[maxXSizeYZ + minYSizeZ + minZ]
				local x0y1z0 = samples[minXSizeYZ + maxYSizeZ + minZ]
				local x1y1z0 = samples[maxXSizeYZ + maxYSizeZ + minZ]
				local x0y0z1 = samples[minXSizeYZ + minYSizeZ + maxZ]
				local x1y0z1 = samples[maxXSizeYZ + minYSizeZ + maxZ]
				local x0y1z1 = samples[minXSizeYZ + maxYSizeZ + maxZ]
				local x1y1z1 = samples[maxXSizeYZ + maxYSizeZ + maxZ]

				for dX = 0, innerCount do
					local materialX = material[cellX + dX + 1]
					local occupancyX = occupancy[cellX + dX + 1]
					local tX = dX / cellsPerSample
					local nX = 1 - tX
					for dY = 0, innerCount do
						local materialY = materialX[cellY + dY + 1]
						local occupancyY = occupancyX[cellY + dY + 1]
						local tY = dY / cellsPerSample
						local nY = 1 - tY
						for dZ = 0, innerCount do
							local tZ = dZ / cellsPerSample
							local nZ = 1 - tZ

							local x0y0 = x0y0z0*nZ + x0y0z1*tZ
							local x0y1 = x0y1z0*nZ + x0y1z1*tZ
							local x1y0 = x1y0z0*nZ + x1y0z1*tZ
							local x1y1 = x1y1z0*nZ + x1y1z1*tZ
							local x0 = x0y0*nY + x0y1*tY
							local x1 = x1y0*nY + x1y1*tY
							local percentSolid = (x0*nX + x1*tX) / 400

							local m
							local o = 1.0
							if percentSolid >= 30.0 then
								m = Rock
							elseif percentSolid > 0.0 then
								m = Grass
								o = percentSolid * sampleFreq
							else
								m = Air
							end
							assert(occupancyY[cellZ + dZ + 1] == 'poison')
							materialY[cellZ + dZ + 1] = m
							occupancyY[cellZ + dZ + 1] = o
						end
					end
				end
			end
		end
	end
	debug.profileend()

	debug.profilebegin("WriteVoxels()")
	Terrain:WriteVoxels(region, 4, material, occupancy)
	debug.profileend()
end

function SmoothChunk:destroy()
	if self.type == self.Type.Terrain then
		local worldPos = self.position * self.chunkSize
		local region = Region3.new(worldPos, worldPos + Vector3.new(self.chunkSize, self.chunkSize, self.chunkSize)):ExpandToGrid(4)
		workspace.Terrain:FillRegion(region, 4, Enum.Material.Air)
	elseif self.type == self.Type.Air then
		-- do nothing
	else
		error("unknown chunk type")
	end
	--self.debugPart:Destroy()
end

return SmoothChunk
