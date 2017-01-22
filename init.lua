RCT = LibStub("AceAddon-3.0"):NewAddon("RaidCooldownTracker", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")
if not RCT then return end

if not RCT.frame then
	RCT.frame = CreateFrame("Frame", "RCT_Frame", UIParent)
end

RCT.frame:UnregisterAllEvents()
