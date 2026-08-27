-- M4-E.1 claimant visual depth pass.
-- Adds deterministic lightweight procedural variation to claimant mannequins using
-- Roblox geometry only. No external assets/image generation; remains suitable for
-- the initial 8-station mobile target.

local workspaceService = game:GetService("Workspace")

local SKIN_TONES = {
    Color3.fromRGB(242, 209, 181),
    Color3.fromRGB(232, 196, 166),
    Color3.fromRGB(220, 180, 146),
    Color3.fromRGB(205, 159, 122),
    Color3.fromRGB(190, 145, 111),
    Color3.fromRGB(171, 126, 94),
    Color3.fromRGB(151, 106, 79),
    Color3.fromRGB(130, 91, 69),
    Color3.fromRGB(108, 74, 56),
}

local OUTFITS = {
    Color3.fromRGB(42, 54, 70),
    Color3.fromRGB(64, 47, 56),
    Color3.fromRGB(45, 66, 58),
    Color3.fromRGB(72, 65, 49),
    Color3.fromRGB(54, 54, 60),
    Color3.fromRGB(40, 61, 76),
    Color3.fromRGB(75, 48, 42),
    Color3.fromRGB(47, 55, 48),
    Color3.fromRGB(63, 55, 76),
    Color3.fromRGB(66, 58, 52),
}

local ACCENTS = {
    Color3.fromRGB(187, 139, 63),
    Color3.fromRGB(72, 145, 171),
    Color3.fromRGB(153, 70, 74),
    Color3.fromRGB(93, 137, 91),
    Color3.fromRGB(151, 118, 169),
    Color3.fromRGB(194, 170, 113),
    Color3.fromRGB(101, 124, 176),
    Color3.fromRGB(164, 103, 61),
}

local HAIR = {
    Color3.fromRGB(24, 22, 21),
    Color3.fromRGB(42, 31, 25),
    Color3.fromRGB(61, 43, 31),
    Color3.fromRGB(82, 58, 40),
    Color3.fromRGB(35, 35, 39),
    Color3.fromRGB(101, 78, 55),
    Color3.fromRGB(54, 48, 44),
}

local PANTS = {
    Color3.fromRGB(34, 38, 45),
    Color3.fromRGB(43, 47, 54),
    Color3.fromRGB(38, 48, 56),
    Color3.fromRGB(52, 48, 43),
    Color3.fromRGB(46, 45, 52),
    Color3.fromRGB(34, 43, 39),
}

local SHOES = {
    Color3.fromRGB(23, 25, 29),
    Color3.fromRGB(47, 38, 33),
    Color3.fromRGB(61, 61, 64),
    Color3.fromRGB(82, 75, 64),
}

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
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    if shape then p.Shape = shape end
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function claimantName(model)
    local head = model:FindFirstChild("Head")
    local billboard = head and head:FindFirstChild("ClaimantLabel")
    local label = billboard and billboard:FindFirstChildOfClass("TextLabel")
    if label then
        local parsed = string.match(label.Text, "^[^•]+") or label.Text
        return string.gsub(parsed, "%s+$", "")
    end
    return model:GetAttribute("ClaimantName") or "CLAIMANT"
end

local function addHair(model, head, headCF, hair, mode)
    if mode == 0 then
        local cap = makePart(model, "HairCap", Vector3.new(head.Size.X * 1.02, head.Size.Y * 0.48, head.Size.Z * 1.02), headCF * CFrame.new(0, head.Size.Y * 0.33, 0), hair, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        cap.Size = Vector3.new(head.Size.X * 1.02, head.Size.Y * 0.48, head.Size.Z * 1.02)
    elseif mode == 1 then
        makePart(model, "HairTop", Vector3.new(head.Size.X * 0.95, 0.42, head.Size.Z * 0.92), headCF * CFrame.new(0, head.Size.Y * 0.48, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairSide", Vector3.new(head.Size.X * 0.28, head.Size.Y * 0.72, head.Size.Z * 0.9), headCF * CFrame.new(-head.Size.X * 0.39, head.Size.Y * 0.10, 0.02), hair, Enum.Material.SmoothPlastic)
    elseif mode == 2 then
        makePart(model, "HairTop", Vector3.new(head.Size.X * 0.96, 0.38, head.Size.Z * 0.92), headCF * CFrame.new(0, head.Size.Y * 0.48, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairBack", Vector3.new(head.Size.X * 0.82, head.Size.Y * 0.95, 0.35), headCF * CFrame.new(0, -0.03, head.Size.Z * 0.47), hair, Enum.Material.SmoothPlastic)
    elseif mode == 3 then
        makePart(model, "HairTop", Vector3.new(head.Size.X * 0.88, 0.34, head.Size.Z * 0.86), headCF * CFrame.new(0.12, head.Size.Y * 0.5, 0), hair, Enum.Material.SmoothPlastic)
    elseif mode == 4 then
        makePart(model, "HairTop", Vector3.new(head.Size.X * 0.90, 0.34, head.Size.Z * 0.88), headCF * CFrame.new(-0.08, head.Size.Y * 0.49, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairFringe", Vector3.new(head.Size.X * 0.62, 0.30, 0.20), headCF * CFrame.new(0.12, head.Size.Y * 0.31, -(head.Size.Z * 0.46)), hair, Enum.Material.SmoothPlastic)
    elseif mode == 5 then
        makePart(model, "HairTop", Vector3.new(head.Size.X * 0.93, 0.38, head.Size.Z * 0.90), headCF * CFrame.new(0, head.Size.Y * 0.48, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairLeft", Vector3.new(0.24, head.Size.Y * 0.82, head.Size.Z * 0.74), headCF * CFrame.new(-head.Size.X * 0.43, 0, 0.08), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairRight", Vector3.new(0.24, head.Size.Y * 0.82, head.Size.Z * 0.74), headCF * CFrame.new(head.Size.X * 0.43, 0, 0.08), hair, Enum.Material.SmoothPlastic)
    else
        makePart(model, "HairTop", Vector3.new(head.Size.X * 0.92, 0.32, head.Size.Z * 0.88), headCF * CFrame.new(0, head.Size.Y * 0.49, 0.02), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairBack", Vector3.new(head.Size.X * 0.70, head.Size.Y * 0.62, 0.28), headCF * CFrame.new(0, -0.10, head.Size.Z * 0.47), hair, Enum.Material.SmoothPlastic)
    end
end

local function addAccessory(model, torso, torsoCF, head, headCF, accent, h, isChild)
    local mode = math.floor(h / 29) % 6
    if mode == 1 then
        makePart(model, "Scarf", Vector3.new(torso.Size.X * 0.82, 0.28, torso.Size.Z + 0.08), torsoCF * CFrame.new(0, torso.Size.Y * 0.38, -0.02), accent, Enum.Material.Fabric)
    elseif mode == 2 then
        local strap = makePart(model, "BagStrap", Vector3.new(0.18, torso.Size.Y * 0.92, 0.12), torsoCF * CFrame.new(0, 0, -(torso.Size.Z / 2 + 0.08)) * CFrame.Angles(0, 0, math.rad(-24)), accent, Enum.Material.Fabric)
        strap.Transparency = 0.03
    elseif mode == 3 and not isChild then
        makePart(model, "Lanyard", Vector3.new(0.10, torso.Size.Y * 0.52, 0.08), torsoCF * CFrame.new(0, 0.18, -(torso.Size.Z / 2 + 0.09)), accent, Enum.Material.Fabric)
        makePart(model, "Badge", Vector3.new(0.48, 0.34, 0.08), torsoCF * CFrame.new(0, -torso.Size.Y * 0.10, -(torso.Size.Z / 2 + 0.09)), Color3.fromRGB(215, 219, 224), Enum.Material.SmoothPlastic)
    elseif mode == 4 then
        local capColor = accent:Lerp(Color3.fromRGB(35, 38, 44), 0.45)
        makePart(model, "CapTop", Vector3.new(head.Size.X * 0.92, 0.28, head.Size.Z * 0.92), headCF * CFrame.new(0, head.Size.Y * 0.57, 0), capColor, Enum.Material.Fabric)
        makePart(model, "CapBrim", Vector3.new(head.Size.X * 0.70, 0.12, 0.46), headCF * CFrame.new(0, head.Size.Y * 0.48, -(head.Size.Z * 0.55)), capColor, Enum.Material.Fabric)
    elseif mode == 5 then
        makePart(model, "WristBand", Vector3.new(0.72, 0.16, 0.84), torsoCF * CFrame.new(torso.Size.X * 0.63, -torso.Size.Y * 0.20, 0), accent, Enum.Material.Fabric)
    end
end

local function polish(model)
    if not model or not model.Parent or model:GetAttribute("M4EPolished") then return end

    local torso = model:FindFirstChild("Torso") or model:WaitForChild("Torso", 1)
    local head = model:FindFirstChild("Head") or model:WaitForChild("Head", 1)
    if not torso or not head or not model.Parent then return end

    model:SetAttribute("M4EPolished", true)
    model:SetAttribute("M4E1Depth", true)

    local name = claimantName(model)
    local h = hashText(name)
    local skin = SKIN_TONES[(h % #SKIN_TONES) + 1]
    local outfit = OUTFITS[((math.floor(h / 7)) % #OUTFITS) + 1]
    local accent = ACCENTS[((math.floor(h / 13)) % #ACCENTS) + 1]
    local hair = HAIR[((math.floor(h / 19)) % #HAIR) + 1]
    local pants = PANTS[((math.floor(h / 23)) % #PANTS) + 1]
    local shoes = SHOES[((math.floor(h / 31)) % #SHOES) + 1]
    local isChild = torso.Size.Y < 3

    torso.Color = outfit
    torso.Material = Enum.Material.Fabric
    head.Color = skin

    local torsoCF = torso.CFrame
    local headCF = head.CFrame
    local bodyWidth = torso.Size.X
    local torsoHeight = torso.Size.Y
    local proportionMode = math.floor(h / 37) % 3
    local widthAdjust = proportionMode == 0 and -0.05 or (proportionMode == 2 and 0.08 or 0)

    local legHeight = isChild and 1.7 or (2.42 + ((h % 5) * 0.05))
    local legWidth = (isChild and 0.68 or 0.82) + widthAdjust
    local legY = -(torsoHeight / 2 + legHeight / 2 - 0.08)
    local legL = makePart(model, "LegL", Vector3.new(legWidth, legHeight, 0.9), torsoCF * CFrame.new(-bodyWidth * 0.23, legY, 0), pants, Enum.Material.Fabric)
    local legR = makePart(model, "LegR", Vector3.new(legWidth, legHeight, 0.9), torsoCF * CFrame.new(bodyWidth * 0.23, legY, 0), pants, Enum.Material.Fabric)

    local shoeHeight = isChild and 0.30 or 0.36
    makePart(model, "ShoeL", Vector3.new(legWidth + 0.08, shoeHeight, 1.05), legL.CFrame * CFrame.new(0, -(legHeight / 2 + shoeHeight / 2 - 0.04), -0.07), shoes, Enum.Material.SmoothPlastic)
    makePart(model, "ShoeR", Vector3.new(legWidth + 0.08, shoeHeight, 1.05), legR.CFrame * CFrame.new(0, -(legHeight / 2 + shoeHeight / 2 - 0.04), -0.07), shoes, Enum.Material.SmoothPlastic)

    local armHeight = isChild and 1.9 or (2.58 + ((math.floor(h / 5) % 4) * 0.06))
    local armWidth = (isChild and 0.54 or 0.63) + math.max(widthAdjust, -0.03)
    makePart(model, "ArmL", Vector3.new(armWidth, armHeight, 0.8), torsoCF * CFrame.new(-(bodyWidth / 2 + armWidth / 2 - 0.05), 0.1, 0) * CFrame.Angles(0, 0, math.rad(4)), skin, Enum.Material.SmoothPlastic)
    makePart(model, "ArmR", Vector3.new(armWidth, armHeight, 0.8), torsoCF * CFrame.new(bodyWidth / 2 + armWidth / 2 - 0.05, 0.1, 0) * CFrame.Angles(0, 0, math.rad(-4)), skin, Enum.Material.SmoothPlastic)

    local outfitMode = math.floor(h / 11) % 4
    if outfitMode == 0 then
        local panel = makePart(model, "OutfitAccent", Vector3.new(bodyWidth * 0.72, 0.22, torso.Size.Z + 0.04), torsoCF * CFrame.new(0, torsoHeight * 0.18, -0.02), accent, Enum.Material.Fabric)
        panel.Transparency = 0.05
    elseif outfitMode == 1 then
        makePart(model, "JacketPanelL", Vector3.new(bodyWidth * 0.34, torsoHeight * 0.78, 0.10), torsoCF * CFrame.new(-bodyWidth * 0.18, -0.02, -(torso.Size.Z / 2 + 0.06)), accent:Lerp(outfit, 0.55), Enum.Material.Fabric)
        makePart(model, "JacketPanelR", Vector3.new(bodyWidth * 0.34, torsoHeight * 0.78, 0.10), torsoCF * CFrame.new(bodyWidth * 0.18, -0.02, -(torso.Size.Z / 2 + 0.06)), accent:Lerp(outfit, 0.55), Enum.Material.Fabric)
    elseif outfitMode == 2 then
        makePart(model, "ChestBand", Vector3.new(bodyWidth * 0.86, 0.28, torso.Size.Z + 0.04), torsoCF * CFrame.new(0, 0.05, -0.02), accent, Enum.Material.Fabric)
    else
        makePart(model, "CollarL", Vector3.new(bodyWidth * 0.27, 0.34, 0.10), torsoCF * CFrame.new(-bodyWidth * 0.12, torsoHeight * 0.34, -(torso.Size.Z / 2 + 0.06)) * CFrame.Angles(0, 0, math.rad(-18)), accent, Enum.Material.Fabric)
        makePart(model, "CollarR", Vector3.new(bodyWidth * 0.27, 0.34, 0.10), torsoCF * CFrame.new(bodyWidth * 0.12, torsoHeight * 0.34, -(torso.Size.Z / 2 + 0.06)) * CFrame.Angles(0, 0, math.rad(18)), accent, Enum.Material.Fabric)
    end

    addHair(model, head, headCF, hair, h % 7)

    local eyeY = head.Size.Y * 0.08
    local eyeZ = -(head.Size.Z / 2 + 0.075)
    local eyeColor = Color3.fromRGB(22, 24, 28)
    makePart(model, "EyeL", Vector3.new(0.14, 0.14, 0.08), headCF * CFrame.new(-head.Size.X * 0.20, eyeY, eyeZ), eyeColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makePart(model, "EyeR", Vector3.new(0.14, 0.14, 0.08), headCF * CFrame.new(head.Size.X * 0.20, eyeY, eyeZ), eyeColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)

    local browTilt = (h % 3) - 1
    makePart(model, "BrowL", Vector3.new(0.30, 0.06, 0.05), headCF * CFrame.new(-head.Size.X * 0.20, eyeY + 0.22, eyeZ - 0.02) * CFrame.Angles(0, 0, math.rad(browTilt * 4)), hair, Enum.Material.SmoothPlastic)
    makePart(model, "BrowR", Vector3.new(0.30, 0.06, 0.05), headCF * CFrame.new(head.Size.X * 0.20, eyeY + 0.22, eyeZ - 0.02) * CFrame.Angles(0, 0, math.rad(-browTilt * 4)), hair, Enum.Material.SmoothPlastic)

    local mouthWidth = 0.24 + ((math.floor(h / 17) % 3) * 0.05)
    makePart(model, "Mouth", Vector3.new(mouthWidth, 0.06, 0.05), headCF * CFrame.new(0, eyeY - 0.30, eyeZ - 0.02), Color3.fromRGB(112, 67, 62), Enum.Material.SmoothPlastic)

    if h % 5 == 0 and not isChild then
        local frame = Color3.fromRGB(45, 49, 56)
        makePart(model, "GlassesL", Vector3.new(0.52, 0.34, 0.06), headCF * CFrame.new(-head.Size.X * 0.20, eyeY, eyeZ - 0.05), frame, Enum.Material.Metal)
        makePart(model, "GlassesR", Vector3.new(0.52, 0.34, 0.06), headCF * CFrame.new(head.Size.X * 0.20, eyeY, eyeZ - 0.05), frame, Enum.Material.Metal)
        makePart(model, "GlassesBridge", Vector3.new(0.28, 0.07, 0.05), headCF * CFrame.new(0, eyeY, eyeZ - 0.05), frame, Enum.Material.Metal)
    end

    addAccessory(model, torso, torsoCF, head, headCF, accent, h, isChild)

    local billboard = head:FindFirstChild("ClaimantLabel")
    if billboard and billboard:IsA("BillboardGui") then
        billboard.AlwaysOnTop = false
        billboard.MaxDistance = 19
        billboard.StudsOffset = Vector3.new(0, isChild and 1.65 or 1.85, 0)
        billboard.Size = UDim2.fromOffset(142, 38)
        local label = billboard:FindFirstChildOfClass("TextLabel")
        if label then
            label.TextSize = 12
            label.BackgroundTransparency = 0.31
        end
    end
end

local function observe(instance)
    if instance:IsA("Model") and instance.Name == "ActiveClaimant" then
        task.spawn(function()
            task.wait(0.05)
            polish(instance)
        end)
    end
end

for _, instance in ipairs(workspaceService:GetDescendants()) do
    observe(instance)
end
workspaceService.DescendantAdded:Connect(observe)
