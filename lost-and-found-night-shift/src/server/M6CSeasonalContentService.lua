-- LOST & FOUND: NIGHT SHIFT — M6-C seasonal content definition registrar.
-- Registration makes persisted items/cases recognizable. It does NOT activate an event.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local CollectionPreviewFactory = require(shared:WaitForChild("CollectionPreviewFactory"))
local CaseRegistry = require(shared:WaitForChild("CaseRegistry"))
local SeasonalPacks = {
    require(shared:WaitForChild("M6CHalloweenContent")),
    require(shared:WaitForChild("M6CChristmasContent")),
}

local M6CSeasonalContentService = {}
local registered = false

function M6CSeasonalContentService.RegisterDefinitions()
    if registered then return true end

    for _, content in ipairs(SeasonalPacks) do
        for _, entry in ipairs(content.Collectibles) do
            local ok, reason = CollectionRegistry.RegisterSeasonal(entry)
            if not ok and reason ~= "DUPLICATE_ID" then
                warn("[LostAndFound] M6-C seasonal collection registration failed", entry.id, reason)
                return false
            end

            CollectionPreviewFactory.RegisterVariant(entry.id, {
                base = entry.visual and entry.visual.base or entry.baseItemId,
                color = entry.visual and entry.visual.color or Color3.fromRGB(90, 96, 108),
                rarity = entry.rarity,
                accent = entry.visual and entry.visual.accent or nil,
            })
        end

        for _, caseData in ipairs(content.Cases) do
            local ok, reason = CaseRegistry.RegisterEventCase(content.EventId, caseData)
            if not ok and reason ~= "DUPLICATE_ID" then
                warn("[LostAndFound] M6-C event case registration failed", caseData.id, reason)
                return false
            end
        end
    end

    registered = true
    return true
end

return M6CSeasonalContentService
