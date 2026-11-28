# M6-C Christmas 2026 — preparation
Date: 2026-11-28
Status: SOURCE PREPARATION ONLY — NOT PUBLISHED / NOT ENABLED

## Content
- Four XMAS26 collectibles: Noel Transit Hardcase (RARE, NTH); Winter Keepsake Bear (EPIC, WKB); Frost-Sealed Parcel (ANOMALY, FSP); Crimson Holiday Backpack (EPIC, CHB).
- Three independent event cases: LF-XMAS26-001 The Last Holiday Check-In → RETURN; LF-XMAS26-002 The Unclaimed Keepsake → STORE; LF-XMAS26-003 The Frost-Sealed Parcel → QUARANTINE.
- Existing base geometry, procedural non-colliding lobby gifts, banner and warm lights. No new external assets.
- Shared registration and client preview support both seasonal packs.
- Runtime case selection, collection visibility and seasonal drop rolls use validated event configuration; seasonal drops are rejected after the active window closes. Already completed discovery/history is preserved.

## Activation lock
Both events remain disabled. All new drops and case weights remain locked. Halloween candidate dates have elapsed; do not activate retroactively. Christmas dates, weights, drop chances and mint policy require explicit approval. No rewards, base cases, canon, currency, save format or trade rules changed.

## Proposed schedule (NOT APPROVED)
18 December 2026 00:00 WITA through 4 January 2027 00:00 WITA (exclusive).
No runtime timestamps are set. No seasonal probabilities or mint limits are approved.

## Gates
1. v69 Android HUD/Shop/Collection/MENU regression.
2. Source static/build QC and event disabled smoke test.
3. Approve schedule, weights, drop probabilities and mint policy; verify localization and 3D previews.
4. Test invalid config, event start/end, expired-case drop lock, history preservation, ownership/trade and low-end Android performance.
5. Publish exact source through locked publisher and verify receipt before LIVE claim.
