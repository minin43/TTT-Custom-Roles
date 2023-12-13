util.AddNetworkString("BeginIceScreen")
util.AddNetworkString("EndIceScreen")

local function IsValidPlayerEnt(ent)
    return ent and IsValid(ent) and ent:IsPlayer() and ent:Alive()
end

local ChilledPlayers = {}
local LitPlayers = {}

hook.Add("TTTSpeedMultiplier", "Frostbite Effect", function(ply, mults)
    local effect = ChilledPlayers[ply:SteamID64()]

    if effect then
        table.Add(mults, effect)
    end
end)

hook.Add("EntityTakeDamage", "Elementalist Effects", function(ent, dmginfo)
    local att = dmginfo:GetAttacker()

    if not IsValidPlayerEnt(ent) or not IsValidPlayerEnt(att) or not dmginfi:IsBulletDamage() then
        return end
    end

    if not att:IsRole(ROLE_ELEMENTALIST) then
        return
    end

    -- Att is a valid elementalist damaging a valid player, begin rolling for effects below
    local attId = att:SteamID64()
    local vicId = ent:SteamID64()
    local damage = math.Clamp(damage, 1, 100)
    local scale = damage * 0.01

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_FROSTBITE) then
        local MovementSlow = math.Round(math.Clamp(20 + (scale * 20), 20, 40))
        local Timer = math.Round(math.Clamp(1 + scale, 1, 2), 1)

        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_FROSTBITE_UP) and ChilledPlayers[vicId] then
            ChilledPlayers[vicId] = false
            ent:Freeze(true)

            net.Start("BeginIceScreen")
                net.WriteBool(true)
            net.Send(ent)
        else
            ChilledPlayers[vicId] = 1 - (MovementSlow * 0.01)
            
            net.Start("BeginIceScreen")
                net.WriteBool(false)
            net.Send(ent)
        end

        local function EndFrostbite()
            ChilledPlayers[vicId] = false
            ent:Freeze(false)

            net.Start("EndIceScreen")
            net.Start(ent)
        end

        if not timer.Exists("frostbite_" .. vicId) then
            timer.Create("frostbite_" .. vicId, Timer, 1, EndFrostbite)
        else
            timer.Adjust("frostbite_" .. vicId, Timer, 1, EndFrostbite)
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_PYROMANCER) then
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_PYROMANCER_UP) then
            --Upgrade functionality
        else
            --Base functionality
            LitPlayers[vicId] = true

            local timeToBurn = 1 + (3 * scale)
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_WINDBURN) then
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_WINDBURN_UP) then
            --Upgrade functionality
        else
            --Base functionality
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_DISCHARGE) then
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_DISCHARGE_UP) then
            --Upgrade functionality
        else
            --Base functionality
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_MIDNIGHT) then
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_MIDNIGHT_UP) then
            --Upgrade functionality
        else
            --Base functionality
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_LIFESTEAL) then
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_LIFESTEAL_UP) then
            --Upgrade functionality
        else
            --Base functionality
        end
    end
end)