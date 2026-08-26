local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local caseUpdate = remotes:WaitForChild("CaseUpdate")

local function restorePlayerControls()
    pcall(function()
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMinZoomDistance = 5
        player.CameraMaxZoomDistance = 18
    end)

    task.defer(function()
        local playerScripts = player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts", 10)
        if not playerScripts then return end
        local moduleScript = playerScripts:FindFirstChild("PlayerModule")
        if not moduleScript then return end
        local ok, playerModule = pcall(require, moduleScript)
        if not ok or not playerModule or not playerModule.GetControls then return end
        local controls = playerModule:GetControls()
        if controls and controls.Enable then controls:Enable() end
    end)
end

restorePlayerControls()
player.CharacterAdded:Connect(function()
    task.delay(0.5, restorePlayerControls)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function addCorner(target, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = target
end

local function addStroke(target, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(74, 91, 112)
    stroke.Thickness = thickness or 1.2
    stroke.Transparency = transparency or 0.3
    stroke.Parent = target
end

local function makeLabel(parent, name, size, position, font, color, textSize)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position or UDim2.new()
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    label.Font = font or Enum.Font.Gotham
    label.TextColor3 = color or Color3.fromRGB(235, 238, 242)
    label.TextSize = textSize or 14
    label.Parent = parent
    return label
end

-- Live money display, separate from the case panel.
local moneyBar = Instance.new("Frame")
moneyBar.Name = "MoneyBar"
moneyBar.AnchorPoint = Vector2.new(1, 0)
moneyBar.Size = UDim2.fromOffset(150, 38)
moneyBar.Position = UDim2.new(1, -18, 0, 18)
moneyBar.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
moneyBar.BackgroundTransparency = 0.05
moneyBar.BorderSizePixel = 0
moneyBar.Active = false
moneyBar.Parent = gui
addCorner(moneyBar, 10)
addStroke(moneyBar, Color3.fromRGB(90, 104, 122), 1.1, 0.35)

local moneyLabel = makeLabel(moneyBar, "Credits", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), Enum.Font.GothamBold, Color3.fromRGB(255, 202, 105), 14)
moneyLabel.TextYAlignment = Enum.TextYAlignment.Center
moneyLabel.Text = "CREDITS  0"

local function bindCredits()
    local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 15)
    if not leaderstats then return end
    local credits = leaderstats:FindFirstChild("Credits") or leaderstats:WaitForChild("Credits", 10)
    if not credits then return end

    local function refreshCredits()
        moneyLabel.Text = "CREDITS  " .. tostring(credits.Value)
    end

    refreshCredits()
    credits:GetPropertyChangedSignal("Value"):Connect(refreshCredits)
end

task.spawn(bindCredits)

-- Compact HUD: true upper-left, below Roblox top controls, clear of joystick.
local compact = Instance.new("Frame")
compact.Name = "CompactCaseHUD"
compact.Size = UDim2.fromOffset(276, 126)
compact.Position = UDim2.fromOffset(8, 112)
compact.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
compact.BackgroundTransparency = 0.06
compact.BorderSizePixel = 0
compact.Active = false
compact.Parent = gui
addCorner(compact, 11)
addStroke(compact)

local compactTitle = makeLabel(compact, "Brand", UDim2.new(1, -18, 0, 18), UDim2.fromOffset(9, 7), Enum.Font.GothamBold, Color3.fromRGB(255, 184, 72), 13)
compactTitle.Text = "LOST & FOUND: NIGHT SHIFT"

local compactCase = makeLabel(compact, "Case", UDim2.new(1, -18, 0, 38), UDim2.fromOffset(9, 29), Enum.Font.GothamBold, Color3.fromRGB(240, 242, 246), 14)
compactCase.Text = "Waiting for first suitcase..."

local compactStatus = makeLabel(compact, "Status", UDim2.new(1, -18, 0, 20), UDim2.fromOffset(9, 68), Enum.Font.GothamMedium, Color3.fromRGB(111, 210, 255), 11)
compactStatus.Text = "M0 — FIRST SUITCASE"

local progress = makeLabel(compact, "Progress", UDim2.new(1, -104, 0, 24), UDim2.fromOffset(9, 98), Enum.Font.GothamBold, Color3.fromRGB(218, 224, 232), 11)
progress.Text = "SCAN ○  TAG ○  OPEN ○"

local caseFileButton = Instance.new("TextButton")
caseFileButton.Name = "CaseFileButton"
caseFileButton.Size = UDim2.fromOffset(88, 32)
caseFileButton.Position = UDim2.new(1, -97, 1, -37)
caseFileButton.BackgroundColor3 = Color3.fromRGB(218, 145, 48)
caseFileButton.BackgroundTransparency = 0.04
caseFileButton.TextColor3 = Color3.fromRGB(20, 22, 27)
caseFileButton.Font = Enum.Font.GothamBold
caseFileButton.TextSize = 12
caseFileButton.Text = "CASE FILE"
caseFileButton.AutoButtonColor = true
caseFileButton.Modal = false
caseFileButton.Parent = compact
addCorner(caseFileButton, 8)

-- Smaller evidence popup; readable text is preserved.
local popup = Instance.new("Frame")
popup.Name = "CaseFilePopup"
popup.AnchorPoint = Vector2.new(0.5, 0.5)
popup.Size = UDim2.new(0.48, 0, 0.62, 0)
popup.Position = UDim2.new(0.53, 0, 0.54, 0)
popup.BackgroundColor3 = Color3.fromRGB(15, 19, 26)
popup.BackgroundTransparency = 0.02
popup.BorderSizePixel = 0
popup.Active = false
popup.Visible = false
popup.Parent = gui
addCorner(popup, 13)
addStroke(popup, Color3.fromRGB(83, 101, 124), 1.3, 0.18)

local popupConstraint = Instance.new("UISizeConstraint")
popupConstraint.MinSize = Vector2.new(320, 270)
popupConstraint.MaxSize = Vector2.new(430, 360)
popupConstraint.Parent = popup

local popupTitle = makeLabel(popup, "PopupTitle", UDim2.new(1, -68, 0, 42), UDim2.fromOffset(15, 13), Enum.Font.GothamBold, Color3.fromRGB(240, 242, 246), 16)
popupTitle.Text = "CASE FILE"

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(38, 34)
closeButton.Position = UDim2.new(1, -49, 0, 11)
closeButton.BackgroundColor3 = Color3.fromRGB(37, 44, 56)
closeButton.TextColor3 = Color3.fromRGB(240, 242, 246)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.Text = "×"
closeButton.Modal = false
closeButton.Parent = popup
addCorner(closeButton, 8)

local popupStatus = makeLabel(popup, "PopupStatus", UDim2.new(1, -30, 0, 25), UDim2.fromOffset(15, 58), Enum.Font.GothamMedium, Color3.fromRGB(111, 210, 255), 13)
popupStatus.Text = "Waiting for evidence..."

local evidenceScroll = Instance.new("ScrollingFrame")
evidenceScroll.Name = "EvidenceScroll"
evidenceScroll.Size = UDim2.new(1, -30, 1, -138)
evidenceScroll.Position = UDim2.fromOffset(15, 88)
evidenceScroll.BackgroundColor3 = Color3.fromRGB(22, 27, 36)
evidenceScroll.BackgroundTransparency = 0.15
evidenceScroll.BorderSizePixel = 0
evidenceScroll.ScrollBarThickness = 4
evidenceScroll.ScrollBarImageTransparency = 0.2
evidenceScroll.CanvasSize = UDim2.fromOffset(0, 0)
evidenceScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
evidenceScroll.Parent = popup
addCorner(evidenceScroll, 8)

local evidencePadding = Instance.new("UIPadding")
evidencePadding.PaddingTop = UDim.new(0, 10)
evidencePadding.PaddingBottom = UDim.new(0, 10)
evidencePadding.PaddingLeft = UDim.new(0, 12)
evidencePadding.PaddingRight = UDim.new(0, 12)
evidencePadding.Parent = evidenceScroll

local evidence = Instance.new("TextLabel")
evidence.Name = "Evidence"
evidence.Size = UDim2.new(1, -24, 0, 0)
evidence.AutomaticSize = Enum.AutomaticSize.Y
evidence.BackgroundTransparency = 1
evidence.TextXAlignment = Enum.TextXAlignment.Left
evidence.TextYAlignment = Enum.TextYAlignment.Top
evidence.TextWrapped = true
evidence.Font = Enum.Font.RobotoMono
evidence.TextColor3 = Color3.fromRGB(215, 220, 228)
evidence.TextSize = 13
evidence.Text = "SCAN: pending\nTAG: pending\nOPEN: pending"
evidence.Parent = evidenceScroll

local instruction = makeLabel(popup, "Instruction", UDim2.new(1, -30, 0, 38), UDim2.new(0, 15, 1, -43), Enum.Font.GothamBold, Color3.fromRGB(255, 202, 105), 12)
instruction.Text = "1/3  SCAN the suitcase."

local resultBanner = Instance.new("TextLabel")
resultBanner.Name = "ResultBanner"
resultBanner.AnchorPoint = Vector2.new(0.5, 1)
resultBanner.Size = UDim2.new(0.52, 0, 0, 56)
resultBanner.Position = UDim2.new(0.5, 0, 0.94, 0)
resultBanner.BackgroundColor3 = Color3.fromRGB(28, 35, 45)
resultBanner.BackgroundTransparency = 0.04
resultBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
resultBanner.TextSize = 14
resultBanner.TextWrapped = true
resultBanner.Font = Enum.Font.GothamBold
resultBanner.Text = ""
resultBanner.Visible = false
resultBanner.Parent = gui
addCorner(resultBanner, 10)

local resultConstraint = Instance.new("UISizeConstraint")
resultConstraint.MaxSize = Vector2.new(520, 56)
resultConstraint.MinSize = Vector2.new(280, 50)
resultConstraint.Parent = resultBanner

local currentPayload = nil
local currentKind = nil

local function inspectionMark(done)
    return done and "DONE" or "pending"
end

local function progressMark(done)
    return done and "✓" or "○"
end

local function updateInstruction(inspections)
    if not inspections.scanned then
        instruction.Text = "1/3  SCAN the suitcase."
    elseif not inspections.tagChecked then
        instruction.Text = "2/3  CHECK TAG and compare claimant data."
    elseif not inspections.opened then
        instruction.Text = "3/3  OPEN / INSPECT the item."
    else
        instruction.Text = "Evidence complete. Choose RETURN / STORE / QUARANTINE / SECURITY."
    end
end

local function buildEvidence(caseData, inspections)
    local lines = {}
    table.insert(lines, "SCAN: " .. inspectionMark(inspections.scanned))
    if inspections.scanned then
        table.insert(lines, "  owner: " .. tostring(caseData.owner))
        table.insert(lines, "  flight: " .. tostring(caseData.flight))
        table.insert(lines, "  weight: " .. tostring(caseData.weight))
        table.insert(lines, "  status: " .. tostring(caseData.scanStatus))
    end
    table.insert(lines, "")
    table.insert(lines, "TAG: " .. inspectionMark(inspections.tagChecked))
    if inspections.tagChecked then
        table.insert(lines, "  item tag: " .. tostring(caseData.tagNumber))
        table.insert(lines, "  claimant: " .. tostring(caseData.claimantName))
        table.insert(lines, "  claim tag: " .. tostring(caseData.claimantTag))
    end
    table.insert(lines, "")
    table.insert(lines, "OPEN: " .. inspectionMark(inspections.opened))
    if inspections.opened then
        table.insert(lines, "  contents: " .. tostring(caseData.contents))
        table.insert(lines, "  note: " .. tostring(caseData.anomaly))
    end
    return table.concat(lines, "\n")
end

local function render(payload, kind)
    local caseData = payload.case
    local inspections = payload.inspections or {}
    if not caseData then return end

    currentPayload = payload
    currentKind = kind

    compactCase.Text = caseData.id .. "  •  " .. caseData.title .. "\n" .. caseData.itemName
    popupTitle.Text = caseData.id .. "  •  " .. caseData.title .. "\n" .. caseData.itemName
    progress.Text = string.format("SCAN %s  TAG %s  OPEN %s", progressMark(inspections.scanned), progressMark(inspections.tagChecked), progressMark(inspections.opened))
    evidence.Text = buildEvidence(caseData, inspections)

    if kind ~= "RESULT" then updateInstruction(inspections) end

    if kind == "CASE_INCOMING" then
        compactStatus.Text = "INCOMING — conveyor moving"
        popupStatus.Text = compactStatus.Text
        resultBanner.Visible = false
        popup.Visible = false
        compact.Visible = true
    elseif kind == "CASE_READY" then
        compactStatus.Text = "CASE READY — inspect item"
        popupStatus.Text = compactStatus.Text
        resultBanner.Visible = false
    elseif kind == "INSPECTION" then
        compactStatus.Text = tostring(payload.message or "Evidence updated")
        popupStatus.Text = compactStatus.Text
    elseif kind == "DECISION_BLOCKED" then
        compactStatus.Text = "DECISION LOCKED — finish evidence"
        popupStatus.Text = compactStatus.Text
        instruction.Text = tostring(payload.message or "Complete all evidence steps first.")
    elseif kind == "RESULT" then
        compactStatus.Text = "CASE COMPLETE — " .. tostring(payload.resolution or "")
        popupStatus.Text = compactStatus.Text
        popup.Visible = false
        compact.Visible = true
        resultBanner.Visible = true
        resultBanner.Text = string.format("%s  •  %s\n+%d Credits / +%d XP", tostring(payload.grade), tostring(payload.decision), payload.reward and payload.reward.Credits or 0, payload.reward and payload.reward.XP or 0)
    elseif kind == "SYNC" then
        compactStatus.Text = payload.locked and "CASE TRANSITION" or "CASE ACTIVE"
        popupStatus.Text = compactStatus.Text
    end
end

caseFileButton.Activated:Connect(function()
    restorePlayerControls()
    local opening = not popup.Visible
    popup.Visible = opening
    compact.Visible = not opening
    if opening and currentPayload then
        render(currentPayload, currentKind or "SYNC")
        popup.Visible = true
        compact.Visible = false
    end
end)

closeButton.Activated:Connect(function()
    popup.Visible = false
    compact.Visible = true
    restorePlayerControls()
end)

caseUpdate.OnClientEvent:Connect(function(kind, payload)
    render(payload or {}, kind)
end)
