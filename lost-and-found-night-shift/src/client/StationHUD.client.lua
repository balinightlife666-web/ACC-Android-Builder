local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local stationUpdate = remotes:WaitForChild("StationUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundStationHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local indicator = Instance.new("TextLabel")
indicator.Name = "StationIndicator"
indicator.Size = UDim2.fromOffset(128, 28)
indicator.Position = UDim2.fromOffset(8, 78)
indicator.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
indicator.BackgroundTransparency = 0.05
indicator.BorderSizePixel = 0
indicator.TextColor3 = Color3.fromRGB(255, 202, 105)
indicator.Font = Enum.Font.GothamBold
indicator.TextSize = 11
indicator.Text = "SHIFT  —"
indicator.Visible = true
indicator.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = indicator

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 104, 122)
stroke.Thickness = 1.1
stroke.Transparency = 0.35
stroke.Parent = indicator

local toast = Instance.new("TextLabel")
toast.Name = "StationToast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Size = UDim2.new(0.62, 0, 0, 54)
toast.Position = UDim2.new(0.5, 0, 0, 72)
toast.BackgroundColor3 = Color3.fromRGB(18, 23, 30)
toast.BackgroundTransparency = 0.03
toast.BorderSizePixel = 0
toast.TextColor3 = Color3.fromRGB(240, 242, 246)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 14
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui

local toastConstraint = Instance.new("UISizeConstraint")
toastConstraint.MinSize = Vector2.new(260, 50)
toastConstraint.MaxSize = Vector2.new(520, 58)
toastConstraint.Parent = toast

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toast

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(214, 151, 55)
toastStroke.Thickness = 1.2
toastStroke.Transparency = 0.2
toastStroke.Parent = toast

local toastToken = 0
local currentHighlight = nil

local function showToast(text, seconds)
    toastToken += 1
    local token = toastToken
    toast.Text = tostring(text or "")
    toast.Visible = true
    task.delay(seconds or 3.2, function()
        if toastToken == token then toast.Visible = false end
    end)
end

local function clearHighlight()
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
end

local function guideStation(stationId)
    clearHighlight()
    task.spawn(function()
        local world = workspace:WaitForChild("LostAndFoundM4D", 20)
        if not world then return end
        local station = world:FindFirstChild("Station_" .. tostring(stationId))
        if not station then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "LocalStationGuide"
        highlight.Adornee = station
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.88
        highlight.OutlineTransparency = 0.05
        highlight.Parent = station
        currentHighlight = highlight

        task.delay(8, function()
            if currentHighlight == highlight then clearHighlight() end
        end)
    end)
end

local function applyStation(stationId)
    if stationId and tostring(stationId) ~= "" then
        indicator.Text = "SHIFT  STATION " .. tostring(stationId)
    else
        indicator.Text = "SHIFT  —"
    end
end

player:GetAttributeChangedSignal("LostFoundStationId"):Connect(function()
    applyStation(player:GetAttribute("LostFoundStationId"))
end)
applyStation(player:GetAttribute("LostFoundStationId"))

stationUpdate.OnClientEvent:Connect(function(kind, payload)
    payload = payload or {}
    if kind == "ASSIGNED" then
        applyStation(payload.stationId)
        showToast(payload.message or ("SHIFT ASSIGNED — STATION " .. tostring(payload.stationId)), 4.5)
        guideStation(payload.stationId)
    elseif kind == "DENIED" then
        showToast(payload.message or "That is another player's station.", 2.4)
    elseif kind == "NO_STATION" then
        applyStation(nil)
        showToast(payload.message or "All shift stations are occupied.", 5)
    end
end)
