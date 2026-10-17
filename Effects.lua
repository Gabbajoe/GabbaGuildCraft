local _, GT = ...
local tooltip

local function plain(text)
    return (tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|H.-|h(.-)|h", "%1")
        :gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

function GT.TooltipEffects(rows, recipe)
    local result, seen = {}, {}
    -- Keep restrictions/binding as well as stats: e.g. BoP is important for guild orders.
    for i = 2, #rows do
        local pieces = {}
        local moneyRow = false
        for _, raw in ipairs(rows[i]) do
            local lower = tostring(raw):lower()
            if lower:find("moneyframe", 1, true) or lower:find("goldicon", 1, true)
                or lower:find("silvericon", 1, true) or lower:find("coppericon", 1, true) then
                moneyRow = true
            end
        end
        for _, raw in ipairs(rows[i]) do
            local text = plain(raw)
            if recipe.classID == 4 then
                local setName = text:match("^(.+)%s+%(%d+%s*/%s*%d+%)$")
                if setName then recipe.setName = setName end
            end
            local duplicateLevel = ITEM_MIN_LEVEL and recipe.requiredLevel
                and text == string.format(ITEM_MIN_LEVEL, recipe.requiredLevel)
            local numberOnly = text:match("^[%d%s%.,]+$")
            if text ~= "" and not moneyRow and not numberOnly and text ~= recipe.itemName and not duplicateLevel and not seen[text] then
                pieces[#pieces + 1] = text
                seen[text] = true
            end
        end
        if #pieces > 0 then result[#result + 1] = table.concat(pieces, " · ") end
    end
    return result
end

function GT.ReadEffects(recipe)
    if recipe.effectsLoaded then return true end
    if not recipe.itemID and recipe.description and recipe.description ~= "" then
        recipe.effects = {plain(recipe.description)}
        recipe.effectsLoaded = true
        return true
    end
    local link = recipe.itemID and recipe.link or (recipe.spellID and ("spell:" .. recipe.spellID))
    if not link or (recipe.itemID and not recipe.itemName) then return false end
    if not tooltip then
        tooltip = CreateFrame("GameTooltip", "GabbaGuildCraftScanTooltip", UIParent, "GameTooltipTemplate")
    end
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    local ok = pcall(tooltip.SetHyperlink, tooltip, link)
    local rows = {}
    if ok then
        for i = 1, tooltip:NumLines() do
            local left = _G["GabbaGuildCraftScanTooltipTextLeft" .. i]
            local right = _G["GabbaGuildCraftScanTooltipTextRight" .. i]
            rows[#rows + 1] = {left and left:GetText() or "", right and right:GetText() or ""}
        end
    end
    tooltip:Hide()
    if #rows < 2 then return false end
    recipe.effects = GT.TooltipEffects(rows, recipe)
    recipe.effectsLoaded = true
    return true
end
