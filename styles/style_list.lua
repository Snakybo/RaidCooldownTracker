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

function RCT.FrameStyleList:AddPlayer(player)
	RCT.FrameStyleBase:AddPlayer()
end

function RCT.FrameStyleList:RemovePlayer(player)
	RCT.FrameStyleBase:RemovePlayer()
end

function RCT.FrameStyleList:AddSpell(spell)
	RCT.FrameStyleBase:AddSpell()
end

function RCT.FrameStyleList:RemoveSpell(spell)
	RCT.FrameStyleBase:RemoveSpell()
end
