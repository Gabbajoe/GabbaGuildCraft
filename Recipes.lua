local _, GT = ...
local getItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

local function itemID(link)
    return link and tonumber(link:match("item:(%d+)"))
end

function GT.Enrich(recipes)
    local pending = 0
    for _, recipe in ipairs(recipes) do
        if recipe.itemID then
            local name, _, quality, ilvl, required, _, _, _, equipLoc, _, _, classID, subclassID, _, _, setID = getItemInfo(recipe.link)
            recipe.itemName, recipe.itemLevel, recipe.requiredLevel = name, ilvl, required
            recipe.quality, recipe.equipLoc, recipe.classID = quality, equipLoc, classID
            recipe.subclassID = subclassID
            recipe.setID = setID
            if not name then pending = pending + 1 end
        end
        if GT.ReadEffects and not GT.ReadEffects(recipe) then pending = pending + 1 end
        for _, reagent in ipairs(recipe.reagents) do
            if reagent.link then
                local name = getItemInfo(reagent.link)
                reagent.name = name or reagent.name
            end
            if not reagent.name then pending = pending + 1 end
        end
    end
    return pending
end

local function spellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return GetSpellInfo(id) end
end

local function professionID(name)
    for _, id in ipairs({3908, 2259, 2018, 2108, 4036, 7411, 2550, 3273, 25229, 2656}) do
        if spellName(id) == name then return id end
    end
end

local function adapter()
    local craftOpen = GT.activeMode == "craft" or (CraftFrame and CraftFrame:IsShown())
    if craftOpen and GetCraftDisplaySkillLine and GetNumCrafts then
        local profession = GetCraftDisplaySkillLine()
        if profession ~= spellName(7411) then
            return nil, "Bitte einen Herstellungsberuf öffnen (keine Tierausbildung)."
        end
        return {
            profession = profession, count = GetNumCrafts,
            info = function(i)
                local name, subname, kind, _, expanded = GetCraftInfo(i)
                if subname and subname ~= "" then name = name .. " (" .. subname .. ")" end
                return name, kind, nil, expanded
            end,
            expand = ExpandCraftSkillLine, collapse = CollapseCraftSkillLine,
            link = GetCraftItemLink, made = function() return 1, 1 end,
            numReagents = GetCraftNumReagents, reagent = GetCraftReagentInfo,
            reagentLink = GetCraftReagentItemLink, description = GetCraftDescription,
        }
    end
    if not GetTradeSkillLine or not GetNumTradeSkills then
        return nil, "Bitte einen klassischen Herstellungsberuf öffnen."
    end
    local profession = GetTradeSkillLine()
    if not profession or profession == "UNKNOWN" or profession == UNKNOWN or GetNumTradeSkills() == 0 then
        return nil, "Bitte zuerst dein eigenes Berufsfenster öffnen."
    end
    if (IsTradeSkillLinked and IsTradeSkillLinked()) or (IsTradeSkillGuild and IsTradeSkillGuild()) then
        return nil, "Bitte deine eigenen Rezepte öffnen, keine fremde Berufsliste."
    end
    return {
        profession = profession, count = GetNumTradeSkills, info = GetTradeSkillInfo,
        expand = ExpandTradeSkillSubClass, collapse = CollapseTradeSkillSubClass,
        link = GetTradeSkillItemLink, recipeLink = GetTradeSkillRecipeLink, made = GetTradeSkillNumMade,
        numReagents = GetTradeSkillNumReagents, reagent = GetTradeSkillReagentInfo,
        reagentLink = GetTradeSkillReagentItemLink,
    }
end

function GT.Scan()
    local api, err = adapter()
    if not api then return nil, err end
    local collapsed, recipes = {}, {profession = api.profession}
    local professionSpellID = professionID(api.profession)
    local index = 1
    -- Expanding shifts later indices. Restore in reverse order, including on failure.
    local ok, failure = pcall(function()
        while index <= api.count() do
            local _, kind, _, expanded = api.info(index)
            if kind == "header" and not expanded then
                collapsed[#collapsed + 1] = index
                api.expand(index)
            end
            index = index + 1
        end
        for i = 1, api.count() do
            local name, kind = api.info(i)
            if name and kind ~= "header" then
                local link = api.link(i)
                local id = itemID(link)
                local recipeLink = api.recipeLink and api.recipeLink(i)
                local spellLink = recipeLink or link or ""
                local spellID = tonumber(spellLink:match("enchant:(%d+)") or spellLink:match("spell:(%d+)"))
                local low, high = api.made(i)
                local recipe = {name = name, link = link, itemID = id, spellID = spellID,
                    professionSpellID = professionSpellID,
                    isEnchant = professionSpellID == 7411 and not id,
                    description = api.description and api.description(i),
                    minMade = low, maxMade = high, reagents = {}}
                for j = 1, api.numReagents(i) do
                    local reagentName, _, count = api.reagent(i, j)
                    recipe.reagents[#recipe.reagents + 1] = {
                        name = reagentName, count = count, link = api.reagentLink(i, j),
                    }
                end
                recipes[#recipes + 1] = recipe
            end
        end
    end)
    for i = #collapsed, 1, -1 do api.collapse(collapsed[i]) end
    if not ok then return nil, "Beruf konnte nicht gelesen werden: " .. tostring(failure) end
    if #recipes == 0 then return nil, "Keine Rezepte gefunden. Bitte Berufsfilter zurücksetzen." end
    GT.Enrich(recipes)
    return recipes
end
