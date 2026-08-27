local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local PlayerDataStore = require(script.Parent:WaitForChild("PlayerDataStore"))
local EconomyTelemetryService = require(script.Parent:WaitForChild("EconomyTelemetryService"))

local TradeService = {}

local REQUEST_TTL = 20
local REQUEST_COOLDOWN = 3
local REVIEW_LOCK_SECONDS = 3
local MIN_ACCOUNT_AGE_DAYS = 7
local MIN_CASES_COMPLETED = 5
local MIN_XP = 50

local function cloneTable(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do
        result[key] = cloneTable(child)
    end
    return result
end

local function replaceArray(target, source)
    table.clear(target)
    for _, value in ipairs(source or {}) do
        table.insert(target, cloneTable(value))
    end
end

local function findInstance(inventory, instanceId)
    for index, instance in ipairs(inventory or {}) do
        if instance.instanceId == instanceId then
            return instance, index
        end
    end
    return nil, nil
end

local function removeInstance(inventory, instanceId)
    local _, index = findInstance(inventory, instanceId)
    if not index then return nil end
    return table.remove(inventory, index)
end

local function progressionReady(player)
    if player.AccountAge < MIN_ACCOUNT_AGE_DAYS then
        return false, "ACCOUNT_TOO_NEW"
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    local xpValue = leaderstats and leaderstats:FindFirstChild("XP")
    local xp = xpValue and xpValue.Value or 0
    local stats = PlayerDataStore.GetEconomyStats(player.UserId)
    local casesCompleted = math.max(0, math.floor(tonumber(stats.casesCompleted) or 0))

    if casesCompleted < MIN_CASES_COMPLETED and xp < MIN_XP then
        return false, "PROGRESSION_LOCKED"
    end
    return true
end

function TradeService.Start(context)
    local remotes = assert(context.remotes, "TradeService requires remotes")
    local CollectionRegistry = assert(context.collectionRegistry, "TradeService requires collectionRegistry")
    local Journal = assert(context.journal, "TradeService requires journal")

    local tradeUpdate = remotes:FindFirstChild("TradeUpdate") or Instance.new("RemoteEvent")
    tradeUpdate.Name = "TradeUpdate"
    tradeUpdate.Parent = remotes

    local sessionsByUserId = {}
    local instanceLocks = {}
    local pendingRequests = {}
    local requestCooldowns = {}
    local commitLockedUsers = {}

    local controller = {}

    local function publicItem(instance)
        if type(instance) ~= "table" then return nil end
        local entry = CollectionRegistry.Get(instance.collectionId)
        return {
            instanceId = instance.instanceId,
            collectionId = instance.collectionId,
            name = entry and entry.name or instance.collectionId,
            rarity = entry and entry.rarity or "UNRATED",
            serial = instance.serial,
            edition = instance.edition,
            serialNumber = instance.serialNumber,
            originalFinderUserId = instance.originalFinderUserId,
            currentOwnerUserId = instance.currentOwnerUserId,
            tradeCount = instance.tradeCount or 0,
            tradeable = instance.tradeable ~= false,
        }
    end

    local function inventoryPublic(player)
        local result = {}
        for _, instance in ipairs(context.getInventory(player)) do
            if instance.tradeable ~= false then
                table.insert(result, publicItem(instance))
            end
        end
        table.sort(result, function(a, b)
            if a.collectionId == b.collectionId then
                return (a.serialNumber or math.huge) < (b.serialNumber or math.huge)
            end
            return tostring(a.name) < tostring(b.name)
        end)
        return result
    end

    local function eligibility(player)
        if not player or not player.Parent then
            return false, "PLAYER_UNAVAILABLE"
        end
        if not context.isPersistenceReady(player) then
            return false, "SAVE_NOT_READY"
        end

        local progressionOk, progressionReason = progressionReady(player)
        if not progressionOk then
            return false, progressionReason
        end

        local tradeableCount = 0
        for _, instance in ipairs(context.getInventory(player)) do
            if instance.tradeable ~= false then
                tradeableCount += 1
            end
        end
        if tradeableCount < 1 then
            return false, "NO_TRADEABLE_ITEMS"
        end
        return true
    end

    local function lobbyPlayers(forPlayer)
        local result = {}
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= forPlayer then
                local ready, reason = eligibility(other)
                table.insert(result, {
                    userId = other.UserId,
                    name = other.DisplayName,
                    username = other.Name,
                    ready = ready,
                    reason = reason,
                })
            end
        end
        table.sort(result, function(a, b)
            return string.lower(a.name) < string.lower(b.name)
        end)
        return result
    end

    local function fireLobby(player, message)
        if not player or not player.Parent then return end
        local ready, reason = eligibility(player)
        tradeUpdate:FireClient(player, "LOBBY_SYNC", {
            ready = ready,
            reason = reason,
            message = message,
            players = lobbyPlayers(player),
            inventory = inventoryPublic(player),
        })
    end

    local function sideFor(session, userId)
        if session.userA == userId then return "A" end
        if session.userB == userId then return "B" end
        return nil
    end

    local function playerFor(session, side)
        local userId = side == "A" and session.userA or session.userB
        return Players:GetPlayerByUserId(userId)
    end

    local function selectedInstance(session, side)
        local userId = side == "A" and session.userA or session.userB
        local instanceId = side == "A" and session.offerA or session.offerB
        if not instanceId then return nil end
        local player = Players:GetPlayerByUserId(userId)
        if not player then return nil end
        return findInstance(context.getInventory(player), instanceId)
    end

    local function stateFor(session, player)
        local side = sideFor(session, player.UserId)
        if not side then return nil end
        local otherSide = side == "A" and "B" or "A"
        local partner = playerFor(session, otherSide)
        local yourOffer = selectedInstance(session, side)
        local theirOffer = selectedInstance(session, otherSide)
        local yourConfirmed = side == "A" and session.confirmA or session.confirmB
        local partnerConfirmed = side == "A" and session.confirmB or session.confirmA
        local yourFinal = side == "A" and session.finalA or session.finalB
        local partnerFinal = side == "A" and session.finalB or session.finalA
        local remaining = 0
        if session.stage == "REVIEW" and session.reviewReadyAt then
            remaining = math.max(0, session.reviewReadyAt - os.clock())
        end

        return {
            sessionId = session.id,
            stage = session.stage,
            partner = partner and {
                userId = partner.UserId,
                name = partner.DisplayName,
                username = partner.Name,
            } or {
                userId = side == "A" and session.userB or session.userA,
                name = "DISCONNECTED",
                username = "DISCONNECTED",
            },
            inventory = inventoryPublic(player),
            yourOffer = publicItem(yourOffer),
            theirOffer = publicItem(theirOffer),
            yourConfirmed = yourConfirmed == true,
            partnerConfirmed = partnerConfirmed == true,
            yourFinal = yourFinal == true,
            partnerFinal = partnerFinal == true,
            reviewRemaining = remaining,
        }
    end

    local function fireState(session)
        local a = Players:GetPlayerByUserId(session.userA)
        local b = Players:GetPlayerByUserId(session.userB)
        if a then tradeUpdate:FireClient(a, "TRADE_STATE", stateFor(session, a)) end
        if b then tradeUpdate:FireClient(b, "TRADE_STATE", stateFor(session, b)) end
    end

    local function releaseOfferLock(session, side)
        local instanceId = side == "A" and session.offerA or session.offerB
        if instanceId and instanceLocks[instanceId] == session.id then
            instanceLocks[instanceId] = nil
        end
        if side == "A" then session.offerA = nil else session.offerB = nil end
    end

    local function releaseSessionLocks(session)
        releaseOfferLock(session, "A")
        releaseOfferLock(session, "B")
    end

    local function finishSession(session)
        sessionsByUserId[session.userA] = nil
        sessionsByUserId[session.userB] = nil
        releaseSessionLocks(session)
    end

    local function cancelSession(session, reason)
        if not session or session.stage == "COMPLETED" then return end
        if session.stage == "COMMITTING" then return end
        session.stage = "CANCELLED"
        local a = Players:GetPlayerByUserId(session.userA)
        local b = Players:GetPlayerByUserId(session.userB)
        finishSession(session)
        EconomyTelemetryService.Record("tradeCancelled", 1)
        if a then tradeUpdate:FireClient(a, "TRADE_CANCELLED", { reason = reason or "CANCELLED" }) end
        if b then tradeUpdate:FireClient(b, "TRADE_CANCELLED", { reason = reason or "CANCELLED" }) end
    end

    local function resetConfirmations(session)
        session.confirmA = false
        session.confirmB = false
        session.finalA = false
        session.finalB = false
        session.reviewReadyAt = nil
        session.stage = "SELECTING"
    end

    local function addOffer(session, player, instanceId)
        if session.stage ~= "SELECTING" then
            tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Offer is locked for final review." })
            return
        end

        local side = sideFor(session, player.UserId)
        if not side then return end
        local inventory = context.getInventory(player)
        local instance = findInstance(inventory, instanceId)
        if not instance or instance.tradeable == false then
            tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Item is no longer tradeable or owned." })
            return
        end

        local lockOwner = instanceLocks[instanceId]
        if lockOwner and lockOwner ~= session.id then
            tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "That item is locked in another trade." })
            return
        end

        local previous = side == "A" and session.offerA or session.offerB
        if previous and previous ~= instanceId and instanceLocks[previous] == session.id then
            instanceLocks[previous] = nil
        end

        if side == "A" then session.offerA = instanceId else session.offerB = instanceId end
        instanceLocks[instanceId] = session.id
        resetConfirmations(session)
        fireState(session)
    end

    local function snapshotInventory(player)
        return cloneTable(context.getInventory(player))
    end

    local function commitTrade(session)
        if session.stage ~= "REVIEW" or not session.finalA or not session.finalB then return end
        local playerA = Players:GetPlayerByUserId(session.userA)
        local playerB = Players:GetPlayerByUserId(session.userB)
        if not playerA or not playerB then
            cancelSession(session, "PLAYER_LEFT")
            return
        end

        local instanceA = findInstance(context.getInventory(playerA), session.offerA)
        local instanceB = findInstance(context.getInventory(playerB), session.offerB)
        if not instanceA or not instanceB then
            cancelSession(session, "OWNERSHIP_CHANGED")
            return
        end
        if instanceLocks[instanceA.instanceId] ~= session.id or instanceLocks[instanceB.instanceId] ~= session.id then
            cancelSession(session, "ITEM_LOCK_LOST")
            return
        end

        local progressionA = progressionReady(playerA)
        local progressionB = progressionReady(playerB)
        if not progressionA or not progressionB then
            cancelSession(session, "ELIGIBILITY_CHANGED")
            return
        end

        session.stage = "COMMITTING"
        commitLockedUsers[playerA.UserId] = true
        commitLockedUsers[playerB.UserId] = true
        fireState(session)

        local tradeId = session.id
        local tradedAt = os.time()
        local record = {
            tradeId = tradeId,
            userA = playerA.UserId,
            userB = playerB.UserId,
            nameA = playerA.DisplayName,
            nameB = playerB.DisplayName,
            instanceA = cloneTable(instanceA),
            instanceB = cloneTable(instanceB),
        }

        local prepared, prepareReason = Journal.Prepare(record)
        if not prepared then
            commitLockedUsers[playerA.UserId] = nil
            commitLockedUsers[playerB.UserId] = nil
            session.stage = "SELECTING"
            resetConfirmations(session)
            tradeUpdate:FireClient(playerA, "TRADE_ERROR", { message = "Trade journal unavailable: " .. tostring(prepareReason) })
            tradeUpdate:FireClient(playerB, "TRADE_ERROR", { message = "Trade journal unavailable: " .. tostring(prepareReason) })
            fireState(session)
            return
        end

        local oldA = snapshotInventory(playerA)
        local oldB = snapshotInventory(playerB)
        local inventoryA = context.getInventory(playerA)
        local inventoryB = context.getInventory(playerB)

        local movedA = Journal.MoveInstance(instanceA, tradeId, playerA.UserId, playerB.UserId, tradedAt)
        local movedB = Journal.MoveInstance(instanceB, tradeId, playerB.UserId, playerA.UserId, tradedAt)

        removeInstance(inventoryA, instanceA.instanceId)
        removeInstance(inventoryB, instanceB.instanceId)
        table.insert(inventoryA, movedB)
        table.insert(inventoryB, movedA)
        context.markDirty(playerA)
        context.markDirty(playerB)

        local saveA = context.savePlayer(playerA, true)
        local saveB = context.savePlayer(playerB, true)
        local journalCommitted = false
        if saveA and saveB then
            journalCommitted = Journal.MarkStatus(tradeId, "COMMITTED")
        end

        if saveA and saveB and journalCommitted then
            Journal.ClearRecovery(playerA.UserId, tradeId)
            Journal.ClearRecovery(playerB.UserId, tradeId)
            commitLockedUsers[playerA.UserId] = nil
            commitLockedUsers[playerB.UserId] = nil
            session.stage = "COMPLETED"

            PlayerDataStore.IncrementEconomy(playerA.UserId, "tradesCompleted", 1)
            PlayerDataStore.IncrementEconomy(playerB.UserId, "tradesCompleted", 1)
            context.markDirty(playerA)
            context.markDirty(playerB)
            EconomyTelemetryService.Record("tradeCompleted", 1)

            context.sendCollectionSync(playerA)
            context.sendCollectionSync(playerB)
            tradeUpdate:FireClient(playerA, "TRADE_COMPLETED", {
                tradeId = tradeId,
                received = publicItem(movedB),
                sent = publicItem(movedA),
            })
            tradeUpdate:FireClient(playerB, "TRADE_COMPLETED", {
                tradeId = tradeId,
                received = publicItem(movedA),
                sent = publicItem(movedB),
            })
            finishSession(session)
            return
        end

        replaceArray(inventoryA, oldA)
        replaceArray(inventoryB, oldB)
        context.markDirty(playerA)
        context.markDirty(playerB)
        local rollbackA = context.savePlayer(playerA, true)
        local rollbackB = context.savePlayer(playerB, true)
        if rollbackA and rollbackB then
            Journal.MarkStatus(tradeId, "ROLLED_BACK")
            Journal.ClearRecovery(playerA.UserId, tradeId)
            Journal.ClearRecovery(playerB.UserId, tradeId)
        end

        commitLockedUsers[playerA.UserId] = nil
        commitLockedUsers[playerB.UserId] = nil
        finishSession(session)
        EconomyTelemetryService.Record("tradeCancelled", 1)
        context.sendCollectionSync(playerA)
        context.sendCollectionSync(playerB)
        tradeUpdate:FireClient(playerA, "TRADE_CANCELLED", { reason = "PERSISTENCE_FAILED" })
        tradeUpdate:FireClient(playerB, "TRADE_CANCELLED", { reason = "PERSISTENCE_FAILED" })
    end

    local function createSession(playerA, playerB)
        local session = {
            id = HttpService:GenerateGUID(false),
            userA = playerA.UserId,
            userB = playerB.UserId,
            stage = "SELECTING",
            offerA = nil,
            offerB = nil,
            confirmA = false,
            confirmB = false,
            finalA = false,
            finalB = false,
            createdAt = os.time(),
        }
        sessionsByUserId[playerA.UserId] = session
        sessionsByUserId[playerB.UserId] = session
        fireState(session)
        return session
    end

    tradeUpdate.OnServerEvent:Connect(function(player, action, payload)
        payload = type(payload) == "table" and payload or {}

        if action == "OPEN" or action == "REFRESH" then
            fireLobby(player)
            return
        end

        if action == "REQUEST" then
            if sessionsByUserId[player.UserId] then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Finish the current trade first." })
                return
            end
            local ready, reason = eligibility(player)
            if not ready then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Trade unavailable: " .. tostring(reason) })
                return
            end

            local now = os.clock()
            if requestCooldowns[player.UserId] and now - requestCooldowns[player.UserId] < REQUEST_COOLDOWN then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Trade request cooldown." })
                return
            end

            local targetUserId = math.floor(tonumber(payload.targetUserId) or 0)
            local target = Players:GetPlayerByUserId(targetUserId)
            if not target or target == player then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Player is unavailable." })
                return
            end
            if sessionsByUserId[target.UserId] then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "That player is already trading." })
                return
            end
            local targetReady, targetReason = eligibility(target)
            if not targetReady then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Player cannot trade: " .. tostring(targetReason) })
                return
            end

            pendingRequests[target.UserId] = pendingRequests[target.UserId] or {}
            pendingRequests[target.UserId][player.UserId] = os.clock() + REQUEST_TTL
            requestCooldowns[player.UserId] = now
            EconomyTelemetryService.Record("tradeRequests", 1)
            tradeUpdate:FireClient(target, "REQUEST_INCOMING", {
                fromUserId = player.UserId,
                fromName = player.DisplayName,
                expiresIn = REQUEST_TTL,
            })
            tradeUpdate:FireClient(player, "REQUEST_SENT", {
                targetUserId = target.UserId,
                targetName = target.DisplayName,
            })
            return
        end

        if action == "RESPOND" then
            local fromUserId = math.floor(tonumber(payload.fromUserId) or 0)
            local requestMap = pendingRequests[player.UserId]
            local expiresAt = requestMap and requestMap[fromUserId]
            if not expiresAt or os.clock() > expiresAt then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Trade request expired." })
                return
            end
            requestMap[fromUserId] = nil
            local requester = Players:GetPlayerByUserId(fromUserId)
            if not requester then return end

            if payload.accept ~= true then
                tradeUpdate:FireClient(requester, "REQUEST_DECLINED", { byName = player.DisplayName })
                return
            end
            if sessionsByUserId[player.UserId] or sessionsByUserId[requester.UserId] then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "One player is already trading." })
                return
            end
            local readyA = eligibility(requester)
            local readyB = eligibility(player)
            if not readyA or not readyB then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Trade eligibility changed." })
                return
            end
            createSession(requester, player)
            return
        end

        local session = sessionsByUserId[player.UserId]
        if not session then
            tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "No active trade." })
            return
        end

        if action == "SELECT_ITEM" then
            local instanceId = tostring(payload.instanceId or "")
            if instanceId == "" then return end
            addOffer(session, player, instanceId)
            return
        end

        if action == "CONFIRM" then
            if session.stage ~= "SELECTING" or not session.offerA or not session.offerB then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Both players must offer one item first." })
                return
            end
            local side = sideFor(session, player.UserId)
            if side == "A" then session.confirmA = true else session.confirmB = true end
            if session.confirmA and session.confirmB then
                session.stage = "REVIEW"
                session.reviewReadyAt = os.clock() + REVIEW_LOCK_SECONDS
                session.finalA = false
                session.finalB = false
                fireState(session)
                task.delay(REVIEW_LOCK_SECONDS, function()
                    if sessionsByUserId[session.userA] == session and session.stage == "REVIEW" then
                        fireState(session)
                    end
                end)
            else
                fireState(session)
            end
            return
        end

        if action == "FINAL_CONFIRM" then
            if session.stage ~= "REVIEW" then return end
            if os.clock() < (session.reviewReadyAt or math.huge) then
                tradeUpdate:FireClient(player, "TRADE_ERROR", { message = "Review lock is still active." })
                return
            end
            local side = sideFor(session, player.UserId)
            if side == "A" then session.finalA = true else session.finalB = true end
            fireState(session)
            if session.finalA and session.finalB then
                commitTrade(session)
            end
            return
        end

        if action == "CANCEL" then
            cancelSession(session, "CANCELLED_BY_PLAYER")
            return
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        pendingRequests[player.UserId] = nil
        for _, requestMap in pairs(pendingRequests) do
            requestMap[player.UserId] = nil
        end
        local session = sessionsByUserId[player.UserId]
        if session and session.stage ~= "COMMITTING" then
            cancelSession(session, "PLAYER_LEFT")
        end
    end)

    function controller:IsCommitLocked(userId)
        return commitLockedUsers[userId] == true
    end

    function controller:SendLobby(player, message)
        fireLobby(player, message)
    end

    return controller
end

return TradeService