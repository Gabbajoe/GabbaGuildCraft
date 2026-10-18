-- Behavioral UI tests with explicit WoW frame/API stand-ins; no live client required.
local frames, named, GT = {}, {}, {}
GetLocale = function() return "deDE" end
assert(loadfile("Locale.lua"))("GabbaGuildCraft", GT)
local methods = {}
local function widget(name)
    local w = setmetatable({scripts = {}, value = '', shown = true, enabled = true}, {__index = methods})
    if name then named[name] = w end
    return w
end
for _, method in ipairs({'SetSize','SetFrameStrata','SetClampedToScreen','SetMovable','EnableMouse',
    'RegisterForDrag','RegisterForClicks','SetBackdrop','SetBackdropColor','SetBackdropBorderColor',
    'SetAutoFocus','SetMaxLetters','SetNumeric','SetWidth','SetHeight','SetJustifyH','SetMultiLine',
    'SetFontObject','SetScrollChild','SetCursorPosition','SetVerticalScroll','ClearFocus','SetFocus',
    'HighlightText','RegisterEvent','ClearAllPoints','SetTexture','SetHighlightTexture','SetFrameLevel',
    'SetOwner','AddLine','StartMoving','StopMovingOrSizing'}) do methods[method] = function() end end
function methods:SetPoint(...) self.point = {...} end
function methods:SetText(value) self.value = value end
function methods:GetText() return self.value end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetEnabled(value) self.enabled = value end
function methods:Disable() self.enabled = false end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:CreateFontString() return widget() end
function methods:CreateTexture() return widget() end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsShown() return self.shown end
function methods:GetFrameLevel() return 1 end
function methods:GetWidth() return 140 end
function methods:GetCenter() return 100, 100 end
function methods:GetEffectiveScale() return 2 end
function CreateFrame(_, name)
    local w = widget(name); w.text = widget(); frames[#frames + 1] = w; return w
end
local function click(w)
    assert(w.enabled, 'button must be enabled before clicking')
    if w.scripts.OnMouseDown then w.scripts.OnMouseDown(w) end
    w.scripts.OnClick(w, 'LeftButton')
end
local function byText(label)
    for _, w in ipairs(frames) do if w.value == label then return w end end
    error('missing button: ' .. label)
end
UIParent, Minimap, GameTooltip = widget(), widget(), widget()
UISpecialFrames, SlashCmdList, tinsert = {}, {}, table.insert
GetBuildInfo = function() return nil, nil, nil, 11509 end
UnitName, GetRealmName = function() return 'Tester' end, function() return 'Realm' end
GetCursorPosition = function() return 200, 360 end
local combat, reloads, saves, saveFailure = false, 0, 0, false
InCombatLockdown = function() return combat end
ReloadUI = function() reloads = reloads + 1 end
GT.BuildPages = function() return {'recipe text'}, 1, 0 end
GT.Scan = function() return {{name = 'Test recipe'}} end
GT.Enrich = function() return 0 end
GT.PendingForExport = function() return {} end
GT.SaveHTML = function(recipes)
    if #recipes == 0 or saveFailure then return nil, 'No recipes to export' end
    saves = saves + 1
    GuildTailorHTML = 'saved export'
    return 1
end
-- Lua 5.4 dropped atan2; WoW and Lua 5.1 provide it.
math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
assert(loadfile('UI.lua'))('GabbaGuildCraft', GT)
GT.ShowWindow()
local window = named.GabbaGuildCraftWindow
assert(window:IsShown())
GT.ToggleWindow(); assert(not window:IsShown())
GT.ToggleWindow(); assert(window:IsShown() and #UISpecialFrames == 1)
local reload, save = byText('Jetzt /reload'), byText('Export speichern')
assert(not reload.enabled)
assert(not save.enabled and not reload.enabled and saves == 0)
click(byText('Rezepte einlesen'))
click(save); assert(reload.enabled and saves == 1 and GuildTailorHTML == 'saved export')
combat = true; click(reload); assert(reloads == 0 and reload.enabled)
combat = false; click(reload); assert(reloads == 1)
window.search.scripts.OnTextChanged(); assert(not reload.enabled)
click(save); assert(reload.enabled)
saveFailure = true; click(save); assert(not reload.enabled)
saveFailure = false; click(save); click(byText('Rezepte einlesen')); assert(not reload.enabled)
assert(loadfile('Minimap.lua'))('GabbaGuildCraft', GT)
local event = frames[#frames]
GabbaGuildCraftDB = {minimapAngle = '90', anotherSetting = true}
event.scripts.OnEvent()
local minimap = named.GabbaGuildCraftMinimapButton
assert(GabbaGuildCraftDB.minimapAngle == 90 and GabbaGuildCraftDB.anotherSetting)
assert(math.abs(minimap.point[4]) < 0.001 and math.abs(minimap.point[5] - 80) < 0.001)
click(minimap); assert(not window:IsShown())
click(minimap); assert(window:IsShown())
minimap.scripts.OnMouseDown(minimap)
minimap.scripts.OnDragStart(minimap); assert(minimap.scripts.OnUpdate)
minimap.scripts.OnUpdate()
assert(math.abs(GabbaGuildCraftDB.minimapAngle - 90) < 0.001)
minimap.scripts.OnDragStop(minimap); assert(not minimap.scripts.OnUpdate)
minimap.scripts.OnClick(minimap, 'LeftButton'); assert(window:IsShown(), 'drag must not toggle window')
click(minimap); assert(not window:IsShown(), 'next real click must work')
minimap.scripts.OnDragStart(minimap); minimap:Hide(); assert(not minimap.scripts.OnUpdate)
local original = minimap
event.scripts.OnEvent(); assert(named.GabbaGuildCraftMinimapButton == original)
-- Simulate a fresh login with a damaged saved setting.
GabbaGuildCraftDB = {minimapAngle = 'broken'}
assert(loadfile('Minimap.lua'))('GabbaGuildCraft', GT)
frames[#frames].scripts.OnEvent()
assert(GabbaGuildCraftDB.minimapAngle == 220)
print('OK: save/reload, combat guard, filters, window toggle, minimap drag and saved position')
-- Materials filter persists and invalidates a prepared export.
window.materials:SetChecked(false)
window.materials.scripts.OnClick()
assert(GabbaGuildCraftDB.includeMaterials==false and not reload.enabled)
window.materials:SetChecked(true)
window.materials.scripts.OnClick()
assert(GabbaGuildCraftDB.includeMaterials==true)
-- Delayed data can recover beyond the previous four-second retry budget.
local queue, attempts, neverReady = {}, 0, false
C_Timer={After=function(_,f) queue[#queue+1]=f end}
GT.Enrich=function() attempts=attempts+1 end
GT.PendingForExport=function() return (neverReady or attempts<10) and {'Test recipe: reagent'} or {} end
click(byText('Rezepte einlesen'))
assert(not save.enabled and not window.copy.enabled)
for i=1,9 do local f=table.remove(queue,1); assert(f); f() end
assert(save.enabled and #queue==0)
click(save); assert(reload.enabled)
neverReady=true;attempts=0
click(byText('Rezepte einlesen'))
while #queue>0 do table.remove(queue,1)() end
assert(attempts==21 and not save.enabled and not reload.enabled)
assert(window.output.value:find('Test recipe: reagent',1,true))
-- A new scan supersedes outstanding retries and a scan failure cannot export old recipes.
neverReady=false;attempts=0
click(byText('Rezepte einlesen'))
local stale=table.remove(queue,1)
GT.Scan=function() return nil,'Profession closed' end
click(byText('Rezepte einlesen'))
stale()
assert(window.status.value=='Profession closed' and not save.enabled and not reload.enabled)
print('OK: saved material filter, delayed recovery, timeout diagnostics and superseded scans')
