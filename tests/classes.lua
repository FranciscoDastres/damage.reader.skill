-- Synthetic fixtures, not scraped or verified spell values. All IDs here are
-- arbitrary to exercise family/rank discovery without imported Classic data.
local ns, hidden = {}, {}
local class, locale, build, fighting = 'ROGUE', 'enUS', 16001, false
local points, rage = 3, 40
local weaponLow, weaponHigh, offLow, offHigh = 20, 40, 10, 20
local rangedLow, rangedHigh = 50, 70
local ap, apPlus, apMinus = 100, 20, -10
local costs = {{type = 1, minCost = 15, cost = 100}}
local descriptions, names, id, count = {}, {}, 800000, 0
GetBuildInfo = function() return '1.60.1', '70862', '', build end
GetLocale = function() return locale end
UnitClass = function() return class, class end
InCombatLockdown = function() return fighting end
issecretvalue = function(value) return rawequal(value, hidden) end
GetComboPoints = function(unit, target) assert(unit == 'player' and target == 'target'); return points end
Enum = {PowerType = {Rage = 1, ComboPoints = 4}}
UnitPower = function(_, power) return power == 1 and rage or points end
UnitDamage = function() return weaponLow, weaponHigh, offLow, offHigh end
UnitRangedDamage = function() return 2.5, rangedLow, rangedHigh end
UnitAttackPower = function() return ap, apPlus, apMinus end
C_Spell = {
    GetSpellName = function(spell) return names[spell] end,
    GetSpellDescription = function(spell) return descriptions[spell] end,
    GetSpellPowerCost = function() return costs end,
}
for _, file in ipairs({'Data.lua', 'ClassData.lua', 'Calculator.lua', 'Paladin.lua', 'Effects.lua', 'Classes.lua', 'Spellbook.lua'}) do
    assert(loadfile(file))('damage.reader.skill', ns)
end
local calc = ns.Calculator
local function eq(actual, expected)
    assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
    count = count + 1
end
local function add(name, text)
    id = id + 1
    names[id], descriptions[id] = name, text
    return id
end
local function expect(spell, text, kind)
    local value, reason = calc:EstimateSpell(spell)
    assert(value, tostring(names[spell]) .. ': ' .. tostring(reason))
    eq(value.text, text)
    if kind then eq(value.kind, kind) end
    return value
end
local function check(name, description, text, kind)
    local spell = add(name, description)
    expect(spell, text, kind)
    return spell
end
local function empty(spell, state)
    local value, _, actual = calc:EstimateSpell(spell)
    eq(value, nil)
    if state then eq(actual, state) end
end
check('Sinister Strike', 'An instant attack that causes normal damage plus 5.', '≈35', 'damage')
check('Backstab', 'Causes 150% weapon damage plus 10 damage. Awards 1 combo point.', '≈55')
check('Backstab', 'Causes 150.5% weapon damage plus 10 damage.', '≈55')
check('Mutilate', 'Strikes with both weapons for 100% weapon damage. Damage is increased by 20% against poisoned targets.', '≈45')
check('Instant Poison', 'Each strike has a 20% chance to deal 20 to 30 Nature damage.', '25')
check('Garrote', 'Garrote the enemy, causing 120 damage over 18 sec.', '120/18s')
local rows = 'Finishing move that causes damage per combo point:\n'
for cp = 1, 5 do rows = rows .. cp .. ' combo points: ' .. cp * 10 .. ' to ' .. (cp * 10 + 10) .. ' damage\n' end
local finisher = check('Eviscerate', rows, '35')
for cp = 1, 5 do points = cp; expect(finisher, tostring(cp * 10 + 5)) end
points = 0; empty(finisher, 'empty')
points = hidden; empty(finisher, 'empty')
points = 3
local rupture = check('Rupture', 'Finishing move that causes damage:\n1 combo point: 20 damage over 8 sec\n3 combo points: 60 damage over 12 sec', '60/12s')
points = 2; empty(rupture, 'empty'); points = 3
local noRows = add('Eviscerate', 'Finishing move that causes 20 damage per combo point.')
empty(noRows, 'empty') -- no guessed coefficient/CP formula
empty(add('Slice and Dice', 'Increases attack speed by 30% for 20 sec.'), 'empty')
class = 'DRUID'
check('Wrath', 'Causes 40 to 60 Nature damage.', '50')
check('Healing Touch', 'Heals a friendly target for 100 to 120.', '110', 'heal')
check('Rejuvenation', 'Heals the target for 120 over 12 sec.', '120/12s', 'heal')
check('Moonfire', 'Deals 20 to 30 Arcane damage and an additional 40 Arcane damage over 12 sec.', '25+40/12s')
check('Regrowth', 'Heals the target for 100 to 120 and another 90 over 21 sec.', '110+90/21s', 'heal')
check('Tranquility', 'Heals party members for 30 health every 2 sec for 8 sec.', '30/t', 'heal')
check('Shred', 'Shreds the target, causing 225% weapon damage plus 20 damage.', '≈88')
local bite = check('Ferocious Bite', 'Converts extra energy into additional damage.\n3 combo points: 100 to 120 damage', '≥110')
check('Thorns', 'Thorns sprout from the friendly target causing 18 Nature damage to attackers when hit. Lasts 10 min.', '18')
empty(add('Cat Form', 'Increases attack power by 40 and reduces damage by 10.'), 'empty')
class = 'PRIEST'
check('Smite', 'Smites an enemy for 100 to 120 Holy damage.', '110')
check('Shadow Word: Pain', 'Causes 120 Shadow damage over 18 sec.', '120/18s')
check('Renew', 'Heals the target for 120 over 15 sec.', '120/15s', 'heal')
check('Holy Fire', 'Consumes the enemy in flames that cause 40 to 60 Holy damage and an additional 30 Holy damage over 7 sec.', '50+30/7s')
check('Power Word: Shield', 'Shields the target, absorbing 200 damage. Lasts 30 sec.', '200', 'absorb')
check('Holy Nova', 'Causes 20 to 30 Holy damage to nearby enemies and heals party members for 30 to 40. These effects cause no threat.', '25 | 35', 'dual')
check('Penance', 'Deals 25 Holy damage every 1 sec to an enemy or heals 50 health every 1 sec to an ally.', '25/t | 50/t', 'dual')
check('Prayer of Mending', 'Heals 100 health when damage is taken. Jumps up to 5 times. Lasts 30 sec.', '100', 'heal')
check('Devouring Plague', 'Causes 120 Shadow damage over 24 sec and heals the caster for 100% of the damage caused.', '120/24s')
check('Shadow Word: Death', 'Deals 50 to 70 Shadow damage. If the target survives, you take 10% of your maximum health as damage.', '60')
empty(add('Resurrection', 'Brings a dead ally back with 100 health and 200 mana.'), 'empty')
class = 'WARRIOR'
check('Heroic Strike', 'A strong attack that increases melee damage by 12.', '≈42')
check('Mortal Strike', 'A vicious strike that deals weapon damage plus 20 and reduces healing received by 50% for 10 sec.', '≈50')
check('Thunder Clap', 'Blasts nearby enemies for 40 Nature damage and reduces attack speed by 10% for 10 sec.', '40')
check('Rend', 'Wounds the target causing 60 damage over 15 sec.', '60/15s')
local blood = check('Bloodthirst', 'Instantly attack the target causing damage equal to 45% of your attack power. Your next 5 attacks restore 10 health.', '50')
ap = 200; expect(blood, '95'); ap = 100
apPlus = hidden; empty(blood); apPlus = 20
local execution = check('Execute', 'Attempts to finish off an enemy, causing 100 damage and converting each extra point of rage into additional damage, plus 3 for each extra point of rage.', '175')
rage = 20; expect(execution, '115')
rage = 10; empty(execution, 'empty')
rage = hidden; empty(execution, 'empty')
rage = 40; costs = {{type=1, cost=100}}; empty(execution, 'empty')
costs = {{type=1, minCost=15, cost=30}}; expect(execution, '145')
empty(add('Battle Shout', 'Increases melee attack power by 100 for 2 min.'), 'empty')
class = 'MAGE'
check('Frostbolt', 'Deals 30 to 50 Frost damage and slows movement speed by 40% for 9 sec.', '40')
check('Fireball', 'Hurls a fiery ball that causes 20 to 30 Fire damage and an additional 8 Fire damage over 8 sec.', '25+8/8s')
check('Frostfire Bolt', 'Deals 40 to 60 Frostfire damage and an additional 10 Frostfire damage over 9 sec. Slows by 40%.', '50+10/9s')
check('Arcane Missiles', 'Launches missiles causing 20 Arcane damage every 1 sec for 5 sec.', '20/t')
check('Blizzard', 'Ice shards pelt the area doing 120 Frost damage over 8 sec.', '120/8s')
check('Ice Lance', 'Deals 20 to 30 Frost damage. Deals 300% increased damage against frozen targets.', '25')
check('Mana Shield', 'Absorbs 150 physical damage, draining mana instead. Lasts 60 sec.', '150', 'absorb')
empty(add('Polymorph', 'Transforms the enemy for 20 sec, regenerating 100 health.'), 'empty')
class = 'WARLOCK'
check('Shadow Bolt', 'Sends a bolt at the enemy, causing 80 to 100 Shadow damage.', '90')
check('Immolate', 'Burns the enemy for 20 Fire damage and then an additional 60 Fire damage over 15 sec.', '20+60/15s')
check('Corruption', 'Corrupts the target, causing 120 Shadow damage over 18 sec.', '120/18s')
check('Bane of Agony', 'Causes 150 Shadow damage over 24 sec.', '150/24s')
check('Drain Life', 'Drains 15 health from the target every 1 sec for 5 sec.', '15/t')
check('Death Coil', 'Deals 100 Shadow damage to the target and heals the caster for 100 health.', '100 | 100', 'dual')
check('Wrack', 'Inflicts 25 Shadow damage every second and increases other periodic damage by 10% for 6 sec.', '25/t')
check('Life Tap', 'Converts 30 health into 50 mana.', '50', 'mana')
check('Health Funnel', 'Gives 20 health to the pet every second at the cost of 10 health.', '20/t', 'heal')
check('Shadow Ward', 'Absorbs 300 Shadow damage. Lasts 30 sec.', '300', 'absorb')
empty(add('Hellfire', 'Deals 30 Fire damage to yourself and 40 Fire damage to nearby enemies every 1 sec.'), 'empty')
empty(add('Summon Imp', 'Summons a demon that deals 100 Fire damage.'), 'empty')
class = 'HUNTER'
check('Aimed Shot', 'An aimed shot that increases ranged damage by 40.', '≈100')
check('Multi-Shot', 'Fires at 3 targets causing weapon damage plus 10 damage to each.', '≈70')
check('Arcane Shot', 'An instant shot that causes 50 Arcane damage.', '50')
check('Serpent Sting', 'Stings the target causing 80 Nature damage over 15 sec.', '80/15s')
check('Mend Pet', 'Heals your pet for 20 health every second for 5 sec.', '20/t', 'heal')
empty(add('Revive Pet', 'Revives your pet with 100 health.'), 'empty')
class = 'SHAMAN'
check('Lightning Bolt', 'Casts a bolt causing 40 to 60 Nature damage.', '50')
check('Chain Lightning', 'Deals 50 Nature damage to the first target. Each jump reduces damage by 30%, affecting 3 targets.', '50')
check('Flame Shock', 'Sears the target with 20 Fire damage and then 40 Fire damage over 12 sec.', '20+40/12s')
check('Chain Heal', 'Heals the friendly target for 100 to 120, then jumps to 2 nearby allies. Healing is reduced by 50% per jump.', '110', 'heal')
check('Healing Stream Totem', 'Summons a totem that restores 8 health every 2 sec to party members. Lasts 120 sec.', '8/t', 'heal')
check('Lightning Shield', 'Surrounds you with orbs that deal 20 Nature damage to attackers. 3 charges. Lasts 600 sec.', '20')
check('Stormstrike', 'Instantly attacks with both weapons for 100% weapon damage and increases Nature damage taken by 20%.', '≈45')
empty(add('Strength of Earth Totem', 'Increases strength by 30 for 120 sec.'), 'empty')
-- Spanish aliases and punctuation, with separate costs/durations/targets.
locale = 'esMX'
class = 'MAGE'
check('Bola de Fuego', 'Bola de Fuego\nRango 2\n45 p. de maná\nInflige 100 a 120 p. de daño de Fuego y 40 p. de daño de Fuego adicionales durante 8 s.', '110+40/8s')
check('Descarga de Escarcha', 'Inflige 1.000 a 1.200 p. de daño de Escarcha y reduce el movimiento un 40% durante 8 s.', '1100')
class = 'DRUID'
check('Recrecimiento', 'Sana al objetivo en 100 a 120 p. y otros 60 durante 12 s.', '110+60/12s', 'heal')
check('Rejuvenecimiento', 'Sana al objetivo 120 p. de salud durante 12 s.', '120/12s', 'heal')
check('Destripar', 'Remate que inflige daño:\n1 punto de combo: 20 p. de daño durante 8 s\n3 puntos de combo: 60 p. de daño durante 12 s', '60/12s')
class = 'PRIEST'
check('Palabra de poder: escudo', 'Escuda al objetivo y absorbe 200 p. de daño durante 30 s.', '200', 'absorb')
class = 'ROGUE'
check('Golpe siniestro', 'Ataque instantáneo que inflige daño normal más 5.', '≈35')
check('Golpe siniestro', 'Ataque instantáneo que inflige daño normal más 1.000.', '≈1030')
check('Puñalada', 'Inflige un 150,5% de daño con arma y 10 p. de daño adicional.', '≈55')
check('Eviscerar', 'Remate que inflige daño por puntos de combo:\n1 punto: 20-30\n3 puntos: 60-70', '65')
-- A newly learned arbitrary rank changes amounts without adding any IDs.
for _, targetClass in ipairs({'ROGUE', 'DRUID', 'PRIEST', 'WARRIOR', 'MAGE', 'WARLOCK', 'HUNTER', 'SHAMAN'}) do
    class = targetClass
    local spellNames = {ROGUE='Gouge', DRUID='Wrath', PRIEST='Smite', WARRIOR='Revenge', MAGE='Frostbolt', WARLOCK='Shadow Bolt', HUNTER='Arcane Shot', SHAMAN='Lightning Bolt'}
    for rank = 1, 5 do check(spellNames[class], 'Deals ' .. rank * 10 .. ' damage.', tostring(rank * 10)) end
end
-- Protected data, missing descriptions and unknown formulas fail closed.
class = 'MAGE'
local secretSpell = add('Fireball', hidden)
empty(secretSpell)
check('Fireball', 'Deals 10 Fire damage and 20 Fire damage over 8 sec.', '10+20/8s')
empty(add('Fireball', 'Deals 10 Fire damage or 20 Fire damage if the target is frozen.'))
empty(add('Blizzard', 'Deals 30 Frost damage.')) -- no duration, not a per-cast total
local wrongBuild = add('Frostbolt', 'Deals 30 Frost damage.')
build = 30300; empty(wrongBuild); build = 16001
class = 'ROGUE'
local unsafeWeapon = add('Backstab', 'Deals 150% weapon damage plus 10 damage.')
weaponLow = hidden; empty(unsafeWeapon); weaponLow = 20
empty(add('Hemorrhage', 'Deals 110% weapon damage, or 160% weapon damage with a dagger.'))
-- Model lookup may use spellbook name before the spell-name API is ready.
local late = add('Sinister Strike', 'Deals normal damage plus 5.')
names[late] = hidden
eq(calc:GetClassModel(late), nil)
eq(calc:GetSpellFamily(late, 'Sinister Strike'), 'ROGUE/weapon')
expect(late, '≈35')
-- Modern combo fallback, never an escape from a protected Classic API.
GetComboPoints = nil
points = 3
expect(finisher, '35')
points = hidden; empty(finisher, 'empty'); points = 3
print(count .. ' multi-class checks passed (synthetic fixtures)')
