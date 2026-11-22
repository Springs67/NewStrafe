local Players = cloneref(game:GetService("Players"))
local Lighting = cloneref(game:GetService("Lighting"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TextService = cloneref(game:GetService("TextService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local CollectionService = cloneref(game:GetService("CollectionService"))

local lplr = Players.LocalPlayer
local gameCamera = workspace.CurrentCamera

local GuiLibrary = shared.GuiLibrary
local downloadFile = shared.downloadFile
local Entity = shared.Entity

local GameUtil = loadstring(downloadFile('Libraries/Bedwars/GameUtil.lua'))()

local Bedwars = {
    ItemMeta = HttpService:JSONDecode(downloadFile('Libraries/Bedwars/ItemMeta.json')).items,
    ProjectileMeta = HttpService:JSONDecode(downloadFile('Libraries/Bedwars/ProjectileMeta.json')),
    InventoryUtil = loadstring(downloadFile('Libraries/Bedwars/InventoryUtil.lua'))(),

    IdUtil = loadstring(downloadFile('Libraries/Bedwars/IdUtil.lua'))().IdUtil,
    SoundUtil = GameUtil.SoundUtil,
    AnimationUtil = GameUtil.AnimationUtil,
}

local swords = {}
for index, value in Bedwars.ItemMeta do
    if value.sword then
        swords[index] = value
    end
end

local itemProjs = {
	['wood_bow'] = 'arrow',
	['wood_crossbow'] = 'crossbow_arrow',
	['tactical_crossbow'] = 'tactical_crossbow_arrow',
	['snowball'] = 'snowball',
    ['fireball'] = 'fireball',
    ['telepearl'] = 'telepearl'
}

local blockPrios = {
    ['wool'] = {Priority = 1},
    ['plank'] = {Priority = 2},
    ['stone'] = {Priority = 3},
    ['blastproof'] = {Priority = 4},
    ['ceramic'] = {Priority = 5},
}

local blockFaces = {
    ['wool_green'] = 'rbxassetid://16991768151',
    ['wool_blue'] = 'rbxassetid://16991767991',
    ['wool_brown'] = 'rbxassetid://15380238175',
    ['wool_cyan'] = 'rbxassetid://16991768048',
    ['wool_orange'] = 'rbxassetid://16991768271',
    ['wool_pink'] = 'rbxassetid://16991768418',
    ['wool_purple'] = 'rbxassetid://7923578873',
    ['wool_red'] = 'rbxassetid://16991768524',
    ['wool_white'] = 'rbxassetid://16991768606',
    ['wool_yellow'] = 'rbxassetid://16991768659',
    ['stone_brick'] = 'rbxassetid://16991767326',
    ['wood_plank_oak'] = 'rbxassetid://16991767868',
    ['ceramic'] = 'rbxassetid://16991765474',
}

local StatusEffect = Entity.Self.Player:WaitForChild('PlayerGui'):WaitForChild('StatusEffectHudScreen', 15):WaitForChild('StatusEffectHud', 15)
local getSpeedMultiplier = function()
    local multi = 1;

    if Entity.Self.Model:FindFirstChild('dodo_bird') then
        multi += 0.5;
    end

    if Entity.Self.Model:GetAttribute('SpeedBoost') then
        multi += Entity.Self.Model:GetAttribute('SpeedBoost') - 1
    end

    if Entity.Self.Model:GetAttribute('SpeedPieBuff') then
        multi += 0.2;
    end

    if StatusEffect:FindFirstChild('WindWalkerEffect') then
        local val = tonumber(StatusEffect:FindFirstChild('WindWalkerEffect').EffectStack.Text)

        multi += (val / 5)
    end

    return multi;
end

local node_modules = ReplicatedStorage:WaitForChild('rbxts_include'):WaitForChild('node_modules')
local Default = node_modules:WaitForChild('@rbxts'):WaitForChild('net'):WaitForChild('out'):WaitForChild('_NetManaged')
local BlockDefault = node_modules:WaitForChild('@easy-games'):WaitForChild('block-engine'):WaitForChild('node_modules'):WaitForChild('@rbxts'):WaitForChild('net'):WaitForChild('out'):WaitForChild('_NetManaged')

Bedwars.Remotes = {
    -- Combat
    SwordHit = Default:WaitForChild('SwordHit'),
    SwordSwingMiss = Default:WaitForChild('SwordSwingMiss'),
    ProjectileFire = Default:WaitForChild('ProjectileFire'),

    -- Block
    DamageBlock = BlockDefault:WaitForChild('DamageBlock'),
    PlaceBlock = BlockDefault:WaitForChild('PlaceBlock'),
    SetObservedChest = Default:WaitForChild('Inventory/SetObservedChest'),
    ChestGetItem = Default:WaitForChild('Inventory/ChestGetItem'),

    -- Misc
    PickupItemDrop = Default:WaitForChild('PickupItemDrop'),
    StartConsume = Default:WaitForChild('StartConsume'),
    ConsumeItem = Default:WaitForChild('ConsumeItem'),
    SetInvItem = Default:WaitForChild('SetInvItem'),
    Emote = Default:WaitForChild('Emote'),
    
    -- NoSlow
    TriggerInvisibleLandmine = Default:WaitForChild('TriggerInvisibleLandmine'),
    --StepOnSnapTrap = Default:WaitForChild('StepOnSnapTrap'),
    StepOnSpiderWeb = Default:WaitForChild('StepOnSpiderWeb'),
}

Bedwars.Inventory = {}
task.spawn(function()
    repeat
        task.wait(0.25)
        Bedwars.Inventory = Bedwars.InventoryUtil.getInventory(lplr)
    until not GuiLibrary
end)

local ignoreSwitch = false
local switchHand = function(tool: Instance, back: boolean, delay: number)
    if ignoreSwitch then
        return false
    end

    if not lplr.Character or not lplr.Character:FindFirstChild('HandInvItem') then
        return false
    end

    if lplr.Character.HandInvItem.Value ~= tool then
        local old = lplr.Character.HandInvItem.Value
        Bedwars.Remotes.SetInvItem:InvokeServer({
            hand = tool
        })

        if back then
            task.delay(delay, function()
                Bedwars.Remotes.SetInvItem:InvokeServer({
                    hand = old
                })
            end)
        end
    end

    return true
end

local hasItem = function(Name: string)
    for _, value in Bedwars.Inventory.items do
        if value.itemType == Name then
            return true
        end
    end

    return false
end

local getItem = function(Name: string)
    for _, value in Bedwars.Inventory.items do
        if value.itemType == Name then
            return value
        end
    end

    return nil
end

local getRelativeItem = function(Name: string)
    for _, value in Bedwars.Inventory.items do
        if value.itemType:lower():find(Name:lower()) then
            return value
        end
    end

    return nil
end

local bows = {}
local getBows = function(snowballEnabled)
    table.clear(bows)

    for _, value in Bedwars.Inventory.items do
        if value.itemType:lower():find('bow') or (snowballEnabled and value.itemType:lower():find('snowball') or false) then
            table.insert(bows, value)
        end
    end
    
    return bows
end

local getPlaceableBlock = function()
    local currBlock, blockPrio = nil, math.huge;

    for index, value in blockPrios do
        local item = getRelativeItem(index);

        if item and value.Priority < blockPrio then
            currBlock = item;
        end
    end

    return currBlock
end

local getServerPos = function(vec3)
    return Vector3.new(
        math.round(vec3.X / 3),
        math.round(vec3.Y / 3),
        math.round(vec3.Z / 3)
    )
end

local getClientPos = function(vec3)
    local X = math.floor(vec3.X / 3 + 0.5) * 3
    local Y = math.floor(vec3.Y / 3 + 0.5) * 3
    local Z = math.floor(vec3.Z / 3 + 0.5) * 3

    return Vector3.new(X, Y, Z)
end

local placeClientBlock = function(pos, item: string)
    local Part = Instance.new('Part')
    Part.Parent = workspace
    Part.Size = Vector3.new(2.999, 2.999, 2.999)
    Part.Transparency = 0
    Part.CanCollide = true
    Part.CanQuery = false
    Part.CanTouch = false
    Part.Anchored = true
    Part.CFrame = CFrame.new(pos)
    Part.Color = Color3.fromRGB(255, 255, 255)
    Part.Material = Enum.Material.Fabric
    Part.MaterialVariant = blockFaces[item] or ''

    task.delay(0.5, function()
        Part:Destroy()
    end)
end

local fireProjectile = function(bow: {}, resource: string, direction: Vector3)
    return Bedwars.Remotes.ProjectileFire:InvokeServer(
        bow.tool,
        resource,
        itemProjs[bow.itemType],
        Entity.Self.Model.Head.Position,
        Entity.Self.Model.Head.Position,
        direction,
        Bedwars.IdUtil.generateId(8),
        {
            shotId = Bedwars.IdUtil.generateId(8),
            drawDurationSec = 3,
        },
        workspace:GetServerTimeNow()
    )
end

local getNearestAttackable = function(Range: number)
    local nearestEnt, nearestDist = nil, math.huge

    for _, value in CollectionService:GetTagged('entity') do
        if value == Entity.Self.Model then
            continue
        end

        if not Entity.getModelAlive(value) then
            continue
        end

        if (value:GetAttribute('Team') == Entity.Self.Player:GetAttribute('Team')) then
            continue
        end

        if value:GetAttribute('PetrifyId') or value:FindFirstChild('ForceField') then
            continue
        end

        local Dist = Entity.Self.Player:DistanceFromCharacter(value.PrimaryPart.CFrame.Position)

        if Dist <= Range and Dist < nearestDist then
            nearestDist = Dist
            nearestEnt = value
        end
    end

    return nearestEnt
end

local getNearestMouseAttackable = function(Range: number)
    local nearestEnt, nearestDist, nearestDist2 = nil, math.huge, math.huge

    for _, value in CollectionService:GetTagged('entity') do
        if value == Entity.Self.Model then
            continue
        end

        if not Entity.getModelAlive(value) then
            continue
        end

        if (value:GetAttribute('Team') == Entity.Self.Player:GetAttribute('Team')) then
            continue
        end

        if value:GetAttribute('PetrifyId') or value:FindFirstChild('ForceField') then
            continue
        end

        local screenPos, onScreen = gameCamera:WorldToViewportPoint(value.PrimaryPart.Position)

        if onScreen and screenPos.Z > 0 then
            local playerPos = Vector2.new(screenPos.X, screenPos.Y)

            local distance = (UserInputService:GetMouseLocation() - playerPos).Magnitude
            local distance2 = Entity.Self.Player:DistanceFromCharacter(value.PrimaryPart.Position)

            if distance < nearestDist and distance <= Range then
                nearestDist = distance
                nearestDist2 = distance2
                nearestEnt = value;
            end
        end
    end

    return nearestEnt, nearestDist2
end

local getBestWeapon = function()
    local bestWeapon, bestDamage = nil, 0

    for index, value in swords do
        if hasItem(index) and value.sword.damage > bestDamage then
            bestWeapon = getItem(index)
            bestDamage = value.sword.damage
        end
    end

    return bestWeapon
end

local getCloserPosition = function(pos1, pos2, amount)
    return (pos2 - pos1).Unit * math.min(amount, (pos2 - pos1).Magnitude) + pos1
end

local getRandomizedVec3 = function()
    return Vector3.new(math.random() * (AuraRandomization.Value / 5), math.random() * (AuraRandomization.Value / 5), math.random() * (AuraRandomization.Value / 5))
end

local Flight

local newBlockAnims = {
    ['Strafe'] = {
        {CFrame = CFrame.Angles(20, 90, -50), Timer = 0.15},
        {CFrame = CFrame.Angles(0, 90, -50), Timer = 0.15},
    },
}

local Viewmodel = gameCamera:WaitForChild('Viewmodel')
local oldC0 = Viewmodel.RightHand.RightWrist.C0
local SilentAura; SilentAura = GuiLibrary:registerModule({
    ['Name'] = 'Silent Aura',
    ['Window'] = 'Combat',
    ['ArrayText'] = function()
        return AuraRange.Value
    end,
    ['Callback'] = function(callback)
        if callback then
            local Attacking = false
            local lastAttack = workspace:GetServerTimeNow()
            local lastHitSent = workspace:GetServerTimeNow()
            SilentAura:Recycle(Viewmodel.Humanoid.AnimationPlayed:Connect(function(anim: AnimationTrack)
                if (anim.Animation.AnimationId == 'rbxassetid://8089691925') and Attacking and (CustomAnimations.Value ~= 'None') then
                    anim:Stop()
                end
            end))

            task.spawn(function()
                repeat
                    task.wait()

                    if Attacking and CustomAnimations.Value ~= 'None' then
                        for _, v in newBlockAnims[CustomAnimations.Value] do
                            TweenService:Create(Viewmodel.RightHand.RightWrist, TweenInfo.new(v.Timer), {
                                C0 = oldC0 * v.CFrame + Vector3.new(1, -0.75, 0)
                            }):Play()
                            task.wait(v.Timer)
                        end
                    else
                        TweenService:Create(Viewmodel.RightHand.RightWrist, TweenInfo.new(0.4), {
                            C0 = oldC0
                        }):Play()
                    end
                until not SilentAura.Enabled
            end)

            SilentAura:Recycle(function()
                RunService:UnbindFromRenderStep('Silent Aura')
            end)

            RunService:BindToRenderStep('Silent Aura', 999, function(dt: number)
                if not Entity.Self.Alive then
                    return
                end

                if HoldItemCheck.Enabled then
                    if not Bedwars.Inventory.hand then
                        return
                    end
                    
                    if not Bedwars.ItemMeta[Bedwars.Inventory.hand.itemType].sword then
                        return
                    end
                end

                local Nearest = getNearestAttackable(AuraRange.Value)

                Attacking = (Nearest ~= nil)

                if Nearest then
                    if (workspace:GetServerTimeNow() - lastAttack) < 0.11111112 or (workspace:GetServerTimeNow() - lastHitSent) < 0.2858 then
                        return
                    end

                    local fovNearest = getNearestMouseAttackable(AuraFieldOfView.Value)

                    if AuraFieldOfView.Value ~= 360 and not fovNearest then
                        return
                    end

                    local Weapon = getBestWeapon()

                    if not Weapon then
                        return
                    end

                    if PlaySwingAnim.Enabled then
                        Bedwars.AnimationUtil.playAnimation('SWORD_SWING')
                        Bedwars.AnimationUtil.playAnimation('FP_SWING_SWORD', Viewmodel.Humanoid)
                    end

                    if PlaySwingSound.Enabled then
                        Bedwars.SoundUtil.playSound('SWORD_SWING_'..tostring(math.random(1, 2)))
                    end

                    if math.random(0, 100) <= AuraMissChance.Value then
                        Bedwars.Remotes.SwordSwingMiss:FireServer({
                            weapon = Weapon,
                            chargeRatio = 0,
                        })

                        lastAttack = workspace:GetServerTimeNow()
                        return
                    end

                    task.spawn(switchHand, Weapon.tool)

                    Bedwars.Remotes.SwordHit:FireServer({
                        weapon = Weapon.tool,
                        chargedAttack = {chargeRatio = 0},
                        entityInstance = Nearest,
                        validate = {
                            targetPosition = {value = getCloserPosition(Nearest.PrimaryPart.Position, Entity.Self.Root.Position + (Entity.Self.Root.AssemblyLinearVelocity * 0.06), 2) + getRandomizedVec3()},
                            selfPosition = {value = getCloserPosition(Entity.Self.Root.Position, Nearest.PrimaryPart.Position, AuraRange.Value - 14)}
                        }
                    })

                    lastHitSent = workspace:GetServerTimeNow()
                    lastAttack = workspace:GetServerTimeNow()
                end
            end)

            --[[repeat
                task.wait()
                if not Entity.Self.Alive then
                    continue
                end

                if HoldItemCheck.Enabled then
                    if not Bedwars.Inventory.hand then
                        continue
                    end
                    
                    if not Bedwars.ItemMeta[Bedwars.Inventory.hand.itemType].sword then
                        continue
                    end
                end

                local Nearest = getNearestAttackable(AuraRange.Value)

                Attacking = (Nearest ~= nil)

                if Nearest then
                    local fovNearest = getNearestMouseAttackable(AuraFieldOfView.Value)

                    if AuraFieldOfView.Value ~= 360 and not fovNearest then
                        continue
                    end

                    local Weapon = getBestWeapon()

                    if not Weapon then
                        continue
                    end

                    if PlaySwingAnim.Enabled then
                        Bedwars.AnimationUtil.playAnimation('SWORD_SWING')
                        Bedwars.AnimationUtil.playAnimation('FP_SWING_SWORD', Viewmodel.Humanoid)
                    end

                    if PlaySwingSound.Enabled then
                        Bedwars.SoundUtil.playSound('SWORD_SWING_'..tostring(math.random(1, 2)))
                    end

                    if math.random(0, 100) <= AuraMissChance.Value then
                        Bedwars.Remotes.SwordSwingMiss:FireServer({
                            weapon = Weapon,
                            chargeRatio = 0,
                        })

                        task.wait(AuraDelay.Value + (math.random() / 45))
                        continue
                    end

                    task.spawn(switchHand, Weapon.tool)

                    Bedwars.Remotes.SwordHit:FireServer({
                        weapon = Weapon.tool,
                        chargedAttack = {chargeRatio = 0},
                        entityInstance = Nearest,
                        validate = {
                            targetPosition = {value = getCloserPosition(Nearest.PrimaryPart.Position, Entity.Self.Root.Position + (Entity.Self.Root.AssemblyLinearVelocity * 0.06), 2) + getRandomizedVec3()},
                            selfPosition = {value = getCloserPosition(Entity.Self.Root.Position, Nearest.PrimaryPart.Position, AuraRange.Value - 14)}
                        }
                    })

                    task.wait(AuraDelay.Value + (math.random() / 45))
                end
            until not SilentAura.Enabled]]
        end
    end
})
AuraRange = SilentAura:registerSlider({
    ['Name'] = 'Range',
    ['Step'] = 1,
    ['Minimum'] = 10,
    ['Maximum'] = 20,
    ['Default'] = 18,
})
--[[AuraDelay = SilentAura:registerSlider({
    ['Name'] = 'Delay',
    ['Step'] = 0.005,
    ['Minimum'] = 0,
    ['Maximum'] = 0.5,
    ['Default'] = 0.285,
})]]
AuraMissChance = SilentAura:registerSlider({
    ['Name'] = 'Miss Chance (%)',
    ['Step'] = 1,
    ['Minimum'] = 0,
    ['Maximum'] = 100,
    ['Default'] = 8,
})
AuraFieldOfView = SilentAura:registerSlider({
    ['Name'] = 'Field Of View',
    ['Step'] = 1,
    ['Minimum'] = 0,
    ['Maximum'] = 360,
    ['Default'] = 360,
})
AuraRandomization = SilentAura:registerSlider({
    ['Name'] = 'Randomization Value',
    ['Step'] = 0.5,
    ['Minimum'] = 0,
    ['Maximum'] = 5,
    ['Default'] = 1,
})
AutoSwitch = SilentAura:registerToggle({
    ['Name'] = 'Switch To Weapon'
})
HoldItemCheck = SilentAura:registerToggle({
    ['Name'] = 'Hand Check'
})
DoRotations = SilentAura:registerToggle({
    ['Name'] = 'Rotations'
})
PlaySwingAnim = SilentAura:registerToggle({
    ['Name'] = 'Play Animation'
})
PlaySwingSound = SilentAura:registerToggle({
    ['Name'] = 'Play Sound'
})
CustomAnimations = SilentAura:registerSelector({
    ['Name'] = 'Animations',
    ['Values'] = {'None', 'Strafe'}
})

local getPredVal = function(bowName: string)
    if bowName == 'wood_bow' then
        return 7
    elseif bowName == 'snowball' then
        return 100
    else
        return 9
    end
end

local function predictPos(char)
    return (char.Position) + (char.AssemblyLinearVelocity * 0.06) :: Vector3
end
local function predictDir(char, bow: string)
    return -(Entity.Self.Root.Position - predictPos(char)).Unit * 200 + Vector3.new(0, (Entity.Self.Player:DistanceFromCharacter(predictPos(char))) / getPredVal(bow), 0)
end

local projDelay = {
    ['snowball'] = 0.1,
    ['wood_bow'] = 0.6,
    ['wood_crossbow'] = 1.2,
    ['tactical_crossbow'] = 1.2,
}

local lastProjDelays = {}
ProjectileAura = GuiLibrary:registerModule({
    ['Name'] = 'Projectile Aura',
    ['Window'] = 'Combat',
    ['Callback'] = function(callback)
        if callback then
            repeat
                task.wait()
                if not Entity.Self.Alive then
                    continue
                end

                local Nearest = getNearestAttackable(ProjRange.Value)

                if Nearest then
                    local Bows = getBows(Snowballs.Enabled)

                    if #Bows > 0 then
                        for _, value in Bows do
                            if not lastProjDelays[value.itemType] then
                                lastProjDelays[value.itemType] = tick()
                            end

                            if (tick() - lastProjDelays[value.itemType]) < projDelay[value.itemType] then
                                continue
                            end

                            local itemData = Bedwars.ItemMeta[value.itemType]

                            if not itemData or not itemData.projectileSource then
                                continue
                            end

                            switchHand(value.tool)
                            fireProjectile(value, (value.itemType:lower():find('bow') and 'arrow' or 'snowball'), predictDir(Nearest.PrimaryPart, value.itemType))
                            lastProjDelays[value.itemType] = tick()
                            
                            task.wait(0.2)
                        end
                    end
                end
            until not ProjectileAura.Enabled
        end
    end
})
Snowballs = ProjectileAura:registerToggle({
    ['Name'] = 'Snowballs'
})
ProjRange = ProjectileAura:registerSlider({
    ['Name'] = 'Range',
    ['Minimum'] = 10,
    ['Maximum'] = 100,
    ['Default'] = 50,
})

UICleanup = GuiLibrary:registerModule({
    ['Name'] = 'UI Cleanup',
    ['Window'] = 'Visual',
    ['Callback'] = function(callback)
        if callback then
            Entity.Self.Player.PlayerGui:WaitForChild('KillFeedGui').Enabled = not KillFeed.Enabled
            Entity.Self.Player.PlayerGui:WaitForChild('TopBarStatsGui').Enabled = not RemoveTopRight.Enabled
            Entity.Self.Player.PlayerGui:WaitForChild('TopBarAppGui').Enabled = not RemoveTopRight.Enabled
            Entity.Self.Player.PlayerGui:WaitForChild('ActionBarScreenGui').Enabled = not RemoveActionbar.Enabled
        else
            Entity.Self.Player.PlayerGui:WaitForChild('KillFeedGui').Enabled = true
            Entity.Self.Player.PlayerGui:WaitForChild('TopBarStatsGui').Enabled = true
            Entity.Self.Player.PlayerGui:WaitForChild('TopBarAppGui').Enabled = true
            Entity.Self.Player.PlayerGui:WaitForChild('ActionBarScreenGui').Enabled = true
        end
    end
})
KillFeed = UICleanup:registerToggle({
    ['Name'] = 'Disable Feed',
    ['Callback'] = function(callback)
        if UICleanup.Enabled then
            Entity.Self.Player.PlayerGui:WaitForChild('KillFeedGui').Enabled = not callback
        end
    end
})
RemoveTopRight = UICleanup:registerToggle({
    ['Name'] = 'Disable Top Right',
    ['Callback'] = function(callback)
        if UICleanup.Enabled then
            Entity.Self.Player.PlayerGui:WaitForChild('TopBarStatsGui').Enabled = not callback
            Entity.Self.Player.PlayerGui:WaitForChild('TopBarAppGui').Enabled = not callback
        end
    end
})
RemoveActionbar = UICleanup:registerToggle({
    ['Name'] = 'Disable Action Bar',
    ['Callback'] = function(callback)
        if UICleanup.Enabled then
            Entity.Self.Player.PlayerGui:WaitForChild('ActionBarScreenGui').Enabled = not callback
        end
    end
})

Stealer = GuiLibrary:registerModule({
    ['Name'] = 'Stealer',
    ['Window'] = 'Player',
    ['Callback'] = function(callback)
        if callback then
            repeat
                task.wait(0.05)
                for _, chest in CollectionService:GetTagged('chest') do
                    if not chest:FindFirstChild('ChestFolderValue') or not chest.ChestFolderValue.Value then
                        continue
                    end

                    local Dist = Entity.Self.Player:DistanceFromCharacter(chest.Position)

                    if Dist <= 11 then
                        task.spawn(function()
                            Bedwars.Remotes.SetObservedChest:FireServer(chest.ChestFolderValue.Value)

                            task.wait(0.05)

                            for _, accessory in chest.ChestFolderValue.Value:GetChildren() do
                                if not accessory:IsA('Accessory') then
                                    continue
                                end

                                task.spawn(function()
                                    Bedwars.Remotes.ChestGetItem:InvokeServer(
                                        chest.ChestFolderValue.Value,
                                        accessory
                                    )
                                end)

                                task.wait(math.random(1, 10) / 100)
                            end

                            task.wait(0.05)
                            Bedwars.Remotes.SetObservedChest:FireServer(nil)
                        end)
                    end
                end
            until not Stealer.Enabled
        end
    end
})

Scaffold = GuiLibrary:registerModule({
    ['Name'] = 'Scaffold Walk',
    ['Window'] = 'Player',
    ['Callback'] = function(callback)
        if callback then
            local lastPlayed = tick()
            repeat
                task.wait()
                if not Entity.Self.Alive then
                    continue
                end

                local Block = getPlaceableBlock()

                if Block then
                    local opos = Entity.Self.Root.CFrame.Position - Vector3.new(0, 4, 0) + Entity.Self.Humanoid.MoveDirection * 3
                    local moveDirection = Entity.Self.Humanoid.MoveDirection
                    local pos = getServerPos(opos)

                    if moveDirection.Magnitude ~= 0 and (tick() - lastPlayed) > 0.2 then
                        Bedwars.AnimationUtil.playAnimation('PLACE_BLOCK')
                        Bedwars.SoundUtil.playSound('GENERIC_BLOCK_PLACE')
                        lastPlayed = tick()
                    end

                    if ScaffoldAutohotbar.Enabled then
                        task.spawn(switchHand, Block.tool)
                    end

                    task.spawn(function()
                        placeClientBlock(getClientPos(opos), Block.itemType)
                        Bedwars.Remotes.PlaceBlock:InvokeServer({
                            ['blockType'] = Block.itemType,
                            ['blockData'] = 0,
                            ['position'] = pos
                        })
                    end)

                    if math.abs(moveDirection.X) > 0.1 and math.abs(moveDirection.Z) > 0.1 then
                        task.wait(0.05)
                    else
                        task.wait(0.05)
                    end
                end
            until not Scaffold.Enabled
        end
    end
})
ScaffoldAutohotbar = Scaffold:registerToggle({
    ['Name'] = 'Auto Switch'
})

NoFall = GuiLibrary:registerModule({
    ['Name'] = 'No Fall',
    ['Window'] = 'Player',
    ['Callback'] = function(callback)
        if callback then
            repeat
                task.wait()
                if not Entity.Self.Alive or Longjump.Enabled or (Flight.Enabled and FlightMode.Value ~= 'Heatseeker') or not Entity.Self.Humanoid or not Entity.Self.Root or not Entity.Self.Model then
                    continue
                end

                if not Entity.Self.Root then
                    continue
                end

                if Entity.Self.Root.AssemblyLinearVelocity.Y < -25 then
                    local oldY = Entity.Self.Root.AssemblyLinearVelocity.Y
                    Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(Entity.Self.Root.AssemblyLinearVelocity.X, 1, Entity.Self.Root.AssemblyLinearVelocity.Z)
                    lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                    RunService.PreAnimation:Wait()
                    Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(Entity.Self.Root.AssemblyLinearVelocity.X, oldY, Entity.Self.Root.AssemblyLinearVelocity.Z)
                end
            until not NoFall.Enabled
        end
    end
})

Speed = GuiLibrary:registerModule({
    ['Name'] = 'Speed',
    ['Window'] = 'Movement',
    ['ArrayText'] = function()
        return SpeedMode.Value
    end,
    ['Callback'] = function(callback)
        if callback then
            local lastBoost = tick() - 1
            local currentSpeed = 20;
            RunService:BindToRenderStep('Speed', 9999, function(dt: number)
                if not Entity.Self.Alive or Longjump.Enabled then
                    return
                end

                if SpeedMode.Value == 'Stable' then
                    currentSpeed = 21
                elseif SpeedMode.Value == 'Boost' then
                    if (tick() - lastBoost) > 1.2 then
                        currentSpeed = 25
                        lastBoost = tick()
                    elseif currentSpeed > 18 then
                        currentSpeed -= dt * 5
                    end
                end

                local MoveDir = Entity.Self.Humanoid.MoveDirection
                local MoveSpeed = Entity.Self.Humanoid.WalkSpeed

                local Expected = ((currentSpeed * getSpeedMultiplier()) - MoveSpeed)

                Entity.Self.Root.CFrame += (Expected * MoveDir * dt)
                Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(MoveDir.X * MoveSpeed, Entity.Self.Root.AssemblyLinearVelocity.Y, MoveDir.Z * MoveSpeed)
            end)
        else
            RunService:UnbindFromRenderStep('Speed')
        end
    end
})
SpeedMode = Speed:registerSelector({
    ['Name'] = 'Mode',
    ['Values'] = {'Stable', 'Boost'}
})

Longjump = GuiLibrary:registerModule({
    ['Name'] = 'Longjump',
    ['Window'] = 'Movement',
    ['ArrayText'] = function()
        return 'Safe'
    end,
    ['Callback'] = function(callback)
        if callback then
            local fireball = getItem('fireball')
            local didDamageBoost = false
            local startDir = Entity.Self.Root.CFrame.LookVector

            if fireball then
                local rayc = workspace:Raycast(Entity.Self.Root.CFrame.Position + Entity.Self.Root.CFrame.LookVector * 3, Vector3.new(0, -4, 0))

                if not rayc or not rayc.Instance or not rayc.Instance.CanCollide then
                    Longjump:Toggle()
                    return
                end

                switchHand(fireball.tool)
                fireProjectile(fireball, 'fireball', Vector3.new(0, -15, 0))
                Entity.Self.Root.CFrame += Entity.Self.Root.CFrame.LookVector * 3
                Entity.Self.Root.Anchored = true
                repeat task.wait() until workspace:GetServerTimeNow() - Entity.Self.Model:GetAttribute('LastDamageTakenTime') < 0.2
                Entity.Self.Root.Anchored = false

                didDamageBoost = true

                if not Longjump.Enabled then
                    return
                end
            end

            local startY = didDamageBoost and 40 or 25
            local startSpeed = 80
            RunService:BindToRenderStep('Longjump', 9999, function(dt: number)
                if not Entity.Self.Alive then
                    return
                end

                startY -= dt * (didDamageBoost and 45 or 25)
                if startSpeed > 25 then
                    startSpeed -= dt * 35
                end

                local MoveDir = Entity.Self.Humanoid.MoveDirection
                local MoveSpeed = Entity.Self.Humanoid.WalkSpeed
                local SpeedMulti = getSpeedMultiplier()

                if didDamageBoost then
                    Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(startDir.X * startSpeed, startY, startDir.Z * startSpeed)
                else
                    Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(MoveDir.X * (MoveSpeed * (SpeedMulti > 1 and SpeedMulti * 1.1 or 1)), startY, MoveDir.Z * (MoveSpeed * (SpeedMulti > 1 and SpeedMulti * 1.1 or 1)))
                end
            end)
        else
            RunService:UnbindFromRenderStep('Longjump')
            Entity.Self.Root.Anchored = false
        end
    end
})
AutoFireball = Longjump:registerToggle({
    ['Name'] = 'Auto Fireball'
})

local setVisible = function(bool)
    lplr.Character:SetAttribute('Transparency', bool and 0 or 1)
end

do
    Flight = GuiLibrary:registerModule({
        ['Name'] = 'Flight',
        ['Window'] = 'Movement',
        ['ArrayText'] = function()
            return FlightMode.Value
        end,
        ['Callback'] = function(callback)
            if callback then
                local aidedFake = Instance.new('Part')
                aidedFake.Parent = workspace
                aidedFake.Size = Vector3.zero
                aidedFake.Anchored = true
                aidedFake.CanCollide = false
                aidedFake.CanQuery = false
                aidedFake.Transparency = 1
                aidedFake.CFrame = lplr.Character.Head.CFrame + Vector3.new(0, 0.2, 0)
                
                local Blacklist = RaycastParams.new()
                Blacklist.FilterType = Enum.RaycastFilterType.Exclude
                Blacklist.FilterDescendantsInstances = {lplr.Character}
                
                local startY = lplr.Character.PrimaryPart.CFrame.Y

                local yVelo = 5
                local newYVelo = -1
                local yMulti = -1
                local startTick = tick()

                if FlightMode.Value == 'Heatseeker' then
                    gameCamera.CameraSubject = aidedFake
                    setVisible(false)
                end

                Flight:Recycle(aidedFake)
                Flight:Recycle(function()
                    setVisible(true)
                    if FlightMode.Value == 'Heatseeker' then
                        repeat task.wait()
                            aidedFake.CFrame = CFrame.new(lplr.Character.PrimaryPart.CFrame.X, aidedFake.CFrame.Y, lplr.Character.PrimaryPart.CFrame.Z)

                            if lplr.Character.PrimaryPart.CFrame.Y < -110 then
                                lplr.Character.PrimaryPart.CFrame = CFrame.new(lplr.Character.PrimaryPart.CFrame.X, 160, lplr.Character.PrimaryPart.CFrame.Z)
                            end

                            if lplr.Character.PrimaryPart.AssemblyLinearVelocity.Y < -160 then
                                lplr.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(lplr.Character.PrimaryPart.AssemblyLinearVelocity.X, -160, lplr.Character.PrimaryPart.AssemblyLinearVelocity.Z)
                            end

                        until (lplr:DistanceFromCharacter(aidedFake.CFrame.Position) <= 30)

                        gameCamera.CameraSubject = lplr.Character
                        lplr.Character.PrimaryPart.CFrame = aidedFake.CFrame


                    end
                end)

                Flight:Recycle(RunService.PreSimulation:Connect(function(dt: number)
                    if not Entity.Self.Alive then
                        return
                    end

                    local Grounded = lplr.Character.Humanoid.FloorMaterial ~= Enum.Material.Air
                    local VerticalSpeed = 0

                    if FlightMode.Value == 'Heatseeker' then
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                            VerticalSpeed = FlightVerticalSpeed.Value
                        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                            VerticalSpeed = -FlightVerticalSpeed.Value
                        end

                        aidedFake.CFrame = CFrame.new(lplr.Character.PrimaryPart.CFrame.X, aidedFake.CFrame.Y + (VerticalSpeed * dt), lplr.Character.PrimaryPart.CFrame.Z)

                        if lplr.Character.PrimaryPart.CFrame.Y < -110 or Grounded then
                            local rayThing = workspace:Raycast(lplr.Character.PrimaryPart.CFrame.Position, Vector3.new(0, -3, 0), Blacklist)

                            if (not rayThing or not rayThing.Instance) and Grounded then
                                return
                            end

                            lplr.Character.PrimaryPart.CFrame = CFrame.new(lplr.Character.PrimaryPart.CFrame.X, 170, lplr.Character.PrimaryPart.CFrame.Z)
                        end

                        if lplr.Character.PrimaryPart.AssemblyLinearVelocity.Y < -160 then
                            lplr.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(lplr.Character.PrimaryPart.AssemblyLinearVelocity.X, -162, lplr.Character.PrimaryPart.AssemblyLinearVelocity.Z)
                        end

                        return
                    end

                    if FlightMode.Value == 'Prediction' then
                            if yVelo > 5 or yVelo < -5 then
                            yMulti = -yMulti
                        end

                        yVelo += (yMulti * (50 * dt))
                    elseif FlightMode.Value == 'Stable' then
                        yVelo = 1
                    end

                    local MoveDir = Entity.Self.Humanoid.MoveDirection
                    local MoveSpeed = Entity.Self.Humanoid.WalkSpeed

                    if (tick() - startTick) < 0.1 then
                        Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(MoveDir.X * MoveSpeed, 40, MoveDir.Z * MoveSpeed)
                    end

                    if (tick() - startTick) > 1.9 and AutoVelocity.Enabled then
                        if AutoToggle.Enabled and Flight.Enabled then
                            Flight:Toggle()
                            return
                        end

                        newYVelo -= dt

                        Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(MoveDir.X * MoveSpeed, newYVelo, MoveDir.Z * MoveSpeed)
                        return
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(MoveDir.X * MoveSpeed, FlightVerticalSpeed.Value, MoveDir.Z * MoveSpeed)
                        return
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(MoveDir.X * MoveSpeed, -FlightVerticalSpeed.Value, MoveDir.Z * MoveSpeed)
                        return
                    end

                    Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(MoveDir.X * MoveSpeed, yVelo, MoveDir.Z * MoveSpeed)
                end))
            end
        end
    })
    FlightMode = Flight:registerSelector({
        ['Name'] = 'Mode',
        ['Values'] = {'Stable', 'Prediction', 'Heatseeker'}
    })
    AutoToggle = Flight:registerToggle({
        ['Name'] = 'Auto Toggle'
    })
    AutoVelocity = Flight:registerToggle({
        ['Name'] = 'Auto Velocity Fix'
    })
    FlightVerticalSpeed = Flight:registerSlider({
        Name = "Vertical Speed",
        Minimum = 10,
        Maximum = 100,
        Default = 50,
        Step = 1
    })
end

local oldAnim, charAddedInvs
local doAnimStuff = function()
    if oldAnim then
        oldAnim:Destroy()
        oldAnim = nil
    end

    setVisible(false)

    if InvisMethod.Value == 'Animation' then
        oldAnim = Bedwars.AnimationUtil.playAnimation('WINTER_BOSS_DEATH')
        oldAnim:Stop()
        oldAnim.Priority = Enum.AnimationPriority.Movement
        oldAnim:Play(0, 1, 0.00001)
        oldAnim.TimePosition = 2.6
    end
end

Invisible = GuiLibrary:registerModule({
    ['Name'] = 'Invisible',
    ['Window'] = 'Misc',
    ['Callback'] = function(callback)
        if callback then
            charAddedInvs = Entity.Self.Player.CharacterAdded:Connect(function(char)
                char:WaitForChild('Humanoid');

                task.wait(1)
                doAnimStuff()
                task.wait(0.01)
                Entity.Self.Root.Transparency = 0.5
            end)

            doAnimStuff()
            Entity.Self.Root.Transparency = 0.5
        else
            if charAddedInvs then
                charAddedInvs:Disconnect()
            end

            if oldAnim then
                oldAnim:Stop()
                oldAnim = nil
            end

            setVisible(true)
            Entity.Self.Root.Transparency = 1
        end
    end
})
InvisMethod = Invisible:registerSelector({
    ['Name'] = 'Method',
    ['Values'] = {'Animation'--[[, 'Remote']]}
})

EmoteClip = GuiLibrary:registerModule({
    ['Name'] = 'Emote Clip',
    ['Window'] = 'Misc',
    ['Callback'] = function(callback)
        if callback then
            if Bedwars.Remotes.Emote:InvokeServer({
                emoteType = 'swimming_emote'
            }) then
                task.wait(2.2)
                local exp = Entity.Self.Root.CFrame.LookVector * -2
                local pos = Entity.Self.Root.CFrame.Position
                Entity.Self.Root.CFrame = CFrame.lookAt(pos, Vector3.new(pos.X + exp.X, pos.Y, pos.Z + exp.Z))
                Entity.Self.Root.CFrame += Entity.Self.Root.CFrame.LookVector * 6
            end

            EmoteClip:Toggle()
        end
    end
})

NoSlow = GuiLibrary:registerModule({
    ['Name'] = 'No Slow',
    ['Window'] = 'Movement',
    ['Callback'] = function(callback)
        Bedwars.Remotes.TriggerInvisibleLandmine.Parent = callback and nil or Default
        --Bedwars.Remotes.StepOnSnapTrap.Parent = callback and nil or Default
        Bedwars.Remotes.StepOnSpiderWeb.Parent = callback and nil or Default
    end
})

local acceptedConsumeItems = {
    ['speed_potion'] = 'SpeedBoost',
    ['pie'] = 'SpeedPieBuff',
}

AutoConsume = GuiLibrary:registerModule({
    ['Name'] = 'Auto Consume',
    ['Window'] = 'Player',
    ['Callback'] = function(callback)
        if callback then
            repeat
                task.wait(0.25)
                if not Entity.Self.Alive then
                    continue
                end

                for _, value in Bedwars.Inventory.items do
                    if acceptedConsumeItems[value.itemType] and not Entity.Self.Model:GetAttribute(acceptedConsumeItems[value.itemType]) then
                        switchHand(value.tool, true, 0.7)
                        ignoreSwitch = true
                        Bedwars.Remotes.StartConsume:FireServer({
                            ['item'] = value.tool
                        })
                        task.wait(0.6)
                        Bedwars.Remotes.ConsumeItem:InvokeServer({
                            ['item'] = value.tool
                        })
                        ignoreSwitch = false
                    end
                end
            until not AutoConsume.Enabled
        end
    end
})

FastPickup = GuiLibrary:registerModule({
    ['Name'] = 'Pickup Range',
    ['Window'] = 'Player',
    ['Callback'] = function(callback)
        if callback then
            repeat
                task.wait(0.1)
                if not Entity.Self.Alive then
                    continue
                end

                for _, value in workspace.ItemDrops:GetChildren() do
                    local dist = lplr:DistanceFromCharacter(value.CFrame.Position)

                    if dist <= 10 and (workspace:GetServerTimeNow() - value:GetAttribute('PickupReadyTime')) > 0 then
                        value.CFrame = Entity.Self.Root.CFrame - Vector3.new(0, 3, 0)
                        Bedwars.Remotes.PickupItemDrop:InvokeServer({
                            ['itemDrop'] = value
                        })
                    end
                end
            until not FastPickup.Enabled
        end
    end
})

Spider = GuiLibrary:registerModule({
    ['Name'] = 'Wall Climb',
    ['Window'] = 'Movement',
    ['Callback'] = function(callback)
        if callback then
            local blacklist = RaycastParams.new()
            blacklist.FilterType = Enum.RaycastFilterType.Exclude
            blacklist.FilterDescendantsInstances = {Entity.Self.Model, gameCamera.Viewmodel}

            Spider:Recycle(RunService.PreSimulation:Connect(function(dt: number)
                if not Entity.Self.Alive then
                    return
                end

                local front = workspace:Raycast(Entity.Self.Root.CFrame.Position - Vector3.new(0, 1, 0), Entity.Self.Humanoid.MoveDirection * 3, blacklist)
                
                if front and front.Instance and front.Instance.CanCollide and not front.Instance:IsDescendantOf(Entity.Self.Model) and not front.Instance:IsDescendantOf(gameCamera) and front.Instance:IsDescendantOf(workspace.Map) then
                    Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(Entity.Self.Root.AssemblyLinearVelocity.X, 40, Entity.Self.Root.AssemblyLinearVelocity.Z)
                end
            end))
        end
    end
})

--[[Breaker = GuiLibrary:registerModule({
    ['Name'] = 'Breaker',
    ['Window'] = 'Player',
})]]