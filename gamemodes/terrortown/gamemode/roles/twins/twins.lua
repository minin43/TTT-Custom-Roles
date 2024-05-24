-------------
-- CONVARS --
-------------

local twins_chance = CreateConVar("ttt_twins_chance", "0.1", FCVAR_REPLICATED)
local twins_min_players = CreateConVar("ttt_twins_min_players", "0", FCVAR_REPLICATED)

local twins_enabled = GetConVar("ttt_twins_enabled")
local twins_invulnerability_timer = GetConVar("ttt_twins_invulnerability_timer")

-------------------
-- ROLE SPAWNING --
-------------------

hook.Add("TTTSelectRoles", "Twins_TTTSelectRoles", function()
    local players = {}
    local choices = {}

    for _, p in player.Iterator() do
        if IsValid(p) then
            if not p:IsSpec() then
                table.insert(players, p)
                if p:GetRole() == ROLE_NONE then
                    table.insert(choices, p)
                end
            end
        end
    end

    local forcedGoodTwin = false
    local forcedEvilTwin = false

    for _, p in player.Iterator() do
        local role = p:GetForcedRole()
        if role then
            if table.HasValue(choices, p) then
                table.RemoveByValue(choices, p)
            end
            if role == ROLE_GOODTWIN then
                forcedGoodTwin = true
            elseif role == ROLE_EVILTWIN then
                forcedGoodTwin = true
            end
        end
    end

    -- If both twins have been forced we can stop here
    if forcedGoodTwin and forcedEvilTwin then return
    -- If neither twin has been forced then we spawn them as normal
    elseif not forcedGoodTwin and not forcedEvilTwin then
        if not twins_enabled:GetBool() then return end
        if math.random() > twins_chance:GetFloat() then return end
        if twins_min_players:GetInt() ~= 0 and #players < twins_min_players:GetInt() then return end
        if #choices < 2 then return end

        table.Shuffle(choices)
        choices[1]:SetRole(ROLE_GOODTWIN)
        choices[2]:SetRole(ROLE_EVILTWIN)
    -- If only one twin has been forced then we should try to spawn the other, regardless of config
    else
        if #choices < 1 then return end
        table.Shuffle(choices)

        if forcedGoodTwin then
            choices[1]:SetRole(ROLE_EVILTWIN)
        else
            choices[1]:SetRole(ROLE_GOODTWIN)
        end
    end
end)

hook.Add("TTTBeginRound", "Twins_TTTBeginRound", function()
    local goodTwins = {}
    local evilTwins = {}
    for _, p in player.Iterator() do
        if p:IsGoodTwin() then
            table.insert(goodTwins, p)
        elseif p:IsEvilTwin() then
            table.insert(evilTwins, p)
        end
    end

    -- If we don't have at least one of each twin at the start of the round, change them to regular innocents and traitors
    if #goodTwins == 0 or #evilTwins == 0 then
        for _, p in ipairs(goodTwins) do
            p:SetRole(ROLE_INNOCENT)
        end
        for _, p in ipairs(evilTwins) do
            p:SetRole(ROLE_TRAITOR)
        end
        return
    end

    local message = ""

    if #goodTwins == 1 then
        message = goodTwins[1]:Nick() .. " is your " .. ROLE_STRINGS[ROLE_GOODTWIN] .. "."
    else
        message = "You have multiple " .. ROLE_STRINGS_PLURAL[ROLE_GOODTWIN] .. "! They are " .. util.FormattedList(goodTwins, function(ply) return ply:Nick() end) .. "."
    end
    for _, p in ipairs(evilTwins) do
        p:QueueMessage(MSG_PRINTBOTH, message)
        if #evilTwins >= 2 then
            local fellowEvilTwins = table.Copy(evilTwins)
            table.RemoveByValue(fellowEvilTwins, p)
            if #fellowEvilTwins == 1 then
                message = fellowEvilTwins[1]:Nick() .. " is a fellow " .. ROLE_STRINGS[ROLE_EVILTWIN] .. "!"
            else
                message = util.FormattedList(fellowEvilTwins, function(ply) return ply:Nick() end) .. " are fellow " .. ROLE_STRINGS_PLURAL[ROLE_EVILTWIN] .. "!"
            end
            p:QueueMessage(MSG_PRINTBOTH, message)
        end
    end

    if #evilTwins == 1 then
        message = evilTwins[1]:Nick() .. " is your " .. ROLE_STRINGS[ROLE_EVILTWIN] .. "."
    else
        message = "You have multiple " .. ROLE_STRINGS_PLURAL[ROLE_EVILTWIN] .. "! They are " .. util.FormattedList(evilTwins, function(ply) return ply:Nick() end) .. "."
    end
    for _, p in ipairs(goodTwins) do
        p:QueueMessage(MSG_PRINTBOTH, message)
        if #goodTwins >= 2 then
            local fellowGoodTwins = table.Copy(goodTwins)
            table.RemoveByValue(fellowGoodTwins, p)
            if #fellowGoodTwins == 1 then
                message = fellowGoodTwins[1]:Nick() .. " is a fellow " .. ROLE_STRINGS[ROLE_GOODTWIN] .. "!"
            else
                message = util.FormattedList(fellowGoodTwins, function(ply) return ply:Nick() end) .. " are fellow " .. ROLE_STRINGS_PLURAL[ROLE_GOODTWIN] .. "!"
            end
            p:QueueMessage(MSG_PRINTBOTH, message)
        end
    end
end)

------------------
-- DEATH CHECKS --
------------------

local invulnerabilityEnd = nil
local invulnerabilityTeam = nil
local twinsCanDamageEachOther = false

hook.Add("PlayerDeath", "Twins_PlayerDeath", function(victim, infl, attacker)
    if twinsCanDamageEachOther then return end

    if victim:IsTwin() and not invulnerabilityEnd then
        local invulnerability_timer = twins_invulnerability_timer:GetInt()
        if invulnerability_timer == 0 then return end

        local livingGoodTwins = false
        local livingEvilTwins = false
        for _, p in player.Iterator() do
            if p:IsActiveGoodTwin() then
                table.insert(livingGoodTwins, p)
                if #livingEvilTwins > 0 then return end
            elseif p:IsActiveEvilTwin() then
                table.insert(livingEvilTwins, p)
                if #livingGoodTwins > 0 then return end
            end
        end

        invulnerabilityEnd = CurTime() + invulnerability_timer
        if #livingGoodTwins > 0 then
            invulnerabilityTeam = ROLE_TEAM_INNOCENT
            for _, p in ipairs(livingGoodTwins) do
                p:QueueMessage(MSG_PRINTBOTH, "The " .. ROLE_STRINGS[ROLE_EVILTWIN] .. " has died! You have been granted " .. invulnerability_timer .. " seconds of invulnerability.")
            end
        elseif #livingEvilTwins > 0 then
            invulnerabilityTeam = ROLE_TEAM_TRAITOR
            for _, p in ipairs(livingGoodTwins) do
                p:QueueMessage(MSG_PRINTBOTH, "The " .. ROLE_STRINGS[ROLE_GOODTWIN] .. " has died! You have been granted " .. invulnerability_timer .. " seconds of invulnerability.")
            end
        end
    else
        local twins = {}
        for _, p in player.Iterator() do
            if p:IsActive() then
                if p:IsTwin() then
                    table.insert(twins, p)
                elseif not p:ShouldActLikeJester() then
                    return
                end
            end
        end

        twinsCanDamageEachOther = true
        for _, p in ipairs(twins) do
            p:QueueMessage(MSG_PRINTBOTH, "Only twins remain! You can now damage each other freely.")
        end
    end
end)

---------------------
-- DAMAGE BLOCKING --
---------------------

hook.Add("EntityTakeDamage", "Twins_EntityTakeDamage", function(target, dmginfo)
    if not IsPlayer(target) then return end
    if not target:IsTwin() then return end

    if invulnerabilityEnd and CurTime() < invulnerabilityEnd then
        if (target:IsGoodTwin() and invulnerabilityTeam == ROLE_TEAM_INNOCENT) or (target:IsEvilTwin() and invulnerabilityTeam == ROLE_TEAM_TRAITOR) then
            dmginfo:ScaleDamage(0)
            dmginfo:SetDamage(0)
            return
        end
    end

    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) then return end

    if not twinsCanDamageEachOther and att:IsTwin() then
        dmginfo:ScaleDamage(0)
        dmginfo:SetDamage(0)
        return
    end
end)

----------------
-- HITMARKERS --
----------------

hook.Add("TTTDrawHitMarker", "Twins_TTTDrawHitMarker", function(victim, dmginfo)
    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) or not IsPlayer(victim) then return end

    if not twinsCanDamageEachOther and att:IsTwin() and victim:IsTwin() then
        return true, false, true, false
    end

    if invulnerabilityEnd and CurTime() < invulnerabilityEnd then
        if (victim:IsGoodTwin() and invulnerabilityTeam == ROLE_TEAM_INNOCENT) or (victim:IsEvilTwin() and invulnerabilityTeam == ROLE_TEAM_TRAITOR) then
            return true, false, true, false
        end
    end
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "Twins_TTTPrepareRound", function()
    invulnerabilityEnd = nil
    invulnerabilityTeam = nil
    twinsCanDamageEachOther = false
end)