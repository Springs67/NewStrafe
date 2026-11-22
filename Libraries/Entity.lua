local Players = cloneref(game:GetService("Players"))
local Entity = {
    Entities = {}
}

local entConnections = {}
function Entity:watchPlayer(plr: Player)
    local entData = {
        Player = plr,
        Model = plr.Character,
        Root = plr.Character and plr.Character.PrimaryPart or nil,
        Humanoid = plr.Character and plr.Character:FindFirstChild('Humanoid') or nil,
        Alive = Entity.getModelAlive(plr.Character),
    }

    table.insert(entConnections, plr.CharacterAdded:Connect(function(char)
        task.wait(0.01)
        char:WaitForChild('HumanoidRootPart')
        char:WaitForChild('Humanoid')

        entData.Model = char
        entData.Root = char.PrimaryPart
        entData.Humanoid = char.Humanoid

        local doStop = false
        char.Destroying:Once(function()
            doStop = true
        end)

        task.spawn(function()
            repeat
                task.wait()
                entData.Alive = Entity.getModelAlive(entData.Model)
            until doStop
        end)
    end))

    return entData
end

function Entity.getModelAlive(model: Model)
    if not model or not model.PrimaryPart or not model:FindFirstChild('Humanoid') or model.Humanoid.Health <= 0 then
        return false
    end

    return true
end

Entity.Self = Entity:watchPlayer(Players.LocalPlayer)

function Entity.init()
    for _, value in Players:GetPlayers() do
        if value == Players.LocalPlayer then
            continue
        end

        Entity.Entities[value.UserId] = Entity:watchPlayer(value)
    end

    Players.PlayerAdded:Connect(function(value: Player)
        Entity.Entities[value.UserId] = Entity:watchPlayer(value)
    end)
end

return Entity