local M = {}

local function loadRemoteModule(url, label)
	if type(loadstring) ~= "function" then
		return nil, "loadstring is not available"
	end

	local fetchOk, source = pcall(function()
		return game:HttpGet(url, true)
	end)

	if not fetchOk or type(source) ~= "string" or source == "" then
		return nil, "download failed: " .. tostring(source)
	end

	local chunk, compileErr = loadstring(source)
	if type(chunk) ~= "function" then
		return nil, "compile failed: " .. tostring(compileErr)
	end

	local runOk, result = pcall(chunk)
	if not runOk then
		return nil, "runtime failed: " .. tostring(result)
	end

	if result == nil then
		return nil, label .. " returned nil"
	end

	return result
end

function M.loadBundle()
	local Fluent, SaveManager, InterfaceManager
	local err

	Fluent, err = loadRemoteModule("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", "Fluent")
	if not Fluent then
		return nil, err
	end

	SaveManager, err = loadRemoteModule("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua", "SaveManager")
	if not SaveManager then
		return nil, err
	end

	InterfaceManager, err = loadRemoteModule("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua", "InterfaceManager")
	if not InterfaceManager then
		return nil, err
	end

	return {
		Fluent = Fluent,
		SaveManager = SaveManager,
		InterfaceManager = InterfaceManager,
	}
end

function M.createWindow(Fluent, title, subtitle, size, tabWidth)
	return Fluent:CreateWindow({
		Title = title,
		SubTitle = subtitle,
		TabWidth = tabWidth or 170,
		Size = size or UDim2.fromOffset(560, 430),
		Acrylic = false,
		Theme = "Darker",
		MinimizeKey = Enum.KeyCode.LeftControl,
	})
end

function M.applyHeader(tab, title, content)
	if tab and tab.AddParagraph then
		tab:AddParagraph({
			Title = title,
			Content = content,
		})
	end
end

return M
