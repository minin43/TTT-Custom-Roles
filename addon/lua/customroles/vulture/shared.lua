CreateConVar("ttt_vulture_health_restoration", "25", FCVAR_REPLICATED, "How much HP a Vulture gets back on a restock.", 1, 100) --should play a sound when health gets restored... or really when anything happens
CreateConVar("ttt_vulture_allow_special_restock", "1", FCVAR_REPLICATED, "Whether Vultures can restock ammo in equipped Traitor weapons", 0, 1)

local ROLE = {}

ROLE.nameraw = "vulture"
ROLE.name = "Vulture"
ROLE.nameplural = "Vultures"
ROLE.nameext = "a Vulture"
ROLE.nameshort = "vlt"

ROLE.desc = [[You are a {role}! {comrades}

Loot corpses to restock on ammo or health.

Press {menukey} to access the standard Traitor equipment shop.]]

ROLE.team = ROLE_TEAM_TRAITOR

ROLE.shop = {}
ROLE.loadout = {}
ROLE.shopsyncroles = {ROLE_TRAITOR}

ROLE.translations = {}

ROLE.convars = {}
table.insert(ROLE.convars, {
    cvar = "ttt_vulture_health_restoration",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE.convars, {
    cvar = "ttt_vulture_allow_special_restock",
    type = ROLE_CONVAR_TYPE_BOOL
})

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()
end