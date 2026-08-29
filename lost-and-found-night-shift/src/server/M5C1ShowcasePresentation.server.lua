-- LOST & FOUND: NIGHT SHIFT — M5-C.1 Showcase Presentation Pass
-- Presentation-only overlay for the five-slot personal collection rack.
-- Normalizes collectible scale/pose, improves the Cream Memory Bear silhouette,
-- adds restrained rarity hierarchy and clearer physical nameplates.
-- No generated images, decals, external textures/assets, economy or gameplay changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local SLOT_COUNT = 5
local VERSION = "M5C1_SHOWCASE_PRESENTATION_V1"

local RARITY_STYLE = {
    COMMON = {color = Color3.fromRGB(177, 187, 201), rank = 1, light = 0.00},
    UNCOMMON = {color = Color3.fromRGB(104, 190, 127), rank = 2, light = 0.00},
    RARE = {color = Color3.fromRGB(95, 167, 232), rank = 3, light = 0.00},
    EPIC = {color = Color3.fromRGB(177, 115, 226), rank = 4, light = 0.42},
    ANOMALY = {color = Color3.fromRGB(88, 221, 224), rank = 5, light = 0.55},
    SECRET = {color = Color3.fromRGB(235, 223, 179), rank = 6, light = 0.65},
}

local PROFILES = {
    hardcase_suitcase = {h=2.48, w=2.58, d=1.48, yaw=180, pitch=0, z=0.00},
    vintage_suitcase = {h=2.42, w=2.55, d=1.46, yaw=180, pitch=0, z=0.00},
    backpack = {h=2.58, w=2.25, d=1.44, yaw=180, pitch=0, z=0.00},
    cardboard_box = {h=2.25, w=2.50, d=1.50, yaw=180, pitch=0, z=0.00},
    teddy_bear = {h=2.66, w=2.32, d=1.48, yaw=180, pitch=0, z=0.00},
    camera_lens = {h=2.02, w=2.12, d=1.42, yaw=168, pitch=-5, z=0.00},
    evidence_tag = {h=2.22, w=2.48, d=0.72, yaw=180, pitch=-3, z=-0.03},
    passport = {h=2.62, w=2.10, d=0.82, yaw=180, pitch=-4, z=-0.03},
    toy_train = {h=2.10, w=2.62, d=1.42, yaw=164, pitch=0, z=0.00},
    power_adapter = {h=2.05, w=2.30, d=1.32, yaw=172, pitch=-3, z=0.00},
    formal_shoe = {h=1.75, w=2.62, d=1.30, yaw=158, pitch=-2, z=0.00},
    name_patch = {h=2.05, w=2.50, d=0.70, yaw=180, pitch=-4, z=-0.03},
    paperback = {h=2.62, w=2.05, d=0.82, yaw=180, pitch=-4, z=-0.03},
    mass_readout = {h=2.15, w=2.58, d=1.18, yaw=180, pitch=-3, z=0.00},
}

local DEFAULT_PROFILE = {h=2.35, w=2.45, d=1.40, yaw=180, pitch=0, z=0.00}

local FALLBACK = {
    panel = Color3.fromRGB(23, 29, 38),
    trim = Color3.fromRGB(75, 85, 99),
    accent = Color3.fromRGB(224, 163, 64),
    base = Color3.fromRGB(38, 45, 56),
}

local boundFolders = setmetatable({}, {__mode = "k"})

local function paletteFor(station)
    local skin = StationSkinRegistry.Get(station:GetAttribute("SkinId"))
    return skin and skin.palette or {}
end

local function roleColor(station, role)
    return paletteFor(station)[role] or FALLBACK[role] or Color3.fromRGB(80, 88, 100)
end

local function parseSlot(model)
    if not model or not model:IsA("Model") then return nil end
    return tonumber(string.match(model.Name, "M5B_Slot_(%d+)"))
        or tonumber(string.match(model.Name, "M5B2_Slot_(%d+)"))
        or tonumber(string.match(model.Name, "Display_(%d+)"))
end

local function removeFloatingLabels(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BillboardGui") and (descendant.Name == "M5BShowcaseLabel" or descendant.Name == "SerialLabel") then
            descendant:Destroy()
        end
    end
end

local function setPart(model, root, name, size, offset, angles)
    local part = model:FindFirstChild(name, true)
    if not part or not part:IsA("BasePart") then return end
    part.Size = size
    local rotation = angles or Vector3.zero
    part.CFrame = root.CFrame
        * CFrame.new(offset)
        * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
end

local function refineMemoryBear(model)
    if model:GetAttribute("M5C1BearRefined") == true then return end
    local collectionId = tostring(model:GetAttribute("CollectionId") or "")
    if collectionId ~= "cream_memory_bear" then return end

    pcall(function() model:ScaleTo(1) end)
    local root = model.PrimaryPart or model:FindFirstChild("Body")
    if not root or not root:IsA("BasePart") then return end

    -- Bring the head and limbs into one coherent plush silhouette instead of a stacked/totem read.
    root.Size = Vector3.new(3.18, 3.30, 2.90)
    setPart(model, root, "Head", Vector3.new(3.15, 3.05, 2.82), Vector3.new(0, 2.23, -0.16))
    setPart(model, root, "EarL", Vector3.new(1.06, 1.06, 0.72), Vector3.new(-1.18, 3.13, -0.03))
    setPart(model, root, "EarR", Vector3.new(1.06, 1.06, 0.72), Vector3.new(1.18, 3.13, -0.03))
    setPart(model, root, "InnerEarL", Vector3.new(0.55, 0.55, 0.18), Vector3.new(-1.18, 3.13, -0.43))
    setPart(model, root, "InnerEarR", Vector3.new(0.55, 0.55, 0.18), Vector3.new(1.18, 3.13, -0.43))
    setPart(model, root, "Muzzle", Vector3.new(1.42, 1.02, 0.72), Vector3.new(0, 1.90, -1.46))
    setPart(model, root, "Nose", Vector3.new(0.42, 0.32, 0.22), Vector3.new(0, 2.13, -1.86))
    setPart(model, root, "EyeL", Vector3.new(0.26, 0.26, 0.18), Vector3.new(-0.57, 2.48, -1.44))
    setPart(model, root, "EyeR", Vector3.new(0.26, 0.26, 0.18), Vector3.new(0.57, 2.48, -1.44))
    setPart(model, root, "Mouth", Vector3.new(0.62, 0.08, 0.08), Vector3.new(0, 1.58, -1.49))
    setPart(model, root, "ArmL", Vector3.new(1.12, 2.48, 1.12), Vector3.new(-1.60, 0.28, 0.02), Vector3.new(0, 0, -20))
    setPart(model, root, "ArmR", Vector3.new(1.12, 2.48, 1.12), Vector3.new(1.60, 0.28, 0.02), Vector3.new(0, 0, 20))
    setPart(model, root, "LegL", Vector3.new(1.42, 1.95, 1.50), Vector3.new(-0.78, -1.74, 0.22), Vector3.new(0, 0, -5))
    setPart(model, root, "LegR", Vector3.new(1.42, 1.95, 1.50), Vector3.new(0.78, -1.74, 0.22), Vector3.new(0, 0, 5))
    setPart(model, root, "BellySeam", Vector3.new(0.10, 1.72, 0.10), Vector3.new(0, -0.08, -1.46))
    setPart(model, root, "Ribbon", Vector3.new(1.88, 0.25, 0.28), Vector3.new(0, 1.20, -1.10))
    setPart(model, root, "BowL", Vector3.new(0.82, 0.62, 0.28), Vector3.new(-0.58, 1.08, -1.19), Vector3.new(0, 0, 24))
    setPart(model, root, "BowR", Vector3.new(0.82, 0.62, 0.28), Vector3.new(0.58, 1.08, -1.19), Vector3.new(0, 0, -24))

    model:SetAttribute("M5C1BearRefined", true)
end

local function normalizeModel(model, anchor, plinth)
    if not model or not anchor or not plinth then return end
    removeFloatingLabels(model)
    refineMemoryBear(model)

    pcall(function() model:ScaleTo(1) end)
    local family = tostring(model:GetAttribute("M5CBaseFamily") or "")
    if family == "" then
        local collectionId = tostring(model:GetAttribute("CollectionId") or "")
        local entry = CollectionRegistry.Get(collectionId)
        family = entry and tostring(entry.baseItemId or "") or ""
    end
    local profile = PROFILES[family] or DEFAULT_PROFILE

    local ok, _, size = pcall(function()
        local cf, extents = model:GetBoundingBox()
        return cf, extents
    end)
    if not ok or not size or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then return end

    local scale = math.min(profile.w / size.X, profile.h / size.Y, profile.d / size.Z)
    scale = math.clamp(scale, 0.16, 0.72)
    pcall(function() model:ScaleTo(scale) end)

    local base = anchor.CFrame
        * CFrame.new(0, 0, profile.z or 0)
        * CFrame.Angles(math.rad(profile.pitch or 0), math.rad(profile.yaw or 180), math.rad(profile.roll or 0))
    model:PivotTo(base)

    local boxCf, boxSize = model:GetBoundingBox()
    local targetBottom = plinth.Position.Y + plinth.Size.Y * 0.5 + 0.055
    local currentBottom = boxCf.Position.Y - boxSize.Y * 0.5
    local deltaY = targetBottom - currentBottom
    model:PivotTo(model:GetPivot() + Vector3.new(0, deltaY, 0))
    model:SetAttribute("M5C1Presentation", VERSION)
end

local function stylePhysicalPart(part, color, material)
    if not part or not part:IsA("BasePart") then return end
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
end

local function ensureRarityBar(station, showcase, slot, plinth, style)
    local name = "M5C1_RarityBar" .. slot
    local bar = showcase:FindFirstChild(name)
    if not bar or not bar:IsA("BasePart") then
        if bar then bar:Destroy() end
        bar = Instance.new("Part")
        bar.Name = name
        bar.Size = Vector3.new(2.34, 0.09, 0.11)
        bar.Parent = showcase
    end
    bar.CFrame = plinth.CFrame * CFrame.new(0, -plinth.Size.Y * 0.5 - 0.055, -plinth.Size.Z * 0.5 - 0.035)
    stylePhysicalPart(bar, style.color, Enum.Material.Neon)

    local light = bar:FindFirstChild("M5C1Light")
    if style.light > 0 then
        if not light or not light:IsA("PointLight") then
            if light then light:Destroy() end
            light = Instance.new("PointLight")
            light.Name = "M5C1Light"
            light.Parent = bar
        end
        light.Color = style.color
        light.Brightness = style.light
        light.Range = 4.5
        light.Shadows = false
    elseif light then
        light:Destroy()
    end
    return bar
end

local function clearRarityBar(showcase, slot)
    local bar = showcase:FindFirstChild("M5C1_RarityBar" .. slot)
    if bar then bar:Destroy() end
end

local function ensureNameplate(station, showcase, slot, oldPlate, model, style)
    local name = "M5C1_Nameplate" .. slot
    local plate = showcase:FindFirstChild(name)
    if not plate or not plate:IsA("BasePart") then
        if plate then plate:Destroy() end
        plate = Instance.new("Part")
        plate.Name = name
        plate.Parent = showcase
    end
    plate.Size = Vector3.new(3.08, 0.90, 0.075)
    plate.CFrame = oldPlate.CFrame * CFrame.new(0, 0, -0.12)
    stylePhysicalPart(plate, roleColor(station, "base"):Lerp(Color3.fromRGB(10, 13, 18), 0.32), Enum.Material.SmoothPlastic)

    for _, child in ipairs(plate:GetChildren()) do
        if child:IsA("SurfaceGui") then child:Destroy() end
    end

    local collectionId = tostring(model:GetAttribute("CollectionId") or "")
    local entry = CollectionRegistry.Get(collectionId)
    local itemName = entry and tostring(entry.name) or collectionId
    local rarity = tostring(model:GetAttribute("Rarity") or model:GetAttribute("M5CRarity") or (entry and entry.rarity) or "COMMON")
    local serial = tostring(model:GetAttribute("Serial") or "")

    local gui = Instance.new("SurfaceGui")
    gui.Name = "M5C1Surface"
    gui.Face = Enum.NormalId.Front
    gui.LightInfluence = 0
    gui.PixelsPerStud = 100
    gui.Parent = plate

    local top = Instance.new("TextLabel")
    top.Size = UDim2.new(1, -10, 0.55, 0)
    top.Position = UDim2.fromOffset(5, 2)
    top.BackgroundTransparency = 1
    top.Text = string.upper(itemName)
    top.TextColor3 = Color3.fromRGB(242, 245, 249)
    top.Font = Enum.Font.GothamBold
    top.TextScaled = true
    top.TextWrapped = true
    top.TextXAlignment = Enum.TextXAlignment.Center
    top.TextYAlignment = Enum.TextYAlignment.Center
    top.Parent = gui
    local topLimit = Instance.new("UITextSizeConstraint")
    topLimit.MinTextSize = 8
    topLimit.MaxTextSize = 12
    topLimit.Parent = top

    local bottom = Instance.new("TextLabel")
    bottom.Size = UDim2.new(1, -10, 0.36, 0)
    bottom.Position = UDim2.new(0, 5, 0.61, 0)
    bottom.BackgroundTransparency = 1
    bottom.Text = rarity .. (serial ~= "" and ("  •  " .. serial) or "")
    bottom.TextColor3 = style.color
    bottom.Font = Enum.Font.RobotoMono
    bottom.TextScaled = true
    bottom.TextWrapped = false
    bottom.TextXAlignment = Enum.TextXAlignment.Center
    bottom.TextYAlignment = Enum.TextYAlignment.Center
    bottom.Parent = gui
    local bottomLimit = Instance.new("UITextSizeConstraint")
    bottomLimit.MinTextSize = 8
    bottomLimit.MaxTextSize = 11
    bottomLimit.Parent = bottom

    return plate
end

local function clearNameplate(showcase, slot)
    local plate = showcase:FindFirstChild("M5C1_Nameplate" .. slot)
    if plate then plate:Destroy() end
end

local function styleSlot(station, showcase, slot, model)
    local glow = showcase:FindFirstChild("M5B2_SlotGlow" .. slot)
    local plinth = showcase:FindFirstChild("M5B2_Plinth" .. slot)
    local oldPlate = showcase:FindFirstChild("M5B2_InfoPlate" .. slot)
    local anchor = showcase:FindFirstChild("DisplayAnchor" .. slot)
    if not plinth or not oldPlate or not anchor then return end

    if not model then
        if glow and glow:IsA("BasePart") then
            glow.Color = roleColor(station, "accent")
            glow.Material = Enum.Material.Neon
        end
        plinth.Color = roleColor(station, "base")
        clearRarityBar(showcase, slot)
        clearNameplate(showcase, slot)
        return
    end

    local rarity = tostring(model:GetAttribute("Rarity") or model:GetAttribute("M5CRarity") or "COMMON")
    local style = RARITY_STYLE[rarity] or RARITY_STYLE.COMMON
    normalizeModel(model, anchor, plinth)

    if glow and glow:IsA("BasePart") then
        glow.Color = style.color
        glow.Material = Enum.Material.Neon
    end

    local blend = ({0.02, 0.05, 0.09, 0.13, 0.16, 0.18})[style.rank] or 0.04
    plinth.Color = roleColor(station, "base"):Lerp(style.color, blend)
    plinth.Material = style.rank >= 5 and Enum.Material.Metal or Enum.Material.SmoothPlastic

    ensureRarityBar(station, showcase, slot, plinth, style)
    ensureNameplate(station, showcase, slot, oldPlate, model, style)
end

local function reconcileStation(station)
    if not station or not station:IsA("Model") then return end
    if string.sub(station.Name, 1, 8) ~= "Station_" then return end
    local showcase = station:FindFirstChild("PublicShowcase")
    if not showcase or not showcase:IsA("Model") then return end

    local folder = showcase:FindFirstChild("DisplayedItems")
    local modelsBySlot = {}
    if folder and folder:IsA("Folder") then
        for _, child in ipairs(folder:GetChildren()) do
            local slot = parseSlot(child)
            if slot and slot >= 1 and slot <= SLOT_COUNT then
                modelsBySlot[slot] = child
            end
        end
        if not boundFolders[folder] then
            boundFolders[folder] = true
            folder.ChildAdded:Connect(function()
                task.delay(0.08, function()
                    if station.Parent then reconcileStation(station) end
                end)
            end)
            folder.ChildRemoved:Connect(function()
                task.delay(0.08, function()
                    if station.Parent then reconcileStation(station) end
                end)
            end)
        end
    end

    for slot = 1, SLOT_COUNT do
        styleSlot(station, showcase, slot, modelsBySlot[slot])
    end
    station:SetAttribute("ShowcasePresentationVersion", VERSION)
end

local function reconcileWorld()
    local world = workspace:FindFirstChild("LostAndFoundM4D")
    if not world then return end
    for _, station in ipairs(world:GetChildren()) do
        reconcileStation(station)
    end
end

local function bindWorld(world)
    if not world or world.Name ~= "LostAndFoundM4D" then return end
    world.ChildAdded:Connect(function(station)
        task.delay(0.35, function() reconcileStation(station) end)
    end)
    task.delay(0.45, reconcileWorld)
    task.delay(1.25, reconcileWorld)
end

local world = workspace:FindFirstChild("LostAndFoundM4D")
if world then bindWorld(world) end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then bindWorld(child) end
end)

-- Presentation self-heal intentionally runs after the older M5-B / M5-B.2 periodic refresh.
task.spawn(function()
    while true do
        task.wait(2.5)
        reconcileWorld()
    end
end)
