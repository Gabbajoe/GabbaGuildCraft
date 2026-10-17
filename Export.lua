local _, GT = ...

function GT.Clean(value)
    local text = tostring(value or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|H.-|h(.-)|h", "%1"):gsub("[\r\n]", " ")
    -- Escape Discord formatting and prevent accidental mentions.
    return (text:gsub("([\\`*_~|%[%]<>])", "\\%1"):gsub("@", "@\226\128\139"))
end

local function level(value)
    if value == nil then return "noch nicht geladen" end
    return value == 0 and "–" or tostring(value)
end

function GT.FormatRecipe(recipe, links, prefix)
    local name = GT.Clean(recipe.itemName or recipe.name)
    if links and recipe.itemID then
        name = "[" .. name .. "](<https://www.wowhead.com/" .. prefix .. "/item=" .. recipe.itemID .. ">)"
    elseif links and recipe.spellID then
        name = "[" .. name .. "](<https://www.wowhead.com/" .. prefix .. "/spell=" .. recipe.spellID .. ">)"
    end
    local amount = recipe.minMade or 1
    local yieldText = tostring(amount)
    if recipe.maxMade and recipe.maxMade ~= amount then
        yieldText = yieldText .. "–" .. recipe.maxMade
    end
    local materials = {}
    for _, reagent in ipairs(recipe.reagents) do
        materials[#materials + 1] = (reagent.count or "?") .. "× " .. GT.Clean(reagent.name or "Zutat noch nicht geladen")
    end
    local details = {}
    for _, effect in ipairs(recipe.effects or {}) do details[#details + 1] = GT.Clean(effect) end
    local levelText = recipe.isEnchant and "Verzauberung · Anforderungen siehe Effekt\n"
        or ("Itemlevel: " .. level(recipe.itemLevel) .. " · Benötigtes Level: " .. level(recipe.requiredLevel) .. "\n")
    return "**" .. name .. "**\n" .. levelText
        .. "Werte & Effekte: " .. (#details > 0 and table.concat(details, "; ")
            or (recipe.effectsLoaded and "keine weiteren Angaben" or "noch nicht geladen – erneut einlesen")) .. "\n"
        .. "Zutaten: " .. (#materials > 0 and table.concat(materials, ", ") or "keine Angabe") .. "\n"
        .. (recipe.isEnchant and "Ergebnis: 1 Verzauberung" or ("Ergebnis: " .. yieldText .. " pro Herstellung"))
end

function GT.IsRelevant(recipe, minimumLevel)
    if recipe.isEnchant then return true end
    -- Bag equip location also covers specialty bags, regardless of quality/level.
    if recipe.classID == 1 or recipe.equipLoc == "INVTYPE_BAG" then return true end
    if recipe.classID == nil then return nil end
    if recipe.professionSpellID and recipe.professionSpellID ~= 3908 then
        -- Consumables, gems, ammunition, engineering parts and finished devices.
        if recipe.classID == 0 or recipe.classID == 3 or recipe.classID == 6 then return true end
        if recipe.professionSpellID == 2656 then return true end -- Smelting produces materials.
        if recipe.professionSpellID == 4036 and recipe.classID == 7
            and (recipe.subclassID == 1 or recipe.subclassID == 2 or recipe.subclassID == 3) then return true end
    end
    if (recipe.classID ~= 4 and recipe.classID ~= 2) or recipe.equipLoc == "INVTYPE_BODY"
        or recipe.equipLoc == "INVTYPE_TABARD" then return false end
    if recipe.quality == nil or recipe.requiredLevel == nil or recipe.equipLoc == nil then return nil end
    return recipe.equipLoc ~= "" and recipe.quality >= 2
        and recipe.requiredLevel >= (tonumber(minimumLevel) or 20)
end

function GT.SelectRecipes(recipes, options)
    local selected = {}
    local pending = 0
    local query = (options.query or ""):lower()
    for _, recipe in ipairs(recipes) do
        if (recipe.name .. " " .. (recipe.itemName or "")):lower():find(query, 1, true) then
            local relevant = true
            if options.relevantOnly then relevant = GT.IsRelevant(recipe, options.minimumLevel) end
            if relevant then selected[#selected + 1] = recipe
            elseif relevant == nil then pending = pending + 1 end
        end
    end
    return selected, pending
end

function GT.BuildPages(recipes, options)
    local selected, pending = GT.SelectRecipes(recipes, options)
    if #selected == 0 then return {}, 0, pending end
    local title = "## ⚒ " .. GT.Clean(options.profession or recipes.profession or "Berufe") .. " · " .. GT.Clean(options.player) .. "\n"
        .. "Gelernte Rezepte für die Gilde · Zutaten je Herstellung\n\n"
    local pages, body = {}, ""
    -- Byte limit is deliberately stricter than Discord's 2000-character limit.
    local budget = 1900 - #title - 40
    local activeHeading
    local function flush()
        if body ~= "" then pages[#pages + 1] = body end
        body, activeHeading = "", nil
    end
    local function append(text, heading)
        local extra = activeHeading ~= heading and #heading or 0
        if #body + extra + #text > budget then flush() end
        if activeHeading ~= heading then
            body = body .. heading
            activeHeading = heading
        end
        body = body .. text
    end
    for _, group in ipairs(GT.GroupRecipes(selected)) do
        local heading = "### " .. GT.Clean(group.name) .. "\n\n"
        local capacity = budget - #heading
        for _, recipe in ipairs(group.recipes) do
            local block = GT.FormatRecipe(recipe, options.links, options.prefix or "classic") .. "\n\n"
            if #block <= capacity then
                append(block, heading)
            else
                -- Preserve every effect, repeat the category on every continuation,
                -- and never split inside a UTF-8 character.
                for line in block:gmatch("([^\n]*)\n") do
                    while #line + 1 > capacity do
                        local cut = capacity - 1
                        while cut > 0 and line:byte(cut + 1) >= 128 and line:byte(cut + 1) < 192 do cut = cut - 1 end
                        append(line:sub(1, cut) .. "\n", heading)
                        flush()
                        line = line:sub(cut + 1)
                    end
                    append(line .. "\n", heading)
                end
            end
        end
    end
    flush()
    for i, content in ipairs(pages) do
        pages[i] = title .. "**Teil " .. i .. "/" .. #pages .. "**\n\n" .. content
    end
    return pages, #selected, pending
end
