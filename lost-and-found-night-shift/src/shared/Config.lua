local Config = {}

Config.GameTitle = "LOST & FOUND: NIGHT SHIFT"
Config.UniverseId = 10745354451
Config.PlaceId = 93699016600671
Config.Milestone = "M0 — FIRST SUITCASE"

Config.CaseAdvanceDelay = 4
Config.ConveyorTravelTime = 3.2
Config.PromptDistance = 10

Config.Rewards = {
    PERFECT = { Credits = 30, XP = 20 },
    CORRECT = { Credits = 20, XP = 10 },
    QUESTIONABLE = { Credits = 5, XP = 3 },
    WRONG = { Credits = 0, XP = 0 },
    CATASTROPHIC = { Credits = 0, XP = 0 },
}

return Config
