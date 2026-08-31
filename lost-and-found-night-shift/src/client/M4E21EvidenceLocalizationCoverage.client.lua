-- LOST & FOUND: NIGHT SHIFT — M4-E.2.1 evidence localization coverage.
-- Presentation-only hotfix for Indonesian clients. Covers evidence/status phrases added
-- by later M4-E.1 scenario depth work without changing case data, decisions, economy,
-- rewards, drops, serial/provenance, trading, station ownership, or mystery canon.

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer

local function resolvedLocaleId()
    local override = player:GetAttribute("LostFoundLocaleOverride")
    if type(override) == "string" and override ~= "" then return string.lower(override) end

    local ok, locale = pcall(function()
        return LocalizationService.RobloxLocaleId
    end)
    if ok and type(locale) == "string" and locale ~= "" then return string.lower(locale) end

    local okPlayer, playerLocale = pcall(function()
        return player.LocaleId
    end)
    if okPlayer and type(playerLocale) == "string" and playerLocale ~= "" then
        return string.lower(playerLocale)
    end
    return "en-us"
end

if string.sub(resolvedLocaleId(), 1, 2) ~= "id" then return end

local STATUS_ID = {
    ["RECORD FOUND"] = "DATA DITEMUKAN",
    ["TAG NUMBER MISMATCH"] = "NOMOR TAG TIDAK COCOK",
    ["OWNER / TAG / ROUTING RECORD MATCH"] = "PEMILIK / TAG / DATA PERJALANAN COCOK",
    ["OWNER MATCH / ROUTING UPDATE DELAYED"] = "PEMILIK COCOK / PEMBARUAN RUTE TERLAMBAT",
    ["BARCODE DAMAGED / MANUAL SERIAL MATCH"] = "BARCODE RUSAK / NOMOR SERIAL COCOK",
    ["OWNER / TAG MATCH / ROUTING REBOOKED"] = "PEMILIK / TAG COCOK / RUTE RESMI DIUBAH",
    ["REGISTERED COLLECTOR AUTHORIZATION / TAG MATCH"] = "PENGAMBIL RESMI TERDAFTAR / TAG COCOK",
    ["REPLACEMENT TAG CROSS-LINK VERIFIED"] = "TAG PENGGANTI RESMI TERHUBUNG",
    ["OWNER RECORD VALID / NO ACTIVE CLAIM"] = "DATA PEMILIK VALID / TIDAK ADA KLAIM AKTIF",
    ["CLAIM TAG DOES NOT MATCH PROPERTY"] = "TAG PENGAMBILAN TIDAK COCOK DENGAN BARANG",
    ["OWNER NAME FOUND / CLAIM PROOF INCOMPLETE"] = "NAMA PEMILIK DITEMUKAN / BUKTI KLAIM BELUM LENGKAP",
    ["THIRD-PARTY FINDER / OWNER RECORD FOUND"] = "PENEMU PIHAK KETIGA / DATA PEMILIK DITEMUKAN",
    ["IDENTITY MATCH / CONTENT DESCRIPTION CONFLICT"] = "IDENTITAS COCOK / DESKRIPSI ISI BERTENTANGAN",
    ["CLAIM RECEIPT VALID / WRONG JOURNEY"] = "BUKTI PENGAMBILAN VALID / PERJALANAN SALAH",
    ["FAMILY RELATION CLAIMED / NO COLLECTION AUTHORIZATION"] = "MENGAKU KELUARGA / TIDAK ADA IZIN PENGAMBILAN",
    ["OWNER / TAG MATCH / INTAKE ROUTE HOLD"] = "PEMILIK / TAG COCOK / BARANG MASIH DITAHAN OPERASIONAL",
    ["CLAIM DESCRIPTION CONFLICT"] = "DESKRIPSI KLAIM BERTENTANGAN",
    ["CLAIMANT IDENTITY DOES NOT MATCH REGISTERED OWNER"] = "IDENTITAS PENGAMBIL TIDAK COCOK DENGAN PEMILIK",
    ["DUPLICATE ACTIVE CLAIM DETECTED"] = "DUA KLAIM AKTIF TERDETEKSI",
    ["TAG ALTERATION DETECTED"] = "PERUBAHAN TAG TERDETEKSI",
    ["PHYSICAL TAG TAMPERING DETECTED"] = "TAG FISIK TERLIHAT DIMANIPULASI",
    ["TAG SERIAL DUPLICATED ON ANOTHER ACTIVE ITEM"] = "NOMOR TAG SAMA DENGAN BARANG AKTIF LAIN",
    ["CLAIM RECEIPT CHECKSUM INVALID"] = "KODE VALIDASI BUKTI PENGAMBILAN TIDAK VALID",
    ["RECEIPT CHECKSUM INVALID / TAG MATCH"] = "KODE VALIDASI BUKTI SALAH / TAG COCOK",
    ["CLAIMANT FLAG / MULTIPLE UNRELATED ACTIVE CLAIMS"] = "PENGAMBIL DITANDAI / BANYAK KLAIM TAK TERKAIT",
    ["INSPECTION ALERT / UNDECLARED RESTRICTED OBJECT"] = "PERINGATAN PEMERIKSAAN / BENDA TERBATAS TIDAK DILAPORKAN",
    ["THERMAL WARNING / INTERNAL BATTERY SWELLING"] = "PERINGATAN PANAS / BATERAI MENGEMBUNG",
    ["UNKNOWN LIQUID LEAK DETECTED"] = "KEBOCORAN CAIRAN TAK DIKENAL",
    ["AIR QUALITY ALERT / UNKNOWN CHEMICAL ODOR"] = "PERINGATAN KUALITAS UDARA / BAU BAHAN KIMIA TAK DIKENAL",
    ["UNKNOWN CHEMICAL ODOR DETECTED"] = "BAU BAHAN KIMIA TAK DIKENAL",
    ["REPEATED TEMPERATURE RISE DETECTED"] = "KENAIKAN SUHU BERULANG TERDETEKSI",
    ["TEMPERATURE RISING WITHOUT POWER SOURCE"] = "SUHU NAIK TANPA SUMBER DAYA",
    ["NO OWNER / NO VALID FLIGHT RECORD"] = "TIDAK ADA PEMILIK / DATA PENERBANGAN TIDAK VALID",
    ["PASSENGER FOUND / FLIGHT NOT FOUND"] = "PENUMPANG DITEMUKAN / PENERBANGAN TIDAK DITEMUKAN",
    ["MASS READING UNSTABLE"] = "HASIL BERAT TIDAK STABIL",
    ["IDENTITY CONFLICT"] = "KONFLIK IDENTITAS",
    ["MISSING PERSON RECORD / 2001"] = "DATA ORANG HILANG / 2001",
}

local NOTE_ID = {
    ["Two scans several seconds apart show the sealed property heating rapidly with no declared powered device."] = "Dua pemindaian yang dilakukan beberapa detik terpisah menunjukkan barang tersegel memanas cepat tanpa perangkat aktif yang tercatat.",
    ["Opening the property produces a strong unknown chemical odor not listed in the contents declaration."] = "Saat barang dibuka, tercium bau bahan kimia kuat yang tidak tercantum dalam daftar isi.",
    ["A sealed inner container is leaking an unidentified liquid with no declaration in the property record."] = "Wadah tertutup di dalam barang membocorkan cairan tak dikenal yang tidak tercatat dalam data barang.",
    ["Inspection finds a hot, swollen battery pack inside the property."] = "Pemeriksaan menemukan baterai panas dan mengembung di dalam barang.",
    ["Inspection reveals an undeclared restricted sharp object concealed beneath ordinary contents."] = "Pemeriksaan menemukan benda tajam terbatas yang tidak dilaporkan dan disembunyikan di bawah isi biasa.",
    ["Scanner detects two adhesive layers and overwritten digits beneath the visible claim tag."] = "Pemindai mendeteksi dua lapisan perekat dan angka yang ditimpa di bawah tag pengambilan yang terlihat.",
    ["The same tag number is currently registered to a different item in another terminal record."] = "Nomor tag yang sama sedang terdaftar pada barang lain di catatan terminal berbeda.",
    ["A second person submitted a verified-looking claim for this exact tag less than ten minutes earlier."] = "Orang kedua mengajukan klaim yang tampak valid untuk tag yang sama kurang dari sepuluh menit sebelumnya.",
    ["The person at the desk says they found the item and is not claiming ownership."] = "Orang di meja menyatakan menemukan barang tersebut dan tidak mengaku sebagai pemilik.",
    ["Claimant identity and tag match, but their listed contents do not match the inspected contents."] = "Identitas pengambil dan tag cocok, tetapi daftar isi yang diberikan tidak cocok dengan hasil pemeriksaan.",
}

local applying = setmetatable({}, { __mode = "k" })
local connections = setmetatable({}, { __mode = "k" })

local function escapePattern(value)
    return (string.gsub(value, "([^%w])", "%%%1"))
end

local function translateCoverage(text)
    local result = tostring(text or "")
    for english, indonesian in pairs(STATUS_ID) do
        result = string.gsub(result, escapePattern(english), indonesian)
    end
    for english, indonesian in pairs(NOTE_ID) do
        result = string.gsub(result, escapePattern(english), indonesian)
    end
    return result
end

local function apply(object)
    if not object:IsA("TextLabel") then return end
    if object.Name ~= "Evidence" then return end
    if applying[object] then return end

    local translated = translateCoverage(object.Text)
    if translated ~= object.Text then
        applying[object] = true
        object.Text = translated
        applying[object] = nil
    end

    if not connections[object] then
        connections[object] = object:GetPropertyChangedSignal("Text"):Connect(function()
            task.defer(function()
                if object.Parent then apply(object) end
            end)
        end)
    end
end

local playerGui = player:WaitForChild("PlayerGui")
for _, instance in ipairs(playerGui:GetDescendants()) do apply(instance) end
playerGui.DescendantAdded:Connect(function(instance)
    task.defer(apply, instance)
end)
