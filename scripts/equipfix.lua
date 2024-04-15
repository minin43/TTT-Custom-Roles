-- Put this script in the "garrysmod/lua/autorun" directory of your GMod install.

if engine.ActiveGamemode() ~= "terrortown" then return end

AddCSLuaFile()

if not CLIENT then return end

local hook = hook
local table = table

print("[EQUIPFIX] Loading...")

local function ApplyFixes()
    print("[EQUIPFIX] Applying fixes...")

    local searchToRemove = {"DoubleTapCorpseIcon", "JuggernogCorpseIcon", "PHDCorpseIcon", "SpeedColaCorpseIcon", "StaminupCorpseIcon", "BlueBullCorpseIcon", "TLHCorpseIcon", "ASCCorpseIcon", "SMCorpseIcon"}
    for _, h in ipairs(searchToRemove) do
        hook.Remove("TTTBodySearchEquipment", h)
    end
    hook.Remove("TTTBodySearchPopulate", "SMCorpseIcon")

    -- Zombie Perk Bottles by Hagen (https://steamcommunity.com/sharedfiles/filedetails/?id=842302491)
    if EQUIP_DOUBLETAP then
        print("[EQUIPFIX] Applying Double Tap fix...")
        hook.Add("TTTBodySearchEquipment", "EquipFix_DoubleTapCorpseIcon", function(search, eq)
            search.eq_doubletap = table.HasValue(eq, EQUIP_DOUBLETAP)
        end)
    end

    if EQUIP_JUGGERNOG then
        print("[EQUIPFIX] Applying Juggernog fix...")
        hook.Add("TTTBodySearchEquipment", "EquipFix_JuggernogCorpseIcon", function(search, eq)
            search.eq_juggernog = table.HasValue(eq, EQUIP_JUGGERNOG)
        end)
    end

    if EQUIP_PHD then
        print("[EQUIPFIX] Applying PHD Flopper fix...")
        hook.Add("TTTBodySearchEquipment", "EquipFix_PHDCorpseIcon", function(search, eq)
            search.eq_phd = table.HasValue(eq, EQUIP_PHD)
        end)
    end

    if EQUIP_SPEEDCOLA then
        print("[EQUIPFIX] Applying Speed Cola fix...")
        hook.Add("TTTBodySearchEquipment", "EquipFix_SpeedColaCorpseIcon", function(search, eq)
            search.eq_speedcola = table.HasValue(eq, EQUIP_SPEEDCOLA)
        end)
    end

    if EQUIP_STAMINUP then
        print("[EQUIPFIX] Applying Staminup fix...")
        hook.Add("TTTBodySearchEquipment", "EquipFix_StaminupCorpseIcon", function(search, eq)
            search.eq_staminup = table.HasValue(eq, EQUIP_STAMINUP)
        end)
    end

    -- Blue Bull by Hagen (https://steamcommunity.com/sharedfiles/filedetails/?id=653258161)
    if EQUIP_BLUE_BULL then
        print("[EQUIPFIX] Applying Blue Bull fix...")
        hook.Add("TTTBodySearchEquipment", "EquipFix_BlueBullCorpseIcon", function(search, eq)
            search.eq_bluebull = table.HasValue(eq, EQUIP_BLUE_BULL)
        end)
    end

    -- The Little Helper by Hagen (https://steamcommunity.com/sharedfiles/filedetails/?id=676695745)
    if EQUIP_TLH then
        print("[EQUIPFIX] Applying The Little Helper fix...")
        hook.Add("TTTBodySearchEquipment", "EquipFix_TLHCorpseIcon", function(search, eq)
            search.eq_tlh = table.HasValue(eq, EQUIP_TLH)
        end)
    end

    -- A Second Chance by Hagen (https://steamcommunity.com/sharedfiles/filedetails/?id=672173225)
    if EQUIP_ASC then
        print("[EQUIPFIX] Applying A Second Chance fix...")
        hook.Add("TTTBodySearchEquipment", "EquipFix_ASCCorpseIcon", function(search, eq)
            search.eq_asc = table.HasValue(eq, EQUIP_ASC)
        end)
    end

    -- Slowmotion by Hagen (https://steamcommunity.com/sharedfiles/filedetails/?id=611911370)
    if EQUIP_SM then
        print("[EQUIPFIX] Applying Slowmotion fix...")
        hook.Add("TTTBodySearchEquipment", "EquipFix_SMCorpseIcon", function(search, eq)
            search.eq_sm = table.HasValue(eq, EQUIP_SM)
        end)

        hook.Add("TTTBodySearchPopulate", "EquipFix_SMCorpseIcon", function(search, raw)
            if not raw.eq_sm then return end

            local highest = 0
            for _, v in pairs(search) do
                highest = math.max(highest, v.p)
            end

            search.eq_sm = {img = "vgui/ttt/slowmotion_icon", text = "They had a Slowmotion to manipulate the time.", p = highest + 1}
        end)
    end
end

hook.Add("TTTPrepareRound", "EquipFixHooks_Prepare", ApplyFixes)
hook.Add("TTTBeginRound", "EquipFixHooks_Prepare", ApplyFixes)
hook.Add("Initialize", "EquipFixHooks_Initialize", ApplyFixes)