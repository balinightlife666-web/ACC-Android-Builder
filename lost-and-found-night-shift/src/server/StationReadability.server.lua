-- M4-D.1 world-label readability tuning.
-- Keeps serialized showcase labels useful for social flex without letting them
-- float aggressively over the mobile HUD.

local world = workspace:WaitForChild("LostAndFoundM4D", 30)
if not world then return end

local function tuneSerialLabel(instance)
    if not instance:IsA("BillboardGui") or instance.Name ~= "SerialLabel" then return end

    instance.AlwaysOnTop = false
    instance.MaxDistance = 13
    instance.Size = UDim2.fromOffset(108, 22)
    instance.StudsOffset = Vector3.new(0, 1.25, 0)

    for _, child in ipairs(instance:GetChildren()) do
        if child:IsA("TextLabel") then
            child.BackgroundTransparency = 0.32
            child.TextSize = 8
            child.TextStrokeTransparency = 0.82
        end
    end
end

for _, descendant in ipairs(world:GetDescendants()) do
    tuneSerialLabel(descendant)
end

world.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("BillboardGui") and descendant.Name == "SerialLabel" then
        task.defer(tuneSerialLabel, descendant)
    end
end)
