-- Get addon object
if not RCT then return end
local RCT = RCT

-- Libraries
local LGIST = LibStub("LibGroupInSpecT-1.1")
local AceDB = LibStub("AceDB-3.0")

RCT.trackedPlayers = { }
--RCT.__debugMode = true

-- Local variables

local availablePlayerFrames = { }
local numPlayerFrames = 0

local availableSpellFrames = { }
local numSpellFrames = 0

--[[ Player Handle ]]--

function RCT:CreatePlayerHandle(guid, info)
	if RCT:HasPlayerHandle(guid) then
		return nil
	end

	local player = { }
	player.guid = guid
	player.info = info
	player.dead = false
	player.frameHandle = nil
	player.cache = {}
	player.cache.global_spec_id = 0
	player.cache.level = 0
	player.cache.talents = nil
	player.spells = { }

	RCT.trackedPlayers[guid] = player
	RCT:InitializePlayerFrameHandle(player)
	
	return player
end

function RCT:DestroyPlayerHandle(playerHandle)
	if playerHandle == nil then
		return
	end

	for _, spellHandle in pairs(playerHandle.spells) do
		RCT:DestroySpellHandle(spellHandle)
	end

	playerHandle.frameHandle.frame:Hide()
	table.insert(availablePlayerFrames, playerHandle.frameHandle)

	RCT.trackedPlayers[playerHandle.guid] = nil
end

function RCT:UpdatePlayerHandle(playerHandle, info)
	playerHandle.info = info

	if playerHandle.cache.global_spec_id ~= info.global_spec_id then
		RCT:HandlePlayerSpecSwitch(playerHandle, info)
		RCT:RearrangeFrameList()
	else
		local shouldUpdate = false

		-- Handle level up
		if UnitLevel(info.lku) ~= playerHandle.level then
			shouldUpdate = true
		-- Handle talent switch
		else
			for _, existing_talent_id in ipairs(playerHandle.cache.talents) do
				local contains = false

				for new_talent_id, _ in pairs(info.talents) do
					if new_talent_id == existing_talent_id then
						contains = true
						break
					end
				end

				if not contains then
					shouldUpdate = true
					break
				end
			end
		end

		if shouldUpdate then
			RCT:HandlePlayerLevelUpOrTalentSwitch(playerHandle, info)
			RCT:RearrangeFrameList()
		end
	end

	if playerHandle.frameHandle == nil then
		RCT:InitializePlayerFrameHandle(playerHandle)

		if playerHandle.frameHandle ~= nil then
			for _, spellHandle in pairs(playerHandle.spells) do
				RCT:InitializeSpellFrameHandle(spellHandle)
			end
		end
	end
end

function RCT:HandlePlayerSpecSwitch(playerHandle, info)
	-- We're still missing info about the player	
	if info == nil or info.class == nil or info.global_spec_id == nil or info.global_spec_id == 0 then
		return
	end

	playerHandle.cache.global_spec_id = info.global_spec_id
	
	local newSpells = RCT:GetSpellsForSpec(info.class, info.global_spec_id)
	local oldSpells = playerHandle.spells

	-- Remove spells not available for the new spec
	for spellId, _ in pairs(oldSpells) do
		if not RCT:TableContainsKey(newSpells, spellId) then
			RCT:DestroySpellHandle(oldSpells[spellId])
		end
	end

	-- Add new spells
	for spellId, _ in pairs(newSpells) do
		if not RCT:TableContainsKey(playerHandle.spells, spellId) then
			RCT:CreateSpellHandle(playerHandle, spellId)
		end
	end

	RCT:HandlePlayerLevelUpOrTalentSwitch(playerHandle, info)
end

function RCT:HandlePlayerLevelUpOrTalentSwitch(playerHandle, info)
	-- We're still missing info about the player	
	if info == nil or info.talents == nil then
		return
	end

	playerHandle.cache.talents = RCT:CacheTalents(info.talents)
	playerHandle.level = UnitLevel(info.lku)
	
	for _, spellHandle in pairs(playerHandle.spells) do
		local spellInfo = RCT:GetSpellInfo(spellHandle)
		local castable = false
		
		if playerHandle.cache.level >= spellInfo.level then
			castable = true

			-- Check if the spell is a talent
			if spellInfo.talents ~= nil then
				local hasTalentSelected = false
				
				for i=1, #spellInfo.talents do
					local talent = spellInfo.talents[i]

					if RCT:PlayerHasTalentSelected(playerHandle, talent.tier, talent.column) then
						hasTalentSelected = true
						break
					end
				end

				castable = hasTalentSelected
			end
		end

		spellHandle.castable = castable
	end
end

function RCT:GetPlayerHandle(guid)
	if RCT:HasPlayerHandle(guid) then
		return RCT.trackedPlayers[guid]
	end

	return nil
end

function RCT:HasPlayerHandle(guid)
	return RCT.trackedPlayers[guid] ~= nil
end

--[[ Spell Handle ]]--

function RCT:CreateSpellHandle(playerHandle, spellId)
	if RCT:HasSpellHandle(playerHandle, spellId) then
		return nil
	end
	
	local spell = { }
	spell.playerHandle = playerHandle
	spell.spellId = spellId
	spell.castable = true
	spell.frameHandle = nil
	spell.activeStart = 0
	spell.activeEnd	= 0
	spell.readyTime	= 0

	playerHandle.spells[spellId] = spell
	RCT:InitializeSpellFrameHandle(spell)

	return spell
end

function RCT:DestroySpellHandle(spellHandle)
	if spellHandle == nil then
		return
	end

	spellHandle.frameHandle.frame:Hide()
	table.insert(availableSpellFrames, spellHandle.frameHandle)

	spellHandle.playerHandle.spells[spellHandle.spellId] = nil
end

function RCT:GetSpellHandle(playerHandle, spellId)
	if RCT:HasSpellHandle(playerHandle, spellId) then
		return playerHandle.spells[spellId]
	end

	return nil
end

function RCT:HasSpellHandle(playerHandle, spellId)
	return playerHandle.spells[spellId] ~= nil
end

--[[ Spell Database ]]--

function RCT:GetSpellsForSpec(class, spec)
	return RCT.spellDB[class][spec]
end

function RCT:GetSpellInfo(spellHandle)
	local class = spellHandle.playerHandle.info.class
	local spec = spellHandle.playerHandle.info.global_spec_id

	local spells = RCT:GetSpellsForSpec(class, spec)
	return spells[spellHandle.spellId]
end

function RCT:GetSpellDuration(spellHandle)
	local spellInfo = RCT:GetSpellInfo(spellHandle)

	if spellInfo.duration ~= nil then
		if spellInfo.modifiers ~= nil and spellInfo.modifiers.duration ~= nil then
			return spellInfo.modifiers.duration(spellHandle.playerHandle, spellInfo)
		end

		return spellInfo.duration
	end

	return 0
end

function RCT:GetSpellCooldown(spellHandle)
	local spellInfo = RCT:GetSpellInfo(spellHandle)

	if spellInfo.cooldown ~= nil then
		if spellInfo.modifiers ~= nil and spellInfo.modifiers.cooldown ~= nil then
			return spellInfo.modifiers.cooldown(spellHandle.playerHandle, spellInfo)
		end

		return spellInfo.cooldown
	end

	return 0
end

--[[ Frame ]]--

function RCT:InitializePlayerFrameHandle(playerHandle)
	if playerHandle.info == nil or playerHandle.info.class == nil then
		return
	end

	local frameHandle
	if #availablePlayerFrames > 0 then
		frameHandle = availablePlayerFrames[1]
		frameHandle.frame:Show()

		table.remove(availablePlayerFrames, 1)
	else
		frameHandle = RCT:CreatePlayerFrameHandle()
	end

	local classColor = RAID_CLASS_COLORS[playerHandle.info.class]
	frameHandle.playerName:SetText(playerHandle.info.name)
	frameHandle.playerName:SetTextColor(classColor.r, classColor.g, classColor.b, 1)

	playerHandle.frameHandle = frameHandle
	RCT:RearrangeFrameList()
end

function RCT:ReleasePlayerFrame(playerHandle)

end

function RCT:CreatePlayerFrameHandle()
	-- temp
	RCT.frame:SetPoint("CENTER", 400, 0)
	RCT.frame:SetWidth(200)
	RCT.frame:SetHeight(500)
	--RCT.frame:SetFrameStrata("LOW")

	numPlayerFrames = numPlayerFrames + 1
	
	local frameHandle = { }	
	frameHandle.id = numPlayerFrames

	-- Main Frame
	frameHandle.frame = CreateFrame("Frame", "RCT_PlayerFrame_" .. numPlayerFrames, RCT.frame)
	frameHandle.frame:SetClampedToScreen(true)
	frameHandle.frame:SetWidth(RCT.frame:GetWidth())
	frameHandle.frame:SetHeight(20)

	-- Player Name
	frameHandle.playerName = frameHandle.frame:CreateFontString("$parent_PlayerName", "OVERLAY", "GameFontNormal")
	frameHandle.playerName:SetPoint("TOPLEFT", frameHandle.frame)
	frameHandle.playerName:SetWidth(frameHandle.frame:GetWidth())
	frameHandle.playerName:SetHeight(20)
	frameHandle.playerName:SetJustifyH("LEFT")

	return frameHandle
end

function RCT:InitializeSpellFrameHandle(spellHandle)
	if spellHandle.playerHandle.frameHandle == nil then
		return
	end

	local spellInfo = RCT:GetSpellInfo(spellHandle)
	local frameHandle
	if #availableSpellFrames > 0 then
		frameHandle = availableSpellFrames[1]
		frameHandle.frame:Show()

		table.remove(availableSpellFrames, 1)
	else
		frameHandle = RCT:CreateSpellFrameHandle()
	end
	
	frameHandle.icon:SetTexture(select(3, GetSpellInfo(spellInfo.spellId)))
	frameHandle.spellName:SetText(spellInfo.name)
	frameHandle.cooldown:SetTextColor(0, 1, 0, 1)
	frameHandle.cooldown:SetText("Ready")
	
	spellHandle.frameHandle = frameHandle
	RCT:RearrangeFrameList()
end

function RCT:CreateSpellFrameHandle()
	numSpellFrames = numSpellFrames + 1

	local frameHandle = { }
	frameHandle.id = numSpellFrames

	-- Main Frame
	frameHandle.frame = CreateFrame("Frame", "RCT_SpellFrame_" ..numSpellFrames, RCT.frame)
	frameHandle.frame:SetWidth(RCT.frame:GetWidth())
	frameHandle.frame:SetHeight(20)

	frameHandle.icon = frameHandle.frame:CreateTexture("$parent_Icon", "OVERLAY")
	frameHandle.icon:SetWidth(15)
	frameHandle.icon:SetHeight(15)
	frameHandle.icon:SetPoint("LEFT", frameHandle.frame, "LEFT")
	frameHandle.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	frameHandle.spellName = frameHandle.frame:CreateFontString("$parent_SpellName", "OVERLAY", "GameFontNormal")
	frameHandle.spellName:SetWidth(frameHandle.frame:GetWidth() * 0.6)
	frameHandle.spellName:SetHeight(frameHandle.frame:GetHeight())
	frameHandle.spellName:SetPoint("LEFT", frameHandle.icon, "RIGHT", 3, 0)
	frameHandle.spellName:SetJustifyH("LEFT")

	frameHandle.cooldown = frameHandle.frame:CreateFontString("$parent_CooldownText", "OVERLAY", "GameFontNormal")
	frameHandle.cooldown:SetWidth(frameHandle.frame:GetWidth() * 0.3)
	frameHandle.cooldown:SetHeight(frameHandle.frame:GetHeight())
	frameHandle.cooldown:SetPoint("RIGHT", frameHandle.frame, "RIGHT")
	frameHandle.cooldown:SetJustifyH("RIGHT")

	return frameHandle;
end

function RCT:RearrangeFrameList()
	local frameHandleOrder = { }

	for _, playerHandle in pairs(RCT.trackedPlayers) do
		local frameHandle = playerHandle.frameHandle
		frameHandleOrder[frameHandle.id] = { playerHandle, frameHandle }
	end
	
	local lastFrameHandle = nil
	local lastFrameHandleHeight = 0
	for i=1, #frameHandleOrder do
		if frameHandleOrder[i] ~= nil then
			local playerHandle = frameHandleOrder[i][1]
			local frameHandle = frameHandleOrder[i][2]

			if lastFrameHandle == nil then
				frameHandle.frame:SetPoint("TOPLEFT", RCT.frame)
			else
				frameHandle.frame:SetPoint("TOPLEFT", lastFrameHandle.frame, "BOTTOMLEFT", 0, -lastFrameHandleHeight)
			end

			local nextY = frameHandle.frame:GetHeight()
			for _, spellHandle in pairs(playerHandle.spells) do
				local spellFrameHandle = spellHandle.frameHandle

				if spellFrameHandle ~= nil then
					spellFrameHandle.frame:SetPoint("TOPLEFT", frameHandle.frame, "TOPLEFT", 0, -nextY)
					nextY = nextY + spellFrameHandle.frame:GetHeight()
				end
			end

			if nextY > frameHandle.frame:GetHeight() then
				frameHandle.frame:Show()
				lastFrameHandle = frameHandle
				lastFrameHandleHeight = nextY
			else
				frameHandle.frame:Hide()
			end
		end
	end
end

--[[ Tracking ]]--

function RCT:HandlePlayerSpellCast(spellHandle)
	-- Make sure the spell if marked as castable
	spellHandle.castable = true

	local duration = RCT:GetSpellDuration(spellHandle)
	local cooldown = RCT:GetSpellCooldown(spellHandle)

	spellHandle.castTime = GetTime()
	spellHandle.readyTime = GetTime() + cooldown

	if duration > 0 then
		spellHandle.activeStart = GetTime()
		spellHandle.activeEnd = GetTime() + duration
	end
end

function RCT:ResetSpellStatus(spellHandle)
	spellHandle.activeStart = 0
	spellHandle.activeEnd = 0
	spellHandle.readyTime = 0
end

-- TEMP
function RCT:HandlePlayerSpellCastText()
	local currentTime = GetTime()

	for _, playerHandle in pairs(RCT.trackedPlayers) do
		for _, spellHandle in pairs(playerHandle.spells) do
			if spellHandle.frameHandle ~= nil then
				if spellHandle.activeEnd > currentTime then
					spellHandle.frameHandle.cooldown:SetTextColor(1, 1, 0, 1)
					spellHandle.frameHandle.cooldown:SetText(RCT:GetFormattedTimeString(spellHandle.activeEnd - currentTime))
				elseif spellHandle.readyTime > currentTime then
					spellHandle.frameHandle.cooldown:SetTextColor(1, 0, 0, 1)
					spellHandle.frameHandle.cooldown:SetText(RCT:GetFormattedTimeString(spellHandle.readyTime - currentTime))
				else
					spellHandle.frameHandle.cooldown:SetTextColor(0, 1, 0, 1)
					spellHandle.frameHandle.cooldown:SetText("Ready")
				end
			end
		end
	end
end

function RCT:GetFormattedTimeString(totalSeconds)
	local minutes = math.floor(totalSeconds / 60)
	local seconds = math.floor(totalSeconds % 60)

	return string.format("%02d:%02d", minutes, seconds)
end

--[[ LibStub callbacks & event callbacks ]]--

function RCT:GROUP_ROSTER_UPDATE()

end

function RCT:ENCOUNTER_START(evt, encounterId, encounterName, difficultyId, groupSize)

end

function RCT:ENCOUNTER_END(evt, encounterId, encounterName, difficultyId, groupSize, success)
	if groupSize >= 10 then
		for _, playerHandle in pairs(RCT.trackedPlayers) do
			for _, spellHandle in pairs(playerHandle.spells) do
				local spellInfo = RCT:GetSpellInfo(spellHandle)
				
				if spellInfo.resetOnWipe then
					RCT:ResetSpellStatus(spellHandle)
				end
			end
		end

		print("Reset cooldowns")
	end
end

function RCT:COMBAT_LOG_EVENT_UNFILTERED(evt, ...)
	if evt == "COMBAT_LOG_EVENT_UNFILTERED" then
		local type, _, guid = select(2, ...)

		if type == "SPELL_CAST_SUCCESS" then
			local playerHandle = RCT:GetPlayerHandle(guid)

			if playerHandle ~= nil then
				local spellId = select(12, ...)
				local spellHandle = RCT:GetSpellHandle(playerHandle, spellId)
				
				if spellHandle ~= nil then
					RCT:HandlePlayerSpellCast(spellHandle)
				end
			end
		end
	end
end

function RCT:SlashProcessor(input)

end

function RCT:OnInitialize()
	LGIST.RegisterCallback(self, "GroupInSpecT_Update", "OnUnitUpdated")
	LGIST.RegisterCallback(self, "GroupInSpecT_Remove", "OnUnitRemoved")

	RCT:RegisterEvent("GROUP_ROSTER_UPDATE")
	RCT:RegisterEvent("ENCOUNTER_START")
	RCT:RegisterEvent("ENCOUNTER_END")
	RCT:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	RCT:RegisterChatCommand("RCT", "SlashProcessor")

	RCT:ScheduleRepeatingTimer("HandlePlayerSpellCastText", 1)
end

--[[ LibGroupInSpecT callbacks ]]--

function RCT:OnUnitUpdated(evt, guid, unitId, info)
	if not RCT:HasPlayerHandle(guid) then
		if RCT.__debugMode then
			for i=1, 4 do
				RCT:CreatePlayerHandle(guid .. i, info)
			end
		else
			RCT:CreatePlayerHandle(guid, info)
		end
	end

	if RCT.__debugMode then
		for i=1, 4 do
			local playerHandle = RCT:GetPlayerHandle(guid .. i)
			RCT:UpdatePlayerHandle(playerHandle, info)
		end
	else
		local playerHandle = RCT:GetPlayerHandle(guid)
		RCT:UpdatePlayerHandle(playerHandle, info)
	end
end

function RCT:OnUnitRemoved(evt, guid)
	if RCT:HasPlayerHandle(guid) then
		local playerHandle = RCT:GetPlayerHandle(guid)
		RCT:DestroyPlayerHandle(playerHandle)
		RCT:RearrangeFrameList()
	end
end

--[[ Helper functions ]]--

-- Get the player's group type ("raid", "party" or "none")
function RCT:GetGroupType()
	if IsInRaid() then
		return "raid"
	end

	if IsInGroup() or IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		return "party"
	end

	return "none"
end

function RCT:TableContainsKey(table, value)
	for k, _ in pairs(table) do
        if k == value then
            return true
        end
    end

    return false
end

function RCT:PlayerHasTalentSelected(playerHandle, tier, column)
	for _, talent in pairs(playerHandle.info.talents) do
		if talent.tier == tier and talent.column == column then
			return true
		end
	end
end

function RCT:CacheTalents(talents)
	local result = { }

	for talent_id, _ in pairs(talents) do
		table.insert(result, talent_id)
	end

	return result
end
