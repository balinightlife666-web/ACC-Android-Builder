local world = workspace:WaitForChild("LostAndFoundM4D", 30)
if not world then return end

local function faceBack(part)
    if not part then return end
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("SurfaceGui") then child.Face = Enum.NormalId.Back end
    end
end

faceBack(world:FindFirstChild("MainHeader"))
faceBack(world:FindFirstChild("LobbySign"))

for _, station in ipairs(world:GetChildren()) do
    if station:IsA("Model") and station:GetAttribute("StationId") then
        faceBack(station:FindFirstChild("OwnerSign"))
        local showcase = station:FindFirstChild("PublicShowcase")
        if showcase then faceBack(showcase:FindFirstChild("Title")) end
    end
end
