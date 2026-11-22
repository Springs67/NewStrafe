local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Lighting = cloneref(game:GetService("Lighting"))
local RunService = cloneref(game:GetService("RunService"))
local TextService = cloneref(game:GetService("TextService"))
local ScriptContext = cloneref(game:GetService("ScriptContext"))

ScriptContext:SetTimeout(1)

if not Players.LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
end

local lplr = Players.LocalPlayer
local gameCamera = workspace.CurrentCamera

local GuiLibrary = shared.GuiLibrary
local Data = shared.Data

GuiLibrary:registerWindow('Combat')
GuiLibrary:registerWindow('Movement')
GuiLibrary:registerWindow('Player')
GuiLibrary:registerWindow('Visual')
GuiLibrary:registerWindow('Misc')

GuiLibrary.screen:FindFirstChild('Arraylist').Visible = false

local ModuleList = GuiLibrary:registerModule({
    ['Name'] = 'Module List',
    ['Window'] = 'Visual',
    ['Callback'] = function(callback)
        GuiLibrary.screen:FindFirstChild('Arraylist').Visible = callback
    end
})
ModuleList:registerSlider({
    ['Name'] = 'Transparency',
    ['Step'] = 0.05,
    ['Minimum'] = 0,
    ['Maximum'] = 1,
    ['Default'] = 1,
    ['Callback'] = function(Value)
        GuiLibrary.Arraylist.Transparency = Value
    end
})
ModuleList:registerToggle({
    ['Name'] = 'Outline',
    ['Callback'] = function(callback)
        GuiLibrary.Arraylist.Outline = callback
    end
})
ModuleList:registerToggle({
    ['Name'] = 'Shadow',
    ['Callback'] = function(callback)
        GuiLibrary.Arraylist.Shadow = callback
    end
})
ModuleList:registerToggle({
    ['Name'] = 'Lowered Text',
    ['Callback'] = function(callback)
        GuiLibrary.Arraylist.Lowered = callback
        GuiLibrary.Arraylist.ArraylistUpdate:Fire()
    end
})
ModuleList:registerSelector({
    ['Name'] = 'Vertical',
    ['Values'] = {'Top', 'Bottom'},
    ['Callback'] = function(callback)
        GuiLibrary.Arraylist.Vertical = callback
        GuiLibrary.Arraylist.ArraylistUpdate:Fire()
        GuiLibrary.screen:FindFirstChild('Arraylist').UIListLayout.VerticalAlignment = Enum.VerticalAlignment[callback]
    end
})

local rgbVal = 0
Interface = GuiLibrary:registerModule({
    ['Name'] = 'Interface',
    ['Window'] = 'Visual',
    ['Callback'] = function(callback)
        if not callback then
            RunService:UnbindFromRenderStep('RGBStuff')
        end
    end
})

Interface:registerSelector({
    ['Name'] = 'Color Mode',
    ['Values'] = {'Static', 'Rainbow', 'Rainbow 2'},
    ['Callback'] = function(Value)
        GuiLibrary.ColorMode = Value

        if Value == 'Rainbow' or Value == 'Rainbow 2' then
            RunService:BindToRenderStep('RGBStuff', 9999, function(dt)
                rgbVal += (dt / 10)

                if rgbVal > 1 then
                    rgbVal = 0
                end

                GuiLibrary.GuiChange:Fire(Color3.fromHSV(rgbVal % 1, 0.6, 1))
            end)
        else
            RunService:UnbindFromRenderStep('RGBStuff')
        end

        if Value == 'Static' then
            GuiLibrary.GuiChange:Fire(Color3.fromRGB(0, 100, 255))
        end
    end
})

Interface:registerSlider({
    Name = "Rainbow Spread",
    Minimum = 1,
    Maximum = 50,
    Step = 1,
    Callback = function(value)
        GuiLibrary.rainbowSpread = value
    end
})

local WatermarkInst = Instance.new('TextLabel')
WatermarkInst.Parent = GuiLibrary.screen
WatermarkInst.Position = UDim2.fromOffset(25, 25)
WatermarkInst.BackgroundTransparency = 0.35
WatermarkInst.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
WatermarkInst.TextXAlignment = Enum.TextXAlignment.Left
WatermarkInst.TextColor3 = Color3.fromRGB(255, 255, 255)
WatermarkInst.TextSize = 25
WatermarkInst.Text = ' ' .. Data.Name .. ' ' .. Data.Version .. ' | ' .. (shared.Developer and 'Developer' or 'Public') .. ' '
WatermarkInst.Font = Enum.Font.BuilderSansMedium
WatermarkInst.Visible = false
WatermarkInst.Size = UDim2.fromOffset(TextService:GetTextSize(WatermarkInst.Text, WatermarkInst.TextSize, WatermarkInst.Font, Vector2.zero).X, 30)
local WatermarkTop = Instance.new('Frame')
WatermarkTop.Parent = WatermarkInst
WatermarkTop.Size = UDim2.new(1, 0, 0, 3)
WatermarkTop.BorderSizePixel = 0
WatermarkTop.BorderColor3 = Color3.fromRGB(0, 0, 0)
WatermarkTop.BackgroundColor3 = Color3.fromRGB(0, 100, 255)

GuiLibrary.GuiChange.Event:Connect(function(val)
    WatermarkTop.BackgroundColor3 = val
end)

if lplr:WaitForChild('PlayerGui'):FindFirstChild('TopbarStandard') then
    lplr.PlayerGui:FindFirstChild('TopbarStandard').Enabled = false
end

CoreGui:WaitForChild('TopBarApp'):WaitForChild('TopBarApp').Enabled = false

GuiLibrary:registerModule({
    ['Name'] = 'Watermark',
    ['Window'] = 'Visual',
    ['Callback'] = function(callback)
        WatermarkInst.Visible = callback
    end
})

local fovAids = nil
local oldFov = gameCamera.FieldOfView
FieldOfView = GuiLibrary:registerModule({
    ['Name'] = 'Field Of View',
    ['Window'] = 'Visual',
    ['Callback'] = function(callback)
        if callback then
            oldFov = gameCamera.FieldOfView

            shared.Aiding = true
            gameCamera.FieldOfView = FieldOfViewValue.Value
            fovAids = gameCamera:GetPropertyChangedSignal('FieldOfView'):Connect(function()
                gameCamera.FieldOfView = FieldOfViewValue.Value
            end)
        else
            fovAids:Disconnect();
            gameCamera.FieldOfView = oldFov
            shared.Aiding = false
        end
    end
})
FieldOfViewValue = FieldOfView:registerSlider({
    ['Name'] = 'Value',
    ['Minimum'] = 30,
    ['Maximum'] = 120,
    ['Default'] = 120,
    ['Callback'] = function(value)
        if not FieldOfView.Enabled then
            return
        end

        gameCamera.FieldOfView = value
    end
})

local AmbientColors = {
    ['Red'] = Color3.fromRGB(255, 0, 0),
    ['Orange'] = Color3.fromRGB(255, 100, 0),
    ['Yellow'] = Color3.fromRGB(255, 255, 0),
    ['Green'] = Color3.fromRGB(0, 255, 0),
    ['Blue'] = Color3.fromRGB(0, 0, 255),
    ['Purple'] = Color3.fromRGB(100, 0, 255),
    ['Pink'] = Color3.fromRGB(255, 0, 255)
}

local ambientIndexs = {}
for index, _ in AmbientColors do
    table.insert(ambientIndexs, index)
end

local oldAmbVals = {}
local oldDay = Lighting.TimeOfDay
local newColorEffect, colorConnection
Atmosphere = GuiLibrary:registerModule({
    ['Name'] = 'Atmosphere',
    ['Window'] = 'Visual',
    ['Callback'] = function(callback)
        if callback then
            --[[oldAmbVals['amb'] = Lighting.Ambient
            oldAmbVals['outdoorAmb'] = Lighting.OutdoorAmbient

            Lighting.Ambient = AtmosphereColors and AmbientColors[AtmosphereColors.Value] or Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = AtmosphereColors and AmbientColors[AtmosphereColors.Value] or Color3.fromRGB(255, 255, 255)]]

            newColorEffect = Instance.new('ColorCorrectionEffect')
            newColorEffect.Parent = Lighting
            newColorEffect.TintColor = AmbientColors[AtmosphereColors.Value]

            colorConnection = newColorEffect:GetPropertyChangedSignal('TintColor'):Connect(function()
                if newColorEffect.TintColor ~= AmbientColors[AtmosphereColors.Value] then
                    newColorEffect.TintColor = AmbientColors[AtmosphereColors.Value]
                end
            end)

            --Lighting.TimeOfDay = tostring(AtmosphereTime and AtmosphereTime.Value or 12)..':00:00'
        else
            colorConnection:Disconnect()
            if newColorEffect then
                newColorEffect:Destroy()
            end
            --[[Lighting.Ambient = oldAmbVals.amb
            Lighting.OutdoorAmbient = oldAmbVals.outdoorAmb]]
        end
    end
})
AtmosphereColors = Atmosphere:registerSelector({
    ['Name'] = 'Color',
    ['Values'] = ambientIndexs,
    ['Callback'] = function(value: string)
        if not Atmosphere.Enabled then
            return
        end

        if newColorEffect then
            newColorEffect.TintColor = AmbientColors[value]
        end
    end
})
AtmosphereTime = Atmosphere:registerSlider({
    ['Name'] = 'Time of Day',
    ['Step'] = 1,
    ['Minimum'] = 0,
    ['Maximum'] = 24,
    ['Default'] = 12,
    ['Callback'] = function(value: number)
        if not Atmosphere.Enabled then
            return
        end

        Lighting.TimeOfDay = tostring(value)..':00:00'
    end
})

local currFolder = nil
if GuiLibrary.currentGame ~= 'Counterblox' then
    currFolder = Instance.new('Folder')
    currFolder.Parent = workspace
else
    currFolder = workspace.CurrentCamera:WaitForChild('GUI', 10)
end

local addNametags = function(plr: Player)
    if not plr or not plr.Character or not plr.Character:FindFirstChild('Head') or plr.Character:FindFirstChild('Head'):FindFirstChild(tostring(plr.UserId)) then
        return
    end

    local Background = Instance.new('BillboardGui')
    Background.Parent = currFolder
    Background.AlwaysOnTop = true
    Background.StudsOffset = Vector3.new(0, 1.35, 0)
    Background.Size = UDim2.fromScale(1, 1)
    Background.Adornee = plr.Character:WaitForChild('Head', 5)
    Background.Name = plr.UserId

    local Text = Instance.new('TextLabel')
    Text.Parent = Background
    Text.AnchorPoint = Vector2.new(0.5, 0.5)
    Text.BackgroundTransparency = 0.5
    Text.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.TextSize = 16
    Text.Text = plr.DisplayName
    Text.Font = Enum.Font.BuilderSansMedium

    Text.Size = UDim2.fromOffset(TextService:GetTextSize(Text.Text, Text.TextSize, Text.Font, Vector2.zero).X + 4, 20)

    if plr.Character and plr.Character:WaitForChild('Humanoid', 1) then
        plr.Character:FindFirstChildOfClass('Humanoid').DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    if plr.Team == Players.LocalPlayer.Team and ESPTeam.Enabled then
        Background.Enabled = false
    end

    plr.Character.Destroying:Once(function()
        Background:Destroy()
    end)
end

local removeTags = function(plr: Player)
    if currFolder:FindFirstChild(plr.Name) then
        currFolder:FindFirstChild(plr.Name):Destroy()
    end
end

local refreshESP = function()
    for _, value in currFolder:GetChildren() do
        local plr = Players:GetPlayerByUserId(tonumber(value.Name))

        if plr and plr.Team == Players.LocalPlayer.Team and ESPTeam.Enabled then
            value.TextLabel.TextColor3 = ESPTeamColor.Enabled and plr.TeamColor or Color3.fromRGB(255, 255, 255)
            value.Enabled = false
        else
            value.Enabled = true
        end
    end
end

local nametagAids = {}
local Nametags = GuiLibrary:registerModule({
    ['Name'] = 'Nametags',
    ['Window'] = 'Visual',
    ['Callback'] = function(callback)
        if callback then
            for _, value: Player in Players:GetPlayers() do
                if value == Players.LocalPlayer then
                    continue
                end

                if value.Character then
                    addNametags(value);
                end

                table.insert(nametagAids, value.CharacterAdded:Connect(function()
                    repeat task.wait() until value.Character
                    task.wait(2)
                    addNametags(value);
                end))

                table.insert(nametagAids, value.CharacterRemoving:Connect(function()
                    removeTags(value);
                end))
            end

            table.insert(nametagAids, Players.PlayerAdded:Connect(function(value: Player)
                table.insert(nametagAids, value.CharacterAdded:Connect(function()
                    repeat task.wait() until value.Character
                    task.wait(2)
                    addNametags(value);
                end))

                table.insert(nametagAids, value.CharacterRemoving:Connect(function()
                    removeTags(value);
                end))
            end))

            Players.PlayerRemoving:Connect(function(player: Player)
                removeTags(player)
            end)
        else
            for _, value in nametagAids do
                value:Disconnect()
            end
            
            for _, value in currFolder:GetChildren() do
                value:Destroy();
            end
        end
    end
})

ESPTeam = Nametags:registerToggle({
    ['Name'] = 'Team Check',
    ['Callback'] = function(callback)
        refreshESP()
    end
})

ESPTeamColor = Nametags:registerToggle({
    ['Name'] = 'Use Team Color',
    ['Callback'] = function(callback)
        refreshESP()
    end
})

local aidedPhase, phaseCon2
Phase = GuiLibrary:registerModule({
    ['Name'] = 'Phase',
    ['Window'] = 'Movement',
    ['Callback'] = function(callback)
        if callback then
            local lastCharAdded = tick()
            aidedPhase = RunService.PreSimulation:Connect(function(dt)
                if not lplr.Character then
                    return
                end

                if (tick() - lastCharAdded) < 2 then
                    return
                end

                for _, v in lplr.Character:GetDescendants() do
                    if v:IsA('BasePart') or v:IsA('MeshPart') then
                        v.CanCollide = false
                    end
                end
            end)

            phaseCon2 = lplr.CharacterAdded:Connect(function(char)
                task.wait(1)
                lastCharAdded = tick()
            end)
        else
            aidedPhase:Disconnect()
            phaseCon2:Disconnect()
        end
    end
})

Destruct = GuiLibrary:registerModule({
    ['Name'] = 'Destruct',
    ['Window'] = 'Misc',
    ['Callback'] = function(callback)
        if callback then
            Destruct:Toggle()
            GuiLibrary:Destroy()

            if Reinject.Enabled then
                loadfile('Strafe/Main.lua')()
            end
        end
    end
})
Reinject = Destruct:registerToggle({
    ['Name'] = 'Reinject'
})