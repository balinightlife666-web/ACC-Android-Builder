local CollectionRegistry = {}

CollectionRegistry.Order = {
    "blue_transit_hardcase",
    "crimson_travel_backpack",
    "cream_memory_bear",
    "brown_heritage_case",
    "black_security_hardcase",
    "ownerless_vintage_case",
    "flight_000_hardcase",
    "unstable_sealed_parcel",
    "green_identity_backpack",
    "milo_small_case",
    "silver_camera_lens",
    "ownerless_tag_00017284",
    "flight_000_boarding_tag",
    "duplicate_passport",
    "milo_toy_train_2001",
    "maya_power_adapter",
    "daniel_formal_shoe",
    "sofia_name_patch",
    "ari_red_paperback",
    "unstable_mass_readout",
}

local function item(id, baseItemId, name, rarity, serialPrefix, edition, eventId)
    return {
        id = id,
        baseItemId = baseItemId,
        name = name,
        rarity = rarity,
        serialPrefix = serialPrefix,
        edition = edition or "S1",
        eventId = eventId,
        tradeable = true,
    }
end

CollectionRegistry.Items = {
    blue_transit_hardcase = item("blue_transit_hardcase", "hardcase_suitcase", "Blue Transit Hardcase", "COMMON", "BTH"),
    crimson_travel_backpack = item("crimson_travel_backpack", "backpack", "Crimson Travel Backpack", "UNCOMMON", "CTB"),
    cream_memory_bear = item("cream_memory_bear", "teddy_bear", "Cream Memory Bear", "RARE", "CMB"),
    brown_heritage_case = item("brown_heritage_case", "vintage_suitcase", "Brown Heritage Case", "UNCOMMON", "BHC"),
    black_security_hardcase = item("black_security_hardcase", "hardcase_suitcase", "Black Security Hardcase", "RARE", "BSH"),
    ownerless_vintage_case = item("ownerless_vintage_case", "vintage_suitcase", "Ownerless Vintage Case", "ANOMALY", "OVC"),
    flight_000_hardcase = item("flight_000_hardcase", "hardcase_suitcase", "Flight 000 Hardcase", "SECRET", "F0H"),
    unstable_sealed_parcel = item("unstable_sealed_parcel", "cardboard_box", "Unstable Sealed Parcel", "ANOMALY", "USP"),
    green_identity_backpack = item("green_identity_backpack", "backpack", "Green Identity Backpack", "EPIC", "GIB"),
    milo_small_case = item("milo_small_case", "vintage_suitcase", "Milo's Small Case", "SECRET", "MSC"),
    silver_camera_lens = item("silver_camera_lens", "camera_lens", "Silver Camera Lens", "RARE", "SCL"),
    ownerless_tag_00017284 = item("ownerless_tag_00017284", "evidence_tag", "Ownerless Tag 000-17284", "ANOMALY", "OT0"),
    flight_000_boarding_tag = item("flight_000_boarding_tag", "evidence_tag", "Flight 000 Boarding Tag", "SECRET", "F0T"),
    duplicate_passport = item("duplicate_passport", "passport", "Duplicate Passport", "EPIC", "DPP"),
    milo_toy_train_2001 = item("milo_toy_train_2001", "toy_train", "Milo's Toy Train", "SECRET", "MTT"),
    maya_power_adapter = item("maya_power_adapter", "power_adapter", "Maya's Power Adapter", "UNCOMMON", "MPA"),
    daniel_formal_shoe = item("daniel_formal_shoe", "formal_shoe", "Daniel's Formal Shoe", "RARE", "DFS"),
    sofia_name_patch = item("sofia_name_patch", "name_patch", "Sofia's Stitched Patch", "RARE", "SNP"),
    ari_red_paperback = item("ari_red_paperback", "paperback", "Ari's Red Paperback", "UNCOMMON", "ARP"),
    unstable_mass_readout = item("unstable_mass_readout", "mass_readout", "Unstable Mass Readout", "ANOMALY", "UMR"),
}

CollectionRegistry.SeasonalOrder = {}

local function cloneEntry(entry)
    return {
        id = entry.id,
        baseItemId = entry.baseItemId,
        name = entry.name,
        rarity = entry.rarity,
        serialPrefix = entry.serialPrefix,
        edition = entry.edition or "S1",
        eventId = entry.eventId,
        tradeable = entry.tradeable ~= false,
        dropEnabled = entry.dropEnabled ~= false,
        dropChance = entry.dropChance,
        mintCap = entry.mintCap,
    }
end

function CollectionRegistry.RegisterSeasonal(entry)
    if type(entry) ~= "table" or type(entry.id) ~= "string" or entry.id == "" then
        return false, "INVALID_ENTRY"
    end
    if CollectionRegistry.Items[entry.id] then
        return false, "DUPLICATE_ID"
    end

    CollectionRegistry.Items[entry.id] = cloneEntry(entry)
    table.insert(CollectionRegistry.SeasonalOrder, entry.id)
    return true
end

function CollectionRegistry.VisibleOrder(activeEventId, discovered, ownedCounts)
    discovered = type(discovered) == "table" and discovered or {}
    ownedCounts = type(ownedCounts) == "table" and ownedCounts or {}

    local result = {}
    for _, collectionId in ipairs(CollectionRegistry.Order) do
        table.insert(result, collectionId)
    end

    for _, collectionId in ipairs(CollectionRegistry.SeasonalOrder) do
        local entry = CollectionRegistry.Items[collectionId]
        local visible = entry
            and (
                (activeEventId ~= nil and activeEventId ~= "" and entry.eventId == activeEventId)
                or discovered[collectionId] == true
                or (tonumber(ownedCounts[collectionId]) or 0) > 0
            )
        if visible then table.insert(result, collectionId) end
    end

    return result
end

function CollectionRegistry.Get(collectionId)
    return CollectionRegistry.Items[collectionId]
end

function CollectionRegistry.Count(order)
    return #(order or CollectionRegistry.Order)
end

function CollectionRegistry.PublicEntries(order)
    local entries = {}
    for _, collectionId in ipairs(order or CollectionRegistry.Order) do
        local entry = CollectionRegistry.Items[collectionId]
        if entry then
            table.insert(entries, {
                id = entry.id,
                baseItemId = entry.baseItemId,
                name = entry.name,
                rarity = entry.rarity,
                serialPrefix = entry.serialPrefix,
                edition = entry.edition,
                eventId = entry.eventId,
                tradeable = entry.tradeable,
                dropEnabled = entry.dropEnabled,
            })
        end
    end
    return entries
end

return CollectionRegistry
