local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local PreviewFactory = require(shared:WaitForChild("CollectionPreviewFactory"))
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local collectionUpdate = remotes:WaitForChild("CollectionUpdate")

local playerGui = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundCollectionHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function corner(target, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 9)
    c.Parent = target
end

local function stroke(target, transparency, color)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(82, 96, 114)
    s.Thickness = 1.1
    s.Transparency = transparency or 0.35
    s.Parent = target
end

local function label(parent, size, position, textSize, font, color)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = position
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextSize = textSize or 13
    l.Font = font or Enum.Font.Gotham
    l.TextColor3 = color or Color3.fromRGB(232, 236, 242)
    l.Parent = parent
    return l
end

local RARITY_COLORS = {
    COMMON = Color3.fromRGB(177, 187, 201),
    UNCOMMON = Color3.fromRGB(104, 190, 127),
    RARE = Color3.fromRGB(95, 167, 232),
    EPIC = Color3.fromRGB(177, 115, 226),
    LEGENDARY = Color3.fromRGB(238, 173, 76),
    MYTHIC = Color3.fromRGB(232, 95, 135),
    SECRET = Color3.fromRGB(229, 229, 235),
    ANOMALY = Color3.fromRGB(88, 221, 224),
}

local indexButton = Instance.new("TextButton")
indexButton.Name = "IndexButton"
indexButton.AnchorPoint = Vector2.new(1, 0)
indexButton.Size = UDim2.fromOffset(150, 34)
indexButton.Position = UDim2.new(1, -18, 0, 62)
indexButton.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
indexButton.BackgroundTransparency = 0.05
indexButton.BorderSizePixel = 0
indexButton.TextColor3 = Color3.fromRGB(181, 214, 232)
indexButton.Font = Enum.Font.GothamBold
indexButton.TextSize = 13
indexButton.Text = "INDEX  0/5"
indexButton.Modal = false
indexButton.Parent = gui
corner(indexButton, 9)
stroke(indexButton, 0.4)

local popup = Instance.new("Frame")
popup.Name = "CollectionPopup"
popup.AnchorPoint = Vector2.new(1, 0)
popup.Size = UDim2.fromOffset(440, 290)
popup.Position = UDim2.new(1, -18, 0, 106)
popup.BackgroundColor3 = Color3.fromRGB(15, 19, 26)
popup.BackgroundTransparency = 0.02
popup.BorderSizePixel = 0
popup.Visible = false
popup.Active = false
popup.Parent = gui
corner(popup, 12)
stroke(popup, 0.2)

local popupConstraint = Instance.new("UISizeConstraint")
popupConstraint.MinSize = Vector2.new(390, 270)
popupConstraint.MaxSize = Vector2.new(460, 310)
popupConstraint.Parent = popup

local title = label(popup, UDim2.new(1, -58, 0, 34), UDim2.fromOffset(12, 7), 14, Enum.Font.GothamBold, Color3.fromRGB(255, 192, 86))
title.Text = "LOST PROPERTY COLLECTION"

local subtitle = label(popup, UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 37), 10, Enum.Font.GothamMedium, Color3.fromRGB(151, 164, 181))
subtitle.Text = "Resolve cases to reveal item types."

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 30)
close.Position = UDim2.new(1, -41, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(38, 45, 57)
close.BorderSizePixel = 0
close.Text = "×"
close.TextColor3 = Color3.fromRGB(240, 242, 246)
close.Font = Enum.Font.GothamBold
close.TextSize = 17
close.Modal = false
close.Parent = popup
corner(close, 8)

local grid = Instance.new("Frame")
grid.Name = "CollectionGrid"
grid.Size = UDim2.new(1, -24, 1, -68)
grid.Position = UDim2.fromOffset(12, 60)
grid.BackgroundTransparency = 1
grid.Parent = popup

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(128, 96)
layout.CellPadding = UDim2.fromOffset(7, 7)
layout.FillDirectionMaxCells = 3
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

local toast = Instance.new("TextLabel")
toast.Name = "DiscoveryToast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Size = UDim2.fromOffset(330, 44)
toast.Position = UDim2.new(0.5, 0, 0, 64)
toast.BackgroundColor3 = Color3.fromRGB(22, 29, 38)
toast.BackgroundTransparency = 0.03
toast.BorderSizePixel = 0
toast.TextColor3 = Color3.fromRGB(255, 211, 125)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 12
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui
corner(toast, 9)
stroke(toast, 0.4)

local discovered = {}
local entries = {}
local toastToken = 0

local function rarityColor(rarity)
    return RARITY_COLORS[tostring(rarity or "COMMON")] or Color3.fromRGB(177, 187, 201)
end

local function setCaseHudVisible(visible)
    local mainHud = playerGui:FindFirstChild("LostAndFoundHUD")
    if not mainHud then return end
    local compact = mainHud:FindFirstChild("CompactCaseHUD")
    local casePopup = mainHud:FindFirstChild("CaseFilePopup")
    if compact then compact.Visible = visible end
    if not visible and casePopup then casePopup.Visible = false end
end

local function addPreview(card, entry, isDiscovered)
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "Preview"
    viewport.Size = UDim2.new(1, -8, 0, 60)
    viewport.Position = UDim2.fromOffset(4, 4)
    viewport.BackgroundColor3 = isDiscovered and Color3.fromRGB(20, 25, 33) or Color3.fromRGB(17, 20, 26)
    viewport.BackgroundTransparency = 0.02
    viewport.BorderSizePixel = 0
    viewport.Ambient = isDiscovered and Color3.fromRGB(160, 170, 185) or Color3.fromRGB(70, 76, 86)
    viewport.LightColor = Color3.fromRGB(245, 237, 220)
    viewport.LightDirection = Vector3.new(-1, -1, -1)
    viewport.Parent = card
    corner(viewport, 7)

    local world = Instance.new("WorldModel")
    world.Name = "PreviewWorld"
    world.Parent = viewport

    local model = PreviewFactory.Create(entry.id, world, not isDiscovered)
    local camera = Instance.new("Camera")
    camera.FieldOfView = 34
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local boxCF, boxSize = model:GetBoundingBox()
    local maxDim = math.max(boxSize.X, boxSize.Y, boxSize.Z)
    local center = boxCF.Position
    local target = center + Vector3.new(0, boxSize.Y * 0.05, 0)
    local cameraPos = center + Vector3.new(maxDim * 0.92, maxDim * 0.58, maxDim * 1.45)
    camera.CFrame = CFrame.lookAt(cameraPos, target)

    if not isDiscovered then
        local lock = label(viewport, UDim2.fromScale(1, 1), UDim2.new(), 22, Enum.Font.GothamBlack, Color3.fromRGB(157, 165, 178))
        lock.TextXAlignment = Enum.TextXAlignment.Center
        lock.TextYAlignment = Enum.TextYAlignment.Center
        lock.Text = "?"
        lock.TextTransparency = 0.18
    end
end

local function rebuildCards()
    for _, child in ipairs(grid:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for order, entry in ipairs(entries) do
        local isDiscovered = discovered[entry.id] == true
        local rarity = tostring(entry.rarity or "COMMON")
        local accent = isDiscovered and rarityColor(rarity) or Color3.fromRGB(72, 80, 92)

        local card = Instance.new("Frame")
        card.Name = entry.id
        card.LayoutOrder = order
        card.BackgroundColor3 = Color3.fromRGB(24, 29, 38)
        card.BackgroundTransparency = isDiscovered and 0.03 or 0.18
        card.BorderSizePixel = 0
        card.Parent = grid
        corner(card, 9)
        stroke(card, isDiscovered and 0.18 or 0.55, accent)

        addPreview(card, entry, isDiscovered)

        local itemName = label(card, UDim2.new(1, -10, 0, 15), UDim2.fromOffset(5, 65), 10, Enum.Font.GothamBold, isDiscovered and Color3.fromRGB(235, 239, 244) or Color3.fromRGB(125, 134, 147))
        itemName.TextXAlignment = Enum.TextXAlignment.Center
        itemName.Text = isDiscovered and entry.name or "???"

        local rarityLabel = label(card, UDim2.new(1, -10, 0, 13), UDim2.fromOffset(5, 80), 8, Enum.Font.GothamBold, accent)
        rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
        rarityLabel.Text = isDiscovered and rarity or "LOCKED"
    end
end

local function applySnapshot(payload)
    entries = payload.entries or entries
    discovered = payload.discovered or discovered
    indexButton.Text = string.format("INDEX  %d/%d", payload.count or 0, payload.total or #entries)
    rebuildCards()
end

local function showToast(item)
    if not item then return end
    toastToken += 1
    local token = toastToken
    toast.Text = string.format("NEW DISCOVERY  •  %s  •  %s", tostring(item.name), tostring(item.rarity))
    toast.Visible = true
    task.delay(2.5, function()
        if token == toastToken then toast.Visible = false end
    end)
end

local function setCollectionOpen(open)
    popup.Visible = open
    setCaseHudVisible(not open)
end

indexButton.Activated:Connect(function()
    setCollectionOpen(not popup.Visible)
end)

close.Activated:Connect(function()
    setCollectionOpen(false)
end)

collectionUpdate.OnClientEvent:Connect(function(kind, payload)
    payload = payload or {}
    applySnapshot(payload)
    if kind == "DISCOVERY" and payload.isNew then
        showToast(payload.item)
    end
end)
