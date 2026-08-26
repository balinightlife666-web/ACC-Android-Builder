local ItemFactory = {}

local COLORS = {
    Dark = Color3.fromRGB(31, 34, 40),
    Metal = Color3.fromRGB(73, 79, 88),
    LightMetal = Color3.fromRGB(122, 129, 139),
    Leather = Color3.fromRGB(86, 55, 38),
    Cardboard = Color3.fromRGB(150, 112, 72),
    Tape = Color3.fromRGB(208, 187, 137),
    Tag = Color3.fromRGB(236, 232, 219),
    MysteryTag = Color3.fromRGB(157, 48, 52),
}

local function makePart(model, name, size, cframe, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = false
    p.CanCollide = false
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    if shape then p.Shape = shape end
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = model
    return p
end

local function weld(child, root)
    local constraint = Instance.new("WeldConstraint")
    constraint.Part0 = root
    constraint.Part1 = child
    constraint.Parent = child
end

local function child(model, root, name, size, offset, color, material, shape)
    local p = makePart(model, name, size, root.CFrame * offset, color, material, shape)
    weld(p, root)
    return p
end

local function addTag(model, root, caseData, offset, face)
    local tagColor = caseData.caseType == "mystery" and COLORS.MysteryTag or COLORS.Tag
    local textColor = caseData.caseType == "mystery" and Color3.fromRGB(248, 242, 232) or Color3.fromRGB(32, 35, 40)
    local tag = child(model, root, "ClaimTag", Vector3.new(1.25, 1.55, 0.12), offset, tagColor, Enum.Material.SmoothPlastic)

    local gui = Instance.new("SurfaceGui")
    gui.Name = "TagLabel"
    gui.Face = face or Enum.NormalId.Front
    gui.LightInfluence = 0
    gui.PixelsPerStud = 48
    gui.Parent = tag

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = tostring(caseData.tagNumber)
    label.TextColor3 = textColor
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
end

local function finalize(model, root)
    root.Anchored = true
    root.CanCollide = false
    model.PrimaryPart = root
    return model
end

local function buildHardcase(model, caseData, startCFrame)
    local root = makePart(model, "Body", Vector3.new(5.6, 3.8, 2.35), startCFrame, caseData.itemColor, Enum.Material.SmoothPlastic)

    for x = -2.0, 2.0, 1.0 do
        child(model, root, "ShellRib", Vector3.new(0.14, 3.25, 0.16), CFrame.new(x, 0, -1.2), Color3.fromRGB(24, 27, 33), Enum.Material.Metal)
    end
    child(model, root, "TopHandle", Vector3.new(2.1, 0.28, 0.34), CFrame.new(0, 2.05, 0), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "HandlePostL", Vector3.new(0.22, 1.05, 0.22), CFrame.new(-0.85, 1.6, 0), COLORS.Dark, Enum.Material.Metal)
    child(model, root, "HandlePostR", Vector3.new(0.22, 1.05, 0.22), CFrame.new(0.85, 1.6, 0), COLORS.Dark, Enum.Material.Metal)

    for _, x in ipairs({-2.1, 2.1}) do
        local wheel = child(model, root, "Wheel", Vector3.new(0.5, 0.5, 0.5), CFrame.new(x, -2.0, 0.75), COLORS.Dark, Enum.Material.Metal, Enum.PartType.Ball)
        wheel.Color = Color3.fromRGB(18, 20, 24)
    end

    addTag(model, root, caseData, CFrame.new(2.15, 0.35, -1.24))
    return finalize(model, root)
end

local function buildVintage(model, caseData, startCFrame)
    local root = makePart(model, "Body", Vector3.new(5.2, 3.35, 2.25), startCFrame, caseData.itemColor, Enum.Material.Wood)
    child(model, root, "LeatherBandL", Vector3.new(0.35, 3.45, 2.34), CFrame.new(-1.55, 0, 0), COLORS.Leather, Enum.Material.SmoothPlastic)
    child(model, root, "LeatherBandR", Vector3.new(0.35, 3.45, 2.34), CFrame.new(1.55, 0, 0), COLORS.Leather, Enum.Material.SmoothPlastic)
    child(model, root, "LatchL", Vector3.new(0.5, 0.52, 0.2), CFrame.new(-1.0, 0.35, -1.2), Color3.fromRGB(180, 139, 62), Enum.Material.Metal)
    child(model, root, "LatchR", Vector3.new(0.5, 0.52, 0.2), CFrame.new(1.0, 0.35, -1.2), Color3.fromRGB(180, 139, 62), Enum.Material.Metal)
    child(model, root, "TopHandle", Vector3.new(1.8, 0.3, 0.38), CFrame.new(0, 1.95, 0), COLORS.Leather, Enum.Material.SmoothPlastic)

    for _, sx in ipairs({-1, 1}) do
        for _, sy in ipairs({-1, 1}) do
            child(model, root, "Corner", Vector3.new(0.5, 0.5, 0.22), CFrame.new(2.38 * sx, 1.48 * sy, -1.17), Color3.fromRGB(106, 68, 38), Enum.Material.SmoothPlastic)
        end
    end

    addTag(model, root, caseData, CFrame.new(2.0, 0.3, -1.18))
    return finalize(model, root)
end

local function buildBackpack(model, caseData, startCFrame)
    local root = makePart(model, "Body", Vector3.new(4.2, 4.8, 2.05), startCFrame, caseData.itemColor, Enum.Material.Fabric)
    child(model, root, "FrontPocket", Vector3.new(3.3, 1.75, 0.7), CFrame.new(0, -0.9, -1.35), caseData.itemColor:Lerp(Color3.fromRGB(20, 22, 26), 0.2), Enum.Material.Fabric)
    child(model, root, "TopCap", Vector3.new(3.7, 1.1, 1.9), CFrame.new(0, 2.2, 0), caseData.itemColor, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "GrabHandle", Vector3.new(1.55, 0.24, 0.3), CFrame.new(0, 2.75, 0.55), COLORS.Dark, Enum.Material.SmoothPlastic)
    child(model, root, "StrapL", Vector3.new(0.35, 3.6, 0.28), CFrame.new(-1.15, 0, 1.17), Color3.fromRGB(32, 35, 40), Enum.Material.Fabric)
    child(model, root, "StrapR", Vector3.new(0.35, 3.6, 0.28), CFrame.new(1.15, 0, 1.17), Color3.fromRGB(32, 35, 40), Enum.Material.Fabric)
    child(model, root, "ZipLine", Vector3.new(3.45, 0.12, 0.14), CFrame.new(0, 0.15, -1.4), Color3.fromRGB(175, 180, 186), Enum.Material.Metal)

    addTag(model, root, caseData, CFrame.new(1.65, 0.75, -1.42))
    return finalize(model, root)
end

local function buildCardboard(model, caseData, startCFrame)
    local root = makePart(model, "Body", Vector3.new(5.15, 3.45, 3.25), startCFrame, caseData.itemColor or COLORS.Cardboard, Enum.Material.SmoothPlastic)
    child(model, root, "TapeLong", Vector3.new(0.65, 3.55, 3.35), CFrame.new(0, 0, 0), COLORS.Tape, Enum.Material.SmoothPlastic)
    child(model, root, "TapeCross", Vector3.new(5.25, 0.58, 3.35), CFrame.new(0, 0.45, 0), COLORS.Tape, Enum.Material.SmoothPlastic)
    child(model, root, "LabelPlate", Vector3.new(2.25, 1.15, 0.1), CFrame.new(-0.75, 0.35, -1.68), Color3.fromRGB(224, 220, 205), Enum.Material.SmoothPlastic)
    child(model, root, "CornerDent", Vector3.new(0.55, 0.55, 0.55), CFrame.new(2.4, 1.45, -1.5), Color3.fromRGB(118, 84, 56), Enum.Material.SmoothPlastic)

    addTag(model, root, caseData, CFrame.new(1.7, -0.65, -1.69))
    return finalize(model, root)
end

local function buildTeddy(model, caseData, startCFrame)
    local root = makePart(model, "Body", Vector3.new(3.25, 3.25, 3.0), startCFrame, caseData.itemColor, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "Head", Vector3.new(2.8, 2.8, 2.65), CFrame.new(0, 2.55, -0.15), caseData.itemColor, Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "EarL", Vector3.new(1.1, 1.1, 0.75), CFrame.new(-1.15, 3.45, 0), caseData.itemColor:Lerp(Color3.fromRGB(90, 60, 45), 0.12), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "EarR", Vector3.new(1.1, 1.1, 0.75), CFrame.new(1.15, 3.45, 0), caseData.itemColor:Lerp(Color3.fromRGB(90, 60, 45), 0.12), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "Muzzle", Vector3.new(1.35, 0.95, 0.65), CFrame.new(0, 2.25, -1.35), Color3.fromRGB(210, 184, 151), Enum.Material.Fabric, Enum.PartType.Ball)
    child(model, root, "ArmL", Vector3.new(1.15, 2.6, 1.15), CFrame.new(-1.7, 0.45, 0) * CFrame.Angles(0, 0, math.rad(-22)), caseData.itemColor, Enum.Material.Fabric)
    child(model, root, "ArmR", Vector3.new(1.15, 2.6, 1.15), CFrame.new(1.7, 0.45, 0) * CFrame.Angles(0, 0, math.rad(22)), caseData.itemColor, Enum.Material.Fabric)
    child(model, root, "LegL", Vector3.new(1.35, 2.1, 1.45), CFrame.new(-0.9, -2.0, 0.2), caseData.itemColor, Enum.Material.Fabric)
    child(model, root, "LegR", Vector3.new(1.35, 2.1, 1.45), CFrame.new(0.9, -2.0, 0.2), caseData.itemColor, Enum.Material.Fabric)
    child(model, root, "EyeL", Vector3.new(0.25, 0.25, 0.18), CFrame.new(-0.55, 2.85, -1.33), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    child(model, root, "EyeR", Vector3.new(0.25, 0.25, 0.18), CFrame.new(0.55, 2.85, -1.33), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic, Enum.PartType.Ball)

    addTag(model, root, caseData, CFrame.new(1.45, -0.25, -1.42))
    return finalize(model, root)
end

local BUILDERS = {
    hardcase_suitcase = buildHardcase,
    vintage_suitcase = buildVintage,
    backpack = buildBackpack,
    cardboard_box = buildCardboard,
    teddy_bear = buildTeddy,
}

function ItemFactory.Create(world, caseData, startCFrame)
    local model = Instance.new("Model")
    model.Name = "ActiveItem"
    model:SetAttribute("ItemId", caseData.itemId)
    model:SetAttribute("CaseId", caseData.id)
    model.Parent = world

    local builder = BUILDERS[caseData.itemId] or buildHardcase
    return builder(model, caseData, startCFrame)
end

return ItemFactory
