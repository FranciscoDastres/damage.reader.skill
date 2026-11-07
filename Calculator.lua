local _, ns = ...

local Calculator = {}
ns.Calculator = Calculator

local DAMAGE_WORDS = {
    "damage",
    "damages",
    "heal",
    "healing",
    "restores",
    "strike",
    "strikes",
    "hits",
    "deals",
}

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
    return tonumber((value:gsub(",", "")))
end

local function hasDamageWord(description)
    local lower = string.lower(description)
    for _, word in ipairs(DAMAGE_WORDS) do
        if string.find(lower, word, 1, true) then
            return true
        end
    end
    return false
end

local function isPercentOrDuration(description, startAt, endAt)
    local after = string.sub(description, endAt + 1, endAt + 8)
    local before = string.sub(description, math.max(1, startAt - 2), startAt - 1)
    return string.find(after, "%%", 1, true)
        or string.find(string.lower(after), "sec", 1, true)
        or string.find(before, "%%", 1, true)
end

local function extractValue(description)
    if not description or not hasDamageWord(description) then
        return nil
    end

    local rangeStart, rangeEnd, first, second = string.find(
        description,
        "(%d[%d,]*)%s*[%-%–—]%s*(%d[%d,]*)"
    )
    if first and second and not isPercentOrDuration(description, rangeStart, rangeEnd) then
        local minimum = parseNumber(first)
        local maximum = parseNumber(second)
        if minimum and maximum then
            return (minimum + maximum) / 2
        end
    end

    for startAt, token in string.gmatch(description, "()(%d[%d,]*%.?%d*)") do
        local endAt = startAt + string.len(token) - 1
        if not isPercentOrDuration(description, startAt, endAt) then
            local number = parseNumber(token)
            if number and number >= 2 then
                return number
            end
        end
    end

    return nil
end

local function formatValue(value)
    if value >= 1000000 then
        return string.format("~%.1fM", value / 1000000)
    end
    if value >= 1000 then
        return string.format("~%.1fK", value / 1000)
    end
    return string.format("~%d", math.floor(value + 0.5))
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

function Calculator:GetSpellDescription(spellID)
    if not isSafe(spellID) or type(spellID) ~= "number" then
        return nil
    end

    if C_Spell and C_Spell.GetSpellDescription then
        local ok, description = pcall(C_Spell.GetSpellDescription, spellID)
        description = ok and safeString(description) or nil
        if description and description ~= "" then
            return description
        end
    end

    return getTooltipDescription(spellID)
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
    return self:EstimateSpell(actionID)
end
