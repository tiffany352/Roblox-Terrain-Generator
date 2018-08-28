local Modules = script.Parent.Parent
local Roact = require(Modules.Roact)
local Signal = require(script.Parent.Signal)

local GeneratorService = {}
GeneratorService.__index = GeneratorService

function GeneratorService.new()
	local self = {
		changed = Signal.new(),
		sampler = {
			frequency = 4,
		},
		sdk = nil,
	}
	setmetatable(self, GeneratorService)

	function self.sampler:sample(pos)
		return
			math.sin(pos.x / 50) * 20 +
			math.cos(pos.z / 50) * 20 +
			-pos.y +
			100
	end

	return self
end

function GeneratorService:_update()
	if self._updatePending then return end
	self._updatePending = true
	spawn(function()
		self._updatePending = false
		self.changed:fire()
	end)
end

function GeneratorService:setSdk(sdk)
	if self.sdk ~= sdk then
		self.sdk = sdk
		self:setChunkType('Smooth')
		self:setManagerType('2D')
		self:_update()
	end
end

function GeneratorService:_rebuildManager()
	if self.loader then
		self.loader:destroy()
	end
	if self.manager then
		self.manager:destroy()
	end
	local ChunkManager = require(self.sdk.ChunkManager)
	self.manager = ChunkManager.new(self.sampler, self.chunkClass)

	if self.managerType == '2D' then
		local ChunkLoader2D = require(self.sdk.ChunkLoader2D)
		self.loader = ChunkLoader2D.new(self.manager)
	elseif self.managerType == '3D' then
		local ChunkLoader3D = require(self.sdk.ChunkLoader3D)
		self.loader = ChunkLoader3D.new(self.manager)
	end
end

function GeneratorService:setChunkType(type)
	if self.chunkType ~= type then
		self.chunkType = type
		if type == 'Smooth' then
			local SmoothChunk = require(self.sdk.SmoothChunk)
			self.chunkClass = SmoothChunk
		end
		self:_rebuildManager()
		self:_update()
	end
end

function GeneratorService:setSampleFrequency(frequency)
	if self.sampler.frequency ~= frequency then
		self.sampler.frequency = frequency
		self:_rebuildManager()
		self:_update()
	end
end

function GeneratorService:setManagerType(type)
	if self.managerType ~= type then
		self.managerType = type
		self:_rebuildManager()
		self:_update()
	end
end

GeneratorService.serviceKey = {}

GeneratorService.Provider = Roact.PureComponent:extend("GeneratorServiceProvider")
function GeneratorService.Provider:init(props)
	self._context[GeneratorService.serviceKey] = props.GeneratorService
end

function GeneratorService.Provider:render()
	return Roact.oneChild(self.props[Roact.Children])
end

GeneratorService.Accessor = Roact.PureComponent:extend("GeneratorServiceAccessor")
function GeneratorService.Accessor:didMount()
	self.changedConnection = self._context[GeneratorService.serviceKey].changed:connect(function()
		-- lazy way to force a re-render
		self:setState({
			token = {},
		})
	end)
end
function GeneratorService.Accessor:willUnmount()
	self.changedConnection:disconnect()
end
function GeneratorService.Accessor:render()
	return self.props.render(self._context[GeneratorService.serviceKey])
end

return GeneratorService
