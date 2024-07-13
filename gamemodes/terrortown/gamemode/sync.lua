util.AddNetworkString("TTT_SetPlayerProperty")
util.AddNetworkString("TTT_ClearPlayerProperty")

SYNC = {}

function SYNC:SetPlayerProperty(ply, propertyName, propertyValue, targets)
    ply[propertyName] = propertyValue

    net.Start("TTT_SetPlayerProperty")
    net.WritePlayer(ply)
    net.WriteString(propertyName)
    net.WriteType(propertyValue)
    if targets then
        net.Send(targets)
    else
        net.Broadcast()
    end
end

function SYNC:ClearPlayerProperty(ply, propertyName, targets)
    ply[propertyName] = nil

    net.Start("TTT_ClearPlayerProperty")
    net.WritePlayer(ply)
    net.WriteString(propertyName)
    if targets then
        net.Send(targets)
    else
        net.Broadcast()
    end
end