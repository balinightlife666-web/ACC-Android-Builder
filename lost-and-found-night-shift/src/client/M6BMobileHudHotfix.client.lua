-- LOST & FOUND: NIGHT SHIFT — M6-B mobile HUD/runtime hotfix
-- Scope: UI layout, modal layering and Indonesia-first labels only.
-- No server, economy, case, rarity, serial, trade, showcase or canon mutation.

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hooked = setmetatable({}, { __mode = "k" })
local textHooked = setmetatable({}, { __mode = "k" })

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

local function localizeTextObject(object)
    if not isIndonesian() then return end
    if not object or not (object:IsA("TextLabel") or object:IsA("TextButton")) then return end

    local adjusting = false
    local function rewrite()
        if adjusting then return end
        local old = tostring(object.Text or "")
        local new = old
        new = new:gsub("NEXT SHIFT", "SHIFT BERIKUT")
        new = new:gsub("^CREDITS", "KREDIT")
        new = new:gsub(" Credits", " Kredit")
        new = new:gsub("Skin Credits", "Skin Kredit")
        if new ~= old then
            adjusting = true
            object.Text = new
            adjusting = false
        end
    end

    rewrite()
    if textHooked[object] then return end
    textHooked[object] = true
    object:GetPropertyChangedSignal("Text"):Connect(rewrite)
end

local function compactProgression()
    local gui = playerGui:FindFirstChild("LostAndFoundProgressionHUD")
    local panel = gui and gui:FindFirstChild("ProgressionPanel")
    if not panel or not panel:IsA("Frame") then return false end

    local compact = compactMode()
    if compact then
        panel.Position = UDim2.new(0.5, 0, 0, 4)
        panel.Size = UDim2.new(0.64, 0, 0, 54)

        local constraint = panel:FindFirstChildOfClass("UISizeConstraint")
        if constraint then
            constraint.MinSize = Vector2.new(230, 54)
            constraint.MaxSize = Vector2.new(360, 54)
        end

        local title = panel:FindFirstChild("ShiftTitle")
        if title and title:IsA("TextLabel") then
            title.Position = UDim2.fromOffset(8, 3)
            title.Size = UDim2.new(0.64, -8, 0, 15)
            title.TextSize = 11
        end

        local xpText = panel:FindFirstChild("XPText")
        if xpText and xpText:IsA("TextLabel") then
            xpText.Position = UDim2.new(1, -8, 0, 3)
            xpText.Size = UDim2.new(0.36, -2, 0, 15)
            xpText.TextSize = 9
        end

        local bar = panel:FindFirstChild("ProgressBack")
        if bar and bar:IsA("Frame") then
            bar.Position = UDim2.fromOffset(8, 21)
            bar.Size = UDim2.new(1, -16, 0, 5)
        end

        local milestone = panel:FindFirstChild("Milestone")
        if milestone and milestone:IsA("TextLabel") then
            milestone.Position = UDim2.fromOffset(8, 28)
            milestone.Size = UDim2.new(1, -16, 0, 11)
            milestone.TextSize = 8
        end
    end

    return true
end

local function attachCareerBar()
    local progressionGui = playerGui:FindFirstChild("LostAndFoundProgressionHUD")
    local progressionPanel = progressionGui and progressionGui:FindFirstChild("ProgressionPanel")
    local careerGui = playerGui:FindFirstChild("LostAndFoundCareerUnlocks")
    local careerBar = careerGui and careerGui:FindFirstChild("CareerTierBar", true)
    if not progressionPanel or not careerBar or not careerBar:IsA("TextLabel") then return false end

    if careerGui and careerGui:IsA("ScreenGui") then
        -- Toast remains above normal HUD but below Station Shop modal.
        careerGui.DisplayOrder = 16
    end

    if compactMode() then
        if careerBar.Parent ~= progressionPanel then
            careerBar.Parent = progressionPanel
        end
        careerBar.AnchorPoint = Vector2.new(0, 0)
        careerBar.Position = UDim2.fromOffset(8, 40)
        careerBar.Size = UDim2.new(1, -16, 0, 10)
        careerBar.BackgroundTransparency = 1
        careerBar.TextSize = 8
        careerBar.TextXAlignment = Enum.TextXAlignment.Left
        careerBar.TextTruncate = Enum.TextTruncate.AtEnd

        local constraint = careerBar:FindFirstChildOfClass("UISizeConstraint")
        if constraint then
            constraint.MinSize = Vector2.new(0, 10)
            constraint.MaxSize = Vector2.new(1000, 10)
        end
        local stroke = careerBar:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Transparency = 1 end
    end

    localizeTextObject(careerBar)
    return true
end

local function ensureShopModal()
    local shop = playerGui:FindFirstChild("LostAndFoundStationShop")
    if not shop or not shop:IsA("ScreenGui") then return false end

    -- Respect Roblox top-bar/safe-area on phones.
    shop.IgnoreGuiInset = false
    shop.DisplayOrder = 18

    local panel = shop:FindFirstChild("ShopPanel")
    local openButton = shop:FindFirstChild("StationShopButton")
    if not panel or not panel:IsA("Frame") then return false end

    if compactMode() then
        panel.Size = UDim2.new(0.78, 0, 0.82, 0)
        panel.Position = UDim2.fromScale(0.5, 0.52)
        local constraint = panel:FindFirstChildOfClass("UISizeConstraint")
        if constraint then
            constraint.MinSize = Vector2.new(300, 260)
            constraint.MaxSize = Vector2.new(500, 380)
        end
    end

    panel.ZIndex = 2

    local shield = shop:FindFirstChild("ModalShield")
    if not shield then
        shield = Instance.new("TextButton")
        shield.Name = "ModalShield"
        shield.Size = UDim2.fromScale(1, 1)
        shield.Position = UDim2.fromScale(0, 0)
        shield.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
        shield.BackgroundTransparency = 0.28
        shield.BorderSizePixel = 0
        shield.Text = ""
        shield.AutoButtonColor = false
        shield.Active = true
        shield.Selectable = false
        shield.ZIndex = 1
        shield.Visible = panel.Visible
        shield.Parent = shop
        shield.Activated:Connect(function()
            panel.Visible = false
        end)
    end

    local function syncModalState()
        shield.Visible = panel.Visible
        if openButton and openButton:IsA("GuiObject") then
            openButton.Visible = not panel.Visible
        end
    end

    syncModalState()
    if not hooked[panel] then
        hooked[panel] = true
        panel:GetPropertyChangedSignal("Visible"):Connect(syncModalState)
    end

    for _, descendant in ipairs(panel:GetDescendants()) do
        localizeTextObject(descendant)
    end
    if not hooked[shop] then
        hooked[shop] = true
        shop.DescendantAdded:Connect(function(descendant)
            task.defer(function() localizeTextObject(descendant) end)
        end)
    end

    return true
end

local function reconcile()
    compactProgression()
    attachCareerBar()
    ensureShopModal()
end

-- Initial bounded reconciliation only; no permanent polling loop.
task.spawn(function()
    for _ = 1, 80 do
        reconcile()
        if playerGui:FindFirstChild("LostAndFoundProgressionHUD")
            and playerGui:FindFirstChild("LostAndFoundCareerUnlocks")
            and playerGui:FindFirstChild("LostAndFoundStationShop") then
            break
        end
        task.wait(0.10)
    end
end)

playerGui.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundProgressionHUD"
        or child.Name == "LostAndFoundCareerUnlocks"
        or child.Name == "LostAndFoundStationShop" then
        task.defer(reconcile)
    end
end)

player:GetAttributeChangedSignal("LostFoundCareerRevision"):Connect(function()
    task.defer(function()
        attachCareerBar()
        ensureShopModal()
    end)
end)

player:GetAttributeChangedSignal("LostFoundProgressionRevision"):Connect(function()
    task.defer(function()
        compactProgression()
        attachCareerBar()
    end)
end)

local camera = workspace.CurrentCamera
if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        task.defer(reconcile)
    end)
end
