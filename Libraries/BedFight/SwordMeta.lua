local AnimationsData = loadstring(shared.downloadFile('Libraries/BedFight/AnimationsData.lua'))();
local u1 = {
    X = 30,
    Y = 20
};
local u2 = CFrame.new(0, 2, 0);

local u4 = {
    DefaultAnimation = AnimationsData.Swords,
    ["Wooden Sword"] = {
        AnimationCooldown = 0.1,
        DamageCooldown = 0.3,
        Range = 5,
        Damage = 20,
        HitboxSize = Vector3.new(4, 4, 11),
        KnockbackPower = u1,
        Offset = u2
    },
    ["Stone Sword"] = {
        AnimationCooldown = 0.1,
        DamageCooldown = 0.3,
        Range = 5,
        Damage = 25,
        HitboxSize = Vector3.new(4, 4, 11),
        KnockbackPower = u1,
        Offset = u2
    },
    ["Iron Sword"] = {
        AnimationCooldown = 0.1,
        DamageCooldown = 0.3,
        Range = 5,
        Damage = 30,
        HitboxSize = Vector3.new(4, 4, 11),
        KnockbackPower = u1,
        Offset = u2
    },
    ["Diamond Sword"] = {
        AnimationCooldown = 0.1,
        DamageCooldown = 0.3,
        Range = 5,
        Damage = 35,
        HitboxSize = Vector3.new(4, 4, 11),
        KnockbackPower = u1,
        Offset = u2
    },
    ["Emerald Sword"] = {
        AnimationCooldown = 0.1,
        DamageCooldown = 0.3,
        Range = 5,
        Damage = 40,
        HitboxSize = Vector3.new(4, 4, 11),
        KnockbackPower = u1,
        Offset = u2
    },
    Pan = {
        AnimationCooldown = 0.1,
        DamageCooldown = 0.3,
        Range = 5,
        Damage = 5,
        HitboxSize = Vector3.new(4, 4, 11),
        KnockbackPower = {
            X = 50,
            Y = 30
        },
        Offset = u2
    }
};

return table.freeze(u4);