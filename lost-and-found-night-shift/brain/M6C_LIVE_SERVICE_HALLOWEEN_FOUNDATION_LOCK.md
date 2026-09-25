# LOST & FOUND: NIGHT SHIFT — M6-C LIVE SERVICE / HALLOWEEN FOUNDATION LOCK v1.2

Date: 2026-09-24  
Status: **FOUNDATION LIVE v69 / ACTIVATION PREP SOURCE-ONLY**

## Purpose
M6-C creates the reusable live-service foundation and first Halloween 2026 content package without activating the event prematurely or changing the existing economy/canon.

This execution label follows M6-A/M6-B progression work and maps to the live-service direction previously described in `ROADMAP.md`.

## Foundation now implemented
- shared seasonal event registry;
- server-authoritative replicated event-state folder;
- explicit seasonal edition tokens:
  - Halloween 2026: `HW26`
  - Christmas 2026: `XMAS26`;
- seasonal collection-definition registration that preserves persistence/trading recognition;
- per-player Collection visibility: seasonal cards appear only while their event is active or when that player already discovered/owns the item;
- event-case registration separate from canonical `CaseRegistry.Cases`;
- event cases require an explicit positive `selectionWeight` before entering live rotation;
- seasonal drops can be hard-disabled per item;
- event-gated Roblox 3D room dressing that stays outside SCAN / TAG / OPEN / decision lanes;
- existing `StationSkinRegistry` event skins remain reserved theme IDs.

## Hard locks
1. Halloween 2026 and Christmas 2026 remain **disabled** until Arda approves exact start/end windows.
2. Missing/invalid windows can never activate an event.
3. Halloween content definitions may exist in source while remaining unavailable in runtime.
4. Every current HW26 collectible is locked with `dropEnabled = false`.
5. Halloween case `LF-HW26-001` has no approved `selectionWeight`; therefore it cannot enter case rotation.
6. No seasonal drop chance or mint cap is approved yet.
7. Existing S1 collectible edition/serial behavior remains unchanged.
8. Existing Credits, XP, rewards, base rarity/drop targets, progression, trading, showcase, station ownership and decision colors remain unchanged.
9. Mystery canon remains unchanged; Flight 000 / Lost Child explanations remain CANON UNKNOWN.
10. Halloween content is self-contained seasonal fiction and does not explain the Season 1 mystery.
11. Seasonal visuals remain Roblox 3D/procedural/in-engine.
12. Do not publish M6-C over the current v68 runtime-QC baseline until the v68 Android polish check is accepted or Arda explicitly overrides that gate.

## Halloween 2026 identity
- event ID: `HALLOWEEN_2026`
- edition token: `HW26`
- real-world anchor: `2026-10-31`
- station skin ID: `HALLOWEEN_2026`
- environment profile: `HALLOWEEN`
- runtime window: **TBD / disabled**

### Designed HW26 collectible pool
1. `hw26_midnight_hardcase`
   - Midnight Check-In Hardcase
   - RARE
   - serial prefix `MCH`
2. `hw26_pumpkin_claim_tag`
   - Pumpkin Claim Tag
   - EPIC
   - serial prefix `PCT`
3. `hw26_black_cat_backpack`
   - Black Cat Transit Backpack
   - EPIC
   - serial prefix `BCT`
4. `hw26_cold_room_parcel`
   - Cold Room Parcel
   - ANOMALY
   - serial prefix `CRP`

All four use edition `HW26`, remain trade-compatible in definition, and currently have `dropEnabled = false` with no mint cap.

### First event case hook
`LF-HW26-001 — Cold Room Parcel`

Operational evidence:
- claimant + claim tag match;
- temperature sensor is materially abnormal;
- a sealed tin inside produces repeated tapping after movement stops.

Correct action:
- `QUARANTINE`

Questionable:
- `SECURITY`

Resolution:
- `RESOLVED`

The case does not provide a definitive supernatural explanation and has no link that rewrites Flight 000 / Ownerless Suitcase / Lost Child canon.

Selection state:
- `selectionWeight = nil`
- therefore **not eligible for runtime rotation**.

## Halloween room dressing
Source:
`src/server/M6CHalloweenEnvironment.server.lua`

When and only when `LostAndFoundLiveServiceState` reports active `HALLOWEEN_2026`:
- lobby/front-wall Halloween operations banner;
- small Roblox-part pumpkins;
- controlled orange/violet local light accents;
- decorations are anchored, non-colliding, non-touching and non-querying;
- station interaction lanes remain clear.

When event is inactive, seasonal decor is removed/not created.

## Christmas 2026
- event ID: `CHRISTMAS_2026`
- edition token: `XMAS26`
- real-world anchor: `2026-12-25`
- station skin ID: `CHRISTMAS_2026`
- environment profile: `CHRISTMAS`
- runtime window: **TBD / disabled**
- collection pool: **TBD**
- event case hooks: **TBD**

## Remaining pre-launch gates
1. v68 Android runtime acceptance for M6-B polish.
2. Approve Halloween event start/end window.
3. Approve event-case selection weight/frequency.
4. Approve seasonal drop behavior and any mint caps.
5. Add clear HW26 edition presentation to Collection card/serial UI.
6. Static/regression QC.
7. Publish through the locked LOST FOUND issue route and verify exact receipt.
8. Android runtime/event QC before calling Halloween LIVE.


## Activation candidate (not applied)
Source: `src/shared/M6CHalloweenActivationCandidate.lua`

Candidate window:
- 24 October 2026 00:00 WITA
- through 4 November 2026 00:00 WITA

Candidate event cases:
- `LF-HW26-001 — Cold Room Parcel`
- `LF-HW26-002 — Midnight Check-In`
- `LF-HW26-003 — Black Cat Transit`

Candidate case weights:
- 2 / 2 / 2

Candidate seasonal ownership rolls:
- Midnight Check-In Hardcase: 35%
- Pumpkin Claim Tag: 20%
- Black Cat Transit Backpack: 20%
- Cold Room Parcel: 10%

Candidate mint policy:
- no hard cap in v1;
- scarcity comes from the limited event window, per-item drop chance, and immutable HW26 serial provenance.

These values are design-only. The candidate module is not required by runtime code. Runtime remains locked with:
- event `enabled=false`;
- event case `selectionWeight=nil`;
- collectible `dropEnabled=false`.
