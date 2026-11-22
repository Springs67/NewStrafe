local Players = cloneref(game:GetService('Players'))
local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))

local lplr = Players.LocalPlayer

local Cached = {}
return {
    getInventory = function(plr: Player)
        if typeof(plr) ~= "Instance" then
            return warn('got non instance')
        end
        
        if not plr:IsA('Player') then
            return warn('got non player')
        end

        if not lplr.PlayerGui.PrivateInventory:FindFirstChild(plr.Name) then
            return
        end

        if not Cached[plr.UserId] then
            Cached[plr.UserId] = {
                items = {}
            }
        end
        table.clear(Cached[plr.UserId])

        Cached[plr.UserId].items = {}
        Cached[plr.UserId].armor = {}
        Cached[plr.UserId].hand = nil

        for _, value in lplr.PlayerGui.PrivateInventory:FindFirstChild(plr.Name):GetChildren() do
            table.insert(Cached[plr.UserId].items, {
                tool = value,
                itemType = value.Name,
                amount = value:GetAttribute('Amount'),
                itemSkin = value:GetAttribute('ItemSkin'),
                addedToBackpackTime = value:GetAttribute('AddedToBackpackTime'),
            })
        end

        for index = 0, 2 do
            local armInvItem = Players.LocalPlayer.Character:FindFirstChild('ArmorInvItem_'..index)

            if armInvItem and armInvItem.Value then
                table.insert(Cached[plr.UserId].armor, {
                    tool = armInvItem.Value,
                    itemType = armInvItem.Value.Name,
                    amount = armInvItem.Value:GetAttribute('Amount'),
                    itemSkin = armInvItem.Value:GetAttribute('ItemSkin'),
                    addedToBackpackTime = armInvItem.Value:GetAttribute('AddedToBackpackTime'),
                })
            end
        end

        local Hand = Players.LocalPlayer.Character:FindFirstChild('HandInvItem')

        if Hand and Hand.Value then
            Cached[plr.UserId].hand = {
                tool = Hand.Value,
                itemType = Hand.Value.Name,
                amount = Hand.Value:GetAttribute('Amount'),
                itemSkin = Hand.Value:GetAttribute('ItemSkin'),
                addedToBackpackTime = Hand.Value:GetAttribute('AddedToBackpackTime'),
            }
        end

        return Cached[plr.UserId]
    end,
    getToolType = function(itemMeta: {})
        if itemMeta.sword then
            return 'sword'
        elseif itemMeta.block then
            return 'block'
        elseif itemMeta.consumable then
            return 'consumable'
        else
            return 'none'
        end
    end,
}