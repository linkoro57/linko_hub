local LinkoUI
local uiOk, uiErr = pcall(function()
    LinkoUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/linkoro57/linko_hub/refs/heads/main/linko_ui.lua"))()
end)

if not uiOk or not LinkoUI then
    warn("[linkoro57] Failed to load custom UI: " .. tostring(uiErr))
    return
end

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Window = LinkoUI:CreateWindow({
    Title = "Flex Your FPS and Your Ping",
    SubTitle = "by linkoro57",
    TabWidth = 170,
    Size = UDim2.fromOffset(580, 410),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "gauge" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "sparkles" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

local state = {
    lowGraphics = false,
    hideEffects = false,
    disableShadows = false,
    hideParticles = false,
    reduceWater = false,
    connection = nil,
    savedLighting = {},
    savedEffects = {},
    savedTerrain = {},
}

local effectClasses = {
    BloomEffect = true,
    BlurEffect = true,
    ColorCorrectionEffect = true,
    DepthOfFieldEffect = true,
    SunRaysEffect = true,
    Atmosphere = true,
}

local emitterClasses = {
    ParticleEmitter = true,
    Trail = true,
    Beam = true,
    Smoke = true,
    Fire = true,
    Sparkles = true,
}

local function saveProp(instance, prop, bucket)
    bucket = bucket or state.savedLighting
    local key = instance:GetDebugId() .. ":" .. prop
    if bucket[key] == nil then
        local ok, value = pcall(function()
            return instance[prop]
        end)
        if ok then
            bucket[key] = value
        end
    end
end

local function restoreProp(instance, prop, bucket)
    bucket = bucket or state.savedLighting
    local key = instance:GetDebugId() .. ":" .. prop
    local value = bucket[key]
    if value ~= nil then
        pcall(function()
            instance[prop] = value
        end)
        bucket[key] = nil
    end
end

local function setEffectDisabled(instance, disabled)
    if instance:IsA("Atmosphere") then
        if disabled then
            saveProp(instance, "Density", state.savedEffects)
            saveProp(instance, "Haze", state.savedEffects)
            saveProp(instance, "Glare", state.savedEffects)
            pcall(function() instance.Density = 0 end)
            pcall(function() instance.Haze = 0 end)
            pcall(function() instance.Glare = 0 end)
        else
            restoreProp(instance, "Density", state.savedEffects)
            restoreProp(instance, "Haze", state.savedEffects)
            restoreProp(instance, "Glare", state.savedEffects)
        end
        return
    end

    if disabled then
        saveProp(instance, "Enabled", state.savedEffects)
        pcall(function()
            instance.Enabled = false
        end)
    else
        restoreProp(instance, "Enabled", state.savedEffects)
        if state.savedEffects[instance:GetDebugId() .. ":Enabled"] == nil then
            pcall(function()
                instance.Enabled = true
            end)
        end
    end
end

local function applyLightingBoosts()
    if state.disableShadows then
        saveProp(Lighting, "GlobalShadows", state.savedLighting)
        pcall(function() Lighting.GlobalShadows = false end)
    else
        restoreProp(Lighting, "GlobalShadows", state.savedLighting)
    end

    if state.lowGraphics then
        saveProp(Lighting, "Brightness", state.savedLighting)
        saveProp(Lighting, "ClockTime", state.savedLighting)
        saveProp(Lighting, "ExposureCompensation", state.savedLighting)
        pcall(function() Lighting.Brightness = 1 end)
        pcall(function() Lighting.ClockTime = 12 end)
        pcall(function() Lighting.ExposureCompensation = 0 end)
    else
        restoreProp(Lighting, "Brightness", state.savedLighting)
        restoreProp(Lighting, "ClockTime", state.savedLighting)
        restoreProp(Lighting, "ExposureCompensation", state.savedLighting)
    end

    for _, child in ipairs(Lighting:GetChildren()) do
        if effectClasses[child.ClassName] then
            setEffectDisabled(child, state.hideEffects)
        end
    end
end

local function applyTerrainBoosts()
    local terrain = Workspace.Terrain

    if state.reduceWater then
        saveProp(terrain, "WaterWaveSize", state.savedTerrain)
        saveProp(terrain, "WaterWaveSpeed", state.savedTerrain)
        saveProp(terrain, "WaterReflectance", state.savedTerrain)
        pcall(function() terrain.WaterWaveSize = 0 end)
        pcall(function() terrain.WaterWaveSpeed = 0 end)
        pcall(function() terrain.WaterReflectance = 0 end)
    else
        restoreProp(terrain, "WaterWaveSize", state.savedTerrain)
        restoreProp(terrain, "WaterWaveSpeed", state.savedTerrain)
        restoreProp(terrain, "WaterReflectance", state.savedTerrain)
    end
end

local function refreshBoosts()
    applyLightingBoosts()
    applyTerrainBoosts()

    if state.hideParticles then
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if emitterClasses[descendant.ClassName] then
                setEffectDisabled(descendant, true)
            end
        end
    end
end

local function startWatcher()
    if state.connection then
        state.connection:Disconnect()
        state.connection = nil
    end

    state.connection = Workspace.DescendantAdded:Connect(function(instance)
        if state.hideParticles and emitterClasses[instance.ClassName] then
            setEffectDisabled(instance, true)
        elseif state.hideEffects and effectClasses[instance.ClassName] then
            setEffectDisabled(instance, true)
        end
    end)
end

local function updateWatcher()
    if state.lowGraphics or state.hideEffects or state.hideParticles then
        startWatcher()
    elseif state.connection then
        state.connection:Disconnect()
        state.connection = nil
    end
end

local function restoreAll()
    state.lowGraphics = false
    state.hideEffects = false
    state.disableShadows = false
    state.hideParticles = false
    state.reduceWater = false
    refreshBoosts()
    updateWatcher()
    LinkoUI:Notify({
        Title = "Restored",
        Content = "Performance settings have been returned to defaults.",
        Duration = 3,
    })
end

Tabs.Main:AddSection("Performance")
Tabs.Main:AddParagraph({
    Title = "Clean FPS boost",
    Content = "This module focuses on visual cleanup and client-side rendering reductions to make the game feel lighter.",
})

local LowGraphicsToggle = Tabs.Main:AddToggle("LowGraphicsToggle", {
    Title = "Low Graphics Mode",
    Description = "Lightens the scene and reduces visual load.",
    Default = false,
})

LowGraphicsToggle:OnChanged(function(stateValue)
    state.lowGraphics = stateValue
    refreshBoosts()
    updateWatcher()
end)

local DisableShadowsToggle = Tabs.Visuals:AddToggle("DisableShadowsToggle", {
    Title = "Disable Shadows",
    Description = "Reduces lighting cost on the client.",
    Default = false,
})

DisableShadowsToggle:OnChanged(function(stateValue)
    state.disableShadows = stateValue
    refreshBoosts()
end)

local HideEffectsToggle = Tabs.Visuals:AddToggle("HideEffectsToggle", {
    Title = "Remove Post Effects",
    Description = "Disables blur, bloom, rays, and similar effects.",
    Default = false,
})

HideEffectsToggle:OnChanged(function(stateValue)
    state.hideEffects = stateValue
    refreshBoosts()
    updateWatcher()
end)

local HideParticlesToggle = Tabs.Visuals:AddToggle("HideParticlesToggle", {
    Title = "Hide Particles",
    Description = "Suppresses particles, beams, trails, smoke, fire, and sparkles.",
    Default = false,
})

HideParticlesToggle:OnChanged(function(stateValue)
    state.hideParticles = stateValue
    refreshBoosts()
    updateWatcher()
end)

local ReduceWaterToggle = Tabs.Visuals:AddToggle("ReduceWaterToggle", {
    Title = "Reduce Water Effects",
    Description = "Turns down terrain water settings for a lighter scene.",
    Default = false,
})

ReduceWaterToggle:OnChanged(function(stateValue)
    state.reduceWater = stateValue
    refreshBoosts()
end)

Tabs.Settings:AddSection("Controls")
Tabs.Settings:AddButton({
    Title = "Restore Defaults",
    Callback = restoreAll,
})

Tabs.Settings:AddParagraph({
    Title = "Notes",
    Content = "This is a client-side visual booster. It improves FPS by reducing render load; it does not alter real network latency.",
})

Window:SelectTab(1)

task.spawn(function()
    task.wait(0.4)
    LinkoUI:Notify({
        Title = "Performance module",
        Content = "Unified UI loaded. Visual boosters are ready.",
        Duration = 3,
    })
end)
