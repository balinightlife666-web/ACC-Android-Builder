-- LOST & FOUND: NIGHT SHIFT — M6-C live-service state authority.
-- Replicates approved event state only. It does not change drops, economy, cases,
-- station ownership, collection minting, or environment dressing by itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local LiveServiceEventRegistry = require(shared:WaitForChild("LiveServiceEventRegistry"))
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local CaseRegistry = require(shared:WaitForChild("CaseRegistry"))

local LiveServiceEventService = {}

local started = false
local stateFolder = nil
local lastKey = nil
local revision = 0

local function ensureStateFolder()
    local folder = ReplicatedStorage:FindFirstChild("LostAndFoundLiveServiceState")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "LostAndFoundLiveServiceState"
        folder.Parent = ReplicatedStorage
    end
    return folder
end

local function guardedInactive(snapshot)
    return {
        active = false,
        id = tostring(snapshot.id or ""),
        name = tostring(snapshot.name or ""),
        editionToken = tostring(snapshot.editionToken or ""),
        realWorldAnchor = tostring(snapshot.realWorldAnchor or ""),
        startsAt = math.max(0, math.floor(tonumber(snapshot.startsAt) or 0)),
        endsAt = math.max(0, math.floor(tonumber(snapshot.endsAt) or 0)),
        stationSkinId = tostring(snapshot.stationSkinId or ""),
        environmentProfile = tostring(snapshot.environmentProfile or ""),
    }
end

local function validateEventConfiguration(event)
    if not event then
        return false, "EVENT_NOT_REGISTERED"
    end

    local eventId = tostring(event.id or "")
    if eventId == "" then
        return false, "EVENT_ID_MISSING"
    end

    local editionToken = tostring(event.editionToken or "")
    if editionToken == "" then
        return false, "EDITION_MISSING"
    end

    local pool = type(event.collectionPool) == "table" and event.collectionPool or {}
    if #pool == 0 then
        return false, "COLLECTION_POOL_EMPTY"
    end

    local poolSet = {}
    for _, collectionId in ipairs(pool) do
        poolSet[collectionId] = true
        local entry = CollectionRegistry.Get(collectionId)
        if not entry then
            return false, "COLLECTIBLE_MISSING:" .. tostring(collectionId)
        end
        if entry.eventId ~= eventId or tostring(entry.edition or "") ~= editionToken then
            return false, "COLLECTIBLE_METADATA_MISMATCH:" .. tostring(collectionId)
        end
        if entry.dropEnabled ~= true then
            return false, "COLLECTIBLE_DROP_LOCKED:" .. tostring(collectionId)
        end
        local chance = tonumber(entry.dropChance)
        if not chance or chance <= 0 or chance > 1 then
            return false, "COLLECTIBLE_DROP_UNAPPROVED:" .. tostring(collectionId)
        end
    end

    local hooks = type(event.caseHookIds) == "table" and event.caseHookIds or {}
    if #hooks == 0 then
        return false, "CASE_HOOKS_EMPTY"
    end

    local registeredCases = {}
    for _, caseData in ipairs(CaseRegistry.GetEventCases(eventId, false)) do
        registeredCases[caseData.id] = caseData
    end

    for _, caseId in ipairs(hooks) do
        local caseData = registeredCases[caseId]
        if not caseData then
            return false, "CASE_MISSING:" .. tostring(caseId)
        end
        if caseData.eventId ~= eventId then
            return false, "CASE_EVENT_MISMATCH:" .. tostring(caseId)
        end
        local weight = tonumber(caseData.selectionWeight)
        if not weight or weight <= 0 then
            return false, "CASE_WEIGHT_UNAPPROVED:" .. tostring(caseId)
        end
        if caseData.dropEnabled ~= true then
            return false, "CASE_DROP_LOCKED:" .. tostring(caseId)
        end
        if caseData.collectionId and not poolSet[caseData.collectionId] then
            return false, "CASE_COLLECTION_OUTSIDE_POOL:" .. tostring(caseId)
        end
        if caseData.bonusCollectionId and not poolSet[caseData.bonusCollectionId] then
            return false, "CASE_BONUS_OUTSIDE_POOL:" .. tostring(caseId)
        end
    end

    return true, "READY"
end

local function auditPreparedEvent()
    for _, eventId in ipairs(LiveServiceEventRegistry.Order or {}) do
        local event = LiveServiceEventRegistry.Get(eventId)
        local pool = event and event.collectionPool
        local hooks = event and event.caseHookIds
        if event and ((type(pool) == "table" and #pool > 0) or (type(hooks) == "table" and #hooks > 0)) then
            local ready, reason = validateEventConfiguration(event)
            return event.id, ready, reason
        end
    end

    return "", false, "NO_PREPARED_EVENT"
end

local function validateActivation(snapshot)
    if snapshot.active ~= true then
        return snapshot, false, "EVENT_INACTIVE"
    end

    local event = LiveServiceEventRegistry.Get(snapshot.id)
    local ready, reason = validateEventConfiguration(event)
    if not ready then
        return guardedInactive(snapshot), false, reason
    end

    if tostring(event.editionToken or "") ~= tostring(snapshot.editionToken or "") then
        return guardedInactive(snapshot), false, "EDITION_MISMATCH"
    end

    return snapshot, true, "READY"
end

local function snapshotKey(snapshot, activationReady, guardReason, preparedEventId, preparedReady, preparedReason)
    return table.concat({
        snapshot.active and "1" or "0",
        tostring(snapshot.id or ""),
        tostring(snapshot.editionToken or ""),
        tostring(snapshot.startsAt or 0),
        tostring(snapshot.endsAt or 0),
        tostring(snapshot.stationSkinId or ""),
        tostring(snapshot.environmentProfile or ""),
        activationReady and "1" or "0",
        tostring(guardReason or ""),
        tostring(preparedEventId or ""),
        preparedReady and "1" or "0",
        tostring(preparedReason or ""),
    }, "|")
end

local function applySnapshot(snapshot, activationReady, guardReason, preparedEventId, preparedReady, preparedReason)
    stateFolder = stateFolder or ensureStateFolder()

    local key = snapshotKey(snapshot, activationReady, guardReason, preparedEventId, preparedReady, preparedReason)
    if key ~= lastKey then
        lastKey = key
        revision += 1
    end

    stateFolder:SetAttribute("Active", snapshot.active == true)
    stateFolder:SetAttribute("ActivationReady", activationReady == true)
    stateFolder:SetAttribute("GuardReason", tostring(guardReason or ""))
    stateFolder:SetAttribute("PreparedEventId", tostring(preparedEventId or ""))
    stateFolder:SetAttribute("PreparedReady", preparedReady == true)
    stateFolder:SetAttribute("PreparedGuardReason", tostring(preparedReason or ""))
    stateFolder:SetAttribute("EventId", tostring(snapshot.id or ""))
    stateFolder:SetAttribute("EventName", tostring(snapshot.name or ""))
    stateFolder:SetAttribute("EditionToken", tostring(snapshot.editionToken or ""))
    stateFolder:SetAttribute("RealWorldAnchor", tostring(snapshot.realWorldAnchor or ""))
    stateFolder:SetAttribute("StartsAt", math.max(0, math.floor(tonumber(snapshot.startsAt) or 0)))
    stateFolder:SetAttribute("EndsAt", math.max(0, math.floor(tonumber(snapshot.endsAt) or 0)))
    stateFolder:SetAttribute("StationSkinId", tostring(snapshot.stationSkinId or ""))
    stateFolder:SetAttribute("EnvironmentProfile", tostring(snapshot.environmentProfile or ""))
    stateFolder:SetAttribute("Revision", revision)
end

function LiveServiceEventService.Audit(eventId)
    local event = LiveServiceEventRegistry.Get(eventId)
    return validateEventConfiguration(event)
end

function LiveServiceEventService.Refresh(now)
    local proposed = LiveServiceEventRegistry.PublicSnapshot(now)
    local snapshot, activationReady, guardReason = validateActivation(proposed)
    local preparedEventId, preparedReady, preparedReason = auditPreparedEvent()
    applySnapshot(snapshot, activationReady, guardReason, preparedEventId, preparedReady, preparedReason)
    return snapshot, activationReady, guardReason
end

function LiveServiceEventService.Start()
    if started then return stateFolder end
    started = true

    stateFolder = ensureStateFolder()
    LiveServiceEventService.Refresh(os.time())

    task.spawn(function()
        while started do
            task.wait(math.max(30, tonumber(LiveServiceEventRegistry.PollSeconds) or 60))
            LiveServiceEventService.Refresh(os.time())
        end
    end)

    return stateFolder
end

return LiveServiceEventService
