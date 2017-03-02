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

function RCT.FrameStyleCategorizedList:AddPlayer(player)
	RCT.FrameStyleBase:AddPlayer()
end

function RCT.FrameStyleCategorizedList:RemovePlayer(player)
	RCT.FrameStyleBase:RemovePlayer()
end

function RCT.FrameStyleCategorizedList:AddSpell(spell)
	RCT.FrameStyleBase:AddSpell()
end

function RCT.FrameStyleCategorizedList:RemoveSpell(spell)
	RCT.FrameStyleBase:RemoveSpell()
end
