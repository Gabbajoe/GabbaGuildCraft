local _, GT = ...
local L = GT.L
local button

local function updatePosition()
    local angle = math.rad(GabbaGuildCraftDB.minimapAngle)
    local radius = (Minimap:GetWidth() or 140) / 2 + 10
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", radius * math.cos(angle), radius * math.sin(angle))
end

local function drag()
    local mx, my = Minimap:GetCenter()
    if not mx or not my then return end
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    GabbaGuildCraftDB.minimapAngle = math.deg(math.atan2(y / scale - my, x / scale - mx))
    updatePosition()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    if type(GabbaGuildCraftDB) ~= "table" then GabbaGuildCraftDB = {} end
    local angle = tonumber(GabbaGuildCraftDB.minimapAngle)
    if not angle or angle ~= angle or math.abs(angle) == math.huge then angle = 220 end
    GabbaGuildCraftDB.minimapAngle = angle % 360
    if not Minimap or button then return end
    button = CreateFrame("Button", "GabbaGuildCraftMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\GabbaGuildCraft\\Assets\\Minimap.tga")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    button:SetScript("OnMouseDown", function(self) self.dragged = false end)
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" and not self.dragged then GT.ToggleWindow() end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("GabbaGuildCraft")
        GameTooltip:AddLine(L("Linksklick: Rezeptfenster öffnen / schließen"), 1, 1, 1)
        GameTooltip:AddLine(L("Ziehen: Symbol an der Minimap verschieben"), 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        self.dragged = true
        GameTooltip:Hide()
        self:SetScript("OnUpdate", drag)
    end)
    local function stopDrag(self)
        self:SetScript("OnUpdate", nil)
        GameTooltip:Hide()
    end
    button:SetScript("OnDragStop", stopDrag)
    button:SetScript("OnHide", stopDrag)
    updatePosition()
end)
