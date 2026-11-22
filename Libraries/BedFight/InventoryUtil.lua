local cached = {}
local itemMeta = loadstring(shared.downloadFile('Libraries/BedFight/ItemMeta.lua'))()

local getToolType = function(item: string)
    if itemMeta[item] then
        return itemMeta[item].Class:lower()
    end
end

return {
    getInventory = function(plr: Player)
        if not plr then
            return
        end

        local Inv = plr.Backpack

        if not Inv then
            return
        end

        if not cached[plr.UserId] then
            cached[plr.UserId] = {}
        end

        table.clear(cached[plr.UserId])
        cached[plr.UserId] = {
            items = {},
            hand = nil,
        }

        for i, v in Inv:GetChildren() do
            table.insert(cached[plr.UserId].items, {
                tool = v,
                itemType = v.Name,
                toolType = getToolType(v.Name),
            })
        end

        for i, v in plr.Character:GetChildren() do
            if v:IsA('Model') and v:FindFirstChild('Handle') then
                cached[plr.UserId].hand = {
                    tool = v,
                    itemType = v.Name,
                    toolType = getToolType(v.Name),
                }

                table.insert(cached[plr.UserId].items, cached[plr.UserId].hand)
            end
        end

        return cached[plr.UserId]
    end,
    getToolType = getToolType
}