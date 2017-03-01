--[[ Base style ]]--

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

function RCT.FrameStyleBase:OnPlayerAdded(player)
end

function RCT.FrameStyleBase:OnPlayerRemoved(player)
end

function RCT.FrameStyleBase:OnSpellAdded(spell)
end

function RCT.FrameStyleBase:OnSpellRemoved(spell)
end

function RCT.FrameStyleBase:RestoreFrame(frame, parent)
	frame:SetParent(parent)
	frame:Show()
end

function RCT.FrameStyleBase:ResetFrame(frame)
	frame:Hide()
	frame:SetParent(nil)
end

--[[ Categorized list Style ]]--

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

--[[ List style ]]--

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

--[[ Compact List style ]]--

RCT.FrameStyleCompactList = { }
for k, v in pairs(RCT.FrameStyleBase) do RCT.FrameStyleCompactList[k] = v end
RCT.FrameStyleCompactList.__index = RCT.FrameStyleCompactList

setmetatable(RCT.FrameStyleCompactList, {
	__index = RCT.FrameStyleBase,
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.FrameStyleCompactList:new()
	RCT.FrameStyleBase:new()

	self.spellFrames = { }

	self.unusedFrames = { }
	self.numFrames = 0

	self.frame = CreateFrame("Frame", "RCT_CompactListFrame", UIParent)
	self.frame:SetPoint("CENTER", 400, 0) -- Temp
	self.frame:SetWidth(200)
	self.frame:SetHeight(20)
end

function RCT.FrameStyleCompactList:Destroy()
	RCT.FrameStyleBase:Destroy()

	for _, spellFrame in pairs(self.spellFrames) do
		table.insert(self.unusedFrames, spellFrame)
	end

	self.spellFrames = { }
end

function RCT.FrameStyleCompactList:Redraw()
	RCT.FrameStyleBase:Redraw()

	for _, spellFrame in pairs(self.spellFrames) do
		spellFrame:Redraw()
	end
end

function RCT.FrameStyleCompactList:OnSpellAdded(spell)
	RCT.FrameStyleBase:OnSpellAdded()

	if not RCT:TableContainsKey(self.spellFrames, spell) then
		if #self.unusedFrames > 0 then
			self.spellFrames[spell] = self.unusedFrames[1]
			self.spellFrames[spell]:SetSpell(spell)
			RCT.FrameStyleBase:RestoreFrame(self.spellFrames[spell].frame, self.frame)
			table.remove(self.unusedFrames, 1)
		else
			self.spellFrames[spell] = RCT.FrameStyleCompactList.SpellFrame(self, spell)
		end
		
		self:Reorder()
	end
end

function RCT.FrameStyleCompactList:OnSpellRemoved(spell)
	RCT.FrameStyleBase:OnSpellRemoved()

	if RCT:TableContainsKey(self.spellFrames, spell) then
		RCT.FrameStyleBase:ResetFrame(self.spellFrames[spell].frame)
		table.insert(self.unusedFrames, self.spellFrames[spell])

		self.spellFrames[spell] = nil
		self:Reorder()
	end
end

function RCT.FrameStyleCompactList:Reorder()
	local order = { }

	-- Sort alphabetically on player name and spell name
	for _, spellFrame in pairs(self.spellFrames) do
		table.insert(order, spellFrame)
	end
	
	local function SortAlphabetically(lhs, rhs)
		local playerName1 = lhs.spell.player.name
		local playerName2 = rhs.spell.player.name

		if playerName1 < playerName2 then
			return true
		end

		if playerName1 == playerName2 then
			local spellName1 = lhs.spell.spellInfo.name
			local spellName2 = rhs.spell.spellInfo.name

			return spellName1 < spellName2
		end

		return false
	end

	table.sort(order, SortAlphabetically)

	-- Reorder
	local lastSpellFrame = nil
	local totalHeight = 0

	for _, spellFrame in ipairs(order) do
		if lastSpellFrame == nil then
			spellFrame.frame:SetPoint("TOPLEFT", self.frame)
		else
			spellFrame.frame:SetPoint("TOPLEFT", lastSpellFrame.frame, "BOTTOMLEFT", 0, 0)
		end
		
		totalHeight = totalHeight + spellFrame:GetHeight()
		self.frame:SetHeight(totalHeight)

		lastSpellFrame = spellFrame
	end
end

RCT.FrameStyleCompactList.SpellFrame = { }
RCT.FrameStyleCompactList.SpellFrame.__index = RCT.FrameStyleCompactList.SpellFrame

setmetatable(RCT.FrameStyleCompactList.SpellFrame, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.FrameStyleCompactList.SpellFrame:new(list, spell)
	self.frame = CreateFrame("Frame", "$parent_SpellFrame_" .. list.numFrames, list.frame)
	self.frame:SetWidth(list.frame:GetWidth())
	self.frame:SetHeight(self:GetHeight())
	
	self.playerName = self.frame:CreateFontString("$parent_PlayerName", "OVERLAY", "GameFontNormal")
	self.playerName:SetWidth(self.frame:GetWidth() * 0.3)
	self.playerName:SetHeight(self.frame:GetHeight())
	self.playerName:SetPoint("LEFT", self.frame)
	self.playerName:SetJustifyH("LEFT")

	self.spellName = self.frame:CreateFontString("$parent_SpellName", "OVERLAY", "GameFontNormal")
	self.spellName:SetWidth(self.frame:GetWidth() * 0.5)
	self.spellName:SetHeight(self.frame:GetHeight())
	self.spellName:SetPoint("LEFT", self.playerName, "RIGHT", 3, 0)
	self.spellName:SetJustifyH("LEFT")

	self.cooldown = self.frame:CreateFontString("$parent_CooldownText", "OVERLAY", "GameFontNormal")
	self.cooldown:SetWidth(self.frame:GetWidth() * 0.2)
	self.cooldown:SetHeight(self.frame:GetHeight())
	self.cooldown:SetPoint("RIGHT", self.frame, "RIGHT")
	self.cooldown:SetJustifyH("RIGHT")

	self:SetSpell(spell)
end

function RCT.FrameStyleCompactList.SpellFrame:Redraw()
	local currentTime = GetTime()

	if self.spell.activeEndTimestamp > currentTime then
		local activeEnd = self.spell.activeEndTimestamp
		self.cooldown:SetTextColor(1, 1, 0, 1)
		self.cooldown:SetText(RCT:FormatTimeString(activeEnd - currentTime))
	elseif self.spell.cooldownEndTimestamp > currentTime then
		local cooldownEnd = self.spell.cooldownEndTimestamp
		self.cooldown:SetTextColor(1, 0, 0, 1)
		self.cooldown:SetText(RCT:FormatTimeString(cooldownEnd - currentTime))
	else
		self.cooldown:SetTextColor(0, 1, 0, 1)
		self.cooldown:SetText("Ready")
	end
end



function RCT.FrameStyleCompactList.SpellFrame:SetSpell(spell)
	self.spell = spell

	local classColor = RAID_CLASS_COLORS[spell.player.class]

	self.playerName:SetText(spell.player.name)
	self.playerName:SetTextColor(classColor.r, classColor.g, classColor.b, 1)

	self.spellName:SetText(spell.spellInfo.name)
	self.spellName:SetTextColor(classColor.r, classColor.g, classColor.b, 1)

	self.cooldown:SetTextColor(0, 1, 0, 1)
	self.cooldown:SetText("Ready")
end

function RCT.FrameStyleCompactList.SpellFrame:GetHeight()
	return 20
end

