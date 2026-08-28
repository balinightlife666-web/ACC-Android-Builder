-- LOST & FOUND: NIGHT SHIFT — M5-B.2.1
-- World-level five-slot showcase layout reconciler.
-- Ensures every personal station A-H uses the same five-slot rack whether vacant or occupied.
-- Presentation only: does not touch inventory, persistence, trading, economy, drops, or case logic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local SLOT_COUNT = 5
local RACK_CENTER_X_OFFSET = 2.0
local RACK_CENTER_Y = 10.25
local RACK_BACK_Z_OFFSET = -13.12
local RACK_FRONT_Z_OFFSET = -12.12
local SLOT_X = {-7.05, -3.52, 0, 3.52, 7.05}

local FALLBACK = {
    panel = Color3.fromRGB(23, 29, 38),
    trim = Color3.fromRGB(75, 85, 99),
    accent = Color3.fromRGB(224, 163, 64),
    base = Color3.fromRGB(38, 45, 56),
}

local function paletteFor(station)
    local skin = StationSkinRegistry.Get(station:GetAttribute("SkinId"))
    return skin and skin.palette or {}
end

local function roleColor(station, role)
    return paletteFor(station)[role] or FALLBACK[role] or Color3.fromRGB(80, 88, 100)
end

local function stylePart(station, target, role, material)
    target:SetAttribute("StationSkinRole", role)
    target.Color = roleColor(station, role)
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
    stylePart(station, p, role, material)
    return p
end

local function setSurfaceText(part, text, color, textSize)
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("SurfaceGui") then child:Destroy() end
    end
    local gui = Instance.new("SurfaceGui")
    gui.Name = "M5B21Surface"
    gui.Face = Enum.NormalId.Front
    gui.LightInfluence = 0
    gui.PixelsPerStud = 62
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 11
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = gui
end

local function clearOldRack(showcase)
    for _, child in ipairs(showcase:GetChildren()) do
        local n = child.Name
        if string.sub(n, 1, 5) == "M5B1_"
            or string.sub(n, 1, 5) == "M5B2_"
            or n == "ShelfBack"
            or n == "Title"
            or string.match(n, "^Shelf%d+$")
        then
            child:Destroy()
        end
    end
end

local function needsRepair(station)
    local showcase = station:FindFirstChild("PublicShowcase")
    if not showcase then return false end
    if station:GetAttribute("ShowcaseLayoutVersion") ~= "M5B2_FIVE_SLOT_LARGE_V1" then return true end
    if not showcase:FindFirstChild("M5B2_InfoPlate5") then return true end
    if not showcase:FindFirstChild("DisplayAnchor5") then return true end
    return false
end

local function ensureFiveSlotRack(station)
    if not station or not station:IsA("Model") then return end
    if string.sub(station.Name, 1, 8) ~= "Station_" then return end

    local showcase = station:FindFirstChild("PublicShowcase")
    local bay = station:FindFirstChild("BayFloor")
    if not showcase or not showcase:IsA("Model") or not bay or not bay:IsA("BasePart") then return end
    if not needsRepair(station) then return end

    clearOldRack(showcase)

    local x = bay.Position.X + RACK_CENTER_X_OFFSET
    local zBack = bay.Position.Z + RACK_BACK_Z_OFFSET
    local zFront = bay.Position.Z + RACK_FRONT_Z_OFFSET

    makePart(station, showcase, "M5B2_Backboard", Vector3.new(18.35, 5.0, 0.32), CFrame.new(x, RACK_CENTER_Y, zBack), "panel", Enum.Material.Metal)
    makePart(station, showcase, "M5B2_TopRail", Vector3.new(18.7, 0.22, 0.44), CFrame.new(x, 12.78, zBack + 0.04), "accent", Enum.Material.Neon)
    makePart(station, showcase, "M5B2_BottomRail", Vector3.new(18.7, 0.20, 0.44), CFrame.new(x, 7.73, zBack + 0.04), "accent", Enum.Material.Neon)
    makePart(station, showcase, "M5B2_LeftRail", Vector3.new(0.20, 5.1, 0.42), CFrame.new(x - 9.25, 10.25, zBack + 0.04), "trim", Enum.Material.Metal)
    makePart(station, showcase, "M5B2_RightRail", Vector3.new(0.20, 5.1, 0.42), CFrame.new(x + 9.25, 10.25, zBack + 0.04), "trim", Enum.Material.Metal)

    local title = makePart(station, showcase, "M5B2_Title", Vector3.new(17.5, 0.68, 0.18), CFrame.new(x, 12.25, zBack + 0.20), "base", Enum.Material.SmoothPlastic)
    setSurfaceText(title, "PERSONAL COLLECTION  //  5 SLOT", roleColor(station, "accent"), 15)

    for slot = 1, SLOT_COUNT do
        local sx = x + SLOT_X[slot]
        if slot < SLOT_COUNT then
            local dividerX = x + (SLOT_X[slot] + SLOT_X[slot + 1]) * 0.5
            makePart(station, showcase, "M5B2_Divider" .. slot, Vector3.new(0.09, 3.72, 0.22), CFrame.new(dividerX, 10.03, zBack + 0.21), "trim", Enum.Material.Metal)
        end

        makePart(station, showcase, "M5B2_SlotGlow" .. slot, Vector3.new(3.05, 0.10, 0.14), CFrame.new(sx, 11.62, zBack + 0.23), "accent", Enum.Material.Neon)
        makePart(station, showcase, "M5B2_Shelf" .. slot, Vector3.new(3.05, 0.18, 1.86), CFrame.new(sx, 9.02, zFront), "trim", Enum.Material.Metal)
        makePart(station, showcase, "M5B2_Plinth" .. slot, Vector3.new(2.52, 0.24, 1.42), CFrame.new(sx, 9.18, zFront - 0.02), "base", Enum.Material.SmoothPlastic)

        local anchor = showcase:FindFirstChild("DisplayAnchor" .. slot)
        if not anchor or not anchor:IsA("BasePart") then
            if anchor then anchor:Destroy() end
            anchor = Instance.new("Part")
            anchor.Name = "DisplayAnchor" .. slot
            anchor.Parent = showcase
        end
        anchor.Size = Vector3.new(0.4, 0.4, 0.4)
        anchor.CFrame = CFrame.new(sx, 10.18, zFront - 0.02)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false

        local plate = makePart(station, showcase, "M5B2_InfoPlate" .. slot, Vector3.new(3.15, 0.95, 0.16), CFrame.new(sx, 8.28, zBack + 0.23), "base", Enum.Material.SmoothPlastic)
        plate:SetAttribute("M5B2Slot", slot)
        setSurfaceText(plate, "SLOT " .. slot .. "\nEMPTY", roleColor(station, "trim"), 10)
    end

    showcase:SetAttribute("M5B2Layout", "FIVE_SLOT_LARGE_V1")
    station:SetAttribute("ShowcaseLayoutVersion", "M5B2_FIVE_SLOT_LARGE_V1")
    station:SetAttribute("ShowcaseWorldLayoutVersion", "M5B21_ALL_STATIONS_V1")
end

local function reconcileWorld()
    local world = workspace:FindFirstChild("LostAndFoundM4D")
    if not world then return end
    for _, child in ipairs(world:GetChildren()) do
        ensureFiveSlotRack(child)
    end
end

local function bindWorld(world)
    if not world or world.Name ~= "LostAndFoundM4D" then return end
    task.delay(0.35, reconcileWorld)
    task.delay(1.0, reconcileWorld)
    task.delay(2.5, reconcileWorld)
    world.ChildAdded:Connect(function(child)
        task.delay(0.25, function() ensureFiveSlotRack(child) end)
    end)
end

local existing = workspace:FindFirstChild("LostAndFoundM4D")
if existing then bindWorld(existing) end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then bindWorld(child) end
end)

-- Low-frequency self-heal covers startup order with the older M5-B.1 presentation script.
task.spawn(function()
    while true do
        task.wait(8)
        reconcileWorld()
    end
end)
