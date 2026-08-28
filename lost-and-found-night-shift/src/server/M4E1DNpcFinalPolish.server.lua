-- LOST & FOUND: NIGHT SHIFT — M4-E.1D final claimant polish overlay.
-- M4-E.1C already owns body construction, grounding, face orientation and eight
-- character profiles. This script adds a bounded final layer only after that pass
-- completes: hair depth, small outfit details and readable glasses. Roblox-only.

local Workspace = game:GetService("Workspace")

local SOURCE_VERSION = "M4E1C_NPC_V4"
local FINAL_VERSION = "M4E1D_NPC_FINAL_V1"
local RETRY_COUNT = 20
local RETRY_DELAY = 0.10
local RECONCILE_SECONDS = 1.25

local GENERATED = {
    FinalHairA = true,
    FinalHairB = true,
    FinalHairSideL = true,
    FinalHairSideR = true,
    FinalPocketL = true,
    FinalPocketR = true,
    FinalChestTrim = true,
    FinalDrawL = true,
    FinalDrawR = true,
    FinalSleeveBandL = true,
    FinalSleeveBandR = true,
}

local pending = setmetatable({}, { __mode = "k" })

local function hashText(text)
    local h = 19
    for i = 1, #text do
        h = (h * 33 + string.byte(text, i)) % 2147483647
    end
    return h
end

local function makePart(parent, name, size, cframe, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = true
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function makeWedge(parent, name, size, cframe, color)
    local p = Instance.new("WedgePart")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = true
    p.Color = color
    p.Material = Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function cleanup(model)
    for _, child in ipairs(model:GetChildren()) do
        if GENERATED[child.Name] then
            child:Destroy()
        end
    end
end

local function findHairColor(model)
    for _, name in ipairs({ "HairCap", "HairTop", "HairBack", "HairSide", "CapTop" }) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part.Color
        end
    end
    return Color3.fromRGB(34, 31, 30)
end

local function claimantName(model)
    local value = model:GetAttribute("ClaimantName")
    if type(value) == "string" and value ~= "" then return value end
    return "CLAIMANT"
end

local function polishGlasses(model)
    local left = model:FindFirstChild("GlassesL")
    local right = model:FindFirstChild("GlassesR")
    local bridge = model:FindFirstChild("GlassesBridge")

    for _, lens in ipairs({ left, right }) do
        if lens and lens:IsA("BasePart") then
            lens.Material = Enum.Material.Glass
            lens.Transparency = 0.66
            lens.Size = Vector3.new(math.min(lens.Size.X, 0.40), math.min(lens.Size.Y, 0.24), 0.035)
            lens.CastShadow = false
        end
    end

    if bridge and bridge:IsA("BasePart") then
        bridge.Transparency = 0.16
        bridge.Size = Vector3.new(math.min(bridge.Size.X, 0.18), 0.035, 0.035)
        bridge.CastShadow = false
    end
end

local function addHairDepth(model, head, hairColor, profileId, h)
    if profileId == "CAP_VEST" then
        -- Keep the cap readable while adding only two small locks below the brim.
        makeWedge(model, "FinalHairA", Vector3.new(0.22, 0.26, 0.13), head.CFrame * CFrame.new(-head.Size.X * 0.26, head.Size.Y * 0.25, -(head.Size.Z * 0.49)) * CFrame.Angles(0, 0, math.rad(9)), hairColor)
        makeWedge(model, "FinalHairB", Vector3.new(0.20, 0.24, 0.13), head.CFrame * CFrame.new(head.Size.X * 0.24, head.Size.Y * 0.24, -(head.Size.Z * 0.49)) * CFrame.Angles(0, 0, math.rad(-8)), hairColor)
        return
    end

    local skew = ((h % 5) - 2) * 0.025
    makeWedge(model, "FinalHairA", Vector3.new(0.28, 0.34, 0.15), head.CFrame * CFrame.new(-head.Size.X * 0.24 + skew, head.Size.Y * 0.25, -(head.Size.Z * 0.50)) * CFrame.Angles(0, 0, math.rad(10)), hairColor)
    makeWedge(model, "FinalHairB", Vector3.new(0.25, 0.31, 0.15), head.CFrame * CFrame.new(head.Size.X * 0.18 + skew, head.Size.Y * 0.28, -(head.Size.Z * 0.50)) * CFrame.Angles(0, 0, math.rad(-11)), hairColor)

    if profileId == "MID_LENGTH" or profileId == "LONG_LAYER" or profileId == "BUN_COAT" then
        makePart(model, "FinalHairSideL", Vector3.new(0.12, head.Size.Y * 0.48, 0.16), head.CFrame * CFrame.new(-head.Size.X * 0.47, -0.10, -(head.Size.Z * 0.24)), hairColor)
        makePart(model, "FinalHairSideR", Vector3.new(0.12, head.Size.Y * 0.48, 0.16), head.CFrame * CFrame.new(head.Size.X * 0.47, -0.10, -(head.Size.Z * 0.24)), hairColor)
    end
end

local function addOutfitDetail(model, torso, profileId, h)
    local front = -(torso.Size.Z / 2 + 0.12)
    local base = torso.Color
    local trim = base:Lerp(Color3.fromRGB(218, 219, 222), 0.18)
    local dark = base:Lerp(Color3.fromRGB(20, 22, 27), 0.28)

    if profileId == "TRAVEL_HOODIE" then
        makePart(model, "FinalDrawL", Vector3.new(0.035, 0.44, 0.035), torso.CFrame * CFrame.new(-0.12, torso.Size.Y * 0.20, front), trim, Enum.Material.Fabric)
        makePart(model, "FinalDrawR", Vector3.new(0.035, 0.44, 0.035), torso.CFrame * CFrame.new(0.12, torso.Size.Y * 0.20, front), trim, Enum.Material.Fabric)
    else
        makePart(model, "FinalPocketL", Vector3.new(torso.Size.X * 0.22, 0.22, 0.045), torso.CFrame * CFrame.new(-torso.Size.X * 0.25, -torso.Size.Y * 0.17, front), dark, Enum.Material.Fabric)
        makePart(model, "FinalPocketR", Vector3.new(torso.Size.X * 0.22, 0.22, 0.045), torso.CFrame * CFrame.new(torso.Size.X * 0.25, -torso.Size.Y * 0.17, front), dark, Enum.Material.Fabric)
    end

    if h % 2 == 0 then
        makePart(model, "FinalChestTrim", Vector3.new(torso.Size.X * 0.54, 0.055, 0.04), torso.CFrame * CFrame.new(0, torso.Size.Y * 0.08, front - 0.02), trim, Enum.Material.Fabric)
    end

    local leftArm = model:FindFirstChild("UpperArmL")
    local rightArm = model:FindFirstChild("UpperArmR")
    if leftArm and rightArm and leftArm:IsA("BasePart") and rightArm:IsA("BasePart") then
        makePart(model, "FinalSleeveBandL", Vector3.new(leftArm.Size.X + 0.02, 0.09, leftArm.Size.Z + 0.02), leftArm.CFrame * CFrame.new(0, -leftArm.Size.Y * 0.23, 0), trim, Enum.Material.Fabric)
        makePart(model, "FinalSleeveBandR", Vector3.new(rightArm.Size.X + 0.02, 0.09, rightArm.Size.Z + 0.02), rightArm.CFrame * CFrame.new(0, -rightArm.Size.Y * 0.23, 0), trim, Enum.Material.Fabric)
    end
end

local function polish(model)
    if not model or not model.Parent or model.Name ~= "ActiveClaimant" then return false end
    if model:GetAttribute("NpcFinalPolishVersion") == FINAL_VERSION then return true end
    if model:GetAttribute("NpcVisualVersion") ~= SOURCE_VERSION then return false end

    local torso = model:FindFirstChild("Torso")
    local head = model:FindFirstChild("Head")
    if not torso or not head or not torso:IsA("BasePart") or not head:IsA("BasePart") then
        return false
    end

    cleanup(model)

    local headMesh = head:FindFirstChild("M4E1CHeadMesh")
    if headMesh and headMesh:IsA("SpecialMesh") then
        -- Slightly reduce the mannequin/block impression without changing the M4-E.1C
        -- ground/body solution.
        headMesh.Scale = Vector3.new(0.97, 1.00, 0.95)
    end

    local h = hashText(claimantName(model))
    local profileId = model:GetAttribute("NpcCharacterProfile") or "CASUAL_LAYER"
    local hairColor = findHairColor(model)

    addHairDepth(model, head, hairColor, profileId, h)
    addOutfitDetail(model, torso, profileId, h)
    polishGlasses(model)

    model:SetAttribute("NpcFinalPolishVersion", FINAL_VERSION)
    return true
end

local function tryPolish(model)
    if pending[model] then return end
    pending[model] = true
    task.spawn(function()
        for _ = 1, RETRY_COUNT do
            if not model or not model.Parent then break end
            local ok, result = pcall(polish, model)
            if ok and result then
                pending[model] = nil
                return
            end
            if not ok then
                warn("[LOST FOUND] M4-E.1D claimant final polish retry:", result)
            end
            task.wait(RETRY_DELAY)
        end
        pending[model] = nil
    end)
end

local function observe(instance)
    if instance:IsA("Model") and instance.Name == "ActiveClaimant" then
        tryPolish(instance)
    end
end

for _, instance in ipairs(Workspace:GetDescendants()) do
    observe(instance)
end
Workspace.DescendantAdded:Connect(observe)

task.spawn(function()
    while true do
        task.wait(RECONCILE_SECONDS)
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if instance:IsA("Model") and instance.Name == "ActiveClaimant" and instance:GetAttribute("NpcFinalPolishVersion") ~= FINAL_VERSION then
                tryPolish(instance)
            end
        end
    end
end)
