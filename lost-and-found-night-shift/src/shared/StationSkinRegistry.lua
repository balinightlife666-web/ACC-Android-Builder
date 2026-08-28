local StationSkinRegistry = {}

local function skin(id, name, acquisition, priceCredits, palette, theme)
    return {
        id = id,
        name = name,
        acquisition = acquisition,
        priceCredits = priceCredits,
        palette = palette,
        theme = theme or { kind = "PALETTE" },
    }
end

StationSkinRegistry.Order = {
    "STANDARD_OPS",
    "INDUSTRIAL_SHIFT",
    "RETRO_AIRPORT",
    "BLACK_OPS",
    "ARMY_FIELD",
    "SAKURA_NIGHT",
    "STREET_GRAFFITI",
    "LUXURY_EXECUTIVE",
    "HALLOWEEN_2026",
    "CHRISTMAS_2026",
}

StationSkinRegistry.Skins = {
    -- M5-A.3: simple palette swaps are free. Paid cosmetics must be full themes.
    STANDARD_OPS = skin("STANDARD_OPS", "Standard Ops", "FREE", 0, {
        base = Color3.fromRGB(40, 48, 59),
        panel = Color3.fromRGB(28, 35, 45),
        accent = Color3.fromRGB(224, 163, 64),
        trim = Color3.fromRGB(108, 122, 141),
        light = Color3.fromRGB(232, 239, 248),
    }, {
        kind = "PALETTE",
        label = "Default operations palette",
    }),
    INDUSTRIAL_SHIFT = skin("INDUSTRIAL_SHIFT", "Industrial Shift", "FREE", 0, {
        base = Color3.fromRGB(48, 48, 45),
        panel = Color3.fromRGB(29, 30, 29),
        accent = Color3.fromRGB(203, 126, 47),
        trim = Color3.fromRGB(104, 101, 91),
        light = Color3.fromRGB(232, 210, 176),
    }, {
        kind = "PALETTE",
        label = "Warm industrial palette",
    }),
    RETRO_AIRPORT = skin("RETRO_AIRPORT", "Retro Airport", "FREE", 0, {
        base = Color3.fromRGB(53, 61, 64),
        panel = Color3.fromRGB(39, 48, 49),
        accent = Color3.fromRGB(81, 181, 174),
        trim = Color3.fromRGB(194, 172, 119),
        light = Color3.fromRGB(230, 229, 204),
    }, {
        kind = "PALETTE",
        label = "Retro terminal palette",
    }),
    BLACK_OPS = skin("BLACK_OPS", "Black Ops", "FREE", 0, {
        base = Color3.fromRGB(20, 22, 25),
        panel = Color3.fromRGB(11, 13, 16),
        accent = Color3.fromRGB(190, 49, 54),
        trim = Color3.fromRGB(72, 78, 86),
        light = Color3.fromRGB(196, 205, 216),
    }, {
        kind = "PALETTE",
        label = "Dark operations palette",
    }),

    ARMY_FIELD = skin("ARMY_FIELD", "Army Field", "CREDITS", 12000, {
        base = Color3.fromRGB(61, 67, 48),
        panel = Color3.fromRGB(37, 43, 31),
        accent = Color3.fromRGB(177, 151, 76),
        trim = Color3.fromRGB(105, 104, 76),
        light = Color3.fromRGB(211, 201, 152),
    }, {
        kind = "ARMY",
        label = "Full military field theme",
        materialByRole = {
            base = "DiamondPlate",
            panel = "Metal",
            trim = "Metal",
        },
        lightMultiplier = 0.86,
    }),
    SAKURA_NIGHT = skin("SAKURA_NIGHT", "Sakura Night", "CREDITS", 16000, {
        base = Color3.fromRGB(48, 41, 49),
        panel = Color3.fromRGB(27, 23, 31),
        accent = Color3.fromRGB(238, 139, 174),
        trim = Color3.fromRGB(148, 105, 130),
        light = Color3.fromRGB(255, 199, 219),
    }, {
        kind = "SAKURA",
        label = "Full sakura night theme",
        materialByRole = {
            base = "SmoothPlastic",
            panel = "SmoothPlastic",
            trim = "WoodPlanks",
        },
        lightMultiplier = 0.92,
    }),
    STREET_GRAFFITI = skin("STREET_GRAFFITI", "Street Graffiti", "CREDITS", 20000, {
        base = Color3.fromRGB(45, 46, 49),
        panel = Color3.fromRGB(30, 31, 35),
        accent = Color3.fromRGB(64, 215, 190),
        trim = Color3.fromRGB(107, 84, 142),
        light = Color3.fromRGB(127, 238, 218),
    }, {
        kind = "STREET",
        label = "Full urban graffiti theme",
        materialByRole = {
            base = "Concrete",
            panel = "Concrete",
            trim = "Metal",
        },
        lightMultiplier = 1.03,
    }),

    -- Deferred premium/event catalog. Not exposed by Station Shop v1 yet.
    LUXURY_EXECUTIVE = skin("LUXURY_EXECUTIVE", "Luxury Executive", "ROBUX", nil, {
        base = Color3.fromRGB(37, 32, 28),
        panel = Color3.fromRGB(21, 19, 18),
        accent = Color3.fromRGB(205, 166, 81),
        trim = Color3.fromRGB(133, 119, 94),
        light = Color3.fromRGB(255, 230, 181),
    }, { kind = "LUXURY" }),
    HALLOWEEN_2026 = skin("HALLOWEEN_2026", "Halloween 2026", "EVENT", nil, {
        base = Color3.fromRGB(38, 27, 42),
        panel = Color3.fromRGB(23, 17, 27),
        accent = Color3.fromRGB(224, 112, 42),
        trim = Color3.fromRGB(102, 73, 113),
        light = Color3.fromRGB(243, 165, 83),
    }, { kind = "HALLOWEEN" }),
    CHRISTMAS_2026 = skin("CHRISTMAS_2026", "Christmas 2026", "EVENT", nil, {
        base = Color3.fromRGB(30, 45, 40),
        panel = Color3.fromRGB(20, 30, 27),
        accent = Color3.fromRGB(184, 54, 57),
        trim = Color3.fromRGB(177, 154, 103),
        light = Color3.fromRGB(239, 229, 205),
    }, { kind = "CHRISTMAS" }),
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
            themeKind = entry.theme and entry.theme.kind or "PALETTE",
            themeLabel = entry.theme and entry.theme.label or nil,
        })
    end
    return result
end

return StationSkinRegistry