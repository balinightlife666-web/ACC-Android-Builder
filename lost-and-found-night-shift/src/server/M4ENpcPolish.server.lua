-- LOST & FOUND: NIGHT SHIFT — M4-E.1A claimant runtime visual hotfix.
-- Screenshot QC showed that claimant silhouettes could still resolve as the legacy
-- head + torso mannequin. This script is deliberately self-contained and resilient:
-- it retries late-created claimants, periodically reconciles missed hooks, and only
-- marks a model polished after the complete visual pass succeeds.
-- Roblox geometry only; no external assets and no economy/case logic changes.

local Workspace = game:GetService("Workspace")

local VISUAL_VERSION = "M4E1A_NPC_V2"
local RECONCILE_SECONDS = 1.0
local RETRY_COUNT = 16
local RETRY_DELAY = 0.10

local SKIN_TONES = {
    Color3.fromRGB(244, 214, 188),
    Color3.fromRGB(234, 199, 170),
    Color3.fromRGB(221, 181, 149),
    Color3.fromRGB(207, 161, 125),
    Color3.fromRGB(190, 143, 108),
    Color3.fromRGB(171, 124, 93),
    Color3.fromRGB(151, 106, 80),
    Color3.fromRGB(129, 90, 69),
    Color3.fromRGB(105, 72, 56),
}

local OUTFITS = {
    Color3.fromRGB(37, 48, 64),
    Color3.fromRGB(62, 43, 53),
    Color3.fromRGB(40, 63, 55),
    Color3.fromRGB(67, 60, 46),
    Color3.fromRGB(48, 49, 57),
    Color3.fromRGB(36, 58, 72),
    Color3.fromRGB(70, 44, 39),
    Color3.fromRGB(44, 52, 46),
    Color3.fromRGB(58, 50, 72),
    Color3.fromRGB(61, 53, 48),
}

local ACCENTS = {
    Color3.fromRGB(190, 143, 69),
    Color3.fromRGB(70, 145, 174),
    Color3.fromRGB(157, 72, 78),
    Color3.fromRGB(92, 139, 93),
    Color3.fromRGB(151, 119, 171),
    Color3.fromRGB(199, 174, 117),
    Color3.fromRGB(99, 123, 178),
    Color3.fromRGB(168, 105, 62),
}

local HAIR_COLORS = {
    Color3.fromRGB(22, 21, 20),
    Color3.fromRGB(39, 29, 24),
    Color3.fromRGB(58, 41, 30),
    Color3.fromRGB(80, 56, 39),
    Color3.fromRGB(34, 34, 38),
    Color3.fromRGB(100, 77, 54),
    Color3.fromRGB(53, 47, 43),
}

local PANTS = {
    Color3.fromRGB(30, 34, 41),
    Color3.fromRGB(40, 44, 51),
    Color3.fromRGB(34, 44, 52),
    Color3.fromRGB(48, 44, 40),
    Color3.fromRGB(42, 41, 49),
    Color3.fromRGB(30, 40, 36),
}

local SHOES = {
    Color3.fromRGB(20, 22, 26),
    Color3.fromRGB(43, 35, 31),
    Color3.fromRGB(57, 57, 61),
    Color3.fromRGB(76, 69, 59),
}

local generatedNames = {
    VisualRoot = true,
    Neck = true,
    ShoulderL = true,
    ShoulderR = true,
    UpperArmL = true,
    UpperArmR = true,
    ForearmL = true,
    ForearmR = true,
    HandL = true,
    HandR = true,
    LegL = true,
    LegR = true,
    ShoeL = true,
    ShoeR = true,
    HairTop = true,
    HairSide = true,
    HairSideR = true,
    HairBack = true,
    HairFringe = true,
    HairBun = true,
    JacketPanelL = true,
    JacketPanelR = true,
    ChestBand = true,
    CollarL = true,
    CollarR = true,
    OutfitAccent = true,
    EyeL = true,
    EyeR = true,
    BrowL = true,
    BrowR = true,
    Nose = true,
    Mouth = true,
    GlassesL = true,
    GlassesR = true,
    GlassesBridge = true,
    Scarf = true,
    BagStrap = true,
    Lanyard = true,
    Badge = true,
    CapTop = true,
    CapBrim = true,
    WristBand = true,
}

local pending = setmetatable({}, { __mode = "k" })

local function hashText(text)
    local h = 17
    for i = 1, #text do
        h = (h * 31 + string.byte(text, i)) % 2147483647
    end
    return h
end

local function makePart(parent, name, size, cframe, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = true
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end

local function cleanupGenerated(model)
    for _, child in ipairs(model:GetChildren()) do
        if generatedNames[child.Name] then
            child:Destroy()
        end
    end
end

local function claimantName(model)
    local fromAttribute = model:GetAttribute("ClaimantName")
    if type(fromAttribute) == "string" and fromAttribute ~= "" then
        return fromAttribute
    end

    local head = model:FindFirstChild("Head")
    local billboard = head and head:FindFirstChild("ClaimantLabel")
    local label = billboard and billboard:FindFirstChildOfClass("TextLabel")
    if label then
        local parsed = string.match(label.Text, "^[^•]+") or label.Text
        return (string.gsub(parsed, "%s+$", ""))
    end
    return "CLAIMANT"
end

local function addHeadMesh(head)
    local old = head:FindFirstChild("M4E1AHeadMesh")
    if old then old:Destroy() end
    local mesh = Instance.new("SpecialMesh")
    mesh.Name = "M4E1AHeadMesh"
    mesh.MeshType = Enum.MeshType.Head
    mesh.Scale = Vector3.new(1.03, 1.06, 1.03)
    mesh.Parent = head
end

local function addHair(model, head, headCF, hair, mode)
    local x, y, z = head.Size.X, head.Size.Y, head.Size.Z
    if mode == 0 then
        makePart(model, "HairTop", Vector3.new(x * 0.90, y * 0.34, z * 0.86), headCF * CFrame.new(0, y * 0.47, 0.03), hair, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    elseif mode == 1 then
        makePart(model, "HairTop", Vector3.new(x * 0.93, 0.34, z * 0.88), headCF * CFrame.new(0, y * 0.49, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairSide", Vector3.new(0.25, y * 0.72, z * 0.78), headCF * CFrame.new(-x * 0.43, 0.03, 0.07), hair, Enum.Material.SmoothPlastic)
    elseif mode == 2 then
        makePart(model, "HairTop", Vector3.new(x * 0.94, 0.35, z * 0.88), headCF * CFrame.new(0, y * 0.49, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairBack", Vector3.new(x * 0.78, y * 0.88, 0.28), headCF * CFrame.new(0, -0.06, z * 0.46), hair, Enum.Material.SmoothPlastic)
    elseif mode == 3 then
        makePart(model, "HairTop", Vector3.new(x * 0.88, 0.30, z * 0.82), headCF * CFrame.new(0.10, y * 0.50, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairFringe", Vector3.new(x * 0.52, 0.24, 0.17), headCF * CFrame.new(0.13, y * 0.29, -(z * 0.45)), hair, Enum.Material.SmoothPlastic)
    elseif mode == 4 then
        makePart(model, "HairTop", Vector3.new(x * 0.92, 0.32, z * 0.86), headCF * CFrame.new(0, y * 0.49, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairSide", Vector3.new(0.22, y * 0.82, z * 0.70), headCF * CFrame.new(-x * 0.43, -0.02, 0.07), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairSideR", Vector3.new(0.22, y * 0.82, z * 0.70), headCF * CFrame.new(x * 0.43, -0.02, 0.07), hair, Enum.Material.SmoothPlastic)
    elseif mode == 5 then
        makePart(model, "HairTop", Vector3.new(x * 0.90, 0.32, z * 0.84), headCF * CFrame.new(0, y * 0.49, 0.02), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairBack", Vector3.new(x * 0.65, y * 0.58, 0.25), headCF * CFrame.new(0, -0.11, z * 0.47), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairBun", Vector3.new(0.55, 0.55, 0.55), headCF * CFrame.new(0, y * 0.38, z * 0.48), hair, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    else
        makePart(model, "HairTop", Vector3.new(x * 0.91, 0.29, z * 0.84), headCF * CFrame.new(-0.06, y * 0.50, 0.02), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairFringe", Vector3.new(x * 0.38, 0.25, 0.16), headCF * CFrame.new(-0.18, y * 0.28, -(z * 0.45)), hair, Enum.Material.SmoothPlastic)
    end
end

local function addFace(model, head, headCF, hair, h)
    local frontZ = -(head.Size.Z / 2 + 0.045)
    local eyeY = head.Size.Y * 0.08
    local eyeColor = Color3.fromRGB(20, 22, 26)
    makePart(model, "EyeL", Vector3.new(0.13, 0.13, 0.07), headCF * CFrame.new(-head.Size.X * 0.19, eyeY, frontZ), eyeColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makePart(model, "EyeR", Vector3.new(0.13, 0.13, 0.07), headCF * CFrame.new(head.Size.X * 0.19, eyeY, frontZ), eyeColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)

    local browTilt = (h % 3) - 1
    makePart(model, "BrowL", Vector3.new(0.27, 0.055, 0.045), headCF * CFrame.new(-head.Size.X * 0.19, eyeY + 0.20, frontZ - 0.01) * CFrame.Angles(0, 0, math.rad(browTilt * 4)), hair, Enum.Material.SmoothPlastic)
    makePart(model, "BrowR", Vector3.new(0.27, 0.055, 0.045), headCF * CFrame.new(head.Size.X * 0.19, eyeY + 0.20, frontZ - 0.01) * CFrame.Angles(0, 0, math.rad(-browTilt * 4)), hair, Enum.Material.SmoothPlastic)

    makePart(model, "Nose", Vector3.new(0.12, 0.19, 0.11), headCF * CFrame.new(0, eyeY - 0.10, frontZ - 0.045), head.Color:Lerp(Color3.fromRGB(120, 88, 73), 0.10), Enum.Material.SmoothPlastic)
    local mouthWidth = 0.23 + ((math.floor(h / 17) % 3) * 0.045)
    makePart(model, "Mouth", Vector3.new(mouthWidth, 0.055, 0.04), headCF * CFrame.new(0, eyeY - 0.31, frontZ - 0.02), Color3.fromRGB(106, 64, 61), Enum.Material.SmoothPlastic)

    if h % 5 == 0 then
        local frame = Color3.fromRGB(42, 45, 52)
        makePart(model, "GlassesL", Vector3.new(0.47, 0.30, 0.045), headCF * CFrame.new(-head.Size.X * 0.19, eyeY, frontZ - 0.04), frame, Enum.Material.Metal)
        makePart(model, "GlassesR", Vector3.new(0.47, 0.30, 0.045), headCF * CFrame.new(head.Size.X * 0.19, eyeY, frontZ - 0.04), frame, Enum.Material.Metal)
        makePart(model, "GlassesBridge", Vector3.new(0.25, 0.055, 0.04), headCF * CFrame.new(0, eyeY, frontZ - 0.04), frame, Enum.Material.Metal)
    end
end

local function addAccessory(model, torso, torsoCF, head, headCF, accent, h, isChild)
    local mode = math.floor(h / 29) % 6
    if mode == 1 then
        makePart(model, "Scarf", Vector3.new(torso.Size.X * 0.78, 0.24, torso.Size.Z + 0.06), torsoCF * CFrame.new(0, torso.Size.Y * 0.40, -0.01), accent, Enum.Material.Fabric)
    elseif mode == 2 then
        makePart(model, "BagStrap", Vector3.new(0.15, torso.Size.Y * 0.86, 0.09), torsoCF * CFrame.new(0, 0, -(torso.Size.Z / 2 + 0.06)) * CFrame.Angles(0, 0, math.rad(-24)), accent, Enum.Material.Fabric)
    elseif mode == 3 and not isChild then
        makePart(model, "Lanyard", Vector3.new(0.08, torso.Size.Y * 0.48, 0.06), torsoCF * CFrame.new(0, 0.16, -(torso.Size.Z / 2 + 0.06)), accent, Enum.Material.Fabric)
        makePart(model, "Badge", Vector3.new(0.42, 0.29, 0.06), torsoCF * CFrame.new(0, -torso.Size.Y * 0.10, -(torso.Size.Z / 2 + 0.07)), Color3.fromRGB(214, 219, 224), Enum.Material.SmoothPlastic)
    elseif mode == 4 then
        local capColor = accent:Lerp(Color3.fromRGB(35, 38, 44), 0.42)
        makePart(model, "CapTop", Vector3.new(head.Size.X * 0.86, 0.23, head.Size.Z * 0.86), headCF * CFrame.new(0, head.Size.Y * 0.56, 0), capColor, Enum.Material.Fabric)
        makePart(model, "CapBrim", Vector3.new(head.Size.X * 0.62, 0.09, 0.40), headCF * CFrame.new(0, head.Size.Y * 0.47, -(head.Size.Z * 0.52)), capColor, Enum.Material.Fabric)
    elseif mode == 5 then
        makePart(model, "WristBand", Vector3.new(0.52, 0.13, 0.62), torsoCF * CFrame.new(torso.Size.X * 0.67, -torso.Size.Y * 0.28, -0.02), accent, Enum.Material.Fabric)
    end
end

local function polish(model)
    if not model or not model.Parent or model.Name ~= "ActiveClaimant" then return false end
    if model:GetAttribute("NpcVisualVersion") == VISUAL_VERSION then return true end

    local torso = model:FindFirstChild("Torso")
    local head = model:FindFirstChild("Head")
    if not torso or not head or not torso:IsA("BasePart") or not head:IsA("BasePart") then
        return false
    end

    cleanupGenerated(model)

    local name = claimantName(model)
    model:SetAttribute("ClaimantName", name)
    local h = hashText(name)
    local skin = SKIN_TONES[(h % #SKIN_TONES) + 1]
    local outfit = OUTFITS[((math.floor(h / 7)) % #OUTFITS) + 1]
    local accent = ACCENTS[((math.floor(h / 13)) % #ACCENTS) + 1]
    local hair = HAIR_COLORS[((math.floor(h / 19)) % #HAIR_COLORS) + 1]
    local pants = PANTS[((math.floor(h / 23)) % #PANTS) + 1]
    local shoes = SHOES[((math.floor(h / 31)) % #SHOES) + 1]
    local isChild = torso.Size.Y < 3

    -- Shrink the legacy cuboid silhouette before layering the humanized geometry.
    if isChild then
        torso.Size = Vector3.new(1.85, 2.34, 1.08)
        head.Size = Vector3.new(1.58, 1.68, 1.52)
    else
        torso.Size = Vector3.new(2.18, 3.12, 1.20)
        head.Size = Vector3.new(1.74, 1.88, 1.68)
    end
    torso.Color = outfit
    torso.Material = Enum.Material.Fabric
    head.Color = skin
    head.Material = Enum.Material.SmoothPlastic
    addHeadMesh(head)

    local torsoCF = torso.CFrame
    local headCF = head.CFrame
    local bodyWidth = torso.Size.X
    local torsoHeight = torso.Size.Y
    local proportion = (math.floor(h / 37) % 3) - 1
    local widthAdjust = proportion * 0.045

    makePart(model, "Neck", Vector3.new(isChild and 0.48 or 0.58, isChild and 0.33 or 0.38, isChild and 0.48 or 0.58), torsoCF * CFrame.new(0, torsoHeight / 2 + 0.12, 0), skin, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)

    local shoulderWidth = (isChild and 0.66 or 0.78) + widthAdjust
    local shoulderY = torsoHeight * 0.31
    makePart(model, "ShoulderL", Vector3.new(shoulderWidth, 0.54, 0.90), torsoCF * CFrame.new(-(bodyWidth / 2 + shoulderWidth * 0.28), shoulderY, 0), outfit, Enum.Material.Fabric, Enum.PartType.Ball)
    makePart(model, "ShoulderR", Vector3.new(shoulderWidth, 0.54, 0.90), torsoCF * CFrame.new(bodyWidth / 2 + shoulderWidth * 0.28, shoulderY, 0), outfit, Enum.Material.Fabric, Enum.PartType.Ball)

    local upperArmH = isChild and 0.92 or 1.18
    local foreArmH = isChild and 0.82 or 1.05
    local armW = isChild and 0.48 or 0.56
    local leftUpperCF = torsoCF * CFrame.new(-(bodyWidth / 2 + armW * 0.68), 0.30, 0) * CFrame.Angles(0, 0, math.rad(5))
    local rightUpperCF = torsoCF * CFrame.new(bodyWidth / 2 + armW * 0.68, 0.30, 0) * CFrame.Angles(0, 0, math.rad(-5))
    makePart(model, "UpperArmL", Vector3.new(armW, upperArmH, 0.68), leftUpperCF, outfit, Enum.Material.Fabric)
    makePart(model, "UpperArmR", Vector3.new(armW, upperArmH, 0.68), rightUpperCF, outfit, Enum.Material.Fabric)
    local leftForeCF = leftUpperCF * CFrame.new(0.04, -(upperArmH / 2 + foreArmH / 2 - 0.05), -0.04) * CFrame.Angles(math.rad(-3), 0, math.rad(-3))
    local rightForeCF = rightUpperCF * CFrame.new(-0.04, -(upperArmH / 2 + foreArmH / 2 - 0.05), -0.04) * CFrame.Angles(math.rad(-3), 0, math.rad(3))
    makePart(model, "ForearmL", Vector3.new(armW * 0.86, foreArmH, 0.62), leftForeCF, skin, Enum.Material.SmoothPlastic)
    makePart(model, "ForearmR", Vector3.new(armW * 0.86, foreArmH, 0.62), rightForeCF, skin, Enum.Material.SmoothPlastic)
    makePart(model, "HandL", Vector3.new(0.50, 0.50, 0.50), leftForeCF * CFrame.new(0, -(foreArmH / 2 + 0.18), 0), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makePart(model, "HandR", Vector3.new(0.50, 0.50, 0.50), rightForeCF * CFrame.new(0, -(foreArmH / 2 + 0.18), 0), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)

    local legH = isChild and 1.55 or (2.15 + ((h % 4) * 0.04))
    local legW = (isChild and 0.62 or 0.72) + widthAdjust
    local legY = -(torsoHeight / 2 + legH / 2 - 0.04)
    local legL = makePart(model, "LegL", Vector3.new(legW, legH, 0.78), torsoCF * CFrame.new(-bodyWidth * 0.23, legY, 0), pants, Enum.Material.Fabric)
    local legR = makePart(model, "LegR", Vector3.new(legW, legH, 0.78), torsoCF * CFrame.new(bodyWidth * 0.23, legY, 0), pants, Enum.Material.Fabric)
    local shoeH = isChild and 0.26 or 0.31
    makePart(model, "ShoeL", Vector3.new(legW + 0.05, shoeH, 0.98), legL.CFrame * CFrame.new(0, -(legH / 2 + shoeH / 2 - 0.03), -0.08), shoes, Enum.Material.SmoothPlastic)
    makePart(model, "ShoeR", Vector3.new(legW + 0.05, shoeH, 0.98), legR.CFrame * CFrame.new(0, -(legH / 2 + shoeH / 2 - 0.03), -0.08), shoes, Enum.Material.SmoothPlastic)

    local outfitMode = math.floor(h / 11) % 4
    if outfitMode == 0 then
        makePart(model, "OutfitAccent", Vector3.new(bodyWidth * 0.72, 0.18, torso.Size.Z + 0.035), torsoCF * CFrame.new(0, torsoHeight * 0.17, -0.01), accent, Enum.Material.Fabric)
    elseif outfitMode == 1 then
        makePart(model, "JacketPanelL", Vector3.new(bodyWidth * 0.32, torsoHeight * 0.76, 0.08), torsoCF * CFrame.new(-bodyWidth * 0.17, -0.02, -(torso.Size.Z / 2 + 0.045)), accent:Lerp(outfit, 0.56), Enum.Material.Fabric)
        makePart(model, "JacketPanelR", Vector3.new(bodyWidth * 0.32, torsoHeight * 0.76, 0.08), torsoCF * CFrame.new(bodyWidth * 0.17, -0.02, -(torso.Size.Z / 2 + 0.045)), accent:Lerp(outfit, 0.56), Enum.Material.Fabric)
    elseif outfitMode == 2 then
        makePart(model, "ChestBand", Vector3.new(bodyWidth * 0.82, 0.23, torso.Size.Z + 0.035), torsoCF * CFrame.new(0, 0.04, -0.01), accent, Enum.Material.Fabric)
    else
        makePart(model, "CollarL", Vector3.new(bodyWidth * 0.25, 0.29, 0.08), torsoCF * CFrame.new(-bodyWidth * 0.12, torsoHeight * 0.34, -(torso.Size.Z / 2 + 0.045)) * CFrame.Angles(0, 0, math.rad(-18)), accent, Enum.Material.Fabric)
        makePart(model, "CollarR", Vector3.new(bodyWidth * 0.25, 0.29, 0.08), torsoCF * CFrame.new(bodyWidth * 0.12, torsoHeight * 0.34, -(torso.Size.Z / 2 + 0.045)) * CFrame.Angles(0, 0, math.rad(18)), accent, Enum.Material.Fabric)
    end

    addHair(model, head, headCF, hair, h % 7)
    addFace(model, head, headCF, hair, h)
    addAccessory(model, torso, torsoCF, head, headCF, accent, h, isChild)

    local billboard = head:FindFirstChild("ClaimantLabel")
    if billboard and billboard:IsA("BillboardGui") then
        billboard.AlwaysOnTop = false
        billboard.MaxDistance = 20
        billboard.StudsOffset = Vector3.new(0, isChild and 1.50 or 1.72, 0)
        billboard.Size = UDim2.fromOffset(142, 38)
        local label = billboard:FindFirstChildOfClass("TextLabel")
        if label then
            label.TextSize = 12
            label.BackgroundTransparency = 0.30
        end
    end

    -- Mark only after every core visual element has been constructed.
    model:SetAttribute("M4EPolished", true)
    model:SetAttribute("M4E1Depth", true)
    model:SetAttribute("NpcVisualVersion", VISUAL_VERSION)
    return true
end

local function tryPolish(model)
    if pending[model] then return end
    pending[model] = true
    task.spawn(function()
        for _ = 1, RETRY_COUNT do
            if not model or not model.Parent then break end
            local ok, result = pcall(polish, model)
            if ok and result then
                pending[model] = nil
                return
            end
            if not ok then
                warn("[LOST FOUND] claimant visual pass retry:", result)
            end
            task.wait(RETRY_DELAY)
        end
        pending[model] = nil
    end)
end

local function observe(instance)
    if instance:IsA("Model") and instance.Name == "ActiveClaimant" then
        tryPolish(instance)
    end
end

for _, instance in ipairs(Workspace:GetDescendants()) do
    observe(instance)
end
Workspace.DescendantAdded:Connect(observe)

-- Reconciliation is intentional. Claimants are short-lived and can be parented before
-- their Torso/Head children exist; this closes that race without touching case runtime.
task.spawn(function()
    while true do
        task.wait(RECONCILE_SECONDS)
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if instance:IsA("Model") and instance.Name == "ActiveClaimant" and instance:GetAttribute("NpcVisualVersion") ~= VISUAL_VERSION then
                tryPolish(instance)
            end
        end
    end
end)
