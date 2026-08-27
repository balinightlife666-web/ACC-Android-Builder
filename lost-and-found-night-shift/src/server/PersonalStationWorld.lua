local Lighting = game:GetService("Lighting")

local PersonalStationWorld = {}

local COLORS = {
    floor = Color3.fromRGB(31, 36, 44),
    wall = Color3.fromRGB(22, 27, 35),
    metal = Color3.fromRGB(70, 80, 94),
    dark = Color3.fromRGB(39, 46, 57),
    panel = Color3.fromRGB(27, 33, 42),
    amber = Color3.fromRGB(224, 163, 64),
    cyan = Color3.fromRGB(69, 177, 214),
    green = Color3.fromRGB(67, 153, 92),
    red = Color3.fromRGB(190, 67, 70),
    white = Color3.fromRGB(240, 243, 247),
    muted = Color3.fromRGB(142, 153, 169),
}

local STATION_LAYOUT = {
    { id = "A", position = Vector3.new(-39, 0, -18) },
    { id = "B", position = Vector3.new(-13, 0, -18) },
    { id = "C", position = Vector3.new(13, 0, -18) },
    { id = "D", position = Vector3.new(39, 0, -18) },
    { id = "E", position = Vector3.new(-39, 0, 18) },
    { id = "F", position = Vector3.new(-13, 0, 18) },
    { id = "G", position = Vector3.new(13, 0, 18) },
    { id = "H", position = Vector3.new(39, 0, 18) },
}

local function part(parent, name, size, cframe, color, material, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = collide ~= false
    p.CanTouch = collide ~= false
    p.CanQuery = true
    p.Color = color or COLORS.metal
    p.Material = material or Enum.Material.Metal
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function rolePart(parent, name, size, cframe, role, color, material, collide)
    local p = part(parent, name, size, cframe, color, material, collide)
    p:SetAttribute("StationSkinRole", role)
    return p
end

local function pointLight(target, color, brightness, range)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = false
    light.Parent = target
    return light
end

local function surfaceText(target, text, face, color, textSize)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "StationText"
    gui.Face = face or Enum.NormalId.Front
    gui.LightInfluence = 0
    gui.PixelsPerStud = 58
    gui.Parent = target

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or COLORS.white
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
    if textSize then label.TextSize = textSize end
    return label
end

local function prompt(target, actionText, objectText, stationId)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = actionText
    p.ObjectText = objectText
    p.MaxActivationDistance = 7
    p.HoldDuration = 0.08
    p.RequiresLineOfSight = false
    p.Enabled = false
    p:SetAttribute("StationId", stationId)
    p.Parent = target
    return p
end

local function configureLighting()
    Lighting.ClockTime = 1.0
    Lighting.Brightness = 2.75
    Lighting.Ambient = Color3.fromRGB(76, 84, 97)
    Lighting.OutdoorAmbient = Color3.fromRGB(38, 44, 53)
    Lighting.EnvironmentDiffuseScale = 0.55
    Lighting.EnvironmentSpecularScale = 0.58

    local atmosphere = Lighting:FindFirstChild("LostAndFoundAtmosphere") or Instance.new("Atmosphere")
    atmosphere.Name = "LostAndFoundAtmosphere"
    atmosphere.Density = 0.045
    atmosphere.Offset = 0.02
    atmosphere.Color = Color3.fromRGB(188, 198, 211)
    atmosphere.Decay = Color3.fromRGB(60, 70, 84)
    atmosphere.Glare = 0
    atmosphere.Haze = 0.18
    atmosphere.Parent = Lighting

    local correction = Lighting:FindFirstChild("LostAndFoundColor") or Instance.new("ColorCorrectionEffect")
    correction.Name = "LostAndFoundColor"
    correction.Brightness = 0.055
    correction.Contrast = 0.025
    correction.Saturation = -0.04
    correction.TintColor = Color3.fromRGB(236, 240, 247)
    correction.Parent = Lighting
end

local function buildDecision(parent, stationId, decision, position, color)
    local model = Instance.new("Model")
    model.Name = decision .. "Console"
    model:SetAttribute("StationId", stationId)
    model.Parent = parent

    rolePart(model, "Base", Vector3.new(4.8, 1.8, 3.0), CFrame.new(position + Vector3.new(0, 0.9, 0)), "base", COLORS.dark, Enum.Material.Metal, true)
    local top = rolePart(model, "Top", Vector3.new(4.5, 0.28, 2.7), CFrame.new(position + Vector3.new(0, 1.94, 0)), "accent", color, Enum.Material.Neon, true)
    surfaceText(top, decision, Enum.NormalId.Top, Color3.fromRGB(250, 251, 253))

    local face = rolePart(
        model,
        "DecisionFace",
        Vector3.new(4.35, 1.0, 0.2),
        CFrame.new(position + Vector3.new(0, 1.45, 1.42)) * CFrame.Angles(0, math.rad(180), 0),
        "panel",
        COLORS.panel,
        Enum.Material.SmoothPlastic,
        false
    )
    surfaceText(face, decision, Enum.NormalId.Front, color)

    rolePart(model, "FootGlow", Vector3.new(4.4, 0.08, 2.75), CFrame.new(position + Vector3.new(0, 0.08, 0)), "accent", color, Enum.Material.Neon, false)
    return prompt(top, decision, "YOUR SHIFT DECISION", stationId)
end

local function buildStation(world, stationId, origin)
    local model = Instance.new("Model")
    model.Name = "Station_" .. stationId
    model:SetAttribute("StationId", stationId)
    model:SetAttribute("OwnerUserId", 0)
    model:SetAttribute("OwnerName", "VACANT")
    model:SetAttribute("SkinId", "STANDARD_OPS")
    model.Parent = world

    local x, z = origin.X, origin.Z
    rolePart(model, "BayFloor", Vector3.new(23.5, 0.22, 28), CFrame.new(x, 0.11, z), "base", COLORS.dark, Enum.Material.Metal, false)
    rolePart(model, "BackPanel", Vector3.new(22.5, 7.5, 0.35), CFrame.new(x, 4.2, z - 13.6), "panel", COLORS.panel, Enum.Material.Metal, false)

    -- Clear visual boundary between eight personal bays. Neon trim has no shadows/lights.
    rolePart(model, "BoundaryLeft", Vector3.new(0.10, 0.09, 27.2), CFrame.new(x - 11.65, 0.29, z), "accent", COLORS.amber, Enum.Material.Neon, false)
    rolePart(model, "BoundaryRight", Vector3.new(0.10, 0.09, 27.2), CFrame.new(x + 11.65, 0.29, z), "accent", COLORS.amber, Enum.Material.Neon, false)
    rolePart(model, "BoundaryFront", Vector3.new(23.2, 0.09, 0.10), CFrame.new(x, 0.29, z + 13.85), "accent", COLORS.amber, Enum.Material.Neon, false)
    rolePart(model, "BoundaryBack", Vector3.new(23.2, 0.09, 0.10), CFrame.new(x, 0.29, z - 13.85), "accent", COLORS.amber, Enum.Material.Neon, false)

    local floorId = rolePart(model, "FloorStationId", Vector3.new(5.8, 0.12, 2.2), CFrame.new(x, 0.31, z + 10.6), "panel", COLORS.panel, Enum.Material.SmoothPlastic, false)
    surfaceText(floorId, "STATION " .. stationId, Enum.NormalId.Top, COLORS.amber)

    local sign = rolePart(model, "OwnerSign", Vector3.new(16.5, 3.0, 0.24), CFrame.new(x, 6.15, z - 13.34), "panel", COLORS.panel, Enum.Material.SmoothPlastic, false)
    local ownerLabel = surfaceText(sign, "STATION " .. stationId .. "\nVACANT", Enum.NormalId.Front, COLORS.amber)
    ownerLabel.Name = "OwnerLabel"

    local signGlow = rolePart(model, "OwnerSignGlow", Vector3.new(16.8, 0.12, 0.14), CFrame.new(x, 7.72, z - 13.18), "accent", COLORS.amber, Enum.Material.Neon, false)
    pointLight(signGlow, COLORS.amber, 0.36, 8)

    local accent = rolePart(model, "OwnerAccent", Vector3.new(18, 0.14, 0.14), CFrame.new(x, 2.15, z - 13.15), "accent", COLORS.amber, Enum.Material.Neon, false)

    -- One soft fill light per station keeps mobile readability without flooding the server with lights.
    local workLight = rolePart(model, "WorkLight", Vector3.new(8.8, 0.12, 0.45), CFrame.new(x + 1.8, 8.45, z - 3.8), "trim", COLORS.white, Enum.Material.Neon, false)
    pointLight(workLight, COLORS.white, 0.58, 13)

    local conveyor = Instance.new("Model")
    conveyor.Name = "Conveyor"
    conveyor.Parent = model
    rolePart(conveyor, "Base", Vector3.new(15.5, 1.4, 4.6), CFrame.new(x - 2.1, 0.8, z - 6.5), "base", COLORS.dark, Enum.Material.Metal, true)
    rolePart(conveyor, "Belt", Vector3.new(14.7, 0.28, 3.7), CFrame.new(x - 2.1, 1.62, z - 6.5), "panel", Color3.fromRGB(22, 26, 33), Enum.Material.DiamondPlate, true)

    local scanner = rolePart(model, "Scanner", Vector3.new(1.15, 4.4, 4.8), CFrame.new(x - 4.7, 3.2, z - 6.5), "base", Color3.fromRGB(48, 59, 72), Enum.Material.Metal, false)
    local scannerGlow = rolePart(model, "ScannerGlow", Vector3.new(0.15, 3.5, 3.9), CFrame.new(x - 4.08, 3.2, z - 6.5), "accent", COLORS.cyan, Enum.Material.Neon, false)
    pointLight(scannerGlow, COLORS.cyan, 0.32, 7)
    local scannerPrompt = prompt(scanner, "SCAN ITEM", "STATION " .. stationId .. " SCANNER", stationId)

    local desk = Instance.new("Model")
    desk.Name = "InspectionDesk"
    desk.Parent = model
    rolePart(desk, "DeskBase", Vector3.new(10, 1.8, 5.4), CFrame.new(x + 5.2, 0.95, z - 1.3), "base", COLORS.dark, Enum.Material.Metal, true)
    rolePart(desk, "DeskTop", Vector3.new(10.4, 0.28, 5.7), CFrame.new(x + 5.2, 2.0, z - 1.3), "trim", COLORS.metal, Enum.Material.Metal, true)

    local tagReader = rolePart(desk, "TagReader", Vector3.new(3.8, 0.45, 2.0), CFrame.new(x + 2.7, 2.35, z - 0.8), "panel", COLORS.panel, Enum.Material.SmoothPlastic, true)
    surfaceText(tagReader, "TAG", Enum.NormalId.Top, COLORS.amber)
    local tagPrompt = prompt(tagReader, "CHECK TAG", "STATION " .. stationId .. " TAG", stationId)

    local openTray = rolePart(desk, "OpenTray", Vector3.new(4.2, 0.45, 2.0), CFrame.new(x + 7.3, 2.35, z - 0.8), "trim", COLORS.metal, Enum.Material.Metal, true)
    surfaceText(openTray, "OPEN / INSPECT", Enum.NormalId.Top, COLORS.white)
    local openPrompt = prompt(openTray, "OPEN / INSPECT", "STATION " .. stationId .. " TABLE", stationId)

    local decisions = {}
    local decisionZ = z + 7.4
    decisions.RETURN = buildDecision(model, stationId, "RETURN", Vector3.new(x - 7.2, 0, decisionZ), COLORS.green)
    decisions.STORE = buildDecision(model, stationId, "STORE", Vector3.new(x - 2.4, 0, decisionZ), COLORS.cyan)
    decisions.QUARANTINE = buildDecision(model, stationId, "QUARANTINE", Vector3.new(x + 2.4, 0, decisionZ), COLORS.amber)
    decisions.SECURITY = buildDecision(model, stationId, "SECURITY", Vector3.new(x + 7.2, 0, decisionZ), COLORS.red)

    local claimantZone = rolePart(model, "ClaimantZone", Vector3.new(5.2, 0.12, 4.8), CFrame.new(x + 8.2, 0.08, z - 7.0), "panel", COLORS.panel, Enum.Material.SmoothPlastic, false)
    surfaceText(claimantZone, "CLAIMANT", Enum.NormalId.Top, COLORS.muted)

    local itemFolder = Instance.new("Folder")
    itemFolder.Name = "ActiveCaseObjects"
    itemFolder.Parent = model

    local startMarker = part(model, "ConveyorStart", Vector3.new(0.4, 0.4, 0.4), CFrame.new(x - 8.4, 3.6, z - 6.5), COLORS.cyan, Enum.Material.SmoothPlastic, false)
    startMarker.Transparency = 1
    startMarker.CanQuery = false

    local stopMarker = part(model, "InspectionStop", Vector3.new(0.4, 0.4, 0.4), CFrame.new(x - 0.2, 3.6, z - 6.5), COLORS.cyan, Enum.Material.SmoothPlastic, false)
    stopMarker.Transparency = 1
    stopMarker.CanQuery = false

    local claimantMarker = part(model, "ClaimantMarker", Vector3.new(0.4, 0.4, 0.4), CFrame.new(x + 8.2, 0.25, z - 7.0), COLORS.amber, Enum.Material.SmoothPlastic, false)
    claimantMarker.Transparency = 1
    claimantMarker.CanQuery = false

    local spawnAnchor = part(model, "SpawnAnchor", Vector3.new(1, 1, 1), CFrame.new(x, 2.8, z + 11.0), COLORS.white, Enum.Material.SmoothPlastic, false)
    spawnAnchor.Transparency = 1
    spawnAnchor.CanQuery = false

    local guideAnchor = part(model, "GuideAnchor", Vector3.new(1, 1, 1), CFrame.new(x, 5.2, z - 11.7), COLORS.amber, Enum.Material.SmoothPlastic, false)
    guideAnchor.Transparency = 1
    guideAnchor.CanQuery = false

    local showcase = Instance.new("Model")
    showcase.Name = "PublicShowcase"
    showcase.Parent = model
    rolePart(showcase, "ShelfBack", Vector3.new(5.5, 4.4, 0.28), CFrame.new(x - 8.5, 3.7, z - 12.9), "panel", COLORS.panel, Enum.Material.Metal, false)
    local showcaseTitle = rolePart(showcase, "Title", Vector3.new(5.0, 0.75, 0.16), CFrame.new(x - 8.5, 5.45, z - 12.65), "accent", COLORS.amber, Enum.Material.SmoothPlastic, false)
    surfaceText(showcaseTitle, "SHOWCASE", Enum.NormalId.Front, Color3.fromRGB(20, 22, 27))
    local displayAnchors = {}
    for index, dx in ipairs({-1.6, 0, 1.6}) do
        rolePart(showcase, "Shelf" .. index, Vector3.new(1.35, 0.15, 1.35), CFrame.new(x - 8.5 + dx, 2.25, z - 12.1), "trim", COLORS.metal, Enum.Material.Metal, false)
        local anchor = part(showcase, "DisplayAnchor" .. index, Vector3.new(0.4, 0.4, 0.4), CFrame.new(x - 8.5 + dx, 3.05, z - 12.05), COLORS.white, Enum.Material.SmoothPlastic, false)
        anchor.Transparency = 1
        anchor.CanQuery = false
        table.insert(displayAnchors, anchor)
    end

    return {
        Id = stationId,
        Model = model,
        OwnerSign = sign,
        OwnerLabel = ownerLabel,
        ScannerPrompt = scannerPrompt,
        TagPrompt = tagPrompt,
        OpenPrompt = openPrompt,
        DecisionPrompts = decisions,
        ConveyorStart = startMarker,
        InspectionStop = stopMarker,
        ClaimantMarker = claimantMarker,
        SpawnAnchor = spawnAnchor,
        GuideAnchor = guideAnchor,
        ObjectFolder = itemFolder,
        Showcase = showcase,
        DisplayAnchors = displayAnchors,
    }
end

function PersonalStationWorld.ApplySkin(station, skin)
    if not station or not station.Model or not skin then return end
    local palette = skin.palette or {}
    station.Model:SetAttribute("SkinId", skin.id or "STANDARD_OPS")

    for _, instance in ipairs(station.Model:GetDescendants()) do
        if instance:IsA("BasePart") then
            local role = instance:GetAttribute("StationSkinRole")
            if role and palette[role] then
                instance.Color = palette[role]
            end
        elseif instance:IsA("PointLight") and palette.light then
            instance.Color = palette.light
        end
    end
end

function PersonalStationWorld.SetOwner(station, player, skin)
    if not station or not station.Model then return end
    local occupied = player ~= nil
    local userId = occupied and player.UserId or 0
    local displayName = occupied and player.DisplayName or "VACANT"
    station.Model:SetAttribute("OwnerUserId", userId)
    station.Model:SetAttribute("OwnerName", displayName)

    if occupied then
        PersonalStationWorld.ApplySkin(station, skin)
        station.OwnerLabel.Text = "STATION " .. station.Id .. "\n" .. string.upper(displayName)
    else
        station.OwnerLabel.Text = "STATION " .. station.Id .. "\nVACANT"
    end

    for _, promptObject in ipairs({station.ScannerPrompt, station.TagPrompt, station.OpenPrompt}) do
        promptObject.Enabled = false
    end
    for _, decisionPrompt in pairs(station.DecisionPrompts) do
        decisionPrompt.Enabled = false
    end
end

function PersonalStationWorld.Build()
    configureLighting()

    for _, oldName in ipairs({"LostAndFoundM0", "LostAndFoundM1", "LostAndFoundM4D"}) do
        local old = workspace:FindFirstChild(oldName)
        if old then old:Destroy() end
    end

    local world = Instance.new("Model")
    world.Name = "LostAndFoundM4D"
    world.Parent = workspace

    part(world, "Floor", Vector3.new(108, 1, 82), CFrame.new(0, -0.5, 0), COLORS.floor, Enum.Material.Concrete, true)
    part(world, "BackWall", Vector3.new(108, 19, 1), CFrame.new(0, 9.5, -41.5), COLORS.wall, Enum.Material.Concrete, true)
    part(world, "FrontWall", Vector3.new(108, 19, 1), CFrame.new(0, 9.5, 41.5), COLORS.wall, Enum.Material.Concrete, true)
    part(world, "LeftWall", Vector3.new(1, 19, 82), CFrame.new(-54.5, 9.5, 0), COLORS.wall, Enum.Material.Concrete, true)
    part(world, "RightWall", Vector3.new(1, 19, 82), CFrame.new(54.5, 9.5, 0), COLORS.wall, Enum.Material.Concrete, true)
    part(world, "Ceiling", Vector3.new(108, 1, 82), CFrame.new(0, 19.2, 0), Color3.fromRGB(18, 22, 28), Enum.Material.Metal, true)

    local header = part(world, "MainHeader", Vector3.new(37, 4.8, 0.35), CFrame.new(0, 12.5, -40.85), COLORS.panel, Enum.Material.Metal, false)
    surfaceText(header, "LOST PROPERTY OPERATIONS\nPERSONAL NIGHT SHIFTS", Enum.NormalId.Front, COLORS.amber)

    for _, x in ipairs({-39, -13, 13, 39}) do
        local light = part(world, "CeilingLight", Vector3.new(16, 0.18, 1.0), CFrame.new(x, 18.3, -18), Color3.fromRGB(232, 238, 246), Enum.Material.Neon, false)
        pointLight(light, Color3.fromRGB(228, 235, 244), 1.0, 24)
        local light2 = part(world, "CeilingLight", Vector3.new(16, 0.18, 1.0), CFrame.new(x, 18.3, 18), Color3.fromRGB(232, 238, 246), Enum.Material.Neon, false)
        pointLight(light2, Color3.fromRGB(228, 235, 244), 1.0, 24)
    end

    local centerLight = part(world, "CenterFill", Vector3.new(28, 0.16, 0.8), CFrame.new(0, 18.1, 0), Color3.fromRGB(211, 222, 236), Enum.Material.Neon, false)
    pointLight(centerLight, Color3.fromRGB(218, 228, 240), 0.75, 28)

    local lobbySign = part(world, "LobbySign", Vector3.new(24, 2.7, 0.3), CFrame.new(0, 7.2, 40.8) * CFrame.Angles(0, math.rad(180), 0), COLORS.panel, Enum.Material.Metal, false)
    surfaceText(lobbySign, "JOIN → GET A STATION → WORK YOUR SHIFT → COLLECT → TRADE", Enum.NormalId.Front, COLORS.white)

    local lobbySpawn = Instance.new("SpawnLocation")
    lobbySpawn.Name = "LobbySpawn"
    lobbySpawn.Size = Vector3.new(8, 1, 8)
    lobbySpawn.CFrame = CFrame.new(0, 0.5, 35)
    lobbySpawn.Anchored = true
    lobbySpawn.Neutral = true
    lobbySpawn.Transparency = 1
    lobbySpawn.CanCollide = false
    lobbySpawn.Parent = world

    local stations = {}
    for _, data in ipairs(STATION_LAYOUT) do
        local station = buildStation(world, data.id, data.position)
        stations[data.id] = station
    end

    return {
        World = world,
        Stations = stations,
        Order = {"A", "B", "C", "D", "E", "F", "G", "H"},
        LobbySpawn = lobbySpawn,
    }
end

return PersonalStationWorld