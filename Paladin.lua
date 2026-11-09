local _, ns = ...
local calc = ns.Calculator
ns.Models = ns.Models or {}
local function safe(value, kind)
    return calc:IsReadable(value) and type(value) == kind
end
local function supported()
    if type(GetBuildInfo) ~= "function" then return false end
    return select(4, GetBuildInfo()) == 16001
end
local function estimate(low, high, kind, metric, evidence, id)
    local mean = (low + high) / 2
    return {value = mean, min = low, max = high, text = tostring(math.floor(mean + .5)),
        kind = kind, metric = metric, evidence = evidence, spellID = id,
        source = "Forever: fórmula del tooltip", details = {}}
end
local families, names = {}, {}
-- Only IDs confirmed by the user's client report. Other ranks are discovered
-- through the spell API/book, never mapped to another rank's numeric values.
local confirmed = {[679] = "strike", [21084] = "righteousness", [21082] = "crusader", [20271] = "judgment"}
local seals = {righteousness = true, fury = true, crusader = true, command = true,
    light = true, wisdom = true, justice = true}
local sealIDs = {[21084] = true, [21082] = true}
for family, aliases in pairs(ns.PaladinFamilies or {}) do
    for _, name in ipairs(aliases) do names[calc:Normalize(name)] = family end
end
function calc:GetPaladinFamily(id, suppliedName)
    if not safe(id, "number") then return end
    if families[id] then return families[id] end
    local name = suppliedName or self:GetSpellName(id)
    local family = safe(name, "string") and names[self:Normalize(name)] or confirmed[id]
    if family then
        families[id] = family
        if seals[family] then sealIDs[id] = true end
    end
    return family
end

-- Extract effect amounts, never bare numbers (cost, duration, target count,
-- threat percentage, AP, etc.). Keep multiple effects distinct.
local function amounts(text)
    local values, cursor = {}, 1
    text = calc:Normalize(text)
    while true do
        local first, last = text:find("%d[%d%.,]*", cursor)
        if not first then break end
        for _, separator in ipairs({"%s*%-%s*", "%s+a%s+", "%s+to%s+", "%s+y%s+", "%s+and%s+"}) do
            local _, ending = text:sub(last + 1):find("^" .. separator .. "%d[%d%.,]*")
            if ending then last = last + ending; break end
        end
        local low, high = calc:ReadQuantity(text:sub(first, last))
        local suffix = text:sub(last + 1):gsub("^%s+", "")
        local prefix = text:sub(1, first - 1)
        local kind
        if suffix:match("^p%.%s*más de daño") or suffix:match("^p%.%s*de daño")
            or suffix:match("^puntos de daño") or suffix:match("^de daño") or suffix:match("^daño")
            or suffix:match("^holy damage") or suffix:match("^as holy damage") or suffix:match("^additional holy damage")
            or suffix:match("^damage") then kind = "damage"
        elseif suffix:match("^p%.%s*de salud") or suffix:match("^puntos de salud")
            or suffix:match("^de salud") or suffix:match("^health") then kind = "heal"
        elseif suffix:match("^p%.%s*de maná") or suffix:match("^puntos de maná")
            or suffix:match("^de maná") or suffix:match("^mana") then kind = "mana"
        elseif (prefix:match("sana[^%.\n]*$") or prefix:match("cura[^%.\n]*$") or prefix:match("heal[^%.\n]*$"))
            and (suffix:match("^p%.") or suffix:match("^[%.%s]*$")) then kind = "heal" end
        if low and kind and not prefix:match("%-%s*$") then
            values[#values + 1] = {low = low, high = high, kind = kind, suffix = suffix, prefix = prefix}
        end
        cursor = last + 1
    end
    return values
end
local function oneAmount(text, kind)
    local selected
    for _, value in ipairs(amounts(text)) do
        if value.kind == kind then
            if selected then return nil end
            selected = value
        end
    end
    return selected
end
local function weapon()
    if type(UnitDamage) ~= "function" then return end
    local ok, low, high = pcall(UnitDamage, "player")
    if ok and safe(low, "number") and safe(high, "number") and low >= 0 and high >= low then return low, high end
end
local function weaponPercent(text)
    return text:match("(%d+)%%%s*de daño con arma") or text:match("(%d+)%%%s*del daño del arma")
        or text:match("(%d+)%%%s*del daño con arma") or text:match("(%d+)%%%s*weapon damage")
        or text:match("(%d+)%%%s*of[^%.\n]-weapon[^%.\n]-damage")
end
local function strike(id, text)
    local pct = weaponPercent(text)
    local extra = oneAmount(text, "damage")
    if not pct or not extra then return end
    local low, high = weapon()
    if not low then return end
    local value = estimate(low * tonumber(pct) / 100 + extra.low, high * tonumber(pct) / 100 + extra.high,
        "damage", "golpe normal medio, antes de mitigación", text, id)
    value.details = {string.format("%s%% × arma %.2f–%.2f + Sagrado %.2f–%.2f", pct, low, high, extra.low, extra.high),
        "UnitDamage ya incluye el poder de ataque; no se suma dos veces.", "Sin crítico ni mitigación del objetivo."}
    return value
end
local function splitSeal(text)
    local position = text:find("desatar la energía", 1, true) or text:find("desatar este sello", 1, true)
        or text:find("unleashing", 1, true)
    if position then return text:sub(1, position - 1), text:sub(position) end
    return text, nil
end
local judgmentRanges = {}
local function sealEffect(id, family, text, judgment)
    local own, released = splitSeal(text)
    local part = own
    if judgment then part = released end
    if not part then return end
    local kind = family == "light" and "heal" or family == "wisdom" and "mana" or "damage"
    if family == "crusader" or family == "justice" then return end
    local amount = oneAmount(part, kind)
    local value
    if not judgment and family == "command" then
        local pct = weaponPercent(part)
        local low, high = weapon()
        if pct and low then
            value = estimate(low * tonumber(pct) / 100, high * tonumber(pct) / 100, "damage",
                "Orden: daño por activación, antes de mitigación", text, id)
            value.details = {"No es daño garantizado por golpe ni DPS; no se supone una probabilidad de activación."}
        end
    elseif amount then
        value = estimate(amount.low, amount.high, kind, judgment and "Sentencia: efecto del sello activo"
            or "Sello: cantidad por activación", text, id)
        if not judgment and family == "righteousness" then
            value.value = nil
            value.text = amount.low .. "–" .. amount.high
            value.metric = "Rectitud: daño adicional por ataque (rango del cliente)"
            value.details = {"El cliente indica dependencia de velocidad del arma; no se inventa un promedio."}
        elseif family == "fury" then
            value.metric = judgment and "Sentencia de Furia: daño medio + provocación" or "Furia: daño adicional por golpe"
            value.details = {"El escudo de absorción y la provocación no se suman al daño."}
        elseif kind ~= "damage" then
            value.metric = (judgment and "Sentencia: " or "Sello: ") .. (kind == "heal" and "sanación" or "maná") .. " por activación"
            value.details = {"Cantidad por activación, no total durante la duración ni daño directo."}
        end
        if judgment and family == "command" then
            value.details = {"Daño base de Sentencia; no se asume que el objetivo esté aturdido o incapacitado."}
        end
    end
    return value
end

function calc:GetActiveSeal()
    if not supported() then return nil, "build no soportada" end
    local direct = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if type(direct) == "function" then
        local found
        for id in pairs(sealIDs) do
            local ok, aura = pcall(direct, id)
            if ok and safe(aura, "table") and safe(aura.spellId, "number") and aura.spellId == id then
                if found and found ~= id then return nil, "varios sellos: estado ambiguo" end
                found = id
            end
        end
        if found then return found end
    end
    local fn = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if type(fn) ~= "function" then return nil, "API de auras no disponible" end
    local active, uncertain
    for index = 1, 255 do
        local ok, aura = pcall(fn, "player", index, "HELPFUL")
        if not ok then return nil, "lectura de auras no disponible" end
        if not calc:IsReadable(aura) then
            if type(issecretvalue) == "function" and issecretvalue(aura) then uncertain = true else break end
        elseif type(aura) ~= "table" then return nil, "formato de aura no disponible"
        elseif not safe(aura.spellId, "number") then uncertain = true
        else
            local family = self:GetPaladinFamily(aura.spellId, safe(aura.name, "string") and aura.name or nil)
            if seals[family] then
                if active and active ~= aura.spellId then return nil, "varios sellos: estado ambiguo" end
                active = aura.spellId
            end
        end
    end
    if active then return active end
    if uncertain then return nil, "hay auras protegidas; no se puede confirmar el sello" end
    return nil, "sin sello compatible activo", "empty"
end
local function judgment(id)
    local seal, reason, state = calc:GetActiveSeal()
    if not seal then return nil, reason, state end
    local family = calc:GetPaladinFamily(seal)
    if family == "crusader" or family == "justice" then
        local value = estimate(0, 0, "damage", "Sentencia: perjuicio sin daño directo", "Sello activo confirmado", id)
        value.sealID = seal
        value.details = {"El efecto de control o el aumento de daño recibido no es daño directo de Sentencia."}
        return value
    end
    for _, source in ipairs(calc:GetSources(seal)) do
        local value = sealEffect(seal, family, calc:Normalize(source.text), true)
        if value then
            judgmentRanges[seal] = value
            local current = {}
            for key, item in pairs(value) do current[key] = item end
            current.spellID, current.sealID = id, seal
            return current
        end
    end
    local cached = judgmentRanges[seal]
    if cached then
        local value = {}
        for key, item in pairs(cached) do value[key] = item end
        value.spellID, value.sealID, value.stale = id, seal, true
        value.details = {"Última cantidad legible de este rango exacto del sello; pendiente de actualizar."}
        return value
    end
    -- A confirmed different rank must never inherit the old seal's estimate.
    return nil, "sin cantidad verificable para el rango del sello activo", "empty"
end
local function healthEffect(id, family, text)
    local matched, pct
    if family == "lay" then
        matched = text:find("igual a la salud máxima del paladín", 1, true) or text:find("igual a la vida máxima del paladín", 1, true)
            or text:find("equal to the paladin's maximum health", 1, true) or text:find("equal to the paladin's max health", 1, true)
        pct = 100
    else
        pct = text:match("(%d+)%% de tu salud máxima") or text:match("(%d+)%% de tu salud total")
            or text:match("(%d+)%% of your maximum health") or text:match("(%d+)%% of your max health")
        matched = pct and (text:find("absor", 1, true))
    end
    if not matched or type(UnitHealthMax) ~= "function" then return end
    local ok, health = pcall(UnitHealthMax, "player")
    if not ok or not safe(health, "number") or health <= 0 then return end
    local amount = health * tonumber(pct) / 100
    return estimate(amount, amount, family == "lay" and "heal" or "absorb",
        family == "lay" and "Imposición de manos: sanación, antes de sobrecuración" or "Absorción del escudo", text, id)
end
local function generalEffect(id, family, text)
    if family == "strike" then return strike(id, text) end
    if family == "lay" or family == "absorb" then return healthEffect(id, family, text) end
    local damage, heal = oneAmount(text, "damage"), oneAmount(text, "heal")
    if family == "dual" then
        if not damage or not heal then return end
        local value = estimate(damage.low, damage.high, "dual", "Daño / sanación (según uso)", text, id)
        local healing = estimate(heal.low, heal.high, "heal", "", text, id)
        value.text, value.healing = value.text .. "/" .. healing.text, healing
        value.details = {"Izquierda: daño por objetivo enemigo. Derecha: sanación por aliado.",
            string.format("Sanación: %.2f–%.2f", heal.low, heal.high)}
        if text:find("choque sagrado", 1, true) or text:find("holy shock", 1, true) then
            value.details[#value.details + 1] = "El efecto de Vigilia requiere activar Choque Sagrado; no ocurre al colocarla."
        end
        return value
    end
    if family == "direct" then
        if text:find("%%") or text:find("cada ") or text:find("every ") or text:find(" over ") then return end
        if damage and heal then return end
    end
    local amount = damage or heal
    if not amount then return end
    local value = estimate(amount.low, amount.high, amount.kind, "Promedio por objetivo, antes de mitigación/crítico", text, id)
    if family == "periodic" then
        local seconds = text:match("durante (%d+[%.,]?%d*) s") or text:match("over (%d+[%.,]?%d*) sec")
        local tick = text:match("cada (%d+[%.,]?%d*) s") or text:match("every (%d+[%.,]?%d*) sec")
        if tick then
            value.text = value.text .. "/t"
            value.metric = "Daño por objetivo y por tick (cada " .. tick .. " s)"
        elseif seconds then
            value.text = value.text .. "/" .. seconds .. "s"
            value.metric = "Daño total por objetivo durante " .. seconds .. " s"
        else return end
        value.details = {"No se multiplica por el número de enemigos ni se confunde el total con daño por segundo.",
            "Se respeta el límite de objetivos descrito por el cliente; no se calcula un total del grupo."}
    elseif family == "reactive" then
        value.metric = "Daño por activación (bloqueo o golpe recibido)"
        value.details = {"No es daño directo al lanzar la habilidad ni la suma de todas sus cargas."}
    end
    return value
end
function calc:EstimatePaladin(id, slot)
    local family = self:GetPaladinFamily(id)
    if not family then return nil, nil, nil, false end
    if not supported() then return nil, "modelo requiere Forever 16001", nil, true end
    if family == "judgment" then
        local value, reason, state = judgment(id)
        return value, reason, state, true
    end
    if family == "utility" or family == "crusader" or family == "justice" then
        return nil, "habilidad de utilidad: sin daño ni sanación directa", "empty", true
    end
    for _, source in ipairs(self:GetSources(id, slot)) do
        local text = self:Normalize(source.text)
        local value
        if seals[family] then
            value = sealEffect(id, family, text, false)
            local released = sealEffect(id, family, text, true)
            if released then judgmentRanges[id] = released end
        else value = generalEffect(id, family, text) end
        if value then return value, nil, nil, true end
    end
    return nil, "familia " .. family .. ": descripción no legible o fórmula todavía no reconocida", nil, true
end
for id in pairs(confirmed) do
    ns.Models[id] = function(spellID, slot) return calc:EstimatePaladin(spellID, slot) end
end
