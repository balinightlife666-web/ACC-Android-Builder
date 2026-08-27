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
- front-facing 3D preview orientation accepted on v20;
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

### M2-D — CONTROLLED COLLECTION EXPANSION
**IMPLEMENTED / LIVE v22 — RUNTIME QC PENDING.**

Collection count is now **15**.

The original 10 case-resolution collectibles remain unchanged. Five new **PERFECT-only bonus finds** were added:
11. Silver Camera Lens — RARE — `LF-M0-005`
12. Ownerless Tag 000-17284 — ANOMALY — `LF-M0-006`
13. Flight 000 Boarding Tag — SECRET — `LF-M0-007`
14. Duplicate Passport — EPIC — `LF-M0-009`
15. Milo's Toy Train — SECRET — `LF-M0-010`

New M2-D collectible geometries:
- `camera_lens`
- `evidence_tag`
- `passport`
- `toy_train`

Rules:
- resolving a case still discovers its normal case collectible;
- a mapped bonus collectible is awarded only when that case is graded `PERFECT`;
- bonus discovery uses a distinct `BONUS FIND` toast;
- all 15 IDs use the existing persistent DataStore payload;
- Collection carousel remains horizontal/mobile-first;
- physical showcase expanded from 10 to 15 slots / three rows;
- no trading.

Authority:
- runtime collection registry: `src/shared/CollectionRegistry.lua`;
- governance mirror: `registry/COLLECTION_REGISTRY.json`;
- bonus mappings: `src/shared/CaseRegistry.lua`;
- bonus award logic: `src/server/Main.server.lua`;
- preview geometry: `src/shared/CollectionPreviewFactory.lua`;
- 15-slot room showcase: `src/client/CollectionShowcase.client.lua`.

## Latest publish receipt
Run: `33051700577`
Source commit: `7f97d7a7dd34fb3c71081779796750938ff28cfa`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `22`
RBXL bytes: `41458`
RBXL SHA256: `1ee0e796bf7eab81cddeee00492077931ebb137e4bdddbc23bd62e7da591db45`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v22 BUILD/DEPLOY VERIFIED.**
M2-D bonus collection runtime visuals/gameplay require mobile acceptance before expanding further.

## Next gate
**M2-D-RUNTIME**
1. existing saved Credits + prior INDEX discoveries restore correctly;
2. INDEX total displays `/15` without wiping existing discoveries;
3. Collection carousel scrolls through all 15 cards;
4. new locked silhouettes render for lens/tag/passport/train;
5. complete one mapped case with the correct PERFECT decision;
6. corresponding `BONUS FIND` appears and INDEX increments by one additional unique item;
7. bonus item persists after leave/rejoin;
8. 15-slot physical showcase does not block movement and shows discovered bonus models correctly;
9. existing case loop remains stable.

After M2-D runtime acceptance, decide whether to take one more controlled collection slice or begin **M3 — FLIGHT 000**. Trading remains locked.
