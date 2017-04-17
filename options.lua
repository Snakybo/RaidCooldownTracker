-- Get addon object
if not RCT then return end
local RCT = RCT

-- Libraries
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local LGIST = LibStub("LibGroupInSpecT-1.1")

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
	AceConfigDialog:AddToBlizOptions("RaidCooldownTracker", "Spells", "RaidCooldownTracker", "spells")
	AceConfigDialog:AddToBlizOptions("RaidCooldownTracker", "Profile", "RaidCooldownTracker", "profile")
end

function RCT.Options:Build()
	self.options = {
		type = "group",
		args = {
			general = self:BuildGeneralPanel(),
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
			-- window = {
			-- 	name = "Window",
			-- 	type = "group",
			-- 	order = 1,
			-- 	inline = true,
			-- 	args = {
			-- 		anchor = {
			-- 			name = "Anchor",
			-- 			type = "select",
			-- 			order = 1,
			-- 			values = {
			-- 				["TOPLEFT"] = "Top Left",
			-- 				["TOP"] = "Top",
			-- 				["TOPRIGHT"] = "Top Right",
			-- 				["LEFT"] = "Left",
			-- 				["CENTER"] = "Center",
			-- 				["RIGHT"] = "Right",
			-- 				["BOTTOMLEFT"] = "Bottom left",
			-- 				["BOTTOM"] = "Bottom",
			-- 				["BOTTOMRIGHT"] = "Bottom Right"
			-- 			},
			-- 			set = function(info, value)
			-- 				RCT:GetWindowProperties().anchor = value
			-- 				-- TODO: Redraw
			-- 			end,
			-- 			get = function()
			-- 				return RCT:GetWindowProperties().anchor
			-- 			end
			-- 		},
			-- 		x = {
			-- 			name = "X Position",
			-- 			type = "range",
			-- 			order = 2,
			-- 			min = 0,
			-- 			max = UIParent:GetWidth(),
			-- 			set = function(info, value)
			-- 				RCT:GetWindowProperties().x = value
			-- 				-- TODO: Redraw
			-- 			end,
			-- 			get = function()
			-- 				return RCT:GetWindowProperties().x
			-- 			end
			-- 		},
			-- 		y = {
			-- 			name = "Y Position",
			-- 			type = "range",
			-- 			order = 3,
			-- 			min = 0,
			-- 			max = UIParent:GetHeight(),
			-- 			set = function(info, value)
			-- 				RCT:GetWindowProperties().y = value
			-- 				-- TODO: Redraw
			-- 			end,
			-- 			get = function()
			-- 				return RCT:GetWindowProperties().y
			-- 			end
			-- 		},
			-- 		w = {
			-- 			name = "Width",
			-- 			type = "range",
			-- 			order = 4,
			-- 			min = 0,
			-- 			max = 500,
			-- 			set = function(info, value)
			-- 				RCT:GetWindowProperties().w = value
			-- 				-- TODO: Redraw
			-- 			end,
			-- 			get = function()
			-- 				return RCT:GetWindowProperties().w
			-- 			end
			-- 		}
			-- 	}
			-- -- },
			-- visibility = {
			-- 	type = "select",
			-- 	order = 2,
			-- 	name = "Visibility",
			-- 	desc = "When to show the frame (only in raids, in both raids and parties or always)",
			-- 	values = {
			-- 		["none"] = "Always",
			-- 		["party"] = "Party/Raid",
			-- 		["raid"] = "Raid"
			-- 	},
			-- 	set = function(info, value)
			-- 		-- TODO
			-- 	end,
			-- 	get = function()
			-- 		return "none"
			-- 	end
			-- },
			displaySelf = {
				type = "toggle",
				order = 3,
				name = "Display Player",
				desc = "Whether or not to display cooldowns for yourself",
				set = function(info, value)
					RCT.database:GetProfile().displaySelf = value and 1 or 0
					
					local guid = UnitGUID("player")

					if not value then
						local player = RCT:GetPlayerByGUID(guid)
						if player ~= nil then player:Destroy() end
					else
						local info = LGIST:GetCachedInfo(guid)
						local player = RCT.Player(guid, info)
						player:Update(info)
					end
				end,
				get = function()
					return RCT.database:GetProfile().displaySelf == 1 and true or false
				end
			}
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
						RCT:SendMessage(RCT.EVENT_SPELL_DATABASE_UPDATED, class, spec, spellId)
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
