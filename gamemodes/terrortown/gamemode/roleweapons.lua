include("shared.lua")

local concommand = concommand
local net = net
local pairs = pairs
local table = table
local string = string

local StringStripExtension = string.StripExtension
local TableHasValue = table.HasValue
local TableInsert = table.insert

util.AddNetworkString("TTT_RoleWeaponsList")
util.AddNetworkString("TTT_RoleWeaponsCopy")
util.AddNetworkString("TTT_RoleWeaponsClean")
util.AddNetworkString("TTT_RoleWeaponsReload")

local function FindAndRemoveInvalidWeapons(tbl, invalidWeapons, printRemoval)
    local cleanTbl = {}
    for _, weaponName in ipairs(tbl) do
        if weapons.GetStored(weaponName) == nil and GetEquipmentItemByName(weaponName) == nil then
            TableInsert(invalidWeapons, weaponName)
            if printRemoval then
                print("[ROLEWEAPONS] Removing entry representing invalid weapon/equipment: " .. weaponName)
            end
        else
            TableInsert(cleanTbl, weaponName)
        end
    end
    return cleanTbl
end

local function ShowList()
    local roleFiles, _ = file.Find("roleweapons/*.json", "DATA")
    local invalidRoles = {}
    for _, fileName in pairs(roleFiles) do
        local name = StringStripExtension(fileName)
        if not TableHasValue(ROLE_STRINGS_RAW, name) then
            TableInsert(invalidRoles, name)
            continue
        end

        local roleBuyables = {}
        local roleExcludes = {}
        local roleNoRandoms = {}
        local roleLoadouts = {}
        local invalidWeapons = {}
        -- Load the lists from the JSON file for this role
        if file.Exists("roleweapons/" .. name .. ".json", "DATA") then
            local roleJson = file.Read("roleweapons/" .. name .. ".json", "DATA")
            if roleJson then
                local roleData = util.JSONToTable(roleJson)
                if roleData then
                    roleBuyables = roleData.Buyables or {}
                    roleExcludes = roleData.Excludes or {}
                    roleNoRandoms = roleData.NoRandoms or {}
                    roleLoadouts = roleData.Loadouts or {}
                end
            end
        end

        roleBuyables = FindAndRemoveInvalidWeapons(roleBuyables, invalidWeapons)
        roleExcludes = FindAndRemoveInvalidWeapons(roleExcludes, invalidWeapons)
        roleNoRandoms = FindAndRemoveInvalidWeapons(roleNoRandoms, invalidWeapons)
        roleLoadouts = FindAndRemoveInvalidWeapons(roleLoadouts, invalidWeapons)

        -- Print this role's information
        print("[ROLEWEAPONS] Configuration information for '" .. name .. "'")
        print("\tInclude:")
        for _, weaponName in ipairs(roleBuyables) do
            print("\t\t" .. weaponName)
        end

        print("\n\tExclude:")
        for _, weaponName in ipairs(roleExcludes) do
            print("\t\t" .. weaponName)
        end

        print("\n\tNo-Random:")
        for _, weaponName in ipairs(roleNoRandoms) do
            print("\t\t" .. weaponName)
        end

        print("\n\tLoadout:")
        for _, weaponName in ipairs(roleLoadouts) do
            print("\t\t" .. weaponName)
        end

        print("\n\tInvalid Weapons (files that don't match any installed weapon or equipment):")
        for _, weaponName in ipairs(invalidWeapons) do
            print("\t\t" .. weaponName)
        end
    end

    if #invalidRoles > 0 then
        print("\n[ROLEWEAPONS] Found " .. #invalidRoles .. " role folders that don't match any known role:")
        for _, role in ipairs(invalidRoles) do
            print("\t" .. role)
        end
    end
end
net.Receive("TTT_RoleWeaponsList", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to run Role Weapons commands\n")
        return
    end

    ShowList()
end)

local function Clean()
    local roleFiles, _ = file.Find("roleweapons/*.json", "DATA")
    for _, fileName in pairs(roleFiles) do
        local name = StringStripExtension(fileName)
        if not TableHasValue(ROLE_STRINGS_RAW, name) then
            print("[ROLEWEAPONS] Removing file representing invalid role: " .. fileName)
            file.Delete("roleweapons/" .. fileName, "DATA")
            continue
        end

        -- Load the lists from the JSON file for this role
        if file.Exists("roleweapons/" .. name .. ".json", "DATA") then
            local roleJson = file.Read("roleweapons/" .. name .. ".json", "DATA")
            local valid = true
            if roleJson then
                local roleData = util.JSONToTable(roleJson)
                if roleData then
                    roleData.Buyables = FindAndRemoveInvalidWeapons(roleData.Buyables or {}, {}, true)
                    roleData.Excludes = FindAndRemoveInvalidWeapons(roleData.Excludes or {}, {}, true)
                    roleData.NoRandoms = FindAndRemoveInvalidWeapons(roleData.NoRandoms or {}, {}, true)
                    roleData.Loadouts = FindAndRemoveInvalidWeapons(roleData.Loadouts or {}, {}, true)

                    -- Update the file with the cleaned tables
                    if #roleData.Buyables > 0 or #roleData.Excludes > 0 or #roleData.NoRandoms > 0 or #roleData.Loadouts > 0 then
                        roleJson = util.TableToJSON(roleData)
                        file.Write("roleweapons/" .. name .. ".json", roleJson)
                    else
                        valid = false
                    end
                else
                    valid = false
                end
            else
                valid = false
            end

            if not valid then
                print("[ROLEWEAPONS] Removing empty file: " .. fileName)
                file.Delete("roleweapons/" .. fileName, "DATA")
            end
        end
    end
end
net.Receive("TTT_RoleWeaponsClean", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to run Role Weapons commands\n")
        return
    end

    Clean()
end)

local function Reload()
    print("[ROLEWEAPONS] Reloading configuration...")

    -- Clear the weapon lists on all clients
    net.Start("TTT_ClearRoleWeapons")
    net.Broadcast()

    -- Use the common logic to clear the weapon lists and load it all again on the server
    WEPS.ClearWeaponsLists()
    WEPS.HandleRoleEquipment()
end
net.Receive("TTT_RoleWeaponsReload", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to run Role Weapons commands\n")
        return
    end

    Reload()
end)

local function Copy(from, to, overwrite)
    if not TableHasValue(ROLE_STRINGS_RAW, from) then
        print("[ROLEWEAPONS] No role named '" .. from .. "' found!")
        return
    end

    if not TableHasValue(ROLE_STRINGS_RAW, to) then
        print("[ROLEWEAPONS] No role named '" .. to .. "' found!")
        return
    end

    -- If the original role doesn't have a configuration
    if not file.Exists("roleweapons/" .. from .. ".json", "DATA") then
        -- We only have to do something if the new role DOES and we're overwriting
        if file.Exists("roleweapons/" .. to .. ".json", "DATA") then
            if overwrite then
                print("[ROLEWEAPONS] '" .. from .. "' does not have a configuration, but '" .. to .. "' does. Removing the '" .. to .. "' configuration.")
                file.Delete("roleweapons/" .. to .. ".json", "DATA")
                Reload()
            else
                print("[ROLEWEAPONS] '" .. from .. "' does not have a configuration, but '" .. to .. "' does and overwrite is disabled. Nothing to do.")
            end
        else
            print("[ROLEWEAPONS] Neither '" .. from .. "' nor '" .. to .. "' has a configuration. Nothing to do.")
        end
    else
        local fromJson = file.Read("roleweapons/" .. from .. ".json", "DATA")
        if not fromJson then
            ErrorNoHalt("[ROLEWEAPONS] Failed to load '" .. from .. "' configuration\n")
            return
        end

        print("[ROLEWEAPONS] Loaded the '" .. from .. "' configuration.")

        -- If we're overwriting, just delete the current config and copy the source
        if overwrite then
            print("[ROLEWEAPONS] Overwriting the '" .. to .. "' configuration.")
            if file.Exists("roleweapons/" .. to .. ".json", "DATA") then
                file.Delete("roleweapons/" .. to .. ".json", "DATA")
            end

            file.Write("roleweapons/" .. to .. ".json", fromJson)
        else
            local fromData = util.JSONToTable(fromJson)
            if not fromData then
                ErrorNoHalt("[ROLEWEAPONS] Failed to parse '" .. from .. "' configuration\n")
                return
            end

            local toJson = file.Read("roleweapons/" .. to .. ".json", "DATA")
            if not toJson then
                ErrorNoHalt("[ROLEWEAPONS] Failed to load '" .. to .. "' configuration\n")
                return
            end

            local toData = util.JSONToTable(toJson)
            if not toData then
                ErrorNoHalt("[ROLEWEAPONS] Failed to parse '" .. to .. "' configuration\n")
                return
            end

            print("[ROLEWEAPONS] Merging with the '" .. to .. "' configuration.")

            local toBuyables = toData.Buyables or {}
            for _, v in ipairs(fromData.Buyables or {}) do
                if not TableHasValue(toBuyables, v) then
                    TableInsert(toBuyables, v)
                end
            end

            local toExcludes = toData.Excludes or {}
            for _, v in ipairs(fromData.Excludes or {}) do
                if not TableHasValue(toExcludes, v) then
                    TableInsert(toExcludes, v)
                end
            end

            local toNoRandoms = toData.NoRandoms or {}
            for _, v in ipairs(fromData.NoRandoms or {}) do
                if not TableHasValue(toNoRandoms, v) then
                    TableInsert(toNoRandoms, v)
                end
            end

            local toLoadouts = toData.Loadouts or {}
            for _, v in ipairs(fromData.Loadouts or {}) do
                if not TableHasValue(toLoadouts, v) then
                    TableInsert(toLoadouts, v)
                end
            end

            toData.Buyables = toBuyables
            toData.Excludes = toExcludes
            toData.NoRandoms = toNoRandoms
            toData.Loadouts = toLoadouts

            toJson = util.TableToJSON(toData)

            print("[ROLEWEAPONS] Saving the '" .. to .. "' configuration.")
            file.Write("roleweapons/" .. to .. ".json", toJson)
        end
        Reload()
    end
end
net.Receive("TTT_RoleWeaponsCopy", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to run Role Weapons commands\n")
        return
    end

    local from = net.ReadString()
    local to = net.ReadString()
    local overwrite = net.ReadBit()
    Copy(from, to, overwrite)
end)

local function PrintHelp()
    print("ttt_roleweapons [OPTION]")
    print("If no options provided, default of 'open' will be used")
    print("\tclean\t-\tRemoves any invalid configurations. WARNING: This CANNOT be undone!")
    print("\tcopy FROM TO [REPLACE]\t-\tDuplicates a role configuration. If \"true\" is provided for the REPLACE parameter, any existing configuration will be removed")
    print("\tduplicate FROM TO [REPLACE]\t")
    print("\thelp\t-\tPrints this message")
    print("\topen\t-\tOpen the configuration dialog [CLIENT ONLY]")
    print("\tshow\t")
    print("\tlist\t-\tPrints the current configuration in the server console, highlighting anything invalid")
    print("\tprint\t")
    print("\treload\t-\tReloads the configurations from the server's filesystem")
end

concommand.Add("sv_ttt_roleweapons", function(ply, cmd, args)
    local method = #args > 0 and args[1] or "help"
    if method == "open" or method == "show" then
        ErrorNoHalt("ERROR: Command must be run inside client console\n")
    elseif method == "print" or method == "list" then
        ShowList()
    elseif method == "clean" then
        Clean()
    elseif method == "reload" then
        Reload()
    elseif method == "help" then
        PrintHelp()
    elseif method == "copy" or method == "duplicate" then
        local from = #args > 1 and args[2] or nil
        local to = #args > 2 and args[3] or nil
        local overwrite = #args > 2 and args[4] or "false"

        if not from or not to then
            ErrorNoHalt("ERROR: '" .. method .. "' command missing required parameter(s)!\n")
            return
        end

        Copy(from, to, string.lower(overwrite) == "true")
    else
        ErrorNoHalt("ERROR: Unknown command '" .. method .. "'\n")
    end
end)