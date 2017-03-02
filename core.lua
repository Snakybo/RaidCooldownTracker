-- Get addon object
if not RCT then return end
local RCT = RCT

-- Libraries
local LGIST = LibStub("LibGroupInSpecT-1.1")
local AceDB = LibStub("AceDB-3.0")

-- Events
RCT.EVENT_PLAYER_ADDED = "PLAYER_ADDED"
RCT.EVENT_PLAYER_REMOVED = "PLAYER_REMOVED"
RCT.EVENT_SPELL_ADDED = "SPELL_ADDDED"
RCT.EVENT_SPELL_REMOVED = "SPELL_REMOVED"

RCT.players = { }

RCT.frameManager = nil
RCT.database = nil

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
	RCT:SendMessage(RCT.EVENT_PLAYER_ADDED, self)
end

function RCT.Player:Destroy()
	for _, spell in pairs(self.spells) do
		spell:Destroy()
	end

	RCT.players[self.guid] = nil
	RCT:SendMessage(RCT.EVENT_PLAYER_REMOVED, self)
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

	-- Remove uncastable and hidden spells
	for spellId, _ in pairs(availableSpells) do
		if self:CanCastSpell(spellId) and RCT.database:IsSpellVisible(self.class, self.spec, spellId) then
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

function RCT.Player:CanCastSpell(spellId)
	local spellInfo = RCT:GetSpellInfo(self.class, self.spec, spellId)

	if self.level < (spellInfo.level or 1) then
		return false
	end

	if spellInfo.talents ~= nil then
		local hasTalent = false

		for _, talent in ipairs(spellInfo.talents) do
			if self:HasTalentSelected(talent.tier, talent.column) then
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

function RCT.Player:HasTalentSelected(tier, column)
	for _, talent in pairs(self.talents) do
		if talent.tier == tier and talent.column == column then
			return true
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

function RCT.Player:GetSpells()
	local result = { }

	for _, spell in pairs(self.spells) do
		table.insert(result, spell)
	end

	return result
end

function RCT.Player:GetSpellById(spellId)
	for id, spell in pairs(self.spells) do
		if id == spellId then
			return spell
		end
	end

	return nil
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
	self.spellInfo = RCT:GetSpellInfo(player.class, player.spec, spellId)
	self.lastCastTimestamp = 0
	self.cooldownEndTimestamp = 0
	self.activeEndTimestamp = 0

	RCT:SendMessage(RCT.EVENT_SPELL_ADDED, self)
end

function RCT.Spell:Destroy()
	RCT:SendMessage(RCT.EVENT_SPELL_REMOVED, self)
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
end

function RCT.Spell:GetDuration()
	local spellInfo = self.spellInfo

	if spellInfo.duration ~= nil then
		if spellInfo.modifiers ~= nil and spellInfo.modifiers.duration ~= nil then
			return spellInfo.modifiers.duration(self.player, spellInfo)
		end

		return spellInfo.duration
	end

	return 0
end

function RCT.Spell:GetCooldown()
	local spellInfo = self.spellInfo

	if spellInfo.cooldown ~= nil then
		if spellInfo.modifiers ~= nil and spellInfo.modifiers.cooldown ~= nil then
			return spellInfo.modifiers.cooldown(self.player, spellInfo)
		end

		return spellInfo.cooldown
	end

	return 0
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

	RCT:RegisterMessage(RCT.EVENT_PLAYER_ADDED, self.EventHandler, self)
	RCT:RegisterMessage(RCT.EVENT_PLAYER_REMOVED, self.EventHandler, self)
	RCT:RegisterMessage(RCT.EVENT_SPELL_ADDED, self.EventHandler, self)
	RCT:RegisterMessage(RCT.EVENT_SPELL_REMOVED, self.EventHandler, self)
end

function RCT.FrameManager:Update()
	if self.style == nil then
		return
	end

	-- Remove
	for _, spell in ipairs(self.removedSpells) do
		self.style:RemoveSpell(spell)
	end

	for _, player in ipairs(self.removedPlayers) do
		self.style:RemovePlayer(player)
	end

	self.removedSpells = { }
	self.removedPlayers = { }

	-- Add
	local spellsNotAdded = { }
	local playersNotAdded = { }

	for _, player in ipairs(self.addedPlayers) do
		if player.initialized then
			self.style:AddPlayer(player)
		else
			table.insert(playersNotAdded, player)
		end
	end

	for _, spell in ipairs(self.addedSpells) do
		if spell.player.initialized then
			self.style:AddSpell(spell)
		else
			table.insert(spellsNotAdded, spell)
		end
	end

	self.addedSpells = spellsNotAdded
	self.addedPlayers = playersNotAdded

	-- Redraw
	self.style:Redraw()
end

function RCT.FrameManager:SetStyle(style)
	if self.style ~= nil then
		self.style:Destroy()
		self.style = nil
	end

	self.style = style()

	for _, player in pairs(RCT.players) do
		self.style:AddPlayer(player)
		
		local spells = player:GetSpells()
		for _, spell in spells do
			self.style.AddSpell(spell)
		end
	end
end

function RCT.FrameManager.EventHandler(self, evt, arg)
	if RCT:TableContains(self.addedPlayers, arg) or RCT:TableContains(self.removedPlayers, arg) then
		return
	end

	if RCT:TableContains(self.addedSpells, arg) or RCT:TableContains(self.removedSpells, arg) then
		return
	end

	if evt == RCT.EVENT_PLAYER_ADDED then
		table.insert(self.addedPlayers, arg)
	elseif evt == RCT.EVENT_PLAYER_REMOVED then
		table.insert(self.removedPlayers, arg)
	elseif evt == RCT.EVENT_SPELL_ADDED then
		table.insert(self.addedSpells, arg)
	elseif evt == RCT.EVENT_SPELL_REMOVED then
		table.insert(self.removedSpells, arg)
	end
end

--[[ Database class ]]--

RCT.Database = { }
RCT.Database.__index = RCT.Database

setmetatable(RCT.Database, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.Database:new()
	self.db = LibStub("AceDB-3.0"):New("RaidCooldownTrackerDB", self:GetDefaults(), true)
	self.db.RegisterCallback(self, "OnProfileChanged", "Reload")
	self.db.RegisterCallback(self, "OnProfileCopied", "Reload")
	self.db.RegisterCallback(self, "OnProfileReset", "Reload")
end

function RCT.Database:OnEnable()
	for className, class in pairs(RCT.spellDB) do
		for specName, spec in pairs(class) do
			for spellId, spell in pairs(spec) do
				local key = className .. "/" .. specName .. "/" .. spellId
				local data = self.db.profile.spellProperties[key]
				
				RCT:InjectSpellProperty(className, specName, spellId, "visible", data["visible"])
			end
		end
	end
end

function RCT.Database:Reload()
	print("TODO: Database reload")
end

function RCT.Database:SetSpellVisible(class, spec, spellId, visible)
	if self:IsSpellVisible(class, spec, spellId) == visible then
		return
	end

	if visible ~= 0 and visible ~= 1 then
		return
	end

	self:SetSpellProperty(class, spec, spellId, "visible", visible)

	-- Start tracking the spell
	if visible == 1 then
		for _, player in pairs(RCT.players) do
			player:AddSpell(spellId)
		end
	-- Stop tracking the spell
	else
		for _, player in pairs(RCT.players) do
			player:RemoveSpell(spellId)
		end
	end
end

function RCT.Database:SetSpellVisibleGlobal(spellId, visible)
	for className, class in pairs(RCT.spellDB) do
		for specName, spec in pairs(class) do
			for id, spell in pairs(spec) do
				if id == spellId then
					self:SetSpellVisible(className, specName, spellId, visible)
				end
			end
		end
	end
end

function RCT.Database:SetSpellProperty(class, spec, spellId, property, value)
	local key = class .. "/" .. spec .. "/" .. spellId
	local data = self.db.profile.spellProperties[key]

	data[property] = value
	RCT:InjectSpellProperty(class, spec, spellId, property, value)
end

function RCT.Database:GetSpellProperty(class, spec, spellId, property)
	local key = class .. "/" .. spec .. "/" .. spellId
	local data = self.db.profile.spellProperties[key]

	return data[property]
end

function RCT.Database:GetDefaults()
	if self.defaults ~= nil then
		return self.defaults
	end

	self.defaults = {
		profile = { 
			spellProperties = {
				['*'] = {
					visible = 1
				}
			}
		}
	}

	return self.defaults
end

function RCT.Database:IsSpellVisible(class, spec, spellId)
	return self:GetSpellProperty(class, spec, spellId, "visible") == 1
end

--[[ Initialization ]]--

function RCT:OnInitialize()
	RCT:InitializeSpellInfos()

	RCT.database = RCT.Database()

	RCT.frameManager = RCT.FrameManager()
	RCT.frameManager:SetStyle(RCT.FrameStyleCompactList)
end

function RCT:OnEnable()
	RCT.database:OnEnable()

	LGIST.RegisterCallback(self, "GroupInSpecT_Update", "OnUnitUpdated")
	LGIST.RegisterCallback(self, "GroupInSpecT_Remove", "OnUnitRemoved")

	RCT:RegisterEvent("ENCOUNTER_END")
	RCT:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	RCT:RegisterChatCommand("RCT", "SlashProcessor")

	RCT:ScheduleRepeatingTimer("UpdateFrames", 1)
end

function RCT:InitializeSpellInfos()
	for className, class in pairs(RCT.spellDB) do
		for specName, spec in pairs(class) do
			for spellId, spell in pairs(spec) do
				local name, _, icon = GetSpellInfo(spellId)
				
				RCT:InjectSpellProperty(className, specName, spellId, "spellId", spellId)
				RCT:InjectSpellProperty(className, specName, spellId, "name", name)
				RCT:InjectSpellProperty(className, specName, spellId, "icon", icon)
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

function RCT:SlashProcessor(input)
	local parts = { }

	for part in string.gmatch(input, "%S+") do
		table.insert(parts, part)
	end

	if parts[1] == "setvisible" then
		RCT.database:SetSpellVisible(parts[2], tonumber(parts[3]), tonumber(parts[4]), tonumber(parts[5]))
	elseif parts[1] == "setvisibleglobal" then
		RCT.database:SetSpellVisibleGlobal(tonumber(parts[2]), tonumber(parts[3]))
	end
end

function RCT:UpdateFrames()
	RCT.frameManager:Update()
end

--[[ Util functions ]]--

function RCT:InjectSpellProperty(class, spec, spellId, key, value)
	local spell = RCT.spellDB[class][spec][spellId]

	if spell ~= nil then
		spell[key] = value
	end
end

function RCT:GetPlayerByGUID(guid)
	return RCT.players[guid]
end

function RCT:GetSpellInfo(class, spec, spellId)
	return RCT.spellDB[class][spec][spellId]
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

function RCT:FormatTimeString(totalSeconds)
	local minutes = math.floor(totalSeconds / 60)
	local seconds = math.floor(totalSeconds % 60)

	return string.format("%02d:%02d", minutes, seconds)
end
