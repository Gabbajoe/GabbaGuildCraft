local GT = {}
local locale = 'enUS'
GetLocale = function() return locale end
for _, file in ipairs({'Locale','Groups','Export','HTML'}) do assert(loadfile(file .. '.lua'))('GabbaGuildCraft', GT) end
local oil = {name='Fire Oil', itemName='Fire Oil', itemID=6371, professionSpellID=2259,
    classID=7, itemLevel=25, requiredLevel=0, quality=1, equipLoc='', effectsLoaded=true,
    effects={'Trade Goods'}, reagents={{name='Firefin Snapper', count=2, link='item:6359'}}}
local recipes = {oil}; recipes.profession='Alchemy'
local options = {player='Tester-Realm', relevantOnly=true, includeMaterials=true}
local pages, count = GT.BuildPages(recipes, options)
assert(count == 1 and pages[1]:find('Reagents: 2× Firefin Snapper',1,true))
assert(pages[1]:find('Materials & parts',1,true))
assert(not pages[1]:find('Zutaten',1,true))
local html = assert(GT.BuildHTML(recipes, options))
assert(html:find('<html lang="en">',1,true))
assert(html:find('Reagents per craft',1,true))
assert(html:find('data-item-id="6359" data-count="2"',1,true))
options.includeMaterials=false
assert(select(2,GT.BuildPages(recipes, options)) == 0)
options.relevantOnly=false
assert(select(2,GT.BuildPages(recipes, options)) == 1)
locale='deDE'; assert(loadfile('Locale.lua'))('GabbaGuildCraft',GT)
-- Modules capture a local function; reloading modules simulates a new client login.
for _, file in ipairs({'Groups','Export','HTML'}) do assert(loadfile(file .. '.lua'))('GabbaGuildCraft',GT) end
html=assert(GT.BuildHTML(recipes, options))
assert(html:find('<html lang="de">',1,true) and html:find('Zutaten je Herstellung',1,true))
assert(html:find('Firefin Snapper',1,true), 'Client-provided item names must not be translated or altered')
local ready=false
GetItemInfo=function(link)
    if not ready then return nil end
    if link=='item:6359' then return 'Firefin Snapper' end
    return 'Fire Oil',link,1,25,0,nil,nil,nil,'',nil,nil,7
end
GT.ReadEffects=function() return ready end
assert(loadfile('Recipes.lua'))('GabbaGuildCraft',GT)
oil.link='item:6371'; oil.reagents[1].name=nil
GT.Enrich(recipes)
options.relevantOnly=true;options.includeMaterials=true
local missing=GT.PendingForExport(recipes,options)
assert(#missing==1 and missing[1]:find('Fire Oil',1,true) and missing[1]:find('Zutat:',1,true))
GuildTailorHTML='keep last good export'
assert(GT.SaveHTML(recipes,options)==nil and GuildTailorHTML=='keep last good export')
ready=true;GT.Enrich(recipes)
assert(#GT.PendingForExport(recipes,options)==0)
oil.missing={'Werte / Tooltip'};options.includeMaterials=false
assert(#GT.PendingForExport(recipes,options)==0, 'Hidden materials must not trigger missing-data warnings')
options.includeMaterials=true;oil.missing={}
assert(GT.SaveHTML(recipes,options)==1)
-- A large profession must retain the final recipe, all reagents and all Discord pages.
local many={};many.profession='Alchemy'
for i=1,300 do
    many[i]={name=string.format('Recipe %03d',i),itemName=string.format('Recipe %03d',i),
        itemID=10000+i,classID=7,professionSpellID=2259,requiredLevel=0,itemLevel=1,
        reagents={{name='Reagent A '..i,count=2},{name='Reagent B '..i,count=3}},effectsLoaded=true}
end
html=assert(GT.BuildHTML(many,options))
assert(#html>65535 and html:find('Reagent B 300',1,true))
pages,count=GT.BuildPages(many,options)
assert(count==300)
local combined=table.concat(pages)
for i=1,300 do assert(combined:find('3× Reagent B '..i,1,true)) end
for _,page in ipairs(pages) do assert(#page<=2000) end
print('OK: DE/EN exports, material filters, missing-data diagnostics, export guard, large exports and reagents')
