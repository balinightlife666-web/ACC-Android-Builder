-- LOST & FOUND: NIGHT SHIFT — M6-B Career Unlock Authority
-- Derives cumulative cosmetic/prestige unlock state from the M6-A Shift Level attribute.
-- No DataStore and no new currency. LostFoundCareerRevision is written last for atomic client reads.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CareerUnlockConfig = require(shared:WaitForChild("CareerUnlockConfig"))

local revisions = setmetatable({}, { __mode = "k" })
local bound = setmetatable({}, { __mode = "k" })

local function apply(player)
    if not player or not player.Parent then return end
    local level = tonumber(player:GetAttribute("LostFoundShiftLevel")) or 1
    local snapshot = CareerUnlockConfig.GetForLevel(level)

    player:SetAttribute("LostFoundCareerVersion", CareerUnlockConfig.Version)
    player:SetAttribute("LostFoundCareerTier", snapshot.tier)
    player:SetAttribute("LostFoundCareerReward", snapshot.rewardLabel)
    player:SetAttribute("LostFoundCareerNextReward", snapshot.nextRewardLabel or "SEMUA UNLOCK TERCAPAI")
    player:SetAttribute("LostFoundCareerNextRewardLevel", snapshot.nextRewardLevel or snapshot.level)
    player:SetAttribute("LostFoundCareerUnlockCount", snapshot.unlockCount)
    player:SetAttribute("LostFoundCareerMaxLevel", snapshot.maxLevel)

    for _, key in ipairs(CareerUnlockConfig.AllUnlockKeys) do
        player:SetAttribute("LostFoundUnlock_" .. key, snapshot.unlocked[key] == true)
    end

    revisions[player] = (revisions[player] or 0) + 1
    player:SetAttribute("LostFoundCareerRevision", revisions[player])
end

local function bind(player)
    if bound[player] then return end
    bound[player] = true
    player:GetAttributeChangedSignal("LostFoundShiftLevel"):Connect(function()
        apply(player)
    end)
    apply(player)
end

for _, player in ipairs(Players:GetPlayers()) do bind(player) end
Players.PlayerAdded:Connect(bind)
