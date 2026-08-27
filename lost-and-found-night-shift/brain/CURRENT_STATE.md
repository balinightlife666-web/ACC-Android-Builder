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

Approved base geometries:
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

### M2-B — CONTROLLED VARIANTS + PHYSICAL SHOWCASE
**COMPLETE / ACCEPTED.**

Collection expanded to 10 controlled variants:
1. Blue Transit Hardcase — COMMON
2. Crimson Travel Backpack — UNCOMMON
3. Cream Memory Bear — RARE
4. Brown Heritage Case — UNCOMMON
5. Black Security Hardcase — RARE
6. Ownerless Vintage Case — ANOMALY
7. Flight 000 Hardcase — SECRET
8. Unstable Sealed Parcel — ANOMALY
9. Green Identity Backpack — EPIC
10. Milo's Small Case — SECRET

Authority:
- `src/shared/CollectionRegistry.lua`;
- `registry/COLLECTION_REGISTRY.json`;
- per-case stable `collectionId`;
- per-player client-side physical collection showcase remains active.

### M2-C — PERSISTENCE / DATASTORE
**COMPLETE / RUNTIME-ACCEPTED.**

Source:
- `src/server/PlayerDataStore.lua`
- `src/server/Main.server.lua`

Persistent payload v1:
- Credits;
- XP;
- discovered collection IDs.

Runtime acceptance confirmed on mobile after leave/rejoin:
- Credits restore correctly;
- Collection/INDEX restore correctly;
- physical showcase restoration is accepted for continuation;
- case loop and movement remain stable.

Safety rules remain locked:
- datastore name: `LostAndFound_PlayerData_v1`;
- load protected by `pcall`;
- failed load falls back to session-only and must not overwrite prior persistent data;
- only successfully-loaded profiles may save;
- autosave every 60 seconds when dirty;
- forced save on `PlayerRemoving` and `BindToClose`.

### Inspection control readability patch
`TAG READER` and `OPEN / INSPECT` are tilted upright toward the approaching player while remaining side-by-side and floor-accessible. Source: `src/server/InteractionLayout.server.lua`.

## Latest publish receipt
Run: `33049729712`
Source commit: `2194829ef52f19a883d4ff5603b612c8b96b1494`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `21`
RBXL bytes: `39649`
RBXL SHA256: `6286b58942177e301a98708647064f0357525d93d635f080fd33035cbeeeb800`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v21 BUILD/DEPLOY VERIFIED + M2-C RUNTIME ACCEPTED.**

## Next gate
**M2-D — CONTROLLED COLLECTION EXPANSION.**

Goal:
- expand the collection in staged batches rather than one uncontrolled jump;
- move from 10 toward the roadmap target of 30–40 approved collectible items;
- prioritize new meaningful item shapes plus controlled variants, not color swaps alone;
- keep mobile Collection UI readable and physical showcase scalable;
- preserve rarity discipline and mystery-item scarcity;
- do not unlock trading yet.

Recommended next slice: add 5 new collectible items with at least 2 new base geometries, then runtime-QC before expanding further.

After the collection foundation is materially stronger, proceed to **M3 — FLIGHT 000**.
