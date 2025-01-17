AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local math = math
local player = player
local timer = timer

local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local killer_smoke_timer = CreateConVar("ttt_killer_smoke_timer", "60", FCVAR_NONE, "Number of seconds before a killer will start to smoke after their last kill", 1, 120)
local killer_damage_penalty = CreateConVar("ttt_killer_damage_penalty", "0.25", FCVAR_NONE, "The fraction a killer's damage will be scaled by when they are attacking without using their knife", 0, 1)
local killer_damage_reduction = CreateConVar("ttt_killer_damage_reduction", "0", FCVAR_NONE, "The fraction an attacker's bullet damage will be reduced by when they are shooting a killer", 0, 1)
local killer_credits_award_pct = CreateConVar("ttt_killer_credits_award_pct", "0.35")
local killer_credits_award_size = CreateConVar("ttt_killer_credits_award_size", "1")
local killer_credits_award_repeat = CreateConVar("ttt_killer_credits_award_repeat", "1")

local killer_knife_enabled = GetConVar("ttt_killer_knife_enabled")
local killer_crowbar_enabled = GetConVar("ttt_killer_crowbar_enabled")
local killer_smoke_enabled = GetConVar("ttt_killer_smoke_enabled")
local killer_show_target_icon = GetConVar("ttt_killer_show_target_icon")
local killer_vision_enabled = GetConVar("ttt_killer_vision_enabled")
local killer_warn_all = GetConVar("ttt_killer_warn_all")

-----------
-- KARMA --
-----------

-- Killer has no karma, positive or negative
hook.Add("TTTKarmaGivePenalty", "Killer_TTTKarmaGivePenalty", function(ply, penalty, victim)
    if IsPlayer(victim) and ply:IsKiller() then
        return true
    end
end)
hook.Add("TTTKarmaGiveReward", "Killer_TTTKarmaGiveReward", function(ply, reward, victim)
    if IsPlayer(victim) and ply:IsKiller() then
        return true
    end
end)

-----------
-- SMOKE --
-----------

-- Handle killer smoke checks
local killerSmokeTime = 0
local function ResetKillerKillCheckTimer()
    killerSmokeTime = 0
    timer.Start("KillerKillCheckTimer")
end

-- Enable smoke if it has been too long between kills
local function HandleKillerSmokeTick()
    timer.Stop("KillerKillCheckTimer")
    if GetRoundState() ~= ROUND_ACTIVE then
        ResetKillerKillCheckTimer()
    end

    timer.Create("KillerTick", 0.1, 0, function()
        if GetRoundState() == ROUND_ACTIVE then
            if killerSmokeTime >= killer_smoke_timer:GetInt() then
                for _, v in PlayerIterator() do
                    if not IsValid(v) then return end
                    if v:IsKiller() and v:Alive() and not v:GetNWBool("KillerSmoke", false) then
                        v:SetNWBool("KillerSmoke", true)
                        v:QueueMessage(MSG_PRINTBOTH, "Your evil is showing")
                    elseif (v:IsKiller() and not v:Alive()) or not player.IsRoleLiving(ROLE_KILLER) then
                        timer.Remove("KillerKillCheckTimer")
                    end
                end
            end
        else
            killerSmokeTime = 0
        end
    end)
end

-- Warn the player periodically if they are going to start smoking
timer.Create("KillerKillCheckTimer", 1, 0, function()
    local killer = player.GetLivingRole(ROLE_KILLER)
    if GetRoundState() == ROUND_ACTIVE and killer_smoke_enabled:GetBool() and killer ~= nil then
        killerSmokeTime = killerSmokeTime + 1

        -- Warn the killer that they need to kill at 1/2 time remaining, 1/4 time remaining, 10 seconds remaining, and 5 seconds remaining
        local smoke_timer = killer_smoke_timer:GetInt()
        local timer_remaining = smoke_timer - killerSmokeTime
        local timer_fraction = (timer_remaining / smoke_timer)
        -- Don't do the 1/2 and 1/4 checks if they represent < 10 seconds
        if (timer_fraction == 0.5 and timer_remaining > 10) or
            (timer_fraction == 0.25 and timer_remaining > 10) or
            timer_remaining == 10 or timer_remaining == 5 then
            killer:PrintMessage(HUD_PRINTTALK, "Your evil grows impatient. Kill someone in the next " .. timer_remaining .. " seconds or you will be revealed!")
        end

        if killerSmokeTime >= smoke_timer then
            HandleKillerSmokeTick()
        else
            timer.Remove("KillerTick")
        end
    else
        killerSmokeTime = 0
    end
end)

-- Reset smoke when the killer... kills
hook.Add("PlayerDeath", "Killer_Smoke_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if valid_kill and attacker:IsKiller() then
        attacker:SetNWBool("KillerSmoke", false)
        ResetKillerKillCheckTimer()
    end
end)

-- Disable the smoke when the round ends, the player respawns, or they have their role changed
hook.Add("TTTPrepareRound", "Killer_Smoke_PrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWBool("KillerSmoke", false)
    end
end)

hook.Add("TTTPlayerSpawnForRound", "Killer_Smoke_TTTPlayerSpawnForRound", function(ply, dead_only)
    if dead_only and ply:Alive() and not ply:IsSpec() then return end

    ply:SetNWBool("KillerSmoke", false)
end)

hook.Add("TTTPlayerRoleChanged", "Killer_Smoke_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_KILLER then
        ply:SetNWBool("KillerSmoke", false)
    end
end)

-------------
-- CREDITS --
-------------

-- Reset credit status
hook.Add("Initialize", "Killer_Credits_Initialize", function()
    GAMEMODE.AwardedKillerCredits = false
    GAMEMODE.AwardedKillerCreditsDead = 0
end)
hook.Add("TTTPrepareRound", "Killer_Credits_TTTPrepareRound", function()
    GAMEMODE.AwardedKillerCredits = false
    GAMEMODE.AwardedKillerCreditsDead = 0
end)

-- Award credits for valid kill
hook.Add("DoPlayerDeath", "Killer_Credits_DoPlayerDeath", function(victim, attacker, dmginfo)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsValid(victim) then return end

    local valid_attacker = IsPlayer(attacker)

    if valid_attacker and attacker:IsActiveKiller() and (not (victim:IsKiller() or victim:IsJesterTeam())) and (not GAMEMODE.AwardedKillerCredits or killer_credits_award_repeat:GetBool()) then
        local ply_alive = 0
        local ply_dead = 0

        for _, ply in PlayerIterator() do
            if not ply:IsKiller() then
                if ply:IsTerror() then
                    ply_alive = ply_alive + 1
                elseif ply:IsDeadTerror() then
                    ply_dead = ply_dead + 1
                end
            end
        end

        -- we check this at the death of an innocent who is still technically
        -- Alive(), so add one to dead count and sub one from living
        ply_dead = ply_dead + 1
        ply_alive = math.max(ply_alive - 1, 0)
        local ply_total = ply_alive + ply_dead

        -- Only repeat-award if we have reached the pct again since last time
        if GAMEMODE.AwardedKillerCredits then
            ply_dead = ply_dead - GAMEMODE.AwardedKillerCreditsDead
        end

        local pct = ply_dead / ply_total
        if pct >= killer_credits_award_pct:GetFloat() then
            -- Traitors have killed sufficient people to get an award
            local amt = killer_credits_award_size:GetInt()

            -- If size is 0, awards are off
            if amt > 0 then
                LANG.Msg(GetKillerFilter(true), "credit_all", { role = ROLE_STRINGS[ROLE_KILLER], num = amt })

                for _, ply in PlayerIterator() do
                    if ply:IsActiveKiller() then
                        ply:AddCredits(amt)
                    end
                end
            end

            GAMEMODE.AwardedKillerCredits = true
            GAMEMODE.AwardedKillerCreditsDead = ply_dead + GAMEMODE.AwardedKillerCreditsDead
        end
    end
end)

------------
-- DAMAGE --
------------

-- Scale a killer's damage
hook.Add("ScalePlayerDamage", "Killer_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    -- Only apply damage scaling after the round starts
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        -- Killers do less damage to encourage using the knife
        if dmginfo:IsBulletDamage() and att:IsKiller() then
            local penalty = killer_damage_penalty:GetFloat()
            dmginfo:ScaleDamage(1 - penalty)
        end

        -- Killers take less bullet damage
        if dmginfo:IsBulletDamage() and ply:IsKiller() then
            local reduction = killer_damage_reduction:GetFloat()
            dmginfo:ScaleDamage(1 - reduction)
        end
    end
end)

------------------
-- ROLE WEAPONS --
------------------

-- Make sure the killer keeps their appropriate weapons
hook.Add("TTTPlayerAliveThink", "Killer_TTTPlayerAliveThink", function(ply)
    if not IsValid(ply) or ply:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end

    if ply:IsKiller() then
        -- Ensure the Killer has their knife, if its enabled
        if not ply:HasWeapon("weapon_kil_knife") and killer_knife_enabled:GetBool() then
            ply:Give("weapon_kil_knife")
        end
        if ply:HasWeapon("weapon_zm_improvised") and not ply:HasWeapon("weapon_kil_crowbar") and killer_crowbar_enabled:GetBool() then
            ply:StripWeapon("weapon_zm_improvised")
            ply:Give("weapon_kil_crowbar")
            ply:SelectWeapon("weapon_kil_crowbar")
        end
    end
end)

-- Handle role weapon assignment based on convars
hook.Add("PlayerLoadout", "Killer_PlayerLoadout", function(ply)
    if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() or not ply:IsKiller() or GetRoundState() ~= ROUND_ACTIVE then return end

    if killer_knife_enabled:GetBool() then
        ply:Give("weapon_kil_knife")
    end
    if killer_crowbar_enabled:GetBool() then
        local had_crowbar_out = WEPS.GetClass(ply:GetActiveWeapon()) == "weapon_zm_improvised"
        ply:StripWeapon("weapon_zm_improvised")
        ply:Give("weapon_kil_crowbar")

        if had_crowbar_out then
            ply:SelectWeapon("weapon_kil_crowbar")
        end
    end
end)

-- Only allow the killer to pick up killer-specific weapons
hook.Add("PlayerCanPickupWeapon", "Killer_Weapons_PlayerCanPickupWeapon", function(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return end

    if (wep:GetClass() == "weapon_kil_knife" or wep:GetClass() == "weapon_kil_crowbar") then
        return ply:IsKiller()
    end
end)

------------------
-- ANNOUNCEMENT --
------------------

-- Warn other players that there is a killer
hook.Add("TTTBeginRound", "Killer_Announce_TTTBeginRound", function()
    timer.Simple(1.5, function()
        local hasKiller = false
        for _, v in PlayerIterator() do
            if v:IsKiller() then
                hasKiller = true
            end
        end

        if hasKiller then
            for _, v in PlayerIterator() do
                local isTraitor = v:IsTraitorTeam()
                -- Warn this player about the Killer if they are a traitor or we are configured to warn everyone
                if not v:IsKiller() and (isTraitor or killer_warn_all:GetBool()) then
                    v:QueueMessage(MSG_PRINTBOTH, "There is " .. ROLE_STRINGS_EXT[ROLE_KILLER] .. ".")
                end
            end
        end
    end)
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTCheckForWin", "Killer_TTTCheckForWin", function()
    local killer_alive = false
    local other_alive = false
    for _, v in PlayerIterator() do
        if v:IsActive() then
            if v:IsKiller() then
                killer_alive = true
            elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                other_alive = true
            end
        end
    end

    if killer_alive and not other_alive then
        return WIN_KILLER
    elseif killer_alive then
        return WIN_NONE
    end
end)

hook.Add("TTTPrintResultMessage", "Killer_TTTPrintResultMessage", function(type)
    if type == WIN_KILLER then
        LANG.Msg("win_killer", { role = ROLE_STRINGS[ROLE_KILLER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_KILLER] .. " wins.\n")
        return true
    end
end)

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all players to the PVS for the killer if highlighting or Kill icon are enabled
hook.Add("SetupPlayerVisibility", "Killer_SetupPlayerVisibility", function(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveKiller() then return end
    if not killer_vision_enabled:GetBool() and not killer_show_target_icon:GetBool() then return end

    for _, v in PlayerIterator() do
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)