-- LOST & FOUND: NIGHT SHIFT — M4-E.1E claimant identity-coherence hotfix.
-- Runtime v42 proved visual variety, but authored fictional names could receive a
-- presentation silhouette that clashed with the intended character identity.
-- This pass uses authored presentation metadata for the game's fictional first-name
-- pool, then rebuilds only hair/cap silhouette after M4-E.1C/D finish.
-- No gameplay, case outcome, economy, collection, trading or mystery changes.

local Workspace = game:GetService("Workspace")

local SOURCE_VISUAL_VERSION = "M4E1C_NPC_V4"
local SOURCE_FINAL_VERSION = "M4E1D_NPC_FINAL_V1"
local IDENTITY_VERSION = "M4E1E_IDENTITY_V1"
local RETRY_COUNT = 24
local RETRY_DELAY = 0.10
local RECONCILE_SECONDS = 1.25

local FEMININE = {
    Alya=true, Nadia=true, Mei=true, Hana=true, Soo=true, Amira=true, Leila=true,
    Maya=true, Sofia=true, Emma=true, Lena=true, Camila=true, Chloe=true, Priya=true,
    Olivia=true, Mila=true, Sara=true, Inez=true, Nora=true, Farah=true, Rina=true,
    Elena=true, Grace=true, Zara=true, Mina=true, Putri=true, Citra=true, Gita=true,
    Sari=true, Nisa=true, Aisha=true, Fatima=true, Layla=true, Yue=true, Min=true,
    Jia=true, Yui=true, Aoi=true, Ye=true, Ana=true, Ines=true, Marta=true, Mira=true,
    Amelie=true, Eva=true, Isla=true,
}

local MASCULINE = {
    Rafi=true, Dimas=true, Kevin=true, Kenji=true, Jae=true, Omar=true, Yusuf=true,
    Daniel=true, Noah=true, Mateo=true, Lucas=true, Samir=true, Arjun=true, Ethan=true,
    Leo=true, Adam=true, Theo=true, Tariq=true, Marco=true, Nathan=true, Julian=true,
    Bagus=true, Bima=true, Fajar=true, Rizky=true, Aditya=true, Bilal=true, Harun=true,
    Chen=true, Wei=true, Wang=true, Rui=true, Haruto=true, Ren=true, Daichi=true,
    Seo=true, Jun=true, Ho=true, Tiago=true, Rafael=true, Piotr=true, Ivan=true,
    Louis=true, Jonas=true, Luca=true, Mason=true,
}

local NEUTRAL = {
    Kai=true, Avery=true, Jordan=true, Taylor=true,
}

local GENERATED_HAIR = {
    HairCap=true, HairTop=true, HairSide=true, HairSideR=true, HairBack=true,
    HairFringeA=true, HairFringeB=true, HairFringeC=true, HairLockL=true,
    HairLockR=true, HairBun=true, CapTop=true, CapBrim=true,
    FinalHairA=true, FinalHairB=true, FinalHairSideL=true, FinalHairSideR=true,
    IdentityHairCap=true, IdentityHairA=true, IdentityHairB=true,
    IdentityHairSideL=true, IdentityHairSideR=true, IdentityHairBack=true,
    IdentityHairBun=true, IdentityCap=true, IdentityBrim=true,
}

local pending = setmetatable({}, { __mode = "k" })

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

local function firstName(name)
    return string.match(tostring(name or ""), "^(%S+)") or ""
end

local function presentationTag(model, name)
    local billboard = model:FindFirstChild("Head") and model.Head:FindFirstChild("ClaimantLabel")
    local label = billboard and billboard:FindFirstChildOfClass("TextLabel")
    if (label and string.find(string.upper(label.Text), "CHILD", 1, true)) or name == "Milo Hart" then
        return "CHILD"
    end

    local first = firstName(name)
    if FEMININE[first] then return "FEMININE" end
    if MASCULINE[first] then return "MASCULINE" end
    if NEUTRAL[first] then return "NEUTRAL" end
    return "NEUTRAL"
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

local function recoverHairColor(model)
    for _, name in ipairs({"HairCap", "HairTop", "HairSide", "HairBack", "FinalHairA", "FinalHairSideL"}) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part.Color end
    end
    return Color3.fromRGB(37, 29, 25)
end

local function clearHair(model)
    for _, child in ipairs(model:GetChildren()) do
        if GENERATED_HAIR[child.Name] then child:Destroy() end
    end
end

local function addFeminineHair(model, head, color, seed)
    local cf = head.CFrame
    local x, y, z = head.Size.X, head.Size.Y, head.Size.Z
    local style = seed % 3

    makePart(model, "IdentityHairCap", Vector3.new(x * 0.94, y * 0.34, z * 0.90), cf * CFrame.new(0, y * 0.48, 0.02), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makeWedge(model, "IdentityHairA", Vector3.new(x * 0.43, y * 0.34, 0.18), cf * CFrame.new(-x * 0.16, y * 0.24, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(10)), color)
    makeWedge(model, "IdentityHairB", Vector3.new(x * 0.43, y * 0.32, 0.18), cf * CFrame.new(x * 0.17, y * 0.25, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(-11)), color)
    makePart(model, "IdentityHairSideL", Vector3.new(0.20, y * (style == 0 and 0.88 or 0.72), 0.22), cf * CFrame.new(-x * 0.45, -y * 0.15, -(z * 0.18)), color)
    makePart(model, "IdentityHairSideR", Vector3.new(0.20, y * (style == 0 and 0.88 or 0.72), 0.22), cf * CFrame.new(x * 0.45, -y * 0.15, -(z * 0.18)), color)
    makePart(model, "IdentityHairBack", Vector3.new(x * 0.76, y * (style == 0 and 0.90 or 0.68), 0.20), cf * CFrame.new(0, -y * 0.14, z * 0.49), color)

    if style == 2 then
        makePart(model, "IdentityHairBun", Vector3.new(0.46, 0.46, 0.46), cf * CFrame.new(0, y * 0.36, z * 0.52), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    end
end

local function addMasculineHair(model, head, color, seed)
    local cf = head.CFrame
    local x, y, z = head.Size.X, head.Size.Y, head.Size.Z
    local style = seed % 3
    makePart(model, "IdentityHairCap", Vector3.new(x * 0.92, y * 0.29, z * 0.88), cf * CFrame.new(0, y * 0.49, 0.04), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    if style == 0 then
        makeWedge(model, "IdentityHairA", Vector3.new(x * 0.45, 0.26, 0.18), cf * CFrame.new(0.12, y * 0.27, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(-10)), color)
    elseif style == 1 then
        makePart(model, "IdentityHairSideL", Vector3.new(0.13, y * 0.42, z * 0.58), cf * CFrame.new(-x * 0.47, 0.06, 0.04), color)
        makePart(model, "IdentityHairSideR", Vector3.new(0.13, y * 0.42, z * 0.58), cf * CFrame.new(x * 0.47, 0.06, 0.04), color)
    else
        makeWedge(model, "IdentityHairA", Vector3.new(0.40, 0.30, 0.18), cf * CFrame.new(-0.24, y * 0.27, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(13)), color)
        makeWedge(model, "IdentityHairB", Vector3.new(0.42, 0.28, 0.18), cf * CFrame.new(0.18, y * 0.27, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(-13)), color)
    end
end

local function addNeutralHair(model, head, color, seed)
    local cf = head.CFrame
    local x, y, z = head.Size.X, head.Size.Y, head.Size.Z
    makePart(model, "IdentityHairCap", Vector3.new(x * 0.93, y * 0.31, z * 0.89), cf * CFrame.new(0, y * 0.49, 0.03), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makeWedge(model, "IdentityHairA", Vector3.new(x * 0.42, 0.29, 0.18), cf * CFrame.new(-0.15, y * 0.26, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(8)), color)
    if seed % 2 == 0 then
        makePart(model, "IdentityHairSideL", Vector3.new(0.17, y * 0.56, 0.20), cf * CFrame.new(-x * 0.46, -0.02, -(z * 0.12)), color)
    end
end

local function addChildHair(model, head, color, seed)
    local cf = head.CFrame
    local x, y, z = head.Size.X, head.Size.Y, head.Size.Z
    makePart(model, "IdentityHairCap", Vector3.new(x * 0.94, y * 0.32, z * 0.90), cf * CFrame.new(0, y * 0.48, 0.02), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makeWedge(model, "IdentityHairA", Vector3.new(x * 0.38, 0.28, 0.17), cf * CFrame.new(-0.18, y * 0.26, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(10)), color)
    makeWedge(model, "IdentityHairB", Vector3.new(x * 0.38, 0.27, 0.17), cf * CFrame.new(0.18, y * 0.25, -(z * 0.49)) * CFrame.Angles(0, 0, math.rad(-10)), color)
end

local function hashName(name)
    local h = 13
    for i = 1, #name do h = (h * 31 + string.byte(name, i)) % 2147483647 end
    return h
end

local function apply(model)
    if not model or not model.Parent or model.Name ~= "ActiveClaimant" then return false end
    if model:GetAttribute("NpcIdentityVersion") == IDENTITY_VERSION then return true end
    if model:GetAttribute("NpcVisualVersion") ~= SOURCE_VISUAL_VERSION then return false end
    if model:GetAttribute("NpcFinalPolishVersion") ~= SOURCE_FINAL_VERSION then return false end

    local head = model:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return false end
    local name = claimantName(model)
    local tag = presentationTag(model, name)
    local color = recoverHairColor(model)
    local seed = hashName(name)

    clearHair(model)
    if tag == "FEMININE" then
        addFeminineHair(model, head, color, seed)
    elseif tag == "MASCULINE" then
        addMasculineHair(model, head, color, seed)
    elseif tag == "CHILD" then
        addChildHair(model, head, color, seed)
    else
        addNeutralHair(model, head, color, seed)
    end

    model:SetAttribute("NpcPresentationTag", tag)
    model:SetAttribute("NpcIdentityVersion", IDENTITY_VERSION)
    return true
end

local function tryApply(model)
    if pending[model] then return end
    pending[model] = true
    task.spawn(function()
        for _ = 1, RETRY_COUNT do
            if not model or not model.Parent then break end
            local ok, result = pcall(apply, model)
            if ok and result then pending[model] = nil return end
            if not ok then warn("[LOST FOUND] identity coherence retry:", result) end
            task.wait(RETRY_DELAY)
        end
        pending[model] = nil
    end)
end

local function observe(instance)
    if instance:IsA("Model") and instance.Name == "ActiveClaimant" then tryApply(instance) end
end

for _, instance in ipairs(Workspace:GetDescendants()) do observe(instance) end
Workspace.DescendantAdded:Connect(observe)

task.spawn(function()
    while true do
        task.wait(RECONCILE_SECONDS)
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if instance:IsA("Model") and instance.Name == "ActiveClaimant" and instance:GetAttribute("NpcIdentityVersion") ~= IDENTITY_VERSION then
                tryApply(instance)
            end
        end
    end
end)
