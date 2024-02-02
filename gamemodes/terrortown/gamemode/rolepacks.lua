include("shared.lua")

local net = net
local util = util
local file = file
local table = table
local string = string

local StringSub = string.sub
local TableInsert = table.insert
local TableHasValue = table.HasValue

ROLEPACKS = {}

util.AddNetworkString("TTT_WriteRolePackRoles")
util.AddNetworkString("TTT_WriteRolePackRoles_Part")
util.AddNetworkString("TTT_RequestRolePackRoles")
util.AddNetworkString("TTT_ReadRolePackRoles")
util.AddNetworkString("TTT_ReadRolePackRoles_Part")
util.AddNetworkString("TTT_WriteRolePackConvars")
util.AddNetworkString("TTT_WriteRolePackConvars_Part")
util.AddNetworkString("TTT_RequestRolePackConvars")
util.AddNetworkString("TTT_ReadRolePackConvars")
util.AddNetworkString("TTT_ReadRolePackConvars_Part")
util.AddNetworkString("TTT_RequestRolePackList")
util.AddNetworkString("TTT_SendRolePackList")
util.AddNetworkString("TTT_CreateRolePack")
util.AddNetworkString("TTT_RenameRolePack")
util.AddNetworkString("TTT_DeleteRolePack")
util.AddNetworkString("TTT_SaveRolePack")
util.AddNetworkString("TTT_ApplyRolePack")
util.AddNetworkString("TTT_ClearRolePack")
util.AddNetworkString("TTT_SendRolePackRoleList")

-- 2^16 bytes - 4 (header) - 2 (UInt length) - 1 (terminanting byte)
local maxStreamLength = 65529

local function SendStreamToClient(ply, json, networkString)
    if not json or json == "" then return end
    local jsonTable = util.Compress(json)
    if jsonTable == "" then
        ErrorNoHalt("Table compression failed!\n")
        return
    end

    local len = #jsonTable

    if len <= maxStreamLength then
        net.Start(networkString)
        net.WriteUInt(len, 16)
        net.WriteData(jsonTable, len)
        net.Send(ply)
    else
        local curpos = 0

        repeat
            net.Start(networkString .. "_Part")
            net.WriteData(StringSub(jsonTable, curpos + 1, curpos + maxStreamLength + 1), maxStreamLength)
            net.Send(ply)

            curpos = curpos + maxStreamLength + 1
        until (len - curpos <= maxStreamLength)

        net.Start(networkString)
        net.WriteUInt(len, 16)
        net.WriteData(StringSub(jsonTable, curpos + 1, len), len - curpos)
        net.Send(ply)
    end
end

local function ReceiveStreamFromClient(networkString, callback)
    local buff = ""
    net.Receive(networkString .. "_Part", function()
        buff = buff .. net.ReadData(maxStreamLength)
    end)

    net.Receive(networkString, function()
        local jsonTable = util.Decompress(buff .. net.ReadData(net.ReadUInt(16)))
        buff = ""

        if jsonTable == "" then
            ErrorNoHalt("Table decompression failed!\n")
            return
        end

        callback(jsonTable)
    end)
end

local function WriteRolePackTable(json)
    local jsonTable = util.JSONToTable(json)
    local name = jsonTable.name
    file.Write("rolepacks/" .. name .. "/roles.json", json)
end
ReceiveStreamFromClient("TTT_WriteRolePackRoles", WriteRolePackTable)

net.Receive("TTT_RequestRolePackRoles", function(len, ply)
    local name = net.ReadString()
    local json = file.Read("rolepacks/" .. name .. "/roles.json", "DATA")
    if not json then return end
    SendStreamToClient(ply, json, "TTT_ReadRolePackRoles")
end)

local function WriteRolePackConvars(json)
    local jsonTable = util.JSONToTable(json)
    local name = jsonTable.name
    file.Write("rolepacks/" .. name .. "/convars.json", json)
end
ReceiveStreamFromClient("TTT_WriteRolePackConvars", WriteRolePackConvars)

net.Receive("TTT_RequestRolePackConvars", function(len, ply)
    local name = net.ReadString()
    local json = file.Read("rolepacks/" .. name .. "/convars.json", "DATA")
    if not json then return end
    SendStreamToClient(ply, json, "TTT_ReadRolePackConvars")
end)

net.Receive("TTT_RequestRolePackList", function(len, ply)
    net.Start("TTT_SendRolePackList")
    local _, directories = file.Find("rolepacks/*", "DATA")
    net.WriteUInt(#directories, 8)
    for _, v in pairs(directories) do
        net.WriteString(v)
    end
    net.Send(ply)
end)

net.Receive("TTT_CreateRolePack", function()
    local name = net.ReadString()
    if not file.IsDir("rolepacks", "DATA") then
        if file.Exists("rolepacks", "DATA") then
            ErrorNoHalt("Item named 'rolepacks' already exists in garrysmod/data but it is not a directory\n")
            return
        end

        file.CreateDir("rolepacks")
    end
    file.CreateDir("rolepacks/" .. name)
    file.Write("rolepacks/" .. name .. "/roles.json", "")
    file.CreateDir("rolepacks/" .. name .. "/weapons")
    file.Write("rolepacks/" .. name .. "/convars.json", "")
end)

net.Receive("TTT_RenameRolePack", function()
    local oldName = net.ReadString()
    local newName = net.ReadString()
    local newPath = "rolepacks/" .. newName
    if file.Exists(newPath, "DATA") then
        ErrorNoHalt("Role pack named '" .. newName .. "' already exists!\n")
        return
    end

    local oldPath = "rolepacks/" .. oldName
    if file.Exists(oldPath, "DATA") then
        file.Rename(oldPath, newPath)
    end
end)

net.Receive("TTT_DeleteRolePack", function()
    local name = net.ReadString()
    local path = "rolepacks/" .. name
    if file.Exists(path, "DATA") then
        file.Delete(path .. "/roles.json")
        file.Delete(path .. "/convars.json")
        for _, v in pairs(file.Find(path .. "/weapons/*.json", "DATA")) do
            file.Delete(path .. "/weapons/" .. v)
        end
        file.Delete(path .. "/weapons")
        file.Delete(path)
    end
end)

net.Receive("TTT_SaveRolePack", function()
    local savedPack = net.ReadString()
    local currentPack = GetConVar("ttt_role_pack"):GetString()
    if savedPack == currentPack then
        ROLEPACKS.SendRolePackRoleList()
        ROLEPACKS.ApplyRolePackConVars()
    end
end)

net.Receive("TTT_ApplyRolePack", function()
    local name = net.ReadString()
    GetConVar("ttt_role_pack"):SetString(name)
    ROLEPACKS.SendRolePackRoleList()
    ROLEPACKS.ApplyRolePackConVars()
end)

net.Receive("TTT_ClearRolePack", function()
    GetConVar("ttt_role_pack"):SetString("")
    ROLEPACKS.SendRolePackRoleList()
    ROLEPACKS.ApplyRolePackConVars()
end)

function ROLEPACKS.SendRolePackRoleList(ply)
    ROLE_PACK_ROLES = {}

    net.Start("TTT_SendRolePackRoleList")
    local name = GetConVar("ttt_role_pack"):GetString()
    local json = file.Read("rolepacks/" .. name .. "/roles.json", "DATA")
    if not json then
        net.WriteUInt(0, 8)
        net.Broadcast()
        return
    end

    local jsonTable = util.JSONToTable(json)
    if jsonTable == nil then
        ErrorNoHalt("Table decoding failed!\n")
        net.WriteUInt(0, 8)
        net.Broadcast()
        return
    end

    local roles = {}
    for _, slot in pairs(jsonTable.slots) do
        for _, roleslot in pairs(slot) do
            local role = ROLE_NONE
            for r = ROLE_INNOCENT, ROLE_MAX do
                if ROLE_STRINGS_RAW[r] == roleslot.role then
                    role = r
                    break
                end
            end
            if role ~= ROLE_NONE and not TableHasValue(roles, role) then
                TableInsert(roles, role)
            end
        end
    end

    net.WriteUInt(#roles, 8)
    for _, role in pairs(roles) do
        net.WriteUInt(role, 8)
        ROLE_PACK_ROLES[role] = true
    end
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

function ROLEPACKS.AssignRoles(choices)
    local rolePackName = GetConVar("ttt_role_pack"):GetString()
    if #rolePackName == 0 then return end

    local json = file.Read("rolepacks/" .. rolePackName .. "/roles.json", "DATA")
    if not json then
        ErrorNoHalt("No role pack named '" .. rolePackName .. "' found!\n")
        return
    end

    local jsonTable = util.JSONToTable(json)
    if not jsonTable then
        ErrorNoHalt("Table decoding failed!\n")
        return
    end

    local rolePackChoices = table.Copy(choices)
    local forcedRoles = {}
    for k, v in ipairs(rolePackChoices) do
        if v.forcedRole and v.forcedRole ~= ROLE_NONE then
            table.insert(forcedRoles, v.forcedRole)
            table.remove(rolePackChoices, k)
        end
    end

    local allowDuplicates = jsonTable.config.allowduplicates

    local chosenRoles = {}
    for _, slot in ipairs(jsonTable.slots) do
        if #rolePackChoices <= 0 then break end

        local possibleRoles = {}
        local skipSlot = false
        for _, roleslot in ipairs(slot) do
            local role = ROLE_NONE
            for r = ROLE_INNOCENT, ROLE_MAX do
                if ROLE_STRINGS_RAW[r] == roleslot.role then
                    role = r
                    break
                end
            end

            if role == ROLE_NONE then continue end

            if table.HasValue(forcedRoles, role) then
                table.RemoveByValue(forcedRoles, role)
                table.insert(chosenRoles, role)
                skipSlot = true
                break
            end

            if not allowDuplicates and table.HasValue(chosenRoles, role) then continue end

            for _ = 1, roleslot.weight do
                table.insert(possibleRoles, role)
            end
        end

        if skipSlot then continue end

        local ply = table.remove(rolePackChoices)
        if #possibleRoles <= 0 then continue end

        table.Shuffle(possibleRoles)
        local role = table.remove(possibleRoles)
        ply:SetRole(role)
        table.insert(chosenRoles, role)
    end

    ROLEPACKS.SendRolePackRoleList()
end

ROLEPACKS.OldConVars = {}

function ROLEPACKS.ApplyRolePackConVars()
    for cvar, value in pairs(ROLEPACKS.OldConVars) do
        GetConVar(cvar):SetString(value)
        ROLEPACKS.OldConVars[cvar] = nil
    end

    local rolePackName = GetConVar("ttt_role_pack"):GetString()
    if #rolePackName == 0 then return end

    local json = file.Read("rolepacks/" .. rolePackName .. "/convars.json", "DATA")
    if not json then
        ErrorNoHalt("No role pack named '" .. rolePackName .. "' found!\n")
        return
    end

    local jsonTable = util.JSONToTable(json)
    if not jsonTable then
        ErrorNoHalt("Table decoding failed!\n")
        return
    end

    local cvarsToChange = {}
    for _, v in ipairs(jsonTable.convars) do
        if not v.cvar or not v.value or v.cvar == "ttt_role_pack" then continue end
        local cvar = GetConVar(v.cvar)
        if cvar == nil then
            v.invalid = true
            continue
        else
            v.invalid = false
            local oldValue = cvar:GetString()
            local newValue = v.value
            if oldValue ~= newValue then
                cvarsToChange[v.cvar] = {oldValue = oldValue, newValue = newValue}
            end
        end
    end

    json = util.TableToJSON(jsonTable)
    if not json then
        ErrorNoHalt("Table encoding failed!\n")
        return
    end
    file.Write("rolepacks/" .. rolePackName .. "/convars.json", json)

    for cvar, value in pairs(cvarsToChange) do
        GetConVar(cvar):SetString(value.newValue)
        ROLEPACKS.OldConVars[cvar] = value.oldValue
    end
end

cvars.AddChangeCallback("ttt_role_pack", function(cvar, old, new)
    ROLEPACKS.SendRolePackRoleList()
    ROLEPACKS.ApplyRolePackConVars()
end)