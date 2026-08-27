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
- Collection remains session-only; no trading.

## 2026-08-27 — M2-B controlled variants + showcase
- Expanded collection from 5 base geometry entries to 10 case-specific collectible variants.
- Preserved reuse of the five approved M1 base geometries.
- Added stable `collectionId` mapping to all 10 existing cases.
- Discovery now tracks collectible variant IDs rather than only base geometry IDs.
- Added `registry/COLLECTION_REGISTRY.json` as governance mirror.
- Added per-player physical collection showcase with 10 non-colliding shelf slots.
- Discovered variants appear as 3D models on the showcase; locked slots remain hidden with `?`.
- Published as Roblox v19; M2-B runtime acceptance pending.
- Persistence/DataStore and trading remain locked.
