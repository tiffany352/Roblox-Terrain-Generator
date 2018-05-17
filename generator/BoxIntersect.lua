local abs = math.abs

local function pointInBox(radius, center, pos)
	pos = pos - center
	return
		abs(pos.x) <= radius or
		abs(pos.y) <= radius or
		abs(pos.z) <= radius
end

local function boxIntersect(oldRadius, oldPos, newRadius, newPos)
	local added = {}
	local removed = {}

	for x = -newRadius, newRadius do
		for y = -newRadius, newRadius do
			for z = -newRadius, newRadius do
				local pos = Vector3.new(x, y, z)
				if not pointInBox(oldRadius, oldPos, pos) then
					added[#removed+1] = pos
				end
			end
		end
	end

	for x = -oldRadius, oldRadius do
		for y = -oldRadius, oldRadius do
			for z = -oldRadius, oldRadius do
				local pos = Vector3.new(x, y, z)
				if not pointInBox(newRadius, newPos, pos) then
					removed[#removed+1] = pos
				end
			end
		end
	end

	return added, removed
end

return boxIntersect
