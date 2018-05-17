local Selection = game:GetService("Selection")

local Modules = script.Parent.Parent
local Roact = require(Modules.Roact)
local RoactStudioWidgets = require(Modules.RoactStudioWidgets)
local GeneratorService = require(script.Parent.GeneratorService)
local EnumProperty = require(script.Parent.EnumProperty)
local SliderProperty = require(script.Parent.SliderProperty)

local pluginGui = plugin:CreateDockWidgetPluginGui("TerrainPlugin", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Left, false))
pluginGui.Name = "TerrainPlugin"
pluginGui.Title = "Terrain Generator"

local toolbar = plugin:CreateToolbar("Terrain")
local button = toolbar:CreateButton("Generator", "", "")

button.Click:Connect(function()
	pluginGui.Enabled = not pluginGui.Enabled
end)

local generatorService = GeneratorService.new()

local ManagerType = Roact.PureComponent:extend("ManagerType")

function ManagerType:render()
	return Roact.createElement(RoactStudioWidgets.Property, {
		propertyName = "Chunk manager type",
	}, {
		Buttons = Roact.createElement(RoactStudioWidgets.RadioButtons, {
			buttons = {
				"2D chunks",
				"3D chunks",
			},
			selected = self.state.selected,
			onSelect = function(i, button)
				self:setState({
					selected = i,
				})
			end
		}),
	})
end

local element = Roact.createElement(GeneratorService.Provider, {
	GeneratorService = generatorService,
}, {
	TerrainPlugin = Roact.createElement(GeneratorService.Accessor, {
		render = function(generatorService)
			return Roact.createElement("Folder", {}, {
				SdkScreen = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1.0,
					Visible = generatorService.sdk == nil,
				}, {
					Section = Roact.createElement(RoactStudioWidgets.Section, {
						titleText = "Select SDK location",
					}, {
						SdkProperty = Roact.createElement(RoactStudioWidgets.Property, {
							propertyName = "Select the location in Explorer",
						}, {
							Container = Roact.createElement(RoactStudioWidgets.FitChildren.Frame, {
								Size = UDim2.new(1, 0, 0, 0),
								BackgroundTransparency = 1.0,
							}, {
								UIPadding = Roact.createElement("UIPadding", {
									PaddingLeft = UDim.new(0, 4),
									PaddingRight = UDim.new(0, 4),
									PaddingTop = UDim.new(0, 4),
									PaddingBottom = UDim.new(0, 4),
								}),
								UIListLayout = Roact.createElement("UIListLayout"),
								Button = Roact.createElement(RoactStudioWidgets.Button, {
									labelText = "Set SDK to selection",
									onClick = function()
										local sel = Selection:Get()
										if #sel == 1 and sel[1].ClassName == 'Folder' then
											generatorService:setSdk(sel[1])
										end
									end,
								}),
							})
						})
					})
				}),
				MainScreen = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1.0,
					Visible = generatorService.sdk ~= nil,
				}, {
					GlobalSettings = Roact.createElement(RoactStudioWidgets.Section, {
						titleText = "Global Settings",
					}, {
						UIListLayout = Roact.createElement("UIListLayout"),
						ManagerType = Roact.createElement(EnumProperty, {
							LayoutOrder = 1,
							propertyName = "Chunk manager type",
							variants = {
								['2D'] = "2D chunks",
								['3D'] = "3D chunks",
							},
							value = generatorService.managerType,
							setValue = function(value)
								generatorService:setManagerType(value)
							end,
						}),
						ChunkType = Roact.createElement(EnumProperty, {
							LayoutOrder = 2,
							propertyName = "Terrain type",
							variants = {
								['Smooth'] = "Roblox Smooth Terrain",
							},
							value = generatorService.chunkType,
							setValue = function(value)
								generatorService:setChunkType(value)
							end,
						}),
						SampleFrequency = Roact.createElement(SliderProperty, {
							LayoutOrder = 3,
							propertyName = "Sample frequency",
							minValue = 4,
							maxValue = 128,
							steps = 1,
							logarithmic = true,
							value = generatorService.sampler.frequency,
							setValue = function(value)
								print("setValue",value)
								generatorService:setSampleFrequency(value)
							end,
						})
					})
				})
			})
		end,
	})
})

Roact.mount(element, pluginGui, "TerrainPlugin")
