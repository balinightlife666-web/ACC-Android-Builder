-- LOST & FOUND: NIGHT SHIFT — M4-E.1D routine presentation anti-repeat.
-- Runs after M4-E.1 case depth and before PersonalShiftRuntime starts.
-- This layer does NOT change decision logic, scenario difficulty, collection mapping,
-- drop rates, serial/provenance, trading, station ownership, or mystery canon.
-- It only suppresses visibly identical routine property presentations in short runs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local M4E1DAntiRepeat = {}
local applied = false

local SOURCE_WINDOW = 4
local FAMILY_WINDOW = 2
local TITLE_WINDOW = 6

local recentSources = {}
local recentFamilies = {}
local recentTitles = {}
local variantCursor = {}

local PRESENTATIONS = {
    ["LF-M0-001"] = {
        { id = "BLUE_CANON", name = "Blue Hardcase Suitcase", color = Color3.fromRGB(41, 72, 112) },
        { id = "NAVY_TRANSIT", name = "Navy Transit Case", color = Color3.fromRGB(35, 63, 101) },
        { id = "COBALT_SHELL", name = "Cobalt Shell Suitcase", color = Color3.fromRGB(43, 76, 118) },
        { id = "BLUE_CARRY", name = "Blue Carry Hardcase", color = Color3.fromRGB(50, 80, 120) },
    },
    ["LF-M0-002"] = {
        { id = "RED_CANON", name = "Red Travel Backpack", color = Color3.fromRGB(122, 44, 48) },
        { id = "CRIMSON_PACK", name = "Crimson Travel Pack", color = Color3.fromRGB(112, 40, 45) },
        { id = "BURGUNDY_CABIN", name = "Burgundy Cabin Backpack", color = Color3.fromRGB(101, 43, 50) },
        { id = "RED_TRANSIT", name = "Red Transit Backpack", color = Color3.fromRGB(130, 51, 54) },
    },
    ["LF-M0-003"] = {
        { id = "CREAM_CANON", name = "Cream Teddy Bear", color = Color3.fromRGB(182, 151, 113) },
        { id = "IVORY_STITCHED", name = "Ivory Stitched Teddy", color = Color3.fromRGB(194, 167, 129) },
        { id = "SAND_PLUSH", name = "Sand Plush Bear", color = Color3.fromRGB(172, 143, 106) },
        { id = "CREAM_MEMORY", name = "Cream Memory Bear", color = Color3.fromRGB(187, 156, 118) },
    },
    ["LF-M0-004"] = {
        { id = "BROWN_CANON", name = "Brown Vintage Suitcase", color = Color3.fromRGB(100, 68, 45) },
        { id = "WALNUT_HERITAGE", name = "Walnut Heritage Case", color = Color3.fromRGB(92, 63, 43) },
        { id = "BROWN_LEATHER", name = "Brown Leather Travel Case", color = Color3.fromRGB(108, 74, 49) },
        { id = "CHESTNUT_VINTAGE", name = "Chestnut Vintage Case", color = Color3.fromRGB(116, 76, 48) },
    },
    ["LF-M0-005"] = {
        { id = "BLACK_CANON", name = "Black Hardcase Suitcase", color = Color3.fromRGB(35, 38, 43) },
        { id = "GRAPHITE_SECURITY", name = "Graphite Security Case", color = Color3.fromRGB(43, 46, 52) },
        { id = "CHARCOAL_TRANSIT", name = "Charcoal Transit Hardcase", color = Color3.fromRGB(48, 49, 54) },
        { id = "BLACK_SHELL", name = "Black Shell Travel Case", color = Color3.fromRGB(29, 31, 36) },
    },
}

local function remember(list, value, limit)
    if value == nil then return end
    table.insert(list, value)
    while #list > limit do
        table.remove(list, 1)
    end
end

local function isRecent(list, value)
    if value == nil then return false end
    for _, recent in ipairs(list) do
        if recent == value then return true end
    end
    return false
end

local function chooseVariant(sourceId, variants, canonicalName, forceAlternate)
    local start = (variantCursor[sourceId] or 1)
    local chosen = nil

    for offset = 0, #variants - 1 do
        local index = ((start + offset - 1) % #variants) + 1
        local candidate = variants[index]
        local titleFresh = not isRecent(recentTitles, candidate.name)
        local differentFromCanonical = candidate.name ~= canonicalName
        if titleFresh and (not forceAlternate or differentFromCanonical) then
            chosen = index
            break
        end
    end

    if not chosen then
        chosen = (start % #variants) + 1
        if forceAlternate and variants[chosen].name == canonicalName then
            chosen = (chosen % #variants) + 1
        end
    end

    variantCursor[sourceId] = (chosen % #variants) + 1
    return variants[chosen]
end

local function applyPresentation(caseData)
    if type(caseData) ~= "table" or caseData.caseType ~= "normal" then
        return caseData
    end

    local sourceId = caseData.sourceCaseId
    local variants = sourceId and PRESENTATIONS[sourceId]
    if not variants then
        remember(recentSources, sourceId, SOURCE_WINDOW)
        remember(recentFamilies, caseData.itemId, FAMILY_WINDOW)
        remember(recentTitles, caseData.itemName, TITLE_WINDOW)
        return caseData
    end

    local repeatedSource = isRecent(recentSources, sourceId)
    local repeatedFamily = isRecent(recentFamilies, caseData.itemId)
    local repeatedTitle = isRecent(recentTitles, caseData.itemName)
    local forceAlternate = repeatedSource or repeatedFamily or repeatedTitle

    if forceAlternate then
        local variant = chooseVariant(sourceId, variants, caseData.itemName, true)
        caseData.itemName = variant.name
        caseData.itemColor = variant.color
        caseData.presentationVariant = variant.id
    else
        caseData.presentationVariant = "CANONICAL"
    end

    remember(recentSources, sourceId, SOURCE_WINDOW)
    remember(recentFamilies, caseData.itemId, FAMILY_WINDOW)
    remember(recentTitles, caseData.itemName, TITLE_WINDOW)
    return caseData
end

function M4E1DAntiRepeat.Apply()
    if applied then return end

    local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
    local CaseRegistry = require(shared:WaitForChild("CaseRegistry"))
    if CaseRegistry.__M4E1DAntiRepeatApplied then
        applied = true
        return
    end

    local previousGet = CaseRegistry.Get
    assert(type(previousGet) == "function", "M4-E.1D requires CaseRegistry.Get")

    CaseRegistry.Get = function(index)
        local caseData = previousGet(index)
        -- Canonical mysteries pass through untouched. Routine fallback cases from a
        -- mystery candidate may receive presentation suppression only.
        return applyPresentation(caseData)
    end

    CaseRegistry.__M4E1DAntiRepeatApplied = true
    applied = true
end

return M4E1DAntiRepeat
