-- Actual esMX descriptions and weapon stats supplied by the user, Forever
-- 1.60.1 / 70862 / 16001. Combo points, max health, aura changes and protected
-- values below are controlled test inputs, not observations from the reports.
local ns = {version = 'test'}
local class, low, high, speed, rangedLow, rangedHigh
local points, health, seal, hidden = 0, 500, nil, {}
local names, descriptions, slots = {}, {}, {}
GetBuildInfo = function() return '1.60.1', '70862', '', 16001 end
GetLocale = function() return 'esMX' end
UnitClass = function() return class, class end
InCombatLockdown = function() return false end
issecretvalue = function(v) return rawequal(v, hidden) end
UnitDamage = function() return low, high, 0, 0, 0, 0, 1 end
UnitRangedDamage = function() return speed, rangedLow, rangedHigh, 0, 0, 1 end
GetComboPoints = function() return points end
UnitHealthMax = function() return health end
GetActionInfo = function(slot) if slots[slot] then return 'spell', slots[slot] end end
C_Spell = {GetSpellName = function(id) return names[id] end,
    GetSpellDescription = function(id) return descriptions[id] end}
C_UnitAuras = {GetAuraDataByIndex = function(_, index)
    if index == 1 and seal then return {spellId = seal} end
end}
for _, file in ipairs({'Data.lua', 'ClassData.lua', 'Calculator.lua', 'Paladin.lua', 'Effects.lua', 'Classes.lua'}) do
    assert(loadfile(file))('damage.reader.skill', ns)
end
local calc, checks = ns.Calculator, 0
local function eq(actual, expected)
    assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
    checks = checks + 1
end
local function player(token, min, max, rs, rmin, rmax)
    class, low, high = token, min, max
    speed, rangedLow, rangedHigh = rs or 0, rmin or 0, rmax or 0
end
local function check(id, name, text, expected, kind)
    names[id], descriptions[id] = name, text
    local result, reason = calc:EstimateSpell(id)
    assert(result, name .. ': ' .. tostring(reason))
    eq(result.text, expected)
    if kind then eq(result.kind, kind) end
    return result
end
player('MAGE', 5.2785716056824, 7.2785716056824)
check(116, 'Descarga de Escarcha', 'Lanza una descarga de Escarcha al enemigo que le inflige de 18 a 20 p. de daño de Escarcha y ralentiza su velocidad de movimiento un 40% durante 5 s.', '19', 'damage')
check(2136, 'Explosión de Fuego', 'Golpea al enemigo, inflige 24 a 32 p. de daño de Fuego.', '28')
check(143, 'Bola de Fuego', 'Lanza una bola ígnea que causa 26 a 38 p. de daño de Fuego y 3 p. de daño de Fuego extra durante 6 s.', '32+3/6s')
local fireball = check(133, 'Bola de Fuego', 'Lanza una bola ígnea que inflige 14 a 23 p. de daño de Fuego y 2 p. extra durante 4 s.', '19+2/4s')
eq(fireball.effects[1].duration, nil)
eq(fireball.effects[2].duration, '4')
-- An unrelated sentence must not inherit the first effect's damage unit.
local effects = calc:ReadEffects('Inflige 14 a 23 p. de daño de Fuego. Gana un beneficio y 2 p. extra durante 4 s.', 'mixed')
eq(#effects, 1)
eq(effects[1].duration, nil)
player('DRUID', 6.3142862319946, 8.3142862319946)
check(5176, 'Cólera', 'Inflige 14 a 16 p. de daño de Naturaleza al objetivo.', '15')
check(5185, 'Toque de sanación', 'Sana 37 a 51 p. a un objetivo aliado.', '44', 'heal')
player('HUNTER', 4.2857146263123, 6.2857146263123, 2.0910000801086, 9.2857151031494, 12.285715103149)
local raptor = check(2973, 'Golpe de raptor', 'Un ataque contundente que inflige 5 p. más de daño con arma cuerpo a cuerpo.', '≈10')
eq(raptor.min, low + 5)
eq(raptor.max, high + 5)
check(75, 'Disparo automático', 'Dispara automáticamente al objetivo hasta que se cancela.', '11')
check(6603, 'Atacar', '', '5')
low, high = 20, 30 -- changed weapon stats must refresh, not reuse initial amount
check(6603, 'Atacar', '', '25')
low = hidden
eq(calc:EstimateSpell(6603), nil)
for _, invalid in ipairs({-1, 0/0, math.huge}) do
    low, high = invalid, invalid
    eq(calc:EstimateSpell(6603), nil)
end
low, high = 30, 20
eq(calc:EstimateSpell(6603), nil)
player('WARRIOR', 4.1214289665222, 6.1214289665222)
local heroic = check(78, 'Golpe heroico', 'Un ataque contundente que aumenta 11 p. el daño cuerpo a cuerpo y genera una gran amenaza.', '≈16')
eq(heroic.min, low + 11)
player('WARLOCK', 2.1428570747375, 3.1428570747375)
check(686, 'Descarga de las Sombras', 'Lanza una descarga de las Sombras al enemigo, lo que le inflige 11 a 15 p. de daño de las Sombras.', '13')
names[687] = 'Piel de demonio'
descriptions[687] = 'Protege al taumaturgo, lo que aumenta la armadura 40 p. y la regeneración 3 p. de salud cada 5 s durante 30 min.'
eq(calc:EstimateSpell(687), nil)
player('SHAMAN', 4.8000001907349, 6.8000001907349)
check(403, 'Descarga de relámpagos', 'Lanza una descarga de relámpagos sobre el objetivo que le inflige 15 a 17 p. de daño de Naturaleza.', '16')
check(331, 'Ola de sanación', 'Sana 34 a 44 p. a un objetivo aliado.', '39', 'heal')
player('ROGUE', 4.1999998092651, 5.1999998092651, 2, 6.2857146263123, 8.2857151031494)
local sinister = check(1752, 'Golpe siniestro', 'Un golpe instantáneo que inflige 3 p. de daño aparte del daño de arma normal. Otorga 1 p. de combo.', '≈8')
eq(sinister.min, low + 3)
check(2764, 'Lanzar', 'Lanza un arma arrojadiza al objetivo.', '7')
names[2098] = 'Eviscerar'
descriptions[2098] = [[35 p. de energía
1 a 5 |4Punto:Puntos; de combo
Remate que inflige daño por cada punto de combo. El daño aumenta con el poder de ataque:
   1 punto: 6-10 p. de daño
   2 puntos: 11-15 p. de daño
   3 puntos: 16-20 p. de daño
   4 puntos: 21-25 p. de daño
   5 puntos: 26-30 p. de daño]]
local value, reason, state = calc:EstimateSpell(2098)
eq(value, nil); eq(state, 'empty'); assert(reason:find('0 puntos', 1, true))
for cp = 1, 5 do points = cp; eq(calc:EstimateSpell(2098).text, tostring(cp * 5 + 3)) end
points = hidden
eq(calc:EstimateSpell(2098), nil)
player('PRIEST', 2.3571429252625, 4.3571429252625)
check(585, 'Punición', 'Golpea al enemigo y le inflige 13 a 17 p. de daño Sagrado.', '15')
check(2050, 'Sanación inferior', 'Sana a tu objetivo 46 a 56 p.', '51', 'heal')
names[5019], descriptions[5019] = 'Disparar', 'Ataque con una varita equipada.'
eq(calc:EstimateSpell(5019), nil) -- actual reports have zero ranged stats
speed, rangedLow, rangedHigh = 1.5, 10, 20 -- synthetic equipped wand
local wand = calc:EstimateSpell(5019)
eq(wand.text, '15'); eq(wand.min, 10); eq(wand.max, 20)
rangedLow = hidden
eq(calc:EstimateSpell(5019), nil)
player('PALADIN', 42.457145690918, 61.457145690918)
check(678, 'Golpe Sagrado', 'Un golpe instantáneo que inflige un 29% de daño con arma y 4 a 6 p. de daño Sagrado.', '20')
check(647, 'Luz Sagrada', 'Sana un objetivo amistoso en 142 a 169 p.', '156', 'heal')
check(633, 'Imposición de manos', 'Sana a un objetivo aliado la misma cantidad de puntos que la salud máxima del paladín. Cuando se usa, absorbe todo el maná restante del paladín, pero no interrumpe la regeneración de maná.', '500', 'heal')
health = 700
eq(calc:EstimateSpell(633).text, '700')
health = hidden
eq(calc:EstimateSpell(633), nil)
health = 500
check(20287, 'Sello de rectitud', 'Colma al paladín de espíritu sagrado durante 30 s y otorga a cada ataque cuerpo a cuerpo entre 3 y 11 p. más de daño Sagrado. Las armas más lentas infligen más daño Sagrado por ataque. Un paladín solo puede tener un sello activo a la vez.\n\nDesatar la energía de este sello inflige 32 a 35 p. de daño Sagrado a un enemigo.', '3–11')
check(1311649, 'Sello de furia', 'Te colma de furia divina durante 30 s, provocando que los ataques cuerpo a cuerpo inflijan 6 de daño sagrado adicional. Mientras tienes un escudo equipado, cada ataque también otorga un escudo de absorción equivalente al 50% del daño sagrado infligido. Un paladín solo puede tener un sello activo a la vez.\n\nDesatar la energía de este sello inflige 28 a 31 de daño sagrado a un enemigo y provoca al objetivo para que te ataque durante 3 s.', '6')
eq(calc:EstimateSpell(20271), nil)
seal = 20287; eq(calc:EstimateSpell(20271).text, '34')
seal = 1311649; eq(calc:EstimateSpell(20271).text, '30')
seal = nil; eq(calc:EstimateSpell(20271), nil)
for _, id in ipairs({1259718, 20600, 13262, 7411, 3908, 1296017, 1259799, 20580, 20594, 2481, 2580, 7731}) do
    eq(calc:GetSpellFamily(id), 'GENERAL/utility')
    local result, _, status = calc:EstimateSpell(id)
    eq(result, nil); eq(status, 'empty')
end
for _, id in ipairs({20598, 81, 1293657, 1293712, 20597, 20585, 20582, 1259721, 1259719, 107, 3127}) do
    eq(calc:GetSpellFamily(id), 'GENERAL/passive')
    eq(calc:EstimateSpell(id), nil)
end
-- Reports retain source text without contradicting a successful family model
-- with the unrelated, deliberately conservative generic parser's failure.
player('DRUID', 6.3142862319946, 8.3142862319946)
slots[1], slots[2] = 5185, 81
local report = calc:BuildReport()
assert(report:find('Modelo: 44', 1, true))
assert(report:find(descriptions[5185], 1, true))
assert(not report:find('sin cantidad directa verificable', 1, true))
assert(not report:find('Sello activo', 1, true))
assert(report:find('Salud máxima: 500', 1, true))
print(checks .. ' checks against nine Forever class reports passed, plus report assertions')
