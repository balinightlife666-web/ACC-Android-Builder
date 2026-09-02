-- LOST & FOUND: NIGHT SHIFT — M6-A compact Shift Progression HUD
-- Indonesia-first, centered, mobile-friendly. Reads server-authoritative player attributes only.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("LostAndFoundProgressionHUD")
if existing then existing:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundProgressionHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 14
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ProgressionPanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 8)
panel.Size = UDim2.new(0.72, 0, 0, 62)
panel.BackgroundColor3 = Color3.fromRGB(12, 16, 23)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(230, 62)
sizeConstraint.MaxSize = Vector2.new(340, 62)
sizeConstraint.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(74, 88, 108)
stroke.Transparency = 0.25
stroke.Thickness = 1
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "ShiftTitle"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(10, 6)
title.Size = UDim2.new(0.64, -10, 0, 18)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextColor3 = Color3.fromRGB(239, 243, 248)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "SHIFT 1 • PETUGAS BARU"
title.Parent = panel

local xpText = Instance.new("TextLabel")
xpText.Name = "XPText"
xpText.BackgroundTransparency = 1
xpText.AnchorPoint = Vector2.new(1, 0)
xpText.Position = UDim2.new(1, -10, 0, 6)
xpText.Size = UDim2.new(0.36, -4, 0, 18)
xpText.Font = Enum.Font.RobotoMono
xpText.TextSize = 10
xpText.TextColor3 = Color3.fromRGB(190, 202, 216)
xpText.TextXAlignment = Enum.TextXAlignment.Right
xpText.Text = "0 / 100 XP"
xpText.Parent = panel

local barBack = Instance.new("Frame")
barBack.Name = "ProgressBack"
barBack.Position = UDim2.fromOffset(10, 29)
barBack.Size = UDim2.new(1, -20, 0, 7)
barBack.BackgroundColor3 = Color3.fromRGB(35, 42, 53)
barBack.BorderSizePixel = 0
barBack.Parent = panel

local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(1, 0)
backCorner.Parent = barBack

local fill = Instance.new("Frame")
fill.Name = "ProgressFill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(151, 174, 208)
fill.BorderSizePixel = 0
fill.Parent = barBack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local milestone = Instance.new("TextLabel")
milestone.Name = "Milestone"
milestone.BackgroundTransparency = 1
milestone.Position = UDim2.fromOffset(10, 40)
milestone.Size = UDim2.new(1, -20, 0, 16)
milestone.Font = Enum.Font.GothamMedium
milestone.TextSize = 9
milestone.TextColor3 = Color3.fromRGB(159, 172, 190)
milestone.TextXAlignment = Enum.TextXAlignment.Left
milestone.Text = "Target berikut: RITME KERJA"
milestone.Parent = panel

local previousLevel = nil
local initialized = false
local flashToken = 0

local function flashLevelUp(level)
    flashToken += 1
    local token = flashToken
    milestone.TextColor3 = Color3.fromRGB(235, 210, 137)
    milestone.Text = "PROMOSI SHIFT • LEVEL " .. tostring(level)
    task.delay(2.2, function()
        if token ~= flashToken then return end
        local nextMilestone = tostring(player:GetAttribute("LostFoundShiftNextMilestone") or "PUNCAK TERCAPAI")
        milestone.TextColor3 = Color3.fromRGB(159, 172, 190)
        milestone.Text = "Target berikut: " .. nextMilestone
    end)
end

local function refresh()
    local level = tonumber(player:GetAttribute("LostFoundShiftLevel"))
    if not level then
        panel.Visible = false
        return
    end

    local shiftTitle = tostring(player:GetAttribute("LostFoundShiftTitle") or "PETUGAS BARU")
    local xp = math.max(0, math.floor(tonumber(player:GetAttribute("LostFoundShiftXP")) or 0))
    local floorXP = math.max(0, math.floor(tonumber(player:GetAttribute("LostFoundShiftFloorXP")) or 0))
    local nextXP = math.max(floorXP, math.floor(tonumber(player:GetAttribute("LostFoundShiftNextXP")) or floorXP))
    local progress = math.clamp(tonumber(player:GetAttribute("LostFoundShiftProgress")) or 0, 0, 1)
    local maxLevel = player:GetAttribute("LostFoundShiftMaxLevel") == true
    local nextMilestone = tostring(player:GetAttribute("LostFoundShiftNextMilestone") or "PUNCAK TERCAPAI")

    panel.Visible = true
    title.Text = "SHIFT " .. tostring(level) .. " • " .. shiftTitle
    xpText.Text = maxLevel and (tostring(xp) .. " XP • MAKS") or (tostring(xp) .. " / " .. tostring(nextXP) .. " XP")

    TweenService:Create(fill, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(progress, 1),
    }):Play()

    if not initialized then
        milestone.Text = maxLevel and "Puncak Night Shift tercapai" or ("Target berikut: " .. nextMilestone)
        previousLevel = level
        initialized = true
    elseif previousLevel and level > previousLevel then
        previousLevel = level
        flashLevelUp(level)
    else
        previousLevel = level
        milestone.Text = maxLevel and "Puncak Night Shift tercapai" or ("Target berikut: " .. nextMilestone)
    end
end

local watched = {
    "LostFoundShiftLevel",
    "LostFoundShiftTitle",
    "LostFoundShiftXP",
    "LostFoundShiftFloorXP",
    "LostFoundShiftNextXP",
    "LostFoundShiftProgress",
    "LostFoundShiftNextMilestone",
    "LostFoundShiftMaxLevel",
}

for _, attributeName in ipairs(watched) do
    player:GetAttributeChangedSignal(attributeName):Connect(refresh)
end

refresh()
