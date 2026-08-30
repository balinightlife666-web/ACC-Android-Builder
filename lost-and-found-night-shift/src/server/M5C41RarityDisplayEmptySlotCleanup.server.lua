-- LOST & FOUND: NIGHT SHIFT — M5-C.4.1 empty-slot rarity trim cleanup
-- Narrow event-driven companion to M5-C.4.
-- Removes only an orphan M5C4 nameplate trim after its stable slot model leaves.
-- Does not touch collectible geometry, rack geometry, economy, ownership, or persistence.

local STABLE_FOLDER = "M5C13StableItems"
local boundFolders = setmetatable({}, {__mode = "k"})

local function cleanup(showcase, slot)
    if not showcase or not showcase.Parent or not slot then return end
    task.defer(function()
        if not showcase.Parent then return end
        local folder = showcase:FindFirstChild(STABLE_FOLDER)
        local active = folder and folder:FindFirstChild("M5C13_Slot_" .. tostring(slot))
        if active then return end
        local trim = showcase:FindFirstChild("M5C4_NameplateTrim" .. tostring(slot))
        if trim then trim:Destroy() end
    end)
end

local function bindFolder(folder)
    if not folder or not folder:IsA("Folder") or boundFolders[folder] then return end
    boundFolders[folder] = true
    local showcase = folder.Parent
    if not showcase or showcase.Name ~= "PublicShowcase" then return end
    folder.ChildRemoved:Connect(function(child)
        if not child:IsA("Model") then return end
        local slot = tonumber(string.match(child.Name, "^M5C13_Slot_(%d+)$"))
        if slot and slot >= 1 and slot <= 5 then cleanup(showcase, slot) end
    end)
end

local function inspect(descendant)
    if descendant:IsA("Folder") and descendant.Name == STABLE_FOLDER then bindFolder(descendant) end
end

local world = workspace:FindFirstChild("LostAndFoundM4D")
if world then
    for _, descendant in ipairs(world:GetDescendants()) do inspect(descendant) end
    world.DescendantAdded:Connect(inspect)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name ~= "LostAndFoundM4D" then return end
    for _, descendant in ipairs(child:GetDescendants()) do inspect(descendant) end
    child.DescendantAdded:Connect(inspect)
end)

print("[LOST FOUND] M5-C.4.1 empty-slot trim cleanup ready")
