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
**ACCEPTED FOR CONTINUATION.**

Runtime proven on mobile:
- player joins and can move;
- case arrives on conveyor;
- enforced sequence is `SCAN → CHECK TAG → OPEN → DECIDE`;
- claimant data appears;
- RETURN / STORE / QUARANTINE / SECURITY work;
- grading and rewards work;
- Credits amount displays live in the top HUD;
- next case starts automatically;
- compact case card + on-demand CASE FILE popup work on mobile.

## M0.1 — FEEL PASS
**ACCEPTED FOR CONTINUATION INTO M1.**

Implemented and published in Roblox v11:
- conveyor travel 2.8s;
- case advance 3.2s;
- interaction distance 7 studs;
- prompt hold 0.08s;
- short claimant staging delay;
- lightweight built-in audio feedback;
- mobile movement/camera safety retained;
- Credits display retained.

## Active milestone
**M1 — PREMIUM ROOM**

Visual authority:
- `brain/M1_VISUAL_LOCK.md`
- premium stylized airport Lost & Found back-office;
- charcoal / graphite architecture;
- brushed dark metal equipment;
- warm amber service/task light;
- cyan scanner/evidence accents;
- restrained red quarantine/security accents;
- operational workplace first, mystery second;
- no neon arcade floor look.

## M1-A — PREMIUM ROOM SHELL + EQUIPMENT
Implemented and published in Roblox v12:
- premium room shell with wall panels, trims, floor guides, and hidden spawn pad;
- layered service counter with wood top, amber task lighting, and monitor;
- layered conveyor with belt slats and restrained under-lighting;
- scanner arch with cyan inner scan lines and evidence display;
- upgraded inspection desk, tag reader, open tray, and evidence screen;
- claimant waiting zone separated from staff work area;
- raised operational decision consoles;
- storage racks / stored-property dressing;
- quarantine access with restricted frame and red warning lamp;
- improved procedure board and industrial ceiling lighting;
- core gameplay refs and sequence preserved.

## M1-B — FIVE BASE ITEM MODELS
Implemented in source and published in Roblox v13:
1. `hardcase_suitcase` — ribbed hard-shell luggage, wheels, telescoping handle;
2. `vintage_suitcase` — wood/leather body, bands, latches, corner protectors;
3. `backpack` — fabric body, front pocket, straps, zip detail;
4. `cardboard_box` — parcel body, tape bands, shipping label plate, corner wear;
5. `teddy_bear` — articulated stylized soft-toy silhouette with head, ears, muzzle, limbs, eyes.

Implementation authority:
- `src/server/ItemFactory.lua` is the M1 base item factory;
- active case spawning now routes through `ItemFactory.Create`;
- no external asset dependency is required for these five models;
- all child parts are welded to one anchored primary part so conveyor tween behavior is preserved;
- claim-tag visibility is preserved on every model.

Case distribution now exercises all five models during the existing 10-case loop while preserving Season 1 pillars:
- Ownerless Suitcase remains vintage suitcase;
- Flight 000 remains hardcase suitcase;
- The Lost Child remains small vintage case;
- normal/supporting cases introduce backpack, cardboard parcel, and teddy bear variants.

Asset authority:
- `registry/ITEM_REGISTRY.json` status is `M1_BASE_MODELS`;
- `registry/ASSET_REGISTRY.json` records all five as `SOURCE_IMPLEMENTED_PENDING_RUNTIME_QC`;
- `baseItemMeshesImplemented = 5`;
- `baseItemMeshesApproved = 0` until mobile visual acceptance;
- M1 is NOT marked complete until runtime visual QC passes.

## M1-B publish receipt
Run: `33006870278`
Source commit: `0a7f93bbade35045dedfeea54a42c5e7fca57140`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `13`
RBXL bytes: `27610`
RBXL SHA256: `6141422425f867162c38d94d22b2c0972ea7e38ea6b15038b7976a754a490729`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v13 BUILD/DEPLOY VERIFIED.**
M1-B item visual acceptance still requires mobile runtime inspection.

## Next gate
**M1-RUNTIME FINAL:** verify on mobile:
1. movement/camera remain normal;
2. premium room modules still read clearly and do not block gameplay;
3. hardcase and vintage suitcase look distinct;
4. backpack reads immediately as a backpack, not a box;
5. cardboard parcel reads immediately as a parcel;
6. teddy bear reads immediately as a toy and is not visually broken during conveyor movement;
7. tags remain visible enough for the interaction fantasy;
8. SCAN → TAG → OPEN → DECIDE still completes on each model;
9. no welded detail lags behind the item during conveyor tween.

If M1-RUNTIME FINAL passes, set all five base item models to runtime-approved, mark M1 complete, then proceed to **M2 — COLLECTION FOUNDATION**. Do not begin M2 before this gate passes.
