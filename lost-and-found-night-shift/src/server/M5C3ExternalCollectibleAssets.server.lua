-- LOST & FOUND: NIGHT SHIFT — M5-C.3.1 External Oxford Runtime Color Pass
-- Replaces only Daniel's Formal Shoe showcase geometry with an approved Roblox model asset.
-- The stable M5-C.1.3 showcase Model instance remains intact, so this does not reintroduce
-- destructive refresh/flicker behavior. If the external asset cannot load, the existing
-- procedural shoe remains as a safe fallback.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local ExternalAssets = require(shared:WaitForChild("ExternalCollectibleAssets"))

local VERSION = "M5C31_EXTERNAL_OXFORD_COLOR_V1"
local COLLECTION_ID = "daniel_formal_shoe"
local assetInfo = ExternalAssets.Models and ExternalAssets.Models[COLLECTION_ID]
local ASSET_ID = math.floor(tonumber(assetInfo and assetInfo.assetId) or 0)

if ASSET_ID <= 0 then
    warn("[LOST FOUND] M5-C.3.1 Oxford external asset not assigned; procedural fallback remains active")
    return
end

local template
local boundFolders = setmetatable({}, {__mode = "k"})
local replacementBusy = setmetatable({}, {__mode = "k"})

local LEATHER_COLOR = Color3.fromRGB(58, 34, 25)
local SOLE_COLOR = Color3.fromRGB(24, 21, 20)
local CORD_COLOR = Color3.fromRGB(150, 124, 91)

local function applyOxfordColor(part)
    local lowerName = string.lower(part.Name)
    part.Material = Enum.Material.SmoothPlastic
    part.Reflectance = 0

    if string.find(lowerName, "cord", 1, true) then
        part.Color = CORD_COLOR
    elseif string.find(lowerName, "plane.001", 1, true) then
        part.Color = SOLE_COLOR
    else
        part.Color = LEATHER_COLOR
    end
end

local function sanitizeTree(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("LuaSourceContainer") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.Massless = true
            descendant.CastShadow = true
            applyOxfordColor(descendant)
        end
    end
end

local function countParts(root)
    local count = 0
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") then count += 1 end
    end
    return count
end

local function loadTemplateOnce()
    if template and template.Parent then return template end

    local ok, container = pcall(function()
        return InsertService:LoadAsset(ASSET_ID)
    end)
    if not ok or not container then
        warn("[LOST FOUND] M5-C.3.1 InsertService load failed", ASSET_ID, container)
        return nil
    end

    local model = Instance.new("Model")
    model.Name = "M5C31_OxfordTemplate"
    for _, child in ipairs(container:GetChildren()) do
        child.Parent = model
    end
    container:Destroy()
    sanitizeTree(model)

    if countParts(model) < 1 then
        model:Destroy()
        warn("[LOST FOUND] M5-C.3.1 Oxford asset contained no BaseParts", ASSET_ID)
        return nil
    end

    model:SetAttribute("ExternalAssetId", ASSET_ID)
    model:SetAttribute("ExternalAssetVersion", VERSION)
    model.Parent = ServerStorage
    template = model
    return template
end

local function findSlotContext(slotModel)
    local folder = slotModel.Parent
    local showcase = folder and folder.Parent
    if not showcase or showcase.Name ~= "PublicShowcase" then return nil end
    local slot = tonumber(string.match(slotModel.Name, "M5C13_Slot_(%d+)"))
    if not slot then return nil end
    local anchor = showcase:FindFirstChild("DisplayAnchor" .. slot)
    local plinth = showcase:FindFirstChild("M5B2_Plinth" .. slot)
    if not anchor or not anchor:IsA("BasePart") or not plinth or not plinth:IsA("BasePart") then return nil end
    return slot, anchor, plinth
end

local function fitOxfordOffWorld(model, anchor, plinth)
    pcall(function() model:ScaleTo(1) end)
    local ok, _, size = pcall(function()
        local cf, extents = model:GetBoundingBox()
        return cf, extents
    end)
    if not ok or not size or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then return false end

    -- Oxford silhouette target stays locked from M5-C.3; color-only pass does not change fit.
    local targetW, targetH, targetD = 2.72, 1.48, 1.42
    local scale = math.min(targetW / size.X, targetH / size.Y, targetD / size.Z)
    scale = math.clamp(scale, 0.08, 4.0)
    pcall(function() model:ScaleTo(scale) end)

    local base = anchor.CFrame
        * CFrame.new(0, 0, -0.02)
        * CFrame.Angles(math.rad(-3), math.rad(158), math.rad(0))
    pcall(function() model:PivotTo(base) end)

    local boxCf, boxSize = model:GetBoundingBox()
    local targetBottom = plinth.Position.Y + plinth.Size.Y * 0.5 + 0.055
    local currentBottom = boxCf.Position.Y - boxSize.Y * 0.5
    pcall(function()
        model:PivotTo(model:GetPivot() + Vector3.new(0, targetBottom - currentBottom, 0))
    end)
    return true
end

local function hideProcedural(slotModel)
    for _, descendant in ipairs(slotModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Transparency = 1
        elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
            descendant.Enabled = false
        end
    end
end

local function replaceGeometry(slotModel)
    if replacementBusy[slotModel] then return end
    if not slotModel:IsA("Model") then return end
    if tostring(slotModel:GetAttribute("CollectionId") or "") ~= COLLECTION_ID then return end
    if tonumber(slotModel:GetAttribute("ExternalAssetId")) == ASSET_ID
        and tostring(slotModel:GetAttribute("ExternalAssetVersion") or "") == VERSION then
        return
    end

    local slot, anchor, plinth = findSlotContext(slotModel)
    if not slot then return end
    local source = loadTemplateOnce()
    if not source then return end

    replacementBusy[slotModel] = true
    local staging = source:Clone()
    staging.Name = "M5C31_StagingOxford"
    staging.Parent = ServerStorage
    sanitizeTree(staging)

    if not fitOxfordOffWorld(staging, anchor, plinth) then
        staging:Destroy()
        replacementBusy[slotModel] = nil
        return
    end

    -- Preserve the stable M5C13 slot Model and immutable instance/serial attributes.
    hideProcedural(slotModel)
    local oldChildren = slotModel:GetChildren()
    for _, child in ipairs(staging:GetChildren()) do
        child.Parent = slotModel
    end
    for _, child in ipairs(oldChildren) do
        child:Destroy()
    end
    staging:Destroy()

    sanitizeTree(slotModel)
    slotModel:SetAttribute("ExternalAssetId", ASSET_ID)
    slotModel:SetAttribute("ExternalAssetVersion", VERSION)
    slotModel:SetAttribute("ExternalSource", "Sketchfab/assetfactory")
    slotModel:SetAttribute("ExternalCollectionId", COLLECTION_ID)
    slotModel:SetAttribute("ExternalColorProfile", "ESPRESSO_BLACK_TAN_V1")
    replacementBusy[slotModel] = nil
end

local function processFolder(folder)
    if not folder or not folder:IsA("Folder") or folder.Name ~= "M5C13StableItems" then return end
    if boundFolders[folder] then return end
    boundFolders[folder] = true

    local function processChild(child)
        if child:IsA("Model") then
            task.defer(function()
                if child.Parent == folder then replaceGeometry(child) end
            end)
        end
    end

    for _, child in ipairs(folder:GetChildren()) do processChild(child) end
    folder.ChildAdded:Connect(processChild)
end

local function processDescendant(descendant)
    if descendant:IsA("Folder") and descendant.Name == "M5C13StableItems" then
        processFolder(descendant)
    elseif descendant:IsA("Model") and tostring(descendant:GetAttribute("CollectionId") or "") == COLLECTION_ID then
        task.defer(function()
            if descendant.Parent then replaceGeometry(descendant) end
        end)
    end
end

-- Warm once; bounded retry only. No periodic visual mutation loop.
task.spawn(function()
    for attempt = 1, 12 do
        if loadTemplateOnce() then break end
        task.wait(5)
    end

    local world = workspace:FindFirstChild("LostAndFoundM4D")
    if world then
        for _, descendant in ipairs(world:GetDescendants()) do processDescendant(descendant) end
    end
end)

workspace.DescendantAdded:Connect(processDescendant)

print("[LOST FOUND] M5-C.3.1 Oxford runtime colors ready", ASSET_ID, VERSION)
