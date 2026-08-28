-- LOST & FOUND: NIGHT SHIFT — M5-A.3 Station Shop theme labels.
-- Makes the new product rule explicit in the existing compact mobile shop:
-- palette swaps are free; paid entries are FULL THEME transformations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local StationSkinRegistry = require(shared:WaitForChild("StationSkinRegistry"))

local function isIndonesian()
    local resolved = player:GetAttribute("LostFoundResolvedLocale")
    if resolved == "id" then return true end
    local ok, locale = pcall(function() return LocalizationService.RobloxLocaleId end)
    locale = ok and string.lower(tostring(locale or "")) or ""
    return string.sub(locale, 1, 2) == "id"
end

local ID = isIndonesian()

local localizedNames = {
    STANDARD_OPS = "Operasi Standar",
    INDUSTRIAL_SHIFT = "Shift Industrial",
    RETRO_AIRPORT = "Bandara Retro",
    BLACK_OPS = "Operasi Hitam",
    ARMY_FIELD = "Tema Militer",
    SAKURA_NIGHT = "Malam Sakura",
    STREET_GRAFFITI = "Grafiti Jalanan",
}

local gui = playerGui:WaitForChild("LostAndFoundStationShop", 30)
if not gui then return end
local panel = gui:WaitForChild("ShopPanel", 10)
local list = panel and panel:WaitForChild("SkinList", 10)
if not list then return end

local function formatCredits(value)
    local text = tostring(math.max(0, math.floor(tonumber(value) or 0)))
    while true do
        local replaced, count = string.gsub(text, "^(%-?%d+)(%d%d%d)", "%1,%2")
        text = replaced
        if count == 0 then break end
    end
    return text
end

local function patchRow(row)
    if not row:IsA("Frame") then return end
    local skin = StationSkinRegistry.Skins[row.Name]
    if not skin then return end

    local nameLabel = nil
    local detailLabel = nil
    local actionButton = nil

    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("TextLabel") and child.Position.X.Offset == 28 then
            if child.Position.Y.Offset <= 15 then
                nameLabel = child
            else
                detailLabel = child
            end
        elseif child:IsA("TextButton") and child.Position.X.Scale == 1 and child.Size.X.Offset >= 80 then
            actionButton = child
        end
    end

    if nameLabel and ID and localizedNames[skin.id] then
        nameLabel.Text = localizedNames[skin.id]
    end

    local price = math.max(0, math.floor(tonumber(skin.priceCredits) or 0))
    local kind = skin.theme and skin.theme.kind or "PALETTE"

    if detailLabel then
        if kind == "PALETTE" then
            detailLabel.Text = ID and "Variasi warna • GRATIS" or "Color variant • FREE"
        elseif skin.acquisition == "CREDITS" then
            detailLabel.Text = string.format(
                "%s • %s Credits",
                ID and "TEMA PENUH" or "FULL THEME",
                formatCredits(price)
            )
        end
    end

    if actionButton and kind == "PALETTE" and price == 0 then
        local text = string.upper(tostring(actionButton.Text or ""))
        if text == "BUY" or text == "BELI" then
            actionButton.Text = ID and "AMBIL GRATIS" or "GET FREE"
            actionButton.TextSize = 8
        end
    end
end

for _, child in ipairs(list:GetChildren()) do
    task.defer(patchRow, child)
end

list.ChildAdded:Connect(function(child)
    task.defer(function()
        task.wait()
        patchRow(child)
    end)
end)
