-- LOST & FOUND: NIGHT SHIFT — M5-C.1.3 Stable Showcase Service
-- Final non-destructive five-slot showcase authority.
--
-- Root cause fixed here:
-- 1) M5-B base showcase destroyed/recreated DisplayedItems during refresh.
-- 2) M5-B.2 rescaled/re-pivoted existing models and recreated slots 4-5.
-- 3) M5-B.1 rewrote the rack back to three slots and rescaled slots 1-3.
-- 4) PersonalShiftRuntime still rebuilds its legacy automatic top-three DisplayedItems.
--
-- M5-C.1.3 keeps its visible collectibles in a separate stable folder that legacy code
-- never destroys, suppresses the legacy automatic preview factory output, and changes a
-- visible model only when the selected serialized instance actually changes/trades/leaves.
-- All fitting/refinement happens off-world before replication. No generated images,
-- decals, external textures or external assets.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local CollectionRegistry = require(shared:WaitForChild("CollectionRegistry"))
local PreviewFactory = require(shared:WaitForChild("CollectionPreviewFactory"))
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local VERSION = "M5C13_STABLE_SHOWCASE_V2"
local SLOT_COUNT = 5
local STABLE_FOLDER_NAME = "M5C13StableItems"

local mainStore = DataStoreService:GetDataStore("LostAndFound_PlayerData_v1")
local baseStore = DataStoreService:GetDataStore("LostAndFound_Showcase_v1")
local extraStore = DataStoreService:GetDataStore("LostAndFound_ShowcaseExtra_v1")

local RARITY_RANK = {
    COMMON = 1,
    UNCOMMON = 2,
    RARE = 3,
    EPIC = 4,
    ANOMALY = 5,
    SECRET = 6,
}

local RARITY_STYLE = {
    COMMON = {color=Color3.fromRGB(177,187,201), rank=1, light=0.00},
    UNCOMMON = {color=Color3.fromRGB(104,190,127), rank=2, light=0.00},
    RARE = {color=Color3.fromRGB(95,167,232), rank=3, light=0.00},
    EPIC = {color=Color3.fromRGB(177,115,226), rank=4, light=0.42},
    ANOMALY = {color=Color3.fromRGB(88,221,224), rank=5, light=0.55},
    SECRET = {color=Color3.fromRGB(235,223,179), rank=6, light=0.65},
}

local PROFILES = {
    hardcase_suitcase = {h=2.48,w=2.58,d=1.48,yaw=180,pitch=0,z=0},
    vintage_suitcase = {h=2.42,w=2.55,d=1.46,yaw=180,pitch=0,z=0},
    backpack = {h=2.58,w=2.25,d=1.44,yaw=180,pitch=0,z=0},
    cardboard_box = {h=2.25,w=2.50,d=1.50,yaw=180,pitch=0,z=0},
    teddy_bear = {h=2.66,w=2.32,d=1.48,yaw=180,pitch=0,z=0},
    camera_lens = {h=2.02,w=2.12,d=1.42,yaw=168,pitch=-5,z=0},
    evidence_tag = {h=2.22,w=2.48,d=0.72,yaw=180,pitch=-3,z=-0.03},
    passport = {h=2.62,w=2.10,d=0.82,yaw=180,pitch=-4,z=-0.03},
    toy_train = {h=2.10,w=2.62,d=1.42,yaw=164,pitch=0,z=0},
    power_adapter = {h=2.05,w=2.30,d=1.32,yaw=172,pitch=-3,z=0},
    formal_shoe = {h=1.75,w=2.62,d=1.30,yaw=158,pitch=-2,z=0},
    name_patch = {h=2.05,w=2.50,d=0.70,yaw=180,pitch=-4,z=-0.03},
    paperback = {h=2.62,w=2.05,d=0.82,yaw=180,pitch=-4,z=-0.03},
    mass_readout = {h=2.15,w=2.58,d=1.18,yaw=180,pitch=-3,z=0},
}
local DEFAULT_PROFILE = {h=2.35,w=2.45,d=1.40,yaw=180,pitch=0,z=0}

local FALLBACK = {
    panel = Color3.fromRGB(23,29,38),
    trim = Color3.fromRGB(75,85,99),
    accent = Color3.fromRGB(224,163,64),
    base = Color3.fromRGB(38,45,56),
}

-- PersonalShiftRuntime still calls CollectionPreviewFactory.Create for its automatic
-- top-three DisplayedItems. Its folder destruction is harmless once our visible models
-- live elsewhere, but its temporary models would still flash on screen. Suppress only
-- that exact legacy station parent and return an empty Model that safely accepts PivotTo.
local ORIGINAL_PREVIEW_CREATE = PreviewFactory.__M5C13OriginalCreate or PreviewFactory.Create
if PreviewFactory.__M5C13LegacySuppression ~= true then
    PreviewFactory.__M5C13OriginalCreate = ORIGINAL_PREVIEW_CREATE
    PreviewFactory.Create = function(collectionId, parent, ...)
        if parent
            and parent.Name == "DisplayedItems"
            and parent.Parent
            and parent.Parent.Name == "PublicShowcase"
        then
            local dummy = Instance.new("Model")
            dummy.Name = "M5C13LegacySuppressed"
            dummy:SetAttribute("M5C13LegacySuppressed", true)
            dummy.Parent = parent
            return dummy
        end
        return ORIGINAL_PREVIEW_CREATE(collectionId, parent, ...)
    end
    PreviewFactory.__M5C13LegacySuppression = true
end

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

local states = {}
local busy = {}
local renderQueued = {}
local boundStations = setmetatable({}, {__mode="k"})

local function keyFor(userId)
    return "u_" .. tostring(userId)
end

local function cleanId(value)
    if type(value) ~= "string" or #value < 1 or #value > 80 then return nil end
    return value
end

local function emptySlots()
    return {"","","","",""}
end

local function cloneSlots(slots)
    local out = emptySlots()
    for slot=1,SLOT_COUNT do out[slot] = tostring(slots and slots[slot] or "") end
    return out
end

local function publicItem(raw, userId)
    if type(raw) ~= "table" then return nil end
    local instanceId = cleanId(raw.instanceId)
    local collectionId = cleanId(raw.collectionId)
    local serial = type(raw.serial)=="string" and string.sub(raw.serial,1,48) or nil
    if not instanceId or not collectionId or not serial then return nil end
    if math.max(0,math.floor(tonumber(raw.currentOwnerUserId) or 0)) ~= userId then return nil end
    local entry = CollectionRegistry.Get(collectionId)
    if not entry then return nil end
    return {
        instanceId=instanceId,
        collectionId=collectionId,
        name=tostring(entry.name or collectionId),
        rarity=tostring(entry.rarity or "COMMON"),
        serial=serial,
        serialNumber=math.max(1,math.floor(tonumber(raw.serialNumber) or 1)),
        edition=tostring(raw.edition or entry.edition or "S1"),
        tradeCount=math.max(0,math.floor(tonumber(raw.tradeCount) or 0)),
    }
end

local function readInventory(userId)
    local ok, raw = pcall(function() return mainStore:GetAsync(keyFor(userId)) end)
    if not ok then
        warn("[LOST FOUND] M5-C.1.3 inventory read failed",userId,raw)
        return nil,"INVENTORY_READ_FAILED"
    end
    local result, seen = {}, {}
    local inventory = type(raw)=="table" and raw.inventory or nil
    if type(inventory)=="table" then
        for _,candidate in ipairs(inventory) do
            local item = publicItem(candidate,userId)
            if item and not seen[item.instanceId] then
                seen[item.instanceId]=true
                table.insert(result,item)
            end
        end
    end
    table.sort(result,function(a,b)
        local ar,br=RARITY_RANK[a.rarity] or 0,RARITY_RANK[b.rarity] or 0
        if ar==br then return (a.serialNumber or math.huge)<(b.serialNumber or math.huge) end
        return ar>br
    end)
    return result
end

local function inventoryMap(inventory)
    local map={}
    for _,item in ipairs(inventory or {}) do map[item.instanceId]=item end
    return map
end

local function seedBaseSlots(inventory)
    local slots={"","",""}
    local collections,instances={},{}
    local index=1
    for _,item in ipairs(inventory or {}) do
        if index>3 then break end
        if not collections[item.collectionId] then
            slots[index]=item.instanceId
            collections[item.collectionId]=true
            instances[item.instanceId]=true
            index+=1
        end
    end
    if index<=3 then
        for _,item in ipairs(inventory or {}) do
            if index>3 then break end
            if not instances[item.instanceId] then
                slots[index]=item.instanceId
                instances[item.instanceId]=true
                index+=1
            end
        end
    end
    return slots
end

local function saveBaseSlots(userId,slots)
    local clean={tostring(slots[1] or ""),tostring(slots[2] or ""),tostring(slots[3] or "")}
    local ok,err=pcall(function()
        baseStore:UpdateAsync(keyFor(userId),function()
            return {version=1,initialized=true,slots=clean,updatedAt=os.time()}
        end)
    end)
    if not ok then warn("[LOST FOUND] M5-C.1.3 base save failed",userId,err) end
    return ok
end

local function saveExtraSlots(userId,slots)
    local ok,err=pcall(function()
        extraStore:UpdateAsync(keyFor(userId),function()
            return {version=1,slot4=tostring(slots[4] or ""),slot5=tostring(slots[5] or ""),updatedAt=os.time()}
        end)
    end)
    if not ok then warn("[LOST FOUND] M5-C.1.3 extra save failed",userId,err) end
    return ok
end

local function readSlots(userId,inventory)
    local slots=emptySlots()
    local baseInitialized=false
    local okBase,rawBase=pcall(function() return baseStore:GetAsync(keyFor(userId)) end)
    if not okBase then return nil,"BASE_SHOWCASE_READ_FAILED" end
    if type(rawBase)=="table" and rawBase.initialized==true and type(rawBase.slots)=="table" then
        baseInitialized=true
        for slot=1,3 do slots[slot]=tostring(rawBase.slots[slot] or "") end
    else
        local seeded=seedBaseSlots(inventory)
        for slot=1,3 do slots[slot]=seeded[slot] end
    end

    local okExtra,rawExtra=pcall(function() return extraStore:GetAsync(keyFor(userId)) end)
    if not okExtra then return nil,"EXTRA_SHOWCASE_READ_FAILED" end
    if type(rawExtra)=="table" then
        slots[4]=tostring(rawExtra.slot4 or "")
        slots[5]=tostring(rawExtra.slot5 or "")
    end

    local owned,seen=inventoryMap(inventory),{}
    local baseChanged=not baseInitialized
    local extraChanged=false
    for slot=1,SLOT_COUNT do
        local id=cleanId(slots[slot])
        if not id or not owned[id] or seen[id] then
            if slots[slot]~="" then
                if slot<=3 then baseChanged=true else extraChanged=true end
            end
            slots[slot]=""
        else
            slots[slot]=id
            seen[id]=true
        end
    end
    if baseChanged and not saveBaseSlots(userId,slots) then return nil,"BASE_SHOWCASE_SAVE_FAILED" end
    if extraChanged and not saveExtraSlots(userId,slots) then return nil,"EXTRA_SHOWCASE_SAVE_FAILED" end
    return slots
end

local function paletteFor(station)
    local skin=StationSkinRegistry.Get(station:GetAttribute("SkinId"))
    return skin and skin.palette or {}
end

local function roleColor(station,role)
    return paletteFor(station)[role] or FALLBACK[role] or Color3.fromRGB(80,88,100)
end

local function currentStation(player)
    local stationId=player:GetAttribute("LostFoundStationId")
    if type(stationId)~="string" or stationId=="" then return nil end
    local world=workspace:FindFirstChild("LostAndFoundM4D")
    local station=world and world:FindFirstChild("Station_"..stationId)
    if not station or not station:IsA("Model") then return nil end
    if station:GetAttribute("OwnerUserId")~=player.UserId then return nil end
    return station
end

local function stationByName(name)
    local world=workspace:FindFirstChild("LostAndFoundM4D")
    return world and type(name)=="string" and world:FindFirstChild(name) or nil
end

local function setPart(model,root,name,size,offset,angles)
    local part=model:FindFirstChild(name,true)
    if not part or not part:IsA("BasePart") then return end
    part.Size=size
    local a=angles or Vector3.zero
    part.CFrame=root.CFrame*CFrame.new(offset)*CFrame.Angles(math.rad(a.X),math.rad(a.Y),math.rad(a.Z))
end

local function refineBear(model)
    if tostring(model:GetAttribute("CollectionId") or "")~="cream_memory_bear" then return end
    local root=model.PrimaryPart or model:FindFirstChild("Body")
    if not root or not root:IsA("BasePart") then return end
    root.Size=Vector3.new(3.18,3.30,2.90)
    setPart(model,root,"Head",Vector3.new(3.15,3.05,2.82),Vector3.new(0,2.23,-0.16))
    setPart(model,root,"EarL",Vector3.new(1.06,1.06,0.72),Vector3.new(-1.18,3.13,-0.03))
    setPart(model,root,"EarR",Vector3.new(1.06,1.06,0.72),Vector3.new(1.18,3.13,-0.03))
    setPart(model,root,"InnerEarL",Vector3.new(0.55,0.55,0.18),Vector3.new(-1.18,3.13,-0.43))
    setPart(model,root,"InnerEarR",Vector3.new(0.55,0.55,0.18),Vector3.new(1.18,3.13,-0.43))
    setPart(model,root,"Muzzle",Vector3.new(1.42,1.02,0.72),Vector3.new(0,1.90,-1.46))
    setPart(model,root,"Nose",Vector3.new(0.42,0.32,0.22),Vector3.new(0,2.13,-1.86))
    setPart(model,root,"EyeL",Vector3.new(0.26,0.26,0.18),Vector3.new(-0.57,2.48,-1.44))
    setPart(model,root,"EyeR",Vector3.new(0.26,0.26,0.18),Vector3.new(0.57,2.48,-1.44))
    setPart(model,root,"Mouth",Vector3.new(0.62,0.08,0.08),Vector3.new(0,1.58,-1.49))
    setPart(model,root,"ArmL",Vector3.new(1.12,2.48,1.12),Vector3.new(-1.60,0.28,0.02),Vector3.new(0,0,-20))
    setPart(model,root,"ArmR",Vector3.new(1.12,2.48,1.12),Vector3.new(1.60,0.28,0.02),Vector3.new(0,0,20))
    setPart(model,root,"LegL",Vector3.new(1.42,1.95,1.50),Vector3.new(-0.78,-1.74,0.22),Vector3.new(0,0,-5))
    setPart(model,root,"LegR",Vector3.new(1.42,1.95,1.50),Vector3.new(0.78,-1.74,0.22),Vector3.new(0,0,5))
    setPart(model,root,"BellySeam",Vector3.new(0.10,1.72,0.10),Vector3.new(0,-0.08,-1.46))
    setPart(model,root,"Ribbon",Vector3.new(1.88,0.25,0.28),Vector3.new(0,1.20,-1.10))
    setPart(model,root,"BowL",Vector3.new(0.82,0.62,0.28),Vector3.new(-0.58,1.08,-1.19),Vector3.new(0,0,24))
    setPart(model,root,"BowR",Vector3.new(0.82,0.62,0.28),Vector3.new(0.58,1.08,-1.19),Vector3.new(0,0,-24))
end

local function removeFloatingLabels(model)
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA("BillboardGui") and (d.Name=="M5BShowcaseLabel" or d.Name=="SerialLabel") then d:Destroy() end
    end
end

local function familyFor(item)
    local entry=CollectionRegistry.Get(item.collectionId)
    return entry and tostring(entry.baseItemId or "") or ""
end

local function fitOffWorld(model,item,anchor,plinth)
    pcall(function() model:ScaleTo(1) end) -- safe: model is still unparented from Workspace
    refineBear(model)
    removeFloatingLabels(model)
    local profile=PROFILES[familyFor(item)] or DEFAULT_PROFILE
    local ok,_,size=pcall(function()
        local cf,extents=model:GetBoundingBox()
        return cf,extents
    end)
    if not ok or not size or size.X<=0 or size.Y<=0 or size.Z<=0 then return end
    local scale=math.min(profile.w/size.X,profile.h/size.Y,profile.d/size.Z)
    scale=math.clamp(scale,0.16,0.72)
    pcall(function() model:ScaleTo(scale) end)
    local base=anchor.CFrame*CFrame.new(0,0,profile.z or 0)*CFrame.Angles(math.rad(profile.pitch or 0),math.rad(profile.yaw or 180),math.rad(profile.roll or 0))
    pcall(function() model:PivotTo(base) end)
    local boxCf,boxSize=model:GetBoundingBox()
    local targetBottom=plinth.Position.Y+plinth.Size.Y*0.5+0.055
    local currentBottom=boxCf.Position.Y-boxSize.Y*0.5
    pcall(function() model:PivotTo(model:GetPivot()+Vector3.new(0,targetBottom-currentBottom,0)) end)
end

local function ensureStableFolder(showcase)
    local folder=showcase:FindFirstChild(STABLE_FOLDER_NAME)
    if folder and folder:IsA("Folder") then return folder end
    if folder then folder:Destroy() end
    folder=Instance.new("Folder")
    folder.Name=STABLE_FOLDER_NAME
    folder:SetAttribute("M5C13StableFolder",VERSION)
    folder.Parent=showcase
    return folder
end

local function parseStableSlot(model)
    return model and model:IsA("Model") and tonumber(string.match(model.Name,"M5C13_Slot_(%d+)")) or nil
end

local function makePhysicalPart(parent,name,size,cframe,color,material)
    local part=parent:FindFirstChild(name)
    if not part or not part:IsA("BasePart") then
        if part then part:Destroy() end
        part=Instance.new("Part")
        part.Name=name
        part.Parent=parent
    end
    part.Size=size
    part.CFrame=cframe
    part.Color=color
    part.Material=material or Enum.Material.SmoothPlastic
    part.Anchored=true
    part.CanCollide=false
    part.CanTouch=false
    part.CanQuery=false
    part.CastShadow=false
    return part
end

local function ensureNameplate(station,showcase,slot,oldPlate,item,style)
    local plate=makePhysicalPart(showcase,"M5C13_Nameplate"..slot,Vector3.new(3.08,0.90,0.075),oldPlate.CFrame*CFrame.new(0,0,-0.12),roleColor(station,"base"):Lerp(Color3.fromRGB(10,13,18),0.32),Enum.Material.SmoothPlastic)
    for _,gui in ipairs(oldPlate:GetChildren()) do if gui:IsA("SurfaceGui") then gui.Enabled=false end end

    local gui=plate:FindFirstChild("M5C13Surface")
    if not gui or not gui:IsA("SurfaceGui") then
        if gui then gui:Destroy() end
        gui=Instance.new("SurfaceGui")
        gui.Name="M5C13Surface"
        gui.Face=Enum.NormalId.Front
        gui.LightInfluence=0
        gui.PixelsPerStud=100
        gui.Parent=plate

        local top=Instance.new("TextLabel")
        top.Name="Top"
        top.Size=UDim2.new(1,-10,0.55,0)
        top.Position=UDim2.fromOffset(5,2)
        top.BackgroundTransparency=1
        top.TextColor3=Color3.fromRGB(242,245,249)
        top.Font=Enum.Font.GothamBold
        top.TextScaled=true
        top.TextWrapped=true
        top.TextXAlignment=Enum.TextXAlignment.Center
        top.TextYAlignment=Enum.TextYAlignment.Center
        top.Parent=gui
        local tc=Instance.new("UITextSizeConstraint")
        tc.MinTextSize=8 tc.MaxTextSize=12 tc.Parent=top

        local bottom=Instance.new("TextLabel")
        bottom.Name="Bottom"
        bottom.Size=UDim2.new(1,-10,0.36,0)
        bottom.Position=UDim2.new(0,5,0.61,0)
        bottom.BackgroundTransparency=1
        bottom.Font=Enum.Font.RobotoMono
        bottom.TextScaled=true
        bottom.TextWrapped=false
        bottom.TextXAlignment=Enum.TextXAlignment.Center
        bottom.TextYAlignment=Enum.TextYAlignment.Center
        bottom.Parent=gui
        local bc=Instance.new("UITextSizeConstraint")
        bc.MinTextSize=8 bc.MaxTextSize=11 bc.Parent=bottom
    end
    gui.Top.Text=string.upper(tostring(item.name))
    gui.Bottom.Text=tostring(item.rarity).."  •  "..tostring(item.serial)
    gui.Bottom.TextColor3=style.color
    return plate
end

local function ensureRarityBar(showcase,slot,plinth,style)
    local bar=makePhysicalPart(showcase,"M5C13_RarityBar"..slot,Vector3.new(2.34,0.09,0.11),plinth.CFrame*CFrame.new(0,-plinth.Size.Y*0.5-0.055,-plinth.Size.Z*0.5-0.035),style.color,Enum.Material.Neon)
    local light=bar:FindFirstChild("M5C13Light")
    if style.light>0 then
        if not light or not light:IsA("PointLight") then
            if light then light:Destroy() end
            light=Instance.new("PointLight")
            light.Name="M5C13Light"
            light.Parent=bar
        end
        light.Color=style.color
        light.Brightness=style.light
        light.Range=4.5
        light.Shadows=false
    elseif light then light:Destroy() end
end

local function clearPresentation(showcase,slot)
    local plate=showcase:FindFirstChild("M5C13_Nameplate"..slot)
    if plate then plate:Destroy() end
    local bar=showcase:FindFirstChild("M5C13_RarityBar"..slot)
    if bar then bar:Destroy() end
    local oldPlate=showcase:FindFirstChild("M5B2_InfoPlate"..slot)
    if oldPlate then
        for _,gui in ipairs(oldPlate:GetChildren()) do if gui:IsA("SurfaceGui") then gui.Enabled=true end end
    end
end

local function styleSlot(station,showcase,slot,item)
    local glow=showcase:FindFirstChild("M5B2_SlotGlow"..slot)
    local plinth=showcase:FindFirstChild("M5B2_Plinth"..slot)
    local oldPlate=showcase:FindFirstChild("M5B2_InfoPlate"..slot)
    if not plinth or not oldPlate then return end
    if not item then
        if glow and glow:IsA("BasePart") then glow.Color=roleColor(station,"accent") glow.Material=Enum.Material.Neon end
        plinth.Color=roleColor(station,"base")
        plinth.Material=Enum.Material.SmoothPlastic
        clearPresentation(showcase,slot)
        return
    end
    local style=RARITY_STYLE[item.rarity] or RARITY_STYLE.COMMON
    if glow and glow:IsA("BasePart") then glow.Color=style.color glow.Material=Enum.Material.Neon end
    local blend=({0.02,0.05,0.09,0.13,0.16,0.18})[style.rank] or 0.04
    plinth.Color=roleColor(station,"base"):Lerp(style.color,blend)
    plinth.Material=style.rank>=5 and Enum.Material.Metal or Enum.Material.SmoothPlastic
    ensureRarityBar(showcase,slot,plinth,style)
    ensureNameplate(station,showcase,slot,oldPlate,item,style)
end

local function clearStationVisual(station)
    if not station or not station:IsA("Model") then return end
    local showcase=station:FindFirstChild("PublicShowcase")
    if showcase then
        local folder=showcase:FindFirstChild(STABLE_FOLDER_NAME)
        if folder then folder:Destroy() end
        for slot=1,SLOT_COUNT do clearPresentation(showcase,slot) end
    end
    station:SetAttribute("ShowcaseCount",0)
    station:SetAttribute("ShowcaseVersion",VERSION)
end

local function createStableModel(item,slot,folder,showcase)
    local anchor=showcase:FindFirstChild("DisplayAnchor"..slot)
    local plinth=showcase:FindFirstChild("M5B2_Plinth"..slot)
    if not anchor or not anchor:IsA("BasePart") or not plinth or not plinth:IsA("BasePart") then return nil end
    local staging=Instance.new("Folder")
    staging.Name="M5C13Staging"
    local model=ORIGINAL_PREVIEW_CREATE(item.collectionId,staging,false)
    if not model or not model:IsA("Model") then staging:Destroy() return nil end
    model.Name="M5C13_Slot_"..slot
    model:SetAttribute("InstanceId",item.instanceId)
    model:SetAttribute("CollectionId",item.collectionId)
    model:SetAttribute("Serial",item.serial)
    model:SetAttribute("Rarity",item.rarity)
    model:SetAttribute("M5C13StableInstance",VERSION)
    fitOffWorld(model,item,anchor,plinth)
    model.Parent=folder
    staging:Destroy()
    return model
end

local function bindStation(station,player)
    if not station or boundStations[station] then return end
    boundStations[station]=true
    station:GetAttributeChangedSignal("SkinId"):Connect(function()
        if player and player.Parent then renderQueued[player.UserId]=nil end
    end)
end

local function renderStable(player)
    local state=states[player.UserId]
    if not state then return false end
    local station=currentStation(player)
    if not station then return false end
    if state.lastStationName and state.lastStationName~=station.Name then clearStationVisual(stationByName(state.lastStationName)) end
    local showcase=station:FindFirstChild("PublicShowcase")
    if not showcase or station:GetAttribute("ShowcaseLayoutVersion")~="M5B2_FIVE_SLOT_LARGE_V1" or not showcase:FindFirstChild("DisplayAnchor5") then return false end
    bindStation(station,player)
    local folder=ensureStableFolder(showcase)
    local owned=inventoryMap(state.inventory)
    local bySlot={}
    for _,child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            local slot=parseStableSlot(child)
            if slot and slot>=1 and slot<=SLOT_COUNT then
                if bySlot[slot] then child:Destroy() else bySlot[slot]=child end
            else child:Destroy() end
        end
    end
    local count=0
    for slot=1,SLOT_COUNT do
        local item=owned[state.slots[slot]]
        local existing=bySlot[slot]
        if item then
            count+=1
            if existing and tostring(existing:GetAttribute("InstanceId") or "")~=item.instanceId then existing:Destroy() existing=nil end
            if not existing then existing=createStableModel(item,slot,folder,showcase) end
            if existing then
                existing:SetAttribute("Serial",item.serial)
                existing:SetAttribute("Rarity",item.rarity)
            end
            styleSlot(station,showcase,slot,item)
        else
            if existing then existing:Destroy() end
            styleSlot(station,showcase,slot,nil)
        end
    end
    station:SetAttribute("ShowcaseCount",count)
    station:SetAttribute("ShowcaseVersion",VERSION)
    station:SetAttribute("ShowcaseRenderMode","STABLE_SEPARATE_FOLDER")
    state.lastStationName=station.Name
    return true
end

local function queueRender(player,delaySeconds)
    if not player or not player.Parent or renderQueued[player.UserId] then return end
    renderQueued[player.UserId]=true
    task.delay(delaySeconds or 0.08,function()
        renderQueued[player.UserId]=nil
        if not player.Parent then return end
        if not renderStable(player) then
            task.delay(0.65,function() if player.Parent then renderStable(player) end end)
        end
    end)
end

local function snapshot(player,code,message)
    local state=states[player.UserId]
    if not state then return {ok=false,code="NOT_READY",message="Showcase state is not ready."} end
    local owned=inventoryMap(state.inventory)
    local slotItems={}
    for slot=1,SLOT_COUNT do slotItems[slot]=owned[state.slots[slot]] end
    return {ok=true,code=code or "SYNC",message=message,slots=cloneSlots(state.slots),slotItems=slotItems,inventory=state.inventory}
end

local function pushUpdates(player,code,message)
    local data=snapshot(player,code,message)
    baseUpdate:FireClient(player,code or "SYNC",data)
    extraUpdate:FireClient(player,code or "SYNC",data)
    return data
end

local function syncPlayer(player,push)
    if not player or not player.Parent then return false,"PLAYER_GONE" end
    if player:GetAttribute("LostFoundPersistenceReady")~=true then return false,"NOT_READY" end
    local inventory,inventoryErr=readInventory(player.UserId)
    if not inventory then return false,inventoryErr end
    local slots,slotErr=readSlots(player.UserId,inventory)
    if not slots then return false,slotErr end
    local previous=states[player.UserId]
    states[player.UserId]={inventory=inventory,slots=cloneSlots(slots),refreshedAt=os.clock(),lastStationName=previous and previous.lastStationName or nil}
    queueRender(player,0.03)
    if push then pushUpdates(player,"SYNC") end
    return true
end

local function persistSelection(player,slots)
    if not saveBaseSlots(player.UserId,slots) then return false,"BASE_SAVE_FAILED" end
    if not saveExtraSlots(player.UserId,slots) then return false,"EXTRA_SAVE_FAILED" end
    return true
end

local function setSlot(player,slot,instanceId)
    local ok,err=syncPlayer(player,false)
    if not ok then return {ok=false,code=err or "SYNC_FAILED",message="Owned inventory could not be verified yet."} end
    local state=states[player.UserId]
    local owned=inventoryMap(state.inventory)
    local item=owned[tostring(instanceId or "")]
    if not item then return {ok=false,code="NOT_OWNED",message="That serialized item is not currently owned."} end
    local slots=cloneSlots(state.slots)
    for index=1,SLOT_COUNT do if slots[index]==item.instanceId then slots[index]="" end end
    slots[slot]=item.instanceId
    local saved,saveErr=persistSelection(player,slots)
    if not saved then syncPlayer(player,false) return {ok=false,code=saveErr or "SAVE_FAILED",message="Showcase selection could not be saved."} end
    state.slots=cloneSlots(slots)
    queueRender(player,0)
    return pushUpdates(player,"SLOT_UPDATED","Showcase slot updated.")
end

local function clearSlot(player,slot)
    local ok,err=syncPlayer(player,false)
    if not ok then return {ok=false,code=err or "SYNC_FAILED",message="Showcase could not sync yet."} end
    local state=states[player.UserId]
    local slots=cloneSlots(state.slots)
    slots[slot]=""
    local saved,saveErr=persistSelection(player,slots)
    if not saved then syncPlayer(player,false) return {ok=false,code=saveErr or "SAVE_FAILED",message="Showcase selection could not be saved."} end
    state.slots=cloneSlots(slots)
    queueRender(player,0)
    return pushUpdates(player,"SLOT_CLEARED","Showcase slot cleared.")
end

local function handleRequest(player,action,argA,argB,minSlot,maxSlot)
    action=string.upper(tostring(action or "SYNC"))
    if player:GetAttribute("LostFoundPersistenceReady")~=true then return {ok=false,code="NOT_READY",message="Player inventory is still loading."} end
    if busy[player.UserId] then return {ok=false,code="BUSY",message="Showcase is processing another request."} end
    busy[player.UserId]=true
    local ok,result=pcall(function()
        if action=="SYNC" then
            local synced,err=syncPlayer(player,false)
            if not synced then return {ok=false,code=err or "SYNC_FAILED",message="Showcase could not sync yet."} end
            return snapshot(player,"SYNC")
        end
        local slot=math.floor(tonumber(argA) or 0)
        if slot<minSlot or slot>maxSlot then return {ok=false,code="INVALID_SLOT",message="Invalid showcase slot for this request."} end
        if action=="SET_SLOT" then return setSlot(player,slot,argB) end
        if action=="CLEAR_SLOT" then return clearSlot(player,slot) end
        return {ok=false,code="UNKNOWN_ACTION",message="Unknown showcase action."}
    end)
    busy[player.UserId]=nil
    if not ok then warn("[LOST FOUND] M5-C.1.3 request failed",result) return {ok=false,code="SERVER_ERROR",message="Showcase request failed safely."} end
    return result
end

baseRequest.OnServerInvoke=function(player,action,argA,argB) return handleRequest(player,action,argA,argB,1,3) end
extraRequest.OnServerInvoke=function(player,action,argA,argB) return handleRequest(player,action,argA,argB,4,5) end

local function startPlayer(player)
    task.spawn(function()
        for _=1,120 do
            if not player.Parent then return end
            if player:GetAttribute("LostFoundPersistenceReady")==true and type(player:GetAttribute("LostFoundStationId"))=="string" and player:GetAttribute("LostFoundStationId")~="" then
                syncPlayer(player,true)
                queueRender(player,0.35)
                return
            end
            task.wait(0.25)
        end
    end)
    player:GetAttributeChangedSignal("LostFoundStationId"):Connect(function()
        task.delay(0.20,function() if player.Parent and states[player.UserId] then queueRender(player,0.10) end end)
    end)
end

Players.PlayerAdded:Connect(startPlayer)
Players.PlayerRemoving:Connect(function(player)
    local state=states[player.UserId]
    if state and state.lastStationName then clearStationVisual(stationByName(state.lastStationName)) end
    states[player.UserId]=nil busy[player.UserId]=nil renderQueued[player.UserId]=nil
end)
for _,player in ipairs(Players:GetPlayers()) do startPlayer(player) end

-- Trade/ownership reconciliation stays periodic, but unchanged slots perform zero
-- model destruction, ScaleTo or PivotTo writes. This is intentionally idempotent.
task.spawn(function()
    while true do
        task.wait(15)
        for _,player in ipairs(Players:GetPlayers()) do
            if player:GetAttribute("LostFoundPersistenceReady")==true and not busy[player.UserId] then
                task.spawn(function()
                    local ok=syncPlayer(player,true)
                    if not ok and states[player.UserId] then queueRender(player,0.05) end
                end)
            end
        end
    end
end)
