AddCSLuaFile()

local hook = hook
local player = player

local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_UpdateJesterSecondaryWins")
util.AddNetworkString("TTT_ResetJesterSecondaryWins")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_jester_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a jester was killed. Killer is notified unless \"ttt_jester_notify_killer\" is disabled", 0, 4)
CreateConVar("ttt_jester_notify_killer", "1", FCVAR_NONE, "Whether to notify a jester's killer", 0, 1)
CreateConVar("ttt_jester_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a jester is killed", 0, 1)
CreateConVar("ttt_jester_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a jester is a killed", 0, 1)
local jester_win_ends_round = CreateConVar("ttt_jester_win_ends_round", "1", FCVAR_NONE, "Whether the jester winning causes the round to end", 0, 1)

local jester_win_by_traitors = GetConVar("ttt_jester_win_by_traitors")

----------------
-- WIN CHECKS --
----------------

local function JesterKilledNotification(attacker, victim)
    JesterTeamKilledNotification(attacker, victim,
        -- getkillstring
        function()
            return attacker:Nick() .. " was dumb enough to kill the " .. ROLE_STRINGS[ROLE_JESTER] .. "!"
        end,
        -- shouldshow
        function()
            -- Don't announce anything if the game doesn't end here and the Jester was killed by a traitor
            return not (not jester_win_by_traitors:GetBool() and attacker:IsTraitorTeam())
        end)
end

local jesterWinTime = nil
hook.Add("PlayerDeath", "Jester_WinCheck_PlayerDeath", function(victim, infl, attacker)
    if jesterWinTime then return end

    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end

    if victim:IsJester() then
        JesterKilledNotification(attacker, victim)
        victim:SetNWString("JesterKiller", attacker:Nick())

        -- If the attacker was a traitor and the jester doesn't win when killed by a traitor, then don't continue
        if attacker:IsTraitorTeam() and not jester_win_by_traitors:GetBool() then return end

        -- If we're not ending the round, just reuse the existing variable and
        -- set it to something valid so the win check logic sees it's been updated
        if not jester_win_ends_round:GetBool() then
            jesterWinTime = 1
            net.Start("TTT_UpdateJesterSecondaryWins")
            net.Broadcast()
            return
        end

        -- If we're debugging, don't end the round
        if GetConVar("ttt_debug_preventwin"):GetBool() then
            return
        end

        -- Delay the actual end for a second so the message and sound have a chance to generate a reaction
        jesterWinTime = CurTime() + 1
    end
end)

hook.Add("TTTCheckForWin", "Jester_TTTCheckForWin", function()
    if not jester_win_ends_round:GetBool() then return end

    if jesterWinTime then
        if CurTime() > jesterWinTime then
            jesterWinTime = nil
            return WIN_JESTER
        end

        return WIN_NONE
    end
end)

hook.Add("TTTPrintResultMessage", "Jester_TTTPrintResultMessage", function(type)
    if type == WIN_JESTER then
        LANG.Msg("win_jester", { role = ROLE_STRINGS[ROLE_JESTER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_JESTER] .. " wins.\n")
        return true
    end
end)

hook.Add("TTTPrepareRound", "Jester_TTTPrepareRound", function()
    jesterWinTime = nil

    for _, v in PlayerIterator() do
        v:SetNWString("JesterKiller", "")
    end

    net.Start("TTT_ResetJesterSecondaryWins")
    net.Broadcast()
end)

hook.Add("TTTBeginRound", "Jester_TTTBeginRound", function()
    net.Start("TTT_ResetJesterSecondaryWins")
    net.Broadcast()
end)