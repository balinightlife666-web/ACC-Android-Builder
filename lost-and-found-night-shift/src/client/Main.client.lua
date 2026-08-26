local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local caseUpdate = remotes:WaitForChild("CaseUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "CasePanel"
panel.Size = UDim2.fromOffset(390, 470)
panel.Position = UDim2.new(0, 18, 0.5, -235)
panel.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
panel.BackgroundTransparency = 0.07
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(74, 91, 112)
stroke.Thickness = 1.5
stroke.Transparency = 0.25
stroke.Parent = panel
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 14)
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
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
    label.TextSize = size or 16
    label.Parent = panel
    return label
end

local title = textLabel("Title", 34, Enum.Font.GothamBold, Color3.fromRGB(255, 184, 72), 20)
title.Text = "LOST & FOUND: NIGHT SHIFT"
local caseTitle = textLabel("CaseTitle", 48, Enum.Font.GothamBold, Color3.fromRGB(240, 242, 246), 19)
caseTitle.Text = "Waiting for first suitcase..."
local status = textLabel("Status", 44, Enum.Font.GothamMedium, Color3.fromRGB(111, 210, 255), 15)
status.Text = "M0 — FIRST SUITCASE"
local evidence = textLabel("Evidence", 218, Enum.Font.RobotoMono, Color3.fromRGB(215, 220, 228), 14)
evidence.Text = "SCAN: pending\nTAG: pending\nOPEN: pending"
local instruction = textLabel("Instruction", 72, Enum.Font.GothamBold, Color3.fromRGB(255, 202, 105), 15)
instruction.Text = "Use world prompts: SCAN → CHECK TAG → OPEN → choose a decision pad."

local resultBanner = Instance.new("TextLabel")
resultBanner.Name = "ResultBanner"
resultBanner.Size = UDim2.new(1, 0, 0, 48)
resultBanner.Position = UDim2.new(0, 0, 1, 10)
resultBanner.BackgroundColor3 = Color3.fromRGB(28, 35, 45)
resultBanner.BackgroundTransparency = 0.08
resultBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
resultBanner.TextSize = 17
resultBanner.TextWrapped = true
resultBanner.Font = Enum.Font.GothamBold
resultBanner.Text = ""
resultBanner.Visible = false
resultBanner.Parent = panel
local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 10)
resultCorner.Parent = resultBanner

local function inspectionMark(done) return done and "DONE" or "pending" end

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
    if kind == "CASE_INCOMING" then
        status.Text = "INCOMING — conveyor moving"
        resultBanner.Visible = false
    elseif kind == "CASE_READY" then
        status.Text = "CASE READY — gather evidence, then decide"
        resultBanner.Visible = false
    elseif kind == "INSPECTION" then
        status.Text = tostring(payload.message or "Evidence updated")
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
