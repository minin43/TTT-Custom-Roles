------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Twins_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_goodtwin", [[You are {role}!
You have a twin on the traitor team that knows who you are.
However, you and your twin are unable to damage each other.
If you are the last twin left alive you get temporary invulnerability.
Try to convince everyone that you are the good twin!]])

    LANG.AddToLanguage("english", "info_popup_eviltwin", [[You are {role}! {comrades}

You have a twin on the innocent team that knows who you are.
However, you and your twin are unable to damage each other.
If you are the last twin left alive you get temporary invulnerability.
Try to trick everyone into thinking you are the good twin!

Press {menukey} to receive your special equipment!]])
end)

---------------
-- TARGET ID --
---------------

hook.Add("TTTTargetIDPlayerRoleIcon", "Twins_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if not cli:IsActiveTwin() then return end
    if ply == cli then return end

    if ply:IsActiveGoodTwin() then
        return ROLE_GOODTWIN, false
    elseif ply:IsActiveEvilTwin() then
        return ROLE_EVILTWIN, cli:IsActiveEvilTwin()
    end
end)

hook.Add("TTTTargetIDPlayerRing", "Twins_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
    if not IsPlayer(ent) then return end
    if not cli:IsActiveTwin() then return end
    if ent == cli then return end

    if ent:IsActiveGoodTwin() then
        return true, ROLE_COLORS_RADAR[ROLE_GOODTWIN]
    elseif ent:IsActiveEvilTwin() then
        return true, ROLE_COLORS_RADAR[ROLE_EVILTWIN]
    end
end)

hook.Add("TTTTargetIDPlayerText", "Twins_TTTTargetIDPlayerText", function(ent, cli, text, col)
    if not IsPlayer(ent) then return end
    if not cli:IsActiveTwin() then return end
    if ent == cli then return end

    if ent:IsActiveGoodTwin() then
        return string.upper(ROLE_STRINGS[ROLE_GOODTWIN]), ROLE_COLORS_RADAR[ROLE_GOODTWIN]
    elseif ent:IsActiveEvilTwin() then
        return string.upper(ROLE_STRINGS[ROLE_EVILTWIN]), ROLE_COLORS_RADAR[ROLE_EVILTWIN]
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_GOODTWIN] = function(ply, target, showJester)
    if not IsPlayer(target) then return end

    if ply:IsActiveGoodTwin() and target:IsActiveTwin() then
        return true, true, true
    end
end

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_EVILTWIN] = function(ply, target, showJester)
    if not IsPlayer(target) then return end

    if ply:IsActiveEvilTwin() and target:IsActiveTwin() then
        return true, true, true
    end
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Twins_TTTScoreboardPlayerRole", function(ply, cli, color, roleFileName)
    if not cli:IsActiveTwin() then return end
    if ply == cli then return end

    if ply:IsActiveGoodTwin() then
        return ROLE_COLORS_SCOREBOARD[ROLE_GOODTWIN], ROLE_STRINGS_SHORT[ROLE_GOODTWIN]
    elseif ply:IsActiveEvilTwin() then
        return ROLE_COLORS_SCOREBOARD[ROLE_EVILTWIN], ROLE_STRINGS_SHORT[ROLE_EVILTWIN]
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_GOODTWIN] = function(ply, target)
    return false, ply:IsActiveGoodTwin() and target:IsActiveTwin()
end

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_EVILTWIN] = function(ply, target)
    return false, ply:IsActiveEvilTwin() and target:IsActiveTwin()
end

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Twins_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_GOODTWIN then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]

        local html = "The " .. ROLE_STRINGS[ROLE_GOODTWIN] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> who has an evil counterpart on the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor team</span>."

        html = html .. "<span style='display: block; margin-top: 10px;'>The twins rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot damage each other</span> unless they are the last non-jester players alive."

        local invulnerability_timer = GetConVar("ttt_twins_invulnerability_timer"):GetInt()
        if invulnerability_timer > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>If one twin dies, the other is given " .. invulnerability_timer .. " second(s) of invulnerability."
        end

        return html
    elseif role == ROLE_EVILTWIN then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local innocentColor = ROLE_COLORS[ROLE_INNOCENT]

        local html = "The " .. ROLE_STRINGS[ROLE_EVILTWIN] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> who has a good counterpart on the <span style='color: rgb(" .. innocentColor.r .. ", " .. innocentColor.g .. ", " .. innocentColor.b .. ")'>innocent team</span>."

        html = html .. "<span style='display: block; margin-top: 10px;'>The twins rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot damage each other</span> unless they are the last non-jester players alive."

        local invulnerability_timer = GetConVar("ttt_twins_invulnerability_timer"):GetInt()
        if invulnerability_timer > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>If one twin dies, the other is given " .. invulnerability_timer .. " second(s) of invulnerability."
        end

        return html
    end
end)