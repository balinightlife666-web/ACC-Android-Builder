-- LOST & FOUND: NIGHT SHIFT — M6-C live-service state authority.
-- Replicates approved event state only. It does not change drops, economy, cases,
-- station ownership, collection minting, or environment dressing by itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local LiveServiceEventRegistry = require(shared:WaitForChild("LiveServiceEventRegistry"))

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

local function snapshotKey(snapshot)
    return table.concat({
        snapshot.active and "1" or "0",
        tostring(snapshot.id or ""),
        tostring(snapshot.editionToken or ""),
        tostring(snapshot.startsAt or 0),
        tostring(snapshot.endsAt or 0),
        tostring(snapshot.stationSkinId or ""),
        tostring(snapshot.environmentProfile or ""),
    }, "|")
end

local function applySnapshot(snapshot)
    stateFolder = stateFolder or ensureStateFolder()

    local key = snapshotKey(snapshot)
    if key ~= lastKey then
        lastKey = key
        revision += 1
    end

    stateFolder:SetAttribute("Active", snapshot.active == true)
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

function LiveServiceEventService.Refresh(now)
    local snapshot = LiveServiceEventRegistry.PublicSnapshot(now)
    applySnapshot(snapshot)
    return snapshot
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
