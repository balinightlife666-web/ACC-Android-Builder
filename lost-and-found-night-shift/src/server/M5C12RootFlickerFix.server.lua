-- LOST & FOUND: NIGHT SHIFT — M5-C.1.2 Root Flicker Fix
-- Single visual authority for five-slot showcase presentation.
-- Retires M5-C.1/M5-C.1.1 visual loops, never resets live models to ScaleTo(1),
-- and applies only one final fitted scale write when a real legacy write/model rebuild occurs.
-- Roblox in-engine only. No generated images, decals, external textures or external assets.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local VERSION = "M5C12_SINGLE_PRESENTATION_AUTHORITY_V1"
local SLOT_COUNT = 5

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

local correcting = setmetatable({}, {__mode = "k"})
local queued = setmetatable({}, {__mode = "k"})
local boundModels = setmetatable({}, {__mode = "k"})
local boundFolders = setmetatable({}, {__mode = "k"})
local boundShowcases = setmetatable({}, {__mode = "k"})
local boundStations = setmetatable({}, {__mode = "k"})

local function retireLegacyAuthority(name)
    local target = ServerScriptService:FindFirstChild(name, true)
    if target and target:IsA("Script") and target ~= script then
        target.Disabled = true
        target:SetAttribute("RetiredBy", VERSION)
    end
end

-- These two scripts both performed visible intermediate scale writes on v53/v54.
retireLegacyAuthority("M5C1ShowcasePresentation")
retireLegacyAuthority("M5C11ShowcasePresentationAuthority")

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

local function currentScale(model)
    local ok, value = pcall(function() return model:GetScale() end)
    if ok and type(value) == "number" and value > 0 then return value end
    return 1
end

local function removeFloatingLabels(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BillboardGui") and (descendant.Name == "M5BShowcaseLabel" or descendant.Name == "SerialLabel") then
            descendant:Destroy()
        end
    end
end

local function setPartScaled(model, root, name, size, offset, modelScale, angles)
    local part = model:FindFirstChild(name, true)
    if not part or not part:IsA("BasePart") then return end
    part.Size = size * modelScale
    local a = angles or Vector3.zero
    part.CFrame = root.CFrame
        * CFrame.new(offset * modelScale)
        * CFrame.Angles(math.rad(a.X), math.rad(a.Y), math.rad(a.Z))
end

local function refineMemoryBear(model)
    if model:GetAttribute("M5C12BearRefined") == true then return end
    if tostring(model:GetAttribute("CollectionId") or "") ~= "cream_memory_bear" then return end

    local root = model.PrimaryPart or model:FindFirstChild("Body")
    if not root or not root:IsA("BasePart") then return end
    local scale = currentScale(model)

    -- Apply the intended unscaled proportions at the model's CURRENT scale.
    -- No ScaleTo(1) intermediate state is ever created.
    root.Size = Vector3.new(3.18, 3.30, 2.90) * scale
    setPartScaled(model, root, "Head", Vector3.new(3.15, 3.05, 2.82), Vector3.new(0, 2.23, -0.16), scale)
    setPartScaled(model, root, "EarL", Vector3.new(1.06, 1.06, 0.72), Vector3.new(-1.18, 3.13, -0.03), scale)
    setPartScaled(model, root, "EarR", Vector3.new(1.06, 1.06, 0.72), Vector3.new(1.18, 3.13, -0.03), scale)
    setPartScaled(model, root, "InnerEarL", Vector3.new(0.55, 0.55, 0.18), Vector3.new(-1.18, 3.13, -0.43), scale)
    setPartScaled(model, root, "InnerEarR", Vector3.new(0.55, 0.55, 0.18), Vector3.new(1.18, 3.13, -0.43), scale)
    setPartScaled(model, root, "Muzzle", Vector3.new(1.42, 1.02, 0.72), Vector3.new(0, 1.90, -1.46), scale)
    setPartScaled(model, root, "Nose", Vector3.new(0.42, 0.32, 0.22), Vector3.new(0, 2.13, -1.86), scale)
    setPartScaled(model, root, "EyeL", Vector3.new(0.26, 0.26, 0.18), Vector3.new(-0.57, 2.48, -1.44), scale)
    setPartScaled(model, root, "EyeR", Vector3.new(0.26, 0.26, 0.18), Vector3.new(0.57, 2.48, -1.44), scale)
    setPartScaled(model, root, "Mouth", Vector3.new(0.62, 0.08, 0.08), Vector3.new(0, 1.58, -1.49), scale)
    setPartScaled(model, root, "ArmL", Vector3.new(1.12, 2.48, 1.12), Vector3.new(-1.60, 0.28, 0.02), scale, Vector3.new(0, 0, -20))
    setPartScaled(model, root, "ArmR", Vector3.new(1.12, 2.48, 1.12), Vector3.new(1.60, 0.28, 0.02), scale, Vector3.new(0, 0, 20))
    setPartScaled(model, root, "LegL", Vector3.new(1.42, 1.95, 1.50), Vector3.new(-0.78, -1.74, 0.22), scale, Vector3.new(0, 0, -5))
    setPartScaled(model, root, "LegR", Vector3.new(1.42, 1.95, 1.50), Vector3.new(0.78, -1.74, 0.22), scale, Vector3.new(0, 0, 5))
    setPartScaled(model, root, "BellySeam", Vector3.new(0.10, 1.72, 0.10), Vector3.new(0, -0.08, -1.46), scale)
    setPartScaled(model, root, "Ribbon", Vector3.new(1.88, 0.25, 0.28), Vector3.new(0, 1.20, -1.10), scale)
    setPartScaled(model, root, "BowL", Vector3.new(0.82, 0.62, 0.28), Vector3.new(-0.58, 1.08, -1.19), scale, Vector3.new(0, 0, 24))
    setPartScaled(model, root, "BowR", Vector3.new(0.82, 0.62, 0.28), Vector3.new(0.58, 1.08, -1.19), scale, Vector3.new(0, 0, -24))
    model:SetAttribute("M5C12BearRefined", true)
end

local function familyFor(model)
    local family = tostring(model:GetAttribute("M5CBaseFamily") or "")
    if family ~= "" then return family end
    local collectionId = tostring(model:GetAttribute("CollectionId") or "")
    local entry = CollectionRegistry.Get(collectionId)
    return entry and tostring(entry.baseItemId or "") or ""
end

local function fitModel(model, anchor, plinth)
    if correcting[model] or not model or not model.Parent then return end
    if not anchor or not anchor:IsA("BasePart") or not plinth or not plinth:IsA("BasePart") then return end

    correcting[model] = true
    local ok, err = pcall(function()
        removeFloatingLabels(model)
        refineMemoryBear(model)

        local profile = PROFILES[familyFor(model)] or DEFAULT_PROFILE
        local _, size = model:GetBoundingBox()
        if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then return end

        local nowScale = currentScale(model)
        local factor = math.min(profile.w / size.X, profile.h / size.Y, profile.d / size.Z)
        local targetScale = math.clamp(nowScale * factor, 0.02, 2.0)

        -- One final scale write only. Never reset to scale 1.
        if math.abs(targetScale - nowScale) > math.max(0.001, nowScale * 0.004) then
            model:ScaleTo(targetScale)
        end

        local base = anchor.CFrame
            * CFrame.new(0, 0, profile.z or 0)
            * CFrame.Angles(math.rad(profile.pitch or 0), math.rad(profile.yaw or 180), math.rad(profile.roll or 0))
        model:PivotTo(base)

        local boxCf, boxSize = model:GetBoundingBox()
        local targetBottom = plinth.Position.Y + plinth.Size.Y * 0.5 + 0.055
        local currentBottom = boxCf.Position.Y - boxSize.Y * 0.5
        local deltaY = targetBottom - currentBottom
        if math.abs(deltaY) > 0.002 then
            model:PivotTo(model:GetPivot() + Vector3.new(0, deltaY, 0))
        end

        model:SetAttribute("M5C1Presentation", "M5C1_SHOWCASE_PRESENTATION_V1")
        model:SetAttribute("M5C12PresentationAuthority", VERSION)
    end)
    correcting[model] = nil
    if not ok then warn("[LOST FOUND] M5-C.1.2 fit failed:", err) end
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

local function clearRarityBar(showcase, slot)
    local bar = showcase:FindFirstChild("M5C1_RarityBar" .. slot)
    if bar then bar:Destroy() end
end

local function ensureRarityBar(showcase, slot, plinth, style)
    local bar = showcase:FindFirstChild("M5C1_RarityBar" .. slot)
    if not bar or not bar:IsA("BasePart") then
        if bar then bar:Destroy() end
        bar = Instance.new("Part")
        bar.Name = "M5C1_RarityBar" .. slot
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
end

local function clearNameplate(showcase, slot)
    local plate = showcase:FindFirstChild("M5C1_Nameplate" .. slot)
    if plate then plate:Destroy() end
end

local function ensureNameplate(station, showcase, slot, oldPlate, model, style)
    local plate = showcase:FindFirstChild("M5C1_Nameplate" .. slot)
    if not plate or not plate:IsA("BasePart") then
        if plate then plate:Destroy() end
        plate = Instance.new("Part")
        plate.Name = "M5C1_Nameplate" .. slot
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
    gui.Name = "M5C12Surface"
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
        plinth.Material = Enum.Material.SmoothPlastic
        clearRarityBar(showcase, slot)
        clearNameplate(showcase, slot)
        return
    end

    local rarity = tostring(model:GetAttribute("Rarity") or model:GetAttribute("M5CRarity") or "COMMON")
    local style = RARITY_STYLE[rarity] or RARITY_STYLE.COMMON
    fitModel(model, anchor, plinth)

    if glow and glow:IsA("BasePart") then
        glow.Color = style.color
        glow.Material = Enum.Material.Neon
    end
    local blend = ({0.02, 0.05, 0.09, 0.13, 0.16, 0.18})[style.rank] or 0.04
    plinth.Color = roleColor(station, "base"):Lerp(style.color, blend)
    plinth.Material = style.rank >= 5 and Enum.Material.Metal or Enum.Material.SmoothPlastic
    ensureRarityBar(showcase, slot, plinth, style)
    ensureNameplate(station, showcase, slot, oldPlate, model, style)
end

local function modelsBySlot(showcase)
    local result = {}
    local folder = showcase:FindFirstChild("DisplayedItems")
    if not folder or not folder:IsA("Folder") then return result, nil end
    for _, child in ipairs(folder:GetChildren()) do
        local slot = parseSlot(child)
        if slot and slot >= 1 and slot <= SLOT_COUNT then result[slot] = child end
    end
    return result, folder
end

local function reconcileStation(station)
    if not station or not station:IsA("Model") or string.sub(station.Name, 1, 8) ~= "Station_" then return end
    local showcase = station:FindFirstChild("PublicShowcase")
    if not showcase or not showcase:IsA("Model") then return end
    local bySlot, folder = modelsBySlot(showcase)
    for slot = 1, SLOT_COUNT do styleSlot(station, showcase, slot, bySlot[slot]) end
    station:SetAttribute("ShowcasePresentationVersion", VERSION)
    if folder then
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") then
                -- binding happens below; this is intentionally only a one-time reconcile
            end
        end
    end
end

local function queueFit(model)
    if correcting[model] or queued[model] or not model or not model.Parent then return end
    queued[model] = true
    task.delay(0.035, function()
        queued[model] = nil
        if not model.Parent then return end
        local folder = model.Parent
        local showcase = folder and folder.Parent
        local station = showcase and showcase.Parent
        local slot = parseSlot(model)
        if not station or not showcase or not slot then return end
        styleSlot(station, showcase, slot, model)
    end)
end

local function bindModel(model)
    if not model or not model:IsA("Model") or boundModels[model] or not parseSlot(model) then return end
    boundModels[model] = true
    task.delay(0.04, function()
        if not model.Parent then return end
        queueFit(model)
        local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if not primary then return end
        primary:GetPropertyChangedSignal("Size"):Connect(function()
            if not correcting[model] then queueFit(model) end
        end)
        primary:GetPropertyChangedSignal("CFrame"):Connect(function()
            if not correcting[model] then queueFit(model) end
        end)
    end)
end

local function bindFolder(folder)
    if not folder or not folder:IsA("Folder") or folder.Name ~= "DisplayedItems" or boundFolders[folder] then return end
    boundFolders[folder] = true
    for _, child in ipairs(folder:GetChildren()) do bindModel(child) end
    folder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then bindModel(child) end
    end)
    folder.ChildRemoved:Connect(function()
        local showcase = folder.Parent
        local station = showcase and showcase.Parent
        if station then task.delay(0.04, reconcileStation, station) end
    end)
end

local function bindShowcase(showcase)
    if not showcase or not showcase:IsA("Model") or boundShowcases[showcase] then return end
    boundShowcases[showcase] = true
    local folder = showcase:FindFirstChild("DisplayedItems")
    if folder then bindFolder(folder) end
    showcase.ChildAdded:Connect(function(child)
        if child.Name == "DisplayedItems" and child:IsA("Folder") then
            bindFolder(child)
            local station = showcase.Parent
            if station then task.delay(0.05, reconcileStation, station) end
        end
    end)
end

local function bindStation(station)
    if not station or not station:IsA("Model") or string.sub(station.Name, 1, 8) ~= "Station_" then return end
    if not boundStations[station] then
        boundStations[station] = true
        station:GetAttributeChangedSignal("SkinId"):Connect(function()
            task.delay(0.05, function() if station.Parent then reconcileStation(station) end end)
        end)
        station.ChildAdded:Connect(function(child)
            if child.Name == "PublicShowcase" and child:IsA("Model") then bindShowcase(child) end
        end)
    end
    local showcase = station:FindFirstChild("PublicShowcase")
    if showcase then bindShowcase(showcase) end
end

local function bindWorld(world)
    if not world or world.Name ~= "LostAndFoundM4D" then return end
    for _, station in ipairs(world:GetChildren()) do bindStation(station) end
    world.ChildAdded:Connect(function(station) task.defer(bindStation, station) end)
end

local world = workspace:FindFirstChild("LostAndFoundM4D")
if world then bindWorld(world) end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then task.defer(bindWorld, child) end
end)

-- Initial presentation only. No destructive periodic reconciliation.
task.delay(0.70, function()
    local current = workspace:FindFirstChild("LostAndFoundM4D")
    if current then
        for _, station in ipairs(current:GetChildren()) do
            bindStation(station)
            reconcileStation(station)
            local showcase = station:FindFirstChild("PublicShowcase")
            local folder = showcase and showcase:FindFirstChild("DisplayedItems")
            if folder then bindFolder(folder) end
        end
    end
end)

-- Non-mutating safety scan: only binds newly recreated legacy folders/models.
task.spawn(function()
    while true do
        task.wait(10)
        local current = workspace:FindFirstChild("LostAndFoundM4D")
        if current then
            for _, station in ipairs(current:GetChildren()) do
                bindStation(station)
                local showcase = station:FindFirstChild("PublicShowcase")
                local folder = showcase and showcase:FindFirstChild("DisplayedItems")
                if folder then
                    bindFolder(folder)
                    for _, model in ipairs(folder:GetChildren()) do bindModel(model) end
                end
            end
        end
    end
end)
