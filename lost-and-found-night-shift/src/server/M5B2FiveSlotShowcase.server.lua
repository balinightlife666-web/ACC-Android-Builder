-- LOST & FOUND: NIGHT SHIFT — M5-B.2 Five-Slot Showcase
-- Expands the public showcase from 3 to 5 slots without changing canonical inventory,
-- serials, trading, drops, Credits, XP, or case logic. Slots 1-3 remain owned by the
-- existing M5-B service; slots 4-5 use a presentation-only persistence store.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local PreviewFactory = require(shared:WaitForChild("CollectionPreviewFactory"))
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local mainStore = DataStoreService:GetDataStore("LostAndFound_PlayerData_v1")
local baseShowcaseStore = DataStoreService:GetDataStore("LostAndFound_Showcase_v1")
local extraStore = DataStoreService:GetDataStore("LostAndFound_ShowcaseExtra_v1")

local remotes = ReplicatedStorage:FindFirstChild("LostAndFoundRemotes") or Instance.new("Folder")
remotes.Name = "LostAndFoundRemotes"
remotes.Parent = ReplicatedStorage

local request = remotes:FindFirstChild("M5B2ShowcaseRequest") or Instance.new("RemoteFunction")
request.Name = "M5B2ShowcaseRequest"
request.Parent = remotes

local update = remotes:FindFirstChild("M5B2ShowcaseUpdate") or Instance.new("RemoteEvent")
update.Name = "M5B2ShowcaseUpdate"
update.Parent = remotes

local SLOT_COUNT = 5
local ITEM_SCALE = 0.30
local RACK_CENTER_X_OFFSET = 2.0
local RACK_CENTER_Y = 10.25
local RACK_BACK_Z_OFFSET = -13.12
local RACK_FRONT_Z_OFFSET = -12.12
local SLOT_X = {-7.05, -3.52, 0, 3.52, 7.05}

local RARITY_COLORS = {
    COMMON = Color3.fromRGB(177, 187, 201),
    UNCOMMON = Color3.fromRGB(104, 190, 127),
    RARE = Color3.fromRGB(95, 167, 232),
    EPIC = Color3.fromRGB(177, 115, 226),
    ANOMALY = Color3.fromRGB(88, 221, 224),
    SECRET = Color3.fromRGB(235, 223, 179),
}

local FALLBACK = {
    panel = Color3.fromRGB(23, 29, 38),
    trim = Color3.fromRGB(75, 85, 99),
    accent = Color3.fromRGB(224, 163, 64),
    base = Color3.fromRGB(38, 45, 56),
}

local states = {}
local busy = {}
local boundStations = setmetatable({}, {__mode = "k"})
local folderConnections = setmetatable({}, {__mode = "k"})

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
    local result = emptySlots()
    for slot = 1, SLOT_COUNT do
        result[slot] = tostring(slots and slots[slot] or "")
    end
    return result
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
    if not ok then return nil, "INVENTORY_READ_FAILED" end

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
        local rank = {COMMON=1,UNCOMMON=2,RARE=3,EPIC=4,ANOMALY=5,SECRET=6}
        local ar, br = rank[a.rarity] or 0, rank[b.rarity] or 0
        if ar == br then return (a.serialNumber or math.huge) < (b.serialNumber or math.huge) end
        return ar > br
    end)
    return result
end

local function inventoryMap(inventory)
    local map = {}
    for _, item in ipairs(inventory or {}) do map[item.instanceId] = item end
    return map
end

local function readBaseSlots(userId)
    local slots = emptySlots()
    local ok, raw = pcall(function() return baseShowcaseStore:GetAsync(keyFor(userId)) end)
    if not ok then return nil, "BASE_SHOWCASE_READ_FAILED" end
    if type(raw) == "table" and type(raw.slots) == "table" then
        for slot = 1, 3 do slots[slot] = tostring(raw.slots[slot] or "") end
    end
    return slots
end

local function saveExtraSlots(userId, slots)
    local slot4 = tostring(slots[4] or "")
    local slot5 = tostring(slots[5] or "")
    local ok = pcall(function()
        extraStore:UpdateAsync(keyFor(userId), function()
            return {version = 1, slot4 = slot4, slot5 = slot5, updatedAt = os.time()}
        end)
    end)
    return ok
end

local function readExtraSlots(userId)
    local ok, raw = pcall(function() return extraStore:GetAsync(keyFor(userId)) end)
    if not ok then return nil, "EXTRA_SHOWCASE_READ_FAILED" end
    return tostring(type(raw) == "table" and raw.slot4 or ""), tostring(type(raw) == "table" and raw.slot5 or "")
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

local function paletteFor(station)
    local skin = StationSkinRegistry.Get(station:GetAttribute("SkinId"))
    return skin and skin.palette or {}
end

local function roleColor(station, role)
    return paletteFor(station)[role] or FALLBACK[role] or Color3.fromRGB(80, 88, 100)
end

local function stylePart(station, target, role, material)
    target:SetAttribute("StationSkinRole", role)
    target.Color = roleColor(station, role)
    target.Material = material or Enum.Material.Metal
    target.Anchored = true
    target.CanCollide = false
    target.CanTouch = false
    target.CanQuery = false
    target.CastShadow = false
    target.TopSurface = Enum.SurfaceType.Smooth
    target.BottomSurface = Enum.SurfaceType.Smooth
end

local function makePart(station, parent, name, size, cframe, role, material)
    local part = parent:FindFirstChild(name)
    if not part or not part:IsA("BasePart") then
        if part then part:Destroy() end
        part = Instance.new("Part")
        part.Name = name
        part.Parent = parent
    end
    part.Size = size
    part.CFrame = cframe
    stylePart(station, part, role, material)
    return part
end

local function setSurfaceText(part, text, color, textSize)
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("SurfaceGui") then child:Destroy() end
    end
    local gui = Instance.new("SurfaceGui")
    gui.Name = "M5B2Surface"
    gui.Face = Enum.NormalId.Front
    gui.LightInfluence = 0
    gui.PixelsPerStud = 62
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 11
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = gui
end

local function clearOldRack(showcase)
    for _, child in ipairs(showcase:GetChildren()) do
        if string.sub(child.Name, 1, 5) == "M5B1_" or child.Name == "ShelfBack" or child.Name == "Title" or string.match(child.Name, "^Shelf%d+$") then
            child:Destroy()
        end
    end
end

local function ensureRack(station)
    local showcase = station:FindFirstChild("PublicShowcase")
    local bay = station:FindFirstChild("BayFloor")
    if not showcase or not showcase:IsA("Model") or not bay or not bay:IsA("BasePart") then return nil end

    clearOldRack(showcase)
    local x = bay.Position.X + RACK_CENTER_X_OFFSET
    local zBack = bay.Position.Z + RACK_BACK_Z_OFFSET
    local zFront = bay.Position.Z + RACK_FRONT_Z_OFFSET

    makePart(station, showcase, "M5B2_Backboard", Vector3.new(18.35, 5.0, 0.32), CFrame.new(x, RACK_CENTER_Y, zBack), "panel", Enum.Material.Metal)
    makePart(station, showcase, "M5B2_TopRail", Vector3.new(18.7, 0.22, 0.44), CFrame.new(x, 12.78, zBack + 0.04), "accent", Enum.Material.Neon)
    makePart(station, showcase, "M5B2_BottomRail", Vector3.new(18.7, 0.20, 0.44), CFrame.new(x, 7.73, zBack + 0.04), "accent", Enum.Material.Neon)
    makePart(station, showcase, "M5B2_LeftRail", Vector3.new(0.20, 5.1, 0.42), CFrame.new(x - 9.25, 10.25, zBack + 0.04), "trim", Enum.Material.Metal)
    makePart(station, showcase, "M5B2_RightRail", Vector3.new(0.20, 5.1, 0.42), CFrame.new(x + 9.25, 10.25, zBack + 0.04), "trim", Enum.Material.Metal)

    local title = makePart(station, showcase, "M5B2_Title", Vector3.new(17.5, 0.68, 0.18), CFrame.new(x, 12.25, zBack + 0.20), "base", Enum.Material.SmoothPlastic)
    setSurfaceText(title, "PERSONAL COLLECTION  //  5 SLOT", roleColor(station, "accent"), 15)

    for slot = 1, SLOT_COUNT do
        local sx = x + SLOT_X[slot]
        if slot < SLOT_COUNT then
            local dividerX = x + (SLOT_X[slot] + SLOT_X[slot + 1]) * 0.5
            makePart(station, showcase, "M5B2_Divider" .. slot, Vector3.new(0.09, 3.72, 0.22), CFrame.new(dividerX, 10.03, zBack + 0.21), "trim", Enum.Material.Metal)
        end
        makePart(station, showcase, "M5B2_SlotGlow" .. slot, Vector3.new(3.05, 0.10, 0.14), CFrame.new(sx, 11.62, zBack + 0.23), "accent", Enum.Material.Neon)
        makePart(station, showcase, "M5B2_Shelf" .. slot, Vector3.new(3.05, 0.18, 1.86), CFrame.new(sx, 9.02, zFront), "trim", Enum.Material.Metal)
        makePart(station, showcase, "M5B2_Plinth" .. slot, Vector3.new(2.52, 0.24, 1.42), CFrame.new(sx, 9.18, zFront - 0.02), "base", Enum.Material.SmoothPlastic)

        local anchor = showcase:FindFirstChild("DisplayAnchor" .. slot)
        if not anchor or not anchor:IsA("BasePart") then
            if anchor then anchor:Destroy() end
            anchor = Instance.new("Part")
            anchor.Name = "DisplayAnchor" .. slot
            anchor.Parent = showcase
        end
        anchor.Size = Vector3.new(0.4, 0.4, 0.4)
        anchor.CFrame = CFrame.new(sx, 10.18, zFront - 0.02)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false

        local plate = makePart(station, showcase, "M5B2_InfoPlate" .. slot, Vector3.new(3.15, 0.95, 0.16), CFrame.new(sx, 8.28, zBack + 0.23), "base", Enum.Material.SmoothPlastic)
        plate:SetAttribute("M5B2Slot", slot)
        setSurfaceText(plate, "SLOT " .. slot .. "\nEMPTY", roleColor(station, "trim"), 10)
    end

    showcase:SetAttribute("M5B2Layout", "FIVE_SLOT_LARGE_V1")
    station:SetAttribute("ShowcaseLayoutVersion", "M5B2_FIVE_SLOT_LARGE_V1")
    return showcase
end

local function setPlate(station, showcase, slot, item)
    local plate = showcase:FindFirstChild("M5B2_InfoPlate" .. slot)
    if not plate or not plate:IsA("BasePart") then return end
    if not item then
        setSurfaceText(plate, "SLOT " .. slot .. "\nEMPTY", roleColor(station, "trim"), 10)
        return
    end
    local accent = RARITY_COLORS[item.rarity] or roleColor(station, "accent")
    setSurfaceText(plate, string.format("%s  •  %s\n%s", tostring(item.name), tostring(item.rarity), tostring(item.serial)), accent, 9)
end

local function removeFloatingLabels(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BillboardGui") and (descendant.Name == "M5BShowcaseLabel" or descendant.Name == "SerialLabel") then
            descendant:Destroy()
        end
    end
end

local function renderCached(player)
    local state = states[player.UserId]
    local station = currentStation(player)
    if not state or not station then return false end
    local showcase = station:FindFirstChild("PublicShowcase")
    if not showcase then return false end
    if station:GetAttribute("ShowcaseLayoutVersion") ~= "M5B2_FIVE_SLOT_LARGE_V1" then
        showcase = ensureRack(station) or showcase
    end

    local folder = showcase:FindFirstChild("DisplayedItems")
    if not folder or not folder:IsA("Folder") then return false end
    local owned = inventoryMap(state.inventory)
    local modelsBySlot = {}

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            local slot = tonumber(string.match(child.Name, "M5B_Slot_(%d+)")) or tonumber(string.match(child.Name, "M5B2_Slot_(%d+)")) or tonumber(string.match(child.Name, "Display_(%d+)"))
            if slot and slot >= 1 and slot <= SLOT_COUNT then
                modelsBySlot[slot] = child
                removeFloatingLabels(child)
                pcall(function() child:ScaleTo(ITEM_SCALE) end)
                local anchor = showcase:FindFirstChild("DisplayAnchor" .. slot)
                if anchor and anchor:IsA("BasePart") then child:PivotTo(anchor.CFrame * CFrame.Angles(0, math.rad(180), 0)) end
            end
        end
    end

    for slot = 4, 5 do
        local old = modelsBySlot[slot]
        if old then old:Destroy() modelsBySlot[slot] = nil end
        local item = owned[state.slots[slot]]
        local anchor = showcase:FindFirstChild("DisplayAnchor" .. slot)
        if item and anchor and anchor:IsA("BasePart") then
            local model = PreviewFactory.Create(item.collectionId, folder, false)
            model.Name = "M5B2_Slot_" .. slot
            model:SetAttribute("InstanceId", item.instanceId)
            model:SetAttribute("CollectionId", item.collectionId)
            model:SetAttribute("Serial", item.serial)
            model:SetAttribute("Rarity", item.rarity)
            pcall(function() model:ScaleTo(ITEM_SCALE) end)
            model:PivotTo(anchor.CFrame * CFrame.Angles(0, math.rad(180), 0))
            removeFloatingLabels(model)
            modelsBySlot[slot] = model
        end
    end

    for slot = 1, SLOT_COUNT do
        local item = owned[state.slots[slot]]
        setPlate(station, showcase, slot, item)
    end

    station:SetAttribute("ShowcaseCount", (function()
        local count = 0
        for slot = 1, SLOT_COUNT do if state.slots[slot] ~= "" then count += 1 end end
        return count
    end)())
    station:SetAttribute("ShowcaseVersion", "M5B2_FIVE_SLOT_V1")
    return true
end

local function reconcile(player, push)
    if not player or not player.Parent or player:GetAttribute("LostFoundPersistenceReady") ~= true then return false, "NOT_READY" end
    local inventory, inventoryErr = readInventory(player.UserId)
    if not inventory then return false, inventoryErr end
    local slots, baseErr = readBaseSlots(player.UserId)
    if not slots then return false, baseErr end
    local slot4, slot5 = readExtraSlots(player.UserId)
    if slot4 == nil then return false, slot5 end
    slots[4], slots[5] = slot4, slot5

    local owned = inventoryMap(inventory)
    local seen = {}
    local extraChanged = false
    for slot = 1, SLOT_COUNT do
        local id = cleanId(slots[slot])
        if not id or not owned[id] or seen[id] then
            if slot >= 4 and slots[slot] ~= "" then extraChanged = true end
            slots[slot] = ""
        else
            slots[slot] = id
            seen[id] = true
        end
    end
    if extraChanged then saveExtraSlots(player.UserId, slots) end

    states[player.UserId] = {inventory = inventory, slots = cloneSlots(slots), refreshedAt = os.clock()}
    renderCached(player)
    if push then update:FireClient(player, "SYNC", {ok=true, code="SYNC", slots=cloneSlots(slots), inventory=inventory}) end
    return true
end

local function snapshot(player, code, message)
    local state = states[player.UserId]
    if not state then return {ok=false, code="NOT_READY", message="Showcase state is not ready."} end
    local owned = inventoryMap(state.inventory)
    local slotItems = {}
    for slot = 1, SLOT_COUNT do slotItems[slot] = owned[state.slots[slot]] end
    return {ok=true, code=code or "SYNC", message=message, slots=cloneSlots(state.slots), slotItems=slotItems, inventory=state.inventory}
end

local function setExtraSlot(player, slot, instanceId)
    slot = math.floor(tonumber(slot) or 0)
    if slot < 4 or slot > 5 then return {ok=false, code="INVALID_SLOT", message="Extra showcase slot must be 4 or 5."} end
    local ok, err = reconcile(player, false)
    if not ok then return {ok=false, code=err or "SYNC_FAILED", message="Owned inventory could not be verified yet."} end
    local state = states[player.UserId]
    local owned = inventoryMap(state.inventory)
    local item = owned[tostring(instanceId or "")]
    if not item then return {ok=false, code="NOT_OWNED", message="That serialized item is not currently owned."} end

    for index = 1, SLOT_COUNT do
        if state.slots[index] == item.instanceId then
            if index <= 3 then return {ok=false, code="ALREADY_DISPLAYED", occupiedSlot=index, message="That item is already displayed in a base showcase slot."} end
            state.slots[index] = ""
        end
    end
    state.slots[slot] = item.instanceId
    if not saveExtraSlots(player.UserId, state.slots) then return {ok=false, code="SAVE_FAILED", message="Extra showcase slots could not be saved."} end
    renderCached(player)
    local data = snapshot(player, "SLOT_UPDATED", "Showcase slot updated.")
    update:FireClient(player, "SLOT_UPDATED", data)
    return data
end

local function clearExtraSlot(player, slot)
    slot = math.floor(tonumber(slot) or 0)
    if slot < 4 or slot > 5 then return {ok=false, code="INVALID_SLOT", message="Extra showcase slot must be 4 or 5."} end
    local ok, err = reconcile(player, false)
    if not ok then return {ok=false, code=err or "SYNC_FAILED", message="Owned inventory could not be verified yet."} end
    states[player.UserId].slots[slot] = ""
    if not saveExtraSlots(player.UserId, states[player.UserId].slots) then return {ok=false, code="SAVE_FAILED", message="Extra showcase slots could not be saved."} end
    renderCached(player)
    local data = snapshot(player, "SLOT_CLEARED", "Showcase slot cleared.")
    update:FireClient(player, "SLOT_CLEARED", data)
    return data
end

request.OnServerInvoke = function(player, action, argA, argB)
    action = string.upper(tostring(action or "SYNC"))
    if busy[player.UserId] then return {ok=false, code="BUSY", message="Showcase is processing another request."} end
    busy[player.UserId] = true
    local result
    if action == "SYNC" then
        local ok, err = reconcile(player, false)
        result = ok and snapshot(player, "SYNC") or {ok=false, code=err or "SYNC_FAILED", message="Showcase could not sync yet."}
    elseif action == "SET_SLOT" then
        result = setExtraSlot(player, argA, argB)
    elseif action == "CLEAR_SLOT" then
        result = clearExtraSlot(player, argA)
    else
        result = {ok=false, code="UNKNOWN_ACTION", message="Unknown showcase action."}
    end
    busy[player.UserId] = nil
    return result
end

local function bindFolder(player, station, showcase, folder)
    if folderConnections[folder] then return end
    folderConnections[folder] = true
    local queued = false
    local function queueRender()
        if queued then return end
        queued = true
        task.delay(0.12, function()
            queued = false
            if player.Parent then renderCached(player) end
        end)
    end
    folder.ChildAdded:Connect(queueRender)
    folder.ChildRemoved:Connect(queueRender)
    queueRender()
end

local function bindStation(player)
    local station = currentStation(player)
    if not station then return end
    if boundStations[station] ~= player.UserId then
        boundStations[station] = player.UserId
        task.spawn(function()
            for _ = 1, 60 do
                if not station.Parent then return end
                local version = tostring(station:GetAttribute("ShowcaseLayoutVersion") or "")
                if string.find(version, "M5B1", 1, true) or string.find(version, "M5B2", 1, true) then break end
                task.wait(0.1)
            end
            local showcase = ensureRack(station)
            if not showcase then return end
            station:GetAttributeChangedSignal("SkinId"):Connect(function()
                task.defer(function()
                    if station.Parent then ensureRack(station) renderCached(player) end
                end)
            end)
            local currentFolder = showcase:FindFirstChild("DisplayedItems")
            if currentFolder then bindFolder(player, station, showcase, currentFolder) end
            showcase.ChildAdded:Connect(function(child)
                if child.Name == "DisplayedItems" and child:IsA("Folder") then bindFolder(player, station, showcase, child) end
            end)
            task.delay(0.25, function() if player.Parent then renderCached(player) end end)
        end)
    end
end

local function startPlayer(player)
    task.spawn(function()
        for _ = 1, 120 do
            if not player.Parent then return end
            if player:GetAttribute("LostFoundPersistenceReady") == true and player:GetAttribute("LostFoundStationId") then break end
            task.wait(0.25)
        end
        if not player.Parent then return end
        reconcile(player, true)
        bindStation(player)
    end)

    player:GetAttributeChangedSignal("LostFoundStationId"):Connect(function()
        task.delay(0.15, function()
            if player.Parent then reconcile(player, false) bindStation(player) renderCached(player) end
        end)
    end)
end

Players.PlayerAdded:Connect(startPlayer)
Players.PlayerRemoving:Connect(function(player)
    states[player.UserId] = nil
    busy[player.UserId] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do startPlayer(player) end

-- Low-frequency reconciliation catches trade ownership changes without touching TradeService.
task.spawn(function()
    while true do
        task.wait(12)
        for _, player in ipairs(Players:GetPlayers()) do
            if player:GetAttribute("LostFoundPersistenceReady") == true then
                reconcile(player, true)
                bindStation(player)
            end
        end
    end
end)
