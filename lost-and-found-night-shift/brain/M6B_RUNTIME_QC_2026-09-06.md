# LOST & FOUND: NIGHT SHIFT — M6-B RUNTIME QC CHECKPOINT

Date: 2026-09-06
Status: STATIC / DEPLOY VERIFICATION PASS — IN-ROBLOX RUNTIME EVIDENCE PENDING
Scope: M6-B Unlock & Career Tiers only

## Deployment route lock

Primary publisher route is locked to:
- repository: `balinightlife666-web/ACC-Android-Builder`
- workflow: `.github/workflows/lost-found-m0-publish.yml`
- issue trigger prefix: `LOST FOUND M0 PUBLISH`
- Roblox secret authority: `ROCKET_RACOON_PUBLISH`
- Universe ID: `10745354451`
- Place ID: `93699016600671`
- Rojo: `7.7.0`
- receipt: `deploy-status/lost-and-found-m0.json`

Do not use the former `ardarawk-cloud/ACC-Roblox-maps` rescue route as the default publisher unless Arda explicitly changes the route.

## M6-B source authority

M6-B merge commit:
`828bf3e73defb3798244feb2f3ba6badab7ea46b`

Published v62 checkout source:
`a834a6351a5a3f4a19b52402f8cca5a5684003fd`

Comparison `828bf3e...` → `a834a635...` contains only unrelated BBYA deploy-status changes. No `lost-and-found-night-shift/` gameplay/source file differs between the M6-B merge and the v62 checkout.

Hard governance note: the receipt does not equal the exact M6-B merge SHA, therefore do not label M6-B `VERIFIED LIVE` solely from this equivalence. Runtime evidence is also still required.

## Verified Roblox publish receipt

- status: `LIVE_PUBLISHED`
- Roblox version: `62`
- workflow run: `33866815546`
- sourceCommit: `a834a6351a5a3f4a19b52402f8cca5a5684003fd`
- Universe: `10745354451`
- Place: `93699016600671`
- Rojo: `7.7.0`
- RBXL bytes: `224499`
- RBXL SHA256: `2ab58a39f9ab1b9a4e58bc9d43d1021e03835e41b3d1420958c2b5397bfea11c`

## Static M6-B QC — PASS

### Progression authority
- Existing persistent XP remains the only XP authority.
- M6-A derives Shift Level from XP thresholds 0 / 100 / 250 / 500 / 900 / 1400 / 2100 / 3000 / 4200 / 5600.
- M6-B consumes `LostFoundShiftLevel`; no second XP currency or progression DataStore exists.
- Career state is event-driven and revision-tagged with `LostFoundCareerRevision`.

### Career / station gates
New acquisition gates are server-authoritative:
- STANDARD_OPS — Shift 1
- INDUSTRIAL_SHIFT — Shift 2
- RETRO_AIRPORT — Shift 3
- BLACK_OPS — Shift 4
- ARMY_FIELD — Shift 5
- SAKURA_NIGHT — Shift 7
- STREET_GRAFFITI — Shift 9

Server rejects under-level new purchase attempts with `LEVEL_LOCKED` and returns current/required Shift Level.

### Grandfather rule
Owned skins are checked before the new acquisition gate and the equip path has no Shift-Level gate. Previously-owned station skins therefore remain equip-safe.

### Regression locks
Confirmed unchanged in current source:
- PERFECT = 30 Credits / 20 XP
- CORRECT = 20 Credits / 10 XP
- QUESTIONABLE = 5 Credits / 3 XP
- WRONG = 0 / 0
- CATASTROPHIC = 0 / 0
- collection drop targets = COMMON 100%, UNCOMMON 85%, RARE 65%, EPIC 40%, ANOMALY 16%, SECRET 8%
- no M6-B mutation to serialized inventory, global mint, provenance, trading, showcase lifecycle, case grading, mystery canon, or decision-color semantics.

### Client presentation
- Career bar is below the M6-A progression HUD.
- Level-up feedback is presentation-only.
- Station Shop buttons are visibly locked to `SHIFT N` before server acquisition eligibility.
- Server remains final authority if a client gate is bypassed.

Known non-blocking localization edge case:
- `StationShop.client.lua` does not currently localize fallback code `LEVEL_LOCKED`; bypass/race fallback can display the server's English `Requires Shift Level N.` message.
- Normal locked-button UX is unaffected.
- Do not change v62 solely for this cosmetic edge case during runtime verification.

## In-Roblox runtime gates — PENDING

M6-B cannot be marked runtime PASS until actual Roblox client/server evidence confirms:

1. Existing-save join preserves Credits, XP, INDEX/ARCHIVE, serialized ownership and equipped station skin.
2. Shift Level/title shown by M6-A matches the player's persisted XP.
3. M6-B career bar shows the correct tier and next unlock.
4. A below-level unowned skin displays `SHIFT N` and cannot be newly acquired.
5. Direct/bypassed purchase request below the required level is rejected by the server without Credits loss or profile mutation.
6. An eligible skin becomes purchasable at the exact required Shift Level.
7. A previously-owned higher-tier skin can still be equipped below its new acquisition requirement.
8. Shift 6 / 8 / 10 promotions grant presentation/prestige only; no gameplay power or economy mutation.
9. Decision consoles retain RETURN green / STORE cyan-blue / QUARANTINE amber-yellow / SECURITY red after station skin equip.
10. Full core loop remains functional: ITEM ARRIVES → SCAN → CHECK TAG → OPEN/INSPECT → DECIDE → RESULT → REWARD → NEXT ITEM.
11. Reward values and collectible drop behavior remain consistent with locked Config values.
12. No showcase flicker/regression occurs while station progression/shop state updates.

## Exit rule

Only after the runtime gates above have real in-game evidence may M6-B move from:
`SOURCE MERGED + ROBLOX v62 PUBLISHED + STATIC QC PASS`

to:
`M6-B VERIFIED LIVE / RUNTIME PASS`.
