local DataStoreService = game:GetService("DataStoreService")

local PlayerDataStore = {}

local STORE_NAME = "LostAndFound_PlayerData_v1"
local store = DataStoreService:GetDataStore(STORE_NAME)

local MAX_INVENTORY_ITEMS = 500

local function keyFor(userId)
    return "u_" .. tostring(userId)
end

local function defaults()
    return {
        credits = 0,
        xp = 0,
        discovered = {},
        inventory = {},
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
    local sourceCaseId = cleanString(raw.sourceCaseId, 64) or "UNKNOWN"
    local sourceKind = cleanString(raw.sourceKind, 32) or "DISCOVERY"

    return {
        instanceId = instanceId,
        collectionId = collectionId,
        serial = serial,
        serialNumber = serialNumber,
        edition = edition,
        mintedAt = mintedAt,
        originalFinderUserId = originalFinderUserId,
        sourceCaseId = sourceCaseId,
        sourceKind = sourceKind,
        tradeable = raw.tradeable ~= false,
    }
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

    return sanitize(result), true
end

function PlayerDataStore.Save(userId, payload)
    local clean = sanitize(payload)
    local ok, err = pcall(function()
        store:UpdateAsync(keyFor(userId), function()
            return {
                version = 2,
                credits = clean.credits,
                xp = clean.xp,
                discovered = clean.discovered,
                inventory = clean.inventory,
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
