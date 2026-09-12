-- LOST & FOUND: NIGHT SHIFT — M6-B unified menu hotfix v2
-- True BBYA-style single MENU drawer: native feature buttons are temporarily reparented into the drawer.
-- Existing Collection / Archive / Trade / Station Shop button callbacks remain the action owners.
-- No server, economy, case, rarity, serial, trade, showcase or canon mutation.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Retire prior unified menu controllers so only one authority remains.
for _, name in ipairs({"LostAndFoundUnifiedMenu", "LostAndFoundUnifiedMenuV2"}) do
    local old = playerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundUnifiedMenuV2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 220
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
gui:SetAttribute("LostFoundUnifiedMenuVersion", "M6B_UNIFIED_MENU_V2")

local C = {
    bg = Color3.fromRGB(11, 14, 20),
    panel = Color3.fromRGB(19, 24, 32),
    white = Color3.fromRGB(242, 244, 248),
    muted = Color3.fromRGB(151, 164, 181),
    line = Color3.fromRGB(79, 92, 110),
    gold = Color3.fromRGB(231, 177, 87),
}

local function corner(target, radius)
    local value = Instance.new("UICorner")
    value.CornerRadius = UDim.new(0, radius or 10)
    value.Parent = target
end

local function stroke(target, color, transparency, thickness)
    local value = Instance.new("UIStroke")
    value.Color = color or C.line
    value.Transparency = transparency or 0.45
    value.Thickness = thickness or 1
    value.Parent = target
end

local function label(parent, text, position, size, textSize, font, color)
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Text = text
    object.Position = position
    object.Size = size
    object.Font = font or Enum.Font.Gotham
    object.TextSize = textSize or 10
    object.TextColor3 = color or C.white
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.TextWrapped = true
    object.ZIndex = 223
    object.Parent = parent
    return object
end

local menuButton = Instance.new("TextButton")
menuButton.Name = "MenuButton"
menuButton.AnchorPoint = Vector2.new(1, 0)
menuButton.Size = UDim2.fromOffset(112, 34)
menuButton.Position = UDim2.new(1, -18, 0, 52)
menuButton.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
menuButton.BackgroundTransparency = 0.03
menuButton.BorderSizePixel = 0
menuButton.Text = "MENU"
menuButton.TextColor3 = C.gold
menuButton.Font = Enum.Font.GothamBold
menuButton.TextSize = 11
menuButton.ZIndex = 225
menuButton.Parent = gui
corner(menuButton, 9)
stroke(menuButton, C.gold, 0.34, 1.1)

local drawer = Instance.new("Frame")
drawer.Name = "FeatureDrawer"
drawer.AnchorPoint = Vector2.new(1, 0)
drawer.Size = UDim2.fromOffset(230, 278)
drawer.Position = UDim2.new(1, -18, 0, 92)
drawer.BackgroundColor3 = C.bg
drawer.BackgroundTransparency = 0.08
drawer.BorderSizePixel = 0
drawer.Active = true
drawer.Visible = false
drawer.ZIndex = 221
drawer.Parent = gui
corner(drawer, 13)
stroke(drawer, C.gold, 0.44, 1.1)

local head = Instance.new("Frame")
head.Name = "Header"
head.Position = UDim2.fromOffset(10, 10)
head.Size = UDim2.new(1, -20, 0, 50)
head.BackgroundColor3 = C.panel
head.BackgroundTransparency = 0.16
head.BorderSizePixel = 0
head.ZIndex = 222
head.Parent = drawer
corner(head, 10)

label(head, "NIGHT SHIFT MENU", UDim2.fromOffset(11, 4), UDim2.new(1, -22, 0, 23), 13, Enum.Font.GothamBlack, C.white)
label(head, "AKSES & KOLEKSI", UDim2.fromOffset(11, 25), UDim2.new(1, -22, 0, 16), 8, Enum.Font.GothamBold, C.muted)

local specs = {
    { guiName = "LostAndFoundCollectionHUD", buttonName = "IndexButton", popupName = "CollectionPopup", slot = 1 },
    { guiName = "LostAndFoundM3HUD", buttonName = "ArchiveButton", popupName = "ArchivePopup", slot = 2 },
    { guiName = "LostAndFoundTradeHUD", buttonName = "TradeButton", popupName = "TradePopup", slot = 3 },
    { guiName = "LostAndFoundStationShop", buttonName = "StationShopButton", popupName = "ShopPanel", slot = 4 },
}

local records = {}
local drawerOpen = false
local refreshing = false
local casePopupBound = nil

local function casePopupOpen()
    local main = playerGui:FindFirstChild("LostAndFoundHUD")
    local popup = main and main:FindFirstChild("CaseFilePopup")
    return popup and popup.Visible == true
end

local function anyFeaturePopupOpen()
    if casePopupOpen() then return true end
    for _, record in pairs(records) do
        if record.popup and record.popup.Parent and record.popup.Visible then
            return true
        end
    end
    return false
end

local function restoreRecord(record)
    local button = record.button
    if not button or not button.Parent then return end
    record.adjusting = true
    if record.originalParent and record.originalParent.Parent then
        button.Parent = record.originalParent
    end
    button.AnchorPoint = record.anchorPoint
    button.Position = record.position
    button.Size = record.size
    button.ZIndex = record.zIndex
    button.Visible = false
    record.adjusting = false
end

local function putRecordInDrawer(record)
    local button = record.button
    if not button or not button.Parent then return end
    record.adjusting = true
    button.Parent = drawer
    button.AnchorPoint = Vector2.new(0, 0)
    button.Position = UDim2.fromOffset(12, 72 + ((record.slot - 1) * 48))
    button.Size = UDim2.fromOffset(206, 40)
    button.ZIndex = 224
    button.Visible = true
    record.adjusting = false
end

local function closeDrawer()
    drawerOpen = false
    drawer.Visible = false
    menuButton.Text = "MENU"
    for _, record in pairs(records) do
        restoreRecord(record)
    end
end

local function refreshState()
    if refreshing then return end
    refreshing = true

    if anyFeaturePopupOpen() then
        closeDrawer()
        menuButton.Visible = false
    elseif drawerOpen then
        menuButton.Visible = true
        menuButton.Text = "TUTUP"
        drawer.Visible = true
        for _, record in pairs(records) do
            putRecordInDrawer(record)
        end
    else
        menuButton.Visible = true
        menuButton.Text = "MENU"
        drawer.Visible = false
        for _, record in pairs(records) do
            restoreRecord(record)
        end
    end

    refreshing = false
end

local function bindRecord(spec)
    local sourceGui = playerGui:FindFirstChild(spec.guiName)
    if not sourceGui or not sourceGui:IsA("ScreenGui") then return false end

    local button = sourceGui:FindFirstChild(spec.buttonName, true)
    local popup = sourceGui:FindFirstChild(spec.popupName, true)
    if not button or not button:IsA("GuiButton") or not popup or not popup:IsA("GuiObject") then return false end

    local existing = records[spec.guiName]
    if existing and existing.button == button and existing.popup == popup then return true end

    local record = {
        gui = sourceGui,
        button = button,
        popup = popup,
        slot = spec.slot,
        originalParent = button.Parent,
        anchorPoint = button.AnchorPoint,
        position = button.Position,
        size = button.Size,
        zIndex = button.ZIndex,
        adjusting = false,
    }
    records[spec.guiName] = record

    button:GetPropertyChangedSignal("Visible"):Connect(function()
        if record.adjusting then return end
        task.defer(refreshState)
    end)
    popup:GetPropertyChangedSignal("Visible"):Connect(function()
        task.defer(refreshState)
    end)

    restoreRecord(record)
    return true
end

local function bindCasePopup()
    local main = playerGui:FindFirstChild("LostAndFoundHUD")
    local popup = main and main:FindFirstChild("CaseFilePopup")
    if not popup or popup == casePopupBound then return popup ~= nil end
    casePopupBound = popup
    popup:GetPropertyChangedSignal("Visible"):Connect(function()
        task.defer(refreshState)
    end)
    return true
end

local function reconcile()
    for _, spec in ipairs(specs) do bindRecord(spec) end
    bindCasePopup()
    refreshState()
end

menuButton.Activated:Connect(function()
    if anyFeaturePopupOpen() then return end
    drawerOpen = not drawerOpen
    refreshState()
end)

playerGui.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundHUD"
        or child.Name == "LostAndFoundCollectionHUD"
        or child.Name == "LostAndFoundM3HUD"
        or child.Name == "LostAndFoundTradeHUD"
        or child.Name == "LostAndFoundStationShop" then
        task.defer(reconcile)
    end
end)

-- Bounded startup reconciliation only. Native feature callbacks remain authority.
task.spawn(function()
    for _ = 1, 100 do
        reconcile()
        if records.LostAndFoundCollectionHUD
            and records.LostAndFoundM3HUD
            and records.LostAndFoundTradeHUD
            and records.LostAndFoundStationShop
            and casePopupBound then
            break
        end
        task.wait(0.10)
    end
    refreshState()
end)
