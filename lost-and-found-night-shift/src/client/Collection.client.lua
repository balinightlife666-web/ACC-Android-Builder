local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local collectionUpdate = remotes:WaitForChild("CollectionUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundCollectionHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(target, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 9)
    c.Parent = target
end

local function stroke(target, transparency)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(82, 96, 114)
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
popup.Size = UDim2.fromOffset(320, 258)
popup.Position = UDim2.new(1, -18, 0, 108)
popup.BackgroundColor3 = Color3.fromRGB(15, 19, 26)
popup.BackgroundTransparency = 0.02
popup.BorderSizePixel = 0
popup.Visible = false
popup.Active = false
popup.Parent = gui
corner(popup, 12)
stroke(popup, 0.2)

local title = label(popup, UDim2.new(1, -62, 0, 40), UDim2.fromOffset(14, 8), 16, Enum.Font.GothamBold, Color3.fromRGB(255, 192, 86))
title.Text = "LOST PROPERTY INDEX"

local subtitle = label(popup, UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 43), 11, Enum.Font.GothamMedium, Color3.fromRGB(151, 164, 181))
subtitle.Text = "Resolve cases to register item types."

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(36, 32)
close.Position = UDim2.new(1, -46, 0, 10)
close.BackgroundColor3 = Color3.fromRGB(38, 45, 57)
close.BorderSizePixel = 0
close.Text = "×"
close.TextColor3 = Color3.fromRGB(240, 242, 246)
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.Modal = false
close.Parent = popup
corner(close, 8)

local list = Instance.new("Frame")
list.Size = UDim2.new(1, -28, 0, 170)
list.Position = UDim2.fromOffset(14, 74)
list.BackgroundTransparency = 1
list.Parent = popup

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 6)
layout.Parent = list

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
toast.TextSize = 13
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui
corner(toast, 9)
stroke(toast, 0.4)

local rowById = {}
local discovered = {}
local entries = {}
local toastToken = 0

local function rarityText(rarity)
    return tostring(rarity or "UNRATED")
end

local function rebuildRows()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    rowById = {}

    for _, entry in ipairs(entries) do
        local row = Instance.new("Frame")
        row.Name = entry.id
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(24, 29, 38)
        row.BackgroundTransparency = discovered[entry.id] and 0.05 or 0.35
        row.BorderSizePixel = 0
        row.Parent = list
        corner(row, 7)

        local itemName = label(row, UDim2.new(0.62, -12, 1, 0), UDim2.fromOffset(10, 0), 12, Enum.Font.GothamBold, discovered[entry.id] and Color3.fromRGB(235, 239, 244) or Color3.fromRGB(102, 111, 124))
        itemName.Text = discovered[entry.id] and entry.name or "LOCKED ITEM"

        local rarity = label(row, UDim2.new(0.38, -10, 1, 0), UDim2.new(0.62, 0, 0, 0), 11, Enum.Font.GothamBold, discovered[entry.id] and Color3.fromRGB(255, 194, 92) or Color3.fromRGB(86, 94, 106))
        rarity.TextXAlignment = Enum.TextXAlignment.Right
        rarity.Text = discovered[entry.id] and rarityText(entry.rarity) or "—"

        rowById[entry.id] = row
    end
end

local function applySnapshot(payload)
    entries = payload.entries or entries
    discovered = payload.discovered or discovered
    indexButton.Text = string.format("INDEX  %d/%d", payload.count or 0, payload.total or #entries)
    rebuildRows()
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

indexButton.Activated:Connect(function()
    popup.Visible = not popup.Visible
end)

close.Activated:Connect(function()
    popup.Visible = false
end)

collectionUpdate.OnClientEvent:Connect(function(kind, payload)
    payload = payload or {}
    applySnapshot(payload)
    if kind == "DISCOVERY" and payload.isNew then
        showToast(payload.item)
    end
end)
