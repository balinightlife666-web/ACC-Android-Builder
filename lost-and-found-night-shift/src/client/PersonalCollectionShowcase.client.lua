-- LOST & FOUND: NIGHT SHIFT — M5-B Personal Collection Showcase v1 client
-- Adds a compact manager inside the Collection Index flow for choosing three
-- serialized items to display publicly at the player's personal station.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local request = remotes:WaitForChild("PersonalShowcaseRequest")
local update = remotes:WaitForChild("PersonalShowcaseUpdate")

local function isIndonesian()
    if player:GetAttribute("LostFoundResolvedLocale") == "id" then return true end
    local ok, locale = pcall(function() return LocalizationService.RobloxLocaleId end)
    locale = ok and string.lower(tostring(locale or "")) or ""
    return string.sub(locale, 1, 2) == "id"
end

local ID = isIndonesian()
local function tr(en, id)
    return ID and id or en
end

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

local function textLabel(parent, size, position, text, textSize, font, color)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = color or Color3.fromRGB(232, 236, 242)
    label.Font = font or Enum.Font.Gotham
    label.TextSize = textSize or 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local collectionGui = playerGui:WaitForChild("LostAndFoundCollectionHUD", 40)
if not collectionGui then return end
local collectionPopup = collectionGui:WaitForChild("CollectionPopup", 10)
local indexButton = collectionGui:WaitForChild("IndexButton", 10)
if not collectionPopup or not indexButton then return end

-- Make room for the showcase manager entry without creating another permanent HUD button.
for _, child in ipairs(collectionPopup:GetChildren()) do
    if child:IsA("TextLabel") and child.Text == "LOST PROPERTY COLLECTION" then
        child.Size = UDim2.new(1, -162, child.Size.Y.Scale, child.Size.Y.Offset)
    end
end

local openButton = Instance.new("TextButton")
openButton.Name = "M5BShowcaseButton"
openButton.Size = UDim2.fromOffset(96, 28)
openButton.Position = UDim2.new(1, -143, 0, 8)
openButton.BackgroundColor3 = Color3.fromRGB(40, 53, 68)
openButton.BorderSizePixel = 0
openButton.TextColor3 = Color3.fromRGB(196, 224, 238)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 9
openButton.Text = tr("SHOWCASE", "PAJANGAN")
openButton.Parent = collectionPopup
corner(openButton, 7)
stroke(openButton, Color3.fromRGB(93, 129, 151), 0.25)

local panel = Instance.new("Frame")
panel.Name = "M5BShowcasePanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Size = UDim2.new(0.86, 0, 0.78, 0)
panel.Position = UDim2.fromScale(0.5, 0.52)
panel.BackgroundColor3 = Color3.fromRGB(14, 18, 25)
panel.BackgroundTransparency = 0.01
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = collectionGui
corner(panel, 12)
stroke(panel, Color3.fromRGB(92, 116, 139), 0.18)

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(330, 330)
constraint.MaxSize = Vector2.new(500, 455)
constraint.Parent = panel

local title = textLabel(panel, UDim2.new(1, -60, 0, 30), UDim2.fromOffset(14, 9), tr("PERSONAL SHOWCASE", "PAJANGAN PRIBADI"), 16, Enum.Font.GothamBold, Color3.fromRGB(239, 207, 139))
local subtitle = textLabel(panel, UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 38), tr("Choose up to 3 owned serialized items. Nearby players can see them at your station.", "Pilih maksimal 3 barang berserial milikmu. Pemain lain bisa melihatnya di stasiunmu."), 10, Enum.Font.Gotham, Color3.fromRGB(158, 173, 190))
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
slotsFrame.Size = UDim2.new(1, -28, 0, 68)
slotsFrame.Position = UDim2.fromOffset(14, 75)
slotsFrame.BackgroundTransparency = 1
slotsFrame.Parent = panel

local slotLayout = Instance.new("UIListLayout")
slotLayout.FillDirection = Enum.FillDirection.Horizontal
slotLayout.Padding = UDim.new(0, 7)
slotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
slotLayout.Parent = slotsFrame

local selectedSlot = 1
local slotButtons = {}
local current = nil
local requestBusy = false

for slot = 1, 3 do
    local button = Instance.new("TextButton")
    button.Name = "Slot" .. tostring(slot)
    button.Size = UDim2.new(0.32, -4, 0, 62)
    button.BackgroundColor3 = Color3.fromRGB(29, 36, 47)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(222, 229, 238)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 9
    button.TextWrapped = true
    button.Text = tr("SLOT ", "SLOT ") .. tostring(slot)
    button.Parent = slotsFrame
    corner(button, 8)
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
clearButton.Position = UDim2.fromOffset(14, 147)
clearButton.BackgroundColor3 = Color3.fromRGB(51, 43, 43)
clearButton.BorderSizePixel = 0
clearButton.TextColor3 = Color3.fromRGB(232, 191, 191)
clearButton.Font = Enum.Font.GothamBold
clearButton.TextSize = 9
clearButton.Text = tr("CLEAR SELECTED SLOT", "KOSONGKAN SLOT")
clearButton.Parent = panel
corner(clearButton, 7)

local status = textLabel(panel, UDim2.new(1, -170, 0, 28), UDim2.fromOffset(154, 147), tr("Select a slot, then choose an item.", "Pilih slot, lalu pilih barang."), 9, Enum.Font.GothamMedium, Color3.fromRGB(154, 207, 229))
status.TextWrapped = true

local list = Instance.new("ScrollingFrame")
list.Name = "ShowcaseInventory"
list.Size = UDim2.new(1, -28, 1, -192)
list.Position = UDim2.fromOffset(14, 180)
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

local function selectedSlotFor(instanceId)
    if not current then return nil end
    for slot = 1, 3 do
        if current.slots and current.slots[slot] == instanceId then return slot end
    end
    return nil
end

local function renderSlots()
    if not current then return end
    for slot = 1, 3 do
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

local renderInventory

local function invoke(action, a, b)
    if requestBusy then return nil end
    requestBusy = true
    local ok, result = pcall(function()
        return request:InvokeServer(action, a, b)
    end)
    requestBusy = false
    if not ok then
        status.Text = tr("Showcase connection failed safely.", "Koneksi pajangan gagal dengan aman.")
        return nil
    end
    return result
end

local function applyResult(result)
    if result and result.ok then
        current = result
        renderSlots()
        renderInventory()
        return true
    end
    local code = result and tostring(result.code or "") or ""
    local idMessages = {
        NOT_READY = "Inventaris masih dimuat.",
        NOT_OWNED = "Barang itu sudah tidak kamu miliki.",
        SAVE_FAILED = "Pilihan pajangan gagal disimpan.",
        BUSY = "Pajangan sedang memproses permintaan lain.",
        INVENTORY_READ_FAILED = "Inventaris belum bisa dibaca. Coba lagi.",
    }
    status.Text = ID and (idMessages[code] or "Pajangan belum bisa diperbarui.") or tostring(result and result.message or "Showcase update failed.")
    return false
end

local function chooseItem(instanceId)
    status.Text = tr("Saving showcase slot...", "Menyimpan slot pajangan...")
    local result = invoke("SET_SLOT", selectedSlot, instanceId)
    if applyResult(result) then
        status.Text = tr("Showcase updated. Your station display is live.", "Pajangan diperbarui. Barang sudah tampil di stasiunmu.")
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

        local name = textLabel(row, UDim2.new(1, -126, 0, 22), UDim2.fromOffset(21, 5), tostring(item.name), 10, Enum.Font.GothamBold, Color3.fromRGB(235, 239, 244))
        name.TextTruncate = Enum.TextTruncate.AtEnd

        local detail = textLabel(row, UDim2.new(1, -126, 0, 20), UDim2.fromOffset(21, 28), tostring(item.rarity) .. "  •  " .. tostring(item.serial), 9, Enum.Font.RobotoMono, RARITY_COLORS[item.rarity] or Color3.fromRGB(158, 171, 188))
        detail.TextTruncate = Enum.TextTruncate.AtEnd

        local action = Instance.new("TextButton")
        action.Size = UDim2.fromOffset(92, 34)
        action.Position = UDim2.new(1, -101, 0.5, -17)
        action.BorderSizePixel = 0
        action.Font = Enum.Font.GothamBold
        action.TextSize = 9
        action.Parent = row
        corner(action, 7)

        local occupiedSlot = selectedSlotFor(item.instanceId)
        if occupiedSlot then
            action.Text = "SLOT " .. tostring(occupiedSlot)
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
        local empty = textLabel(list, UDim2.new(1, -14, 0, 60), UDim2.fromOffset(7, 7), tr("No persisted serialized items are available yet. Finish a shift and try again after your inventory saves.", "Belum ada barang berserial yang tersimpan. Selesaikan shift lalu coba lagi setelah inventaris tersimpan."), 10, Enum.Font.Gotham, Color3.fromRGB(153, 164, 180))
        empty.TextWrapped = true
        empty.TextXAlignment = Enum.TextXAlignment.Center
    end
end

local function sync()
    status.Text = tr("Loading owned serialized items...", "Memuat barang berserial milikmu...")
    local result = invoke("SYNC", "", "")
    if applyResult(result) then
        status.Text = tr("Select a slot, then choose an item.", "Pilih slot, lalu pilih barang.")
    end
end

openButton.Activated:Connect(function()
    collectionPopup.Visible = false
    indexButton.Visible = false
    panel.Visible = true
    task.spawn(sync)
end)

close.Activated:Connect(function()
    panel.Visible = false
    collectionPopup.Visible = true
    indexButton.Visible = false
end)

clearButton.Activated:Connect(function()
    status.Text = tr("Clearing showcase slot...", "Mengosongkan slot pajangan...")
    local result = invoke("CLEAR_SLOT", selectedSlot, "")
    if applyResult(result) then
        status.Text = tr("Selected showcase slot cleared.", "Slot pajangan sudah dikosongkan.")
    end
end)

update.OnClientEvent:Connect(function(_, payload)
    if type(payload) == "table" and payload.ok then
        current = payload
        if panel.Visible then
            renderSlots()
            renderInventory()
        end
    end
end)
