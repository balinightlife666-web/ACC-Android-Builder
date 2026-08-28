-- LOST & FOUND: NIGHT SHIFT — M5-A.3 premium station theme decorator.
-- Full paid themes are Roblox-only procedural geometry/text. No external images or textures.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local DECOR_NAME = "ThemeDecorations"
local MATERIAL_ATTR = "M5A3OriginalMaterial"
local LIGHT_ATTR = "M5A3OriginalBrightness"

local function materialFromName(name)
    if type(name) ~= "string" then return nil end
    local ok, value = pcall(function()
        return Enum.Material[name]
    end)
    return ok and value or nil
end

local function decorPart(parent, name, size, cframe, color, material, transparency)
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
    p.Material = material or Enum.Material.SmoothPlastic
    p.Transparency = transparency or 0
    p.Parent = parent
    return p
end

local function textPanel(parent, name, size, cframe, background, text, textColor, font)
    local p = decorPart(parent, name, size, cframe, background, Enum.Material.SmoothPlastic)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "ThemeText"
    gui.Face = Enum.NormalId.Front
    gui.LightInfluence = 0
    gui.PixelsPerStud = 54
    gui.Parent = p

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = textColor
    label.Font = font or Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
    return p
end

local function clearDecor(station)
    local old = station:FindFirstChild(DECOR_NAME)
    if old then old:Destroy() end
end

local function applyMaterials(station, theme)
    local materialByRole = theme and theme.materialByRole or nil
    local lightMultiplier = tonumber(theme and theme.lightMultiplier) or 1

    for _, instance in ipairs(station:GetDescendants()) do
        if instance:IsA("BasePart") and not instance:IsDescendantOf(station:FindFirstChild(DECOR_NAME) or Instance.new("Folder")) then
            local role = instance:GetAttribute("StationSkinRole")
            if role then
                local original = instance:GetAttribute(MATERIAL_ATTR)
                if not original then
                    original = instance.Material.Name
                    instance:SetAttribute(MATERIAL_ATTR, original)
                end

                local themed = materialByRole and materialFromName(materialByRole[role]) or nil
                if themed then
                    instance.Material = themed
                else
                    local restore = materialFromName(original)
                    if restore then instance.Material = restore end
                end
            end
        elseif instance:IsA("PointLight") then
            local originalBrightness = instance:GetAttribute(LIGHT_ATTR)
            if originalBrightness == nil then
                originalBrightness = instance.Brightness
                instance:SetAttribute(LIGHT_ATTR, originalBrightness)
            end
            instance.Brightness = originalBrightness * lightMultiplier
        end
    end
end

local function makeDecorModel(station, kind)
    local model = Instance.new("Model")
    model.Name = DECOR_NAME
    model:SetAttribute("ThemeKind", kind)
    model.Parent = station
    return model
end

local function buildArmy(station, palette, origin)
    local decor = makeDecorModel(station, "ARMY")
    local x, z = origin.X, origin.Z
    local wallZ = z - 13.38
    local floorY = 0.245

    local camo = {
        Color3.fromRGB(65, 74, 47),
        Color3.fromRGB(91, 88, 58),
        Color3.fromRGB(49, 55, 38),
        Color3.fromRGB(116, 104, 65),
    }

    local wallPatches = {
        {-8.6, 3.6, 4.6, 1.5, -8}, {-4.0, 5.4, 3.5, 1.3, 11}, {0.3, 3.1, 5.0, 1.5, -4},
        {5.0, 5.1, 4.0, 1.2, 8}, {8.2, 2.4, 3.0, 1.1, -13}, {-6.2, 6.8, 2.8, 0.7, 5},
    }
    for index, data in ipairs(wallPatches) do
        decorPart(
            decor,
            "CamoWall" .. index,
            Vector3.new(data[3], data[4], 0.08),
            CFrame.new(x + data[1], data[2], wallZ) * CFrame.Angles(0, 0, math.rad(data[5])),
            camo[((index - 1) % #camo) + 1],
            Enum.Material.Fabric
        )
    end

    local floorPatches = {
        {-7.8, -1.0, 5.0, 3.0, 13}, {-2.4, 3.8, 4.2, 2.4, -18}, {3.5, -4.0, 5.2, 2.8, 8},
        {7.4, 4.5, 4.4, 2.2, -9}, {0.0, 9.7, 5.5, 1.8, 16},
    }
    for index, data in ipairs(floorPatches) do
        decorPart(
            decor,
            "CamoFloor" .. index,
            Vector3.new(data[3], 0.045, data[4]),
            CFrame.new(x + data[1], floorY, z + data[2]) * CFrame.Angles(0, math.rad(data[5]), 0),
            camo[((index + 1) % #camo) + 1],
            Enum.Material.Fabric,
            0.08
        )
    end

    textPanel(
        decor,
        "FieldOpsStencil",
        Vector3.new(8.4, 1.35, 0.09),
        CFrame.new(x + 1.2, 6.55, wallZ + 0.03),
        Color3.fromRGB(39, 44, 31),
        "FIELD OPS // NIGHT SHIFT",
        palette.accent or Color3.fromRGB(177, 151, 76),
        Enum.Font.RobotoMono
    )

    for index = 1, 5 do
        decorPart(
            decor,
            "HazardChevron" .. index,
            Vector3.new(1.35, 0.22, 0.06),
            CFrame.new(x - 9.3 + ((index - 1) * 1.25), 1.05, wallZ + 0.04) * CFrame.Angles(0, 0, math.rad(index % 2 == 0 and -35 or 35)),
            palette.accent or Color3.fromRGB(177, 151, 76),
            Enum.Material.Neon
        )
    end

    for index, dx in ipairs({-9.3, 9.2}) do
        local crate = Instance.new("Model")
        crate.Name = "FieldCrate" .. index
        crate.Parent = decor
        decorPart(crate, "Body", Vector3.new(2.2, 1.45, 1.8), CFrame.new(x + dx, 0.78, z - 10.2), Color3.fromRGB(72, 70, 48), Enum.Material.WoodPlanks)
        decorPart(crate, "BandA", Vector3.new(2.3, 0.12, 1.9), CFrame.new(x + dx, 1.05, z - 10.2), Color3.fromRGB(39, 44, 31), Enum.Material.Metal)
        decorPart(crate, "BandB", Vector3.new(0.12, 1.5, 1.9), CFrame.new(x + dx, 0.78, z - 10.2), Color3.fromRGB(39, 44, 31), Enum.Material.Metal)
    end
end

local function buildSakura(station, palette, origin)
    local decor = makeDecorModel(station, "SAKURA")
    local x, z = origin.X, origin.Z
    local wallZ = z - 13.37
    local floorY = 0.245
    local branch = Color3.fromRGB(78, 49, 47)
    local pinkA = palette.accent or Color3.fromRGB(238, 139, 174)
    local pinkB = Color3.fromRGB(255, 185, 207)

    local branches = {
        {-8.0, 2.3, 5.6, 0.18, 28}, {-5.7, 4.3, 4.2, 0.16, -16}, {-3.4, 5.5, 3.5, 0.15, 25},
        {3.8, 2.7, 5.2, 0.18, -29}, {6.0, 4.5, 4.0, 0.16, 18}, {7.7, 5.8, 2.8, 0.14, -24},
    }
    for index, data in ipairs(branches) do
        decorPart(
            decor,
            "Branch" .. index,
            Vector3.new(data[3], data[4], 0.10),
            CFrame.new(x + data[1], data[2], wallZ) * CFrame.Angles(0, 0, math.rad(data[5])),
            branch,
            Enum.Material.Wood
        )
    end

    local petals = {
        {-8.4, 4.3, 18}, {-7.1, 5.0, -12}, {-6.0, 3.8, 35}, {-4.9, 5.8, 8}, {-3.4, 6.2, -28},
        {3.9, 4.2, -17}, {5.2, 5.2, 24}, {6.8, 3.9, -34}, {7.4, 6.0, 11}, {8.7, 5.0, 31},
        {-1.2, 2.5, 14}, {1.0, 6.5, -15},
    }
    for index, data in ipairs(petals) do
        decorPart(
            decor,
            "WallPetal" .. index,
            Vector3.new(0.48, 0.22, 0.07),
            CFrame.new(x + data[1], data[2], wallZ + 0.03) * CFrame.Angles(0, 0, math.rad(data[3])),
            index % 2 == 0 and pinkB or pinkA,
            Enum.Material.Neon,
            0.05
        )
    end

    local floorPetals = {
        {-8.0, 3.0, 18}, {-5.7, 8.5, -31}, {-2.0, 5.1, 10}, {1.3, 10.2, 39},
        {4.0, 2.5, -14}, {6.8, 8.7, 25}, {8.4, -1.0, -35}, {0.4, -6.2, 16},
    }
    for index, data in ipairs(floorPetals) do
        decorPart(
            decor,
            "FloorPetal" .. index,
            Vector3.new(0.62, 0.035, 0.26),
            CFrame.new(x + data[1], floorY, z + data[2]) * CFrame.Angles(0, math.rad(data[3]), 0),
            index % 2 == 0 and pinkB or pinkA,
            Enum.Material.Neon,
            0.08
        )
    end

    -- Lightweight torii-inspired wall frame to make the theme read from across the bay.
    decorPart(decor, "ToriiLeft", Vector3.new(0.22, 3.0, 0.10), CFrame.new(x - 1.9, 4.1, wallZ), branch, Enum.Material.Wood)
    decorPart(decor, "ToriiRight", Vector3.new(0.22, 3.0, 0.10), CFrame.new(x + 1.9, 4.1, wallZ), branch, Enum.Material.Wood)
    decorPart(decor, "ToriiTop", Vector3.new(5.0, 0.25, 0.10), CFrame.new(x, 5.5, wallZ), pinkA, Enum.Material.Neon)
    textPanel(decor, "SakuraSign", Vector3.new(3.7, 1.0, 0.09), CFrame.new(x, 4.35, wallZ + 0.03), Color3.fromRGB(35, 27, 35), "SAKURA NIGHT", pinkB, Enum.Font.GothamMedium)
end

local function buildStreet(station, palette, origin)
    local decor = makeDecorModel(station, "STREET")
    local x, z = origin.X, origin.Z
    local wallZ = z - 13.37
    local floorY = 0.245
    local cyan = palette.accent or Color3.fromRGB(64, 215, 190)
    local purple = Color3.fromRGB(156, 91, 210)
    local magenta = Color3.fromRGB(224, 74, 149)
    local chalk = Color3.fromRGB(220, 219, 211)

    local strokes = {
        {-8.2, 2.0, 5.2, 0.30, 16, cyan}, {-5.2, 5.7, 4.4, 0.23, -26, purple},
        {0.5, 2.4, 6.0, 0.28, -10, magenta}, {5.3, 5.2, 4.9, 0.25, 24, cyan},
        {8.2, 2.7, 3.3, 0.22, -32, purple},
    }
    for index, data in ipairs(strokes) do
        decorPart(
            decor,
            "WallStroke" .. index,
            Vector3.new(data[3], data[4], 0.07),
            CFrame.new(x + data[1], data[2], wallZ) * CFrame.Angles(0, 0, math.rad(data[5])),
            data[6],
            Enum.Material.Neon,
            0.08
        )
    end

    local words = {
        {-7.3, 5.0, 4.3, 1.45, "LOST", cyan, -7},
        {-2.2, 3.4, 4.5, 1.45, "FOUND", magenta, 6},
        {4.0, 5.3, 5.0, 1.40, "NIGHT", purple, -5},
        {7.3, 2.7, 3.8, 1.25, "SHIFT", cyan, 8},
    }
    for index, data in ipairs(words) do
        textPanel(
            decor,
            "GraffitiWord" .. index,
            Vector3.new(data[3], data[4], 0.08),
            CFrame.new(x + data[1], data[2], wallZ + 0.035) * CFrame.Angles(0, 0, math.rad(data[7])),
            Color3.fromRGB(31, 32, 35),
            data[5],
            data[6],
            Enum.Font.Arcade
        )
    end

    for index = 1, 4 do
        local dz = -8 + ((index - 1) * 5.1)
        decorPart(
            decor,
            "FloorLane" .. index,
            Vector3.new(0.18, 0.035, 3.8),
            CFrame.new(x - 9.6 + ((index % 2) * 19.0), floorY, z + dz) * CFrame.Angles(0, math.rad(index % 2 == 0 and 12 or -12), 0),
            index % 2 == 0 and magenta or cyan,
            Enum.Material.Neon,
            0.06
        )
    end

    textPanel(
        decor,
        "UrbanStencil",
        Vector3.new(6.0, 0.72, 0.08),
        CFrame.new(x, 7.05, wallZ + 0.04),
        Color3.fromRGB(31, 32, 35),
        "PROPERTY CREW // 24H",
        chalk,
        Enum.Font.RobotoMono
    )

    -- Non-colliding urban barrier blocks along the back edge.
    for index, dx in ipairs({-9.2, 9.2}) do
        decorPart(decor, "Barrier" .. index, Vector3.new(2.4, 0.9, 0.65), CFrame.new(x + dx, 0.55, z - 10.6), Color3.fromRGB(78, 79, 83), Enum.Material.Concrete)
        decorPart(decor, "BarrierStripe" .. index, Vector3.new(2.0, 0.14, 0.69), CFrame.new(x + dx, 0.65, z - 10.6), index == 1 and cyan or magenta, Enum.Material.Neon)
    end
end

local function applyStation(station)
    if not station or not station:IsA("Model") then return end
    if string.sub(station.Name, 1, 8) ~= "Station_" then return end

    clearDecor(station)

    local skin = StationSkinRegistry.Get(station:GetAttribute("SkinId"))
    local theme = skin.theme or { kind = "PALETTE" }
    applyMaterials(station, theme)

    local bay = station:FindFirstChild("BayFloor")
    if not bay or not bay:IsA("BasePart") then return end
    local origin = bay.Position
    local kind = theme.kind or "PALETTE"

    if kind == "ARMY" then
        buildArmy(station, skin.palette or {}, origin)
    elseif kind == "SAKURA" then
        buildSakura(station, skin.palette or {}, origin)
    elseif kind == "STREET" then
        buildStreet(station, skin.palette or {}, origin)
    end
end

local function bindStation(station)
    if not station:IsA("Model") or string.sub(station.Name, 1, 8) ~= "Station_" then return end
    station:GetAttributeChangedSignal("SkinId"):Connect(function()
        task.defer(applyStation, station)
    end)
    task.defer(applyStation, station)
end

local function bindWorld(world)
    if not world or world.Name ~= "LostAndFoundM4D" then return end
    for _, child in ipairs(world:GetChildren()) do
        bindStation(child)
    end
    world.ChildAdded:Connect(function(child)
        task.defer(bindStation, child)
    end)
end

local current = workspace:FindFirstChild("LostAndFoundM4D")
if current then task.defer(bindWorld, current) end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then
        task.defer(bindWorld, child)
    end
end)
