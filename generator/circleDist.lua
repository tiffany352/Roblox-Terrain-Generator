local sqrt = math.sqrt

local function circleDist(x, y)
	return sqrt(x*x + y*y)
end

return circleDist
