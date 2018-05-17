local floor = math.floor

local function lessThan(a, b)
	return a < b
end

local Heap = {}
Heap.__index = Heap

function Heap.new(compare, array)
	local self = {
		array = {},
		compare = compare or lessThan,
	}
	setmetatable(self, Heap)

	if array then
		self:build(array)
	end

	return self
end

-- O(log N)
function Heap:insert(value)
	local arr = self.array
	local cmp = self.compare

	local index = #self.array + 1
	arr[index] = value

	while index > 1 do
		local parent = floor(index / 2)
		if cmp(arr[index], arr[parent]) then
			-- index < parent, swap
			arr[index], arr[parent] = arr[parent], arr[index]
			index = parent
		else
			break
		end
	end
end

-- O(1)
function Heap:peekMin()
	return self.array[1]
end

local function heapify(arr, cmp, index)
	local left = index * 2
	local right = index * 2 + 1
	while true do
		local smallest = left
		if arr[left] and arr[right] and cmp(arr[right], arr[left]) then
			smallest = right
		end

		if arr[smallest] and cmp(arr[smallest], arr[index]) then
			-- smallest < parent, swap
			arr[index], arr[smallest] = arr[smallest], arr[index]
			index = smallest
			left = index * 2
			right = index * 2 + 1
		else
			break
		end
	end
end

-- O(log N)
function Heap:extractMin()
	local arr = self.array

	local result
	-- shuffle everything leftward
	result, arr[1], arr[#arr] = arr[1], arr[#arr], nil

	heapify(arr, self.compare, 1)

	return result
end

-- O(N)
function Heap:build(arr)
	arr = arr or self.array
	local cmp = self.compare

	self.array = arr

	for i = floor(#arr / 2), 1, -1 do
		heapify(arr, cmp, i)
	end
end

return Heap
