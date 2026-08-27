local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local incidentUpdate = remotes:WaitForChild("IncidentUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundM3HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 12
gui.Parent = playerGui

local function corner(target, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 9)
    c.Parent = target
end

local function stroke(target, transparency, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(90, 105, 126)
    s.Transparency = transparency or 0.35
    s.Thickness = thickness or 1.1
    s.Parent = target
end

local function label(parent, size, position, textSize, font, color)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = position or UDim2.new()
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.fromRGB(232, 236, 242)
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = true
    l.Parent = parent
    return l
end

local archiveButton = Instance.new("TextButton")
archiveButton.Name = "ArchiveButton"
archiveButton.AnchorPoint = Vector2.new(1, 0)
archiveButton.Size = UDim2.fromOffset(150, 34)
archiveButton.Position = UDim2.new(1, -18, 0, 102)
archiveButton.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
archiveButton.BackgroundTransparency = 0.03
archiveButton.BorderSizePixel = 0
archiveButton.Text = "ARCHIVE  000-A"
archiveButton.TextColor3 = Color3.fromRGB(110, 224, 226)
archiveButton.Font = Enum.Font.GothamBold
archiveButton.TextSize = 12
archiveButton.Visible = false
archiveButton.Modal = false
archiveButton.Parent = gui
corner(archiveButton, 9)
stroke(archiveButton, 0.25, Color3.fromRGB(88, 221, 224), 1.2)

local popup = Instance.new("Frame")
popup.Name = "ArchivePopup"
popup.AnchorPoint = Vector2.new(0.5, 0)
popup.Size = UDim2.fromOffset(390, 244)
popup.Position = UDim2.new(0.54, 0, 0, 88)
popup.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
popup.BackgroundTransparency = 0.01
popup.BorderSizePixel = 0
popup.Visible = false
popup.Active = false
popup.Parent = gui
corner(popup, 12)
stroke(popup, 0.15, Color3.fromRGB(88, 221, 224), 1.2)

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(350, 230)
constraint.MaxSize = Vector2.new(410, 260)
constraint.Parent = popup

local popupTitle = label(popup, UDim2.new(1, -58, 0, 32), UDim2.fromOffset(14, 8), 15, Enum.Font.GothamBold, Color3.fromRGB(255, 192, 86))
popupTitle.Text = "INCIDENT 000-A — FLIGHT 000"

local status = label(popup, UDim2.new(1, -28, 0, 20), UDim2.fromOffset(14, 42), 11, Enum.Font.GothamBold, Color3.fromRGB(88, 221, 224))
status.Text = "CONNECTED / UNRESOLVED"

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 30)
close.Position = UDim2.new(1, -42, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(37, 44, 56)
close.BorderSizePixel = 0
close.Text = "×"
close.TextColor3 = Color3.fromRGB(240, 242, 246)
close.Font = Enum.Font.GothamBold
close.TextSize = 17
close.Modal = false
close.Parent = popup
corner(close, 8)

local evidenceBox = Instance.new("Frame")
evidenceBox.Size = UDim2.new(1, -28, 0, 132)
evidenceBox.Position = UDim2.fromOffset(14, 70)
evidenceBox.BackgroundColor3 = Color3.fromRGB(20, 25, 33)
evidenceBox.BackgroundTransparency = 0.04
evidenceBox.BorderSizePixel = 0
evidenceBox.Parent = popup
corner(evidenceBox, 8)

local evidence = label(evidenceBox, UDim2.new(1, -20, 1, -16), UDim2.fromOffset(10, 8), 11, Enum.Font.RobotoMono, Color3.fromRGB(216, 223, 231))
evidence.TextYAlignment = Enum.TextYAlignment.Top
evidence.Text = ""

local footer = label(popup, UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 208), 10, Enum.Font.GothamMedium, Color3.fromRGB(145, 157, 174))
footer.Text = "Operational archive only. Final explanation remains unknown."

local incidentOverlay = Instance.new("Frame")
incidentOverlay.Name = "IncidentOverlay"
incidentOverlay.Size = UDim2.fromScale(1, 1)
incidentOverlay.BackgroundColor3 = Color3.fromRGB(4, 8, 12)
incidentOverlay.BackgroundTransparency = 1
incidentOverlay.BorderSizePixel = 0
incidentOverlay.Active = false
incidentOverlay.Visible = false
incidentOverlay.Parent = gui

local incidentCard = Instance.new("Frame")
incidentCard.AnchorPoint = Vector2.new(0.5, 0.5)
incidentCard.Size = UDim2.fromOffset(360, 96)
incidentCard.Position = UDim2.fromScale(0.5, 0.47)
incidentCard.BackgroundColor3 = Color3.fromRGB(18, 24, 31)
incidentCard.BackgroundTransparency = 0.08
incidentCard.BorderSizePixel = 0
incidentCard.Parent = incidentOverlay
corner(incidentCard, 11)
stroke(incidentCard, 0.05, Color3.fromRGB(88, 221, 224), 1.4)

local incidentTitle = label(incidentCard, UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 13), 17, Enum.Font.GothamBlack, Color3.fromRGB(255, 192, 86))
incidentTitle.TextXAlignment = Enum.TextXAlignment.Center
incidentTitle.Text = "TERMINAL INCIDENT // FLIGHT 000"

local incidentSub = label(incidentCard, UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 51), 11, Enum.Font.GothamBold, Color3.fromRGB(88, 221, 224))
incidentSub.TextXAlignment = Enum.TextXAlignment.Center
incidentSub.Text = "ARCHIVE LINK ESTABLISHED — CASE REMAINS UNRESOLVED"

local currentArchive = nil
local incidentToken = 0

local function setOtherHudVisible(visible)
    local mainHud = playerGui:FindFirstChild("LostAndFoundHUD")
    if mainHud then
        local compact = mainHud:FindFirstChild("CompactCaseHUD")
        local casePopup = mainHud:FindFirstChild("CaseFilePopup")
        local moneyBar = mainHud:FindFirstChild("MoneyBar")
        if compact then compact.Visible = visible end
        if moneyBar then moneyBar.Visible = visible end
        if not visible and casePopup then casePopup.Visible = false end
    end

    local collectionHud = playerGui:FindFirstChild("LostAndFoundCollectionHUD")
    if collectionHud then
        local collectionPopup = collectionHud:FindFirstChild("CollectionPopup")
        local indexButton = collectionHud:FindFirstChild("IndexButton")
        if collectionPopup then collectionPopup.Visible = false end
        if indexButton then indexButton.Visible = visible end
    end
end

local function renderArchive(payload)
    currentArchive = payload
    archiveButton.Visible = true
    popupTitle.Text = tostring(payload.title or "INCIDENT 000-A — FLIGHT 000")
    status.Text = tostring(payload.status or "CONNECTED / UNRESOLVED")
    evidence.Text = table.concat({
        "PASSENGER RECORD: " .. tostring(payload.passengerRecord or "FOUND") .. " — " .. tostring(payload.passenger or "Jonas Vale"),
        "FLIGHT RECORD: " .. tostring(payload.flightRecord or "NOT FOUND"),
        "TAG: " .. tostring(payload.tag or "F0-00013"),
        "ACTION: " .. tostring(payload.operationalAction or "QUARANTINE"),
        "",
        "NOTE: " .. tostring(payload.note or "Transport origin remains impossible under current records."),
        "FINAL EXPLANATION: " .. tostring(payload.finalExplanation or "CLASSIFIED / UNKNOWN"),
    }, "\n")
end

local function showIncident(payload)
    renderArchive(payload)
    incidentToken += 1
    local token = incidentToken

    incidentOverlay.Visible = true
    incidentOverlay.BackgroundTransparency = 1
    incidentCard.BackgroundTransparency = 1
    incidentTitle.TextTransparency = 1
    incidentSub.TextTransparency = 1

    TweenService:Create(incidentOverlay, TweenInfo.new(0.18), {BackgroundTransparency = 0.42}):Play()
    TweenService:Create(incidentCard, TweenInfo.new(0.18), {BackgroundTransparency = 0.08}):Play()
    TweenService:Create(incidentTitle, TweenInfo.new(0.18), {TextTransparency = 0}):Play()
    TweenService:Create(incidentSub, TweenInfo.new(0.18), {TextTransparency = 0}):Play()

    task.delay(2.6, function()
        if token ~= incidentToken then return end
        local fade = TweenService:Create(incidentOverlay, TweenInfo.new(0.35), {BackgroundTransparency = 1})
        TweenService:Create(incidentCard, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
        TweenService:Create(incidentTitle, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
        TweenService:Create(incidentSub, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
        fade:Play()
        fade.Completed:Wait()
        if token == incidentToken then incidentOverlay.Visible = false end
    end)
end

archiveButton.Activated:Connect(function()
    if not currentArchive then return end
    popup.Visible = true
    archiveButton.Visible = false
    setOtherHudVisible(false)
end)

close.Activated:Connect(function()
    popup.Visible = false
    archiveButton.Visible = currentArchive ~= nil
    setOtherHudVisible(true)
end)

incidentUpdate.OnClientEvent:Connect(function(kind, payload)
    payload = payload or {}
    if kind == "FLIGHT_000_INCIDENT" then
        showIncident(payload)
    elseif kind == "ARCHIVE_SYNC" then
        renderArchive(payload)
    end
end)
