local ns = {}
local fighting, hidden = false, {}
local weaponLow, weaponHigh = 20, 24
local seal, protectedAction, protectedText = 21084, false, false
local actionID = 679
local queued, scripts = {}, {}
GetBuildInfo = function() return "1.60.1", "70862", "", 16001 end
GetLocale = function() return "esMX" end
InCombatLockdown = function() return fighting end
issecretvalue = function(value) return rawequal(value, hidden) end
UnitDamage = function() return weaponLow, weaponHigh end
GetActionInfo = function()
    if protectedAction then return hidden, hidden end
    if actionID then return "spell", actionID end
end
local descriptions = {
    [679] = "Un golpe instantáneo que inflige un 25% de daño con arma y 2 a 4 p. de daño Sagrado.",
    [21084] = "Desatar la energía de este sello inflige 24 a 27 p. de daño Sagrado a un enemigo.",
    [639] = "Sana un objetivo amistoso en 78 a 93 p.",
}
C_Spell = {GetSpellDescription = function(id)
    if protectedText then return hidden end
    return descriptions[id]
end}
C_UnitAuras = {GetAuraDataByIndex = function(_, index)
    if index == 1 and seal then return {spellId = seal} end
end}
-- No GameTooltip scanning or new overlay construction is allowed in combat.
local frame = {}
function frame:SetScript(name, fn) scripts[name] = fn end
function frame:RegisterEvent() end
CreateFrame = function(kind)
    assert(not fighting, "created a frame during combat")
    if kind == "GameTooltip" then return {SetOwner = function() end, ClearLines = function() end, Hide = function() end} end
    return frame
end
C_Timer = {After = function(delay, fn) queued[#queued + 1] = {delay = delay, fn = fn} end}
SlashCmdList = {}
assert(loadfile("Core.lua"))("damage.reader.skill", ns)
assert(loadfile("Data.lua"))("damage.reader.skill", ns)
assert(loadfile("Calculator.lua"))("damage.reader.skill", ns)
assert(loadfile("Paladin.lua"))("damage.reader.skill", ns)
assert(loadfile("Spellbook.lua"))("damage.reader.skill", ns)
assert(loadfile("Buttons.lua"))("damage.reader.skill", ns)
ns:InitializeDatabase()
local label = {}
function label:SetFont() end
function label:SetTextColor(r, g, b) self.color = {r, g, b} end
function label:SetText(text) self.value = text end
function label:Show() self.visible = true end
function label:Hide() self.visible = false end
ActionButton1 = {action = 1, DamageReaderSkillText = label,
    CreateFontString = function() error("overlay already exists") end}
local function flush()
    local current = queued
    queued = {}
    table.sort(current, function(a, b) return a.delay < b.delay end)
    for _, timer in ipairs(current) do timer.fn() end
end
local function event(name, unit)
    scripts.OnEvent(frame, name, unit)
    flush()
end
ns:Refresh()
assert(label.value == "9" and label.visible)
fighting = true
event("PLAYER_REGEN_DISABLED")
assert(label.value == "9" and label.visible)
weaponLow, weaponHigh = 40, 60
event("UNIT_DAMAGE", "player")
assert(label.value == "16" and not ActionButton1.DamageReaderSkillStale)
weaponLow, weaponHigh = 20, 24
event("UNIT_AURA", "player") -- proc expires
assert(label.value == "9")
weaponLow = hidden
event("UNIT_DAMAGE", "player")
assert(label.value == "~9" and label.visible and ActionButton1.DamageReaderSkillStale)
weaponLow = 20
event("UNIT_DAMAGE", "player")
assert(label.value == "9" and not ActionButton1.DamageReaderSkillStale)
protectedText = true
event("UNIT_AURA", "player")
assert(label.value == "~9" and label.visible)
protectedText = false
event("UNIT_AURA", "player")
assert(label.value == "9")
protectedAction = true
event("UNIT_AURA", "player")
assert(label.value == "9") -- public cached binding + freshly readable spell inputs
event("ACTIONBAR_PAGE_CHANGED")
assert(not label.visible and not ActionButton1.DamageReaderSkillResult)
protectedAction = false
actionID = 20271
event("ACTIONBAR_SLOT_CHANGED")
assert(label.value == "26" and label.visible)
seal = 21082
event("UNIT_AURA", "player")
assert(label.value == "0")
seal = hidden
event("UNIT_AURA", "player")
assert(label.value == "~0")
seal = nil
event("UNIT_AURA", "player")
assert(not label.visible) -- a known absent seal clears the old number
actionID = 639
event("ACTIONBAR_SLOT_CHANGED")
assert(label.value == "86" and label.color[2] == 1)
descriptions[639] = "Sana un objetivo amistoso en 100 a 120 p."
event("SPELL_POWER_CHANGED")
assert(label.value == "110" and label.color[2] == 1)
protectedText = true
event("UNIT_AURA", "player")
assert(label.value == "~110")
protectedText = false
fighting = false
event("PLAYER_REGEN_ENABLED")
assert(label.value == "110" and not ActionButton1.DamageReaderSkillStale)
actionID = nil
event("ACTIONBAR_SLOT_CHANGED")
assert(not label.visible)
-- Many proc/stat events coalesce into one refresh, unrelated units do not queue.
event("UNIT_AURA", "target")
assert(#queued == 0)
for i = 1, 50 do scripts.OnEvent(frame, "UNIT_AURA", "player") end
assert(#queued == 1)
flush()
print("Combat integration passed: procs, expiry, seals, hidden data, paging, healing, exit and event coalescing")

-- Regression: Crusader -> Judgment -> Rectitude while unrelated aura IDs and
-- action IDs become secret. Delayed aura state must be re-read after the cast.
fighting = true
actionID, seal = 20271, 21082
event("ACTIONBAR_SLOT_CHANGED", 1)
assert(label.value == "0")
C_UnitAuras.GetAuraDataByIndex = function(_, index)
    if index == 1 then return {spellId = hidden} end
    if index == 2 and seal then return {spellId = seal} end
end
protectedAction = true
event("ACTIONBAR_SLOT_CHANGED", 2) -- unrelated slot must not erase Judgment
assert(label.value == "0" and ActionButton1.DamageReaderSkillBinding.id == 20271)
scripts.OnEvent(frame, "UNIT_SPELLCAST_SUCCEEDED", "player")
flush() -- immediate refresh can still see the old seal
assert(label.value == "0")
seal = 21084
flush() -- retry sees the new seal even with an unrelated protected buff
assert(label.value == "26" and not ActionButton1.DamageReaderSkillStale)
-- Direct lookup avoids a restricted general enumeration.
C_UnitAuras.GetPlayerAuraBySpellID = function(id)
    if id == seal then return {spellId = id} end
end
C_UnitAuras.GetAuraDataByIndex = function() error("restricted enumeration") end
seal = 21082
event("UNIT_AURA", "player")
assert(label.value == "0")
seal, protectedText = 21084, true
event("UNIT_AURA", "player")
assert(label.value == "~26" and ActionButton1.DamageReaderSkillStale)
protectedText = false
event("UNIT_AURA", "player")
assert(label.value == "26")
-- Hidden seal identity is never decoded or inferred from a cast.
C_UnitAuras.GetPlayerAuraBySpellID = function() return {spellId = hidden} end
event("UNIT_AURA", "player")
assert(label.value == "~26")
event("ACTIONBAR_PAGE_CHANGED")
assert(not label.visible and not ActionButton1.DamageReaderSkillBinding)
print("Seal-switch regression passed: unrelated secrets, delayed aura, direct lookup, cached amount, invalidation")

-- Learning a rank refreshes the registry. Combat transitions must not keep
-- Judgment from a different seal/rank when the new quantity is unavailable.
fighting, protectedAction, protectedText = false, false, false
C_Spell.GetSpellName = function(id)
    if id == 20287 or id == 900002 then return "Sello de rectitud" end
    if id == 900003 then return "Sello de furia" end
    if id == 900004 then return "Sello de sabiduría" end
end
C_UnitAuras.GetPlayerAuraBySpellID = function(id)
    if id == seal then return {spellId = id} end
end
C_UnitAuras.GetAuraDataByIndex = function(_, index)
    if index == 1 and seal then return {spellId = seal} end
end
Enum = {SpellBookSpellBank = {Player = 0}}
C_SpellBook = {
    GetNumSpellBookSkillLines = function() assert(not fighting); return 1 end,
    GetSpellBookSkillLineInfo = function() return {itemIndexOffset = 0, numSpellBookItems = 3} end,
    GetSpellBookItemInfo = function(slot) return {spellID = ({20287, 900002, 900003})[slot]} end,
}
descriptions[20287] = "Otorga a cada ataque cuerpo a cuerpo entre 4 y 13 p. más de daño Sagrado. Desatar la energía de este sello inflige 40 a 44 p. de daño Sagrado."
descriptions[900003] = "Cada ataque inflige 8 p. de daño Sagrado. Desatar la energía de este sello inflige 31 a 35 p. de daño Sagrado."
descriptions[900004] = "Cada ataque restaura 40 p. de maná. Desatar la energía de este sello restaura 20 p. de maná."
actionID, seal = 20271, 20287
event("SPELLS_CHANGED")
assert(label.value == "42" and label.visible)
fighting = true
event("PLAYER_REGEN_DISABLED")
seal = 900003
event("UNIT_AURA", "player")
assert(label.value == "33")
seal = 900002 -- confirmed active rank, but its amounts have never been read
event("UNIT_AURA", "player")
assert(not label.visible, "different rank inherited the previous Judgment")
seal = 20287
event("UNIT_AURA", "player")
assert(label.value == "42" and label.visible)
-- Replacing a seal button with its new rank also discards old values.
actionID = 20287
event("ACTIONBAR_SLOT_CHANGED", 1)
assert(label.value == "4–13")
actionID = 900002
event("ACTIONBAR_SLOT_CHANGED", 1)
assert(not label.visible)
actionID = 900004
event("ACTIONBAR_SLOT_CHANGED", 1)
assert(label.value == "40" and label.color[3] == 1 and label.color[2] == .65)
print("Rank upgrade integration passed: learned ranks, Judgment isolation, button replacement and mana color")
