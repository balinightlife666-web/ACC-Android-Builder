-- LOST & FOUND: NIGHT SHIFT — M5-B Personal Collection Showcase v1
-- Lets each player persistently choose up to three owned serialized collectibles
-- to display in their replicated personal station. Selection data is separate from
-- the canonical inventory/economy payload and never grants, duplicates, or moves items.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local PreviewFactory = require(shared:WaitForChild("CollectionPreviewFactory"))

local mainStore = DataStoreService:GetDataStore("LostAndFound_PlayerData_v1")
local showcaseStore = DataStoreService:GetDataStore("LostAndFound_Showcase_v1")

local remotes = ReplicatedStorage:FindFirstChild("LostAndFoundRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "LostAndFoundRemotes"
    remotes.Parent = ReplicatedStorage
end

local request = remotes:FindFirstChild("PersonalShowcaseRequest")
if not request then
    request = Instance.new("RemoteFunction")
    request.Name = "PersonalShowcaseRequest"
    request.Parent = remotes
end

local update = remotes:FindFirstChild("PersonalShowcaseUpdate")
if not update then
    update = Instance.new("RemoteEvent")
    update.Name = "PersonalShowcaseUpdate"
    update.Parent = remotes
end

local RARITY_RANK = {
    COMMON = 1,
    UNCOMMON = 2,
    RARE = 3,
    EPIC = 4,
    ANOMALY = 5,
    SECRET = 6,
}

local RARITY_COLORS = {
    COMMON = Color3.fromRGB(177, 187, 201),
    UNCOMMON = Color3.fromRGB(104, 190, 127),
    RARE = Color3.fromRGB(95, 167, 232),
    EPIC = Color3.fromRGB(177, 115, 226),
    ANOMALY = Color3.fromRGB(88, 221, 224),
    SECRET = Color3.fromRGB(235, 223, 179),
}

local states = {}
local busy = {}

local function keyFor(userId)
    return "u_" .. tostring(userId)
end

local function cleanId(value)
    if type(value) ~= "string" or #value < 1 or #value > 80 then return nil end
    return value
end

local function cloneSlots(slots)
    return {
        tostring(slots and slots[1] or ""),
        tostring(slots and slots[2] or ""),
        tostring(slots and slots[3] or ""),
    }
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
        name = entry.name,
        rarity = entry.rarity,
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
        warn("[LOST FOUND] Showcase inventory read failed for", userId, raw)
        return nil, "INVENTORY_READ_FAILED"
    end

    local result = {}
    local seen = {}
    local inventory = type(raw) == "table" and raw.inventory or nil
    if type(inventory) == "table" then
        for _, rawInstance in ipairs(inventory) do
            local item = publicItem(rawInstance, userId)
            if item and not seen[item.instanceId] then
                seen[item.instanceId] = true
                table.insert(result, item)
            end
        end
    end

    table.sort(result, function(a, b)
        local rankA = RARITY_RANK[a.rarity] or 0
        local rankB = RARITY_RANK[b.rarity] or 0
        if rankA == rankB then
            return (a.serialNumber or math.huge) < (b.serialNumber or math.huge)
        end
        return rankA > rankB
    end)
    return result
end

local function inventoryMap(inventory)
    local map = {}
    for _, item in ipairs(inventory or {}) do
        map[item.instanceId] = item
    end
    return map
end

local function seedSlots(inventory)
    local slots = {"", "", ""}
    local usedCollection = {}
    local usedInstance = {}
    local index = 1

    -- Prefer three different collections so the first public flex is visually varied.
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

local function saveSelection(userId, slots, initialized)
    local clean = cloneSlots(slots)
    local ok, err = pcall(function()
        showcaseStore:UpdateAsync(keyFor(userId), function()
            return {
                version = 1,
                initialized = initialized ~= false,
                slots = clean,
                updatedAt = os.time(),
            }
        end)
    end)
    if not ok then
        warn("[LOST FOUND] Showcase selection save failed for", userId, err)
        return false
    end
    return true
end

local function readSelection(userId, inventory)
    local ok, raw = pcall(function()
        return showcaseStore:GetAsync(keyFor(userId))
    end)
    if not ok then
        warn("[LOST FOUND] Showcase selection read failed for", userId, raw)
        return nil, "SHOWCASE_READ_FAILED"
    end

    local initialized = type(raw) == "table" and raw.initialized == true
    local slots = {"", "", ""}
    if initialized and type(raw.slots) == "table" then
        slots = cloneSlots(raw.slots)
    else
        slots = seedSlots(inventory)
        initialized = true
        saveSelection(userId, slots, true)
    end

    local owned = inventoryMap(inventory)
    local seen = {}
    local changed = false
    for index = 1, 3 do
        local id = cleanId(slots[index])
        if not id or not owned[id] or seen[id] then
            if slots[index] ~= "" then changed = true end
            slots[index] = ""
        else
            slots[index] = id
            seen[id] = true
        end
    end

    if changed then saveSelection(userId, slots, true) end
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

local function makeLabel(primary, item)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "M5BShowcaseLabel"
    billboard.Size = UDim2.fromOffset(158, 44)
    billboard.StudsOffset = Vector3.new(0, 1.65, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 28
    billboard.Parent = primary

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(14, 18, 24)
    frame.BackgroundTransparency = 0.10
    frame.BorderSizePixel = 0
    frame.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = RARITY_COLORS[item.rarity] or Color3.fromRGB(177, 187, 201)
    stroke.Transparency = 0.20
    stroke.Thickness = 1
    stroke.Parent = frame

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -8, 0, 22)
    name.Position = UDim2.fromOffset(4, 1)
    name.BackgroundTransparency = 1
    name.TextColor3 = Color3.fromRGB(240, 243, 247)
    name.Font = Enum.Font.GothamBold
    name.TextSize = 9
    name.TextWrapped = true
    name.Text = tostring(item.name) .. " • " .. tostring(item.rarity)
    name.Parent = frame

    local serial = Instance.new("TextLabel")
    serial.Size = UDim2.new(1, -8, 0, 17)
    serial.Position = UDim2.fromOffset(4, 24)
    serial.BackgroundTransparency = 1
    serial.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(177, 187, 201)
    serial.Font = Enum.Font.RobotoMono
    serial.TextSize = 9
    serial.Text = tostring(item.serial)
    serial.Parent = frame
end

local function render(player)
    local state = states[player.UserId]
    if not state then return false end

    local station = currentStation(player)
    if not station then return false end
    local showcase = station:FindFirstChild("PublicShowcase")
    if not showcase then return false end

    local old = showcase:FindFirstChild("DisplayedItems")
    if old then old:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name = "DisplayedItems"
    folder:SetAttribute("M5BManualShowcase", true)
    folder.Parent = showcase

    local owned = inventoryMap(state.inventory)
    for slot = 1, 3 do
        local item = owned[state.slots[slot]]
        local anchor = showcase:FindFirstChild("DisplayAnchor" .. tostring(slot))
        if item and anchor and anchor:IsA("BasePart") then
            local model = PreviewFactory.Create(item.collectionId, folder, false)
            model.Name = "M5B_Slot_" .. tostring(slot)
            model:SetAttribute("InstanceId", item.instanceId)
            model:SetAttribute("CollectionId", item.collectionId)
            model:SetAttribute("Serial", item.serial)
            model:SetAttribute("Rarity", item.rarity)
            pcall(function() model:ScaleTo(0.20) end)
            model:PivotTo(anchor.CFrame * CFrame.Angles(0, math.rad(180), 0))
            local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if primary then makeLabel(primary, item) end
        end
    end

    station:SetAttribute("ShowcaseCount", (state.slots[1] ~= "" and 1 or 0) + (state.slots[2] ~= "" and 1 or 0) + (state.slots[3] ~= "" and 1 or 0))
    station:SetAttribute("ShowcaseVersion", "M5B_V1")
    return true
end

local function snapshot(player, message, code)
    local state = states[player.UserId]
    if not state then return nil end
    local selected = inventoryMap(state.inventory)
    local slotItems = {}
    for slot = 1, 3 do
        slotItems[slot] = selected[state.slots[slot]]
    end
    return {
        ok = true,
        code = code or "SYNC",
        message = message,
        slots = cloneSlots(state.slots),
        slotItems = slotItems,
        inventory = state.inventory,
    }
end

local function refresh(player, push)
    if not player or not player.Parent then return false end
    if player:GetAttribute("LostFoundPersistenceReady") ~= true then return false end

    local inventory, inventoryErr = readInventory(player.UserId)
    if not inventory then return false, inventoryErr end
    local slots, selectionErr = readSelection(player.UserId, inventory)
    if not slots then return false, selectionErr end

    states[player.UserId] = {
        inventory = inventory,
        slots = slots,
        refreshedAt = os.clock(),
    }
    render(player)
    if push then update:FireClient(player, "SYNC", snapshot(player)) end
    return true
end

local function setSlot(player, slot, instanceId)
    slot = math.floor(tonumber(slot) or 0)
    if slot < 1 or slot > 3 then
        return { ok = false, code = "INVALID_SLOT", message = "Showcase slot must be 1, 2, or 3." }
    end

    local refreshed, refreshErr = refresh(player, false)
    if not refreshed then
        return { ok = false, code = refreshErr or "SYNC_FAILED", message = "Owned inventory could not be verified yet." }
    end

    local state = states[player.UserId]
    local owned = inventoryMap(state.inventory)
    local item = owned[tostring(instanceId or "")]
    if not item then
        return { ok = false, code = "NOT_OWNED", message = "That serialized item is not currently owned." }
    end

    for index = 1, 3 do
        if state.slots[index] == item.instanceId then state.slots[index] = "" end
    end
    state.slots[slot] = item.instanceId

    if not saveSelection(player.UserId, state.slots, true) then
        refresh(player, false)
        return { ok = false, code = "SAVE_FAILED", message = "Showcase selection could not be saved." }
    end

    render(player)
    local data = snapshot(player, "Showcase slot updated.", "SLOT_UPDATED")
    update:FireClient(player, "SLOT_UPDATED", data)
    return data
end

local function clearSlot(player, slot)
    slot = math.floor(tonumber(slot) or 0)
    if slot < 1 or slot > 3 then
        return { ok = false, code = "INVALID_SLOT", message = "Showcase slot must be 1, 2, or 3." }
    end

    local refreshed, refreshErr = refresh(player, false)
    if not refreshed then
        return { ok = false, code = refreshErr or "SYNC_FAILED", message = "Owned inventory could not be verified yet." }
    end
    local state = states[player.UserId]
    state.slots[slot] = ""
    if not saveSelection(player.UserId, state.slots, true) then
        return { ok = false, code = "SAVE_FAILED", message = "Showcase selection could not be saved." }
    end
    render(player)
    local data = snapshot(player, "Showcase slot cleared.", "SLOT_CLEARED")
    update:FireClient(player, "SLOT_CLEARED", data)
    return data
end

request.OnServerInvoke = function(player, action, argA, argB)
    action = string.upper(tostring(action or "SYNC"))
    if player:GetAttribute("LostFoundPersistenceReady") ~= true then
        return { ok = false, code = "NOT_READY", message = "Player inventory is still loading." }
    end
    if busy[player.UserId] then
        return { ok = false, code = "BUSY", message = "Showcase is processing another request." }
    end
    busy[player.UserId] = true

    local ok, result = pcall(function()
        if action == "SYNC" then
            local refreshed, err = refresh(player, false)
            if not refreshed then return { ok = false, code = err or "SYNC_FAILED", message = "Showcase inventory is not ready." } end
            return snapshot(player)
        elseif action == "SET_SLOT" then
            return setSlot(player, argA, argB)
        elseif action == "CLEAR_SLOT" then
            return clearSlot(player, argA)
        end
        return { ok = false, code = "INVALID_ACTION", message = "Unknown showcase action." }
    end)

    busy[player.UserId] = nil
    if not ok then
        warn("[LOST FOUND] Personal Showcase request failed:", result)
        return { ok = false, code = "SERVER_ERROR", message = "Showcase request failed safely." }
    end
    return result
end

local boundShowcases = setmetatable({}, { __mode = "k" })

local function bindShowcase(showcase)
    if not showcase or boundShowcases[showcase] then return end
    boundShowcases[showcase] = true
    showcase.ChildAdded:Connect(function(child)
        if child.Name ~= "DisplayedItems" or child:GetAttribute("M5BManualShowcase") == true then return end
        -- M4-D still rebuilds its legacy automatic top-three folder on collection sync.
        -- Replace it only after that synchronous build has finished, without touching inventory.
        task.delay(0.20, function()
            if not showcase.Parent then return end
            local station = showcase.Parent
            local userId = math.floor(tonumber(station:GetAttribute("OwnerUserId")) or 0)
            local player = userId > 0 and Players:GetPlayerByUserId(userId) or nil
            if player and states[userId] then render(player) end
        end)
    end)
end

local function bindWorld(world)
    if not world or world.Name ~= "LostAndFoundM4D" then return end
    local function bindStation(station)
        if not station:IsA("Model") or string.sub(station.Name, 1, 8) ~= "Station_" then return end
        local showcase = station:FindFirstChild("PublicShowcase")
        if showcase then bindShowcase(showcase) end
        station.ChildAdded:Connect(function(child)
            if child.Name == "PublicShowcase" then task.defer(bindShowcase, child) end
        end)
    end
    for _, station in ipairs(world:GetChildren()) do bindStation(station) end
    world.ChildAdded:Connect(function(station) task.defer(bindStation, station) end)
end

local currentWorld = workspace:FindFirstChild("LostAndFoundM4D")
if currentWorld then task.defer(bindWorld, currentWorld) end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundM4D" then task.defer(bindWorld, child) end
end)

local function bindPlayer(player)
    player:GetAttributeChangedSignal("LostFoundStationId"):Connect(function()
        if states[player.UserId] then task.delay(0.25, render, player) end
    end)
    task.spawn(function()
        for _ = 1, 100 do
            if not player.Parent then return end
            if player:GetAttribute("LostFoundPersistenceReady") == true and type(player:GetAttribute("LostFoundStationId")) == "string" and player:GetAttribute("LostFoundStationId") ~= "" then
                refresh(player, true)
                return
            end
            task.wait(0.25)
        end
    end)
end

Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player)
    states[player.UserId] = nil
    busy[player.UserId] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end

-- Ownership reconciliation. Trades are persisted immediately by TradeService; this
-- periodic pass removes a displayed instance after it is no longer owned, even if
-- no Showcase UI is open. It never changes the canonical inventory itself.
task.spawn(function()
    while true do
        task.wait(12)
        for _, player in ipairs(Players:GetPlayers()) do
            if player:GetAttribute("LostFoundPersistenceReady") == true and not busy[player.UserId] then
                task.spawn(function()
                    local ok = refresh(player, true)
                    if not ok and states[player.UserId] then render(player) end
                end)
            end
        end
    end
end)
