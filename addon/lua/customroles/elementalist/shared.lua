CreateConVar("ttt_elementalist_allow_effect_upgrades", "1", FCVAR_REPLICATED, "Controls whether elemental effect \"upgrades\" should be available for purchase", 0, 1)

local ROLE = ROLE or {}

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

hook.Add("Initialize", "MadScientist_DeathRadar_Initialize", function()
    EQUIP_ELEMENTALIST_FROSTBITE = EQUIP_ELEMENTALIST_FROSTBITE or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_FROSTBITE,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Frostbite", --Mirrors functionality from CTDM
        desc        = "Shoot players to slow down their movement, strength and duration of slow depending on damage done."
    })
    -- How to get this to show only after version 1 has been purchased?
    EQUIP_ELEMENTALIST_FROSTBITE_UP = EQUIP_ELEMENTALIST_FROSTBITE_UP or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_FROSTBITE_UP,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Frostbite Upgrade", --Just extends Frostbite slow to 0
        desc        = "Players who have been slowed have a chance to freeze, losing all movement."
    })

    EQUIP_ELEMENTALIST_PYROMANCER = EQUIP_ELEMENTALIST_PYROMANCER or GenerateNewEquipmentID()
    table.insert(EQUIP_ELEMENTALIST_PYROMANCER[ROLE_ELEMENTALIST], {
        id          = pyroEquipmentId,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Pyromancer", --Mirrors functionality from CTDM
        desc        = "Shoot players to ignite them, duration scaling with damage done."
    })
    EQUIP_ELEMENTALIST_PYROMANCER_UP = EQUIP_ELEMENTALIST_PYROMANCER_UP or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_PYROMANCER_UP,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Pyromancer Upgrade", --Mirrors functionaliy from CTDM
        desc        = "Ignited players have a chance to explode, doing damage to everyone around them."
    })

    EQUIP_ELEMENTALIST_WINDBURN = EQUIP_ELEMENTALIST_WINDBURN or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_WINDBURN,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Windburn", --I think you can add force push to the dmginfo in EntityTakeDamage?
        desc        = "Shooting players pushes them backwards and away from you, force of push scaling with damage done."
    })
    EQUIP_ELEMENTALIST_WINDBURN_UP = EQUIP_ELEMENTALIST_WINDBURN_UP or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_WINDBURN_UP,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Windburn Upgrade", --Can duplicate the functionality from the grenade from CTDM
        desc        = "Instead of pushing, occaisonally launches shot players into the air, for a hard, painful landing" --should rob them of their second jump
    })

    EQUIP_ELEMENTALIST_DISCHARGE = EQUIP_ELEMENTALIST_DISCHARGE or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_DISCHARGE,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Discharge", --Mirror functionality from the discombob grenade?
        desc        = "Shoot players to shock them, punching their view and disorienting them."
    })
    EQUIP_ELEMENTALIST_DISCHARGE_UP = EQUIP_ELEMENTALIST_DISCHARGE_UP or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_DISCHARGE_UP,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Discharge Upgrade",
        desc        = "" --What should be?
    })

    EQUIP_ELEMENTALIST_MIDNIGHT = EQUIP_ELEMENTALIST_MIDNIGHT or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_MIDNIGHT,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Midnight", --Should use an overlay, gradient to center
        desc        = "Shoot players to begin to blind them, dimming their screen and making it difficult for them to see."
    })
    EQUIP_ELEMENTALIST_MIDNIGHT_UP = EQUIP_ELEMENTALIST_MIDNIGHT_UP or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_MIDNIGHT_UP,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Midnight Upgrade", --No overlay, completely black screen that fades out
        desc        = "Players with dimmed screens have a chance to go completely blind, seeing nothing."
    })

    EQUIP_ELEMENTALIST_LIFESTEAL = EQUIP_ELEMENTALIST_LIFESTEAL or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_LIFESTEAL,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Lifesteal", --Easy to do
        desc        = "Shoot players to steal their life force, one bullet at a time."
    })
    EQUIP_ELEMENTALIST_LIFESTEAL_UP = EQUIP_ELEMENTALIST_LIFESTEAL_UP or GenerateNewEquipmentID()
    table.insert(EquipmentItems[ROLE_ELEMENTALIST], {
        id          = EQUIP_ELEMENTALIST_LIFESTEAL_UP,
        type        = "item_passive",
        material    = "vgui/ttt/",
        name        = "Lifesteal Upgrade", --Easy to do
        desc        = "Executes targets instead if they get too low hp, killing them instantly."
    })
end)