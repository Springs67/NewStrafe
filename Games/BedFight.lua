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
Entity.init()

local BedFight = {
    ItemMeta = loadstring(downloadFile('Libraries/BedFight/ItemMeta.lua'))(),
    SwordMeta = loadstring(downloadFile('Libraries/BedFight/SwordMeta.lua'))(),
    AnimationData = loadstring(downloadFile('Libraries/BedFight/AnimationsData.lua'))(),
    InventoryUtil = loadstring(downloadFile('Libraries/BedFight/InventoryUtil.lua'))(),
}

GuiLibrary:removeModule('Atmosphere')

BedFight.Inventory = {}
task.spawn(function()
    repeat
        task.wait(0.25)
        BedFight.Inventory = BedFight.InventoryUtil.getInventory(lplr)
    until false
end)

local Default = ReplicatedStorage:WaitForChild('Remotes')
local ItemDefault = Default:WaitForChild('ItemsRemotes')
local PartyDefault = Default:WaitForChild('PartyRemotes')

BedFight.Remotes = {
    SwordHit = ItemDefault:WaitForChild('SwordHit'),
    EquipTool = ItemDefault:WaitForChild('EquipTool'),
    PlaceBlock = ItemDefault:WaitForChild('PlaceBlock'),
    MineBlock = ItemDefault:WaitForChild('MineBlock'),
}

local switchHand = function(tool: Instance)
    if not lplr.Character then
        return false
    end

    if not BedFight.Inventory.hand then
        BedFight.Remotes.EquipTool:FireServer(
            tool.itemType
        )
    end

    if BedFight.Inventory.hand and BedFight.Inventory.hand.tool ~= tool then
        BedFight.Remotes.EquipTool:FireServer(
            tool.itemType
        )

        return true
    end

    return false
end

local hasItem = function(Name: string)
    for _, value in BedFight.Inventory.items do
        if value.itemType == Name then
            return true
        end
    end

    return false
end

local getItem = function(Name: string)
    for _, value in BedFight.Inventory.items do
        if value.itemType == Name then
            return value
        end
    end

    return nil
end

local getRelItem = function(Name: string)
    for _, value in BedFight.Inventory.items do
        if value.itemType:lower():find(Name:lower()) then
            return value
        end
    end

    return nil
end

local getRoundedPos = function(Position: Vector3)
    local X = math.floor(Position.X / 3 + 0.5) * 3
    local Y = math.floor(Position.Y / 3) * 3
    local Z = math.floor(Position.Z / 3 + 0.5) * 3

    return Vector3.new(X, Y, Z)
end

local function placeBlock(pos: Vector3, shouldCollide: boolean)
    local Wool = getItem('wool') or getItem('fake block')

    if Wool then
        pos = getRoundedPos(pos)

        BedFight.Remotes.PlaceBlock:FireServer(Wool.itemType, 1, pos)

        local Clone = ReplicatedStorage.Blocks[Wool.itemType]:Clone()
        Clone.Parent = workspace:FindFirstChildWhichIsA('Folder')
        Clone.Position = pos
        Clone.CanCollide = shouldCollide or true

        task.delay(0.5, function()
            Clone:Destroy()
            Clone = nil
        end)

        return Clone
    end
end

local getNearestBed = function(Range: number)
    local nearest, nearestDist

    if workspace:FindFirstChild('BedsContainer') then
        for _, value in workspace.BedsContainer:GetChildren() do
            local Hitbox = value:FindFirstChild('BedHitbox')

            if Hitbox then
                local Distance = lplr:DistanceFromCharacter(Hitbox.Position)

                if Distance <= Range and (not nearestDist or Distance < nearestDist) then
                    nearest = Hitbox
                    nearestDist = Distance
                end
            end
        end
    end

    return nearest, nearestDist
end

local getBestWeapon = function()
    local bestWeapon, bestDamage = nil, 0

    for index, value in BedFight.SwordMeta do
        if hasItem(index) and value.Damage > bestDamage then
            bestWeapon = getItem(index)
            bestDamage = value.Damage
        end
    end

    return bestWeapon
end

local getNearestAttackable = function(Range: number)
    local nearestEnt, nearestDist = nil, math.huge

    for i, v in Entity.Entities do
        if not Entity.getModelAlive(v.Model) then
            continue
        end

        if not v.Player:GetAttribute('PVP') or not lplr:GetAttribute('PVP') then
            continue
        end

        if tostring(v.Player.Team and v.Player.Team.Name or 'None') ~= 'Spectators' and v.Player.Team == lplr.Team then
            continue
        end

        local dist = lplr:DistanceFromCharacter(v.Root.Position)

        if dist <= Range and dist < nearestDist then
            nearestEnt = v
            nearestDist = dist
        end
    end

    return nearestEnt
end

local getNearestMouseAttackable = function(Range: number, Range2: number)
    local nearestEnt, nearestDist = nil, math.huge

    for i, v in Entity.Entities do
        if not Entity.getModelAlive(v.Model) then
            continue
        end

        if not v.Player:GetAttribute('PVP') or not lplr:GetAttribute('PVP') then
            continue
        end

        if tostring(v.Player.Team and v.Player.Team.Name or 'None') ~= 'Spectators' and v.Player.Team == lplr.Team then
            continue
        end

        local screenPos, onScreen = gameCamera:WorldToViewportPoint(v.Root.Position)

        if onScreen and screenPos.Z > 0 then
            local playerPos = Vector2.new(screenPos.X, screenPos.Y)

            local distance = (UserInputService:GetMouseLocation() - playerPos).Magnitude
            local distance2 = Entity.Self.Player:DistanceFromCharacter(v.Root.Position)

            if distance < nearestDist and distance <= Range and distance2 <= Range2 then
                nearestDist = distance
                nearestEnt = v;
            end
        end
    end

    return nearestEnt
end

local swingFPAnimation = Instance.new('Animation'); swingFPAnimation.AnimationId = 'rbxassetid://80138703077151'
local swingFPLoaded = nil;

local swingAnimation = Instance.new('Animation'); swingAnimation.AnimationId = 'rbxassetid://123800159244236'
local swingLoaded = nil;

if Entity.Self.Alive then
    swingLoaded = Entity.Self.Humanoid:LoadAnimation(swingAnimation)
end

lplr.CharacterAdded:Connect(function(char)
    repeat task.wait() until lplr.Character and char and Entity.getModelAlive(char)

    swingLoaded = Entity.Self.Humanoid:LoadAnimation(swingAnimation)
end)

if workspace.CurrentCamera:FindFirstChild('ViewModel') and workspace.CurrentCamera:FindFirstChild('ViewModel'):FindFirstChild('AnimationController') then
    swingFPLoaded = workspace.CurrentCamera:FindFirstChild('ViewModel'):FindFirstChild('AnimationController').Animator:LoadAnimation(swingFPAnimation)
end

local toolHandlers = ReplicatedStorage:WaitForChild('ToolHandlers')
local SilentAura; SilentAura = GuiLibrary:registerModule({
    ['Name'] = 'Silent Aura',
    ['Window'] = 'Combat',
    ['Callback'] = function(callback)
        if callback then
            RunService:BindToRenderStep('SilentAura', 99, function()
                if not Entity.Self.Alive then
                    return
                end

                local Nearest = getNearestAttackable(AuraRange.Value)

                if Nearest and DoRotations.Enabled then
                    Entity.Self.Root.CFrame = CFrame.lookAt(
                        Entity.Self.Root.CFrame.Position,
                        Vector3.new(
                            Nearest.Root.CFrame.Position.X,
                            Entity.Self.Root.CFrame.Y,
                            Nearest.Root.CFrame.Position.Z
                        )
                    )
                end
            end)

            repeat
                task.wait()
                if not Entity.Self.Alive then
                    continue
                end

                local Nearest = getNearestAttackable(AuraRange.Value)

                if HoldItemCheck.Enabled then
                    if not BedFight.Inventory.hand then
                        continue
                    end
                    
                    if BedFight.InventoryUtil.getToolType(BedFight.Inventory.hand.itemType).Class ~= 'Swords' then
                        continue
                    end
                end

                if Nearest then
                    local fovNearest = getNearestMouseAttackable(AuraFieldOfView.Value, AuraRange.Value)

                    if AuraFieldOfView.Value ~= 360 and not fovNearest then
                        continue
                    end

                    local Weapon = getBestWeapon()

                    if not Weapon then
                        continue
                    end

                    if (math.random(1, 100)) < AuraMissChance.Value then
                        continue
                    end

                    if AutoSwitch.Enabled then
                        BedFight.Remotes.EquipTool:FireServer(
                            Weapon.itemType
                        )
                    end

                    BedFight.Remotes.SwordHit:FireServer(
                        Nearest.Model,
                        Weapon.itemType
                    )

                    if PlaySwingAnim.Enabled then
                        swingLoaded:Play()
                        swingFPLoaded:Play()
                    end

                    if PlaySwingSound.Enabled then
                        local var = tostring(math.round(math.random(1, 2)))

                        if Entity.Self.Root:FindFirstChild('Swing'..var) then
                            Entity.Self.Root:FindFirstChild('Swing'..var):Play()
                        else
                            toolHandlers.Sword.Sounds.Default['Swing'..var]:Clone().Parent = Entity.Self.Root
                        end
                    end

                    task.wait(AuraDelay.Value)
                end
            until not SilentAura.Enabled
        else
            RunService:UnbindFromRenderStep('SilentAura')
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
AuraDelay = SilentAura:registerSlider({
    ['Name'] = 'Delay',
    ['Step'] = 0.01,
    ['Minimum'] = 0,
    ['Maximum'] = 0.5,
    ['Default'] = 0.285,
})
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

local fkb = nil
NoKnockback = GuiLibrary:registerModule({
    ['Name'] = 'No Knockback',
    ['Window'] = 'Combat',
    ['Callback'] = function(callback)
        if callback then
            lplr.Character.Humanoid:SetAttribute('KnockbackDisabled', true)
            fkb = lplr.CharacterAdded:Connect(function()
                task.wait(1.5)
                lplr.Character.Humanoid:SetAttribute('KnockbackDisabled', true)
            end)
        else
            lplr.Character.Humanoid:SetAttribute('KnockbackDisabled', false)
            if fkb then
                fkb:Disconnect()
            end
        end
    end
})

local aided2;
local aided3;
Disabler = GuiLibrary:registerModule({
    ['Name'] = 'Disabler',
    ['Window'] = 'Misc',
    ['ArrayText'] = function()
        return 'Knockback'
    end,
    ['Callback'] = function(callback)
        if callback then
            lplr:WaitForChild('Kit').Value = 'Hacker'

            aided2 = lplr:WaitForChild('Kit'):GetPropertyChangedSignal('Value'):Connect(function()
                lplr:WaitForChild('Kit').Value = 'Hacker'
            end)

            lplr:WaitForChild('PlayerGui'):WaitForChild('AbilitiesGui').Enabled = false
            lplr.PlayerGui:WaitForChild('HackGui').Enabled = false

            aided3 = lplr.PlayerGui:WaitForChild('HackGui'):GetPropertyChangedSignal('Enabled'):Connect(function()
                lplr.PlayerGui:WaitForChild('HackGui').Enabled = false
            end)
        else
            aided3:Disconnect()
            aided2:Disconnect()

            lplr:WaitForChild('Kit').Value = 'None'
        end
    end
})

UICleanup = GuiLibrary:registerModule({
    ['Name'] = 'UI Cleanup',
    ['Window'] = 'Visual',
    ['Callback'] = function(callback)
        lplr.PlayerGui:WaitForChild('TopbarButtonsGui', 999999999).Enabled = not callback
        lplr.PlayerGui:WaitForChild('KillLogGui', 99999999).Enabled = not callback
    end
})

local startY = 0
local startPosY = Vector3.zero
Longjump = GuiLibrary:registerModule({
    ['Name'] = 'Longjump',
    ['Window'] = 'Movement',
    ['ArrayText'] = function()
        return 'BedFight'
    end,
    ['Callback'] = function(callback)
        if callback then
            Entity.Self.Root.CFrame += Vector3.new(0, 3, 0)
            --fakeDamage.new()

            if not Longjump.Enabled then
                return
            end

            local startDir = Entity.Self.Root.CFrame.LookVector
            local startSpeed = 28
            local startTick = tick()
            startY = 50
            startPosY = Entity.Self.Root.CFrame.Y
            RunService:BindToRenderStep('Longjump', 9999, function(dt)
                if not Entity.Self.Alive or not isnetworkowner(Entity.Self.Root) then
                    return
                end

                startSpeed = 28

                if (tick() - startTick) < (LongjumpBoostTime and LongjumpBoostTime.Value or 0.2) then
                    startSpeed = (LongjumpSpeed and LongjumpSpeed.Value or 300)
                end
                startY -= (workspace.Gravity * dt) / 2

                Entity.Self.Root.AssemblyLinearVelocity = Vector3.new((LongjumpFreeMove.Enabled and Entity.Self.Humanoid.MoveDirection or startDir).X * startSpeed, (tick() - startTick) < 0.8 and 1 or -5, (LongjumpFreeMove.Enabled and Entity.Self.Humanoid.MoveDirection or startDir).Z * startSpeed)

                if (tick() - startTick) > (LongjumpDisableTime and LongjumpDisableTime.Value or 0.85) and Longjump.Enabled and LongjumpAutoDisable.Enabled then
                    RunService:UnbindFromRenderStep('Longjump')
                    Longjump:Toggle()
                end
            end)
        else
            RunService:UnbindFromRenderStep('Longjump')
            Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(Entity.Self.Humanoid.MoveDirection.X * 20, Entity.Self.Root.AssemblyLinearVelocity.Y, Entity.Self.Humanoid.MoveDirection.Z * 20)
            --entityLib.root.CFrame = CFrame.new(Vector3.new(entityLib.root.CFrame.X, startPosY, entityLib.root.CFrame.Z))
        end
    end
})
LongjumpFreeMove = Longjump:registerToggle({
    ['Name'] = 'Free Move',
})
LongjumpAutoDisable = Longjump:registerToggle({
    ['Name'] = 'Auto Disable',
})
LongjumpSpeed = Longjump:registerSlider({
    ['Name'] = 'Boost Speed',
    ['Step'] = 1,
    ['Minimum'] = 28,
    ['Maximum'] = 600,
    ['Default'] = 550,
})
LongjumpBoostTime = Longjump:registerSlider({
    ['Name'] = 'Boost Time',
    ['Step'] = 0.01,
    ['Minimum'] = 0,
    ['Maximum'] = 0.3,
    ['Default'] = 0.2,
})
LongjumpDisableTime = Longjump:registerSlider({
    ['Name'] = 'Auto Disable Time',
    ['Step'] = 0.025,
    ['Minimum'] = 0.25,
    ['Maximum'] = 1,
    ['Default'] = 0.85,
})

Flight = GuiLibrary:registerModule({
    ['Name'] = 'Flight',
    ['Window'] = 'Movement',
    ['ArrayText'] = function()
        return 'BedFight'
    end,
    ['Callback'] = function(callback)
        if callback then
            local startTick = tick()
            RunService:BindToRenderStep('Flight', 9999, function(dt)
                if not Entity.Self.Alive or not isnetworkowner(Entity.Self.Root) then
                    return
                end

                local flyVal = 1
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    flyVal = 50
                elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    flyVal = -50
                end

                Entity.Self.Root.AssemblyLinearVelocity = Vector3.new(Entity.Self.Root.AssemblyLinearVelocity.X, (tick() - startTick) < 1 and flyVal or -5, Entity.Self.Root.AssemblyLinearVelocity.Z)
            end)
        else
            RunService:UnbindFromRenderStep('Flight')
        end
    end
})

local getSpeed = function(val: number)
    val -= Entity.Self.Humanoid.WalkSpeed

    return val
end

Speed = GuiLibrary:registerModule({
    ['Name'] = 'Speed',
    ['Window'] = 'Movement',
    ['ArrayText'] = function()
        return 'BedFight'
    end,
    ['Callback'] = function(callback)
        if callback then
            RunService:BindToRenderStep('Speed', 9999, function(dt)
                if not Entity.Self.Alive or Longjump.Enabled or not isnetworkowner(Entity.Self.Root) then
                    return
                end

                Entity.Self.Root.CFrame += (Entity.Self.Humanoid.MoveDirection * getSpeed(SpeedValue and SpeedValue.Value or 26) * dt)
            end)
        else
            task.wait(0.05)
            RunService:UnbindFromRenderStep('Speed')
        end
    end
})
SpeedValue = Speed:registerSlider({
    ['Name'] = 'Value',
    ['Minimum'] = 16,
    ['Maximum'] = 27,
    ['Default'] = 26,
})

Breaker = GuiLibrary:registerModule({
    ['Name'] = 'Breaker',
    ['Window'] = 'Player',
    ['Callback'] = function(callback)
        if callback then
            local lastSwitched = tick()
            repeat
                task.wait()
                if not Entity.Self.Alive then
                    continue
                end

                local Bed = getNearestBed(BreakerRange and BreakerRange.Value or 18)
                local Pickaxe = getRelItem('pickaxe')

                if Bed and Pickaxe then
                    if (tick() - lastSwitched) < (BreakerDelay and BreakerDelay.Value or 0.5) then
                        continue
                    end

                    lastSwitched = tick()
                    switchHand(Pickaxe)
                    task.wait(0.05)
                    print('sent?', Pickaxe.Name)
                    BedFight.Remotes.MineBlock:FireServer(
                        Pickaxe.itemType,
                        Bed.Parent,
                        Bed.Position,
                        Bed.Position + Vector3.new(0, 2, 0),
                        Vector3.new(0, -1, 0)
                    )
                end
            until not Breaker.Enabled
        end
    end
})
BreakerRange = Breaker:registerSlider({
    ['Name'] = 'Range',
    ['Step'] = 1,
    ['Minimum'] = 10,
    ['Maximum'] = 22,
    ['Default'] = 20,
})
BreakerDelay = Breaker:registerSlider({
    ['Name'] = 'Delay',
    ['Step'] = 0.025,
    ['Minimum'] = 0,
    ['Maximum'] = 0.5,
    ['Default'] = 0.3,
})

local oldFOV = lplr:FindFirstChild('Settings').FOV.Value
local aidscon
AutoSprint = GuiLibrary:registerModule({
    ['Name'] = 'Auto Sprint',
    ['Window'] = 'Movement',
    ['Callback'] = function(callback)
        if callback then
            oldFOV = lplr:FindFirstChild('Settings').FOV.Value
            
            TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.1), {FieldOfView = oldFOV + 15}):Play()
            task.wait(0.1)

            if not AutoSprint.Enabled then
                return
            end

            aidscon = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(function()
                if shared.Aiding then
                    return
                end
                
                workspace.CurrentCamera.FieldOfView = oldFOV + 15
            end)

            RunService:BindToRenderStep('Sprinting', 99999, function()
                if not Entity.Self.Alive then
                    return
                end

                Entity.Self.Humanoid.WalkSpeed = 20
            end)
        else
            RunService:UnbindFromRenderStep('Sprinting')

            TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.1), {FieldOfView = oldFOV}):Play()
            Entity.Self.Humanoid.WalkSpeed = 16
            aidscon:Disconnect()
        end
    end
})
