RCT.FrameStyleCategorizedList = { }
for k, v in pairs(RCT.FrameStyleBase) do RCT.FrameStyleCategorizedList[k] = v end
RCT.FrameStyleCategorizedList.__index = RCT.FrameStyleCategorizedList

setmetatable(RCT.FrameStyleCategorizedList, {
	__index = RCT.FrameStyleBase,
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.FrameStyleCategorizedList:new()
	RCT.FrameStyleBase:new()
end

function RCT.FrameStyleCategorizedList:Destroy()
	RCT.FrameStyleBase:Destroy()
end

function RCT.FrameStyleCategorizedList:Redraw()
	RCT.FrameStyleBase:Redraw()
end

function RCT.FrameStyleCategorizedList:OnPlayerAdded(player)
	RCT.FrameStyleBase:OnPlayerAdded()
end

function RCT.FrameStyleCategorizedList:OnPlayerRemoved(player)
	RCT.FrameStyleBase:OnPlayerRemoved()
end

function RCT.FrameStyleCategorizedList:OnSpellAdded(spell)
	RCT.FrameStyleBase:OnSpellAdded()
end

function RCT.FrameStyleCategorizedList:OnSpellRemoved(spell)
	RCT.FrameStyleBase:OnSpellRemoved()
end
