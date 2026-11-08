local _, ns = ...

local Calculator = {}
ns.Calculator = Calculator

local DAMAGE_WORDS = {
    "damage",
    "damages",
    "strike",
    "strikes",
    "hits",
    "deals",
    "daño",
    "daños",
    "golpea",
    "inflige",
}

local HEAL_WORDS = {
    "heal",
    "healing",
    "restores",
    "cura",
    "curación",
    "sana",
    "restaura",
    "curar",
    "sanación",
}

local IGNORE_WORDS = {
    "mana",
    "maná",
    "rage",
    "ira",
    "energy",
    "energía",
    "cost",
    "coste",
    "costs",
    "requiere",
    "requires",
    "range",
    "rango",
    "yard",
    "yards",
    "metros",
    "sec",
    "seg",
    "second",
    "segundo",
    "cooldown",
    "recarga",
    "duration",
    "duración",
    "level",
    "nivel",
    "rank",
    "rango",
}

local scannerTooltip

local function isSafe(value)
    if value == nil then
        return false
    end

    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if ok and secret then
            return false
        end
    end

    return true
end

local function safeString(value)
    if not isSafe(value) or type(value) ~= "string" then
        return nil
    end
    return value
end

local function parseNumber(value)
    if not value then
        return nil
    end
    local normalized = value:gsub(",", "")
    return tonumber(normalized)
end

local function hasDamageWord(description)
    local lower = string.lower(description)
    for _, word in ipairs(DAMAGE_WORDS) do
        if string.find(lower, word, 1, true) then
            return true
        end
    end
    for _, word in ipairs(HEAL_WORDS) do
        if string.find(lower, word, 1, true) then
            return true
        end
    end
    return false
end

local function nearestWordDistance(description, startAt, endAt, words)
    local lower = string.lower(description)
    local nearest

    for _, word in ipairs(words) do
        local searchAt = 1
        while true do
            local wordStart, wordEnd = string.find(lower, word, searchAt, true)
            if not wordStart then
                break
            end

            local distance
            if wordEnd < startAt then
                distance = startAt - wordEnd
            elseif wordStart > endAt then
                distance = wordStart - endAt
            else
                distance = 0
            end

            if not nearest or distance < nearest then
                nearest = distance
            end
            searchAt = wordEnd + 1
        end
    end

    return nearest
end

local function getValueKind(description, startAt, endAt)
    local damageDistance = nearestWordDistance(description, startAt, endAt, DAMAGE_WORDS)
    local healDistance = nearestWordDistance(description, startAt, endAt, HEAL_WORDS)
    if healDistance and (not damageDistance or healDistance < damageDistance) then
        return healDistance, "heal"
    end
    return damageDistance, "damage"
end

local function isPercentOrDuration(description, startAt, endAt)
    local after = string.sub(description, endAt + 1, endAt + 8)
    local before = string.sub(description, math.max(1, startAt - 2), startAt - 1)
    return string.find(after, "%%", 1, true)
        or string.find(string.lower(after), "sec", 1, true)
        or string.find(before, "%%", 1, true)
end

local function isIgnoredNumber(description, startAt, endAt)
    local token = string.sub(description, startAt, endAt)
    if string.sub(token, 1, 1) == "-" then
        return true
    end

    if string.sub(description, math.max(1, startAt - 1), startAt - 1) == "-" then
        return true
    end

    if isPercentOrDuration(description, startAt, endAt) then
        return true
    end

    local context = string.lower(string.sub(description, math.max(1, startAt - 28), endAt + 28))
    for _, word in ipairs(IGNORE_WORDS) do
        if string.find(context, word, 1, true) then
            return true
        end
    end

    return false
end

local function extractHealthPercentage(description)
    for startAt, token in string.gmatch(description, "()(%d+%.?%d*)%s*%%") do
        local endAt = startAt + string.len(token) - 1
        local distance, kind = getValueKind(description, startAt, endAt)
        local context = string.lower(string.sub(description, math.max(1, startAt - 40), endAt + 40))
        local describesHealth = string.find(context, "health", 1, true)
            or string.find(context, "salud", 1, true)
            or string.find(context, "vida", 1, true)

        if distance and distance <= 80 and kind == "heal" and describesHealth
            and type(UnitHealthMax) == "function" then
            local ok, maximumHealth = pcall(UnitHealthMax, "player")
            if ok and isSafe(maximumHealth) and type(maximumHealth) == "number" then
                local percentage = tonumber(token)
                if percentage then
                    return maximumHealth * percentage / 100, "heal"
                end
            end
        end
    end

    return nil
end

local function extractValue(description)
    if not description or not hasDamageWord(description) then
        return nil
    end

    local percentageValue, percentageKind = extractHealthPercentage(description)
    if percentageValue then
        return percentageValue, percentageKind
    end

    local bestValue
    local bestDistance
    local bestKind

    for rangeStart, first, second in string.gmatch(
        description,
        "()(%d[%d,]*)%s*[%-%–—]%s*(%d[%d,]*)"
    ) do
        local rangeEnd = rangeStart + string.len(first) + string.len(second)
        local distance, kind = getValueKind(description, rangeStart, rangeEnd)
        if distance and distance <= 80
            and not isIgnoredNumber(description, rangeStart, rangeStart + string.len(first) - 1) then
            local minimum = parseNumber(first)
            local maximum = parseNumber(second)
            if minimum and maximum and (not bestDistance or distance < bestDistance) then
                bestValue = (minimum + maximum) / 2
                bestDistance = distance
                bestKind = kind
            end
        end
    end

    for startAt, token in string.gmatch(description, "()(%d[%d,]*%.?%d*)") do
        local endAt = startAt + string.len(token) - 1
        local distance, kind = getValueKind(description, startAt, endAt)
        if distance and distance <= 80 and not isIgnoredNumber(description, startAt, endAt) then
            local number = parseNumber(token)
            if number and number >= 2 and (not bestDistance or distance < bestDistance) then
                bestValue = number
                bestDistance = distance
                bestKind = kind
            end
        end
    end

    return bestValue, bestKind
end

local function formatValue(value)
    if value >= 1000000 then
        return string.format("~%.1fM", value / 1000000)
    end
    if value >= 1000 then
        return string.format("~%.1fK", value / 1000)
    end
    return string.format("%d", math.floor(value + 0.5))
end

local function getTooltipDescription(spellID)
    if not C_TooltipInfo or not C_TooltipInfo.GetSpellByID then
        return nil
    end

    local ok, data = pcall(C_TooltipInfo.GetSpellByID, spellID)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then
        return nil
    end

    local parts = {}
    for _, line in ipairs(data.lines) do
        if type(line) == "table" then
            local left = safeString(line.leftText)
            local right = safeString(line.rightText)
            if left then
                table.insert(parts, left)
            end
            if right then
                table.insert(parts, right)
            end
        end
    end

    if #parts == 0 then
        return nil
    end
    return table.concat(parts, " ")
end

local function appendTooltipLines(data, parts)
    if type(data) ~= "table" or type(data.lines) ~= "table" then
        return
    end

    for _, line in ipairs(data.lines) do
        if type(line) == "table" then
            local left = safeString(line.leftText)
            local right = safeString(line.rightText)
            if left then
                table.insert(parts, left)
            end
            if right then
                table.insert(parts, right)
            end
        end
    end
end

local function getActionTooltipDescription(actionSlot)
    local parts = {}

    if C_TooltipInfo and C_TooltipInfo.GetAction then
        local ok, data = pcall(C_TooltipInfo.GetAction, actionSlot)
        if ok then
            appendTooltipLines(data, parts)
        end
    end

    if #parts > 0 then
        return table.concat(parts, " ")
    end

    if not scannerTooltip then
        scannerTooltip = CreateFrame(
            "GameTooltip",
            "DamageReaderSkillScannerTooltip",
            UIParent,
            "GameTooltipTemplate"
        )
        scannerTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end

    scannerTooltip:ClearLines()
    local ok = false
    if scannerTooltip.SetAction then
        ok = pcall(scannerTooltip.SetAction, scannerTooltip, actionSlot)
    end
    if not ok then
        return nil
    end

    scannerTooltip:Show()
    local lineCount = scannerTooltip.NumLines and scannerTooltip:NumLines() or 0
    for index = 1, lineCount do
        local left = safeString(_G["DamageReaderSkillScannerTooltipTextLeft" .. index]
            and _G["DamageReaderSkillScannerTooltipTextLeft" .. index]:GetText())
        local right = safeString(_G["DamageReaderSkillScannerTooltipTextRight" .. index]
            and _G["DamageReaderSkillScannerTooltipTextRight" .. index]:GetText())
        if left then
            table.insert(parts, left)
        end
        if right then
            table.insert(parts, right)
        end
    end
    scannerTooltip:Hide()

    if #parts == 0 then
        return nil
    end
    return table.concat(parts, " ")
end

local function getSpellTooltipDescription(spellID)
    if not scannerTooltip then
        scannerTooltip = CreateFrame(
            "GameTooltip",
            "DamageReaderSkillScannerTooltip",
            UIParent,
            "GameTooltipTemplate"
        )
        scannerTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end

    scannerTooltip:ClearLines()
    local ok = false
    if scannerTooltip.SetSpellByID then
        ok = pcall(scannerTooltip.SetSpellByID, scannerTooltip, spellID)
    elseif scannerTooltip.SetSpell then
        ok = pcall(scannerTooltip.SetSpell, scannerTooltip, spellID)
    end
    if not ok then
        return nil
    end

    scannerTooltip:Show()
    local parts = {}
    local lineCount = scannerTooltip.NumLines and scannerTooltip:NumLines() or 0
    for index = 1, lineCount do
        local left = safeString(_G["DamageReaderSkillScannerTooltipTextLeft" .. index]
            and _G["DamageReaderSkillScannerTooltipTextLeft" .. index]:GetText())
        local right = safeString(_G["DamageReaderSkillScannerTooltipTextRight" .. index]
            and _G["DamageReaderSkillScannerTooltipTextRight" .. index]:GetText())
        if left then
            table.insert(parts, left)
        end
        if right then
            table.insert(parts, right)
        end
    end
    scannerTooltip:Hide()

    if #parts == 0 then
        return nil
    end
    return table.concat(parts, " ")
end

function Calculator:GetSpellDescription(spellID, actionSlot)
    if not isSafe(spellID) or type(spellID) ~= "number" then
        return nil
    end

    local actionDescription = actionSlot and getActionTooltipDescription(actionSlot)
    if actionDescription and actionDescription ~= "" then
        return actionDescription
    end

    if C_Spell and C_Spell.GetSpellDescription then
        local ok, description = pcall(C_Spell.GetSpellDescription, spellID)
        description = ok and safeString(description) or nil
        if description and description ~= "" then
            return description
        end
    end

    if type(GetSpellDescription) == "function" then
        local ok, description = pcall(GetSpellDescription, spellID)
        description = ok and safeString(description) or nil
        if description and description ~= "" then
            return description
        end
    end

    local spellTooltip = getTooltipDescription(spellID)
    if spellTooltip and spellTooltip ~= "" then
        return spellTooltip
    end

    return getSpellTooltipDescription(spellID)
end

function Calculator:GetActionInfo(actionSlot)
    if not isSafe(actionSlot) or type(actionSlot) ~= "number" then
        return nil
    end

    if C_ActionBar and C_ActionBar.GetActionInfo then
        local ok, actionType, actionID, subType = pcall(C_ActionBar.GetActionInfo, actionSlot)
        if not ok or not isSafe(actionType) or not isSafe(actionID) then
            return nil
        end
        return actionType, actionID, subType
    end

    -- Forever puede exponer esta función como global aunque no tenga
    -- el namespace C_ActionBar disponible.
    if type(GetActionInfo) == "function" then
        local ok, actionType, actionID, subType = pcall(GetActionInfo, actionSlot)
        if not ok or not isSafe(actionType) or not isSafe(actionID) then
            return nil
        end
        return actionType, actionID, subType
    end

    return nil
end

function Calculator:EstimateSpell(spellID)
    local manual = ns.ManualData and ns.ManualData[spellID]
    if manual and manual.min and manual.max then
        local value = (manual.min + manual.max) / 2
        return { value = value, text = formatValue(value), source = "manual" }
    end

    local description = self:GetSpellDescription(spellID)
    local value = extractValue(description)
    if not value then
        return nil
    end

    return { value = value, text = formatValue(value), source = "spell-description" }
end

function Calculator:EstimateAction(actionSlot)
    local actionType, actionID = self:GetActionInfo(actionSlot)
    if actionType ~= "spell" or not isSafe(actionID) or type(actionID) ~= "number" then
        return nil
    end
    local description = self:GetSpellDescription(actionID, actionSlot)
    local value, kind = extractValue(description)
    if not value then
        return nil
    end

    return { value = value, text = formatValue(value), kind = kind, source = "action-tooltip" }
end
