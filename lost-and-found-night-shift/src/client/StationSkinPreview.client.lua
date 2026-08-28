-- LOST & FOUND: NIGHT SHIFT — M5-A.2 Station Skin Preview client.
-- Adds a compact TRY / COBA button to each earnable Station Shop row.
-- Preview is temporary and automatically restores the persisted equipped skin when the shop closes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local request = remotes:WaitForChild("StationSkinPreviewRequest")

local function isIndonesian()
    local resolved = player:GetAttribute("LostFoundResolvedLocale")
    if resolved == "id" then return true end
    local ok, locale = pcall(function() return LocalizationService.RobloxLocaleId end)
    locale = ok and string.lower(tostring(locale or "")) or ""
    return string.sub(locale, 1, 2) == "id"
end

local ID = isIndonesian()
local function tr(en, id)
    return ID and id or en
end

local gui = playerGui:WaitForChild("LostAndFoundStationShop", 30)
if not gui then return end

local panel = gui:WaitForChild("ShopPanel", 10)
local openButton = gui:WaitForChild("StationShopButton", 10)
if not panel or not openButton then return end

local list = panel:WaitForChild("SkinList", 10)
if not list then return end

local status = nil
for _, child in ipairs(panel:GetChildren()) do
    if child:IsA("TextLabel") and child.Position.Y.Scale == 1 and child.Position.Y.Offset < 0 then
        status = child
        break
    end
end

local closeButton = nil
for _, child in ipairs(panel:GetChildren()) do
    if child:IsA("TextButton") and child.Text == "×" then
        closeButton = child
        break
    end
end

local activePreview = nil
local requestBusy = false
local restoreBusy = false

local function setStatus(text)
    if status then status.Text = tostring(text or "") end
end

local function invoke(action, skinId)
    if requestBusy then return nil end
    requestBusy = true
    local ok, result = pcall(function()
        return request:InvokeServer(action, skinId or "")
    end)
    requestBusy = false
    if not ok then
        setStatus(tr("Preview connection failed safely.", "Koneksi pratinjau gagal dengan aman."))
        return nil
    end
    return result
end

local function restorePreview()
    if not activePreview or restoreBusy then return end
    restoreBusy = true
    local result = invoke("RESTORE", "")
    if result and result.ok then
        activePreview = nil
        setStatus(tr("Your equipped skin is active again.", "Skin yang kamu pakai sudah kembali."))
    end
    restoreBusy = false
end

local function previewSkin(skinId)
    local skin = StationSkinRegistry.Skins[skinId]
    if not skin then return end

    setStatus(tr("Applying temporary preview...", "Menerapkan pratinjau sementara..."))
    local result = invoke("PREVIEW", skinId)
    if result and result.ok then
        activePreview = skinId
        setStatus(tr(
            tostring(result.skinName or skin.name) .. " preview — no Credits spent. Close shop to restore.",
            "Pratinjau " .. tostring(result.skinName or skin.name) .. " — tanpa potong Kredit. Tutup toko untuk kembali."
        ))
    elseif result then
        setStatus(ID and ({
            NOT_READY = "Profil stasiun masih dimuat.",
            NO_STATION = "Stasiun pribadimu belum siap.",
            PREVIEW_LOCKED = "Skin ini belum tersedia untuk dicoba.",
            BUSY = "Pratinjau sedang memproses permintaan sebelumnya.",
        })[tostring(result.code)] or tostring(result.message or "Preview unavailable."))
    end
end

local function makeCorner(target)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = target
end

local function attachRow(row)
    if not row:IsA("Frame") then return end
    if row:FindFirstChild("M5A2PreviewButton") then return end

    local skin = StationSkinRegistry.Skins[row.Name]
    if not skin then return end
    if skin.acquisition ~= "FREE" and skin.acquisition ~= "CREDITS" then return end

    -- Make a narrow middle slot without increasing row height or mobile panel width.
    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("TextLabel") and child.Position.X.Offset == 28 then
            child.Size = UDim2.new(1, -184, child.Size.Y.Scale, child.Size.Y.Offset)
        end
    end

    local button = Instance.new("TextButton")
    button.Name = "M5A2PreviewButton"
    button.Size = UDim2.fromOffset(48, 36)
    button.Position = UDim2.new(1, -154, 0.5, -18)
    button.BackgroundColor3 = Color3.fromRGB(44, 58, 75)
    button.BackgroundTransparency = 0.02
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(185, 220, 238)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 9
    button.Text = tr("TRY", "COBA")
    button.Parent = row
    makeCorner(button)

    button.Activated:Connect(function()
        previewSkin(row.Name)
    end)
end

for _, child in ipairs(list:GetChildren()) do
    attachRow(child)
end

list.ChildAdded:Connect(function(child)
    task.defer(attachRow, child)
end)

panel:GetPropertyChangedSignal("Visible"):Connect(function()
    if not panel.Visible then
        task.spawn(restorePreview)
    end
end)

openButton.Activated:Connect(function()
    task.defer(function()
        if not panel.Visible then task.spawn(restorePreview) end
    end)
end)

if closeButton then
    closeButton.Activated:Connect(function()
        task.defer(function() task.spawn(restorePreview) end)
    end)
end
