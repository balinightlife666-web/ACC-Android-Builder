-- LOST & FOUND: NIGHT SHIFT — M5-C collectible 3D quality pass v1.
-- Shared Roblox-only preview factory used by Collection Index and personal station showcase.
-- No external images/textures/assets; visual/presentation only.

local CollectionPreviewFactory = {}

local COLORS = {
    Dark = Color3.fromRGB(28, 31, 37),
    Dark2 = Color3.fromRGB(43, 47, 54),
    Metal = Color3.fromRGB(83, 89, 99),
    Silver = Color3.fromRGB(151, 158, 169),
    Leather = Color3.fromRGB(88, 58, 40),
    LeatherDark = Color3.fromRGB(58, 38, 29),
    Brass = Color3.fromRGB(177, 137, 62),
    Cardboard = Color3.fromRGB(150, 112, 72),
    Tape = Color3.fromRGB(208, 187, 137),
    Paper = Color3.fromRGB(218, 211, 191),
    Ink = Color3.fromRGB(31, 33, 37),
    Cyan = Color3.fromRGB(85, 216, 221),
    Gold = Color3.fromRGB(217, 181, 78),
    Violet = Color3.fromRGB(170, 119, 211),
    Red = Color3.fromRGB(186, 64, 59),
}

local VARIANTS = {
    blue_transit_hardcase = { base = "hardcase_suitcase", color = Color3.fromRGB(41, 72, 112), rarity = "COMMON" },
    crimson_travel_backpack = { base = "backpack", color = Color3.fromRGB(122, 44, 48), rarity = "UNCOMMON" },
    cream_memory_bear = { base = "teddy_bear", color = Color3.fromRGB(182, 151, 113), rarity = "RARE" },
    brown_heritage_case = { base = "vintage_suitcase", color = Color3.fromRGB(100, 68, 45), rarity = "UNCOMMON" },
    black_security_hardcase = { base = "hardcase_suitcase", color = Color3.fromRGB(35, 38, 43), rarity = "RARE" },
    ownerless_vintage_case = { base = "vintage_suitcase", color = Color3.fromRGB(70, 45, 36), rarity = "ANOMALY" },
    flight_000_hardcase = { base = "hardcase_suitcase", color = Color3.fromRGB(24, 28, 36), rarity = "SECRET" },
    unstable_sealed_parcel = { base = "cardboard_box", color = Color3.fromRGB(147, 108, 70), rarity = "ANOMALY" },
    green_identity_backpack = { base = "backpack", color = Color3.fromRGB(55, 82, 66), rarity = "EPIC" },
    milo_small_case = { base = "vintage_suitcase", color = Color3.fromRGB(86, 58, 43), rarity = "SECRET", scale = 0.82 },
    silver_camera_lens = { base = "camera_lens", color = Color3.fromRGB(82, 88, 98), rarity = "RARE" },
    ownerless_tag_00017284 = { base = "evidence_tag", color = Color3.fromRGB(104, 80, 57), rarity = "ANOMALY" },
    flight_000_boarding_tag = { base = "evidence_tag", color = Color3.fromRGB(55, 67, 82), rarity = "SECRET" },
    duplicate_passport = { base = "passport", color = Color3.fromRGB(67, 42, 58), rarity = "EPIC" },
    milo_toy_train_2001 = { base = "toy_train", color = Color3.fromRGB(112, 42, 38), rarity = "SECRET" },
    maya_power_adapter = { base = "power_adapter", color = Color3.fromRGB(224, 224, 218), rarity = "UNCOMMON" },
    daniel_formal_shoe = { base = "formal_shoe", color = Color3.fromRGB(38, 35, 34), rarity = "RARE" },
    sofia_name_patch = { base = "name_patch", color = Color3.fromRGB(196, 169, 133), rarity = "RARE" },
    ari_red_paperback = { base = "paperback", color = Color3.fromRGB(132, 47, 44), rarity = "UNCOMMON" },
    unstable_mass_readout = { base = "mass_readout", color = Color3.fromRGB(57, 65, 76), rarity = "ANOMALY" },

    hardcase_suitcase = { base = "hardcase_suitcase", color = Color3.fromRGB(41, 72, 112), rarity = "COMMON" },
    vintage_suitcase = { base = "vintage_suitcase", color = Color3.fromRGB(100, 68, 45), rarity = "UNCOMMON" },
    backpack = { base = "backpack", color = Color3.fromRGB(122, 44, 48), rarity = "UNCOMMON" },
    cardboard_box = { base = "cardboard_box", color = Color3.fromRGB(147, 108, 70), rarity = "COMMON" },
    teddy_bear = { base = "teddy_bear", color = Color3.fromRGB(182, 151, 113), rarity = "RARE" },
}

local function makePart(model, name, size, cframe, color, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = true
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    if shape then part.Shape = shape end
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = model
    return part
end

local function child(model, root, name, size, offset, color, material, shape)
    return makePart(model, name, size, root.CFrame * offset, color, material, shape)
end

local function thinBar(model, root, name, size, offset, color, material)
    return child(model, root, name, size, offset, color, material or Enum.Material.Metal)
end

local function buildHardcase(model, color)
    local root = makePart(model, "Body", Vector3.new(5.6, 3.8, 2.35), CFrame.new(), color, Enum.Material.SmoothPlastic)
    child(model, root, "RearShell", Vector3.new(5.35, 3.55, 0.18), CFrame.new(0, 0, 1.24), color:Lerp(COLORS.Dark, 0.12), Enum.Material.SmoothPlastic)
    for x = -2, 2 do
        thinBar(model, root, "ShellRib" .. tostring(x), Vector3.new(0.14, 3.25, 0.16), CFrame.new(x, 0, -1.20), COLORS.Dark, Enum.Material.Metal)
    end
    thinBar(model, root, "EdgeTop", Vector3.new(5.22, 0.13, 0.16), CFrame.new(0, 1.66, -1.20), COLORS.Dark, Enum.Material.Metal)
    thinBar(model, root, "EdgeBottom", Vector3.new(5.22, 0.13, 0.16), CFrame.new(0, -1.66, -1.20), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "TopHandle", Vector3.new(2.05, 0.26, 0.34), CFrame.new(0, 2.06, 0.18), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "HandlePostL", Vector3.new(0.22, 0.95, 0.22), CFrame.new(-0.83, 1.64, 0.18), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "HandlePostR", Vector3.new(0.22, 0.95, 0.22), CFrame.new(0.83, 1.64, 0.18), COLORS.Dark, Enum.Material.Metal)
    for _, x in ipairs({-2.2, 2.2}) do
        child(model, root, "Wheel" .. tostring(x), Vector3.new(0.55, 0.55, 0.55), CFrame.new(x, -2.00, 0.76), Color3.fromRGB(18, 20, 24), Enum.Material.Metal, Enum.PartType.Ball)
        child(model, root, "CornerTop" .. tostring(x), Vector3.new(0.42, 0.42, 0.28), CFrame.new(x, 1.52, -1.18), COLORS.Metal, Enum.Material.Metal)
        child(model, root, "CornerBottom" .. tostring(x), Vector3.new(0.42, 0.42, 0.28), CFrame.new(x, -1.52, -1.18), COLORS.Metal, Enum.Material.Metal)
    end
    child(model, root, "LockPlate", Vector3.new(1.05, 0.42, 0.14), CFrame.new(0, 0.10, -1.25), COLORS.Metal, Enum.Material.Metal)
    child(model, root, "LockDot", Vector3.new(0.18, 0.18, 0.10), CFrame.new(0, 0.10, -1.34), Color3.fromRGB(190, 194, 199), Enum.Material.Metal, Enum.PartType.Ball)
    model.PrimaryPart = root
end

local function buildVintage(model, color)
    local root = makePart(model, "Body", Vector3.new(5.2, 3.35, 2.25), CFrame.new(), color, Enum.Material.Wood)
    child(model, root, "FrontPanel", Vector3.new(4.72, 2.9, 0.18), CFrame.new(0, 0, -1.18), color:Lerp(Color3.fromRGB(150, 112, 74), 0.12), Enum.Material.Wood)
    child(model, root, "LeatherBandL", Vector3.new(0.34, 3.45, 2.34), CFrame.new(-1.55, 0, 0), COLORS.Leather, Enum.Material.Fabric)
    child(model, root, "LeatherBandR", Vector3.new(0.34, 3.45, 2.34), CFrame.new(1.55, 0, 0), COLORS.Leather, Enum.Material.Fabric)
    thinBar(model, root, "PipingTop", Vector3.new(5.12, 0.15, 0.18), CFrame.new(0, 1.52, -1.18), COLORS.LeatherDark, Enum.Material.Fabric)
    thinBar(model, root, "PipingBottom", Vector3.new(5.12, 0.15, 0.18), CFrame.new(0, -1.52, -1.18), COLORS.LeatherDark, Enum.Material.Fabric)
    child(model, root, "LatchL", Vector3.new(0.52, 0.56, 0.20), CFrame.new(-1.00, 0.32, -1.22), COLORS.Brass, Enum.Material.Metal)
    child(model, root, "LatchR", Vector3.new(0.52, 0.56, 0.20), CFrame.new(1.00, 0.32, -1.22), COLORS.Brass, Enum.Material.Metal)
    child(model, root, "Handle", Vector3.new(1.85, 0.28, 0.36), CFrame.new(0, 1.97, 0.08), COLORS.LeatherDark, Enum.Material.Fabric)
    child(model, root, "HandleMountL", Vector3.new(0.32, 0.55, 0.32), CFrame.new(-0.75, 1.70, 0.08), COLORS.Brass, Enum.Material.Metal)
    child(model, root, "HandleMountR", Vector3.new(0.32, 0.55, 0.32), CFrame.new(0.75, 1.70, 0.08), COLORS.Brass, Enum.Material.Metal)
    for _, x in ipairs({-2.25, 2.25}) do
        for _, y in ipairs({-1.37, 1.37}) do
            child(model, root, "Corner", Vector3.new(0.46, 0.42, 0.24), CFrame.new(x, y, -1.18), COLORS.Brass, Enum.Material.Metal)
        end
    end
    model.PrimaryPart = root
end

local function buildBackpack(model, color)
    local root = makePart(model, "Body", Vector3.new(4.15, 4.7, 2.05), CFrame.new(), color, Enum.Material.Fabric)
    child(model, root, "TopCap", Vector3.new(3.72, 1.20, 1.92), CFrame.new(0, 2.05, 0), color:Lerp(Color3.new(1,1,1), 0.05), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "FrontPocket", Vector3.new(3.28, 1.72, 0.72), CFrame.new(0, -0.93, -1.34), color:Lerp(COLORS.Dark, 0.18), Enum.Material.Fabric)
    thinBar(model, root, "PocketZipper", Vector3.new(2.72, 0.12, 0.12), CFrame.new(0, -0.25, -1.72), COLORS.Silver, Enum.Material.Metal)
    thinBar(model, root, "MainZipper", Vector3.new(3.15, 0.12, 0.12), CFrame.new(0, 1.60, -1.10), COLORS.Silver, Enum.Material.Metal)
    child(model, root, "GrabHandle", Vector3.new(1.55, 0.24, 0.30), CFrame.new(0, 2.68, 0.55), COLORS.Dark, Enum.Material.Fabric)
    child(model, root, "StrapL", Vector3.new(0.35, 3.55, 0.28), CFrame.new(-1.15, 0, 1.17), COLORS.Dark2, Enum.Material.Fabric)
    child(model, root, "StrapR", Vector3.new(0.35, 3.55, 0.28), CFrame.new(1.15, 0, 1.17), COLORS.Dark2, Enum.Material.Fabric)
    child(model, root, "SidePocketL", Vector3.new(0.58, 1.55, 1.35), CFrame.new(-2.18, -0.75, 0.18), color:Lerp(COLORS.Dark, 0.22), Enum.Material.Fabric)
    child(model, root, "SidePocketR", Vector3.new(0.58, 1.55, 1.35), CFrame.new(2.18, -0.75, 0.18), color:Lerp(COLORS.Dark, 0.22), Enum.Material.Fabric)
    child(model, root, "BuckleL", Vector3.new(0.42, 0.48, 0.20), CFrame.new(-1.05, -1.65, -1.38), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "BuckleR", Vector3.new(0.42, 0.48, 0.20), CFrame.new(1.05, -1.65, -1.38), COLORS.Dark, Enum.Material.Metal)
    model.PrimaryPart = root
end

local function buildCardboard(model, color)
    local root = makePart(model, "Body", Vector3.new(5.15, 3.45, 3.25), CFrame.new(), color or COLORS.Cardboard, Enum.Material.SmoothPlastic)
    child(model, root, "TopFlap", Vector3.new(4.90, 0.12, 3.03), CFrame.new(0, 1.78, 0), color:Lerp(Color3.new(1,1,1), 0.04), Enum.Material.SmoothPlastic)
    child(model, root, "TapeLong", Vector3.new(0.62, 3.55, 3.35), CFrame.new(), COLORS.Tape, Enum.Material.SmoothPlastic)
    child(model, root, "TapeCross", Vector3.new(5.25, 0.56, 3.35), CFrame.new(0, 0.45, 0), COLORS.Tape, Enum.Material.SmoothPlastic)
    child(model, root, "LabelPlate", Vector3.new(2.35, 1.20, 0.11), CFrame.new(-0.72, 0.35, -1.68), Color3.fromRGB(226, 222, 207), Enum.Material.SmoothPlastic)
    for i = -1, 1 do
        thinBar(model, root, "LabelLine" .. i, Vector3.new(1.65 - math.abs(i) * 0.25, 0.09, 0.07), CFrame.new(-0.72, 0.35 + i * 0.28, -1.76), Color3.fromRGB(82, 77, 70), Enum.Material.SmoothPlastic)
    end
    for _, x in ipairs({-2.38, 2.38}) do
        thinBar(model, root, "Edge" .. x, Vector3.new(0.10, 3.10, 0.10), CFrame.new(x, 0, -1.66), color:Lerp(COLORS.Dark, 0.25), Enum.Material.SmoothPlastic)
    end
    model.PrimaryPart = root
end

local function buildTeddy(model, color)
    local root = makePart(model, "Body", Vector3.new(3.15, 3.35, 2.85), CFrame.new(), color, Enum.Material.Fabric, Enum.PartType.Ball)
    local head = child(model, root, "Head", Vector3.new(2.85, 2.85, 2.65), CFrame.new(0, 2.62, -0.15), color, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "EarL", Vector3.new(1.10, 1.10, 0.72), CFrame.new(-1.15, 3.50, -0.02), color, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "EarR", Vector3.new(1.10, 1.10, 0.72), CFrame.new(1.15, 3.50, -0.02), color, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "InnerEarL", Vector3.new(0.58, 0.58, 0.18), CFrame.new(-1.15, 3.50, -0.43), color:Lerp(Color3.fromRGB(224, 190, 164), 0.38), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "InnerEarR", Vector3.new(0.58, 0.58, 0.18), CFrame.new(1.15, 3.50, -0.43), color:Lerp(Color3.fromRGB(224, 190, 164), 0.38), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "Muzzle", Vector3.new(1.38, 1.00, 0.70), CFrame.new(0, 2.25, -1.37), Color3.fromRGB(211, 185, 152), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "Nose", Vector3.new(0.42, 0.32, 0.22), CFrame.new(0, 2.48, -1.76), Color3.fromRGB(54, 43, 38), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    child(model, root, "EyeL", Vector3.new(0.26, 0.26, 0.18), CFrame.new(-0.55, 2.92, -1.35), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    child(model, root, "EyeR", Vector3.new(0.26, 0.26, 0.18), CFrame.new(0.55, 2.92, -1.35), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    child(model, root, "ArmL", Vector3.new(1.08, 2.55, 1.08), CFrame.new(-1.70, 0.42, 0) * CFrame.Angles(0, 0, math.rad(-23)), color, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "ArmR", Vector3.new(1.08, 2.55, 1.08), CFrame.new(1.70, 0.42, 0) * CFrame.Angles(0, 0, math.rad(23)), color, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "LegL", Vector3.new(1.35, 2.05, 1.45), CFrame.new(-0.88, -2.00, 0.20), color, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "LegR", Vector3.new(1.35, 2.05, 1.45), CFrame.new(0.88, -2.00, 0.20), color, Enum.Material.Fabric, Enum.PartType.Ball)
    thinBar(model, root, "BellySeam", Vector3.new(0.10, 1.85, 0.10), CFrame.new(0, -0.10, -1.43), color:Lerp(COLORS.Dark, 0.35), Enum.Material.Fabric)
    thinBar(model, head, "Mouth", Vector3.new(0.62, 0.08, 0.08), CFrame.new(0, -0.62, -1.39), Color3.fromRGB(77, 54, 47), Enum.Material.SmoothPlastic)
    model.PrimaryPart = root
end

local function buildCameraLens(model, color)
    local root = makePart(model, "LensBody", Vector3.new(3.10, 3.10, 2.55), CFrame.new() * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Metal, Enum.PartType.Cylinder)
    child(model, root, "RearMount", Vector3.new(0.28, 2.72, 2.72), CFrame.new(1.48, 0, 0), COLORS.Silver, Enum.Material.Metal, Enum.PartType.Cylinder)
    child(model, root, "FocusRing", Vector3.new(0.82, 3.38, 3.38), CFrame.new(0.30, 0, 0), COLORS.Dark, Enum.Material.Metal, Enum.PartType.Cylinder)
    child(model, root, "ZoomRing", Vector3.new(0.68, 3.28, 3.28), CFrame.new(-0.48, 0, 0), Color3.fromRGB(47, 51, 58), Enum.Material.Metal, Enum.PartType.Cylinder)
    child(model, root, "SilverRing", Vector3.new(0.20, 3.05, 3.05), CFrame.new(-1.08, 0, 0), COLORS.Silver, Enum.Material.Metal, Enum.PartType.Cylinder)
    child(model, root, "FrontGlass", Vector3.new(0.22, 2.52, 2.52), CFrame.new(-1.31, 0, 0), Color3.fromRGB(45, 88, 112), Enum.Material.Glass, Enum.PartType.Cylinder)
    child(model, root, "InnerGlass", Vector3.new(0.08, 1.62, 1.62), CFrame.new(-1.44, 0, 0), Color3.fromRGB(24, 44, 58), Enum.Material.Glass, Enum.PartType.Cylinder)
    for i = -2, 2 do
        thinBar(model, root, "FocusMark" .. i, Vector3.new(0.08, 0.10, 0.52), CFrame.new(0.27, i * 0.43, -1.63), COLORS.Silver, Enum.Material.Metal)
    end
    model.PrimaryPart = root
end

local function buildEvidenceTag(model, color)
    local root = makePart(model, "Tag", Vector3.new(4.90, 2.80, 0.28), CFrame.new(), color, Enum.Material.SmoothPlastic)
    child(model, root, "Inset", Vector3.new(4.45, 2.35, 0.10), CFrame.new(0, 0, -0.19), color:Lerp(Color3.new(1,1,1), 0.10), Enum.Material.SmoothPlastic)
    thinBar(model, root, "Header", Vector3.new(4.12, 0.40, 0.10), CFrame.new(0, 0.82, -0.26), COLORS.Gold, Enum.Material.Metal)
    for i = -3, 3 do
        local width = (i % 2 == 0) and 0.15 or 0.09
        thinBar(model, root, "CodeBar" .. i, Vector3.new(width, 0.76, 0.08), CFrame.new(i * 0.43, -0.58, -0.27), COLORS.Ink, Enum.Material.SmoothPlastic)
    end
    child(model, root, "PunchOuter", Vector3.new(0.48, 0.48, 0.10), CFrame.new(-2.02, 0.91, -0.26), COLORS.Silver, Enum.Material.Metal, Enum.PartType.Ball)
    child(model, root, "PunchInner", Vector3.new(0.24, 0.24, 0.12), CFrame.new(-2.02, 0.91, -0.33), COLORS.Dark, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    thinBar(model, root, "RouteLineA", Vector3.new(1.45, 0.10, 0.08), CFrame.new(0.82, 0.18, -0.27), COLORS.Ink, Enum.Material.SmoothPlastic)
    thinBar(model, root, "RouteLineB", Vector3.new(1.00, 0.10, 0.08), CFrame.new(0.60, -0.05, -0.27), COLORS.Ink, Enum.Material.SmoothPlastic)
    model.PrimaryPart = root
end

local function buildPassport(model, color)
    local root = makePart(model, "Cover", Vector3.new(3.45, 4.62, 0.42), CFrame.new(), color, Enum.Material.SmoothPlastic)
    child(model, root, "BackCover", Vector3.new(3.38, 4.55, 0.22), CFrame.new(0.12, 0, 0.47), color:Lerp(COLORS.Dark, 0.16), Enum.Material.SmoothPlastic)
    child(model, root, "PageBlock", Vector3.new(3.04, 4.25, 0.30), CFrame.new(0.12, 0, 0.34), COLORS.Paper, Enum.Material.SmoothPlastic)
    child(model, root, "Spine", Vector3.new(0.28, 4.55, 0.56), CFrame.new(-1.58, 0, 0.06), color:Lerp(COLORS.Dark, 0.20), Enum.Material.SmoothPlastic)
    child(model, root, "SealOuter", Vector3.new(1.16, 1.16, 0.12), CFrame.new(0, 0.52, -0.28), COLORS.Gold, Enum.Material.Metal, Enum.PartType.Ball)
    child(model, root, "SealInner", Vector3.new(0.60, 0.60, 0.10), CFrame.new(0, 0.52, -0.36), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    thinBar(model, root, "GoldLineTop", Vector3.new(2.25, 0.15, 0.09), CFrame.new(0, -1.25, -0.29), COLORS.Gold, Enum.Material.Metal)
    thinBar(model, root, "GoldLineBottom", Vector3.new(1.55, 0.10, 0.08), CFrame.new(0, -1.53, -0.29), COLORS.Gold, Enum.Material.Metal)
    for i = -1, 1 do
        thinBar(model, root, "PageEdge" .. i, Vector3.new(2.70, 0.05, 0.06), CFrame.new(0.15, -0.65 + i * 0.70, 0.52), Color3.fromRGB(188, 181, 161), Enum.Material.SmoothPlastic)
    end
    model.PrimaryPart = root
end

local function buildToyTrain(model, color)
    local root = makePart(model, "Engine", Vector3.new(4.25, 2.05, 2.15), CFrame.new(), color, Enum.Material.Metal)
    child(model, root, "Cab", Vector3.new(1.78, 2.45, 2.02), CFrame.new(1.02, 1.50, 0), color:Lerp(COLORS.Dark, 0.05), Enum.Material.Metal)
    child(model, root, "CabWindowL", Vector3.new(0.55, 0.75, 0.08), CFrame.new(0.60, 1.63, -1.06), Color3.fromRGB(39, 54, 62), Enum.Material.Glass)
    child(model, root, "CabWindowR", Vector3.new(0.55, 0.75, 0.08), CFrame.new(1.38, 1.63, -1.06), Color3.fromRGB(39, 54, 62), Enum.Material.Glass)
    child(model, root, "Boiler", Vector3.new(2.85, 1.58, 1.58), CFrame.new(-1.38, 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Metal, Enum.PartType.Cylinder)
    child(model, root, "BoilerCap", Vector3.new(0.22, 1.78, 1.78), CFrame.new(-2.83, 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), COLORS.Brass, Enum.Material.Metal, Enum.PartType.Cylinder)
    child(model, root, "Chimney", Vector3.new(0.78, 1.75, 0.78), CFrame.new(-1.72, 1.78, 0), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "ChimneyCap", Vector3.new(1.08, 0.22, 1.08), CFrame.new(-1.72, 2.62, 0), COLORS.Dark2, Enum.Material.Metal)
    child(model, root, "Cowcatcher", Vector3.new(0.52, 0.58, 2.38), CFrame.new(-2.38, -0.65, 0), COLORS.Dark2, Enum.Material.Metal)
    for _, x in ipairs({-1.35, 1.22}) do
        for _, z in ipairs({-1.13, 1.13}) do
            child(model, root, "Wheel", Vector3.new(0.80, 0.80, 0.80), CFrame.new(x, -1.10, z), COLORS.Dark, Enum.Material.Metal, Enum.PartType.Ball)
        end
    end
    thinBar(model, root, "SideRod", Vector3.new(3.10, 0.14, 0.14), CFrame.new(0, -1.10, -1.50), COLORS.Brass, Enum.Material.Metal)
    model.PrimaryPart = root
end

local function buildPowerAdapter(model, color)
    local root = makePart(model, "Adapter", Vector3.new(3.20, 2.45, 1.55), CFrame.new(), color, Enum.Material.SmoothPlastic)
    child(model, root, "Inset", Vector3.new(2.35, 1.50, 0.12), CFrame.new(0, 0, -0.84), Color3.fromRGB(182, 184, 180), Enum.Material.SmoothPlastic)
    child(model, root, "ProngL", Vector3.new(0.28, 1.20, 0.28), CFrame.new(-0.65, 1.70, 0.15), COLORS.Silver, Enum.Material.Metal)
    child(model, root, "ProngR", Vector3.new(0.28, 1.20, 0.28), CFrame.new(0.65, 1.70, 0.15), COLORS.Silver, Enum.Material.Metal)
    child(model, root, "Port", Vector3.new(1.15, 0.48, 0.18), CFrame.new(0, -0.55, -0.88), COLORS.Dark, Enum.Material.SmoothPlastic)
    thinBar(model, root, "Seam", Vector3.new(3.02, 0.10, 0.08), CFrame.new(0, 0.85, -0.83), Color3.fromRGB(156, 158, 158), Enum.Material.SmoothPlastic)
    for i = -2, 2 do
        thinBar(model, root, "Vent" .. i, Vector3.new(0.10, 0.70, 0.08), CFrame.new(i * 0.42, 0.05, 0.84), Color3.fromRGB(151, 153, 153), Enum.Material.SmoothPlastic)
    end
    child(model, root, "CableNeck", Vector3.new(0.42, 0.42, 0.60), CFrame.new(1.18, -0.70, 0.82), COLORS.Dark2, Enum.Material.SmoothPlastic)
    model.PrimaryPart = root
end

local function buildFormalShoe(model, color)
    local root = makePart(model, "Sole", Vector3.new(5.35, 0.55, 2.05), CFrame.new(), Color3.fromRGB(25, 24, 24), Enum.Material.SmoothPlastic)
    child(model, root, "Midsole", Vector3.new(5.15, 0.32, 1.92), CFrame.new(-0.05, 0.35, 0), Color3.fromRGB(58, 53, 48), Enum.Material.SmoothPlastic)
    child(model, root, "Upper", Vector3.new(3.35, 1.42, 1.82), CFrame.new(0.20, 1.02, -0.04), color, Enum.Material.SmoothPlastic)
    child(model, root, "Toe", Vector3.new(2.25, 1.35, 1.90), CFrame.new(-1.72, 0.86, -0.04), color:Lerp(Color3.new(1,1,1), 0.03), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    child(model, root, "HeelQuarter", Vector3.new(1.28, 1.72, 1.80), CFrame.new(2.00, 1.08, 0), color, Enum.Material.SmoothPlastic)
    child(model, root, "HeelBlock", Vector3.new(0.88, 0.58, 1.65), CFrame.new(2.15, -0.48, 0), Color3.fromRGB(30, 28, 27), Enum.Material.SmoothPlastic)
    child(model, root, "Tongue", Vector3.new(1.38, 1.68, 0.22), CFrame.new(0.58, 1.58, -0.93) * CFrame.Angles(math.rad(-12), 0, 0), color:Lerp(Color3.new(1,1,1), 0.07), Enum.Material.SmoothPlastic)
    for i = -2, 2 do
        thinBar(model, root, "Lace" .. i, Vector3.new(1.36, 0.08, 0.08), CFrame.new(0.48 + i * 0.02, 1.40 + i * 0.17, -1.05), Color3.fromRGB(128, 119, 106), Enum.Material.Fabric)
    end
    thinBar(model, root, "Welt", Vector3.new(4.75, 0.10, 0.08), CFrame.new(-0.20, 0.58, -1.03), Color3.fromRGB(103, 89, 75), Enum.Material.SmoothPlastic)
    model.PrimaryPart = root
end

local function buildNamePatch(model, color)
    local root = makePart(model, "Patch", Vector3.new(4.90, 2.60, 0.22), CFrame.new(), color, Enum.Material.Fabric)
    child(model, root, "Inset", Vector3.new(4.45, 2.15, 0.08), CFrame.new(0, 0, -0.17), color:Lerp(Color3.new(1,1,1), 0.04), Enum.Material.Fabric)
    for _, x in ipairs({-2.20, 2.20}) do thinBar(model, root, "StitchV", Vector3.new(0.11, 2.20, 0.08), CFrame.new(x, 0, -0.17), Color3.fromRGB(108, 75, 52), Enum.Material.Fabric) end
    for _, y in ipairs({-1.05, 1.05}) do thinBar(model, root, "StitchH", Vector3.new(4.38, 0.11, 0.08), CFrame.new(0, y, -0.17), Color3.fromRGB(108, 75, 52), Enum.Material.Fabric) end
    thinBar(model, root, "NameBarA", Vector3.new(2.72, 0.28, 0.09), CFrame.new(0, 0.35, -0.21), Color3.fromRGB(65, 54, 46), Enum.Material.Fabric)
    thinBar(model, root, "NameBarB", Vector3.new(1.82, 0.22, 0.09), CFrame.new(-0.45, -0.35, -0.21), Color3.fromRGB(65, 54, 46), Enum.Material.Fabric)
    for i = -3, 3 do
        child(model, root, "Thread" .. i, Vector3.new(0.07, 0.07, 0.07), CFrame.new(i * 0.48, -0.84, -0.23), Color3.fromRGB(125, 82, 54), Enum.Material.Fabric, Enum.PartType.Ball)
    end
    model.PrimaryPart = root
end

local function buildPaperback(model, color)
    local root = makePart(model, "Cover", Vector3.new(3.62, 5.02, 0.48), CFrame.new(), color, Enum.Material.SmoothPlastic)
    child(model, root, "BackCover", Vector3.new(3.55, 4.95, 0.18), CFrame.new(0.12, 0, 0.49), color:Lerp(COLORS.Dark, 0.16), Enum.Material.SmoothPlastic)
    child(model, root, "Pages", Vector3.new(3.25, 4.64, 0.38), CFrame.new(0.13, 0, 0.35), Color3.fromRGB(218, 208, 180), Enum.Material.SmoothPlastic)
    child(model, root, "Spine", Vector3.new(0.36, 5.02, 0.66), CFrame.new(-1.64, 0, 0.05), color:Lerp(Color3.fromRGB(35, 28, 26), 0.20), Enum.Material.SmoothPlastic)
    thinBar(model, root, "TitleBand", Vector3.new(2.45, 0.35, 0.10), CFrame.new(0.15, 1.25, -0.30), Color3.fromRGB(230, 195, 110), Enum.Material.Metal)
    thinBar(model, root, "Subtitle", Vector3.new(1.72, 0.12, 0.08), CFrame.new(0.15, 0.82, -0.31), Color3.fromRGB(220, 207, 173), Enum.Material.SmoothPlastic)
    for i = -2, 2 do
        thinBar(model, root, "PageLine" .. i, Vector3.new(2.76, 0.05, 0.05), CFrame.new(0.18, i * 0.77, 0.57), Color3.fromRGB(187, 177, 149), Enum.Material.SmoothPlastic)
    end
    model.PrimaryPart = root
end

local function buildMassReadout(model, color)
    local root = makePart(model, "Meter", Vector3.new(5.10, 3.30, 1.05), CFrame.new(), color, Enum.Material.Metal)
    child(model, root, "Bezel", Vector3.new(4.20, 2.12, 0.16), CFrame.new(-0.18, 0.32, -0.59), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "Screen", Vector3.new(3.70, 1.55, 0.14), CFrame.new(-0.25, 0.43, -0.70), Color3.fromRGB(13, 25, 31), Enum.Material.Glass)
    for i = -3, 3 do
        local h = 0.16 + ((i * i + 2) % 4) * 0.08
        thinBar(model, root, "Wave" .. i, Vector3.new(0.25, h, 0.08), CFrame.new(-0.35 + i * 0.38, 0.42, -0.80), COLORS.Cyan, Enum.Material.Neon)
    end
    for i = 0, 2 do
        child(model, root, "Key" .. i, Vector3.new(0.58, 0.40, 0.12), CFrame.new(-1.00 + i, -0.86, -0.62), Color3.fromRGB(126, 134, 146), Enum.Material.Metal)
    end
    child(model, root, "WarningOuter", Vector3.new(0.78, 0.78, 0.10), CFrame.new(1.84, 0.45, -0.66), Color3.fromRGB(205, 144, 56), Enum.Material.Neon, Enum.PartType.Ball)
    child(model, root, "WarningInner", Vector3.new(0.34, 0.34, 0.10), CFrame.new(1.84, 0.45, -0.74), COLORS.Dark, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    for i = -2, 2 do
        thinBar(model, root, "Vent" .. i, Vector3.new(0.10, 0.62, 0.08), CFrame.new(1.92, -0.78 + i * 0.22, 0.55), COLORS.Dark2, Enum.Material.Metal)
    end
    model.PrimaryPart = root
end

local BUILDERS = {
    hardcase_suitcase = buildHardcase,
    vintage_suitcase = buildVintage,
    backpack = buildBackpack,
    cardboard_box = buildCardboard,
    teddy_bear = buildTeddy,
    camera_lens = buildCameraLens,
    evidence_tag = buildEvidenceTag,
    passport = buildPassport,
    toy_train = buildToyTrain,
    power_adapter = buildPowerAdapter,
    formal_shoe = buildFormalShoe,
    name_patch = buildNamePatch,
    paperback = buildPaperback,
    mass_readout = buildMassReadout,
}

local function detailPart(model, root, name, size, offset, color, material, shape)
    if not root then return nil end
    return child(model, root, "M5C_" .. name, size, offset, color, material, shape)
end

local function applyCollectionDetails(model, collectionId, variant)
    local root = model.PrimaryPart
    if not root then return end

    if collectionId == "blue_transit_hardcase" then
        detailPart(model, root, "TransitPlate", Vector3.new(1.55, 0.48, 0.10), CFrame.new(-1.35, 0.72, -1.29), Color3.fromRGB(188, 204, 217), Enum.Material.Metal)
        detailPart(model, root, "TransitBar", Vector3.new(0.72, 0.09, 0.08), CFrame.new(-1.35, 0.72, -1.36), Color3.fromRGB(51, 93, 144), Enum.Material.Metal)
    elseif collectionId == "crimson_travel_backpack" then
        detailPart(model, root, "TravelBadge", Vector3.new(1.18, 0.70, 0.10), CFrame.new(0.76, 0.65, -1.16), Color3.fromRGB(211, 172, 132), Enum.Material.Fabric)
        detailPart(model, root, "TravelBadgeLine", Vector3.new(0.72, 0.10, 0.08), CFrame.new(0.76, 0.65, -1.23), Color3.fromRGB(93, 52, 48), Enum.Material.Fabric)
    elseif collectionId == "cream_memory_bear" then
        detailPart(model, root, "Ribbon", Vector3.new(1.92, 0.25, 0.28), CFrame.new(0, 1.48, -1.00), Color3.fromRGB(116, 57, 54), Enum.Material.Fabric)
        detailPart(model, root, "BowL", Vector3.new(0.82, 0.62, 0.28), CFrame.new(-0.58, 1.35, -1.10) * CFrame.Angles(0, 0, math.rad(24)), Color3.fromRGB(129, 61, 59), Enum.Material.Fabric, Enum.PartType.Ball)
        detailPart(model, root, "BowR", Vector3.new(0.82, 0.62, 0.28), CFrame.new(0.58, 1.35, -1.10) * CFrame.Angles(0, 0, math.rad(-24)), Color3.fromRGB(129, 61, 59), Enum.Material.Fabric, Enum.PartType.Ball)
    elseif collectionId == "black_security_hardcase" then
        detailPart(model, root, "SecurityStrip", Vector3.new(2.00, 0.16, 0.09), CFrame.new(0, 0.88, -1.30), Color3.fromRGB(151, 48, 48), Enum.Material.Neon)
        detailPart(model, root, "SecurityBadge", Vector3.new(0.55, 0.55, 0.10), CFrame.new(1.72, 0.90, -1.29), COLORS.Silver, Enum.Material.Metal)
    elseif collectionId == "ownerless_vintage_case" then
        detailPart(model, root, "AnomalySeam", Vector3.new(2.30, 0.10, 0.07), CFrame.new(0, -0.82, -1.30), COLORS.Cyan, Enum.Material.Neon)
        detailPart(model, root, "OldTag", Vector3.new(1.00, 0.58, 0.10), CFrame.new(-1.62, 0.85, -1.28) * CFrame.Angles(0, 0, math.rad(-8)), Color3.fromRGB(143, 119, 83), Enum.Material.Fabric)
    elseif collectionId == "flight_000_hardcase" then
        detailPart(model, root, "ZeroLine", Vector3.new(2.45, 0.12, 0.08), CFrame.new(0, 0.92, -1.30), COLORS.Gold, Enum.Material.Metal)
        for i = -1, 1 do
            detailPart(model, root, "ZeroCode" .. i, Vector3.new(0.22, 0.46 + math.abs(i) * 0.18, 0.08), CFrame.new(i * 0.46, 0.15, -1.31), Color3.fromRGB(215, 209, 184), Enum.Material.Metal)
        end
    elseif collectionId == "unstable_sealed_parcel" then
        detailPart(model, root, "SealA", Vector3.new(0.18, 2.30, 0.09), CFrame.new(1.52, 0, -1.70), COLORS.Cyan, Enum.Material.Neon)
        detailPart(model, root, "SealB", Vector3.new(1.20, 0.18, 0.09), CFrame.new(1.52, 0.75, -1.70), COLORS.Cyan, Enum.Material.Neon)
    elseif collectionId == "green_identity_backpack" then
        detailPart(model, root, "IdentityPlate", Vector3.new(1.72, 0.82, 0.10), CFrame.new(0, 0.55, -1.16), Color3.fromRGB(188, 203, 187), Enum.Material.Fabric)
        detailPart(model, root, "IdentityAccent", Vector3.new(1.18, 0.11, 0.08), CFrame.new(0, 0.55, -1.23), COLORS.Violet, Enum.Material.Neon)
    elseif collectionId == "milo_small_case" then
        detailPart(model, root, "MiloPlate", Vector3.new(1.45, 0.48, 0.10), CFrame.new(0, 0.70, -1.22), Color3.fromRGB(185, 151, 82), Enum.Material.Metal)
        detailPart(model, root, "MiloMark", Vector3.new(0.72, 0.10, 0.08), CFrame.new(0, 0.70, -1.30), COLORS.Gold, Enum.Material.Neon)
    elseif collectionId == "silver_camera_lens" then
        detailPart(model, root, "LensIndex", Vector3.new(0.14, 0.78, 0.08), CFrame.new(0.25, 0.95, -1.63), Color3.fromRGB(224, 227, 230), Enum.Material.Neon)
    elseif collectionId == "ownerless_tag_00017284" then
        detailPart(model, root, "AnomalyTagLine", Vector3.new(1.35, 0.11, 0.08), CFrame.new(1.30, 0.85, -0.30), COLORS.Cyan, Enum.Material.Neon)
    elseif collectionId == "flight_000_boarding_tag" then
        detailPart(model, root, "FlightZeroBand", Vector3.new(1.55, 0.12, 0.08), CFrame.new(1.15, 0.84, -0.30), COLORS.Gold, Enum.Material.Neon)
    elseif collectionId == "duplicate_passport" then
        detailPart(model, root, "DuplicateEdge", Vector3.new(2.85, 3.98, 0.10), CFrame.new(0.28, -0.08, 0.60), Color3.fromRGB(111, 80, 104), Enum.Material.SmoothPlastic)
        detailPart(model, root, "DuplicateMark", Vector3.new(1.18, 0.12, 0.08), CFrame.new(0, 1.35, -0.30), COLORS.Violet, Enum.Material.Neon)
    elseif collectionId == "milo_toy_train_2001" then
        detailPart(model, root, "TrainMemoryPlate", Vector3.new(1.12, 0.46, 0.10), CFrame.new(1.00, 0.20, -1.13), COLORS.Gold, Enum.Material.Metal)
    elseif collectionId == "maya_power_adapter" then
        detailPart(model, root, "MayaMark", Vector3.new(1.12, 0.12, 0.08), CFrame.new(0, 0.48, -0.94), Color3.fromRGB(112, 137, 151), Enum.Material.SmoothPlastic)
    elseif collectionId == "daniel_formal_shoe" then
        detailPart(model, root, "ToeCapLine", Vector3.new(0.10, 1.65, 0.08), CFrame.new(-1.05, 0.88, -1.02), Color3.fromRGB(100, 91, 80), Enum.Material.SmoothPlastic)
    elseif collectionId == "sofia_name_patch" then
        detailPart(model, root, "SofiaThread", Vector3.new(2.30, 0.10, 0.08), CFrame.new(0, 0.02, -0.25), Color3.fromRGB(83, 59, 46), Enum.Material.Fabric)
    elseif collectionId == "ari_red_paperback" then
        detailPart(model, root, "AriBand", Vector3.new(2.18, 0.10, 0.08), CFrame.new(0.12, -1.22, -0.31), Color3.fromRGB(237, 215, 157), Enum.Material.Metal)
    elseif collectionId == "unstable_mass_readout" then
        detailPart(model, root, "AnomalyTick", Vector3.new(0.16, 1.50, 0.08), CFrame.new(-2.15, 0.30, -0.62), COLORS.Cyan, Enum.Material.Neon)
    end

    model:SetAttribute("M5CVisualQuality", "M5C_COLLECTIBLE_V1")
    model:SetAttribute("M5CBaseFamily", tostring(variant.base or "unknown"))
    model:SetAttribute("M5CRarity", tostring(variant.rarity or "COMMON"))
end

function CollectionPreviewFactory.Create(collectionId, parent, locked)
    local model = Instance.new("Model")
    model.Name = "Preview_" .. tostring(collectionId)
    model.Parent = parent

    local variant = VARIANTS[collectionId] or { base = "hardcase_suitcase", color = Color3.fromRGB(90, 96, 108), rarity = "COMMON" }
    local builder = BUILDERS[variant.base] or buildHardcase
    builder(model, variant.color)
    applyCollectionDetails(model, collectionId, variant)

    if variant.scale then model:ScaleTo(variant.scale) end

    if locked then
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Color = Color3.fromRGB(53, 59, 68)
                descendant.Material = Enum.Material.SmoothPlastic
                descendant.Transparency = 0.10
            end
        end
    end

    model:PivotTo(CFrame.Angles(math.rad(-6), math.rad(-148), 0))
    return model
end

return CollectionPreviewFactory
