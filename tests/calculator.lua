-- Synthetic fixtures: these are regression cases, not Forever spell data.
local ns = {}
local locale = "esES"
GetLocale = function() return locale end
local fighting = false
InCombatLockdown = function() return fighting end
assert(loadfile("Calculator.lua"))("damage.reader.skill", ns)
local calc = ns.Calculator
local count = 0
local function check(text, expected, kind)
    local value = calc:Parse(text)
    assert((value and value.value or nil) == expected, text .. ": " .. tostring(value and value.value))
    if value then assert(value.kind == kind) end
    count = count + 1
end
check("Luz Sagrada\nRango 2\n40 maná\n2.5 s de lanzamiento\nSana de 76 a 90 puntos de salud.", 83, "heal")
check("Sana al objetivo de 88 a 106.", 97, "heal")
check("Inflige de 25 a 40 puntos de daño Sagrado.", 32.5, "damage")
check("Inflige 25-40 p. de daño Sagrado.", 32.5, "damage")
check("Inflige 1.250 de daño.", 1250, "damage")
check("Restaura 3% de salud.", nil)
check("3% de maná base\nSana de 88 a 106 puntos de salud.", 97, "heal")
check("Inflige 40 de daño cada 2 s.", nil)
check("Libera el sello causando daño.", nil)
check("Aumenta el daño un 25%.", nil)
check("Inflige 25 de daño y sana 40 puntos de salud.", nil)
check("Inflige -25 de daño.", nil)
check("Rango 3\n25 maná\n40 m\n2 s de lanzamiento", nil)
check("Sana de 106 a 88 puntos de salud.", nil)
check("|cffffffffSana de 88 a 106 puntos de salud.|r", 97, "heal")
locale = "enUS"
check("Deals 100 to 120 Holy damage.", 110, "damage")
check("Heals the target for 88 to 106.", 97, "heal")
check("Restores 1,200 health.", 1200, "heal")
check("Deals 40 damage over 8 sec.", nil)
check("Deals 100% weapon damage.", nil)
-- A nonempty action tooltip with only costs must not suppress spell fallback.
GetActionInfo = function() return "spell", 123 end
C_Spell = {GetSpellDescription = function() return "Heals the target for 88 to 106." end}
C_TooltipInfo = {GetAction = function() return {lines = {{leftText = "40 mana"}}} end}
assert(calc:EstimateAction(1).value == 97)
fighting = true
GetActionInfo = function() error("simulated unavailable action API") end
assert(calc:EstimateAction(1) == nil)
fighting = false
-- The guard must recognize a protected object before touching/comparing it.
local secret = {}
issecretvalue = function(v) return rawequal(v, secret) end
assert(calc:Parse(secret) == nil)
print(count .. " parser cases + fallback/combat/secret checks passed")

-- Exercise the actual renderer: a nil actionID must not hide a valid .action.
ns.db = {enabled = true, fontSize = 11, color = {1, .82, .05}, healColor = {.2, 1, .2}}
assert(loadfile("Buttons.lua"))("damage.reader.skill", ns)
local label = {}
function label:SetFont() end
function label:SetTextColor(r, g, b) self.color = {r, g, b} end
function label:SetText(value) self.value = value end
function label:Show() self.visible = true end
function label:Hide() self.visible = false end
local button = {action = 7, DamageReaderSkillText = label}
GetActionInfo = function(slot) assert(slot == 7); return "spell", 123 end
ns.Buttons:UpdateButton(button)
assert(label.value == "97" and label.color[2] == 1 and label.visible)
C_Spell.GetSpellDescription = function() return "Deals 100 to 120 Holy damage." end
ns.Buttons:UpdateButton(button)
assert(label.value == "110" and label.color[1] == 1 and label.visible)
C_Spell.GetSpellDescription = function() return "Deals 100% weapon damage." end
ns.Buttons:UpdateButton(button)
assert(not label.visible)
print("Healing/damage colors, action mapping and unsupported-value hiding passed")
