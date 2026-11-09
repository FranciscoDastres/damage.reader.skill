-- Regression: screenshot showed cached ~18 / ~30 looking like negative damage.
local ns, hidden = {}, {}
issecretvalue = function(value) return rawequal(value, hidden) end
ns.db = {enabled=true, fontSize=11, color={1,.82,.05}, healColor={.2,1,.2}}
assert(loadfile('Buttons.lua'))('damage.reader.skill', ns)
local buttons, count = ns.Buttons, 0
local function eq(actual, expected)
    assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
    count = count + 1
end
local current = {text='18', value=18, min=16, max=20, kind='damage'}
eq(buttons:GetDisplayText(current), '18')
eq(buttons:GetDisplayText(current, true), '18*')
eq(current.text, '18') -- rendering never mutates model data/cache
local cached = {text='30', value=30, stale=true}
eq(buttons:GetDisplayText(cached), '30*')
eq(buttons:GetDisplayText(cached, true), '30*')
eq(buttons:GetDisplayText({text='≈55', value=55}), '55e')
eq(buttons:GetDisplayText({text='≈55', value=55}, true), '55e*')
eq(buttons:GetDisplayText({text='≥110', value=110}), '110+')
eq(buttons:GetDisplayText({text='≥110', value=110}, true), '110+*')
eq(buttons:GetDisplayText({text='3–10', min=3, max=10}), '3–10')
eq(buttons:GetDisplayText({text='3–10', min=3, max=10}, true), '3–10*')
eq(buttons:GetDisplayText({text='0', value=0}), '0')
eq(buttons:GetDisplayText({text='25+40/8s', min=65,max=65}), '25+40/8s')
eq(buttons:GetDisplayText({text='25/t | 50/t'}, true), '25/t | 50/t*')
for _, value in ipairs({
    {text='-18',value=-18}, {text='-18'}, {text='−18'}, {text='≈-18'},
    {text='18',min=-1,max=18}, {text='18',min=20,max=10}, {text='18',value=0/0},
    {text='18',value=math.huge}, {text='18',value=hidden}, {text=hidden},
    {text='10+20/t',effects={{min=10,max=10},{min=-20,max=20}}},
    {text='10/20',healing={min=-20,max=20}}, {text='≈'},
}) do eq(buttons:GetDisplayText(value),nil) end
local label = {}
function label:SetFont() end
function label:SetTextColor(r,g,b) self.color={r,g,b} end
function label:SetText(text) self.value=text end
function label:Show() self.visible=true end
function label:Hide() self.visible=false end
local button = {action=1,DamageReaderSkillText=label}
buttons.buttons = {button}
local model = current
ns.Calculator = {GetActionInfo=function() return 'spell',123 end,
    EstimateSpell=function() return model end}
buttons:UpdateButton(button)
eq(label.value,'18')
buttons:SetInCombat(true)
model=nil
buttons:UpdateButton(button)
eq(label.value,'18*')
eq(button.DamageReaderSkillStale,true)
buttons:KeepLast(button)
eq(label.value,'18*')
model=current
buttons:UpdateButton(button)
eq(label.value,'18')
eq(button.DamageReaderSkillStale,false)
model={text='-18',value=-18,kind='damage'}
buttons:UpdateButton(button)
eq(label.visible,false) -- real negatives are rejected, not abs() or old cache
model=cached
buttons:UpdateButton(button)
eq(label.value,'30*')
eq(button.DamageReaderSkillStale,true)
buttons:InvalidateActions(1)
eq(label.visible,false)
print(count .. ' combat-label checks passed: suffixes, ranges, refresh, invalid values and cache safety')
