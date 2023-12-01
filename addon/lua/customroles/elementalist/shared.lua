CreateConVar("ttt_elementalist_allow_effect_upgrades", "1", FCVAR_REPLICATED, "Controls whether elemental effect \"upgrades\" should be available for purchase", 0, 1)

local ROLE = {}

ROLE.nameraw = "elementalist"
ROLE.name = "Elemantalist"
ROLE.nameplural = "Elementalists"
ROLE.nameext = "an Elementalist"
ROLE.nameshort = "elm"

ROLE.desc = [[You are an {role}! {comrades}

Bullets you shoot may activate a special effect when they hit your target.

Press {menukey} to purchase new effects as you unlock additional equipment points!]]

ROLE.team = ROLE_TEAM_TRAITOR

ROLE.shop = {}
ROLE.loadout = {}

ROLE.translations = {}

ROLE.convars = {}
table.insert(ROLE.convars, {
    cvar = "ttt_elementalist_allow_effect_upgrades",
    type = ROLE_CONVAR_TYPE_BOOL
})

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()
end

local mat_dir = "vgui/ttt/"

local frostbiteEquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = frostbiteEquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Frostbite", --Mirrors functionality from CTDM
    desc        = "Shoot players to slow down their movement, strength and duration of slow depending on damage done."
})
-- How to get this to show only after version 1 has been purchased?
local frostbite2EquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = frostbite2EquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Frostbite Upgrade", --Just extends Frostbite slow to 0
    desc        = "Players who have been slowed have a chance to freeze, losing all movement."
})

local pyroEquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = pyroEquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Pyromancer", --Mirrors functionality from CTDM
    desc        = "Shoot players to ignite them, duration scaling with damage done."
})
local pyro2EquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = pyro2EquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Pyromancer Upgrade", --Mirrors functionaliy from CTDM
    desc        = "Ignited players have a chance to explode, doing damage to everyone around them."
})

local windEquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = windEquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Windburn", --I think you can add force push to the dmginfo in EntityTakeDamage?
    desc        = "Shooting players pushes them backwards and away from you, force of push scaling with damage done."
})
local wind2EquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = wind2EquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Windburn Upgrade", --Can duplicate the functionality from the grenade from CTDM
    desc        = "Instead of pushing, occaisonally launches shot players into the air, for a hard, painful landing" --should rob them of their second jump
})

local dischargeEquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = dischargeEquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Discharge", --Mirror functionality from the discombob grenade?
    desc        = "Shoot players to shock them, punching their view and disorienting them."
})
local discharge2EquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = discharge2EquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Discharge Upgrade",
    desc        = "" --What should be?
})

local midEquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = midEquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Midnight", --Should use an overlay, gradient to center
    desc        = "Shoot players to begin to blind them, dimming their screen and making it difficult for them to see."
})
local mid2EquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = mid2EquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Midnight Upgrade", --No overlay, completely black screen that fades out
    desc        = "Players with dimmed screens have a chance to go completely blind, seeing nothing."
})

local lifeEquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = lifeEquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Lifesteal", --Easy to do
    desc        = "Shoot players to steal their life force, one bullet at a time."
})
local life2EquipmentId = GenerateNewEquipmentID()
table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
    id          = life2EquipmentId,
    type        = "item_passive",
    material    = mat_dir .. "",
    name        = "Lifesteal Upgrade", --Easy to do
    desc        = "Executes targets instead if they get too low hp, killing them instantly."
})