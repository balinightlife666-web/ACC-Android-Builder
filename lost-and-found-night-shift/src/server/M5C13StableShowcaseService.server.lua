-- LOST & FOUND: NIGHT SHIFT — M5-C.1.3 Stable Showcase Service
-- Unified non-destructive five-slot showcase authority.
-- Replaces the retired M5-B / M5-B.2 renderers while preserving their DataStores
-- and remote contracts. Existing display models are never rebuilt unless the selected
-- serialized instance actually changes, is traded away, or the station changes.
-- Roblox in-engine only. No generated images, decals, external textures or external assets.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local PreviewFactory = require(shared:WaitForChild("CollectionPreviewFactory"))

local VERSION = "M5C13_NONDESTRUCTIVE_SHOWCASE_V1"
local SLOT_COUNT = 5
local INITIAL_SCALE = 0.30

local mainStore = DataStoreService:GetDataStore("LostAndFound_PlayerData_v1")
local baseStore = DataStoreService:GetDataStore("LostAndFound_Showcase_v1")
local extraStore = DataStoreService:GetDataStore("LostAndFound_ShowcaseExtra_v1")

local remotes = ReplicatedStorage:FindFirstChild("LostAndFoundRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "LostAndFoundRemotes"
    remotes.Parent = ReplicatedStorage
end

local function ensureRemote(className, name)
    local existing = remotes:FindFirstChild(name)
    if existing and existing.ClassName == className then return existing end
    if existing then existing:Destroy() end
    local remote = Instance.new(className)
    remote.Name = name
    remote.Parent = remotes
    return remote
end

local baseRequest = ensureRemote("RemoteFunction", "PersonalShowcaseRequest")
local baseUpdate = ensureRemote("RemoteEvent", "PersonalShowcaseUpdate")
local extraRequest = ensureRemote("RemoteFunction", "M5B2ShowcaseRequest")
local extraUpdate = ensureRemote("RemoteEvent", "M5B2ShowcaseUpdate")

local RARITY_RANK = {
    COMMON = 1,
    UNCOMMON = 2,
    RARE = 3,
    EPIC = 4,
    ANOMALY = 5,
    SECRET = 6,
}

local states = {}
local busy = {}
local renderQueued = {}

local function keyFor(userId)
    return "u_" .. tostring(userId)
end

local function cleanId(value)
    if type(value) ~= "string" or #value < 1 or #value > 80 then return nil end
    return value
end

local function emptySlots()
    return {"", "", "", "", ""}
end

local function cloneSlots(slots)
    local out = emptySlots()
    for slot = 1, SLOT_COUNT do
        out[slot] = tostring(slots and slots[slot] or "")
    end
    return out
end

local function publicItem(raw, userId)
    if type(raw) ~= "table" then return nil end
    local instanceId = cleanId(raw.instanceId)
    local collectionId = cleanId(raw.collectionId)
    local serial = type(raw.serial) == "string" and string.sub(raw.serial, 1, 48) or nil
    if not instanceId or not collectionId or not serial then return nil end

    local owner = math.max(0, math.floor(tonumber(raw.currentOwnerUserId) or 0))
    if owner ~= userId then return nil end

    local entry = CollectionRegistry.Get(collectionId)
    if not entry then return nil end

    return {
        instanceId = instanceId,
        collectionId = collectionId,
        name = tostring(entry.name or collectionId),
        rarity = tostring(entry.rarity or "COMMON"),
        serial = serial,
        serialNumber = math.max(1, math.floor(tonumber(raw.serialNumber) or 1)),
        edition = tostring(raw.edition or entry.edition or "S1"),
        tradeCount = math.max(0, math.floor(tonumber(raw.tradeCount) or 0)),
    }
end

local function readInventory(userId)
    local ok, raw = pcall(function()
        return mainStore:GetAsync(keyFor(userId))
    end)
    if not ok then
        warn("[LOST FOUND] M5-C.1.3 inventory read failed", userId, raw)
        return nil, "INVENTORY_READ_FAILED"
    end

    local result, seen = {}, {}
    local inventory = type(raw) == "table" and raw.inventory or nil
    if type(inventory) == "table" then
        for _, candidate in ipairs(inventory) do
            local item = publicItem(candidate, userId)
            if item and not seen[item.instanceId] then
                seen[item.instanceId] = true
                table.insert(result, item)
            end
        end
    end

    table.sort(result, function(a, b)
        local ar = RARITY_RANK[a.rarity] or 0
        local br = RARITY_RANK[b.rarity] or 0
        if ar == br then
            return (a.serialNumber or math.huge) < (b.serialNumber or math.huge)
        end
        return ar > br
    end)
    return result
end

local function inventoryMap(inventory)
    local map = {}
    for _, item in ipairs(inventory or {}) do map[item.instanceId] = item end
    return map
end

local function seedBaseSlots(inventory)
    local slots = {"", "", ""}
    local usedCollection, usedInstance = {}, {}
    local index = 1

    for _, item in ipairs(inventory or {}) do
        if index > 3 then break end
        if not usedCollection[item.collectionId] then
            slots[index] = item.instanceId
            usedCollection[item.collectionId] = true
            usedInstance[item.instanceId] = true
            index += 1
        end
    end
    if index <= 3 then
        for _, item in ipairs(inventory or {}) do
            if index > 3 then break end
            if not usedInstance[item.instanceId] then
                slots[index] = item.instanceId
                usedInstance[item.instanceId] = true
                index += 1
            end
        end
    end
    return slots
end

local function saveBaseSlots(userId, slots)
    local clean = {tostring(slots[1] or ""), tostring(slots[2] or ""), tostring(slots[3] or "")}
    local ok, err = pcall(function()
        baseStore:UpdateAsync(keyFor(userId), function()
            return {
                version = 1,
                initialized = true,
                slots = clean,
                updatedAt = os.time(),
            }
        end)
    end)
    if not ok then warn("[LOST FOUND] M5-C.1.3 base showcase save failed", userId, err) end
    return ok
end

local function saveExtraSlots(userId, slots)
    local slot4, slot5 = tostring(slots[4] or ""), tostring(slots[5] or "")
    local ok, err = pcall(function()
        extraStore:UpdateAsync(keyFor(userId), function()
            return {
                version = 1,
                slot4 = slot4,
                slot5 = slot5,
                updatedAt = os.time(),
            }
        end)
    end)
    if not ok then warn("[LOST FOUND] M5-C.1.3 extra showcase save failed", userId, err) end
    return ok
end

local function readSlots(userId, inventory)
    local slots = emptySlots()
    local baseInitialized = false

    local okBase, rawBase = pcall(function() return baseStore:GetAsync(keyFor(userId)) end)
    if not okBase then return nil, "BASE_SHOWCASE_READ_FAILED" end
    if type(rawBase) == "table" and rawBase.initialized == true and type(rawBase.slots) == "table" then
        baseInitialized = true
        for slot = 1, 3 do slots[slot] = tostring(rawBase.slots[slot] or "") end
    else
        local seeded = seedBaseSlots(inventory)
        for slot = 1, 3 do slots[slot] = seeded[slot] end
    end

    local okExtra, rawExtra = pcall(function() return extraStore:GetAsync(keyFor(userId)) end)
    if not okExtra then return nil, "EXTRA_SHOWCASE_READ_FAILED" end
    if type(rawExtra) == "table" then
        slots[4] = tostring(rawExtra.slot4 or "")
        slots[5] = tostring(rawExtra.slot5 or "")
    end

    local owned = inventoryMap(inventory)
    local seen = {}
    local baseChanged = not baseInitialized
    local extraChanged = false

    for slot = 1, SLOT_COUNT do
        local id = cleanId(slots[slot])
        if not id or not owned[id] or seen[id] then
            if slots[slot] ~= "" then
                if slot <= 3 then baseChanged = true else extraChanged = true end
            end
            slots[slot] = ""
        else
            slots[slot] = id
            seen[id] = true
        end
    end

    if baseChanged and not saveBaseSlots(userId, slots) then return nil, "BASE_SHOWCASE_SAVE_FAILED" end
    if extraChanged and not saveExtraSlots(userId, slots) then return nil, "EXTRA_SHOWCASE_SAVE_FAILED" end
    return slots
end

local function currentStation(player)
    local stationId = player:GetAttribute("LostFoundStationId")
    if type(stationId) ~= "string" or stationId == "" then return nil end
    local world = workspace:FindFirstChild("LostAndFoundM4D")
    local station = world and world:FindFirstChild("Station_" .. stationId)
    if not station or not station:IsA("Model") then return nil end
    if station:GetAttribute("OwnerUserId") ~= player.UserId then return nil end
    return station
end

local function stationByName(name)
    if type(name) ~= "string" or name == "" then return nil end
    local world = workspace:FindFirstChild("LostAndFoundM4D")
    return world and world:FindFirstChild(name) or nil
end

local function parseSlot(model)
    if not model or not model:IsA("Model") then return nil end
    return tonumber(string.match(model.Name, "M5B_Slot_(%d+)"))
        or tonumber(string.match(model.Name, "M5B2_Slot_(%d+)"))
        or tonumber(string.match(model.Name, "Display_(%d+)"))
end

local function ensureDisplayFolder(showcase)
    local folder = showcase:FindFirstChild("DisplayedItems")
    if folder and folder:IsA("Folder") then
        folder:SetAttribute("M5C13StableFolder", VERSION)
        return folder
    end
    if folder then folder:Destroy() end
    folder = Instance.new("Folder")
    folder.Name = "DisplayedItems"
    folder:SetAttribute("M5BManualShowcase", true)
    folder:SetAttribute("M5C13StableFolder", VERSION)
    folder.Parent = showcase
    return folder
end

local function clearStationVisual(station)
    if not station or not station:IsA("Model") then return end
    local showcase = station:FindFirstChild("PublicShowcase")
    local folder = showcase and showcase:FindFirstChild("DisplayedItems")
    if folder and folder:IsA("Folder") then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") then child:Destroy() end
        end
    end
    station:SetAttribute("ShowcaseCount", 0)
    station:SetAttribute("ShowcaseVersion", VERSION)
end

local function createDisplayModel(item, slot, folder, showcase)
    local anchor = showcase:FindFirstChild("DisplayAnchor" .. slot)
    if not anchor or not anchor:IsA("BasePart") then return nil end

    -- Build off-world first so the client never sees the factory's raw default size/position.
    local staging = Instance.new("Folder")
    staging.Name = "M5C13Staging"
    local model = PreviewFactory.Create(item.collectionId, staging, false)
    if not model or not model:IsA("Model") then
        staging:Destroy()
        return nil
    end

    model.Name = slot <= 3 and ("M5B_Slot_" .. slot) or ("M5B2_Slot_" .. slot)
    model:SetAttribute("InstanceId", item.instanceId)
    model:SetAttribute("CollectionId", item.collectionId)
    model:SetAttribute("Serial", item.serial)
    model:SetAttribute("Rarity", item.rarity)
    model:SetAttribute("M5C13StableInstance", VERSION)
    pcall(function() model:ScaleTo(INITIAL_SCALE) end)
    pcall(function() model:PivotTo(anchor.CFrame * CFrame.Angles(0, math.rad(180), 0)) end)

    model.Parent = folder
    staging:Destroy()
    return model
end

local function renderStable(player)
    local state = states[player.UserId]
    if not state then return false end
    local station = currentStation(player)
    if not station then return false end

    if state.lastStationName and state.lastStationName ~= station.Name then
        clearStationVisual(stationByName(state.lastStationName))
    end

    local showcase = station:FindFirstChild("PublicShowcase")
    if not showcase or not showcase:IsA("Model") then return false end
    if station:GetAttribute("ShowcaseLayoutVersion") ~= "M5B2_FIVE_SLOT_LARGE_V1"
        or not showcase:FindFirstChild("DisplayAnchor5")
        or not showcase:FindFirstChild("M5B2_Plinth5")
    then
        return false
    end

    local folder = ensureDisplayFolder(showcase)
    local owned = inventoryMap(state.inventory)
    local desired = {}
    for slot = 1, SLOT_COUNT do desired[slot] = owned[state.slots[slot]] end

    local candidates = {}
    for slot = 1, SLOT_COUNT do candidates[slot] = {} end

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            local slot = parseSlot(child)
            if slot and slot >= 1 and slot <= SLOT_COUNT then
                table.insert(candidates[slot], child)
            else
                child:Destroy()
            end
        end
    end

    for slot = 1, SLOT_COUNT do
        local wanted = desired[slot]
        local keeper = nil
        if wanted then
            for _, model in ipairs(candidates[slot]) do
                if tostring(model:GetAttribute("InstanceId") or "") == wanted.instanceId then
                    keeper = model
                    break
                end
            end
        end

        for _, model in ipairs(candidates[slot]) do
            if model ~= keeper then model:Destroy() end
        end

        if wanted then
            if keeper then
                -- Stable path: metadata may be refreshed, but scale/CFrame are never touched.
                keeper:SetAttribute("CollectionId", wanted.collectionId)
                keeper:SetAttribute("Serial", wanted.serial)
                keeper:SetAttribute("Rarity", wanted.rarity)
                keeper:SetAttribute("M5C13StableInstance", VERSION)
            else
                createDisplayModel(wanted, slot, folder, showcase)
            end
        end
    end

    local count = 0
    for slot = 1, SLOT_COUNT do if state.slots[slot] ~= "" then count += 1 end end
    station:SetAttribute("ShowcaseCount", count)
    station:SetAttribute("ShowcaseVersion", VERSION)
    station:SetAttribute("ShowcaseRenderMode", "NON_DESTRUCTIVE")
    state.lastStationName = station.Name
    return true
end

local function queueRender(player, delaySeconds)
    if not player or not player.Parent then return end
    if renderQueued[player.UserId] then return end
    renderQueued[player.UserId] = true
    task.delay(delaySeconds or 0.15, function()
        renderQueued[player.UserId] = nil
        if not player.Parent then return end
        if not renderStable(player) then
            task.delay(0.65, function()
                if player.Parent then renderStable(player) end
            end)
        end
    end)
end

local function snapshot(player, code, message)
    local state = states[player.UserId]
    if not state then return {ok=false, code="NOT_READY", message="Showcase state is not ready."} end
    local owned = inventoryMap(state.inventory)
    local slotItems = {}
    for slot = 1, SLOT_COUNT do slotItems[slot] = owned[state.slots[slot]] end
    return {
        ok = true,
        code = code or "SYNC",
        message = message,
        slots = cloneSlots(state.slots),
        slotItems = slotItems,
        inventory = state.inventory,
    }
end

local function pushUpdates(player, code, message)
    local data = snapshot(player, code, message)
    baseUpdate:FireClient(player, code or "SYNC", data)
    extraUpdate:FireClient(player, code or "SYNC", data)
    return data
end

local function syncPlayer(player, push)
    if not player or not player.Parent then return false, "PLAYER_GONE" end
    if player:GetAttribute("LostFoundPersistenceReady") ~= true then return false, "NOT_READY" end

    local inventory, inventoryErr = readInventory(player.UserId)
    if not inventory then return false, inventoryErr end
    local slots, slotErr = readSlots(player.UserId, inventory)
    if not slots then return false, slotErr end

    local previous = states[player.UserId]
    states[player.UserId] = {
        inventory = inventory,
        slots = cloneSlots(slots),
        refreshedAt = os.clock(),
        lastStationName = previous and previous.lastStationName or nil,
    }
    queueRender(player, 0.05)
    if push then pushUpdates(player, "SYNC") end
    return true
end

local function persistSelection(player, slots)
    if not saveBaseSlots(player.UserId, slots) then return false, "BASE_SAVE_FAILED" end
    if not saveExtraSlots(player.UserId, slots) then return false, "EXTRA_SAVE_FAILED" end
    return true
end

local function setSlot(player, slot, instanceId)
    local ok, err = syncPlayer(player, false)
    if not ok then return {ok=false, code=err or "SYNC_FAILED", message="Owned inventory could not be verified yet."} end

    local state = states[player.UserId]
    local owned = inventoryMap(state.inventory)
    local item = owned[tostring(instanceId or "")]
    if not item then return {ok=false, code="NOT_OWNED", message="That serialized item is not currently owned."} end

    local slots = cloneSlots(state.slots)
    for index = 1, SLOT_COUNT do
        if slots[index] == item.instanceId then slots[index] = "" end
    end
    slots[slot] = item.instanceId

    local saved, saveErr = persistSelection(player, slots)
    if not saved then
        syncPlayer(player, false)
        return {ok=false, code=saveErr or "SAVE_FAILED", message="Showcase selection could not be saved."}
    end

    state.slots = cloneSlots(slots)
    queueRender(player, 0)
    return pushUpdates(player, "SLOT_UPDATED", "Showcase slot updated.")
end

local function clearSlot(player, slot)
    local ok, err = syncPlayer(player, false)
    if not ok then return {ok=false, code=err or "SYNC_FAILED", message="Showcase could not sync yet."} end

    local state = states[player.UserId]
    local slots = cloneSlots(state.slots)
    slots[slot] = ""
    local saved, saveErr = persistSelection(player, slots)
    if not saved then
        syncPlayer(player, false)
        return {ok=false, code=saveErr or "SAVE_FAILED", message="Showcase selection could not be saved."}
    end

    state.slots = cloneSlots(slots)
    queueRender(player, 0)
    return pushUpdates(player, "SLOT_CLEARED", "Showcase slot cleared.")
end

local function handleRequest(player, action, argA, argB, minSlot, maxSlot)
    action = string.upper(tostring(action or "SYNC"))
    if player:GetAttribute("LostFoundPersistenceReady") ~= true then
        return {ok=false, code="NOT_READY", message="Player inventory is still loading."}
    end
    if busy[player.UserId] then return {ok=false, code="BUSY", message="Showcase is processing another request."} end
    busy[player.UserId] = true

    local ok, result = pcall(function()
        if action == "SYNC" then
            local synced, err = syncPlayer(player, false)
            if not synced then return {ok=false, code=err or "SYNC_FAILED", message="Showcase could not sync yet."} end
            return snapshot(player, "SYNC")
        end

        local slot = math.floor(tonumber(argA) or 0)
        if slot < minSlot or slot > maxSlot then
            return {ok=false, code="INVALID_SLOT", message="Invalid showcase slot for this request."}
        end
        if action == "SET_SLOT" then return setSlot(player, slot, argB) end
        if action == "CLEAR_SLOT" then return clearSlot(player, slot) end
        return {ok=false, code="UNKNOWN_ACTION", message="Unknown showcase action."}
    end)

    busy[player.UserId] = nil
    if not ok then
        warn("[LOST FOUND] M5-C.1.3 request failed", result)
        return {ok=false, code="SERVER_ERROR", message="Showcase request failed safely."}
    end
    return result
end

baseRequest.OnServerInvoke = function(player, action, argA, argB)
    return handleRequest(player, action, argA, argB, 1, 3)
end

extraRequest.OnServerInvoke = function(player, action, argA, argB)
    return handleRequest(player, action, argA, argB, 4, 5)
end

local function startPlayer(player)
    task.spawn(function()
        for _ = 1, 120 do
            if not player.Parent then return end
            if player:GetAttribute("LostFoundPersistenceReady") == true
                and type(player:GetAttribute("LostFoundStationId")) == "string"
                and player:GetAttribute("LostFoundStationId") ~= ""
            then
                syncPlayer(player, true)
                queueRender(player, 0.4)
                return
            end
            task.wait(0.25)
        end
    end)

    player:GetAttributeChangedSignal("LostFoundStationId"):Connect(function()
        task.delay(0.20, function()
            if player.Parent and states[player.UserId] then queueRender(player, 0.15) end
        end)
    end)
end

Players.PlayerAdded:Connect(startPlayer)
Players.PlayerRemoving:Connect(function(player)
    local state = states[player.UserId]
    if state and state.lastStationName then clearStationVisual(stationByName(state.lastStationName)) end
    states[player.UserId] = nil
    busy[player.UserId] = nil
    renderQueued[player.UserId] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do startPlayer(player) end

-- Ownership reconciliation remains periodic so traded-away items disappear automatically,
-- but the renderer is idempotent: unchanged instanceId => zero model rebuild/scale/pivot writes.
task.spawn(function()
    while true do
        task.wait(15)
        for _, player in ipairs(Players:GetPlayers()) do
            if player:GetAttribute("LostFoundPersistenceReady") == true and not busy[player.UserId] then
                task.spawn(function()
                    local ok = syncPlayer(player, true)
                    if not ok and states[player.UserId] then queueRender(player, 0.1) end
                end)
            end
        end
    end
end)
