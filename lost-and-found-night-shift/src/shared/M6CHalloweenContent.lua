-- LOST & FOUND: NIGHT SHIFT — M6-C Halloween 2026 content definitions.
-- Content is intentionally dormant. No runtime registration/drop occurs from this module alone.

local M6CHalloweenContent = {}

M6CHalloweenContent.EventId = "HALLOWEEN_2026"
M6CHalloweenContent.EditionToken = "HW26"

-- Exact mint caps and seasonal drop chances remain unapproved.
-- dropEnabled=false is a hard safety default until economy review.
M6CHalloweenContent.Collectibles = {
    {
        id = "hw26_midnight_hardcase",
        baseItemId = "hardcase_suitcase",
        name = "Midnight Check-In Hardcase",
        rarity = "RARE",
        serialPrefix = "MCH",
        edition = "HW26",
        eventId = "HALLOWEEN_2026",
        tradeable = true,
        dropEnabled = false,
        mintCap = nil,
        visual = {
            base = "hardcase_suitcase",
            color = Color3.fromRGB(34, 27, 43),
            accent = Color3.fromRGB(224, 112, 42),
        },
    },
    {
        id = "hw26_pumpkin_claim_tag",
        baseItemId = "evidence_tag",
        name = "Pumpkin Claim Tag",
        rarity = "EPIC",
        serialPrefix = "PCT",
        edition = "HW26",
        eventId = "HALLOWEEN_2026",
        tradeable = true,
        dropEnabled = false,
        mintCap = nil,
        visual = {
            base = "evidence_tag",
            color = Color3.fromRGB(116, 74, 45),
            accent = Color3.fromRGB(239, 136, 52),
        },
    },
    {
        id = "hw26_black_cat_backpack",
        baseItemId = "backpack",
        name = "Black Cat Transit Backpack",
        rarity = "EPIC",
        serialPrefix = "BCT",
        edition = "HW26",
        eventId = "HALLOWEEN_2026",
        tradeable = true,
        dropEnabled = false,
        mintCap = nil,
        visual = {
            base = "backpack",
            color = Color3.fromRGB(30, 30, 35),
            accent = Color3.fromRGB(150, 92, 174),
        },
    },
    {
        id = "hw26_cold_room_parcel",
        baseItemId = "cardboard_box",
        name = "Cold Room Parcel",
        rarity = "ANOMALY",
        serialPrefix = "CRP",
        edition = "HW26",
        eventId = "HALLOWEEN_2026",
        tradeable = true,
        dropEnabled = false,
        mintCap = nil,
        visual = {
            base = "cardboard_box",
            color = Color3.fromRGB(111, 78, 58),
            accent = Color3.fromRGB(108, 202, 214),
        },
    },
}

-- First Halloween gameplay hook. It is self-contained seasonal fiction and does not
-- explain or rewrite Flight 000, Ownerless Suitcase, or The Lost Child.
M6CHalloweenContent.Cases = {
    {
        id = "LF-HW26-001",
        title = "Cold Room Parcel",
        caseType = "event",
        eventId = "HALLOWEEN_2026",
        itemId = "cardboard_box",
        collectionId = "hw26_cold_room_parcel",
        bonusCollectionId = "hw26_pumpkin_claim_tag",
        itemName = "Cold Room Parcel",
        itemColor = Color3.fromRGB(111, 78, 58),
        owner = "Lena Voss",
        claimantName = "Lena Voss",
        claimantKind = "Adult",
        tagNumber = "HW-1031-26",
        claimantTag = "HW-1031-26",
        flight = "TR-431",
        weight = "4.6 kg",
        contents = "Costume fabric, sealed candy tin, paper lantern",
        scanStatus = "OWNER RECORD FOUND / TEMPERATURE SENSOR OUTLIER",
        anomaly = "The parcel interior remains far colder than the inspection room. A sealed tin produces repeated tapping after the parcel stops moving.",
        correctDecision = "QUARANTINE",
        questionableDecisions = { "SECURITY" },
        resolution = "RESOLVED",
        risk = "high",
        reason = "The claimant and tag match, but unexplained physical behavior makes normal release unsafe. Isolate the property for anomaly review.",
        seasonal = true,
        selectionWeight = nil,
        dropEnabled = false,
    },
}

function M6CHalloweenContent.CollectionIds()
    local ids = {}
    for _, entry in ipairs(M6CHalloweenContent.Collectibles) do
        table.insert(ids, entry.id)
    end
    return ids
end

function M6CHalloweenContent.CaseIds()
    local ids = {}
    for _, entry in ipairs(M6CHalloweenContent.Cases) do
        table.insert(ids, entry.id)
    end
    return ids
end

return M6CHalloweenContent
