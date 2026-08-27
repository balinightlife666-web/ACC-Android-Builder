local world = workspace:WaitForChild("LostAndFoundM4D", 30)
if not world then return end

local configuredStations = {}

local function faceBack(part)
    if not part then return end
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("SurfaceGui") then child.Face = Enum.NormalId.Back end
    end
end

local function configureStation(station)
    if not station:IsA("Model") or not station:GetAttribute("StationId") then return end
    if configuredStations[station] then return end
    configuredStations[station] = true

    task.spawn(function()
        local ownerSign = station:WaitForChild("OwnerSign", 8)
        faceBack(ownerSign)
        local showcase = station:WaitForChild("PublicShowcase", 8)
        if showcase then
            faceBack(showcase:WaitForChild("Title", 5))
        end
    end)
end

task.spawn(function()
    faceBack(world:WaitForChild("MainHeader", 8))
    faceBack(world:WaitForChild("LobbySign", 8))
end)

for _, child in ipairs(world:GetChildren()) do configureStation(child) end
world.ChildAdded:Connect(configureStation)
