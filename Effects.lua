local _, ns = ...
local calc = ns.Calculator

local number = "%d[%d%.,]*"
local separators = {"%s*%-%s*", "%s+a%s+", "%s+to%s+", "%s+y%s+", "%s+and%s+"}
local function contains(text, words)
    for _, word in ipairs(words) do if text:find(word, 1, true) then return true end end
end
local function timing(tail)
    local tick = tail:match("cada (%d+[%.,]?%d*) s") or tail:match("every (%d+[%.,]?%d*) sec")
    if not tick and (tail:find("cada segundo", 1, true) or tail:find("every second", 1, true)
        or tail:find("per second", 1, true) or tail:find("por segundo", 1, true)) then tick = "1" end
    local duration = tail:match("durante (%d+[%.,]?%d*) s") or tail:match("a lo largo de (%d+[%.,]?%d*) s")
        or tail:match("over (%d+[%.,]?%d*) sec")
    return tick, duration
end
calc.EffectTiming = timing

-- Read quantities attached to an actual effect. The classifier is scoped to
-- registered active spell families, not arbitrary talent/item descriptions.
function calc:ReadEffects(description, mode)
    local text, entries, cursor = self:Normalize(description), {}, 1
    while true do
        local first, last = text:find(number, cursor)
        if not first then break end
        for _, separator in ipairs(separators) do
            local _, ending = text:sub(last + 1):find("^" .. separator .. number)
            if ending then last = last + ending; break end
        end
        while last >= first and text:sub(last, last):match("[.,]") do last = last - 1 end
        local low, high = self:ReadQuantity(text:sub(first, last))
        local prefix = text:sub(1, first - 1)
        local clause = prefix:gsub("p%.", "p"):match("[^%.;\n]*$") or prefix
        local suffix = text:sub(last + 1):gsub("^%s+", "")
        local kind
        if suffix:match("^p%.%s*de daño") or suffix:match("^puntos de daño") or suffix:match("^de daño")
            or suffix:match("^daño") or suffix:match("^damage") or suffix:match("^%a+ damage")
            or suffix:match("^as %a+ damage") or suffix:match("^additional damage") then kind = "damage"
        elseif suffix:match("^healing") or suffix:match("^p%.%s*de sanación") then kind = "heal"
        elseif suffix:match("^p%.%s*de salud") or suffix:match("^puntos de salud")
            or suffix:match("^de salud") or suffix:match("^health") then
            if mode == "drain" and contains(clause, {"drain", "steal", "transfer", "drena", "roba", "transfiere"}) then kind = "damage"
            elseif contains(clause, {"heal", "restor", "gives", "sana", "cura", "restaura", "recupera", "otorga"}) then kind = "heal" end
        elseif suffix:match("^p%.%s*de maná") or suffix:match("^puntos de maná") or suffix:match("^de maná")
            or suffix:match("^mana") then
            if contains(clause, {"restor", "drain", "gain", "transfer", "restaura", "drena", "obtiene", "otorga", "transfiere", "convierte", "convert"}) then kind = "mana" end
        elseif suffix:match("^p%.%s*de energía") or suffix:match("^energy") then
            if contains(clause, {"gain", "restor", "grants", "otorga", "restaura", "obtiene"}) then kind = "energy" end
        elseif suffix:match("^p%.[%s%.,]") or suffix:match("^p%.$") or suffix:match("^[%.%s]*$")
            or suffix:match("^%.%s") or suffix:match("^,") or suffix:match("^and ") or suffix:match("^y ")
            or suffix:match("^over ") or suffix:match("^durante ") or suffix:match("^every ") then
            if contains(clause, {"heal", "sana", "cura"}) then kind = "heal"
            elseif mode == "mixed" and #entries > 0 and prefix:match(" y %s*$")
                and suffix:match("^p%. extra durante ")
                and not text:sub(entries[#entries].last + 1, first - 1):gsub("p%.", "p"):find("[%.;\n]") then
                kind = entries[#entries].kind
            elseif #entries > 0 and contains(clause, {"additional", "another", "adicional", "otros"}) then
                kind = entries[#entries].kind
            end
        end
        if kind == "damage" and (clause:match("heal[^,;]*$") or clause:match("sana[^,;]*$")) then kind = "heal" end
        if kind == "damage" and contains(clause, {"absor", "escudo que", "shield that"}) then kind = "absorb" end
        -- Do not count a received-damage modifier or self-cost as outgoing damage.
        local modifier = contains(clause, {"increases damage", "increased by", "reduce damage", "reduces damage", "damage taken",
            "aumenta el daño", "aumentando el daño", "aumenta en", "reduce el daño", "reduciendo el daño", "daño recibido"})
        local cost = clause:find("at the cost of", 1, true) or clause:find("a costa de", 1, true)
            or clause:find("al coste de", 1, true)
        if low and kind and not modifier and not cost and not prefix:match("%-%s*$") then
            entries[#entries + 1] = {min = low, max = high, kind = kind, first = first, last = last}
        end
        cursor = last + 1
    end
    for i, entry in ipairs(entries) do
        -- Stop at the next effect amount: its duration must not be attributed
        -- to this effect (e.g. initial Fireball damage + its separate DoT).
        local ending = entries[i + 1] and entries[i + 1].first - 1 or #text
        local tail = text:sub(entry.last + 1, ending)
        for _, marker in ipairs({"and slows", "and reduces", "and increases", "and immobilizes", "slowing ",
            "y reduce", "y aumenta", "y ralentiza", "e inmoviliza", "ralentizando", "reduciendo"}) do
            local position = tail:find(marker, 1, true)
            if position then tail = tail:sub(1, position - 1) end
        end
        -- A new sentence can describe an unrelated buff/debuff duration.
        tail = tail:gsub("p%.", "p")
        tail = tail:match("^[^%.;\n]*") or tail
        entry.tick, entry.duration = timing(tail)
        if entry.kind == "absorb" then entry.tick, entry.duration = nil, nil end
    end
    return entries
end

function calc:EffectResult(id, entries, evidence, mode)
    if #entries == 0 then return nil, "sin cantidades de efecto verificables" end
    local kinds, min, max, pieces, details = {}, 0, 0, {}, {}
    local periodic = false
    local hasTick = false
    local instantCount, periodicCount = 0, 0
    for _, effect in ipairs(entries) do
        kinds[effect.kind] = true
        local mean = (effect.min + effect.max) / 2
        local text = tostring(math.floor(mean + .5))
        local unit = "por objetivo"
        if effect.tick then
            text, unit = text .. "/t", "por tick, cada " .. effect.tick .. " s"
            periodic, hasTick, periodicCount = true, true, periodicCount + 1
        elseif effect.duration then
            text, unit = text .. "/" .. effect.duration .. "s", "total en " .. effect.duration .. " s"
            periodic, periodicCount = true, periodicCount + 1
        else instantCount = instantCount + 1 end
        pieces[#pieces + 1] = text
        details[#details + 1] = string.format("%s: %.2f–%.2f (%s)", effect.kind, effect.min, effect.max, unit)
        min, max = min + effect.min, max + effect.max
    end
    local count, kind = 0
    for candidate in pairs(kinds) do count, kind = count + 1, candidate end
    local paired = mode == "dual" or (mode == "drain" and kinds.damage and kinds.heal)
    if count > 1 and not paired then return nil, "efectos de distinto tipo: falta una regla específica" end
    if #entries > 1 and count == 1 and not (mode == "mixed" and #entries == 2 and instantCount == 1 and periodicCount == 1) then
        return nil, "varias cantidades del mismo tipo: no se suman variantes, costes ni objetivos"
    end
    if mode == "periodic" and not periodic then return nil, "falta duración o intervalo del efecto periódico" end
    if paired and not (kinds.damage and kinds.heal and #entries == 2) then
        return nil, "faltan daño y sanación separados"
    end
    if mode == "absorb" and (count ~= 1 or not kinds.absorb) then return nil, "sin cantidad explícita de absorción" end
    local metric = "Estimación por objetivo, antes de mitigación y crítico"
    if periodic then metric = "Efectos por objetivo: total/duración o cantidad/tick" end
    if mode == "reactive" then metric = "Cantidad por activación; no suma cargas ni procs futuros" end
    if mode == "drain" then metric = "Cantidad drenada por objetivo; sin sumar sanación y daño" end
    if paired then
        -- Stable order even when the client describes healing before damage.
        if entries[1].kind == "heal" then pieces[1], pieces[2] = pieces[2], pieces[1] end
        kind, metric = "dual", "Daño / sanación por objetivo, según uso"
        if mode == "drain" then metric = "Daño al objetivo / sanación propia; efectos separados" end
    end
    details[#details + 1] = "No se multiplican enemigos, cargas, saltos ni probabilidades de activación."
    local value = {spellID = id, text = table.concat(pieces, paired and " | " or "+"),
        kind = kind, source = "Forever: cantidades del cliente", metric = metric, evidence = evidence,
        details = details, effects = entries}
    -- A tick plus an initial hit do not share a time basis. Don't expose their
    -- sum as the full cast's damage, even though both components are displayed.
    if not (hasTick and #entries > 1) and count == 1 then
        value.min, value.max, value.value = min, max, (min + max) / 2
    end
    return value
end
