local function IsValidPlayerEnt(ent)
    return ent and IsValid(ent) and ent:IsPlayer() and ent:Alive()
end

hook.Add("EntityTakeDamage", "Elementalist Effects", function(ent, dmginfo)
    local att = dmginfo:GetAttacker()

    if not IsValidPlayerEnt(ent) or not IsValidPlayerEnt(att) then
        return end
    end

    if not att:IsRole(ROLE_ELEMENTALIST) then
        return
    end

    -- Att is a valid elementalist damaging a valid player, begin rolling for effects below
    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_FROSTBITE) then
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_FROSTBITE_UP) then
            --Upgrade functionality
        else
            --Base functionality
        end
    end

    if att:HasEquipmentItem(EQUIP_ELEMENTALIST_PYROMANCER) then
        if att:HasEquipmentItem(EQUIP_ELEMENTALIST_PYROMANCER_UP) then
            --Upgrade functionality
        else
            --Base functionality
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