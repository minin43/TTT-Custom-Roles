net.Receive("TTT_SetPlayerProperty", function()
    local ply = net.ReadPlayer()
    if not IsPlayer(ply) then return end

    local propertyName = net.ReadString()
    local propertyValue = net.ReadType()

    ply[propertyName] = propertyValue
end)

net.Receive("TTT_ClearPlayerProperty", function()
    local ply = net.ReadPlayer()
    if not IsPlayer(ply) then return end

    local propertyName = net.ReadString()
    ply[propertyName] = nil
end)