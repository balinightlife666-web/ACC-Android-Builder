-- LOST & FOUND: NIGHT SHIFT — M6-C seasonal content definition registrar.
-- Registration makes persisted items/cases recognizable. It does NOT activate an event.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local CollectionPreviewFactory = require(shared:WaitForChild("CollectionPreviewFactory"))
local CaseRegistry = require(shared:WaitForChild("CaseRegistry"))
local HalloweenContent = require(shared:WaitForChild("M6CHalloweenContent"))

local M6CSeasonalContentService = {}
local registered = false

function M6CSeasonalContentService.RegisterDefinitions()
    if registered then return true end

    for _, entry in ipairs(HalloweenContent.Collectibles) do
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

    for _, caseData in ipairs(HalloweenContent.Cases) do
        local ok, reason = CaseRegistry.RegisterEventCase(HalloweenContent.EventId, caseData)
        if not ok and reason ~= "DUPLICATE_ID" then
            warn("[LostAndFound] M6-C event case registration failed", caseData.id, reason)
            return false
        end
    end

    registered = true
    return true
end

return M6CSeasonalContentService
