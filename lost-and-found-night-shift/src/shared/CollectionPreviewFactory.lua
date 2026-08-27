local CollectionPreviewFactory = {}

local COLORS = {
    Dark = Color3.fromRGB(31, 34, 40),
    Metal = Color3.fromRGB(73, 79, 88),
    Leather = Color3.fromRGB(86, 55, 38),
    Cardboard = Color3.fromRGB(150, 112, 72),
    Tape = Color3.fromRGB(208, 187, 137),
}

local VARIANTS = {
    blue_transit_hardcase = { base = "hardcase_suitcase", color = Color3.fromRGB(41, 72, 112) },
    crimson_travel_backpack = { base = "backpack", color = Color3.fromRGB(122, 44, 48) },
    cream_memory_bear = { base = "teddy_bear", color = Color3.fromRGB(182, 151, 113) },
    brown_heritage_case = { base = "vintage_suitcase", color = Color3.fromRGB(100, 68, 45) },
    black_security_hardcase = { base = "hardcase_suitcase", color = Color3.fromRGB(35, 38, 43) },
    ownerless_vintage_case = { base = "vintage_suitcase", color = Color3.fromRGB(70, 45, 36) },
    flight_000_hardcase = { base = "hardcase_suitcase", color = Color3.fromRGB(24, 28, 36) },
    unstable_sealed_parcel = { base = "cardboard_box", color = Color3.fromRGB(147, 108, 70) },
    green_identity_backpack = { base = "backpack", color = Color3.fromRGB(55, 82, 66) },
    milo_small_case = { base = "vintage_suitcase", color = Color3.fromRGB(86, 58, 43), scale = 0.82 },

    hardcase_suitcase = { base = "hardcase_suitcase", color = Color3.fromRGB(41, 72, 112) },
    vintage_suitcase = { base = "vintage_suitcase", color = Color3.fromRGB(100, 68, 45) },
    backpack = { base = "backpack", color = Color3.fromRGB(122, 44, 48) },
    cardboard_box = { base = "cardboard_box", color = Color3.fromRGB(147, 108, 70) },
    teddy_bear = { base = "teddy_bear", color = Color3.fromRGB(182, 151, 113) },
}

local function makePart(model, name, size, cframe, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    if shape then p.Shape = shape end
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = model
    return p
end

local function child(model, root, name, size, offset, color, material, shape)
    return makePart(model, name, size, root.CFrame * offset, color, material, shape)
end

local function buildHardcase(model, color)
    local root = makePart(model, "Body", Vector3.new(5.6, 3.8, 2.35), CFrame.new(), color, Enum.Material.SmoothPlastic)
    for x = -2.0, 2.0, 1.0 do
        child(model, root, "ShellRib", Vector3.new(0.14, 3.25, 0.16), CFrame.new(x, 0, -1.2), Color3.fromRGB(24, 27, 33), Enum.Material.Metal)
    end
    child(model, root, "TopHandle", Vector3.new(2.1, 0.28, 0.34), CFrame.new(0, 2.05, 0), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "HandlePostL", Vector3.new(0.22, 1.05, 0.22), CFrame.new(-0.85, 1.6, 0), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "HandlePostR", Vector3.new(0.22, 1.05, 0.22), CFrame.new(0.85, 1.6, 0), COLORS.Dark, Enum.Material.Metal)
    for _, x in ipairs({-2.1, 2.1}) do
        makePart(model, "Wheel", Vector3.new(0.5, 0.5, 0.5), root.CFrame * CFrame.new(x, -2.0, 0.75), Color3.fromRGB(18, 20, 24), Enum.Material.Metal, Enum.PartType.Ball)
    end
    model.PrimaryPart = root
end

local function buildVintage(model, color)
    local root = makePart(model, "Body", Vector3.new(5.2, 3.35, 2.25), CFrame.new(), color, Enum.Material.Wood)
    child(model, root, "LeatherBandL", Vector3.new(0.35, 3.45, 2.34), CFrame.new(-1.55, 0, 0), COLORS.Leather, Enum.Material.SmoothPlastic)
    child(model, root, "LeatherBandR", Vector3.new(0.35, 3.45, 2.34), CFrame.new(1.55, 0, 0), COLORS.Leather, Enum.Material.SmoothPlastic)
    child(model, root, "LatchL", Vector3.new(0.5, 0.52, 0.2), CFrame.new(-1.0, 0.35, -1.2), Color3.fromRGB(180, 139, 62), Enum.Material.Metal)
    child(model, root, "LatchR", Vector3.new(0.5, 0.52, 0.2), CFrame.new(1.0, 0.35, -1.2), Color3.fromRGB(180, 139, 62), Enum.Material.Metal)
    child(model, root, "TopHandle", Vector3.new(1.8, 0.3, 0.38), CFrame.new(0, 1.95, 0), COLORS.Leather, Enum.Material.SmoothPlastic)
    model.PrimaryPart = root
end

local function buildBackpack(model, color)
    local root = makePart(model, "Body", Vector3.new(4.2, 4.8, 2.05), CFrame.new(), color, Enum.Material.Fabric)
    child(model, root, "FrontPocket", Vector3.new(3.3, 1.75, 0.7), CFrame.new(0, -0.9, -1.35), color:Lerp(Color3.fromRGB(20, 22, 26), 0.2), Enum.Material.Fabric)
    child(model, root, "TopCap", Vector3.new(3.7, 1.1, 1.9), CFrame.new(0, 2.2, 0), color, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "GrabHandle", Vector3.new(1.55, 0.24, 0.3), CFrame.new(0, 2.75, 0.55), COLORS.Dark, Enum.Material.SmoothPlastic)
    child(model, root, "StrapL", Vector3.new(0.35, 3.6, 0.28), CFrame.new(-1.15, 0, 1.17), Color3.fromRGB(32, 35, 40), Enum.Material.Fabric)
    child(model, root, "StrapR", Vector3.new(0.35, 3.6, 0.28), CFrame.new(1.15, 0, 1.17), Color3.fromRGB(32, 35, 40), Enum.Material.Fabric)
    model.PrimaryPart = root
end

local function buildCardboard(model, color)
    local root = makePart(model, "Body", Vector3.new(5.15, 3.45, 3.25), CFrame.new(), color or COLORS.Cardboard, Enum.Material.SmoothPlastic)
    child(model, root, "TapeLong", Vector3.new(0.65, 3.55, 3.35), CFrame.new(), COLORS.Tape, Enum.Material.SmoothPlastic)
    child(model, root, "TapeCross", Vector3.new(5.25, 0.58, 3.35), CFrame.new(0, 0.45, 0), COLORS.Tape, Enum.Material.SmoothPlastic)
    child(model, root, "LabelPlate", Vector3.new(2.25, 1.15, 0.1), CFrame.new(-0.75, 0.35, -1.68), Color3.fromRGB(224, 220, 205), Enum.Material.SmoothPlastic)
    model.PrimaryPart = root
end

local function buildTeddy(model, color)
    local root = makePart(model, "Body", Vector3.new(3.25, 3.25, 3.0), CFrame.new(), color, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "Head", Vector3.new(2.8, 2.8, 2.65), CFrame.new(0, 2.55, -0.15), color, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "EarL", Vector3.new(1.1, 1.1, 0.75), CFrame.new(-1.15, 3.45, 0), color:Lerp(Color3.fromRGB(90, 60, 45), 0.12), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "EarR", Vector3.new(1.1, 1.1, 0.75), CFrame.new(1.15, 3.45, 0), color:Lerp(Color3.fromRGB(90, 60, 45), 0.12), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "Muzzle", Vector3.new(1.35, 0.95, 0.65), CFrame.new(0, 2.25, -1.35), Color3.fromRGB(210, 184, 151), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "ArmL", Vector3.new(1.15, 2.6, 1.15), CFrame.new(-1.7, 0.45, 0) * CFrame.Angles(0, 0, math.rad(-22)), color, Enum.Material.Fabric)
    child(model, root, "ArmR", Vector3.new(1.15, 2.6, 1.15), CFrame.new(1.7, 0.45, 0) * CFrame.Angles(0, 0, math.rad(22)), color, Enum.Material.Fabric)
    child(model, root, "LegL", Vector3.new(1.35, 2.1, 1.45), CFrame.new(-0.9, -2.0, 0.2), color, Enum.Material.Fabric)
    child(model, root, "LegR", Vector3.new(1.35, 2.1, 1.45), CFrame.new(0.9, -2.0, 0.2), color, Enum.Material.Fabric)
    child(model, root, "EyeL", Vector3.new(0.25, 0.25, 0.18), CFrame.new(-0.55, 2.85, -1.33), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    child(model, root, "EyeR", Vector3.new(0.25, 0.25, 0.18), CFrame.new(0.55, 2.85, -1.33), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    model.PrimaryPart = root
end

local BUILDERS = {
    hardcase_suitcase = buildHardcase,
    vintage_suitcase = buildVintage,
    backpack = buildBackpack,
    cardboard_box = buildCardboard,
    teddy_bear = buildTeddy,
}

function CollectionPreviewFactory.Create(collectionId, parent, locked)
    local model = Instance.new("Model")
    model.Name = "Preview_" .. tostring(collectionId)
    model.Parent = parent

    local variant = VARIANTS[collectionId] or { base = "hardcase_suitcase", color = Color3.fromRGB(90, 96, 108) }
    local builder = BUILDERS[variant.base] or buildHardcase
    builder(model, variant.color)

    if variant.scale then
        model:ScaleTo(variant.scale)
    end

    if locked then
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Color = Color3.fromRGB(53, 59, 68)
                descendant.Material = Enum.Material.SmoothPlastic
                descendant.Transparency = 0.1
            end
        end
    end

    -- Front details are built toward -Z. Rotate the model so that face points
    -- toward the collection camera (+X/+Z), while keeping a slight 3/4 angle.
    model:PivotTo(CFrame.Angles(math.rad(-6), math.rad(-148), 0))
    return model
end

return CollectionPreviewFactory
