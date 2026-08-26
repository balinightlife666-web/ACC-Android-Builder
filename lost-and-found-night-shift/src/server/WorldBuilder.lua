local Lighting = game:GetService("Lighting")

local WorldBuilder = {}

local COLORS = {
    Floor = Color3.fromRGB(27, 31, 38),
    Wall = Color3.fromRGB(20, 24, 31),
    Panel = Color3.fromRGB(31, 37, 46),
    Metal = Color3.fromRGB(55, 63, 74),
    DarkMetal = Color3.fromRGB(37, 43, 52),
    Amber = Color3.fromRGB(214, 151, 55),
    AmberSoft = Color3.fromRGB(166, 111, 42),
    Cyan = Color3.fromRGB(58, 158, 194),
    CyanSoft = Color3.fromRGB(42, 112, 139),
    Red = Color3.fromRGB(170, 58, 62),
    Green = Color3.fromRGB(58, 132, 78),
    White = Color3.fromRGB(235, 238, 242),
    Muted = Color3.fromRGB(132, 142, 156),
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

local function nonCollide(p)
    p.CanCollide = false
    return p
end

local function addLabel(target, text, face, textColor, backgroundTransparency)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "Label"
    gui.Face = face or Enum.NormalId.Front
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0
    gui.PixelsPerStud = 44
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
    p.MaxActivationDistance = 7
    p.HoldDuration = 0.08
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

local function addPointLight(target, color, brightness, range, shadows)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = shadows == true
    light.Parent = target
    return light
end

local function configureLighting()
    Lighting.ClockTime = 1.0
    Lighting.Brightness = 2.1
    Lighting.Ambient = Color3.fromRGB(54, 61, 73)
    Lighting.OutdoorAmbient = Color3.fromRGB(23, 28, 36)
    Lighting.EnvironmentDiffuseScale = 0.4
    Lighting.EnvironmentSpecularScale = 0.55

    local atmosphere = Lighting:FindFirstChild("LostAndFoundAtmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "LostAndFoundAtmosphere"
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.11
    atmosphere.Offset = 0.04
    atmosphere.Color = Color3.fromRGB(176, 188, 204)
    atmosphere.Decay = Color3.fromRGB(48, 57, 72)
    atmosphere.Glare = 0.01
    atmosphere.Haze = 0.55

    local color = Lighting:FindFirstChild("LostAndFoundColor")
    if not color then
        color = Instance.new("ColorCorrectionEffect")
        color.Name = "LostAndFoundColor"
        color.Parent = Lighting
    end
    color.Brightness = 0.01
    color.Contrast = 0.08
    color.Saturation = -0.08
    color.TintColor = Color3.fromRGB(225, 232, 242)

    local bloom = Lighting:FindFirstChild("LostAndFoundBloom")
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Name = "LostAndFoundBloom"
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.12
    bloom.Size = 18
    bloom.Threshold = 1.4
end

local function addCeilingLight(world, x, z)
    local casing = part(world, "CeilingLightHousing", Vector3.new(14.5, 0.55, 1.7), CFrame.new(x, 17.6, z), COLORS.DarkMetal, Enum.Material.Metal)
    casing.CanCollide = false
    local lens = part(world, "CeilingLightLens", Vector3.new(13.4, 0.18, 1.05), CFrame.new(x, 17.28, z), Color3.fromRGB(220, 230, 240), Enum.Material.Neon)
    lens.CanCollide = false
    addPointLight(lens, Color3.fromRGB(210, 222, 236), 1.15, 25, true)
end

local function addWallPanel(world, x, width)
    local panel = part(world, "BackWallPanel", Vector3.new(width, 11.5, 0.28), CFrame.new(x, 8.2, -30.88), COLORS.Panel, Enum.Material.Metal)
    panel.CanCollide = false
    local trimTop = part(world, "PanelTrimTop", Vector3.new(width, 0.16, 0.12), CFrame.new(x, 14.0, -30.68), COLORS.Muted, Enum.Material.Metal)
    trimTop.CanCollide = false
end

local function addStorageRack(world, x, z)
    local rack = Instance.new("Model")
    rack.Name = "StorageRack"
    rack.Parent = world

    for _, dx in ipairs({-3.2, 3.2}) do
        part(rack, "Post", Vector3.new(0.35, 9, 0.35), CFrame.new(x + dx, 4.5, z), COLORS.Metal, Enum.Material.Metal)
    end
    for level = 0, 3 do
        local y = 0.65 + level * 2.35
        part(rack, "Shelf", Vector3.new(7, 0.28, 2.8), CFrame.new(x, y, z), COLORS.DarkMetal, Enum.Material.Metal)
    end

    local boxA = part(rack, "StoredProperty", Vector3.new(2.3, 1.2, 1.7), CFrame.new(x - 1.7, 1.45, z), Color3.fromRGB(105, 82, 58), Enum.Material.Wood)
    boxA.CanCollide = false
    local boxB = part(rack, "StoredProperty", Vector3.new(2.0, 1.0, 1.6), CFrame.new(x + 1.6, 3.75, z), Color3.fromRGB(55, 67, 82), Enum.Material.SmoothPlastic)
    boxB.CanCollide = false
end

local function buildServiceCounter(world)
    local model = Instance.new("Model")
    model.Name = "PremiumServiceCounter"
    model.Parent = world

    part(model, "CounterBase", Vector3.new(30, 3.2, 4.8), CFrame.new(11, 1.6, -13), COLORS.DarkMetal, Enum.Material.Metal)
    part(model, "CounterTop", Vector3.new(30.8, 0.42, 5.3), CFrame.new(11, 3.38, -13), Color3.fromRGB(87, 71, 54), Enum.Material.Wood)
    part(model, "FrontFascia", Vector3.new(27.5, 2.0, 0.28), CFrame.new(11, 1.7, -10.48), Color3.fromRGB(29, 34, 42), Enum.Material.Metal)
    local amberStrip = nonCollide(part(model, "CounterAmberStrip", Vector3.new(27.4, 0.13, 0.12), CFrame.new(11, 2.78, -10.27), COLORS.Amber, Enum.Material.Neon))
    addPointLight(amberStrip, COLORS.Amber, 0.45, 9, false)

    local monitor = part(model, "DeskMonitor", Vector3.new(4.5, 2.8, 0.35), CFrame.new(9, 5.05, -14.1) * CFrame.Angles(math.rad(-8), 0, 0), Color3.fromRGB(18, 23, 30), Enum.Material.Metal)
    monitor.CanCollide = false
    addLabel(monitor, "L&F OPS\nNIGHT SHIFT", Enum.NormalId.Front, COLORS.Cyan)

    local deskLamp = nonCollide(part(model, "DeskTaskLight", Vector3.new(4.2, 0.16, 0.7), CFrame.new(17, 5.35, -13.1), COLORS.Amber, Enum.Material.Neon))
    addPointLight(deskLamp, Color3.fromRGB(255, 185, 92), 0.85, 12, true)

    return model
end

local function buildConveyor(world)
    local model = Instance.new("Model")
    model.Name = "PremiumConveyor"
    model.Parent = world

    part(model, "ConveyorBase", Vector3.new(35, 2.2, 9.6), CFrame.new(-20, 1.1, -8), COLORS.DarkMetal, Enum.Material.Metal)
    part(model, "ConveyorBelt", Vector3.new(32.8, 0.48, 7.2), CFrame.new(-20, 2.42, -8), Color3.fromRGB(16, 19, 24), Enum.Material.DiamondPlate)

    for i = -5, 5 do
        local x = -20 + i * 2.6
        local slat = nonCollide(part(model, "BeltSlat", Vector3.new(0.16, 0.06, 6.8), CFrame.new(x, 2.69, -8), Color3.fromRGB(49, 56, 67), Enum.Material.Metal))
        slat.Transparency = 0.25
    end

    part(model, "RailLeft", Vector3.new(35, 1.45, 0.38), CFrame.new(-20, 3.15, -12.48), COLORS.Metal, Enum.Material.Metal).CanCollide = false
    part(model, "RailRight", Vector3.new(35, 1.45, 0.38), CFrame.new(-20, 3.15, -3.52), COLORS.Metal, Enum.Material.Metal).CanCollide = false

    local underGlow = nonCollide(part(model, "ConveyorUnderGlow", Vector3.new(29, 0.11, 0.14), CFrame.new(-21, 0.58, -3.25), COLORS.AmberSoft, Enum.Material.Neon))
    addPointLight(underGlow, COLORS.AmberSoft, 0.25, 7, false)

    return model
end

local function buildScanner(world)
    local model = Instance.new("Model")
    model.Name = "PremiumScanner"
    model.Parent = world

    local left = part(model, "ScannerPillarL", Vector3.new(1.25, 7.3, 1.8), CFrame.new(-4.2, 5.5, -11.2), Color3.fromRGB(38, 47, 58), Enum.Material.Metal)
    local right = part(model, "ScannerPillarR", Vector3.new(1.25, 7.3, 1.8), CFrame.new(-4.2, 5.5, -4.8), Color3.fromRGB(38, 47, 58), Enum.Material.Metal)
    local top = part(model, "ScannerTop", Vector3.new(1.25, 1.35, 8.2), CFrame.new(-4.2, 8.95, -8), Color3.fromRGB(38, 47, 58), Enum.Material.Metal)
    left.CanCollide = false
    right.CanCollide = false
    top.CanCollide = false

    local glowL = nonCollide(part(model, "ScannerGlowL", Vector3.new(0.18, 5.7, 0.24), CFrame.new(-3.52, 5.6, -10.55), COLORS.Cyan, Enum.Material.Neon))
    local glowR = nonCollide(part(model, "ScannerGlowR", Vector3.new(0.18, 5.7, 0.24), CFrame.new(-3.52, 5.6, -5.45), COLORS.Cyan, Enum.Material.Neon))
    local glowTop = nonCollide(part(model, "ScannerGlowTop", Vector3.new(0.18, 0.24, 5.25), CFrame.new(-3.52, 8.45, -8), COLORS.Cyan, Enum.Material.Neon))
    addPointLight(glowL, COLORS.Cyan, 0.7, 11, false)
    addPointLight(glowR, COLORS.Cyan, 0.7, 11, false)
    addPointLight(glowTop, COLORS.Cyan, 0.45, 9, false)

    local display = nonCollide(part(model, "ScannerDisplay", Vector3.new(0.3, 2.2, 3.5), CFrame.new(-3.48, 6.2, -12.0), Color3.fromRGB(14, 24, 31), Enum.Material.SmoothPlastic))
    addLabel(display, "SCAN\nREADY", Enum.NormalId.Right, COLORS.Cyan)

    local anchor = nonCollide(part(model, "ScannerInteraction", Vector3.new(1, 1, 1), CFrame.new(-3.1, 4.1, -8), COLORS.Cyan, Enum.Material.SmoothPlastic))
    anchor.Transparency = 1
    return anchor
end

local function buildInspectionDesk(world)
    local model = Instance.new("Model")
    model.Name = "PremiumInspectionDesk"
    model.Parent = world

    part(model, "DeskBase", Vector3.new(11.5, 2.7, 9.4), CFrame.new(3.5, 1.35, -8), Color3.fromRGB(48, 55, 65), Enum.Material.Metal)
    part(model, "DeskTop", Vector3.new(12.2, 0.36, 10), CFrame.new(3.5, 2.88, -8), Color3.fromRGB(74, 81, 92), Enum.Material.Metal)
    local edge = nonCollide(part(model, "DeskEdgeLight", Vector3.new(10.7, 0.1, 0.12), CFrame.new(3.5, 3.11, -3.02), COLORS.AmberSoft, Enum.Material.Neon))
    addPointLight(edge, COLORS.AmberSoft, 0.25, 6, false)

    local tagReader = part(model, "TagReader", Vector3.new(3.4, 0.9, 3.3), CFrame.new(5.4, 3.55, -6.25), Color3.fromRGB(29, 36, 45), Enum.Material.Metal)
    addLabel(tagReader, "TAG\nREADER", Enum.NormalId.Top, COLORS.Amber)

    local openTray = part(model, "OpenTray", Vector3.new(4.1, 0.55, 3.4), CFrame.new(5.2, 3.35, -10.4), Color3.fromRGB(92, 99, 111), Enum.Material.Metal)
    addLabel(openTray, "OPEN / INSPECT", Enum.NormalId.Top, COLORS.White)

    local screen = nonCollide(part(model, "EvidenceScreen", Vector3.new(3.8, 2.4, 0.28), CFrame.new(0.4, 4.75, -11.8) * CFrame.Angles(0, math.rad(-15), 0), Color3.fromRGB(14, 22, 29), Enum.Material.Metal))
    addLabel(screen, "EVIDENCE\nTERMINAL", Enum.NormalId.Front, COLORS.Cyan)

    return tagReader, openTray
end

local function buildDecisionConsole(world, decisionName, color, cframe)
    local model = Instance.new("Model")
    model.Name = decisionName .. "Console"
    model.Parent = world

    local base = part(model, "Base", Vector3.new(6.4, 1.8, 5.5), cframe * CFrame.new(0, 0.9, 0), COLORS.DarkMetal, Enum.Material.Metal)
    local top = part(model, "Top", Vector3.new(5.8, 0.35, 4.9), cframe * CFrame.new(0, 2.0, 0), color, Enum.Material.SmoothPlastic)
    base.CanCollide = true
    top.CanCollide = true

    local face = nonCollide(part(model, "Face", Vector3.new(5.2, 1.1, 0.12), cframe * CFrame.new(0, 1.05, -2.82), Color3.fromRGB(21, 25, 32), Enum.Material.Metal))
    addLabel(face, decisionName, Enum.NormalId.Front, color)

    local indicator = nonCollide(part(model, "Indicator", Vector3.new(3.8, 0.08, 0.08), cframe * CFrame.new(0, 2.24, -2.0), color, Enum.Material.Neon))
    addPointLight(indicator, color, 0.22, 5, false)

    return prompt(top, decisionName, "CASE DECISION")
end

function WorldBuilder.Build()
    configureLighting()

    local oldM0 = workspace:FindFirstChild("LostAndFoundM0")
    if oldM0 then oldM0:Destroy() end
    local oldM1 = workspace:FindFirstChild("LostAndFoundM1")
    if oldM1 then oldM1:Destroy() end

    local world = Instance.new("Model")
    world.Name = "LostAndFoundM1"
    world.Parent = workspace

    -- Room shell
    part(world, "Floor", Vector3.new(92, 1, 64), CFrame.new(0, -0.5, 0), COLORS.Floor, Enum.Material.Concrete)
    part(world, "BackWall", Vector3.new(92, 18, 1), CFrame.new(0, 9, -31.5), COLORS.Wall, Enum.Material.Concrete)
    part(world, "LeftWall", Vector3.new(1, 18, 64), CFrame.new(-45.5, 9, 0), COLORS.Wall, Enum.Material.Concrete)
    part(world, "RightWall", Vector3.new(1, 18, 64), CFrame.new(45.5, 9, 0), COLORS.Wall, Enum.Material.Concrete)
    part(world, "Ceiling", Vector3.new(92, 1, 64), CFrame.new(0, 18.5, 0), Color3.fromRGB(15, 19, 25), Enum.Material.Metal)

    for _, x in ipairs({-36, -18, 0, 18, 36}) do
        part(world, "FloorGuide", Vector3.new(0.08, 0.03, 56), CFrame.new(x, 0.03, 0), Color3.fromRGB(42, 48, 57), Enum.Material.Metal).CanCollide = false
    end

    for _, x in ipairs({-32, -16, 0, 16, 32}) do
        addWallPanel(world, x, 14.5)
    end

    part(world, "BackWallBaseTrim", Vector3.new(88, 0.6, 0.3), CFrame.new(0, 0.7, -30.75), Color3.fromRGB(70, 78, 90), Enum.Material.Metal).CanCollide = false
    part(world, "AmberGuideLine", Vector3.new(74, 0.05, 0.15), CFrame.new(-1, 0.04, -18), COLORS.AmberSoft, Enum.Material.Neon).CanCollide = false

    addCeilingLight(world, -28, -4)
    addCeilingLight(world, 0, -4)
    addCeilingLight(world, 28, -4)
    addCeilingLight(world, -28, 17)
    addCeilingLight(world, 0, 17)
    addCeilingLight(world, 28, 17)

    -- Invisible spawn. No giant colored pad in premium room.
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "M1Spawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(0, 0.5, 24)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Transparency = 1
    spawn.CanCollide = false
    spawn.Parent = world

    buildServiceCounter(world)
    buildConveyor(world)
    local scannerAnchor = buildScanner(world)
    local tagReader, openTray = buildInspectionDesk(world)

    -- Main identity sign
    local signFrame = part(world, "MainSignFrame", Vector3.new(31, 5.8, 0.7), CFrame.new(12, 11.2, -30.65), COLORS.DarkMetal, Enum.Material.Metal)
    signFrame.CanCollide = false
    local sign = part(world, "MainSign", Vector3.new(29.5, 4.5, 0.12), CFrame.new(12, 11.2, -30.25), Color3.fromRGB(13, 17, 23), Enum.Material.SmoothPlastic)
    sign.CanCollide = false
    addLabel(sign, "LOST PROPERTY OPERATIONS\nNIGHT SHIFT", Enum.NormalId.Front, COLORS.Amber)

    -- Storage makes the room read like an actual operational Lost & Found.
    addStorageRack(world, -35, 12)
    addStorageRack(world, -27, 12)

    -- Claimant zone separated from staff equipment.
    local claimantBase = part(world, "ClaimantZone", Vector3.new(9, 0.25, 8), CFrame.new(13, 0.13, -1.5), Color3.fromRGB(39, 43, 50), Enum.Material.SmoothPlastic)
    claimantBase.CanCollide = false
    local claimEdgeA = nonCollide(part(world, "ClaimEdgeA", Vector3.new(9, 0.08, 0.12), CFrame.new(13, 0.31, 2.48), COLORS.AmberSoft, Enum.Material.Neon))
    local claimEdgeB = nonCollide(part(world, "ClaimEdgeB", Vector3.new(9, 0.08, 0.12), CFrame.new(13, 0.31, -5.48), COLORS.AmberSoft, Enum.Material.Neon))
    claimEdgeA.Transparency = 0.2
    claimEdgeB.Transparency = 0.2
    addLabel(claimantBase, "CLAIMANT WAIT", Enum.NormalId.Top, COLORS.Amber)

    local claimantMarker = part(world, "ClaimantMarker", Vector3.new(1, 0.2, 1), CFrame.new(13, 0.2, -1.5), COLORS.Amber, Enum.Material.SmoothPlastic)
    claimantMarker.Transparency = 1
    claimantMarker.CanCollide = false

    -- Decisions are now operational consoles, not glowing arcade pads.
    local decisions = {}
    decisions.RETURN = buildDecisionConsole(world, "RETURN", COLORS.Green, CFrame.new(25, 0, 8))
    decisions.STORE = buildDecisionConsole(world, "STORE", COLORS.CyanSoft, CFrame.new(34, 0, 8))
    decisions.QUARANTINE = buildDecisionConsole(world, "QUARANTINE", COLORS.Amber, CFrame.new(25, 0, 16))
    decisions.SECURITY = buildDecisionConsole(world, "SECURITY", COLORS.Red, CFrame.new(34, 0, 16))

    -- Procedure board
    local procedureFrame = part(world, "ProcedureFrame", Vector3.new(17.5, 8.5, 0.55), CFrame.new(-34, 8.1, -30.7), COLORS.DarkMetal, Enum.Material.Metal)
    procedureFrame.CanCollide = false
    local procedure = part(world, "ProcedureBoard", Vector3.new(16.2, 7.2, 0.12), CFrame.new(-34, 8.1, -30.34), Color3.fromRGB(16, 21, 28), Enum.Material.SmoothPlastic)
    procedure.CanCollide = false
    addLabel(procedure, "NIGHT SHIFT PROCEDURE\n\n01  SCAN\n02  CHECK TAG\n03  OPEN / INSPECT\n04  DECIDE", Enum.NormalId.Front, COLORS.White)

    -- Restricted quarantine access
    local qFrame = part(world, "QuarantineFrame", Vector3.new(14, 13.5, 1.2), CFrame.new(36, 6.75, -30.2), Color3.fromRGB(42, 24, 29), Enum.Material.Metal)
    qFrame.CanCollide = false
    local quarantineDoor = part(world, "QuarantineDoor", Vector3.new(11.8, 11.6, 0.55), CFrame.new(36, 5.9, -29.45), Color3.fromRGB(48, 29, 34), Enum.Material.Metal)
    addLabel(quarantineDoor, "QUARANTINE\nAUTHORIZED ONLY", Enum.NormalId.Front, COLORS.Red)
    local redLamp = nonCollide(part(world, "QuarantineLamp", Vector3.new(3.4, 0.3, 0.65), CFrame.new(36, 13.1, -29.3), COLORS.Red, Enum.Material.Neon))
    addPointLight(redLamp, COLORS.Red, 0.7, 11, true)

    -- Interaction prompts keep the locked gameplay loop intact.
    local scannerPrompt = prompt(scannerAnchor, "SCAN ITEM", "BAGGAGE SCANNER")
    local tagPrompt = prompt(tagReader, "CHECK TAG", "CLAIM TAG")
    local openPrompt = prompt(openTray, "OPEN / INSPECT", "INSPECTION TABLE")

    -- Invisible conveyor markers remain compatible with existing server loop.
    local startMarker = part(world, "ConveyorStart", Vector3.new(1, 1, 1), CFrame.new(-34, 3.6, -8), COLORS.Cyan, Enum.Material.SmoothPlastic)
    startMarker.Transparency = 1
    startMarker.CanCollide = false

    local stopMarker = part(world, "InspectionStop", Vector3.new(1, 1, 1), CFrame.new(-7, 3.6, -8), COLORS.Cyan, Enum.Material.SmoothPlastic)
    stopMarker.Transparency = 1
    stopMarker.CanCollide = false

    return {
        World = world,
        ConveyorStart = startMarker,
        InspectionStop = stopMarker,
        ClaimantMarker = claimantMarker,
        ScannerPrompt = scannerPrompt,
        TagPrompt = tagPrompt,
        OpenPrompt = openPrompt,
        DecisionPrompts = decisions,
    }
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

    local lowerBand = Instance.new("Part")
    lowerBand.Name = "LowerBand"
    lowerBand.Size = Vector3.new(body.Size.X + 0.08, 0.22, body.Size.Z + 0.08)
    lowerBand.CFrame = body.CFrame * CFrame.new(0, -body.Size.Y * 0.28, 0)
    lowerBand.Color = Color3.fromRGB(28, 30, 34)
    lowerBand.Material = Enum.Material.Metal
    lowerBand.Parent = model
    weld(lowerBand, body)

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
    billboard.Size = UDim2.fromOffset(150, 44)
    billboard.StudsOffset = Vector3.new(0, 2.1, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 24
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
    label.BackgroundTransparency = 0.22
    label.TextColor3 = COLORS.White
    label.TextSize = 13
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Text = caseData.claimantName .. (child and "  •  CHILD" or "")
    label.Parent = billboard

    return model
end

return WorldBuilder
