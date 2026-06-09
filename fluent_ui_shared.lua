local M = {}

local function loadRemoteModule(url, label)
	if type(loadstring) ~= "function" then
		return nil, "loadstring is not available"
	end

	local ok, source = pcall(function()
		return game:HttpGet(url, true)
	end)

	if not ok or type(source) ~= "string" or source == "" then
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

local function loadLinoriaBundle()
	local Library, ThemeManager, SaveManager
	local err

	Library, err = loadRemoteModule("https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/Library.lua", "Linoria Library")
	if not Library then
		Library, err = loadRemoteModule("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua", "Linoria Library")
		if not Library then
			return nil, err
		end
	end

	ThemeManager, err = loadRemoteModule("https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/addons/ThemeManager.lua", "ThemeManager")
	if not ThemeManager then
		ThemeManager, err = loadRemoteModule("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua", "ThemeManager")
		if not ThemeManager then
			return nil, err
		end
	end

	SaveManager, err = loadRemoteModule("https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/addons/SaveManager.lua", "SaveManager")
	if not SaveManager then
		SaveManager, err = loadRemoteModule("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua", "SaveManager")
		if not SaveManager then
			return nil, err
		end
	end

	return Library, ThemeManager, SaveManager
end

local function getTitle(spec)
	if type(spec) == "table" then
		return tostring(spec.Title or spec.title or spec.Name or spec.name or "Tab")
	end
	return tostring(spec or "Tab")
end

local function getDescription(opts)
	if type(opts) ~= "table" then
		return ""
	end
	return tostring(opts.Description or opts.Tooltip or opts.Content or "")
end

local function buildTextBlock(groupbox, title, content)
	local labels = {}
	if title and title ~= "" then
		table.insert(labels, groupbox:AddLabel(title))
	end
	if content and content ~= "" then
		table.insert(labels, groupbox:AddLabel(content, true))
	end
	return labels
end

local function augmentTab(tab, tabTitle)
	tab._title = tabTitle
	tab._sections = {}
	tab._currentGroupbox = nil

	local function ensureGroupbox(title)
		if not tab._currentGroupbox then
			tab._currentGroupbox = tab:AddLeftGroupbox(title or tabTitle or "General")
			table.insert(tab._sections, tab._currentGroupbox)
		end
		return tab._currentGroupbox
	end

	function tab:AddSection(title)
		tab._currentGroupbox = tab:AddLeftGroupbox(title or "Section")
		table.insert(tab._sections, tab._currentGroupbox)
		return tab._currentGroupbox
	end

	function tab:AddParagraph(spec)
		local groupbox = tab:AddLeftGroupbox(getTitle(spec))
		table.insert(tab._sections, groupbox)
		buildTextBlock(groupbox, getTitle(spec), getDescription(spec))
		return groupbox
	end

	function tab:AddLabel(text, wrap)
		return ensureGroupbox():AddLabel(text, wrap)
	end

	function tab:AddDivider()
		return ensureGroupbox():AddDivider()
	end

	function tab:AddToggle(id, opts)
		opts = opts or {}
		return ensureGroupbox():AddToggle(id, {
			Text = opts.Text or opts.Title or id or "Toggle",
			Default = opts.Default or opts.CurrentValue or false,
			Tooltip = opts.Tooltip or opts.Description,
			Callback = opts.Callback or opts.Func,
		})
	end

	function tab:AddSlider(id, opts)
		opts = opts or {}
		return ensureGroupbox():AddSlider(id, {
			Text = opts.Text or opts.Title or id or "Slider",
			Default = opts.Default or opts.CurrentValue or 0,
			Min = (opts.Range and opts.Range[1]) or opts.Min or 0,
			Max = (opts.Range and opts.Range[2]) or opts.Max or 100,
			Rounding = opts.Rounding or opts.Increment or 1,
			Suffix = opts.Suffix or "",
			Compact = opts.Compact or false,
			Tooltip = opts.Tooltip or opts.Description,
			Callback = opts.Callback or opts.Func,
		})
	end

	function tab:AddDropdown(id, opts)
		opts = opts or {}
		return ensureGroupbox():AddDropdown(id, {
			Values = opts.Values or {},
			Multi = opts.Multi or false,
			Default = opts.Default,
			Text = opts.Text or opts.Title or id or "Dropdown",
			Tooltip = opts.Tooltip or opts.Description,
			Callback = opts.Callback or opts.Func,
		})
	end

	function tab:AddInput(id, opts)
		opts = opts or {}
		return ensureGroupbox():AddInput(id, {
			Default = opts.Default or opts.CurrentValue or "",
			Placeholder = opts.Placeholder or opts.PlaceholderText or "",
			Numeric = opts.Numeric or false,
			Finished = opts.Finished or false,
			Text = opts.Text or opts.Title or id or "Input",
			Tooltip = opts.Tooltip or opts.Description,
			Callback = opts.Callback or opts.Func,
		})
	end

	function tab:AddButton(opts)
		opts = opts or {}
		return ensureGroupbox():AddButton({
			Text = opts.Text or opts.Title or "Button",
			Func = opts.Func or opts.Callback or function() end,
			DoubleClick = opts.DoubleClick or false,
			Tooltip = opts.Tooltip or opts.Description,
		})
	end

	return tab
end

local function augmentWindow(library, window)
	window._library = library
	window._tabOrder = {}

	local rawAddTab = window.AddTab

	function window:AddTab(spec)
		local title = getTitle(spec)
		local tab = rawAddTab(self, title)
		table.insert(self._tabOrder, tab)
		return augmentTab(tab, title)
	end

	function window:SelectTab(index)
		local tab = self._tabOrder and self._tabOrder[index]
		if not tab then
			return
		end
		if type(tab.Select) == "function" then
			pcall(function()
				tab:Select()
			end)
		elseif type(tab.Show) == "function" then
			pcall(function()
				tab:Show()
			end)
		end
	end

	function window:Destroy()
		pcall(function()
			library:Unload()
		end)
	end

	return window
end

function M.loadBundle()
	local Library, ThemeManager, SaveManager = loadLinoriaBundle()
	if not Library then
		return nil, ThemeManager
	end

	local api = setmetatable({
		Options = Library.Options,
	}, {
		__index = function(_, key)
			if key == "Notify" then
				return function(_, arg)
					if type(arg) == "table" then
						local title = tostring(arg.Title or arg.title or "Notice")
						local content = tostring(arg.Content or arg.content or "")
						local duration = tonumber(arg.Duration or arg.duration) or 5
						local msg = content ~= "" and (title .. ": " .. content) or title
						return Library:Notify(msg, duration)
					end
					return Library:Notify(tostring(arg), 5)
				end
			end
			if key == "CreateWindow" then
				return function(_, opts)
					opts = opts or {}
					local window = Library:CreateWindow({
						Title = opts.Title or "Hub",
						TabWidth = opts.TabWidth,
						Size = opts.Size,
						Center = true,
						AutoShow = false,
					})
					if opts.SubTitle and window.SetSubtitle then
						pcall(function()
							window:SetSubtitle(opts.SubTitle)
						end)
					end
					if opts.Theme and ThemeManager.SetLibrary then
						pcall(function()
							ThemeManager:SetLibrary(Library)
						end)
					end
					return augmentWindow(Library, window)
				end
			end
			return Library[key]
		end,
	})

	return {
		Fluent = api,
		SaveManager = SaveManager,
		InterfaceManager = ThemeManager,
		Library = Library,
	}
end

function M.createWindow(Fluent, title, subtitle, size, tabWidth)
	local window = Fluent:CreateWindow({
		Title = title,
		SubTitle = subtitle,
		Size = size,
		TabWidth = tabWidth,
	})
	return window
end

function M.applyHeader(tab, title, content)
	if not tab then
		return
	end
	tab:AddParagraph({
		Title = title,
		Content = content,
	})
end

return M
