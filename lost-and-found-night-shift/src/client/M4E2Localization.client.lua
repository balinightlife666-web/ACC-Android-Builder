-- LOST & FOUND: NIGHT SHIFT — M4-E.2 player-language foundation.
-- Uses the Roblox client locale. English is source/fallback; Indonesian is authored.
-- Localization is presentation-only: no decision IDs, case logic, reward math, drop
-- rules, serial/provenance, trading or mystery outcomes are changed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local Localization = require(shared:WaitForChild("Localization"))

local function resolvedLocaleId()
    local override = player:GetAttribute("LostFoundLocaleOverride")
    if type(override) == "string" and override ~= "" then return override end

    local ok, locale = pcall(function()
        return LocalizationService.RobloxLocaleId
    end)
    if ok and type(locale) == "string" and locale ~= "" then return locale end

    local okPlayer, playerLocale = pcall(function()
        return player.LocaleId
    end)
    if okPlayer and type(playerLocale) == "string" and playerLocale ~= "" then return playerLocale end
    return "en-us"
end

local localeId = resolvedLocaleId()
local locale = Localization.ResolveLocale(localeId)
player:SetAttribute("LostFoundResolvedLocale", locale)

-- English remains untouched. Keeping the overlay dormant for English reduces risk
-- while still making every new locale opt-in through one deterministic code path.
if locale == "en" then return end

local applying = setmetatable({}, { __mode = "k" })
local connections = setmetatable({}, { __mode = "k" })

local function translateCaseHeader(text)
    local id, title, item = string.match(text, "^(.-)%s+•%s+([^\n]+)\n(.+)$")
    if id then
        return id .. "  •  " .. Localization.TranslateExact(localeId, title) .. "\n" .. Localization.TranslateExact(localeId, item)
    end
    return nil
end

local function translateStatus(text)
    local exact = {
        ["M0 — FIRST SUITCASE"] = "M0 — BARANG PERTAMA",
        ["INCOMING — conveyor moving"] = "BARANG MASUK — konveyor bergerak",
        ["CASE READY — inspect item"] = "KASUS SIAP — periksa barang",
        ["Evidence updated"] = "Bukti diperbarui",
        ["Scanner record loaded."] = "Data pemindai dimuat.",
        ["Claim tag checked."] = "Tag pengambilan sudah dicek.",
        ["Physical inspection completed. Choose a decision."] = "Pemeriksaan fisik selesai. Pilih keputusan.",
        ["DECISION LOCKED — finish evidence"] = "KEPUTUSAN TERKUNCI — lengkapi bukti",
        ["Complete all evidence steps first."] = "Lengkapi semua bukti terlebih dahulu.",
        ["Complete SCAN, CHECK TAG, and OPEN before deciding."] = "Selesaikan PINDAI, CEK TAG, dan BUKA sebelum memilih.",
        ["CASE TRANSITION"] = "GANTI KASUS",
        ["CASE ACTIVE"] = "KASUS AKTIF",
        ["No eligible case available."] = "Tidak ada kasus yang tersedia.",
    }
    if exact[text] then return exact[text] end

    local station = string.match(text, "^Incoming property to Station ([A-H])%.%.%.$")
    if station then return "Barang masuk ke Stasiun " .. station .. "..." end
    station = string.match(text, "^Station ([A-H]) ready%. Scan the item%.$")
    if station then return "Stasiun " .. station .. " siap. Pindai barang." end

    local resolution = string.match(text, "^CASE COMPLETE%s+—%s+(.+)$")
    if resolution then
        return "KASUS SELESAI — " .. Localization.Resolution(localeId, resolution)
    end
    return Localization.TranslateOperationalText(localeId, text)
end

local function translateInstruction(text)
    local exact = {
        ["1/3  SCAN the suitcase."] = "1/3  PINDAI barang.",
        ["2/3  CHECK TAG and compare claimant data."] = "2/3  CEK TAG dan cocokkan data pengambil.",
        ["3/3  OPEN / INSPECT the item."] = "3/3  BUKA / PERIKSA barang.",
        ["Evidence complete. Choose RETURN / STORE / QUARANTINE / SECURITY."] = "Bukti lengkap. Pilih KEMBALIKAN / SIMPAN / ISOLASI / KEAMANAN.",
        ["Complete all evidence steps first."] = "Lengkapi semua bukti terlebih dahulu.",
        ["Complete SCAN, CHECK TAG, and OPEN before deciding."] = "Selesaikan PINDAI, CEK TAG, dan BUKA sebelum memilih.",
    }
    return exact[text] or translateStatus(text)
end

local function translateProgress(text)
    local scanMark, tagMark, openMark = string.match(text, "^SCAN%s+(%S+)%s+TAG%s+(%S+)%s+OPEN%s+(%S+)$")
    if scanMark then
        return string.format("PINDAI %s  TAG %s  BUKA %s", scanMark, tagMark, openMark)
    end
    return text
end

local function translateEvidence(text)
    local result = {}
    for line in string.gmatch(text .. "\n", "(.-)\n") do
        local indent, label, value = string.match(line, "^(%s*)([^:]+):%s*(.*)$")
        if label then
            local upper = string.upper(label)
            local localizedLabel = label
            if upper == "SCAN" then localizedLabel = "PINDAI"
            elseif upper == "TAG" then localizedLabel = "TAG"
            elseif upper == "OPEN" then localizedLabel = "BUKA"
            elseif string.lower(label) == "owner" then localizedLabel = "pemilik"
            elseif string.lower(label) == "flight" then localizedLabel = "penerbangan"
            elseif string.lower(label) == "weight" then localizedLabel = "berat"
            elseif string.lower(label) == "status" then localizedLabel = "status"
            elseif string.lower(label) == "item tag" then localizedLabel = "tag barang"
            elseif string.lower(label) == "claimant" then localizedLabel = "pengambil"
            elseif string.lower(label) == "claim tag" then localizedLabel = "tag pengambilan"
            elseif string.lower(label) == "contents" then localizedLabel = "isi"
            elseif string.lower(label) == "note" then localizedLabel = "catatan"
            end

            local localizedValue = value
            if value == "pending" then localizedValue = "belum"
            elseif value == "DONE" then localizedValue = "SELESAI"
            elseif string.lower(label) == "status" or string.lower(label) == "note" then
                localizedValue = Localization.TranslateOperationalText(localeId, value)
            elseif string.lower(label) == "contents" then
                localizedValue = Localization.TranslateExact(localeId, value)
            elseif string.lower(label) == "claimant" and value == "NO CLAIMANT" then
                localizedValue = "TIDAK ADA PENGAMBIL"
            else
                localizedValue = Localization.TranslateExact(localeId, value)
            end
            table.insert(result, indent .. localizedLabel .. ": " .. localizedValue)
        else
            table.insert(result, line)
        end
    end
    return table.concat(result, "\n")
end

local function translateResult(text)
    local grade, decision, credits, xp = string.match(text, "^(%S+)%s+•%s+(%S+)\n%+(%-?%d+)%s+Credits%s+/%s+%+(%-?%d+)%s+XP$")
    if grade then
        return string.format("%s  •  %s\n+%s Kredit / +%s XP", Localization.Grade(localeId, grade), Localization.Decision(localeId, decision), credits, xp)
    end
    return text
end

local function translateGeneric(text)
    if text == "CREDITS" then return "KREDIT" end
    local credits = string.match(text, "^CREDITS%s+(%d+)$")
    if credits then return "KREDIT  " .. credits end

    local index = string.match(text, "^INDEX%s+(.+)$")
    if index then return "INDEKS " .. index end
    local archive = string.match(text, "^ARCHIVE%s+(.+)$")
    if archive then return "ARSIP " .. archive end

    local station = string.match(text, "^STATION%s+([A-H])$")
    if station then return "STASIUN " .. station end
    local ownerStation, vacant = string.match(text, "^STATION%s+([A-H])\n(VACANT)$")
    if ownerStation and vacant then return "STASIUN " .. ownerStation .. "\nKOSONG" end

    local generic = {
        ["CASE FILE"] = "BERKAS KASUS",
        ["Waiting for first suitcase..."] = "Menunggu barang pertama...",
        ["Waiting for evidence..."] = "Menunggu bukti...",
        ["SCAN ITEM"] = "PINDAI BARANG",
        ["CHECK TAG"] = "CEK TAG",
        ["OPEN / INSPECT"] = "BUKA / PERIKSA",
        ["RETURN"] = "KEMBALIKAN",
        ["STORE"] = "SIMPAN",
        ["QUARANTINE"] = "ISOLASI",
        ["SECURITY"] = "KEAMANAN",
        ["CLAIMANT"] = "PENGAMBIL",
        ["VACANT"] = "KOSONG",
        ["TRADE"] = "TUKAR",
        ["ARCHIVE"] = "ARSIP",
        ["INDEX"] = "INDEKS",
        ["COLLECTION"] = "KOLEKSI",
        ["COLLECTION INDEX"] = "INDEKS KOLEKSI",
        ["INVENTORY"] = "INVENTARIS",
        ["DISCOVERED"] = "DITEMUKAN",
        ["OWNED"] = "DIMILIKI",
        ["RARITY"] = "KELANGKAAN",
        ["CLOSE"] = "TUTUP",
        ["NIGHT SHIFT OPERATOR"] = "OPERATOR SHIFT MALAM",
        ["SCAN\nREADY"] = "PINDAI\nSIAP",
        ["TAG\nREADER"] = "PEMBACA\nTAG",
        ["L&F OPS\nNIGHT SHIFT"] = "OPERASI L&F\nSHIFT MALAM",
    }
    if generic[text] then return generic[text] end

    local header = translateCaseHeader(text)
    if header then return header end
    return Localization.TranslateExact(localeId, text)
end

local function translateForObject(object, text)
    if object.Name == "Case" or object.Name == "PopupTitle" then return translateCaseHeader(text) or translateGeneric(text) end
    if object.Name == "Status" or object.Name == "PopupStatus" then return translateStatus(text) end
    if object.Name == "Progress" then return translateProgress(text) end
    if object.Name == "Evidence" then return translateEvidence(text) end
    if object.Name == "Instruction" then return translateInstruction(text) end
    if object.Name == "ResultBanner" then return translateResult(text) end
    if object.Name == "Credits" then return translateGeneric(text) end
    return translateGeneric(text)
end

local function localizeTextObject(object)
    if not (object:IsA("TextLabel") or object:IsA("TextButton")) then return end
    if applying[object] then return end
    local translated = translateForObject(object, object.Text)
    if translated ~= object.Text then
        applying[object] = true
        object.Text = translated
        applying[object] = nil
    end

    if not connections[object] then
        connections[object] = object:GetPropertyChangedSignal("Text"):Connect(function()
            task.defer(function()
                if object.Parent then localizeTextObject(object) end
            end)
        end)
    end
end

local function localizePrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    local action = prompt.ActionText
    local actionMap = {
        ["SCAN ITEM"] = "PINDAI BARANG",
        ["CHECK TAG"] = "CEK TAG",
        ["OPEN / INSPECT"] = "BUKA / PERIKSA",
        ["RETURN"] = "KEMBALIKAN",
        ["STORE"] = "SIMPAN",
        ["QUARANTINE"] = "ISOLASI",
        ["SECURITY"] = "KEAMANAN",
    }
    if actionMap[action] then prompt.ActionText = actionMap[action] end

    local objectText = prompt.ObjectText
    if objectText == "YOUR SHIFT DECISION" then
        prompt.ObjectText = "KEPUTUSAN SHIFT KAMU"
        return
    end
    local station = string.match(objectText, "^STATION ([A-H]) SCANNER$")
    if station then prompt.ObjectText = "PEMINDAI STASIUN " .. station return end
    station = string.match(objectText, "^STATION ([A-H]) TAG$")
    if station then prompt.ObjectText = "TAG STASIUN " .. station return end
    station = string.match(objectText, "^STATION ([A-H]) TABLE$")
    if station then prompt.ObjectText = "MEJA STASIUN " .. station return end
end

local function observe(instance)
    if instance:IsA("TextLabel") or instance:IsA("TextButton") then
        task.defer(localizeTextObject, instance)
    elseif instance:IsA("ProximityPrompt") then
        task.defer(localizePrompt, instance)
    end
end

for _, instance in ipairs(player:WaitForChild("PlayerGui"):GetDescendants()) do observe(instance) end
player.PlayerGui.DescendantAdded:Connect(observe)

for _, instance in ipairs(Workspace:GetDescendants()) do observe(instance) end
Workspace.DescendantAdded:Connect(observe)

-- Reconcile server-created labels/prompts whose text changes after ownership/case swaps.
task.spawn(function()
    while true do
        task.wait(1.5)
        for _, instance in ipairs(player.PlayerGui:GetDescendants()) do
            if instance:IsA("TextLabel") or instance:IsA("TextButton") then localizeTextObject(instance) end
        end
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if instance:IsA("TextLabel") or instance:IsA("TextButton") then localizeTextObject(instance)
            elseif instance:IsA("ProximityPrompt") then localizePrompt(instance) end
        end
    end
end)
