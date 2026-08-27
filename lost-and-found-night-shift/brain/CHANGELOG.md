# LOST & FOUND: NIGHT SHIFT — CHANGELOG

## 2026-08-27 — Foundation v1.0
- Locked title: LOST & FOUND: NIGHT SHIFT.
- Locked primary genre: Simulation / Job Simulator.
- Locked positioning: Mystery Inspection Simulator with Collection & Supernatural Cases.
- Locked M0 milestone: FIRST SUITCASE.
- Locked four decisions: RETURN / STORE / QUARANTINE / SECURITY.
- Locked Season 1 mystery pillars: Flight 000 / Lost Child / Ownerless Suitcase.
- Added anti-drift Project Brain hierarchy.
- Added initial 10-case test registry.
- Added procedural playable M0 source with no external asset dependency.

## 2026-08-27 — M0 / M0.1 accepted
- Proved complete mobile case loop.
- Enforced SCAN → TAG → OPEN → DECIDE.
- Added compact CASE FILE HUD, Credits display, movement safety, lighting/readability fixes, and feel timing/audio pass.

## 2026-08-27 — M1 complete
- Locked M1 premium visual language.
- Upgraded room shell, counter, conveyor, scanner, inspection station, decision consoles, storage, quarantine access, and lighting.
- Implemented and runtime-approved five base item types: hardcase suitcase, vintage suitcase, backpack, cardboard parcel, teddy bear.
- Added floor-accessible TAG-left / OPEN-right interaction rail.

## 2026-08-27 — M2-A collection foundation accepted
- Added CollectionRegistry with rarity/discovery foundation.
- Added server-authoritative session discovery tracking.
- Added top-right INDEX mobile control and first-discovery toast.
- Replaced text-only index with 3D ViewportFrame collection cards.
- Added locked silhouettes and horizontal mobile collection carousel.
- Accepted front-facing 3D collection preview orientation on mobile.

## 2026-08-27 — M2-B controlled variants + showcase accepted
- Expanded collection from 5 base geometry entries to 10 case-specific collectible variants.
- Preserved reuse of the five approved M1 base geometries.
- Added stable `collectionId` mapping to all 10 existing cases.
- Discovery now tracks collectible variant IDs rather than only base geometry IDs.
- Added `registry/COLLECTION_REGISTRY.json` as governance mirror.
- Added per-player physical collection showcase with 10 non-colliding shelf slots.
- Discovered variants appear as 3D models on the showcase; locked slots remain hidden with `?`.

## 2026-08-27 — M2-C persistence accepted
- Added persistent player data through `LostAndFound_PlayerData_v1`.
- Credits, XP, and discovered collection IDs survive leave/rejoin.
- Added protected load/save behavior with session-only fallback when DataStore load fails.
- Added 60-second dirty autosave plus `PlayerRemoving` / `BindToClose` saves.
- Confirmed persistence runtime behavior on mobile.
- Roblox v21 is the accepted M2-C runtime baseline.
- Trading remains locked.

## 2026-08-27 — M2-D controlled expansion accepted
- Expanded persistent INDEX from 10 to 15 collectible entries.
- Added five PERFECT-only bonus finds tied to canon-consistent case evidence: Silver Camera Lens, Ownerless Tag 000-17284, Flight 000 Boarding Tag, Duplicate Passport, and Milo's Toy Train.
- Added four new 3D collectible geometries: camera lens, evidence tag, passport, and toy train.
- Added distinct BONUS FIND discovery feedback.
- Expanded physical showcase from 10 to 15 slots across three rows.
- Mobile runtime screenshots confirmed bonus item rendering, rarity display, locked silhouettes, and carousel stability.
- Corrected TAG / OPEN visual panels in v23 so labels stand vertically with horizontal readable text rather than tilted SurfaceGui text.

## 2026-08-27 — M2-E 20-item collection live candidate
- Expanded persistent INDEX from 15 to 20 collectible entries.
- All 10 cases now have exactly one PERFECT-only bonus collectible.
- Added Maya's Power Adapter, Daniel's Formal Shoe, Sofia's Stitched Patch, Ari's Red Paperback, and Unstable Mass Readout.
- Added five new 3D collectible geometries: power adapter, formal shoe, name patch, paperback, and mass readout.
- Long collection names now wrap to two lines instead of truncating with ellipsis.
- Expanded physical showcase from 15 to 20 slots across four rows.
- Existing DataStore payload remains compatible; old saves remain valid and new discoveries persist in the same discovered-ID list.
- Published as Roblox v24; M2-E mobile runtime acceptance pending.
- Trading remains locked.
