-- Synthetic language/API fixtures: these test parsing and rank isolation,
-- not the actual amounts or coefficients of an unobserved Forever build.
local ns, hidden = {}, {}
local descriptions, names, active, book = {}, {}, nil, {}
local fighting, maxHealth, weaponLow = false, 1234, 20
GetBuildInfo = function() return "1.60.1", "70862", "", 16001 end
GetLocale = function() return "esMX" end
InCombatLockdown = function() return fighting end
issecretvalue = function(value) return rawequal(value, hidden) end
UnitDamage = function() return weaponLow, 40 end
UnitHealthMax = function() return maxHealth end
GetActionInfo = function() end
C_Spell = {
    GetSpellName = function(id) return names[id] end,
    GetSpellDescription = function(id) return descriptions[id] end,
}
C_UnitAuras = {
    GetPlayerAuraBySpellID = function(id) if id == active then return {spellId = id} end end,
    GetAuraDataByIndex = function(_, index)
        if index == 1 then return {spellId = hidden} end
        if index == 2 and active then return {spellId = active, name = names[active]} end
    end,
}
Enum = {SpellBookSpellBank = {Player = 0}}
C_SpellBook = {
    GetNumSpellBookSkillLines = function() assert(not fighting); return 1 end,
    GetSpellBookSkillLineInfo = function() return {itemIndexOffset = 0, numSpellBookItems = #book} end,
    GetSpellBookItemInfo = function(slot, bank) assert(bank == 0); return {spellID = book[slot], name = names[book[slot]]} end,
    GetSpellBookItemName = function(slot) return names[book[slot]] end,
}
for _, file in ipairs({"Data.lua", "Calculator.lua", "Paladin.lua", "Spellbook.lua"}) do
    assert(loadfile(file))("damage.reader.skill", ns)
end
local calc, count = ns.Calculator, 0
local function eq(actual, expected)
    assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
    count = count + 1
end
local function add(id, name, text)
    names[id], descriptions[id] = name, text
    book[#book + 1] = id
end
local function result(id, text, kind)
    local value, reason = calc:EstimateSpell(id)
    assert(value, reason)
    eq(value.text, text)
    if kind then eq(value.kind, kind) end
    return value
end
add(20271, "Sentencia", "Desata el sello activo.")
-- IDs deliberately arbitrary: no rank table is allowed to decide the amount.
for rank = 1, 8 do
    local id, amount = 900000 + rank, rank * 10
    add(id, "Sello de rectitud", "Colma al paladín durante 30 s y otorga a cada ataque cuerpo a cuerpo entre "
        .. amount .. " y " .. (amount + 9) .. " p. más de daño Sagrado. Las armas más lentas infligen más daño.\n"
        .. "Desatar la energía de este sello inflige " .. (amount + 20) .. " a " .. (amount + 24) .. " p. de daño Sagrado.")
    result(id, amount .. "–" .. (amount + 9))
    active = id
    result(20271, tostring(amount + 22))
end
-- Actual reported failure: learning another rank discovers it without reload,
-- and direct aura lookup works when general enumeration is unavailable.
add(20287, "Sello de rectitud", "Otorga a cada ataque cuerpo a cuerpo entre 4 y 13 p. más de daño Sagrado. "
    .. "Desatar la energía de este sello inflige 40 a 44 p. de daño Sagrado.")
calc:RefreshSpellbook()
local enumeration = C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex = function() error("protected enumeration") end
active = 20287
result(20271, "42")
result(20287, "4–13")
descriptions[20287] = hidden
local stale = result(20271, "42")
eq(stale.stale, true)
-- Unknown new rank must not borrow rank 2 or the previous seal's range.
add(900099, "Sello de rectitud", nil)
calc:RefreshSpellbook()
active = 900099
local value, _, state = calc:EstimateSpell(20271)
eq(value, nil)
eq(state, "empty")
C_UnitAuras.GetAuraDataByIndex = enumeration
add(900100, "Sello de furia", "Colma al paladín de furia divina durante 30 s y hace que sus ataques cuerpo a cuerpo inflijan 8 p. de daño Sagrado adicional. "
    .. "Obtiene un escudo que absorbe un 50% del daño. Desatar la energía de este sello inflige 31 a 35 p. de daño Sagrado y provoca al objetivo durante 3 s.")
result(900100, "8", "damage")
active = 900100
result(20271, "33")
add(900101, "Seal of Fury", "Fills the Paladin for 30 sec, causing melee attacks to deal an additional 14 Holy damage. "
    .. "Grants an absorb shield for 50% of the damage. Unleashing this Seal's energy inflicts 40 to 44 Holy damage and taunts for 4 sec.")
result(900101, "14")
active = 900101
result(20271, "42")
for rank = 1, 8 do
    local id = 900200 + rank
    add(id, "Golpe Sagrado", "Un golpe instantáneo que inflige un " .. (25 + rank) .. "% de daño con arma y 2 a 4 p. de daño Sagrado.")
    local value = calc:EstimateSpell(id)
    eq(value.min, 20 * (25 + rank) / 100 + 2)
    eq(value.max, 40 * (25 + rank) / 100 + 4)
end
add(900220, "Holy Strike", "An instant strike that causes 50% weapon damage plus an additional 2 to 4 as Holy damage.")
-- Standard English phrasing may put 'as' between quantity and school.
result(900220, "18")
add(900300, "Sello de orden", "Otorga una probabilidad de infligir un daño Sagrado equivalente al 70% del daño del arma. "
    .. "Desatar la energía de este sello inflige 30 a 40 p. de daño Sagrado; el doble contra objetivos aturdidos.")
result(900300, "21")
active = 900300
result(20271, "35")
weaponLow = hidden
eq(calc:EstimateSpell(900300), nil)
weaponLow = 20
add(900310, "Sello de Luz", "Cada ataque tiene una probabilidad de sanar 50 p. de salud. "
    .. "Desatar la energía de este sello permite a los ataques restaurar 30 p. de salud.")
result(900310, "50", "heal")
active = 900310
result(20271, "30", "heal")
add(900320, "Sello de sabiduría", "Cada ataque tiene una probabilidad de restaurar 40 p. de maná. "
    .. "Desatar la energía de este sello permite a los ataques restaurar 20 p. de maná.")
result(900320, "40", "mana")
active = 900320
result(20271, "20", "mana")
for i, name in ipairs({"Luz Sagrada", "Destello de Luz", "Holy Light", "Flash of Light"}) do
    add(900400 + i, name, "Sana un objetivo amistoso en 100 a 120 p.")
    result(900400 + i, "110", "heal")
end
for i, name in ipairs({"Exorcismo", "Martillo de cólera", "Cólera Sagrada", "Exorcism", "Holy Wrath"}) do
    add(900420 + i, name, "Inflige 100 a 120 p. de daño Sagrado a los enemigos en 10 m.")
    result(900420 + i, "110", "damage")
end
add(900450, "Choque Sagrado", "Inflige 100 a 120 p. de daño Sagrado a un enemigo o sana a un aliado en 150 a 170 p.")
result(900450, "110/160", "dual")
add(900451, "Light's Vigil", "After Holy Shock, deals 100 to 120 Holy damage to an enemy or heals allies for 150 to 170 health.")
result(900451, "110/160", "dual")
add(900460, "Consagración", "Consagra el suelo e inflige 80 p. de daño Sagrado durante 8 s a los primeros 4 enemigos. Los demás reciben un 10% del daño.")
result(900460, "80/8s")
add(900461, "Consecration", "Deals 10 Holy damage every 1 sec for 8 sec to the first 4 enemies.")
result(900461, "10/t")
add(900462, "Consagración", "Inflige 80 p. de daño Sagrado a los primeros 4 y 8 p. de daño Sagrado a los demás durante 8 s.")
eq(calc:EstimateSpell(900462), nil) -- ambiguous target tiers must not be added
for i, name in ipairs({"Escudo Sagrado", "Aura de reprensión", "Holy Shield", "Retribution Aura"}) do
    add(900470 + i, name, "Aumenta el bloqueo un 30% durante 10 s e inflige 25 p. de daño Sagrado al bloquear. 4 cargas.")
    result(900470 + i, "25")
end
add(900480, "Imposición de manos", "Sana al objetivo por una cantidad igual a la salud máxima del paladín y restaura 100 p. de maná.")
result(900480, "1234", "heal")
add(900481, "Templar's Bulwark", "Gain a shield absorbing damage equal to 100% of your maximum health for 8 sec.")
result(900481, "1234", "absorb")
maxHealth = 1500
result(900480, "1500", "heal")
maxHealth = hidden
eq(calc:EstimateSpell(900481), nil)
-- Misleading quantities in non-damage skills stay off the damage overlay.
for i, name in ipairs({"Furia recta", "Redención", "Bendición de sacrificio", "Protección divina", "Voice of Truth", "Swift Judgement"}) do
    add(900500 + i, name, "Transfiere 50 p. de daño y restaura 100 p. de salud durante 10 s.")
    eq(calc:EstimateSpell(900500 + i), nil)
end
-- A non-Paladin spell cannot acquire a Paladin model from a number alone.
add(900600, "Unknown spell", "25% weapon damage plus 2 to 4 Holy damage.")
eq(calc:EstimateSpell(900600), nil)
add(900601, "Sello de furia", "Aumenta tu amenaza un 60% durante 30 s.")
eq(calc:EstimateSpell(900601), nil)
add(900603, "Sello de furia", "Cada ataque inflige 14 p. de daño Sagrado.")
result(900603, "14")
active = 900603
eq(calc:EstimateSpell(20271), nil) -- no Judgment paragraph: never use on-hit damage
add(900604, "Imposición de manos", "Sana un 3% de la salud máxima del paladín.")
maxHealth = 1500
eq(calc:EstimateSpell(900604), nil) -- do not infer 100% from a max-health mention
-- Late spell text: failed lookups are not negatively cached.
names[900602] = hidden
eq(calc:GetPaladinFamily(900602), nil)
add(900602, "Sello de furia", descriptions[900100])
result(900602, "8")
calc:RefreshSpellbook()
eq(#calc.knownSpells, #book)
-- The report must contain spells absent from all action bars.
ns.version = "test"
local report = calc:BuildReport()
assert(report:find("Hechizo 900602", 1, true))
assert(report:find("familia fury", 1, true))
-- Legacy spellbook and missing APIs are supported without throwing.
C_SpellBook = nil
GetNumSpellTabs = function() return 1 end
GetSpellTabInfo = function() return "Paladin", nil, 0, #book end
GetSpellBookItemInfo = function(slot) return "SPELL", book[slot] end
GetSpellBookItemName = function(slot) return names[book[slot]] end
calc:RefreshSpellbook()
eq(#calc.knownSpells, #book)
fighting = true
GetNumSpellTabs = function() error("must not read spellbook in combat") end
calc.spellbookDirty = true
calc:RefreshSpellbook()
eq(calc.spellbookDirty, true)
print(count .. " rank/family checks passed (synthetic fixtures; in-client validation still required)")
