local GT = {}
GetLocale = function() return "deDE" end
assert(loadfile("Locale.lua"))("GabbaGuildCraft", GT)
assert(loadfile("Groups.lua"))("GabbaGuildCraft", GT)
assert(loadfile("Export.lua"))("GabbaGuildCraft", GT)
assert(loadfile("HTML.lua"))("GabbaGuildCraft", GT)
local function contains(text, expected) assert(text:find(expected, 1, true), expected .. " missing") end
local robe = {name = "Mondstoffrobe", itemName = "Mondstoffrobe", itemID = 14104,
    itemLevel = 61, requiredLevel = 56, minMade = 1, maxMade = 1,
    reagents = {{name = "Mondstoff", count = 8}, {name = "Runenstoffballen", count = 6}}}
local pages, count = GT.BuildPages({robe}, {player = "Test-Realm", links = true})
assert(count == 1 and #pages == 1)
contains(pages[1], "Itemlevel: 61 · Benötigtes Level: 56")
contains(pages[1], "8× Mondstoff, 6× Runenstoffballen")
contains(pages[1], "https://www.wowhead.com/classic/item=14104")
contains(pages[1], "Ergebnis: 1 pro Herstellung")
local filtered, n = GT.BuildPages({robe}, {player = "Test", query = "MOND"})
assert(n == 1 and #filtered == 1)
assert(#GT.BuildPages({robe}, {player = "Test", query = "Tasche"}) == 0)
assert(#GT.BuildPages({}, {player = "Test"}) == 0)
contains(GT.Clean("|cffffffff|Hitem:1|h[Item]|h|r @everyone *x*"), "\\[Item\\]")
assert(not GT.Clean("@everyone"):find("@everyone", 1, true))
local many = {}
for i = 1, 100 do
    many[i] = {name = "Rezept " .. i, itemLevel = i, requiredLevel = i,
        reagents = {{name = "Grüner Stoff", count = i}}, minMade = 2, maxMade = 4}
end
pages, count = GT.BuildPages(many, {player = "Test", links = false})
assert(#pages > 1 and count == 100)
local combined = table.concat(pages)
for _, page in ipairs(pages) do assert(#page <= 2000) end
for i = 1, 100 do contains(combined, "**Rezept " .. i .. "**") end
contains(pages[1], "**Rezept 100**")
contains(combined, "Ergebnis: 2–4 pro Herstellung")
local long = {name = "Lang", reagents = {{name = string.rep("ä", 3000), count = 1}}}
pages = GT.BuildPages({long}, {player = "Test"})
for _, page in ipairs(pages) do
    assert(#page <= 2000)
    if utf8 then assert(utf8.len(page)) end
end
contains(GT.FormatRecipe(long, false), "noch nicht geladen")

-- Relevance uses item metadata, not localized names or a fragile allowlist.
local function gear(name, required, quality, classID, slot)
    return {name = name, requiredLevel = required, quality = quality,
        classID = classID, equipLoc = slot, reagents = {}}
end
local relevantRecipes = {
    gear("Spidersilk Boots", 20, 3, 4, "INVTYPE_FEET"),
    gear("Dreamweave Vest", 40, 3, 4, "INVTYPE_ROBE"),
    gear("Robe of the Archmage", 57, 4, 4, "INVTYPE_ROBE"),
    gear("Leinentasche", 0, 1, 1, "INVTYPE_BAG"),
    gear("Stoffballen", 0, 1, 7, ""),
    gear("Hemd", 30, 2, 4, "INVTYPE_BODY"),
    gear("Anfängerrobe", 19, 2, 4, "INVTYPE_ROBE"),
    gear("Weiße Robe", 30, 1, 4, "INVTYPE_ROBE"),
    gear("Grüner Umhang", 20, 2, 4, "INVTYPE_CLOAK"),
    gear("Unbekannt", nil, nil, nil, nil),
}
local pending
pages, count, pending = GT.BuildPages(relevantRecipes, {player = "Test", relevantOnly = true})
assert(count == 5 and pending == 1)
combined = table.concat(pages)
contains(combined, "Spidersilk Boots")
contains(combined, "Dreamweave Vest")
contains(combined, "Robe of the Archmage")
contains(combined, "Leinentasche")
assert(not combined:find("Stoffballen", 1, true))
pages, count = GT.BuildPages(relevantRecipes, {player = "Test", relevantOnly = true, minimumLevel = 50})
assert(count == 2)
contains(table.concat(pages), "Leinentasche")
pages, count = GT.BuildPages(relevantRecipes, {player = "Test", relevantOnly = false})
assert(count == 10)
pages, count = GT.BuildPages(relevantRecipes, {player = "Test", relevantOnly = true, query = "Stoffballen"})
assert(count == 0)

-- Simulate the Classic API, including index shifts when expanding categories.
local profession, linked, cached = "Schneiderei", false, false
local groups = {{name = "Rüstungen", expanded = false, recipes = {"Robe"}},
    {name = "Stoffe", expanded = false, recipes = {"Ballen"}}}
local function rows()
    local result = {}
    for _, group in ipairs(groups) do
        result[#result + 1] = {group = group}
        if group.expanded then
            for _, name in ipairs(group.recipes) do result[#result + 1] = {name = name} end
        end
    end
    return result
end
local professionNames = {[3908] = "Schneiderei", [2259] = "Alchemie", [7411] = "Verzauberkunst",
    [2018] = "Schmiedekunst", [2108] = "Lederverarbeitung", [4036] = "Ingenieurskunst",
    [2550] = "Kochkunst", [3273] = "Erste Hilfe", [25229] = "Juwelenschleifen", [2656] = "Verhüttung"}
GetSpellInfo = function(id) return professionNames[id] end
GetTradeSkillLine = function() return profession end
GetNumTradeSkills = function() return #rows() end
GetTradeSkillInfo = function(i)
    local row = rows()[i]
    if row.group then return row.group.name, "header", 0, row.group.expanded end
    return row.name, "optimal", 0
end
ExpandTradeSkillSubClass = function(i) rows()[i].group.expanded = true end
CollapseTradeSkillSubClass = function(i) rows()[i].group.expanded = false end
GetTradeSkillItemLink = function() return "|Hitem:100|h[Test]|h" end
GetTradeSkillNumMade = function() return 1, 2 end
GetTradeSkillNumReagents = function() return 1 end
GetTradeSkillReagentInfo = function() return nil, nil, 3 end
GetTradeSkillReagentItemLink = function() return "item:200" end
IsTradeSkillLinked = function() return linked end
GetItemInfo = function(link)
    if not cached then return nil end
    if link == "item:200" then return "Leinenstoff" end
    return "Testgegenstand", link, 2, 25, 20, "Rüstung", "Stoff", 1, "INVTYPE_ROBE", 0, 0, 4
end
assert(loadfile("Recipes.lua"))("GabbaGuildCraft", GT)
local recipes = assert(GT.Scan())
assert(#recipes == 2 and recipes[1].name == "Robe" and recipes[2].name == "Ballen")
assert(not groups[1].expanded and not groups[2].expanded)
assert(GT.Enrich(recipes) == 4)
cached = true
assert(GT.Enrich(recipes) == 0)
assert(recipes[1].itemLevel == 25 and recipes[1].requiredLevel == 20)
assert(GT.IsRelevant(recipes[1], 20) == true)
assert(GT.IsRelevant(recipes[1], 21) == false)
assert(recipes[1].reagents[1].count == 3 and recipes[1].reagents[1].name == "Leinenstoff")
linked = true
assert(GT.Scan() == nil)
linked, profession = false, "Alchemie"
local alchemy = assert(GT.Scan())
assert(alchemy.profession == "Alchemie" and alchemy[1].professionSpellID == 2259)
contains(GT.BuildPages(alchemy, {player = "Test"})[1], "Alchemie")
for id, name in pairs(professionNames) do
    profession = name
    assert(GT.Scan()[1].professionSpellID == id)
end
-- Even a read failure must restore collapsed categories.
local oldLink = GetTradeSkillItemLink
GetTradeSkillItemLink = function() error("simulated API failure") end
assert(GT.Scan() == nil)
assert(not groups[1].expanded and not groups[2].expanded)
GetTradeSkillItemLink = oldLink
GetTradeSkillLine = nil
assert(GT.Scan() == nil)

-- UI smoke test: open, empty state, error state and copying controls.
local widgets = {}
local function widget()
    local w = {scripts = {}, value = ""}
    return setmetatable(w, {__index = function(self, key)
        if key == "text" then local child = widget(); rawset(self, key, child); return child end
        return function(obj, ...)
            local args = {...}
            if key == "SetScript" then obj.scripts[args[1]] = args[2]
            elseif key == "SetText" then obj.value = args[1]
            elseif key == "GetText" then return obj.value
            elseif key == "SetChecked" then obj.checked = args[1]
            elseif key == "GetChecked" then return obj.checked
            elseif key == "CreateFontString" then return widget() end
        end
    end})
end
CreateFrame = function() local w = widget(); widgets[#widgets + 1] = w; return w end
UISpecialFrames, SlashCmdList, tinsert = {}, {}, table.insert
GetBuildInfo = function() return nil, nil, nil, 11509 end
UnitName = function() return "Test" end
GetRealmName = function() return "Realm" end
assert(loadfile("UI.lua"))("GabbaGuildCraft", GT)
SlashCmdList.GABBAGUILDCRAFT()
assert(UISpecialFrames[1] == "GabbaGuildCraftWindow")
for _, w in ipairs(widgets) do
    if w.scripts.OnTextChanged then w.scripts.OnTextChanged() end
    if w.value == "Rezepte einlesen" then w.scripts.OnClick() end
    if w.value == "Text markieren" then w.scripts.OnClick() end
    if w.value == "HTML speichern" then w.scripts.OnClick() end
end
assert(loadfile("Effects.lua"))("GabbaGuildCraft", GT)
ITEM_MIN_LEVEL = "Benötigt Stufe %d"
local tooltipRows = {
    {"Testgegenstand"}, {"Wird beim Aufheben gebunden"}, {"Brust", "Stoff"},
    {"|cff00ff00+12 Intelligenz|r"}, {"Anlegen: Erhöht Heilung um 20."},
    {"Benutzen: Stellt Mana wieder her."}, {"Benötigt Stufe 20"},
}
local tooltipCalls = 0
CreateFrame = function(kind)
    assert(kind == "GameTooltip")
    return {
        SetOwner = function() end, ClearLines = function() end, Hide = function() end,
        SetHyperlink = function()
            tooltipCalls = tooltipCalls + 1
            for i, row in ipairs(tooltipRows) do
                _G["GabbaGuildCraftScanTooltipTextLeft" .. i] = {GetText = function() return row[1] end}
                _G["GabbaGuildCraftScanTooltipTextRight" .. i] = {GetText = function() return row[2] end}
            end
        end,
        NumLines = function() return #tooltipRows end,
    }
end
assert(GT.ReadEffects(recipes[1]))
contains(table.concat(recipes[1].effects), "+12 Intelligenz")
contains(table.concat(recipes[1].effects), "Wird beim Aufheben gebunden")
contains(table.concat(recipes[1].effects), "Anlegen:")
contains(table.concat(recipes[1].effects), "Benutzen:")
assert(not table.concat(recipes[1].effects):find("Benötigt Stufe 20", 1, true))
assert(not table.concat(recipes[1].effects):find("|c", 1, true))
assert(GT.ReadEffects(recipes[1]) and tooltipCalls == 1)
contains(GT.FormatRecipe(recipes[1], false), "Werte & Effekte:")
assert(not GT.ReadEffects({itemID = 123, link = "item:123"}))
tooltipRows = {{"Tasche"}, {"16 Plätze"}}
local bag = {itemID = 123, link = "item:123", itemName = "Tasche"}
assert(GT.ReadEffects(bag))
contains(table.concat(bag.effects), "16 Plätze")
local cleanEffects = GT.TooltipEffects({{'Bag'}, {'Binds when equipped'}, {'18 Slot Bag'}, {'4'},
    {'Sell Price:', '4|TInterface\\MoneyFrame\\UI-GoldIcon:0|t'}, {'+4 Intellect'}}, {})
assert(#cleanEffects == 3)
assert(cleanEffects[2] == '18 Slot Bag' and cleanEffects[3] == '+4 Intellect')

-- Materials/transmutation outputs may have a title-only tooltip.
for _, name in ipairs({"Geisterfarbstoff", "Arkanitbarren", "Echtsilberbarren", "Goldbarren"}) do
    tooltipRows = {{name}}
    local material = {name = name, itemID = 123, link = "item:123", itemName = name,
        classID = 7, subclassID = 0, reagents = {}}
    assert(GT.ReadEffects(material))
    assert(material.effectsLoaded and #material.effects == 0)
end
for _, class in ipairs({{0, 0}, {4, 1}, {7, 2}, {7, 3}}) do
    tooltipRows = {{"Testgegenstand"}}
    assert(not GT.ReadEffects({itemID = 123, link = "item:123", itemName = "Testgegenstand",
        classID = class[1], subclassID = class[2]}))
end
local unloadedMaterial = {itemID = 123, link = "item:123", itemName = "Arkanitbarren", classID = 7}
tooltipRows = {}
assert(not GT.ReadEffects(unloadedMaterial))
tooltipRows = {{"Daten werden geladen"}}
assert(not GT.ReadEffects(unloadedMaterial))
assert(not unloadedMaterial.effectsLoaded)
tooltipRows = {{"Arkanitbarren"}, {"Zusätzliche Materialangabe"}}
assert(GT.ReadEffects(unloadedMaterial))
contains(table.concat(unloadedMaterial.effects), "Zusätzliche Materialangabe")

-- Classic enchanting uses Craft APIs and has no item level or output item.
GT.activeMode = "craft"
GetCraftDisplaySkillLine = function() return "Verzauberkunst" end
GetNumCrafts = function() return 1 end
GetCraftInfo = function() return "Brust verzaubern", "Schwache Gesundheit", "optimal", 0, false end
GetCraftItemLink = function() return "|Henchant:777|h[Brust verzaubern]|h" end
GetCraftNumReagents = function() return 1 end
GetCraftReagentInfo = function() return "Seltsamer Staub", nil, 2 end
GetCraftReagentItemLink = function() return nil end
GetCraftDescription = function() return "Verzaubert eine Brust dauerhaft mit +5 Gesundheit." end
local enchants = assert(GT.Scan())
assert(enchants[1].isEnchant and enchants[1].spellID == 777)
assert(enchants[1].itemName == nil and enchants[1].itemLevel == nil)
assert(enchants[1].effectsLoaded and GT.IsRelevant(enchants[1], 60))
local enchantPage = GT.BuildPages(enchants, {player = "Test", relevantOnly = true, links = true})[1]
contains(enchantPage, "+5 Gesundheit")
contains(enchantPage, "2× Seltsamer Staub")
contains(enchantPage, "/spell=777")
assert(not enchantPage:find("Itemlevel:", 1, true))
GetCraftDisplaySkillLine = function() return "Tierausbildung" end
assert(GT.Scan() == nil)
GT.activeMode = nil

for _, id in ipairs({2259, 2550, 3273}) do
    assert(GT.IsRelevant({classID = 0, professionSpellID = id}, 60))
end
assert(GT.IsRelevant({classID = 7, subclassID = 2, professionSpellID = 4036}, 60))
local component = {name = "Delicate Arcanite Converter", classID = 7, subclassID = 1, professionSpellID = 4036}
assert(GT.IsRelevant(component, 60))
local _, componentGroup = GT.GroupFor(component)
assert(componentGroup == "Materialien & Bauteile")
assert(not GT.IsRelevant({classID = 7, subclassID = 1, professionSpellID = 3908}, 20))
assert(GT.IsRelevant({classID = 3, professionSpellID = 25229}, 60))
local weapon = gear("Schwert", 30, 2, 2, "INVTYPE_WEAPON")
weapon.professionSpellID = 2018
assert(GT.IsRelevant(weapon, 20))
assert(not GT.IsRelevant(weapon, 40))
long.effects = {string.rep("Benutzen: Heilt. ", 600)}
pages = GT.BuildPages({long}, {player = "Test"})
for _, page in ipairs(pages) do assert(#page <= 2000); if utf8 then assert(utf8.len(page)) end end
contains(table.concat(pages), "Benutzen: Heilt.")
local dreamLow = gear("Dreamweave Vest", 40, 3, 4, "INVTYPE_ROBE")
local dreamHigh = gear("Dreamweave Circlet", 45, 3, 4, "INVTYPE_HEAD")
local moonBag = gear("Mooncloth Bag", 0, 2, 1, "INVTYPE_BAG")
local highBag = gear("Hochstufige Tasche", 10, 2, 1, "INVTYPE_BAG")
local setPiece = gear("Setbrust", 60, 4, 4, "INVTYPE_ROBE")
setPiece.setID = 123
GT.TooltipEffects({{"Setbrust"}, {"|cffffff00Testset (0/3)|r"}}, setPiece)
assert(setPiece.setName == "Testset")
local normal = gear("Einzelrobe", 57, 4, 4, "INVTYPE_ROBE")
local tieLow = gear("A Robe", 57, 3, 4, "INVTYPE_ROBE")
normal.itemLevel, tieLow.itemLevel = 62, 60
local grouped = GT.GroupRecipes({dreamLow, normal, moonBag, dreamHigh, highBag, setPiece, tieLow})
assert(grouped[1].name == "Taschen")
assert(grouped[1].recipes[1] == highBag and grouped[1].recipes[2] == moonBag)
assert(grouped[2].name == "Rüstungssets · Testset")
assert(grouped[3].name == "Rüstungsserien · Traumzwirn")
assert(grouped[3].recipes[1] == dreamHigh and grouped[3].recipes[2] == dreamLow)
assert(grouped[4].recipes[1] == normal and grouped[4].recipes[2] == tieLow)
pages, count = GT.BuildPages({dreamLow, normal, moonBag, dreamHigh, highBag, setPiece}, {player = "Test"})
assert(count == 6)
combined = table.concat(pages)
contains(combined, "### Taschen")
contains(combined, "### Rüstungssets · Testset")
contains(combined, "### Rüstungsserien · Traumzwirn")
assert(combined:find("**Dreamweave Circlet**", 1, true) < combined:find("**Dreamweave Vest**", 1, true))
pages, count = GT.BuildPages({dreamLow, normal}, {player = "Test", query = "Einzelrobe"})
assert(count == 1 and not table.concat(pages):find("Traumzwirn", 1, true))
for _, recipe in ipairs(many) do recipe.classID = 1 end
pages, count = GT.BuildPages(many, {player = "Test"})
assert(count == 100 and #pages > 1)
for _, page in ipairs(pages) do
    assert(#page <= 2000)
    contains(page, "### Taschen")
end
long.classID = 1
pages = GT.BuildPages({long}, {player = "Test"})
for _, page in ipairs(pages) do
    assert(#page <= 2000)
    contains(page, "### Taschen")
    if utf8 then assert(utf8.len(page)) end
end
local htmlOptions = {player = 'Test <script>alert(1)</script>', links = true, exportedAt = "TESTDATEN"}
local html, htmlCount = GT.BuildHTML({dreamLow, dreamHigh, moonBag}, htmlOptions)
assert(htmlCount == 3)
contains(html, '<h2>Taschen</h2>')
contains(html, 'Rüstungsserien · Traumzwirn')
contains(html, '&lt;script&gt;alert(1)&lt;/script&gt;')
assert(not html:find('<script>alert(1)', 1, true))
assert(html:find('Dreamweave Circlet', 1, true) < html:find('Dreamweave Vest', 1, true))
assert(GT.BuildHTML({}, htmlOptions) == nil)
dreamLow.professionSpellID = 3908
assert(GT.SaveHTML({dreamLow}, htmlOptions) == 1)
local tailorSaved = GuildTailorHTMLTailor
assert(tailorSaved:match('^[0-9a-f]+$'))
local decoded = tailorSaved:gsub('..', function(hex) return string.char(tonumber(hex, 16)) end)
assert(decoded == GT.BuildHTML({dreamLow}, htmlOptions))
weapon.professionSpellID = 4036
assert(GT.SaveHTML({weapon}, htmlOptions) == 1)
assert(GuildTailorHTMLTailor == tailorSaved and GuildTailorHTMLEngineering ~= tailorSaved)
assert(GT.SaveHTML({}, htmlOptions) == nil and GuildTailorHTMLTailor == tailorSaved)
if arg[1] == '--preview' then
    local preview = assert(io.open('preview.html', 'w'))
    preview:write(assert(GT.BuildHTML({dreamLow, dreamHigh, moonBag, normal}, {
        player = 'VORSCHAU · Beispieldaten, keine echten Charakterdaten',
        profession = 'Schneiderei', links = false, exportedAt = 'Demo',
    })))
    preview:close()
end
print("OK: HTML export, escaping, snapshots, categories, pagination, professions, effects and UI")

local idHTML = GT.BuildHTML({{name="Test", itemID=10021, spellID=12070, professionSpellID=3908, reagents={{name="Runecloth",count=4,link="item:14047:0"}}}}, {player="Test",links=false,prefix="tbc"})
contains(idHTML, 'data-item-id="10021"')
contains(idHTML, 'data-spell-id="12070"')
contains(idHTML, 'data-item-id="14047" data-count="4"')
contains(idHTML, 'name="ggc-game" content="tbc"')
print("OK: language-independent IDs without Wowhead links")
