-- LOST & FOUND: NIGHT SHIFT — localization foundation.
-- English remains the source language. Indonesian is the first authored translation.
-- This module is intentionally dependency-free so both client and server code can
-- share terminology without touching gameplay decisions, economy, or mystery canon.

local Localization = {}

local UI = {
    en = {
        CREDITS = "CREDITS",
        CASE_FILE = "CASE FILE",
        WAITING_FIRST = "Waiting for first suitcase...",
        FIRST_CASE = "FIRST SUITCASE",
        WAITING_EVIDENCE = "Waiting for evidence...",
        SCAN = "SCAN",
        TAG = "TAG",
        OPEN = "OPEN",
        PENDING = "pending",
        DONE = "DONE",
        OWNER = "owner",
        FLIGHT = "flight",
        WEIGHT = "weight",
        STATUS = "status",
        ITEM_TAG = "item tag",
        CLAIMANT = "claimant",
        CLAIM_TAG = "claim tag",
        CONTENTS = "contents",
        NOTE = "note",
        INCOMING = "INCOMING — conveyor moving",
        CASE_READY = "CASE READY — inspect item",
        EVIDENCE_UPDATED = "Evidence updated",
        DECISION_LOCKED = "DECISION LOCKED — finish evidence",
        COMPLETE_EVIDENCE = "Complete all evidence steps first.",
        CASE_TRANSITION = "CASE TRANSITION",
        CASE_ACTIVE = "CASE ACTIVE",
        CASE_COMPLETE = "CASE COMPLETE",
        INSTRUCTION_SCAN = "1/3  SCAN the suitcase.",
        INSTRUCTION_TAG = "2/3  CHECK TAG and compare claimant data.",
        INSTRUCTION_OPEN = "3/3  OPEN / INSPECT the item.",
        INSTRUCTION_DECIDE = "Evidence complete. Choose RETURN / STORE / QUARANTINE / SECURITY.",
        RETURN = "RETURN",
        STORE = "STORE",
        QUARANTINE = "QUARANTINE",
        SECURITY = "SECURITY",
        PERFECT = "PERFECT",
        CORRECT = "CORRECT",
        QUESTIONABLE = "QUESTIONABLE",
        WRONG = "WRONG",
        CATASTROPHIC = "CATASTROPHIC",
        CLOSED = "CLOSED",
        CONNECTED = "CONNECTED",
        UNRESOLVED = "UNRESOLVED",
        RESOLVED = "RESOLVED",
        NO_CLAIMANT = "NO CLAIMANT",
        CHILD = "CHILD",
    },
    id = {
        CREDITS = "KREDIT",
        CASE_FILE = "BERKAS KASUS",
        WAITING_FIRST = "Menunggu barang pertama...",
        FIRST_CASE = "BARANG PERTAMA",
        WAITING_EVIDENCE = "Menunggu bukti...",
        SCAN = "PINDAI",
        TAG = "TAG",
        OPEN = "BUKA",
        PENDING = "belum",
        DONE = "SELESAI",
        OWNER = "pemilik",
        FLIGHT = "penerbangan",
        WEIGHT = "berat",
        STATUS = "status",
        ITEM_TAG = "tag barang",
        CLAIMANT = "pengambil",
        CLAIM_TAG = "tag pengambilan",
        CONTENTS = "isi",
        NOTE = "catatan",
        INCOMING = "BARANG MASUK — konveyor bergerak",
        CASE_READY = "KASUS SIAP — periksa barang",
        EVIDENCE_UPDATED = "Bukti diperbarui",
        DECISION_LOCKED = "KEPUTUSAN TERKUNCI — lengkapi bukti",
        COMPLETE_EVIDENCE = "Selesaikan PINDAI, CEK TAG, dan BUKA sebelum memilih.",
        CASE_TRANSITION = "GANTI KASUS",
        CASE_ACTIVE = "KASUS AKTIF",
        CASE_COMPLETE = "KASUS SELESAI",
        INSTRUCTION_SCAN = "1/3  PINDAI barang.",
        INSTRUCTION_TAG = "2/3  CEK TAG dan cocokkan data pengambil.",
        INSTRUCTION_OPEN = "3/3  BUKA / PERIKSA barang.",
        INSTRUCTION_DECIDE = "Bukti lengkap. Pilih KEMBALIKAN / SIMPAN / ISOLASI / KEAMANAN.",
        RETURN = "KEMBALIKAN",
        STORE = "SIMPAN",
        QUARANTINE = "ISOLASI",
        SECURITY = "KEAMANAN",
        PERFECT = "SEMPURNA",
        CORRECT = "BENAR",
        QUESTIONABLE = "MERAGUKAN",
        WRONG = "SALAH",
        CATASTROPHIC = "FATAL",
        CLOSED = "DITUTUP",
        CONNECTED = "TERHUBUNG",
        UNRESOLVED = "BELUM TERPECAHKAN",
        RESOLVED = "SELESAI",
        NO_CLAIMANT = "TIDAK ADA PENGAMBIL",
        CHILD = "ANAK",
    },
}

local EXACT_ID = {
    ["Property Review"] = "Pemeriksaan Barang",
    ["Routine Claim"] = "Klaim Rutin",
    ["Wrong Color"] = "Warna Tidak Cocok",
    ["Tag Mismatch"] = "Tag Tidak Cocok",
    ["No Claimant"] = "Tanpa Pengambil",
    ["False Claim"] = "Klaim Palsu",
    ["Ownerless Suitcase"] = "Koper Tanpa Pemilik",
    ["Flight 000"] = "Penerbangan 000",
    ["Changing Weight"] = "Berat Berubah",
    ["Double Identity"] = "Identitas Ganda",
    ["The Lost Child"] = "Anak yang Hilang",

    ["Blue Hardcase Suitcase"] = "Koper Hardcase Biru",
    ["Navy Transit Case"] = "Koper Transit Biru Tua",
    ["Cobalt Shell Suitcase"] = "Koper Hardcase Kobalt",
    ["Blue Carry Hardcase"] = "Koper Hardcase Biru",
    ["Red Travel Backpack"] = "Ransel Perjalanan Merah",
    ["Crimson Travel Pack"] = "Ransel Perjalanan Merah Tua",
    ["Burgundy Cabin Backpack"] = "Ransel Kabin Burgundy",
    ["Red Transit Backpack"] = "Ransel Transit Merah",
    ["Cream Teddy Bear"] = "Boneka Beruang Krem",
    ["Ivory Stitched Teddy"] = "Boneka Beruang Gading Berjahit",
    ["Sand Plush Bear"] = "Boneka Beruang Warna Pasir",
    ["Cream Memory Bear"] = "Boneka Beruang Krem",
    ["Brown Vintage Suitcase"] = "Koper Vintage Cokelat",
    ["Walnut Heritage Case"] = "Koper Heritage Cokelat Tua",
    ["Brown Leather Travel Case"] = "Koper Perjalanan Kulit Cokelat",
    ["Chestnut Vintage Case"] = "Koper Vintage Chestnut",
    ["Black Hardcase Suitcase"] = "Koper Hardcase Hitam",
    ["Graphite Security Case"] = "Koper Keamanan Grafit",
    ["Charcoal Transit Hardcase"] = "Koper Transit Arang",
    ["Black Shell Travel Case"] = "Koper Perjalanan Hitam",
    ["Ownerless Vintage Suitcase"] = "Koper Vintage Tanpa Pemilik",
    ["Flight 000 Suitcase"] = "Koper Penerbangan 000",
    ["Sealed Cardboard Parcel"] = "Paket Kardus Tersegel",
    ["Green Travel Backpack"] = "Ransel Perjalanan Hijau",
    ["Small Vintage Case"] = "Koper Vintage Kecil",

    ["Clothing, charger, paperback"] = "Pakaian, pengisi daya, buku",
    ["Two shirts, travel adapter, notebook"] = "Dua kemeja, adaptor perjalanan, buku catatan",
    ["Jacket, toiletries, phone cable"] = "Jaket, perlengkapan mandi, kabel ponsel",
    ["Folded clothing, power bank, travel guide"] = "Pakaian lipat, power bank, panduan perjalanan",
    ["Sweater, charging cable, paperback novel"] = "Sweater, kabel pengisi daya, novel",
    ["Formal clothing, shoes"] = "Pakaian formal, sepatu",
    ["Tablet sleeve, shirt, headphones"] = "Sarung tablet, kemeja, headphone",
    ["Documents, sweater, shoes"] = "Dokumen, sweater, sepatu",
    ["Gym shirt, headphones, toiletry pouch"] = "Baju olahraga, headphone, tas perlengkapan mandi",
    ["Laptop sleeve, documents, light jacket"] = "Sarung laptop, dokumen, jaket ringan",
    ["Stuffed toy with stitched owner label"] = "Boneka dengan label nama pemilik yang dijahit",
    ["Stuffed toy with fabric name patch"] = "Boneka dengan patch nama kain",
    ["Stuffed toy with small ribbon and stitched initials"] = "Boneka dengan pita kecil dan inisial jahitan",
    ["Stuffed toy with embroidered initials"] = "Boneka dengan inisial bordir",
    ["Stuffed toy with stitched repair on left arm"] = "Boneka dengan bekas jahitan perbaikan di lengan kiri",
    ["Books, jacket, toiletries"] = "Buku, jaket, perlengkapan mandi",
    ["Paperback novels, scarf, shaving kit"] = "Novel, syal, perlengkapan cukur",
    ["Clothes, old notebook, toiletries"] = "Pakaian, buku catatan lama, perlengkapan mandi",
    ["Two books, folded jacket, wash bag"] = "Dua buku, jaket lipat, tas perlengkapan mandi",
    ["Clothing, reading glasses case, notebook"] = "Pakaian, kotak kacamata baca, buku catatan",
    ["Clothing, camera lens"] = "Pakaian, lensa kamera",
    ["Camera pouch, jacket, cables"] = "Tas kamera, jaket, kabel",
    ["Clothing, lens case, memory-card wallet"] = "Pakaian, kotak lensa, dompet kartu memori",
    ["Camera strap, clothes, charger pouch"] = "Tali kamera, pakaian, tas pengisi daya",
    ["Jacket, camera accessory pouch, cables"] = "Jaket, tas aksesori kamera, kabel",
    ["No declared contents"] = "Tidak ada isi yang didaftarkan",
    ["Unclear image on X-ray placeholder"] = "Gambar X-ray tidak jelas",
    ["Appears empty"] = "Terlihat kosong",
    ["Two passports with the same name and different birth dates"] = "Dua paspor dengan nama sama tetapi tanggal lahir berbeda",
    ["Toy train, old family photograph"] = "Kereta mainan, foto keluarga lama",

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
    ["PHYSICAL TAG TAMPERING DETECTED"] = "TAG FISIK TERLIHAT DIMANIPULASI",
    ["TAG SERIAL DUPLICATED ON ANOTHER ACTIVE ITEM"] = "NOMOR TAG SAMA DENGAN BARANG AKTIF LAIN",
    ["RECEIPT CHECKSUM INVALID / TAG MATCH"] = "KODE VALIDASI BUKTI SALAH / TAG COCOK",
    ["CLAIMANT FLAG / MULTIPLE UNRELATED ACTIVE CLAIMS"] = "PENGAMBIL DITANDAI / BANYAK KLAIM TAK TERKAIT",
    ["INSPECTION ALERT / UNDECLARED RESTRICTED OBJECT"] = "PERINGATAN PEMERIKSAAN / BENDA TERBATAS TIDAK DILAPORKAN",
    ["THERMAL WARNING / INTERNAL BATTERY SWELLING"] = "PERINGATAN PANAS / BATERAI MENGEMBUNG",
    ["UNKNOWN LIQUID LEAK DETECTED"] = "KEBOCORAN CAIRAN TAK DIKENAL",
    ["UNKNOWN CHEMICAL ODOR DETECTED"] = "BAU BAHAN KIMIA TAK DIKENAL",
    ["TEMPERATURE RISING WITHOUT POWER SOURCE"] = "SUHU NAIK TANPA SUMBER DAYA",
    ["NO OWNER / NO VALID FLIGHT RECORD"] = "TIDAK ADA PEMILIK / DATA PENERBANGAN TIDAK VALID",
    ["PASSENGER FOUND / FLIGHT NOT FOUND"] = "PENUMPANG DITEMUKAN / PENERBANGAN TIDAK DITEMUKAN",
    ["MASS READING UNSTABLE"] = "HASIL BERAT TIDAK STABIL",
    ["IDENTITY CONFLICT"] = "KONFLIK IDENTITAS",
    ["MISSING PERSON RECORD / 2001"] = "DATA ORANG HILANG / 2001",

    ["None"] = "Tidak ada",
    ["Adult"] = "Dewasa",
    ["Authorized Collector"] = "Pengambil Resmi",
    ["Finder"] = "Penemu",
    ["Family Member"] = "Anggota Keluarga",
    ["Child"] = "Anak",
    ["NOT PROVIDED"] = "TIDAK DIBERIKAN",
    ["FINDER TURN-IN"] = "DISERAHKAN PENEMU",
    ["—"] = "—",
}

local function lowerPrefix(localeId)
    return string.lower(tostring(localeId or "en-us"))
end

function Localization.ResolveLocale(localeId)
    local value = lowerPrefix(localeId)
    if string.sub(value, 1, 2) == "id" then return "id" end
    return "en"
end

function Localization.T(localeId, key)
    local locale = Localization.ResolveLocale(localeId)
    local dict = UI[locale] or UI.en
    return dict[key] or UI.en[key] or key
end

function Localization.TranslateExact(localeId, value)
    if Localization.ResolveLocale(localeId) ~= "id" then return tostring(value or "") end
    local text = tostring(value or "")
    return EXACT_ID[text] or text
end

function Localization.Decision(localeId, decision)
    return Localization.T(localeId, tostring(decision or ""))
end

function Localization.Grade(localeId, grade)
    return Localization.T(localeId, tostring(grade or ""))
end

function Localization.Resolution(localeId, resolution)
    return Localization.T(localeId, tostring(resolution or ""))
end

function Localization.TranslateOperationalText(localeId, value)
    local text = tostring(value or "")
    if Localization.ResolveLocale(localeId) ~= "id" then return text end
    if EXACT_ID[text] then return EXACT_ID[text] end

    local a, b = string.match(text, "^Original routing (.+) was replaced by (.+) after a documented rebooking%.$")
    if a then return "Rute awal " .. a .. " resmi diubah menjadi " .. b .. "." end
    a, b = string.match(text, "^The claimant receipt shows retired tag (.+); the system links it to replacement tag (.+)%.$")
    if a then return "Bukti pengambilan memakai tag lama " .. a .. "; sistem resmi menghubungkannya ke tag baru " .. b .. "." end
    a, b = string.match(text, "^Receipt (.+) belongs to an earlier trip and is not cross%-linked to property tag (.+)%.$")
    if a then return "Bukti " .. a .. " berasal dari perjalanan lama dan tidak terhubung ke tag barang " .. b .. "." end
    a = string.match(text, "^The property record is valid, but a pending transfer to (.+) has not been cancelled by operations%.$")
    if a then return "Data barang valid, tetapi pemindahan ke " .. a .. " masih ditahan oleh operasional." end
    a = string.match(text, "^Claimant repeatedly describes a (.+) item; the inspected property is .+%.$")
    if a then return "Deskripsi fisik dari pengambil tidak cocok dengan barang yang diperiksa." end

    local patterns = {
        {"The transfer scan posted late, but the physical tag and claimant identity both match.", "Pembaruan rute terlambat, tetapi tag fisik dan identitas pengambil cocok."},
        {"Barcode is unreadable; the printed serial, owner ID and claim receipt match exactly.", "Barcode tidak terbaca, tetapi nomor serial, identitas pemilik, dan bukti pengambilan semuanya cocok."},
        {"Claimant is not the owner, but a valid collection authorization is attached to the owner record.", "Pengambil bukan pemilik, tetapi memiliki izin pengambilan resmi yang tercatat."},
        {"Claimant knows the owner name but cannot provide the claim tag or receipt.", "Pengambil tahu nama pemilik tetapi tidak dapat menunjukkan tag atau bukti pengambilan."},
        {"The person at the desk says they found the item and is not claiming ownership.", "Orang di meja hanya menyerahkan barang yang ditemukan dan tidak mengaku sebagai pemilik."},
        {"Claimant identity and tag match, but their listed contents do not match the inspected contents.", "Identitas dan tag cocok, tetapi deskripsi isi tidak cocok dengan hasil pemeriksaan."},
        {"The claimant shares the owner's surname and knows the tag, but no authorized-collector record exists.", "Pengambil mengaku keluarga dan mengetahui tag, tetapi tidak ada izin pengambilan resmi."},
        {"The claimant presents the exact tag number but their identity differs from the registered owner, with no collector authorization.", "Pengambil memiliki nomor tag yang benar, tetapi identitasnya berbeda dari pemilik dan tidak memiliki izin resmi."},
        {"A second person submitted a verified-looking claim for this exact tag less than ten minutes earlier.", "Ada klaim lain untuk tag yang sama kurang dari sepuluh menit sebelumnya."},
        {"The same tag number is currently registered to a different item in another terminal record.", "Nomor tag yang sama juga terdaftar pada barang aktif lain."},
        {"The claimant has three active claims for unrelated owners and presents the exact tag for this item without authorization.", "Pengambil memiliki beberapa klaim aktif milik orang berbeda dan membawa tag barang ini tanpa izin."},
        {"Inspection reveals an undeclared restricted sharp object concealed beneath ordinary contents.", "Pemeriksaan menemukan benda tajam terbatas yang tidak dilaporkan dan disembunyikan di dalam barang."},
        {"Inspection finds a hot, swollen battery pack inside the property.", "Pemeriksaan menemukan baterai panas dan mengembung di dalam barang."},
        {"A sealed inner container is leaking an unidentified liquid with no declaration in the property record.", "Wadah di dalam barang bocor dan mengeluarkan cairan tak dikenal yang tidak tercatat."},
        {"Inspection detects a strong unidentified chemical odor from inside the property.", "Pemeriksaan menemukan bau bahan kimia kuat yang tidak dikenal dari dalam barang."},
        {"Repeated temperature readings rise while the item contains no declared battery or powered device.", "Suhu barang terus naik meski tidak ada baterai atau perangkat bertenaga yang tercatat."},
        {"The tag exists physically but has no database origin.", "Tag fisik ada, tetapi tidak memiliki asal di database."},
        {"The passenger record exists, but Flight 000 does not exist in the terminal schedule.", "Data penumpang ada, tetapi Penerbangan 000 tidak ada dalam jadwal terminal."},
        {"Repeated scans return incompatible weight values while the sealed parcel appears empty.", "Pemindaian berulang menunjukkan berat yang berbeda-beda padahal paket tersegel terlihat kosong."},
        {"Two valid-looking identities exist for one claimant.", "Ada dua identitas yang tampak valid untuk satu pengambil."},
        {"The child matches a missing-person photo archived twenty-five years earlier.", "Anak tersebut cocok dengan foto orang hilang yang diarsipkan sejak 2001."},
    }
    for _, entry in ipairs(patterns) do
        if text == entry[1] then return entry[2] end
    end

    return text
end

return Localization
