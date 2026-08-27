local DataStoreService = game:GetService("DataStoreService")

local PlayerDataStore = {}

local STORE_NAME = "LostAndFound_PlayerData_v1"
local store = DataStoreService:GetDataStore(STORE_NAME)

local function keyFor(userId)
    return "u_" .. tostring(userId)
end

local function defaults()
    return {
        credits = 0,
        xp = 0,
        discovered = {},
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
        for _, value in ipairs(raw.discovered) do
            if type(value) == "string" then
                table.insert(data.discovered, value)
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
                version = 1,
                credits = clean.credits,
                xp = clean.xp,
                discovered = clean.discovered,
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
