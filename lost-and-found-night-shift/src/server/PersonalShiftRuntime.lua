local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local Config = require(shared:WaitForChild("Config"))
local CaseRegistry = require(shared:WaitForChild("CaseRegistry"))
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local CollectionPreviewFactory = require(shared:WaitForChild("CollectionPreviewFactory"))
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local PersonalStationWorld = require(script.Parent:WaitForChild("PersonalStationWorld"))
local LegacyWorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local ItemFactory = require(script.Parent:WaitForChild("ItemFactory"))
local PlayerDataStore = require(script.Parent:WaitForChild("PlayerDataStore"))
local SerialMintService = require(script.Parent:WaitForChild("SerialMintService"))
local TradeJournalService = require(script.Parent:WaitForChild("TradeJournalService"))
local TradeService = require(script.Parent:WaitForChild("TradeService"))
local EconomyTelemetryService = require(script.Parent:WaitForChild("EconomyTelemetryService"))

local PersonalShiftRuntime = {}

local DROP_CHANCE = Config.CollectionDropChance or {
    COMMON = 1.00,
    UNCOMMON = 0.85,
    RARE = 0.65,
    EPIC = 0.40,
    ANOMALY = 0.16,
    SECRET = 0.08,
}

local RARITY_RANK = {
    COMMON = 1,
    UNCOMMON = 2,
    RARE = 3,
    EPIC = 4,
    ANOMALY = 5,
    SECRET = 6,
}

local function cloneTable(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do
        result[key] = cloneTable(child)
    end
    return result
end

function PersonalShiftRuntime.Start()
    EconomyTelemetryService.Start()

    local remotes = ReplicatedStorage:FindFirstChild("LostAndFoundRemotes") or Instance.new("Folder")
    remotes.Name = "LostAndFoundRemotes"
    remotes.Parent = ReplicatedStorage

    local caseUpdate = remotes:FindFirstChild("CaseUpdate") or Instance.new("RemoteEvent")
    caseUpdate.Name = "CaseUpdate"
    caseUpdate.Parent = remotes

    local collectionUpdate = remotes:FindFirstChild("CollectionUpdate") or Instance.new("RemoteEvent")
    collectionUpdate.Name = "CollectionUpdate"
    collectionUpdate.Parent = remotes

    local incidentUpdate = remotes:FindFirstChild("IncidentUpdate") or Instance.new("RemoteEvent")
    incidentUpdate.Name = "IncidentUpdate"
    incidentUpdate.Parent = remotes

    local stationUpdate = remotes:FindFirstChild("StationUpdate") or Instance.new("RemoteEvent")
    stationUpdate.Name = "StationUpdate"
    stationUpdate.Parent = remotes

    local refs = PersonalStationWorld.Build()

    local discoveries = {}
    local inventories = {}
    local minting = {}
    local persistenceReady = {}
    local serialMigrationComplete = {}
    local stationProfiles = {}
    local dirty = {}
    local states = {}
    local stationOwners = {}
    local activeCaseCounts = {}
    local playAccrualAt = {}
    local flight000IncidentPayload = nil
    local tradeController = nil

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

    local function inventoryFor(userId)
        inventories[userId] = inventories[userId] or {}
        return inventories[userId]
    end

    local function firstInstanceFor(userId, collectionId)
        local best = nil
        for _, instance in ipairs(inventoryFor(userId)) do
            if instance.collectionId == collectionId then
                if not best or (instance.serialNumber or math.huge) < (best.serialNumber or math.huge) then
                    best = instance
                end
            end
        end
        return best
    end

    local function validEquippedSkin(profile)
        profile = type(profile) == "table" and profile or {}
        local owned = {}
        for _, skinId in ipairs(profile.ownedSkins or {}) do
            owned[skinId] = true
        end
        owned.STANDARD_OPS = true

        local requested = tostring(profile.equippedSkin or "STANDARD_OPS")
        local entry = StationSkinRegistry.Get(requested)
        if entry.acquisition == "FREE" or owned[requested] then
            return requested, entry
        end
        return "STANDARD_OPS", StationSkinRegistry.Get("STANDARD_OPS")
    end

    local function collectionSnapshot(player)
        local userId = player.UserId
        local found = discoveries[userId] or {}
        local discoveredIds = {}
        local serialByCollectionId = {}
        local ownedCounts = {}
        local count = 0

        for _, collectionId in ipairs(CollectionRegistry.Order) do
            if found[collectionId] then
                discoveredIds[collectionId] = true
                count += 1
            end
        end

        for _, instance in ipairs(inventoryFor(userId)) do
            if CollectionRegistry.Get(instance.collectionId) then
                ownedCounts[instance.collectionId] = (ownedCounts[instance.collectionId] or 0) + 1
                local current = serialByCollectionId[instance.collectionId]
                if not current or (instance.serialNumber or math.huge) < (current.serialNumber or math.huge) then
                    serialByCollectionId[instance.collectionId] = {
                        serial = instance.serial,
                        serialNumber = instance.serialNumber,
                        edition = instance.edition,
                        tradeable = instance.tradeable,
                        instanceId = instance.instanceId,
                        tradeCount = instance.tradeCount or 0,
                    }
                end
            end
        end

        return {
            discovered = discoveredIds,
            count = count,
            total = CollectionRegistry.Count(),
            entries = CollectionRegistry.PublicEntries(),
            serialByCollectionId = serialByCollectionId,
            ownedCounts = ownedCounts,
            inventoryCount = #inventoryFor(userId),
            serialMigrationComplete = serialMigrationComplete[userId] == true,
            persistent = persistenceReady[userId] == true,
            stationProfile = cloneTable(stationProfiles[userId] or {}),
        }
    end

    local function savePayload(player)
        local credits, xp = ensureStats(player)
        local found = discoveries[player.UserId] or {}
        local discoveredList = {}

        for _, collectionId in ipairs(CollectionRegistry.Order) do
            if found[collectionId] then table.insert(discoveredList, collectionId) end
        end

        local inventoryList = {}
        for _, instance in ipairs(inventoryFor(player.UserId)) do
            table.insert(inventoryList, instance)
        end

        return {
            credits = credits.Value,
            xp = xp.Value,
            discovered = discoveredList,
            inventory = inventoryList,
            serialMigrationComplete = serialMigrationComplete[player.UserId] == true,
            stationProfile = stationProfiles[player.UserId],
        }
    end

    local function accruePlaytime(player)
        local userId = player.UserId
        local now = os.time()
        local previous = playAccrualAt[userId] or now
        local delta = math.max(0, now - previous)
        if delta > 0 then
            PlayerDataStore.IncrementEconomy(userId, "playSeconds", delta)
            dirty[userId] = true
        end
        playAccrualAt[userId] = now
    end

    local function savePlayer(player, force, bypassTradeLock)
        local userId = player.UserId
        if persistenceReady[userId] ~= true then return false end
        if tradeController and tradeController:IsCommitLocked(userId) and not bypassTradeLock then
            return false
        end
        if not force and not dirty[userId] then return true end

        local ok = PlayerDataStore.Save(userId, savePayload(player))
        if ok then dirty[userId] = false end
        return ok
    end

    local function publicShowcaseFor(player)
        local state = states[player.UserId]
        if not state or not state.station then return end
        local showcase = state.station.Showcase
        if not showcase then return end

        local old = showcase:FindFirstChild("DisplayedItems")
        if old then old:Destroy() end
        local folder = Instance.new("Folder")
        folder.Name = "DisplayedItems"
        folder.Parent = showcase

        local candidates = {}
        for _, instance in ipairs(inventoryFor(player.UserId)) do
            local entry = CollectionRegistry.Get(instance.collectionId)
            if entry then
                table.insert(candidates, { instance = instance, entry = entry })
            end
        end
        table.sort(candidates, function(a, b)
            local rankA = RARITY_RANK[a.entry.rarity] or 0
            local rankB = RARITY_RANK[b.entry.rarity] or 0
            if rankA == rankB then
                return (a.instance.serialNumber or math.huge) < (b.instance.serialNumber or math.huge)
            end
            return rankA > rankB
        end)

        for index = 1, math.min(3, #candidates) do
            local candidate = candidates[index]
            local anchor = state.station.DisplayAnchors[index]
            if anchor then
                local model = CollectionPreviewFactory.Create(candidate.instance.collectionId, folder, false)
                model.Name = "Display_" .. tostring(index)
                pcall(function() model:ScaleTo(0.20) end)
                model:PivotTo(anchor.CFrame * CFrame.Angles(0, math.rad(180), 0))

                local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if primary then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "SerialLabel"
                    billboard.Size = UDim2.fromOffset(120, 26)
                    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
                    billboard.AlwaysOnTop = true
                    billboard.MaxDistance = 22
                    billboard.Parent = primary

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.fromScale(1, 1)
                    label.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
                    label.BackgroundTransparency = 0.18
                    label.TextColor3 = Color3.fromRGB(238, 221, 176)
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 9
                    label.Text = tostring(candidate.instance.serial)
                    label.Parent = billboard
                end
            end
        end
    end

    local function sendCollectionSync(player)
        collectionUpdate:FireClient(player, "SYNC", collectionSnapshot(player))
        publicShowcaseFor(player)
    end

    local function sourceForCollection(collectionId)
        for _, caseData in ipairs(CaseRegistry.Cases) do
            if caseData.collectionId == collectionId then return caseData.id, "CASE_ITEM" end
            if caseData.bonusCollectionId == collectionId then return caseData.id, "PERFECT_BONUS" end
        end
        return "UNKNOWN", "DISCOVERY"
    end

    local function markIndexDiscovered(player, collectionId, eventKind)
        local entry = CollectionRegistry.Get(collectionId)
        if not entry then return false end

        local found = discoveries[player.UserId]
        if not found then
            found = {}
            discoveries[player.UserId] = found
        end

        local isNew = not found[collectionId]
        found[collectionId] = true
        if isNew then dirty[player.UserId] = true end

        local snapshot = collectionSnapshot(player)
        snapshot.item = {
            id = entry.id,
            baseItemId = entry.baseItemId,
            name = entry.name,
            rarity = entry.rarity,
            serialPrefix = entry.serialPrefix,
            edition = entry.edition,
        }
        snapshot.isNew = isNew
        snapshot.bonus = eventKind == "BONUS_DISCOVERY"
        collectionUpdate:FireClient(player, isNew and (eventKind or "DISCOVERY") or "UPDATE", snapshot)
        return isNew
    end

    local function mintInstance(player, collectionId, sourceCaseId, sourceKind, silent)
        local userId = player.UserId
        if persistenceReady[userId] ~= true then return nil end

        minting[userId] = minting[userId] or {}
        local mintKey = tostring(collectionId) .. ":" .. tostring(os.clock())
        if minting[userId][mintKey] then return nil end
        minting[userId][mintKey] = true

        local entry = CollectionRegistry.Get(collectionId)
        if not entry then
            minting[userId][mintKey] = nil
            return nil
        end

        local instance = SerialMintService.Mint(entry, userId, sourceCaseId, sourceKind)
        minting[userId][mintKey] = nil
        if not instance or not player.Parent or persistenceReady[userId] ~= true then return nil end

        table.insert(inventoryFor(userId), instance)
        dirty[userId] = true
        PlayerDataStore.IncrementEconomy(userId, "serialsMinted", 1)
        EconomyTelemetryService.Record("serialsMinted", 1)

        if not silent then
            local snapshot = collectionSnapshot(player)
            snapshot.serialMint = {
                collectionId = instance.collectionId,
                serial = instance.serial,
                edition = instance.edition,
                sourceKind = instance.sourceKind,
            }
            collectionUpdate:FireClient(player, "SERIAL_MINTED", snapshot)
        end
        publicShowcaseFor(player)
        return instance
    end

    local function backfillSerializedInventory(player)
        local userId = player.UserId
        if persistenceReady[userId] ~= true then return end
        if serialMigrationComplete[userId] == true then
            player:SetAttribute("LostFoundSerializedInventoryReady", true)
            return
        end

        local found = discoveries[userId] or {}
        for _, collectionId in ipairs(CollectionRegistry.Order) do
            if not player.Parent then return end
            if found[collectionId] and not firstInstanceFor(userId, collectionId) then
                local sourceCaseId = sourceForCollection(collectionId)
                mintInstance(player, collectionId, sourceCaseId, "LEGACY_BACKFILL", true)
                task.wait(0.12)
            end
        end

        if player.Parent then
            serialMigrationComplete[userId] = true
            player:SetAttribute("LostFoundSerializedInventoryReady", true)
            dirty[userId] = true
            savePlayer(player, true)
            sendCollectionSync(player)
        end
    end

    local function seedLegacyEconomy(player)
        local stats = PlayerDataStore.GetEconomyStats(player.UserId)
        local credits, xp = ensureStats(player)
        local changed = false
        if (stats.casesCompleted or 0) == 0 and xp.Value > 0 then
            stats.casesCompleted = math.max(1, math.floor(xp.Value / 10))
            changed = true
        end
        if (stats.creditsEarned or 0) == 0 and credits.Value > 0 then
            stats.creditsEarned = credits.Value
            changed = true
        end
        if changed then dirty[player.UserId] = true end
    end

    local function setupPlayer(player)
        local credits, xp = ensureStats(player)
        local loaded, ok = PlayerDataStore.Load(player.UserId)
        local found = {}
        local inventory = {}
        local migrationComplete = false
        local recoveryChanged = false
        local recoveryTradeId = nil
        local recoveryStatus = nil

        if ok then
            credits.Value = loaded.credits or 0
            xp.Value = loaded.xp or 0
            migrationComplete = loaded.serialMigrationComplete == true
            stationProfiles[player.UserId] = cloneTable(loaded.stationProfile or {
                equippedSkin = "STANDARD_OPS",
                ownedSkins = {"STANDARD_OPS"},
                title = "NIGHT SHIFT OPERATOR",
            })

            for _, collectionId in ipairs(loaded.discovered or {}) do
                if CollectionRegistry.Get(collectionId) then found[collectionId] = true end
            end
            for _, instance in ipairs(loaded.inventory or {}) do
                if CollectionRegistry.Get(instance.collectionId) then
                    if not instance.currentOwnerUserId or instance.currentOwnerUserId == 0 then
                        instance.currentOwnerUserId = player.UserId
                    end
                    table.insert(inventory, instance)
                end
            end

            inventory, recoveryChanged, recoveryTradeId, recoveryStatus = TradeJournalService.ReconcileUser(player.UserId, inventory)
        else
            stationProfiles[player.UserId] = {
                equippedSkin = "STANDARD_OPS",
                ownedSkins = {"STANDARD_OPS"},
                title = "NIGHT SHIFT OPERATOR",
            }
        end

        discoveries[player.UserId] = found
        inventories[player.UserId] = inventory
        minting[player.UserId] = {}
        persistenceReady[player.UserId] = ok
        serialMigrationComplete[player.UserId] = migrationComplete
        dirty[player.UserId] = recoveryChanged == true
        playAccrualAt[player.UserId] = os.time()

        player:SetAttribute("LostFoundPersistenceReady", ok)
        player:SetAttribute("LostFoundSerializedInventoryReady", ok and migrationComplete)

        seedLegacyEconomy(player)

        if ok and recoveryChanged and recoveryTradeId then
            task.defer(function()
                if savePlayer(player, true) then
                    if recoveryStatus == "PREPARED" then
                        TradeJournalService.MarkStatus(recoveryTradeId, "ROLLED_BACK")
                    end
                    TradeJournalService.ClearRecovery(player.UserId, recoveryTradeId)
                end
            end)
        end
    end

    local function publicCase(caseData)
        if not caseData then return nil end
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

    local function fireCase(player, kind, state, extra)
        if not player or not player.Parent then return end
        local payload = extra or {}
        payload.case = state and publicCase(state.activeCase) or nil
        payload.inspections = state and cloneTable(state.inspections) or { scanned = false, tagChecked = false, opened = false }
        payload.locked = state and state.locked == true or true
        payload.milestone = Config.Milestone
        payload.stationId = state and state.stationId or player:GetAttribute("LostFoundStationId")
        caseUpdate:FireClient(player, kind, payload)
    end

    local function allInspectionComplete(state)
        return state.inspections.scanned and state.inspections.tagChecked and state.inspections.opened
    end

    local function refreshPrompts(state)
        if not state or not state.station then return end
        local enabled = state.owner and state.owner.Parent and state.activeCase and not state.locked
        state.station.ScannerPrompt.Enabled = enabled and not state.inspections.scanned or false
        state.station.TagPrompt.Enabled = enabled and state.inspections.scanned and not state.inspections.tagChecked or false
        state.station.OpenPrompt.Enabled = enabled and state.inspections.scanned and state.inspections.tagChecked and not state.inspections.opened or false
        for _, decisionPrompt in pairs(state.station.DecisionPrompts) do
            decisionPrompt.Enabled = enabled and allInspectionComplete(state) or false
        end
    end

    local function clearCaseObjects(state)
        if not state then return end
        if state.activeCase and activeCaseCounts[state.activeCase.id] then
            activeCaseCounts[state.activeCase.id] = math.max(0, activeCaseCounts[state.activeCase.id] - 1)
            if activeCaseCounts[state.activeCase.id] <= 0 then activeCaseCounts[state.activeCase.id] = nil end
        end
        state.activeCase = nil
        state.item = nil
        state.claimant = nil
        if state.station and state.station.ObjectFolder then
            state.station.ObjectFolder:ClearAllChildren()
        end
    end

    local function casesCompletedFor(player)
        local stats = PlayerDataStore.GetEconomyStats(player.UserId)
        return math.max(0, math.floor(tonumber(stats.casesCompleted) or 0))
    end

    local function eligibleCases(player)
        local completed = casesCompletedFor(player)
        if completed < 3 then
            return { CaseRegistry.Get(completed + 1) }, true
        end

        local pool = {}
        for index = 1, 5 do table.insert(pool, CaseRegistry.Get(index)) end
        if completed >= 5 then table.insert(pool, CaseRegistry.Get(6)) end
        if completed >= 7 then table.insert(pool, CaseRegistry.Get(7)) end
        if completed >= 8 then table.insert(pool, CaseRegistry.Get(8)) end
        if completed >= 9 then table.insert(pool, CaseRegistry.Get(9)) end
        if completed >= 10 then table.insert(pool, CaseRegistry.Get(10)) end
        return pool, false
    end

    local function weightedPick(state, candidates)
        local weighted = {}
        local total = 0
        for _, caseData in ipairs(candidates) do
            local weight = caseData.caseType == "mystery" and 3 or 10
            if caseData.id == "LF-M0-010" then weight = 2 end
            if state.lastCaseId == caseData.id then weight = math.max(1, math.floor(weight * 0.25)) end
            total += weight
            table.insert(weighted, { caseData = caseData, ceiling = total })
        end
        if total <= 0 then return candidates[1] end
        local roll = state.random:NextInteger(1, total)
        for _, entry in ipairs(weighted) do
            if roll <= entry.ceiling then return entry.caseData end
        end
        return candidates[#candidates]
    end

    local function selectCase(state)
        local pool, onboarding = eligibleCases(state.owner)
        if onboarding then return pool[1] end

        local nonDuplicate = {}
        for _, caseData in ipairs(pool) do
            if not activeCaseCounts[caseData.id] then table.insert(nonDuplicate, caseData) end
        end
        local candidates = #nonDuplicate > 0 and nonDuplicate or pool
        return weightedPick(state, candidates)
    end

    local function gradeDecision(state, decision)
        if decision == state.activeCase.correctDecision then return "PERFECT" end
        for _, candidate in ipairs(state.activeCase.questionableDecisions or {}) do
            if candidate == decision then return "QUESTIONABLE" end
        end
        if state.activeCase.risk == "high" and decision == "RETURN" then return "CATASTROPHIC" end
        return "WRONG"
    end

    local function grant(player, grade)
        local credits, xp = ensureStats(player)
        local reward = Config.Rewards[grade] or Config.Rewards.WRONG
        if reward.Credits ~= 0 then credits.Value += reward.Credits end
        if reward.XP ~= 0 then xp.Value += reward.XP end
        if reward.Credits ~= 0 or reward.XP ~= 0 then dirty[player.UserId] = true end

        PlayerDataStore.IncrementEconomy(player.UserId, "casesCompleted", 1)
        EconomyTelemetryService.Record("casesCompleted", 1)
        if grade == "PERFECT" then
            PlayerDataStore.IncrementEconomy(player.UserId, "perfectCases", 1)
            EconomyTelemetryService.Record("perfectCases", 1)
        end
        if reward.Credits > 0 then
            PlayerDataStore.IncrementEconomy(player.UserId, "creditsEarned", reward.Credits)
            EconomyTelemetryService.Record("creditsIssued", reward.Credits)
        end
        dirty[player.UserId] = true
        return reward, credits.Value, xp.Value
    end

    local function rollDrop(state, collectionId, grade, sourceCaseId, sourceKind)
        local entry = CollectionRegistry.Get(collectionId)
        if not entry or grade ~= "PERFECT" then return nil, "NOT_ELIGIBLE" end

        local chance = tonumber(DROP_CHANCE[entry.rarity]) or 0
        if chance <= 0 then return nil, "NO_CHANCE" end
        local roll = state.random:NextNumber()
        if roll > chance then return nil, "ROLL_MISS" end

        local instance = mintInstance(state.owner, collectionId, sourceCaseId, sourceKind, false)
        if instance then return instance, "MINTED" end
        return nil, "MINT_FAILED"
    end

    local function buildFlight000Incident(player, state)
        return {
            incidentId = "INCIDENT_000_A",
            title = "INCIDENT 000-A — FLIGHT 000",
            caseId = "LF-M0-007",
            triggeredBy = player and player.DisplayName or "UNKNOWN",
            stationId = state and state.stationId or "?",
            passenger = "Jonas Vale",
            passengerRecord = "FOUND",
            flightRecord = "NOT FOUND",
            tag = "F0-00013",
            operationalAction = "QUARANTINE",
            status = "CONNECTED / UNRESOLVED",
            note = "Transport origin remains impossible under current records.",
            finalExplanation = "CLASSIFIED / UNKNOWN",
        }
    end

    local function raiseFlight000Incident(player, state)
        local payload = buildFlight000Incident(player, state)
        flight000IncidentPayload = payload
        task.delay(0.65, function()
            incidentUpdate:FireAllClients("FLIGHT_000_INCIDENT", payload)
        end)
    end

    local function stationDenied(player, stationId)
        stationUpdate:FireClient(player, "DENIED", {
            stationId = stationId,
            message = "That station belongs to another shift.",
        })
    end

    local function startNextCase(state)
        if not state or not state.owner or not state.owner.Parent then return end
        state.locked = true
        refreshPrompts(state)
        clearCaseObjects(state)

        local caseData = selectCase(state)
        if not caseData then
            fireCase(state.owner, "SYNC", state, { message = "No eligible case available." })
            return
        end

        state.activeCase = caseData
        state.lastCaseId = caseData.id
        activeCaseCounts[caseData.id] = (activeCaseCounts[caseData.id] or 0) + 1
        state.inspections = { scanned = false, tagChecked = false, opened = false }
        refreshPrompts(state)

        state.item = ItemFactory.Create(state.station.ObjectFolder, caseData, state.station.ConveyorStart.CFrame)
        if state.item then state.item:SetAttribute("StationId", state.stationId) end
        fireCase(state.owner, "CASE_INCOMING", state, { message = "Incoming property to Station " .. state.stationId .. "..." })

        if state.item and state.item.PrimaryPart then
            local tween = TweenService:Create(
                state.item.PrimaryPart,
                TweenInfo.new(Config.ConveyorTravelTime or 2.8, Enum.EasingStyle.Linear),
                { CFrame = state.station.InspectionStop.CFrame }
            )
            tween:Play()
            tween.Completed:Wait()
        end

        if not state.owner.Parent or states[state.owner.UserId] ~= state then return end
        if state.item and state.item.Parent then
            task.wait(Config.ClaimantArrivalDelay or 0.45)
            state.claimant = LegacyWorldBuilder.CreateClaimant(state.station.ObjectFolder, state.station.ClaimantMarker, caseData)
            if state.claimant then state.claimant:SetAttribute("StationId", state.stationId) end
        end

        state.locked = false
        refreshPrompts(state)
        fireCase(state.owner, "CASE_READY", state, { message = "Station " .. state.stationId .. " ready. Scan the item." })
    end

    local function handleInspection(stationId, player, step)
        local ownerUserId = stationOwners[stationId]
        if ownerUserId ~= player.UserId then
            stationDenied(player, stationId)
            return
        end
        local state = states[player.UserId]
        if not state or state.locked or not state.activeCase then return end

        if step == "SCAN" then
            if state.inspections.scanned then return end
            state.inspections.scanned = true
        elseif step == "TAG" then
            if not state.inspections.scanned or state.inspections.tagChecked then return end
            state.inspections.tagChecked = true
        elseif step == "OPEN" then
            if not state.inspections.scanned or not state.inspections.tagChecked or state.inspections.opened then return end
            state.inspections.opened = true
        else
            return
        end

        refreshPrompts(state)
        local messages = {
            SCAN = "Scanner record loaded.",
            TAG = "Claim tag checked.",
            OPEN = "Physical inspection completed. Choose a decision.",
        }
        fireCase(player, "INSPECTION", state, {
            step = step,
            by = player.DisplayName,
            message = messages[step],
        })
    end

    local function handleDecision(stationId, player, decision)
        local ownerUserId = stationOwners[stationId]
        if ownerUserId ~= player.UserId then
            stationDenied(player, stationId)
            return
        end
        local state = states[player.UserId]
        if not state or state.locked or not state.activeCase then return end
        if not allInspectionComplete(state) then
            refreshPrompts(state)
            fireCase(player, "DECISION_BLOCKED", state, { message = "Complete SCAN, CHECK TAG, and OPEN before deciding." })
            return
        end

        state.locked = true
        refreshPrompts(state)

        local caseData = state.activeCase
        local caseId = caseData.id
        local grade = gradeDecision(state, decision)
        local reward, totalCredits, totalXP = grant(player, grade)

        -- Index records what the player has actually encountered, while ownership
        -- still requires a valid server-side drop roll. This preserves mystery/archive
        -- progression without creating free replacement items.
        markIndexDiscovered(player, caseData.collectionId or caseData.itemId, nil)
        local baseInstance, baseDropReason = rollDrop(state, caseData.collectionId or caseData.itemId, grade, caseId, "CASE_DROP")

        local bonusId = grade == "PERFECT" and caseData.bonusCollectionId or nil
        local bonusInstance = nil
        local bonusDropReason = nil
        if bonusId then
            markIndexDiscovered(player, bonusId, "BONUS_DISCOVERY")
            bonusInstance, bonusDropReason = rollDrop(state, bonusId, grade, caseId, "PERFECT_BONUS_DROP")
        end

        local isFlight000Incident = caseId == "LF-M0-007" and grade == "PERFECT"
        fireCase(player, "RESULT", state, {
            decision = decision,
            grade = grade,
            correctDecision = caseData.correctDecision,
            reason = caseData.reason,
            resolution = caseData.resolution,
            reward = reward,
            totalCredits = totalCredits,
            totalXP = totalXP,
            bonusCollectible = bonusId ~= nil,
            serverIncident = isFlight000Incident,
            by = player.DisplayName,
            drops = {
                base = baseInstance and { collectionId = baseInstance.collectionId, serial = baseInstance.serial } or nil,
                baseReason = baseDropReason,
                bonus = bonusInstance and { collectionId = bonusInstance.collectionId, serial = bonusInstance.serial } or nil,
                bonusReason = bonusDropReason,
            },
        })

        if isFlight000Incident then raiseFlight000Incident(player, state) end
        sendCollectionSync(player)

        local advanceDelay = isFlight000Incident and 6.2 or (Config.CaseAdvanceDelay or 3.2)
        task.delay(advanceDelay, function()
            if player.Parent and states[player.UserId] == state then startNextCase(state) end
        end)
    end

    local function connectStationPrompts(stationId, station)
        station.ScannerPrompt.Triggered:Connect(function(player)
            handleInspection(stationId, player, "SCAN")
        end)
        station.TagPrompt.Triggered:Connect(function(player)
            handleInspection(stationId, player, "TAG")
        end)
        station.OpenPrompt.Triggered:Connect(function(player)
            handleInspection(stationId, player, "OPEN")
        end)
        for decision, decisionPrompt in pairs(station.DecisionPrompts) do
            decisionPrompt.Triggered:Connect(function(player)
                handleDecision(stationId, player, decision)
            end)
        end
    end

    for stationId, station in pairs(refs.Stations) do
        connectStationPrompts(stationId, station)
    end

    local function findFreeStation()
        for _, stationId in ipairs(refs.Order) do
            if not stationOwners[stationId] then return stationId, refs.Stations[stationId] end
        end
        return nil, nil
    end

    local function moveCharacterToStation(player, state, character)
        task.delay(0.25, function()
            if not player.Parent or states[player.UserId] ~= state then return end
            local root = character and (character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5))
            if root and state.station and state.station.SpawnAnchor then
                root.CFrame = state.station.SpawnAnchor.CFrame
            end
        end)
    end

    local function assignStation(player)
        local stationId, station = findFreeStation()
        if not stationId then
            player:SetAttribute("LostFoundStationId", "")
            stationUpdate:FireClient(player, "NO_STATION", {
                message = "All 8 shift stations are occupied. You may remain in the social room until one opens.",
            })
            return nil
        end

        local profile = stationProfiles[player.UserId] or {
            equippedSkin = "STANDARD_OPS",
            ownedSkins = {"STANDARD_OPS"},
            title = "NIGHT SHIFT OPERATOR",
        }
        local skinId, skin = validEquippedSkin(profile)
        profile.equippedSkin = skinId
        stationProfiles[player.UserId] = profile

        local state = {
            owner = player,
            stationId = stationId,
            station = station,
            activeCase = nil,
            item = nil,
            claimant = nil,
            inspections = { scanned = false, tagChecked = false, opened = false },
            locked = true,
            lastCaseId = nil,
            random = Random.new((player.UserId * 1664525 + os.time()) % 2147483647),
        }
        states[player.UserId] = state
        stationOwners[stationId] = player.UserId
        player:SetAttribute("LostFoundStationId", stationId)
        PersonalStationWorld.SetOwner(station, player, skin)

        stationUpdate:FireClient(player, "ASSIGNED", {
            stationId = stationId,
            skinId = skinId,
            skinName = skin.name,
            title = profile.title,
            message = "SHIFT ASSIGNED — STATION " .. stationId,
        })

        player.CharacterAdded:Connect(function(character)
            normalizeCharacter(character)
            moveCharacterToStation(player, state, character)
        end)
        if player.Character then
            normalizeCharacter(player.Character)
            moveCharacterToStation(player, state, player.Character)
        end

        publicShowcaseFor(player)
        return state
    end

    local function releaseStation(player)
        local state = states[player.UserId]
        if not state then return end
        state.locked = true
        refreshPrompts(state)
        clearCaseObjects(state)
        stationOwners[state.stationId] = nil
        PersonalStationWorld.SetOwner(state.station, nil, StationSkinRegistry.Get("STANDARD_OPS"))
        states[player.UserId] = nil
        player:SetAttribute("LostFoundStationId", "")
    end

    tradeController = TradeService.Start({
        remotes = remotes,
        collectionRegistry = CollectionRegistry,
        journal = TradeJournalService,
        getInventory = function(player)
            return inventoryFor(player.UserId)
        end,
        isPersistenceReady = function(player)
            return persistenceReady[player.UserId] == true and serialMigrationComplete[player.UserId] == true
        end,
        markDirty = function(player)
            dirty[player.UserId] = true
        end,
        savePlayer = function(player, force)
            return savePlayer(player, force, true)
        end,
        sendCollectionSync = sendCollectionSync,
    })

    local function initializePlayer(player)
        setupPlayer(player)
        if not player.Parent then return end

        if persistenceReady[player.UserId] == true then
            backfillSerializedInventory(player)
        end
        sendCollectionSync(player)

        local state = assignStation(player)
        if flight000IncidentPayload then
            incidentUpdate:FireClient(player, "ARCHIVE_SYNC", flight000IncidentPayload)
        end

        if state then
            task.delay(0.9, function()
                if player.Parent and states[player.UserId] == state then startNextCase(state) end
            end)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        task.spawn(initializePlayer, player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if tradeController then
            local started = os.clock()
            while tradeController:IsCommitLocked(player.UserId) and os.clock() - started < 8 do
                task.wait(0.1)
            end
        end
        accruePlaytime(player)
        savePlayer(player, true)
        releaseStation(player)

        discoveries[player.UserId] = nil
        inventories[player.UserId] = nil
        minting[player.UserId] = nil
        persistenceReady[player.UserId] = nil
        serialMigrationComplete[player.UserId] = nil
        stationProfiles[player.UserId] = nil
        dirty[player.UserId] = nil
        playAccrualAt[player.UserId] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(initializePlayer, player)
    end

    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do
                accruePlaytime(player)
                savePlayer(player, false)
            end
        end
    end)

    game:BindToClose(function()
        for _, player in ipairs(Players:GetPlayers()) do
            local started = os.clock()
            while tradeController and tradeController:IsCommitLocked(player.UserId) and os.clock() - started < 8 do
                task.wait(0.1)
            end
            accruePlaytime(player)
            savePlayer(player, true)
        end
        EconomyTelemetryService.Flush()
    end)
end

return PersonalShiftRuntime
