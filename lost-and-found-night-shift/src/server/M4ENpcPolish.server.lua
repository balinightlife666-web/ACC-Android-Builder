-- M4-E claimant visual polish.
-- Adds lightweight procedural variation to the existing static claimant mannequin
-- without external assets or image generation. Keeps NPCs non-colliding and cheap
-- enough for the 8-station mobile target.

local workspaceService = game:GetService("Workspace")

local SKIN_TONES = {
    Color3.fromRGB(232, 196, 166),
    Color3.fromRGB(215, 174, 139),
    Color3.fromRGB(190, 145, 111),
    Color3.fromRGB(155, 111, 82),
    Color3.fromRGB(118, 82, 62),
}

local OUTFITS = {
    Color3.fromRGB(42, 54, 70),
    Color3.fromRGB(64, 47, 56),
    Color3.fromRGB(45, 66, 58),
    Color3.fromRGB(72, 65, 49),
    Color3.fromRGB(54, 54, 60),
    Color3.fromRGB(40, 61, 76),
}

local ACCENTS = {
    Color3.fromRGB(187, 139, 63),
    Color3.fromRGB(72, 145, 171),
    Color3.fromRGB(153, 70, 74),
    Color3.fromRGB(93, 137, 91),
    Color3.fromRGB(151, 118, 169),
}

local HAIR = {
    Color3.fromRGB(28, 25, 24),
    Color3.fromRGB(54, 39, 30),
    Color3.fromRGB(92, 66, 45),
    Color3.fromRGB(35, 35, 39),
    Color3.fromRGB(116, 91, 66),
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
        return string.match(label.Text, "^[^•]+") or label.Text
    end
    return model:GetAttribute("ClaimantName") or "CLAIMANT"
end

local function polish(model)
    if not model or not model.Parent or model:GetAttribute("M4EPolished") then return end

    local torso = model:FindFirstChild("Torso") or model:WaitForChild("Torso", 1)
    local head = model:FindFirstChild("Head") or model:WaitForChild("Head", 1)
    if not torso or not head or not model.Parent then return end

    model:SetAttribute("M4EPolished", true)

    local name = claimantName(model)
    local h = hashText(name)
    local skin = SKIN_TONES[(h % #SKIN_TONES) + 1]
    local outfit = OUTFITS[((math.floor(h / 7)) % #OUTFITS) + 1]
    local accent = ACCENTS[((math.floor(h / 13)) % #ACCENTS) + 1]
    local hair = HAIR[((math.floor(h / 19)) % #HAIR) + 1]
    local isChild = torso.Size.Y < 3

    torso.Color = outfit
    torso.Material = Enum.Material.Fabric
    head.Color = skin

    local torsoCF = torso.CFrame
    local headCF = head.CFrame
    local bodyWidth = torso.Size.X
    local torsoHeight = torso.Size.Y

    local legHeight = isChild and 1.7 or 2.5
    local legWidth = isChild and 0.7 or 0.85
    local legY = -(torsoHeight / 2 + legHeight / 2 - 0.08)
    makePart(model, "LegL", Vector3.new(legWidth, legHeight, 0.9), torsoCF * CFrame.new(-bodyWidth * 0.23, legY, 0), Color3.fromRGB(34, 38, 45), Enum.Material.Fabric)
    makePart(model, "LegR", Vector3.new(legWidth, legHeight, 0.9), torsoCF * CFrame.new(bodyWidth * 0.23, legY, 0), Color3.fromRGB(34, 38, 45), Enum.Material.Fabric)

    local armHeight = isChild and 1.9 or 2.7
    local armWidth = isChild and 0.55 or 0.65
    makePart(model, "ArmL", Vector3.new(armWidth, armHeight, 0.8), torsoCF * CFrame.new(-(bodyWidth / 2 + armWidth / 2 - 0.05), 0.1, 0) * CFrame.Angles(0, 0, math.rad(4)), skin, Enum.Material.SmoothPlastic)
    makePart(model, "ArmR", Vector3.new(armWidth, armHeight, 0.8), torsoCF * CFrame.new(bodyWidth / 2 + armWidth / 2 - 0.05, 0.1, 0) * CFrame.Angles(0, 0, math.rad(-4)), skin, Enum.Material.SmoothPlastic)

    local shirtPanel = makePart(model, "OutfitAccent", Vector3.new(bodyWidth * 0.72, 0.22, torso.Size.Z + 0.04), torsoCF * CFrame.new(0, torsoHeight * 0.18, -0.02), accent, Enum.Material.Fabric)
    shirtPanel.Transparency = 0.05

    local hairMode = h % 4
    if hairMode == 0 then
        local cap = makePart(model, "HairCap", Vector3.new(head.Size.X * 1.02, head.Size.Y * 0.42, head.Size.Z * 1.02), headCF * CFrame.new(0, head.Size.Y * 0.33, 0), hair, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        cap.Size = Vector3.new(head.Size.X * 1.02, head.Size.Y * 0.48, head.Size.Z * 1.02)
    elseif hairMode == 1 then
        makePart(model, "HairTop", Vector3.new(head.Size.X * 0.95, 0.42, head.Size.Z * 0.92), headCF * CFrame.new(0, head.Size.Y * 0.48, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairSide", Vector3.new(head.Size.X * 0.28, head.Size.Y * 0.72, head.Size.Z * 0.9), headCF * CFrame.new(-head.Size.X * 0.39, head.Size.Y * 0.10, 0.02), hair, Enum.Material.SmoothPlastic)
    elseif hairMode == 2 then
        makePart(model, "HairTop", Vector3.new(head.Size.X * 0.96, 0.38, head.Size.Z * 0.92), headCF * CFrame.new(0, head.Size.Y * 0.48, 0), hair, Enum.Material.SmoothPlastic)
        makePart(model, "HairBack", Vector3.new(head.Size.X * 0.82, head.Size.Y * 0.95, 0.35), headCF * CFrame.new(0, -0.03, head.Size.Z * 0.47), hair, Enum.Material.SmoothPlastic)
    else
        makePart(model, "HairTop", Vector3.new(head.Size.X * 0.88, 0.34, head.Size.Z * 0.86), headCF * CFrame.new(0.12, head.Size.Y * 0.5, 0), hair, Enum.Material.SmoothPlastic)
    end

    local eyeY = head.Size.Y * 0.08
    local eyeZ = -(head.Size.Z / 2 + 0.075)
    makePart(model, "EyeL", Vector3.new(0.14, 0.14, 0.08), headCF * CFrame.new(-head.Size.X * 0.20, eyeY, eyeZ), Color3.fromRGB(22, 24, 28), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makePart(model, "EyeR", Vector3.new(0.14, 0.14, 0.08), headCF * CFrame.new(head.Size.X * 0.20, eyeY, eyeZ), Color3.fromRGB(22, 24, 28), Enum.Material.SmoothPlastic, Enum.PartType.Ball)

    if h % 5 == 0 and not isChild then
        local glassesY = eyeY
        makePart(model, "GlassesL", Vector3.new(0.52, 0.34, 0.06), headCF * CFrame.new(-head.Size.X * 0.20, glassesY, eyeZ - 0.05), Color3.fromRGB(45, 49, 56), Enum.Material.Metal)
        makePart(model, "GlassesR", Vector3.new(0.52, 0.34, 0.06), headCF * CFrame.new(head.Size.X * 0.20, glassesY, eyeZ - 0.05), Color3.fromRGB(45, 49, 56), Enum.Material.Metal)
        makePart(model, "GlassesBridge", Vector3.new(0.28, 0.07, 0.05), headCF * CFrame.new(0, glassesY, eyeZ - 0.05), Color3.fromRGB(45, 49, 56), Enum.Material.Metal)
    end

    local billboard = head:FindFirstChild("ClaimantLabel")
    if billboard and billboard:IsA("BillboardGui") then
        billboard.AlwaysOnTop = false
        billboard.MaxDistance = 19
        billboard.StudsOffset = Vector3.new(0, isChild and 1.65 or 1.85, 0)
        billboard.Size = UDim2.fromOffset(138, 38)
        local label = billboard:FindFirstChildOfClass("TextLabel")
        if label then
            label.TextSize = 12
            label.BackgroundTransparency = 0.34
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
