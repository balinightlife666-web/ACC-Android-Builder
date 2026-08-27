local world = workspace:WaitForChild("LostAndFoundM4D", 30)
if not world then return end

local DECISION_COLORS = {
    RETURN = Color3.fromRGB(58, 170, 90),
    STORE = Color3.fromRGB(58, 158, 194),
    QUARANTINE = Color3.fromRGB(214, 151, 55),
    SECURITY = Color3.fromRGB(190, 58, 62),
}

local function paintConsole(station, decision, color)
    local console = station:FindFirstChild(decision .. "Console")
    if not console then return end

    local top = console:FindFirstChild("Top")
    if top and top:IsA("BasePart") then
        top:SetAttribute("StationSkinRole", "decisionColor")
        top.Color = color
        top.Material = Enum.Material.Neon
    end

    local footGlow = console:FindFirstChild("FootGlow")
    if footGlow and footGlow:IsA("BasePart") then
        footGlow:SetAttribute("StationSkinRole", "decisionColor")
        footGlow.Color = color
        footGlow.Material = Enum.Material.Neon
    end

    local face = console:FindFirstChild("DecisionFace")
    if face then
        local gui = face:FindFirstChildOfClass("SurfaceGui")
        local label = gui and gui:FindFirstChild("Text")
        if label and label:IsA("TextLabel") then
            label.TextColor3 = color
        end
    end
end

local function applyStation(station)
    if not station:IsA("Model") or not station:GetAttribute("StationId") then return end
    for decision, color in pairs(DECISION_COLORS) do
        paintConsole(station, decision, color)
    end
end

for _, station in ipairs(world:GetChildren()) do
    applyStation(station)
end

world.ChildAdded:Connect(function(child)
    task.defer(applyStation, child)
end)
