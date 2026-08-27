local DataStoreService = game:GetService("DataStoreService")

local TradeJournalService = {}

local JOURNAL_STORE_NAME = "LostAndFound_TradeJournal_v1"
local RECOVERY_STORE_NAME = "LostAndFound_TradeRecovery_v1"
local journalStore = DataStoreService:GetDataStore(JOURNAL_STORE_NAME)
local recoveryStore = DataStoreService:GetDataStore(RECOVERY_STORE_NAME)

local MAX_PROVENANCE = 12

local function tradeKey(tradeId)
    return "t_" .. tostring(tradeId)
end

local function recoveryKey(userId)
    return "u_" .. tostring(userId)
end

local function cloneTable(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do
        result[key] = cloneTable(child)
    end
    return result
end

local function removeInstanceIds(inventory, ids)
    local result = {}
    for _, instance in ipairs(inventory or {}) do
        if not ids[instance.instanceId] then
            table.insert(result, cloneTable(instance))
        end
    end
    return result
end

function TradeJournalService.MoveInstance(instance, tradeId, fromUserId, toUserId, tradedAt)
    local moved = cloneTable(instance)
    moved.currentOwnerUserId = math.max(0, math.floor(tonumber(toUserId) or 0))
    moved.tradeCount = math.max(0, math.floor(tonumber(moved.tradeCount) or 0)) + 1
    moved.lastTradeAt = math.max(0, math.floor(tonumber(tradedAt) or os.time()))
    moved.lastTradeId = tostring(tradeId)

    local provenance = {}
    for _, event in ipairs(moved.provenance or {}) do
        if type(event) == "table" then
            table.insert(provenance, cloneTable(event))
        end
    end

    local alreadyRecorded = false
    for _, event in ipairs(provenance) do
        if event.tradeId == tradeId then
            alreadyRecorded = true
            break
        end
    end

    if not alreadyRecorded then
        table.insert(provenance, {
            tradeId = tostring(tradeId),
            fromUserId = math.max(0, math.floor(tonumber(fromUserId) or 0)),
            toUserId = math.max(0, math.floor(tonumber(toUserId) or 0)),
            tradedAt = math.max(0, math.floor(tonumber(tradedAt) or os.time())),
        })
    end

    while #provenance > MAX_PROVENANCE do
        table.remove(provenance, 1)
    end
    moved.provenance = provenance
    return moved
end

function TradeJournalService.Prepare(record)
    if type(record) ~= "table" or type(record.tradeId) ~= "string" then
        return false, "INVALID_RECORD"
    end
    if type(record.userA) ~= "number" or type(record.userB) ~= "number" then
        return false, "INVALID_USERS"
    end
    if type(record.instanceA) ~= "table" or type(record.instanceB) ~= "table" then
        return false, "INVALID_INSTANCES"
    end

    local stored = {
        version = 1,
        tradeId = record.tradeId,
        status = "PREPARED",
        preparedAt = os.time(),
        userA = record.userA,
        userB = record.userB,
        nameA = tostring(record.nameA or record.userA),
        nameB = tostring(record.nameB or record.userB),
        instanceA = cloneTable(record.instanceA),
        instanceB = cloneTable(record.instanceB),
    }

    local okJournal, journalErr = pcall(function()
        journalStore:SetAsync(tradeKey(record.tradeId), stored)
    end)
    if not okJournal then
        warn("[LostAndFound] Trade journal prepare failed", record.tradeId, journalErr)
        return false, "JOURNAL_WRITE_FAILED"
    end

    local okA = pcall(function()
        recoveryStore:SetAsync(recoveryKey(record.userA), record.tradeId)
    end)
    local okB = pcall(function()
        recoveryStore:SetAsync(recoveryKey(record.userB), record.tradeId)
    end)

    if not okA or not okB then
        pcall(function()
            journalStore:UpdateAsync(tradeKey(record.tradeId), function(current)
                if type(current) ~= "table" then current = stored end
                current.status = "ABORTED"
                current.updatedAt = os.time()
                return current
            end)
        end)
        pcall(function() recoveryStore:RemoveAsync(recoveryKey(record.userA)) end)
        pcall(function() recoveryStore:RemoveAsync(recoveryKey(record.userB)) end)
        return false, "RECOVERY_MARKER_FAILED"
    end

    return true
end

function TradeJournalService.MarkStatus(tradeId, status)
    local allowed = {
        COMMITTED = true,
        ROLLED_BACK = true,
        ABORTED = true,
    }
    if not allowed[status] then return false end

    local ok, err = pcall(function()
        journalStore:UpdateAsync(tradeKey(tradeId), function(current)
            if type(current) ~= "table" then return current end
            current.status = status
            current.updatedAt = os.time()
            if status == "COMMITTED" then current.committedAt = os.time() end
            if status == "ROLLED_BACK" then current.rolledBackAt = os.time() end
            return current
        end)
    end)
    if not ok then
        warn("[LostAndFound] Trade journal status failed", tradeId, status, err)
    end
    return ok
end

function TradeJournalService.ClearRecovery(userId, tradeId)
    local ok, err = pcall(function()
        recoveryStore:UpdateAsync(recoveryKey(userId), function(current)
            if current == tradeId then return nil end
            return current
        end)
    end)
    if not ok then
        warn("[LostAndFound] Trade recovery clear failed", userId, tradeId, err)
    end
    return ok
end

function TradeJournalService.ReconcileUser(userId, inventory)
    local okMarker, tradeId = pcall(function()
        return recoveryStore:GetAsync(recoveryKey(userId))
    end)
    if not okMarker or type(tradeId) ~= "string" then
        return inventory or {}, false, nil, nil
    end

    local okJournal, record = pcall(function()
        return journalStore:GetAsync(tradeKey(tradeId))
    end)
    if not okJournal or type(record) ~= "table" then
        return inventory or {}, false, tradeId, "JOURNAL_UNAVAILABLE"
    end

    local isA = tonumber(userId) == tonumber(record.userA)
    local isB = tonumber(userId) == tonumber(record.userB)
    if not isA and not isB then
        TradeJournalService.ClearRecovery(userId, tradeId)
        return inventory or {}, false, nil, "NOT_PARTICIPANT"
    end

    local outgoing = isA and record.instanceA or record.instanceB
    local incoming = isA and record.instanceB or record.instanceA
    if type(outgoing) ~= "table" or type(incoming) ~= "table" then
        return inventory or {}, false, tradeId, "INVALID_JOURNAL"
    end

    local ids = {
        [outgoing.instanceId] = true,
        [incoming.instanceId] = true,
    }
    local reconciled = removeInstanceIds(inventory or {}, ids)
    local status = tostring(record.status or "PREPARED")

    if status == "COMMITTED" then
        local fromUserId = isA and record.userB or record.userA
        local moved = TradeJournalService.MoveInstance(incoming, tradeId, fromUserId, userId, record.committedAt or record.updatedAt or os.time())
        table.insert(reconciled, moved)
    else
        local original = cloneTable(outgoing)
        original.currentOwnerUserId = userId
        table.insert(reconciled, original)
    end

    return reconciled, true, tradeId, status
end

return TradeJournalService
