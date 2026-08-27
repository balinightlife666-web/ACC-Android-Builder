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

Movement/camera safety, compact CASE FILE UI, Credits display, and four operational decisions remain active.

## M0.1 — FEEL PASS
**COMPLETE / ACCEPTED.**

Locked feel values:
- conveyor travel: 2.8s;
- case advance delay: 3.2s;
- interaction distance: 7 studs baseline;
- prompt hold: 0.08s;
- claimant arrival delay: 0.45s;
- lightweight feedback audio retained.

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
Collection UI/runtime has been accepted on mobile.

Accepted behavior:
- collection is presented as 3D ViewportFrame cards, not text-only rows;
- locked entries show dark silhouettes + `? / LOCKED`;
- discovered entries reveal model + name + rarity;
- landscape mobile popup uses a compact horizontal carousel;
- CASE HUD / Credits / INDEX hide temporarily while Collection is open and restore on close;
- no generated images are used for the collection visuals.

## M2-B — CONTROLLED VARIANTS + PHYSICAL SHOWCASE
**IMPLEMENTED / LIVE — RUNTIME ACCEPTANCE PENDING.**

Collection expanded from 5 base types to **10 controlled collectible variants**, each reusing one of the five M1-approved base geometries:
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
- runtime registry: `src/shared/CollectionRegistry.lua`;
- governance mirror: `registry/COLLECTION_REGISTRY.json`;
- each existing case now has a stable `collectionId` while preserving its base item geometry;
- discovery tracks `collectionId`, not merely the five base geometry IDs.

### Physical showcase
Source: `src/client/CollectionShowcase.client.lua`

Behavior:
- client-only/per-player collection wall on the left side of the room;
- 10 display slots arranged in two rows;
- undiscovered slots stay dark with `?`;
- discovered entries spawn a small 3D model on the matching shelf slot;
- one player's discoveries do not reveal another player's collection;
- showcase is non-colliding and does not alter core case gameplay.

### M2-B limits
- collection is still **SESSION-ONLY**;
- no DataStore persistence yet;
- no trading;
- no Evidence Tokens;
- 10 variants are a controlled expansion slice, not the final 30–40 item target.

## Latest publish receipt
Run: `33045703308`
Source commit: `ce1afa3feb40b0a69acfe4a3af56f3eee3b036f0`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `19`
RBXL bytes: `37766`
RBXL SHA256: `69f664469f301cf8ea3e776884a637baefc8f0dc81330fbfd468e42a044a59ca`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v19 BUILD/DEPLOY VERIFIED.**
M2-B collection variants + physical showcase still require mobile runtime acceptance.

## Next gate
**M2-B-RUNTIME:** verify on mobile:
1. INDEX reports `0/10` on a fresh session;
2. first resolved case discovers the correct variant and increments to `1/10`;
3. Collection carousel displays 10 cards without layout regression;
4. locked cards remain hidden/silhouetted;
5. physical showcase appears on the left side of the room;
6. discovered item appears on its physical showcase slot;
7. showcase does not block walking, scanner, claimant, decision consoles, or camera;
8. existing SCAN → TAG → OPEN → DECIDE loop remains stable.

If M2-B-RUNTIME passes, proceed to **M2-C — PERSISTENCE / DATASTORE** so Credits + Collection survive rejoin. Trading remains locked until later economy review.
