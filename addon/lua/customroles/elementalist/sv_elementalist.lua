util.AddNetworkString("BeginIceScreen")
util.AddNetworkString("EndIceScreen")
util.AddNetworkString("BeginDimScreen")
util.AddNetworkString("EndDimScreen")

local function IsValidPlayerEnt(ent)
    return ent and IsValid(ent) and ent:IsPlayer() and ent:Alive()
end

local ChilledPlayers = {}
local IgnitedPlayers = {}
local BlindedPlayers = {}

hook.Add("TTTSpeedMultiplier", "Frostbite Effect", function(ply, mults)
    local effect = ChilledPlayers[ply:SteamID64()]

    if effect then
        table.Add(mults, effect)
    end
end)

hook.Add("EntityTakeDamage", "Elementalist Effects", function(ent, dmginfo)
    local att = dmginfo:GetAttacker()

    if not IsValidPlayerEnt(ent) or not IsValidPlayerEnt(att) or not dmginfo:IsBulletDamage() then
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
        local chance = math.random(20) == 1

        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_FROSTBITE_UP) and ChilledPlayers[vicId] and chance then
            --Upgrade functionality
            ChilledPlayers[vicId] = false
            ent:Freeze(true)

            net.Start("BeginIceScreen")
                net.WriteBool(true)
            net.Send(ent)
        else
            --Base fucntionality
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

        if not timer.Exists(vicId .. "_IsSlowed") then
            timer.Create(vicId .. "_IsSlowed", Timer, 1, EndFrostbite)
        else
            timer.Adjust(vicId .. "_IsSlowed", Timer, 1, EndFrostbite)
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_PYROMANCER) then
        local chance = math.random(20) == 1

        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_PYROMANCER_UP) and IgnitedPlayers[vicId] and chance then
            --Upgrade functionality
            local timerId = vicId .. "_IsBurningShotgunFix"
            if timer.Exists() then return end
            timer.Create(timerId, 0.1, 1, function()
                timer.Remove(timerId)
            end)

            local explosion = ents.Create( "env_explosion" )

            if IsValid(explosion) then
                IgnitedPlayers[vicId] = nil
                ent:Extinguish()

                explosion:SetPos(ent:GetPos())
                explosion:SetOwner(att)
                explosion:Spawn()
                explosion:SetKeyValue("iMagnitude", ent:Health() * 2)
                explosion:Fire("Explode", 0, 0)
                util.BlastDamage(explosion, att, ent:GetPos(), ent:Health() * 2, ent:Health()) 
            end
        else
            --Base functionality
            IgnitedPlayers[vicId] = true
            local timerID = vicId .. "_IsBurning"

            local timeToBurn = 1 + (4 * scale)

            if not timer.Exists(timerId) or timeToBurn > timer.TimeLeft(timerId)
            ent:Ignite(timeToBurn, 400 * scale)

            local function removeBurningStatus(ply)
                IgnitedPlayers[ply:SteamID64()] = false
                ply:Extinguish()
            end

            if timer.Exists(timerId) then
                timer.Adjust(timerId, timeToBurn, 1, removeBurningStatus(ent))
            else
                timer.Create(timerId, timeToBurn, 1, removeBurningStatus(ent))
            end
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_WINDBURN) then
        local chance = math.random(20) == 1

        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_WINDBURN_UP) and chance then
            --Upgrade functionality
        else
            --Base functionality
            dmginfo:SetDamageForce(1000 * scale) -- This really all this needs to be?
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_DISCHARGE) then
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_DISCHARGE_UP) then
            --Upgrade functionality
        else
            --Base functionality
            local edata = EffectData()
            if edata then -- Does this need to be sent to clients? It's ran in shared in weapon_ttt_stungun, where this is pulled from...
                edata:SetEntity(ent)
                edata:SetMagnitude(3)
                edata:SetScale(2)

                util.Effect("TeslaHitBoxes", edata)
            end

            local eyeang = ent:EyeAngles()
            if eyeang then
                local j = 10
                eyeang.pitch = math.Clamp(eyeang.pitch + math.Rand(-j, j), -90, 90)
                eyeang.yaw = math.Clamp(eyeang.yaw + math.Rand(-j, j), -90, 90)
                ent:SetEyeAngles(eyeang)
            end
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_MIDNIGHT) then
        local chance = math.random(20) == 1
        
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_MIDNIGHT_UP) and BlindedPlayers[vicId] and chance then
            --Upgrade functionality
            BlindedPlayers[vicId] = 100
        else
            --Base functionality
            BlindedPlayers[vicId] = BlindedPlayers[vicId] or 0
            BlindedPlayers[vicId] = math.Clamp(BlindedPlayers[vicId] + (40 * scale), 0, 50)            
        end

        net.Start("BeginDimScreen")
            net.WriteInt(BlindedPlayers[vidId])
        net.Send(ent)

        local function EndBlind()
            BlindedPlayers[vicId] = 0

            net.Start("EndDimScreen")
            net.Send(ent)
        end

        if not timer.Exists(vicId .. "_IsBlind") then
            timer.Create(vicId .. "_IsBlind", 2, 1, EndBlind)
        else
            timer.Adjust(vicId .. "_IsBlind", 2, 1, EndBlind)
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_LIFESTEAL) then
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_LIFESTEAL_UP) then
            --Upgrade functionality
        else
            --Base functionality
            local dmg = dmginfo:GetDamage()
            local healAmount = math.Round(dmg * 0.33, 0)

            att:SetHealth(math.Clamp(att:Health() + healAmount), 0, att:GetMaxHealth())
        end
    end
end)

-- Should I include a check to end all effects on a player death?