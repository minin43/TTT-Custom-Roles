AddCSLuaFile()

local hook = hook
local table = table
local util = util
local weapons = weapons

-- Initialize role features
ROLE_STARTING_CREDITS[ROLE_DOCTOR] = 1
local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_DOCTOR] = {
            "weapon_ttt_health_station",
            "weapon_doc_cure"
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Doctor_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Doctor_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE CONVARS --
------------------

local doctor_cure_rebuyable = CreateConVar("ttt_doctor_cure_rebuyable", "0", FCVAR_REPLICATED, "Whether the cure can be bought multiple times", 0, 1)

ROLE_CONVARS[ROLE_DOCTOR] = {}
table.insert(ROLE_CONVARS[ROLE_DOCTOR], {
    cvar = "ttt_doctor_cure_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Kill nobody", "Kill owner", "Kill target"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_DOCTOR], {
    cvar = "ttt_doctor_cure_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_DOCTOR], {
    cvar = "ttt_doctor_cure_rebuyable",
    type = ROLE_CONVAR_TYPE_BOOL
})

------------------
-- ROLE WEAPONS --
------------------

hook.Add("TTTUpdateRoleState", "Doctor_TTTUpdateRoleState", function()
    local cure = weapons.GetStored("weapon_doc_cure")
    if util.CanRoleSpawn(ROLE_PARASITE) or util.CanRoleSpawn(ROLE_PLAGUEMASTER) then
        cure.CanBuy = table.Copy(cure.CanBuyDefault)
    else
        table.Empty(cure.CanBuy)
    end

    cure.LimitedStock = not doctor_cure_rebuyable:GetBool()
end)