-- LOST & FOUND: NIGHT SHIFT — M5-B.1 larger showcase rack layout.
-- Presentation-only. Moves the existing three-slot public showcase into the owner-marked
-- upper-right wall zone, enlarges it, and replaces overlapping floating labels with
-- fixed physical information plates. Roblox in-engine geometry/UI only; no images.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local RARITY_COLORS = {
    COMMON = Color3.fromRGB(177, 187, 201),
    UNCOMMON = Color3.fromRGB(104, 190, 127),
    RARE = Color3.fromRGB(95, 167, 232),
    EPIC = Color3.fromRGB(177, 115, 226),
    ANOMALY = Color3.fromRGB(88, 221, 224),
    SECRET = Color3.fromRGB(235, 223, 179),
}

local FALLBACK = {
    panel = Color3.fromRGB(23, 29, 38),
    trim = Color3.fromRGB(75, 85, 99),
    accent = Color3.fromRGB(224, 163, 64),
    base = Color3.fromRGB(38, 45, 56),
}

local RACK_CENTER_X_OFFSET = 4.45
local RACK_CENTER_Y = 10.25
local RACK_BACK_Z_OFFSET = -13.12
local RACK_FRONT_Z_OFFSET = -12.12
local ITEM_SCALE = 0.30
local SLOT_X = {-3.35, 0, 3.35}

local function paletteFor(station)
    local skin = StationSkinRegistry.Get(station:GetAttribute("SkinId"))
    return skin and skin.palette or {}
end

local function roleColor(station, role)
    local palette = paletteFor(station)
    return palette[role] or FALLBACK[role] or Color3.fromRGB(80, 88, 100)
end

local function stylePart(station, target, role, color, material)
    target:SetAttribute("StationSkinRole", role)
    target.Color = color or roleColor(station, role)
    target.Material = material or Enum.Material.Metal
    target.Anchored = true
    target.CanCollide = false
    target.CanTouch = false
    target.CanQuery = false
    target.CastShadow = false
    target.TopSurface = Enum.SurfaceType.Smooth
    target.BottomSurface = Enum.SurfaceType.Smooth
end

local function makePart(station, parent, name, size, cframe, role, material)
    local p = parent:FindFirstChild(name)
    if not p or not p:IsA("BasePart") then
        if p then p:Destroy() end
        p = Instance.new("Part")
        p.Name = name
        p.Parent = parent
    end
    p.Size = size
    p.CFrame = cframe
    stylePart(station, p, role, nil, material)
    return p
end

local function clearSurface(part)
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("SurfaceGui") then child:Destroy() end
    end
end

local function surfaceLabel(part, text, textColor, font, textSize)
    clearSurface(part)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "M5B1Surface"
    gui.Face = Enum.NormalId.Front
    gui.LightInfluence = 0
    gui.PixelsPerStud = 62
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = textColor
    label.Font = font or Enum.Font.GothamBold
    label.TextSize = textSize or 14
    label.TextScaled = false
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = gui
    return label
end

local function removeLegacyRackParts(showcase)
    for _, name in ipairs({"ShelfBack", "Title", "Shelf1", "Shelf2", "Shelf3"}) do
        local old = showcase:FindFirstChild(name)
        if old then old:Destroy() end
    end
end

local function recolorRack(station, showcase)
    for _, descendant in ipairs(showcase:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local role = descendant:GetAttribute("StationSkinRole")
            if role then descendant.Color = roleColor(station, role) end
        end
    end
end

local function setupRack(station)
    local showcase = station:FindFirstChild("PublicShowcase")
    local bay = station:FindFirstChild("BayFloor")
    if not showcase or not showcase:IsA("Model") or not bay or not bay:IsA("BasePart") then return nil end

    removeLegacyRackParts(showcase)

    local x = bay.Position.X + RACK_CENTER_X_OFFSET
    local zBack = bay.Position.Z + RACK_BACK_Z_OFFSET
    local zFront = bay.Position.Z + RACK_FRONT_Z_OFFSET

    local backing = makePart(station, showcase, "M5B1_Backboard", Vector3.new(11.2, 4.9, 0.32), CFrame.new(x, RACK_CENTER_Y, zBack), "panel", Enum.Material.Metal)
    local top = makePart(station, showcase, "M5B1_TopRail", Vector3.new(11.55, 0.22, 0.44), CFrame.new(x, 12.73, zBack + 0.04), "accent", Enum.Material.Neon)
    local bottom = makePart(station, showcase, "M5B1_BottomRail", Vector3.new(11.55, 0.20, 0.44), CFrame.new(x, 7.78, zBack + 0.04), "accent", Enum.Material.Neon)
    makePart(station, showcase, "M5B1_LeftRail", Vector3.new(0.20, 5.0, 0.42), CFrame.new(x - 5.68, 10.25, zBack + 0.04), "trim", Enum.Material.Metal)
    makePart(station, showcase, "M5B1_RightRail", Vector3.new(0.20, 5.0, 0.42), CFrame.new(x + 5.68, 10.25, zBack + 0.04), "trim", Enum.Material.Metal)

    local title = makePart(station, showcase, "M5B1_Title", Vector3.new(10.5, 0.72, 0.18), CFrame.new(x, 12.24, zBack + 0.20), "base", Enum.Material.SmoothPlastic)
    surfaceLabel(title, "PERSONAL COLLECTION  //  3 SLOT", roleColor(station, "accent"), Enum.Font.GothamBlack, 15)

    for slot = 1, 3 do
        local sx = x + SLOT_X[slot]
        if slot < 3 then
            local dividerX = x + (SLOT_X[slot] + SLOT_X[slot + 1]) * 0.5
            makePart(station, showcase, "M5B1_Divider" .. tostring(slot), Vector3.new(0.10, 3.70, 0.22), CFrame.new(dividerX, 10.05, zBack + 0.21), "trim", Enum.Material.Metal)
        end

        makePart(station, showcase, "M5B1_SlotGlow" .. tostring(slot), Vector3.new(2.95, 0.10, 0.14), CFrame.new(sx, 11.65, zBack + 0.23), "accent", Enum.Material.Neon)
        makePart(station, showcase, "M5B1_Shelf" .. tostring(slot), Vector3.new(2.85, 0.18, 1.85), CFrame.new(sx, 9.03, zFront), "trim", Enum.Material.Metal)
        makePart(station, showcase, "M5B1_Plinth" .. tostring(slot), Vector3.new(2.35, 0.24, 1.40), CFrame.new(sx, 9.18, zFront - 0.02), "base", Enum.Material.SmoothPlastic)

        local anchor = showcase:FindFirstChild("DisplayAnchor" .. tostring(slot))
        if not anchor or not anchor:IsA("BasePart") then
            if anchor then anchor:Destroy() end
            anchor = Instance.new("Part")
            anchor.Name = "DisplayAnchor" .. tostring(slot)
            anchor.Parent = showcase
        end
        anchor.Size = Vector3.new(0.4, 0.4, 0.4)
        anchor.CFrame = CFrame.new(sx, 10.18, zFront - 0.02)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false

        local plate = makePart(station, showcase, "M5B1_InfoPlate" .. tostring(slot), Vector3.new(3.00, 0.95, 0.16), CFrame.new(sx, 8.30, zBack + 0.23), "base", Enum.Material.SmoothPlastic)
        plate:SetAttribute("M5B1Slot", slot)
        surfaceLabel(plate, "SLOT " .. tostring(slot) .. "\nEMPTY", roleColor(station, "trim"), Enum.Font.GothamBold, 11)
    end

    backing:SetAttribute("M5B1Rack", true)
    top:SetAttribute("M5B1Rack", true)
    bottom:SetAttribute("M5B1Rack", true)
    showcase:SetAttribute("M5B1Layout", "UPPER_RIGHT_LARGE_V1")
    station:SetAttribute("ShowcaseLayoutVersion", "M5B1_UPPER_RIGHT_LARGE_V1")
    recolorRack(station, showcase)
    return showcase
end

local function clearFloatingLabels(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BillboardGui") and (descendant.Name == "M5BShowcaseLabel" or descendant.Name == "SerialLabel") then
            descendant:Destroy()
        end
    end
end

local function setPlate(station, showcase, slot, model)
    local plate = showcase:FindFirstChild("M5B1_InfoPlate" .. tostring(slot))
    if not plate or not plate:IsA("BasePart") then return end

    if not model then
        surfaceLabel(plate, "SLOT " .. tostring(slot) .. "\nEMPTY", roleColor(station, "trim"), Enum.Font.GothamBold, 11)
        return
    end

    local collectionId = model:GetAttribute("CollectionId")
    local serial = tostring(model:GetAttribute("Serial") or "")
    local rarity = tostring(model:GetAttribute("Rarity") or "COMMON")
    local entry = CollectionRegistry.Get(collectionId)
    local name = entry and entry.name or tostring(collectionId or "COLLECTIBLE")
    local accent = RARITY_COLORS[rarity] or roleColor(station, "accent")
    surfaceLabel(plate, string.format("%s  •  %s\n%s", name, rarity, serial), accent, Enum.Font.GothamBold, 10)
end

local function refreshDisplayed(station, showcase)
    if not station or not showcase then return end
    local folder = showcase:FindFirstChild("DisplayedItems")
    local bySlot = {}

    if folder then
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") then
                local slot = tonumber(string.match(model.Name, "M5B_Slot_(%d+)")) or tonumber(string.match(model.Name, "Display_(%d+)"))
                if slot and slot >= 1 and slot <= 3 then
                    bySlot[slot] = model
                    clearFloatingLabels(model)
                    pcall(function() model:ScaleTo(ITEM_SCALE) end)
                    local anchor = showcase:FindFirstChild("DisplayAnchor" .. tostring(slot))
                    if anchor and anchor:IsA("BasePart") then
                        model:PivotTo(anchor.CFrame * CFrame.Angles(0, math.rad(180), 0))
                    end
                end
            end
        end
    end

    for slot = 1, 3 do
        setPlate(station, showcase, slot, bySlot[slot])
    end
end

local function bindDisplayedFolder(station, showcase, folder)
    if not folder or not folder:IsA("Folder") then return end
    task.defer(refreshDisplayed, station, showcase)
    folder.ChildAdded:Connect(function()
        task.defer(refreshDisplayed, station, showcase)
        task.delay(0.15, refreshDisplayed, station, showcase)
    end)
    folder.ChildRemoved:Connect(function()
        task.defer(refreshDisplayed, station, showcase)
    end)
end

local boundStations = setmetatable({}, { __mode = "k" })

local function bindStation(station)
    if boundStations[station] then return end
    if not station:IsA("Model") or string.sub(station.Name, 1, 8) ~= "Station_" then return end

    local showcase = setupRack(station)
    if not showcase then
        task.delay(0.20, bindStation, station)
        return
    end

    boundStations[station] = true
    station:GetAttributeChangedSignal("SkinId"):Connect(function()
        task.defer(function()
            recolorRack(station, showcase)
            local title = showcase:FindFirstChild("M5B1_Title")
            if title and title:IsA("BasePart") then
                surfaceLabel(title, "PERSONAL COLLECTION  //  3 SLOT", roleColor(station, "accent"), Enum.Font.GothamBlack, 15)
            end
            refreshDisplayed(station, showcase)
        end)
    end)

    local current = showcase:FindFirstChild("DisplayedItems")
    if current then bindDisplayedFolder(station, showcase, current) end
    showcase.ChildAdded:Connect(function(child)
        if child.Name == "DisplayedItems" and child:IsA("Folder") then
            bindDisplayedFolder(station, showcase, child)
        end
    end)

    task.defer(refreshDisplayed, station, showcase)
    task.delay(1.0, refreshDisplayed, station, showcase)
end

local function bindWorld(world)
    if not world or world.Name ~= "LostAndFoundM4D" then return end
    for _, child in ipairs(world:GetChildren()) do bindStation(child) end
    world.ChildAdded:Connect(function(child)
        task.defer(bindStation, child)
    end)
end

local world = workspace:FindFirstChild("LostAndFoundM4D")
if world then task.defer(bindWorld, world) end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then task.defer(bindWorld, child) end
end)
