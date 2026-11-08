local _, ns = ...
local calc = ns.Calculator
ns.Models = ns.Models or {}

-- Source: user's esMX report, Forever 1.60.1 build 70862 / interface 16001.
-- Amounts are read afresh, never hardcoded to that character's level or gear.
local function safe(value, kind)
    return calc:IsReadable(value) and type(value) == kind
end
local function supported()
    if type(GetBuildInfo) ~= "function" then return false end
    return select(4, GetBuildInfo()) == 16001
end
local function estimate(low, high, metric, evidence, id)
    local mean = (low + high) / 2
    return {value = mean, min = low, max = high, text = tostring(math.floor(mean + .5)),
        kind = "damage", metric = metric, evidence = evidence, spellID = id,
        source = "Forever: fórmula del tooltip", details = {}}
end

local function holyStrike(id, slot)
    if not supported() then return nil, "modelo requiere Forever 16001" end
    for _, source in ipairs(calc:GetSources(id, slot)) do
        -- Restrict this formula to the exact construction supplied by the client.
        local pct, low, high = source.text:match("(%d+)%% de daño con arma y (%d+) a (%d+) p%. de daño Sagrado")
        if pct then
            if type(UnitDamage) ~= "function" then return nil, "daño de arma no disponible" end
            local ok, weaponLow, weaponHigh = pcall(UnitDamage, "player")
            if not ok or not safe(weaponLow, "number") or not safe(weaponHigh, "number") then
                return nil, "daño de arma protegido o no disponible"
            end
            if weaponLow < 0 or weaponHigh < weaponLow then return nil, "rango de arma inválido" end
            local fraction = tonumber(pct) / 100
            low, high = tonumber(low), tonumber(high)
            if high < low then return nil, "rango Sagrado inválido" end
            local value = estimate(weaponLow * fraction + low, weaponHigh * fraction + high,
                "golpe normal medio, antes de mitigación", source.text, id)
            value.details = {
                string.format("%s%% × arma %.2f–%.2f + Sagrado %d–%d", pct, weaponLow, weaponHigh, low, high),
                "El daño de arma ya incluye tu poder de ataque; no se suma dos veces.",
                "Sin crítico, mitigación del objetivo ni activaciones extra del sello.",
            }
            return value
        end
    end
    return nil, "fórmula de Golpe Sagrado no reconocida"
end

local judgmentRanges = {}
local function rectitude(id, slot, judgment)
    if not supported() then return nil, "modelo requiere Forever 16001" end
    for _, source in ipairs(calc:GetSources(id, slot)) do
        local jlow, jhigh = source.text:match("Desatar la energía de este sello inflige (%d+) a (%d+) p%. de daño Sagrado")
        if jlow and tonumber(jhigh) >= tonumber(jlow) then
            judgmentRanges[id] = {low = tonumber(jlow), high = tonumber(jhigh)}
        end
        local low, high
        if judgment then
            low, high = source.text:match("Desatar la energía de este sello inflige (%d+) a (%d+) p%. de daño Sagrado")
        else
            low, high = source.text:match("ataque cuerpo a cuerpo entre (%d+) y (%d+) p%. más de daño Sagrado")
        end
        if low then
            low, high = tonumber(low), tonumber(high)
            if high < low then return nil, "rango de Rectitud inválido" end
            local value = estimate(low, high, judgment and "Sentencia de Rectitud: promedio del tooltip"
                or "daño adicional del sello por ataque: rango del tooltip", source.text, id)
            if not judgment then
                -- The client says weapon speed affects the proc. Its range is not
                -- evidence of a uniform distribution: do not invent an average.
                value.value = nil
                value.text = low .. "–" .. high
                value.details = {"Daño adicional del sello, no el daño de Sentencia.",
                    "El cliente indica dependencia de velocidad de arma; se muestra el rango, sin inventar un promedio."}
            else
                value.details = {"Se usa únicamente el sello activo legible.",
                    "Antes de resistencias, crítico y modificadores del objetivo."}
            end
            return value
        end
    end
    if judgment and judgmentRanges[id] then
        local previous = judgmentRanges[id]
        local value = estimate(previous.low, previous.high, "Sentencia: último rango legible del sello actual",
            "El sello activo se confirma ahora; la cantidad procede de una lectura anterior.", id)
        value.stale = true
        value.details = {"Cantidad pendiente de actualizar: no incluye cambios posteriores en el tooltip del sello."}
        return value
    end
    return nil, "cantidad de Rectitud no reconocida"
end

function calc:GetActiveSeal()
    if not supported() then return nil, "build no soportada" end
    -- Query only supported seals first. Unrelated protected buffs must not veto
    -- a seal that the client explicitly exposes with a readable spell ID.
    local direct = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if type(direct) == "function" then
        local found
        for _, id in ipairs({21084, 21082}) do
            local ok, aura = pcall(direct, id)
            if ok and safe(aura, "table") and safe(aura.spellId, "number") and aura.spellId == id then
                if found then return nil, "varios sellos: estado ambiguo" end
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
            if type(issecretvalue) == "function" and issecretvalue(aura) then
                uncertain = true
            else
                break
            end
        elseif type(aura) ~= "table" then
            return nil, "formato de aura no disponible"
        elseif not safe(aura.spellId, "number") then
            uncertain = true
        elseif aura.spellId == 21084 or aura.spellId == 21082 then
            if active and active ~= aura.spellId then return nil, "varios sellos: estado ambiguo" end
            active = aura.spellId
        end
    end
    if active then return active end
    if uncertain then return nil, "hay auras protegidas; no se puede confirmar el sello" end
    return nil, "sin sello compatible activo", "empty"
end

local function judgment(id)
    local seal, reason, state = calc:GetActiveSeal()
    if not seal then return nil, reason, state end
    if seal == 21082 then
        local value = estimate(0, 0, "Sentencia del Cruzado: aplica un perjuicio sin daño directo",
            "El tooltip del Cruzado describe aumento de daño Sagrado recibido; no un golpe de 23.", id)
        value.details = {"Los 23 p. son un modificador del perjuicio, no daño de este lanzamiento."}
        return value
    end
    local value, failure = rectitude(seal, nil, true)
    if value then value.spellID, value.sealID = id, seal end
    return value, failure
end

ns.Models[679] = holyStrike
ns.Models[21084] = function(id, slot) return rectitude(id, slot, false) end
ns.Models[20271] = judgment
ns.Models[21082] = function() return nil, "Sello del Cruzado modifica estadísticas; no inflige daño directo al lanzarlo" end
