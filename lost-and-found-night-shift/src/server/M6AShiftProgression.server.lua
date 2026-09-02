-- LOST & FOUND: NIGHT SHIFT — M6-A Shift Progression Foundation
-- Event-driven derived progression. Existing persistent XP remains canonical.
-- No economy/drop/trade/case reward mutation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local ShiftProgressionConfig = require(shared:WaitForChild("ShiftProgressionConfig"))

local VERSION = ShiftProgressionConfig.Version
local boundPlayers = setmetatable({}, { __mode = "k" })
local boundLeaderstats = setmetatable({}, { __mode = "k" })
local boundXP = setmetatable({}, { __mode = "k" })
local revisions = setmetatable({}, { __mode = "k" })

local function apply(player, xpValue)
    if not player or not player.Parent then return end
    local snapshot = ShiftProgressionConfig.GetForXP(xpValue and xpValue.Value or 0)

    player:SetAttribute("LostFoundProgressionVersion", VERSION)
    player:SetAttribute("LostFoundShiftLevel", snapshot.level)
    player:SetAttribute("LostFoundShiftTitle", snapshot.title)
    player:SetAttribute("LostFoundShiftXP", snapshot.xp)
    player:SetAttribute("LostFoundShiftFloorXP", snapshot.floorXP)
    player:SetAttribute("LostFoundShiftNextXP", snapshot.nextXP or snapshot.floorXP)
    player:SetAttribute("LostFoundShiftProgress", snapshot.progress)
    player:SetAttribute("LostFoundShiftMilestone", snapshot.milestone)
    player:SetAttribute("LostFoundShiftNextMilestone", snapshot.nextMilestone or "PUNCAK TERCAPAI")
    player:SetAttribute("LostFoundShiftMaxLevel", snapshot.maxLevel)

    for _, entry in ipairs(ShiftProgressionConfig.Levels) do
        player:SetAttribute("LostFoundMilestoneL" .. tostring(entry.level), snapshot.xp >= entry.minXP)
    end

    revisions[player] = (revisions[player] or 0) + 1
    -- Written last so clients never render a partially-updated progression snapshot.
    player:SetAttribute("LostFoundProgressionRevision", revisions[player])
end

local function bindXP(player, xpValue)
    if not xpValue or not xpValue:IsA("IntValue") or boundXP[xpValue] then return end
    boundXP[xpValue] = true
    apply(player, xpValue)
    xpValue:GetPropertyChangedSignal("Value"):Connect(function()
        apply(player, xpValue)
    end)
end

local function bindLeaderstats(player, leaderstats)
    if not leaderstats or not leaderstats:IsA("Folder") or boundLeaderstats[leaderstats] then return end
    boundLeaderstats[leaderstats] = true

    local xp = leaderstats:FindFirstChild("XP")
    if xp then bindXP(player, xp) end

    leaderstats.ChildAdded:Connect(function(child)
        if child.Name == "XP" and child:IsA("IntValue") then
            bindXP(player, child)
        end
    end)
end

local function bindPlayer(player)
    if boundPlayers[player] then return end
    boundPlayers[player] = true

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then bindLeaderstats(player, leaderstats) end

    player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" and child:IsA("Folder") then
            bindLeaderstats(player, child)
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    bindPlayer(player)
end
Players.PlayerAdded:Connect(bindPlayer)
