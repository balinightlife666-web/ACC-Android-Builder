-- M1/M2 mobile interaction ergonomics.
-- Keep TAG and OPEN side-by-side at the front of the inspection desk so
-- players can use both from the floor. The interaction anchors stay low,
-- while dedicated vertical display panels keep the text perfectly upright.

local function makeDisplayPanel(parent, name, position, size, text, textColor)
    local old = parent:FindFirstChild(name)
    if old then old:Destroy() end

    local panel = Instance.new("Part")
    panel.Name = name
    panel.Size = size
    -- Front face points toward +Z (approaching player) after 180deg Y rotation.
    panel.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0)
    panel.Anchored = true
    panel.CanCollide = false
    panel.CanTouch = false
    panel.CanQuery = false
    panel.Color = Color3.fromRGB(25, 31, 40)
    panel.Material = Enum.Material.Metal
    panel.TopSurface = Enum.SurfaceType.Smooth
    panel.BottomSurface = Enum.SurfaceType.Smooth
    panel.Parent = parent

    local gui = Instance.new("SurfaceGui")
    gui.Name = "ReadableLabel"
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0
    gui.PixelsPerStud = 64
    gui.Parent = panel

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = textColor
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui

    return panel
end

task.spawn(function()
    local world = workspace:WaitForChild("LostAndFoundM1", 30)
    if not world then return end

    local desk = world:WaitForChild("PremiumInspectionDesk", 15)
    if not desk then return end

    local tagReader = desk:WaitForChild("TagReader", 10)
    local openTray = desk:WaitForChild("OpenTray", 10)
    if not tagReader or not openTray then return end

    -- Invisible interaction anchors remain side-by-side and floor-accessible.
    tagReader.Size = Vector3.new(3.2, 0.8, 2.15)
    tagReader.CFrame = CFrame.new(1.15, 2.15, -2.72)
    tagReader.CanCollide = false
    tagReader.Transparency = 1

    openTray.Size = Vector3.new(3.6, 0.8, 2.15)
    openTray.CFrame = CFrame.new(5.95, 2.15, -2.72)
    openTray.CanCollide = false
    openTray.Transparency = 1

    -- Dedicated vertical faces: no X/Z tilt, so lettering stays horizontal.
    makeDisplayPanel(
        desk,
        "TagReaderDisplay",
        Vector3.new(1.15, 3.1, -3.05),
        Vector3.new(3.3, 1.65, 0.22),
        "TAG\nREADER",
        Color3.fromRGB(235, 177, 78)
    )

    makeDisplayPanel(
        desk,
        "OpenInspectDisplay",
        Vector3.new(5.95, 3.1, -3.05),
        Vector3.new(3.8, 1.65, 0.22),
        "OPEN /\nINSPECT",
        Color3.fromRGB(235, 238, 242)
    )

    local tagPrompt = tagReader:FindFirstChildOfClass("ProximityPrompt")
    if tagPrompt then
        tagPrompt.MaxActivationDistance = 7.5
        tagPrompt.RequiresLineOfSight = false
    end

    local openPrompt = openTray:FindFirstChildOfClass("ProximityPrompt")
    if openPrompt then
        openPrompt.MaxActivationDistance = 7.5
        openPrompt.RequiresLineOfSight = false
    end
end)
