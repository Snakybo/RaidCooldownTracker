RCT.FrameStyleList = { }
for k, v in pairs(RCT.FrameStyleBase) do RCT.FrameStyleList[k] = v end
RCT.FrameStyleList.__index = RCT.FrameStyleList

setmetatable(RCT.FrameStyleList, {
	__index = RCT.FrameStyleBase,
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.FrameStyleList:new()
	RCT.FrameStyleBase:new()
end

function RCT.FrameStyleList:Destroy()
	RCT.FrameStyleBase:Destroy()
end

function RCT.FrameStyleList:Redraw()
	RCT.FrameStyleBase:Redraw()
end

function RCT.FrameStyleList:OnPlayerAdded(player)
	RCT.FrameStyleBase:OnPlayerAdded()
end

function RCT.FrameStyleList:OnPlayerRemoved(player)
	RCT.FrameStyleBase:OnPlayerRemoved()
end

function RCT.FrameStyleList:OnSpellAdded(spell)
	RCT.FrameStyleBase:OnSpellAdded()
end

function RCT.FrameStyleList:OnSpellRemoved(spell)
	RCT.FrameStyleBase:OnSpellRemoved()
end
