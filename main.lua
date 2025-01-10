-- [[
-- Easy Aim 
-- v2.0.0
-- ]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local me = Players.LocalPlayer
local aimOnNow = false
local whoToAim = nil
local activeInputs = {}
local lastRender = tick()
local renderCooldown = 0.01

local COLORS = {
    background = Color3.fromRGB(10, 10, 15),      
    accent = Color3.fromRGB(255, 0, 60),          
    accent2 = Color3.fromRGB(255, 0, 0),          
    text = Color3.fromRGB(255, 255, 255),         
    toggleOn = Color3.fromRGB(255, 0, 60),        
    toggleOff = Color3.fromRGB(30, 30, 35),       
    slider = Color3.fromRGB(255, 0, 60),          
    sidebar = Color3.fromRGB(15, 15, 20),         
    hover = Color3.fromRGB(40, 40, 45),           
    keybindBg = Color3.fromRGB(20, 20, 25)        
}

local settings = {
    aimOn = true,
    smoothness = 5,
    pickTargetBy = "closest",
    fov = 70,
    aimPart = "Head",
    maxDist = 1000,
    sensitivity = 1.5,
    lockTime = 0.5,
    seeOnly = true,
    noTeammates = false,
    autoFov = true,
    aimMovingFirst = true,
    toggleKey = Enum.UserInputType.MouseButton2,
    showWelcome = true
}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.FilterDescendantsInstances = {me.Character}

local function canSee(part)
    local cam = workspace.CurrentCamera
    local from = cam.CFrame.Position
    local dir = (part.Position - from).Unit * settings.maxDist
    local ray = workspace:Raycast(from, dir, rayParams)
    return ray and ray.Instance:IsDescendantOf(part.Parent)
end

local function isEnemy(plyr)
    if not settings.noTeammates then return true end
    return plyr.Team ~= me.Team
end

local function getAimPart(plyr)
    return plyr.Character and plyr.Character:FindFirstChild(settings.aimPart)
end

local function isValidTarget(plyr, part)
    return plyr ~= me and isEnemy(plyr) and part and (not settings.seeOnly or canSee(part))
end

local function calculateDistance(part)
    local point, onScreen = workspace.CurrentCamera:WorldToScreenPoint(part.Position)
    if onScreen then
        local diff = (Vector2.new(point.X, point.Y) - Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)).Magnitude
        return diff, onScreen
    end
    return math.huge, false
end

local function findClosest()
    local closest, dist = nil, settings.maxDist
    for _, plyr in pairs(Players:GetPlayers()) do
        local part = getAimPart(plyr)
        if isValidTarget(plyr, part) then
            local diff, onScreen = calculateDistance(part)
            if diff < dist and diff <= settings.fov then
                closest, dist = plyr, diff
            end
        end
    end
    return closest
end

local function aimAt(who)
    if who and who.Character and who.Character:FindFirstChild(settings.aimPart) then
        local part = who.Character[settings.aimPart]
        local cam = workspace.CurrentCamera
        local aimHere = part.Position
        local lookNow = cam.CFrame.LookVector
        local lookWant = (aimHere - cam.CFrame.Position).Unit
        cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + 
            lookNow:Lerp(lookWant, settings.smoothness / 10))
    end
end

local function createGui()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "EasyAimGui"
    ScreenGui.ResetOnSpawn = false

    local MainContainer = Instance.new("Frame")
    MainContainer.Name = "MainContainer"
    MainContainer.Size = UDim2.new(0, 500, 0, 400)
    MainContainer.Position = UDim2.new(0.5, -250, 0.5, -200)
    MainContainer.BackgroundColor3 = COLORS.background
    MainContainer.BorderSizePixel = 0
    MainContainer.ClipsDescendants = true
    MainContainer.Parent = ScreenGui

    local GradientFrame = Instance.new("Frame")
    GradientFrame.Size = UDim2.new(2, 0, 2, 0)
    GradientFrame.Position = UDim2.new(-0.5, 0, -0.5, 0)
    GradientFrame.BackgroundTransparency = 0.9
    GradientFrame.BorderSizePixel = 0
    GradientFrame.Parent = MainContainer

    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.accent),
        ColorSequenceKeypoint.new(0.5, COLORS.background),
        ColorSequenceKeypoint.new(1, COLORS.accent2)
    })
    Gradient.Parent = GradientFrame

    spawn(function()
        local rotation = 0
        while wait() do
            rotation = (rotation + 1) % 360
            Gradient.Rotation = rotation
        end
    end)

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainContainer

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 60, 1, 0)
    Sidebar.BackgroundColor3 = COLORS.sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainContainer

    local SidebarGlow = Instance.new("ImageLabel")
    SidebarGlow.Name = "Glow"
    SidebarGlow.BackgroundTransparency = 1
    SidebarGlow.Position = UDim2.new(1, -5, 0, 0)
    SidebarGlow.Size = UDim2.new(0, 10, 1, 0)
    SidebarGlow.Image = "rbxassetid://2954823557"
    SidebarGlow.ImageColor3 = COLORS.accent
    SidebarGlow.ImageTransparency = 0.8
    SidebarGlow.Parent = Sidebar

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BackgroundColor3 = COLORS.sidebar
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainContainer

    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.new(0, 60, 1, 0)
    Controls.Position = UDim2.new(1, -60, 0, 0)
    Controls.BackgroundTransparency = 1
    Controls.Parent = TopBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -25, 0.5, -10)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = COLORS.text
    CloseBtn.TextSize = 20
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = Controls

    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "MinBtn"
    MinBtn.Size = UDim2.new(0, 20, 0, 20)
    MinBtn.Position = UDim2.new(0, 5, 0.5, -10)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "−"
    MinBtn.TextColor3 = COLORS.text
    MinBtn.TextSize = 20
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Parent = Controls

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -120, 1, 0)
    Title.Position = UDim2.new(0, 60, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "EASY AIM"
    Title.TextColor3 = COLORS.text
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.Parent = TopBar

    local TitleGradient = Instance.new("UIGradient")
    TitleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.accent),
        ColorSequenceKeypoint.new(1, COLORS.accent2)
    })
    TitleGradient.Parent = Title

    local Container = Instance.new("ScrollingFrame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, -80, 1, -40)
    Container.Position = UDim2.new(0, 70, 0, 35)
    Container.BackgroundTransparency = 1
    Container.ScrollBarThickness = 4
    Container.ScrollBarImageColor3 = COLORS.accent
    Container.Parent = MainContainer

    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        MainContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainContainer.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    local minimized = false

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local goal = {}
        goal.Size = minimized and UDim2.new(0, 500, 0, 30) or UDim2.new(0, 500, 0, 400)
        local tween = TweenService:Create(MainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad), goal)
        tween:Play()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local yPos = 0
    local padding = 35

    local function createToggle(name, default)
        local Toggle = Instance.new("Frame")
        Toggle.Name = name .. "Toggle"
        Toggle.Size = UDim2.new(1, 0, 0, 30)
        Toggle.Position = UDim2.new(0, 0, 0, yPos)
        Toggle.BackgroundTransparency = 1
        Toggle.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = name
        Label.TextColor3 = COLORS.text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.Parent = Toggle

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 44, 0, 22)
        Button.Position = UDim2.new(1, -44, 0.5, -11)
        Button.BackgroundColor3 = default and COLORS.toggleOn or COLORS.toggleOff
        Button.Text = ""
        Button.Parent = Toggle

        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(1, 0)
        ButtonCorner.Parent = Button

        local Circle = Instance.new("Frame")
        Circle.Size = UDim2.new(0, 18, 0, 18)
        Circle.Position = UDim2.new(default and 1 or 0, default and -20 or 2, 0.5, -9)
        Circle.BackgroundColor3 = COLORS.text
        Circle.Parent = Button

        local CircleCorner = Instance.new("UICorner")
        CircleCorner.CornerRadius = UDim.new(1, 0)
        CircleCorner.Parent = Circle

        local Glow = Instance.new("ImageLabel")
        Glow.Name = "Glow"
        Glow.BackgroundTransparency = 1
        Glow.Position = UDim2.new(0.5, -20, 0.5, -20)
        Glow.Size = UDim2.new(0, 40, 0, 40)
        Glow.Image = "rbxassetid://2954823557"
        Glow.ImageColor3 = COLORS.accent
        Glow.ImageTransparency = 0.8
        Glow.Parent = Button

        Button.MouseButton1Click:Connect(function()
            settings[name:lower()] = not settings[name:lower()]
            local goal = {
                Position = settings[name:lower()] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = settings[name:lower()] and COLORS.toggleOn or COLORS.toggleOff
            }
            local tween = TweenService:Create(Circle, TweenInfo.new(0.2), {Position = goal.Position})
            local tween2 = TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = goal.BackgroundColor3})
            tween:Play()
            tween2:Play()
        end)

        yPos = yPos + padding
    end

    local function createSlider(name, min, max, default)
        local Slider = Instance.new("Frame")
        Slider.Name = name .. "Slider"
        Slider.Size = UDim2.new(1, 0, 0, 45)
        Slider.Position = UDim2.new(0, 0, 0, yPos)
        Slider.BackgroundTransparency = 1
        Slider.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.Text = name .. ": " .. default
        Label.TextColor3 = COLORS.text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.Parent = Slider

        local SliderBar = Instance.new("Frame")
        SliderBar.Size = UDim2.new(1, 0, 0, 4)
        SliderBar.Position = UDim2.new(0, 0, 0.7, 0)
        SliderBar.BackgroundColor3 = COLORS.toggleOff
        SliderBar.Parent = Slider

        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(1, 0)
        SliderCorner.Parent = SliderBar

        local Progress = Instance.new("Frame")
        Progress.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
        Progress.BackgroundColor3 = COLORS.slider
        Progress.BorderSizePixel = 0
        Progress.Parent = SliderBar

        local ProgressCorner = Instance.new("UICorner")
        ProgressCorner.CornerRadius = UDim.new(1, 0)
        ProgressCorner.Parent = Progress

        local Knob = Instance.new("TextButton")
        Knob.Size = UDim2.new(0, 16, 0, 16)
        local initialPos = (default - min)/(max - min)
        Knob.Position = UDim2.new(initialPos, -8, 0.7, -6)
        Knob.BackgroundColor3 = COLORS.accent
        Knob.Text = ""
        Knob.Parent = Slider

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob

        local Glow = Instance.new("ImageLabel")
        Glow.Name = "Glow"
        Glow.BackgroundTransparency = 1
        Glow.Position = UDim2.new(0.5, -15, 0.5, -15)
        Glow.Size = UDim2.new(0, 30, 0, 30)
        Glow.Image = "rbxassetid://2954823557"
        Glow.ImageColor3 = COLORS.accent
        Glow.ImageTransparency = 0.8
        Glow.Parent = Knob

        local dragging = false

        Knob.MouseButton1Down:Connect(function()
            dragging = true
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                Knob.Position = UDim2.new(pos, -8, 0.7, -6)
                Progress.Size = UDim2.new(pos, 0, 1, 0)
                local value = math.floor(min + (pos * (max - min)))
                Label.Text = name .. ": " .. value
                settings[name:lower()] = value
            end
        end)

        yPos = yPos + padding + 10
    end

    local function createKeybind()
        local Keybind = Instance.new("Frame")
        Keybind.Name = "KeybindFrame"
        Keybind.Size = UDim2.new(1, 0, 0, 45)
        Keybind.Position = UDim2.new(0, 0, 0, yPos)
        Keybind.BackgroundTransparency = 1
        Keybind.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.7, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.Text = "Toggle Key"
        Label.TextColor3 = COLORS.text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.Parent = Keybind

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 100, 0, 30)
        Button.Position = UDim2.new(1, -100, 0, 0)
        Button.BackgroundColor3 = COLORS.keybindBg
        Button.Text = "Right Click"
        Button.TextColor3 = COLORS.text
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 12
        Button.Parent = Keybind

        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 4)
        ButtonCorner.Parent = Button

        local listening = false

        Button.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            Button.Text = "Press any key..."

            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    settings.toggleKey = input.KeyCode
                    Button.Text = input.KeyCode.Name
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 or
                       input.UserInputType == Enum.UserInputType.MouseButton2 or
                       input.UserInputType == Enum.UserInputType.MouseButton3 then
                    settings.toggleKey = input.UserInputType
                    Button.Text = input.UserInputType.Name
                end
                listening = false
                connection:Disconnect()
            end)
        end)

        yPos = yPos + padding + 10
    end

    createToggle("AimOn", settings.aimOn)
    createSlider("Smoothness", 1, 10, settings.smoothness)
    createSlider("FOV", 30, 180, settings.fov)
    createSlider("MaxDist", 100, 2000, settings.maxDist)
    createSlider("Sensitivity", 0.1, 5, settings.sensitivity)
    createSlider("LockTime", 0.1, 2, settings.lockTime)
    createToggle("SeeOnly", settings.seeOnly)
    createToggle("NoTeammates", settings.noTeammates)
    createToggle("AutoFov", settings.autoFov)
    createToggle("AimMovingFirst", settings.aimMovingFirst)
    createKeybind()

    Container.CanvasSize = UDim2.new(0, 0, 0, yPos)

    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    if settings.showWelcome then
        local success, errorMsg = pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Easy Aim!",
                Text = "Loaded! Have fun aiming!",
                Duration = 5
            })
        end)
        if not success then
            warn("Failed to send notification: " .. tostring(errorMsg))
        end
    end

    return settings
end

local aimSettings = createGui()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if activeInputs[input.KeyCode or input.UserInputType] then return end

    activeInputs[input.KeyCode or input.UserInputType] = true

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if settings.toggleKey == Enum.UserInputType.MouseButton2 then
            aimOnNow = true
            whoToAim = nil
        end
    elseif input.KeyCode == settings.toggleKey or input.UserInputType == settings.toggleKey then
        if settings.toggleKey ~= Enum.UserInputType.MouseButton2 then
            aimOnNow = not aimOnNow
            if not aimOnNow then whoToAim = nil end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    activeInputs[input.KeyCode or input.UserInputType] = nil

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if settings.toggleKey == Enum.UserInputType.MouseButton2 then
            aimOnNow = false
            whoToAim = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastRender < renderCooldown then return end
    lastRender = now

    if settings.aimOn and aimOnNow then
        if not whoToAim or (whoToAim.Character and not whoToAim.Character:FindFirstChild(settings.aimPart)) then
            whoToAim = findClosest()
        end
        aimAt(whoToAim)
    end
end)

return aimSettings
