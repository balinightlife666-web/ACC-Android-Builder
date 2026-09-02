-- LOST & FOUND: NIGHT SHIFT — M6-A Shift Progression Foundation
-- XP remains the existing persistent authority. This module only derives level/title/milestone state.

local ShiftProgressionConfig = {}

ShiftProgressionConfig.Version = "M6A_SHIFT_PROGRESSION_V1"

ShiftProgressionConfig.Levels = {
    { level = 1, minXP = 0,    title = "PETUGAS BARU",        milestone = "ORIENTASI SHIFT",       unlockKey = "FOUNDATION" },
    { level = 2, minXP = 100,  title = "OPERATOR JUNIOR",    milestone = "RITME KERJA",           unlockKey = "SHIFT_LOG" },
    { level = 3, minXP = 250,  title = "OPERATOR SHIFT",     milestone = "KONSISTENSI KASUS",     unlockKey = "CASE_STREAK" },
    { level = 4, minXP = 500,  title = "OPERATOR SENIOR",    milestone = "ARSIP LANJUTAN",        unlockKey = "ADVANCED_ARCHIVE" },
    { level = 5, minXP = 900,  title = "SPESIALIS KASUS",    milestone = "PENANGANAN INSIDEN",    unlockKey = "INCIDENT_DESK" },
    { level = 6, minXP = 1400, title = "PENGAWAS MALAM",     milestone = "ANALISIS MALAM",        unlockKey = "NIGHT_ANALYSIS" },
    { level = 7, minXP = 2100, title = "ANALIS INSIDEN",     milestone = "KASUS KOMPLEKS",        unlockKey = "COMPLEX_CASES" },
    { level = 8, minXP = 3000, title = "SPESIALIS ARSIP",    milestone = "ARSIP ANOMALI",         unlockKey = "ANOMALY_ARCHIVE" },
    { level = 9, minXP = 4200, title = "PEMIMPIN SHIFT",     milestone = "KEPEMIMPINAN SHIFT",    unlockKey = "SHIFT_LEAD" },
    { level = 10,minXP = 5600, title = "MASTER NIGHT SHIFT", milestone = "PUNCAK NIGHT SHIFT",    unlockKey = "MASTER_SHIFT" },
}

function ShiftProgressionConfig.GetForXP(rawXP)
    local xp = math.max(0, math.floor(tonumber(rawXP) or 0))
    local current = ShiftProgressionConfig.Levels[1]
    local nextLevel = nil

    for index, entry in ipairs(ShiftProgressionConfig.Levels) do
        if xp >= entry.minXP then
            current = entry
            nextLevel = ShiftProgressionConfig.Levels[index + 1]
        else
            break
        end
    end

    local floorXP = current.minXP
    local ceilingXP = nextLevel and nextLevel.minXP or floorXP
    local progress = 1
    if nextLevel then
        local span = math.max(1, ceilingXP - floorXP)
        progress = math.clamp((xp - floorXP) / span, 0, 1)
    end

    return {
        xp = xp,
        level = current.level,
        title = current.title,
        milestone = current.milestone,
        unlockKey = current.unlockKey,
        floorXP = floorXP,
        nextXP = nextLevel and nextLevel.minXP or nil,
        nextLevel = nextLevel and nextLevel.level or nil,
        nextTitle = nextLevel and nextLevel.title or nil,
        nextMilestone = nextLevel and nextLevel.milestone or nil,
        progress = progress,
        maxLevel = nextLevel == nil,
    }
end

return ShiftProgressionConfig
