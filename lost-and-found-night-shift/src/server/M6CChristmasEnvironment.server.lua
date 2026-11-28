-- Event-gated decorative geometry only. Does not modify station geometry or Lighting.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local state = ReplicatedStorage:WaitForChild("LostAndFoundLiveServiceState")
local NAME = "M6CChristmasDecor"
local EVENT = "CHRISTMAS_2026"
local green = Color3.fromRGB(31, 76, 55)
local red = Color3.fromRGB(155, 46, 51)
local gold = Color3.fromRGB(222, 183, 102)
local function part(parent, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end
local function gift(parent, x, z, size, color)
    local y = size.Y / 2 + 0.15
    local cf = CFrame.new(x, y, z)
    part(parent, "Gift", size, cf, color)
    part(parent, "RibbonTop", Vector3.new(size.X + 0.03, 0.03, 0.18), cf * CFrame.new(0, size.Y/2 + 0.015, 0), gold)
    part(parent, "RibbonFront", Vector3.new(0.18, size.Y, 0.03), cf * CFrame.new(0, 0, -size.Z/2 - 0.015), gold)
end
local function reconcile()
    local world = workspace:FindFirstChild("LostAndFoundM4D")
    if not world then return end
    local old = world:FindFirstChild(NAME)
    local active = state:GetAttribute("Active") == true and state:GetAttribute("EventId") == EVENT and state:GetAttribute("ActivationReady") == true
    if not active then
        if old then old:Destroy() end
        return
    end
    if old then return end
    local decor = Instance.new("Model")
    decor.Name = NAME
    decor:SetAttribute("EventId", EVENT)
    local board = part(decor, "ChristmasBanner", Vector3.new(24, 2.1, 0.22), CFrame.new(0, 10.3, 40.75) * CFrame.Angles(0, math.rad(180), 0), green, Enum.Material.Metal)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.LightInfluence = 0
    gui.PixelsPerStud = 55
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "CHRISTMAS 2026  •  WINTER PROPERTY SERVICE"
    label.TextColor3 = gold
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui
    for _, x in ipairs({-19, 19}) do
        gift(decor, x, 39, Vector3.new(1.8, 1.25, 1.45), red)
        gift(decor, x + 2, 39, Vector3.new(1.15, 0.8, 1.1), green)
    end
    for _, x in ipairs({-32, -16, 0, 16, 32}) do
        local lamp = part(decor, "WarmSeasonLamp", Vector3.new(4.8, 0.10, 0.28), CFrame.new(x, 17.85, 38.5), gold, Enum.Material.Neon)
        local light = Instance.new("PointLight")
        light.Color = gold
        light.Brightness = 0.35
        light.Range = 11
        light.Shadows = false
        light.Parent = lamp
    end
    decor.Parent = world
end
state:GetAttributeChangedSignal("Revision"):Connect(function() task.defer(reconcile) end)
workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then task.defer(reconcile) end
end)
task.defer(reconcile)
