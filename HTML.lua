local _, GT = ...

local function escape(value)
    local text = tostring(value or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")
    return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        :gsub('"', "&quot;"):gsub("'", "&#39;"))
end

local function level(value)
    if value == nil then return "unbekannt" end
    return value == 0 and "–" or tostring(value)
end

function GT.BuildHTML(recipes, options)
    local selected, pending = GT.SelectRecipes(recipes, options)
    if #selected == 0 then return nil, "Keine passenden Rezepte für den HTML-Export." end
    local profession = options.profession or recipes.profession or "Berufe"
    local groups = GT.GroupRecipes(selected)
    local game = options.prefix == "tbc" and "tbc" or "classic"
    local locale = GetLocale and GetLocale() or "enUS"
    local function numeric(value) return tostring(tonumber(value) or 0) end
    local parts = {}
    local function add(text) parts[#parts + 1] = text end
    add([=[<!doctype html>
<html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="dark"><title>]=] .. escape(profession .. " · " .. options.player) .. [=[</title>
<style>
:root{color-scheme:dark;--bg:#111819;--panel:#1b2425;--line:#344243;--text:#f2eee3;--muted:#b4c2be;--gold:#e8bc70}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:16px/1.6 system-ui,sans-serif}
header,main,footer{max-width:1160px;margin:auto;padding:28px}header{padding-top:64px;padding-bottom:36px}
.eyebrow{color:var(--gold);font-size:12px;font-weight:700;letter-spacing:.18em;text-transform:uppercase}
h1{font:clamp(36px,7vw,64px)/1.1 Georgia,serif;margin:14px 0}h2{font:28px/1.3 Georgia,serif;margin:0}
h3{font-size:19px;line-height:1.35;margin:0 0 12px}p{margin:8px 0}a{color:var(--gold);text-decoration:none}a:hover{text-decoration:underline}
.intro,.muted,footer{color:var(--muted)}.tools{padding:20px;background:var(--panel);border:1px solid var(--line);border-radius:14px}
label{display:block;font-size:13px;font-weight:600;margin-bottom:8px}input{width:100%;font:inherit;background:var(--bg);color:var(--text);padding:12px 14px;border:1px solid var(--line);border-radius:8px}
:focus-visible{outline:2px solid var(--gold);outline-offset:3px}nav{display:flex;flex-wrap:wrap;gap:8px;margin-top:16px}
nav a{font-size:13px;padding:5px 12px;border:1px solid var(--line);border-radius:20px}section{margin:38px 0;scroll-margin-top:20px}
.section-head{display:flex;align-items:center;gap:16px;margin-bottom:18px}.section-head span{color:var(--muted);font-size:13px}
.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}.recipe{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:24px;overflow-wrap:anywhere}
.levels{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:18px}.levels span{font-size:12px;background:#293535;padding:3px 9px;border-radius:5px}
.caption{color:var(--gold);font-size:11px;letter-spacing:.1em;font-weight:700;text-transform:uppercase;margin:18px 0 6px}
ul{padding-left:20px;margin:6px 0}.effects{font-size:14px;color:#d3ddd8}.materials{font-size:14px}.yield{font-size:12px;color:var(--muted);border-top:1px solid var(--line);padding-top:12px;margin-top:16px}
[hidden]{display:none!important}#empty{padding:30px;text-align:center}footer{border-top:1px solid var(--line);font-size:12px;padding-bottom:40px}
@media(max-width:700px){.grid{grid-template-columns:1fr}header,main,footer{padding:20px}header{padding-top:38px}.recipe{padding:20px}}
</style></head><body><header><div class="eyebrow">Handwerk für die Gilde</div><h1>]=] .. escape(profession) .. '</h1><meta name="ggc-game" content="' .. game .. '"><meta name="ggc-locale" content="' .. escape(locale) .. '"><meta name="ggc-profession" content="' .. numeric(selected[1].professionSpellID) .. '">')
    add('<p class="intro">' .. escape(options.player) .. ' · ' .. #selected .. ' gelernte Rezepte · Stand ' .. escape(options.exportedAt or "unbekannt") .. '</p>')
    add('<p class="muted">Nach Kategorien, innerhalb jeder Gruppe nach benötigtem Level absteigend.</p></header><main>')
    add('<div class="tools"><label for="search">Rezepte, Effekte oder Zutaten suchen</label><input id="search" type="search" placeholder="Zum Beispiel: Traumzwirn, Intelligenz, Runenstoff …"><p id="result" class="muted" role="status">' .. #selected .. ' Rezepte</p><nav aria-label="Kategorien">')
    for i, group in ipairs(groups) do add('<a href="#group-' .. i .. '">' .. escape(group.name) .. '</a>') end
    add('</nav></div>')
    if pending > 0 then add('<p class="muted">' .. pending .. ' Rezepte wegen fehlender Itemdaten nicht enthalten.</p>') end
    for i, group in ipairs(groups) do
        add('<section id="group-' .. i .. '"><div class="section-head"><h2>' .. escape(group.name) .. '</h2><span class="group-count">' .. #group.recipes .. '</span></div><div class="grid">')
        for _, recipe in ipairs(group.recipes) do
            local name = escape(recipe.itemName or recipe.name)
            local id = tonumber(recipe.itemID or recipe.spellID)
            if options.links and id then
                local prefix = options.prefix == "tbc" and "tbc" or "classic"
                name = '<a href="https://www.wowhead.com/' .. prefix .. '/' .. (recipe.itemID and "item=" or "spell=") .. id .. '" target="_blank" rel="noopener noreferrer">' .. name .. ' ↗</a>'
            end
            add('<article class="recipe" data-item-id="' .. numeric(recipe.itemID) .. '" data-spell-id="' .. numeric(recipe.spellID) .. '"><h3>' .. name .. '</h3><div class="levels">')
            if recipe.isEnchant then add('<span>Verzauberung</span>')
            else add('<span>Benötigtes Level: ' .. level(recipe.requiredLevel) .. '</span><span>Itemlevel: ' .. level(recipe.itemLevel) .. '</span>') end
            add('</div><div class="caption">Werte &amp; Effekte</div><ul class="effects">')
            for _, effect in ipairs(recipe.effects or {}) do add('<li>' .. escape(effect) .. '</li>') end
            if not recipe.effects or #recipe.effects == 0 then
                add('<li>' .. (recipe.effectsLoaded and "Keine weiteren Angaben" or "Noch nicht geladen – Export im Spiel aktualisieren") .. '</li>')
            end
            add('</ul><div class="caption">Zutaten je Herstellung</div><ul class="materials">')
            for _, reagent in ipairs(recipe.reagents) do add('<li data-item-id="' .. numeric(reagent.link and reagent.link:match("item:(%d+)")) .. '" data-count="' .. numeric(reagent.count) .. '"><strong>' .. escape(reagent.count or "?") .. '×</strong> ' .. escape(reagent.name or "Unbekannte Zutat") .. '</li>') end
            if #recipe.reagents == 0 then add('<li>Keine Angabe</li>') end
            local amount = tostring(recipe.minMade or 1)
            if recipe.maxMade and recipe.maxMade ~= (recipe.minMade or 1) then amount = amount .. "–" .. recipe.maxMade end
            add('</ul><p class="yield">Ergebnis: ' .. (recipe.isEnchant and "1 Verzauberung" or escape(amount) .. " pro Herstellung") .. '</p></article>')
        end
        add('</div></section>')
    end
    add([=[<p id="empty" hidden>Keine passenden Rezepte. Versuche einen anderen Suchbegriff.</p></main>
<footer>Gelernte Rezepte zum angegebenen Stand. Materialien und Cooldowns sind nicht live geprüft.
Bindungen und Anforderungen in den Effekten beachten. Erstellt mit GabbaGuildCraft.</footer>
<script>
const search=document.getElementById('search');
search.addEventListener('input',()=>{
 const query=search.value.trim().toLocaleLowerCase('de');let total=0;
 document.querySelectorAll('section').forEach(section=>{
  let count=0;section.querySelectorAll('.recipe').forEach(card=>{
   card.hidden=!card.textContent.toLocaleLowerCase('de').includes(query);if(!card.hidden)count++;
  });section.hidden=count===0;section.querySelector('.group-count').textContent=count;total+=count;
  document.querySelector('nav a[href="#'+section.id+'"]').hidden=count===0;
 });document.getElementById('result').textContent=total+' passende Rezepte';document.getElementById('empty').hidden=total>0;
});
</script></body></html>]=])
    return table.concat(parts, "\n"), #selected
end

function GT.SaveHTML(recipes, options)
    local html, result = GT.BuildHTML(recipes, options)
    if not html then return nil, result end
    -- A hex string survives WoW's Lua serialization and needs no Lua execution to extract.
    GuildTailorHTML = html:gsub(".", function(byte) return string.format("%02x", byte:byte()) end)
    if recipes[1] and recipes[1].professionSpellID == 3908 then GuildTailorHTMLTailor = GuildTailorHTML end
    if recipes[1] and recipes[1].professionSpellID == 4036 then GuildTailorHTMLEngineering = GuildTailorHTML end
    return result
end
