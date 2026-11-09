local _, ns = ...
local Calculator = {}
ns.Calculator = Calculator

function Calculator:IsReadable(value)
    if type(issecretvalue) == "function" and issecretvalue(value) then return false end
    return value ~= nil
end
local function readable(value, kind)
    return Calculator:IsReadable(value) and type(value) == kind
end
local function combat()
    return type(InCombatLockdown) == "function" and InCombatLockdown()
end
local function numeric(token)
    local locale = type(GetLocale) == "function" and GetLocale() or "enUS"
    if locale == "esES" or locale == "esMX" then
        token = token:gsub("%.", ""):gsub(",", ".")
    else token = token:gsub(",", "") end
    return tonumber(token)
end
local number = "(%d[%d%.,]*)"
local function quantity(text)
    text = text:gsub("%s+$", "")
    local a, b
    for _, separator in ipairs({"%s*%-%s*", "%s+a%s+", "%s+to%s+", "%s+y%s+", "%s+and%s+"}) do
        a, b = text:match("^" .. number .. separator .. number .. "$")
        if a then break end
    end
    if not a then a = text:match("^" .. number .. "$") end
    local low, high = a and numeric(a), b and numeric(b)
    if not low or low <= 0 then return end
    high = high or low
    if high < low then return end
    return low, high
end

function Calculator:ReadQuantity(text)
    return quantity(text)
end

function Calculator:Normalize(text)
    return string.lower(text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|T.-|t", ""):gsub("Á", "á"):gsub("É", "é"):gsub("Í", "í")
        :gsub("Ó", "ó"):gsub("Ú", "ú"):gsub("–", "-"):gsub("—", "-")
        :gsub(" ", " "))
end

function Calculator:GetSpellName(id)
    local fn = C_Spell and C_Spell.GetSpellName
    if type(fn) == "function" then
        local ok, name = pcall(fn, id)
        if ok and readable(name, "string") then return name end
    end
    fn = C_Spell and C_Spell.GetSpellInfo or GetSpellInfo
    if type(fn) == "function" then
        local ok, info = pcall(fn, id)
        if ok and readable(info, "string") then return info end
        if ok and readable(info, "table") and readable(info.name, "string") then return info.name end
    end
end
local function result(low, high, kind, evidence)
    local value = (low + high) / 2
    return {value = value, min = low, max = high, kind = kind,
        text = tostring(math.floor(value + 0.5)), evidence = evidence,
        source = "tooltip", metric = "promedio indicado por el cliente"}
end

-- Accept only explicit amounts attached to effects, retaining line boundaries.
-- Percentages, seals and weapon scaling need a verified spell-specific model.
function Calculator:Parse(description)
    if not readable(description, "string") then return nil, "texto no disponible" end
    local selected
    for raw in description:gmatch("[^\n]+") do
        local line = string.lower(raw:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            :gsub("|T.-|t", ""):gsub("–", "-"):gsub("—", "-"))
        local complex = line:find("%%") or line:find("cada ") or line:find("every ")
            or line:find("durante ") or line:find(" over ") or line:find("sello")
            or line:find("seal") or line:find("arma") or line:find("weapon")
        if not complex then
            local candidates = {}
            local cursor = 1
            while true do
                local first, last = line:find("%d[%d%.,]*", cursor)
                if not first then break end
                for _, separator in ipairs({"%s*%-%s*", "%s+a%s+", "%s+to%s+", "%s+y%s+", "%s+and%s+"}) do
                    local _, ending = line:sub(last + 1):find("^" .. separator .. "%d[%d%.,]*")
                    if ending then last = last + ending; break end
                end
                local amount = line:sub(first, last)
                local suffix = line:sub(last + 1):gsub("^%s+", "")
                local prefix = line:sub(1, first - 1)
                local low, high = quantity(amount)
                local kind
                if suffix:match("^p%.%s*de daño") or suffix:match("^puntos de daño")
                    or suffix:match("^de daño") or suffix:match("^daño")
                    or suffix:match("^%a*%s*damage") then kind = "damage"
                elseif suffix:match("^puntos de salud") or suffix:match("^p%.%s*de salud")
                    or suffix:match("^de salud") or suffix:match("^health") then
                    if line:find("sana") or line:find("cura") or line:find("restaura")
                        or line:find("heal") or line:find("restor") then kind = "heal" end
                end
                if not kind and (suffix:match("^[%.%s]*$") or suffix:match("^p%.[%s%.]*$")) then
                    if prefix:match("^sana ") or prefix:match("^cura ") or prefix:match("^heals ") then kind = "heal" end
                end
                if low and kind and not prefix:match("%-%s*$") then
                    candidates[#candidates + 1] = result(low, high, kind, raw)
                end
                cursor = last + 1
            end
            for _, candidate in ipairs(candidates) do
                if selected then return nil, "varios efectos: requiere fórmula específica" end
                selected = candidate
            end
        end
    end
    if selected then return selected end
    return nil, "sin cantidad directa verificable"
end

local scanner
local function scan(method, id)
    if combat() or type(CreateFrame) ~= "function" then return end
    if not scanner then
        scanner = CreateFrame("GameTooltip", "DamageReaderSkillScannerTooltip", UIParent, "GameTooltipTemplate")
    end
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    if type(scanner[method]) ~= "function" then scanner:Hide(); return end
    local ok = pcall(scanner[method], scanner, id)
    local lines = {}
    if ok then
        for i = 1, scanner:NumLines() do
            local font = _G["DamageReaderSkillScannerTooltipTextLeft" .. i]
            local value = font and font:GetText()
            if readable(value, "string") then lines[#lines + 1] = value end
        end
    end
    scanner:Hide()
    return table.concat(lines, "\n")
end
local function structured(fn, id)
    if type(fn) ~= "function" then return end
    local ok, data = pcall(fn, id)
    if not ok or not readable(data, "table") or not readable(data.lines, "table") then return end
    local lines = {}
    for _, line in ipairs(data.lines) do
        if not readable(line, "table") then return end
        -- Never build a partial description from a tooltip with hidden amounts.
        if type(issecretvalue) == "function" and issecretvalue(line.leftText) then return end
        if readable(line.leftText, "string") then lines[#lines + 1] = line.leftText end
    end
    return table.concat(lines, "\n")
end
function Calculator:GetActionInfo(slot)
    if not readable(slot, "number") then return end
    local fn = C_ActionBar and C_ActionBar.GetActionInfo or GetActionInfo
    if type(fn) ~= "function" then return end
    local ok, kind, id, subtype = pcall(fn, slot)
    if ok and readable(kind, "string") and readable(id, "number") then return kind, id, subtype end
    if ok and (type(issecretvalue) ~= "function" or not issecretvalue(kind)) and kind == nil then
        return "empty"
    end
end
function Calculator:GetSources(id, slot)
    local sources = {}
    local function add(text, name)
        if readable(text, "string") and text ~= "" then sources[#sources + 1] = {text = text, name = name} end
    end
    if slot then
        add(structured(C_TooltipInfo and C_TooltipInfo.GetAction, slot), "C_TooltipInfo.GetAction")
        add(scan("SetAction", slot), "GameTooltip:SetAction")
    end
    if readable(id, "number") then
        local fn = C_Spell and C_Spell.GetSpellDescription or GetSpellDescription
        if type(fn) == "function" then
            local ok, text = pcall(fn, id)
            if ok then add(text, "descripción del hechizo") end
        end
        add(structured(C_TooltipInfo and C_TooltipInfo.GetSpellByID, id), "C_TooltipInfo.GetSpellByID")
        add(scan("SetSpellByID", id), "GameTooltip:SetSpellByID")
    end
    return sources
end
function Calculator:EstimateAction(slot)
    local kind, id = self:GetActionInfo(slot)
    if kind ~= "spell" then return nil, "no es un hechizo directo" end
    return self:EstimateSpell(id, slot)
end

function Calculator:EstimateSpell(id, slot)
    if not readable(id, "number") then return nil, "hechizo no legible" end
    if ns.Models and ns.Models[id] then return ns.Models[id](id, slot) end
    if self.EstimatePaladin then
        local value, reason, state, handled = self:EstimatePaladin(id, slot)
        if handled then return value, reason, state end
    end
    if self.EstimateClass then
        local value, reason, state, handled = self:EstimateClass(id, slot)
        if handled then return value, reason, state end
    end
    for _, source in ipairs(self:GetSources(id, slot)) do
        local estimate = self:Parse(source.text)
        if estimate then
            estimate.source, estimate.spellID = source.name, id
            return estimate
        end
    end
    return nil, "falta modelo o descripción numérica de esta habilidad"
end
function Calculator:Report(slot)
    if combat() then ns:Print("Diagnóstico disponible fuera de combate."); return end
    local kind, id = self:GetActionInfo(slot)
    ns:Print("Casilla " .. slot .. ": " .. tostring(kind) .. " / " .. tostring(id))
    local calculated, reason = self:EstimateAction(slot)
    ns:Print(calculated and ("Modelo: " .. calculated.text .. " — " .. calculated.metric) or reason)
    for _, source in ipairs(self:GetSources(id, slot)) do
        ns:Print(source.name)
        for line in source.text:gmatch("[^\n]+") do ns:Print(line) end
        local value, reason = self:Parse(source.text)
        ns:Print(value and (value.kind .. " " .. value.min .. "-" .. value.max .. " => " .. value.text) or reason)
    end
end

function Calculator:BuildReport()
    if combat() then return "Sal del combate para generar el informe." end
    if self.RefreshSpellbook then self:RefreshSpellbook() end
    local lines = {"Damage Reader Skill " .. ns.version}
    local function add(text) lines[#lines + 1] = text end
    if type(GetBuildInfo) == "function" then
        local version, build, _, interface = GetBuildInfo()
        add("Cliente: " .. tostring(version) .. " / " .. tostring(build) .. " / " .. tostring(interface))
    end
    add("Idioma: " .. (type(GetLocale) == "function" and GetLocale() or "?"))
    if type(UnitClass) == "function" then
        local ok, _, class = pcall(UnitClass, "player")
        if ok and readable(class, "string") then add("Clase: " .. class) end
    end
    if self.GetActiveSeal then
        local seal, reason = self:GetActiveSeal()
        add("Sello activo: " .. tostring(seal) .. " / " .. tostring(reason or "legible"))
    end
    local function stat(name, fn, arg)
        if type(fn) ~= "function" then return end
        local values = {pcall(fn, arg)}
        if not values[1] then return end
        local parts = {}
        for i = 2, #values do
            if readable(values[i], "number") then parts[#parts + 1] = tostring(values[i]) end
        end
        add(name .. ": " .. table.concat(parts, ", "))
    end
    stat("Bonus sanación", GetSpellBonusHealing)
    stat("Bonus daño sagrado", GetSpellBonusDamage, 2)
    stat("Poder de ataque", UnitAttackPower, "player")
    stat("Daño arma", UnitDamage, "player")
    stat("Daño arma a distancia (velocidad, mínimo, máximo)", UnitRangedDamage, "player")
    stat("Poder de ataque a distancia", UnitRangedAttackPower, "player")
    local seen = {}
    for slot = 1, 180 do
        local kind, id = self:GetActionInfo(slot)
        if kind == "spell" and not seen[id] then
            seen[id] = true
            local family = self.GetSpellFamily and self:GetSpellFamily(id) or self.GetPaladinFamily and self:GetPaladinFamily(id)
            add("\nCasilla " .. slot .. " / hechizo " .. id .. " / familia " .. (family or "sin modelo específico"))
            local calculated, reason = self:EstimateAction(slot)
            add(calculated and ("Modelo: " .. calculated.text .. " — " .. calculated.metric) or reason)
            if calculated and calculated.evidence then add(calculated.evidence) end
            for _, source in ipairs(self:GetSources(id, slot)) do
                add(source.name .. "\n" .. source.text)
                local estimate, reason = self:Parse(source.text)
                add(estimate and ("Resultado: " .. estimate.text .. " " .. estimate.kind .. "; " .. estimate.evidence) or reason)
            end
        end
    end
    add("\nLibro de hechizos: habilidades y rangos fuera de las barras")
    for _, spell in ipairs(self.knownSpells or {}) do
        if not seen[spell.id] then
            add("\nHechizo " .. spell.id .. " / " .. (spell.name or "nombre no disponible")
                .. " / familia " .. (spell.family or "sin modelo específico"))
            local value, reason = self:EstimateSpell(spell.id)
            add(value and ("Modelo: " .. value.text .. " — " .. value.metric) or reason)
            for _, source in ipairs(self:GetSources(spell.id)) do add(source.name .. "\n" .. source.text) end
        end
    end
    return table.concat(lines, "\n")
end
