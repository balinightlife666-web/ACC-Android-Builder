-- LOST & FOUND: NIGHT SHIFT — M5-A Station Shop v1 + M6-B career gates.
-- Server-authoritative Credits purchases/equips for persistent station cosmetics.
-- M6-B only gates NEW acquisition by existing Shift Level; previously-owned skins remain equip-safe.
-- Cosmetic only: no case, reward, drop, serial, trading or mystery behavior changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))
local CareerUnlockConfig = require(shared:WaitForChild("CareerUnlockConfig"))
local PlayerDataStore = require(script.Parent:WaitForChild("PlayerDataStore"))
local PersonalStationWorld = require(script.Parent:WaitForChild("PersonalStationWorld"))

local remotes = ReplicatedStorage:FindFirstChild("LostAndFoundRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "LostAndFoundRemotes"
    remotes.Parent = ReplicatedStorage
end

local request = remotes:FindFirstChild("StationShopRequest")
if not request then
    request = Instance.new("RemoteFunction")
    request.Name = "StationShopRequest"
    request.Parent = remotes
end

local update = remotes:FindFirstChild("StationShopUpdate")
if not update then
    update = Instance.new("RemoteEvent")
    update.Name = "StationShopUpdate"
    update.Parent = remotes
end

local DECISION_COLORS = {
    RETURN = Color3.fromRGB(58, 170, 90),
    STORE = Color3.fromRGB(58, 158, 194),
    QUARANTINE = Color3.fromRGB(214, 151, 55),
    SECURITY = Color3.fromRGB(190, 58, 62),
}

local busy = {}

local function shiftLevel(player)
    return math.max(1, math.floor(tonumber(player:GetAttribute("LostFoundShiftLevel")) or 1))
end

local function creditsValue(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    local credits = leaderstats and leaderstats:FindFirstChild("Credits")
    if credits and credits:IsA("IntValue") then return credits end
    return nil
end

local function ownedSet(profile)
    local result = { STANDARD_OPS = true }
    for _, id in ipairs(profile.ownedSkins or {}) do result[id] = true end
    return result
end

local function publicEntries()
    local result = {}
    for _, id in ipairs(StationSkinRegistry.Order) do
        local entry = StationSkinRegistry.Skins[id]
        if entry then
            table.insert(result, {
                id = entry.id,
                name = entry.name,
                acquisition = entry.acquisition,
                priceCredits = entry.priceCredits,
                minShiftLevel = CareerUnlockConfig.RequiredLevelForSkin(entry.id),
            })
        end
    end
    return result
end

local function snapshot(player, message, code)
    local profile = PlayerDataStore.GetStationProfile(player.UserId)
    local credits = creditsValue(player)
    return {
        ok = true,
        code = code or "SYNC",
        message = message,
        credits = credits and credits.Value or 0,
        shiftLevel = shiftLevel(player),
        careerTier = player:GetAttribute("LostFoundCareerTier") or "ORIENTASI",
        equippedSkin = profile.equippedSkin,
        ownedSkins = profile.ownedSkins,
        entries = publicEntries(),
    }
end

local function currentStationModel(player)
    local stationId = player:GetAttribute("LostFoundStationId")
    if type(stationId) ~= "string" or stationId == "" then return nil end
    local world = workspace:FindFirstChild("LostAndFoundM4D")
    if not world then return nil end
    local station = world:FindFirstChild("Station_" .. stationId)
    if not station or not station:IsA("Model") then return nil end
    if station:GetAttribute("OwnerUserId") ~= player.UserId then return nil end
    return station
end

local function restoreDecisionColors(station)
    for decision, color in pairs(DECISION_COLORS) do
        local console = station:FindFirstChild(decision .. "Console")
        if console then
            for _, name in ipairs({"Top", "FootGlow"}) do
                local part = console:FindFirstChild(name)
                if part and part:IsA("BasePart") then
                    part:SetAttribute("StationSkinRole", "decisionColor")
                    part.Color = color
                    part.Material = Enum.Material.Neon
                end
            end
            local face = console:FindFirstChild("DecisionFace")
            local gui = face and face:FindFirstChildOfClass("SurfaceGui")
            local label = gui and gui:FindFirstChild("Text")
            if label and label:IsA("TextLabel") then label.TextColor3 = color end
        end
    end
end

local function applyEquipped(player)
    local station = currentStationModel(player)
    if not station then return false end
    local profile = PlayerDataStore.GetStationProfile(player.UserId)
    local skin = StationSkinRegistry.Skins[profile.equippedSkin] or StationSkinRegistry.Skins.STANDARD_OPS
    PersonalStationWorld.ApplySkin({ Model = station }, skin)
    restoreDecisionColors(station)
    player:SetAttribute("LostFoundStationSkin", skin.id)
    return true
end

local function waitAndApply(player)
    task.spawn(function()
        for _ = 1, 80 do
            if not player.Parent then return end
            if player:GetAttribute("LostFoundPersistenceReady") == true and applyEquipped(player) then
                update:FireClient(player, "SYNC", snapshot(player))
                return
            end
            task.wait(0.25)
        end
    end)
end

local function copyProfile(profile)
    local result = {
        equippedSkin = profile.equippedSkin,
        title = profile.title,
        ownedSkins = {},
    }
    for _, id in ipairs(profile.ownedSkins or {}) do table.insert(result.ownedSkins, id) end
    return result
end

local function purchase(player, skinId)
    if player:GetAttribute("LostFoundPersistenceReady") ~= true then
        return { ok = false, code = "NOT_READY", message = "Persistence is not ready yet." }
    end

    local skin = StationSkinRegistry.Skins[skinId]
    if not skin then
        return { ok = false, code = "INVALID_SKIN", message = "Unknown station skin." }
    end
    if skin.acquisition ~= "CREDITS" then
        return { ok = false, code = "NOT_FOR_CREDITS", message = "This skin is not available for Credits." }
    end

    local profile = PlayerDataStore.GetStationProfile(player.UserId)
    local owned = ownedSet(profile)
    if owned[skinId] then
        return { ok = false, code = "ALREADY_OWNED", message = "You already own this station skin.", snapshot = snapshot(player) }
    end

    local requiredLevel = CareerUnlockConfig.RequiredLevelForSkin(skinId)
    local currentLevel = shiftLevel(player)
    if currentLevel < requiredLevel then
        return {
            ok = false,
            code = "LEVEL_LOCKED",
            message = string.format("Requires Shift Level %d.", requiredLevel),
            requiredLevel = requiredLevel,
            shiftLevel = currentLevel,
        }
    end

    local credits = creditsValue(player)
    if not credits then
        return { ok = false, code = "NO_CREDITS", message = "Credits are not ready yet." }
    end

    local price = math.max(0, math.floor(tonumber(skin.priceCredits) or 0))
    if credits.Value < price then
        return {
            ok = false,
            code = "INSUFFICIENT_CREDITS",
            message = "Not enough Credits.",
            needed = price,
            credits = credits.Value,
        }
    end

    local nextProfile = copyProfile(profile)
    table.insert(nextProfile.ownedSkins, skinId)
    nextProfile.equippedSkin = skinId

    credits.Value -= price
    local committed = PlayerDataStore.CommitStationProfile(player.UserId, nextProfile, credits.Value, price)
    if not committed then
        credits.Value += price
        return { ok = false, code = "SAVE_FAILED", message = "Purchase could not be saved. Credits were restored." }
    end

    applyEquipped(player)
    local data = snapshot(player, skin.name .. " purchased and equipped.", "PURCHASED")
    update:FireClient(player, "PURCHASED", data)
    return data
end

local function equip(player, skinId)
    if player:GetAttribute("LostFoundPersistenceReady") ~= true then
        return { ok = false, code = "NOT_READY", message = "Persistence is not ready yet." }
    end

    local skin = StationSkinRegistry.Skins[skinId]
    if not skin then
        return { ok = false, code = "INVALID_SKIN", message = "Unknown station skin." }
    end

    local profile = PlayerDataStore.GetStationProfile(player.UserId)
    local owned = ownedSet(profile)
    if not owned[skinId] then
        return { ok = false, code = "NOT_OWNED", message = "Buy this station skin first." }
    end

    -- Grandfather rule: an already-owned skin is always equip-safe even if it predates M6-B level gates.
    if profile.equippedSkin == skinId then
        return snapshot(player, skin.name .. " is already equipped.", "EQUIPPED")
    end

    local nextProfile = copyProfile(profile)
    nextProfile.equippedSkin = skinId
    local credits = creditsValue(player)
    local committed = PlayerDataStore.CommitStationProfile(player.UserId, nextProfile, credits and credits.Value or 0, 0)
    if not committed then
        return { ok = false, code = "SAVE_FAILED", message = "Equip change could not be saved." }
    end

    applyEquipped(player)
    local data = snapshot(player, skin.name .. " equipped.", "EQUIPPED")
    update:FireClient(player, "EQUIPPED", data)
    return data
end

request.OnServerInvoke = function(player, action, skinId)
    action = string.upper(tostring(action or "SYNC"))
    skinId = tostring(skinId or "")

    if action == "SYNC" then
        if player:GetAttribute("LostFoundPersistenceReady") ~= true then
            return { ok = false, code = "NOT_READY", message = "Station profile is loading." }
        end
        return snapshot(player)
    end

    if busy[player.UserId] then
        return { ok = false, code = "BUSY", message = "Station Shop is processing another request." }
    end
    busy[player.UserId] = true

    local ok, result = pcall(function()
        if action == "BUY" then
            return purchase(player, skinId)
        elseif action == "EQUIP" then
            return equip(player, skinId)
        end
        return { ok = false, code = "INVALID_ACTION", message = "Unknown Station Shop action." }
    end)

    busy[player.UserId] = nil
    if not ok then
        warn("[LOST FOUND] Station Shop request failed:", result)
        return { ok = false, code = "SERVER_ERROR", message = "Station Shop request failed safely." }
    end
    return result
end

local function bindPlayer(player)
    player:GetAttributeChangedSignal("LostFoundStationId"):Connect(function()
        if player:GetAttribute("LostFoundStationId") ~= "" then waitAndApply(player) end
    end)
    player:GetAttributeChangedSignal("LostFoundPersistenceReady"):Connect(function()
        if player:GetAttribute("LostFoundPersistenceReady") == true then waitAndApply(player) end
    end)
    waitAndApply(player)
end

Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player)
    busy[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
