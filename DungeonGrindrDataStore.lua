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
	
	if T.DungeonGrindrDataStore:GetHelpShown() == nil then
		T.DungeonGrindrDataStore:SetHelpShown(false)
	end
	
	if T.DungeonGrindrDataStore:GetIgnoreNewPlayers() == nil then
		T.DungeonGrindrDataStore:SetIgnoreNewPlayers(true)
	end
	frame:UnregisterEvent("ADDON_LOADED")
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

function T.DungeonGrindrDataStore:GetHelpShown() 
	return _G.DGhelpShown
end

function T.DungeonGrindrDataStore:SetHelpShown(value)
	if type(value) ~= "boolean" then return end
	_G.DGhelpShown = value
end


function T.DungeonGrindrDataStore:GetIgnoreNewPlayers() 
	return _G.DGignoreNewPlayers
end

function T.DungeonGrindrDataStore:SetIgnoreNewPlayers(value)
	if type(value) ~= "boolean" then return end
	_G.DGignoreNewPlayers = value
end
-- END PUBLIC API