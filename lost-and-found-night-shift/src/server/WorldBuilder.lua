local Lighting = game:GetService("Lighting")

local WorldBuilder = {}

local COLORS = {
    Floor = Color3.fromRGB(30, 34, 42), Wall = Color3.fromRGB(22, 26, 34), Metal = Color3.fromRGB(64, 70, 80), Amber = Color3.fromRGB(255, 174, 57), Cyan = Color3.fromRGB(72, 198, 255), Red = Color3.fromRGB(210, 54, 58), Green = Color3.fromRGB(67, 168, 92), White = Color3.fromRGB(235, 238, 242),
}

local function part(parent, name, size, cframe, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = true
    p.Color = color or COLORS.Metal
    p.Material = material or Enum.Material.Metal
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function addLabel(target, text, face, textColor, backgroundTransparency)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "Label"
    gui.Face = face or Enum.NormalId.Front
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0
    gui.PixelsPerStud = 40
    gui.Parent = target
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = backgroundTransparency == nil and 1 or backgroundTransparency
    label.Text = text
    label.TextColor3 = textColor or COLORS.White
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
    return label
end

local function prompt(target, actionText, objectText)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = actionText
    p.ObjectText = objectText
    p.MaxActivationDistance = 10
    p.HoldDuration = 0.15
    p.RequiresLineOfSight = false
    p.Parent = target
    return p
end

local function weld(child, root)
    child.Anchored = false
    child.CanCollide = false
    local w = Instance.new("WeldConstraint")
    w.Part0 = root
    w.Part1 = child
    w.Parent = child
end

local function configureLighting()
    Lighting.ClockTime = 1.0
    Lighting.Brightness = 1.8
    Lighting.Ambient = Color3.fromRGB(46, 54, 68)
    Lighting.OutdoorAmbient = Color3.fromRGB(18, 22, 30)
    Lighting.EnvironmentDiffuseScale = 0.35
    Lighting.EnvironmentSpecularScale = 0.65
    local atmosphere = Lighting:FindFirstChild("LostAndFoundAtmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "LostAndFoundAtmosphere"
        atmosphere.Density = 0.22
        atmosphere.Offset = 0.1
        atmosphere.Color = Color3.fromRGB(165, 185, 210)
        atmosphere.Decay = Color3.fromRGB(44, 55, 72)
        atmosphere.Glare = 0.05
        atmosphere.Haze = 1.2
        atmosphere.Parent = Lighting
    end
end

function WorldBuilder.Build()
    configureLighting()
    local old = workspace:FindFirstChild("LostAndFoundM0")
    if old then old:Destroy() end
    local world = Instance.new("Model")
    world.Name = "LostAndFoundM0"
    world.Parent = workspace

    part(world, "Floor", Vector3.new(92, 1, 64), CFrame.new(0, -0.5, 0), COLORS.Floor, Enum.Material.Concrete)
    part(world, "BackWall", Vector3.new(92, 18, 1), CFrame.new(0, 9, -31.5), COLORS.Wall, Enum.Material.Concrete)
    part(world, "LeftWall", Vector3.new(1, 18, 64), CFrame.new(-45.5, 9, 0), COLORS.Wall, Enum.Material.Concrete)
    part(world, "RightWall", Vector3.new(1, 18, 64), CFrame.new(45.5, 9, 0), COLORS.Wall, Enum.Material.Concrete)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "M0Spawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(0, 0.5, 24)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Transparency = 0.35
    spawn.Color = COLORS.Cyan
    spawn.Material = Enum.Material.Neon
    spawn.Parent = world

    local counter = part(world, "ServiceCounter", Vector3.new(30, 4, 4), CFrame.new(11, 2, -13), COLORS.Metal, Enum.Material.Metal)
    addLabel(counter, "LOST & FOUND  •  NIGHT SHIFT", Enum.NormalId.Front, COLORS.Amber)
    local sign = part(world, "MainSign", Vector3.new(28, 5, 1), CFrame.new(11, 11, -30.8), Color3.fromRGB(15, 18, 24), Enum.Material.Metal)
    addLabel(sign, "LOST & FOUND\nNIGHT SHIFT", Enum.NormalId.Front, COLORS.Amber)

    part(world, "ConveyorBase", Vector3.new(34, 2, 9), CFrame.new(-20, 1, -8), Color3.fromRGB(45, 49, 57), Enum.Material.Metal)
    part(world, "ConveyorBelt", Vector3.new(32, 0.6, 7), CFrame.new(-20, 2.25, -8), Color3.fromRGB(18, 20, 24), Enum.Material.DiamondPlate)
    local railA = part(world, "ConveyorRailA", Vector3.new(34, 2, 0.5), CFrame.new(-20, 3.0, -12.3), COLORS.Metal, Enum.Material.Metal)
    local railB = part(world, "ConveyorRailB", Vector3.new(34, 2, 0.5), CFrame.new(-20, 3.0, -3.7), COLORS.Metal, Enum.Material.Metal)
    railA.CanCollide = false
    railB.CanCollide = false

    local inspection = part(world, "InspectionTable", Vector3.new(12, 2.5, 9), CFrame.new(2, 1.25, -8), Color3.fromRGB(72, 78, 89), Enum.Material.Metal)
    addLabel(inspection, "INSPECTION", Enum.NormalId.Front, COLORS.White)
    local scanner = part(world, "Scanner", Vector3.new(5, 6, 7), CFrame.new(-2.5, 5, -8), Color3.fromRGB(35, 45, 58), Enum.Material.Metal)
    scanner.CanCollide = false
    local scannerGlow = part(world, "ScannerGlow", Vector3.new(0.3, 4.8, 5.7), CFrame.new(0.05, 5, -8), COLORS.Cyan, Enum.Material.Neon)
    scannerGlow.CanCollide = false

    local tagReader = part(world, "TagReader", Vector3.new(3.5, 1, 3.5), CFrame.new(4, 3, -7), COLORS.Amber, Enum.Material.Neon)
    addLabel(tagReader, "TAG", Enum.NormalId.Top, Color3.fromRGB(20, 20, 20))
    local openTray = part(world, "OpenTray", Vector3.new(3.5, 1, 3.5), CFrame.new(4, 3, -10.5), Color3.fromRGB(120, 126, 138), Enum.Material.Metal)
    addLabel(openTray, "OPEN", Enum.NormalId.Top, COLORS.White)

    local claimantMarker = part(world, "ClaimantMarker", Vector3.new(8, 0.35, 8), CFrame.new(11, 0.2, -4), COLORS.Amber, Enum.Material.Neon)
    claimantMarker.Transparency = 0.55
    claimantMarker.CanCollide = false
    addLabel(claimantMarker, "CLAIMANT", Enum.NormalId.Top, Color3.fromRGB(20, 20, 20))

    local decisions = {}
    local decisionData = {
        { "RETURN", COLORS.Green, CFrame.new(25, 0.35, 5) }, { "STORE", COLORS.Cyan, CFrame.new(34, 0.35, 5) }, { "QUARANTINE", COLORS.Amber, CFrame.new(25, 0.35, 15) }, { "SECURITY", COLORS.Red, CFrame.new(34, 0.35, 15) },
    }
    for _, info in ipairs(decisionData) do
        local decisionName, color, cf = info[1], info[2], info[3]
        local pad = part(world, decisionName .. "Pad", Vector3.new(7, 0.7, 7), cf, color, Enum.Material.Neon)
        addLabel(pad, decisionName, Enum.NormalId.Top, Color3.fromRGB(20, 20, 20))
        decisions[decisionName] = prompt(pad, decisionName, "CASE DECISION")
    end

    local scannerPrompt = prompt(scanner, "SCAN ITEM", "BAGGAGE SCANNER")
    local tagPrompt = prompt(tagReader, "CHECK TAG", "CLAIM TAG")
    local openPrompt = prompt(openTray, "OPEN / INSPECT", "INSPECTION TABLE")

    local instructions = part(world, "Instructions", Vector3.new(18, 9, 1), CFrame.new(-33, 8, -30.7), Color3.fromRGB(18, 21, 28), Enum.Material.Metal)
    addLabel(instructions, "M0 — FIRST SUITCASE\n\n1  SCAN\n2  CHECK TAG\n3  OPEN / INSPECT\n4  DECIDE", Enum.NormalId.Front, COLORS.White)
    local quarantineDoor = part(world, "QuarantineDoor", Vector3.new(12, 12, 1), CFrame.new(34, 6, -30.7), Color3.fromRGB(50, 24, 28), Enum.Material.Metal)
    addLabel(quarantineDoor, "QUARANTINE\nAUTHORIZED ONLY", Enum.NormalId.Front, COLORS.Red)

    local startMarker = Instance.new("Part")
    startMarker.Name = "ConveyorStart"
    startMarker.Size = Vector3.new(1, 1, 1)
    startMarker.CFrame = CFrame.new(-34, 3.6, -8)
    startMarker.Transparency = 1
    startMarker.Anchored = true
    startMarker.CanCollide = false
    startMarker.Parent = world
    local stopMarker = Instance.new("Part")
    stopMarker.Name = "InspectionStop"
    stopMarker.Size = Vector3.new(1, 1, 1)
    stopMarker.CFrame = CFrame.new(-7, 3.6, -8)
    stopMarker.Transparency = 1
    stopMarker.Anchored = true
    stopMarker.CanCollide = false
    stopMarker.Parent = world

    return { World = world, ConveyorStart = startMarker, InspectionStop = stopMarker, ClaimantMarker = claimantMarker, ScannerPrompt = scannerPrompt, TagPrompt = tagPrompt, OpenPrompt = openPrompt, DecisionPrompts = decisions }
end

function WorldBuilder.CreateSuitcase(world, caseData, startCFrame)
    local model = Instance.new("Model")
    model.Name = "ActiveSuitcase"
    model.Parent = world
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = caseData.itemId == "vintage_suitcase" and Vector3.new(5.3, 3.4, 2.3) or Vector3.new(5.8, 3.8, 2.5)
    body.CFrame = startCFrame
    body.Anchored = true
    body.CanCollide = false
    body.Color = caseData.itemColor or Color3.fromRGB(70, 80, 95)
    body.Material = caseData.itemId == "vintage_suitcase" and Enum.Material.Wood or Enum.Material.SmoothPlastic
    body.Parent = model
    model.PrimaryPart = body
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(2.1, 0.35, 0.35)
    handle.CFrame = body.CFrame * CFrame.new(0, 2.1, 0)
    handle.Color = Color3.fromRGB(32, 32, 34)
    handle.Material = Enum.Material.Metal
    handle.Parent = model
    weld(handle, body)
    local tag = Instance.new("Part")
    tag.Name = "ClaimTag"
    tag.Size = Vector3.new(1.3, 1.7, 0.12)
    tag.CFrame = body.CFrame * CFrame.new(2.35, 0.5, -1.3)
    tag.Color = caseData.caseType == "mystery" and COLORS.Red or COLORS.White
    tag.Material = Enum.Material.SmoothPlastic
    tag.Parent = model
    weld(tag, body)
    addLabel(tag, caseData.tagNumber, Enum.NormalId.Front, caseData.caseType == "mystery" and COLORS.White or Color3.fromRGB(25, 25, 25))
    return model
end

function WorldBuilder.CreateClaimant(world, marker, caseData)
    local old = world:FindFirstChild("ActiveClaimant")
    if old then old:Destroy() end
    if not caseData.claimantName or caseData.claimantKind == "None" then return nil end
    local model = Instance.new("Model")
    model.Name = "ActiveClaimant"
    model.Parent = world
    local child = caseData.claimantKind == "Child"
    local torsoHeight = child and 2.4 or 3.4
    local torso = part(model, "Torso", Vector3.new(child and 2.2 or 2.8, torsoHeight, 1.5), marker.CFrame * CFrame.new(0, torsoHeight / 2 + 0.3, 0), Color3.fromRGB(42, 48, 59), Enum.Material.SmoothPlastic)
    torso.CanCollide = false
    local headSize = child and 1.8 or 2.1
    local head = part(model, "Head", Vector3.new(headSize, headSize, headSize), torso.CFrame * CFrame.new(0, torsoHeight / 2 + headSize / 2, 0), child and Color3.fromRGB(212, 172, 138) or Color3.fromRGB(190, 150, 118), Enum.Material.SmoothPlastic)
    head.CanCollide = false
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ClaimantLabel"
    billboard.Size = UDim2.fromOffset(220, 70)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
    label.BackgroundTransparency = 0.15
    label.TextColor3 = COLORS.White
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Text = caseData.claimantName .. (child and "\n[CHILD]" or "\n[CLAIMANT]")
    label.Parent = billboard
    return model
end

return WorldBuilder
