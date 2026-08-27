local DataStoreService = game:GetService("DataStoreService")

local EconomyTelemetryService = {}

local STORE_NAME = "LostAndFound_EconomyTelemetry_v1"
local store = DataStoreService:GetDataStore(STORE_NAME)

local allowed = {
    casesCompleted = true,
    perfectCases = true,
    creditsIssued = true,
    serialsMinted = true,
    tradeRequests = true,
    tradeCompleted = true,
    tradeCancelled = true,
}

local buffer = {}
local flushing = false

local function utcDayKey()
    local now = os.date("!*t")
    return string.format("%04d-%02d-%02d", now.year, now.month, now.day)
end

function EconomyTelemetryService.Record(metric, amount)
    if not allowed[metric] then return end
    amount = math.floor(tonumber(amount) or 1)
    if amount == 0 then return end
    buffer[metric] = (buffer[metric] or 0) + amount
end

function EconomyTelemetryService.Flush()
    if flushing then return false end
    if next(buffer) == nil then return true end

    flushing = true
    local snapshot = buffer
    buffer = {}

    local ok, err = pcall(function()
        store:UpdateAsync("day_" .. utcDayKey(), function(current)
            current = type(current) == "table" and current or {}
            for metric, amount in pairs(snapshot) do
                current[metric] = math.max(0, math.floor(tonumber(current[metric]) or 0)) + amount
            end
            current.updatedAt = os.time()
            return current
        end)
    end)

    if not ok then
        for metric, amount in pairs(snapshot) do
            buffer[metric] = (buffer[metric] or 0) + amount
        end
        warn("[LostAndFound] Economy telemetry flush failed", err)
    end

    flushing = false
    return ok
end

function EconomyTelemetryService.Start()
    task.spawn(function()
        while true do
            task.wait(120)
            EconomyTelemetryService.Flush()
        end
    end)
end

return EconomyTelemetryService
