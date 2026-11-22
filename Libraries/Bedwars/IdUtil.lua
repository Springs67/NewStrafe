local v10 = {
    generateId = function(p1, p2)
        local v3 = p2 == nil and "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789" or p2;
        local v4 = #v3;
        local v5 = false;
        local v6 = 0;
        local v7 = "";

        while true do
            if v5 then
                v6 = v6 + 1;
            else
                v5 = true;
            end;

            if v6 >= p1 then
                return v7;
            end;

            local v8 = math.random() * v4;
            local v9 = math.floor(v8);
            v7 = v7 .. string.sub(v3, v9 + 1, v9 + 1);
        end;
    end
};
local u11 = setmetatable({}, {
    __tostring = function()
        return "IncrementingId";
    end
});
u11.__index = u11;

function u11.new(...)
    local v12 = setmetatable({}, u11);

    return v12:constructor(...) or v12;
end;

function u11.constructor(p13, p14, p15, p16)
    p13.startingNumber = p14;
    p13.maxNumber = p15;
    p13.rollOver = p16;
    p13.id = p14;
end;

function u11.getCurrId(p17)
    return p17.id;
end;

function u11.getNextId(p18)
    if p18.id + 1 > p18.maxNumber then
        if p18.rollOver then
            return p18.startingNumber;
        end;

        return p18.id;
    end;

    p18.id = p18.id + 1;

    return p18.id;
end;

v10.IncrementingId = u11;

return {
    IdUtil = v10
};
