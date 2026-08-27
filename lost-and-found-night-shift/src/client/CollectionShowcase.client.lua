local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local PreviewFactory = require(shared:WaitForChild("CollectionPreviewFactory"))
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local collectionUpdate = remotes:WaitForChild("CollectionUpdate")

local SHOWCASE_NAME = "LocalCollectionShowcase"
local PANEL_X = -44.55
local PANEL_Y = 8.0
local PANEL_Z = 10

local function makePart(parent, name, size, cframe, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Transparency = transparency or 0
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function addSurfaceText(target, text, face, color, textSize)
    local gui = Instance.new("SurfaceGui")
    gui.Face = face
    gui.LightInfluence = 0
    gui.PixelsPerStud = 42
    gui.Parent = target

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 22
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
end

local old = workspace:FindFirstChild(SHOWCASE_NAME)
if old then old:Destroy() end

local showcase = Instance.new("Model")
showcase.Name = SHOWCASE_NAME
showcase.Parent = workspace

makePart(
    showcase,
    "BackPanel",
    Vector3.new(0.5, 15.7, 24),
    CFrame.new(PANEL_X, PANEL_Y, PANEL_Z),
    Color3.fromRGB(20, 25, 33),
    Enum.Material.Metal,
    0.08
)

local titlePlate = makePart(
    showcase,
    "TitlePlate",
    Vector3.new(0.16, 1.35, 20),
    CFrame.new(PANEL_X + 0.34, 15.0, PANEL_Z),
    Color3.fromRGB(31, 37, 46),
    Enum.Material.Metal,
    0
)
addSurfaceText(titlePlate, "LOST PROPERTY COLLECTION  •  15", Enum.NormalId.Right, Color3.fromRGB(235, 177, 78), 18)

for _, shelfY in ipairs({1.55, 5.45, 9.35}) do
    makePart(
        showcase,
        "Shelf",
        Vector3.new(2.1, 0.22, 22),
        CFrame.new(PANEL_X + 0.9, shelfY, PANEL_Z),
        Color3.fromRGB(64, 72, 84),
        Enum.Material.Metal,
        0
    )
end

local slots = {}
local zPositions = {2, 6, 10, 14, 18}
local rowY = {2.8, 6.7, 10.6}
local slotIndex = 0

for row = 1, 3 do
    for col = 1, 5 do
        slotIndex += 1
        local y = rowY[row]
        local z = zPositions[col]

        local pedestal = makePart(
            showcase,
            "Slot_" .. tostring(slotIndex),
            Vector3.new(1.8, 0.22, 3.2),
            CFrame.new(PANEL_X + 1.15, y - 1.15, z),
            Color3.fromRGB(34, 41, 52),
            Enum.Material.Metal,
            0
        )

        local lockPlate = makePart(
            showcase,
            "Lock_" .. tostring(slotIndex),
            Vector3.new(0.14, 1.45, 2.5),
            CFrame.new(PANEL_X + 0.38, y, z),
            Color3.fromRGB(24, 29, 38),
            Enum.Material.SmoothPlastic,
            0
        )
        addSurfaceText(lockPlate, "?", Enum.NormalId.Right, Color3.fromRGB(112, 123, 139), 22)

        slots[slotIndex] = {
            pedestal = pedestal,
            lockPlate = lockPlate,
            position = Vector3.new(PANEL_X + 1.35, y, z),
        }
    end
end

local displayedModels = {}
local entries = {}
local discovered = {}

local function clearModels()
    for _, model in pairs(displayedModels) do
        if model and model.Parent then model:Destroy() end
    end
    table.clear(displayedModels)
end

local function rebuildShowcase()
    clearModels()

    for index, entry in ipairs(entries) do
        local slot = slots[index]
        if slot then
            local isDiscovered = discovered[entry.id] == true
            slot.lockPlate.Transparency = isDiscovered and 1 or 0

            for _, gui in ipairs(slot.lockPlate:GetChildren()) do
                if gui:IsA("SurfaceGui") then gui.Enabled = not isDiscovered end
            end

            if isDiscovered then
                local model = PreviewFactory.Create(entry.id, showcase, false)
                model.Name = "Display_" .. entry.id
                model:ScaleTo(0.3)
                model:PivotTo(CFrame.new(slot.position) * CFrame.Angles(0, math.rad(-90), 0))
                displayedModels[entry.id] = model
            end
        end
    end
end

collectionUpdate.OnClientEvent:Connect(function(_, payload)
    payload = payload or {}
    entries = payload.entries or entries
    discovered = payload.discovered or discovered
    rebuildShowcase()
end)
