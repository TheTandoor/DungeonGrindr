local addonName, T = ...;

local DungeonGrindrUI = T.DungeonGrindrUI;
local Funcs = T.Funcs;
local dataStore = T.DungeonGrindrDataStore;

local activityDropdown = DungeonGrindrUI.framesCollection.dropDowns.dungeonDropDown
local boxFrame = DungeonGrindrUI.framesCollection.boxFrame
local queueButton = DungeonGrindrUI.framesCollection.buttons.queue
local refreshFrame = DungeonGrindrUI.framesCollection.buttons.refresh
local leaveQueueButton = DungeonGrindrUI.framesCollection.buttons.leaveQueue
local closeButton = DungeonGrindrUI.framesCollection.buttons.close
local helpButton = DungeonGrindrUI.framesCollection.buttons.help
local inviteGroupButton = DungeonGrindrUI.framesCollection.buttons.inviteGroup
local roleCheckButton = DungeonGrindrUI.framesCollection.buttons.roleCheck
local settingsButton = DungeonGrindrUI.framesCollection.buttons.settings
local roleFrames = DungeonGrindrUI.framesCollection.roleFrames

activityDropdown.selectedValues = {};

DungeonGrindr = CreateFrame("frame");

DungeonGrindr:RegisterEvent("PLAYER_ROLES_ASSIGNED"); -- Fired when all players have selected a role via InitiateRolePoll or the poll times out
DungeonGrindr:RegisterEvent("GROUP_ROSTER_UPDATE"); -- Fires when anyone joins/leaves/rejects or is moved in a party
DungeonGrindr:RegisterEvent("TALENT_GROUP_ROLE_CHANGED"); -- Fired when the user switches talent roles
DungeonGrindr:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED"); -- fired when the user switches specs
DungeonGrindr:RegisterEvent("ROLE_CHANGED_INFORM"); -- Fired when any user in the party has their role changed
DungeonGrindr:RegisterEvent("LFG_LIST_AVAILABILITY_UPDATE");
DungeonGrindr:RegisterEvent("LFG_LIST_SEARCH_FAILED");
DungeonGrindr:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED");
DungeonGrindr:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED");

local initCalled = false
local roleCheckEnum = { none = "NONE", inprogress = "INPROGRESS", complete = "COMPLETE" }
local queueStateEnum = { none = "NONE", inprogress = "INPROGRESS", invitingGroup = "INVITINGGROUP", complete = "COMPLETE" }

local dungeonQueue = {
	roleCheckState = roleCheckEnum.none,
	roleCheckCount = 0,
	dungeonId = nil,
	dungeonName = "",
	inQueue = false,
	queueStatus = queueStateEnum.none,
	queuePopTimerExpired = false,
	needs = {
		tanks = 1,
		healers = 1,
		dps = 3,
	},
}

local dungeonCategoryId = 2

local groupToInvite = {
	tank = "",
	healer = "",
	dps = { "", "", "" }
}

local requireRefreshOnFullGroupAfter = 15

-- DEBUG BEGIN
local DEBUG = false
local DEBUGDUNGEONS = false
local ROLE_BYPASS = false
local SPOOFING = false

function DungeonGrindr:DebugLFGList()
	if DEBUGDUNGEONS == false then return end
	local results = select(2, Funcs:GetFilteredSearchResults());
	local searchResultInfo = Funcs:LFGListGetSearchResultInfo(results[1]);
	local name = Funcs:GetSearchResultLeaderInfo(results[1]);
	local activityIDs = searchResultInfo.activityIDs
	if activityIDs == nil then print("activityIDs: nil") return end
	for index = 1, #activityIDs do
		local activityInfo = Funcs:GetActivityInfoTable(activityIDs[index])
		Funcs:print(activityInfo.fullName..": catID: "..activityInfo.categoryID .." activityID: " .. activityIDs[index])
	end
end

function DungeonGrindr:DebugPrint(text)
	if DEBUG == false then return end
	Funcs:print("DG DEBUG: " .. text)
end

function DungeonGrindr:PrintGroupCache(groupToInvite) 
	DungeonGrindr:DebugPrint("GroupCache: " .. groupToInvite.tank .. ":" .. groupToInvite.healer .. ":" .. groupToInvite.dps[1] .. "," .. groupToInvite.dps[2] .. "," .. groupToInvite.dps[3])
end
-- DEBUG END

function DungeonGrindr:PrettyPrint(text)
	Funcs:print("[" .. DungeonGrindr:Rainbowify("DungeonGrindr") .. "] " .. tostring(text)) 
end

function DungeonGrindr:Rainbowify(text)
	local red = "|cFFFF0000"
	local green = "|cFF00FF00" 
	local blue = "|cFF0000FF"
	local purple = "|cFFFF00FF"
	local yellow = "|cFFFFFF00"
	local teal = "|cFF00FFFF"
	local close = "|r"
	
	local newString = ""
	
	local colors = { red, green, blue, purple, yellow, teal }
	for i = 1, #text do
		local c = text:sub(i,i)
		newString = newString .. colors[ math.random( #colors ) ] .. c .. close
	end
	
	return newString
end

function DungeonGrindr:TableContainsValue(tab, val)
	for idx, value in ipairs(tab) do
		if value == val then return true end 
	end
	
	return false
end




-- MINIMAP
local MinimapButton = CreateFrame('Button', "DGMinimapButton", Minimap)
function MinimapButton:Load()
    self:SetFrameStrata('HIGH')
    self:SetWidth(31)
    self:SetHeight(31)
    self:SetFrameLevel(8)
    self:RegisterForClicks('anyUp')
    self:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')

    local overlay = self:CreateTexture(nil, 'OVERLAY')
    overlay:SetWidth(53)
    overlay:SetHeight(53)
    overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
    overlay:SetPoint('TOPLEFT')

    local icon = self:CreateTexture(nil, 'BACKGROUND')
	self.icon = icon
    icon:SetWidth(20)
    icon:SetHeight(20)
    MinimapButton:SetRole(GetTalentGroupRole(GetActiveTalentGroup()))
    icon:SetPoint('TOPLEFT', 7, -5)

    self:SetScript('OnClick', self.OnClick)

    self:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -2, 2)
end

function MinimapButton:SetRole(role)
	self.icon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
	self.icon:SetTexCoord(GetTexCoordsForRole(role))
end

function MinimapButton:OnClick(button)
	if boxFrame:IsShown() == false then
		boxFrame:Show()
	else
		boxFrame:Hide()
	end
end 
-- MINIMAP END

function DungeonGrindr:RefreshDropdown()
	UIDropDownMenu_Initialize(activityDropdown, _LFGBrowseActivityDropDown_Initialize);
end

-- OnEvent Handler
DungeonGrindr:SetScript("OnEvent", function(f, event)
	if initCalled == false then 
		DungeonGrindr:Init()
		MinimapButton:Load()
		initCalled = true
		DungeonGrindr:InvalidateUI(groupToInvite, dungeonQueue)
		
		UIDropDownMenu_Initialize(activityDropdown, _LFGBrowseActivityDropDown_Initialize);
	end
	
	DungeonGrindr:DebugLFGList()
	
	if event == "LFG_LIST_AVAILABILITY_UPDATE" then 
		--DungeonGrindr:RefreshDropdown()
	end
	
	-- simply ignore failures
	if ( event == "LFG_LIST_SEARCH_FAILED" ) then
		DungeonGrindr:DebugPrint(event);
		return
	end
	
	if event == "GROUP_ROSTER_UPDATE" and dungeonQueue.queueStatus == queueStateEnum.inprogress then
		DungeonGrindr:LeaveQueue()
	elseif event == "GROUP_ROSTER_UPATE" and dungeonQueue.queueStatus == queueStateEnum.invitingGroup then
		if GetNumGroupMembers() == 5 then
			DungeonGrindr:LeaveQueue()
			boxFrame:Hide()
			return
		end
	end
	
	if event == "ROLE_CHANGED_INFORM" or event == "TALENT_GROUP_ROLE_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
		roleFrames.player.texture:SetTexCoord(GetTexCoordsForRole(GetTalentGroupRole(GetActiveTalentGroup())))
		MinimapButton:SetRole(GetTalentGroupRole(GetActiveTalentGroup()))
	end

	if event == "ROLE_CHANGED_INFORM" and dungeonQueue.roleCheckState == roleCheckEnum.inprogress then
		dungeonQueue.roleCheckCount = dungeonQueue.roleCheckCount + 1
		roleCheckButton:SetText(dungeonQueue.roleCheckCount .. " / " ..  GetNumGroupMembers())
		
		if dungeonQueue.roleCheckCount == GetNumGroupMembers() then
			dungeonQueue.roleCheckCount = 0
			if DungeonGrindr:IsValidStarterRoleComplete() == false then 
				DungeonGrindr:PrettyPrint("Valid groups cannot contain multiple tanks/healers or more than 3 dps")
				dungeonQueue.roleCheckState = roleCheckEnum.none
			else
				dungeonQueue.roleCheckState = roleCheckEnum.complete
			end
			
			roleCheckButton:SetText("Role Check")
		end
	end
	
	if dungeonQueue.roleCheckState == roleCheckEnum.inprogress then
		queueButton:Hide()
	else
		if dungeonQueue.dungeonId ~= nil then
			roleCheckButton:Hide()
		end
		
		if dungeonQueue.inQueue == true then 
			queueButton:Hide()
		else 
			queueButton:Show()
		end
	end
	
	if dungeonQueue.inQueue == false then
		DungeonGrindr:DebugPrint("Not in queue so returning early")
		DungeonGrindr:InvalidateUI(groupToInvite, dungeonQueue)
		return
	end

	-- ensure the user isn't navigating the group finder and looking at invalid results
	local entryData = Funcs:GetActiveEntryInfo();
	if (entryData) then
		if entryData.activityID ~= dungeonQueue.dungeonId then
			return 
		end 
	end
	
	if SPOOFING == true then 
		DungeonGrindr:DebugPrint("Spoofing thus skipping queue checker")
	end
	
	if ( event == "LFG_LIST_AVAILABILITY_UPDATE" ) then
		DungeonGrindr:DebugPrint(event);
	elseif ( event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" ) and SPOOFING == false then
		DungeonGrindr:DebugPrint(event);

		local results = select(2, Funcs:GetFilteredSearchResults());
		DungeonGrindr:EnsurePlayersStillInQueue(results)
		
		for index = 1, #results do
			if dungeonQueue.inQueue == false then break end
			
			local resultID = results[index]
			local searchResultInfo = Funcs:LFGListGetSearchResultInfo(resultID);
			local playerName = Funcs:GetSearchResultLeaderInfo(resultID);
			
			if searchResultInfo.isDelisted == true or searchResultInfo.numMembers > 1 then
				DungeonGrindr:RemovePlayerForReason(playerName, "delisted")
				DungeonGrindr:ReOrderTheDPS()
			end

			if DungeonGrindr:SearchResultContains(searchResultInfo, dungeonQueue.dungeonId) == true and searchResultInfo.isDelisted == false and searchResultInfo.numMembers == 1 then
				DungeonGrindr:CachePlayerIfFits(resultID)
			end
		end
	end
	
	DungeonGrindr:InvalidateUI(groupToInvite, dungeonQueue)
end)

function DungeonGrindr:SearchResultContains(searchResultInfo, activityId) 
	if (searchResultInfo) then
		if (searchResultInfo.activityID) then
			if searchResultInfo.activityID == activityId then return true end
		end
		
		if (searchResultInfo.activityIDs) then
			if DungeonGrindr:TableContainsValue(searchResultInfo.activityIDs, activityId) then return true end
		end
	end
	return false
end

function DungeonGrindr:InvalidateUI(groupToInvite, dungeonQueue)
	if dungeonQueue.dungeonId and DungeonGrindr:IsHeroic(dungeonQueue.dungeonId) then 
		DungeonGrindrUI.framesCollection.titleFrame.text:SetText("HC: "..dungeonQueue.dungeonName)
	else
		DungeonGrindrUI.framesCollection.titleFrame.text:SetText(dungeonQueue.dungeonName)
	end
	DungeonGrindr:InvalidateNameFrames(groupToInvite)
	DungeonGrindr:ShowRoleFrames(dungeonQueue.inQueue) -- Always show role frames if in queue
	
	-- Update UI elements for when the queue is complete
	if dungeonQueue.needs.tanks <= 0 and dungeonQueue.needs.healers <= 0 and dungeonQueue.needs.dps <= 0 then
		if inviteGroupButton:IsShown() == false then 
			PlaySound(SOUNDKIT.READY_CHECK);
		end
		boxFrame:Show()
		inviteGroupButton:Show()
		refreshFrame:Hide()
		
		-- Start timer to invalidate the invite option if the player takes too long to respond
		C_Timer.After(requireRefreshOnFullGroupAfter, function()
			inviteGroupButton:Hide()
			refreshFrame:Show() 
			dungeonQueue.queuePopTimerExpired = true
		end)
	else 
		inviteGroupButton:Hide()
	end

	if (IsInGroup() and dungeonQueue.roleCheckState == roleCheckEnum.inprogress) or dungeonQueue.inQueue == true or dungeonQueue.dungeonId == nil then 
		queueButton:Hide()
	elseif dungeonQueue.dungeonId ~= nil and dungeonQueue.inQueue == false then 
		if IsInGroup() and dungeonQueue.roleCheckState == roleCheckEnum.none then
			roleCheckButton:Show()
			queueButton:Hide()
		else
			queueButton:Show()
		end
	end
	
	if dungeonQueue.inQueue == false then 
		DungeonGrindrUI.framesCollection.titleFrame.text:SetText("")
	end
	
	DungeonGrindr:RefreshDropdown()
	DungeonGrindr:PrintGroupCache(groupToInvite)
end

function DungeonGrindr:EnsurePlayersStillInQueue(results)
	if groupToInvite.tank ~= "" then 
		local playerName = groupToInvite.tank
		if DungeonGrindr:IsPlayerInQueueAsRole(playerName, "tank", results) == false and UnitInParty(playerName) ~= true then
			dungeonQueue.needs.tanks = 1
			groupToInvite.tank = ""
			DungeonGrindr:DebugPrint("Removing TANK for not in queue: " .. playerName)
		end
	end
	
	if groupToInvite.healer ~= "" then 
		local playerName = groupToInvite.healer
		if DungeonGrindr:IsPlayerInQueueAsRole(playerName, "healer", results) == false and UnitInParty(playerName) ~= true then
			dungeonQueue.needs.healers = 1
			groupToInvite.healer = ""
			DungeonGrindr:DebugPrint("Removing HEALER for not in queue: " .. playerName)
		end
	end

	local dpsUnlistedCounter = 0
	for index = 1, #groupToInvite.dps do
		if groupToInvite.dps[index] ~= "" then
			local playerName = groupToInvite.dps[index]
			if DungeonGrindr:IsPlayerInQueueAsRole(playerName, "damager", results) == false and UnitInParty(playerName) ~= true then
				dpsUnlistedCounter = dpsUnlistedCounter + 1
				groupToInvite.dps[index] = ""
				DungeonGrindr:DebugPrint("Removing DPS #" ..tostring(index) .. " for not in queue: " .. playerName)
			end
		end
	end

	dungeonQueue.needs.dps = dungeonQueue.needs.dps + dpsUnlistedCounter
end

function DungeonGrindr:IsPlayerInQueueAsRole(playerName, role, results)
	if playerName == UnitName("player") or playerName == player then return true end
		
	local role = string.lower(role);
	for index = 1, #results do
		local resultID = results[index]
		local name, _, _, _, _, _, soloRoleTank, soloRoleHealer, soloRoleDPS = Funcs:GetSearchResultLeaderInfo(resultID);

		if name == playerName then
			-- Check to see if a player has added players to their group but is still in queue
			local searchResultInfo = Funcs:LFGListGetSearchResultInfo(resultID);
			if searchResultInfo.numMembers > 1 then return false end
		
			if role == "tank" then
				return soloRoleTank
			elseif role == "healer" then
				return soloRoleHealer
			else
				return soloRoleDPS
			end
		end		
	end
	
	return false
end

function DungeonGrindr:RemovePlayerForReason(playerName, reason)
	local dpsFrames = roleFrames.dps
	local tankFrame = roleFrames.tank
	local healerFrame = roleFrames.healer

	if groupToInvite.tank == playerName then 
		groupToInvite.tank = ""
		roleFrames.nameFrames.tank.text:SetText("")
		dungeonQueue.needs.tanks = dungeonQueue.needs.tanks + 1
		DungeonGrindr:DebugPrint("Removing player for " .. reason ..": " .. playerName)
	end
	if groupToInvite.healer == playerName then
		groupToInvite.healer = ""
		roleFrames.nameFrames.healer.text:SetText("")
		dungeonQueue.needs.healers = dungeonQueue.needs.healers + 1
		DungeonGrindr:DebugPrint("Removing player for " .. reason ..": " .. playerName)
	end
	if groupToInvite.dps[1] == playerName then
		groupToInvite.dps[1] = ""
		roleFrames.nameFrames.dps[1].text:SetText("")
		dungeonQueue.needs.dps = dungeonQueue.needs.dps + 1
		DungeonGrindr:DebugPrint("Removing player for " .. reason ..": " .. playerName)
	end
	if groupToInvite.dps[2] == playerName then
		groupToInvite.dps[2] = ""
		roleFrames.nameFrames.dps[2].text:SetText("")
		dungeonQueue.needs.dps = dungeonQueue.needs.dps + 1
		DungeonGrindr:DebugPrint("Removing player for " .. reason ..": " .. playerName)
	end
	if groupToInvite.dps[3] == playerName then
		groupToInvite.dps[3] = ""
		roleFrames.nameFrames.dps[3].text:SetText("")
		dungeonQueue.needs.dps = dungeonQueue.needs.dps + 1
		DungeonGrindr:DebugPrint("Removing player for " .. reason ..": " .. playerName)
	end
end

function DungeonGrindr:CachePlayerIfFits(resultID)
	local name, role, classFileName, className, level, areaName, soloRoleTank, soloRoleHealer, soloRoleDPS, isNewPlayerFriendly = Funcs:GetSearchResultLeaderInfo(resultID);
	
	if isNewPlayerFriendly == true and dataStore:GetIgnoreNewPlayers() then return end

	-- Guard against duplicates 
	if groupToInvite.tank == name or groupToInvite.healer == name then return end 
	for index = 1, #groupToInvite.dps do
		if groupToInvite.dps[index] == name then
			DungeonGrindr:ReOrderTheDPS()
			return
		end
	end
	
	if soloRoleTank == true and dungeonQueue.needs.tanks > 0 and DungeonGrindr:ValidateRoleIsLogical(className, "TANK") == true then
		DungeonGrindr:DebugPrint("Caching ".. name .. " as tank")
		dungeonQueue.needs.tanks = dungeonQueue.needs.tanks - 1
		groupToInvite.tank = name
		roleFrames.nameFrames.tank.text:SetText(name)
	elseif soloRoleHealer == true and dungeonQueue.needs.healers > 0 and DungeonGrindr:ValidateRoleIsLogical(className, "HEALER") == true then
		DungeonGrindr:DebugPrint("Caching ".. name .. " as healer")
		dungeonQueue.needs.healers = dungeonQueue.needs.healers - 1
		roleFrames.nameFrames.healer.text:SetText(name)
		groupToInvite.healer = name
	elseif soloRoleDPS == true and dungeonQueue.needs.dps > 0 and DungeonGrindr:ValidateRoleIsLogical(className, "DAMAGER") == true then
		DungeonGrindr:DebugPrint("Caching ".. name .. " as dps" .. tostring(dungeonQueue.needs.dps))	
		groupToInvite.dps[dungeonQueue.needs.dps] = name
		roleFrames.nameFrames.dps[dungeonQueue.needs.dps].text:SetText(name)
		dungeonQueue.needs.dps = dungeonQueue.needs.dps - 1
	end
end

function DungeonGrindr:ValidateRoleIsLogical(className, role) 
	if dataStore:GetExcludeMemeSpecs() == true then return true end

	local class = string.lower(className)
	if role == "TANK" then
		return class == "paladin" or class == "death knight" or class == "warrior" or class == "druid"
	elseif role == "HEALER" then 
		return class == "paladin" or class == "priest" or class == "shaman" or class == "druid"
	end
	
	if role == "DAMAGER" and class == "warrior" then
		return dataStore:GetExcludeMemeSpecs() == false
	end

	return true
end

function DungeonGrindr:InviteParty(dungeonId, groupToInvite)
	dungeonQueue.queueStatus = queueStateEnum.invitingGroup
	DungeonGrindr:PrettyPrint("Your Party is Ready!")
	TimeSinceLastInvite = 0

	DungeonGrindr:Invite(groupToInvite.tank, "TANK", dungeonId); 
	DungeonGrindr:Invite(groupToInvite.healer, "HEALER", dungeonId);
	DungeonGrindr:Invite(groupToInvite.dps[1], "DPS", dungeonId);
	DungeonGrindr:Invite(groupToInvite.dps[2], "DPS", dungeonId);
	DungeonGrindr:Invite(groupToInvite.dps[3], "DPS", dungeonId);
	
	if dataStore:GetAutoReinvite() == false then return end
	C_Timer.After(15, function()
		DungeonGrindr:Reinvite(groupToInvite.tank, "TANK", dungeonId); 
		DungeonGrindr:Reinvite(groupToInvite.healer, "HEALER", dungeonId);
		DungeonGrindr:Reinvite(groupToInvite.dps[1], "DPS", dungeonId);
		DungeonGrindr:Reinvite(groupToInvite.dps[2], "DPS", dungeonId);
		DungeonGrindr:Reinvite(groupToInvite.dps[3], "DPS", dungeonId);
	end)
end

function DungeonGrindr:IsHeroic(dungeonId)
	return dungeonId > 1120 or (dungeonId > 900 and dungeonId < 1000)
end

function DungeonGrindr:Invite(player, role, dungeonId)
	local activityInfo = Funcs:GetActivityInfoTable(dungeonId)

	local heroicText = ""
	if DungeonGrindr:IsHeroic(dungeonId) == true then
		heroicText = "Heroic: "
	end
	local firstMsg = "[DungeonGrindr] You are being invited to " .. heroicText .. activityInfo.fullName .. " as a " .. role
	local secondMsg = "[DungeonGrindr] If you are in a party, please drop group. You will be invited again in 15s"

	if player == "player" or player == UnitName("player") then 
		if DEBUG then 
			SendChatMessage(firstMsg, "WHISPER", nil, UnitName("player"))
			if dataStore:GetAutoReinvite() == true then 
				SendChatMessage(secondMsg, "WHISPER", nil, UnitName("player"))
			end
		end
		return
	end
	
	-- Don't message people already in the group
	for i = 1, GetNumGroupMembers() do
		local partyIndex = "party"..i
		local name = UnitName(partyIndex)
		if name == player then return end
	end
	
	if DEBUG then
		DungeonGrindr:DebugPrint("[DungeonGrindr] auto invited " .. player .." to " .. activityInfo.fullName .. " as a " .. role)
		return
	end

	DungeonGrindr:DebugPrint("[DungeonGrindr] auto invited " .. player .." to " .. activityInfo.fullName .. " as a " .. role)
	InviteUnit(player)
	SendChatMessage(firstMsg, "WHISPER", nil, player)
	
	if dataStore:GetAutoReinvite() == true then 
		SendChatMessage(secondMsg, "WHISPER", nil, player)
	end
end

function DungeonGrindr:Reinvite(player, role, dungeonId)
	if dataStore:GetAutoReinvite() == false then return end
	
	local activityInfo = Funcs:GetActivityInfoTable(dungeonId)
	local heroicText = ""
	if DungeonGrindr:IsHeroic(dungeonId) == true then
		heroicText = "Heroic: "
	end
 
	local firstMsg = "[DungeonGrindr] You are being reinvited to "  .. heroicText .. activityInfo.fullName .. " as a " .. role
 
	if player == "player" or player == UnitName("player") then 
		if DEBUG then 
			SendChatMessage(firstMsg, "WHISPER", nil, UnitName("player"))
		end
		return
	end
	
	-- Don't message people already in the group
	for i = 1, GetNumGroupMembers() do
		local partyIndex = "party"..i
		local name = UnitName(partyIndex)
		if name == player then return end
	end
	
	if DEBUG then
		DungeonGrindr:DebugPrint("[DungeonGrindr] auto invited " .. player .." to " .. activityInfo.fullName .. " as a " .. role)
		return
	end

	DungeonGrindr:DebugPrint("[DungeonGrindr] auto invited " .. player .." to " .. activityInfo.fullName .. " as a " .. role)
	InviteUnit(player)
	SendChatMessage(firstMsg, "WHISPER", nil, player)
end

function DungeonGrindr:LeaveQueue() 
	DungeonGrindr:ShowRoleFrames(false)
	refreshFrame:Hide()
	DungeonGrindrUI.framesCollection.titleFrame.text:SetText("")
	inviteGroupButton:Hide()
	
	if dungeonQueue.inQueue and dungeonQueue.dungeonName ~= "" then
		local heroicText = ""
		if DungeonGrindr:IsHeroic(dungeonQueue.dungeonId) then 
			heroicText = "HC: "
		end

		if IsInGroup() then
			SendChatMessage("[DungeonGrindr] Left queue for " .. heroicText .. tostring(dungeonQueue.dungeonName), "PARTY", nil, nil)
		else
			DungeonGrindr:PrettyPrint("[DungeonGrindr] Left queue for " .. heroicText .. tostring(dungeonQueue.dungeonName))
		end
	end
	
	-- Reset the indivual items in the object but don't override the object itself
	dungeonQueue.roleCheckState = roleCheckEnum.none
	dungeonQueue.roleCheckCount = 0
	dungeonQueue.dungeonId = dungeonQueue.dungeonId
	dungeonQueue.dungeonName = dungeonQueue.dungeonName
	dungeonQueue.inQueue = false
	dungeonQueue.queueStatus = queueStateEnum.none
	dungeonQueue.queuePopTimerExpired = false
	dungeonQueue.needs.tanks = 1
	dungeonQueue.needs.healers = 1
	dungeonQueue.needs.dps = 3
	
	groupToInvite.tank = ""
	groupToInvite.healer = ""
	groupToInvite.dps = { "", "", "" }
	
	_LFGBrowseActivityDropDown_ValueSetSelected(activityDropdown, dungeonQueue.dungeonId, true) -- ensure our dropdown stays selected

	DungeonGrindr:InvalidateUI(groupToInvite, dungeonQueue)
end

function DungeonGrindr:IsValidStarterRoleComplete()
	local groupComp = {
		tanks = 0,
		healers = 0,
		dps = 0,
	}

	if IsInGroup() then
		for i = 1, GetNumGroupMembers() do
			local partyIndex = "party"..i
			local role = UnitGroupRolesAssigned(partyIndex)
			local name = UnitName(partyIndex)
			if name == nil then
				name = "player"
				role = GetTalentGroupRole(GetActiveTalentGroup());
			end
			DungeonGrindr:DebugPrint("role for " .. name ..": " .. partyIndex .. ":" .. role)
			
			if role == "DAMAGER" then
				groupComp.dps = groupComp.dps + 1
			elseif role == "TANK" then
				groupComp.tanks = groupComp.tanks + 1
			elseif role == "HEALER" then
				groupComp.healers = groupComp.healers + 1
			end
		end
		
		if groupComp.dps > 3 or groupComp.tanks > 1 or groupComp.healers > 1 then
			return false
		else 
			return true
		end
	else
		return true
	end
end

function DungeonGrindr:ReOrderTheDPS()
	if groupToInvite.dps[2] == "" then
		groupToInvite.dps[2] = groupToInvite.dps[1]
		groupToInvite.dps[1] = ""
	end

	if groupToInvite.dps[3] == "" then
		groupToInvite.dps[3] = groupToInvite.dps[2]
		groupToInvite.dps[2] = ""
	end
end

function DungeonGrindr:InvalidateNameFrames(groupToInvite)
	local tank = groupToInvite.tank
	roleFrames.nameFrames.tank.text:SetText(tank)
	if tank == "" then
		roleFrames.tank.texture:SetDesaturated(1)
	else
		roleFrames.tank.texture:SetDesaturated(nil)
	end
	
	local healer = groupToInvite.healer
	roleFrames.nameFrames.healer.text:SetText(healer)
	if healer == "" then
		roleFrames.healer.texture:SetDesaturated(1)
	else
		roleFrames.healer.texture:SetDesaturated(nil)
	end
	
	for index = 1, #groupToInvite.dps do
		local name = groupToInvite.dps[index]
		roleFrames.nameFrames.dps[index].text:SetText(name)
		if name == "" then 
			roleFrames.dps[index].texture:SetDesaturated(1)
		else
			roleFrames.dps[index].texture:SetDesaturated(nil)
		end
	end	
end

function DungeonGrindr:AddPartyMemberToGroupComp(partyIndex, groupComp, role)
	local name = UnitName(partyIndex)
	if name == nil then name = UnitName("player") end
	
	if role == "DAMAGER" then
		groupToInvite.dps[3 - groupComp.dps] = name
		groupComp.dps = groupComp.dps + 1
	elseif role == "TANK" then
		groupComp.tanks = groupComp.tanks + 1
		groupToInvite.tank = name
	elseif role == "HEALER" then
		groupComp.healers = groupComp.healers + 1
		groupToInvite.healer = name
	end
	
	DungeonGrindr:InvalidateNameFrames(groupToInvite)
end

function DungeonGrindr:AddPlayerToGroupComp(groupComp, role)
	if role == "DAMAGER" then
		groupComp.dps = groupComp.dps + 1
		groupToInvite.dps[3] = UnitName("player")
	elseif role == "TANK" then
		groupComp.tanks = groupComp.tanks + 1
		groupToInvite.tank = UnitName("player")
	elseif role == "HEALER" then
		groupComp.healers = groupComp.healers + 1
		groupToInvite.healer = UnitName("player")
	end
	
	DungeonGrindr:InvalidateNameFrames(groupToInvite);
end

function DungeonGrindr:ShowRoleFrames(shown) 
	if shown then
		activityDropdown:Hide()
		leaveQueueButton:Show()
		roleFrames.tank:Show()
		roleFrames.healer:Show()
		for index = 1, #roleFrames.dps do 
			roleFrames.dps[index]:Show()
		end
		
		roleFrames.nameFrames.tank:Show()
		roleFrames.nameFrames.healer:Show()
		roleFrames.nameFrames.dps[1]:Show()
		roleFrames.nameFrames.dps[2]:Show()
		roleFrames.nameFrames.dps[3]:Show()
	else
		activityDropdown:Show()
		leaveQueueButton:Hide()
		roleFrames.tank:Hide()
		roleFrames.healer:Hide()
		for index = 1, #roleFrames.dps do 
			roleFrames.dps[index]:Hide()
		end
		
		
		roleFrames.nameFrames.tank:Hide()
		roleFrames.nameFrames.healer:Hide()
		roleFrames.nameFrames.dps[1]:Hide()
		roleFrames.nameFrames.dps[2]:Hide()
		roleFrames.nameFrames.dps[3]:Hide()
	end
end

function DungeonGrindr:FillGroupFor(dungeonId) 
	DungeonGrindr:LeaveQueue() 
	DungeonGrindr:DebugPrint("queue up for " .. dungeonId);
	if IsInRaid() then DungeonGrindr:PrettyPrint("Cannot queue up while in raid") return end
	DungeonGrindr:ShowRoleFrames(true) 
	
	local groupComp = {
		tanks = 0,
		healers = 0,
		dps = 0,
	}
	
	if IsInGroup() then
		for i = 1, GetNumGroupMembers() do
			local partyIndex = "party"..i
			local role = UnitGroupRolesAssigned(partyIndex)
			local name = UnitName(partyIndex)
			if name == nil then
				name = "player"
				role = GetTalentGroupRole(GetActiveTalentGroup());
			end
			DungeonGrindr:DebugPrint("role for " .. name ..": " .. partyIndex .. ":" .. role)
			DungeonGrindr:AddPartyMemberToGroupComp(partyIndex, groupComp, role)
		end
	else
		-- Role found in the players talent tree UI
		local role = GetTalentGroupRole(GetActiveTalentGroup());
		DungeonGrindr:DebugPrint("role for solo queue player: " .. role)
		DungeonGrindr:AddPlayerToGroupComp(groupComp, role)
	end
	DungeonGrindr:DebugPrint("---- Current Group: " .. groupComp["tanks"] .. ":" .. groupComp["healers"] .. ":" .. groupComp["dps"] .. " ----")

	if DungeonGrindr:IsValidStarterRoleComplete() == false then
		DungeonGrindr:LeaveQueue()
		return
	end

	dungeonQueue.dungeonId = dungeonId
	dungeonQueue.needs.tanks = 1 - groupComp.tanks
	dungeonQueue.needs.healers = 1 - groupComp.healers
	dungeonQueue.needs.dps = 3 - groupComp.dps
	dungeonQueue.inQueue = true
	dungeonQueue.queueStatus = queueStateEnum.inprogress
	dungeonQueue.queuePopTimerExpired = false
	
	local heroicText = ""
	
	if DungeonGrindr:IsHeroic(dungeonQueue.dungeonId) then 
		heroicText = "HC: "
	end
	
	if IsInGroup() then
		SendChatMessage("[DungeonGrindr] Joined queue for " .. heroicText .. tostring(dungeonQueue.dungeonName), "PARTY", nil, nil)
	else
		DungeonGrindr:PrettyPrint("Joined queue for " .. heroicText.. tostring(dungeonQueue.dungeonName))
	end

	DungeonGrindr:Retry(dungeonQueue)
end

function DungeonGrindr:Retry(dungeonQueue)
	if dungeonQueue.inQueue == false then DungeonGrindr:DebugPrint("Not in Queue") return end
	DungeonGrindr:DebugPrint("Refresh Queue")
	
	Funcs:Search(dungeonCategoryId, { dungeonQueue.dungeonId });
	
	if (Funcs:HasActiveEntryInfo()) then	
		LFGParentFrame_SearchActiveEntry();
	end
end

function DungeonGrindr:Init() 
	roleFrames.player.texture:SetTexCoord(GetTexCoordsForRole(GetTalentGroupRole(GetActiveTalentGroup())))
	DungeonGrindrUI.framesCollection.addonNameFrame.text:SetText("DungeonGrindr")
	SLASH_DungeonGrindr1 = "/dg"
	SlashCmdList["DungeonGrindr"] = function(msg) 
		DungeonGrindr:ChatCommands(msg)
	end
end

function DungeonGrindr:ChatCommands(msg)
    msg = string.lower(msg)
	local args = {}
	for word in string.gmatch(msg, "[^%s]+") do
		table.insert(args, word)
	end
    if args[1] == nil then
		if boxFrame:IsShown() then
			boxFrame:Hide()
		else 
			boxFrame:Show()
		end
	elseif args[1] == "help" then
		dataStore:SetHelpShown(false)
		T.DungeonGrindrHelp.frame:Show()
	elseif args[1] == "hide" then
		boxFrame:Hide()
	elseif args[1] == "show" then
		boxFrame:Show()
	elseif args[1] == "debug" then
		DEBUG = not DEBUG
		DungeonGrindr:PrettyPrint("Debugging: " .. tostring(DEBUG))
	elseif args[1] == "dump" then
		DEBUG = true
		DungeonGrindr:DebugPrint("GroupToInvite: " .. groupToInvite.tank .. ":" .. groupToInvite.healer .. ":" .. groupToInvite.dps[1] .. ":" .. groupToInvite.dps[2] .. ":" .. groupToInvite.dps[3] )
		DungeonGrindr:DebugPrint("dungeonQueue.needs: " .. dungeonQueue.needs.tanks .. ":" .. dungeonQueue.needs.healers .. ":" .. dungeonQueue.needs.dps )
	elseif args[1] == "spoof" then
		SPOOFING = true
		DEBUG = true
		groupToInvite = DungeonGrindr:DummyFullGroupToInvite()
		dungeonQueue = DungeonGrindr:DummyFullDungeonQueue()
		DungeonGrindr:Retry(dungeonQueue)
		DungeonGrindr:PrettyPrint("spoof")
	elseif args[1] == "spoof2" then
		SPOOFING = true
		DEBUG = true
		groupToInvite = DungeonGrindr:DummyPartialGroupToInvite()
		dungeonQueue = DungeonGrindr:DummyPartialDungeonQueue()
		DungeonGrindr:Retry(dungeonQueue)
		DungeonGrindr:PrettyPrint("spoof2")
	elseif args[1] == "unspoof" then
		SPOOFING = false
		DEBUG = false
		DungeonGrindr:LeaveQueue()
		DungeonGrindr:PrettyPrint("unspoof")
    end
end

function DungeonGrindr:DummyFullGroupToInvite() 
	return {
		tank = UnitName("player"),
		healer = "fakeHealer",
		dps = { "fake1dps", "fake2dps", "fake3dps" }
	}
end

function DungeonGrindr:DummyPartialGroupToInvite() 
	return {
		tank = UnitName("player"),
		healer = "",
		dps = { "fake1dps", "fake2dps", "fake3dps" }
	}
end

function DungeonGrindr:DummyFullDungeonQueue() 
	return {
		roleCheckState = roleCheckEnum.complete,
		roleCheckCount = 0,
		dungeonId = 1121,
		dungeonName = "FakeSpoofer",
		inQueue = true,
		needs = {
			tanks = 0,
			healers = 0,
			dps = 0,
		},
	}
end

function DungeonGrindr:DummyPartialDungeonQueue() 
	return {
		roleCheckState = roleCheckEnum.complete,
		roleCheckCount = 0,
		dungeonId = 1121,
		dungeonName = "FakeSpoofer",
		inQueue = true,
		needs = {
			tanks = 0,
			healers = 1,
			dps = 0,
		},
	}
end

-- QUEUE HANDLER 
local frame = CreateFrame("Frame")

-- The minimum number of seconds between each update
local ONUPDATE_INTERVAL = 2

-- The number of seconds since the last update
local TimeSinceLastUpdate = 0
frame:SetScript("OnUpdate", function(self, elapsed)
	TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
	if refreshFrame:IsShown() then
		TimeSinceLastUpdate = 0
		return
	end
	
	if TimeSinceLastUpdate >= ONUPDATE_INTERVAL then
		TimeSinceLastUpdate = 0
		
		local isGroupFull = (dungeonQueue.needs.tanks + dungeonQueue.needs.healers + dungeonQueue.needs.dps) <= 0
		
		if dungeonQueue.inQueue == false or (isGroupFull == true and dungeonQueue.queuePopTimerExpired == false) or inviteGroupButton:IsShown() then
			refreshFrame:Hide()
			return
		end
		refreshFrame:Show()
	end
end)

-- When the frame is shown, reset the update timer
frame:SetScript("OnShow", function(self)
	TimeSinceLastUpdate = 0
end)

function DungeonGrindr:SelectActivityId(activityId) 
	local activityInfo = C_LFGList.GetActivityInfoTable(activityId);
	dungeonQueue.dungeonName = activityInfo.shortName
	dungeonQueue.dungeonId = activityId
	DungeonGrindr:DebugPrint("dungeonId: " .. dungeonQueue.dungeonId)
	DungeonGrindr:DebugPrint("rolecheckState: " .. dungeonQueue.roleCheckState)
	
	if GetNumGroupMembers() == 0 or ROLE_BYPASS == true then
		dungeonQueue.roleCheckState = roleCheckEnum.complete
		queueButton:Show()		
	else 
		roleCheckButton:Show()
	end
	
	if dungeonQueue.roleCheckState == roleCheckEnum.complete then 
		queueButton:Show()
	end
end

-- UI BEGIN
queueButton:RegisterForClicks("AnyUp")
queueButton:SetScript("OnClick", function(self) 
	if dungeonQueue.dungeonId == nil then DungeonGrindr:PrettyPrint("You need to select a dungeon") return end
	
	DungeonGrindr:FillGroupFor(dungeonQueue.dungeonId);
end)

inviteGroupButton:RegisterForClicks("AnyUp")
inviteGroupButton:SetScript("OnClick", function(self) 
	DungeonGrindr:InviteParty(dungeonQueue.dungeonId, groupToInvite);
end)
 
refreshFrame:RegisterForClicks("AnyUp")
refreshFrame:SetScript("OnClick", function(self)
	if self:IsShown() == true then 
		self:Hide()
		DungeonGrindr:Retry(dungeonQueue)
	end
end)

roleCheckButton:RegisterForClicks("AnyUp")
roleCheckButton:SetScript("OnClick", function(self) 
	-- Ignore presses while a check in progress
	if dungeonQueue.roleCheckState == roleCheckEnum.inprogress then return end
	
	dungeonQueue.roleCheckCount = 0
	dungeonQueue.roleCheckState = roleCheckEnum.inprogress
	
	roleCheckButton:SetText(dungeonQueue.roleCheckCount .. " / " .. GetNumGroupMembers())
	InitiateRolePoll()
end)

leaveQueueButton:RegisterForClicks("AnyUp")
leaveQueueButton:SetScript("OnClick", function(self) 
	DungeonGrindr:LeaveQueue();
end)

 -- Create and bind the initialization function to the dropdown menu
UIDropDownMenu_Initialize(roleFrames.player, function(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo();
	info.text = INLINE_TANK_ICON.." "..TANK;
	info.func = self.OnSelect;
	info.classicChecks = true;
	info.arg1 = "TANK";
	info.value = info.arg1;
	info.checked = info.value == currentRole;
	UIDropDownMenu_AddButton(info);

	info.text = INLINE_HEALER_ICON.." "..HEALER;
	info.func = self.OnSelect;
	info.classicChecks = true;
	info.arg1 = "HEALER";
	info.value = info.arg1;
	info.checked = info.value == currentRole;
	UIDropDownMenu_AddButton(info);

	info.text = INLINE_DAMAGER_ICON.." "..DAMAGER;
	info.func = self.OnSelect;
	info.classicChecks = true;
	info.arg1 = "DAMAGER";
	info.value = info.arg1;
	info.checked = info.value == currentRole or currentRole == "NONE";
	UIDropDownMenu_AddButton(info);
end)

function roleFrames.player:OnSelect(newValue)
	local talentGroup = GetActiveTalentGroup()
	local currentRole = GetTalentGroupRole(talentGroup)
	SetTalentGroupRole(talentGroup, newValue)
	if currentRole ~= newValue and dungeonQueue.inQueue then 
		DungeonGrindr:LeaveQueue()
	end
	CloseDropDownMenus()
end


roleFrames.player:RegisterForClicks("AnyUp")
roleFrames.player:SetScript("OnClick", function(self) 
	ToggleDropDownMenu(1, nil, roleFrames.player, "DGPlayerTalentFrameRoleButton", 17, 4);
end)

closeButton:RegisterForClicks("AnyUp")
closeButton:SetScript("OnClick", function(self) 
	boxFrame:Hide()
end)

settingsButton:RegisterForClicks("AnyUp")
settingsButton:SetScript("OnClick", function(self) 
	if T.DungeonGrindrSettings.frame:IsShown() then
		T.DungeonGrindrSettings.frame:Hide()
	else
		T.DungeonGrindrSettings.frame:Show()
	end
end)

helpButton:RegisterForClicks("AnyUp")
helpButton:SetScript("OnClick", function(self) 
	boxFrame:Hide()
	T.DungeonGrindrHelp.frame:Show()
end)
--- UIEND
-- UI END



-- TEST
function _LFGBrowseActivityDropDown_Initialize(self, level, menuList)
	-- If we're a submenu, just display that.
	if (menuList) then
		for _, buttonInfo in pairs(menuList) do
			UIDropDownMenu_AddButton(buttonInfo, level);
		end
		return;
	end

	-- If we're not a submenu, we need to generate the full menu from the top.
	local selectedType = dungeonCategoryId -- Default to dungeonType

	if ( selectedType > 0 ) then
		UIDropDownMenu_EnableDropDown(self);
		local activities = C_LFGList.GetAvailableActivities(selectedType);

		if (#activities > 0) then
			local organizedActivities = LFGUtil_OrganizeActivitiesByActivityGroup(activities);
			local activityGroupIDs = GetKeysArray(organizedActivities);
			LFGUtil_SortActivityGroupIDs(activityGroupIDs);

			for _, activityGroupID in ipairs(activityGroupIDs) do
				local activityIDs = organizedActivities[activityGroupID];
				if (activityGroupID == 0) then
					-- Free-floating activities (no group)
					local buttonInfo = UIDropDownMenu_CreateInfo();
					buttonInfo.func = _LFGBrowseActivityButton_OnClick;
					buttonInfo.owner = self;
					buttonInfo.keepShownOnClick = true;
					buttonInfo.classicChecks = true;

					for _, activityID in pairs(activityIDs) do
						local activityInfo = C_LFGList.GetActivityInfoTable(activityID);

						buttonInfo.text = activityInfo.shortName;
						buttonInfo.value = activityID;
						buttonInfo.checked = function(self)
							return _LFGBrowseActivityDropDown_ValueIsSelected(activityDropdown, self.value);
						end;
						UIDropDownMenu_AddButton(buttonInfo, level);
					end
				else
					-- Grouped activities.
					local groupButtonInfo = UIDropDownMenu_CreateInfo();
					groupButtonInfo.func = function(self) print("did click groupButton") end; --_LFGBrowseActivityGroupButton_OnClick;
					groupButtonInfo.owner = self;
					groupButtonInfo.text = C_LFGList.GetActivityGroupInfo(activityGroupID);
					groupButtonInfo.value = activityGroupID;
					groupButtonInfo.notCheckable = true


					if (#activityGroupIDs == 1) then -- If we only have one activityGroup, do everything in one menu.
						UIDropDownMenu_AddButton(groupButtonInfo, level);

						for _, activityID in pairs(activityIDs) do
							local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
							local buttonInfo = UIDropDownMenu_CreateInfo();
							buttonInfo.func = _LFGBrowseActivityButton_OnClick;
							buttonInfo.owner = self;
							buttonInfo.keepShownOnClick = true;
							buttonInfo.classicChecks = true;

							buttonInfo.text = "  "..activityInfo.shortName; -- Extra spacing to "indent" this from the group title.
							buttonInfo.value = activityID;
							buttonInfo.checked = function(self)
								return _LFGBrowseActivityDropDown_ValueIsSelected(activityDropdown, self.value);
							end;

							UIDropDownMenu_AddButton(buttonInfo, level);
						end
					else -- If we have more than one group, do submenus.
						groupButtonInfo.hasArrow = true;
						groupButtonInfo.menuList = {};

						for _, activityID in pairs(activityIDs) do
							local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
							local buttonInfo = UIDropDownMenu_CreateInfo();
							buttonInfo.func = _LFGBrowseActivityButton_OnClick;
							buttonInfo.owner = self;
							buttonInfo.keepShownOnClick = true;
							buttonInfo.classicChecks = true;

							buttonInfo.text = activityInfo.shortName;
							buttonInfo.value = activityID;
							buttonInfo.checked = function(self)
								return _LFGBrowseActivityDropDown_ValueIsSelected(activityDropdown, self.value);
							end;
							tinsert(groupButtonInfo.menuList, buttonInfo);
						end

						UIDropDownMenu_AddButton(groupButtonInfo, level);
					end
				end
			end
		end
	else
		_LFGBrowseActivityDropDown_ValueReset(self);
		UIDropDownMenu_DisableDropDown(self);
		UIDropDownMenu_ClearAll(self);
	end

	_LFGBrowseActivityDropDown_UpdateHeader(self);
end

function _LFGBrowseActivityButton_OnClick(self)  
	_LFGBrowseActivityDropDown_ValueToggleSelected(self.owner, self.value);
	UIDropDownMenu_RefreshAll(self.owner, true);
	_LFGBrowseActivityDropDown_UpdateHeader(self.owner)
	CloseDropDownMenus()
end

function _LFGBrowseActivityDropDown_ValueIsSelected(self, value)
	return tContains(self.selectedValues, value);
end

function _LFGBrowseActivityDropDown_ValueReset(self)
	wipe(self.selectedValues);
end

function _LFGBrowseActivityDropDown_ValueToggleSelected(self, value)
	_LFGBrowseActivityDropDown_ValueSetSelected(self, value, not _LFGBrowseActivityDropDown_ValueIsSelected(self, value));
end

function _LFGBrowseActivityDropDown_ValueSetSelected(self, value, selected) 
	if (selected) then
		if (not tContains(self.selectedValues, value)) then
			wipe(self.selectedValues);
			tinsert(self.selectedValues, value);
			DungeonGrindr:SelectActivityId(value)
		end
	else
		tDeleteItem(self.selectedValues, value);
	end
end

function _LFGBrowseActivityDropDown_IsAnyValueSelectedForActivityGroup(self, activityGroupID)
	local selectedType = dungeonCategoryId;

	if ( selectedType > 0 ) then
		local activities = C_LFGList.GetAvailableActivities(selectedType);
		for i=1, #activities do
			if (LFGUtil_GetActivityGroupForActivity(activities[i]) == activityGroupID) then
				if (_LFGBrowseActivityDropDown_ValueIsSelected(self, activities[i])) then
					return true;
				end
			end
		end
	end

	return false;
end

function _LFGBrowseActivityGroupButton_OnClick(self)
	_LFGBrowseActivityDropDown_SetAllValuesForActivityGroup(self.owner, self.value, not _LFGBrowseActivityDropDown_IsAnyValueSelectedForActivityGroup(self.owner, self.value));
	UIDropDownMenu_Refresh(self.owner, true);
	_LFGBrowseActivityDropDown_UpdateHeader(self.owner);
end

function _LFGBrowseActivityDropDown_SetAllValuesForActivityGroup(self, activityGroupID, selected)
	local selectedType = dungeonCategoryId;

	if ( selectedType > 0 ) then
		local activities = C_LFGList.GetAvailableActivities(selectedType);
		for i=1, #activities do
			if (LFGUtil_GetActivityGroupForActivity(activities[i]) == activityGroupID) then
				_LFGBrowseActivityDropDown_ValueSetSelected(self, activities[i], selected);
			end
		end
	end
end

function _LFGBrowseActivityDropDown_UpdateHeader(self)
	if #self.selectedValues == 0 then
		UIDropDownMenu_SetText(self, LFGBROWSE_ACTIVITY_HEADER_DEFAULT);
	elseif #self.selectedValues == 1 then
		local activityInfo = C_LFGList.GetActivityInfoTable(self.selectedValues[1]);
		if DungeonGrindr:IsHeroic(self.selectedValues[1]) then 
			UIDropDownMenu_SetText(self, "HC: " .. activityInfo.fullName);
		else 
			UIDropDownMenu_SetText(self, activityInfo.fullName);
		end
	else
		UIDropDownMenu_SetText(self, string.format(LFGBROWSE_ACTIVITY_HEADER, #self.selectedValues));
	end
end
