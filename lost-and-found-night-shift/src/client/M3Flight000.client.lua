local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local incidentUpdate = remotes:WaitForChild("IncidentUpdate")
local caseUpdate = remotes:WaitForChild("CaseUpdate")
local collectionUpdate = remotes:WaitForChild("CollectionUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundM3HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
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
    return s
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

local archiveDefs = {
    {
        key = "A",
        bonusId = "flight_000_boarding_tag",
        code = "000-A",
        title = "FLIGHT 000",
        status = "CONNECTED / UNRESOLVED",
        detail = "Jonas Vale • passenger FOUND • flight NOT FOUND\ntag F0-00013 • action QUARANTINE",
    },
    {
        key = "B",
        bonusId = "ownerless_tag_00017284",
        code = "000-B",
        title = "OWNERLESS SUITCASE",
        status = "CONNECTED / UNRESOLVED",
        detail = "owner UNKNOWN • flight 000 • database origin NONE\ntag 000-17284 • action QUARANTINE",
    },
    {
        key = "C",
        bonusId = "milo_toy_train_2001",
        code = "000-C",
        title = "THE LOST CHILD",
        status = "CONNECTED / PROTECTIVE ESCALATION",
        detail = "Milo Hart • MISSING PERSON RECORD / 2001\ntag OLD-2001-14 • action SECURITY",
    },
}

local unlocked = { A = false, B = false, C = false }
local archiveCount = 0
local lastIncidentAt = 0
local toastToken = 0

local archiveButton = Instance.new("TextButton")
archiveButton.Name = "ArchiveButton"
archiveButton.AnchorPoint = Vector2.new(1, 0)
archiveButton.Size = UDim2.fromOffset(150, 34)
archiveButton.Position = UDim2.new(1, -18, 0, 102)
archiveButton.BackgroundColor3 = Color3.fromRGB(27, 31, 39)
archiveButton.BackgroundTransparency = 0.03
archiveButton.BorderSizePixel = 0
archiveButton.Text = "ARCHIVE  0/3"
archiveButton.TextColor3 = Color3.fromRGB(128, 139, 153)
archiveButton.Font = Enum.Font.GothamBold
archiveButton.TextSize = 12
archiveButton.Parent = gui
corner(archiveButton, 9)
local archiveStroke = stroke(archiveButton, 0.35, Color3.fromRGB(76, 86, 101), 1.1)

local popup = Instance.new("Frame")
popup.Name = "ArchivePopup"
popup.AnchorPoint = Vector2.new(0.5, 0.5)
popup.Size = UDim2.fromOffset(430, 330)
popup.Position = UDim2.new(0.53, 0, 0.52, 0)
popup.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
popup.BackgroundTransparency = 0.01
popup.BorderSizePixel = 0
popup.Visible = false
popup.Active = true
popup.Parent = gui
corner(popup, 12)
stroke(popup, 0.15, Color3.fromRGB(88, 221, 224), 1.2)

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(330, 285)
constraint.MaxSize = Vector2.new(430, 330)
constraint.Parent = popup

local popupTitle = label(popup, UDim2.new(1, -62, 0, 30), UDim2.fromOffset(14, 9), 15, Enum.Font.GothamBold, Color3.fromRGB(255, 192, 86))
popupTitle.Text = "MYSTERY ARCHIVE // SEASON 1"

local summary = label(popup, UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 40), 11, Enum.Font.GothamBold, Color3.fromRGB(88, 221, 224))
summary.Text = "CONNECTED CASE CHAIN  0/3"

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 30)
close.Position = UDim2.new(1, -44, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(37, 44, 56)
close.BorderSizePixel = 0
close.Text = "×"
close.TextColor3 = Color3.fromRGB(240, 242, 246)
close.Font = Enum.Font.GothamBold
close.TextSize = 17
close.Parent = popup
corner(close, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ArchiveEntries"
scroll.Size = UDim2.new(1, -28, 1, -104)
scroll.Position = UDim2.fromOffset(14, 68)
scroll.BackgroundColor3 = Color3.fromRGB(18, 23, 31)
scroll.BackgroundTransparency = 0.18
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = popup
corner(scroll, 8)

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = scroll

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local entryCards = {}
for index, def in ipairs(archiveDefs) do
    local card = Instance.new("Frame")
    card.Name = def.code
    card.Size = UDim2.new(1, -16, 0, 92)
    card.BackgroundColor3 = Color3.fromRGB(25, 30, 39)
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = scroll
    corner(card, 8)
    local cardStroke = stroke(card, 0.55, Color3.fromRGB(78, 89, 104), 1.0)

    local title = label(card, UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 7), 12, Enum.Font.GothamBold, Color3.fromRGB(146, 154, 166))
    local status = label(card, UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 29), 10, Enum.Font.GothamBold, Color3.fromRGB(109, 118, 132))
    local detail = label(card, UDim2.new(1, -20, 0, 38), UDim2.fromOffset(10, 48), 10, Enum.Font.RobotoMono, Color3.fromRGB(126, 134, 146))
    detail.TextYAlignment = Enum.TextYAlignment.Top

    entryCards[def.key] = {
        frame = card,
        stroke = cardStroke,
        title = title,
        status = status,
        detail = detail,
        def = def,
    }
end

local footer = label(popup, UDim2.new(1, -28, 0, 24), UDim2.new(0, 14, 1, -30), 9, Enum.Font.GothamMedium, Color3.fromRGB(145, 157, 174))
footer.Text = "CONFIRMED CONNECTION ONLY • FINAL EXPLANATION REMAINS UNKNOWN"
footer.TextXAlignment = Enum.TextXAlignment.Center

local linkToast = Instance.new("TextLabel")
linkToast.Name = "CaseLinkToast"
linkToast.AnchorPoint = Vector2.new(0.5, 0)
linkToast.Size = UDim2.fromOffset(330, 52)
linkToast.Position = UDim2.new(0.5, 0, 0, 74)
linkToast.BackgroundColor3 = Color3.fromRGB(16, 23, 30)
linkToast.BackgroundTransparency = 0.04
linkToast.BorderSizePixel = 0
linkToast.TextColor3 = Color3.fromRGB(255, 202, 105)
linkToast.Font = Enum.Font.GothamBold
linkToast.TextSize = 12
linkToast.TextWrapped = true
linkToast.Visible = false
linkToast.ZIndex = 60
linkToast.Parent = gui
corner(linkToast, 9)
stroke(linkToast, 0.18, Color3.fromRGB(88, 221, 224), 1.2)

local incidentOverlay = Instance.new("Frame")
incidentOverlay.Name = "IncidentOverlay"
incidentOverlay.Size = UDim2.fromScale(1, 1)
incidentOverlay.BackgroundColor3 = Color3.fromRGB(4, 8, 12)
incidentOverlay.BackgroundTransparency = 1
incidentOverlay.BorderSizePixel = 0
incidentOverlay.Active = false
incidentOverlay.Visible = false
incidentOverlay.ZIndex = 70
incidentOverlay.Parent = gui

local incidentCard = Instance.new("Frame")
incidentCard.AnchorPoint = Vector2.new(0.5, 0.5)
incidentCard.Size = UDim2.fromOffset(360, 100)
incidentCard.Position = UDim2.fromScale(0.5, 0.47)
incidentCard.BackgroundColor3 = Color3.fromRGB(18, 24, 31)
incidentCard.BackgroundTransparency = 0.08
incidentCard.BorderSizePixel = 0
incidentCard.ZIndex = 71
incidentCard.Parent = incidentOverlay
corner(incidentCard, 11)
stroke(incidentCard, 0.05, Color3.fromRGB(88, 221, 224), 1.4)

local incidentTitle = label(incidentCard, UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 13), 17, Enum.Font.GothamBlack, Color3.fromRGB(255, 192, 86))
incidentTitle.TextXAlignment = Enum.TextXAlignment.Center
incidentTitle.Text = "TERMINAL INCIDENT // FLIGHT 000"
incidentTitle.ZIndex = 72

local incidentSub = label(incidentCard, UDim2.new(1, -24, 0, 36), UDim2.fromOffset(12, 50), 11, Enum.Font.GothamBold, Color3.fromRGB(88, 221, 224))
incidentSub.TextXAlignment = Enum.TextXAlignment.Center
incidentSub.Text = "ARCHIVE LINK ESTABLISHED\nCASE REMAINS UNRESOLVED"
incidentSub.ZIndex = 72

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

local function refreshArchiveVisuals()
    archiveCount = 0
    for _, def in ipairs(archiveDefs) do
        local card = entryCards[def.key]
        if unlocked[def.key] then
            archiveCount += 1
            card.frame.BackgroundColor3 = Color3.fromRGB(21, 31, 38)
            card.stroke.Color = Color3.fromRGB(88, 221, 224)
            card.stroke.Transparency = 0.28
            card.title.TextColor3 = Color3.fromRGB(245, 198, 108)
            card.title.Text = def.code .. "  •  " .. def.title
            card.status.TextColor3 = Color3.fromRGB(88, 221, 224)
            card.status.Text = def.status
            card.detail.TextColor3 = Color3.fromRGB(211, 220, 230)
            card.detail.Text = def.detail
        else
            card.frame.BackgroundColor3 = Color3.fromRGB(25, 30, 39)
            card.stroke.Color = Color3.fromRGB(78, 89, 104)
            card.stroke.Transparency = 0.55
            card.title.TextColor3 = Color3.fromRGB(146, 154, 166)
            card.title.Text = def.code .. "  •  " .. def.title
            card.status.TextColor3 = Color3.fromRGB(109, 118, 132)
            card.status.Text = "LOCKED"
            card.detail.TextColor3 = Color3.fromRGB(126, 134, 146)
            card.detail.Text = "Resolve this connected case with a PERFECT decision to reveal archive evidence."
        end
    end

    archiveButton.Text = string.format("ARCHIVE  %d/3", archiveCount)
    summary.Text = string.format("CONNECTED CASE CHAIN  %d/3", archiveCount)

    if archiveCount > 0 then
        archiveButton.TextColor3 = Color3.fromRGB(110, 224, 226)
        archiveStroke.Color = Color3.fromRGB(88, 221, 224)
        archiveStroke.Transparency = 0.25
    else
        archiveButton.TextColor3 = Color3.fromRGB(128, 139, 153)
        archiveStroke.Color = Color3.fromRGB(76, 86, 101)
        archiveStroke.Transparency = 0.35
    end
end

local function showLinkToast(def)
    toastToken += 1
    local token = toastToken
    linkToast.Text = "CASE LINK CONFIRMED\n" .. def.code .. " • " .. def.title
    linkToast.Visible = true
    task.delay(2.8, function()
        if token == toastToken then linkToast.Visible = false end
    end)
end

local function applyCollectionSnapshot(kind, payload)
    local discovered = payload and payload.discovered or {}
    local previous = { A = unlocked.A, B = unlocked.B, C = unlocked.C }

    for _, def in ipairs(archiveDefs) do
        unlocked[def.key] = discovered[def.bonusId] == true
    end

    refreshArchiveVisuals()

    if kind == "BONUS_DISCOVERY" and payload and payload.item then
        for _, def in ipairs(archiveDefs) do
            if payload.item.id == def.bonusId and unlocked[def.key] and not previous[def.key] then
                if def.key ~= "A" then
                    showLinkToast(def)
                end
                break
            end
        end
    end
end

local function showIncident()
    local now = os.clock()
    if now - lastIncidentAt < 4.5 then return end
    lastIncidentAt = now

    incidentOverlay.Visible = true
    incidentOverlay.BackgroundTransparency = 1
    incidentCard.BackgroundTransparency = 1
    incidentTitle.TextTransparency = 1
    incidentSub.TextTransparency = 1

    TweenService:Create(incidentOverlay, TweenInfo.new(0.12), { BackgroundTransparency = 0.28 }):Play()
    TweenService:Create(incidentCard, TweenInfo.new(0.12), { BackgroundTransparency = 0.02 }):Play()
    TweenService:Create(incidentTitle, TweenInfo.new(0.12), { TextTransparency = 0 }):Play()
    TweenService:Create(incidentSub, TweenInfo.new(0.12), { TextTransparency = 0 }):Play()

    task.delay(3.8, function()
        local fade = TweenService:Create(incidentOverlay, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
        TweenService:Create(incidentCard, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(incidentTitle, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
        TweenService:Create(incidentSub, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
        fade:Play()
        fade.Completed:Wait()
        incidentOverlay.Visible = false
    end)
end

archiveButton.Activated:Connect(function()
    popup.Visible = true
    archiveButton.Visible = false
    linkToast.Visible = false
    setOtherHudVisible(false)
end)

close.Activated:Connect(function()
    popup.Visible = false
    archiveButton.Visible = true
    setOtherHudVisible(true)
end)

collectionUpdate.OnClientEvent:Connect(function(kind, payload)
    applyCollectionSnapshot(kind, payload or {})
end)

caseUpdate.OnClientEvent:Connect(function(kind, payload)
    payload = payload or {}
    local caseData = payload.case
    if kind == "RESULT" and payload.serverIncident and caseData and caseData.id == "LF-M0-007" then
        showIncident()
    end
end)

incidentUpdate.OnClientEvent:Connect(function(kind)
    if kind == "FLIGHT_000_INCIDENT" then
        showIncident()
    end
end)

refreshArchiveVisuals()
