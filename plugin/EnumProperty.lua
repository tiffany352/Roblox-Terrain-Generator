local Modules = script.Parent.Parent
local Roact = require(Modules.Roact)
local RoactStudioWidgets = require(Modules.RoactStudioWidgets)

-- props:
-- string propertyName
-- variant value
-- dict<variant, string> variants
-- function<variant> setValue
local function EnumProperty(props)
	local variantsMap = props.variants
	local variants = {}
	for key, value in pairs(variantsMap) do
		variants[#variants+1] = {
			id = key,
			text = value,
		}
	end
	table.sort(variants, function(a,b) return a.text < b.text end)
	local buttons = {}
	for i = 1, #variants do
		buttons[i] = variants[i].text
	end
	local selected
	for i = 1, #variants do
		if variants[i].id == props.value then
			selected = i
			break
		end
	end

	return Roact.createElement(RoactStudioWidgets.Property, {
		LayoutOrder = props.LayoutOrder,
		propertyName = props.propertyName,
	}, {
		Buttons = Roact.createElement(RoactStudioWidgets.RadioButtons, {
			buttons = buttons,
			selected = selected,
			onSelect = function(i, _button)
				props.setValue(variants[i].id)
			end
		}),
	})
end

return EnumProperty
