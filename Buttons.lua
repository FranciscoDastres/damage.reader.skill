local _, ns = ...

local ButtonManager = {
    buttons = {},
    inCombat = false,
}
ns.Buttons = ButtonManager

local BUTTON_PREFIXES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

local function isSafe(value)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if ok and secret then
            return false
        end
    end
    return value ~= nil
end

local function addButton(collection, button)
    if button and button.CreateFontString and not collection[button] then
        collection[button] = true
    end
end

function ButtonManager:Discover()
    local discovered = {}

    for _, prefix in ipairs(BUTTON_PREFIXES) do
        for index = 1, 12 do
            addButton(discovered, _G[prefix .. index])
        end
    end

    self.buttons = {}
    for button in pairs(discovered) do
        table.insert(self.buttons, button)
    end
end

local function getActionSlot(button)
    local function validSlot(slot)
        return isSafe(slot) and type(slot) == "number" and slot > 0
    end

    if validSlot(button.action) then return button.action end
    if validSlot(button.actionID) then return button.actionID end
    if type(ActionButton_GetPagedID) == "function" then
        local ok, slot = pcall(ActionButton_GetPagedID, button)
        if ok and validSlot(slot) then
            return slot
        end
    end

    if button.GetAttribute then
        local ok, slot = pcall(button.GetAttribute, button, "action")
        if ok and validSlot(slot) then
            return slot
        end
    end

    -- A protected binding cannot be reconstructed from its name in combat.
    if ButtonManager.inCombat then return nil end

    local buttonName = button.GetName and button:GetName() or ""
    local index = tonumber(string.match(buttonName, "(%d+)$"))
    if index then
        if string.match(buttonName, "^ActionButton") then
            if type(GetActionBarPage) == "function" then
                local page = GetActionBarPage()
                if validSlot(page) then return (page - 1) * 12 + index end
            end
            return nil
        elseif string.match(buttonName, "^MultiBarBottomLeftButton") then
            return 60 + index
        elseif string.match(buttonName, "^MultiBarBottomRightButton") then
            return 48 + index
        elseif string.match(buttonName, "^MultiBarRightButton") then
            return 24 + index
        elseif string.match(buttonName, "^MultiBarLeftButton") then
            return 36 + index
        elseif string.match(buttonName, "^MultiBar5Button") then
            return 72 + index
        elseif string.match(buttonName, "^MultiBar6Button") then
            return 84 + index
        elseif string.match(buttonName, "^MultiBar7Button") then
            return 96 + index
        end
    end

    return nil
end

function ButtonManager:DebugScan()
    local printed = 0
    for _, button in ipairs(self.buttons) do
        local slot = getActionSlot(button)
        if slot then
            local actionType, actionID = ns.Calculator:GetActionInfo(slot)
            if actionType then
                local estimate = ns.Calculator:EstimateAction(slot)
                local buttonName = button.GetName and button:GetName() or "button"
                local value = estimate and estimate.text or "sin número"
                ns:Print(buttonName .. " slot=" .. tostring(slot)
                    .. " tipo=" .. tostring(actionType)
                    .. " id=" .. tostring(actionID)
                    .. " => " .. value)
                printed = printed + 1
                if printed >= 20 then
                    break
                end
            end
        end
    end

    if printed == 0 then
        ns:Print("scan: no se pudo leer ninguna acción colocada en las barras.")
    else
        ns:Print("scan: se muestran hasta 20 acciones detectadas.")
    end
end

function ButtonManager:CreateOverlay(button)
    if button.DamageReaderSkillText then
        return button.DamageReaderSkillText
    end
    -- Create and hook protected action-button children only out of combat.
    if self.inCombat then return nil end

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", ns.db.fontSize, "OUTLINE")
    text:ClearAllPoints()
    text:SetPoint("BOTTOM", button, "BOTTOM", 0, 1)
    text:SetDrawLayer("OVERLAY", 7)
    text:SetJustifyH("RIGHT")
    text:SetShadowOffset(1, -1)
    text:SetTextColor(unpack(ns.db.color))
    text:Hide()

    button.DamageReaderSkillText = text

    if not button.DamageReaderSkillHooked then
        button:HookScript("OnEnter", function(currentButton)
            local value = currentButton.DamageReaderSkillResult
            if not value or ButtonManager.inCombat or not GameTooltip then return end
            GameTooltip:AddLine("Damage Reader Skill", 1, .82, .05)
            if currentButton.DamageReaderSkillStale then
                GameTooltip:AddLine("* Última lectura disponible; pendiente de actualizar.", 1, .75, .25, true)
            end
            if value.text:match("^≈") then
                GameTooltip:AddLine("e = estimación aproximada con el daño actual del arma.", 1, 1, 1, true)
            elseif value.text:match("^≥") then
                GameTooltip:AddLine("+ = cantidad base; no incluye el efecto adicional indicado.", 1, 1, 1, true)
            end
            GameTooltip:AddLine(value.metric or "Promedio del tooltip del cliente", 1, 1, 1, true)
            if value.min and value.max then
                GameTooltip:AddLine(string.format("Rango: %.2f–%.2f", value.min, value.max), 1, 1, 1)
            end
            for _, detail in ipairs(value.details or {}) do
                GameTooltip:AddLine(detail, .8, .8, .8, true)
            end
            GameTooltip:Show()
        end)
        button:HookScript("OnShow", function(currentButton)
            ButtonManager:UpdateButton(currentButton)
        end)
        button:HookScript("OnHide", function(currentButton)
            if currentButton.DamageReaderSkillText then
                currentButton.DamageReaderSkillText:Hide()
            end
        end)
        button.DamageReaderSkillHooked = true
    end

    return text
end

function ButtonManager:HideButton(button)
    button.DamageReaderSkillResult = nil
    button.DamageReaderSkillSlot = nil
    button.DamageReaderSkillSpellID = nil
    button.DamageReaderSkillStale = nil
    if button.DamageReaderSkillText then
        button.DamageReaderSkillText:Hide()
    end
end

-- Keep status marks after the number: ~ and ≈ at 11 px looked like a minus
-- sign in the user's combat screenshot. Do not turn a real negative into
-- a positive number; invalid model output must be hidden instead.
function ButtonManager:GetDisplayText(value, stale)
    if not value or not isSafe(value.text) or type(value.text) ~= "string" then return end
    local function validNumbers(part)
        for _, key in ipairs({"value", "min", "max"}) do
            local number = part[key]
            if type(number) ~= "nil" then
                if not isSafe(number) or type(number) ~= "number"
                    or number ~= number or number < 0 or number == math.huge then return false end
            end
        end
        if part.min and part.max and part.max < part.min then return false end
        return true
    end
    if not validNumbers(value) then return end
    for _, effect in ipairs(value.effects or {}) do
        if not validNumbers(effect) then return end
    end
    if value.healing and not validNumbers(value.healing) then return end
    local text = value.text
    if text:match("^≈") then text = text:gsub("^≈", "") .. "e"
    elseif text:match("^≥") then text = text:gsub("^≥", "") .. "+" end
    if not text:find("%d") or text:match("^%s*%-") or text:match("^%s*−") then return end
    return text .. ((stale or value.stale) and "*" or "")
end

function ButtonManager:KeepLast(button)
    local value, text = button.DamageReaderSkillResult, button.DamageReaderSkillText
    if value and text then
        local displayed = self:GetDisplayText(value, true)
        if not displayed then self:HideButton(button); return end
        button.DamageReaderSkillStale = true
        text:SetText(displayed)
        text:Show()
    end
end

function ButtonManager:InvalidateActions(slot)
    -- Paging, replacement and removal invalidate identity even if IDs are secret.
    for _, button in ipairs(self.buttons) do
        local binding = button.DamageReaderSkillBinding
        if not slot or not binding or binding.slot == slot then
            button.DamageReaderSkillBinding = nil
            self:HideButton(button)
        end
    end
end

function ButtonManager:InvalidateContext()
    for _, button in ipairs(self.buttons) do
        local value = button.DamageReaderSkillResult
        if value and value.contextSensitive then self:HideButton(button) end
    end
end

function ButtonManager:UpdateButton(button)
    if not ns.db or not ns.db.enabled then
        self:HideButton(button)
        return
    end
    local text = self:CreateOverlay(button)
    if not text then return end

    local slotOK, actionSlot = pcall(getActionSlot, button)
    if not slotOK then actionSlot = nil end
    local binding = button.DamageReaderSkillBinding
    if not actionSlot and self.inCombat and binding then actionSlot = binding.slot end
    if not actionSlot then
        if self.inCombat then self:KeepLast(button) else self:HideButton(button) end
        return
    end
    if button.DamageReaderSkillSlot and button.DamageReaderSkillSlot ~= actionSlot then
        self:HideButton(button)
    end

    local kind, id = ns.Calculator:GetActionInfo(actionSlot)
    local cachedIdentity = false
    if not kind and self.inCombat and binding and binding.slot == actionSlot then
        kind, id, cachedIdentity = "spell", binding.id, true
    end
    if not kind then
        if self.inCombat then self:KeepLast(button) else self:HideButton(button) end
        return
    end
    if kind ~= "spell" then
        button.DamageReaderSkillBinding = nil
        self:HideButton(button)
        return
    end
    button.DamageReaderSkillBinding = {slot = actionSlot, id = id}
    if button.DamageReaderSkillSpellID and button.DamageReaderSkillSpellID ~= id then
        self:HideButton(button)
    end
    -- A cached binding is public data captured earlier and invalidated on paging
    -- or slot changes. Re-read spell stats/auras, never reconstruct secret IDs.
    local sourceSlot = not cachedIdentity and actionSlot or nil
    local ok, result, reason, state = pcall(ns.Calculator.EstimateSpell, ns.Calculator, id, sourceSlot)
    if not ok then result = nil end
    if not result or not result.text then
        if self.inCombat and state ~= "empty" then self:KeepLast(button) else self:HideButton(button) end
        return
    end
    local displayed = self:GetDisplayText(result)
    if not displayed then self:HideButton(button); return end

    text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", ns.db.fontSize, "OUTLINE")
    local color = result.kind == "heal" and ns.db.healColor
        or result.kind == "mana" and ns.db.manaColor
        or result.kind == "energy" and ns.db.energyColor
        or result.kind == "absorb" and ns.db.absorbColor or ns.db.color
    text:SetTextColor(unpack(color))
    text:SetText(displayed)
    button.DamageReaderSkillResult = result
    button.DamageReaderSkillSlot = actionSlot
    button.DamageReaderSkillSpellID = id
    button.DamageReaderSkillStale = result.stale or false
    text:Show()
end

function ButtonManager:UpdateAll()
    for _, button in ipairs(self.buttons) do
        self:UpdateButton(button)
    end
end

function ButtonManager:SetInCombat(inCombat)
    self.inCombat = inCombat
end
