local addonName, T = ...;

local dataStore = T.DungeonGrindrDataStore;
local mainFrame = T.DungeonGrindrUI.framesCollection.boxFrame

T.DungeonGrindrHelp = {}
T.DungeonGrindrHelp.frame = CreateFrame("frame", "DungeonGrindrHelp", UIParent)

local frame = T.DungeonGrindrHelp.frame
frame:SetSize(700, 300)
frame:SetMovable(true)
local t = frame:CreateTexture(nil,"BACKGROUND")
t:SetAllPoints(frame)
frame.texture = t
frame:SetPoint("CENTER",0,0)
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
titleFrame.text:SetText("Help")

local okayButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
okayButton:SetSize(100,15)
okayButton:SetPoint("BOTTOM", frame, "BOTTOM", 0,15)
okayButton:SetText("OKAY")
okayButton:RegisterForClicks("AnyUp")
okayButton:SetScript("OnClick", function(self) 
	frame:Hide()
	mainFrame:Show()
end)

local textFrame = CreateFrame("Frame", nil, frame);
textFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30);
textFrame:SetSize(700, 50);
 
local text1 = textFrame:CreateFontString(nil,"OVERLAY","GameFontNormal");
text1:SetFont("Fonts\\FRIZQT__.TTF", 11)
text1:SetJustifyH("LEFT")
text1:SetJustifyV("TOP")
text1:SetPoint("TOPLEFT");
text1:SetText("To use\n\n" ..
			  "Select a dungeon and repeatedly press `Refresh` until your group fills \n" ..
			 "Macro `/click DungeonGrindrRefresh` into your abilities to auto refresh while you play the game \n" ..
			 "Using the above /click you can close the addon and it will reopen when your group is ready \n" ..
			 "If not all players accept your invites, simply requeue for the same dungeon \n\n\n")
			 
local text2Frame = CreateFrame("Frame", nil, frame);
text2Frame:SetPoint("TOPLEFT", textFrame, "BOTTOMLEFT", 0, -40);
text2Frame:SetSize(700, 50);

local text2 = text2Frame:CreateFontString(nil,"OVERLAY","GameFontNormal");
text2:SetFont("Fonts\\FRIZQT__.TTF", 11)
text2:SetJustifyH("LEFT")
text2:SetJustifyV("TOP")
text2:SetPoint("TOPLEFT");
text2:SetText("Why does this addon exist?\n\n`nurture and protect social experiences`\n\n" ..
			 "The WOTLK dungeon content is too easy to NOT have a dungeon finder tool\n" ..
			 "This addon is mainly meant to show that users are actively looking to ignore new/unskilled players\n" ..
			 "and by not giving us RDF blizzard is actively going against their community pillar \n" ..
			 "" 			 
 )
 
local text3Frame = CreateFrame("Frame", nil, frame);
text3Frame:SetPoint("TOPLEFT", text2Frame, "BOTTOMLEFT", 0, -40);
text3Frame:SetSize(700, 50);

local text3 = text3Frame:CreateFontString(nil,"OVERLAY","GameFontNormal");
text3:SetFont("Fonts\\FRIZQT__.TTF", 11)
text3:SetJustifyH("LEFT")
text3:SetJustifyV("TOP")
text3:SetPoint("TOPLEFT");
text3:SetText("Low level dungeons?\n" ..
			 "Because of how 1-70 leveling changes and how hyper optimized the community, is players\n"..
			 "will actively avoid leveling in low level dungeons because there is no teleport in/out"
 )

-- ON LOADED
local loadFrame = CreateFrame("frame")
loadFrame:RegisterEvent("ADDON_LOADED");

loadFrame:SetScript("OnEvent", function(f, event)
	if dataStore:GetHelpShown() == false then 
		mainFrame:Hide()
		frame:Show()
		dataStore:SetHelpShown(true)
	end
	loadFrame:UnregisterEvent("ADDON_LOADED")
	print("DungeonGrindrHelp Loaded")
end)
