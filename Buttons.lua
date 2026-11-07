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

    local candidates = { button.actionID, button.action }
    for _, slot in ipairs(candidates) do
        if validSlot(slot) then
            return slot
        end
    end

    local buttonName = button.GetName and button:GetName() or ""
    local index = tonumber(string.match(buttonName, "(%d+)$"))
    if index then
        if string.match(buttonName, "^ActionButton") then
            return index
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

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", ns.db.fontSize, "OUTLINE")
    text:ClearAllPoints()
    text:SetPoint("CENTER", button, "CENTER", 0, -7)
    text:SetDrawLayer("OVERLAY", 7)
    text:SetJustifyH("RIGHT")
    text:SetShadowOffset(1, -1)
    text:SetTextColor(unpack(ns.db.color))
    text:Hide()

    button.DamageReaderSkillText = text

    if not button.DamageReaderSkillHooked then
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
    if button.DamageReaderSkillText then
        button.DamageReaderSkillText:Hide()
    end
end

function ButtonManager:UpdateButton(button)
    local text = self:CreateOverlay(button)

    if not ns.db or not ns.db.enabled or self.inCombat then
        text:Hide()
        return
    end

    local actionSlot = getActionSlot(button)
    if not actionSlot then
        text:Hide()
        return
    end

    local result = ns.Calculator:EstimateAction(actionSlot)
    if not result or not result.text then
        text:Hide()
        return
    end

    text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", ns.db.fontSize, "OUTLINE")
    text:SetTextColor(unpack(ns.db.color))
    text:SetText(result.text)
    text:Show()
end

function ButtonManager:UpdateAll()
    for _, button in ipairs(self.buttons) do
        self:UpdateButton(button)
    end
end

function ButtonManager:SetInCombat(inCombat)
    self.inCombat = inCombat
    if inCombat then
        for _, button in ipairs(self.buttons) do
            self:HideButton(button)
        end
    end
end
