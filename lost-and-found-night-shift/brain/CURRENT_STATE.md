# LOST & FOUND: NIGHT SHIFT — CURRENT STATE

Updated: 2026-08-27

## Identity
- Universe ID: `10745354451`
- Place ID: `93699016600671`
- Genre: Simulation
- Subgenre: None

## Infrastructure
- Temporary repo/build home: `balinightlife666-web/ACC-Android-Builder/lost-and-found-night-shift`
- Publish workflow is trigger-file/manual only.
- Deployment authority is `deploy-status/lost-and-found-m0.json`; never claim LIVE from source changes alone.

## M0 — FIRST SUITCASE
**COMPLETE / ACCEPTED.**

Core mobile loop is proven:
`spawn → incoming item → SCAN → CHECK TAG → OPEN → DECIDE → grade/reward → next case`

## M0.1 — FEEL PASS
**COMPLETE / ACCEPTED.**

Locked feel values:
- conveyor travel: 2.8s;
- case advance delay: 3.2s;
- interaction distance: 7 studs baseline;
- prompt hold: 0.08s;
- claimant arrival delay: 0.45s.

## M1 — PREMIUM ROOM
**COMPLETE / RUNTIME-APPROVED.**

Approved original base geometries:
1. `hardcase_suitcase`
2. `vintage_suitcase`
3. `backpack`
4. `cardboard_box`
5. `teddy_bear`

M1 visual authority remains `brain/M1_VISUAL_LOCK.md`.

## M2 — COLLECTION FOUNDATION

### M2-A — COMPLETE / ACCEPTED
- 3D ViewportFrame collection cards;
- locked silhouettes + `? / LOCKED`;
- discovered model + name + rarity;
- compact horizontal mobile carousel;
- front-facing 3D preview orientation accepted;
- no generated images used for collection visuals.

### M2-B — COMPLETE / ACCEPTED
- 10 stable case-specific collectible variants;
- stable `collectionId` on all 10 existing cases;
- per-player physical collection showcase;
- rarity ladder active through COMMON / UNCOMMON / RARE / EPIC / SECRET / ANOMALY.

### M2-C — COMPLETE / RUNTIME-ACCEPTED
Persistent payload through `LostAndFound_PlayerData_v1`:
- Credits;
- XP;
- discovered collection IDs.

Runtime leave/rejoin persistence accepted on mobile. DataStore safety fallback remains locked.

### M2-D — COMPLETE / RUNTIME-ACCEPTED
Collection count reached **15**.

Five PERFECT-only bonus finds accepted on mobile:
11. Silver Camera Lens — RARE — `LF-M0-005`
12. Ownerless Tag 000-17284 — ANOMALY — `LF-M0-006`
13. Flight 000 Boarding Tag — SECRET — `LF-M0-007`
14. Duplicate Passport — EPIC — `LF-M0-009`
15. Milo's Toy Train — SECRET — `LF-M0-010`

M2-D introduced new geometries:
- `camera_lens`
- `evidence_tag`
- `passport`
- `toy_train`

Mobile screenshots confirmed bonus-find collection cards, rarity rendering, locked silhouettes, and carousel behavior. The TAG / OPEN visual panels were subsequently corrected to dedicated upright front-facing panels in Roblox v23 so text remains horizontal/readable.

### M2-E — COMPLETE / RUNTIME-ACCEPTED
Collection count reached **20**. Every one of the 10 cases has exactly one PERFECT-only bonus collectible.

Five M2-E bonus finds accepted on mobile:
16. Maya's Power Adapter — UNCOMMON — `LF-M0-001`
17. Daniel's Formal Shoe — RARE — `LF-M0-002`
18. Sofia's Stitched Patch — RARE — `LF-M0-003`
19. Ari's Red Paperback — UNCOMMON — `LF-M0-004`
20. Unstable Mass Readout — ANOMALY — `LF-M0-008`

M2-E introduced geometries:
- `power_adapter`
- `formal_shoe`
- `name_patch`
- `paperback`
- `mass_readout`

Runtime acceptance confirmed:
- `/20` collection restores after rejoin;
- new bonus items persist;
- long card names wrap to two lines;
- new 3D preview geometries are readable on mobile;
- physical showcase / collection loop remains stable.

Trading remains locked.

## M3 — FLIGHT 000
Authority: `brain/M3_FLIGHT_000_LOCK.md`.

### M3-A — FIRST INCIDENT
**COMPLETE / USER-ACCEPTED ON v27.**

Trigger:
- `LF-M0-007 — Flight 000`;
- complete SCAN / TAG / OPEN;
- choose `QUARANTINE`;
- receive `PERFECT`.

Behavior:
- case reward and bonus discovery still resolve normally;
- Flight 000 PERFECT raises a server-wide terminal incident;
- transition to the next case is extended for readability;
- `ARCHIVE LOCKED` is visible before the incident and becomes `PENDING` during Flight 000;
- successful Flight 000 resolution unlocks `ARCHIVE 000-A`;
- archive contains only canon operational facts;
- exact final explanation remains **CANON UNKNOWN**.

Archive entry:
- Passenger record: FOUND — Jonas Vale
- Flight record: NOT FOUND
- Tag: F0-00013
- Operational action: QUARANTINE
- Status: CONNECTED / UNRESOLVED
- Note: transport origin remains impossible under current records
- Final explanation: CLASSIFIED / UNKNOWN

Acceptance note:
- v26 confirmed Archive control visibility on mobile;
- v27 fixed the missing incident-banner path by triggering the banner directly from the Flight 000 `RESULT` event while retaining the server incident event for archive synchronization;
- Arda explicitly accepted M3-A without repeating the full Flight 000 runtime loop again after the v27 hotfix;
- therefore M3-A is closed as **USER-ACCEPTED**, not independently re-verified end-to-end after v27.

M3-A limits remain locked:
- no new location/map expansion;
- no trading;
- no new currency;
- no final supernatural explanation;
- Lost Child 2001 and Ownerless Suitcase canon remain unchanged.

## Latest publish receipt
Run: `33069729711`
Source commit: `8fff876498aaeb4accdd9d97ae9b2e36da2026b1`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `27`
RBXL bytes: `48484`
RBXL SHA256: `ff184fec93eb04c45493dbac31315ab9120f80eb3ed0a9f6c3557afce2e19da0`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v27 BUILD/DEPLOY VERIFIED.**
M3-A is user-accepted and closed.

## Next gate
**M3-B — CONNECTED MYSTERY CHAIN**
Continue the Flight 000 storyline by connecting it to existing Season 1 pillars and operational evidence without revealing the final explanation. Preserve core loop, persistence, collection, and mobile readability. Trading remains locked until M4 review.
