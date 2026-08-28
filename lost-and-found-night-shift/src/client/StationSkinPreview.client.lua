-- LOST & FOUND: NIGHT SHIFT — M5-A.3 proper station skin preview mode.
-- TRY / COBA hides the shop while leaving the temporary theme active so the player
-- can walk around the station. Preview ends only through END PREVIEW or session reset.

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
local list = panel and panel:WaitForChild("SkinList", 10)
if not panel or not list then return end

local status = nil
for _, child in ipairs(panel:GetChildren()) do
    if child:IsA("TextLabel") and child.Position.Y.Scale == 1 and child.Position.Y.Offset < 0 then
        status = child
        break
    end
end

local activePreview = nil
local activePreviewName = nil
local requestBusy = false

local function corner(target, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = target
end

local function setStatus(text)
    if status then status.Text = tostring(text or "") end
end

local previewHud = Instance.new("Frame")
previewHud.Name = "M5A3PreviewHud"
previewHud.AnchorPoint = Vector2.new(0.5, 1)
previewHud.Size = UDim2.fromOffset(350, 68)
previewHud.Position = UDim2.new(0.5, 0, 1, -30)
previewHud.BackgroundColor3 = Color3.fromRGB(16, 20, 27)
previewHud.BackgroundTransparency = 0.03
previewHud.BorderSizePixel = 0
previewHud.Visible = false
previewHud.ZIndex = 30
previewHud.Parent = gui
corner(previewHud, 11)

local hudStroke = Instance.new("UIStroke")
hudStroke.Color = Color3.fromRGB(224, 163, 64)
hudStroke.Transparency = 0.24
hudStroke.Thickness = 1.2
hudStroke.Parent = previewHud

local previewTitle = Instance.new("TextLabel")
previewTitle.Size = UDim2.new(1, -150, 0, 24)
previewTitle.Position = UDim2.fromOffset(12, 7)
previewTitle.BackgroundTransparency = 1
previewTitle.TextXAlignment = Enum.TextXAlignment.Left
previewTitle.TextColor3 = Color3.fromRGB(245, 218, 157)
previewTitle.Font = Enum.Font.GothamBold
previewTitle.TextSize = 11
previewTitle.ZIndex = 31
previewTitle.Text = tr("PREVIEW MODE", "MODE PRATINJAU")
previewTitle.Parent = previewHud

local previewName = Instance.new("TextLabel")
previewName.Size = UDim2.new(1, -150, 0, 25)
previewName.Position = UDim2.fromOffset(12, 31)
previewName.BackgroundTransparency = 1
previewName.TextXAlignment = Enum.TextXAlignment.Left
previewName.TextColor3 = Color3.fromRGB(218, 226, 237)
previewName.Font = Enum.Font.GothamMedium
previewName.TextSize = 10
previewName.ZIndex = 31
previewName.Text = "—"
previewName.Parent = previewHud

local backButton = Instance.new("TextButton")
backButton.Size = UDim2.fromOffset(78, 46)
backButton.Position = UDim2.new(1, -142, 0.5, -23)
backButton.BackgroundColor3 = Color3.fromRGB(45, 58, 75)
backButton.BorderSizePixel = 0
backButton.TextColor3 = Color3.fromRGB(194, 224, 239)
backButton.Font = Enum.Font.GothamBold
backButton.TextSize = 9
backButton.TextWrapped = true
backButton.ZIndex = 31
backButton.Text = tr("BACK\nTO SHOP", "KEMBALI\nKE TOKO")
backButton.Parent = previewHud
corner(backButton, 8)

local endButton = Instance.new("TextButton")
endButton.Size = UDim2.fromOffset(54, 46)
endButton.Position = UDim2.new(1, -60, 0.5, -23)
endButton.BackgroundColor3 = Color3.fromRGB(84, 48, 50)
endButton.BorderSizePixel = 0
endButton.TextColor3 = Color3.fromRGB(246, 199, 199)
endButton.Font = Enum.Font.GothamBold
endButton.TextSize = 9
endButton.TextWrapped = true
endButton.ZIndex = 31
endButton.Text = tr("END", "SELESAI")
endButton.Parent = previewHud
corner(endButton, 8)

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

local function updatePreviewHud()
    previewHud.Visible = activePreview ~= nil and not panel.Visible
    if activePreview then
        previewName.Text = tostring(activePreviewName or activePreview) .. tr(" • walk around to inspect", " • jalan keliling untuk melihat")
    else
        previewName.Text = "—"
    end
end

local function endPreview(reopenShop)
    if not activePreview then
        previewHud.Visible = false
        if reopenShop then panel.Visible = true end
        return
    end

    previewTitle.Text = tr("RESTORING...", "MENGEMBALIKAN...")
    local result = invoke("RESTORE", "")
    if result and result.ok then
        activePreview = nil
        activePreviewName = nil
        previewTitle.Text = tr("PREVIEW MODE", "MODE PRATINJAU")
        setStatus(tr("Your equipped skin is active again.", "Skin yang kamu pakai sudah kembali."))
        previewHud.Visible = false
        if reopenShop then panel.Visible = true end
    else
        previewTitle.Text = tr("PREVIEW MODE", "MODE PRATINJAU")
        setStatus(tr("Could not restore preview yet.", "Pratinjau belum bisa dikembalikan."))
        updatePreviewHud()
    end
end

local function previewSkin(skinId)
    local skin = StationSkinRegistry.Skins[skinId]
    if not skin then return end

    setStatus(tr("Applying temporary preview...", "Menerapkan pratinjau sementara..."))
    local result = invoke("PREVIEW", skinId)
    if result and result.ok then
        activePreview = skinId
        activePreviewName = tostring(result.skinName or skin.name)
        setStatus(tr(
            activePreviewName .. " preview active — 0 Credits spent.",
            "Pratinjau " .. activePreviewName .. " aktif — 0 Kredit terpotong."
        ))

        -- The important M5-A.3 UX change: hide the shop WITHOUT restoring the skin.
        panel.Visible = false
        updatePreviewHud()
    elseif result then
        local idMessages = {
            NOT_READY = "Profil stasiun masih dimuat.",
            NO_STATION = "Stasiun pribadimu belum siap.",
            PREVIEW_LOCKED = "Skin ini belum tersedia untuk dicoba.",
            BUSY = "Pratinjau sedang memproses permintaan sebelumnya.",
        }
        setStatus(ID and (idMessages[tostring(result.code)] or tostring(result.message or "Pratinjau tidak tersedia.")) or tostring(result.message or "Preview unavailable."))
    end
end

local function attachRow(row)
    if not row:IsA("Frame") then return end
    if row:FindFirstChild("M5A3PreviewButton") then return end

    local skin = StationSkinRegistry.Skins[row.Name]
    if not skin then return end
    if skin.acquisition ~= "FREE" and skin.acquisition ~= "CREDITS" then return end

    -- Keep the row mobile-safe: reserve a narrow middle preview slot.
    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("TextLabel") and child.Position.X.Offset == 28 then
            child.Size = UDim2.new(1, -184, child.Size.Y.Scale, child.Size.Y.Offset)
        end
    end

    -- Remove the retired M5-A.2 button if a stale client instance created one first.
    local legacy = row:FindFirstChild("M5A2PreviewButton")
    if legacy then legacy:Destroy() end

    local button = Instance.new("TextButton")
    button.Name = "M5A3PreviewButton"
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
    corner(button, 7)

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
    updatePreviewHud()
end)

backButton.Activated:Connect(function()
    if activePreview then
        panel.Visible = true
        updatePreviewHud()
    end
end)

endButton.Activated:Connect(function()
    task.spawn(function()
        endPreview(false)
    end)
end)

player:GetAttributeChangedSignal("LostFoundStationId"):Connect(function()
    -- Server invalidates previews when a temporary A-H assignment changes.
    activePreview = nil
    activePreviewName = nil
    previewHud.Visible = false
end)
