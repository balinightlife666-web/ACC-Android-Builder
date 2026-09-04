-- LOST & FOUND: NIGHT SHIFT — M6-B Unlock & Career Tiers
-- Single authority for level-gated career rewards. XP thresholds remain owned by ShiftProgressionConfig.
-- Cosmetic/prestige only: no Credits values, reward values, drop rarity, serial, trade, case or canon mutation.

local CareerUnlockConfig = {}

CareerUnlockConfig.Version = "M6B_UNLOCK_CAREER_V1"

CareerUnlockConfig.Levels = {
    { level = 1,  tier = "ORIENTASI",          rewardKey = "CORE_SHIFT",              rewardLabel = "Akses shift inti" },
    { level = 2,  tier = "OPERASIONAL",        rewardKey = "STATION_INDUSTRIAL",      rewardLabel = "Skin Industrial Shift", stationSkin = "INDUSTRIAL_SHIFT" },
    { level = 3,  tier = "OPERASIONAL",        rewardKey = "STATION_RETRO",           rewardLabel = "Skin Retro Airport", stationSkin = "RETRO_AIRPORT" },
    { level = 4,  tier = "SENIOR",             rewardKey = "STATION_BLACK_OPS",       rewardLabel = "Skin Black Ops", stationSkin = "BLACK_OPS" },
    { level = 5,  tier = "SENIOR",             rewardKey = "THEME_ARMY",              rewardLabel = "Akses pembelian Army Field", stationSkin = "ARMY_FIELD" },
    { level = 6,  tier = "SPESIALIS MALAM",    rewardKey = "BADGE_NIGHT_SUPERVISOR", rewardLabel = "Badge karier Pengawas Malam" },
    { level = 7,  tier = "SPESIALIS MALAM",    rewardKey = "THEME_SAKURA",            rewardLabel = "Akses pembelian Sakura Night", stationSkin = "SAKURA_NIGHT" },
    { level = 8,  tier = "SPESIALIS MALAM",    rewardKey = "ARCHIVE_PRESTIGE",        rewardLabel = "Bingkai prestise Arsip" },
    { level = 9,  tier = "KOMANDO SHIFT",      rewardKey = "THEME_STREET",            rewardLabel = "Akses pembelian Street Graffiti", stationSkin = "STREET_GRAFFITI" },
    { level = 10, tier = "MASTER NIGHT SHIFT", rewardKey = "MASTER_CREST",            rewardLabel = "Crest Master Night Shift" },
}

CareerUnlockConfig.AllUnlockKeys = {}
CareerUnlockConfig.SkinRequiredLevel = {
    STANDARD_OPS = 1,
}

for _, entry in ipairs(CareerUnlockConfig.Levels) do
    table.insert(CareerUnlockConfig.AllUnlockKeys, entry.rewardKey)
    if entry.stationSkin then
        CareerUnlockConfig.SkinRequiredLevel[entry.stationSkin] = entry.level
    end
end

function CareerUnlockConfig.GetForLevel(rawLevel)
    local level = math.clamp(math.floor(tonumber(rawLevel) or 1), 1, #CareerUnlockConfig.Levels)
    local current = CareerUnlockConfig.Levels[level]
    local nextEntry = CareerUnlockConfig.Levels[level + 1]
    local unlocked = {}
    local count = 0

    for _, entry in ipairs(CareerUnlockConfig.Levels) do
        local active = entry.level <= level
        unlocked[entry.rewardKey] = active
        if active then count += 1 end
    end

    return {
        level = level,
        tier = current.tier,
        rewardKey = current.rewardKey,
        rewardLabel = current.rewardLabel,
        nextRewardLabel = nextEntry and nextEntry.rewardLabel or nil,
        nextRewardLevel = nextEntry and nextEntry.level or nil,
        maxLevel = nextEntry == nil,
        unlockCount = count,
        unlocked = unlocked,
    }
end

function CareerUnlockConfig.RequiredLevelForSkin(skinId)
    return CareerUnlockConfig.SkinRequiredLevel[tostring(skinId or "")] or 1
end

function CareerUnlockConfig.IsSkinUnlocked(level, skinId)
    return math.max(1, math.floor(tonumber(level) or 1)) >= CareerUnlockConfig.RequiredLevelForSkin(skinId)
end

return CareerUnlockConfig
