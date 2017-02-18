-- Get addon object
if not RCT then return end
local RCT = RCT

-- Libraries
local LGIST = LibStub("LibGroupInSpecT-1.1")
local AceDB = LibStub("AceDB-3.0")

RCT.players = { }
RCT.frameManager = nil

--[[ Player class ]]--

RCT.Player = { }
RCT.Player.__index = RCT.Player

setmetatable(RCT.Player, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.Player:new(guid, info)
	self.guid = guid
	self.name = info.name
	self.unit = info.lku
	self.class = info.class
	self.spec = info.global_spec_id
	self.level = UnitLevel(info.lku)
	self.initialized = false
	self.talents = RCT:ConstructTalentTable(info.talents)
	self.spells = { }

	RCT.players[guid] = self
	RCT.frameManager:OnPlayerAdded(self)
end

function RCT.Player:Destroy()
	for _, spell in pairs(self.spells) do
		spell:Destroy()
	end

	RCT.players[self.guid] = nil
	RCT.frameManager:OnPlayerRemoved(self)
end

function RCT.Player:Update(info)
	-- Wait until the info has been fully initialized
	if info.name == nil then return end
	if info.class == nil then return end
	if info.global_spec_id == nil then return end
	if info.global_spec_id == 0 then return end
	if info.lku == nil then return end
	if info.talents == nil then return end

	-- Default to being dirty so spells are initialized at least once
	local dirty = true

	if self.initialized then
		dirt = false

		-- Check if level up
		if UnitLevel(info.lku) ~= self.level then
			dirty = true
		-- Check if spec switch
		elseif info.global_spec_id ~= self.spec then
			dirty = true
		-- Check if talent change
		else
			local newTalents = RCT:ConstructTalentTable(info.talents)

			for talentId, _ in pairs(newTalents) do
				if not RCT:TableContainsKey(self.talents, talentId) then
					dirty = true
					break
				end
			end
		end
	end

	self.name = info.name
	self.unit = info.lku
	self.class = info.class
	self.spec = info.global_spec_id
	self.level = UnitLevel(self.unit)
	self.talents = RCT:ConstructTalentTable(info.talents)
	self.initialized = true

	if dirty then
		self:Reload()
	end
end

function RCT.Player:Reload()
	if not self.initialized then return end

	local availableSpells = RCT.spellDB[self.class][self.spec]
	local newSpells = { }

	-- Remove uncastable spells
	for spellId, _ in pairs(availableSpells) do
		if RCT:CanPlayerCastSpell(self, spellId) then
			table.insert(newSpells, spellId)
		end
	end

	-- Remove old spells
	for spellId, _ in pairs(self.spells) do
		if not RCT:TableContains(newSpells, spellId) then
			self:RemoveSpell(spellId)
		end
	end

	-- Add new spells
	for _, spellId in ipairs(newSpells) do
		if not RCT:TableContainsKey(self.spells, spellId) then
			self:AddSpell(spellId)
		end
	end
end

function RCT.Player:AddSpell(spellId)
	if self:GetSpellById(spellId) ~= nil then
		return nil
	end
	
	self.spells[spellId] = RCT.Spell(self, spellId)
	return self.spells[spellId]
end

function RCT.Player:RemoveSpell(spellId)
	if self:GetSpellById(spellId) == nil then
		return
	end
	
	self.spells[spellId]:Destroy()
	self.spells[spellId] = nil
end

function RCT.Player:IsInitialized()
	return self.initialized
end

function RCT.Player:GetSpells()
	local result = { }

	for _, spell in pairs(self.spells) do
		table.insert(result, spell)
	end

	return result
end

function RCT.Player:GetTalents()
	return self.talents
end

function RCT.Player:GetSpellById(spellId)
	for id, spell in pairs(self.spells) do
		if id == spellId then
			return spell
		end
	end

	return nil
end

function RCT.Player:GetName()
	return self.name
end

function RCT.Player:GetUnitId()
	return self.unit
end

function RCT.Player:GetClass()
	return self.class
end

function RCT.Player:GetSpec()
	return self.spec
end

function RCT.Player:GetLevel()
	return self.level
end

--[[ Spell class ]]--

RCT.Spell = { }
RCT.Spell.__index = RCT.Spell

setmetatable(RCT.Spell, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.Spell:new(player, spellId)
	self.player = player
	self.spellId = spellId	
	self.spellInfo = RCT:GetSpellInfo(player:GetClass(), player:GetSpec(), spellId)
	self.lastCastTimestamp = 0
	self.cooldownEndTimestamp = 0
	self.activeEndTimestamp = 0

	RCT.frameManager:OnSpellAdded(self)
end

function RCT.Spell:Destroy()
	RCT.frameManager:OnSpellRemoved(self)
end

function RCT.Spell:Reset()
	self.lastCastTimestamp = 0
	self.cooldownEndTimestamp = 0
	self.activeEndTimestamp = 0
end

function RCT.Spell:OnCast(timestamp)
	self.lastCastTimestamp = timestamp
	self.cooldownEndTimestamp = timestamp + self:GetCooldown()
	self.activeEndTimestamp = timestamp + self:GetDuration()

	print(self:GetPlayer():GetName() .. " cast: " .. self:GetSpellInfo().name)
end

function RCT.Spell:GetDuration()
	local spellInfo = self:GetSpellInfo()

	if spellInfo.duration ~= nil then
		if spellInfo.modifiers ~= nil and spellInfo.modifiers.duration ~= nil then
			return spellInfo.modifiers.duration(self:GetPlayer(), spellInfo)
		end

		return spellInfo.duration
	end

	return 0
end

function RCT.Spell:GetCooldown()
	local spellInfo = self:GetSpellInfo()

	if spellInfo.cooldown ~= nil then
		if spellInfo.modifiers ~= nil and spellInfo.modifiers.cooldown ~= nil then
			return spellInfo.modifiers.cooldown(self:GetPlayer(), spellInfo)
		end

		return spellInfo.cooldown
	end

	return 0
end

function RCT.Spell:GetPlayer()
	return self.player
end

function RCT.Spell:GetSpellId()
	return self.spellId
end

function RCT.Spell:GetSpellInfo()
	return self.spellInfo
end

function RCT.Spell:GetLastCastTime()
	return self.lastCastTimestamp
end

function RCT.Spell:GetCooldownEndTime()
	return self.cooldownEndTimestamp
end

function RCT.Spell:GetActiveEndTime()
	return self.activeEndTimestamp
end

--[[ Frame manager class ]]--

RCT.FrameManager = { }
RCT.FrameManager.__index = RCT.FrameManager

setmetatable(RCT.FrameManager, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.FrameManager:new()
	self.style = nil

	self.addedPlayers = { }
	self.removedPlayers = { }

	self.addedSpells = { }
	self.removedSpells = { }
end

function RCT.FrameManager:Update()
	if self.style == nil then
		return
	end

	-- Remove
	for _, spell in ipairs(self.removedSpells) do
		self.style:OnSpellRemoved(spell)
	end

	for _, player in ipairs(self.removedPlayers) do
		self.style:OnPlayerRemoved(player)
	end

	self.removedSpells = { }
	self.removedPlayers = { }

	-- Add
	local spellsNotAdded = { }
	local playersNotAdded = { }

	for _, player in ipairs(self.addedPlayers) do
		if player:IsInitialized() then
			self.style:OnPlayerAdded(player)
		else
			table.insert(playersNotAdded, player)
		end
	end

	for _, spell in ipairs(self.addedSpells) do
		if spell:GetPlayer():IsInitialized() then
			self.style:OnSpellAdded(spell)
		else
			table.insert(spellsNotAdded, spell)
		end
	end

	self.addedSpells = spellsNotAdded
	self.addedPlayers = playersNotAdded

	-- Redraw
	self.style:Redraw()
end

function RCT.FrameManager:OnPlayerAdded(player)
	if RCT:TableContains(self.addedPlayers, player) or RCT:TableContains(self.removedPlayers, player) then
		return
	end

	table.insert(self.addedPlayers, player)
end

function RCT.FrameManager:OnPlayerRemoved(player)
	if RCT:TableContains(self.addedPlayers, player) or RCT:TableContains(self.removedPlayers, player) then
		return
	end

	table.insert(self.removedPlayers, player)
end

function RCT.FrameManager:OnSpellAdded(spell)
	if RCT:TableContains(self.addedSpells, spell) or RCT:TableContains(self.removedSpells, spell) then
		return
	end

	table.insert(self.addedSpells, spell)
end

function RCT.FrameManager:OnSpellRemoved(spell)
	if RCT:TableContains(self.addedSpells, spell) or RCT:TableContains(self.removedSpells, spell) then
		return
	end

	table.insert(self.removedSpells, spell)
end

function RCT.FrameManager:SetStyle(style)
	if self.style ~= nil then
		self.style:Destroy()
		self.style = nil
	end

	self.style = style()

	for _, player in pairs(RCT.players) do
		self.style:OnPlayerAdded(player)
		
		local spells = player:GetSpells()
		for _, spell in spells do
			self.style.OnSpellAdded(spell)
		end
	end
end

--[[ Initialization ]]--

function RCT:OnInitialize()
	RCT:InitializeSpells()
	RCT.frameManager = RCT.FrameManager()
	RCT.frameManager:SetStyle(RCT.FrameStyleCompactList)

	LGIST.RegisterCallback(self, "GroupInSpecT_Update", "OnUnitUpdated")
	LGIST.RegisterCallback(self, "GroupInSpecT_Remove", "OnUnitRemoved")

	RCT:RegisterEvent("ENCOUNTER_END")
	RCT:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	RCT:RegisterChatCommand("RCT", "SlashProcessor")

	RCT:ScheduleRepeatingTimer("UpdateFrames", 1)
end

function RCT:InitializeSpells()
	for className, class in pairs(RCT.spellDB) do
		for specName, spec in pairs(class) do
			for spellId, spell in pairs(spec) do
				local name, _, icon = GetSpellInfo(spellId)
				
				spell.name = name
				spell.icon = icon
				spell.spellId = spellId
			end
		end
	end
end

--[[ LibGroupInSpecT callbacks ]]--

function RCT:OnUnitUpdated(evt, guid, unitId, info)
	local player = RCT:GetPlayerByGUID(guid)

	if player == nil then
		player = RCT.Player(guid, info)
	end

	player:Update(info)
end

function RCT:OnUnitRemoved(evt, guid)
	local player = RCT:GetPlayerByGUID(guid)

	if player ~= nil then
		player:Destroy()
	end
end

--[[ Callbacks ]]--

function RCT:ENCOUNTER_END(evt, encounterId, encounterName, difficultyId, groupSize, success)
	if groupSize < 10 then
		return
	end

	for _, player in pairs(RCT.players) do
		local spells = player:GetSpells()

		for _, spell in ipairs(spells) do
			spell:Reset()
		end
	end
end

function RCT:COMBAT_LOG_EVENT_UNFILTERED(evt, ...)
	if evt == "COMBAT_LOG_EVENT_UNFILTERED" then
		local type, _, guid = select(2, ...)

		if type == "SPELL_CAST_SUCCESS" then
			local player = RCT:GetPlayerByGUID(guid)

			if player ~= nil then
				local spellId = select(12, ...)
				local spell = player:GetSpellById(spellId)

				if spell ~= nil then
					spell:OnCast(GetTime())
				end
			end
		end
	end
end

function RCT:UpdateFrames()
	RCT.frameManager:Update()
end

--[[ Helper functions ]]--

function RCT:GetPlayerByGUID(guid)
	return RCT.players[guid]
end

function RCT:GetSpellInfo(class, spec, spellId)
	return RCT.spellDB[class][spec][spellId]
end

function RCT:CanPlayerCastSpell(player, spellId)
	local spellInfo = RCT:GetSpellInfo(player:GetClass(), player:GetSpec(), spellId)

	if player:GetLevel() < spellInfo.level then
		return false
	end

	if spellInfo.talents ~= nil then
		local hasTalent = false

		for _, talent in ipairs(spellInfo.talents) do
			if RCT:PlayerHasTalentSelected(player, talent.tier, talent.column) then
				hasTalent = true
				break
			end
		end

		if not hasTalent then
			return false
		end
	end

	return true
end

function RCT:PlayerHasTalentSelected(player, tier, column)
	for _, talent in pairs(player:GetTalents()) do
		if talent.tier == tier and talent.column == column then
			return true
		end
	end
end

function RCT:ConstructTalentTable(talents)
	local result = { }

	for talentId, talent in pairs(talents) do
		result[talentId] = { tier = talent.tier, column = talent.column }
	end

	return result
end

function RCT:TableContainsKey(table, value)
	for k, _ in pairs(table) do
        if k == value then
            return true
        end
    end

    return false
end

function RCT:TableContains(table, value)
	for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end

    return false
end
