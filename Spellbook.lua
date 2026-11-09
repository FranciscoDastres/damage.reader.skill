local _, ns = ...
local calc = ns.Calculator
local function safe(value, kind)
    return calc:IsReadable(value) and type(value) == kind
end
local function call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then return a, b, c, d end
end

-- Discover every learned rank, including spells not placed on an action bar.
-- This runs outside combat, never infers an active seal from the spellbook.
function calc:RefreshSpellbook()
    if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
    local spells, seen = {}, {}
    local function add(id, name)
        if not safe(id, "number") or id <= 0 or seen[id] then return end
        seen[id] = true
        name = safe(name, "string") and name or self:GetSpellName(id)
        local family = self.GetSpellFamily and self:GetSpellFamily(id, name) or self:GetPaladinFamily(id, name)
        spells[#spells + 1] = {id = id, name = name, family = family}
    end
    local modern = C_SpellBook
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local count = modern and call(modern.GetNumSpellBookSkillLines)
    if safe(count, "number") and safe(bank, "number") then
        for tab = 1, math.min(count, 100) do
            local info = call(modern.GetSpellBookSkillLineInfo, tab)
            if safe(info, "table") and safe(info.itemIndexOffset, "number") and safe(info.numSpellBookItems, "number") then
                for slot = info.itemIndexOffset + 1, info.itemIndexOffset + math.min(info.numSpellBookItems, 1000) do
                    local item = call(modern.GetSpellBookItemInfo, slot, bank)
                    if safe(item, "table") then
                        local name = safe(item.name, "string") and item.name or call(modern.GetSpellBookItemName, slot, bank)
                        add(item.spellID, name)
                    end
                end
            end
        end
    end
    if #spells == 0 then
        count = call(GetNumSpellTabs)
        if safe(count, "number") then
            for tab = 1, math.min(count, 100) do
                local _, _, offset, size = call(GetSpellTabInfo, tab)
                if safe(offset, "number") and safe(size, "number") then
                    for slot = offset + 1, offset + math.min(size, 1000) do
                        local kind, id = call(GetSpellBookItemInfo, slot, BOOKTYPE_SPELL or "spell")
                        if safe(kind, "string") and kind == "SPELL" then
                            add(id, call(GetSpellBookItemName, slot, BOOKTYPE_SPELL or "spell"))
                        end
                    end
                end
            end
        end
    end
    -- Action slots also expose ranks when a client lacks spellbook APIs.
    for slot = 1, 180 do
        local kind, id = self:GetActionInfo(slot)
        if kind == "spell" then add(id) end
    end
    self.knownSpells = spells
    self.spellbookDirty = false
end
