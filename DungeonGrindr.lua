local addonName, T = ...;

local DungeonGrindrUI = T.DungeonGrindrUI;
local Funcs = T.Funcs;

local activityDropdown = DungeonGrindrUI.framesCollection.dropDowns.dungeonDropDown
local boxFrame = DungeonGrindrUI.framesCollection.boxFrame
local queueButton = DungeonGrindrUI.framesCollection.buttons.queue
local refreshFrame = DungeonGrindrUI.framesCollection.buttons.refresh
local leaveQueueButton = DungeonGrindrUI.framesCollection.buttons.leaveQueue
local closeButton = DungeonGrindrUI.framesCollection.buttons.close
local inviteGroupButton = DungeonGrindrUI.framesCollection.buttons.inviteGroup
local roleCheckButton = DungeonGrindrUI.framesCollection.buttons.roleCheck

local roleFrames = DungeonGrindrUI.framesCollection.roleFrames

activityDropdown.selectedValues = {};

DungeonGrindr = CreateFrame("frame");

DungeonGrindr:RegisterEvent("GROUP_ROSTER_UPDATE");
DungeonGrindr:RegisterEvent("TALENT_GROUP_ROLE_CHANGED");
DungeonGrindr:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
DungeonGrindr:RegisterEvent("ROLE_CHANGED_INFORM");
DungeonGrindr:RegisterEvent("LFG_LIST_AVAILABILITY_UPDATE");
DungeonGrindr:RegisterEvent("LFG_LIST_SEARCH_FAILED");
DungeonGrindr:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED");
DungeonGrindr:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED");

local initCalled = false
local roleCheckEnum = { none = "NONE", inprogress = "INPROGRESS", complete = "COMPLETE" }

local dungeonQueue = {
	roleCheckState = roleCheckEnum.none,
	roleCheckCount = 0,
	dungeonId = nil,
	dungeonName = "",
	inQueue = false,
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

-- DEBUG BEGIN
local DEBUG = false
local DEBUGDUNGEONS = false

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
    if button == 'LeftButton' then
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
	
	if event == "GROUP_ROSTER_UPDATE" then			
		if GetNumGroupMembers() > 0 and dungeonQueue.dungeonId ~= nil then
			roleCheckButton:Show()
		else
			roleCheckButton:Hide()
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
			dungeonQueue.roleCheckState = roleCheckEnum.complete
			roleCheckButton:SetText("Role Check")
		end
	end
	
	if dungeonQueue.roleCheckState == roleCheckEnum.inprogress then
		queueButton:Hide()
	else
		if dungeonQueue.dungeonId ~= nil then
			queueButton:Show()
			roleCheckButton:Hide()
		end
	end
	
	if dungeonQueue.inQueue == false then
		DungeonGrindr:DebugPrint("Not in queue so returning early")
		return
	end

	-- ensure the user isn't navigating the group finder and looking at invalid results
	local entryData = Funcs:GetActiveEntryInfo();
	if (entryData) then
		if entryData.activityID ~= dungoneQueue.dungeonId then
			return 
		end 
	end
	
	if ( event == "LFG_LIST_AVAILABILITY_UPDATE" ) then
		DungeonGrindr:DebugPrint(event);
	elseif ( event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" ) then
		DungeonGrindr:DebugPrint(event);

		local results = select(2, Funcs:GetFilteredSearchResults());
		DungeonGrindr:EnsurePlayersStillInQueue(groupToInvite, dungeonQueue, results)
		
		for index = 1, #results do
			if dungeonQueue.inQueue == false then break end
			
			local resultID = results[index]
			local searchResultInfo = Funcs:LFGListGetSearchResultInfo(resultID);
			
			if searchResultInfo.isDelisted == true then
				DungeonGrindr:RemovePlayerForDelisted(dungeonQueue, groupToInvite, resultID)
			end

			if DungeonGrindr:SearchResultContains(searchResultInfo, dungeonQueue.dungeonId) == true and searchResultInfo.isDelisted == false and searchResultInfo.numMembers == 1 then
				DungeonGrindr:CachePlayerIfFits(dungeonQueue, groupToInvite, resultID)
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
	if dungeonQueue.dungeonId > 1120 then 
		DungeonGrindrUI.framesCollection.titleFrame.text:SetText("HC: "..dungeonQueue.dungeonName)
	else
		DungeonGrindrUI.framesCollection.titleFrame.text:SetText(dungeonQueue.dungeonName)
	end
	DungeonGrindr:UpdateNameFrames(groupToInvite)
	DungeonGrindr:ShowRoleFrames(dungeonQueue.inQueue) -- Always show role frames if in queue
	
	-- Update UI elements for when the queue is complete
	if dungeonQueue.needs.tanks <= 0 and dungeonQueue.needs.healers <= 0 and dungeonQueue.needs.dps <= 0 then
		if inviteGroupButton:IsShown() == false then 
			PlaySound(SOUNDKIT.READY_CHECK);
		end
		boxFrame:Show()
		inviteGroupButton:Show()
	end

	DungeonGrindr:PrintGroupCache(groupToInvite)
end

function DungeonGrindr:EnsurePlayersStillInQueue(groupToInvite, dungeonQueue, results)
	if groupToInvite.tank ~= "" then 
		local playerName = groupToInvite.tank
		if DungeonGrindr:IsPlayerInQueueAsRole(playerName, "tank", results) == false then
			dungeonQueue.tank = 1
			groupToInvite.tank = ""
			DungeonGrindr:SetFrameColor(roleFrames.tank, "red")
			DungeonGrindr:DebugPrint("Removing TANK for not in queue: " .. playerName)
		end
	end
	
	if groupToInvite.healer ~= "" then 
		local playerName = groupToInvite.healer
		if DungeonGrindr:IsPlayerInQueueAsRole(playerName, "healer", results) == false then
			dungeonQueue.healer = 1
			groupToInvite.healer = ""
			DungeonGrindr:SetFrameColor(roleFrames.healer, "red")
			DungeonGrindr:DebugPrint("Removing HEALER for not in queue: " .. playerName)
		end
	end
	
	for index = 1, #groupToInvite.dps do
		if groupToInvite.dps[index] ~= "" then
			local playerName = groupToInvite.dps[index]
			if DungeonGrindr:IsPlayerInQueueAsRole(playerName, "damager", results) == false then
				dungeonQueue.dps = dungeonQueue.dps + 1
				groupToInvite.dps[index] = ""
				DungeonGrindr:SetFrameColor(roleFrames.dps[index], "red")
				DungeonGrindr:DebugPrint("Removing DPS #" ..tostring(index) .. " for not in queue: " .. playerName)
			end
		end
	end	
end

function DungeonGrindr:IsPlayerInQueueAsRole(playerName, role, results)
	if playerName == UnitName("player") or playerName == player then return true end
	
	local role = string.lower(role);
	for index = 1, #results do
		local resultID = results[index]
		local name, _, _, _, _, _, soloRoleTank, soloRoleHealer, soloRoleDPS = Funcs:GetSearchResultLeaderInfo(resultID);
	
		if name == playerName then
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

function DungeonGrindr:RemovePlayerForDelisted(dungeonQueue, groupToInvite, resultID)
	local dpsFrames = roleFrames.dps
	local tankFrame = roleFrames.tank
	local healerFrame = roleFrames.healer
	
	local name = Funcs:GetSearchResultLeaderInfo(resultID);
	if groupToInvite.tank == name then 
		groupToInvite.tank = ""
		DungeonGrindr:SetFrameColor(tankFrame, "red")
		roleFrames.nameFrames.tank.text:SetText("")
		dungeonQueue.needs.tanks = dungeonQueue.needs.tanks + 1
		DungeonGrindr:DebugPrint("Removing player for delist: " .. name)
	elseif groupToInvite.healer == name then
		groupToInvite.healer = ""
		DungeonGrindr:SetFrameColor(healerFrame, "red")
		roleFrames.nameFrames.healer.text:SetText("")
		dungeonQueue.needs.healers = dungeonQueue.needs.healers + 1
		DungeonGrindr:DebugPrint("Removing player for delist: " .. name)
	elseif groupToInvite.dps[1] == name then
		groupToInvite.dps[1] = ""
		DungeonGrindr:SetFrameColor(dpsFrames[1], "red")
		roleFrames.nameFrames.dps[1].text:SetText("")
		dungeonQueue.needs.dps = dungeonQueue.needs.dps + 1
		DungeonGrindr:DebugPrint("Removing player for delist: " .. name)
	elseif groupToInvite.dps[2] == name then
		groupToInvite.dps[2] = ""
		DungeonGrindr:SetFrameColor(dpsFrames[2], "red")
		roleFrames.nameFrames.dps[2].text:SetText("")
		dungeonQueue.needs.dps = dungeonQueue.needs.dps + 1
		DungeonGrindr:DebugPrint("Removing player for delist: " .. name)
	elseif groupToInvite.dps[3] == name then
		groupToInvite.dps[3] = ""
		DungeonGrindr:SetFrameColor(dpsFrames[3], "red")
		roleFrames.nameFrames.dps[3].text:SetText("")
		dungeonQueue.needs.dps = dungeonQueue.needs.dps + 1
		DungeonGrindr:DebugPrint("Removing player for delist: " .. name)
	end
end

function DungeonGrindr:CachePlayerIfFits(dungeonQueue, groupToInvite, resultID)
	local name, role, classFileName, className, level, areaName, soloRoleTank, soloRoleHealer, soloRoleDPS = Funcs:GetSearchResultLeaderInfo(resultID);
	
	-- Guard against duplicates 
	if groupToInvite.tank == name or groupToInvite.healer == name then return end 
	for index = 1, #groupToInvite.dps do
		if groupToInvite.dps[index] == name then return end
	end
	
	if soloRoleTank == true and dungeonQueue.needs.tanks > 0 and DungeonGrindr:ValidateRoleIsLogical(className, "TANK") == true then
		dungeonQueue.needs.tanks = dungeonQueue.needs.tanks - 1
		groupToInvite.tank = name
		roleFrames.nameFrames.tank.text:SetText(name)
		DungeonGrindr:SetFrameColor(roleFrames.tank, "green")
	elseif soloRoleHealer == true and dungeonQueue.needs.healers > 0 and DungeonGrindr:ValidateRoleIsLogical(className, "HEALER") == true then
		dungeonQueue.needs.healers = dungeonQueue.needs.healers - 1
		roleFrames.nameFrames.healer.text:SetText(name)
		groupToInvite.healer = name
		DungeonGrindr:SetFrameColor(roleFrames.healer, "green")
	elseif soloRoleDPS == true and dungeonQueue.needs.dps > 0 and DungeonGrindr:ValidateRoleIsLogical(className, "DAMAGER") == true then	
		groupToInvite.dps[dungeonQueue.needs.dps] = name
		roleFrames.nameFrames.dps[dungeonQueue.needs.dps].text:SetText(name)
		DungeonGrindr:SetFrameColor(roleFrames.dps[dungeonQueue.needs.dps], "green")
		
		dungeonQueue.needs.dps = dungeonQueue.needs.dps - 1
	end
end

function DungeonGrindr:ValidateRoleIsLogical(className, role) 
	local class = string.lower(className)
	if role == "TANK" then
		return class == "paladin" or class == "death knight" or class == "warrior" or class == "druid"
	elseif role == "HEALER" then 
		return class == "paladin" or class == "priest" or class == "shaman" or class == "druid"
	end
	
	if role == "DAMAGER" and class == "warrior" then
		return not DungeonGrindrUI.framesCollection.checkBoxes.blackList:GetChecked()
	end

	return true
end

function DungeonGrindr:InviteParty(dungeonId, groupToInvite, firstCall)
	DungeonGrindr:PrettyPrint("Your Party is Ready!")
	TimeSinceLastInvite = 0

	-- Set to heroic
	SetDungeonDifficultyID(2);

	DungeonGrindr:Invite(groupToInvite.tank, "TANK", dungeonId); 
	DungeonGrindr:Invite(groupToInvite.healer, "HEALER", dungeonId);
	DungeonGrindr:Invite(groupToInvite.dps[1], "DPS", dungeonId);
	DungeonGrindr:Invite(groupToInvite.dps[2], "DPS", dungeonId);
	DungeonGrindr:Invite(groupToInvite.dps[3], "DPS", dungeonId);
	
	if firstCall == false then return end
	
	C_Timer.After(15, function() DungeonGrindr:InviteParty(dungeonQueue.dungeonId, groupToInvite, false) end)
end

function DungeonGrindr:Invite(player, role, dungeonId) 
	if player == "player" or player == UnitName("player") then return end
	
	for i = 1, GetNumGroupMembers() do
		local partyIndex = "party"..i
		local name = UnitName(partyIndex)
		if name == player then return end
	end
	
	if DEBUG then
		local activityInfo = Funcs:GetActivityInfoTable(dungeonId)
		DungeonGrindr:DebugPrint("[DungeonGrindr] auto invited " .. player .." to " .. activityInfo.fullName .. " as a " .. role)
		return
	end
	
	
	local activityInfo = Funcs:GetActivityInfoTable(dungeonId)
	DungeonGrindr:DebugPrint("[DungeonGrindr] auto invited " .. player .." to " .. activityInfo.fullName .. " as a " .. role)
	InviteUnit(player)
	SendChatMessage("[DungeonGrindr] You were queued and invited for |cFFFFFF00" .. activityInfo.fullName .. "|r as a |cFFFF0000" .. role .. "|r", "WHISPER", nil, player)
	SendChatMessage("[DungeonGrindr] If you are in a party, please drop group. You will be invited again in 15s", "WHISPER", nil, player)
end


function DungeonGrindr:ResetRoleFrames() 
	DungeonGrindr:SetFrameColor(roleFrames.tank, "red")
	DungeonGrindr:SetFrameColor(roleFrames.healer, "red")
	DungeonGrindr:SetFrameColor(roleFrames.dps[1], "red")
	DungeonGrindr:SetFrameColor(roleFrames.dps[2], "red")
	DungeonGrindr:SetFrameColor(roleFrames.dps[3], "red")
end

function DungeonGrindr:LeaveQueue() 
	DungeonGrindr:ShowRoleFrames(false)
	DungeonGrindr:ResetRoleFrames()
	refreshFrame:Hide()
	DungeonGrindrUI.framesCollection.titleFrame.text:SetText("")
	inviteGroupButton:Hide()
	
	if dungeonQueue.inQueue and dungeonQueue.dungeonName ~= "" then
		if IsInGroup() then
			SendChatMessage("[DungeonGrindr] Left queue for " .. tostring(dungeonQueue.dungeonName), "PARTY", nil, nil)
		else
			DungeonGrindr:PrettyPrint("[DungeonGrindr] Left queue for " .. tostring(dungeonQueue.dungeonName))
		end
	end
	
	-- Reset the indivual items in the object but don't override the object itself
	dungeonQueue.roleCheckState = roleCheckEnum.none
	dungeonQueueroleCheckCount = 0
	dungeonQueue.dungeonId = dungeonQueue.dungeonId
	dungeonQueue.dungeonName = dungeonQueue.dungeonName
	dungeonQueue.inQueue = false
	dungeonQueue.needs.tanks = 1
	dungeonQueue.needs.healers = 1
	dungeonQueue.needs.dps = 3
	
	groupToInvite.tank = ""
	groupToInvite.healer = ""
	groupToInvite.dps = { "", "", "" }

	DungeonGrindr:UpdateNameFrames(groupToInvite)
	DungeonGrindr:InvalidateUI(groupToInvite, dungeonQueue)
end

function DungeonGrindr:UpdateNameFrames(groupToInvite)
	roleFrames.nameFrames.tank.text:SetText(groupToInvite.tank)
	roleFrames.nameFrames.healer.text:SetText(groupToInvite.healer)
	roleFrames.nameFrames.dps[1].text:SetText(groupToInvite.dps[1])
	roleFrames.nameFrames.dps[2].text:SetText(groupToInvite.dps[2])
	roleFrames.nameFrames.dps[3].text:SetText(groupToInvite.dps[3])
end

function DungeonGrindr:AddPartyMemberToGroupComp(partyIndex, groupComp, role)
	local name = UnitName(partyIndex)
	if name == nil then name = UnitName("player") end
	
	if role == "DAMAGER" then
		groupToInvite.dps[3 - groupComp.dps] = name
		groupComp.dps = groupComp.dps + 1
		DungeonGrindr:SetFrameColor(roleFrames.dps[3], "green")
	elseif role == "TANK" then
		groupComp.tanks = groupComp.tanks + 1
		groupToInvite.tank = name
		DungeonGrindr:SetFrameColor(roleFrames.tank, "green")
	elseif role == "HEALER" then
		groupComp.healers = groupComp.healers + 1
		groupToInvite.healer = name
		DungeonGrindr:SetFrameColor(roleFrames.healer, "green")
	end
	
	DungeonGrindr:UpdateNameFrames(groupToInvite)
end

function DungeonGrindr:AddPlayerToGroupComp(groupComp, role)
	if role == "DAMAGER" then
		groupComp.dps = groupComp.dps + 1
		groupToInvite.dps[3] = UnitName("player")
		DungeonGrindr:SetFrameColor(roleFrames.dps[3], "green")
	elseif role == "TANK" then
		groupComp.tanks = groupComp.tanks + 1
		groupToInvite.tank = UnitName("player")
		DungeonGrindr:SetFrameColor(roleFrames.tank, "green")
	elseif role == "HEALER" then
		groupComp.healers = groupComp.healers + 1
		groupToInvite.healer = UnitName("player")
		DungeonGrindr:SetFrameColor(roleFrames.healer, "green")
	end
	
	DungeonGrindr:UpdateNameFrames(groupToInvite);
end

function DungeonGrindr:ShowRoleFrames(shown) 
	if shown then
		activityDropdown:Hide()
		queueButton:Hide()
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
		queueButton:Show()
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
	
	dungeonQueue.dungeonId = dungeonId
	dungeonQueue.needs.tanks = 1 - groupComp.tanks
	dungeonQueue.needs.healers = 1 - groupComp.healers
	dungeonQueue.needs.dps = 3 - groupComp.dps
	dungeonQueue.inQueue = true
	
	if IsInGroup() then
		SendChatMessage("[DungeonGrindr] Joined queue for " .. tostring(dungeonQueue.dungeonName), "PARTY", nil, nil)
	else
		DungeonGrindr:PrettyPrint("Joined queue for " .. tostring(dungeonQueue.dungeonName))
	end
	
	DungeonGrindr:Retry(dungeonQueue, true)
end

function DungeonGrindr:Retry(dungeonQueue, tryAgain)
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
		print("DungeonGrindrUI[1]: " .. tostring(DungeonGrindrUI[1]))
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
		boxFrame:Show()
	elseif args[1] == "hide" then
		boxFrame:Hide()
	elseif args[1] == "show" then
		boxFrame:Show()
	elseif args[1] == "debug" then
		DEBUG = not DEBUG
		DungeonGrindr:PrettyPrint("Debugging: " .. tostring(DEBUG))
    end
end

function DungeonGrindr:SetFrameColor(frame, color)
	if frame == nil then return end 
	
	if string.lower(color) == "red" then
		frame.texture:SetDesaturated(1)
	elseif string.lower(color) == "green" then
		frame.texture:SetDesaturated(nil)
	end
end

-- QUEUE HANDLER 
local frame = CreateFrame("Frame")

-- The minimum number of seconds between each update
local ONUPDATE_INTERVAL = 2

-- The number of seconds since the last update
local TimeSinceLastUpdate = 0
frame:SetScript("OnUpdate", function(self, elapsed)
	TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
		
	if TimeSinceLastUpdate >= ONUPDATE_INTERVAL then
		TimeSinceLastUpdate = 0
		
		local isGroupFull = (dungeonQueue.needs.tanks + dungeonQueue.needs.healers + dungeonQueue.needs.dps) >= 5
		
		if dungeonQueue.inQueue == false or isGroupFull == true then return end
		DungeonGrindr:DebugPrint("OnUpdate Queue search")
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
	
	if GetNumGroupMembers() == 0 then
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
	DungeonGrindr:InviteParty(dungeonQueue.dungeonId, groupToInvite, true);
end)
 
refreshFrame:RegisterForClicks("AnyUp")
refreshFrame:SetScript("OnClick", function(self)
	if self:IsShown() == true then 
		DungeonGrindr:Retry(dungeonQueue, false)
		self:Hide()
	end
end)
 
roleCheckButton:RegisterForClicks("AnyUp")
roleCheckButton:SetScript("OnClick", function(self) 
	-- Ignore presses while a check in progress
	if dungeonQueue.roleCheckState == roleCheckEnum.inprogress then return end
	
	dungeonQueue.roleCheckState = roleCheckEnum.inprogress
	dungeonQueue.roleCheckCount = 0
	
	roleCheckButton:SetText("0 / " .. GetNumGroupMembers())
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
		if self.selectedValues[1] > 1120 then 
			UIDropDownMenu_SetText(self, "HC: " .. activityInfo.fullName);
		else 
			UIDropDownMenu_SetText(self, activityInfo.fullName);
		end
	else
		UIDropDownMenu_SetText(self, string.format(LFGBROWSE_ACTIVITY_HEADER, #self.selectedValues));
	end
end