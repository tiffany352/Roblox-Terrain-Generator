local min = math.min
local max = math.max
local clamp = math.clamp
local floor = math.floor
local cos = math.cos
local pi = math.pi
local Vector2new = Vector2.new

local function circleScanline(radius, y, offX, offY)
	if radius <= 0 or y - offY < -radius or y - offY > radius then
		return 0,-1
	end
	y = clamp(y - offY, -radius, radius)
	y = floor(y)
	local r = floor(cos(y / radius * pi / 2) * radius + 0.5)
	return offX - r, offX + r
end

local function circleIntersect(radius1, x1, y1, radius2, x2, y2)
	local minY = min(y1 - radius1, y2 - radius2)
	local maxY = max(y1 + radius1, y2 + radius2)

	local added = {}
	local removed = {}
	local addedNum = 0
	local removedNum = 0

	for y = minY, maxY do
		local left1, right1 = circleScanline(radius1, y, x1, y1)
		local left2, right2 = circleScanline(radius2, y, x2, y2)

		if left1 < left2 then
			-- removed from left side
			for i = left1, left2 - 1 do
				removedNum = removedNum + 1
				removed[removedNum] = Vector2new(i, y)
			end
		elseif left2 < left1 then
			-- added to left side
			for i = left2, left1 - 1 do
				addedNum = addedNum + 1
				added[addedNum] = Vector2new(i, y)
			end
		end
		if right1 < right2 then
			--added to right side
			for i = right1 + 1, right2 do
				addedNum = addedNum + 1
				added[addedNum] = Vector2new(i, y)
			end
		elseif right2 < right1 then
			-- removed from right side
			for i = right2 + 1, right1 do
				removedNum = removedNum + 1
				removed[#removed+1] = Vector2new(i, y)
			end
		end
	end

	return added, removed
end

return circleIntersect
