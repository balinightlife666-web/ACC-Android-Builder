-- LOST & FOUND: NIGHT SHIFT — M4-E.1C NPC CHARACTER QUALITY PASS.
-- Runtime v40 proved hook + facing are correct, but screenshot QC showed a large
-- visual gap between the claimant and a normal Roblox player avatar. This pass
-- keeps the resilient M4-E.1A/B hook, fixes the floating-head/ground proportion
-- problem, and replaces the generic mannequin treatment with eight lightweight
-- in-engine character presets. Roblox primitives + built-in Head mesh only.
-- No case/economy/trading/serial/mystery changes.

local Workspace = game:GetService("Workspace")

local VISUAL_VERSION = "M4E1C_NPC_V4"
local FACING_VERSION = "M4E1B_FACE_PLUS_Z"
local RECONCILE_SECONDS = 1.0
local RETRY_COUNT = 16
local RETRY_DELAY = 0.10

local SKIN_TONES = {
    Color3.fromRGB(244, 214, 188), Color3.fromRGB(234, 199, 170),
    Color3.fromRGB(221, 181, 149), Color3.fromRGB(207, 161, 125),
    Color3.fromRGB(190, 143, 108), Color3.fromRGB(171, 124, 93),
    Color3.fromRGB(151, 106, 80), Color3.fromRGB(129, 90, 69),
    Color3.fromRGB(105, 72, 56),
}

local OUTFITS = {
    Color3.fromRGB(36, 47, 62), Color3.fromRGB(61, 43, 52),
    Color3.fromRGB(39, 62, 54), Color3.fromRGB(68, 60, 46),
    Color3.fromRGB(48, 49, 57), Color3.fromRGB(35, 58, 72),
    Color3.fromRGB(70, 44, 39), Color3.fromRGB(44, 52, 46),
    Color3.fromRGB(58, 50, 72), Color3.fromRGB(61, 53, 48),
}

local ACCENTS = {
    Color3.fromRGB(190, 143, 69), Color3.fromRGB(70, 145, 174),
    Color3.fromRGB(157, 72, 78), Color3.fromRGB(92, 139, 93),
    Color3.fromRGB(151, 119, 171), Color3.fromRGB(199, 174, 117),
    Color3.fromRGB(99, 123, 178), Color3.fromRGB(168, 105, 62),
}

local HAIR = {
    Color3.fromRGB(21, 20, 19), Color3.fromRGB(39, 29, 24),
    Color3.fromRGB(58, 41, 30), Color3.fromRGB(80, 56, 39),
    Color3.fromRGB(34, 34, 38), Color3.fromRGB(100, 77, 54),
    Color3.fromRGB(53, 47, 43),
}

local PANTS = {
    Color3.fromRGB(29, 33, 40), Color3.fromRGB(40, 44, 51),
    Color3.fromRGB(34, 44, 52), Color3.fromRGB(48, 44, 40),
    Color3.fromRGB(42, 41, 49), Color3.fromRGB(30, 40, 36),
}

local SHOES = {
    Color3.fromRGB(19, 21, 25), Color3.fromRGB(43, 35, 31),
    Color3.fromRGB(57, 57, 61), Color3.fromRGB(76, 69, 59),
}

-- Eight intentional presets prevent every claimant from feeling like the same
-- procedural mannequin with different colors. Values stay conservative for mobile.
local PROFILES = {
    { id="URBAN_JACKET", hair=1, outfit=1, width=0.98, height=1.00, head=0.98, stance=0.02 },
    { id="TRAVEL_HOODIE", hair=2, outfit=2, width=1.03, height=0.99, head=1.02, stance=0.05 },
    { id="SMART_COAT", hair=5, outfit=4, width=0.95, height=1.04, head=0.97, stance=0.00 },
    { id="CASUAL_LAYER", hair=3, outfit=0, width=1.00, height=0.97, head=1.01, stance=0.03 },
    { id="MID_LENGTH", hair=4, outfit=3, width=0.96, height=1.01, head=1.00, stance=0.01 },
    { id="BUN_COAT", hair=6, outfit=4, width=0.94, height=1.02, head=0.99, stance=0.02 },
    { id="CAP_VEST", hair=7, outfit=5, width=1.05, height=0.98, head=1.01, stance=0.05 },
    { id="LONG_LAYER", hair=8, outfit=3, width=0.97, height=1.00, head=1.03, stance=0.02 },
}

local GENERATED = {
    Neck=true, EarL=true, EarR=true, ShoulderL=true, ShoulderR=true,
    UpperArmL=true, UpperArmR=true, ForearmL=true, ForearmR=true,
    HandL=true, HandR=true, LegL=true, LegR=true, ShoeL=true, ShoeR=true,
    Waist=true, TorsoLayer=true, InnerLayer=true, JacketPanelL=true,
    JacketPanelR=true, LapelL=true, LapelR=true, Zipper=true, ChestBand=true,
    CollarL=true, CollarR=true, HoodL=true, HoodR=true, VestL=true, VestR=true,
    CoatHem=true, HairCap=true, HairTop=true, HairSide=true, HairSideR=true,
    HairBack=true, HairFringeA=true, HairFringeB=true, HairFringeC=true,
    HairLockL=true, HairLockR=true, HairBun=true, CapTop=true, CapBrim=true,
    Scarf=true, BagStrap=true, Lanyard=true, Badge=true, WristBand=true,
    GlassesL=true, GlassesR=true, GlassesBridge=true,
}

local pending = setmetatable({}, { __mode = "k" })

local function hashText(text)
    local h = 17
    for i = 1, #text do
        h = (h * 31 + string.byte(text, i)) % 2147483647
    end
    return h
end

local function makePart(parent, name, size, cframe, color, material, shape)
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
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end

local function makeWedge(parent, name, size, cframe, color, material)
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
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function cleanup(model, head)
    for _, child in ipairs(model:GetChildren()) do
        if GENERATED[child.Name] then child:Destroy() end
    end
    if head then
        local oldFace = head:FindFirstChild("NpcFace")
        if oldFace then oldFace:Destroy() end
        for _, meshName in ipairs({"M4E1AHeadMesh", "M4E1CHeadMesh"}) do
            local old = head:FindFirstChild(meshName)
            if old then old:Destroy() end
        end
    end
end

local function claimantName(model)
    local attr = model:GetAttribute("ClaimantName")
    if type(attr) == "string" and attr ~= "" then return attr end
    local head = model:FindFirstChild("Head")
    local billboard = head and head:FindFirstChild("ClaimantLabel")
    local label = billboard and billboard:FindFirstChildOfClass("TextLabel")
    if label then
        local parsed = string.match(label.Text, "^[^•]+") or label.Text
        return (string.gsub(parsed, "%s+$", ""))
    end
    return "CLAIMANT"
end

local function orientTowardPlayerSide(model, torso, head)
    if model:GetAttribute("NpcFacingVersion") == FACING_VERSION then return end
    local turn = CFrame.Angles(0, math.rad(180), 0)
    torso.CFrame = torso.CFrame * turn
    head.CFrame = head.CFrame * turn
    model:SetAttribute("NpcFacingVersion", FACING_VERSION)
end

local function addHeadMesh(head)
    head.Shape = Enum.PartType.Block
    local mesh = Instance.new("SpecialMesh")
    mesh.Name = "M4E1CHeadMesh"
    mesh.MeshType = Enum.MeshType.Head
    mesh.Scale = Vector3.new(1.00, 1.03, 0.98)
    mesh.Parent = head
end

local function addFace(head, hairColor, skin, h)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "NpcFace"
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0
    gui.PixelsPerStud = 96
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.Parent = head

    local root = Instance.new("Frame")
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.Parent = gui

    local function frame(name, x, y, w, hgt, color, round)
        local f = Instance.new("Frame")
        f.Name = name
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.fromScale(x, y)
        f.Size = UDim2.fromScale(w, hgt)
        f.BorderSizePixel = 0
        f.BackgroundColor3 = color
        f.Parent = root
        if round then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = f
        end
        return f
    end

    local eye = Color3.fromRGB(25, 26, 29)
    local brow = hairColor:Lerp(Color3.fromRGB(20, 20, 22), 0.18)
    local mouth = Color3.fromRGB(105, 64, 62)
    local nose = skin:Lerp(Color3.fromRGB(128, 92, 76), 0.18)
    local tilt = (h % 3) - 1

    frame("EyeL", 0.36, 0.43, 0.055, 0.060, eye, true)
    frame("EyeR", 0.64, 0.43, 0.055, 0.060, eye, true)
    local browL = frame("BrowL", 0.36, 0.33, 0.16, 0.027, brow, true)
    local browR = frame("BrowR", 0.64, 0.33, 0.16, 0.027, brow, true)
    browL.Rotation = tilt * 4
    browR.Rotation = -tilt * 4
    frame("Nose", 0.50, 0.53, 0.035, 0.065, nose, true)
    frame("Mouth", 0.50, 0.66, 0.14 + ((math.floor(h / 17) % 3) * 0.02), 0.028, mouth, true)
end

local function addGlasses(model, headCF, head, h)
    if h % 5 ~= 0 then return end
    local z = -(head.Size.Z / 2 + 0.045)
    local y = head.Size.Y * 0.06
    local frame = Color3.fromRGB(42, 45, 52)
    makePart(model, "GlassesL", Vector3.new(0.44, 0.29, 0.04), headCF * CFrame.new(-head.Size.X * 0.19, y, z), frame, Enum.Material.Metal)
    makePart(model, "GlassesR", Vector3.new(0.44, 0.29, 0.04), headCF * CFrame.new(head.Size.X * 0.19, y, z), frame, Enum.Material.Metal)
    makePart(model, "GlassesBridge", Vector3.new(0.22, 0.045, 0.04), headCF * CFrame.new(0, y, z), frame, Enum.Material.Metal)
end

local function addHair(model, head, headCF, color, style)
    local x, y, z = head.Size.X, head.Size.Y, head.Size.Z
    local topY = y * 0.48

    if style == 1 then -- side swept
        makePart(model, "HairCap", Vector3.new(x * 0.94, y * 0.36, z * 0.91), headCF * CFrame.new(0, topY, 0.03), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        makeWedge(model, "HairFringeA", Vector3.new(x * 0.58, 0.28, 0.20), headCF * CFrame.new(0.10, y * 0.25, -(z * 0.48)) * CFrame.Angles(0, 0, math.rad(-12)), color)
        makePart(model, "HairSide", Vector3.new(0.16, y * 0.54, z * 0.64), headCF * CFrame.new(-x * 0.47, 0.00, 0.06), color)
    elseif style == 2 then -- messy traveler
        makePart(model, "HairCap", Vector3.new(x * 0.92, y * 0.33, z * 0.88), headCF * CFrame.new(0, topY, 0.02), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        makeWedge(model, "HairFringeA", Vector3.new(0.42, 0.34, 0.18), headCF * CFrame.new(-0.28, y * 0.26, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(14)), color)
        makeWedge(model, "HairFringeB", Vector3.new(0.46, 0.31, 0.18), headCF * CFrame.new(0.05, y * 0.28, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(-8)), color)
        makeWedge(model, "HairFringeC", Vector3.new(0.38, 0.28, 0.17), headCF * CFrame.new(0.33, y * 0.24, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(-18)), color)
    elseif style == 3 then -- clean crop
        makePart(model, "HairCap", Vector3.new(x * 0.93, y * 0.30, z * 0.89), headCF * CFrame.new(0, topY, 0.04), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        makePart(model, "HairSide", Vector3.new(0.14, y * 0.42, z * 0.62), headCF * CFrame.new(-x * 0.47, 0.07, 0.06), color)
        makePart(model, "HairSideR", Vector3.new(0.14, y * 0.42, z * 0.62), headCF * CFrame.new(x * 0.47, 0.07, 0.06), color)
    elseif style == 4 then -- medium layers
        makePart(model, "HairCap", Vector3.new(x * 0.94, y * 0.34, z * 0.90), headCF * CFrame.new(0, topY, 0.02), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        makePart(model, "HairBack", Vector3.new(x * 0.72, y * 0.72, 0.22), headCF * CFrame.new(0, -0.05, z * 0.48), color)
        makeWedge(model, "HairLockL", Vector3.new(0.25, y * 0.65, 0.19), headCF * CFrame.new(-x * 0.43, -0.07, -(z * 0.32)) * CFrame.Angles(0, 0, math.rad(-7)), color)
        makeWedge(model, "HairLockR", Vector3.new(0.25, y * 0.65, 0.19), headCF * CFrame.new(x * 0.43, -0.07, -(z * 0.32)) * CFrame.Angles(0, 0, math.rad(7)), color)
    elseif style == 5 then -- swept back
        makePart(model, "HairCap", Vector3.new(x * 0.91, y * 0.30, z * 0.86), headCF * CFrame.new(0, topY, 0.08), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        makePart(model, "HairBack", Vector3.new(x * 0.66, y * 0.48, 0.20), headCF * CFrame.new(0, -0.02, z * 0.49), color)
    elseif style == 6 then -- bun
        makePart(model, "HairCap", Vector3.new(x * 0.93, y * 0.33, z * 0.89), headCF * CFrame.new(0, topY, 0.02), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        makePart(model, "HairBack", Vector3.new(x * 0.68, y * 0.58, 0.20), headCF * CFrame.new(0, -0.08, z * 0.49), color)
        makePart(model, "HairBun", Vector3.new(0.48, 0.48, 0.48), headCF * CFrame.new(0, y * 0.34, z * 0.52), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    elseif style == 7 then -- cap + short hair
        makePart(model, "HairSide", Vector3.new(x * 0.82, 0.18, z * 0.76), headCF * CFrame.new(0, y * 0.31, 0.07), color)
        local capColor = color:Lerp(Color3.fromRGB(45, 49, 56), 0.45)
        makePart(model, "CapTop", Vector3.new(x * 0.90, 0.24, z * 0.88), headCF * CFrame.new(0, y * 0.55, 0), capColor, Enum.Material.Fabric)
        makePart(model, "CapBrim", Vector3.new(x * 0.62, 0.08, 0.40), headCF * CFrame.new(0, y * 0.45, -(z * 0.54)), capColor, Enum.Material.Fabric)
    else -- longer layered silhouette
        makePart(model, "HairCap", Vector3.new(x * 0.94, y * 0.35, z * 0.91), headCF * CFrame.new(0, topY, 0.02), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        makePart(model, "HairBack", Vector3.new(x * 0.78, y * 0.92, 0.22), headCF * CFrame.new(0, -0.14, z * 0.49), color)
        makeWedge(model, "HairLockL", Vector3.new(0.27, y * 0.78, 0.20), headCF * CFrame.new(-x * 0.43, -0.12, -(z * 0.31)) * CFrame.Angles(0, 0, math.rad(-5)), color)
        makeWedge(model, "HairLockR", Vector3.new(0.27, y * 0.78, 0.20), headCF * CFrame.new(x * 0.43, -0.12, -(z * 0.31)) * CFrame.Angles(0, 0, math.rad(5)), color)
    end
end

local function addOutfit(model, torso, torsoCF, outfit, accent, style)
    local w, h, d = torso.Size.X, torso.Size.Y, torso.Size.Z
    local front = -(d / 2 + 0.035)
    local layer = outfit:Lerp(Color3.fromRGB(235, 236, 238), 0.08)

    makePart(model, "TorsoLayer", Vector3.new(w * 0.92, h * 0.90, 0.055), torsoCF * CFrame.new(0, -0.02, front), layer, Enum.Material.Fabric)

    if style == 0 then -- clean shirt
        makeWedge(model, "CollarL", Vector3.new(w * 0.24, 0.33, 0.07), torsoCF * CFrame.new(-w * 0.13, h * 0.32, front - 0.02) * CFrame.Angles(0, math.rad(180), math.rad(-18)), accent, Enum.Material.Fabric)
        makeWedge(model, "CollarR", Vector3.new(w * 0.24, 0.33, 0.07), torsoCF * CFrame.new(w * 0.13, h * 0.32, front - 0.02) * CFrame.Angles(0, 0, math.rad(18)), accent, Enum.Material.Fabric)
    elseif style == 1 then -- jacket
        makePart(model, "JacketPanelL", Vector3.new(w * 0.37, h * 0.82, 0.07), torsoCF * CFrame.new(-w * 0.20, -0.04, front - 0.03), outfit:Lerp(accent, 0.18), Enum.Material.Fabric)
        makePart(model, "JacketPanelR", Vector3.new(w * 0.37, h * 0.82, 0.07), torsoCF * CFrame.new(w * 0.20, -0.04, front - 0.03), outfit:Lerp(accent, 0.18), Enum.Material.Fabric)
        makePart(model, "Zipper", Vector3.new(0.055, h * 0.72, 0.04), torsoCF * CFrame.new(0, -0.04, front - 0.075), accent, Enum.Material.Metal)
    elseif style == 2 then -- hoodie
        makePart(model, "ChestBand", Vector3.new(w * 0.70, 0.18, 0.06), torsoCF * CFrame.new(0, -h * 0.08, front - 0.03), accent, Enum.Material.Fabric)
        makePart(model, "HoodL", Vector3.new(w * 0.34, 0.24, d * 0.42), torsoCF * CFrame.new(-w * 0.20, h * 0.40, 0.14), outfit:Lerp(Color3.new(1,1,1), 0.05), Enum.Material.Fabric, Enum.PartType.Ball)
        makePart(model, "HoodR", Vector3.new(w * 0.34, 0.24, d * 0.42), torsoCF * CFrame.new(w * 0.20, h * 0.40, 0.14), outfit:Lerp(Color3.new(1,1,1), 0.05), Enum.Material.Fabric, Enum.PartType.Ball)
    elseif style == 3 then -- layered overshirt
        makePart(model, "InnerLayer", Vector3.new(w * 0.54, h * 0.74, 0.06), torsoCF * CFrame.new(0, -0.04, front - 0.04), accent:Lerp(Color3.fromRGB(220,220,220), 0.24), Enum.Material.Fabric)
        makePart(model, "JacketPanelL", Vector3.new(w * 0.28, h * 0.80, 0.075), torsoCF * CFrame.new(-w * 0.31, -0.04, front - 0.05), outfit, Enum.Material.Fabric)
        makePart(model, "JacketPanelR", Vector3.new(w * 0.28, h * 0.80, 0.075), torsoCF * CFrame.new(w * 0.31, -0.04, front - 0.05), outfit, Enum.Material.Fabric)
    elseif style == 4 then -- coat
        makePart(model, "JacketPanelL", Vector3.new(w * 0.40, h * 0.88, 0.075), torsoCF * CFrame.new(-w * 0.21, -0.06, front - 0.05), outfit:Lerp(accent, 0.12), Enum.Material.Fabric)
        makePart(model, "JacketPanelR", Vector3.new(w * 0.40, h * 0.88, 0.075), torsoCF * CFrame.new(w * 0.21, -0.06, front - 0.05), outfit:Lerp(accent, 0.12), Enum.Material.Fabric)
        makePart(model, "CoatHem", Vector3.new(w * 0.84, 0.16, 0.07), torsoCF * CFrame.new(0, -h * 0.43, front - 0.05), accent, Enum.Material.Fabric)
        makeWedge(model, "LapelL", Vector3.new(w * 0.27, h * 0.48, 0.08), torsoCF * CFrame.new(-w * 0.17, h * 0.14, front - 0.075) * CFrame.Angles(0, math.rad(180), math.rad(-7)), accent, Enum.Material.Fabric)
        makeWedge(model, "LapelR", Vector3.new(w * 0.27, h * 0.48, 0.08), torsoCF * CFrame.new(w * 0.17, h * 0.14, front - 0.075) * CFrame.Angles(0, 0, math.rad(7)), accent, Enum.Material.Fabric)
    else -- vest
        makePart(model, "InnerLayer", Vector3.new(w * 0.78, h * 0.84, 0.06), torsoCF * CFrame.new(0, -0.02, front - 0.03), Color3.fromRGB(182, 184, 190), Enum.Material.Fabric)
        makePart(model, "VestL", Vector3.new(w * 0.34, h * 0.78, 0.075), torsoCF * CFrame.new(-w * 0.21, -0.03, front - 0.06), outfit, Enum.Material.Fabric)
        makePart(model, "VestR", Vector3.new(w * 0.34, h * 0.78, 0.075), torsoCF * CFrame.new(w * 0.21, -0.03, front - 0.06), outfit, Enum.Material.Fabric)
    end
end

local function addAccessory(model, torso, torsoCF, accent, h, isChild)
    local mode = math.floor(h / 29) % 5
    if mode == 1 then
        makePart(model, "Scarf", Vector3.new(torso.Size.X * 0.74, 0.20, torso.Size.Z + 0.04), torsoCF * CFrame.new(0, torso.Size.Y * 0.40, -0.01), accent, Enum.Material.Fabric)
    elseif mode == 2 then
        makePart(model, "BagStrap", Vector3.new(0.12, torso.Size.Y * 0.80, 0.06), torsoCF * CFrame.new(0, 0, -(torso.Size.Z / 2 + 0.09)) * CFrame.Angles(0, 0, math.rad(-25)), accent, Enum.Material.Fabric)
    elseif mode == 3 and not isChild then
        makePart(model, "Lanyard", Vector3.new(0.06, torso.Size.Y * 0.42, 0.045), torsoCF * CFrame.new(0, 0.15, -(torso.Size.Z / 2 + 0.10)), accent, Enum.Material.Fabric)
        makePart(model, "Badge", Vector3.new(0.36, 0.24, 0.045), torsoCF * CFrame.new(0, -torso.Size.Y * 0.10, -(torso.Size.Z / 2 + 0.11)), Color3.fromRGB(214, 219, 224))
    elseif mode == 4 then
        makePart(model, "WristBand", Vector3.new(0.42, 0.10, 0.50), torsoCF * CFrame.new(torso.Size.X * 0.66, -torso.Size.Y * 0.28, -0.02), accent, Enum.Material.Fabric)
    end
end

local function polish(model)
    if not model or not model.Parent or model.Name ~= "ActiveClaimant" then return false end
    if model:GetAttribute("NpcVisualVersion") == VISUAL_VERSION then return true end

    local torso = model:FindFirstChild("Torso")
    local head = model:FindFirstChild("Head")
    if not torso or not head or not torso:IsA("Part") or not head:IsA("Part") then return false end

    local originalTorsoHeight = torso.Size.Y
    local isChild = originalTorsoHeight < 3
    local groundY = torso.Position.Y - originalTorsoHeight / 2 - 0.30

    cleanup(model, head)
    orientTowardPlayerSide(model, torso, head)

    local name = claimantName(model)
    model:SetAttribute("ClaimantName", name)
    local h = hashText(name)
    local profile = PROFILES[(h % #PROFILES) + 1]
    local skin = SKIN_TONES[(h % #SKIN_TONES) + 1]
    local outfit = OUTFITS[(math.floor(h / 7) % #OUTFITS) + 1]
    local accent = ACCENTS[(math.floor(h / 13) % #ACCENTS) + 1]
    local hair = HAIR[(math.floor(h / 19) % #HAIR) + 1]
    local pants = PANTS[(math.floor(h / 23) % #PANTS) + 1]
    local shoes = SHOES[(math.floor(h / 31) % #SHOES) + 1]

    local torsoH = (isChild and 2.05 or 2.58) * profile.height
    local torsoW = (isChild and 1.55 or 1.90) * profile.width
    local torsoD = isChild and 0.90 or 1.02
    local headH = (isChild and 1.30 or 1.48) * profile.head
    local headW = (isChild and 1.26 or 1.43) * profile.head
    local headD = (isChild and 1.22 or 1.36) * profile.head
    local legH = (isChild and 1.18 or 1.62) * profile.height
    local legW = (isChild and 0.49 or 0.58) * profile.width
    local shoeH = isChild and 0.22 or 0.27

    local rotation = torso.CFrame - torso.Position
    local torsoY = groundY + shoeH + legH + torsoH / 2 - 0.02
    torso.Size = Vector3.new(torsoW, torsoH, torsoD)
    torso.CFrame = CFrame.new(torso.Position.X, torsoY, torso.Position.Z) * rotation
    torso.Color = outfit
    torso.Material = Enum.Material.Fabric

    head.Size = Vector3.new(headW, headH, headD)
    head.CFrame = torso.CFrame * CFrame.new(0, torsoH / 2 + headH / 2 + 0.10, 0)
    head.Color = skin
    head.Material = Enum.Material.SmoothPlastic
    addHeadMesh(head)

    local torsoCF = torso.CFrame
    local headCF = head.CFrame

    local neckH = isChild and 0.24 or 0.28
    makePart(model, "Neck", Vector3.new(isChild and 0.36 or 0.42, neckH, isChild and 0.36 or 0.42), torsoCF * CFrame.new(0, torsoH / 2 + neckH / 2 - 0.01, 0), skin, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
    makePart(model, "EarL", Vector3.new(0.16, 0.26, 0.12), headCF * CFrame.new(-headW * 0.49, -0.01, 0), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makePart(model, "EarR", Vector3.new(0.16, 0.26, 0.12), headCF * CFrame.new(headW * 0.49, -0.01, 0), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)

    local legCenterY = groundY + shoeH + legH / 2
    local hipOffset = torsoW * 0.22 + profile.stance
    local baseRotation = rotation
    local legLCF = CFrame.new(torso.Position.X, legCenterY, torso.Position.Z) * baseRotation * CFrame.new(-hipOffset, 0, 0)
    local legRCF = CFrame.new(torso.Position.X, legCenterY, torso.Position.Z) * baseRotation * CFrame.new(hipOffset, 0, 0)
    local legL = makePart(model, "LegL", Vector3.new(legW, legH, 0.66), legLCF, pants, Enum.Material.Fabric)
    local legR = makePart(model, "LegR", Vector3.new(legW, legH, 0.66), legRCF, pants, Enum.Material.Fabric)
    makePart(model, "ShoeL", Vector3.new(legW + 0.08, shoeH, 0.86), legL.CFrame * CFrame.new(0, -(legH / 2 + shoeH / 2 - 0.02), -0.08), shoes)
    makePart(model, "ShoeR", Vector3.new(legW + 0.08, shoeH, 0.86), legR.CFrame * CFrame.new(0, -(legH / 2 + shoeH / 2 - 0.02), -0.08), shoes)
    makePart(model, "Waist", Vector3.new(torsoW * 0.76, 0.18, torsoD * 0.82), torsoCF * CFrame.new(0, -torsoH / 2 - 0.02, 0), pants, Enum.Material.Fabric)

    local shoulderW = isChild and 0.52 or 0.62
    local shoulderY = torsoH * 0.31
    makePart(model, "ShoulderL", Vector3.new(shoulderW, 0.46, 0.72), torsoCF * CFrame.new(-(torsoW / 2 + shoulderW * 0.24), shoulderY, 0), outfit, Enum.Material.Fabric, Enum.PartType.Ball)
    makePart(model, "ShoulderR", Vector3.new(shoulderW, 0.46, 0.72), torsoCF * CFrame.new(torsoW / 2 + shoulderW * 0.24, shoulderY, 0), outfit, Enum.Material.Fabric, Enum.PartType.Ball)

    local upperH = isChild and 0.72 or 0.92
    local foreH = isChild and 0.66 or 0.82
    local armW = isChild and 0.38 or 0.46
    local leftUpper = torsoCF * CFrame.new(-(torsoW / 2 + armW * 0.64), 0.22, 0) * CFrame.Angles(math.rad(-2), 0, math.rad(5))
    local rightUpper = torsoCF * CFrame.new(torsoW / 2 + armW * 0.64, 0.22, 0) * CFrame.Angles(math.rad(-2), 0, math.rad(-5))
    makePart(model, "UpperArmL", Vector3.new(armW, upperH, 0.55), leftUpper, outfit, Enum.Material.Fabric)
    makePart(model, "UpperArmR", Vector3.new(armW, upperH, 0.55), rightUpper, outfit, Enum.Material.Fabric)
    local leftFore = leftUpper * CFrame.new(0.02, -(upperH / 2 + foreH / 2 - 0.04), -0.04) * CFrame.Angles(math.rad(-5), 0, math.rad(-2))
    local rightFore = rightUpper * CFrame.new(-0.02, -(upperH / 2 + foreH / 2 - 0.04), -0.04) * CFrame.Angles(math.rad(-5), 0, math.rad(2))
    makePart(model, "ForearmL", Vector3.new(armW * 0.86, foreH, 0.50), leftFore, skin)
    makePart(model, "ForearmR", Vector3.new(armW * 0.86, foreH, 0.50), rightFore, skin)
    makePart(model, "HandL", Vector3.new(0.38, 0.42, 0.38), leftFore * CFrame.new(0, -(foreH / 2 + 0.16), 0), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makePart(model, "HandR", Vector3.new(0.38, 0.42, 0.38), rightFore * CFrame.new(0, -(foreH / 2 + 0.16), 0), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)

    addOutfit(model, torso, torsoCF, outfit, accent, profile.outfit)
    addHair(model, head, headCF, hair, profile.hair)
    addFace(head, hair, skin, h)
    addGlasses(model, headCF, head, h)
    addAccessory(model, torso, torsoCF, accent, h, isChild)

    local billboard = head:FindFirstChild("ClaimantLabel")
    if billboard and billboard:IsA("BillboardGui") then
        billboard.AlwaysOnTop = false
        billboard.MaxDistance = 20
        billboard.StudsOffset = Vector3.new(0, isChild and 1.20 or 1.36, 0)
        billboard.Size = UDim2.fromOffset(142, 38)
        local label = billboard:FindFirstChildOfClass("TextLabel")
        if label then
            label.TextSize = 12
            label.BackgroundTransparency = 0.30
        end
    end

    model:SetAttribute("NpcCharacterProfile", profile.id)
    model:SetAttribute("M4EPolished", true)
    model:SetAttribute("M4E1Depth", true)
    model:SetAttribute("NpcVisualVersion", VISUAL_VERSION)
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
            if not ok then warn("[LOST FOUND] claimant character quality retry:", result) end
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

for _, instance in ipairs(Workspace:GetDescendants()) do observe(instance) end
Workspace.DescendantAdded:Connect(observe)

task.spawn(function()
    while true do
        task.wait(RECONCILE_SECONDS)
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if instance:IsA("Model") and instance.Name == "ActiveClaimant" and instance:GetAttribute("NpcVisualVersion") ~= VISUAL_VERSION then
                tryPolish(instance)
            end
        end
    end
end)
