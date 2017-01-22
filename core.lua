-- Get addon object
if not RCT then return end
local RCT = RCT

-- Libraries
local LGIST = LibStub("LibGroupInSpecT-1.1")
local AceDB = LibStub("AceDB-3.0")

RCT.trackedPlayers = { }

RCT.availablePlayerFrames = { }
RCT.availablePlayerSpellFrames = { }

RCT.numCreatedPlayerFrames = 0
RCT.numCreatedPlayerSpellFrames = 0

--[[ Frame Creation ]]--

function RCT:ClaimPlayerFrame(guid)
	if #RCT.availablePlayerFrames > 0 then
		local frame = RCT.availablePlayerFrames[1]
		table.remove(RCT.availablePlayerFrames, 1)
		return frame
	end

	RCT.numCreatedPlayerFrames = RCT.numCreatedPlayerFrames + 1
	local frame = CreateFrame("Frame", "RCT_PlayerFrame_" .. RCT.numCreatedPlayerFrames, RCT.frame)

	RCT:ResetPlayerFrameData(frame)
	return frame
end

function RCT:ClaimPlayerSpellFrame(guid, spellId)
	if #RCT.availablePlayerSpellFrames > 0 then
		local frame = RCT.availabavailablePlayerSpellFramesleSpellFrames[1]
		table.remove(RCT.availablePlayerSpellFrames, 1)
		return frame
	end

	RCT.numCreatedPlayerSpellFrames = RCT.numCreatedPlayerSpellFrames + 1
	local frame = CreateFrame("Frame", "RCT_PlayerSpellFrame_" .. RCT.numCreatedPlayerSpellFrames, RCT.trackedPlayers[guid].frame)
	
	RCT:ResetPlayerSpellFrameData(frame)
	return frame
end

function RCT:ReleasePlayerFrame(guid)
	if RCT.trackedPlayers[guid] ~= nil and RCT.trackedPlayers[guid].frame ~= nil then
		RCT:ResetPlayerFrameData(RCT.trackedPlayers[guid].frame)
		RCT.trackedPlayers[guid].frame = nil
	end
end

function RCT:ReleasePlayerSpellFrame(guid, spellId)
	if RCT.trackedPlayers[guid] ~= nil and RCT.trackedPlayers[guid].spells[spellId] ~= nil and RCT.trackedPlayers[guid].spells[spellId].frame ~= nil then
		RCT:ResetPlayerSpellFrameData(RCT.trackedPlayers[guid].spells[spellId].frame)
		RCT.trackedPlayers[guid].spells[spellId].frame = nil
	end
end

function RCT:ResetPlayerFrameData(frame)

end

function RCT:ResetPlayerSpellFrameData(frame)

end

--[[ Player ]]--

function RCT:CreatePlayer(guid, info)
	if RCT.trackedPlayers[guid] == nil then
		local player = { }
		player.guid = guid
		player.info = info
		player.hidden = false
		player.dead = false
		player.frame = nil
		player.spec = info.global_spec_id
		player.talents = info.talents
		player.level = UnitLevel(info.lku)
		player.spells = { }

		RCT.trackedPlayers[guid] = player
		RCT:ClaimPlayerFrame(guid)

		RCT:HandlePlayerSpecSwitch(guid, info)
	end
end

function RCT:DestroyPlayer(guid)
	if RCT.trackedPlayers[guid] ~= nil then
		RCT:ReleasePlayerFrame(guid)
		RCT.trackedPlayers[guid] = nil
	end
end

function RCT:UpdatePlayer(guid, info)
	if RCT.trackedPlayers[guid] ~= nil then
		RCT.trackedPlayers[guid].info = info
		
		-- Handle spec switch
		if info.global_spec_id ~= RCT.trackedPlayers[guid].spec then
			RCT:HandlePlayerSpecSwitch(guid, info)
		else
			local shouldUpdate = false

			-- Handle level up
			if UnitLevel(info.lku) ~= RCT.trackedPlayers[guid].level then
				shouldUpdate = true
			-- Handle talent switch
			else
				for _, existing_talent_id in ipairs(RCT.trackedPlayers[guid].talents) do
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
				RCT:HandlePlayerLevelUpOrTalentSwitch(guid, info)
			end
		end
	end
end

function RCT:ShowPlayer(guid, show)
	if RCT.trackedPlayers[guid] ~= nil then
		RCT.trackedPlayers[guid].hidden = not show

		-- TODO: Frame
	end
end

function RCT:ShowPlayerSpell(guid, spellId, show)
	if RCT.trackedPlayers[guid] ~= nil and RCT.trackedPlayers[guid].spells[spellId] ~= nil then
		RCT.trackedPlayers[guid].spells[spellId].hidden = not show
		
		-- TODO: Frame
	end
end

function RCT:AddPlayerSpell(guid, spellId)
	local spell = { }
	spell.spellId = spellId
	spell.frame = nil
	spell.hidden = false
	spell.castable = false
	spell.activeStart = 0
	spell.activeEnd	= 0
	spell.readyTime	= 0

	RCT.trackedPlayers[guid].spells[spellId] = spell
	RCT:ClaimPlayerSpellFrame(guid, spellId)
end

function RCT:HandlePlayerSpecSwitch(guid, info)
	-- We're still missing info about the player
	if info == nil or info.class == nil or info.global_spec_id == nil then
		return
	end

	local newSpells = RCT.spellDB[info.class][info.global_spec_id]
	if newSpells == nil then return end
	
	RCT.trackedPlayers[guid].spec = info.global_spec_id

	local playerInfo = RCT.trackedPlayers[guid].info
	local playerSpellCache = RCT.trackedPlayers[guid].spells

	-- Remove spells not available for the new spec
	for spellId, _ in pairs(playerSpellCache) do
		if not RCT:TableContainsKey(newSpells, spellId) then
			RCT:ReleasePlayerSpellFrame(guid, spellId)
			RCT.trackedPlayers[guid].spells[spellId] = nil
		end
	end

	-- Add new spells
	for spellId, _ in pairs(newSpells) do
		if not RCT:TableContainsKey(RCT.trackedPlayers[guid].spells, spellId) then
			RCT:AddPlayerSpell(guid, spellId)
		end
	end

	RCT:HandlePlayerLevelUpOrTalentSwitch(guid, info)
end

function RCT:HandlePlayerLevelUpOrTalentSwitch(guid, info)
	RCT.trackedPlayers[guid].talents = { }
	for talent_id, _ in pairs(info.talents) do
		table.insert(RCT.trackedPlayers[guid].talents, talent_id)
	end

	RCT.trackedPlayers[guid].level = UnitLevel(info.lku)

	for _, spell in pairs(RCT.trackedPlayers[guid].spells) do
		local playerInfo = RCT.trackedPlayers[guid].info
		local spellInfo = RCT:GetSpellInfo(playerInfo.class, playerInfo.global_spec_id, spell.spellId)

		local castable = false
		
		if RCT.trackedPlayers[guid].level >= spellInfo.level then
			castable = true

			-- Check if the spell is a talent
			if spellInfo.talents ~= nil then
				local hasTalentSelected = false
				
				for i=1, #spellInfo.talents do
					if RCT:PlayerHasTalentSelected(guid, spellInfo.talents[i].tier, spellInfo.talents[i].column) then
						hasTalentSelected = true
						break
					end
				end

				castable = hasTalentSelected
			end
		end

		RCT.trackedPlayers[guid].spells[spell.spellId].castable = castable
	end
end

function RCT:HandlePlayerSpellCast(guid, spellId)
	if RCT.trackedPlayers[guid] ~= nil and RCT.trackedPlayers[guid].spells[spellId] ~= nil then
		local duration = RCT:GetPlayerSpellDuration(guid, spellId)
		local cooldown = RCT:GetPlayerSpellCooldown(guid, spellId)

		-- We wrongly marked this spell as not-castable but apperantly it is castable
		if not RCT.trackedPlayers[guid].spells[spellId].castable then
			RCT.trackedPlayers[guid].spells[spellId].castable = true
		end

		if duration > 0 then
			RCT.trackedPlayers[guid].spells[spellId].activeStart = GetTime()
			RCT.trackedPlayers[guid].spells[spellId].activeEnd = GetTime() + duration

			RCT:ScheduleTimer("HandlePlayerSpellCastActiveEnd", duration, guid, spellId)
		end

		RCT.trackedPlayers[guid].spells[spellId].castTime = GetTime()
		RCT.trackedPlayers[guid].spells[spellId].readyTime = GetTime() + cooldown
		RCT:ScheduleTimer("HandlePlayerSpellCastCooldownEnd", cooldown, guid, spellId)

		-- TEMP
		do
			local playerInfo = RCT.trackedPlayers[guid].info
			local spellInfo = RCT:GetSpellInfo(playerInfo.class, playerInfo.global_spec_id, spellId)
			print(playerInfo.name .. " cast spell: " .. spellInfo.name .. " (Duration=" .. duration .. " Cooldown=" .. cooldown .. ")")
		end
	end
end

-- TEMP
function RCT:HandlePlayerSpellCastActiveEnd(guid, spellId)
	if RCT.trackedPlayers[guid] ~= nil and RCT.trackedPlayers[guid].spells[spellId] ~= nil then
		local playerInfo = RCT.trackedPlayers[guid].info
		local spellInfo = RCT:GetSpellInfo(playerInfo.class, playerInfo.global_spec_id, spellId)
		print(spellInfo.name .. " is no longer active for " .. playerInfo.name)
	end
end

-- TEMP
function RCT:HandlePlayerSpellCastCooldownEnd(guid, spellId)
	if RCT.trackedPlayers[guid] ~= nil and RCT.trackedPlayers[guid].spells[spellId] ~= nil then
		local playerInfo = RCT.trackedPlayers[guid].info
		local spellInfo = RCT:GetSpellInfo(playerInfo.class, playerInfo.global_spec_id, spellId)
		print(spellInfo.name .. " is off cooldown for " .. playerInfo.name)
	end
end

function RCT:EnablePlayerSpellTracking(guid, spellId, enable)
	if RCT.trackedPlayers[guid] ~= nil and RCT.trackedPlayers[guid].spells[spellId] ~= nil then
		RCT.trackedPlayers[guid].spells[spellId].hidden = not enable
	end
end

function RCT:PlayerHasTalentSelected(guid, tier, column)
	if RCT.trackedPlayers[guid] ~= nil then
		for _, talent in pairs(RCT.trackedPlayers[guid].info.talents) do
			if talent.tier == tier and talent.column == column then
				return true
			end
		end
	end

	return false
end

function RCT:GetPlayerSpellDuration(guid, spellId)
	local playerInfo = RCT.trackedPlayers[guid].info
	local spellInfo = RCT:GetSpellInfo(playerInfo.class, playerInfo.global_spec_id, spellId)
	
	if spellInfo ~= nil and spellInfo.duration ~= nil then
		if spellInfo.modifiers ~= nil and spellInfo.modifiers.duration ~= nil then
			return spellInfo.modifiers.duration(guid, spellInfo)
		end

		return spellInfo.duration
	end

	return 0
end

function RCT:GetPlayerSpellCooldown(guid, spellId)
	local playerInfo = RCT.trackedPlayers[guid].info
	local spellInfo = RCT:GetSpellInfo(playerInfo.class, playerInfo.global_spec_id, spellId)
	
	if spellInfo ~= nil and spellInfo.cooldown ~= nil then
		if spellInfo.modifiers ~= nil and spellInfo.modifiers.cooldown ~= nil then
			return spellInfo.modifiers.cooldown(guid, spellInfo)
		end

		return spellInfo.cooldown
	end

	return 0
end

--[[ Spell ]]--

function RCT:GetSpellInfo(class, spec, spellId)
	return RCT.spellDB[class][spec][spellId]
end

--[[ LibStub callbacks & event callbacks ]]--

function RCT:GROUP_ROSTER_UPDATE()

end

function RCT:ENCOUNTER_START(evt, encounterId, encounterName, difficultyId, groupSize)

end

function RCT:ENCOUNTER_END(evt, encounterId, encounterName, difficultyId, groupSize, success)

end

function RCT:COMBAT_LOG_EVENT_UNFILTERED(evt, ...)
	if evt == "COMBAT_LOG_EVENT_UNFILTERED" then
		local type, _, guid = select(2, ...)

		if type == "SPELL_CAST_SUCCESS" then
			local spellId = select(12, ...)
			RCT:HandlePlayerSpellCast(guid, spellId)
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
end

--[[ LibGroupInSpecT callbacks ]]--

function RCT:OnUnitUpdated(evt, guid, unitId, info)
	if RCT.trackedPlayers[guid] == nil then
		RCT:CreatePlayer(guid, info)
	end

	RCT:UpdatePlayer(guid, info)
end

function RCT:OnUnitRemoved(evt, guid)
	RCT:DestroyPlayer(guid)
end

--[[ Frames ]]--

-- TODO: Check with config settings
-- Check whether or not the frame should be visible
function RCT:ShouldFrameBeVisible()
	local groupType = RCT:GetGroupType()

	-- Always show
	
	-- Only in raid group
	if groupType == "raid" then
		return true
	end
	
	-- Only in raid or pary groups
	if groupType == "raid" or groupType == "party" then
		return true
	end

	return false
end

-- TODO: Check if the frame is actually visible
-- Check whether or not the frame is visible
function RCT:IsFrameVisible()
	return true
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
