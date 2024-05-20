------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Scout_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_scout", [[You are {role}! You know which {traitor}
roles are in play. Use your intel to help your fellow {innocents}!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Scout_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_SCOUT then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_SCOUT] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> who knows which traitor"

        local revealJesters = GetConVar("ttt_scout_reveal_jesters"):GetBool()
        local revealIndependents = GetConVar("ttt_scout_reveal_independents"):GetBool()
        if revealJesters and revealIndependents then
            html = html .. ", jester, and independent"
        elseif revealJesters then
            html = html .. " and jester"
        elseif revealIndependents then
            html = html .. " and independent"
        end
        html = html .. " roles are in play."

        local delayIntel = GetConVar("ttt_scout_delay_intel"):GetInt()
        if delayIntel > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>This information is revealed to the Scout after <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. delayIntel .. " second(s)</span>.</span>"
        end

        return html
    end
end)