-- M1/M2 mobile interaction ergonomics.
-- Keep TAG and OPEN side-by-side at the front of the inspection desk so
-- players can use both from the floor. Panels are tilted upright so their
-- TOP SurfaceGui labels face the approaching player instead of the ceiling.

task.spawn(function()
    local world = workspace:WaitForChild("LostAndFoundM1", 30)
    if not world then return end

    local desk = world:WaitForChild("PremiumInspectionDesk", 15)
    if not desk then return end

    local tagReader = desk:WaitForChild("TagReader", 10)
    local openTray = desk:WaitForChild("OpenTray", 10)
    if not tagReader or not openTray then return end

    -- Front interaction rail: TAG left, OPEN right, same height/depth.
    -- +62deg around X turns each TOP face toward the player (+Z side).
    local tilt = CFrame.Angles(math.rad(62), 0, 0)

    tagReader.Size = Vector3.new(3.2, 0.58, 2.15)
    tagReader.CFrame = CFrame.new(1.15, 2.75, -2.95) * tilt
    tagReader.CanCollide = false

    openTray.Size = Vector3.new(3.6, 0.58, 2.15)
    openTray.CFrame = CFrame.new(5.95, 2.75, -2.95) * tilt
    openTray.CanCollide = false

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
