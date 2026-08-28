-- LOST & FOUND: NIGHT SHIFT — M5-B.2 Five-Slot Showcase client.
-- Replaces the old 3-slot manager UI with a 5-slot manager while keeping the same
-- Collection Index entry point and server-authoritative ownership validation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local baseRequest = remotes:WaitForChild("PersonalShowcaseRequest")
local extraRequest = remotes:WaitForChild("M5B2ShowcaseRequest")
local extraUpdate = remotes:WaitForChild("M5B2ShowcaseUpdate")

local function isIndonesian()
    if player:GetAttribute("LostFoundResolvedLocale") == "id" then return true end
    local ok, locale = pcall(function() return LocalizationService.RobloxLocaleId end)
    locale = ok and string.lower(tostring(locale or "")) or ""
    return string.sub(locale, 1, 2) == "id"
end

local ID = isIndonesian()
local function tr(en, id) return ID and id or en end

local RARITY_COLORS = {
    COMMON = Color3.fromRGB(177, 187, 201),
    UNCOMMON = Color3.fromRGB(104, 190, 127),
    RARE = Color3.fromRGB(95, 167, 232),
    EPIC = Color3.fromRGB(177, 115, 226),
    ANOMALY = Color3.fromRGB(88, 221, 224),
    SECRET = Color3.fromRGB(235, 223, 179),
}

local function corner(target, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = target
end

local function stroke(target, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(82, 96, 114)
    s.Thickness = 1.1
    s.Transparency = transparency or 0.35
    s.Parent = target
end

local function label(parent, size, position, text, textSize, font, color)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = position
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextColor3 = color or Color3.fromRGB(232, 236, 242)
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local collectionGui = playerGui:WaitForChild("LostAndFoundCollectionHUD", 40)
if not collectionGui then return end
local collectionPopup = collectionGui:WaitForChild("CollectionPopup", 10)
if not collectionPopup then return end

-- Retire the old three-slot manager presentation without touching its server service.
local oldButton = collectionPopup:FindFirstChild("M5BShowcaseButton")
if oldButton then oldButton.Visible = false end
local oldPanel = collectionGui:FindFirstChild("M5BShowcasePanel")
if oldPanel then oldPanel.Visible = false end

local openButton = Instance.new("TextButton")
openButton.Name = "M5B2ShowcaseButton"
openButton.Size = UDim2.fromOffset(106, 28)
openButton.Position = UDim2.new(1, -153, 0, 8)
openButton.BackgroundColor3 = Color3.fromRGB(40, 53, 68)
openButton.BorderSizePixel = 0
openButton.TextColor3 = Color3.fromRGB(196, 224, 238)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 9
openButton.Text = tr("SHOWCASE x5", "PAJANGAN x5")
openButton.Parent = collectionPopup
corner(openButton, 7)
stroke(openButton, Color3.fromRGB(93, 129, 151), 0.25)

local panel = Instance.new("Frame")
panel.Name = "M5B2ShowcasePanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Size = UDim2.new(0.90, 0, 0.82, 0)
panel.Position = UDim2.fromScale(0.5, 0.52)
panel.BackgroundColor3 = Color3.fromRGB(14, 18, 25)
panel.BackgroundTransparency = 0.01
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = collectionGui
corner(panel, 12)
stroke(panel, Color3.fromRGB(92, 116, 139), 0.18)

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(340, 350)
constraint.MaxSize = Vector2.new(560, 485)
constraint.Parent = panel

local title = label(panel, UDim2.new(1, -60, 0, 30), UDim2.fromOffset(14, 9), tr("PERSONAL SHOWCASE — 5 SLOTS", "PAJANGAN PRIBADI — 5 SLOT"), 15, Enum.Font.GothamBold, Color3.fromRGB(239, 207, 139))
local subtitle = label(panel, UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 38), tr("Choose up to 5 owned serialized collectibles for your station trophy rack.", "Pilih maksimal 5 collectible berserial milikmu untuk rak pajangan stasiun."), 10, Enum.Font.Gotham, Color3.fromRGB(158, 173, 190))
subtitle.TextWrapped = true
subtitle.TextYAlignment = Enum.TextYAlignment.Top

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 32)
close.Position = UDim2.new(1, -44, 0, 9)
close.BackgroundColor3 = Color3.fromRGB(38, 45, 57)
close.BorderSizePixel = 0
close.Text = "×"
close.TextColor3 = Color3.fromRGB(240, 242, 246)
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.Parent = panel
corner(close, 8)

local slotsFrame = Instance.new("Frame")
slotsFrame.Size = UDim2.new(1, -28, 0, 66)
slotsFrame.Position = UDim2.fromOffset(14, 75)
slotsFrame.BackgroundTransparency = 1
slotsFrame.Parent = panel

local slotLayout = Instance.new("UIListLayout")
slotLayout.FillDirection = Enum.FillDirection.Horizontal
slotLayout.Padding = UDim.new(0, 5)
slotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
slotLayout.Parent = slotsFrame

local selectedSlot = 1
local slotButtons = {}
local current = nil
local requestBusy = false

for slot = 1, 5 do
    local button = Instance.new("TextButton")
    button.Name = "Slot" .. slot
    button.Size = UDim2.new(0.195, -4, 0, 60)
    button.BackgroundColor3 = Color3.fromRGB(29, 36, 47)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(222, 229, 238)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 8
    button.TextWrapped = true
    button.Text = "SLOT " .. slot
    button.Parent = slotsFrame
    corner(button, 7)
    stroke(button, Color3.fromRGB(83, 101, 124), 0.30)
    slotButtons[slot] = button
    button.Activated:Connect(function()
        selectedSlot = slot
        for index, other in ipairs(slotButtons) do
            other.BackgroundColor3 = index == selectedSlot and Color3.fromRGB(52, 67, 85) or Color3.fromRGB(29, 36, 47)
        end
    end)
end

local clearButton = Instance.new("TextButton")
clearButton.Size = UDim2.fromOffset(126, 28)
clearButton.Position = UDim2.fromOffset(14, 145)
clearButton.BackgroundColor3 = Color3.fromRGB(51, 43, 43)
clearButton.BorderSizePixel = 0
clearButton.TextColor3 = Color3.fromRGB(232, 191, 191)
clearButton.Font = Enum.Font.GothamBold
clearButton.TextSize = 9
clearButton.Text = tr("CLEAR SLOT", "KOSONGKAN SLOT")
clearButton.Parent = panel
corner(clearButton, 7)

local status = label(panel, UDim2.new(1, -170, 0, 30), UDim2.fromOffset(154, 145), tr("Select a slot, then choose an item.", "Pilih slot, lalu pilih barang."), 9, Enum.Font.GothamMedium, Color3.fromRGB(154, 207, 229))
status.TextWrapped = true

local list = Instance.new("ScrollingFrame")
list.Name = "M5B2ShowcaseInventory"
list.Size = UDim2.new(1, -28, 1, -190)
list.Position = UDim2.fromOffset(14, 178)
list.BackgroundColor3 = Color3.fromRGB(20, 25, 33)
list.BackgroundTransparency = 0.08
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.fromOffset(0, 0)
list.Parent = panel
corner(list, 9)

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 7)
padding.PaddingBottom = UDim.new(0, 7)
padding.PaddingLeft = UDim.new(0, 7)
padding.PaddingRight = UDim.new(0, 7)
padding.Parent = list

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function invoke(remote, action, a, b)
    if requestBusy then return nil end
    requestBusy = true
    local ok, result = pcall(function() return remote:InvokeServer(action, a, b) end)
    requestBusy = false
    if not ok then
        status.Text = tr("Showcase connection failed safely.", "Koneksi pajangan gagal dengan aman.")
        return nil
    end
    return result
end

local function sync()
    local result = invoke(extraRequest, "SYNC")
    if result and result.ok then
        current = result
        return true
    end
    status.Text = tr("Showcase is still syncing. Try again.", "Pajangan masih sinkron. Coba lagi.")
    return false
end

local function occupiedSlot(instanceId)
    if not current or not current.slots then return nil end
    for slot = 1, 5 do
        if current.slots[slot] == instanceId then return slot end
    end
    return nil
end

local renderInventory

local function renderSlots()
    if not current then return end
    for slot = 1, 5 do
        local item = current.slotItems and current.slotItems[slot] or nil
        local button = slotButtons[slot]
        if item then
            button.Text = string.format("SLOT %d\n%s\n%s", slot, tostring(item.rarity), tostring(item.serial))
            button.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(222, 229, 238)
        else
            button.Text = string.format("SLOT %d\n%s", slot, tr("EMPTY", "KOSONG"))
            button.TextColor3 = Color3.fromRGB(158, 169, 184)
        end
        button.BackgroundColor3 = slot == selectedSlot and Color3.fromRGB(52, 67, 85) or Color3.fromRGB(29, 36, 47)
    end
end

local function refreshUI(message)
    if sync() then
        renderSlots()
        renderInventory()
        if message then status.Text = message end
    end
end

local function clearExistingLocation(instanceId, targetSlot)
    local slot = occupiedSlot(instanceId)
    if not slot or slot == targetSlot then return true end
    local result
    if slot <= 3 then
        result = invoke(baseRequest, "CLEAR_SLOT", slot)
    else
        result = invoke(extraRequest, "CLEAR_SLOT", slot)
    end
    return result and result.ok == true
end

local function chooseItem(instanceId)
    status.Text = tr("Saving showcase slot...", "Menyimpan slot pajangan...")
    if not clearExistingLocation(instanceId, selectedSlot) then
        refreshUI(tr("Could not move that item yet.", "Barang itu belum bisa dipindahkan."))
        return
    end

    local result
    if selectedSlot <= 3 then
        result = invoke(baseRequest, "SET_SLOT", selectedSlot, instanceId)
    else
        result = invoke(extraRequest, "SET_SLOT", selectedSlot, instanceId)
        if result and result.code == "ALREADY_DISPLAYED" and result.occupiedSlot then
            local cleared = invoke(baseRequest, "CLEAR_SLOT", result.occupiedSlot)
            if cleared and cleared.ok then result = invoke(extraRequest, "SET_SLOT", selectedSlot, instanceId) end
        end
    end

    if result and result.ok then
        refreshUI(tr("Showcase updated — rack refreshed.", "Pajangan diperbarui — rak sudah disegarkan."))
    else
        refreshUI(tr("Showcase update failed safely.", "Pembaruan pajangan gagal dengan aman."))
    end
end

renderInventory = function()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    if not current then return end

    for order, item in ipairs(current.inventory or {}) do
        local row = Instance.new("Frame")
        row.Name = tostring(item.instanceId)
        row.LayoutOrder = order
        row.Size = UDim2.new(1, -2, 0, 54)
        row.BackgroundColor3 = Color3.fromRGB(27, 33, 43)
        row.BorderSizePixel = 0
        row.Parent = list
        corner(row, 8)

        local accent = Instance.new("Frame")
        accent.Size = UDim2.fromOffset(6, 40)
        accent.Position = UDim2.fromOffset(7, 7)
        accent.BackgroundColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(177, 187, 201)
        accent.BorderSizePixel = 0
        accent.Parent = row
        corner(accent, 3)

        local name = label(row, UDim2.new(1, -126, 0, 22), UDim2.fromOffset(21, 5), tostring(item.name), 10, Enum.Font.GothamBold, Color3.fromRGB(235, 239, 244))
        name.TextTruncate = Enum.TextTruncate.AtEnd
        local detail = label(row, UDim2.new(1, -126, 0, 20), UDim2.fromOffset(21, 28), tostring(item.rarity) .. "  •  " .. tostring(item.serial), 9, Enum.Font.RobotoMono, RARITY_COLORS[item.rarity] or Color3.fromRGB(158, 171, 188))
        detail.TextTruncate = Enum.TextTruncate.AtEnd

        local action = Instance.new("TextButton")
        action.Size = UDim2.fromOffset(92, 34)
        action.Position = UDim2.new(1, -101, 0.5, -17)
        action.BorderSizePixel = 0
        action.Font = Enum.Font.GothamBold
        action.TextSize = 9
        action.Parent = row
        corner(action, 7)

        local slot = occupiedSlot(item.instanceId)
        if slot then
            action.Text = "SLOT " .. slot
            action.BackgroundColor3 = Color3.fromRGB(48, 70, 62)
            action.TextColor3 = Color3.fromRGB(181, 231, 201)
        else
            action.Text = tr("SELECT", "PILIH")
            action.BackgroundColor3 = Color3.fromRGB(53, 68, 87)
            action.TextColor3 = Color3.fromRGB(222, 230, 240)
        end
        action.Activated:Connect(function() chooseItem(item.instanceId) end)
    end

    if #(current.inventory or {}) == 0 then
        local empty = label(list, UDim2.new(1, -14, 0, 60), UDim2.fromOffset(7, 7), tr("No persisted serialized items available yet.", "Belum ada barang berserial yang tersimpan."), 10, Enum.Font.Gotham, Color3.fromRGB(153, 164, 180))
        empty.TextWrapped = true
        empty.TextXAlignment = Enum.TextXAlignment.Center
    end
end

clearButton.Activated:Connect(function()
    local result
    if selectedSlot <= 3 then
        result = invoke(baseRequest, "CLEAR_SLOT", selectedSlot)
    else
        result = invoke(extraRequest, "CLEAR_SLOT", selectedSlot)
    end
    if result and result.ok then
        refreshUI(tr("Slot cleared.", "Slot dikosongkan."))
    else
        refreshUI(tr("Could not clear that slot yet.", "Slot belum bisa dikosongkan."))
    end
end)

local function setOpen(open)
    panel.Visible = open
    collectionPopup.Visible = not open
    if open then
        status.Text = tr("Loading 5-slot showcase...", "Memuat pajangan 5 slot...")
        refreshUI()
    end
end

openButton.Activated:Connect(function() setOpen(true) end)
close.Activated:Connect(function() setOpen(false) end)

extraUpdate.OnClientEvent:Connect(function()
    if panel.Visible then task.defer(refreshUI) end
end)

-- Re-hide the legacy button/panel if the old client finishes constructing after this script.
task.spawn(function()
    for _ = 1, 50 do
        local legacyButton = collectionPopup:FindFirstChild("M5BShowcaseButton")
        if legacyButton then legacyButton.Visible = false end
        local legacyPanel = collectionGui:FindFirstChild("M5BShowcasePanel")
        if legacyPanel then legacyPanel.Visible = false end
        task.wait(0.2)
    end
end)
