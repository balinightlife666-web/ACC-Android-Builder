local Config = {}

Config.GameTitle = "LOST & FOUND: NIGHT SHIFT"
Config.UniverseId = 10745354451
Config.PlaceId = 93699016600671
Config.Milestone = "M2 — COLLECTION FOUNDATION"

Config.CaseAdvanceDelay = 3.2
Config.ConveyorTravelTime = 2.8
Config.PromptDistance = 7
Config.PromptHoldDuration = 0.08
Config.ClaimantArrivalDelay = 0.45

Config.Rewards = {
    PERFECT = { Credits = 30, XP = 20 },
    CORRECT = { Credits = 20, XP = 10 },
    QUESTIONABLE = { Credits = 5, XP = 3 },
    WRONG = { Credits = 0, XP = 0 },
    CATASTROPHIC = { Credits = 0, XP = 0 },
}

return Config
