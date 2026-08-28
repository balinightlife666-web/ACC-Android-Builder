-- LOST & FOUND: NIGHT SHIFT — M5-A.2 Station Shop preview.
-- Server-authoritative Credits purchases/equips plus temporary no-cost skin preview.
-- Preview is visual only: no ownership, Credits, persistence, rewards, drops, serials,
-- trading, mystery canon, station isolation or decision-color changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))
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

local PREVIEW_SECONDS = 20
local busy = {}
local previewState = {}
local previewTokens = {}

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
            })
        end
    end
    return result
end

local function snapshot(player, message, code)
    local profile = PlayerDataStore.GetStationProfile(player.UserId)
    local credits = creditsValue(player)
    local activePreview = previewState[player.UserId]
    return {
        ok = true,
        code = code or "SYNC",
        message = message,
        credits = credits and credits.Value or 0,
        equippedSkin = profile.equippedSkin,
        ownedSkins = profile.ownedSkins,
        entries = publicEntries(),
        previewSkin = activePreview and activePreview.skinId or nil,
        previewSeconds = activePreview and math.max(0, math.ceil(activePreview.expiresAt - os.clock())) or 0,
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

local function applySkinVisual(player, skin)
    local station = currentStationModel(player)
    if not station or not skin then return false end
    PersonalStationWorld.ApplySkin({ Model = station }, skin)
    restoreDecisionColors(station)
    return true
end

local function applyEquipped(player)
    local profile = PlayerDataStore.GetStationProfile(player.UserId)
    local skin = StationSkinRegistry.Skins[profile.equippedSkin] or StationSkinRegistry.Skins.STANDARD_OPS
    if not applySkinVisual(player, skin) then return false end
    player:SetAttribute("LostFoundStationSkin", skin.id)
    player:SetAttribute("LostFoundStationPreviewSkin", "")
    return true
end

local function invalidatePreview(player, restore)
    local userId = player.UserId
    previewTokens[userId] = (previewTokens[userId] or 0) + 1
    previewState[userId] = nil
    player:SetAttribute("LostFoundStationPreviewSkin", "")
    if restore then applyEquipped(player) end
end

local function waitAndApply(player)
    task.spawn(function()
        for _ = 1, 80 do
            if not player.Parent then return end
            if player:GetAttribute("LostFoundPersistenceReady") == true then
                -- A new/reassigned station always starts from the player's persisted skin.
                if previewState[player.UserId] then invalidatePreview(player, false) end
                if applyEquipped(player) then
                    update:FireClient(player, "SYNC", snapshot(player))
                    return
                end
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

local function preview(player, skinId)
    if player:GetAttribute("LostFoundPersistenceReady") ~= true then
        return { ok = false, code = "NOT_READY", message = "Persistence is not ready yet." }
    end

    local skin = StationSkinRegistry.Skins[skinId]
    if not skin then
        return { ok = false, code = "INVALID_SKIN", message = "Unknown station skin." }
    end
    if skin.acquisition ~= "FREE" and skin.acquisition ~= "CREDITS" then
        return { ok = false, code = "PREVIEW_UNAVAILABLE", message = "This skin is not available for preview yet." }
    end
    if not currentStationModel(player) then
        return { ok = false, code = "NO_STATION", message = "Your personal station is not ready yet." }
    end

    local userId = player.UserId
    previewTokens[userId] = (previewTokens[userId] or 0) + 1
    local token = previewTokens[userId]
    previewState[userId] = {
        skinId = skin.id,
        token = token,
        expiresAt = os.clock() + PREVIEW_SECONDS,
    }

    if not applySkinVisual(player, skin) then
        previewState[userId] = nil
        return { ok = false, code = "NO_STATION", message = "Your personal station is not ready yet." }
    end

    player:SetAttribute("LostFoundStationPreviewSkin", skin.id)
    local data = snapshot(player, skin.name .. " preview active for " .. PREVIEW_SECONDS .. " seconds.", "PREVIEWING")
    update:FireClient(player, "PREVIEWING", data)

    task.delay(PREVIEW_SECONDS, function()
        if not player.Parent then return end
        local active = previewState[userId]
        if not active or active.token ~= token then return end
        previewState[userId] = nil
        player:SetAttribute("LostFoundStationPreviewSkin", "")
        applyEquipped(player)
        update:FireClient(player, "PREVIEW_ENDED", snapshot(player, "Preview ended. Your equipped skin was restored.", "PREVIEW_ENDED"))
    end)

    return data
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

    local credits = creditsValue(player)
    if not credits then
        return { ok = false, code = "NO_CREDITS", message = "Credits are not ready yet." }
    end

    local profile = PlayerDataStore.GetStationProfile(player.UserId)
    local owned = ownedSet(profile)
    if owned[skinId] then
        return { ok = false, code = "ALREADY_OWNED", message = "You already own this station skin.", snapshot = snapshot(player) }
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

    invalidatePreview(player, false)

    local nextProfile = copyProfile(profile)
    table.insert(nextProfile.ownedSkins, skinId)
    nextProfile.equippedSkin = skinId

    credits.Value -= price
    local committed = PlayerDataStore.CommitStationProfile(player.UserId, nextProfile, credits.Value, price)
    if not committed then
        credits.Value += price
        applyEquipped(player)
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

    invalidatePreview(player, false)

    if profile.equippedSkin == skinId then
        applyEquipped(player)
        return snapshot(player, skin.name .. " is already equipped.", "EQUIPPED")
    end

    local nextProfile = copyProfile(profile)
    nextProfile.equippedSkin = skinId
    local credits = creditsValue(player)
    local committed = PlayerDataStore.CommitStationProfile(player.UserId, nextProfile, credits and credits.Value or 0, 0)
    if not committed then
        applyEquipped(player)
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
        if action == "PREVIEW" then
            return preview(player, skinId)
        elseif action == "BUY" then
            return purchase(player, skinId)
        elseif action == "EQUIP" then
            return equip(player, skinId)
        elseif action == "END_PREVIEW" then
            invalidatePreview(player, true)
            return snapshot(player, "Preview ended. Your equipped skin was restored.", "PREVIEW_ENDED")
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
    player:SetAttribute("LostFoundStationPreviewSkin", "")
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
    previewState[player.UserId] = nil
    previewTokens[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
