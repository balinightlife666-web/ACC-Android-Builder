-- LOST & FOUND: NIGHT SHIFT — M6-B unified menu hotfix
-- Collapses legacy right-side utility launchers into one BBYA-style MENU drawer.
-- Existing Collection / Archive / Trade / Station Shop buttons remain native action owners.
-- No server, economy, case, rarity, serial, trade, showcase or canon mutation.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("LostAndFoundUnifiedMenu")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundUnifiedMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 220
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

gui:SetAttribute("LostFoundUnifiedMenuVersion", "M6B_UNIFIED_MENU_V1")

local C = {
    bg = Color3.fromRGB(11, 14, 20),
    panel = Color3.fromRGB(19, 24, 32),
    card = Color3.fromRGB(29, 35, 45),
    white = Color3.fromRGB(242, 244, 248),
    muted = Color3.fromRGB(151, 164, 181),
    line = Color3.fromRGB(79, 92, 110),
    gold = Color3.fromRGB(231, 177, 87),
    cyan = Color3.fromRGB(88, 221, 224),
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

local function makeLabel(parent, text, position, size, textSize, font, color)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.Position = position
    label.Size = size
    label.Font = font or Enum.Font.Gotham
    label.TextSize = textSize or 10
    label.TextColor3 = color or C.white
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.ZIndex = 223
    label.Parent = parent
    return label
end

local menuButton = Instance.new("TextButton")
menuButton.Name = "MenuButton"
menuButton.AnchorPoint = Vector2.new(1, 0)
menuButton.Size = UDim2.fromOffset(128, 36)
menuButton.Position = UDim2.new(1, -18, 0, 98)
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
stroke(menuButton, C.gold, 0.36, 1.1)

local drawer = Instance.new("Frame")
drawer.Name = "FeatureDrawer"
drawer.AnchorPoint = Vector2.new(1, 0)
drawer.Size = UDim2.fromOffset(230, 270)
drawer.Position = UDim2.new(1, -18, 0, 144)
drawer.BackgroundColor3 = C.bg
drawer.BackgroundTransparency = 0.10
drawer.BorderSizePixel = 0
drawer.Active = true
drawer.Visible = false
drawer.ZIndex = 221
drawer.Parent = gui
corner(drawer, 13)
stroke(drawer, C.gold, 0.48, 1.1)

local head = Instance.new("Frame")
head.Name = "Header"
head.Position = UDim2.fromOffset(10, 10)
head.Size = UDim2.new(1, -20, 0, 52)
head.BackgroundColor3 = C.panel
head.BackgroundTransparency = 0.18
head.BorderSizePixel = 0
head.ZIndex = 222
head.Parent = drawer
corner(head, 10)

makeLabel(head, "NIGHT SHIFT MENU", UDim2.fromOffset(11, 4), UDim2.new(1, -22, 0, 24), 13, Enum.Font.GothamBlack, C.white)
makeLabel(head, "AKSES & KOLEKSI", UDim2.fromOffset(11, 26), UDim2.new(1, -22, 0, 16), 8, Enum.Font.GothamBold, C.muted)

local footer = makeLabel(drawer, "Pilih fitur", UDim2.new(0, 12, 1, -23), UDim2.new(1, -24, 0, 14), 8, Enum.Font.GothamMedium, C.muted)
footer.TextXAlignment = Enum.TextXAlignment.Center

local specs = {
    { guiName = "LostAndFoundCollectionHUD", buttonName = "IndexButton", popupName = "CollectionPopup", slot = 1 },
    { guiName = "LostAndFoundM3HUD", buttonName = "ArchiveButton", popupName = "ArchivePopup", slot = 2 },
    { guiName = "LostAndFoundTradeHUD", buttonName = "TradeButton", popupName = "TradePopup", slot = 3 },
    { guiName = "LostAndFoundStationShop", buttonName = "StationShopButton", popupName = "ShopPanel", slot = 4 },
}

local records = {}
local drawerOpen = false
local refreshing = false

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

local function setButtonVisible(record, visible)
    if not record.button or not record.button.Parent then return end
    record.adjusting = true
    record.button.Visible = visible
    record.adjusting = false
end

local function restoreGeometry(record)
    if not record.button or not record.button.Parent then return end
    record.adjusting = true
    record.button.AnchorPoint = record.anchorPoint
    record.button.Position = record.position
    record.button.Size = record.size
    record.button.ZIndex = record.zIndex
    record.adjusting = false
    if record.gui and record.gui.Parent then
        record.gui.DisplayOrder = record.displayOrder
    end
end

local function applyDrawerGeometry(record)
    if not record.button or not record.button.Parent then return end
    record.adjusting = true
    record.button.AnchorPoint = Vector2.new(1, 0)
    record.button.Position = UDim2.new(1, -30, 0, 210 + ((record.slot - 1) * 48))
    record.button.Size = UDim2.fromOffset(206, 42)
    record.button.ZIndex = 250
    record.button.Visible = true
    record.adjusting = false
    if record.gui and record.gui.Parent then
        record.gui.DisplayOrder = 221
    end
end

local function closeDrawer()
    drawerOpen = false
    drawer.Visible = false
    menuButton.Text = "MENU"
    for _, record in pairs(records) do
        restoreGeometry(record)
        setButtonVisible(record, false)
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
            applyDrawerGeometry(record)
        end
    else
        menuButton.Visible = true
        menuButton.Text = "MENU"
        drawer.Visible = false
        for _, record in pairs(records) do
            restoreGeometry(record)
            setButtonVisible(record, false)
        end
    end

    refreshing = false
end

local function bindRecord(spec)
    local sourceGui = playerGui:FindFirstChild(spec.guiName)
    if not sourceGui or not sourceGui:IsA("ScreenGui") then return false end

    local button = sourceGui:FindFirstChild(spec.buttonName)
    local popup = sourceGui:FindFirstChild(spec.popupName)
    if not button or not button:IsA("GuiButton") or not popup or not popup:IsA("GuiObject") then return false end

    local existing = records[spec.guiName]
    if existing and existing.button == button and existing.popup == popup then return true end

    local record = {
        gui = sourceGui,
        button = button,
        popup = popup,
        slot = spec.slot,
        anchorPoint = button.AnchorPoint,
        position = button.Position,
        size = button.Size,
        zIndex = button.ZIndex,
        displayOrder = sourceGui.DisplayOrder,
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

    setButtonVisible(record, false)
    return true
end

local casePopupBound = nil
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
    for _, spec in ipairs(specs) do
        bindRecord(spec)
    end
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

-- Bounded startup reconciliation only. Native button events remain the feature authority.
task.spawn(function()
    for _ = 1, 80 do
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
