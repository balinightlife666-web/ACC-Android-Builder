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

### M2-E — CONTROLLED COLLECTION EXPANSION
**IMPLEMENTED / LIVE v24 — RUNTIME QC PENDING.**

Collection count is now **20**. Every one of the 10 cases now has exactly one PERFECT-only bonus collectible.

Five new M2-E bonus finds:
16. Maya's Power Adapter — UNCOMMON — `LF-M0-001`
17. Daniel's Formal Shoe — RARE — `LF-M0-002`
18. Sofia's Stitched Patch — RARE — `LF-M0-003`
19. Ari's Red Paperback — UNCOMMON — `LF-M0-004`
20. Unstable Mass Readout — ANOMALY — `LF-M0-008`

New M2-E collectible geometries:
- `power_adapter`
- `formal_shoe`
- `name_patch`
- `paperback`
- `mass_readout`

M2-E rules:
- resolving any case still discovers its normal case collectible;
- a PERFECT result also discovers that case's mapped bonus collectible;
- all 20 IDs persist through the existing DataStore payload;
- long collection names wrap to two lines instead of truncating with ellipsis;
- physical showcase expanded to 20 non-colliding slots / four rows;
- no trading.

Authority:
- runtime collection registry: `src/shared/CollectionRegistry.lua`;
- governance mirror: `registry/COLLECTION_REGISTRY.json`;
- bonus mappings: `src/shared/CaseRegistry.lua`;
- bonus award logic: `src/server/Main.server.lua`;
- preview geometry: `src/shared/CollectionPreviewFactory.lua`;
- 20-slot room showcase: `src/client/CollectionShowcase.client.lua`;
- mobile collection UI: `src/client/Collection.client.lua`.

## Latest publish receipt
Run: `33058949238`
Source commit: `dad3f6ef90620e4d711607d955022d56c270cba1`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `24`
RBXL bytes: `43805`
RBXL SHA256: `5f7f7961d1d38bc675754b57ce727b2d8ceac3ce6d48e66bee74120f13ea2809`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v24 BUILD/DEPLOY VERIFIED.**
M2-E collection runtime visuals require mobile acceptance before locking the slice complete.

## Next gate
**M2-E-RUNTIME**
1. existing Credits + prior INDEX discoveries restore without regression;
2. INDEX total displays `/20`;
3. long names render on two lines without clipping rarity labels;
4. five new locked silhouettes render without broken geometry;
5. complete one of cases 1/2/3/4/8 with the correct PERFECT decision;
6. mapped new BONUS FIND appears and INDEX increments;
7. new discovery persists after leave/rejoin;
8. 20-slot physical showcase remains inside the room and does not block movement/camera;
9. existing case loop, Collection carousel, TAG / OPEN, and decision flow remain stable.

After M2-E runtime acceptance, evaluate moving directly into **M3 — FLIGHT 000** rather than expanding collection indefinitely. Trading remains locked.
