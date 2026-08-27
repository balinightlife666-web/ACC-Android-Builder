local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local Config = require(shared:WaitForChild("Config"))
local CaseRegistry = require(shared:WaitForChild("CaseRegistry"))
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local ItemFactory = require(script.Parent:WaitForChild("ItemFactory"))
local PlayerDataStore = require(script.Parent:WaitForChild("PlayerDataStore"))

local remotes = ReplicatedStorage:FindFirstChild("LostAndFoundRemotes") or Instance.new("Folder")
remotes.Name = "LostAndFoundRemotes"
remotes.Parent = ReplicatedStorage

local caseUpdate = remotes:FindFirstChild("CaseUpdate") or Instance.new("RemoteEvent")
caseUpdate.Name = "CaseUpdate"
caseUpdate.Parent = remotes

local collectionUpdate = remotes:FindFirstChild("CollectionUpdate") or Instance.new("RemoteEvent")
collectionUpdate.Name = "CollectionUpdate"
collectionUpdate.Parent = remotes

local refs = WorldBuilder.Build()
local activeIndex = 0
local activeCase = nil
local activeSuitcase = nil
local activeClaimant = nil
local locked = false
local inspections = { scanned = false, tagChecked = false, opened = false }
local discoveries = {}
local persistenceReady = {}
local dirty = {}

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
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local credits = leaderstats:FindFirstChild("Credits")
    if not credits then
        credits = Instance.new("IntValue")
        credits.Name = "Credits"
        credits.Value = 0
        credits.Parent = leaderstats
    end

    local xp = leaderstats:FindFirstChild("XP")
    if not xp then
        xp = Instance.new("IntValue")
        xp.Name = "XP"
        xp.Value = 0
        xp.Parent = leaderstats
    end

    return credits, xp
end

local function normalizeCharacter(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then descendant.Anchored = false end
    end

    if root then root.Anchored = false end

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

local function collectionSnapshot(player)
    local found = discoveries[player.UserId] or {}
    local discoveredIds = {}
    local count = 0

    for _, collectionId in ipairs(CollectionRegistry.Order) do
        if found[collectionId] then
            discoveredIds[collectionId] = true
            count += 1
        end
    end

    return {
        discovered = discoveredIds,
        count = count,
        total = CollectionRegistry.Count(),
        entries = CollectionRegistry.PublicEntries(),
        persistent = persistenceReady[player.UserId] == true,
    }
end

local function savePayload(player)
    local credits, xp = ensureStats(player)
    local found = discoveries[player.UserId] or {}
    local discoveredList = {}

    for _, collectionId in ipairs(CollectionRegistry.Order) do
        if found[collectionId] then
            table.insert(discoveredList, collectionId)
        end
    end

    return {
        credits = credits.Value,
        xp = xp.Value,
        discovered = discoveredList,
    }
end

local function savePlayer(player, force)
    local userId = player.UserId
    if persistenceReady[userId] ~= true then
        return false
    end
    if not force and not dirty[userId] then
        return true
    end

    local ok = PlayerDataStore.Save(userId, savePayload(player))
    if ok then
        dirty[userId] = false
    end
    return ok
end

local function sendCollectionSync(player)
    collectionUpdate:FireClient(player, "SYNC", collectionSnapshot(player))
end

local function markDiscovered(player, collectionId, newEventKind)
    local entry = CollectionRegistry.Get(collectionId)
    if not entry then return false end

    local found = discoveries[player.UserId]
    if not found then
        found = {}
        discoveries[player.UserId] = found
    end

    local isNew = not found[collectionId]
    found[collectionId] = true
    if isNew then
        dirty[player.UserId] = true
    end

    local snapshot = collectionSnapshot(player)
    snapshot.item = {
        id = entry.id,
        baseItemId = entry.baseItemId,
        name = entry.name,
        rarity = entry.rarity,
    }
    snapshot.isNew = isNew
    snapshot.bonus = newEventKind == "BONUS_DISCOVERY"

    local kind = isNew and (newEventKind or "DISCOVERY") or "UPDATE"
    collectionUpdate:FireClient(player, kind, snapshot)
    return isNew
end

local function setupPlayer(player)
    local credits, xp = ensureStats(player)
    local loaded, ok = PlayerDataStore.Load(player.UserId)
    local found = {}

    if ok then
        credits.Value = loaded.credits or 0
        xp.Value = loaded.xp or 0
        for _, collectionId in ipairs(loaded.discovered or {}) do
            if CollectionRegistry.Get(collectionId) then
                found[collectionId] = true
            end
        end
    end

    discoveries[player.UserId] = found
    persistenceReady[player.UserId] = ok
    dirty[player.UserId] = false
    player:SetAttribute("LostFoundPersistenceReady", ok)

    player.CharacterAdded:Connect(function(character)
        task.defer(normalizeCharacter, character)
    end)
    if player.Character then task.defer(normalizeCharacter, player.Character) end
end

local function publicCase(caseData)
    local collectionId = caseData.collectionId or caseData.itemId
    local collectionItem = CollectionRegistry.Get(collectionId)
    return {
        id = caseData.id,
        title = caseData.title,
        caseType = caseData.caseType,
        itemId = caseData.itemId,
        collectionId = collectionId,
        itemName = caseData.itemName,
        itemRarity = collectionItem and collectionItem.rarity or "UNRATED",
        owner = caseData.owner,
        claimantName = caseData.claimantName or "NO CLAIMANT",
        claimantKind = caseData.claimantKind,
        tagNumber = caseData.tagNumber,
        claimantTag = caseData.claimantTag,
        flight = caseData.flight,
        weight = caseData.weight,
        contents = caseData.contents,
        scanStatus = caseData.scanStatus,
        anomaly = caseData.anomaly,
        resolution = caseData.resolution,
    }
end

local function broadcast(kind, extra)
    local payload = extra or {}
    payload.case = activeCase and publicCase(activeCase) or nil
    payload.inspections = {
        scanned = inspections.scanned,
        tagChecked = inspections.tagChecked,
        opened = inspections.opened,
    }
    payload.locked = locked
    payload.milestone = Config.Milestone
    caseUpdate:FireAllClients(kind, payload)
end

Players.PlayerAdded:Connect(function(player)
    setupPlayer(player)
    task.delay(0.5, function()
        if not player.Parent then return end
        if activeCase then
            caseUpdate:FireClient(player, "SYNC", {
                case = publicCase(activeCase),
                inspections = inspections,
                locked = locked,
                milestone = Config.Milestone,
            })
        end
        sendCollectionSync(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayer(player, true)
    discoveries[player.UserId] = nil
    persistenceReady[player.UserId] = nil
    dirty[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
    task.defer(sendCollectionSync, player)
end

local function cleanActive()
    if activeSuitcase then
        activeSuitcase:Destroy()
        activeSuitcase = nil
    end
    if activeClaimant then
        activeClaimant:Destroy()
        activeClaimant = nil
    end
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

    activeSuitcase = ItemFactory.Create(refs.World, activeCase, refs.ConveyorStart.CFrame)
    broadcast("CASE_INCOMING", { message = "Incoming property on conveyor..." })

    if activeSuitcase and activeSuitcase.PrimaryPart then
        local tween = TweenService:Create(
            activeSuitcase.PrimaryPart,
            TweenInfo.new(Config.ConveyorTravelTime, Enum.EasingStyle.Linear),
            { CFrame = refs.InspectionStop.CFrame }
        )
        tween:Play()
        tween.Completed:Wait()
    end

    if activeSuitcase and activeSuitcase.Parent then
        task.wait(Config.ClaimantArrivalDelay or 0)
        activeClaimant = WorldBuilder.CreateClaimant(refs.World, refs.ClaimantMarker, activeCase)
    end

    locked = false
    refreshPromptState()
    broadcast("CASE_READY", { message = "Scan the item to begin inspection." })
end

local function grant(player, grade)
    local credits, xp = ensureStats(player)
    local reward = Config.Rewards[grade] or Config.Rewards.WRONG

    if reward.Credits ~= 0 then credits.Value += reward.Credits end
    if reward.XP ~= 0 then xp.Value += reward.XP end
    if reward.Credits ~= 0 or reward.XP ~= 0 then
        dirty[player.UserId] = true
    end

    return reward, credits.Value, xp.Value
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then return true end
    end
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
    broadcast("INSPECTION", {
        step = "SCAN",
        by = player.DisplayName,
        message = "Scanner record loaded.",
    })
end)

refs.TagPrompt.Triggered:Connect(function(player)
    if locked or not activeCase or not inspections.scanned or inspections.tagChecked then return end
    inspections.tagChecked = true
    refreshPromptState()
    broadcast("INSPECTION", {
        step = "TAG",
        by = player.DisplayName,
        message = "Claim tag checked.",
    })
end)

refs.OpenPrompt.Triggered:Connect(function(player)
    if locked or not activeCase or not inspections.scanned or not inspections.tagChecked or inspections.opened then return end
    inspections.opened = true
    refreshPromptState()
    broadcast("INSPECTION", {
        step = "OPEN",
        by = player.DisplayName,
        message = "Physical inspection completed. Choose a decision.",
    })
end)

for decision, decisionPrompt in pairs(refs.DecisionPrompts) do
    decisionPrompt.Triggered:Connect(function(player)
        if locked or not activeCase then return end
        if not inspectionsComplete() then
            refreshPromptState()
            broadcast("DECISION_BLOCKED", {
                message = "Complete SCAN, CHECK TAG, and OPEN before deciding.",
            })
            return
        end

        locked = true
        refreshPromptState()

        local grade = gradeDecision(decision)
        local reward, totalCredits, totalXP = grant(player, grade)
        markDiscovered(player, activeCase.collectionId or activeCase.itemId)

        local bonusId = grade == "PERFECT" and activeCase.bonusCollectionId or nil
        if bonusId then
            task.delay(1.35, function()
                if player.Parent then
                    markDiscovered(player, bonusId, "BONUS_DISCOVERY")
                end
            end)
        end

        broadcast("RESULT", {
            decision = decision,
            grade = grade,
            correctDecision = activeCase.correctDecision,
            reason = activeCase.reason,
            resolution = activeCase.resolution,
            reward = reward,
            totalCredits = totalCredits,
            totalXP = totalXP,
            bonusCollectible = bonusId ~= nil,
            by = player.DisplayName,
        })

        task.delay(Config.CaseAdvanceDelay, function()
            startNextCase()
        end)
    end)
end

-- Conservative autosave: only dirty, successfully-loaded profiles are written.
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayer(player, false)
        end
    end
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlayer(player, true)
    end
end)

refreshPromptState()
task.spawn(function()
    task.wait(1.5)
    startNextCase()
end)
