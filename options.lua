-- Get addon object
if not RCT then return end
local RCT = RCT

-- Libraries
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

--[[ Options class ]]--

RCT.Options = { }
RCT.Options.__index = RCT.Options

setmetatable(RCT.Options, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:new(...)
		return self
	end,
})

function RCT.Options:new()
	self:Build()

	AceConfigRegistry:RegisterOptionsTable("RaidCooldownTracker", self.options)
	AceConfig:RegisterOptionsTable("RaidCooldownTracker", self.options)
	
	AceConfigDialog:AddToBlizOptions("RaidCooldownTracker", "RaidCooldownTracker", nil, "general")
	AceConfigDialog:AddToBlizOptions("RaidCooldownTracker", "Window", "RaidCooldownTracker", "window")
	AceConfigDialog:AddToBlizOptions("RaidCooldownTracker", "Spells", "RaidCooldownTracker", "spells")
	AceConfigDialog:AddToBlizOptions("RaidCooldownTracker", "Profile", "RaidCooldownTracker", "profile")
end

function RCT.Options:Build()
	self.options = {
		type = "group",
		args = {
			general = self:BuildGeneralPanel(),
			window = self:BuildWindowPanel(),
			spells = self:BuildSpellsPanel(),
			profile = AceDBOptions:GetOptionsTable(RCT.database.db),
		}
	}
end

--[[ Panels ]]--

function RCT.Options:BuildGeneralPanel()
	return {
		name = "General",
		desc = "General",
		type = "group",
		order = 1,
		args = {
			visibility = {
				type = "select",
				order = 1,
				name = "Visibility",
				desc = "When to show the frame (only in raids, in both raids and parties or always)",
				values = {
					["none"] = "Always",
					["party"] = "Party/Raid",
					["raid"] = "Raid"
				},
				set = function(info, value)
					-- TODO
				end,
				get = function()
					return "none"
				end
			}
		}
	}
end

function RCT.Options:BuildWindowPanel()
	return {
		name = "Window",
		desc = "Window",
		type = "group",
		order = 2,
		args = {
			
		}
	}
end

function RCT.Options:BuildSpellsPanel()
	local function BuildSpell(class, spec, spellId)
		local spellInfo = RCT.spellDB[class][spec][spellId]

		return {
			name = spellInfo.name,
			desc = GetSpellDescription(spellId),
			type = "group",
			args = {
				header = {
					name = spellInfo.name,
					type = "header",
					order = 1,
				},
				enabled = {
					name = "Enable",
					desc = "Enable or disable tracking of this spell",
					type = "toggle",
					order = 2,
					set = function(info, value)
						RCT:GetSpellProperties(class, spec, spellId).enabled = value and 1 or 0

						if value then
							for _, player in pairs(RCT.players) do
								player:AddSpell(spellId)
							end
						else
							for _, player in pairs(RCT.players) do
								player:RemoveSpell(spellId)
							end
						end
					end,
					get = function()
						return RCT:GetSpellProperties(class, spec, spellId).enabled == 1 and true or false
					end
				}
			}
		}
	end

	local function BuildSpellsForClassSpec(class, spec)
		local res = {
			name = RCT.specNames[spec],
			type = "group",
			args = { }
		}

		for spellId, _ in pairs(RCT.spellDB[class][spec]) do
			res.args[tostring(spellId)] = BuildSpell(class, spec, spellId)
		end

		return res
	end

	local function BuildSpellsForClass(class)
		local res = {
			name = RCT.classNames[class],
			type = "group",
			args = { }
		}
		
		for specName, _ in pairs(RCT.spellDB[class]) do
			res.args[tostring(specName)] = BuildSpellsForClassSpec(class, specName)
		end

		return res
	end

	local classes = { }

	for className, _ in pairs(RCT.spellDB) do
		classes[className] = BuildSpellsForClass(className)
	end

	return {
		name = "Spells",
		desc = "Spells",
		type = "group",
		order = 3,
		args = classes
	}
end
