local Players = game:GetService("Players")
local player = Players.LocalPlayer

local HUB_BASE = "https://raw.githubusercontent.com/linkoro57/linko_hub/main/"

local TARGETS = {
    [124473577469410] = {
        name = "Be a Lucky Block",
        path = "be-a-lucky-block.lua",
    },
    [18667984660] = {
        name = "Flex Your FPS and Your Ping",
        path = "flex-your-fps-and-your-ping.lua",
    },
    [96017656548489] = {
        name = "Ban or Be Banned",
        path = "ban-or-be-banned.lua",
    },
}

local function runRemoteScript(path, label)
    local source = HUB_BASE .. path
    if type(loadstring) ~= "function" then
        warn("[linkoro57] Your executor does not support loadstring.")
        return
    end

    local fetchOk, scriptSource = pcall(function()
        return game:HttpGet(source, true)
    end)

    if not fetchOk or type(scriptSource) ~= "string" or scriptSource == "" then
        warn(string.format("[linkoro57] Failed to download %s (%s): %s", label, source, tostring(scriptSource)))
        return
    end

    local chunk, compileErr = loadstring(scriptSource)
    if type(chunk) ~= "function" then
        warn(string.format("[linkoro57] Failed to compile %s (%s): %s", label, source, tostring(compileErr)))
        return
    end

    local ok, err = pcall(chunk)

    if not ok then
        warn(string.format("[linkoro57] Failed to load %s (%s): %s", label, source, tostring(err)))
    end
end

local placeId = game.PlaceId
local target = TARGETS[placeId]

if target then
    print(string.format("[linkoro57] Loading %s...", target.name))
    runRemoteScript(target.path, target.name)
else
    player:Kick("This game is not supported")
end
