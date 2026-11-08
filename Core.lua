local ADDON_NAME, ns = ...

ns.name = ADDON_NAME or "damage.reader.skill"
ns.version = "0.4.0"

local DEFAULTS = {
    enabled = true,
    fontSize = 11,
    color = { 1.0, 0.82, 0.05 },
    healColor = { 0.20, 1.0, 0.20 },
    debug = false,
}

local eventFrame = CreateFrame("Frame")
ns.EventFrame = eventFrame
ns.refreshPending = false

local function copyDefaults(db)
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            if type(value) == "table" then
                db[key] = { unpack(value) }
            else
                db[key] = value
            end
        end
    end
end

function ns:Print(message)
    print("|cfff5c542Damage Reader Skill:|r " .. tostring(message))
end

function ns:InitializeDatabase()
    DamageReaderSkillDB = DamageReaderSkillDB or {}
    copyDefaults(DamageReaderSkillDB)
    self.db = DamageReaderSkillDB
end

function ns:Refresh(reason)
    if not self.db then return end
    if self.db and self.db.debug and reason then
        self:Print("actualización: " .. reason)
    end

    if self.Buttons then
        if type(InCombatLockdown) == "function" then
            self.Buttons:SetInCombat(InCombatLockdown())
        end
        self.Buttons:Discover()
        self.Buttons:UpdateAll()
    end
end

function ns:ScheduleRefresh(reason)
    if not C_Timer or not C_Timer.After then
        self:Refresh(reason)
        return
    end

    if self.refreshPending then
        return
    end
    self.refreshPending = true

    C_Timer.After(0.1, function()
        self.refreshPending = false
        self:Refresh(reason)
    end)
end

function ns:HandleCommand(rawMessage)
    local message = rawMessage or ""
    message = message:gsub("^%s+", ""):gsub("%s+$", "")
    message = string.lower(message)

    if message == "" or message == "status" then
        self:Print("v" .. self.version .. " /drs on | off | refresh | scan | inspect N | report")
        if type(GetBuildInfo) == "function" then
            local version, build, _, interface = GetBuildInfo()
            self:Print("Cliente: " .. tostring(version) .. " build " .. tostring(build) .. " interfaz " .. tostring(interface))
        end
        self:Print("estado: " .. (self.db and self.db.enabled and "activado" or "desactivado"))
        if self.Buttons then
            self.Buttons:Discover()
            self:Print("botones de acción encontrados: " .. tostring(#self.Buttons.buttons))
        end
        local actionAPI = C_ActionBar and C_ActionBar.GetActionInfo
        if not actionAPI and type(GetActionInfo) == "function" then
            actionAPI = true
        end
        self:Print("API de acciones: " .. (actionAPI and "disponible" or "no disponible"))
        return
    end

    if message == "on" then
        self.db.enabled = true
        self:Refresh("activado")
        self:Print("números activados.")
        return
    end

    if message == "off" then
        self.db.enabled = false
        self:Refresh("desactivado")
        self:Print("números desactivados.")
        return
    end

    if message == "refresh" then
        self:Refresh("manual")
        self:Print("barras actualizadas.")
        return
    end

    if message == "scan" then
        if self.Buttons then
            self.Buttons:Discover()
            self.Buttons:DebugScan()
        end
        return
    end

    local slot = tonumber(message:match("^inspect%s+(%d+)$"))
    if slot and slot >= 1 and slot <= 180 then
        self.Calculator:Report(slot)
        return
    end

    if message == "report" then
        self:ShowReport()
        return
    end

    if message == "reset" then
        DamageReaderSkillDB = {}
        self:InitializeDatabase()
        self:Refresh("configuración reiniciada")
        self:Print("configuración reiniciada.")
        return
    end

    if message == "debug" then
        self.db.debug = not self.db.debug
        self:Print("debug " .. (self.db.debug and "activado" or "desactivado") .. ".")
        return
    end

    self:Print("comando desconocido. Usa /drs para ver la ayuda.")
end

function ns:ShowReport()
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        self:Print("Sal del combate para generar el informe.")
        return
    end
    if not self.reportPanel then
        local panel = CreateFrame("Frame", nil, UIParent)
        panel:SetSize(620, 400)
        panel:SetPoint("CENTER")
        panel:SetFrameStrata("DIALOG")
        panel:EnableMouse(true)
        local background = panel:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        if background.SetColorTexture then
            background:SetColorTexture(0, 0, 0, 0.95)
        else
            background:SetTexture(0, 0, 0, 0.95)
        end
        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Informe: Ctrl+A, Ctrl+C para copiar. Esc para cerrar.")
        local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT")
        close:SetScript("OnClick", function() panel:Hide() end)
        local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 16, -40)
        scroll:SetPoint("BOTTOMRIGHT", -32, 16)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(560)
        edit:SetHeight(320)
        edit:SetAutoFocus(false)
        edit:SetMaxLetters(0)
        edit:SetScript("OnEscapePressed", function() panel:Hide() end)
        scroll:SetScrollChild(edit)
        panel.edit = edit
        self.reportPanel = panel
    end
    self.reportPanel:Show()
    self.reportPanel.edit:SetText(self.Calculator:BuildReport())
    self.reportPanel.edit:SetFocus()
    self.reportPanel.edit:HighlightText()
end

SLASH_DAMAGEREADERSKILL1 = "/drs"
SLASH_DAMAGEREADERSKILL2 = "/damagereader"
SlashCmdList.DAMAGEREADERSKILL = function(message)
    ns:HandleCommand(message)
end

function ns:OnEvent(event, addonName)
    if event == "ADDON_LOADED" then
        if addonName ~= self.name then
            return
        end
        self:InitializeDatabase()
        self:Print("addon cargado v" .. self.version .. ". Usa /drs status para diagnosticar.")
        return
    end

    if event == "PLAYER_LOGIN" then
        self:InitializeDatabase()
        if self.Buttons and type(InCombatLockdown) == "function" then
            self.Buttons:SetInCombat(InCombatLockdown())
        end
        self:ScheduleRefresh("inicio")
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, function() self:ScheduleRefresh("inicio diferido") end)
            C_Timer.After(2, function() self:ScheduleRefresh("inicio final") end)
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if self.Buttons then
            self.Buttons:SetInCombat(true)
        end
        self:ScheduleRefresh("inicio de combate")
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if self.Buttons then
            self.Buttons:SetInCombat(false)
        end
        self:ScheduleRefresh("fin de combate")
        return
    end

    if event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED"
        or event:match("^UPDATE_.*ACTIONBAR$") or event == "SPELLS_CHANGED" then
        if self.Buttons then self.Buttons:InvalidateActions() end
    end
    if event:match("^UNIT_") then
        if not self.Calculator:IsReadable(addonName) or addonName ~= "player" then return end
    end
    self:ScheduleRefresh(event)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    ns:OnEvent(event, ...)
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
eventFrame:RegisterEvent("UPDATE_EXTRA_ACTIONBAR")
eventFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
eventFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_STATS")
eventFrame:RegisterEvent("SPELL_POWER_CHANGED")
eventFrame:RegisterEvent("UNIT_DAMAGE")
eventFrame:RegisterEvent("UNIT_ATTACK_POWER")
eventFrame:RegisterEvent("UNIT_ATTACK_SPEED")
