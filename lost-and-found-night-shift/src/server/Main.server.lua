local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local Config = require(shared:WaitForChild("Config"))
local CaseRegistry = require(shared:WaitForChild("CaseRegistry"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local remotes = ReplicatedStorage:FindFirstChild("LostAndFoundRemotes") or Instance.new("Folder")
remotes.Name = "LostAndFoundRemotes"
remotes.Parent = ReplicatedStorage
local caseUpdate = remotes:FindFirstChild("CaseUpdate") or Instance.new("RemoteEvent")
caseUpdate.Name = "CaseUpdate"
caseUpdate.Parent = remotes

local refs = WorldBuilder.Build()
local activeIndex = 0
local activeCase = nil
local activeSuitcase = nil
local activeClaimant = nil
local locked = false
local inspections = { scanned = false, tagChecked = false, opened = false }

local function inspectionsComplete()
    return inspections.scanned and inspections.tagChecked and inspections.opened
end

local function setDecisionPrompts(enabled)
    for _, decisionPrompt in pairs(refs.DecisionPrompts) do
        decisionPrompt.Enabled = enabled
    end
end

local function refreshPromptState()
    if locked or not activeCase then
        refs.ScannerPrompt.Enabled = false
        refs.TagPrompt.Enabled = false
        refs.OpenPrompt.Enabled = false
        setDecisionPrompts(false)
        return
    end

    refs.ScannerPrompt.Enabled = not inspections.scanned
    refs.TagPrompt.Enabled = inspections.scanned and not inspections.tagChecked
    refs.OpenPrompt.Enabled = inspections.scanned and inspections.tagChecked and not inspections.opened
    setDecisionPrompts(inspectionsComplete())
end

local function ensureStats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then leaderstats = Instance.new("Folder"); leaderstats.Name = "leaderstats"; leaderstats.Parent = player end
    local credits = leaderstats:FindFirstChild("Credits")
    if not credits then credits = Instance.new("IntValue"); credits.Name = "Credits"; credits.Value = 0; credits.Parent = leaderstats end
    local xp = leaderstats:FindFirstChild("XP")
    if not xp then xp = Instance.new("IntValue"); xp.Name = "XP"; xp.Value = 0; xp.Parent = leaderstats end
end

local function normalizeCharacter(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = false
        end
    end

    if root then
        root.Anchored = false
    end

    if humanoid then
        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid.AutoRotate = true
        if humanoid.WalkSpeed <= 0 then humanoid.WalkSpeed = 16 end
        if humanoid.UseJumpPower then
            if humanoid.JumpPower <= 0 then humanoid.JumpPower = 50 end
        elseif humanoid.JumpHeight <= 0 then
            humanoid.JumpHeight = 7.2
        end
    end
end

local function setupPlayer(player)
    ensureStats(player)
    player.CharacterAdded:Connect(function(character)
        task.defer(normalizeCharacter, character)
    end)
    if player.Character then
        task.defer(normalizeCharacter, player.Character)
    end
end

local function publicCase(caseData)
    return { id = caseData.id, title = caseData.title, caseType = caseData.caseType, itemName = caseData.itemName, owner = caseData.owner, claimantName = caseData.claimantName or "NO CLAIMANT", claimantKind = caseData.claimantKind, tagNumber = caseData.tagNumber, claimantTag = caseData.claimantTag, flight = caseData.flight, weight = caseData.weight, contents = caseData.contents, scanStatus = caseData.scanStatus, anomaly = caseData.anomaly, resolution = caseData.resolution }
end

local function broadcast(kind, extra)
    local payload = extra or {}
    payload.case = activeCase and publicCase(activeCase) or nil
    payload.inspections = { scanned = inspections.scanned, tagChecked = inspections.tagChecked, opened = inspections.opened }
    payload.locked = locked
    payload.milestone = Config.Milestone
    caseUpdate:FireAllClients(kind, payload)
end

Players.PlayerAdded:Connect(function(player)
    setupPlayer(player)
    task.delay(1.5, function()
        if activeCase then caseUpdate:FireClient(player, "SYNC", { case = publicCase(activeCase), inspections = inspections, locked = locked, milestone = Config.Milestone }) end
    end)
end)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end

local function cleanActive()
    if activeSuitcase then activeSuitcase:Destroy(); activeSuitcase = nil end
    if activeClaimant then activeClaimant:Destroy(); activeClaimant = nil end
end

local function startNextCase()
    locked = true
    refreshPromptState()
    cleanActive()
    activeIndex += 1
    if activeIndex > CaseRegistry.Count() then activeIndex = 1 end
    activeCase = CaseRegistry.Get(activeIndex)
    inspections.scanned = false
    inspections.tagChecked = false
    inspections.opened = false
    refreshPromptState()
    activeSuitcase = WorldBuilder.CreateSuitcase(refs.World, activeCase, refs.ConveyorStart.CFrame)
    broadcast("CASE_INCOMING", { message = "Incoming property on conveyor..." })
    if activeSuitcase and activeSuitcase.PrimaryPart then
        local tween = TweenService:Create(activeSuitcase.PrimaryPart, TweenInfo.new(Config.ConveyorTravelTime, Enum.EasingStyle.Linear), { CFrame = refs.InspectionStop.CFrame })
        tween:Play()
        tween.Completed:Wait()
    end
    if activeSuitcase and activeSuitcase.Parent then activeClaimant = WorldBuilder.CreateClaimant(refs.World, refs.ClaimantMarker, activeCase) end
    locked = false
    refreshPromptState()
    broadcast("CASE_READY", { message = "Scan the item to begin inspection." })
end

local function grant(player, grade)
    ensureStats(player)
    local reward = Config.Rewards[grade] or Config.Rewards.WRONG
    local leaderstats = player:FindFirstChild("leaderstats")
    local credits = leaderstats and leaderstats:FindFirstChild("Credits")
    local xp = leaderstats and leaderstats:FindFirstChild("XP")
    if credits then credits.Value += reward.Credits end
    if xp then xp.Value += reward.XP end
    return reward, credits and credits.Value or 0, xp and xp.Value or 0
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do if item == value then return true end end
    return false
end

local function gradeDecision(decision)
    if decision == activeCase.correctDecision then return "PERFECT" end
    if contains(activeCase.questionableDecisions, decision) then return "QUESTIONABLE" end
    if activeCase.risk == "high" and decision == "RETURN" then return "CATASTROPHIC" end
    return "WRONG"
end

refs.ScannerPrompt.Triggered:Connect(function(player)
    if locked or not activeCase or inspections.scanned then return end
    inspections.scanned = true
    refreshPromptState()
    broadcast("INSPECTION", { step = "SCAN", by = player.DisplayName, message = "Scanner record loaded." })
end)
refs.TagPrompt.Triggered:Connect(function(player)
    if locked or not activeCase or not inspections.scanned or inspections.tagChecked then return end
    inspections.tagChecked = true
    refreshPromptState()
    broadcast("INSPECTION", { step = "TAG", by = player.DisplayName, message = "Claim tag checked." })
end)
refs.OpenPrompt.Triggered:Connect(function(player)
    if locked or not activeCase or not inspections.scanned or not inspections.tagChecked or inspections.opened then return end
    inspections.opened = true
    refreshPromptState()
    broadcast("INSPECTION", { step = "OPEN", by = player.DisplayName, message = "Physical inspection completed. Choose a decision." })
end)

for decision, decisionPrompt in pairs(refs.DecisionPrompts) do
    decisionPrompt.Triggered:Connect(function(player)
        if locked or not activeCase then return end
        if not inspectionsComplete() then
            refreshPromptState()
            broadcast("DECISION_BLOCKED", { message = "Complete SCAN, CHECK TAG, and OPEN before deciding." })
            return
        end
        locked = true
        refreshPromptState()
        local grade = gradeDecision(decision)
        local reward, totalCredits, totalXP = grant(player, grade)
        broadcast("RESULT", { decision = decision, grade = grade, correctDecision = activeCase.correctDecision, reason = activeCase.reason, resolution = activeCase.resolution, reward = reward, totalCredits = totalCredits, totalXP = totalXP, by = player.DisplayName })
        task.delay(Config.CaseAdvanceDelay, function() startNextCase() end)
    end)
end

refreshPromptState()
task.spawn(function()
    task.wait(1.5)
    startNextCase()
end)
