-- LOST & FOUND: NIGHT SHIFT — M5-C.2 Collectible Readability Pass
-- Event-driven, presentation-only refinement for stable showcase models.
-- Runs once when an M5-C.1.3 stable collectible becomes visible; no loops, no rescaling,
-- no periodic PivotTo, no generated images/decals/external textures/assets.

local VERSION = "M5C2_READABILITY_V1"
local STABLE_FOLDER_NAME = "M5C13StableItems"

local function safeFind(model, name)
    local part = model:FindFirstChild(name, true)
    return part and part:IsA("BasePart") and part or nil
end

local function mark(model)
    model:SetAttribute("M5C2ReadabilityVersion", VERSION)
end

local function alreadyDone(model)
    return model:GetAttribute("M5C2ReadabilityVersion") == VERSION
end

local function makePart(model, name, size, cframe, color, material, shape)
    local existing = model:FindFirstChild(name, true)
    if existing then existing:Destroy() end
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    if shape then p.Shape = shape end
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = model
    return p
end

local function makeWedge(model, name, size, cframe, color, material)
    local existing = model:FindFirstChild(name, true)
    if existing then existing:Destroy() end
    local p = Instance.new("WedgePart")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = model
    return p
end

local function refineFormalShoe(model)
    local sole = safeFind(model, "Sole")
    if not sole then return end

    local sx, sy, sz = sole.Size.X, sole.Size.Y, sole.Size.Z
    local cf = sole.CFrame
    local leather = Color3.fromRGB(38, 35, 34)
    local leatherHi = Color3.fromRGB(53, 48, 43)
    local leatherDark = Color3.fromRGB(22, 21, 21)
    local stitch = Color3.fromRGB(132, 119, 99)

    -- Push the base toward a long, low dress-shoe silhouette instead of a boxy machine shape.
    sole.Size = Vector3.new(sx * 1.06, sy * 0.82, sz * 0.94)

    local midsole = safeFind(model, "Midsole")
    if midsole then
        midsole.Size = Vector3.new(sx * 0.99, sy * 0.46, sz * 0.88)
        midsole.CFrame = cf * CFrame.new(-sx * 0.015, sy * 0.50, 0)
    end

    local upper = safeFind(model, "Upper")
    if upper then
        upper.Size = Vector3.new(sx * 0.47, sy * 2.15, sz * 0.76)
        upper.CFrame = cf * CFrame.new(sx * 0.07, sy * 1.42, 0)
    end

    local toe = safeFind(model, "Toe")
    if toe then
        toe.Size = Vector3.new(sx * 0.47, sy * 1.72, sz * 0.83)
        toe.CFrame = cf * CFrame.new(-sx * 0.33, sy * 1.18, 0)
    end

    local heelQuarter = safeFind(model, "HeelQuarter")
    if heelQuarter then
        heelQuarter.Size = Vector3.new(sx * 0.20, sy * 2.65, sz * 0.73)
        heelQuarter.CFrame = cf * CFrame.new(sx * 0.37, sy * 1.60, 0)
    end

    local heel = safeFind(model, "HeelBlock")
    if heel then
        heel.Size = Vector3.new(sx * 0.14, sy * 0.92, sz * 0.68)
        heel.CFrame = cf * CFrame.new(sx * 0.40, -sy * 0.35, 0)
    end

    local tongue = safeFind(model, "Tongue")
    if tongue then
        tongue.Size = Vector3.new(sx * 0.20, sy * 2.35, sz * 0.10)
        tongue.CFrame = cf * CFrame.new(sx * 0.10, sy * 2.15, -sz * 0.42) * CFrame.Angles(math.rad(-18), 0, 0)
    end

    -- Sloped vamp is the strongest silhouette cue that this object is footwear.
    makeWedge(
        model,
        "M5C2_Vamp",
        Vector3.new(sx * 0.32, sy * 1.80, sz * 0.70),
        cf * CFrame.new(-sx * 0.08, sy * 1.58, 0) * CFrame.Angles(0, math.rad(90), 0),
        leather,
        Enum.Material.SmoothPlastic
    )

    -- Dark top opening separates the heel/quarter from the tongue at a glance.
    makePart(
        model,
        "M5C2_Opening",
        Vector3.new(sx * 0.19, sy * 0.30, sz * 0.50),
        cf * CFrame.new(sx * 0.25, sy * 2.45, 0),
        leatherDark,
        Enum.Material.SmoothPlastic
    )

    -- Toe-cap line and side welt make the profile read as a formal shoe from distance.
    makePart(
        model,
        "M5C2_ToeCap",
        Vector3.new(sx * 0.035, sy * 1.18, sz * 0.78),
        cf * CFrame.new(-sx * 0.22, sy * 1.15, 0),
        leatherHi,
        Enum.Material.SmoothPlastic
    )
    makePart(
        model,
        "M5C2_Welt",
        Vector3.new(sx * 0.78, sy * 0.12, sz * 0.075),
        cf * CFrame.new(-sx * 0.05, sy * 0.58, -sz * 0.48),
        stitch,
        Enum.Material.Fabric
    )

    -- Replace visually noisy tiny laces with four clear cross-laces.
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") and string.match(d.Name, "^Lace") then
            d.Transparency = 1
        end
    end
    for i = 1, 4 do
        local y = sy * (1.72 + (i - 1) * 0.24)
        makePart(
            model,
            "M5C2_Lace" .. i,
            Vector3.new(sx * 0.22, sy * 0.12, sz * 0.055),
            cf * CFrame.new(sx * 0.07, y, -sz * 0.49) * CFrame.Angles(0, 0, math.rad(i % 2 == 0 and 10 or -10)),
            stitch,
            Enum.Material.Fabric
        )
    end
end

local function refinePassport(model)
    local body = safeFind(model, "Body") or model.PrimaryPart
    if not body or not body:IsA("BasePart") then return end

    local sx, sy, sz = body.Size.X, body.Size.Y, body.Size.Z
    local cf = body.CFrame
    local gold = Color3.fromRGB(208, 170, 74)
    local paper = Color3.fromRGB(219, 210, 187)

    -- Slimmer cover + visible page block immediately reads as a passport/booklet.
    body.Size = Vector3.new(sx * 0.96, sy * 1.02, math.max(sz * 0.82, 0.05))
    makePart(model, "M5C2_PageBlock", Vector3.new(sx * 0.88, sy * 0.90, math.max(sz * 0.32, 0.035)), cf * CFrame.new(0, 0, sz * 0.48), paper, Enum.Material.SmoothPlastic)
    makePart(model, "M5C2_Spine", Vector3.new(sx * 0.085, sy * 0.96, math.max(sz * 1.08, 0.055)), cf * CFrame.new(-sx * 0.47, 0, 0), gold, Enum.Material.Metal)
    makePart(model, "M5C2_GoldLine1", Vector3.new(sx * 0.48, sy * 0.035, math.max(sz * 0.10, 0.025)), cf * CFrame.new(0, sy * 0.11, -sz * 0.56), gold, Enum.Material.Metal)
    makePart(model, "M5C2_GoldLine2", Vector3.new(sx * 0.34, sy * 0.035, math.max(sz * 0.10, 0.025)), cf * CFrame.new(0, -sy * 0.02, -sz * 0.56), gold, Enum.Material.Metal)
    makePart(model, "M5C2_Emblem", Vector3.new(sx * 0.20, sy * 0.20, math.max(sz * 0.12, 0.03)), cf * CFrame.new(0, -sy * 0.22, -sz * 0.57), gold, Enum.Material.Metal, Enum.PartType.Ball)
end

local function refineSuitcase(model)
    local collectionId = tostring(model:GetAttribute("CollectionId") or "")
    if collectionId ~= "blue_transit_hardcase" and collectionId ~= "black_security_hardcase" and collectionId ~= "flight_000_hardcase" then
        return
    end
    local body = safeFind(model, "Body") or model.PrimaryPart
    if not body or not body:IsA("BasePart") then return end

    local sx, sy, sz = body.Size.X, body.Size.Y, body.Size.Z
    local cf = body.CFrame
    local metal = Color3.fromRGB(112, 119, 130)
    local dark = Color3.fromRGB(22, 24, 28)

    makePart(model, "M5C2_HandleGrip", Vector3.new(sx * 0.34, sy * 0.075, sz * 0.16), cf * CFrame.new(0, sy * 0.60, 0), dark, Enum.Material.Metal)
    makePart(model, "M5C2_LatchL", Vector3.new(sx * 0.10, sy * 0.12, sz * 0.10), cf * CFrame.new(-sx * 0.16, sy * 0.12, -sz * 0.52), metal, Enum.Material.Metal)
    makePart(model, "M5C2_LatchR", Vector3.new(sx * 0.10, sy * 0.12, sz * 0.10), cf * CFrame.new(sx * 0.16, sy * 0.12, -sz * 0.52), metal, Enum.Material.Metal)
end

local function refine(model)
    if not model or not model:IsA("Model") or alreadyDone(model) then return end
    local collectionId = tostring(model:GetAttribute("CollectionId") or "")

    if collectionId == "daniel_formal_shoe" then
        refineFormalShoe(model)
    elseif collectionId == "duplicate_passport" then
        refinePassport(model)
    else
        refineSuitcase(model)
    end

    mark(model)
end

local boundFolders = setmetatable({}, {__mode = "k"})

local function bindStableFolder(folder)
    if not folder or not folder:IsA("Folder") or folder.Name ~= STABLE_FOLDER_NAME or boundFolders[folder] then return end
    boundFolders[folder] = true
    for _, child in ipairs(folder:GetChildren()) do
        task.defer(refine, child)
    end
    folder.ChildAdded:Connect(function(child)
        -- Defer once so M5-C.1.3 has completed parenting. No periodic work follows.
        task.defer(refine, child)
    end)
end

local function bindShowcase(showcase)
    if not showcase or showcase.Name ~= "PublicShowcase" then return end
    local current = showcase:FindFirstChild(STABLE_FOLDER_NAME)
    if current then bindStableFolder(current) end
    showcase.ChildAdded:Connect(function(child)
        if child.Name == STABLE_FOLDER_NAME then bindStableFolder(child) end
    end)
end

local function bindStation(station)
    if not station or not station:IsA("Model") or string.sub(station.Name, 1, 8) ~= "Station_" then return end
    local showcase = station:FindFirstChild("PublicShowcase")
    if showcase then bindShowcase(showcase) end
    station.ChildAdded:Connect(function(child)
        if child.Name == "PublicShowcase" then bindShowcase(child) end
    end)
end

local function bindWorld(world)
    if not world or world.Name ~= "LostAndFoundM4D" then return end
    for _, station in ipairs(world:GetChildren()) do bindStation(station) end
    world.ChildAdded:Connect(bindStation)
end

local world = workspace:FindFirstChild("LostAndFoundM4D")
if world then task.defer(bindWorld, world) end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then task.defer(bindWorld, child) end
end)
