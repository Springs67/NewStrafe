local downloadFile = shared.downloadFile
local Entity = shared.Entity

local Animations = loadstring(downloadFile('Libraries/Bedwars/Animations.lua'))()
local Sounds = loadstring(downloadFile('Libraries/Bedwars/Sounds.lua'))()

local GameUtil = {
    AnimationUtil = {},
    SoundUtil = {},
}

function GameUtil.AnimationUtil.playAnimation(name: string, animator: Animator)
    if not Animations.ProdAnimations[name] then
        return
    end

    if not animator then
        animator = Entity.Self.Humanoid
    end

    local Animation
    if animator:FindFirstChild(name) then
        Animation = animator:FindFirstChild(name)
    else
        Animation = Instance.new('Animation')
        Animation.Parent = animator
        Animation.Name = name
        Animation.AnimationId = Animations.ProdAnimations[name]
    end

    local AnimationLoaded = animator:LoadAnimation(Animation)
    AnimationLoaded.Looped = false
    AnimationLoaded:Play()

    return AnimationLoaded
end

function GameUtil.SoundUtil.playSound(name: string, root: Part)
    if not Sounds.GameSound[name] then
        return
    end

    if not root then
        root = Entity.Self.Root
    end

    local Sound
    if root:FindFirstChild(name) then
        Sound = root:FindFirstChild(name)
    else
        Sound = Instance.new('Sound')
        Sound.Parent = root
        Sound.Name = name
        Sound.SoundId = Sounds.GameSound[name]
    end

    Sound.Volume = 0.25
    Sound:Play()
end

return GameUtil