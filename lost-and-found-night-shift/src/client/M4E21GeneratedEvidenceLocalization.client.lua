-- LOST & FOUND: NIGHT SHIFT — M4-E.2.1 generated evidence localization coverage.
-- Presentation-only hotfix for M4-E.1 runtime scenario text that was added after
-- the original Indonesian localization table. No case logic, decisions, economy,
-- drops, serials, trading, station ownership, or mystery canon are changed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local Localization = require(shared:WaitForChild("Localization"))

local EXTRA_ID = {
    ["RECORD FOUND"] = "DATA DITEMUKAN",
    ["TAG NUMBER MISMATCH"] = "NOMOR TAG TIDAK COCOK",
    ["TAG ALTERATION DETECTED"] = "PERUBAHAN TAG TERDETEKSI",
    ["CLAIM RECEIPT CHECKSUM INVALID"] = "KODE VALIDASI BUKTI PENGAMBILAN TIDAK VALID",
    ["AIR QUALITY ALERT / UNKNOWN CHEMICAL ODOR"] = "PERINGATAN KUALITAS UDARA / BAU KIMIA TAK DIKENAL",
    ["REPEATED TEMPERATURE RISE DETECTED"] = "KENAIKAN SUHU BERULANG TERDETEKSI",

    ["The transfer scan posted late, but the physical tag and claimant identity both match."] = "Pemindaian transfer masuk terlambat, tetapi tag fisik dan identitas pengambil sama-sama cocok.",
    ["Barcode is unreadable; the printed serial, owner ID and claim receipt match exactly."] = "Barcode tidak terbaca; nomor serial tercetak, ID pemilik, dan bukti pengambilan cocok sepenuhnya.",
    ["Claimant is not the owner, but a valid collection authorization is attached to the owner record."] = "Pengambil bukan pemilik, tetapi izin pengambilan yang valid tercatat pada data pemilik.",
    ["Claimant knows the owner name but cannot provide the claim tag or receipt."] = "Pengambil mengetahui nama pemilik tetapi tidak dapat menunjukkan tag pengambilan atau bukti.",
    ["The person at the desk says they found the item and is not claiming ownership."] = "Orang di meja layanan mengatakan bahwa ia menemukan barang ini dan tidak mengaku sebagai pemilik.",
    ["Claimant identity and tag match, but their listed contents do not match the inspected contents."] = "Identitas pengambil dan tag cocok, tetapi daftar isi tidak cocok dengan isi hasil pemeriksaan.",
    ["The claimant shares the owner's surname and knows the tag, but no authorized-collector record exists."] = "Pengambil memiliki nama keluarga yang sama dengan pemilik dan mengetahui tag, tetapi tidak ada izin pengambilan resmi.",
    ["The claimant presents the exact tag number but their identity differs from the registered owner, with no collector authorization."] = "Pengambil menunjukkan nomor tag yang tepat, tetapi identitasnya berbeda dari pemilik terdaftar dan tidak memiliki izin pengambilan.",
    ["A second person submitted a verified-looking claim for this exact tag less than ten minutes earlier."] = "Orang kedua mengajukan klaim yang tampak valid untuk tag yang sama kurang dari sepuluh menit sebelumnya.",
    ["Scanner detects two adhesive layers and overwritten digits beneath the visible claim tag."] = "Pemindai mendeteksi dua lapisan perekat dan angka yang ditimpa di bawah tag pengambilan yang terlihat.",
    ["The same tag number is currently registered to a different item in another terminal record."] = "Nomor tag yang sama sedang terdaftar pada barang berbeda di catatan terminal lain.",
    ["The printed receipt matches the visible tag number, but its verification code belongs to a different transaction."] = "Bukti tercetak cocok dengan nomor tag yang terlihat, tetapi kode verifikasinya berasal dari transaksi lain.",
    ["The claimant has three active claims for unrelated owners and presents the exact tag for this item without authorization."] = "Pengambil memiliki tiga klaim aktif untuk pemilik yang tidak berkaitan dan menunjukkan tag barang ini tanpa izin.",
    ["Inspection reveals an undeclared restricted sharp object concealed beneath ordinary contents."] = "Pemeriksaan menemukan benda tajam terbatas yang tidak dilaporkan dan disembunyikan di antara isi biasa.",
    ["Inspection finds a hot, swollen battery pack inside the property."] = "Pemeriksaan menemukan baterai panas dan mengembung di dalam barang.",
    ["A sealed inner container is leaking an unidentified liquid with no declaration in the property record."] = "Wadah tertutup di dalam barang mengalami kebocoran cairan tak dikenal yang tidak tercatat dalam data barang.",
    ["Opening the property produces a strong unknown chemical odor not listed in the contents declaration."] = "Saat barang dibuka, muncul bau bahan kimia kuat yang tidak dikenal dan tidak tercantum dalam daftar isi.",
    ["Two scans several seconds apart show the sealed property heating rapidly with no declared powered device."] = "Dua pemindaian dengan jeda beberapa detik menunjukkan barang tersegel memanas cepat tanpa perangkat berdaya yang dilaporkan.",
}

local COLOR_ID = {
    black = "hitam", blue = "biru", red = "merah", green = "hijau",
    cream = "krem", brown = "cokelat", silver = "perak", navy = "biru tua",
    grey = "abu-abu", white = "putih", maroon = "marun", olive = "zaitun",
}

local applying = setmetatable({}, { __mode = "k" })
local bound = setmetatable({}, { __mode = "k" })

local function localeId()
    local override = player:GetAttribute("LostFoundLocaleOverride")
    if type(override) == "string" and override ~= "" then return override end
    local ok, value = pcall(function() return LocalizationService.RobloxLocaleId end)
    if ok and type(value) == "string" and value ~= "" then return value end
    return "en-us"
end

local function isIndonesian()
    local resolved = player:GetAttribute("LostFoundResolvedLocale")
    if resolved ~= nil then return resolved == "id" end
    return Localization.ResolveLocale(localeId()) == "id"
end

local function translateExtra(value)
    value = tostring(value or "")
    local translated = Localization.TranslateOperationalText(localeId(), value)
    if translated ~= value then return translated end
    if EXTRA_ID[value] then return EXTRA_ID[value] end

    local oldRoute, newRoute = string.match(value, "^Original routing (.+) was replaced by (.+) after a documented rebooking%.$")
    if oldRoute then
        return string.format("Rute awal %s diganti menjadi %s setelah perubahan pemesanan yang tercatat.", oldRoute, newRoute)
    end

    local retiredTag, replacementTag = string.match(value, "^The claimant receipt shows retired tag (.+); the system links it to replacement tag (.+)%.$")
    if retiredTag then
        return string.format("Bukti pengambil menunjukkan tag lama %s; sistem menghubungkannya ke tag pengganti %s.", retiredTag, replacementTag)
    end

    local receiptTag, propertyTag = string.match(value, "^Receipt (.+) belongs to an earlier trip and is not cross%-linked to property tag (.+)%.$")
    if receiptTag then
        return string.format("Bukti %s berasal dari perjalanan sebelumnya dan tidak terhubung ke tag barang %s.", receiptTag, propertyTag)
    end

    local transferDesk = string.match(value, "^The property record is valid, but a pending transfer to (.+) has not been cancelled by operations%.$")
    if transferDesk then
        return string.format("Data barang valid, tetapi pemindahan tertunda ke %s belum dibatalkan oleh operasional.", transferDesk)
    end

    local claimedColor, actualColor = string.match(value, "^Claimant repeatedly describes a (.+) item; the inspected property is (.+)%.$")
    if claimedColor then
        return string.format(
            "Pengambil berulang kali menyebut barang berwarna %s; barang yang diperiksa berwarna %s.",
            COLOR_ID[string.lower(claimedColor)] or claimedColor,
            COLOR_ID[string.lower(actualColor)] or actualColor
        )
    end

    return value
end

local function localizeEvidence(text)
    local result = {}
    for line in string.gmatch(tostring(text or "") .. "\n", "(.-)\n") do
        local indent, label, value = string.match(line, "^(%s*)([^:]+):%s*(.*)$")
        if label then
            local lower = string.lower(label)
            local localized = value
            if lower == "status" or lower == "note" or lower == "catatan" then
                localized = translateExtra(value)
            elseif (lower == "claimant" or lower == "pengambil") and (value == "nil" or value == "NO CLAIMANT") then
                localized = "TIDAK ADA PENGAMBIL"
            end
            table.insert(result, indent .. label .. ": " .. localized)
        else
            table.insert(result, line)
        end
    end
    return table.concat(result, "\n")
end

local function apply(object)
    if not object:IsA("TextLabel") or object.Name ~= "Evidence" then return end
    if applying[object] or not isIndonesian() then return end
    local localized = localizeEvidence(object.Text)
    if localized ~= object.Text then
        applying[object] = true
        object.Text = localized
        applying[object] = nil
    end
    if not bound[object] then
        bound[object] = true
        object:GetPropertyChangedSignal("Text"):Connect(function()
            task.defer(function()
                if object.Parent then apply(object) end
            end)
        end)
    end
end

local playerGui = player:WaitForChild("PlayerGui")
for _, object in ipairs(playerGui:GetDescendants()) do apply(object) end
playerGui.DescendantAdded:Connect(function(object)
    task.defer(apply, object)
end)

player:GetAttributeChangedSignal("LostFoundResolvedLocale"):Connect(function()
    if not isIndonesian() then return end
    for _, object in ipairs(playerGui:GetDescendants()) do apply(object) end
end)
