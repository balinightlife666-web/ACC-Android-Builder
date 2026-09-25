# LOST & FOUND: NIGHT SHIFT — CURRENT STATE

Updated: 2026-09-24

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

## Accepted baseline
- M0 — FIRST SUITCASE — COMPLETE / ACCEPTED.
- Current execution phase: M6-C Live Service / Halloween Foundation.

## Latest VERIFIED LIVE baseline — Roblox v69
Status: **LIVE_PUBLISHED / RECEIPT VERIFIED / ANDROID RUNTIME QC PENDING**

- source commit: `cc4fbdbb64024fed29f995f069adc5b1baaca260`
- workflow run: `36034437502`
- Universe: `10745354451`
- Place: `93699016600671`
- RBXL bytes: `240392`
- RBXL SHA256: `95ce1e5c4c368d599947ec436ccfd58a26cc4b312d84c618b999c35c6ffb0820`
- published: `2026-09-24T17:27:44Z`

v69 includes the final M6-B mobile polish plus the dormant M6-C live-service foundation:
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
Status: **FOUNDATION LIVE IN v69 / HALLOWEEN CONTENT DORMANT / ACTIVATION PREP SOURCE-ONLY**

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
- Halloween 2026: disabled; exact runtime window TBD.
- HW26 source pool designed: Midnight Check-In Hardcase / Pumpkin Claim Tag / Black Cat Transit Backpack / Cold Room Parcel.
- all HW26 collectible definitions remain `dropEnabled=false`; no seasonal mint cap or drop chance approved.
- first event case definition: `LF-HW26-001 — Cold Room Parcel`; `selectionWeight=nil`, so it cannot enter runtime rotation.
- Halloween in-engine lobby dressing is implemented behind the event-state gate and remains invisible while the event is inactive.
- seasonal Collection definitions remain hidden unless the event is active or the player historically discovered/owns that seasonal item.
- seasonal Collection cards show an explicit edition token (for example `RARE • HW26` or `HW26 • LOCKED`).
- Christmas 2026: disabled; exact runtime window/pool/case hooks remain TBD.
- no seasonal reward/economy change has been activated.

v69 is now LIVE_PUBLISHED by explicit Arda instruction. Android runtime QC is still required before Halloween activation.

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
