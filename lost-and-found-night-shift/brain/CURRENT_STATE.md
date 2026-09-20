# LOST & FOUND: NIGHT SHIFT — CURRENT STATE

Updated: 2026-09-20

## Identity / infrastructure
- Universe ID: `10745354451`
- Place ID: `93699016600671`
- Repo/build home: `balinightlife666-web/ACC-Android-Builder/lost-and-found-night-shift`
- Publisher: `.github/workflows/lost-found-m0-publish.yml`
- Official issue trigger prefix: `LOST FOUND M0 PUBLISH`
- Roblox secret authority: `ROCKET_RACOON_PUBLISH`
- Rojo: `7.7.0`
- Deploy authority: `deploy-status/lost-and-found-m0.json`

Never call a new build LIVE/VERIFIED without a valid deploy receipt. Runtime PASS remains a separate Roblox-client gate.

## Latest VERIFIED LIVE baseline — Roblox v68
Status: **LIVE_PUBLISHED / RECEIPT VERIFIED / ANDROID RUNTIME POLISH QC PENDING**

- source commit: `5fae0e20e9dd336e352ce743b1d88479e5b6e91e`
- workflow run: `35366469917`
- Universe: `10745354451`
- Place: `93699016600671`
- RBXL bytes: `231605`
- RBXL SHA256: `6a9a7448c438307c382300a2020ccd753821d117b5bc4977d5bd9ad2df96694f`
- published: `2026-09-18T16:06:37Z`

v68 includes the final M6-B mobile polish:
- Station Shop uses an invisible input blocker instead of a visible dark backdrop.
- Collection gets visual priority by suppressing Progression + Career HUD while open and restoring prior Enabled state when closed.
- Unified MENU V2 remains the only runtime menu authority.

## M6-B status
Phase: **Unlock / Career Tiers + final mobile polish**

Source/deploy gates: PASS.  
Runtime gate: **PENDING Android verification**.

Hard locks remain:
- existing XP is the only progression XP;
- no second progression DataStore/currency;
- Shift 6/8/10 are prestige/career presentation only;
- grandfathered owned skins remain equip-safe;
- reward/economy/drop/canon/serial/trade/showcase rules are unchanged.

## M6-C — Live Service / Halloween Foundation
Status: **SOURCE FOUNDATION / DORMANT / NOT LIVE**

Authority:
- `brain/M6C_LIVE_SERVICE_HALLOWEEN_FOUNDATION_LOCK.md`
- `brain/SEASONAL_EVENTS_LOCK.md`

Implemented in source:
- `src/shared/LiveServiceEventRegistry.lua`
- `src/server/LiveServiceEventService.lua`
- server-replicated `LostAndFoundLiveServiceState` attributes;
- reserved Halloween 2026 edition token `HW26`;
- reserved Christmas 2026 edition token `XMAS26`;
- backward-compatible `CollectionRegistry` support for future `edition` + `eventId` metadata;
- milestone metadata updated to `M6-C — LIVE SERVICE FOUNDATION`.

Current event state:
- Halloween 2026: disabled; exact runtime window TBD; pool empty; case hooks empty.
- Christmas 2026: disabled; exact runtime window TBD; pool empty; case hooks empty.
- no seasonal drop rate, mint cap, rarity mix, reward, room transformation or event case has been activated.

M6-C source must not be published over v68 until the v68 Android polish runtime check is accepted, unless Arda explicitly overrides that gate.

## Core gameplay locks
Loop:
`ITEM ARRIVES → SCAN → CHECK TAG → OPEN / INSPECT → DECIDE → RESULT → REWARD → NEXT ITEM`

Decision colors:
- RETURN = green
- STORE = cyan / blue
- QUARANTINE = amber / yellow
- SECURITY = red

Rewards:
- PERFECT = 30 Credits / 20 XP
- CORRECT = 20 Credits / 10 XP
- QUESTIONABLE = 5 Credits / 3 XP
- WRONG = 0 / 0
- CATASTROPHIC = 0 / 0

Drop targets:
- COMMON 100%
- UNCOMMON 85%
- RARE 65%
- EPIC 40%
- ANOMALY 16%
- SECRET 8%

## Canon locks
- Ownerless Suitcase → QUARANTINE
- Flight 000 → QUARANTINE; final explanation CANON UNKNOWN
- Changing Weight → QUARANTINE
- Double Identity → SECURITY
- The Lost Child → SECURITY / protective escalation
- Lost Child archive year: 2001
- Lost Child supernatural explanation: CANON UNKNOWN

## Collection / serial / trade locks
- Collection Index = historical discovery/prestige.
- Inventory Instance = actual transferable serialized collectible.
- immutable instanceId / serial / global mint / provenance.
- trading does not re-mint.
- Credits are non-transferable.
- Credits cannot directly buy SECRET / ANOMALY.
- no RMT / off-platform trading.

## Multiplayer / station locks
- 8 active personal stations A–H.
- personal case/item/decision/timer/reward/persistent station profile.
- server validates station ownership.
- showcase is public flex.
- serialized trading is same-server.
- stable showcase must not periodic destroy/recreate or continuously repivot unchanged items.

## Active gate
1. Arda tests Roblox v68 on Android landscape.
2. Confirm Station Shop has no visible backdrop and gameplay taps remain blocked behind it.
3. Confirm Collection header is no longer covered by Progression/Career HUD and HUD restores after close.
4. Confirm unified MENU still routes INDEKS → ARSIP → TUKAR → TOKO STASIUN.
5. Confirm close returns to normal gameplay.
6. Only then mark M6-B runtime PASS.
7. After that, approve exact Halloween event window before enabling any M6-C event content.
