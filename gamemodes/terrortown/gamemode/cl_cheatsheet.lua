local GetTranslation = LANG.GetTranslation
local StringLower = string.lower
local TableInsert = table.insert
local TableSort = table.sort
local MathMax = math.max
local MathCeil = math.ceil

local hotkey = CreateClientConVar("ttt_cheatsheat_hotkey", "H", true, false, "Hotkey for opening the cheat sheet")
local panel

hook.Add("PlayerButtonDown", "CheatSheet_PlayerButtonDown", function(ply, button)
    if button ~= input.GetKeyCode(hotkey:GetString()) then return end
    if panel ~= nil then return end

    UpdateRoleColours()

    local function AddRolesFromTeam(tbl, team, exclude)
        local roles = {}
        for role, v in pairs(team) do
            if not v or DEFAULT_ROLES[role] or (exclude and exclude[role]) then continue end
            if util.CanRoleSpawn(role) then
                TableInsert(roles, role)
            end
        end
        TableSort(roles, function(a, b) return StringLower(ROLE_STRINGS[a]) < StringLower(ROLE_STRINGS[b]) end)
        for _, role in pairs(roles) do
            TableInsert(tbl, role)
        end
    end

    local detectives = {}
    TableInsert(detectives, ROLE_DETECTIVE)
    AddRolesFromTeam(detectives, DETECTIVE_ROLES)
    local innocents = {}
    TableInsert(innocents, ROLE_INNOCENT)
    AddRolesFromTeam(innocents, INNOCENT_ROLES, DETECTIVE_ROLES)
    local traitors = {}
    TableInsert(traitors, ROLE_TRAITOR)
    AddRolesFromTeam(traitors, TRAITOR_ROLES)
    local jesters = {}
    AddRolesFromTeam(jesters, JESTER_ROLES)
    local independents = {}
    AddRolesFromTeam(independents, INDEPENDENT_ROLES)
    local monsters = {}
    AddRolesFromTeam(monsters, MONSTER_ROLES)

    local columns = 3
    local detectiveRows     = MathCeil(#detectives / columns)
    local innocentRows      = MathCeil(#innocents / columns)
    local traitorRows       = MathCeil(#traitors / columns)
    local jesterRows        = MathCeil(#jesters / columns)
    local independentRows   = MathCeil(#independents / columns)
    local monsterRows       = MathCeil(#monsters / columns)

    local function IsLabelNeeded(tbl)
        return #tbl == 0 and 0 or 1
    end

    local labels = IsLabelNeeded(detectives) + IsLabelNeeded(innocents) + IsLabelNeeded(traitors)
            + IsLabelNeeded(jesters) + IsLabelNeeded(independents) + IsLabelNeeded(monsters)

    local iconSize          = 64
    local titleHeight       = 18
    local descriptionWidth  = 196
    local labelHeight       = 16
    local m                 = 5

    local detectivesHeight      = MathMax((iconSize + m) * detectiveRows + m, 0)
    local innocentsHeight       = MathMax((iconSize + m) * innocentRows + m, 0)
    local traitorsHeight        = MathMax((iconSize + m) * traitorRows + m, 0)
    local jestersHeight         = MathMax((iconSize + m) * jesterRows + m, 0)
    local independentsHeight    = MathMax((iconSize + m) * independentRows + m, 0)
    local monstersHeight        = MathMax((iconSize + m) * monsterRows + m, 0)

    local w = (iconSize + descriptionWidth + (m * 3)) * 3
    local h = detectivesHeight + innocentsHeight + traitorsHeight + jestersHeight + independentsHeight + monstersHeight + (labelHeight * labels)

    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetVisible(true)
    dframe:SetDeleteOnClose(true)
    dframe:ShowCloseButton(false)
    dframe:SetTitle(GetTranslation("cheatsheet_title"))
    if scrollbarEnabled then
        dframe:SetVerticalScrollbarEnabled(true)
    end

    local dlist = vgui.Create("DPanel", dframe)
    dlist:SetSize(w, h)
    dlist:SetPos(0, 0)
    dlist:SetMouseInputEnabled(true)
    dlist:SetBackgroundColor(COLOR_GRAY)

    local function CreateTeamList(label, roleTable, height, yOffset)
        local dlabel = vgui.Create("DLabel", dlist)
        dlabel:SetFont("TabLarge")
        dlabel:SetText(label)
        dlabel:SetContentAlignment(7)
        dlabel:SetWidth(w)
        dlabel:SetPos(m + 3, yOffset) -- For some reason the text isn't inline with the icons so we shift it 3px to the right

        local dteam = vgui.Create("DPanel", dlist)
        dteam:SetPos(m, yOffset + labelHeight)
        dteam:SetSize(w, height)
        dteam:SetPaintBackground(false)

        local currentColumn = 0
        local currentRow = 0

        for _, role in pairs(roleTable) do
            local icon = vgui.Create("SimpleIcon", dteam)

            local roleStringShort = ROLE_STRINGS_SHORT[role]
            local material = util.GetRoleIconPath(roleStringShort, "icon", "vtf")

            icon:SetIconSize(iconSize)
            icon:SetIcon(material)
            icon:SetBackgroundColor(ROLE_COLORS[role] or Color(0, 0, 0, 0))
            icon:SetTooltip(ROLE_STRINGS[role])
            icon:SetPos(currentColumn * (iconSize + descriptionWidth + (m * 2)), currentRow * (iconSize + m))
            icon.DoClick = function()
                -- TODO: Open tutorial page for role
                panel:Close()
                panel = nil
            end

            local title = vgui.Create("DLabel", dteam)
            title:SetFont("TabLarge")
            title:SetPos(iconSize + m + (currentColumn * (iconSize + descriptionWidth + (m * 2))), currentRow * (iconSize + m))
            title:SetSize(descriptionWidth, titleHeight)
            title:SetContentAlignment(7)
            title:SetText(ROLE_STRINGS[role])

            local desc = vgui.Create("DLabel", dteam)
            desc:SetPos(iconSize + m + (currentColumn * (iconSize + descriptionWidth + (m * 2))), titleHeight + (currentRow * (iconSize + m)))
            desc:SetSize(descriptionWidth, iconSize - titleHeight)
            desc:SetWrap(true)
            desc:SetContentAlignment(7)
            -- TODO: Actually add role descriptions
            desc:SetText("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec aliquam turpis mollis elit consectetur venenatis.")

            currentColumn = currentColumn + 1
            if currentColumn == 3 then
                currentColumn = 0
                currentRow = currentRow + 1
            end

            -- TODO: Highlight current role
        end
    end

    local yOffset = m
    if #detectives > 0 then
        CreateTeamList("Detective Roles", detectives, detectivesHeight, yOffset)
        yOffset = yOffset + detectivesHeight + labelHeight
    end
    if #innocents > 0 then
        CreateTeamList("Innocent Roles", innocents, innocentsHeight, yOffset)
        yOffset = yOffset + innocentsHeight + labelHeight
    end
    if #traitors > 0 then
        CreateTeamList("Traitor Roles", traitors, traitorsHeight, yOffset)
        yOffset = yOffset + traitorsHeight + labelHeight
    end
    if #jesters > 0 then
        CreateTeamList("Jester Roles", jesters, jestersHeight, yOffset)
        yOffset = yOffset + jestersHeight + labelHeight
    end
    if #independents > 0 then
        CreateTeamList("Independent Roles", independents, independentsHeight, yOffset)
        yOffset = yOffset + independentsHeight + labelHeight
    end
    if #monsters > 0 then
        CreateTeamList("Monster Roles", monsters, monstersHeight, yOffset)
    end

    dframe:MakePopup()
    dframe:SetKeyboardInputEnabled(false)

    panel = dframe
end)

hook.Add("PlayerButtonUp", "CheatSheet_PlayerButtonUp", function(ply, button)
    if button ~= input.GetKeyCode(hotkey:GetString()) then return end
    if panel == nil then return end

    panel:Close()
    panel = nil
end)