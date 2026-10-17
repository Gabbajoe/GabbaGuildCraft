local _, GT = ...

-- These are name families, not claims that the items grant a set bonus.
local families = {
    {"Traumzwirn", "traumzwirn", "dreamweave"},
    {"Mondstoff", "mondstoff", "mooncloth"},
    {"Runenstoff", "runenstoff", "runecloth"},
    {"Magiestoff", "magiestoff", "mageweave"},
    {"Schattenzwirn", "schattenzwirn", "shadoweave"},
}

function GT.GroupFor(recipe)
    if recipe.isEnchant then return 70, "Verzauberungen" end
    if recipe.classID == 1 or recipe.equipLoc == "INVTYPE_BAG" then return 10, "Taschen" end
    if recipe.classID == 4 then
        if recipe.equipLoc == "INVTYPE_BODY" or recipe.equipLoc == "INVTYPE_TABARD" then
            return 90, "Hemden & Kosmetik"
        end
        if recipe.setName or (recipe.setID and recipe.setID > 0) then
            return 20, "Rüstungssets · " .. (recipe.setName or ("Set " .. recipe.setID))
        end
        local name = (recipe.itemName or recipe.name):lower()
        for _, family in ipairs(families) do
            for i = 2, #family do
                if name:find(family[i], 1, true) then return 25, "Rüstungsserien · " .. family[1] end
            end
        end
        return 30, "Weitere Rüstung & Schmuck"
    end
    if recipe.classID == 2 then return 40, "Waffen" end
    if recipe.classID == 0 then
        if recipe.professionSpellID == 2550 then return 50, "Essen & Getränke" end
        if recipe.professionSpellID == 3273 then return 50, "Verbände & Erste Hilfe" end
        if recipe.professionSpellID == 2259 then return 50, "Tränke, Elixiere & Verbrauch" end
        return 50, "Verbrauchsgegenstände"
    end
    if recipe.classID == 3 then return 60, "Edelsteine" end
    if recipe.classID == 6 then return 65, "Munition" end
    if recipe.classID == 7 then
        if recipe.professionSpellID == 4036 and (recipe.subclassID == 2 or recipe.subclassID == 3) then
            return 65, "Geräte & Sprengstoffe"
        end
        return 80, "Materialien & Bauteile"
    end
    return 99, "Sonstige Rezepte"
end

function GT.GroupRecipes(recipes)
    local groups, byName = {}, {}
    for _, recipe in ipairs(recipes) do
        local order, name = GT.GroupFor(recipe)
        if not byName[name] then
            byName[name] = {name = name, order = order, recipes = {}, maxLevel = -1}
            groups[#groups + 1] = byName[name]
        end
        local group = byName[name]
        group.recipes[#group.recipes + 1] = recipe
        group.maxLevel = math.max(group.maxLevel, recipe.requiredLevel or -1)
    end
    local function byLevel(a, b)
        if (a.requiredLevel or -1) ~= (b.requiredLevel or -1) then
            return (a.requiredLevel or -1) > (b.requiredLevel or -1)
        end
        if (a.itemLevel or -1) ~= (b.itemLevel or -1) then
            return (a.itemLevel or -1) > (b.itemLevel or -1)
        end
        return a.name < b.name
    end
    for _, group in ipairs(groups) do table.sort(group.recipes, byLevel) end
    table.sort(groups, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        if a.maxLevel ~= b.maxLevel then return a.maxLevel > b.maxLevel end
        return a.name < b.name
    end)
    return groups
end
