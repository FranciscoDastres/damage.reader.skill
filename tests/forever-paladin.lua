-- Verbatim descriptions from the user's Forever 1.60.1 / 70862 / 16001 esMX report.
local ns = {}
local fighting = false
local seal
local hidden = {}
local build = 16001
local low, high = 21.742858886719, 24.742858886719
local descriptions = {
    [679] = "Un golpe instantáneo que inflige un 25% de daño con arma y 2 a 4 p. de daño Sagrado.",
    [21084] = "Colma al paladín de espíritu sagrado durante 30 s y otorga a cada ataque cuerpo a cuerpo entre 2 y 9 p. más de daño Sagrado. Las armas más lentas infligen más daño Sagrado por ataque. Un paladín solo puede tener un sello activo a la vez.\n\nDesatar la energía de este sello inflige 24 a 27 p. de daño Sagrado a un enemigo.",
    [20271] = "Desata la energía de un hechizo de sello contra un enemigo. No consume el sello. Consulta cada sello para ver su efecto de Sentencia.",
    [639] = "Luz Sagrada\n60 p. de maná\nLanzamiento de 2.5 s\nSana un objetivo amistoso en 78 a 93 p.",
    [19740] = "Coloca una bendición sobre el objetivo aliado que aumenta 14 p. el poder de ataque cuerpo a cuerpo durante 1 h. Los jugadores solo pueden tener una bendición activa por Paladín a la vez.",
    [21082] = "Colma al paladín del espíritu de un cruzado durante 30 s, otorgando 32 p. de poder de ataque cuerpo a cuerpo. El paladín ataca un 40% más rápido pero causa menos daño en cada ataque. Un paladín solo puede tener un sello activo a la vez.\n\nDesatar la energía de este sello sentenciará a un enemigo durante 40 s, aumentando el daño Sagrado recibido en un máximo de 23 p. Tus golpes cuerpo a cuerpo restablecerán la duración del hechizo. Un paladín solo puede tener una sentencia activa a la vez.",
    [7620] = "Pesca\nAlcance de 10-20 m\nCanalizado\nRequiere Caña de pescar",
    [498] = "Te da inmunidad frente a los ataques físicos y hechizos durante 6 s, pero no puedes atacar ni usar habilidades físicas.",
}
GetLocale = function() return "esMX" end
GetBuildInfo = function() return "1.60.1", "70862", "", build end
InCombatLockdown = function() return fighting end
issecretvalue = function(value) return rawequal(value, hidden) end
UnitDamage = function() return low, high, 5.9285717010498, 5.9285717010498, 0, 0, 1 end
GetActionInfo = function(slot) return "spell", slot end
C_UnitAuras = {GetAuraDataByIndex = function(unit, index, filter)
    assert(unit == "player" and filter == "HELPFUL" and not fighting)
    if index == 1 and seal then return {spellId = seal} end
end}
C_Spell = {GetSpellDescription = function(id) return descriptions[id] end}
assert(loadfile("Calculator.lua"))("damage.reader.skill", ns)
assert(loadfile("Paladin.lua"))("damage.reader.skill", ns)
local calc = ns.Calculator
local count = 0
local function eq(value, expected)
    assert(value == expected, tostring(value) .. " ~= " .. tostring(expected))
    count = count + 1
end
local strike = calc:EstimateAction(679)
eq(strike.text, "9")
eq(strike.min, low * .25 + 2)
eq(strike.max, high * .25 + 4)
local heal = calc:EstimateAction(639)
eq(heal.kind, "heal")
eq(heal.text, "86")
eq(heal.min, 78)
eq(heal.max, 93)
eq(calc:EstimateAction(21084).text, "2–9")
eq(calc:EstimateAction(21084).value, nil) -- speed-dependent range, no fake mean
eq(calc:EstimateAction(20271), nil)
seal = 21084
eq(calc:EstimateAction(20271).text, "26")
eq(calc:EstimateAction(20271).min, 24)
eq(calc:EstimateAction(20271).max, 27)
seal = 21082
eq(calc:EstimateAction(20271).text, "0")
eq(calc:EstimateAction(21082), nil)
seal = 99999 -- unsupported seal never treated as Rectitude
eq(calc:EstimateAction(20271), nil)
seal = hidden
eq(calc:EstimateAction(20271), nil)
seal = nil
eq(calc:EstimateAction(20271), nil)
low, high = 40, 60 -- equipment/AP change must immediately change the formula
eq(calc:EstimateAction(679).value, 15.5)
low = hidden
eq(calc:EstimateAction(679), nil)
for _, id in ipairs({19740, 7620, 498}) do eq(calc:EstimateAction(id), nil) end
fighting = true
eq(calc:EstimateAction(679), nil)
eq(calc:EstimateAction(20271), nil)
fighting = false
build = 30300
eq(calc:EstimateAction(679), nil)
build = 16001
descriptions[679] = "Inflige 500% de daño con arma."
eq(calc:EstimateAction(679), nil) -- changed spell formula fails closed
print(count .. " checks against the Forever paladin report passed")
