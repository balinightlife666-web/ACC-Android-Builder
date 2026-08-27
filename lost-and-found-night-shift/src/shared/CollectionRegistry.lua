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

CollectionRegistry.Items = {
    blue_transit_hardcase = { id = "blue_transit_hardcase", baseItemId = "hardcase_suitcase", name = "Blue Transit Hardcase", rarity = "COMMON" },
    crimson_travel_backpack = { id = "crimson_travel_backpack", baseItemId = "backpack", name = "Crimson Travel Backpack", rarity = "UNCOMMON" },
    cream_memory_bear = { id = "cream_memory_bear", baseItemId = "teddy_bear", name = "Cream Memory Bear", rarity = "RARE" },
    brown_heritage_case = { id = "brown_heritage_case", baseItemId = "vintage_suitcase", name = "Brown Heritage Case", rarity = "UNCOMMON" },
    black_security_hardcase = { id = "black_security_hardcase", baseItemId = "hardcase_suitcase", name = "Black Security Hardcase", rarity = "RARE" },
    ownerless_vintage_case = { id = "ownerless_vintage_case", baseItemId = "vintage_suitcase", name = "Ownerless Vintage Case", rarity = "ANOMALY" },
    flight_000_hardcase = { id = "flight_000_hardcase", baseItemId = "hardcase_suitcase", name = "Flight 000 Hardcase", rarity = "SECRET" },
    unstable_sealed_parcel = { id = "unstable_sealed_parcel", baseItemId = "cardboard_box", name = "Unstable Sealed Parcel", rarity = "ANOMALY" },
    green_identity_backpack = { id = "green_identity_backpack", baseItemId = "backpack", name = "Green Identity Backpack", rarity = "EPIC" },
    milo_small_case = { id = "milo_small_case", baseItemId = "vintage_suitcase", name = "Milo's Small Case", rarity = "SECRET" },
    silver_camera_lens = { id = "silver_camera_lens", baseItemId = "camera_lens", name = "Silver Camera Lens", rarity = "RARE" },
    ownerless_tag_00017284 = { id = "ownerless_tag_00017284", baseItemId = "evidence_tag", name = "Ownerless Tag 000-17284", rarity = "ANOMALY" },
    flight_000_boarding_tag = { id = "flight_000_boarding_tag", baseItemId = "evidence_tag", name = "Flight 000 Boarding Tag", rarity = "SECRET" },
    duplicate_passport = { id = "duplicate_passport", baseItemId = "passport", name = "Duplicate Passport", rarity = "EPIC" },
    milo_toy_train_2001 = { id = "milo_toy_train_2001", baseItemId = "toy_train", name = "Milo's Toy Train", rarity = "SECRET" },
    maya_power_adapter = { id = "maya_power_adapter", baseItemId = "power_adapter", name = "Maya's Power Adapter", rarity = "UNCOMMON" },
    daniel_formal_shoe = { id = "daniel_formal_shoe", baseItemId = "formal_shoe", name = "Daniel's Formal Shoe", rarity = "RARE" },
    sofia_name_patch = { id = "sofia_name_patch", baseItemId = "name_patch", name = "Sofia's Stitched Patch", rarity = "RARE" },
    ari_red_paperback = { id = "ari_red_paperback", baseItemId = "paperback", name = "Ari's Red Paperback", rarity = "UNCOMMON" },
    unstable_mass_readout = { id = "unstable_mass_readout", baseItemId = "mass_readout", name = "Unstable Mass Readout", rarity = "ANOMALY" },
}

function CollectionRegistry.Get(collectionId)
    return CollectionRegistry.Items[collectionId]
end

function CollectionRegistry.Count()
    return #CollectionRegistry.Order
end

function CollectionRegistry.PublicEntries()
    local entries = {}
    for _, collectionId in ipairs(CollectionRegistry.Order) do
        local item = CollectionRegistry.Items[collectionId]
        table.insert(entries, {
            id = item.id,
            baseItemId = item.baseItemId,
            name = item.name,
            rarity = item.rarity,
        })
    end
    return entries
end

return CollectionRegistry
