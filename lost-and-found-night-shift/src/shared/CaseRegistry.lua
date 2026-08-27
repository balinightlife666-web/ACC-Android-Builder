local CaseRegistry = {}

CaseRegistry.Cases = {
    {
        id = "LF-M0-001", title = "Routine Claim", caseType = "normal", itemId = "hardcase_suitcase", collectionId = "blue_transit_hardcase", itemName = "Blue Hardcase Suitcase", itemColor = Color3.fromRGB(41, 72, 112), owner = "Maya Chen", claimantName = "Maya Chen", claimantKind = "Adult", tagNumber = "AC-18420", claimantTag = "AC-18420", flight = "GA-417", weight = "11.8 kg", contents = "Clothing, charger, paperback", scanStatus = "RECORD FOUND", anomaly = "None", correctDecision = "RETURN", questionableDecisions = {}, resolution = "CLOSED", risk = "low", reason = "Owner identity and baggage tag match the record.",
    },
    {
        id = "LF-M0-002", title = "Wrong Color", caseType = "normal", itemId = "backpack", collectionId = "crimson_travel_backpack", itemName = "Red Travel Backpack", itemColor = Color3.fromRGB(122, 44, 48), owner = "Daniel Ortiz", claimantName = "Daniel Ortiz", claimantKind = "Adult", tagNumber = "TR-90218", claimantTag = "TR-90218", flight = "QZ-751", weight = "8.2 kg", contents = "Formal clothing, shoes", scanStatus = "CLAIM DESCRIPTION CONFLICT", anomaly = "Claimant repeatedly describes a black backpack; this item is red.", correctDecision = "SECURITY", questionableDecisions = { "STORE" }, resolution = "CLOSED", risk = "medium", reason = "Identity matches, but the claimant's item description conflicts with the physical property. Escalate the suspicious claim.",
    },
    {
        id = "LF-M0-003", title = "Tag Mismatch", caseType = "normal", itemId = "teddy_bear", collectionId = "cream_memory_bear", itemName = "Cream Teddy Bear", itemColor = Color3.fromRGB(182, 151, 113), owner = "Sofia Rahman", claimantName = "Sofia Rahman", claimantKind = "Adult", tagNumber = "GA-33107", claimantTag = "GA-33170", flight = "GA-883", weight = "1.1 kg", contents = "Stuffed toy with stitched owner label", scanStatus = "TAG NUMBER MISMATCH", anomaly = "None", correctDecision = "STORE", questionableDecisions = { "SECURITY" }, resolution = "CLOSED", risk = "low", reason = "The claimant cannot prove this specific item is theirs. Keep it in storage pending valid documentation.",
    },
    {
        id = "LF-M0-004", title = "No Claimant", caseType = "normal", itemId = "vintage_suitcase", collectionId = "brown_heritage_case", itemName = "Brown Vintage Suitcase", itemColor = Color3.fromRGB(100, 68, 45), owner = "Ari Pratama", claimantName = nil, claimantKind = "None", tagNumber = "JT-66104", claimantTag = "—", flight = "ID-622", weight = "7.4 kg", contents = "Books, jacket, toiletries", scanStatus = "OWNER RECORD VALID / NO ACTIVE CLAIM", anomaly = "None", correctDecision = "STORE", questionableDecisions = {}, resolution = "CLOSED", risk = "low", reason = "The property is normal but currently unclaimed. Store it.",
    },
    {
        id = "LF-M0-005", title = "False Claim", caseType = "normal", itemId = "hardcase_suitcase", collectionId = "black_security_hardcase", itemName = "Black Hardcase Suitcase", itemColor = Color3.fromRGB(35, 38, 43), owner = "Emma Laurent", claimantName = "Kevin Brooks", claimantKind = "Adult", tagNumber = "AF-51033", claimantTag = "AF-51033", flight = "AF-129", weight = "12.1 kg", contents = "Clothing, camera lens", scanStatus = "CLAIMANT IDENTITY DOES NOT MATCH OWNER", anomaly = "Claimant has the correct tag number but is not the registered owner.", correctDecision = "SECURITY", questionableDecisions = { "STORE" }, resolution = "CLOSED", risk = "medium", reason = "A non-owner possesses the correct tag number. Escalate potential theft/fraud.",
    },
    {
        id = "LF-M0-006", title = "Ownerless Suitcase", caseType = "mystery", itemId = "vintage_suitcase", collectionId = "ownerless_vintage_case", itemName = "Ownerless Vintage Suitcase", itemColor = Color3.fromRGB(70, 45, 36), owner = "UNKNOWN", claimantName = nil, claimantKind = "None", tagNumber = "000-17284", claimantTag = "—", flight = "000", weight = "18.0 kg", contents = "No declared contents", scanStatus = "NO OWNER / NO VALID FLIGHT RECORD", anomaly = "The tag exists physically but has no database origin.", correctDecision = "QUARANTINE", questionableDecisions = { "STORE" }, resolution = "CONNECTED", risk = "high", reason = "An item with no valid owner and impossible origin must be contained, not returned or stored with normal property.",
    },
    {
        id = "LF-M0-007", title = "Flight 000", caseType = "mystery", itemId = "hardcase_suitcase", collectionId = "flight_000_hardcase", itemName = "Flight 000 Suitcase", itemColor = Color3.fromRGB(24, 28, 36), owner = "Jonas Vale", claimantName = "Jonas Vale", claimantKind = "Adult", tagNumber = "F0-00013", claimantTag = "F0-00013", flight = "000", weight = "13.0 kg", contents = "Unclear image on X-ray placeholder", scanStatus = "PASSENGER FOUND / FLIGHT NOT FOUND", anomaly = "The passenger record exists, but Flight 000 does not exist in the terminal schedule.", correctDecision = "QUARANTINE", questionableDecisions = { "SECURITY" }, resolution = "CONNECTED", risk = "high", reason = "The item's transport origin is impossible. Contain the item for anomaly review.",
    },
    {
        id = "LF-M0-008", title = "Changing Weight", caseType = "mystery", itemId = "cardboard_box", collectionId = "unstable_sealed_parcel", itemName = "Sealed Cardboard Parcel", itemColor = Color3.fromRGB(147, 108, 70), owner = "Nina Ward", claimantName = "Nina Ward", claimantKind = "Adult", tagNumber = "SQ-22191", claimantTag = "SQ-22191", flight = "SQ-944", weight = "7.0 kg → 43.0 kg", contents = "Appears empty", scanStatus = "MASS READING UNSTABLE", anomaly = "Repeated scans return incompatible weight values while the sealed parcel appears empty.", correctDecision = "QUARANTINE", questionableDecisions = { "SECURITY" }, resolution = "RESOLVED", risk = "high", reason = "Impossible physical readings require quarantine even when identity appears valid.",
    },
    {
        id = "LF-M0-009", title = "Double Identity", caseType = "mystery", itemId = "backpack", collectionId = "green_identity_backpack", itemName = "Green Travel Backpack", itemColor = Color3.fromRGB(55, 82, 66), owner = "Elias North", claimantName = "Elias North", claimantKind = "Adult", tagNumber = "KL-44381", claimantTag = "KL-44381", flight = "KL-836", weight = "6.2 kg", contents = "Two passports with the same name and different birth dates", scanStatus = "IDENTITY CONFLICT", anomaly = "Two valid-looking identities exist for one claimant.", correctDecision = "SECURITY", questionableDecisions = { "QUARANTINE" }, resolution = "UNRESOLVED", risk = "high", reason = "The immediate threat is an identity incident involving a person. Security must take control of the claimant and evidence.",
    },
    {
        id = "LF-M0-010", title = "The Lost Child", caseType = "mystery", itemId = "vintage_suitcase", collectionId = "milo_small_case", itemName = "Small Vintage Case", itemColor = Color3.fromRGB(86, 58, 43), owner = "Milo Hart", claimantName = "Milo Hart", claimantKind = "Child", tagNumber = "OLD-2001-14", claimantTag = "OLD-2001-14", flight = "ARCHIVED / 2001", weight = "3.1 kg", contents = "Toy train, old family photograph", scanStatus = "MISSING PERSON RECORD / 2001", anomaly = "The child matches a missing-person photo archived twenty-five years earlier.", correctDecision = "SECURITY", questionableDecisions = { "QUARANTINE" }, resolution = "CONNECTED", risk = "high", reason = "Protect and escalate the child. Do not treat a person as property and do not attempt to solve the anomaly alone.",
    },
}

function CaseRegistry.Get(index)
    return CaseRegistry.Cases[index]
end

function CaseRegistry.Count()
    return #CaseRegistry.Cases
end

return CaseRegistry
