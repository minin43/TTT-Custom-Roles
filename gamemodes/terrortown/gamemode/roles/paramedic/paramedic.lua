AddCSLuaFile()

local hook = hook
local player = player

local PlayerIterator = player.Iterator

-------------------
-- ROLE FEATURES --
-------------------

local paramedic_revive_muted = CreateConVar("ttt_paramedic_revive_muted", 0, FCVAR_NONE, "Whether players revived by the paramedic should be muted", 0, 1)

hook.Add("PlayerCanHearPlayersVoice", "Paramedic_PlayerCanHearPlayersVoice", function(listener, speaker)
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not IsPlayer(listener) then return end
    if not listener:Alive() or listener:IsSpec() then return end

    if not IsPlayer(speaker) then return end
    if not speaker:Alive() or speaker:IsSpec() then return end

    if speaker == listener then return end

    if not paramedic_revive_muted:GetBool() then return end
    if not GetConVar("sv_voiceenable"):GetBool() then return end
    if not speaker:GetNWBool("WasRevivedByParamedic", false) then return end
    if speaker.NextParamedicMuteWarning and speaker.NextParamedicMuteWarning > CurTime() then return end

    speaker.NextParamedicMuteWarning = CurTime() + 1
    speaker:PrintMessage(HUD_PRINTTALK, "You have not yet regained your ability to speak")
    return false, false
end)

hook.Add("PlayerSay", "Paramedic_PlayerSay", function(ply, text, team_only)
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not IsPlayer(ply) then return end
    if not ply:Alive() or ply:IsSpec() then return end

    if not paramedic_revive_muted:GetBool() then return end
    if not ply:GetNWBool("WasRevivedByParamedic", false) then return end

    ply:PrintMessage(HUD_PRINTTALK, "You have not yet regained your ability to speak")
    return ""
end)

----------------
-- ROLE STATE --
----------------

hook.Add("TTTPrepareRound", "Paramedic_PrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWBool("WasRevivedByParamedic", false)
        v.NextParamedicMuteWarning = nil
    end
end)