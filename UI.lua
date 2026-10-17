local _, GT = ...
local window, recipes, pages, page = nil, {}, {}, 1
local generation = 0

local function button(parent, text, width, x, y, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 26)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end

local function showPage()
    window.output:SetText(pages[page] or "")
    window.output:SetCursorPosition(0)
    window.scroll:SetVerticalScroll(0)
    window.counter:SetText(#pages > 0 and ("Nachricht " .. page .. " / " .. #pages) or "Keine Nachricht")
    window.previous:SetEnabled(page > 1)
    window.next:SetEnabled(page < #pages)
end

local function exportOptions()
    local _, _, _, interface = GetBuildInfo()
    return {
        query = window.search:GetText(), links = window.links:GetChecked(),
        relevantOnly = window.relevant:GetChecked(), minimumLevel = window.minimum:GetText(),
        player = UnitName("player") .. "-" .. GetRealmName(),
        prefix = interface >= 20000 and "tbc" or "classic",
        exportedAt = date and date("%d.%m.%Y %H:%M") or "unbekannt",
    }
end

local function render()
    if not window.output then return end
    if window.reload then window.reload:Disable() end
    local count, pending
    pages, count, pending = GT.BuildPages(recipes, exportOptions())
    page = 1
    showPage()
    window.status:SetText((recipes.profession or "Beruf") .. ": " .. count .. " passende Rezepte · " .. #recipes .. " eingelesen")
    if pending > 0 then
        window.status:SetText(count .. " passende Rezepte · " .. pending .. " ohne Itemdaten ausgeblendet; erneut einlesen")
    end
end

local function scan()
    window.reload:Disable()
    generation = generation + 1
    local current = generation
    local result, err = GT.Scan()
    if not result then
        recipes, pages, page = {}, {}, 1
        showPage()
        window.status:SetText(err)
        return
    end
    recipes = result
    local attempts = 0
    local function refresh()
        if current ~= generation then return end
        local pending = GT.Enrich(recipes)
        render()
        if pending > 0 then
            attempts = attempts + 1
            window.status:SetText(attempts < 8 and "Gegenstandsdaten werden geladen …"
                or "Einige Daten fehlen noch. Bitte erneut einlesen.")
            if attempts < 8 then C_Timer.After(0.5, refresh) end
        end
    end
    refresh()
end

local function createWindow()
    window = CreateFrame("Frame", "GabbaGuildCraftWindow", UIParent, "BackdropTemplate")
    window:SetSize(740, 620)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16})
    window:SetBackdropColor(0.055, 0.065, 0.10, 0.98)
    window:SetBackdropBorderColor(0.65, 0.49, 0.25, 1)
    tinsert(UISpecialFrames, "GabbaGuildCraftWindow")
    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 22, -20)
    title:SetText("GabbaGuildCraft | Berufe für deine Gilde")
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    local help = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", 22, -50)
    help:SetText("Beruf öffnen > Berufsfilter zurücksetzen > Rezepte einlesen > Text kopieren")
    button(window, "Rezepte einlesen", 145, 22, -78, scan)
    window.search = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    window.search:SetSize(210, 26)
    window.search:SetPoint("TOPLEFT", 225, -78)
    window.search:SetAutoFocus(false)
    window.search:SetMaxLetters(100)
    window.search:SetScript("OnTextChanged", render)
    window.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local label = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("RIGHT", window.search, "LEFT", -10, 0)
    label:SetText("Suche")
    window.links = CreateFrame("CheckButton", "GabbaGuildCraftLinks", window, "UICheckButtonTemplate")
    window.links:SetPoint("TOPLEFT", 465, -78)
    window.links.text:SetText("Wowhead-Links")
    window.links:SetChecked(true)
    window.links:SetScript("OnClick", render)
    window.relevant = CreateFrame("CheckButton", "GabbaGuildCraftRelevant", window, "UICheckButtonTemplate")
    window.relevant:SetPoint("TOPLEFT", 20, -112)
    window.relevant.text:SetText("Nur relevante Items")
    window.relevant:SetChecked(true)
    window.relevant:SetScript("OnClick", render)
    local minimumLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    minimumLabel:SetPoint("TOPLEFT", 230, -121)
    minimumLabel:SetText("Ausrüstung ab Level:")
    window.minimum = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    window.minimum:SetSize(40, 24)
    window.minimum:SetPoint("TOPLEFT", 365, -115)
    window.minimum:SetAutoFocus(false)
    window.minimum:SetNumeric(true)
    window.minimum:SetMaxLetters(2)
    window.minimum:SetText("20")
    window.minimum:SetScript("OnTextChanged", render)
    window.minimum:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local filterHelp = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    filterHelp:SetPoint("TOPLEFT", 435, -121)
    filterHelp:SetText("Taschen, Verbrauch & Verzauberungen")
    window.status = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.status:SetPoint("TOPLEFT", 22, -153)
    window.status:SetWidth(695)
    window.status:SetJustifyH("LEFT")

    window.scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    window.scroll:SetPoint("TOPLEFT", 24, -181)
    window.scroll:SetPoint("BOTTOMRIGHT", -44, 127)
    window.output = CreateFrame("EditBox", nil, window.scroll)
    window.output:SetMultiLine(true)
    window.output:SetAutoFocus(false)
    window.output:SetFontObject(ChatFontNormal)
    window.output:SetWidth(665)
    window.output:SetHeight(340)
    window.output:SetMaxLetters(0)
    window.output:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    window.scroll:SetScrollChild(window.output)

    window.previous = button(window, "Zurück", 105, 22, -503, function() page = page - 1; showPage() end)
    window.next = button(window, "Weiter", 105, 135, -503, function() page = page + 1; showPage() end)
    button(window, "HTML speichern", 135, 420, -541, function()
        local count, err = GT.SaveHTML(recipes, exportOptions())
        window.reload:SetEnabled(count ~= nil and count ~= false)
        window.status:SetText(count and (count .. " Rezepte vorbereitet. Jetzt »Neu laden« und danach GabbaGuildCraft.lua hochladen.") or err)
    end)
    window.reload = button(window, "Neu laden", 150, 565, -541, function()
        if InCombatLockdown() then
            window.status:SetText("Bitte den Kampf abwarten und anschließend »Neu laden« klicken.")
            return
        end
        ReloadUI()
    end)
    window.reload:Disable()
    window.reload:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Export auf die Festplatte schreiben")
        GameTooltip:AddLine("Zuerst HTML speichern. Danach lädt WoW die Oberfläche neu", 1, 1, 1)
        GameTooltip:AddLine("und schreibt die Exportdatei in SavedVariables.", 1, 1, 1)
        GameTooltip:Show()
    end)
    window.reload:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button(window, "Text markieren", 150, 565, -503, function()
        window.output:SetFocus(); window.output:HighlightText()
    end)
    window.counter = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    window.counter:SetPoint("TOPLEFT", 265, -510)
    local copyHelp = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    copyHelp:SetPoint("BOTTOMLEFT", 22, 22)
    copyHelp:SetText("Discord: Text markieren > Strg+C. Webseite: HTML speichern > Neu laden > GabbaGuildCraft.lua hochladen.")
    window.status:SetText("Öffne deinen Beruf und klicke auf »Rezepte einlesen«.")
    showPage()
end

SLASH_GABBAGUILDCRAFT1 = "/gts"
SLASH_GABBAGUILDCRAFT2 = "/schneiderdiscord"
function GT.ShowWindow()
    if not window then createWindow() end
    window:Show()
end
function GT.ToggleWindow()
    if window and window:IsShown() then window:Hide() else GT.ShowWindow() end
end
SlashCmdList.GABBAGUILDCRAFT = GT.ShowWindow

SLASH_GABBAGUILDCRAFT3 = "/gildenrezepte"
SLASH_GABBAGUILDCRAFT4 = "/ggc"
SLASH_GABBAGUILDCRAFT5 = "/gabbaguildcraft"
local professionEvents = CreateFrame("Frame")
professionEvents:RegisterEvent("TRADE_SKILL_SHOW")
professionEvents:RegisterEvent("TRADE_SKILL_CLOSE")
if GetCraftDisplaySkillLine then
    professionEvents:RegisterEvent("CRAFT_SHOW")
    professionEvents:RegisterEvent("CRAFT_CLOSE")
end
professionEvents:SetScript("OnEvent", function(_, event)
    if event == "TRADE_SKILL_SHOW" then GT.activeMode = "trade"
    elseif event == "CRAFT_SHOW" then GT.activeMode = "craft"
    elseif event == "TRADE_SKILL_CLOSE" and GT.activeMode == "trade" then GT.activeMode = nil
    elseif event == "CRAFT_CLOSE" and GT.activeMode == "craft" then GT.activeMode = nil end
end)
