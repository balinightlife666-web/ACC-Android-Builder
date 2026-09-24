-- LOST & FOUND: NIGHT SHIFT — M6-C Halloween environment dresser.
-- Runs only when the replicated live-service state says HALLOWEEN_2026 is active.
-- Decorations are anchored/non-colliding and remain outside core station interaction lanes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local state = ReplicatedStorage:WaitForChild("LostAndFoundLiveServiceState")
local DECOR_NAME = "M6CSeasonalDecor"

local function part(parent, name, size, cframe, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end

local function addPumpkin(parent, position, scale)
    scale = scale or 1
    local model = Instance.new("Model")
    model.Name = "Pumpkin"
    model.Parent = parent

    for i = -1, 1 do
        local lobe = part(
            model,
            "Lobe" .. tostring(i),
            Vector3.new(1.45, 1.25, 1.35) * scale,
            CFrame.new(position + Vector3.new(i * 0.42 * scale, 0, 0)),
            Color3.fromRGB(198, 91, 32),
            Enum.Material.SmoothPlastic,
            Enum.PartType.Ball
        )
        if i == 0 then
            local light = Instance.new("PointLight")
            light.Name = "PumpkinGlow"
            light.Color = Color3.fromRGB(243, 141, 58)
            light.Brightness = 0.45
            light.Range = 7
            light.Shadows = false
            light.Parent = lobe
        end
    end

    part(
        model,
        "Stem",
        Vector3.new(0.28, 0.55, 0.28) * scale,
        CFrame.new(position + Vector3.new(0, 0.78 * scale, 0)),
        Color3.fromRGB(65, 79, 48),
        Enum.Material.Wood
    )

    return model
end

local function addBanner(parent)
    local board = part(
        parent,
        "HalloweenBanner",
        Vector3.new(24, 2.4, 0.22),
        CFrame.new(0, 9.2, 40.75) * CFrame.Angles(0, math.rad(180), 0),
        Color3.fromRGB(28, 22, 34),
        Enum.Material.Metal
    )

    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.LightInfluence = 0
    surface.PixelsPerStud = 55
    surface.Parent = board

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = "HALLOWEEN 2026  •  NIGHT PROPERTY PROTOCOL"
    text.TextColor3 = Color3.fromRGB(239, 148, 65)
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Parent = surface
end

local function clearDecor()
    local world = workspace:FindFirstChild("LostAndFoundM4D")
    local old = world and world:FindFirstChild(DECOR_NAME)
    if old then old:Destroy() end
end

local function applyHalloween()
    local world = workspace:FindFirstChild("LostAndFoundM4D")
    if not world then return false end

    clearDecor()

    local decor = Instance.new("Model")
    decor.Name = DECOR_NAME
    decor:SetAttribute("EventId", "HALLOWEEN_2026")
    decor.Parent = world

    -- Lobby/front-wall dressing only: never occupy SCAN/TAG/OPEN/decision lanes.
    addBanner(decor)
    addPumpkin(decor, Vector3.new(-13, 0.85, 37.5), 1.05)
    addPumpkin(decor, Vector3.new(13, 0.85, 37.5), 1.05)
    addPumpkin(decor, Vector3.new(-20, 0.65, 39.0), 0.72)
    addPumpkin(decor, Vector3.new(20, 0.65, 39.0), 0.72)

    for _, x in ipairs({-32, -16, 0, 16, 32}) do
        local lamp = part(
            decor,
            "SeasonLamp",
            Vector3.new(4.8, 0.10, 0.28),
            CFrame.new(x, 17.85, 38.5),
            Color3.fromRGB(146, 83, 169),
            Enum.Material.Neon
        )
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(157, 91, 181)
        light.Brightness = 0.35
        light.Range = 11
        light.Shadows = false
        light.Parent = lamp
    end

    return true
end

local function reconcile()
    local active = state:GetAttribute("Active") == true
    local eventId = tostring(state:GetAttribute("EventId") or "")

    if active and eventId == "HALLOWEEN_2026" then
        if not applyHalloween() then
            task.delay(0.5, reconcile)
        end
    else
        clearDecor()
    end
end

state:GetAttributeChangedSignal("Revision"):Connect(function()
    task.defer(reconcile)
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then
        task.defer(reconcile)
    end
end)

task.defer(reconcile)
