-- LOST & FOUND: NIGHT SHIFT — M6-C live-service event registry.
-- Foundation only. Events remain dormant until Arda approves explicit runtime windows.

local LiveServiceEventRegistry = {}

LiveServiceEventRegistry.PollSeconds = 60

LiveServiceEventRegistry.Order = {
    "HALLOWEEN_2026",
    "CHRISTMAS_2026",
}

LiveServiceEventRegistry.Events = {
    HALLOWEEN_2026 = {
        id = "HALLOWEEN_2026",
        name = "Halloween 2026",
        editionToken = "HW26",
        realWorldAnchor = "2026-10-31",
        enabled = false,
        startsAt = nil,
        endsAt = nil,
        stationSkinId = "HALLOWEEN_2026",
        environmentProfile = "HALLOWEEN",
        collectionPool = {
            "hw26_midnight_hardcase",
            "hw26_pumpkin_claim_tag",
            "hw26_black_cat_backpack",
            "hw26_cold_room_parcel",
        },
        caseHookIds = {
            "LF-HW26-001",
            "LF-HW26-002",
            "LF-HW26-003",
        },
    },
    CHRISTMAS_2026 = {
        id = "CHRISTMAS_2026",
        name = "Christmas 2026",
        editionToken = "XMAS26",
        realWorldAnchor = "2026-12-25",
        enabled = false,
        startsAt = nil,
        endsAt = nil,
        stationSkinId = "CHRISTMAS_2026",
        environmentProfile = "CHRISTMAS",
        collectionPool = {},
        caseHookIds = {},
    },
}

local function hasApprovedWindow(event)
    return event
        and event.enabled == true
        and type(event.startsAt) == "number"
        and type(event.endsAt) == "number"
        and event.startsAt > 0
        and event.endsAt > event.startsAt
end

function LiveServiceEventRegistry.Get(eventId)
    return LiveServiceEventRegistry.Events[tostring(eventId or "")]
end

function LiveServiceEventRegistry.GetActive(now)
    now = math.floor(tonumber(now) or os.time())

    for _, eventId in ipairs(LiveServiceEventRegistry.Order) do
        local event = LiveServiceEventRegistry.Events[eventId]
        if hasApprovedWindow(event) and now >= event.startsAt and now < event.endsAt then
            return event
        end
    end

    return nil
end

function LiveServiceEventRegistry.PublicSnapshot(now)
    local event = LiveServiceEventRegistry.GetActive(now)
    if not event then
        return {
            active = false,
            id = "",
            name = "",
            editionToken = "",
            realWorldAnchor = "",
            startsAt = 0,
            endsAt = 0,
            stationSkinId = "",
            environmentProfile = "",
        }
    end

    return {
        active = true,
        id = event.id,
        name = event.name,
        editionToken = event.editionToken,
        realWorldAnchor = event.realWorldAnchor,
        startsAt = event.startsAt,
        endsAt = event.endsAt,
        stationSkinId = event.stationSkinId,
        environmentProfile = event.environmentProfile,
    }
end

return LiveServiceEventRegistry
