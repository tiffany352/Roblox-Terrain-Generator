local Array3D = {}
Array3D.__index = Array3D

function Array3D.new(size, fillValue, offset)
	local self = {
		size = size,
		offset = offset or Vector3.new(1, 1, 1),
	}
	local sizeY, sizeZ = size.Y, size.Z
	local sizeYZ = sizeY * sizeZ
	local offsetX, offsetY, offsetZ = self.offset.X, self.offset.Y, self.offset.Z
	function self.getFast(x, y, z)
		x = x - offsetX
		y = y - offsetY
		z = z - offsetZ
		return self[x*sizeYZ + y*sizeZ + z]
	end
	function self.setFast(x, y, z, value)
		x = x - offsetX
		y = y - offsetY
		z = z - offsetZ
		self[x*sizeYZ + y*sizeZ + z] = value
	end
	setmetatable(self, Array3D)

	if fillValue then
		for i = 1, size.x*size.y*size.z do
			self[i] = fillValue
		end
	end

	return self
end

function Array3D:get(pos)
	local size = self.size
	local offset = self.offset
	if offset then
		pos = pos - offset
	end
	return self[pos.x*size.y*size.z + pos.y*size.z + pos.z]
end

function Array3D:set(pos, value)
	local size = self.size
	local offset = self.offset
	if offset then
		pos = pos - offset
	end
	self[pos.x*size.y*size.z + pos.y*size.z + pos.z] = value
end

return Array3D
