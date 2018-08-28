local function sortedInsert(array, value, lessThan)
	if #array == 0 then
		array[1] = value
		return
	end
	local start = 1
	local stop = #array

	while stop >= start do
		local pivot = math.floor(start + (stop - start) / 2)
		if lessThan(value, array[pivot]) then
			stop = pivot - 1
		else
			start = pivot + 1
		end
	end

	table.insert(array, stop + 1, value)
end

return sortedInsert
