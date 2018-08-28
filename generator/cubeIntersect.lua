local min = math.min
local max = math.max
local abs = math.abs

local function contains(radius, offX, offY, offZ, x, y, z)
	if radius <= 0 then
		return false
	end
	x = x - offX
	y = y - offY
	z = z - offZ
	return
		abs(x) <= radius and
		abs(y) <= radius and
		abs(z) <= radius
end

local function cubeIntersect(radius1, x1, y1, z1, radius2, x2, y2, z2)
	local minY = min(y1 - radius1, y2 - radius2)
	local maxY = max(y1 + radius1, y2 + radius2)
	local minX = min(x1 - radius1, x2 - radius2)
	local maxX = max(x1 + radius1, x2 + radius2)
	local minZ = min(z1 - radius1, z2 - radius2)
	local maxZ = max(z1 + radius1, z2 + radius2)

	local added = {}
	local removed = {}

	if
		maxY - minY > radius1*2 + radius2*2 + 2 or
		maxX - minX > radius1*2 + radius2*2 + 2 or
		maxZ - minZ > radius1*2 + radius2*2 + 2
	then
		-- no overlap fast path
		for y = y1 - radius1, y1 + radius1 do
			for x = x1 - radius1, x1 + radius1 do
				for z = z1 - radius1, z1 + radius1 do
					removed[#removed+1] = Vector3.new(x, y, z)
				end
			end
		end
		for y = y2 - radius2, x2 + radius2 do
			for x = x2 - radius2, x2 + radius2 do
				for z = z2 - radius2, z2 + radius2 do
					added[#added+1] = Vector3.new(x, y, z)
				end
			end
		end

		return added, removed
	end

	for x = minX, maxX do
		for y = minY, maxY do
			for z = minZ, maxZ do
				local inOld = contains(radius1, x1, y1, z1, x, y, z)
				local inNew = contains(radius2, x2, y2, z2, x, y, z)

				if inOld and not inNew then
					removed[#removed+1] = Vector3.new(x, y, z)
				elseif inNew and not inOld then
					added[#added+1] = Vector3.new(x, y, z)
				end
			end
		end
	end

	return added, removed
end

return cubeIntersect
