local addonName, T = ...;

local _G = _G
T.DungeonGrindrDataStore = {}

local frame = CreateFrame("frame")
frame:RegisterEvent("ADDON_LOADED");

frame:SetScript("OnEvent", function(f, event)
	if T.DungeonGrindrDataStore:GetExcludeMemeSpecs() == nil then
		T.DungeonGrindrDataStore:SetExcludeMemeSpecs(true)
	end
	
	if T.DungeonGrindrDataStore:GetAutoReinvite() == nil then
		T.DungeonGrindrDataStore:SetAutoReinvite(true)
	end
	
	print("DungeonGrindrDataStore Loaded")
end)

-- PUBLIC API 
function T.DungeonGrindrDataStore:GetExcludeMemeSpecs() 
	return _G.DGexcludeMemeSpecs
end

function T.DungeonGrindrDataStore:SetExcludeMemeSpecs(value)
	if type(value) ~= "boolean" then return end
	_G.DGexcludeMemeSpecs = value
end

function T.DungeonGrindrDataStore:GetAutoReinvite() 
	return _G.DGautoReinvite
end

function T.DungeonGrindrDataStore:SetAutoReinvite(value)
	if type(value) ~= "boolean" then return end
	_G.DGautoReinvite = value
end
-- END PUBLIC API