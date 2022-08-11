local addonName, T = ...;
T.DungeonGrindrUI = {}

local boxFrame = CreateFrame("Frame", "DungeonGrindrMain", UIParent)
boxFrame:SetSize(420, 130)
boxFrame:SetMovable(true)
local t = boxFrame:CreateTexture(nil,"BACKGROUND")
t:SetAllPoints(boxFrame)
boxFrame.texture = t
boxFrame:SetPoint("CENTER",0,0)
boxFrame.texture:SetColorTexture(0, 0, 0, 0.4)
boxFrame:EnableMouse(true)
boxFrame:SetScript("OnMouseDown", function(self, button)
  if button == "LeftButton" and not self.isMoving then
   self:StartMoving();
   self.isMoving = true;
  end
end)
boxFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and self.isMoving then
   self:StopMovingOrSizing();
   self.isMoving = false;
  end
end)
boxFrame:SetScript("OnHide", function(self)
  if ( self.isMoving ) then
   self:StopMovingOrSizing();
   self.isMoving = false;
  end
end)
boxFrame:Show()

local dungeonNameFrame = CreateFrame("Frame", nil, boxFrame)
dungeonNameFrame:SetSize(30, 100)
dungeonNameFrame.text = dungeonNameFrame:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
dungeonNameFrame.text:SetPoint("TOP", boxFrame, "TOP", 0, 0)
dungeonNameFrame.text:SetText("")

local addonNameFrame = CreateFrame("Frame", nil, boxFrame)
addonNameFrame:SetSize(30, 100)
addonNameFrame.text = addonNameFrame:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
addonNameFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE, MONOCHROME")
addonNameFrame.text:SetPoint("BOTTOM", boxFrame, "BOTTOM", 0, 0)
addonNameFrame.text:SetText("")

local tankFrame = CreateFrame("Frame", nil, boxFrame)
tankFrame:SetSize(30, 30)
local tf = tankFrame:CreateTexture(nil,"BACKGROUND")
tf:SetAllPoints(tankFrame)
tankFrame.texture = tf
tankFrame:SetPoint("LEFT", 20,0, "LEFT")
tankFrame.texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
tankFrame.texture:SetTexCoord(GetTexCoordsForRole("TANK"))
tankFrame.texture:SetDesaturated(1)
tankFrame:Hide()

local tankNameFrame = CreateFrame("Frame", nil, tankFrame)
tankNameFrame:SetSize(30, 100)
tankNameFrame.text = tankNameFrame:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
tankNameFrame.text:SetPoint("TOP", tankFrame, "BOTTOM", 0, 0)
tankNameFrame.text:SetText("")
tankNameFrame:Hide()

local healerFrame = CreateFrame("Frame", nil, tankFrame)
healerFrame:SetSize(30, 30)
local hf = healerFrame:CreateTexture(nil,"BACKGROUND")
hf:SetAllPoints(healerFrame)
healerFrame.texture = hf
healerFrame:SetPoint("LEFT", 80, 0)
healerFrame.texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
healerFrame.texture:SetTexCoord(GetTexCoordsForRole("HEALER"))
healerFrame.texture:SetDesaturated(1)
healerFrame:Hide()

local healerNameFrame = CreateFrame("Frame", nil, healerFrame)
healerNameFrame:SetSize(30, 100)
healerNameFrame.text = healerNameFrame:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
healerNameFrame.text:SetPoint("TOP", healerFrame, "BOTTOM", 0, 0)
healerNameFrame.text:SetText("")
healerNameFrame:Hide()

local dpsFrame = CreateFrame("Frame", nil, healerFrame)
dpsFrame:SetSize(30, 30)
local df = dpsFrame:CreateTexture(nil,"BACKGROUND")
df:SetAllPoints(dpsFrame)
dpsFrame.texture = df
dpsFrame:SetPoint("LEFT", 80, 0)
dpsFrame.texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
dpsFrame.texture:SetTexCoord(GetTexCoordsForRole("DAMAGER"))
dpsFrame.texture:SetDesaturated(1)
dpsFrame:Hide()

local dpsNameFrame = CreateFrame("Frame", nil, dpsFrame)
dpsNameFrame:SetSize(30, 100)
dpsNameFrame.text = dpsNameFrame:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
dpsNameFrame.text:SetPoint("TOP", dpsFrame, "BOTTOM", 0, 0)
dpsNameFrame.text:SetText("")
dpsNameFrame:Hide()

local dps2Frame = CreateFrame("Frame", nil, dpsFrame)
dps2Frame:SetSize(30, 30)
local d2f = dps2Frame:CreateTexture(nil,"BACKGROUND")
d2f:SetAllPoints(dps2Frame)
dps2Frame.texture = d2f
dps2Frame:SetPoint("LEFT", 80, 0)
dps2Frame.texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
dps2Frame.texture:SetTexCoord(GetTexCoordsForRole("DAMAGER"))
dps2Frame.texture:SetDesaturated(1)
dps2Frame:Hide()

local dps2NameFrame = CreateFrame("Frame", nil, dps2Frame)
dps2NameFrame:SetSize(30, 100)
dps2NameFrame.text = dps2NameFrame:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
dps2NameFrame.text:SetPoint("TOP", dps2Frame, "BOTTOM", 0, 0)
dps2NameFrame.text:SetText("")
dps2NameFrame:Hide()

local dps3Frame = CreateFrame("Frame", nil, dps2Frame)
dps3Frame:SetSize(30, 30)
local d3f = dps3Frame:CreateTexture(nil,"BACKGROUND")
d3f:SetAllPoints(dps3Frame)
dps3Frame.texture = d3f
dps3Frame:SetPoint("LEFT", 80, 0)
dps3Frame.texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
dps3Frame.texture:SetTexCoord(GetTexCoordsForRole("DAMAGER"))
dps3Frame.texture:SetDesaturated(1)
dps3Frame:Hide()

local dps3NameFrame = CreateFrame("Frame", nil, dps3Frame)
dps3NameFrame:SetSize(30, 100)
dps3NameFrame.text = dps3NameFrame:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
dps3NameFrame.text:SetPoint("TOP", dps3Frame, "BOTTOM", 0, 0)
dps3NameFrame.text:SetText("")
dps3NameFrame:Hide()

local refreshFrame = CreateFrame("Button", "DungeonGrindrRefresh", boxFrame, "UIPanelButtonTemplate");
refreshFrame:SetSize(60,20)
refreshFrame:SetPoint("BOTTOMRIGHT",0,0, "BOTTOMRIGHT")
refreshFrame:SetText("Refresh")
refreshFrame:Hide()

local inviteGroupButton = CreateFrame("Button", "DungeonGrindrRefresh", boxFrame, "UIPanelButtonTemplate");
inviteGroupButton:SetSize(100,20)
inviteGroupButton:SetPoint("BOTTOMRIGHT", boxFrame, "BOTTOMRIGHT", 0,0)
inviteGroupButton:SetText("INVITE GROUP")
inviteGroupButton:Hide()

local leaveQueueButton = CreateFrame("Button", "DungeonGrindrRefresh", boxFrame, "UIPanelButtonTemplate");
leaveQueueButton:SetSize(80,20)
leaveQueueButton:SetPoint("BOTTOMLEFT",0,0, "BOTTOMLEFT")
leaveQueueButton:SetText("Leave Queue")
leaveQueueButton:Hide()

local roleCheckButton = CreateFrame("Button", "DungeonGrindrRoleCheck", boxFrame, "UIPanelButtonTemplate");
roleCheckButton:SetSize(100,20)

local queueButton = CreateFrame("Button", "DungeonGrindrRefresh", boxFrame, "UIPanelButtonTemplate");
queueButton:SetSize(100,20)
queueButton:SetText("QUEUE")
queueButton:Hide()

 
-- Create the dropdown, and configure its appearance
local activityDropdown = CreateFrame("FRAME", "DGDropDown", boxFrame, "UIDropDownMenuTemplate")
activityDropdown:SetPoint("CENTER", boxFrame, "CENTER", 0, 0)
roleCheckButton:SetPoint("TOPRIGHT", activityDropdown, "CENTER", -5,-15)
queueButton:SetPoint("TOPLEFT", activityDropdown, "CENTER", 5, -15)
UIDropDownMenu_SetWidth(activityDropdown, 150)


roleCheckButton:SetText("Role Check")
roleCheckButton:Hide()


local closeButton = CreateFrame("Button", nil, boxFrame, "UIPanelButtonTemplate");
closeButton:SetSize(20,20)
closeButton:SetPoint("TOPRIGHT", boxFrame, "TOPRIGHT", 0,0)
closeButton:SetText("X")

local settingsButton = CreateFrame("Button", nil, boxFrame, "UIPanelButtonTemplate");
settingsButton:SetSize(20,20)
settingsButton:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", 0,0)
settingsButton:SetText("S")


local playerRoleFrame = CreateFrame("Button", "DGPlayerTalentFrameRoleButton", boxFrame)
playerRoleFrame:SetSize(30, 30)
local pRF = playerRoleFrame:CreateTexture(nil,"BACKGROUND")
pRF:SetAllPoints(playerRoleFrame)
playerRoleFrame.texture = pRF
playerRoleFrame:SetPoint("TOPLEFT", 0, 0, "TOPLEFT")
playerRoleFrame.texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
playerRoleFrame.texture:SetTexCoord(GetTexCoordsForRole("DAMAGER"))

local buttons = { 
	refresh = refreshFrame,
	queue = queueButton,
	leaveQueue = leaveQueueButton,
	close = closeButton,
	settings = settingsButton,
	inviteGroup = inviteGroupButton,
	roleCheck = roleCheckButton
}

local dropDowns = {
	dungeonDropDown = activityDropdown,
}

local dpsFrames = { dpsFrame, dps2Frame, dps3Frame };
local dpsNameFrames = { dpsNameFrame, dps2NameFrame, dps3NameFrame };
local roleFrames = {
	nameFrames = { 
		tank = tankNameFrame,
		healer = healerNameFrame,
		dps = dpsNameFrames
	},
	player = playerRoleFrame,
	tank = tankFrame,
	healer = healerFrame,
	dps = dpsFrames,
}

T.DungeonGrindrUI.framesCollection = { 
	roleFrames = roleFrames,
	titleFrame = dungeonNameFrame,
	addonNameFrame = addonNameFrame,
	boxFrame = boxFrame,
	buttons = buttons,
	dropDowns = dropDowns,
}
