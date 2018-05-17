local min = math.min
local max = math.max

local function circleScanline(radius, y, offX, offY)
	if radius <= 0 or y - offY < -radius or y - offY > radius then
		return 0,-1
	end
	y = math.clamp(y - offY, -radius, radius)
	y = math.floor(y)
	local r = math.floor(math.cos(y / radius * math.pi / 2) * radius + 0.5)
	return offX - r, offX + r
end

local function circleIntersect(radius1, x1, y1, radius2, x2, y2)
	local minY = min(y1 - radius1, y2 - radius2)
	local maxY = max(y1 + radius1, y2 + radius2)

	local added = {}
	local removed = {}

	for y = minY, maxY do
		local left1, right1 = circleScanline(radius1, y, x1, y1)
		local left2, right2 = circleScanline(radius2, y, x2, y2)

		if left1 < left2 then
			-- removed from left side
			for i = left1, left2 - 1 do
				removed[#removed+1] = Vector2.new(i, y)
			end
		elseif left2 < left1 then
			-- added to left side
			for i = left2, left1 - 1 do
				added[#added+1] = Vector2.new(i, y)
			end
		end
		if right1 < right2 then
			--added to right side
			for i = right1 + 1, right2 do
				added[#added+1] = Vector2.new(i, y)
			end
		elseif right2 < right1 then
			-- removed from right side
			for i = right2 + 1, right1 do
				removed[#removed+1] = Vector2.new(i, y)
			end
		end
	end

	return added, removed
end

return circleIntersect
