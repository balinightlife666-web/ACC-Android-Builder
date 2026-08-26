local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local caseUpdate = remotes:WaitForChild("CaseUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
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

-- Compact always-on HUD. Keep it clear of the Roblox top bar and movement controls.
local compact = Instance.new("Frame")
compact.Name = "CompactCaseHUD"
compact.Size = UDim2.fromOffset(300, 174)
compact.Position = UDim2.fromOffset(16, 108)
compact.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
compact.BackgroundTransparency = 0.06
compact.BorderSizePixel = 0
compact.Parent = gui
addCorner(compact, 12)
addStroke(compact)

local compactConstraint = Instance.new("UISizeConstraint")
compactConstraint.MinSize = Vector2.new(260, 164)
compactConstraint.MaxSize = Vector2.new(300, 174)
compactConstraint.Parent = compact

local compactTitle = makeLabel(compact, "Brand", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 10), Enum.Font.GothamBold, Color3.fromRGB(255, 184, 72), 14)
compactTitle.Text = "LOST & FOUND: NIGHT SHIFT"

local compactCase = makeLabel(compact, "Case", UDim2.new(1, -24, 0, 48), UDim2.fromOffset(12, 36), Enum.Font.GothamBold, Color3.fromRGB(240, 242, 246), 15)
compactCase.Text = "Waiting for first suitcase..."

local compactStatus = makeLabel(compact, "Status", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 86), Enum.Font.GothamMedium, Color3.fromRGB(111, 210, 255), 12)
compactStatus.Text = "M0 — FIRST SUITCASE"

local progress = makeLabel(compact, "Progress", UDim2.new(1, -118, 0, 34), UDim2.fromOffset(12, 118), Enum.Font.GothamBold, Color3.fromRGB(218, 224, 232), 12)
progress.Text = "SCAN ○   TAG ○   OPEN ○"

local caseFileButton = Instance.new("TextButton")
caseFileButton.Name = "CaseFileButton"
caseFileButton.Size = UDim2.fromOffset(96, 36)
caseFileButton.Position = UDim2.new(1, -108, 1, -48)
caseFileButton.BackgroundColor3 = Color3.fromRGB(218, 145, 48)
caseFileButton.BackgroundTransparency = 0.04
caseFileButton.TextColor3 = Color3.fromRGB(20, 22, 27)
caseFileButton.Font = Enum.Font.GothamBold
caseFileButton.TextSize = 13
caseFileButton.Text = "CASE FILE"
caseFileButton.AutoButtonColor = true
caseFileButton.Parent = compact
addCorner(caseFileButton, 8)

-- Full evidence popup. Open only when requested so gameplay stays visible.
local popup = Instance.new("Frame")
popup.Name = "CaseFilePopup"
popup.AnchorPoint = Vector2.new(0.5, 0.5)
popup.Size = UDim2.new(0.58, 0, 0.72, 0)
popup.Position = UDim2.new(0.56, 0, 0.55, 0)
popup.BackgroundColor3 = Color3.fromRGB(15, 19, 26)
popup.BackgroundTransparency = 0.02
popup.BorderSizePixel = 0
popup.Visible = false
popup.Parent = gui
addCorner(popup, 14)
addStroke(popup, Color3.fromRGB(83, 101, 124), 1.4, 0.18)

local popupConstraint = Instance.new("UISizeConstraint")
popupConstraint.MinSize = Vector2.new(360, 300)
popupConstraint.MaxSize = Vector2.new(540, 430)
popupConstraint.Parent = popup

local popupTitle = makeLabel(popup, "PopupTitle", UDim2.new(1, -82, 0, 48), UDim2.fromOffset(18, 16), Enum.Font.GothamBold, Color3.fromRGB(240, 242, 246), 18)
popupTitle.Text = "CASE FILE"

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(44, 38)
closeButton.Position = UDim2.new(1, -58, 0, 14)
closeButton.BackgroundColor3 = Color3.fromRGB(37, 44, 56)
closeButton.TextColor3 = Color3.fromRGB(240, 242, 246)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 20
closeButton.Text = "×"
closeButton.Parent = popup
addCorner(closeButton, 9)

local popupStatus = makeLabel(popup, "PopupStatus", UDim2.new(1, -36, 0, 30), UDim2.fromOffset(18, 68), Enum.Font.GothamMedium, Color3.fromRGB(111, 210, 255), 14)
popupStatus.Text = "Waiting for evidence..."

local evidenceScroll = Instance.new("ScrollingFrame")
evidenceScroll.Name = "EvidenceScroll"
evidenceScroll.Size = UDim2.new(1, -36, 1, -166)
evidenceScroll.Position = UDim2.fromOffset(18, 104)
evidenceScroll.BackgroundColor3 = Color3.fromRGB(22, 27, 36)
evidenceScroll.BackgroundTransparency = 0.15
evidenceScroll.BorderSizePixel = 0
evidenceScroll.ScrollBarThickness = 5
evidenceScroll.ScrollBarImageTransparency = 0.2
evidenceScroll.CanvasSize = UDim2.fromOffset(0, 0)
evidenceScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
evidenceScroll.Parent = popup
addCorner(evidenceScroll, 9)

local evidencePadding = Instance.new("UIPadding")
evidencePadding.PaddingTop = UDim.new(0, 12)
evidencePadding.PaddingBottom = UDim.new(0, 12)
evidencePadding.PaddingLeft = UDim.new(0, 14)
evidencePadding.PaddingRight = UDim.new(0, 14)
evidencePadding.Parent = evidenceScroll

local evidence = Instance.new("TextLabel")
evidence.Name = "Evidence"
evidence.Size = UDim2.new(1, -28, 0, 0)
evidence.AutomaticSize = Enum.AutomaticSize.Y
evidence.BackgroundTransparency = 1
evidence.TextXAlignment = Enum.TextXAlignment.Left
evidence.TextYAlignment = Enum.TextYAlignment.Top
evidence.TextWrapped = true
evidence.Font = Enum.Font.RobotoMono
evidence.TextColor3 = Color3.fromRGB(215, 220, 228)
evidence.TextSize = 14
evidence.Text = "SCAN: pending\nTAG: pending\nOPEN: pending"
evidence.Parent = evidenceScroll

local instruction = makeLabel(popup, "Instruction", UDim2.new(1, -36, 0, 48), UDim2.new(0, 18, 1, -54), Enum.Font.GothamBold, Color3.fromRGB(255, 202, 105), 13)
instruction.Text = "1/3  SCAN the suitcase."

-- Result stays as a small toast and never consumes the movement area.
local resultBanner = Instance.new("TextLabel")
resultBanner.Name = "ResultBanner"
resultBanner.AnchorPoint = Vector2.new(0.5, 1)
resultBanner.Size = UDim2.new(0.54, 0, 0, 58)
resultBanner.Position = UDim2.new(0.5, 0, 0.94, 0)
resultBanner.BackgroundColor3 = Color3.fromRGB(28, 35, 45)
resultBanner.BackgroundTransparency = 0.04
resultBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
resultBanner.TextSize = 15
resultBanner.TextWrapped = true
resultBanner.Font = Enum.Font.GothamBold
resultBanner.Text = ""
resultBanner.Visible = false
resultBanner.Parent = gui
addCorner(resultBanner, 10)

local resultConstraint = Instance.new("UISizeConstraint")
resultConstraint.MaxSize = Vector2.new(560, 58)
resultConstraint.MinSize = Vector2.new(300, 52)
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
    progress.Text = string.format("SCAN %s   TAG %s   OPEN %s", progressMark(inspections.scanned), progressMark(inspections.tagChecked), progressMark(inspections.opened))
    evidence.Text = buildEvidence(caseData, inspections)

    if kind ~= "RESULT" then
        updateInstruction(inspections)
    end

    if kind == "CASE_INCOMING" then
        compactStatus.Text = "INCOMING — conveyor moving"
        popupStatus.Text = compactStatus.Text
        resultBanner.Visible = false
        popup.Visible = false
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
        resultBanner.Visible = true
        resultBanner.Text = string.format("%s  •  %s\n+%d Credits / +%d XP", tostring(payload.grade), tostring(payload.decision), payload.reward and payload.reward.Credits or 0, payload.reward and payload.reward.XP or 0)
    elseif kind == "SYNC" then
        compactStatus.Text = payload.locked and "CASE TRANSITION" or "CASE ACTIVE"
        popupStatus.Text = compactStatus.Text
    end
end

caseFileButton.Activated:Connect(function()
    popup.Visible = not popup.Visible
    if popup.Visible and currentPayload then
        render(currentPayload, currentKind or "SYNC")
        popup.Visible = true
    end
end)

closeButton.Activated:Connect(function()
    popup.Visible = false
end)

caseUpdate.OnClientEvent:Connect(function(kind, payload)
    render(payload or {}, kind)
end)
