local DataStoreService = game:GetService("DataStoreService")

local PlayerDataStore = {}

local STORE_NAME = "LostAndFound_PlayerData_v1"
local store = DataStoreService:GetDataStore(STORE_NAME)

local MAX_INVENTORY_ITEMS = 500
local MAX_PROVENANCE_EVENTS = 12
local MAX_OWNED_SKINS = 64
local economyCache = {}

local function keyFor(userId)
    return "u_" .. tostring(userId)
end

local function defaultEconomyStats()
    return {
        casesCompleted = 0,
        perfectCases = 0,
        creditsEarned = 0,
        creditsSpent = 0,
        serialsMinted = 0,
        tradesCompleted = 0,
        playSeconds = 0,
    }
end

local function defaultStationProfile()
    return {
        equippedSkin = "STANDARD_OPS",
        ownedSkins = {"STANDARD_OPS"},
        title = "NIGHT SHIFT OPERATOR",
    }
end

local function defaults()
    return {
        credits = 0,
        xp = 0,
        discovered = {},
        inventory = {},
        serialMigrationComplete = false,
        economyStats = defaultEconomyStats(),
        stationProfile = defaultStationProfile(),
    }
end

local function cleanString(value, maxLength)
    if type(value) ~= "string" then return nil end
    if #value < 1 then return nil end
    if #value > maxLength then
        return string.sub(value, 1, maxLength)
    end
    return value
end

local function sanitizeProvenance(raw)
    local result = {}
    if type(raw) ~= "table" then return result end

    for _, event in ipairs(raw) do
        if #result >= MAX_PROVENANCE_EVENTS then break end
        if type(event) == "table" then
            local tradeId = cleanString(event.tradeId, 80)
            if tradeId then
                table.insert(result, {
                    tradeId = tradeId,
                    fromUserId = math.max(0, math.floor(tonumber(event.fromUserId) or 0)),
                    toUserId = math.max(0, math.floor(tonumber(event.toUserId) or 0)),
                    tradedAt = math.max(0, math.floor(tonumber(event.tradedAt) or 0)),
                })
            end
        end
    end
    return result
end

local function sanitizeInstance(raw)
    if type(raw) ~= "table" then return nil end

    local instanceId = cleanString(raw.instanceId, 80)
    local collectionId = cleanString(raw.collectionId, 80)
    local serial = cleanString(raw.serial, 48)
    local edition = cleanString(raw.edition, 16) or "S1"
    if not instanceId or not collectionId or not serial then return nil end

    local serialNumber = math.max(1, math.floor(tonumber(raw.serialNumber) or 1))
    local mintedAt = math.max(0, math.floor(tonumber(raw.mintedAt) or 0))
    local originalFinderUserId = math.max(0, math.floor(tonumber(raw.originalFinderUserId) or 0))
    local currentOwnerUserId = math.max(0, math.floor(tonumber(raw.currentOwnerUserId) or originalFinderUserId))
    local sourceCaseId = cleanString(raw.sourceCaseId, 64) or "UNKNOWN"
    local sourceKind = cleanString(raw.sourceKind, 32) or "DISCOVERY"
    local lastTradeId = cleanString(raw.lastTradeId, 80)

    return {
        instanceId = instanceId,
        collectionId = collectionId,
        serial = serial,
        serialNumber = serialNumber,
        edition = edition,
        mintedAt = mintedAt,
        originalFinderUserId = originalFinderUserId,
        currentOwnerUserId = currentOwnerUserId,
        sourceCaseId = sourceCaseId,
        sourceKind = sourceKind,
        tradeable = raw.tradeable ~= false,
        tradeCount = math.max(0, math.floor(tonumber(raw.tradeCount) or 0)),
        lastTradeAt = math.max(0, math.floor(tonumber(raw.lastTradeAt) or 0)),
        lastTradeId = lastTradeId,
        provenance = sanitizeProvenance(raw.provenance),
    }
end

local function sanitizeEconomyStats(raw)
    local result = defaultEconomyStats()
    if type(raw) ~= "table" then return result end

    for key in pairs(result) do
        result[key] = math.max(0, math.floor(tonumber(raw[key]) or 0))
    end
    return result
end

local function cloneEconomyStats(raw)
    local clean = sanitizeEconomyStats(raw)
    local result = {}
    for key, value in pairs(clean) do result[key] = value end
    return result
end

local function sanitizeStationProfile(raw)
    local result = defaultStationProfile()
    if type(raw) ~= "table" then return result end

    result.equippedSkin = cleanString(raw.equippedSkin, 48) or result.equippedSkin
    result.title = cleanString(raw.title, 48) or result.title

    local seen = { STANDARD_OPS = true }
    result.ownedSkins = {"STANDARD_OPS"}
    if type(raw.ownedSkins) == "table" then
        for _, value in ipairs(raw.ownedSkins) do
            if #result.ownedSkins >= MAX_OWNED_SKINS then break end
            local id = cleanString(value, 48)
            if id and not seen[id] then
                seen[id] = true
                table.insert(result.ownedSkins, id)
            end
        end
    end

    if not seen[result.equippedSkin] then
        result.equippedSkin = "STANDARD_OPS"
    end
    return result
end

local function sanitize(raw)
    local data = defaults()
    if type(raw) ~= "table" then
        return data
    end

    if type(raw.credits) == "number" then
        data.credits = math.max(0, math.floor(raw.credits))
    end
    if type(raw.xp) == "number" then
        data.xp = math.max(0, math.floor(raw.xp))
    end
    data.serialMigrationComplete = raw.serialMigrationComplete == true
    data.economyStats = sanitizeEconomyStats(raw.economyStats)
    data.stationProfile = sanitizeStationProfile(raw.stationProfile)

    if type(raw.discovered) == "table" then
        local seen = {}
        for _, value in ipairs(raw.discovered) do
            if type(value) == "string" and not seen[value] then
                seen[value] = true
                table.insert(data.discovered, value)
            end
        end
    end

    if type(raw.inventory) == "table" then
        local seenInstance = {}
        local seenSerial = {}
        for _, rawInstance in ipairs(raw.inventory) do
            if #data.inventory >= MAX_INVENTORY_ITEMS then break end
            local instance = sanitizeInstance(rawInstance)
            if instance and not seenInstance[instance.instanceId] and not seenSerial[instance.serial] then
                seenInstance[instance.instanceId] = true
                seenSerial[instance.serial] = true
                table.insert(data.inventory, instance)
            end
        end
    end

    return data
end

function PlayerDataStore.Load(userId)
    local ok, result = pcall(function()
        return store:GetAsync(keyFor(userId))
    end)

    if not ok then
        warn("[LostAndFound] DataStore load failed for", userId, result)
        return defaults(), false
    end

    local clean = sanitize(result)
    economyCache[userId] = cloneEconomyStats(clean.economyStats)
    return clean, true
end

function PlayerDataStore.GetEconomyStats(userId)
    economyCache[userId] = economyCache[userId] or defaultEconomyStats()
    return economyCache[userId]
end

function PlayerDataStore.SetEconomyStats(userId, stats)
    economyCache[userId] = cloneEconomyStats(stats)
end

function PlayerDataStore.IncrementEconomy(userId, metric, amount)
    local stats = PlayerDataStore.GetEconomyStats(userId)
    if stats[metric] == nil then return false end
    amount = math.floor(tonumber(amount) or 1)
    stats[metric] = math.max(0, stats[metric] + amount)
    return true
end

function PlayerDataStore.Save(userId, payload)
    payload = type(payload) == "table" and payload or {}
    if type(payload.economyStats) ~= "table" and economyCache[userId] then
        local copy = {}
        for key, value in pairs(payload) do copy[key] = value end
        copy.economyStats = economyCache[userId]
        payload = copy
    end

    local clean = sanitize(payload)
    economyCache[userId] = cloneEconomyStats(clean.economyStats)

    local ok, err = pcall(function()
        store:UpdateAsync(keyFor(userId), function()
            return {
                version = 6,
                credits = clean.credits,
                xp = clean.xp,
                discovered = clean.discovered,
                inventory = clean.inventory,
                serialMigrationComplete = clean.serialMigrationComplete,
                economyStats = clean.economyStats,
                stationProfile = clean.stationProfile,
                updatedAt = os.time(),
            }
        end)
    end)

    if not ok then
        warn("[LostAndFound] DataStore save failed for", userId, err)
    end

    return ok
end

return PlayerDataStore
