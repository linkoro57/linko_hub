local HubUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/linkoro57/linko_hub/main/fluent_ui_shared.lua", true))()
local bundle, uiErr = HubUI.loadBundle()

if not bundle then
	warn("[Linko Hub] Failed to load Fluent UI: " .. tostring(uiErr))
	return
end

local Fluent = bundle.Fluent
local SaveManager = bundle.SaveManager
local InterfaceManager = bundle.InterfaceManager
local Library = bundle.Library

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local MeowRemote = ReplicatedStorage:WaitForChild("meow")
local NyaRemote = ReplicatedStorage:WaitForChild("nya")
local MeowConnection
local FPSConnection

local FYFPConfig = {
	FPS = {
		Enabled = false,
		Value = 400,
		Fluctuating = true,
	},
	Memory = {
		Enabled = false,
		Value = 1024,
		Fluctuating = true,
	},
	ScreenRes = {
		Enabled = false,
		Width = 1920,
		Height = 1080,
	},
	GQ = {
		Enabled = false,
		Value = 5,
	},
}

local function notify(title, content, image)
	Fluent:Notify({
		Title = title,
		Content = content,
		Duration = 5,
		Image = image or "info",
	})
end

local function safeSetValue(optionName, value)
	pcall(function()
		local option = Fluent.Options and Fluent.Options[optionName]
		if option and option.SetValue then
			option:SetValue(value)
		end
	end)
end

local function clampNumber(value, minValue, maxValue)
	return math.clamp(math.floor(tonumber(value) or minValue), minValue, maxValue)
end

local function fluctuateInteger(baseValue, spread, minValue, maxValue)
	local value = math.random(baseValue - spread, baseValue + spread)
	return math.clamp(value, minValue, maxValue)
end

local Window = HubUI.createWindow(Fluent, "Flex your FPS and Ping", "Fluent edition", UDim2.fromOffset(560, 430), 170)

local Tabs = {
	Overview = Window:AddTab({ Title = "Overview", Icon = "layout-dashboard" }),
	Spoof = Window:AddTab({ Title = "Spoof", Icon = "sliders-horizontal" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

local Options = Fluent.Options

Tabs.Overview:AddParagraph({
	Title = "What this does",
	Content = "Spoofs the values returned to the server for FPS, memory, screen resolution, and graphics quality. Fluctuating mode adds small random movement to the spoofed value.",
})

Tabs.Overview:AddSection("Quick Notes")
Tabs.Overview:AddParagraph({
	Title = "Server flow",
	Content = "The game can send a device check or a metrics request. This script answers both locally and uses the values you set in the Spoof tab.",
})

Tabs.Spoof:AddSection("FPS")
local fpsToggle = Tabs.Spoof:AddToggle("EnableFPS", {
	Title = "Enable spoofed FPS",
	Default = false,
})
fpsToggle:OnChanged(function(value)
	FYFPConfig.FPS.Enabled = value
end)

Tabs.Spoof:AddInput("FPSValue", {
	Title = "FPS value",
	Default = "400",
	Placeholder = "Spoofed FPS amount",
	Numeric = true,
	Finished = false,
	Callback = function(value)
		if tonumber(value) == nil then
			safeSetValue("FPSValue", tostring(FYFPConfig.FPS.Value))
			notify("Error", "FPS must be a number", "circle-x")
			return
		end

		local newValue = clampNumber(value, 1, 3500)
		if newValue ~= tonumber(value) then
			safeSetValue("FPSValue", tostring(newValue))
			notify("Error", "FPS can't be higher than 3500", "circle-x")
		end

		FYFPConfig.FPS.Value = newValue
	end,
})

local fpsFluctuatingToggle = Tabs.Spoof:AddToggle("EnableFluctuatingFPS", {
	Title = "Enable fluctuating FPS",
	Default = true,
})
fpsFluctuatingToggle:OnChanged(function(value)
	FYFPConfig.FPS.Fluctuating = value
end)

Tabs.Spoof:AddSection("Memory")
local memoryToggle = Tabs.Spoof:AddToggle("EnableMemory", {
	Title = "Enable spoofed memory",
	Default = false,
})
memoryToggle:OnChanged(function(value)
	FYFPConfig.Memory.Enabled = value
end)

Tabs.Spoof:AddInput("MemoryValue", {
	Title = "Memory value",
	Default = "1024",
	Placeholder = "Spoofed memory amount",
	Numeric = true,
	Finished = false,
	Callback = function(value)
		if tonumber(value) == nil then
			safeSetValue("MemoryValue", tostring(FYFPConfig.Memory.Value))
			notify("Error", "Memory must be a number", "circle-x")
			return
		end

		FYFPConfig.Memory.Value = clampNumber(value, 1, 999999)
	end,
})

local memoryFluctuatingToggle = Tabs.Spoof:AddToggle("EnableFluctuatingMemory", {
	Title = "Enable fluctuating memory",
	Default = true,
})
memoryFluctuatingToggle:OnChanged(function(value)
	FYFPConfig.Memory.Fluctuating = value
end)

Tabs.Spoof:AddSection("Display")
local screenToggle = Tabs.Spoof:AddToggle("EnableScreenRes", {
	Title = "Enable spoofed screen resolution",
	Default = false,
})
screenToggle:OnChanged(function(value)
	FYFPConfig.ScreenRes.Enabled = value
end)

Tabs.Spoof:AddInput("ScreenResWidth", {
	Title = "Screen width",
	Default = "1920",
	Placeholder = "Spoofed screen width",
	Numeric = true,
	Finished = false,
	Callback = function(value)
		if tonumber(value) == nil then
			safeSetValue("ScreenResWidth", tostring(FYFPConfig.ScreenRes.Width))
			notify("Error", "Screen width must be a number", "circle-x")
			return
		end

		FYFPConfig.ScreenRes.Width = clampNumber(value, 1, 99999)
	end,
})

Tabs.Spoof:AddInput("ScreenResHeight", {
	Title = "Screen height",
	Default = "1080",
	Placeholder = "Spoofed screen height",
	Numeric = true,
	Finished = false,
	Callback = function(value)
		if tonumber(value) == nil then
			safeSetValue("ScreenResHeight", tostring(FYFPConfig.ScreenRes.Height))
			notify("Error", "Screen height must be a number", "circle-x")
			return
		end

		FYFPConfig.ScreenRes.Height = clampNumber(value, 1, 99999)
	end,
})

Tabs.Spoof:AddSection("Graphics Quality")
local gqToggle = Tabs.Spoof:AddToggle("EnableGQ", {
	Title = "Enable spoofed graphics quality",
	Default = false,
})
gqToggle:OnChanged(function(value)
	FYFPConfig.GQ.Enabled = value
end)

Tabs.Spoof:AddSlider("GQValue", {
	Title = "Graphics quality",
	Description = "0 = Automatic",
	Default = 5,
	Min = 0,
	Max = 10,
	Rounding = 0,
	Callback = function(value)
		FYFPConfig.GQ.Value = clampNumber(value, 0, 10)
	end,
})

Tabs.Settings:AddSection("Interface")
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("LinkoHub")
SaveManager:SetFolder("LinkoHub/FlexYourFpsAndPing")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Tabs.Settings:AddSection("Defaults")
Tabs.Settings:AddButton({
	Title = "Close UI",
	Description = "Destroys the interface and disconnects listeners.",
	Callback = function()
		pcall(function()
			Window:Destroy()
		end)

		if MeowConnection then
			MeowConnection:Disconnect()
			MeowConnection = nil
		end

		if FPSConnection then
			FPSConnection:Disconnect()
			FPSConnection = nil
		end
	end,
})

Tabs.Settings:AddButton({
	Title = "Reset to defaults",
	Description = "Restores the UI fields to the original values used by the script.",
	Callback = function()
		FYFPConfig.FPS.Enabled = false
		FYFPConfig.FPS.Value = 400
		FYFPConfig.FPS.Fluctuating = true
		FYFPConfig.Memory.Enabled = false
		FYFPConfig.Memory.Value = 1024
		FYFPConfig.Memory.Fluctuating = true
		FYFPConfig.ScreenRes.Enabled = false
		FYFPConfig.ScreenRes.Width = 1920
		FYFPConfig.ScreenRes.Height = 1080
		FYFPConfig.GQ.Enabled = false
		FYFPConfig.GQ.Value = 5

		safeSetValue("EnableFPS", false)
		safeSetValue("FPSValue", "400")
		safeSetValue("EnableFluctuatingFPS", true)
		safeSetValue("EnableMemory", false)
		safeSetValue("MemoryValue", "1024")
		safeSetValue("EnableFluctuatingMemory", true)
		safeSetValue("EnableScreenRes", false)
		safeSetValue("ScreenResWidth", "1920")
		safeSetValue("ScreenResHeight", "1080")
		safeSetValue("EnableGQ", false)
		safeSetValue("GQValue", 5)

		notify("Reset", "Values were restored to defaults.", "refresh-cw")
	end,
})

local frameCount = 0
local lastClock = os.clock()
local fps = 0

FPSConnection = RunService.Heartbeat:Connect(function()
	frameCount += 1
	local currentTime = os.clock()
	if currentTime - lastClock < 1 then
		return
	end

	fps = frameCount
	frameCount = 0
	lastClock = currentTime
end)

local QLM = {
	["0"] = Enum.SavedQualitySetting.Automatic,
	["1"] = Enum.SavedQualitySetting.QualityLevel1,
	["2"] = Enum.SavedQualitySetting.QualityLevel2,
	["3"] = Enum.SavedQualitySetting.QualityLevel3,
	["4"] = Enum.SavedQualitySetting.QualityLevel4,
	["5"] = Enum.SavedQualitySetting.QualityLevel5,
	["6"] = Enum.SavedQualitySetting.QualityLevel6,
	["7"] = Enum.SavedQualitySetting.QualityLevel7,
	["8"] = Enum.SavedQualitySetting.QualityLevel8,
	["9"] = Enum.SavedQualitySetting.QualityLevel9,
	["10"] = Enum.SavedQualitySetting.QualityLevel10,
}

local function getDefaultSetting(flag)
	if flag == "FPS" then
		return fps
	elseif flag == "Memory" then
		return Stats:GetTotalMemoryUsageMb()
	elseif flag == "ScreenRes" then
		return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(0, 0)
	elseif flag == "GQ" then
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end

	return nil
end

local function getSetting(flag)
	local config = FYFPConfig[flag]
	if not config.Enabled then
		return getDefaultSetting(flag)
	end

	if config.Fluctuating ~= nil and config.Fluctuating then
		local value = config.Value
		if flag == "FPS" then
			return fluctuateInteger(value, 10, 1, 3500)
		elseif flag == "Memory" then
			return math.max(1, math.random() * 1.8 + (value - 0.9))
		end
	end

	if flag == "ScreenRes" then
		return Vector2.new(config.Width, config.Height)
	end

	if flag == "GQ" then
		return QLM[tostring(config.Value)]
	end

	return config.Value
end

local function getDeviceData()
	return {
		A = UserInputService.VREnabled,
		B = GuiService:IsTenFootInterface(),
		C = GuiService.IsWindows,
		D = "0.716.0.7160875",
		E = UserInputService.GyroscopeEnabled or UserInputService.AccelerometerEnabled,
		F = UserInputService.TouchEnabled,
		G = UserInputService.KeyboardEnabled,
		H = UserInputService.MouseEnabled,
		I = TextService:GetTextSize(utf8.char(65535), 16, "SourceSans", Vector2.one * 1000)
			~= TextService:GetTextSize(utf8.char(63743), 16, "SourceSans", Vector2.one * 1000),
	}
end

MeowConnection = MeowRemote.OnClientEvent:Connect(function(arg)

	if type(arg) ~= "table" then
		return
	end

	if arg.t == "device" and type(arg.token) == "number" then
		NyaRemote:FireServer({
			t = "device",
			token = arg.token,
			tbl = getDeviceData(),
		})
	elseif arg.t == "metrics" and type(arg.token) == "number" then
		NyaRemote:FireServer({
			t = "metrics",
			token = arg.token,
			fps = getSetting("FPS"),
			gfx = getSetting("GQ"),
			mem = getSetting("Memory"),
			res = getSetting("ScreenRes"),
		})
	end
end)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
