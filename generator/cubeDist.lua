local max = math.max

local function cubeDist(x, y, z)
	local xdist = x < 0 and -x or x
	local ydist = y < 0 and -y or y
	local zdist = z < 0 and -z or z
	local dist = max(xdist, max(ydist, zdist))

	return dist
end

return cubeDist
