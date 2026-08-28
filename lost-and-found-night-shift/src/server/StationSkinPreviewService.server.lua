-- LOST & FOUND: NIGHT SHIFT — M5-A.2 Station Skin Preview.
-- Temporary cosmetic preview only. No ownership, Credits, persistence, or gameplay mutation.

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

local request = remotes:FindFirstChild("StationSkinPreviewRequest")
if not request then
    request = Instance.new("RemoteFunction")
    request.Name = "StationSkinPreviewRequest"
    request.Parent = remotes
end

local DECISION_COLORS = {
    RETURN = Color3.fromRGB(58, 170, 90),
    STORE = Color3.fromRGB(58, 158, 194),
    QUARANTINE = Color3.fromRGB(214, 151, 55),
    SECURITY = Color3.fromRGB(190, 58, 62),
}

local busy = {}
local previewing = {}

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
            if label and label:IsA("TextLabel") then
                label.TextColor3 = color
            end
        end
    end
end

local function applySkin(player, skin)
    local station = currentStationModel(player)
    if not station then return false end

    PersonalStationWorld.ApplySkin({ Model = station }, skin)
    restoreDecisionColors(station)
    return true
end

local function restoreEquipped(player)
    local profile = PlayerDataStore.GetStationProfile(player.UserId)
    local skin = StationSkinRegistry.Skins[profile.equippedSkin] or StationSkinRegistry.Skins.STANDARD_OPS
    if not applySkin(player, skin) then return false end

    previewing[player.UserId] = nil
    player:SetAttribute("LostFoundStationPreviewSkin", nil)
    player:SetAttribute("LostFoundStationSkin", skin.id)
    return true, skin
end

local function preview(player, skinId)
    local skin = StationSkinRegistry.Skins[skinId]
    if not skin then
        return { ok = false, code = "INVALID_SKIN", message = "Unknown station skin." }
    end

    -- M5-A.2 previews only the currently earnable Station Shop catalog.
    -- Premium/event entries remain deferred and are not exposed through trial mode.
    if skin.acquisition ~= "FREE" and skin.acquisition ~= "CREDITS" then
        return { ok = false, code = "PREVIEW_LOCKED", message = "This skin is not available for preview yet." }
    end

    if not applySkin(player, skin) then
        return { ok = false, code = "NO_STATION", message = "Your personal station is not ready." }
    end

    previewing[player.UserId] = skin.id
    player:SetAttribute("LostFoundStationPreviewSkin", skin.id)
    return {
        ok = true,
        code = "PREVIEWING",
        skinId = skin.id,
        skinName = skin.name,
        message = skin.name .. " preview active. No Credits were spent.",
    }
end

request.OnServerInvoke = function(player, action, skinId)
    action = string.upper(tostring(action or "RESTORE"))
    skinId = tostring(skinId or "")

    if player:GetAttribute("LostFoundPersistenceReady") ~= true then
        return { ok = false, code = "NOT_READY", message = "Station profile is still loading." }
    end

    if busy[player.UserId] then
        return { ok = false, code = "BUSY", message = "Preview is processing another request." }
    end
    busy[player.UserId] = true

    local ok, result = pcall(function()
        if action == "PREVIEW" then
            return preview(player, skinId)
        elseif action == "RESTORE" then
            local restored, skin = restoreEquipped(player)
            if not restored then
                return { ok = false, code = "NO_STATION", message = "Your personal station is not ready." }
            end
            return {
                ok = true,
                code = "RESTORED",
                skinId = skin.id,
                skinName = skin.name,
                message = "Equipped station skin restored.",
            }
        end
        return { ok = false, code = "INVALID_ACTION", message = "Unknown preview action." }
    end)

    busy[player.UserId] = nil
    if not ok then
        warn("[LOST FOUND] Station skin preview failed:", result)
        return { ok = false, code = "SERVER_ERROR", message = "Station skin preview failed safely." }
    end
    return result
end

local function bindPlayer(player)
    player:GetAttributeChangedSignal("LostFoundStationId"):Connect(function()
        -- A preview never follows a physical A-H slot change. The persisted equipped
        -- skin remains the authority whenever a new temporary station is assigned.
        if previewing[player.UserId] then
            previewing[player.UserId] = nil
            player:SetAttribute("LostFoundStationPreviewSkin", nil)
        end
    end)
end

Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player)
    busy[player.UserId] = nil
    previewing[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    bindPlayer(player)
end
