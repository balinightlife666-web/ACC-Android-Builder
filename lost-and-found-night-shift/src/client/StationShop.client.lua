-- LOST & FOUND: NIGHT SHIFT — M5-A.2 Station Shop preview client.
-- Compact mobile-safe Credits shop with temporary no-cost TRY/COBA preview.
-- Server remains purchase/equip/preview authority.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local request = remotes:WaitForChild("StationShopRequest")
local update = remotes:WaitForChild("StationShopUpdate")

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

local function formatCredits(value)
    local text = tostring(math.max(0, math.floor(tonumber(value) or 0)))
    while true do
        local replaced, count = string.gsub(text, "^(%-?%d+)(%d%d%d)", "%1,%2")
        text = replaced
        if count == 0 then break end
    end
    return text
end

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundStationShop"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 18
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(target, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 9)
    c.Parent = target
end

local function stroke(target, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(85, 99, 119)
    s.Thickness = 1.1
    s.Transparency = transparency or 0.30
    s.Parent = target
end

local openButton = Instance.new("TextButton")
openButton.Name = "StationShopButton"
openButton.AnchorPoint = Vector2.new(1, 0)
openButton.Size = UDim2.fromOffset(128, 30)
-- M5-A.1 hard stack: Credits -> Index -> Archive -> Trade -> Station Shop.
openButton.Position = UDim2.new(1, -18, 0, 170)
openButton.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
openButton.BackgroundTransparency = 0.04
openButton.BorderSizePixel = 0
openButton.TextColor3 = Color3.fromRGB(255, 202, 105)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 10
openButton.Text = tr("STATION SHOP", "TOKO STASIUN")
openButton.Parent = gui
corner(openButton, 8)
stroke(openButton)

local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Size = UDim2.new(0.72, 0, 0.72, 0)
panel.Position = UDim2.fromScale(0.5, 0.52)
panel.BackgroundColor3 = Color3.fromRGB(15, 19, 26)
panel.BackgroundTransparency = 0.01
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 13)
stroke(panel, Color3.fromRGB(112, 94, 62), 0.16)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(320, 330)
sizeConstraint.MaxSize = Vector2.new(500, 440)
sizeConstraint.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -110, 0, 28)
title.Position = UDim2.fromOffset(16, 12)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(245, 218, 157)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.Text = tr("STATION SHOP", "TOKO STASIUN")
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -32, 0, 35)
subtitle.Position = UDim2.fromOffset(16, 41)
subtitle.BackgroundTransparency = 1
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextYAlignment = Enum.TextYAlignment.Top
subtitle.TextWrapped = true
subtitle.TextColor3 = Color3.fromRGB(167, 178, 192)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.Text = tr(
    "Try a skin free for 20s before buying. Purchases stay permanent.",
    "Coba skin gratis 20 detik sebelum beli. Pembelian tetap permanen."
)
subtitle.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 32)
close.Position = UDim2.new(1, -45, 0, 11)
close.BackgroundColor3 = Color3.fromRGB(38, 44, 55)
close.BorderSizePixel = 0
close.TextColor3 = Color3.fromRGB(239, 242, 247)
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.Text = "×"
close.Parent = panel
corner(close, 8)

local creditsLabel = Instance.new("TextLabel")
creditsLabel.Size = UDim2.fromOffset(150, 26)
creditsLabel.Position = UDim2.new(1, -198, 0, 13)
creditsLabel.BackgroundTransparency = 1
creditsLabel.TextXAlignment = Enum.TextXAlignment.Right
creditsLabel.TextColor3 = Color3.fromRGB(255, 202, 105)
creditsLabel.Font = Enum.Font.GothamBold
creditsLabel.TextSize = 11
creditsLabel.Text = "CREDITS  —"
creditsLabel.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Name = "SkinList"
list.Size = UDim2.new(1, -30, 1, -135)
list.Position = UDim2.fromOffset(15, 83)
list.BackgroundColor3 = Color3.fromRGB(21, 26, 34)
list.BackgroundTransparency = 0.12
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.fromOffset(0, 0)
list.Parent = panel
corner(list, 10)

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 9)
padding.PaddingBottom = UDim.new(0, 9)
padding.PaddingLeft = UDim.new(0, 9)
padding.PaddingRight = UDim.new(0, 9)
padding.Parent = list

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -30, 0, 36)
status.Position = UDim2.new(0, 15, 1, -43)
status.BackgroundTransparency = 1
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(164, 213, 235)
status.Font = Enum.Font.GothamMedium
status.TextSize = 11
status.Text = tr("Choose a skin to try or buy.", "Pilih skin untuk dicoba atau dibeli.")
status.Parent = panel

local previewBanner = Instance.new("TextLabel")
previewBanner.Name = "PreviewBanner"
previewBanner.AnchorPoint = Vector2.new(0.5, 1)
previewBanner.Size = UDim2.fromOffset(330, 42)
previewBanner.Position = UDim2.new(0.5, 0, 1, -22)
previewBanner.BackgroundColor3 = Color3.fromRGB(20, 27, 35)
previewBanner.BackgroundTransparency = 0.03
previewBanner.BorderSizePixel = 0
previewBanner.TextColor3 = Color3.fromRGB(255, 211, 125)
previewBanner.Font = Enum.Font.GothamBold
previewBanner.TextSize = 11
previewBanner.TextWrapped = true
previewBanner.Visible = false
previewBanner.Parent = gui
corner(previewBanner, 9)
stroke(previewBanner, Color3.fromRGB(224, 163, 64), 0.20)

local current = nil
local requestBusy = false

local function ownedMap(data)
    local result = {}
    for _, id in ipairs(data and data.ownedSkins or {}) do result[id] = true end
    result.STANDARD_OPS = true
    return result
end

local function localizedSkinName(entry)
    if not entry then return "Skin" end
    if not ID then return entry.name end
    local names = {
        STANDARD_OPS = "Operasi Standar",
        INDUSTRIAL_SHIFT = "Shift Industrial",
        RETRO_AIRPORT = "Bandara Retro",
        BLACK_OPS = "Operasi Hitam",
    }
    return names[entry.id] or entry.name
end

local function entryById(id)
    for _, entry in ipairs(current and current.entries or {}) do
        if entry.id == id then return entry end
    end
    return nil
end

local function resultMessage(result)
    if not result then return tr("No response from Station Shop.", "Tidak ada respons dari Toko Stasiun.") end
    local code = tostring(result.code or "")
    local idMessages = {
        PURCHASED = "Skin dibeli dan langsung dipakai.",
        EQUIPPED = "Skin stasiun sudah dipakai.",
        PREVIEWING = "Trial aktif 20 detik. Panel ditutup agar kamu bisa melihat stasiun.",
        PREVIEW_ENDED = "Trial selesai. Skin yang kamu pakai sebelumnya sudah dikembalikan.",
        PREVIEW_UNAVAILABLE = "Skin ini belum bisa dicoba.",
        INSUFFICIENT_CREDITS = "Credits belum cukup untuk membeli skin ini.",
        ALREADY_OWNED = "Skin ini sudah kamu miliki.",
        NOT_OWNED = "Beli skin ini terlebih dahulu.",
        NOT_READY = "Data pemain masih dimuat. Coba sebentar lagi.",
        NO_STATION = "Stasiun pribadimu belum siap.",
        BUSY = "Toko sedang memproses permintaan sebelumnya.",
        SAVE_FAILED = "Perubahan gagal disimpan dengan aman. Coba lagi.",
        NOT_FOR_CREDITS = "Skin ini belum tersedia dengan Credits.",
        SERVER_ERROR = "Toko mengalami gangguan sementara.",
    }
    if ID and idMessages[code] then return idMessages[code] end
    return tostring(result.message or code or "Station Shop updated.")
end

local function refreshPreviewBanner(data)
    local previewSkin = data and data.previewSkin
    if not previewSkin or previewSkin == "" then
        previewBanner.Visible = false
        return
    end
    local entry = entryById(previewSkin)
    local seconds = math.max(1, math.floor(tonumber(data.previewSeconds) or 20))
    previewBanner.Text = tr(
        string.format("FREE PREVIEW • %s • about %ds", localizedSkinName(entry), seconds),
        string.format("TRIAL GRATIS • %s • sekitar %d detik", localizedSkinName(entry), seconds)
    )
    previewBanner.Visible = true
end

local function invoke(action, skinId)
    if requestBusy then return nil end
    requestBusy = true
    local ok, result = pcall(function()
        return request:InvokeServer(action, skinId)
    end)
    requestBusy = false
    if not ok then
        status.Text = tr("Station Shop connection failed safely.", "Koneksi Toko Stasiun gagal dengan aman.")
        return nil
    end
    return result
end

local render
local function transact(action, skinId)
    status.Text = tr("Processing...", "Memproses...")
    local result = invoke(action, skinId)
    if result and result.ok then
        current = result.snapshot or result
        status.Text = resultMessage(result)
        render()
        refreshPreviewBanner(current)
        if action == "PREVIEW" then
            -- Hide the shop so the player can inspect the station itself during the trial.
            panel.Visible = false
        end
    else
        status.Text = resultMessage(result)
        local sync = invoke("SYNC", "")
        if sync and sync.ok then
            current = sync
            render()
            refreshPreviewBanner(current)
        end
    end
end

local function makeAction(parent, text, size, position, background, textColor)
    local action = Instance.new("TextButton")
    action.Size = size
    action.Position = position
    action.BorderSizePixel = 0
    action.Font = Enum.Font.GothamBold
    action.TextSize = 10
    action.Text = text
    action.BackgroundColor3 = background
    action.TextColor3 = textColor
    action.Parent = parent
    corner(action, 8)
    return action
end

local function makeRow(entry, owned, equipped, previewing, anyPreview, order)
    local skin = StationSkinRegistry.Skins[entry.id]
    local row = Instance.new("Frame")
    row.Name = entry.id
    row.LayoutOrder = order
    row.Size = UDim2.new(1, -2, 0, 74)
    row.BackgroundColor3 = Color3.fromRGB(28, 34, 44)
    row.BackgroundTransparency = 0.04
    row.BorderSizePixel = 0
    row.Parent = list
    corner(row, 9)

    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.fromOffset(11, 54)
    swatch.Position = UDim2.fromOffset(8, 10)
    swatch.BackgroundColor3 = skin and skin.palette and skin.palette.accent or Color3.fromRGB(224, 163, 64)
    swatch.BorderSizePixel = 0
    swatch.Parent = row
    corner(swatch, 4)

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -132, 0, 23)
    name.Position = UDim2.fromOffset(28, 9)
    name.BackgroundTransparency = 1
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextColor3 = Color3.fromRGB(238, 241, 246)
    name.Font = Enum.Font.GothamBold
    name.TextSize = 12
    name.Text = localizedSkinName(entry)
    name.Parent = row

    local detail = Instance.new("TextLabel")
    detail.Size = UDim2.new(1, -132, 0, 34)
    detail.Position = UDim2.fromOffset(28, 32)
    detail.BackgroundTransparency = 1
    detail.TextXAlignment = Enum.TextXAlignment.Left
    detail.TextYAlignment = Enum.TextYAlignment.Top
    detail.TextColor3 = Color3.fromRGB(158, 171, 188)
    detail.Font = Enum.Font.Gotham
    detail.TextSize = 10
    detail.TextWrapped = true
    if entry.acquisition == "FREE" then
        detail.Text = tr("Default • Free", "Bawaan • Gratis")
    else
        detail.Text = string.format("%s Credits", formatCredits(entry.priceCredits or 0))
    end
    detail.Parent = row

    if equipped and anyPreview then
        local restore = makeAction(
            row,
            tr("RESTORE", "KEMBALI"),
            UDim2.fromOffset(92, 36),
            UDim2.new(1, -101, 0.5, -18),
            Color3.fromRGB(74, 66, 48),
            Color3.fromRGB(245, 218, 157)
        )
        restore.Activated:Connect(function() transact("END_PREVIEW", "") end)
    elseif equipped then
        local action = makeAction(
            row,
            tr("EQUIPPED", "DIPAKAI"),
            UDim2.fromOffset(92, 36),
            UDim2.new(1, -101, 0.5, -18),
            Color3.fromRGB(54, 83, 70),
            Color3.fromRGB(184, 235, 203)
        )
        action.AutoButtonColor = false
        action.Active = false
    elseif owned then
        local action = makeAction(
            row,
            tr("EQUIP", "PAKAI"),
            UDim2.fromOffset(92, 36),
            UDim2.new(1, -101, 0.5, -18),
            Color3.fromRGB(55, 68, 87),
            Color3.fromRGB(222, 230, 240)
        )
        action.Activated:Connect(function() transact("EQUIP", entry.id) end)
    else
        local try = makeAction(
            row,
            previewing and tr("TRYING", "DICOBA") or tr("TRY 20S", "COBA 20D"),
            UDim2.fromOffset(92, 27),
            UDim2.new(1, -101, 0, 7),
            previewing and Color3.fromRGB(54, 83, 70) or Color3.fromRGB(50, 67, 80),
            previewing and Color3.fromRGB(184, 235, 203) or Color3.fromRGB(184, 222, 238)
        )
        if previewing then
            try.AutoButtonColor = false
            try.Active = false
        else
            try.Activated:Connect(function() transact("PREVIEW", entry.id) end)
        end

        local buy = makeAction(
            row,
            tr("BUY", "BELI"),
            UDim2.fromOffset(92, 27),
            UDim2.new(1, -101, 0, 40),
            Color3.fromRGB(184, 125, 47),
            Color3.fromRGB(25, 25, 27)
        )
        buy.Activated:Connect(function() transact("BUY", entry.id) end)
    end
end

render = function()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    if not current then return end

    creditsLabel.Text = "CREDITS  " .. formatCredits(current.credits or 0)
    local owned = ownedMap(current)
    local anyPreview = current.previewSkin ~= nil and current.previewSkin ~= ""
    local order = 0
    for _, entry in ipairs(current.entries or {}) do
        if entry.acquisition == "FREE" or entry.acquisition == "CREDITS" then
            order += 1
            makeRow(
                entry,
                owned[entry.id] == true,
                current.equippedSkin == entry.id,
                current.previewSkin == entry.id,
                anyPreview,
                order
            )
        end
    end
end

local function syncShop()
    status.Text = tr("Loading station profile...", "Memuat profil stasiun...")
    for _ = 1, 12 do
        local data = invoke("SYNC", "")
        if data and data.ok then
            current = data
            render()
            refreshPreviewBanner(current)
            if current.previewSkin then
                status.Text = tr(
                    "A free preview is active. Choose another skin or restore your equipped skin.",
                    "Trial gratis sedang aktif. Coba skin lain atau kembalikan skin yang dipakai."
                )
            else
                status.Text = tr(
                    "Try any Credits skin free for 20 seconds before buying.",
                    "Coba skin Credits gratis selama 20 detik sebelum membeli."
                )
            end
            return true
        end
        task.wait(0.5)
    end
    status.Text = tr("Station profile is still loading.", "Profil stasiun masih dimuat.")
    return false
end

openButton.Activated:Connect(function()
    panel.Visible = not panel.Visible
    if panel.Visible then task.spawn(syncShop) end
end)

-- Closing the panel does NOT cancel the trial; the server restores the persisted skin
-- automatically after 20 seconds so the player can actually look around.
close.Activated:Connect(function()
    panel.Visible = false
end)

update.OnClientEvent:Connect(function(kind, data)
    if type(data) ~= "table" or not data.ok then return end
    current = data
    if kind == "PREVIEW_ENDED" then
        previewBanner.Visible = false
    else
        refreshPreviewBanner(current)
    end
    if panel.Visible then
        render()
        if data.message then status.Text = resultMessage(data) end
    end
end)

-- Keep the Credits counter fresh while the panel is open, even when shifts reward
-- Credits between shop interactions.
task.spawn(function()
    local leaderstats = player:WaitForChild("leaderstats", 20)
    local credits = leaderstats and leaderstats:WaitForChild("Credits", 10)
    if not credits then return end
    credits:GetPropertyChangedSignal("Value"):Connect(function()
        if current then
            current.credits = credits.Value
            creditsLabel.Text = "CREDITS  " .. formatCredits(credits.Value)
        end
    end)
end)
