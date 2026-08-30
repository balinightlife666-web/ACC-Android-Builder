-- LOST & FOUND: NIGHT SHIFT — M5-C.4 Rarity Display Language
-- Display-only rarity language. Does NOT recolor or mutate collectible geometry.
-- M5-C.1.3 remains the sole stable showcase lifecycle authority.
--
-- COMMON   = neutral gallery display, no emissive effect.
-- UNCOMMON = restrained silver/metal trim.
-- RARE     = cobalt/deep-blue rail.
-- EPIC     = violet rail + static under-plinth halo.
-- ANOMALY  = cold-white/icy-cyan rail + static cold halo.
-- SECRET   = black + gold presentation + restrained top light.
--
-- This script is event-driven only. No periodic loops, no ScaleTo/PivotTo, no model rebuilds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))

local VERSION = "M5C4_RARITY_DISPLAY_V1"
local SLOT_COUNT = 5
local STABLE_FOLDER = "M5C13StableItems"

local STYLES = {
    COMMON = {
        accent = Color3.fromRGB(184, 191, 201),
        secondary = Color3.fromRGB(184, 191, 201),
        plinth = Color3.fromRGB(42, 48, 57),
        plate = Color3.fromRGB(17, 21, 28),
        surfaceMaterial = Enum.Material.SmoothPlastic,
        railMaterial = Enum.Material.Metal,
        railTransparency = 0.20,
        trim = false,
        halo = false,
        light = 0,
    },
    UNCOMMON = {
        accent = Color3.fromRGB(173, 187, 201),
        secondary = Color3.fromRGB(203, 211, 219),
        plinth = Color3.fromRGB(39, 46, 55),
        plate = Color3.fromRGB(16, 20, 27),
        surfaceMaterial = Enum.Material.Metal,
        railMaterial = Enum.Material.Metal,
        railTransparency = 0.05,
        trim = true,
        halo = false,
        light = 0,
    },
    RARE = {
        accent = Color3.fromRGB(53, 98, 184),
        secondary = Color3.fromRGB(76, 126, 220),
        plinth = Color3.fromRGB(31, 39, 54),
        plate = Color3.fromRGB(14, 19, 29),
        surfaceMaterial = Enum.Material.SmoothPlastic,
        railMaterial = Enum.Material.Neon,
        railTransparency = 0.00,
        trim = true,
        halo = false,
        light = 0,
    },
    EPIC = {
        accent = Color3.fromRGB(130, 77, 190),
        secondary = Color3.fromRGB(158, 103, 220),
        plinth = Color3.fromRGB(37, 29, 51),
        plate = Color3.fromRGB(18, 13, 27),
        surfaceMaterial = Enum.Material.SmoothPlastic,
        railMaterial = Enum.Material.Neon,
        railTransparency = 0.00,
        trim = true,
        halo = true,
        haloTransparency = 0.34,
        light = 0,
    },
    ANOMALY = {
        accent = Color3.fromRGB(214, 239, 244),
        secondary = Color3.fromRGB(106, 200, 220),
        plinth = Color3.fromRGB(34, 43, 47),
        plate = Color3.fromRGB(12, 19, 22),
        surfaceMaterial = Enum.Material.Metal,
        railMaterial = Enum.Material.Neon,
        railTransparency = 0.00,
        trim = true,
        halo = true,
        haloTransparency = 0.24,
        light = 0,
    },
    SECRET = {
        accent = Color3.fromRGB(217, 174, 72),
        secondary = Color3.fromRGB(242, 211, 125),
        plinth = Color3.fromRGB(9, 10, 13),
        plate = Color3.fromRGB(7, 8, 11),
        surfaceMaterial = Enum.Material.Metal,
        railMaterial = Enum.Material.Neon,
        railTransparency = 0.00,
        trim = true,
        halo = true,
        haloTransparency = 0.22,
        light = 0.24,
    },
}

local boundShowcases = setmetatable({}, {__mode = "k"})
local boundFolders = setmetatable({}, {__mode = "k"})
local boundModels = setmetatable({}, {__mode = "k"})
local scheduled = setmetatable({}, {__mode = "k"})

local function makePart(parent, name, size, cframe, color, material, transparency)
    local part = parent:FindFirstChild(name)
    if not part or not part:IsA("BasePart") then
        if part then part:Destroy() end
        part = Instance.new("Part")
        part.Name = name
        part.Parent = parent
    end
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Transparency = transparency or 0
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    return part
end

local function destroyIfPresent(parent, name)
    local child = parent and parent:FindFirstChild(name)
    if child then child:Destroy() end
end

local function findStableModel(showcase, slot)
    local folder = showcase:FindFirstChild(STABLE_FOLDER)
    local model = folder and folder:FindFirstChild("M5C13_Slot_" .. tostring(slot))
    return model and model:IsA("Model") and model or nil
end

local function restoreLegacyEmpty(showcase, slot)
    local glow = showcase:FindFirstChild("M5B2_SlotGlow" .. slot)
    if glow and glow:IsA("BasePart") then glow.Transparency = 0 end
    local oldInfo = showcase:FindFirstChild("M5B2_InfoPlate" .. slot)
    if oldInfo then
        for _, gui in ipairs(oldInfo:GetChildren()) do
            if gui:IsA("SurfaceGui") then gui.Enabled = true end
        end
    end
    destroyIfPresent(showcase, "M5C4_PlinthSurface" .. slot)
    destroyIfPresent(showcase, "M5C4_AccentRail" .. slot)
    destroyIfPresent(showcase, "M5C4_Halo" .. slot)
    destroyIfPresent(showcase, "M5C4_Nameplate" .. slot)
end

local function ensureNameplate(showcase, slot, oldInfo, model, style, rarity)
    local collectionId = tostring(model:GetAttribute("CollectionId") or "")
    local serial = tostring(model:GetAttribute("Serial") or "")
    local entry = CollectionRegistry.Get(collectionId)
    local itemName = entry and tostring(entry.name or collectionId) or collectionId

    local plate = makePart(
        showcase,
        "M5C4_Nameplate" .. slot,
        Vector3.new(3.08, 0.90, 0.075),
        oldInfo.CFrame * CFrame.new(0, 0, -0.16),
        style.plate,
        rarity == "SECRET" and Enum.Material.Metal or Enum.Material.SmoothPlastic,
        0
    )

    local gui = plate:FindFirstChild("M5C4Surface")
    if not gui or not gui:IsA("SurfaceGui") then
        if gui then gui:Destroy() end
        gui = Instance.new("SurfaceGui")
        gui.Name = "M5C4Surface"
        gui.Face = Enum.NormalId.Front
        gui.LightInfluence = 0
        gui.PixelsPerStud = 100
        gui.Parent = plate

        local top = Instance.new("TextLabel")
        top.Name = "Top"
        top.Size = UDim2.new(1, -10, 0.55, 0)
        top.Position = UDim2.fromOffset(5, 2)
        top.BackgroundTransparency = 1
        top.TextColor3 = Color3.fromRGB(242, 245, 249)
        top.Font = Enum.Font.GothamBold
        top.TextScaled = true
        top.TextWrapped = true
        top.TextXAlignment = Enum.TextXAlignment.Center
        top.TextYAlignment = Enum.TextYAlignment.Center
        top.Parent = gui
        local tc = Instance.new("UITextSizeConstraint")
        tc.MinTextSize = 8
        tc.MaxTextSize = 12
        tc.Parent = top

        local bottom = Instance.new("TextLabel")
        bottom.Name = "Bottom"
        bottom.Size = UDim2.new(1, -10, 0.36, 0)
        bottom.Position = UDim2.new(0, 5, 0.61, 0)
        bottom.BackgroundTransparency = 1
        bottom.Font = Enum.Font.RobotoMono
        bottom.TextScaled = true
        bottom.TextWrapped = false
        bottom.TextXAlignment = Enum.TextXAlignment.Center
        bottom.TextYAlignment = Enum.TextYAlignment.Center
        bottom.Parent = gui
        local bc = Instance.new("UITextSizeConstraint")
        bc.MinTextSize = 8
        bc.MaxTextSize = 11
        bc.Parent = bottom
    end

    gui.Top.Text = string.upper(itemName)
    gui.Bottom.Text = rarity .. "  •  " .. serial
    gui.Bottom.TextColor3 = style.accent

    if style.trim then
        makePart(
            showcase,
            "M5C4_NameplateTrim" .. slot,
            Vector3.new(2.82, 0.055, 0.040),
            plate.CFrame * CFrame.new(0, plate.Size.Y * 0.5 - 0.08, -0.055),
            style.secondary,
            rarity == "UNCOMMON" and Enum.Material.Metal or Enum.Material.Neon,
            rarity == "UNCOMMON" and 0.05 or 0
        )
    else
        destroyIfPresent(showcase, "M5C4_NameplateTrim" .. slot)
    end
end

local function ensureHalo(showcase, slot, plinth, style, rarity)
    if not style.halo then
        destroyIfPresent(showcase, "M5C4_Halo" .. slot)
        return
    end

    local halo = makePart(
        showcase,
        "M5C4_Halo" .. slot,
        Vector3.new(2.70, 0.035, 1.56),
        plinth.CFrame * CFrame.new(0, -plinth.Size.Y * 0.5 - 0.030, 0),
        style.secondary,
        Enum.Material.Neon,
        style.haloTransparency or 0.30
    )

    local light = halo:FindFirstChild("M5C4SecretLight")
    if style.light and style.light > 0 then
        if not light or not light:IsA("SurfaceLight") then
            if light then light:Destroy() end
            light = Instance.new("SurfaceLight")
            light.Name = "M5C4SecretLight"
            light.Face = Enum.NormalId.Top
            light.Parent = halo
        end
        light.Color = style.secondary
        light.Brightness = style.light
        light.Range = 3.0
        light.Angle = 85
        light.Shadows = false
    elseif light then
        light:Destroy()
    end
end

local function applySlot(showcase, slot)
    if not showcase or not showcase.Parent then return end
    local model = findStableModel(showcase, slot)
    if not model then
        restoreLegacyEmpty(showcase, slot)
        return
    end

    local rarity = string.upper(tostring(model:GetAttribute("Rarity") or "COMMON"))
    local style = STYLES[rarity] or STYLES.COMMON
    local plinth = showcase:FindFirstChild("M5B2_Plinth" .. slot)
    local oldInfo = showcase:FindFirstChild("M5B2_InfoPlate" .. slot)
    if not plinth or not plinth:IsA("BasePart") or not oldInfo or not oldInfo:IsA("BasePart") then return end

    -- Hide previous M5-C.1.3 rarity presentation without deleting it. Its lifecycle stays intact.
    local oldBar = showcase:FindFirstChild("M5C13_RarityBar" .. slot)
    if oldBar and oldBar:IsA("BasePart") then oldBar.Transparency = 1 end
    local oldPlate = showcase:FindFirstChild("M5C13_Nameplate" .. slot)
    if oldPlate then
        local oldGui = oldPlate:FindFirstChild("M5C13Surface")
        if oldGui and oldGui:IsA("SurfaceGui") then oldGui.Enabled = false end
    end
    local oldGlow = showcase:FindFirstChild("M5B2_SlotGlow" .. slot)
    if oldGlow and oldGlow:IsA("BasePart") then oldGlow.Transparency = 1 end
    for _, gui in ipairs(oldInfo:GetChildren()) do
        if gui:IsA("SurfaceGui") then gui.Enabled = false end
    end

    -- A thin display surface overlays the existing station-theme plinth. The collectible itself is untouched.
    makePart(
        showcase,
        "M5C4_PlinthSurface" .. slot,
        Vector3.new(2.46, 0.035, 1.36),
        plinth.CFrame * CFrame.new(0, plinth.Size.Y * 0.5 + 0.018, 0),
        style.plinth,
        style.surfaceMaterial,
        0
    )

    makePart(
        showcase,
        "M5C4_AccentRail" .. slot,
        Vector3.new(2.38, 0.085, 0.10),
        plinth.CFrame * CFrame.new(0, -plinth.Size.Y * 0.5 - 0.058, -plinth.Size.Z * 0.5 - 0.035),
        style.accent,
        style.railMaterial,
        style.railTransparency
    )

    ensureHalo(showcase, slot, plinth, style, rarity)
    ensureNameplate(showcase, slot, oldInfo, model, style, rarity)

    model:SetAttribute("RarityDisplayVersion", VERSION)
    local station = showcase.Parent
    if station and station:IsA("Model") then station:SetAttribute("RarityDisplayVersion", VERSION) end
end

local function scheduleSlot(showcase, slot)
    if not showcase or not showcase.Parent then return end
    local map = scheduled[showcase]
    if not map then
        map = {}
        scheduled[showcase] = map
    end
    if map[slot] then return end
    map[slot] = true
    task.defer(function()
        map[slot] = nil
        if showcase.Parent then applySlot(showcase, slot) end
    end)
end

local function bindModel(showcase, model)
    if not model or boundModels[model] then return end
    local slot = tonumber(string.match(model.Name, "^M5C13_Slot_(%d+)$"))
    if not slot or slot < 1 or slot > SLOT_COUNT then return end
    boundModels[model] = true
    model:GetAttributeChangedSignal("Rarity"):Connect(function() scheduleSlot(showcase, slot) end)
    model:GetAttributeChangedSignal("Serial"):Connect(function() scheduleSlot(showcase, slot) end)
    model:GetAttributeChangedSignal("CollectionId"):Connect(function() scheduleSlot(showcase, slot) end)
    scheduleSlot(showcase, slot)
end

local function bindFolder(showcase, folder)
    if not folder or boundFolders[folder] then return end
    boundFolders[folder] = true
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then bindModel(showcase, child) end
    end
    folder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then bindModel(showcase, child) end
    end)
    folder.ChildRemoved:Connect(function(child)
        local slot = child:IsA("Model") and tonumber(string.match(child.Name, "^M5C13_Slot_(%d+)$")) or nil
        if slot then scheduleSlot(showcase, slot) end
    end)
end

local function bindShowcase(showcase)
    if not showcase or boundShowcases[showcase] then return end
    boundShowcases[showcase] = true

    local folder = showcase:FindFirstChild(STABLE_FOLDER)
    if folder and folder:IsA("Folder") then bindFolder(showcase, folder) end

    showcase.ChildAdded:Connect(function(child)
        if child.Name == STABLE_FOLDER and child:IsA("Folder") then
            bindFolder(showcase, child)
        end
    end)

    showcase.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Model") and descendant.Parent and descendant.Parent.Name == STABLE_FOLDER then
            bindModel(showcase, descendant)
        end
    end)

    for slot = 1, SLOT_COUNT do scheduleSlot(showcase, slot) end
end

local function bindWorld(world)
    if not world or world.Name ~= "LostAndFoundM4D" then return end
    for _, descendant in ipairs(world:GetDescendants()) do
        if descendant.Name == "PublicShowcase" and descendant:IsA("Model") then bindShowcase(descendant) end
    end
    world.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "PublicShowcase" and descendant:IsA("Model") then bindShowcase(descendant) end
    end)
end

local existing = workspace:FindFirstChild("LostAndFoundM4D")
if existing then bindWorld(existing) end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then bindWorld(child) end
end)

print("[LOST FOUND] M5-C.4 rarity display language ready", VERSION)
