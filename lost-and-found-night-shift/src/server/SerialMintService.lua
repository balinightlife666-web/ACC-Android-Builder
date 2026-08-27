local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local SerialMintService = {}

local COUNTER_STORE_NAME = "LostAndFound_MintCounters_v1"
local counterStore = DataStoreService:GetDataStore(COUNTER_STORE_NAME)

local function waitForUpdateBudget()
    for _ = 1, 40 do
        local budget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
        if budget > 0 then
            return true
        end
        task.wait(0.25)
    end
    return false
end

local function counterKey(collectionId)
    return "mint_" .. tostring(collectionId)
end

function SerialMintService.Mint(entry, originalFinderUserId, sourceCaseId, sourceKind)
    if type(entry) ~= "table" or type(entry.id) ~= "string" then
        return nil, "INVALID_ENTRY"
    end

    if not waitForUpdateBudget() then
        warn("[LostAndFound] Serial mint budget unavailable for", entry.id)
        return nil, "NO_BUDGET"
    end

    local ok, serialNumber = pcall(function()
        return counterStore:UpdateAsync(counterKey(entry.id), function(current)
            local value = tonumber(current) or 0
            return math.max(0, math.floor(value)) + 1
        end)
    end)

    if not ok or type(serialNumber) ~= "number" then
        warn("[LostAndFound] Serial mint failed for", entry.id, serialNumber)
        return nil, "COUNTER_FAILED"
    end

    serialNumber = math.max(1, math.floor(serialNumber))
    local prefix = tostring(entry.serialPrefix or "LNF")
    local edition = tostring(entry.edition or "S1")
    local serial = string.format("%s-%s-%06d", prefix, edition, serialNumber)

    return {
        instanceId = HttpService:GenerateGUID(false),
        collectionId = entry.id,
        serial = serial,
        serialNumber = serialNumber,
        edition = edition,
        mintedAt = os.time(),
        originalFinderUserId = math.max(0, math.floor(tonumber(originalFinderUserId) or 0)),
        sourceCaseId = tostring(sourceCaseId or "UNKNOWN"),
        sourceKind = tostring(sourceKind or "DISCOVERY"),
        tradeable = entry.tradeable ~= false,
    }
end

return SerialMintService
