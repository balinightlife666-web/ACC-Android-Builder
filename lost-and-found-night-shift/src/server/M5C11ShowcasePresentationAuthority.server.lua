-- LOST & FOUND: NIGHT SHIFT — M5-C.1.1 Showcase Presentation Authority
-- Runtime hotfix for M5-C.1 scale/pose flicker.
-- Older M5-B renderers still reconcile inventory and may temporarily rescale/re-pivot
-- displayed models. This presentation-only authority immediately restores the M5-C.1
-- fitted pose after those writes, without touching ownership, persistence or gameplay.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))

local VERSION = "M5C11_STABLE_PRESENTATION_V1"
local SLOT_COUNT = 5

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

local correcting = setmetatable({}, {__mode = "k"})
local boundModels = setmetatable({}, {__mode = "k"})
local boundShowcases = setmetatable({}, {__mode = "k"})

local function parseSlot(model)
    if not model or not model:IsA("Model") then return nil end
    return tonumber(string.match(model.Name, "M5B_Slot_(%d+)"))
        or tonumber(string.match(model.Name, "M5B2_Slot_(%d+)"))
        or tonumber(string.match(model.Name, "Display_(%d+)"))
end

local function setPart(model, root, name, size, offset, angles)
    local part = model:FindFirstChild(name, true)
    if not part or not part:IsA("BasePart") then return end
    part.Size = size
    local a = angles or Vector3.zero
    part.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(math.rad(a.X), math.rad(a.Y), math.rad(a.Z))
end

local function refineBear(model)
    if tostring(model:GetAttribute("CollectionId") or "") ~= "cream_memory_bear" then return end
    local root = model.PrimaryPart or model:FindFirstChild("Body")
    if not root or not root:IsA("BasePart") then return end

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
end

local function normalize(model)
    if correcting[model] or not model or not model.Parent then return end
    local folder = model.Parent
    local showcase = folder and folder.Parent
    local station = showcase and showcase.Parent
    if not folder or folder.Name ~= "DisplayedItems" or not showcase or not station then return end

    local slot = parseSlot(model)
    if not slot or slot < 1 or slot > SLOT_COUNT then return end
    local anchor = showcase:FindFirstChild("DisplayAnchor" .. slot)
    local plinth = showcase:FindFirstChild("M5B2_Plinth" .. slot)
    if not anchor or not anchor:IsA("BasePart") or not plinth or not plinth:IsA("BasePart") then return end

    correcting[model] = true
    local ok, err = pcall(function()
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BillboardGui") and (descendant.Name == "M5BShowcaseLabel" or descendant.Name == "SerialLabel") then
                descendant:Destroy()
            end
        end

        model:ScaleTo(1)
        refineBear(model)

        local family = tostring(model:GetAttribute("M5CBaseFamily") or "")
        if family == "" then
            local collectionId = tostring(model:GetAttribute("CollectionId") or "")
            local entry = CollectionRegistry.Get(collectionId)
            family = entry and tostring(entry.baseItemId or "") or ""
        end
        local profile = PROFILES[family] or DEFAULT_PROFILE

        local _, size = model:GetBoundingBox()
        if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then return end
        local scale = math.min(profile.w / size.X, profile.h / size.Y, profile.d / size.Z)
        scale = math.clamp(scale, 0.16, 0.72)
        model:ScaleTo(scale)

        local base = anchor.CFrame
            * CFrame.new(0, 0, profile.z or 0)
            * CFrame.Angles(math.rad(profile.pitch or 0), math.rad(profile.yaw or 180), math.rad(profile.roll or 0))
        model:PivotTo(base)

        local boxCf, boxSize = model:GetBoundingBox()
        local targetBottom = plinth.Position.Y + plinth.Size.Y * 0.5 + 0.055
        local currentBottom = boxCf.Position.Y - boxSize.Y * 0.5
        model:PivotTo(model:GetPivot() + Vector3.new(0, targetBottom - currentBottom, 0))
        model:SetAttribute("M5C1Presentation", "M5C1_SHOWCASE_PRESENTATION_V1")
        model:SetAttribute("M5C11PresentationAuthority", VERSION)
    end)
    correcting[model] = nil
    if not ok then warn("[LOST FOUND] M5-C.1.1 presentation normalize failed:", err) end
end

local function queueNormalize(model)
    if correcting[model] or not model or not model.Parent then return end
    if model:GetAttribute("M5C11NormalizeQueued") == true then return end
    model:SetAttribute("M5C11NormalizeQueued", true)
    task.defer(function()
        if not model.Parent then return end
        model:SetAttribute("M5C11NormalizeQueued", nil)
        normalize(model)
    end)
end

local function bindModel(model)
    if not model or not model:IsA("Model") or boundModels[model] then return end
    if not parseSlot(model) then return end
    boundModels[model] = true

    task.defer(function()
        if not model.Parent then return end
        normalize(model)
        local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if not primary then return end
        primary:GetPropertyChangedSignal("Size"):Connect(function()
            if not correcting[model] then queueNormalize(model) end
        end)
        primary:GetPropertyChangedSignal("CFrame"):Connect(function()
            if not correcting[model] then queueNormalize(model) end
        end)
    end)
end

local function bindShowcase(showcase)
    if not showcase or not showcase:IsA("Model") or boundShowcases[showcase] then return end
    boundShowcases[showcase] = true

    local function bindFolder(folder)
        if not folder or folder.Name ~= "DisplayedItems" then return end
        for _, child in ipairs(folder:GetChildren()) do bindModel(child) end
        folder.ChildAdded:Connect(function(child)
            if child:IsA("Model") then task.defer(bindModel, child) end
        end)
    end

    local folder = showcase:FindFirstChild("DisplayedItems")
    if folder then bindFolder(folder) end
    showcase.ChildAdded:Connect(function(child)
        if child.Name == "DisplayedItems" then task.defer(bindFolder, child) end
    end)
end

local function bindStation(station)
    if not station or not station:IsA("Model") or string.sub(station.Name, 1, 8) ~= "Station_" then return end
    local showcase = station:FindFirstChild("PublicShowcase")
    if showcase then bindShowcase(showcase) end
    station.ChildAdded:Connect(function(child)
        if child.Name == "PublicShowcase" then task.defer(bindShowcase, child) end
    end)
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

-- Low-frequency safety pass only. Normal correction is event-driven and should occur
-- immediately after any legacy scale/pivot write, preventing visible oscillation.
task.spawn(function()
    while true do
        task.wait(6)
        local current = workspace:FindFirstChild("LostAndFoundM4D")
        if current then
            for _, station in ipairs(current:GetChildren()) do
                local showcase = station:FindFirstChild("PublicShowcase")
                local folder = showcase and showcase:FindFirstChild("DisplayedItems")
                if folder then
                    for _, model in ipairs(folder:GetChildren()) do
                        if model:IsA("Model") then bindModel(model) end
                    end
                end
            end
        end
    end
end)
