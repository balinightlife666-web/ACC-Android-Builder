local StationSkinRegistry = {}

local function skin(id, name, acquisition, priceCredits, palette)
    return {
        id = id,
        name = name,
        acquisition = acquisition,
        priceCredits = priceCredits,
        palette = palette,
    }
end

StationSkinRegistry.Order = {
    "STANDARD_OPS",
    "INDUSTRIAL_SHIFT",
    "RETRO_AIRPORT",
    "BLACK_OPS",
    "LUXURY_EXECUTIVE",
    "HALLOWEEN_2026",
    "CHRISTMAS_2026",
}

StationSkinRegistry.Skins = {
    STANDARD_OPS = skin("STANDARD_OPS", "Standard Ops", "FREE", 0, {
        base = Color3.fromRGB(31, 37, 46),
        panel = Color3.fromRGB(20, 25, 33),
        accent = Color3.fromRGB(214, 151, 55),
        trim = Color3.fromRGB(90, 104, 122),
        light = Color3.fromRGB(220, 230, 240),
    }),
    INDUSTRIAL_SHIFT = skin("INDUSTRIAL_SHIFT", "Industrial Shift", "CREDITS", 8000, {
        base = Color3.fromRGB(48, 48, 45),
        panel = Color3.fromRGB(29, 30, 29),
        accent = Color3.fromRGB(203, 126, 47),
        trim = Color3.fromRGB(104, 101, 91),
        light = Color3.fromRGB(232, 210, 176),
    }),
    RETRO_AIRPORT = skin("RETRO_AIRPORT", "Retro Airport", "CREDITS", 18000, {
        base = Color3.fromRGB(53, 61, 64),
        panel = Color3.fromRGB(39, 48, 49),
        accent = Color3.fromRGB(81, 181, 174),
        trim = Color3.fromRGB(194, 172, 119),
        light = Color3.fromRGB(230, 229, 204),
    }),
    BLACK_OPS = skin("BLACK_OPS", "Black Ops", "CREDITS", 35000, {
        base = Color3.fromRGB(20, 22, 25),
        panel = Color3.fromRGB(11, 13, 16),
        accent = Color3.fromRGB(190, 49, 54),
        trim = Color3.fromRGB(72, 78, 86),
        light = Color3.fromRGB(196, 205, 216),
    }),
    LUXURY_EXECUTIVE = skin("LUXURY_EXECUTIVE", "Luxury Executive", "ROBUX", nil, {
        base = Color3.fromRGB(37, 32, 28),
        panel = Color3.fromRGB(21, 19, 18),
        accent = Color3.fromRGB(205, 166, 81),
        trim = Color3.fromRGB(133, 119, 94),
        light = Color3.fromRGB(255, 230, 181),
    }),
    HALLOWEEN_2026 = skin("HALLOWEEN_2026", "Halloween 2026", "EVENT", nil, {
        base = Color3.fromRGB(38, 27, 42),
        panel = Color3.fromRGB(23, 17, 27),
        accent = Color3.fromRGB(224, 112, 42),
        trim = Color3.fromRGB(102, 73, 113),
        light = Color3.fromRGB(243, 165, 83),
    }),
    CHRISTMAS_2026 = skin("CHRISTMAS_2026", "Christmas 2026", "EVENT", nil, {
        base = Color3.fromRGB(30, 45, 40),
        panel = Color3.fromRGB(20, 30, 27),
        accent = Color3.fromRGB(184, 54, 57),
        trim = Color3.fromRGB(177, 154, 103),
        light = Color3.fromRGB(239, 229, 205),
    }),
}

function StationSkinRegistry.Get(id)
    return StationSkinRegistry.Skins[id] or StationSkinRegistry.Skins.STANDARD_OPS
end

function StationSkinRegistry.PublicEntries()
    local result = {}
    for _, id in ipairs(StationSkinRegistry.Order) do
        local entry = StationSkinRegistry.Skins[id]
        table.insert(result, {
            id = entry.id,
            name = entry.name,
            acquisition = entry.acquisition,
            priceCredits = entry.priceCredits,
        })
    end
    return result
end

return StationSkinRegistry
