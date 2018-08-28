local function squareDist(x, y, z)
	local xdist = x < 0 and -x or x
	local ydist = y < 0 and -y or y
	local dist = xdist > ydist and xdist or ydist

	return dist
end

return squareDist
