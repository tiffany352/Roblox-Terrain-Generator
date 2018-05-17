local Modules = script.Parent.Parent
local Roact = require(Modules.Roact)
local RoactStudioWidgets = require(Modules.RoactStudioWidgets)

-- props:
-- string propertyName
-- float value
-- float minValue
-- float maxValue
-- float steps
-- bool logarithmic
-- function<float> setValue
local function SliderProperty(props)
	local max = props.maxValue or 1.0
	if props.logarithmic then
		max = math.log(max) / math.log(2)
	end

	local function map(value)
		local result = value

		if props.logarithmic then
			result = math.log(result) / math.log(2)
		end

		result = result / max

		return result
	end

	local function unmap(value)
		local result = value * max

		if props.steps then
			result = math.floor(result / props.steps) * props.steps
		end

		if props.logarithmic then
			result = math.pow(2, result)
		end

		result = math.clamp(result, props.minValue or -math.huge, props.maxValue or math.huge)

		return result
	end

	return Roact.createElement(RoactStudioWidgets.Property, {
		LayoutOrder = props.LayoutOrder,
		propertyName = props.propertyName,
	}, {
		Slider = Roact.createElement(RoactStudioWidgets.Slider, {
			Size = UDim2.new(1, 0, 0, 24),
			value = map(props.value),
			setValue = function(value)
				value = unmap(value)
				if props.setValue then
					props.setValue(value)
				end
			end
		}),
	})
end

return SliderProperty
