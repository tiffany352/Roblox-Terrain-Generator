local min = math.min
local max = math.max

local function squareScanline(radius, y, offX, offY)
	if radius <= 0 or y - offY < -radius or y - offY > radius then
		return 0,-1
	end
	return offX - radius, offX + radius
end

local function squareIntersect(radius1, x1, y1, radius2, x2, y2)
	local minY = min(y1 - radius1, y2 - radius2)
	local maxY = max(y1 + radius1, y2 + radius2)
	local minX = min(x1 - radius1, x2 - radius2)
	local maxX = max(x1 + radius1, x2 + radius2)

	local added = {}
	local removed = {}

	if maxY - minY > radius1*2 + radius2*2 + 2 or maxX - minX > radius1*2 + radius2*2 + 2 then
		-- no overlap fast path
		for y = y1 - radius1, y1 + radius1 do
			for x = x1 - radius1, x1 + radius1 do
				removed[#removed+1] = Vector2.new(x, y)
			end
		end
		for y = y2 - radius2, x2 + radius2 do
			for x = x2 - radius2, x2 + radius2 do
				added[#added+1] = Vector2.new(x, y)
			end
		end

		return added, removed
	end

	for y = minY, maxY do
		local left1, right1 = squareScanline(radius1, y, x1, y1)
		local left2, right2 = squareScanline(radius2, y, x2, y2)

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

return squareIntersect
