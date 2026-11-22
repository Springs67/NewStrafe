if shared.GuiLibrary then
    shared.GuiLibrary:Destroy()
    shared.GuiLibrary = nil

    task.wait(0.5)
end

local Developer = true --shared.Developer or false
local Debugging = shared.Debugging or false

local lplr = cloneref(game:GetService('Players')).LocalPlayer

repeat
    task.wait()
    lplr = cloneref(game:GetService('Players')).LocalPlayer
until lplr

if isfolder('Strafe') and not isfile('Strafe/Data.lua') then
    delfolder('Strafe')
end

if not isfolder('Strafe') then
    for i, v in {'Strafe', 'Strafe/Games', 'Strafe/Configs', 'Strafe/Libraries', 'Strafe/Assets'} do
        makefolder(v)
    end
end

if not isfile('Strafe/Assets/checkmark.png') then
    for i, v in {'checkmark.png', 'warning.png', 'x.png'} do
        writefile('Strafe/Assets/' .. v, game:HttpGet('https://raw.githubusercontent.com/Springs67/NewStrafe/refs/heads/Main/Assets/' .. v))
    end
end

local downloadFile = function(path: string)
    path = path:gsub('Strafe/', '')

    if Debugging then
        print(path)
    end

    if Developer then
        return readfile('Strafe/' .. path)
    end

    local newContent = game:HttpGet('https://raw.githubusercontent.com/Springs67/NewStrafe/refs/heads/Main/'..path)
    local oldContent = isfile('Strafe/' .. path) and readfile('Strafe/' .. path) or ''

    if newContent ~= oldContent then
        writefile(
            'Strafe/' .. path,
            game:HttpGet('https://raw.githubusercontent.com/Springs67/NewStrafe/refs/heads/Main/'..path)
        )

        repeat task.wait(0.5) until isfile('Strafe/' .. path)

        return readfile('Strafe/' .. path)
    end

    return readfile('Strafe/' .. path)
end

if shared.onTeleport then
    shared.onTeleport:Disconnect()
    shared.onTeleport = nil
end

shared.Uninjected = false
shared.onTeleport = lplr.OnTeleport:Once(function()
    local str = ''

    if Developer then
        str = 'shared.Developer = true;'
    end

    if Debugging then
        str = str .. ' shared.Debugging = true;'
    end

    str = str .. 'shared.Destroyed = ' .. tostring(shared.Uninjected) .. ';'
    str = str .. ' if shared.Destroyed then return end; loadfile("Strafe/Main.lua")()'

    queue_on_teleport(str);
end)

shared.downloadFile = downloadFile
shared.GuiLibrary = loadstring(downloadFile('GuiLibrary.lua'))()
shared.Entity = loadstring(downloadFile('Libraries/Entity.lua'))()
shared.Data = loadstring(downloadFile('Data.lua'))()

loadstring(downloadFile('Games/Universal.lua'))()

local Games = loadstring(downloadFile('Games.lua'))()

for index, value in Games do
    for _, id in value do
        if game.PlaceId == id then
            loadstring(downloadFile('Games/'.. index ..'.lua'))()
        end
    end
end