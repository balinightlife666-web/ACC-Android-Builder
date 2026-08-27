local Players = game:GetService("Players")

local PlayerDataStore = require(script.Parent:WaitForChild("PlayerDataStore"))
local EconomyTelemetryService = require(script.Parent:WaitForChild("EconomyTelemetryService"))
local SerialMintService = require(script.Parent:WaitForChild("SerialMintService"))

EconomyTelemetryService.Start()

local playAccrualAt = {}
local decisionConnections = {}

local function statsFor(player)
    return PlayerDataStore.GetEconomyStats(player.UserId)
end

local function accruePlaytime(player)
    local userId = player.UserId
    local now = os.time()
    local previous = playAccrualAt[userId] or now
    local delta = math.max(0, now - previous)
    if delta > 0 then
        PlayerDataStore.IncrementEconomy(userId, "playSeconds", delta)
    end
    playAccrualAt[userId] = now
end

local function refreshTradeAttributes(player)
    local stats = statsFor(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    local xpValue = leaderstats and leaderstats:FindFirstChild("XP")
    local xp = xpValue and xpValue.Value or 0
    local ageReady = player.AccountAge >= 7
    local progressReady = (stats.casesCompleted or 0) >= 5 or xp >= 50

    player:SetAttribute("LostFoundTradeAccountAgeReady", ageReady)
    player:SetAttribute("LostFoundTradeProgressReady", progressReady)
    player:SetAttribute("LostFoundTradeEconomyReady", ageReady and progressReady)
end

local function seedLegacyProgress(player)
    local stats = statsFor(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local xpValue = leaderstats:FindFirstChild("XP")
    local creditsValue = leaderstats:FindFirstChild("Credits")
    local xp = xpValue and xpValue.Value or 0
    local credits = creditsValue and creditsValue.Value or 0

    if (stats.casesCompleted or 0) == 0 and xp > 0 then
        stats.casesCompleted = math.max(1, math.floor(xp / 10))
    end
    if (stats.creditsEarned or 0) == 0 and credits > 0 then
        stats.creditsEarned = credits
    end
end

local function watchPlayer(player)
    playAccrualAt[player.UserId] = os.time()

    task.spawn(function()
        local started = os.clock()
        while player.Parent and player:GetAttribute("LostFoundPersistenceReady") == nil and os.clock() - started < 15 do
            task.wait(0.1)
        end
        if not player.Parent or player:GetAttribute("LostFoundPersistenceReady") ~= true then return end

        local leaderstats = player:WaitForChild("leaderstats", 10)
        if not leaderstats then return end
        local xpValue = leaderstats:FindFirstChild("XP") or leaderstats:WaitForChild("XP", 5)

        seedLegacyProgress(player)
        refreshTradeAttributes(player)

        if xpValue then
            xpValue.Changed:Connect(function()
                refreshTradeAttributes(player)
            end)
        end
    end)
end

local originalMint = SerialMintService.Mint
if not SerialMintService._M4CEconomyWrapped then
    SerialMintService._M4CEconomyWrapped = true
    SerialMintService.Mint = function(entry, originalFinderUserId, sourceCaseId, sourceKind)
        local instance, reason = originalMint(entry, originalFinderUserId, sourceCaseId, sourceKind)
        if instance then
            PlayerDataStore.IncrementEconomy(originalFinderUserId, "serialsMinted", 1)
            EconomyTelemetryService.Record("serialsMinted", 1)
        end
        return instance, reason
    end
end

local function connectDecisionPrompt(prompt)
    if decisionConnections[prompt] then return end
    decisionConnections[prompt] = true

    prompt.Triggered:Connect(function(player)
        if not player or player:GetAttribute("LostFoundPersistenceReady") ~= true then return end
        local leaderstats = player:FindFirstChild("leaderstats")
        local xpValue = leaderstats and leaderstats:FindFirstChild("XP")
        local creditsValue = leaderstats and leaderstats:FindFirstChild("Credits")
        local beforeXP = xpValue and xpValue.Value or 0
        local beforeCredits = creditsValue and creditsValue.Value or 0

        task.defer(function()
            if not player.Parent then return end
            local afterXP = xpValue and xpValue.Value or beforeXP
            local afterCredits = creditsValue and creditsValue.Value or beforeCredits
            local xpDelta = math.max(0, afterXP - beforeXP)
            local creditDelta = math.max(0, afterCredits - beforeCredits)

            PlayerDataStore.IncrementEconomy(player.UserId, "casesCompleted", 1)
            EconomyTelemetryService.Record("casesCompleted", 1)

            if xpDelta >= 20 then
                PlayerDataStore.IncrementEconomy(player.UserId, "perfectCases", 1)
                EconomyTelemetryService.Record("perfectCases", 1)
            end

            if creditDelta > 0 then
                PlayerDataStore.IncrementEconomy(player.UserId, "creditsEarned", creditDelta)
                EconomyTelemetryService.Record("creditsIssued", creditDelta)
            end

            refreshTradeAttributes(player)
        end)
    end)
end

local function connectDecisionPrompts()
    local world = workspace:WaitForChild("LostAndFoundM1", 20)
    if not world then
        warn("[LostAndFound] M4-C could not find LostAndFoundM1 for decision telemetry")
        return
    end

    for _, descendant in ipairs(world:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.ObjectText == "CASE DECISION" then
            connectDecisionPrompt(descendant)
        end
    end

    world.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ProximityPrompt") and descendant.ObjectText == "CASE DECISION" then
            connectDecisionPrompt(descendant)
        end
    end)
end

Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(player)
    accruePlaytime(player)
    playAccrualAt[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(watchPlayer, player)
end

task.spawn(connectDecisionPrompts)

task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            accruePlaytime(player)
        end
    end
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        accruePlaytime(player)
    end
    EconomyTelemetryService.Flush()
end)
