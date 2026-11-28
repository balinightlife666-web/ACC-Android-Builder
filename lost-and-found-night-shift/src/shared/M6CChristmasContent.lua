-- M6-C Christmas 2026: dormant definitions, no activation authority.
local Content = {}
Content.EventId = "CHRISTMAS_2026"
Content.EditionToken = "XMAS26"
Content.Collectibles = {
    {
        id = "xmas26_noel_hardcase", baseItemId = "hardcase_suitcase", name = "Noel Transit Hardcase",
        rarity = "RARE", serialPrefix = "NTH",
        edition = "XMAS26", eventId = "CHRISTMAS_2026",
        tradeable = true, dropEnabled = false, mintCap = nil,
        visual = { base = "hardcase_suitcase", color = Color3.fromRGB(35, 81, 64), accent = Color3.fromRGB(214, 180, 102) },
    },
    {
        id = "xmas26_winter_bear", baseItemId = "teddy_bear", name = "Winter Keepsake Bear",
        rarity = "EPIC", serialPrefix = "WKB",
        edition = "XMAS26", eventId = "CHRISTMAS_2026",
        tradeable = true, dropEnabled = false, mintCap = nil,
        visual = { base = "teddy_bear", color = Color3.fromRGB(224, 211, 185), accent = Color3.fromRGB(156, 43, 48) },
    },
    {
        id = "xmas26_frost_parcel", baseItemId = "cardboard_box", name = "Frost-Sealed Parcel",
        rarity = "ANOMALY", serialPrefix = "FSP",
        edition = "XMAS26", eventId = "CHRISTMAS_2026",
        tradeable = true, dropEnabled = false, mintCap = nil,
        visual = { base = "cardboard_box", color = Color3.fromRGB(64, 103, 126), accent = Color3.fromRGB(184, 222, 230) },
    },
    {
        id = "xmas26_crimson_backpack", baseItemId = "backpack", name = "Crimson Holiday Backpack",
        rarity = "EPIC", serialPrefix = "CHB",
        edition = "XMAS26", eventId = "CHRISTMAS_2026",
        tradeable = true, dropEnabled = false, mintCap = nil,
        visual = { base = "backpack", color = Color3.fromRGB(146, 35, 49), accent = Color3.fromRGB(214, 180, 102) },
    },
}
Content.Cases = {
    {
        id = "LF-XMAS26-001", title = "The Last Holiday Check-In", caseType = "event",
        eventId = "CHRISTMAS_2026", itemId = "hardcase_suitcase",
        collectionId = "xmas26_noel_hardcase", bonusCollectionId = "xmas26_crimson_backpack",
        itemName = "Noel Transit Hardcase", itemColor = Color3.fromRGB(35, 81, 64),
        owner = "Clara Reed", claimantName = "Clara Reed", claimantKind = "Adult",
        tagNumber = "XM-2512-01", claimantTag = "XM-2512-01", flight = "TR-625",
        weight = "8.4 kg", contents = "Winter coat, wrapped scarf, red backpack", scanStatus = "OWNER RECORD FOUND / TAG MATCH",
        anomaly = "None", correctDecision = "RETURN",
        questionableDecisions = { "STORE" }, resolution = "CLOSED",
        risk = "low", reason = "The claimant, tag and contents agree. Return the verified property.",
        seasonal = true, selectionWeight = nil, dropEnabled = false,
    },
    {
        id = "LF-XMAS26-002", title = "The Unclaimed Keepsake", caseType = "event",
        eventId = "CHRISTMAS_2026", itemId = "teddy_bear",
        collectionId = "xmas26_winter_bear", bonusCollectionId = nil,
        itemName = "Winter Keepsake Bear", itemColor = Color3.fromRGB(224, 211, 185),
        owner = "Elliot Snow", claimantName = nil, claimantKind = "None",
        tagNumber = "XM-2512-02", claimantTag = "—", flight = "TR-426",
        weight = "0.8 kg", contents = "Cream teddy bear, red ribbon, blank gift card", scanStatus = "OWNER RECORD VALID / NO ACTIVE CLAIM",
        anomaly = "None", correctDecision = "STORE",
        questionableDecisions = {  }, resolution = "CLOSED",
        risk = "low", reason = "Normal unclaimed property belongs in storage until a verified claim arrives.",
        seasonal = true, selectionWeight = nil, dropEnabled = false,
    },
    {
        id = "LF-XMAS26-003", title = "The Frost-Sealed Parcel", caseType = "event",
        eventId = "CHRISTMAS_2026", itemId = "cardboard_box",
        collectionId = "xmas26_frost_parcel", bonusCollectionId = nil,
        itemName = "Frost-Sealed Parcel", itemColor = Color3.fromRGB(64, 103, 126),
        owner = "Nora Vale", claimantName = "Nora Vale", claimantKind = "Adult",
        tagNumber = "XM-2512-03", claimantTag = "XM-2512-03", flight = "TR-825",
        weight = "3.2 kg", contents = "Wrapped tin, wool gloves, sealed paper envelope", scanStatus = "OWNER RECORD FOUND / TEMPERATURE OUTLIER",
        anomaly = "Frost reforms on the sealed tin at room temperature immediately after being wiped away.", correctDecision = "QUARANTINE",
        questionableDecisions = { "SECURITY" }, resolution = "RESOLVED",
        risk = "high", reason = "Matching ownership does not override unexplained physical behavior. Isolate the parcel for review.",
        seasonal = true, selectionWeight = nil, dropEnabled = false,
    },
}
return Content
