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

local panel = Instance.new("Frame")
panel.Name = "CasePanel"
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Size = UDim2.new(0.34, 0, 0.86, 0)
panel.Position = UDim2.new(0, 10, 0.54, 0)
panel.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(310, 410)
sizeConstraint.MinSize = Vector2.new(220, 275)
sizeConstraint.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(74, 91, 112)
stroke.Thickness = 1.25
stroke.Transparency = 0.3
stroke.Parent = panel
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 9)
padding.PaddingBottom = UDim.new(0, 9)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local function textLabel(name, height, font, color, size)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, 0, height)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    label.Font = font or Enum.Font.Gotham
    label.TextColor3 = color or Color3.fromRGB(235, 238, 242)
    label.TextSize = size or 14
    label.Parent = panel
    return label
end

local title = textLabel("Title", 22, Enum.Font.GothamBold, Color3.fromRGB(255, 184, 72), 14)
title.Text = "LOST & FOUND: NIGHT SHIFT"
local caseTitle = textLabel("CaseTitle", 38, Enum.Font.GothamBold, Color3.fromRGB(240, 242, 246), 15)
caseTitle.Text = "Waiting for first suitcase..."
local status = textLabel("Status", 28, Enum.Font.GothamMedium, Color3.fromRGB(111, 210, 255), 12)
status.Text = "M0 — FIRST SUITCASE"
local evidence = textLabel("Evidence", 126, Enum.Font.RobotoMono, Color3.fromRGB(215, 220, 228), 11)
evidence.Text = "SCAN: pending\nTAG: pending\nOPEN: pending"
local instruction = textLabel("Instruction", 42, Enum.Font.GothamBold, Color3.fromRGB(255, 202, 105), 11)
instruction.Text = "1/3  SCAN the suitcase."

local resultBanner = Instance.new("TextLabel")
resultBanner.Name = "ResultBanner"
resultBanner.AnchorPoint = Vector2.new(0.5, 1)
resultBanner.Size = UDim2.new(0.62, 0, 0, 52)
resultBanner.Position = UDim2.new(0.5, 0, 0.96, 0)
resultBanner.BackgroundColor3 = Color3.fromRGB(28, 35, 45)
resultBanner.BackgroundTransparency = 0.05
resultBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
resultBanner.TextSize = 14
resultBanner.TextWrapped = true
resultBanner.Font = Enum.Font.GothamBold
resultBanner.Text = ""
resultBanner.Visible = false
resultBanner.Parent = gui
local resultConstraint = Instance.new("UISizeConstraint")
resultConstraint.MaxSize = Vector2.new(520, 52)
resultConstraint.MinSize = Vector2.new(280, 48)
resultConstraint.Parent = resultBanner
local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 10)
resultCorner.Parent = resultBanner

local function inspectionMark(done) return done and "DONE" or "pending" end

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

local function render(payload, kind)
    local caseData = payload.case
    local inspections = payload.inspections or {}
    if not caseData then return end
    caseTitle.Text = caseData.id .. "  •  " .. caseData.title .. "\n" .. caseData.itemName
    local lines = {}
    table.insert(lines, "SCAN: " .. inspectionMark(inspections.scanned))
    if inspections.scanned then
        table.insert(lines, "  owner: " .. tostring(caseData.owner))
        table.insert(lines, "  flight: " .. tostring(caseData.flight))
        table.insert(lines, "  weight: " .. tostring(caseData.weight))
        table.insert(lines, "  status: " .. tostring(caseData.scanStatus))
    end
    table.insert(lines, "TAG: " .. inspectionMark(inspections.tagChecked))
    if inspections.tagChecked then
        table.insert(lines, "  item tag: " .. tostring(caseData.tagNumber))
        table.insert(lines, "  claimant: " .. tostring(caseData.claimantName))
        table.insert(lines, "  claim tag: " .. tostring(caseData.claimantTag))
    end
    table.insert(lines, "OPEN: " .. inspectionMark(inspections.opened))
    if inspections.opened then
        table.insert(lines, "  contents: " .. tostring(caseData.contents))
        table.insert(lines, "  note: " .. tostring(caseData.anomaly))
    end
    evidence.Text = table.concat(lines, "\n")

    if kind ~= "RESULT" then updateInstruction(inspections) end

    if kind == "CASE_INCOMING" then
        status.Text = "INCOMING — conveyor moving"
        resultBanner.Visible = false
    elseif kind == "CASE_READY" then
        status.Text = "CASE READY — begin inspection"
        resultBanner.Visible = false
    elseif kind == "INSPECTION" then
        status.Text = tostring(payload.message or "Evidence updated")
    elseif kind == "DECISION_BLOCKED" then
        status.Text = "DECISION LOCKED — finish inspection"
        instruction.Text = tostring(payload.message or "Complete all evidence steps first.")
    elseif kind == "RESULT" then
        status.Text = "CASE COMPLETE — " .. tostring(payload.resolution or "")
        resultBanner.Visible = true
        resultBanner.Text = string.format("%s  •  %s\n+%d Credits / +%d XP", tostring(payload.grade), tostring(payload.decision), payload.reward and payload.reward.Credits or 0, payload.reward and payload.reward.XP or 0)
        instruction.Text = tostring(payload.reason or "")
    elseif kind == "SYNC" then
        status.Text = payload.locked and "CASE TRANSITION" or "CASE ACTIVE"
    end
end

caseUpdate.OnClientEvent:Connect(function(kind, payload)
    render(payload or {}, kind)
end)
