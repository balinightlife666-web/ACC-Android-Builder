-- LOST & FOUND: NIGHT SHIFT — M5-D Premium Station Structural Pass
-- Paid themes must read as different station silhouettes, not palette swaps.
-- Presentation-only overlay: no gameplay/economy/inventory/showcase lifecycle mutation.
-- M5-B.2.1 remains sole five-slot rack geometry authority.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local WORLD_NAME = "LostAndFoundM4D"
local DECOR_NAME = "M5DStructuralDecor"
local VERSION = "M5D_PREMIUM_STRUCTURE_V1"

local function part(parent, name, size, cframe, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Transparency = transparency or 0
    p.Parent = parent
    return p
end

local function textPart(parent, name, size, cframe, background, text, color, font)
    local p = part(parent, name, size, cframe, background, Enum.Material.SmoothPlastic, 0)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "M5DText"
    gui.Face = Enum.NormalId.Front
    gui.LightInfluence = 0
    gui.PixelsPerStud = 60
    gui.Parent = p
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = font or Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
    return p
end

local function clear(station)
    local old = station:FindFirstChild(DECOR_NAME)
    if old then old:Destroy() end
    station:SetAttribute("M5DStructuralTheme", nil)
end

local function createDecor(station, kind)
    local model = Instance.new("Model")
    model.Name = DECOR_NAME
    model:SetAttribute("ThemeKind", kind)
    model:SetAttribute("Version", VERSION)
    model.Parent = station
    return model
end

local function consoleTops(station)
    local result = {}
    for _, child in ipairs(station:GetChildren()) do
        if child:IsA("Model") and string.match(child.Name, "Console$") then
            local top = child:FindFirstChild("Top") or child:FindFirstChildWhichIsA("BasePart")
            if top and top:IsA("BasePart") then table.insert(result, top) end
        end
    end
    table.sort(result, function(a, b)
        if math.abs(a.Position.Z - b.Position.Z) > 0.01 then return a.Position.Z < b.Position.Z end
        return a.Position.X < b.Position.X
    end)
    return result
end

local function buildArmy(station, palette, bay)
    local decor = createDecor(station, "ARMY")
    local x = bay.Position.X + 2.0
    local zBack = bay.Position.Z - 13.12
    local dark = Color3.fromRGB(42, 48, 34)
    local olive = palette.base or Color3.fromRGB(61, 67, 48)
    local accent = palette.accent or Color3.fromRGB(177, 151, 76)
    local trim = palette.trim or Color3.fromRGB(105, 104, 76)

    part(decor, "RackPillarL", Vector3.new(0.42, 6.25, 0.62), CFrame.new(x - 10.05, 10.35, zBack - 0.12), dark, Enum.Material.DiamondPlate)
    part(decor, "RackPillarR", Vector3.new(0.42, 6.25, 0.62), CFrame.new(x + 10.05, 10.35, zBack - 0.12), dark, Enum.Material.DiamondPlate)
    part(decor, "RackHeader", Vector3.new(20.45, 0.48, 0.72), CFrame.new(x, 13.35, zBack - 0.10), olive, Enum.Material.DiamondPlate)
    part(decor, "RackHeaderAccent", Vector3.new(8.5, 0.10, 0.76), CFrame.new(x, 13.09, zBack - 0.08), accent, Enum.Material.Neon, 0.08)
    part(decor, "CanopyRoof", Vector3.new(20.6, 0.26, 2.25), CFrame.new(x, 13.62, zBack + 0.95), olive, Enum.Material.DiamondPlate)
    for _, dx in ipairs({-9.5, 9.5}) do
        part(decor, "CanopyBrace" .. tostring(dx), Vector3.new(0.22, 1.45, 2.45), CFrame.new(x + dx, 12.95, zBack + 0.92) * CFrame.Angles(math.rad(-22), 0, 0), dark, Enum.Material.Metal)
    end
    textPart(decor, "CommandHeader", Vector3.new(8.2, 0.72, 0.12), CFrame.new(x, 14.05, zBack + 0.45), olive, "FIELD PROPERTY COMMAND", accent, Enum.Font.RobotoMono)

    for index, top in ipairs(consoleTops(station)) do
        local cf, sz = top.CFrame, top.Size
        part(decor, "ConsoleArmorL" .. index, Vector3.new(0.13, 0.72, sz.Z + 0.36), cf * CFrame.new(-(sz.X * 0.5 + 0.12), -0.15, 0), dark, Enum.Material.DiamondPlate)
        part(decor, "ConsoleArmorR" .. index, Vector3.new(0.13, 0.72, sz.Z + 0.36), cf * CFrame.new((sz.X * 0.5 + 0.12), -0.15, 0), dark, Enum.Material.DiamondPlate)
        part(decor, "ConsoleGuard" .. index, Vector3.new(sz.X + 0.32, 0.11, 0.16), cf * CFrame.new(0, 0.18, -(sz.Z * 0.5 + 0.10)), trim, Enum.Material.Metal)
    end
end

local function buildSakura(station, palette, bay)
    local decor = createDecor(station, "SAKURA")
    local x = bay.Position.X + 2.0
    local zBack = bay.Position.Z - 13.12
    local wood = Color3.fromRGB(78, 49, 47)
    local woodLight = Color3.fromRGB(116, 73, 70)
    local pink = palette.accent or Color3.fromRGB(238, 139, 174)
    local softPink = Color3.fromRGB(255, 192, 214)

    part(decor, "RackPostL", Vector3.new(0.34, 6.35, 0.52), CFrame.new(x - 10.05, 10.45, zBack - 0.10), wood, Enum.Material.WoodPlanks)
    part(decor, "RackPostR", Vector3.new(0.34, 6.35, 0.52), CFrame.new(x + 10.05, 10.45, zBack - 0.10), wood, Enum.Material.WoodPlanks)
    part(decor, "RackLintel", Vector3.new(20.65, 0.34, 0.62), CFrame.new(x, 13.38, zBack - 0.08), woodLight, Enum.Material.WoodPlanks)
    part(decor, "EaveLower", Vector3.new(21.4, 0.18, 1.40), CFrame.new(x, 13.73, zBack + 0.25), wood, Enum.Material.WoodPlanks)
    part(decor, "EaveUpper", Vector3.new(19.8, 0.16, 1.85), CFrame.new(x, 13.96, zBack + 0.18), Color3.fromRGB(38, 30, 38), Enum.Material.SmoothPlastic)
    part(decor, "EaveGlow", Vector3.new(10.2, 0.08, 1.90), CFrame.new(x, 13.84, zBack + 0.22), pink, Enum.Material.Neon, 0.38)

    for i, dx in ipairs({-8.7, -4.35, 0, 4.35, 8.7}) do
        local lantern = part(decor, "Lantern" .. i, Vector3.new(0.42, 0.66, 0.42), CFrame.new(x + dx, 13.10, zBack + 0.75), i % 2 == 0 and softPink or pink, Enum.Material.Neon, 0.15)
        local light = Instance.new("PointLight")
        light.Name = "LanternLight"
        light.Color = lantern.Color
        light.Brightness = 0.18
        light.Range = 3.2
        light.Shadows = false
        light.Parent = lantern
    end
    textPart(decor, "NightHeader", Vector3.new(6.6, 0.66, 0.11), CFrame.new(x, 14.36, zBack + 0.45), Color3.fromRGB(35, 27, 35), "SAKURA NIGHT // LOST PROPERTY", softPink, Enum.Font.GothamMedium)

    for index, top in ipairs(consoleTops(station)) do
        local cf, sz = top.CFrame, top.Size
        part(decor, "ConsoleWoodL" .. index, Vector3.new(0.10, 0.66, sz.Z + 0.28), cf * CFrame.new(-(sz.X * 0.5 + 0.10), -0.12, 0), wood, Enum.Material.WoodPlanks)
        part(decor, "ConsoleWoodR" .. index, Vector3.new(0.10, 0.66, sz.Z + 0.28), cf * CFrame.new((sz.X * 0.5 + 0.10), -0.12, 0), wood, Enum.Material.WoodPlanks)
        for slat = -1, 1 do
            part(decor, "ConsoleSlat" .. index .. "_" .. slat, Vector3.new(0.09, 0.48, 0.08), cf * CFrame.new(slat * math.min(0.30, sz.X * 0.20), -0.22, -(sz.Z * 0.5 + 0.09)), slat == 0 and pink or wood, slat == 0 and Enum.Material.Neon or Enum.Material.WoodPlanks, slat == 0 and 0.22 or 0)
        end
    end
end

local function buildStreet(station, palette, bay)
    local decor = createDecor(station, "STREET")
    local x = bay.Position.X + 2.0
    local zBack = bay.Position.Z - 13.12
    local steel = Color3.fromRGB(68, 72, 78)
    local dark = Color3.fromRGB(24, 25, 29)
    local cyan = palette.accent or Color3.fromRGB(64, 215, 190)
    local magenta = Color3.fromRGB(224, 74, 149)

    for _, dx in ipairs({-10.15, 10.15}) do
        part(decor, "ScaffoldPost" .. tostring(dx), Vector3.new(0.22, 6.55, 0.22), CFrame.new(x + dx, 10.45, zBack - 0.02), steel, Enum.Material.Metal)
    end
    part(decor, "ScaffoldTop", Vector3.new(20.55, 0.20, 0.22), CFrame.new(x, 13.62, zBack - 0.02), steel, Enum.Material.Metal)
    part(decor, "ScaffoldDiagL", Vector3.new(0.16, 6.8, 0.16), CFrame.new(x - 7.4, 10.45, zBack - 0.04) * CFrame.Angles(0, 0, math.rad(-28)), steel, Enum.Material.Metal)
    part(decor, "ScaffoldDiagR", Vector3.new(0.16, 6.8, 0.16), CFrame.new(x + 7.4, 10.45, zBack - 0.04) * CFrame.Angles(0, 0, math.rad(28)), steel, Enum.Material.Metal)
    part(decor, "Awning", Vector3.new(13.6, 0.22, 2.05), CFrame.new(x - 2.7, 14.05, zBack + 0.72) * CFrame.Angles(0, 0, math.rad(-2.5)), dark, Enum.Material.DiamondPlate)
    part(decor, "AwningCyan", Vector3.new(7.3, 0.08, 2.10), CFrame.new(x - 5.7, 13.92, zBack + 0.72), cyan, Enum.Material.Neon, 0.30)
    part(decor, "AwningMagenta", Vector3.new(5.2, 0.08, 2.10), CFrame.new(x + 1.0, 13.92, zBack + 0.72), magenta, Enum.Material.Neon, 0.36)
    textPart(decor, "CrewSign", Vector3.new(7.8, 0.90, 0.12), CFrame.new(x + 4.8, 14.55, zBack + 0.52) * CFrame.Angles(0, 0, math.rad(4)), dark, "NIGHT PROPERTY CREW", magenta, Enum.Font.Arcade)

    for index, top in ipairs(consoleTops(station)) do
        local cf, sz = top.CFrame, top.Size
        local accent = index % 2 == 0 and magenta or cyan
        part(decor, "ConsoleCageL" .. index, Vector3.new(0.10, 0.78, sz.Z + 0.30), cf * CFrame.new(-(sz.X * 0.5 + 0.11), -0.12, 0), steel, Enum.Material.Metal)
        part(decor, "ConsoleCageR" .. index, Vector3.new(0.10, 0.78, sz.Z + 0.30), cf * CFrame.new((sz.X * 0.5 + 0.11), -0.12, 0), steel, Enum.Material.Metal)
        part(decor, "ConsoleTag" .. index, Vector3.new(math.max(0.42, sz.X * 0.42), 0.08, 0.10), cf * CFrame.new(0, 0.20, -(sz.Z * 0.5 + 0.10)), accent, Enum.Material.Neon, 0.08)
    end
end

local function applyStation(station)
    if not station or not station:IsA("Model") then return end
    if string.sub(station.Name, 1, 8) ~= "Station_" then return end
    clear(station)
    local bay = station:FindFirstChild("BayFloor")
    if not bay or not bay:IsA("BasePart") then return end
    local skin = StationSkinRegistry.Get(station:GetAttribute("SkinId"))
    local kind = skin and skin.theme and skin.theme.kind or "PALETTE"
    local palette = skin and skin.palette or {}
    if kind == "ARMY" then
        buildArmy(station, palette, bay)
    elseif kind == "SAKURA" then
        buildSakura(station, palette, bay)
    elseif kind == "STREET" then
        buildStreet(station, palette, bay)
    else
        return
    end
    station:SetAttribute("M5DStructuralTheme", kind)
    station:SetAttribute("M5DStructuralVersion", VERSION)
end

local bound = setmetatable({}, {__mode = "k"})
local function bindStation(station)
    if not station or not station:IsA("Model") then return end
    if string.sub(station.Name, 1, 8) ~= "Station_" then return end
    if bound[station] then return end
    bound[station] = true
    station:GetAttributeChangedSignal("SkinId"):Connect(function() task.defer(applyStation, station) end)
    task.defer(applyStation, station)
    task.delay(0.65, function() if station.Parent then applyStation(station) end end)
    task.delay(1.8, function() if station.Parent then applyStation(station) end end)
end

local function bindWorld(world)
    if not world or world.Name ~= WORLD_NAME then return end
    for _, child in ipairs(world:GetChildren()) do bindStation(child) end
    world.ChildAdded:Connect(function(child) task.defer(bindStation, child) end)
end

local existing = workspace:FindFirstChild(WORLD_NAME)
if existing then task.defer(bindWorld, existing) end
workspace.ChildAdded:Connect(function(child)
    if child.Name == WORLD_NAME then task.defer(bindWorld, child) end
end)
