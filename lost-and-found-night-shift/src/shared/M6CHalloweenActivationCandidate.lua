-- LOST & FOUND: NIGHT SHIFT — M6-C Halloween activation candidate.
-- DESIGN CANDIDATE ONLY. This module is not consumed by runtime code.
-- Activation requires explicit promotion into the live event/content registries.

local Candidate = {}

Candidate.Status = "CANDIDATE_NOT_APPLIED"
Candidate.EventId = "HALLOWEEN_2026"
Candidate.EditionToken = "HW26"

-- Candidate window is expressed in Bali/WITA for production clarity.
-- 2026-10-24 00:00 WITA -> 2026-11-04 00:00 WITA.
Candidate.Window = {
    timezone = "Asia/Makassar",
    startsAt = 1792771200,
    endsAt = 1793721600,
    startsLocal = "2026-10-24T00:00:00+08:00",
    endsLocal = "2026-11-04T00:00:00+08:00",
}

-- Event cases are intended to feel special, not replace the normal job loop.
Candidate.CaseWeights = {
    ["LF-HW26-001"] = 2,
    ["LF-HW26-002"] = 2,
    ["LF-HW26-003"] = 2,
}

-- Candidate seasonal ownership rolls. These DO NOT change the locked S1 table.
Candidate.DropPolicy = {
    hw26_midnight_hardcase = { chance = 0.35, mintCap = nil },
    hw26_pumpkin_claim_tag = { chance = 0.20, mintCap = nil },
    hw26_black_cat_backpack = { chance = 0.20, mintCap = nil },
    hw26_cold_room_parcel = { chance = 0.10, mintCap = nil },
}

-- No hard mint cap is proposed for HW26 v1. Scarcity comes from the time-bounded
-- event window + item-specific drop chances + permanent HW26 serial provenance.
Candidate.MintPolicy = "NO_HARD_CAP_TIME_BOUNDED"

return Candidate
