-- LOST & FOUND: NIGHT SHIFT — M5-E Collection Prestige & Showcase Polish
-- Presentation-only layer on top of M5-C.4 rarity display language.
--
-- Goals:
--   * Keep collectible materials/colors realistic and untouched.
--   * Improve display readability and prestige without rebuilding stable models.
--   * Add restrained edition badge + gallery edge framing.
--   * Reserve special static lighting for ANOMALY and SECRET only.
--
-- Hard locks:
--   * M5-C.1.3 remains sole stable collectible lifecycle authority.
--   * No Destroy/ScaleTo/PivotTo on collectible models.
--   * No periodic loops or pulsing animation.
--   * No economy/drop/trade/serial/provenance/station-ownership changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))

local VERSION = "M5E_PRESTIGE_DISPLAY_V1"
local WORLD_NAME = "LostAndFoundM4D"
local SHOWCASE_NAME = "PublicShowcase"
local STABLE_FOLDER = "M5C13StableItems"
local SLOT_COUNT = 5

local PRESTIGE = {
    COMMON = {
        edge = Color3.fromRGB(126, 136, 149),
        edgeMaterial = Enum.Material.Metal,
        edgeTransparency = 0.46,
        sideEdges = false,
        badge = Color3.fromRGB(177, 185, 196),
    },
    UNCOMMON = {
        edge = Color3.fromRGB(188, 198, 208),
        edgeMaterial = Enum.Material.Metal,
        edgeTransparency = 0.18,
        sideEdges = true,
        badge = Color3.fromRGB(205, 214, 222),
    },
    RARE = {
        edge = Color3.fromRGB(59, 103, 190),
        edgeMaterial = Enum.Material.Metal,
        edgeTransparency = 0.08,
        sideEdges = true,
        badge = Color3.fromRGB(94, 139, 226),
    },
    EPIC = {
        edge = Color3.fromRGB(139, 86, 196),
        edgeMaterial = Enum.Material.Metal,
        edgeTransparency = 0.05,
        sideEdges = true,
        badge = Color3.fromRGB(174, 119, 225),
    },
    ANOMALY = {
        edge = Color3.fromRGB(185, 227, 235),
        edgeMaterial = Enum.Material.Metal,
        edgeTransparency = 0.00,
        sideEdges = true,
        badge = Color3.fromRGB(205, 239, 244),
        spotlight = Color3.fromRGB(170, 226, 236),
        brightness = 0.16,
        range = 5.0,
    },
    SECRET = {
        edge = Color3.fromRGB(219, 174, 73),
        edgeMaterial = Enum.Material.Metal,
        edgeTransparency = 0.00,
        sideEdges = true,
        badge = Color3.fromRGB(245, 214, 132),
        spotlight = Color3.fromRGB(255, 218, 145),
        brightness = 0.20,
        range = 5.2,
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
    part.Material = material or Enum.Material.Metal
    part.Transparency = transparency or 0
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    return part
end

local function destroyOwn(showcase, name)
    local child = showcase and showcase:FindFirstChild(name)
    if child then child:Destroy() end
end

local function stableModel(showcase, slot)
    local folder = showcase:FindFirstChild(STABLE_FOLDER)
    local model = folder and folder:FindFirstChild("M5C13_Slot_" .. tostring(slot))
    return model and model:IsA("Model") and model or nil
end

local function clearEditionBadge(showcase, slot)
    local plate = showcase:FindFirstChild("M5C4_Nameplate" .. tostring(slot))
    local gui = plate and plate:FindFirstChild("M5C4Surface")
    local badge = gui and gui:FindFirstChild("M5EEdition")
    if badge then badge:Destroy() end
    local top = gui and gui:FindFirstChild("Top")
    if top and top:IsA("TextLabel") then
        top.Size = UDim2.new(1, -10, 0.55, 0)
        top.Position = UDim2.fromOffset(5, 2)
        top.TextXAlignment = Enum.TextXAlignment.Center
    end
end

local function clearSlot(showcase, slot)
    destroyOwn(showcase, "M5E_FrontEdge" .. slot)
    destroyOwn(showcase, "M5E_LeftEdge" .. slot)
    destroyOwn(showcase, "M5E_RightEdge" .. slot)
    destroyOwn(showcase, "M5E_BackEdge" .. slot)
    destroyOwn(showcase, "M5E_LightAnchor" .. slot)
    clearEditionBadge(showcase, slot)
end

local function ensureEditionBadge(showcase, slot, model, style)
    local plate = showcase:FindFirstChild("M5C4_Nameplate" .. tostring(slot))
    local gui = plate and plate:FindFirstChild("M5C4Surface")
    if not gui or not gui:IsA("SurfaceGui") then return false end

    local collectionId = tostring(model:GetAttribute("CollectionId") or "")
    local entry = CollectionRegistry.Get(collectionId)
    local edition = entry and tostring(entry.edition or "S1") or "S1"

    local top = gui:FindFirstChild("Top")
    if top and top:IsA("TextLabel") then
        top.Size = UDim2.new(0.78, -5, 0.55, 0)
        top.Position = UDim2.fromOffset(5, 2)
        top.TextXAlignment = Enum.TextXAlignment.Left
    end

    local badge = gui:FindFirstChild("M5EEdition")
    if not badge or not badge:IsA("TextLabel") then
        if badge then badge:Destroy() end
        badge = Instance.new("TextLabel")
        badge.Name = "M5EEdition"
        badge.Size = UDim2.new(0.20, -4, 0.40, 0)
        badge.Position = UDim2.new(0.80, 0, 0.08, 0)
        badge.BackgroundTransparency = 1
        badge.Font = Enum.Font.GothamBold
        badge.TextScaled = true
        badge.TextWrapped = false
        badge.TextXAlignment = Enum.TextXAlignment.Right
        badge.TextYAlignment = Enum.TextYAlignment.Center
        badge.Parent = gui

        local constraint = Instance.new("UITextSizeConstraint")
        constraint.MinTextSize = 7
        constraint.MaxTextSize = 10
        constraint.Parent = badge
    end

    badge.Text = edition
    badge.TextColor3 = style.badge
    return true
end

local function ensureGalleryEdges(showcase, slot, plinthSurface, style)
    local cf = plinthSurface.CFrame
    local size = plinthSurface.Size
    local y = size.Y * 0.5 + 0.030
    local frontZ = -(size.Z * 0.5 + 0.020)
    local backZ = size.Z * 0.5 + 0.020
    local sideX = size.X * 0.5 + 0.020

    makePart(
        showcase,
        "M5E_FrontEdge" .. slot,
        Vector3.new(size.X + 0.08, 0.045, 0.050),
        cf * CFrame.new(0, y, frontZ),
        style.edge,
        style.edgeMaterial,
        style.edgeTransparency
    )

    if style.sideEdges then
        makePart(
            showcase,
            "M5E_LeftEdge" .. slot,
            Vector3.new(0.050, 0.045, size.Z + 0.08),
            cf * CFrame.new(-sideX, y, 0),
            style.edge,
            style.edgeMaterial,
            style.edgeTransparency
        )
        makePart(
            showcase,
            "M5E_RightEdge" .. slot,
            Vector3.new(0.050, 0.045, size.Z + 0.08),
            cf * CFrame.new(sideX, y, 0),
            style.edge,
            style.edgeMaterial,
            style.edgeTransparency
        )
        makePart(
            showcase,
            "M5E_BackEdge" .. slot,
            Vector3.new(size.X + 0.08, 0.045, 0.050),
            cf * CFrame.new(0, y, backZ),
            style.edge,
            style.edgeMaterial,
            math.min(0.65, style.edgeTransparency + 0.10)
        )
    else
        destroyOwn(showcase, "M5E_LeftEdge" .. slot)
        destroyOwn(showcase, "M5E_RightEdge" .. slot)
        destroyOwn(showcase, "M5E_BackEdge" .. slot)
    end
end

local function ensureSpotlight(showcase, slot, plinthSurface, style)
    if not style.spotlight or not style.brightness or style.brightness <= 0 then
        destroyOwn(showcase, "M5E_LightAnchor" .. slot)
        return
    end

    local anchor = makePart(
        showcase,
        "M5E_LightAnchor" .. slot,
        Vector3.new(0.18, 0.18, 0.18),
        plinthSurface.CFrame * CFrame.new(0, 3.15, 0),
        Color3.new(1, 1, 1),
        Enum.Material.SmoothPlastic,
        1
    )

    local light = anchor:FindFirstChild("M5EPrestigeSpot")
    if not light or not light:IsA("SpotLight") then
        if light then light:Destroy() end
        light = Instance.new("SpotLight")
        light.Name = "M5EPrestigeSpot"
        light.Face = Enum.NormalId.Bottom
        light.Parent = anchor
    end
    light.Color = style.spotlight
    light.Brightness = style.brightness
    light.Range = style.range or 5.0
    light.Angle = 52
    light.Shadows = false
end

local function applySlot(showcase, slot)
    if not showcase or not showcase.Parent then return end
    local model = stableModel(showcase, slot)
    if not model then
        clearSlot(showcase, slot)
        return
    end

    -- M5-E depends on the M5-C.4 presentation surface, but never mutates the collectible.
    local plinthSurface = showcase:FindFirstChild("M5C4_PlinthSurface" .. tostring(slot))
    local nameplate = showcase:FindFirstChild("M5C4_Nameplate" .. tostring(slot))
    if not plinthSurface or not plinthSurface:IsA("BasePart") or not nameplate then return end

    local rarity = string.upper(tostring(model:GetAttribute("Rarity") or "COMMON"))
    local style = PRESTIGE[rarity] or PRESTIGE.COMMON

    ensureGalleryEdges(showcase, slot, plinthSurface, style)
    ensureEditionBadge(showcase, slot, model, style)
    ensureSpotlight(showcase, slot, plinthSurface, style)

    showcase:SetAttribute("CollectionPrestigeVersion", VERSION)
    local station = showcase.Parent
    if station and station:IsA("Model") then
        station:SetAttribute("CollectionPrestigeVersion", VERSION)
    end
end

local function scheduleSlot(showcase, slot)
    if not showcase or not showcase.Parent then return end
    local slots = scheduled[showcase]
    if not slots then
        slots = {}
        scheduled[showcase] = slots
    end
    if slots[slot] then return end
    slots[slot] = true
    task.defer(function()
        slots[slot] = nil
        if showcase.Parent then applySlot(showcase, slot) end
    end)
end

local function slotFromChildName(name)
    return tonumber(string.match(tostring(name), "(%d+)$"))
end

local function bindModel(showcase, model)
    if not model or boundModels[model] then return end
    local slot = tonumber(string.match(model.Name, "^M5C13_Slot_(%d+)$"))
    if not slot or slot < 1 or slot > SLOT_COUNT then return end
    boundModels[model] = true
    model:GetAttributeChangedSignal("Rarity"):Connect(function() scheduleSlot(showcase, slot) end)
    model:GetAttributeChangedSignal("CollectionId"):Connect(function() scheduleSlot(showcase, slot) end)
    model:GetAttributeChangedSignal("Serial"):Connect(function() scheduleSlot(showcase, slot) end)
    scheduleSlot(showcase, slot)
end

local function bindStableFolder(showcase, folder)
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
    if folder and folder:IsA("Folder") then bindStableFolder(showcase, folder) end

    showcase.ChildAdded:Connect(function(child)
        if child.Name == STABLE_FOLDER and child:IsA("Folder") then
            bindStableFolder(showcase, child)
            return
        end
        if string.match(child.Name, "^M5C4_") then
            local slot = slotFromChildName(child.Name)
            if slot and slot >= 1 and slot <= SLOT_COUNT then scheduleSlot(showcase, slot) end
        end
    end)

    showcase.ChildRemoved:Connect(function(child)
        if string.match(child.Name, "^M5C4_") then
            local slot = slotFromChildName(child.Name)
            if slot and slot >= 1 and slot <= SLOT_COUNT then scheduleSlot(showcase, slot) end
        end
    end)

    for slot = 1, SLOT_COUNT do scheduleSlot(showcase, slot) end
end

local function bindStation(station)
    if not station or not station:IsA("Model") then return end
    local showcase = station:FindFirstChild(SHOWCASE_NAME)
    if showcase then bindShowcase(showcase) end
    station.ChildAdded:Connect(function(child)
        if child.Name == SHOWCASE_NAME then bindShowcase(child) end
    end)
end

local world = workspace:WaitForChild(WORLD_NAME)
for _, station in ipairs(world:GetChildren()) do bindStation(station) end
world.ChildAdded:Connect(bindStation)
