local addonName, T = ...;

local dataStore = T.DungeonGrindrDataStore;
local UI = T.DungeonGrindrUI

T.DungeonGrindrSettings = {}
local mainFrame = T.DungeonGrindrUI.framesCollection.boxFrame
T.DungeonGrindrSettings.frame = CreateFrame("frame", "DungeonGrindrSettings", mainFrame)

local frame = T.DungeonGrindrSettings.frame
frame:SetSize(300, 300)
local t = frame:CreateTexture(nil,"BACKGROUND")
t:SetAllPoints(frame)
frame.texture = t
frame:SetPoint("LEFT", mainFrame, "RIGHT", 10,0)
frame.texture:SetColorTexture(0, 0, 0, 0.4)
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function(self, button)
  if button == "LeftButton" and not self.isMoving then
   self:StartMoving();
   self.isMoving = true;
  end
end)
frame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" and self.isMoving then
   self:StopMovingOrSizing();
   self.isMoving = false;
  end
end)
frame:SetScript("OnHide", function(self)
  if ( self.isMoving ) then
   self:StopMovingOrSizing();
   self.isMoving = false;
  end
end)
frame:Hide()

local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
closeButton:SetSize(20,20)
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0,0)
closeButton:SetText("X")
closeButton:RegisterForClicks("AnyUp")
closeButton:SetScript("OnClick", function(self) 
	frame:Hide()
end)

local addonNameFrame = CreateFrame("Frame", nil, frame)
addonNameFrame:SetSize(30, 100)
addonNameFrame.text = addonNameFrame:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
addonNameFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE, MONOCHROME")
addonNameFrame.text:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
addonNameFrame.text:SetText("DungeonGrindr")

local titleFrame = CreateFrame("Frame", nil, frame)
titleFrame:SetSize(30, 100)
titleFrame.text = titleFrame:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
titleFrame.text:SetPoint("TOP", frame, "TOP", 0, 0)
titleFrame.text:SetText("Settings")

local allowMemeSpecsCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
allowMemeSpecsCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -20)
allowMemeSpecsCheckbox.text = allowMemeSpecsCheckbox:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
allowMemeSpecsCheckbox.text:SetPoint("LEFT", allowMemeSpecsCheckbox, "RIGHT", 0, 0)
allowMemeSpecsCheckbox.text:SetText("Exclude Meme Specs")
allowMemeSpecsCheckbox:SetScript("OnClick", function(self)
	dataStore:SetExcludeMemeSpecs(self:GetChecked())
end)

allowMemeSpecsCheckbox:SetScript("OnEnter", function(self, motion)
		GameTooltip:SetOwner(allowMemeSpecsCheckbox, "ANCHOR_TOP")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("(shaman tank, warrior dps, etc.)")
		GameTooltip:Show()
end)
allowMemeSpecsCheckbox:SetScript("OnLeave", function(self, motion)
	GameTooltip:Hide()
end)

local autoReinviteCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
autoReinviteCheckbox:SetPoint("TOPLEFT", allowMemeSpecsCheckbox, "BOTTOMLEFT", 0, -5)
autoReinviteCheckbox.text = autoReinviteCheckbox:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
autoReinviteCheckbox.text:SetPoint("LEFT", autoReinviteCheckbox, "RIGHT", 0, 0)
autoReinviteCheckbox.text:SetText("Auto reinvite")
autoReinviteCheckbox:SetScript("OnClick", function(self)
	dataStore:SetAutoReinvite(self:GetChecked())
end)

autoReinviteCheckbox:SetScript("OnEnter", function(self, motion)
		GameTooltip:SetOwner(autoReinviteCheckbox, "ANCHOR_TOP")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Automatically reinvite players after an unaccepted invitation")
		GameTooltip:Show()
end)
autoReinviteCheckbox:SetScript("OnLeave", function(self, motion)
	GameTooltip:Hide()
end)

local ignoreNewPlayersCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
ignoreNewPlayersCheckbox:SetPoint("TOPLEFT", autoReinviteCheckbox, "BOTTOMLEFT", 0, -5)
ignoreNewPlayersCheckbox.text = ignoreNewPlayersCheckbox:CreateFontString(nil,"OVERLAY", "GameFontNormal") 
ignoreNewPlayersCheckbox.text:SetPoint("LEFT", ignoreNewPlayersCheckbox, "RIGHT", 0, 0)
ignoreNewPlayersCheckbox.text:SetText("Ignore `New Players`")
ignoreNewPlayersCheckbox:SetScript("OnClick", function(self)
	dataStore:SetIgnoreNewPlayers(self:GetChecked())
end)

ignoreNewPlayersCheckbox:SetScript("OnEnter", function(self, motion)
		GameTooltip:SetOwner(ignoreNewPlayersCheckbox, "ANCHOR_TOP")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Never try to invite a player that is flagged as `New Player Friendly` in the LFG tool as they may be unskilled")
		GameTooltip:Show()
end)
ignoreNewPlayersCheckbox:SetScript("OnLeave", function(self, motion)
	GameTooltip:Hide()
end)

-- ON LOADED
local loadFrame = CreateFrame("frame")
loadFrame:RegisterEvent("ADDON_LOADED");

loadFrame:SetScript("OnEvent", function(f, event)
	allowMemeSpecsCheckbox:SetChecked(dataStore:GetExcludeMemeSpecs())
	autoReinviteCheckbox:SetChecked(dataStore:GetAutoReinvite())
	ignoreNewPlayersCheckbox:SetChecked(dataStore:GetIgnoreNewPlayers())
	print("DungeonGrindrSettings Loaded")
end)
