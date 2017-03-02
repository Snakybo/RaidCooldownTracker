RCT.FrameStyleBase = { }
RCT.FrameStyleBase.__index = RCT.FrameStyleBase

setmetatable(RCT.FrameStyleBase, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.FrameStyleBase:new()
end

function RCT.FrameStyleBase:Destroy()
end

function RCT.FrameStyleBase:Redraw()
end

function RCT.FrameStyleBase:AddPlayer(player)
end

function RCT.FrameStyleBase:RemovePlayer(player)
end

function RCT.FrameStyleBase:AddSpell(spell)
end

function RCT.FrameStyleBase:RemoveSpell(spell)
end

function RCT.FrameStyleBase:RestoreFrame(frame, parent)
	frame:SetParent(parent)
	frame:Show()
end

function RCT.FrameStyleBase:ResetFrame(frame)
	frame:Hide()
	frame:SetParent(nil)
end
