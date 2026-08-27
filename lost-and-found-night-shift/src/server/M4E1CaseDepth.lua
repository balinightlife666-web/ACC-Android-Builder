-- LOST & FOUND: NIGHT SHIFT — M4-E.1 case depth patch.
-- Applies before PersonalShiftRuntime starts so routine jobs become less memorisable
-- without rewriting canonical Season 1 mystery cases or economy/drop rules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local M4E1CaseDepth = {}
local applied = false

local RNG = Random.new()
local runtimeCounter = 0
local MYSTERY_CANDIDATE_CHANCE = 0.35

local NAMES = {
    "Alya Putri", "Rafi Santoso", "Dimas Kurnia", "Nadia Prameswari", "Kevin Lim",
    "Mei Tan", "Hana Suzuki", "Kenji Mori", "Min Jae Park", "Soo Jin Lee",
    "Amira Hassan", "Omar Khalid", "Leila Farah", "Yusuf Rahman", "Maya Chen",
    "Daniel Ortiz", "Sofia Rahman", "Ari Pratama", "Emma Laurent", "Noah Bennett",
    "Lena Fischer", "Mateo Silva", "Camila Torres", "Lucas Martin", "Chloe Dubois",
    "Samir Patel", "Priya Nair", "Arjun Mehta", "Anika Rao", "Ethan Brooks",
    "Olivia Ward", "Mila Novak", "Leo Anders", "Sara Costa", "Adam Wilson",
    "Inez Romero", "Theo Grant", "Nora Ibrahim", "Farah Malik", "Kai Morgan",
    "Rina Sato", "Jae Kim", "Tariq Aziz", "Elena Rossi", "Marco Bellini",
    "Grace Lee", "Nathan Cole", "Zara Ahmed", "Julian Cross", "Mina Park",
    "Bagus Mahendra", "Putri Lestari", "Bima Saputra", "Citra Dewi", "Gita Anindya",
    "Fajar Nugroho", "Rizky Hidayat", "Sari Wulandari", "Aditya Permana", "Nisa Aulia",
    "Aisha Rahman", "Bilal Khan", "Fatima Noor", "Harun Malik", "Layla Abbas",
    "Chen Wei", "Lin Yue", "Wang Rui", "Zhang Min", "Liu Jia",
    "Haruto Sato", "Yui Nakamura", "Ren Kobayashi", "Aoi Takeda", "Daichi Ito",
    "Ji Woo Han", "Seo Jun Kim", "Ha Neul Park", "Ye Jin Choi", "Min Ho Lee",
    "Ana Ribeiro", "Tiago Costa", "Sofia Mendes", "Rafael Sousa", "Ines Martins",
    "Marta Kowalska", "Piotr Nowak", "Elena Popov", "Ivan Petrov", "Mira Jovanovic",
    "Amelie Laurent", "Louis Bernard", "Eva Muller", "Jonas Weber", "Luca Romano",
    "Isla Morgan", "Mason Reed", "Avery Carter", "Jordan Blake", "Taylor Quinn",
}

local FAMILY_FIRSTS = {
    "Alya", "Rafi", "Nadia", "Maya", "Daniel", "Sofia", "Ari", "Emma",
    "Noah", "Lena", "Mateo", "Camila", "Priya", "Arjun", "Rina", "Grace",
}

local AIRLINES = {
    "GA", "QZ", "SQ", "KL", "AF", "TR", "ID", "JT", "CX", "TG", "MH", "BR",
    "EK", "QR", "EY", "JL", "NH", "KE", "PR", "VN",
}

local ALT_COLORS = {
    "black", "blue", "red", "green", "cream", "brown", "silver", "navy",
    "grey", "white", "maroon", "olive",
}

local PROFILE_META = {
    [1] = {
        colorName = "blue",
        contents = {
            "Clothing, charger, paperback",
            "Two shirts, travel adapter, notebook",
            "Jacket, toiletries, phone cable",
            "Folded clothing, power bank, travel guide",
            "Sweater, charging cable, paperback novel",
        },
        minWeight = 85, maxWeight = 148,
    },
    [2] = {
        colorName = "red",
        contents = {
            "Formal clothing, shoes",
            "Tablet sleeve, shirt, headphones",
            "Documents, sweater, shoes",
            "Gym shirt, headphones, toiletry pouch",
            "Laptop sleeve, documents, light jacket",
        },
        minWeight = 42, maxWeight = 96,
    },
    [3] = {
        colorName = "cream",
        contents = {
            "Stuffed toy with stitched owner label",
            "Stuffed toy with fabric name patch",
            "Stuffed toy with small ribbon and stitched initials",
            "Stuffed toy with embroidered initials",
            "Stuffed toy with stitched repair on left arm",
        },
        minWeight = 7, maxWeight = 18,
    },
    [4] = {
        colorName = "brown",
        contents = {
            "Books, jacket, toiletries",
            "Paperback novels, scarf, shaving kit",
            "Clothes, old notebook, toiletries",
            "Two books, folded jacket, wash bag",
            "Clothing, reading glasses case, notebook",
        },
        minWeight = 58, maxWeight = 122,
    },
    [5] = {
        colorName = "black",
        contents = {
            "Clothing, camera lens",
            "Camera pouch, jacket, cables",
            "Clothing, lens case, memory-card wallet",
            "Camera strap, clothes, charger pouch",
            "Jacket, camera accessory pouch, cables",
        },
        minWeight = 92, maxWeight = 151,
    },
}

local recentScenarios = {}
local recentNames = {}

local function pick(list)
    return list[RNG:NextInteger(1, #list)]
end

local function cloneTable(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do
        result[key] = cloneTable(child)
    end
    return result
end

local function remember(list, value, limit)
    table.insert(list, value)
    while #list > limit do
        table.remove(list, 1)
    end
end

local function inRecent(list, value)
    for _, recent in ipairs(list) do
        if recent == value then return true end
    end
    return false
end

local function randomName(exclude)
    local value = pick(NAMES)
    local guard = 0
    while guard < 24 and (value == exclude or inRecent(recentNames, value)) do
        value = pick(NAMES)
        guard += 1
    end
    remember(recentNames, value, 12)
    return value
end

local function familyName(owner)
    local surname = string.match(tostring(owner), "(%S+)$") or tostring(owner)
    local candidate = pick(FAMILY_FIRSTS) .. " " .. surname
    if candidate == owner then
        candidate = "Nora " .. surname
    end
    return candidate
end

local function randomFlight()
    return pick(AIRLINES) .. "-" .. tostring(RNG:NextInteger(101, 989))
end

local function differentFlight(current)
    local value = randomFlight()
    local guard = 0
    while value == current and guard < 10 do
        value = randomFlight()
        guard += 1
    end
    return value
end

local function randomTag()
    return pick(AIRLINES) .. "-" .. string.format("%05d", RNG:NextInteger(1000, 99999))
end

local function changedTag(tag)
    local prefix, digits = string.match(tostring(tag), "^(%a+%-)(%d+)$")
    if not prefix or not digits then return tostring(tag) .. "X" end
    local last = tonumber(string.sub(digits, -1)) or 0
    local replacement = (last + RNG:NextInteger(1, 8)) % 10
    return prefix .. string.sub(digits, 1, #digits - 1) .. tostring(replacement)
end

local function randomWeight(meta)
    local tenths = RNG:NextInteger(meta.minWeight, meta.maxWeight)
    return string.format("%.1f kg", tenths / 10)
end

local function alternateColor(actual)
    local result = pick(ALT_COLORS)
    local guard = 0
    while result == actual and guard < 12 do
        result = pick(ALT_COLORS)
        guard += 1
    end
    return result
end

local SCENARIOS = {}

SCENARIOS.verified_return = function(c)
    c.scanStatus = "OWNER / TAG / ROUTING RECORD MATCH"
    c.reason = "Owner identity, claim tag and routing record all match the property."
end

SCENARIOS.delayed_scan_return = function(c)
    c.scanStatus = "OWNER MATCH / ROUTING UPDATE DELAYED"
    c.anomaly = "The transfer scan posted late, but the physical tag and claimant identity both match."
    c.reason = "A delayed routing update alone does not invalidate a verified owner and matching physical tag."
end

SCENARIOS.manual_tag_return = function(c)
    c.scanStatus = "BARCODE DAMAGED / MANUAL SERIAL MATCH"
    c.anomaly = "Barcode is unreadable; the printed serial, owner ID and claim receipt match exactly."
    c.reason = "The damaged barcode is compensated by matching manual serial, owner identity and claim receipt."
end

SCENARIOS.rerouted_return = function(c)
    local oldFlight = c.flight
    c.flight = differentFlight(oldFlight)
    c.scanStatus = "OWNER / TAG MATCH / ROUTING REBOOKED"
    c.anomaly = "Original routing " .. oldFlight .. " was replaced by " .. c.flight .. " after a documented rebooking."
    c.reason = "The route changed, but the owner, tag and official rebooking record all identify the same property."
end

SCENARIOS.authorized_proxy_return = function(c)
    c.claimantName = randomName(c.owner)
    c.claimantKind = "Authorized Collector"
    c.scanStatus = "REGISTERED COLLECTOR AUTHORIZATION / TAG MATCH"
    c.anomaly = "Claimant is not the owner, but a valid collection authorization is attached to the owner record."
    c.reason = "A verified authorized collector with the correct property tag may receive the item."
end

SCENARIOS.replacement_tag_return = function(c)
    local oldTag = changedTag(c.tagNumber)
    c.claimantTag = oldTag
    c.scanStatus = "REPLACEMENT TAG CROSS-LINK VERIFIED"
    c.anomaly = "The claimant receipt shows retired tag " .. oldTag .. "; the system links it to replacement tag " .. c.tagNumber .. "."
    c.reason = "The visible tag differs from the old receipt, but the official replacement-tag cross-link verifies the same property."
end

SCENARIOS.no_claimant_store = function(c)
    c.claimantName = nil
    c.claimantKind = "None"
    c.claimantTag = "—"
    c.scanStatus = "OWNER RECORD VALID / NO ACTIVE CLAIM"
    c.correctDecision = "STORE"
    c.reason = "The item has a valid record but nobody is currently proving a claim. Keep it stored."
end

SCENARIOS.tag_mismatch_store = function(c)
    c.claimantTag = changedTag(c.tagNumber)
    c.scanStatus = "CLAIM TAG DOES NOT MATCH PROPERTY"
    c.correctDecision = "STORE"
    c.questionableDecisions = { "SECURITY" }
    c.reason = "The claimant identity may be genuine, but the supplied claim tag does not prove ownership of this item."
end

SCENARIOS.no_tag_store = function(c)
    c.claimantTag = "NOT PROVIDED"
    c.scanStatus = "OWNER NAME FOUND / CLAIM PROOF INCOMPLETE"
    c.anomaly = "Claimant knows the owner name but cannot provide the claim tag or receipt."
    c.correctDecision = "STORE"
    c.reason = "Knowledge of the owner name is not enough to release property without proof tied to this item."
end

SCENARIOS.finder_store = function(c)
    c.claimantName = randomName(c.owner)
    c.claimantKind = "Finder"
    c.claimantTag = "FINDER TURN-IN"
    c.scanStatus = "THIRD-PARTY FINDER / OWNER RECORD FOUND"
    c.anomaly = "The person at the desk says they found the item and is not claiming ownership."
    c.correctDecision = "STORE"
    c.questionableDecisions = {}
    c.reason = "A finder is surrendering the property, not claiming it. Store it for the registered owner."
end

SCENARIOS.contents_conflict_store = function(c)
    c.scanStatus = "IDENTITY MATCH / CONTENT DESCRIPTION CONFLICT"
    c.anomaly = "Claimant identity and tag match, but their listed contents do not match the inspected contents."
    c.correctDecision = "STORE"
    c.questionableDecisions = { "SECURITY" }
    c.reason = "Conflicting contents weaken proof of this specific property. Hold it in storage pending better documentation."
end

SCENARIOS.expired_receipt_store = function(c)
    local previousTag = randomTag()
    c.claimantTag = previousTag
    c.scanStatus = "CLAIM RECEIPT VALID / WRONG JOURNEY"
    c.anomaly = "Receipt " .. previousTag .. " belongs to an earlier trip and is not cross-linked to property tag " .. c.tagNumber .. "."
    c.correctDecision = "STORE"
    c.reason = "A genuine old receipt does not prove ownership of this current item. Keep the property stored."
end

SCENARIOS.unauthorized_family_store = function(c)
    c.claimantName = familyName(c.owner)
    c.claimantKind = "Family Member"
    c.scanStatus = "FAMILY RELATION CLAIMED / NO COLLECTION AUTHORIZATION"
    c.anomaly = "The claimant shares the owner's surname and knows the tag, but no authorized-collector record exists."
    c.correctDecision = "STORE"
    c.questionableDecisions = {}
    c.reason = "Family relationship alone does not authorize release of property without the owner's recorded permission."
end

SCENARIOS.intake_route_hold_store = function(c)
    local transferDesk = "DESK-" .. tostring(RNG:NextInteger(2, 9))
    c.scanStatus = "OWNER / TAG MATCH / INTAKE ROUTE HOLD"
    c.anomaly = "The property record is valid, but a pending transfer to " .. transferDesk .. " has not been cancelled by operations."
    c.correctDecision = "STORE"
    c.questionableDecisions = {}
    c.reason = "Ownership is credible, but an unresolved operational hold prevents release until routing is cleared."
end

SCENARIOS.description_conflict_security = function(c, meta)
    local claimed = alternateColor(meta.colorName)
    c.scanStatus = "CLAIM DESCRIPTION CONFLICT"
    c.anomaly = "Claimant repeatedly describes a " .. claimed .. " item; the inspected property is " .. meta.colorName .. "."
    c.correctDecision = "SECURITY"
    c.questionableDecisions = { "STORE" }
    c.risk = "medium"
    c.reason = "The claimant has matching paperwork but gives a materially wrong physical description. Escalate possible fraud."
end

SCENARIOS.identity_mismatch_security = function(c)
    c.claimantName = randomName(c.owner)
    c.scanStatus = "CLAIMANT IDENTITY DOES NOT MATCH REGISTERED OWNER"
    c.anomaly = "The claimant presents the exact tag number but their identity differs from the registered owner, with no collector authorization."
    c.correctDecision = "SECURITY"
    c.questionableDecisions = { "STORE" }
    c.risk = "medium"
    c.reason = "A non-owner possessing the exact claim tag without authorization requires a security review for possible theft or fraud."
end

SCENARIOS.duplicate_claim_security = function(c)
    c.scanStatus = "DUPLICATE ACTIVE CLAIM DETECTED"
    c.anomaly = "A second person submitted a verified-looking claim for this exact tag less than ten minutes earlier."
    c.correctDecision = "SECURITY"
    c.questionableDecisions = { "STORE" }
    c.risk = "medium"
    c.reason = "Two competing verified-looking claims for one tag require security to preserve evidence and identities."
end

SCENARIOS.tampered_tag_security = function(c)
    c.scanStatus = "TAG ALTERATION DETECTED"
    c.anomaly = "Scanner detects two adhesive layers and overwritten digits beneath the visible claim tag."
    c.correctDecision = "SECURITY"
    c.questionableDecisions = { "STORE" }
    c.risk = "high"
    c.reason = "Physical evidence of claim-tag tampering indicates possible deliberate fraud."
end

SCENARIOS.copied_tag_security = function(c)
    c.scanStatus = "TAG SERIAL DUPLICATED ON ANOTHER ACTIVE ITEM"
    c.anomaly = "The same tag number is currently registered to a different item in another terminal record."
    c.correctDecision = "SECURITY"
    c.questionableDecisions = { "STORE" }
    c.risk = "high"
    c.reason = "A duplicated live tag is evidence of possible label cloning or fraud and must be escalated."
end

SCENARIOS.forged_receipt_security = function(c)
    c.scanStatus = "CLAIM RECEIPT CHECKSUM INVALID"
    c.anomaly = "The printed receipt matches the visible tag number, but its verification code belongs to a different transaction."
    c.correctDecision = "SECURITY"
    c.questionableDecisions = { "STORE" }
    c.risk = "high"
    c.reason = "A deliberately falsified-looking receipt tied to the correct tag is evidence requiring security review."
end

SCENARIOS.multi_claim_pattern_security = function(c)
    c.scanStatus = "CLAIMANT FLAG / MULTIPLE UNRELATED ACTIVE CLAIMS"
    c.anomaly = "The claimant has three active claims for unrelated owners and presents the exact tag for this item without authorization."
    c.claimantName = randomName(c.owner)
    c.correctDecision = "SECURITY"
    c.questionableDecisions = { "STORE" }
    c.risk = "high"
    c.reason = "Possession of several unrelated claim credentials plus this exact tag indicates a pattern that security must investigate."
end

SCENARIOS.restricted_item_security = function(c)
    c.scanStatus = "INSPECTION ALERT / UNDECLARED RESTRICTED OBJECT"
    c.anomaly = "Inspection reveals an undeclared restricted sharp object concealed beneath ordinary contents."
    c.correctDecision = "SECURITY"
    c.questionableDecisions = { "QUARANTINE" }
    c.risk = "high"
    c.reason = "The immediate issue is a restricted security item requiring controlled handoff to terminal security."
end

SCENARIOS.unsafe_battery_quarantine = function(c)
    c.scanStatus = "THERMAL WARNING / INTERNAL BATTERY SWELLING"
    c.anomaly = "Inspection finds a hot, swollen battery pack inside the property."
    c.correctDecision = "QUARANTINE"
    c.questionableDecisions = { "SECURITY" }
    c.risk = "high"
    c.reason = "The immediate issue is a hazardous item requiring controlled isolation, regardless of ownership."
end

SCENARIOS.liquid_leak_quarantine = function(c)
    c.scanStatus = "UNKNOWN LIQUID LEAK DETECTED"
    c.anomaly = "A sealed inner container is leaking an unidentified liquid with no declaration in the property record."
    c.correctDecision = "QUARANTINE"
    c.questionableDecisions = { "SECURITY" }
    c.risk = "high"
    c.reason = "Unknown leaking material must be isolated before normal storage, return or investigative handling."
end

SCENARIOS.chemical_odor_quarantine = function(c)
    c.scanStatus = "AIR QUALITY ALERT / UNKNOWN CHEMICAL ODOR"
    c.anomaly = "Opening the property produces a strong unknown chemical odor not listed in the contents declaration."
    c.correctDecision = "QUARANTINE"
    c.questionableDecisions = { "SECURITY" }
    c.risk = "high"
    c.reason = "An unidentified chemical exposure risk requires isolation before any ownership decision."
end

SCENARIOS.rising_heat_quarantine = function(c)
    c.scanStatus = "REPEATED TEMPERATURE RISE DETECTED"
    c.anomaly = "Two scans several seconds apart show the sealed property heating rapidly with no declared powered device."
    c.correctDecision = "QUARANTINE"
    c.questionableDecisions = { "SECURITY" }
    c.risk = "high"
    c.reason = "Unexplained rapid heating is an immediate safety hazard and must be isolated."
end

local EASY_POOL = {
    { "verified_return", 24 },
    { "delayed_scan_return", 10 },
    { "no_claimant_store", 16 },
    { "tag_mismatch_store", 16 },
    { "no_tag_store", 12 },
    { "finder_store", 8 },
    { "identity_mismatch_security", 8 },
    { "contents_conflict_store", 6 },
}

local MEDIUM_POOL = {
    { "verified_return", 14 },
    { "delayed_scan_return", 8 },
    { "manual_tag_return", 10 },
    { "rerouted_return", 8 },
    { "authorized_proxy_return", 8 },
    { "replacement_tag_return", 6 },
    { "no_claimant_store", 8 },
    { "tag_mismatch_store", 8 },
    { "no_tag_store", 6 },
    { "finder_store", 5 },
    { "contents_conflict_store", 7 },
    { "expired_receipt_store", 6 },
    { "unauthorized_family_store", 5 },
    { "description_conflict_security", 5 },
    { "identity_mismatch_security", 5 },
    { "duplicate_claim_security", 4 },
    { "unsafe_battery_quarantine", 4 },
    { "liquid_leak_quarantine", 3 },
}

local HARD_POOL = {
    { "verified_return", 6 },
    { "delayed_scan_return", 5 },
    { "manual_tag_return", 6 },
    { "rerouted_return", 7 },
    { "authorized_proxy_return", 7 },
    { "replacement_tag_return", 7 },
    { "no_claimant_store", 5 },
    { "tag_mismatch_store", 6 },
    { "no_tag_store", 4 },
    { "finder_store", 4 },
    { "contents_conflict_store", 6 },
    { "expired_receipt_store", 7 },
    { "unauthorized_family_store", 7 },
    { "intake_route_hold_store", 6 },
    { "description_conflict_security", 6 },
    { "identity_mismatch_security", 6 },
    { "duplicate_claim_security", 6 },
    { "tampered_tag_security", 7 },
    { "copied_tag_security", 7 },
    { "forged_receipt_security", 8 },
    { "multi_claim_pattern_security", 7 },
    { "restricted_item_security", 6 },
    { "unsafe_battery_quarantine", 5 },
    { "liquid_leak_quarantine", 5 },
    { "chemical_odor_quarantine", 4 },
    { "rising_heat_quarantine", 4 },
}

local function weightedScenario(pool)
    local weighted = {}
    local total = 0

    for _, entry in ipairs(pool) do
        local id = entry[1]
        local weight = entry[2]
        if inRecent(recentScenarios, id) then
            weight = math.max(1, math.floor(weight * 0.18))
        end
        total += weight
        table.insert(weighted, { id = id, weight = weight })
    end

    local roll = RNG:NextNumber() * total
    local running = 0
    for _, entry in ipairs(weighted) do
        running += entry.weight
        if roll <= running then
            remember(recentScenarios, entry.id, 7)
            return entry.id
        end
    end

    local fallback = weighted[#weighted].id
    remember(recentScenarios, fallback, 7)
    return fallback
end

local function baseRoutine(CaseRegistry, profileIndex, tier)
    local canonical = CaseRegistry.GetCanonical and CaseRegistry.GetCanonical(profileIndex) or CaseRegistry.Cases[profileIndex]
    local meta = PROFILE_META[profileIndex]
    local c = cloneTable(canonical)

    runtimeCounter += 1
    local owner = randomName(nil)
    local tag = randomTag()

    c.id = string.format("LF-R-%06d-%03d", RNG:NextInteger(0, 999999), runtimeCounter % 1000)
    c.sourceCaseId = canonical.id
    c.title = "Property Review"
    c.caseType = "normal"
    c.owner = owner
    c.claimantName = owner
    c.claimantKind = "Adult"
    c.tagNumber = tag
    c.claimantTag = tag
    c.flight = randomFlight()
    c.weight = randomWeight(meta)
    c.contents = pick(meta.contents)
    c.scanStatus = "RECORD FOUND"
    c.anomaly = "None"
    c.correctDecision = "RETURN"
    c.questionableDecisions = {}
    c.resolution = "CLOSED"
    c.risk = "low"
    c.reason = "Identity, tag and property record support the same claimant."
    c.runtimeRoutine = true
    c.difficultyTier = tier

    return c, meta
end

local function generateRoutine(CaseRegistry, profileIndex, tier)
    local c, meta = baseRoutine(CaseRegistry, profileIndex, tier)
    local pool = tier == "easy" and EASY_POOL or (tier == "medium" and MEDIUM_POOL or HARD_POOL)
    local scenarioId = weightedScenario(pool)
    c.scenarioId = scenarioId
    SCENARIOS[scenarioId](c, meta)
    return c
end

function M4E1CaseDepth.Apply()
    if applied then return end

    local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
    local CaseRegistry = require(shared:WaitForChild("CaseRegistry"))

    if CaseRegistry.__M4E1DepthApplied then
        applied = true
        return
    end

    CaseRegistry.__M4E1DepthApplied = true

    CaseRegistry.Get = function(index)
        if index >= 1 and index <= 5 then
            local tier = index <= 2 and "easy" or (index == 3 and "medium" or "hard")
            return generateRoutine(CaseRegistry, index, tier)
        end

        if index >= 6 and index <= 10 then
            if RNG:NextNumber() <= MYSTERY_CANDIDATE_CHANCE then
                return CaseRegistry.Cases[index]
            end
            return generateRoutine(CaseRegistry, RNG:NextInteger(1, 5), "hard")
        end

        return CaseRegistry.Cases[index]
    end

    applied = true
end

return M4E1CaseDepth
