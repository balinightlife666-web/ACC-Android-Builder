-- LOST & FOUND: NIGHT SHIFT — M6-B unified mobile menu
-- UI-only hotfix: collapse INDEX / ARCHIVE / TRADE / STATION SHOP into one MENU panel.
-- Existing feature buttons and their original Activated handlers are preserved.
-- Also pins the progression HUD to the actual top-center on compact/touch layouts.
-- No server, economy, case, reward, rarity, serial, trade authority, showcase or canon mutation.

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function isIndonesian()
    if player:GetAttribute("LostFoundResolvedLocale") == "id" then return true end
    local ok, locale = pcall(function() return LocalizationService.RobloxLocaleId end)
    locale = ok and string.lower(tostring(locale or "")) or ""
    return string.sub(locale, 1, 2) == "id"
end

local function compactMode()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    return UserInputService.TouchEnabled or viewport.Y <= 720
end

local function corner(target, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = target
    return c
end

local function stroke(target, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(84, 99, 119)
    s.Transparency = transparency or 0.28
    s.Thickness = thickness or 1.1
    s.Parent = target
    return s
end

local existing = playerGui:FindFirstChild("LostAndFoundMenuHub")
if existing then existing:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundMenuHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 60
gui.Parent = playerGui

local menuButton = Instance.new("TextButton")
menuButton.Name = "UnifiedMenuButton"
menuButton.AnchorPoint = Vector2.new(1, 0)
menuButton.Size = UDim2.fromOffset(128, 34)
menuButton.Position = UDim2.new(1, -18, 0, 104)
menuButton.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
menuButton.BackgroundTransparency = 0.03
menuButton.BorderSizePixel = 0
menuButton.Text = "MENU"
menuButton.TextColor3 = Color3.fromRGB(245, 205, 126)
menuButton.Font = Enum.Font.GothamBold
menuButton.TextSize = 11
menuButton.Parent = gui
corner(menuButton, 9)
stroke(menuButton, Color3.fromRGB(115, 99, 70), 0.20, 1.2)

local panel = Instance.new("Frame")
panel.Name = "UnifiedMenuPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Size = UDim2.fromOffset(210, 224)
panel.Position = UDim2.new(1, -18, 0, 102)
panel.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
panel.BackgroundTransparency = 0.02
panel.BorderSizePixel = 0
panel.Visible = false
panel.Active = true
panel.Parent = gui
corner(panel, 12)
stroke(panel, Color3.fromRGB(115, 99, 70), 0.16, 1.2)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -48, 0, 32)
title.Position = UDim2.fromOffset(13, 8)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "MENU SHIFT"
title.TextColor3 = Color3.fromRGB(245, 218, 157)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = panel

local close = Instance.new("TextButton")
close.Name = "Close"
close.Size = UDim2.fromOffset(30, 30)
close.Position = UDim2.new(1, -39, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(38, 45, 57)
close.BorderSizePixel = 0
close.Text = "×"
close.TextColor3 = Color3.fromRGB(240, 242, 246)
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.Parent = panel
corner(close, 8)

local list = Instance.new("Frame")
list.Name = "MenuItems"
list.Size = UDim2.new(1, -24, 1, -54)
list.Position = UDim2.fromOffset(12, 46)
list.BackgroundTransparency = 1
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = list

local features = {
    { guiName = "LostAndFoundCollectionHUD", buttonName = "IndexButton", popupName = "CollectionPopup", order = 1 },
    { guiName = "LostAndFoundM3HUD", buttonName = "ArchiveButton", popupName = "ArchivePopup", order = 2 },
    { guiName = "LostAndFoundTradeHUD", buttonName = "TradeButton", popupName = "TradePopup", order = 3 },
    { guiName = "LostAndFoundStationShop", buttonName = "StationShopButton", popupName = "ShopPanel", order = 4 },
}

local adopted = {}
local popupHooks = setmetatable({}, { __mode = "k" })
local textHooks = setmetatable({}, { __mode = "k" })
local reconcilingText = setmetatable({}, { __mode = "k" })

local function localizeFeatureButton(button)
    if not button or not button:IsA("TextButton") or not isIndonesian() then return end
    if reconcilingText[button] then return end

    local old = tostring(button.Text or "")
    local new = old
    new = new:gsub("^INDEX", "INDEKS")
    new = new:gsub("^ARCHIVE", "ARSIP")
    if new == "TRADE" then new = "TUKAR" end
    if new == "STATION SHOP" then new = "TOKO STASIUN" end

    if new ~= old then
        reconcilingText[button] = true
        button.Text = new
        reconcilingText[button] = nil
    end

    if not textHooks[button] then
        textHooks[button] = true
        button:GetPropertyChangedSignal("Text"):Connect(function()
            task.defer(function() localizeFeatureButton(button) end)
        end)
    end
end

local function findPopup(feature)
    local featureGui = playerGui:FindFirstChild(feature.guiName)
    return featureGui and featureGui:FindFirstChild(feature.popupName) or nil
end

local function anyFeatureOpen()
    for _, feature in ipairs(features) do
        local popup = findPopup(feature)
        if popup and popup:IsA("GuiObject") and popup.Visible then
            return true
        end
    end
    return false
end

local function syncHubVisibility()
    local busy = anyFeatureOpen()
    if busy then
        panel.Visible = false
        menuButton.Visible = false
    else
        menuButton.Visible = true
    end
end

local function hookPopup(feature)
    local popup = findPopup(feature)
    if not popup or popupHooks[popup] then return end
    popupHooks[popup] = true
    popup:GetPropertyChangedSignal("Visible"):Connect(function()
        task.defer(syncHubVisibility)
    end)
end

local function styleAdoptedButton(button, order)
    button.AnchorPoint = Vector2.new(0, 0)
    button.Position = UDim2.new()
    button.Size = UDim2.new(1, 0, 0, 36)
    button.LayoutOrder = order
    button.TextSize = 11
    button.Visible = true
    button.Parent = list
    localizeFeatureButton(button)
end

local function adoptFeature(feature)
    if adopted[feature.buttonName] then
        local button = adopted[feature.buttonName]
        if button.Parent ~= list then
            styleAdoptedButton(button, feature.order)
        end
        hookPopup(feature)
        return true
    end

    local featureGui = playerGui:FindFirstChild(feature.guiName)
    local button = featureGui and featureGui:FindFirstChild(feature.buttonName)
    if not button or not button:IsA("TextButton") then return false end

    adopted[feature.buttonName] = button
    styleAdoptedButton(button, feature.order)
    hookPopup(feature)
    return true
end

local function pinProgressionTop()
    if not compactMode() then return end
    local progressionGui = playerGui:FindFirstChild("LostAndFoundProgressionHUD")
    local progressionPanel = progressionGui and progressionGui:FindFirstChild("ProgressionPanel")
    if not progressionGui or not progressionPanel then return end

    -- Top-center is clear of Roblox's left-side core controls. Ignore the inset here
    -- so the progression card no longer floats one full top-bar lower on phones.
    progressionGui.IgnoreGuiInset = true
    progressionPanel.Position = UDim2.new(0.5, 0, 0, 8)
end

local function reconcile()
    pinProgressionTop()
    for _, feature in ipairs(features) do
        adoptFeature(feature)
    end
    syncHubVisibility()
end

local function openMenu()
    if anyFeatureOpen() then return end
    for _, feature in ipairs(features) do
        local button = adopted[feature.buttonName]
        if button then
            button.Visible = true
            localizeFeatureButton(button)
        end
    end
    panel.Visible = not panel.Visible
end

menuButton.Activated:Connect(openMenu)
close.Activated:Connect(function()
    panel.Visible = false
end)

-- Clicking a preserved feature button runs its original handler. As soon as its
-- original popup becomes visible, the menu hub automatically gets out of the way.
list.ChildAdded:Connect(function(child)
    if child:IsA("TextButton") then
        child.Activated:Connect(function()
            panel.Visible = false
            task.defer(syncHubVisibility)
        end)
    end
end)

-- Existing buttons may already have been adopted before ChildAdded wiring above.
for _, child in ipairs(list:GetChildren()) do
    if child:IsA("TextButton") then
        child.Activated:Connect(function()
            panel.Visible = false
            task.defer(syncHubVisibility)
        end)
    end
end

playerGui.ChildAdded:Connect(function(child)
    for _, feature in ipairs(features) do
        if child.Name == feature.guiName then
            task.defer(reconcile)
            break
        end
    end
    if child.Name == "LostAndFoundProgressionHUD" then
        task.defer(pinProgressionTop)
    end
end)

player:GetAttributeChangedSignal("LostFoundResolvedLocale"):Connect(function()
    task.defer(function()
        for _, button in pairs(adopted) do
            localizeFeatureButton(button)
        end
    end)
end)

local camera = workspace.CurrentCamera
if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        task.defer(pinProgressionTop)
    end)
end

-- Bounded startup reconciliation: feature LocalScripts are created independently.
task.spawn(function()
    for _ = 1, 100 do
        reconcile()
        local count = 0
        for _, feature in ipairs(features) do
            if adopted[feature.buttonName] then count += 1 end
        end
        if count == #features and playerGui:FindFirstChild("LostAndFoundProgressionHUD") then
            break
        end
        task.wait(0.10)
    end
end)
