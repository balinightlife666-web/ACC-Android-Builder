-- LOST & FOUND: NIGHT SHIFT — M6-B Career Unlock UX
-- Adds persistent career-tier readability, promotion reward feedback, and Station Shop level gates.
-- Server remains the authority for acquisition.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CareerUnlockConfig = require(shared:WaitForChild("CareerUnlockConfig"))

local function isIndonesian()
    if player:GetAttribute("LostFoundResolvedLocale") == "id" then return true end
    local ok, locale = pcall(function() return LocalizationService.RobloxLocaleId end)
    locale = ok and string.lower(tostring(locale or "")) or ""
    return string.sub(locale, 1, 2) == "id"
end

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundCareerUnlocks"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 19
gui.Parent = playerGui

local careerBar = Instance.new("TextLabel")
careerBar.Name = "CareerTierBar"
careerBar.AnchorPoint = Vector2.new(0.5, 0)
careerBar.Position = UDim2.new(0.5, 0, 0, 72)
careerBar.Size = UDim2.new(0.78, 0, 0, 22)
careerBar.BackgroundColor3 = Color3.fromRGB(17, 22, 30)
careerBar.BackgroundTransparency = 0.10
careerBar.BorderSizePixel = 0
careerBar.TextColor3 = Color3.fromRGB(184, 195, 209)
careerBar.Font = Enum.Font.GothamMedium
careerBar.TextSize = 9
careerBar.TextTruncate = Enum.TextTruncate.AtEnd
careerBar.Text = "KARIER • ORIENTASI"
careerBar.Parent = gui

local barSize = Instance.new("UISizeConstraint")
barSize.MinSize = Vector2.new(230, 22)
barSize.MaxSize = Vector2.new(360, 22)
barSize.Parent = careerBar

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 7)
barCorner.Parent = careerBar

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromRGB(75, 90, 111)
barStroke.Transparency = 0.42
barStroke.Thickness = 1
barStroke.Parent = careerBar

local toast = Instance.new("TextLabel")
toast.Name = "CareerUnlockToast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 98)
toast.Size = UDim2.new(0.78, 0, 0, 34)
toast.BackgroundColor3 = Color3.fromRGB(18, 23, 31)
toast.BackgroundTransparency = 0.05
toast.BorderSizePixel = 0
toast.TextColor3 = Color3.fromRGB(228, 234, 242)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 10
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui

local size = Instance.new("UISizeConstraint")
size.MinSize = Vector2.new(230, 34)
size.MaxSize = Vector2.new(360, 34)
size.Parent = toast

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toast

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(88, 103, 124)
stroke.Transparency = 0.25
stroke.Thickness = 1
stroke.Parent = toast

local previousLevel = nil
local toastToken = 0

local function showReward(level)
    local snapshot = CareerUnlockConfig.GetForLevel(level)
    toastToken += 1
    local token = toastToken
    toast.Text = (isIndonesian() and "TERBUKA SHIFT " or "SHIFT UNLOCK ") .. tostring(level) .. " • " .. snapshot.rewardLabel
    toast.Visible = true
    task.delay(3.2, function()
        if token == toastToken then toast.Visible = false end
    end)
end

local function refreshCareer()
    local level = math.max(1, math.floor(tonumber(player:GetAttribute("LostFoundShiftLevel")) or 1))
    local snapshot = CareerUnlockConfig.GetForLevel(level)
    if snapshot.maxLevel then
        careerBar.Text = "KARIER • " .. snapshot.tier .. " • MAKS"
    else
        careerBar.Text = "KARIER • " .. snapshot.tier .. "  |  NEXT SHIFT " .. tostring(snapshot.nextRewardLevel) .. " • " .. tostring(snapshot.nextRewardLabel)
    end
    if previousLevel and level > previousLevel then
        showReward(level)
    end
    previousLevel = level
end

local function isOwnedOrEquippedAction(button)
    local text = string.upper(tostring(button.Text or ""))
    return text == "EQUIPPED" or text == "DIPAKAI" or text == "EQUIP" or text == "PAKAI"
end

local function applyRowGate(row)
    if not row or not row:IsA("Frame") then return end
    local required = CareerUnlockConfig.RequiredLevelForSkin(row.Name)
    if required <= 1 then return end

    local action = row:FindFirstChildWhichIsA("TextButton")
    if not action or isOwnedOrEquippedAction(action) then return end

    local level = math.max(1, math.floor(tonumber(player:GetAttribute("LostFoundShiftLevel")) or 1))
    if level < required then
        action.Text = "SHIFT " .. tostring(required)
        action.BackgroundColor3 = Color3.fromRGB(52, 59, 69)
        action.TextColor3 = Color3.fromRGB(170, 180, 193)
        action.AutoButtonColor = false
        action.Active = false
    elseif string.sub(string.upper(tostring(action.Text or "")), 1, 5) == "SHIFT" then
        action.Text = isIndonesian() and "BELI" or "BUY"
        action.BackgroundColor3 = Color3.fromRGB(184, 125, 47)
        action.TextColor3 = Color3.fromRGB(25, 25, 27)
        action.AutoButtonColor = true
        action.Active = true
    end
end

local function refreshShopRows()
    local shop = playerGui:FindFirstChild("LostAndFoundStationShop")
    local panel = shop and shop:FindFirstChild("ShopPanel")
    local list = panel and panel:FindFirstChild("SkinList")
    if not list then return end
    for _, row in ipairs(list:GetChildren()) do
        applyRowGate(row)
    end
end

local hookedLists = setmetatable({}, { __mode = "k" })
local function hookShop()
    local shop = playerGui:FindFirstChild("LostAndFoundStationShop")
    local panel = shop and shop:FindFirstChild("ShopPanel")
    local list = panel and panel:FindFirstChild("SkinList")
    if not list or hookedLists[list] then return end
    hookedLists[list] = true
    list.ChildAdded:Connect(function(child)
        task.defer(function() applyRowGate(child) end)
    end)
    refreshShopRows()
end

player:GetAttributeChangedSignal("LostFoundCareerRevision"):Connect(function()
    refreshCareer()
    refreshShopRows()
end)
player:GetAttributeChangedSignal("LostFoundShiftLevel"):Connect(function()
    refreshCareer()
    refreshShopRows()
end)
playerGui.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundStationShop" then task.defer(hookShop) end
end)

task.spawn(function()
    for _ = 1, 80 do
        hookShop()
        if playerGui:FindFirstChild("LostAndFoundStationShop") then break end
        task.wait(0.25)
    end
end)

refreshCareer()
