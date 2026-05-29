local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local function getUiParent()
    local ok, parent = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
        return game:GetService("CoreGui")
    end)

    if ok and parent then
        return parent
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function new(className, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    return object
end

local function round(value, step)
    step = step or 1
    return math.floor((value / step) + 0.5) * step
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function tween(object, properties, duration)
    local info = TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local success = pcall(function()
        TweenService:Create(object, info, properties):Play()
    end)
    if not success then
        for key, value in pairs(properties) do
            object[key] = value
        end
    end
end

local UI = {
    Options = {},
}

local palette = {
    background = Color3.fromRGB(10, 14, 22),
    panel = Color3.fromRGB(17, 23, 34),
    panelAlt = Color3.fromRGB(22, 30, 44),
    stroke = Color3.fromRGB(40, 51, 72),
    accent = Color3.fromRGB(87, 166, 255),
    accentSoft = Color3.fromRGB(52, 108, 170),
    text = Color3.fromRGB(240, 244, 252),
    subtext = Color3.fromRGB(156, 170, 193),
    success = Color3.fromRGB(76, 201, 143),
    danger = Color3.fromRGB(255, 97, 97),
}

local fonts = {
    title = Enum.Font.GothamBlack,
    bold = Enum.Font.GothamSemibold,
    regular = Enum.Font.Gotham,
}

local function makeCard(parent, height)
    local frame = new("Frame", {
        Parent = parent,
        BackgroundColor3 = palette.panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 70),
    })
    new("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 14) })
    new("UIStroke", { Parent = frame, Color = palette.stroke, Thickness = 1, Transparency = 0.18 })
    return frame
end

local function makeLabel(parent, text, size, bold, color)
    return new("TextLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Font = bold and fonts.bold or fonts.regular,
        Text = text or "",
        TextColor3 = color or palette.text,
        TextSize = size or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        RichText = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
end

function UI:Notify(config)
    config = config or {}

    if not self._notificationsRoot then
        self._notificationsRoot = new("ScreenGui", {
            Name = "LinkoHubNotifications",
            Parent = getUiParent(),
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })

        self._notificationHolder = new("Frame", {
            Parent = self._notificationsRoot,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -18, 0, 18),
            Size = UDim2.new(0, 320, 1, -36),
        })

        local layout = new("UIListLayout", {
            Parent = self._notificationHolder,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
        })

        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
    end

    local card = new("Frame", {
        Parent = self._notificationHolder,
        BackgroundColor3 = palette.panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 82),
    })
    new("UICorner", { Parent = card, CornerRadius = UDim.new(0, 14) })
    new("UIStroke", { Parent = card, Color = palette.stroke, Thickness = 1, Transparency = 0.18 })

    local accent = new("Frame", {
        Parent = card,
        BackgroundColor3 = config.Color or palette.accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 4, 1, 0),
    })
    new("UICorner", { Parent = accent, CornerRadius = UDim.new(0, 14) })

    makeLabel(card, config.Title or "Notification", 15, true).Position = UDim2.new(0, 16, 0, 12)
    local body = makeLabel(card, config.Content or "", 13, false, palette.subtext)
    body.Position = UDim2.new(0, 16, 0, 34)
    body.Size = UDim2.new(1, -28, 0, 36)

    card.BackgroundTransparency = 1
    accent.BackgroundTransparency = 1
    tween(card, { BackgroundTransparency = 0 }, 0.16)
    tween(accent, { BackgroundTransparency = 0 }, 0.16)

    local duration = tonumber(config.Duration) or 3
    task.delay(duration, function()
        if card and card.Parent then
            tween(card, { BackgroundTransparency = 1 }, 0.18)
            tween(accent, { BackgroundTransparency = 1 }, 0.18)
            task.wait(0.2)
            if card and card.Parent then
                card:Destroy()
            end
        end
    end)
end

function UI:CreateWindow(config)
    config = config or {}

    local window = {
        Title = config.Title or "Linko Hub",
        SubTitle = config.SubTitle or "",
        Options = UI.Options,
        _tabs = {},
        _activeTab = nil,
        _defaultSize = config.Size or UDim2.fromOffset(620, 440),
        _minimized = false,
    }

    local screenGui = new("ScreenGui", {
        Name = "LinkoHubUI",
        Parent = getUiParent(),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    local main = new("Frame", {
        Parent = screenGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = palette.background,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = window._defaultSize,
    })
    main.ClipsDescendants = true
    new("UICorner", { Parent = main, CornerRadius = UDim.new(0, 18) })
    new("UIStroke", { Parent = main, Color = palette.stroke, Thickness = 1, Transparency = 0.12 })

    local ambient = new("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, -40, 0, -40),
        Size = UDim2.new(1, 80, 1, 80),
    })
    local ambientGradient = new("UIGradient", {
        Parent = ambient,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 128, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 24, 38)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 16)),
        }),
        Rotation = 32,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(0.5, 1),
            NumberSequenceKeypoint.new(1, 0.84),
        }),
    })

    local gradient = new("UIGradient", {
        Parent = main,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 23, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 13, 20)),
        }),
        Rotation = 90,
    })
    gradient.Offset = Vector2.new(0, 0)

    task.spawn(function()
        local t = 0
        while screenGui.Parent do
            t += RunService.Heartbeat:Wait()
            ambientGradient.Rotation = 32 + math.sin(t * 0.15) * 5
            ambientGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.84 + (math.sin(t * 0.2) * 0.02)),
                NumberSequenceKeypoint.new(0.5, 1),
                NumberSequenceKeypoint.new(1, 0.86 + (math.cos(t * 0.18) * 0.02)),
            })
        end
    end)

    local topBar = new("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 62),
    })

    local header = new("Frame", {
        Parent = topBar,
        BackgroundColor3 = palette.panelAlt,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 12),
        Size = UDim2.new(1, -28, 0, 38),
    })
    new("UICorner", { Parent = header, CornerRadius = UDim.new(0, 12) })
    new("UIStroke", { Parent = header, Color = palette.stroke, Thickness = 1, Transparency = 0.2 })

    local headerGlow = new("Frame", {
        Parent = header,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
    })
    new("UICorner", { Parent = headerGlow, CornerRadius = UDim.new(0, 12) })
    new("UIGradient", {
        Parent = headerGlow,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        }),
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.96),
            NumberSequenceKeypoint.new(0.5, 0.88),
            NumberSequenceKeypoint.new(1, 0.98),
        }),
    })

    local titleBlock = new("Frame", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 5),
        Size = UDim2.new(1, -120, 1, -10),
    })
    local title = makeLabel(titleBlock, window.Title, 18, true, palette.text)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Font = fonts.title
    title.Size = UDim2.new(1, 0, 0, 20)
    local subtitle = makeLabel(titleBlock, window.SubTitle, 12, false, palette.subtext)
    subtitle.Position = UDim2.new(0, 0, 0, 20)
    subtitle.Size = UDim2.new(1, 0, 0, 14)
    subtitle.Text = string.format("%s  |  Custom Hub", window.SubTitle ~= "" and window.SubTitle or "Linko UI")

    local brandPill = new("TextLabel", {
        Parent = header,
        BackgroundColor3 = Color3.fromRGB(22, 31, 46),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(1, -146, 0.5, 0),
        Size = UDim2.new(0, 92, 0, 22),
        Font = fonts.bold,
        Text = "LINKO HUB",
        TextColor3 = palette.accent,
        TextSize = 11,
    })
    brandPill.TextTransparency = 0.03
    new("UICorner", { Parent = brandPill, CornerRadius = UDim.new(1, 0) })
    new("UIStroke", { Parent = brandPill, Color = palette.accent, Thickness = 1, Transparency = 0.5 })
    new("UIPadding", {
        Parent = brandPill,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })

    local closeButton = new("TextButton", {
        Parent = header,
        BackgroundColor3 = Color3.fromRGB(45, 26, 28),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "X",
        TextColor3 = palette.text,
        TextSize = 12,
        AutoButtonColor = false,
    })
    new("UICorner", { Parent = closeButton, CornerRadius = UDim.new(0, 8) })

    local minimizeButton = new("TextButton", {
        Parent = header,
        BackgroundColor3 = Color3.fromRGB(33, 43, 58),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -44, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "–",
        TextColor3 = palette.text,
        TextSize = 16,
        AutoButtonColor = false,
    })
    new("UICorner", { Parent = minimizeButton, CornerRadius = UDim.new(0, 8) })

    local body = new("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 62),
        Size = UDim2.new(1, 0, 1, -62),
    })

    local sidebar = new("Frame", {
        Parent = body,
        BackgroundColor3 = palette.panelAlt,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, config.TabWidth or 168, 1, -14),
    })
    new("UICorner", { Parent = sidebar, CornerRadius = UDim.new(0, 16) })
    new("UIStroke", { Parent = sidebar, Color = palette.stroke, Thickness = 1, Transparency = 0.2 })

    local sidebarHeader = new("Frame", {
        Parent = sidebar,
        BackgroundColor3 = Color3.fromRGB(14, 19, 29),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(1, -20, 0, 72),
    })
    new("UICorner", { Parent = sidebarHeader, CornerRadius = UDim.new(0, 14) })
    new("UIStroke", { Parent = sidebarHeader, Color = palette.stroke, Thickness = 1, Transparency = 0.32 })
    local sidebarHeaderTitle = makeLabel(sidebarHeader, "Workspace", 13, true)
    sidebarHeaderTitle.Position = UDim2.new(0, 12, 0, 10)
    sidebarHeaderTitle.Size = UDim2.new(1, -24, 0, 18)
    local sidebarHeaderBody = makeLabel(sidebarHeader, "Cleaner tabs. Sharper flow.", 11, false, palette.subtext)
    sidebarHeaderBody.Position = UDim2.new(0, 12, 0, 32)
    sidebarHeaderBody.Size = UDim2.new(1, -24, 0, 28)

    local tabList = new("Frame", {
        Parent = sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 92),
        Size = UDim2.new(1, -20, 1, -102),
    })
    local tabLayout = new("UIListLayout", {
        Parent = tabList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })

    local content = new("Frame", {
        Parent = body,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, (config.TabWidth or 168) + 28, 0, 0),
        Size = UDim2.new(1, -(config.TabWidth or 168) - 42, 1, -14),
    })

    local pages = new("Folder", { Parent = content })

    local function setMinimized(state)
        window._minimized = state
        for _, child in ipairs(body:GetChildren()) do
            if child:IsA("GuiObject") then
                child.Visible = not state
            end
        end
        if state then
            main.Size = UDim2.new(window._defaultSize.X.Scale, window._defaultSize.X.Offset, 0, 62)
        else
            main.Size = window._defaultSize
        end
    end

    minimizeButton.MouseButton1Click:Connect(function()
        setMinimized(not window._minimized)
    end)

    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        if UI._notificationsRoot then
            UI._notificationsRoot:Destroy()
            UI._notificationsRoot = nil
            UI._notificationHolder = nil
        end
    end)

    do
        local dragging = false
        local dragStart = nil
        local startPos = nil

        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
            end
        end)

        header.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPos then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    local function showTab(tab)
        if window._activeTab == tab then
            return
        end

        if window._activeTab then
            window._activeTab.Button.BackgroundColor3 = palette.panelAlt
            window._activeTab.Button.TextColor3 = palette.text
            window._activeTab.Page.Visible = false
        end

        window._activeTab = tab
        tab.Button.BackgroundColor3 = palette.accentSoft
        tab.Button.TextColor3 = Color3.new(1, 1, 1)
        tab.Page.Visible = true
    end

    function window:SelectTab(target)
        if typeof(target) == "number" then
            local tab = self._tabs[target]
            if tab then
                showTab(tab)
            end
            return
        end

        if typeof(target) == "string" then
            for _, tab in ipairs(self._tabs) do
                if tab.Name == target then
                    showTab(tab)
                    return
                end
            end
        end
    end

    local function addTab(tabConfig)
        tabConfig = tabConfig or {}
        local tab = {
            Name = tabConfig.Title or "Tab",
            Icon = tabConfig.Icon,
        }

        local button = new("TextButton", {
            Parent = tabList,
            BackgroundColor3 = palette.panelAlt,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 40),
            Font = Enum.Font.GothamSemibold,
            Text = tab.Name,
            TextColor3 = palette.text,
            TextSize = 13,
            AutoButtonColor = false,
        })
        new("UICorner", { Parent = button, CornerRadius = UDim.new(0, 12) })
        new("UIStroke", { Parent = button, Color = palette.stroke, Thickness = 1, Transparency = 0.3 })

        local buttonGradient = new("UIGradient", {
            Parent = button,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 46, 66)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 30, 44)),
            }),
            Rotation = 0,
        })

        local leftBar = new("Frame", {
            Parent = button,
            BackgroundColor3 = palette.accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 6),
            Size = UDim2.new(0, 3, 1, -12),
        })
        new("UICorner", { Parent = leftBar, CornerRadius = UDim.new(0, 12) })

        local page = new("ScrollingFrame", {
            Parent = pages,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarImageColor3 = palette.accent,
            ScrollBarThickness = 4,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
        })
        local padding = new("UIPadding", {
            Parent = page,
            PaddingLeft = UDim.new(0, 0),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 12),
        })
        padding.Name = "Padding"

        local list = new("UIListLayout", {
            Parent = page,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
        })

        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 14)
        end)

        tab.Button = button
        tab.Page = page
        tab._list = list
        tab._page = page

        function tab:AddSection(sectionTitle)
            local section = new("Frame", {
                Parent = page,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                LayoutOrder = 0,
            })
            makeLabel(section, sectionTitle or "", 14, true, palette.accent).Position = UDim2.new(0, 2, 0, 6)
            local line = new("Frame", {
                Parent = section,
                BackgroundColor3 = palette.stroke,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 140, 1, -12),
                Size = UDim2.new(1, -150, 0, 1),
                BackgroundTransparency = 0.3,
            })
            return line
        end

        function tab:AddParagraph(props)
            props = props or {}
            local block = makeCard(page, 72)
            block.LayoutOrder = 0
            local t = makeLabel(block, props.Title or "", 14, true)
            t.Position = UDim2.new(0, 14, 0, 10)
            t.Size = UDim2.new(1, -28, 0, 18)
            local c = makeLabel(block, props.Content or "", 12, false, palette.subtext)
            c.Position = UDim2.new(0, 14, 0, 32)
            c.Size = UDim2.new(1, -28, 0, 28)
            block.Size = UDim2.new(1, 0, 0, 76)
        end

        function tab:AddButton(props)
            props = props or {}
            local buttonFrame = makeCard(page, 58)
            local button = new("TextButton", {
                Parent = buttonFrame,
                BackgroundColor3 = palette.accentSoft,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 14, 0, 13),
                Size = UDim2.new(1, -28, 0, 32),
                Font = Enum.Font.GothamSemibold,
                Text = props.Title or "Button",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 13,
                AutoButtonColor = false,
            })
            new("UICorner", { Parent = button, CornerRadius = UDim.new(0, 10) })
            local callback = props.Callback
            button.MouseButton1Click:Connect(function()
                if callback then
                    callback()
                end
            end)
            button.MouseEnter:Connect(function()
                tween(button, { BackgroundColor3 = palette.accent }, 0.12)
            end)
            button.MouseLeave:Connect(function()
                tween(button, { BackgroundColor3 = palette.accentSoft }, 0.12)
            end)
            return button
        end

        function tab:AddToggle(id, props)
            props = props or {}
            local control = {
                Value = props.Default and true or false,
                _callback = props.Callback,
            }

            local card = makeCard(page, 78)
            local titleLabel = makeLabel(card, props.Title or id or "Toggle", 13, true)
            titleLabel.Position = UDim2.new(0, 14, 0, 12)
            titleLabel.Size = UDim2.new(1, -90, 0, 18)

            local descLabel = makeLabel(card, props.Description or "", 11, false, palette.subtext)
            descLabel.Position = UDim2.new(0, 14, 0, 33)
            descLabel.Size = UDim2.new(1, -90, 0, 30)

            local toggle = new("TextButton", {
                Parent = card,
                BackgroundColor3 = control.Value and palette.success or Color3.fromRGB(56, 61, 74),
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.new(0, 48, 0, 24),
                Text = "",
                AutoButtonColor = false,
            })
            new("UICorner", { Parent = toggle, CornerRadius = UDim.new(1, 0) })

            local knob = new("Frame", {
                Parent = toggle,
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Position = control.Value and UDim2.new(1, -22, 0.5, -7) or UDim2.new(0, 4, 0.5, -7),
                Size = UDim2.new(0, 16, 0, 16),
            })
            new("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

            local function apply(value, silent)
                control.Value = not not value
                tween(toggle, { BackgroundColor3 = control.Value and palette.success or Color3.fromRGB(56, 61, 74) }, 0.12)
                tween(knob, { Position = control.Value and UDim2.new(1, -22, 0.5, -7) or UDim2.new(0, 4, 0.5, -7) }, 0.12)
                if control._callback and not silent then
                    control._callback(control.Value)
                end
            end

            function control:SetValue(value, silent)
                apply(value, silent)
            end

            function control:OnChanged(fn)
                self._callback = fn
            end

            toggle.MouseButton1Click:Connect(function()
                apply(not control.Value, false)
            end)

            if id then
                UI.Options[id] = control
            end

            apply(control.Value, true)
            return control
        end

        function tab:AddSlider(id, props)
            props = props or {}
            local control = {
                Value = props.Default or props.Min or 0,
                _callback = props.Callback,
            }

            local minValue = props.Min or 0
            local maxValue = props.Max or 100
            local rounding = props.Rounding or 1

            local card = makeCard(page, 88)
            local titleLabel = makeLabel(card, props.Title or id or "Slider", 13, true)
            titleLabel.Position = UDim2.new(0, 14, 0, 10)
            titleLabel.Size = UDim2.new(1, -90, 0, 18)

            local valueLabel = makeLabel(card, tostring(control.Value), 12, true, palette.accent)
            valueLabel.AnchorPoint = Vector2.new(1, 0)
            valueLabel.Position = UDim2.new(1, -14, 0, 10)
            valueLabel.Size = UDim2.new(0, 70, 0, 18)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right

            local descLabel = makeLabel(card, props.Description or "", 11, false, palette.subtext)
            descLabel.Position = UDim2.new(0, 14, 0, 30)
            descLabel.Size = UDim2.new(1, -28, 0, 18)

            local track = new("Frame", {
                Parent = card,
                BackgroundColor3 = Color3.fromRGB(40, 47, 60),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 14, 0, 58),
                Size = UDim2.new(1, -28, 0, 12),
            })
            new("UICorner", { Parent = track, CornerRadius = UDim.new(1, 0) })

            local fill = new("Frame", {
                Parent = track,
                BackgroundColor3 = palette.accent,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(0, 1),
            })
            new("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })

            local knob = new("Frame", {
                Parent = track,
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 14),
            })
            new("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

            local dragging = false

            local function apply(value, silent)
                local snapped = round(clamp(value, minValue, maxValue), rounding)
                control.Value = snapped
                valueLabel.Text = tostring(snapped)
                local alpha = (snapped - minValue) / math.max(1, (maxValue - minValue))
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                if control._callback and not silent then
                    control._callback(snapped)
                end
            end

            local function updateFromInput(inputX)
                local absPos = track.AbsolutePosition.X
                local absSize = track.AbsoluteSize.X
                local alpha = clamp((inputX - absPos) / math.max(1, absSize), 0, 1)
                apply(minValue + ((maxValue - minValue) * alpha), false)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateFromInput(input.Position.X)
                end
            end)

            track.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateFromInput(input.Position.X)
                end
            end)

            function control:SetValue(value, silent)
                apply(value, silent)
            end

            function control:OnChanged(fn)
                self._callback = fn
            end

            if id then
                UI.Options[id] = control
            end

            apply(control.Value, true)
            return control
        end

        function tab:AddDropdown(id, props)
            props = props or {}
            local values = props.Values or {}
            local control = {
                Value = props.Default,
                _callback = props.Callback,
                _open = false,
            }

            local collapsedHeight = 56
            local optionHeight = 32
            local card = makeCard(page, collapsedHeight)
            card.ClipsDescendants = true

            local titleLabel = makeLabel(card, props.Title or id or "Dropdown", 13, true)
            titleLabel.Position = UDim2.new(0, 14, 0, 10)
            titleLabel.Size = UDim2.new(1, -50, 0, 18)

            local valueLabel = makeLabel(card, "", 12, false, palette.subtext)
            valueLabel.Position = UDim2.new(0, 14, 0, 30)
            valueLabel.Size = UDim2.new(1, -36, 0, 16)

            local arrow = makeLabel(card, "v", 16, true, palette.accent)
            arrow.AnchorPoint = Vector2.new(1, 0)
            arrow.Position = UDim2.new(1, -14, 0, 10)
            arrow.Size = UDim2.new(0, 16, 0, 16)
            arrow.TextXAlignment = Enum.TextXAlignment.Center

            local button = new("TextButton", {
                Parent = card,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, collapsedHeight),
                Text = "",
                AutoButtonColor = false,
            })

            local listFrame = new("Frame", {
                Parent = card,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 10, 0, collapsedHeight - 2),
                Size = UDim2.new(1, -20, 0, 0),
            })

            local listLayout = new("UIListLayout", {
                Parent = listFrame,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
            })

            local function refreshValueText()
                valueLabel.Text = tostring(control.Value or "")
            end

            local function refreshSize()
                local height = collapsedHeight
                if control._open then
                    height = collapsedHeight + (#values * (optionHeight + 6)) + 6
                end
                card.Size = UDim2.new(1, 0, 0, height)
                listFrame.Size = UDim2.new(1, -20, 0, height - collapsedHeight - 6)
                listFrame.Visible = control._open
                arrow.Text = control._open and "^" or "v"
            end

            local function apply(value, silent)
                if value == nil then
                    value = values[1]
                end
                control.Value = value
                refreshValueText()
                if control._callback and not silent then
                    control._callback(value)
                end
            end

            for index, option in ipairs(values) do
                local optionButton = new("TextButton", {
                    Parent = listFrame,
                    BackgroundColor3 = palette.panelAlt,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, optionHeight),
                    Font = Enum.Font.Gotham,
                    Text = tostring(option),
                    TextColor3 = palette.text,
                    TextSize = 12,
                    AutoButtonColor = false,
                })
                new("UICorner", { Parent = optionButton, CornerRadius = UDim.new(0, 10) })
                new("UIStroke", { Parent = optionButton, Color = palette.stroke, Thickness = 1, Transparency = 0.35 })
                optionButton.MouseButton1Click:Connect(function()
                    apply(option, false)
                    control._open = false
                    refreshSize()
                end)
            end

            button.MouseButton1Click:Connect(function()
                control._open = not control._open
                refreshSize()
            end)

            function control:SetValue(value, silent)
                apply(value, silent)
            end

            function control:OnChanged(fn)
                self._callback = fn
            end

            if id then
                UI.Options[id] = control
            end

            apply(control.Value, true)
            refreshSize()
            return control
        end

        function tab:AddInput(id, props)
            props = props or {}
            local control = {
                Value = props.Default or "",
                _callback = props.Callback,
            }

            local card = makeCard(page, 76)
            local titleLabel = makeLabel(card, props.Title or id or "Input", 13, true)
            titleLabel.Position = UDim2.new(0, 14, 0, 10)
            titleLabel.Size = UDim2.new(1, -28, 0, 18)

            local box = new("TextBox", {
                Parent = card,
                BackgroundColor3 = palette.panelAlt,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 14, 0, 34),
                Size = UDim2.new(1, -28, 0, 30),
                ClearTextOnFocus = false,
                Font = Enum.Font.Gotham,
                PlaceholderText = props.Placeholder or "",
                Text = tostring(control.Value),
                TextColor3 = palette.text,
                PlaceholderColor3 = palette.subtext,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            new("UICorner", { Parent = box, CornerRadius = UDim.new(0, 10) })
            new("UIPadding", {
                Parent = box,
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
            })

            local function apply(value, silent)
                control.Value = tostring(value or "")
                box.Text = control.Value
                if control._callback and not silent then
                    control._callback(control.Value)
                end
            end

            box.FocusLost:Connect(function()
                apply(box.Text, false)
            end)

            function control:SetValue(value, silent)
                apply(value, silent)
            end

            function control:OnChanged(fn)
                self._callback = fn
            end

            if id then
                UI.Options[id] = control
            end

            apply(control.Value, true)
            return control
        end

        table.insert(window._tabs, tab)

        button.MouseButton1Click:Connect(function()
            showTab(tab)
        end)

        button.MouseEnter:Connect(function()
            if window._activeTab ~= tab then
                tween(button, { BackgroundColor3 = palette.panel }, 0.12)
            end
        end)

        button.MouseLeave:Connect(function()
            if window._activeTab ~= tab then
                tween(button, { BackgroundColor3 = palette.panelAlt }, 0.12)
            end
        end)

        if #window._tabs == 1 then
            showTab(tab)
        end

        return tab
    end

    function window:AddTab(tabConfig)
        return addTab(tabConfig)
    end

    function window:Notify(config)
        UI:Notify(config)
    end

    function window:SelectFirstTab()
        if self._tabs[1] then
            showTab(self._tabs[1])
        end
    end

    local keyCode = config.MinimizeKey
    if typeof(keyCode) == "EnumItem" then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == keyCode then
                setMinimized(not window._minimized)
            end
        end)
    end

    window._screenGui = screenGui
    window._main = main
    window._body = body
    window._sidebar = sidebar
    window._content = content
    window._showTab = showTab

    return setmetatable(window, {
        __index = function(_, key)
            return UI[key]
        end,
    })
end

return UI
