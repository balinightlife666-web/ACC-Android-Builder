local Players = game:GetService("Players")

local player = Players.LocalPlayer
local filtered = false

local function filterWorld()
    local stationId = tostring(player:GetAttribute("LostFoundStationId") or "")
    if stationId == "" then return end

    local world = workspace:FindFirstChild("LostAndFoundM4D")
    if not world then return end

    local function filter(instance)
        if not instance:IsA("ProximityPrompt") then return end
        local promptStation = tostring(instance:GetAttribute("StationId") or "")
        if promptStation ~= "" and promptStation ~= stationId then
            instance.Enabled = false
        end
    end

    for _, instance in ipairs(world:GetDescendants()) do filter(instance) end
    if not filtered then
        filtered = true
        world.DescendantAdded:Connect(filter)
    end
end

player:GetAttributeChangedSignal("LostFoundStationId"):Connect(function()
    task.defer(filterWorld)
end)

task.spawn(function()
    workspace:WaitForChild("LostAndFoundM4D", 30)
    filterWorld()
end)
