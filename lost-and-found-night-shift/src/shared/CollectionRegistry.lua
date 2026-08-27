local CollectionRegistry = {}

CollectionRegistry.Order = {
    "hardcase_suitcase",
    "vintage_suitcase",
    "backpack",
    "cardboard_box",
    "teddy_bear",
}

CollectionRegistry.Items = {
    hardcase_suitcase = {
        id = "hardcase_suitcase",
        name = "Hardcase Suitcase",
        rarity = "COMMON",
    },
    vintage_suitcase = {
        id = "vintage_suitcase",
        name = "Vintage Suitcase",
        rarity = "UNCOMMON",
    },
    backpack = {
        id = "backpack",
        name = "Travel Backpack",
        rarity = "COMMON",
    },
    cardboard_box = {
        id = "cardboard_box",
        name = "Cardboard Parcel",
        rarity = "UNCOMMON",
    },
    teddy_bear = {
        id = "teddy_bear",
        name = "Teddy Bear",
        rarity = "RARE",
    },
}

function CollectionRegistry.Get(itemId)
    return CollectionRegistry.Items[itemId]
end

function CollectionRegistry.Count()
    return #CollectionRegistry.Order
end

function CollectionRegistry.PublicEntries()
    local entries = {}
    for _, itemId in ipairs(CollectionRegistry.Order) do
        local item = CollectionRegistry.Items[itemId]
        table.insert(entries, {
            id = item.id,
            name = item.name,
            rarity = item.rarity,
        })
    end
    return entries
end

return CollectionRegistry
