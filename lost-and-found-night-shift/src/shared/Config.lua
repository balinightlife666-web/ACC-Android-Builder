local Config = {}

Config.GameTitle = "LOST & FOUND: NIGHT SHIFT"
Config.UniverseId = 10745354451
Config.PlaceId = 93699016600671
Config.Milestone = "M4-D — PERSONAL SHIFTS"

Config.InitialServerStationCapacity = 8
Config.CaseAdvanceDelay = 3.2
Config.ConveyorTravelTime = 2.8
Config.PromptDistance = 7
Config.PromptHoldDuration = 0.08
Config.ClaimantArrivalDelay = 0.45

-- Initial server-authoritative collectible ownership roll.
-- Index discovery is separate from ownership: encountering evidence can unlock
-- historical Collection/Archive progress even when no serialized instance drops.
Config.CollectionDropChance = {
    COMMON = 1.00,
    UNCOMMON = 0.85,
    RARE = 0.65,
    EPIC = 0.40,
    ANOMALY = 0.16,
    SECRET = 0.08,
}

Config.Rewards = {
    PERFECT = { Credits = 30, XP = 20 },
    CORRECT = { Credits = 20, XP = 10 },
    QUESTIONABLE = { Credits = 5, XP = 3 },
    WRONG = { Credits = 0, XP = 0 },
    CATASTROPHIC = { Credits = 0, XP = 0 },
}

return Config
