-- https://www.youtube.com/@WadaS-z7z
if _G.KM_UNLOAD then pcall(_G.KM_UNLOAD) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

local Settings = {
    ESPEnabled = true,
    BoxESP = true,
    CornerBoxESP = false,
    SkeletonESP = true,
    TracerESP = true,
    HealthBar = true,
    Crosshair = true,
    MaxDistance = 1000,
    CameraFOV = 70,
    
    BoxColor = Color3.fromRGB(255, 60, 60),
    SkeletonColor = Color3.fromRGB(170, 0, 255),
    TracerColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    HealthColor = Color3.fromRGB(0, 255, 0),
    CrosshairColor = Color3.fromRGB(170, 0, 255),
    
    ChamsEnabled = false,
    ChamsColor = Color3.fromRGB(170, 0, 255),
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ChamsFill = 0.5,

    LootESP = false,
    LootDist = 500,
    LootColor = Color3.fromRGB(255, 215, 0),
    
    ContainerESP = false,
    ContainerDist = 500,
    ContainerColor = Color3.fromRGB(255, 140, 0),
    
    ExtractorESP = false,
    ExtractorDist = 1000,
    ExtractorColor = Color3.fromRGB(0, 255, 255),
    
    CorpseESP = false,
    CorpseDist = 500,
    CorpseColor = Color3.fromRGB(255, 255, 255),
    
    WeaponESP = false,
    WeaponDist = 500,
    WeaponColor = Color3.fromRGB(255, 165, 0),
    
    GrenadeESP = false,
    GrenadeDist = 500,
    GrenadeColor = Color3.fromRGB(255, 0, 0),
    
    LootFilter = false,
    FilterWeapons = true,
    FilterMeds = true,
    FilterArmor = true,
    
    Radar = false,
    RadarColor = Color3.fromRGB(255, 60, 60),
    
    Skybox = false,
    SkyboxColor = Color3.fromRGB(170, 0, 255),
    Fullbright = false,
    
    Freecam = false,
    FreecamKey = Enum.KeyCode.F,
    FreecamSpeed = 50,

    AimEnabled = true,
    AimKey = Enum.KeyCode.E,
    AimFOV = 75,
    AimSmooth = 0.18,
    AimPart = "Head",
    SilentAim = false,
    ShowFOV = true,
    FOVColor = Color3.fromRGB(170, 0, 255),
    
    Triggerbot = false,
    TriggerbotKey = Enum.KeyCode.V,
    TriggerbotDist = 500,
    
    Hitmarker = true,
    
    MenuKey = Enum.KeyCode.Insert,
}

local espObjects = {}
local worldObjects = {}
local connections = {}
local crosshairLines = {}
local hitmarkerLines = {}
local radarBg = nil
local radarBlips = {}

local origFOV = Camera.FieldOfView
local origBrightness = Lighting.Brightness
local origAmbient = Lighting.OutdoorAmbient
local origFogEnd = Lighting.FogEnd
local origClockTime = Lighting.ClockTime
local origGlobalShadows = Lighting.GlobalShadows
local origFogStart = Lighting.FogStart

local origAtmosDensity, origAtmosHaze, origAtmosGlare, origAtmosColor
local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
if atmos then
    origAtmosDensity = atmos.Density
    origAtmosHaze = atmos.Haze
    origAtmosGlare = atmos.Glare
    origAtmosColor = atmos.Color
end

local origSky = {}
local sky = Lighting:FindFirstChildOfClass("Sky")
if sky then
    origSky.Bk = sky.SkyboxBk
    origSky.Dn = sky.SkyboxDn
    origSky.Ft = sky.SkyboxFt
    origSky.Lf = sky.SkyboxLf
    origSky.Rt = sky.SkyboxRt
    origSky.Up = sky.SkyboxUp
end

local ACCENT = Color3.fromRGB(170, 0, 255)
local BG = Color3.fromRGB(15, 15, 20)
local BG2 = Color3.fromRGB(22, 22, 28)
local BG3 = Color3.fromRGB(35, 35, 45)
local TXT = Color3.fromRGB(225, 225, 230)
local MUTED = Color3.fromRGB(150, 150, 160)

local targetGui = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

local menuGui = Instance.new("ScreenGui")
menuGui.Name = "MenuUI"
menuGui.ResetOnSpawn = false
menuGui.IgnoreGuiInset = true
menuGui.DisplayOrder = 999999
menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
menuGui.Parent = targetGui

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
end

local toggleBtn = new("TextButton", {
    Size = UDim2.new(0, 46, 0, 46),
    Position = UDim2.new(0, 14, 0, 14),
    BackgroundColor3 = Color3.fromRGB(12, 12, 16),
    BackgroundTransparency = 0.15,
    Text = "M",
    TextColor3 = ACCENT,
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    AutoButtonColor = false,
    ZIndex = 10
}, menuGui)
corner(toggleBtn, 12)
local tbStroke = new("UIStroke", {Color = ACCENT, Thickness = 1.2, Transparency = 0.35}, toggleBtn)

task.spawn(function()
    while toggleBtn.Parent do
        TweenService:Create(tbStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {Transparency = 0.75}):Play()
        task.wait(1.2)
        TweenService:Create(tbStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {Transparency = 0.35}):Play()
        task.wait(1.2)
    end
end)

local main = new("Frame", {
    Size = UDim2.new(0, 540, 0, 580),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = BG,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
    Active = true,
    ZIndex = 5
}, menuGui)
corner(main, 12)
new("UIStroke", {Color = ACCENT, Thickness = 1, Transparency = 0.5}, main)

local uiScale = Instance.new("UIScale")
uiScale.Scale = 0
uiScale.Parent = main

local title = new("Frame", {
    Size = UDim2.new(1, 0, 0, 35),
    BackgroundColor3 = Color3.fromRGB(18, 18, 24),
    BorderSizePixel = 0,
    ZIndex = 6
}, main)
corner(title, 12)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = Color3.fromRGB(18, 18, 24),
    BorderSizePixel = 0,
    ZIndex = 6
}, title)

local closeBtn = new("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -32, 0.5, -12),
    BackgroundColor3 = Color3.fromRGB(255, 80, 80),
    Text = "×",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    AutoButtonColor = false,
    ZIndex = 7
}, title)
corner(closeBtn, 6)
closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(255, 110, 110) end)
closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80) end)

do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local tabBar = new("Frame", {
    Size = UDim2.new(1, -20, 0, 35),
    Position = UDim2.new(0, 10, 0, 45),
    BackgroundTransparency = 1,
    ZIndex = 6
}, main)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 0)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local contentArea = new("Frame", {
    Size = UDim2.new(1, -20, 1, -90),
    Position = UDim2.new(0, 10, 0, 85),
    BackgroundTransparency = 1,
    ZIndex = 6
}, main)

local tabs = {}
local activeTab = nil

local function setActiveTab(target)
    for _, t in ipairs(tabs) do
        local on = (t == target)
        t.scroll.Visible = on
        t.btn.TextColor3 = on and ACCENT or MUTED
        t.underline.BackgroundTransparency = on and 0 or 1
    end
    activeTab = target
end

local function newTab(label, widthScale)
    local btn = new("TextButton", {
        Size = UDim2.new(widthScale, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = MUTED,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        AutoButtonColor = false,
        ZIndex = 7
    }, tabBar)

    local underline = new("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -5),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ZIndex = 7
    }, btn)
    corner(underline, 2)

    local scroll = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = ACCENT,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 6,
        Active = true
    }, contentArea)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local tab = {btn = btn, scroll = scroll, underline = underline, layout = layout}
    table.insert(tabs, tab)
    btn.MouseButton1Click:Connect(function() setActiveTab(tab) end)
    return tab
end

local orderCounter = 0
local function nextOrder()
    orderCounter = orderCounter + 1
    return orderCounter
end

local function addSection(parent, text)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = text:upper(),
        TextColor3 = ACCENT,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = nextOrder(),
        ZIndex = 6
    }, parent)
end

local function addToggle(parent, name, getFn, setFn)
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = BG2,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = nextOrder(),
        ZIndex = 6
    }, parent)
    corner(btn, 6)

    new("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = TXT,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7
    }, btn)

    local pill = new("Frame", {
        Size = UDim2.new(0, 36, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = getFn() and ACCENT or BG3,
        BorderSizePixel = 0,
        ZIndex = 7
    }, btn)
    corner(pill, 999)

    local knob = new("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = getFn() and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 8
    }, pill)
    corner(knob, 999)

    btn.MouseButton1Click:Connect(function()
        local nv = not getFn()
        setFn(nv)
        pill.BackgroundColor3 = nv and ACCENT or BG3
        knob:TweenPosition(
            nv and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            "Out", "Quad", 0.15, true
        )
    end)

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = BG2 end)
end

local function addSlider(parent, name, min, max, getFn, setFn, fmt)
    fmt = fmt or function(v) return string.format("%.2f", v) end
    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = BG2,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(),
        ZIndex = 6
    }, parent)
    corner(frame, 6)

    new("TextLabel", {
        Size = UDim2.new(1, -80, 0, 22),
        Position = UDim2.new(0, 14, 0, 4),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = TXT,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7
    }, frame)

    local valLbl = new("TextLabel", {
        Size = UDim2.new(0, 60, 0, 22),
        Position = UDim2.new(1, -74, 0, 4),
        BackgroundTransparency = 1,
        Text = fmt(getFn()),
        TextColor3 = ACCENT,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 7
    }, frame)

    local bar = new("Frame", {
        Size = UDim2.new(1, -28, 0, 8),
        Position = UDim2.new(0, 14, 1, -18),
        BackgroundColor3 = BG3,
        BorderSizePixel = 0,
        ZIndex = 7
    }, frame)
    corner(bar, 999)

    local fill = new("Frame", {
        Size = UDim2.new((getFn() - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
        ZIndex = 8
    }, bar)
    corner(fill, 999)

    local hitbox = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 10
    }, bar)

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * rel
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valLbl.Text = fmt(val)
        setFn(val)
    end

    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function addKeybind(parent, name, getFn, setFn)
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = BG2,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = nextOrder(),
        ZIndex = 6
    }, parent)
    corner(btn, 6)

    new("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = TXT,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7
    }, btn)

    local keyLbl = new("TextButton", {
        Size = UDim2.new(0, 100, 0, 24),
        Position = UDim2.new(1, -114, 0.5, -12),
        BackgroundColor3 = BG3,
        Text = getFn().Name,
        TextColor3 = ACCENT,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 8
    }, btn)
    corner(keyLbl, 5)

    local listening = false
    keyLbl.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyLbl.Text = "..."
        keyLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
    end)

    table.insert(connections, UserInputService.InputBegan:Connect(function(input)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            setFn(input.KeyCode)
            keyLbl.Text = input.KeyCode.Name
            keyLbl.TextColor3 = ACCENT
        end
    end))
end

local function addColor(parent, name, getFn, setFn)
    local box = new("Frame", {
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = BG2,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(),
        ZIndex = 6
    }, parent)
    corner(box, 6)

    new("TextLabel", {
        Size = UDim2.new(1, -60, 0, 24),
        Position = UDim2.new(0, 14, 0, 4),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = TXT,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7
    }, box)

    local swatch = new("Frame", {
        Size = UDim2.new(0, 32, 0, 18),
        Position = UDim2.new(1, -46, 0, 7),
        BackgroundColor3 = getFn(),
        BorderSizePixel = 0,
        ZIndex = 7
    }, box)
    corner(swatch, 4)

    local channels = {"R", "G", "B"}
    for i = 1, 3 do
        local y = 32 + (i - 1) * 24
        local ch = channels[i]

        new("TextLabel", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 14, 0, y),
            BackgroundTransparency = 1,
            Text = ch,
            TextColor3 = TXT,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            ZIndex = 7
        }, box)

        local bar = new("Frame", {
            Size = UDim2.new(1, -56, 0, 8),
            Position = UDim2.new(0, 36, 0, y + 4),
            BackgroundColor3 = BG3,
            BorderSizePixel = 0,
            ZIndex = 7
        }, box)
        corner(bar, 999)

        local cur = getFn()
        local v = (ch == "R" and cur.R) or (ch == "G" and cur.G) or cur.B

        local fill = new("Frame", {
            Size = UDim2.new(v, 0, 1, 0),
            BackgroundColor3 = ACCENT,
            BorderSizePixel = 0,
            ZIndex = 8
        }, bar)
        corner(fill, 999)

        local hitbox = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0.5, -12),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 10
        }, bar)

        local dragging = false
        local function update(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local c = getFn()
            local r = math.floor(c.R * 255 + 0.5)
            local g = math.floor(c.G * 255 + 0.5)
            local b = math.floor(c.B * 255 + 0.5)
            if ch == "R" then r = math.floor(rel * 255 + 0.5) end
            if ch == "G" then g = math.floor(rel * 255 + 0.5) end
            if ch == "B" then b = math.floor(rel * 255 + 0.5) end
            setFn(Color3.fromRGB(r, g, b))
            swatch.BackgroundColor3 = getFn()
        end

        hitbox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end
end

local tabVisuals = newTab("Visuals", 0.25)
local tabAim = newTab("Aim", 0.25)
local tabWorld = newTab("World", 0.25)
local tabColors = newTab("Colors", 0.25)
setActiveTab(tabVisuals)

addSection(tabVisuals.scroll, "Player ESP")
addToggle(tabVisuals.scroll, "Enable ESP", function() return Settings.ESPEnabled end, function(v) Settings.ESPEnabled = v end)
addToggle(tabVisuals.scroll, "2D Box", function() return Settings.BoxESP end, function(v) Settings.BoxESP = v end)
addToggle(tabVisuals.scroll, "Corner Box", function() return Settings.CornerBoxESP end, function(v) Settings.CornerBoxESP = v end)
addToggle(tabVisuals.scroll, "Skeleton", function() return Settings.SkeletonESP end, function(v) Settings.SkeletonESP = v end)
addToggle(tabVisuals.scroll, "Tracers", function() return Settings.TracerESP end, function(v) Settings.TracerESP = v end)
addToggle(tabVisuals.scroll, "Health Bar", function() return Settings.HealthBar end, function(v) Settings.HealthBar = v end)
addToggle(tabVisuals.scroll, "Weapon ESP", function() return Settings.WeaponESP end, function(v) Settings.WeaponESP = v end)
addSlider(tabVisuals.scroll, "Weapon Dist", 50, 3000,
    function() return Settings.WeaponDist end,
    function(v) Settings.WeaponDist = v end,
    function(v) return tostring(math.floor(v)) end)
addToggle(tabVisuals.scroll, "Corpse ESP", function() return Settings.CorpseESP end, function(v) Settings.CorpseESP = v end)
addSlider(tabVisuals.scroll, "Corpse Dist", 50, 3000,
    function() return Settings.CorpseDist end,
    function(v) Settings.CorpseDist = v end,
    function(v) return tostring(math.floor(v)) end)
addSlider(tabVisuals.scroll, "Player Dist", 100, 3000,
    function() return Settings.MaxDistance end,
    function(v) Settings.MaxDistance = v end,
    function(v) return tostring(math.floor(v)) end)

addSection(tabVisuals.scroll, "Crosshair & Radar")
addToggle(tabVisuals.scroll, "Enable Crosshair", function() return Settings.Crosshair end, function(v) Settings.Crosshair = v end)
addToggle(tabVisuals.scroll, "Enable Radar", function() return Settings.Radar end, function(v) Settings.Radar = v end)
addToggle(tabVisuals.scroll, "Enable Hitmarker", function() return Settings.Hitmarker end, function(v) Settings.Hitmarker = v end)

addSection(tabVisuals.scroll, "Camera")
addSlider(tabVisuals.scroll, "Camera FOV", 50, 120,
    function() return Settings.CameraFOV end,
    function(v) Settings.CameraFOV = v; Camera.FieldOfView = v end,
    function(v) return tostring(math.floor(v)) end)

addSection(tabVisuals.scroll, "Chams")
addToggle(tabVisuals.scroll, "Enable Chams", function() return Settings.ChamsEnabled end, function(v) Settings.ChamsEnabled = v; refreshAllChams() end)
addSlider(tabVisuals.scroll, "Fill Transparency", 0, 1,
    function() return Settings.ChamsFill end,
    function(v) Settings.ChamsFill = v; refreshAllChams() end)

addSection(tabAim.scroll, "Aimbot")
addToggle(tabAim.scroll, "Enable Aimbot", function() return Settings.AimEnabled end, function(v) Settings.AimEnabled = v end)
addToggle(tabAim.scroll, "Show FOV", function() return Settings.ShowFOV end, function(v) Settings.ShowFOV = v end)
addToggle(tabAim.scroll, "Silent Aim", function() return Settings.SilentAim end, function(v) Settings.SilentAim = v end)
addKeybind(tabAim.scroll, "Aim Key", function() return Settings.AimKey end, function(v) Settings.AimKey = v end)
addSlider(tabAim.scroll, "FOV", 10, 300,
    function() return Settings.AimFOV end,
    function(v) Settings.AimFOV = v end,
    function(v) return tostring(math.floor(v)) end)
addSlider(tabAim.scroll, "Smooth", 0.02, 1,
    function() return Settings.AimSmooth end,
    function(v) Settings.AimSmooth = v end)

addSection(tabAim.scroll, "Triggerbot")
addToggle(tabAim.scroll, "Enable Triggerbot", function() return Settings.Triggerbot end, function(v) Settings.Triggerbot = v end)
addKeybind(tabAim.scroll, "Triggerbot Key", function() return Settings.TriggerbotKey end, function(v) Settings.TriggerbotKey = v end)
addSlider(tabAim.scroll, "Trigger Distance", 50, 1000,
    function() return Settings.TriggerbotDist end,
    function(v) Settings.TriggerbotDist = v end,
    function(v) return tostring(math.floor(v)) end)

addSection(tabWorld.scroll, "World ESP")
addToggle(tabWorld.scroll, "Loot ESP", function() return Settings.LootESP end, function(v) Settings.LootESP = v end)
addSlider(tabWorld.scroll, "Loot Dist", 50, 3000,
    function() return Settings.LootDist end,
    function(v) Settings.LootDist = v end,
    function(v) return tostring(math.floor(v)) end)

addToggle(tabWorld.scroll, "Container ESP", function() return Settings.ContainerESP end, function(v) Settings.ContainerESP = v end)
addSlider(tabWorld.scroll, "Container Dist", 50, 3000,
    function() return Settings.ContainerDist end,
    function(v) Settings.ContainerDist = v end,
    function(v) return tostring(math.floor(v)) end)

addToggle(tabWorld.scroll, "Extractor ESP", function() return Settings.ExtractorESP end, function(v) Settings.ExtractorESP = v end)
addSlider(tabWorld.scroll, "Extractor Dist", 50, 3000,
    function() return Settings.ExtractorDist end,
    function(v) Settings.ExtractorDist = v end,
    function(v) return tostring(math.floor(v)) end)

addToggle(tabWorld.scroll, "Grenade ESP", function() return Settings.GrenadeESP end, function(v) Settings.GrenadeESP = v end)
addSlider(tabWorld.scroll, "Grenade Dist", 50, 3000,
    function() return Settings.GrenadeDist end,
    function(v) Settings.GrenadeDist = v end,
    function(v) return tostring(math.floor(v)) end)

addSection(tabWorld.scroll, "Loot Filter")
addToggle(tabWorld.scroll, "Enable Loot Filter", function() return Settings.LootFilter end, function(v) Settings.LootFilter = v end)
addToggle(tabWorld.scroll, "Show Weapons", function() return Settings.FilterWeapons end, function(v) Settings.FilterWeapons = v end)
addToggle(tabWorld.scroll, "Show Meds", function() return Settings.FilterMeds end, function(v) Settings.FilterMeds = v end)
addToggle(tabWorld.scroll, "Show Armor", function() return Settings.FilterArmor end, function(v) Settings.FilterArmor = v end)

addSection(tabWorld.scroll, "Lighting & Camera")
addToggle(tabWorld.scroll, "Skybox", function() return Settings.Skybox end, function(v) Settings.Skybox = v; updateSkybox() end)
addToggle(tabWorld.scroll, "Fullbright", function() return Settings.Fullbright end, function(v) Settings.Fullbright = v; updateLighting() end)
addToggle(tabWorld.scroll, "Freecam", function() return Settings.Freecam end, function(v) Settings.Freecam = v; toggleFreecam() end)
addKeybind(tabWorld.scroll, "Freecam Key", function() return Settings.FreecamKey end, function(v) Settings.FreecamKey = v end)
addSlider(tabWorld.scroll, "Freecam Speed", 10, 200,
    function() return Settings.FreecamSpeed end,
    function(v) Settings.FreecamSpeed = v end,
    function(v) return tostring(math.floor(v)) end)

addSection(tabColors.scroll, "ESP Colors")
addColor(tabColors.scroll, "Box Color", function() return Settings.BoxColor end, function(c) Settings.BoxColor = c end)
addColor(tabColors.scroll, "Skeleton Color", function() return Settings.SkeletonColor end, function(c) Settings.SkeletonColor = c end)
addColor(tabColors.scroll, "Tracer Color", function() return Settings.TracerColor end, function(c) Settings.TracerColor = c end)
addColor(tabColors.scroll, "Name Color", function() return Settings.TextColor end, function(c) Settings.TextColor = c end)
addColor(tabColors.scroll, "Health Color", function() return Settings.HealthColor end, function(c) Settings.HealthColor = c end)
addColor(tabColors.scroll, "Crosshair Color", function() return Settings.CrosshairColor end, function(c) Settings.CrosshairColor = c end)
addColor(tabColors.scroll, "Radar Color", function() return Settings.RadarColor end, function(c) Settings.RadarColor = c end)

addSection(tabColors.scroll, "World Colors")
addColor(tabColors.scroll, "Loot Color", function() return Settings.LootColor end, function(c) Settings.LootColor = c end)
addColor(tabColors.scroll, "Container Color", function() return Settings.ContainerColor end, function(c) Settings.ContainerColor = c end)
addColor(tabColors.scroll, "Extractor Color", function() return Settings.ExtractorColor end, function(c) Settings.ExtractorColor = c end)
addColor(tabColors.scroll, "Corpse Color", function() return Settings.CorpseColor end, function(c) Settings.CorpseColor = c end)
addColor(tabColors.scroll, "Weapon Color", function() return Settings.WeaponColor end, function(c) Settings.WeaponColor = c end)
addColor(tabColors.scroll, "Grenade Color", function() return Settings.GrenadeColor end, function(c) Settings.GrenadeColor = c end)
addColor(tabColors.scroll, "Skybox Color", function() return Settings.SkyboxColor end, function(c) Settings.SkyboxColor = c; updateSkybox() end)

addSection(tabColors.scroll, "Chams & Aimbot")
addColor(tabColors.scroll, "Chams Fill", function() return Settings.ChamsColor end, function(c) Settings.ChamsColor = c; refreshAllChams() end)
addColor(tabColors.scroll, "Chams Outline", function() return Settings.ChamsOutlineColor end, function(c) Settings.ChamsOutlineColor = c; refreshAllChams() end)
addColor(tabColors.scroll, "FOV Circle", function() return Settings.FOVColor end, function(c) Settings.FOVColor = c end)

local menuOpen = false
local animating = false

local function openMenu()
    if menuOpen or animating then return end
    animating = true
    menuOpen = true
    main.Visible = true
    uiScale.Scale = 0.85
    TweenService:Create(uiScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    main.BackgroundTransparency = 0.6
    TweenService:Create(main, TweenInfo.new(0.22), {BackgroundTransparency = 0}):Play()
    task.wait(0.28)
    animating = false
end

local function closeMenu()
    if not menuOpen or animating then return end
    animating = true
    menuOpen = false
    TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.85}):Play()
    TweenService:Create(main, TweenInfo.new(0.18), {BackgroundTransparency = 0.6}):Play()
    task.wait(0.18)
    main.Visible = false
    animating = false
end

toggleBtn.MouseButton1Click:Connect(function()
    if menuOpen then closeMenu() else openMenu() end
end)
closeBtn.MouseButton1Click:Connect(closeMenu)
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Settings.MenuKey then
        if menuOpen then closeMenu() else openMenu() end
    end
end))

local notif = new("Frame", {
    Size = UDim2.new(0, 230, 0, 46),
    Position = UDim2.new(0.5, -115, 0, -60),
    BackgroundColor3 = BG,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 20
}, menuGui)
corner(notif, 10)
local nStroke = new("UIStroke", {Color = ACCENT, Thickness = 1, Transparency = 1}, notif)
local nDot = new("Frame", {
    Size = UDim2.new(0, 8, 0, 8),
    Position = UDim2.new(0, 14, 0.5, -4),
    BackgroundColor3 = ACCENT,
    BorderSizePixel = 0,
    BackgroundTransparency = 1,
    ZIndex = 21
}, notif)
corner(nDot, 999)
local nText = new("TextLabel", {
    Size = UDim2.new(1, -36, 1, 0),
    Position = UDim2.new(0, 30, 0, 0),
    BackgroundTransparency = 1,
    Text = "Loaded",
    TextColor3 = ACCENT,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTransparency = 1,
    ZIndex = 21
}, notif)

task.spawn(function()
    TweenService:Create(notif, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -115, 0, 24),
        BackgroundTransparency = 0.1,
    }):Play()
    TweenService:Create(nStroke, TweenInfo.new(0.45), {Transparency = 0.25}):Play()
    TweenService:Create(nDot, TweenInfo.new(0.45), {BackgroundTransparency = 0}):Play()
    TweenService:Create(nText, TweenInfo.new(0.45), {TextTransparency = 0}):Play()
    task.wait(2.6)
    TweenService:Create(notif, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -115, 0, -60),
        BackgroundTransparency = 1,
    }):Play()
    TweenService:Create(nStroke, TweenInfo.new(0.45), {Transparency = 1}):Play()
    TweenService:Create(nDot, TweenInfo.new(0.45), {BackgroundTransparency = 1}):Play()
    TweenService:Create(nText, TweenInfo.new(0.45), {TextTransparency = 1}):Play()
    task.wait(0.5)
    notif:Destroy()
end)

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.NumSides = 48
fovCircle.Filled = false
fovCircle.Color = Settings.FOVColor
fovCircle.Visible = false
fovCircle.ZIndex = 0
fovCircle.Radius = Settings.AimFOV

for i = 1, 4 do
    crosshairLines[i] = Drawing.new("Line")
    crosshairLines[i].Thickness = 1
    crosshairLines[i].Color = Settings.CrosshairColor
    crosshairLines[i].Visible = false
    
    hitmarkerLines[i] = Drawing.new("Line")
    hitmarkerLines[i].Thickness = 2
    hitmarkerLines[i].Color = Color3.fromRGB(255, 255, 255)
    hitmarkerLines[i].Visible = false
end

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local skeletonOffsets = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

local skeletonOffsetsR6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function createObjects(player)
    if player == LocalPlayer or espObjects[player] then return end
    local lines = {}
    for i = 1, 14 do
        lines[i] = newDrawing("Line", {Thickness = 1.5, Color = Settings.SkeletonColor, Visible = false, ZIndex = 1})
    end
    
    local corners = {}
    for i = 1, 8 do
        corners[i] = newDrawing("Line", {Thickness = 1, Color = Settings.BoxColor, Visible = false, ZIndex = 1})
    end

    espObjects[player] = {
        box = newDrawing("Square", {Thickness = 1, Filled = false, Color = Settings.BoxColor, Visible = false, ZIndex = 1}),
        corners = corners,
        name = newDrawing("Text", {Size = 13, Center = true, Outline = true, Color = Settings.TextColor, Visible = false, ZIndex = 2}),
        weapon = newDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Settings.WeaponColor, Visible = false, ZIndex = 2}),
        healthBg = newDrawing("Square", {Thickness = 1, Filled = true, Color = Color3.fromRGB(20, 20, 20), Visible = false, ZIndex = 1}),
        healthFill = newDrawing("Square", {Thickness = 1, Filled = true, Color = Settings.HealthColor, Visible = false, ZIndex = 2}),
        tracer = newDrawing("Line", {Thickness = 1, Color = Settings.TracerColor, Visible = false, ZIndex = 0}),
        skeleton = lines,
    }
end

local function removeObjects(player)
    local o = espObjects[player]
    if not o then return end
    pcall(function() o.box:Remove() end)
    for _, c in pairs(o.corners) do pcall(function() c:Remove() end) end
    pcall(function() o.name:Remove() end)
    pcall(function() o.weapon:Remove() end)
    pcall(function() o.healthBg:Remove() end)
    pcall(function() o.healthFill:Remove() end)
    pcall(function() o.tracer:Remove() end)
    for _, l in pairs(o.skeleton) do pcall(function() l:Remove() end) end
    espObjects[player] = nil
end

local function hideAll(o)
    o.box.Visible = false
    for _, c in pairs(o.corners) do c.Visible = false end
    o.name.Visible = false
    o.weapon.Visible = false
    o.healthBg.Visible = false
    o.healthFill.Visible = false
    o.tracer.Visible = false
    for _, l in pairs(o.skeleton) do l.Visible = false end
end

local function getClosest()
    local closest = nil
    local shortest = Settings.AimFOV
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local part = char:FindFirstChild(Settings.AimPart)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if part and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and pos.Z > 0 then
                    local dist2d = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                    local dist3d = (myRoot.Position - part.Position).Magnitude
                    if dist2d < shortest and dist3d <= Settings.MaxDistance then
                        shortest = dist2d
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

local function isVisible(targetPart)
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin).Unit * (targetPart.Position - rayOrigin).Magnitude
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function drawSkeleton(char, lines)
    local isR15 = char:FindFirstChild("UpperTorso")
    local offsets = isR15 and skeletonOffsets or skeletonOffsetsR6
    for i, pair in ipairs(offsets) do
        local a = char:FindFirstChild(pair[1])
        local b = char:FindFirstChild(pair[2])
        local line = lines[i]
        if a and b and line then
            local p1, on1 = Camera:WorldToViewportPoint(a.Position)
            local p2, on2 = Camera:WorldToViewportPoint(b.Position)
            if on1 or on2 then
                line.From = Vector2.new(p1.X, p1.Y)
                line.To = Vector2.new(p2.X, p2.Y)
                line.Color = Settings.SkeletonColor
                line.Visible = true
            else
                line.Visible = false
            end
        elseif line then
            line.Visible = false
        end
    end
    for i = #offsets + 1, #lines do lines[i].Visible = false end
end

function refreshAllChams()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local hl = char:FindFirstChild("KM_Chams")
            if Settings.ChamsEnabled then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "KM_Chams"
                    hl.Adornee = char
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = char
                end
                hl.FillColor = Settings.ChamsColor
                hl.OutlineColor = Settings.ChamsOutlineColor
                hl.FillTransparency = Settings.ChamsFill
                hl.OutlineTransparency = 0
            elseif hl then hl:Destroy() end
        end
    end
end

local skyboxObj = nil
function updateSkybox()
    if Settings.Skybox then
        if not skyboxObj then
            skyboxObj = Instance.new("Sky")
            skyboxObj.Parent = Lighting
        end
        local c = Settings.SkyboxColor
        local asset = "rbxassetid://0"
        skyboxObj.SkyboxBk = asset
        skyboxObj.SkyboxDn = asset
        skyboxObj.SkyboxFt = asset
        skyboxObj.SkyboxLf = asset
        skyboxObj.SkyboxRt = asset
        skyboxObj.SkyboxUp = asset
        
        local cc = Lighting:FindFirstChild("KM_CC")
        if not cc then
            cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "KM_CC"
            cc.Parent = Lighting
        end
        cc.TintColor = c
    else
        if skyboxObj then skyboxObj:Destroy(); skyboxObj = nil end
        local cc = Lighting:FindFirstChild("KM_CC")
        if cc then cc:Destroy() end
    end
end

function updateLighting()
    if Settings.Fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        
        if atmos then
            atmos.Density = 0
            atmos.Haze = 0
            atmos.Glare = 0
            atmos.Color = Color3.fromRGB(255, 255, 255)
        end
        
        if sky then
            sky.SkyboxBk = "rbxassetid://0"
            sky.SkyboxDn = "rbxassetid://0"
            sky.SkyboxFt = "rbxassetid://0"
            sky.SkyboxLf = "rbxassetid://0"
            sky.SkyboxRt = "rbxassetid://0"
            sky.SkyboxUp = "rbxassetid://0"
        end
        
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("ColorCorrectionEffect") then
                v.Enabled = false
            end
        end
    else
        Lighting.Brightness = origBrightness
        Lighting.ClockTime = origClockTime
        Lighting.FogEnd = origFogEnd
        Lighting.FogStart = origFogStart
        Lighting.GlobalShadows = origGlobalShadows
        Lighting.OutdoorAmbient = origAmbient
        Lighting.Ambient = origAmbient
        
        if atmos then
            atmos.Density = origAtmosDensity
            atmos.Haze = origAtmosHaze
            atmos.Glare = origAtmosGlare
            atmos.Color = origAtmosColor
        end
        
        if sky then
            sky.SkyboxBk = origSky.Bk
            sky.SkyboxDn = origSky.Dn
            sky.SkyboxFt = origSky.Ft
            sky.SkyboxLf = origSky.Lf
            sky.SkyboxRt = origSky.Rt
            sky.SkyboxUp = origSky.Up
        end
        
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("ColorCorrectionEffect") then
                v.Enabled = true
            end
        end
    end
end

local freecamEnabled = false
local freecamCFrame = CFrame.new()
local freecamConn = nil
local freecamYaw, freecamPitch = 0, 0

function toggleFreecam()
    freecamEnabled = Settings.Freecam
    if freecamEnabled then
        freecamCFrame = Camera.CFrame
        local look = Camera.CFrame.LookVector
        freecamYaw = math.atan2(-look.X, -look.Z)
        freecamPitch = math.asin(look.Y)
        
        if freecamConn then freecamConn:Disconnect() end
        freecamConn = RunService.RenderStepped:Connect(function(dt)
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CameraSubject = nil
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            
            local delta = UserInputService:GetMouseDelta()
            
            if delta.Magnitude == 0 and UserInputService:GetMouseLocation() then
                local mpos = UserInputService:GetMouseLocation()
                delta = Vector2.new(mpos.X - Camera.ViewportSize.X/2, mpos.Y - Camera.ViewportSize.Y/2)
            end
            
            freecamYaw = freecamYaw - delta.X * 0.005
            freecamPitch = math.clamp(freecamPitch - delta.Y * 0.005, -math.pi/2 + 0.01, math.pi/2 - 0.01)
            
            local camCF = CFrame.new(freecamCFrame.Position) * CFrame.Angles(0, freecamYaw, 0) * CFrame.Angles(freecamPitch, 0, 0)
            
            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
            
            if move.Magnitude > 0 then
                freecamCFrame = freecamCFrame + (move.Unit * Settings.FreecamSpeed * dt)
            end
            
            Camera.CFrame = CFrame.new(freecamCFrame.Position) * CFrame.Angles(0, freecamYaw, 0) * CFrame.Angles(freecamPitch, 0, 0)
        end)
    else
        if freecamConn then freecamConn:Disconnect() end
        Camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if LocalPlayer.Character then
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    end
end

local aiming = false
local triggerbotHeld = false
local hitmarkerTimer = 0

local function isLoot(obj)
    if not obj:IsA("Model") and not obj:IsA("BasePart") then return nil end
    if obj == LocalPlayer.Character or obj:IsDescendantOf(LocalPlayer.Character) then return nil end
    
    local isChar = false
    if obj:IsA("Model") then
        if obj:FindFirstChildOfClass("Humanoid") then isChar = true end
        if Players:GetPlayerFromCharacter(obj) then isChar = true end
    end
    if isChar then
        local hum = obj:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then
            return "Corpse"
        end
        return nil
    end
    
    local name = obj.Name:lower()
    
    if name:find("hitbox") or name:find("humanoid") or name:find("torso") or name:find("head") then
        return nil
    end
    
    if name:find("crate") or name:find("container") or name:find("chest") or name:find("safe") or name:find("stash") or name:find("military") then
        return "Container"
    elseif name:find("extract") or name:find("evac") or name:find("exit") then
        return "Extractor"
    elseif name:find("grenade") or name:find("frag") or name:find("projectile") or name:find("bomb") then
        return "Grenade"
    elseif name:find("loot") or name:find("item") or name:find("weapon") or name:find("ammo") or name:find("med") or name:find("tool") or name:find("rifle") or name:find("pistol") then
        return "Loot"
    end
    return nil
end

local function addWorldObject(obj, espType)
    if worldObjects[obj] then return end
    local text = Drawing.new("Text")
    text.Size = 12
    text.Center = true
    text.Outline = true
    text.Text = obj.Name
    text.Visible = false
    worldObjects[obj] = {text = text, type = espType}
    
    obj.AncestryChanged:Connect(function()
        if not obj:IsDescendantOf(game) then
            if worldObjects[obj] then
                pcall(function() worldObjects[obj].text:Remove() end)
                worldObjects[obj] = nil
            end
        end
    end)
end

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") or obj:IsA("BasePart") then
        local espType = isLoot(obj)
        if espType then
            addWorldObject(obj, espType)
        end
    end
end)

for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Model") or obj:IsA("BasePart") then
        if Players:GetPlayerFromCharacter(obj) then continue end
        local espType = isLoot(obj)
        if espType then
            addWorldObject(obj, espType)
        end
    end
end

local function showHitmarker()
    hitmarkerTimer = 0.2
end

local function update()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if not freecamEnabled and not aiming and Camera.FieldOfView ~= Settings.CameraFOV then
        Camera.FieldOfView = Settings.CameraFOV
    end

    fovCircle.Position = Vector2.new(mouse.X, mouse.Y + 36)
    fovCircle.Radius = Settings.AimFOV
    fovCircle.Color = Settings.FOVColor
    fovCircle.Visible = Settings.ShowFOV and Settings.AimEnabled and not freecamEnabled

    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2
    local gap = 3
    local len = 6
    
    crosshairLines[1].From = Vector2.new(cx, cy - gap)
    crosshairLines[1].To = Vector2.new(cx, cy - gap - len)
    
    crosshairLines[2].From = Vector2.new(cx, cy + gap)
    crosshairLines[2].To = Vector2.new(cx, cy + gap + len)
    
    crosshairLines[3].From = Vector2.new(cx - gap, cy)
    crosshairLines[3].To = Vector2.new(cx - gap - len, cy)
    
    crosshairLines[4].From = Vector2.new(cx + gap, cy)
    crosshairLines[4].To = Vector2.new(cx + gap + len, cy)

    for i = 1, 4 do
        crosshairLines[i].Color = Settings.CrosshairColor
        crosshairLines[i].Visible = Settings.Crosshair and not freecamEnabled
    end

    if hitmarkerTimer > 0 then
        hitmarkerTimer = hitmarkerTimer - (RunService.RenderStepped:Wait() or 0.016)
        local gapH = 6
        local lenH = 8
        hitmarkerLines[1].From = Vector2.new(cx - gapH, cy - gapH)
        hitmarkerLines[1].To = Vector2.new(cx - gapH - lenH, cy - gapH - lenH)
        hitmarkerLines[2].From = Vector2.new(cx + gapH, cy - gapH)
        hitmarkerLines[2].To = Vector2.new(cx + gapH + lenH, cy - gapH - lenH)
        hitmarkerLines[3].From = Vector2.new(cx - gapH, cy + gapH)
        hitmarkerLines[3].To = Vector2.new(cx - gapH - lenH, cy + gapH + lenH)
        hitmarkerLines[4].From = Vector2.new(cx + gapH, cy + gapH)
        hitmarkerLines[4].To = Vector2.new(cx + gapH + lenH, cy + gapH + lenH)
        
        for i = 1, 4 do
            hitmarkerLines[i].Color = Color3.fromRGB(255, 255, 255)
            hitmarkerLines[i].Visible = true
        end
    else
        for i = 1, 4 do hitmarkerLines[i].Visible = false end
    end

    if Settings.AimEnabled and aiming and not freecamEnabled then
        local target = getClosest()
        if target then
            if Settings.SilentAim then
                mouse.Target = target
            else
                local current = Camera.CFrame
                local goal = CFrame.new(current.Position, target.Position)
                Camera.CFrame = current:Lerp(goal, Settings.AimSmooth)
            end
        end
    end

    if Settings.Triggerbot and triggerbotHeld and myRoot and not freecamEnabled then
        local target = getClosest()
        if target then
            local dist = (myRoot.Position - target.Position).Magnitude
            if dist <= Settings.TriggerbotDist then
                if isVisible(target) then
                    if mouse1click then mouse1click() end
                    showHitmarker()
                end
            end
        end
    end

    for player, o in pairs(espObjects) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if Settings.ESPEnabled and head and root and hum and hum.Health > 0 and myRoot then
            local dist = (myRoot.Position - root.Position).Magnitude
            if dist <= Settings.MaxDistance then
                local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.4, 0))
                local footPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local rootPos = Camera:WorldToViewportPoint(root.Position)

                if onScreen then
                    local height = math.abs(footPos.Y - headPos.Y)
                    local width = height * 0.55
                    local x = headPos.X - width / 2
                    local y = headPos.Y

                    if Settings.BoxESP then
                        if Settings.CornerBoxESP then
                            o.box.Visible = false
                            local cLen = math.min(width, height) * 0.2
                            
                            o.corners[1].From = Vector2.new(x, y)
                            o.corners[1].To = Vector2.new(x + cLen, y)
                            o.corners[2].From = Vector2.new(x, y)
                            o.corners[2].To = Vector2.new(x, y + cLen)
                            
                            o.corners[3].From = Vector2.new(x + width, y)
                            o.corners[3].To = Vector2.new(x + width - cLen, y)
                            o.corners[4].From = Vector2.new(x + width, y)
                            o.corners[4].To = Vector2.new(x + width, y + cLen)
                            
                            o.corners[5].From = Vector2.new(x, y + height)
                            o.corners[5].To = Vector2.new(x + cLen, y + height)
                            o.corners[6].From = Vector2.new(x, y + height)
                            o.corners[6].To = Vector2.new(x, y + height - cLen)
                            
                            o.corners[7].From = Vector2.new(x + width, y + height)
                            o.corners[7].To = Vector2.new(x + width - cLen, y + height)
                            o.corners[8].From = Vector2.new(x + width, y + height)
                            o.corners[8].To = Vector2.new(x + width, y + height - cLen)
                            
                            for i = 1, 8 do
                                o.corners[i].Color = Settings.BoxColor
                                o.corners[i].Visible = true
                            end
                        else
                            o.box.Position = Vector2.new(x, y)
                            o.box.Size = Vector2.new(width, height)
                            o.box.Color = Settings.BoxColor
                            o.box.Visible = true
                            for i = 1, 8 do o.corners[i].Visible = false end
                        end
                    else
                        o.box.Visible = false
                        for i = 1, 8 do o.corners[i].Visible = false end
                    end

                    o.name.Text = string.format("%s [%d]", player.DisplayName, math.floor(dist))
                    o.name.Position = Vector2.new(headPos.X, headPos.Y - 15)
                    o.name.Color = Settings.TextColor
                    o.name.Visible = true
                    
                    if Settings.WeaponESP and dist <= Settings.WeaponDist then
                        local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
                        if rightHand then
                            local weapon = rightHand:FindFirstChildOfClass("Tool") or rightHand:FindFirstChildWhichIsA("Model")
                            if weapon then
                                o.weapon.Text = weapon.Name
                                o.weapon.Position = Vector2.new(headPos.X, headPos.Y - 28)
                                o.weapon.Color = Settings.WeaponColor
                                o.weapon.Visible = true
                            else
                                o.weapon.Visible = false
                            end
                        else
                            o.weapon.Visible = false
                        end
                    else
                        o.weapon.Visible = false
                    end

                    if Settings.HealthBar then
                        local barWidth = 2
                        local barHeight = height
                        local barX = x - 6
                        local barY = y
                        
                        o.healthBg.Position = Vector2.new(barX, barY)
                        o.healthBg.Size = Vector2.new(barWidth, barHeight)
                        o.healthBg.Visible = true
                        
                        local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local fillHeight = barHeight * healthPct
                        
                        o.healthFill.Position = Vector2.new(barX, barY + barHeight - fillHeight)
                        o.healthFill.Size = Vector2.new(barWidth, fillHeight)
                        o.healthFill.Color = Settings.HealthColor
                        o.healthFill.Visible = true
                    else
                        o.healthBg.Visible = false
                        o.healthFill.Visible = false
                    end

                    if Settings.TracerESP then
                        local from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        o.tracer.From = from
                        o.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                        o.tracer.Color = Settings.TracerColor
                        o.tracer.Visible = true
                    else
                        o.tracer.Visible = false
                    end

                    if Settings.SkeletonESP then
                        drawSkeleton(char, o.skeleton)
                    else
                        for _, l in pairs(o.skeleton) do l.Visible = false end
                    end
                else
                    hideAll(o)
                end
            else
                hideAll(o)
            end
        else
            hideAll(o)
        end
    end

    if Settings.Radar and myRoot then
        local radarX = 100
        local radarY = Camera.ViewportSize.Y - 100
        local radarRadius = 80
        
        if not radarBg then
            radarBg = Drawing.new("Circle")
            radarBg.NumSides = 32
            radarBg.Filled = true
            radarBg.Color = Color3.fromRGB(0, 0, 0)
            radarBg.Transparency = 0.5
        end
        
        radarBg.Position = Vector2.new(radarX, radarY)
        radarBg.Radius = radarRadius
        radarBg.Visible = true
        
        local myPos = myRoot.Position
        local camLook = Camera.CFrame.LookVector
        local angle = math.atan2(camLook.X, camLook.Z)
        local idx = 1
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local rel = root.Position - myPos
                    local dist = rel.Magnitude
                    if dist <= 200 then
                        local rx = rel.X * math.cos(-angle) - rel.Z * math.sin(-angle)
                        local rz = rel.X * math.sin(-angle) + rel.Z * math.cos(-angle)
                        
                        local px = radarX + (rx / 200) * radarRadius
                        local py = radarY - (rz / 200) * radarRadius
                        
                        if not radarBlips[idx] then
                            radarBlips[idx] = Drawing.new("Circle")
                            radarBlips[idx].NumSides = 8
                            radarBlips[idx].Filled = true
                            radarBlips[idx].Radius = 3
                        end
                        
                        radarBlips[idx].Position = Vector2.new(px, py)
                        radarBlips[idx].Color = Settings.RadarColor
                        radarBlips[idx].Visible = true
                    else
                        if radarBlips[idx] then radarBlips[idx].Visible = false end
                    end
                    idx = idx + 1
                end
            end
        end
        for i = idx, #radarBlips do
            radarBlips[i].Visible = false
        end
    else
        if radarBg then radarBg.Visible = false end
        for _, blip in ipairs(radarBlips) do blip.Visible = false end
    end

    for obj, data in pairs(worldObjects) do
        if not obj.Parent or not obj:IsDescendantOf(game) then
            pcall(function() data.text:Remove() end)
            worldObjects[obj] = nil
        else
            local shouldShow = false
            if Settings.LootESP and data.type == "Loot" then shouldShow = true end
            if Settings.ContainerESP and data.type == "Container" then shouldShow = true end
            if Settings.ExtractorESP and data.type == "Extractor" then shouldShow = true end
            if Settings.GrenadeESP and data.type == "Grenade" then shouldShow = true end
            if Settings.CorpseESP and data.type == "Corpse" then shouldShow = true end
            
            if shouldShow and myRoot then
                local pos = nil
                if obj:IsA("Model") then
                    local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if p then pos = p.Position end
                elseif obj:IsA("BasePart") then
                    pos = obj.Position
                end
                
                if pos then
                    local dist = (myRoot.Position - pos).Magnitude
                    local maxDist = 0
                    if data.type == "Loot" then maxDist = Settings.LootDist
                    elseif data.type == "Container" then maxDist = Settings.ContainerDist
                    elseif data.type == "Extractor" then maxDist = Settings.ExtractorDist
                    elseif data.type == "Grenade" then maxDist = Settings.GrenadeDist
                    elseif data.type == "Corpse" then maxDist = Settings.CorpseDist
                    end
                    
                    if dist <= maxDist then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                        if onScreen and screenPos.Z > 0 then
                            data.text.Position = Vector2.new(screenPos.X, screenPos.Y)
                            
                            if data.type == "Loot" then
                                data.text.Color = Settings.LootColor
                                if Settings.LootFilter then
                                    local n = obj.Name:lower()
                                    local isW = n:find("weapon") or n:find("gun") or n:find("ammo") or n:find("rifle") or n:find("pistol")
                                    local isM = n:find("med") or n:find("health") or n:find("bandage")
                                    local isA = n:find("armor") or n:find("vest") or n:find("helmet")
                                    if (isW and not Settings.FilterWeapons) or (isM and not Settings.FilterMeds) or (isA and not Settings.FilterArmor) then
                                        data.text.Visible = false
                                    else
                                        data.text.Visible = true
                                    end
                                else
                                    data.text.Visible = true
                                end
                            elseif data.type == "Container" then
                                data.text.Color = Settings.ContainerColor
                                data.text.Visible = true
                            elseif data.type == "Extractor" then
                                data.text.Color = Settings.ExtractorColor
                                data.text.Visible = true
                            elseif data.type == "Grenade" then
                                data.text.Color = Settings.GrenadeColor
                                data.text.Visible = true
                            elseif data.type == "Corpse" then
                                data.text.Color = Settings.CorpseColor
                                data.text.Visible = true
                            end
                        else
                            data.text.Visible = false
                        end
                    else
                        data.text.Visible = false
                    end
                else
                    data.text.Visible = false
                end
            else
                data.text.Visible = false
            end
        end
    end
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Settings.AimKey then aiming = true end
    if input.KeyCode == Settings.TriggerbotKey then triggerbotHeld = true end
    if input.KeyCode == Settings.FreecamKey then 
        Settings.Freecam = not Settings.Freecam
        toggleFreecam()
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if Settings.Hitmarker and mouse.Target and mouse.Target:FindFirstAncestorOfClass("Model") then
            local model = mouse.Target:FindFirstAncestorOfClass("Model")
            if Players:GetPlayerFromCharacter(model) then
                showHitmarker()
            end
        end
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Settings.AimKey then aiming = false end
    if input.KeyCode == Settings.TriggerbotKey then triggerbotHeld = false end
end))

for _, p in ipairs(Players:GetPlayers()) do createObjects(p) end
table.insert(connections, Players.PlayerAdded:Connect(function(p) createObjects(p); refreshAllChams() end))
table.insert(connections, Players.PlayerRemoving:Connect(removeObjects))

table.insert(connections, RunService.RenderStepped:Connect(update))

_G.KM_UNLOAD = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for player in pairs(espObjects) do removeObjects(player) end
    for obj, data in pairs(worldObjects) do pcall(function() data.text:Remove() end) end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("KM_Chams")
            if hl then hl:Destroy() end
        end
    end
    for i = 1, 4 do 
        pcall(function() crosshairLines[i]:Remove() end)
        pcall(function() hitmarkerLines[i]:Remove() end)
    end
    if radarBg then radarBg:Remove() end
    for _, blip in ipairs(radarBlips) do pcall(function() blip:Remove() end) end
    if skyboxObj then skyboxObj:Destroy() end
    local cc = Lighting:FindFirstChild("KM_CC")
    if cc then cc:Destroy() end
    
    Lighting.Brightness = origBrightness
    Lighting.ClockTime = origClockTime
    Lighting.FogEnd = origFogEnd
    Lighting.FogStart = origFogStart
    Lighting.GlobalShadows = origGlobalShadows
    Lighting.OutdoorAmbient = origAmbient
    Lighting.Ambient = origAmbient
    
    if atmos then
        atmos.Density = origAtmosDensity
        atmos.Haze = origAtmosHaze
        atmos.Glare = origAtmosGlare
        atmos.Color = origAtmosColor
    end
    
    if sky then
        sky.SkyboxBk = origSky.Bk
        sky.SkyboxDn = origSky.Dn
        sky.SkyboxFt = origSky.Ft
        sky.SkyboxLf = origSky.Lf
        sky.SkyboxRt = origSky.Rt
        sky.SkyboxUp = origSky.Up
    end
    
    for _, v in ipairs(Lighting:GetDescendants()) do
        if v:IsA("ColorCorrectionEffect") then
            v.Enabled = true
        end
    end
    
    Camera.CameraType = Enum.CameraType.Custom
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    Camera.FieldOfView = origFOV
    
    pcall(function() fovCircle:Remove() end)
    pcall(function() menuGui:Destroy() end)
    _G.KM_UNLOAD = nil
end

print("Loaded")
-- https://www.youtube.com/@WadaS-z7z