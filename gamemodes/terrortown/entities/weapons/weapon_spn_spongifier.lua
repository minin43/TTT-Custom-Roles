AddCSLuaFile()

local hook = hook
local player = player

local PlayerIterator = player.Iterator

if CLIENT then
    SWEP.PrintName = "Spongifier"
    SWEP.Slot = 8
end

SWEP.Base = "weapon_cr_defibbase"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.InLoadoutFor = {}
SWEP.InLoadoutForDefault = {}
-- Make this its own kind so it doesn't conflict with all the other role weapons and the DNA scanner
SWEP.Kind = WEAPON_ROLE + 2

SWEP.FindRespawnLocation = false
SWEP.DeadTarget = false

SWEP.BlockShopRandomization = true

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_sponge_device_time", "8", FCVAR_NONE, "The amount of time (in seconds) the spongifier takes to use", 0, 60)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("spongifier_help_pri", "spongifier_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

if SERVER then
    function SWEP:OnSuccess(ply, body)
        local owner = self:GetOwner()
        hook.Call("TTTPlayerRoleChangedByItem", nil, owner, owner, self)

        local originalRole = owner:GetRole()
        owner:SetRole(ROLE_SPONGE)
        owner:StripRoleWeapons()
        owner:QueueMessage(MSG_PRINTCENTER, "You have converted yourself to be " .. ROLE_STRINGS_EXT[ROLE_SPONGE])

        local maxhealth = owner:GetMaxHealth()
        local health = owner:Health()
        SetRoleMaxHealth(owner)

        local newmaxhealth = owner:GetMaxHealth()
        local rolestring = ROLE_STRINGS_RAW[originalRole]
        local heal = cvars.Bool("ttt_sponge_device_for_" .. rolestring .. "_heal", false)
        if heal then
            owner:SetHealth(newmaxhealth)
        else
            -- Scale the player's health to match their new max
            -- If they were at 100/100 before, they'll be at 150/150 now
            local healthscale = health / maxhealth
            local newhealth = math.max(math.min(newmaxhealth, math.Round(newmaxhealth * healthscale, 0)), 1)
            owner:SetHealth(newhealth)
        end

        SendFullStateUpdate()
    end

    function SWEP:OnDefibStart(ply, body, bone)
        for _, p in PlayerIterator() do
            if p == ply then continue end
            p:QueueMessage(MSG_PRINTCENTER, ply:Nick() .. " is converting themselves to be " .. ROLE_STRINGS_EXT[ROLE_SPONGE])
        end
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        return "SPONGIFYING YOURSELF"
    end

    function SWEP:GetAbortMessage()
        return "SPONGIFICATION ABORTED"
    end

    function SWEP:IsCurrentTargetValid()
        local owner = self:GetOwner()
        return owner == self.Target and owner:KeyDown(IN_ATTACK)
    end

    function SWEP:GetTarget()
        return self:GetOwner(), nil
    end
end