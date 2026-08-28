-- M5-A.3 readability guard: theme wall text is procedural SurfaceGui only.
-- Mirror it to the opposite face so station orientation cannot hide the theme label.

local function mirror(gui)
    if not gui:IsA("SurfaceGui") or gui.Name ~= "ThemeText" then return end
    if gui.Parent and gui.Parent:FindFirstChild("ThemeTextMirror") then return end

    local clone = gui:Clone()
    clone.Name = "ThemeTextMirror"
    clone.Face = gui.Face == Enum.NormalId.Front and Enum.NormalId.Back or Enum.NormalId.Front
    clone.Parent = gui.Parent
end

local function scan(root)
    for _, item in ipairs(root:GetDescendants()) do
        mirror(item)
    end
    root.DescendantAdded:Connect(function(item)
        task.defer(mirror, item)
    end)
end

local function bindStation(station)
    if not station:IsA("Model") or string.sub(station.Name, 1, 8) ~= "Station_" then return end
    local existing = station:FindFirstChild("ThemeDecorations")
    if existing then scan(existing) end
    station.ChildAdded:Connect(function(child)
        if child.Name == "ThemeDecorations" then
            task.defer(scan, child)
        end
    end)
end

local function bindWorld(world)
    if world.Name ~= "LostAndFoundM4D" then return end
    for _, child in ipairs(world:GetChildren()) do bindStation(child) end
    world.ChildAdded:Connect(bindStation)
end

local world = workspace:FindFirstChild("LostAndFoundM4D")
if world then task.defer(bindWorld, world) end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then task.defer(bindWorld, child) end
end)
