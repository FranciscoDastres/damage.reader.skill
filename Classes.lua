local _, ns = ...
local calc = ns.Calculator
local names, models = {}, {}
local function safe(value, kind)
    return calc:IsReadable(value) and type(value) == kind
end
local function call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then return a, b, c, d end
end
for class, groups in pairs(ns.ClassFamilies or {}) do
    names[class] = {}
    for mode, aliases in pairs(groups) do
        for name in aliases:gmatch("[^|]+") do
            local key = calc:Normalize(name)
            assert(not names[class][key] or names[class][key].mode == mode, "Duplicate class spell: " .. name)
            names[class][key] = {class = class, mode = mode}
        end
    end
end
function calc:GetClassModel(id, suppliedName)
    if not safe(id, "number") then return end
    if models[id] then return models[id] end
    local name = suppliedName or self:GetSpellName(id)
    if not safe(name, "string") then return end
    local key, selected = self:Normalize(name)
    local _, class = call(UnitClass, "player")
    if safe(class, "string") then
        selected = names[class] and names[class][key]
    else
        -- No class API in some test/legacy clients: only unambiguous names.
        for _, aliases in pairs(names) do
            if aliases[key] then
                if selected then return end
                selected = aliases[key]
            end
        end
    end
    if selected then models[id] = selected end
    return selected
end
function calc:GetSpellFamily(id, suppliedName)
    local paladin = self.GetPaladinFamily and self:GetPaladinFamily(id, suppliedName)
    if paladin then return paladin end
    local model = self:GetClassModel(id, suppliedName)
    return model and (model.class .. "/" .. model.mode)
end
local function simple(id, low, high, evidence, metric)
    return {spellID = id, value = (low + high) / 2, min = low, max = high,
        text = tostring(math.floor((low + high) / 2 + .5)), kind = "damage", evidence = evidence,
        metric = metric, source = "Forever: fórmula del cliente", details = {}}
end
local function comboPoints()
    -- The target-aware Classic API takes precedence. If it is protected, do
    -- not fall back to a different source to reconstruct that hidden value.
    local value
    if type(GetComboPoints) == "function" then value = call(GetComboPoints, "player", "target")
    else
        local power = Enum and Enum.PowerType and Enum.PowerType.ComboPoints or 4
        value = call(UnitPower, "player", power)
    end
    if safe(value, "number") and value >= 0 and value <= 10 and value == math.floor(value) then return value end
end
local function combo(id, text)
    local points = comboPoints()
    if not points or points == 0 then return nil, "sin puntos de combo legibles", "empty" end
    local selected, rows = nil, false
    for line in text:gmatch("[^\n]+") do
        local count, rest = line:match("^%s*(%d+)%s+combo points?%s*:%s*(.+)")
        if not count then count, rest = line:match("^%s*(%d+)%s+puntos? de combo%s*:%s*(.+)") end
        if not count then count, rest = line:match("^%s*(%d+)%s+puntos?%s*:%s*(.+)") end
        if count then
            rows = true
            if tonumber(count) == points then
                if selected then return nil, "fila de combo ambigua", "empty" end
                selected = rest
            end
        end
    end
    if not selected then
        return nil, rows and "no hay fila para los puntos de combo actuales" or "falta tabla de daño por puntos de combo", "empty"
    end
    local effects = calc:ReadEffects(selected, "direct")
    if #effects == 0 then
        -- Some clients print bare amounts under a damage-labelled combo table.
        if not (text:find("damage", 1, true) or text:find("daño", 1, true)) then return nil, "tabla sin unidad", "empty" end
        local amount = selected:match("^(%d[%d%.,]*%s*%-%s*%d[%d%.,]*)")
            or selected:match("^(%d[%d%.,]*%s+a%s+%d[%d%.,]*)")
            or selected:match("^(%d[%d%.,]*%s+to%s+%d[%d%.,]*)") or selected:match("^(%d[%d%.,]*)")
        if amount and not selected:find("%%") then
            local low, high = calc:ReadQuantity(amount)
            if low then
                local tick, duration = calc.EffectTiming(selected)
                effects = {{min = low, max = high, kind = "damage", tick = tick, duration = duration}}
            end
        end
    end
    local value, reason = calc:EffectResult(id, effects, text, "direct")
    if not value then return nil, reason, "empty" end
    value.comboPoints, value.contextSensitive = points, true
    value.metric = points .. " puntos de combo: " .. value.metric
    if text:find("energy", 1, true) or text:find("energía", 1, true) then
        -- Do not assume extra-energy conversion from another expansion.
        if text:find("extra", 1, true) or text:find("adicional", 1, true) or text:find("convert", 1, true) then
            value.text = "≥" .. value.text
            value.metric = value.metric .. "; base sin energía adicional"
        end
    end
    return value
end
local function weapon(id, text, mode)
    local effects = calc:ReadEffects(text, "direct")
    local flatBonus = text:match("increases melee damage by (%d[%d%.,]*)") or text:match("increases ranged damage by (%d[%d%.,]*)")
        or text:match("aumenta el daño cuerpo a cuerpo en (%d[%d%.,]*)") or text:match("aumenta el daño a distancia en (%d[%d%.,]*)")
    local fraction, pctCount = nil, 0
    for _, pattern in ipairs({"(%d[%d%.,]*)%%%s*weapon damage", "(%d[%d%.,]*)%%%s*of weapon damage",
        "(%d[%d%.,]*)%%%s*de daño con arma", "(%d[%d%.,]*)%%%s*del daño del arma", "(%d[%d%.,]*)%%%s*del daño con arma"}) do
        for token in text:gmatch(pattern) do
            fraction, pctCount = calc:ReadQuantity(token), pctCount + 1
        end
    end
    local hasWeapon = text:find("weapon damage", 1, true) or text:find("daño del arma", 1, true)
        or text:find("daño con arma", 1, true) or text:find("normal damage", 1, true)
        or text:find("daño normal", 1, true) or text:find("ranged damage", 1, true) or flatBonus
    if not hasWeapon then return calc:EffectResult(id, effects, text, "direct") end
    -- Two different weapon percentages may mean dagger/non-dagger variants.
    if pctCount > 1 then return nil, "variantes de arma: no se elige un coeficiente sin evidencia" end
    if pctCount == 1 and not fraction then return nil, "porcentaje de arma inválido" end
    fraction = fraction and fraction / 100 or 1
    local low, high, offLow, offHigh
    if mode == "ranged" then
        local speed
        speed, low, high = call(UnitRangedDamage, "player")
    else low, high, offLow, offHigh = call(UnitDamage, "player") end
    if not safe(low, "number") or not safe(high, "number") or low <= 0 or high < low then return nil, "daño de arma no legible" end
    if mode == "both" then
        if not (text:find("both weapons", 1, true) or text:find("both hands", 1, true)
            or text:find("ambas armas", 1, true) or text:find("ambas manos", 1, true)) then
            return nil, "falta fórmula explícita de ambas armas"
        end
        if not safe(offLow, "number") or not safe(offHigh, "number") or offLow <= 0 or offHigh < offLow then
            return nil, "daño de mano secundaria no legible"
        end
        low, high = low + offLow, high + offHigh
    end
    local bonusLow, bonusHigh = 0, 0
    if #effects == 1 and effects[1].kind == "damage" and not effects[1].duration and not effects[1].tick then
        bonusLow, bonusHigh = effects[1].min, effects[1].max
    elseif #effects > 0 then return nil, "varios efectos del ataque con arma" end
    if #effects == 0 then
        -- Heroic/Sinister Strike descriptions often say 'normal damage plus X'.
        local extra = flatBonus or text:match("normal damage plus (%d[%d%.,]*)") or text:match("weapon damage plus (%d[%d%.,]*)")
            or text:match("daño normal más (%d[%d%.,]*)") or text:match("daño del arma más (%d[%d%.,]*)")
        if extra then
            bonusLow, bonusHigh = calc:ReadQuantity(extra)
            if not bonusLow then return nil, "bonificación de arma inválida" end
        end
    end
    if mode == "both" and (bonusLow > 0 or bonusHigh > 0) then return nil, "bonificación por mano no determinada" end
    local value = simple(id, low * fraction + bonusLow, high * fraction + bonusHigh, text, "Aproximación con el daño actual del arma")
    value.text, value.contextSensitive = "≈" .. value.text, true
    value.details = {"UnitDamage/UnitRangedDamage ya incluye poder de ataque y los modificadores publicados.",
        "La normalización interna de ataques especiales y los modificadores condicionales no están modelados.",
        "Antes de armadura, resistencias, crítico, venenos y ataques extra."}
    return value
end
local function attackPower(id, text)
    local pct = text:match("(%d[%d%.,]*)%% of your attack power") or text:match("(%d[%d%.,]*)%% del poder de ataque")
        or text:match("(%d[%d%.,]*)%% de tu poder de ataque")
    if not pct then return calc:EffectResult(id, calc:ReadEffects(text, "direct"), text, "direct") end
    pct = calc:ReadQuantity(pct)
    if not pct then return nil, "porcentaje de AP inválido" end
    local base, plus, minus = call(UnitAttackPower, "player")
    if not safe(base, "number") or not safe(plus, "number") or not safe(minus, "number") then return nil, "AP no legible" end
    local amount = (base + plus + minus) * pct / 100
    if amount < 0 then return end
    local value = simple(id, amount, amount, text, "Porcentaje explícito del poder de ataque actual")
    value.details = {"No incluye sanación posterior, mitigación, críticos ni activaciones adicionales."}
    return value
end
local function execute(id, text)
    local effects = calc:ReadEffects(text, "direct")
    local rate = text:match("plus (%d+[%.,]?%d*) for each extra point of rage")
        or text:match("(%d+[%.,]?%d*) p%. de daño por cada punto extra de ira")
        or text:match("(%d+[%.,]?%d*) por cada punto de ira adicional")
    local base = effects[1]
    if not rate or not base or base.kind ~= "damage" then return nil, "falta fórmula explícita de Ejecutar", "empty" end
    local powerType = Enum and Enum.PowerType and Enum.PowerType.Rage or 1
    local rage = call(UnitPower, "player", powerType)
    local costs = call(C_Spell and C_Spell.GetSpellPowerCost or GetSpellPowerCost, id)
    if not safe(rage, "number") or not safe(costs, "table") then return nil, "ira o costes no legibles", "empty" end
    local minimum, maximum
    for _, cost in ipairs(costs) do
        if safe(cost, "table") and safe(cost.type, "number") and cost.type == powerType then
            if not safe(cost.minCost, "number") or not safe(cost.cost, "number") then return nil, "coste de ira protegido", "empty" end
            if minimum then return nil, "varios costes de ira", "empty" end
            minimum, maximum = cost.minCost, cost.cost
        end
    end
    if not minimum or minimum < 0 or maximum < minimum or rage < minimum then return nil, "sin ira suficiente o coste válido", "empty" end
    local amount = math.max(0, math.min(rage, maximum) - minimum) * tonumber((rate:gsub(",", ".")))
    local value = simple(id, base.min + amount, base.max + amount, text, "Ejecutar: base + ira adicional legible")
    value.contextSensitive = true
    value.details = {"La API debe publicar minCost y cost (coste total con consumo opcional).",
        "No afirma que el objetivo esté en el umbral de vida requerido."}
    return value
end
function calc:EstimateClass(id, slot)
    local model = self:GetClassModel(id)
    if not model then return nil, nil, nil, false end
    if type(GetBuildInfo) ~= "function" or select(4, GetBuildInfo()) ~= 16001 then
        return nil, "modelos de clase requieren Forever 16001", nil, true
    end
    if model.mode == "utility" then return nil, "utilidad: sin daño o sanación directa", "empty", true end
    if model.mode == "conditional" then
        return nil, "efecto condicionado: requiere una fórmula específica del cliente", "empty", true
    end
    local failure, state
    for _, source in ipairs(self:GetSources(id, slot)) do
        local text = self:Normalize(source.text)
        local value, reason, unavailable
        if model.mode == "combo" then value, reason, unavailable = combo(id, text)
        elseif model.mode == "weapon" or model.mode == "ranged" or model.mode == "both" then
            value, reason = weapon(id, text, model.mode)
        elseif model.mode == "attackpower" then value, reason = attackPower(id, text)
        elseif model.mode == "execute" then value, reason, unavailable = execute(id, text)
        else
            local effects = self:ReadEffects(text, model.mode)
            if model.mode == "resource" then
                local filtered = {}
                for _, effect in ipairs(effects) do
                    if effect.kind == "mana" or effect.kind == "energy" or effect.kind == "heal" then filtered[#filtered + 1] = effect end
                end
                effects = filtered
            end
            value, reason = self:EffectResult(id, effects, text, model.mode)
        end
        if value then
            value.class, value.family = model.class, model.mode
            value.details[#value.details + 1] = "Talentos/procs se reflejan solo cuando modifican las entradas legibles del modelo."
            value.details[#value.details + 1] = "No se asumen condiciones del enemigo: congelación, venenos, inmolación, armadura o umbrales de vida."
            return value, nil, nil, true
        end
        failure, state = reason or failure, unavailable or state
    end
    if model.mode == "combo" or model.mode == "execute" then state = "empty" end
    return nil, failure or (model.class .. "/" .. model.mode .. ": falta descripción o fórmula verificable"), state, true
end
