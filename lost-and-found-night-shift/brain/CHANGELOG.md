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

## 2026-08-27 — M2-E 20-item collection accepted
- Expanded persistent INDEX from 15 to 20 collectible entries.
- All 10 cases now have exactly one PERFECT-only bonus collectible.
- Added Maya's Power Adapter, Daniel's Formal Shoe, Sofia's Stitched Patch, Ari's Red Paperback, and Unstable Mass Readout.
- Added five new 3D collectible geometries: power adapter, formal shoe, name patch, paperback, and mass readout.
- Long collection names wrap to two lines instead of truncating with ellipsis.
- Expanded physical showcase from 15 to 20 slots across four rows.
- Existing DataStore payload remains compatible; old saves remain valid and new discoveries persist in the same discovered-ID list.
- Mobile visual QC and leave/rejoin persistence were accepted on Roblox v24.
- Trading remains locked.

## 2026-08-27 — M3-A Flight 000 accepted
- Added `brain/M3_FLIGHT_000_LOCK.md` as M3 authority.
- Flight 000 preserves Jonas Vale, passenger FOUND, flight NOT FOUND, tag F0-00013, and correct action QUARANTINE.
- Exact final explanation remains CANON UNKNOWN.
- PERFECT Flight 000 raises a server-wide terminal incident and briefly extends case transition timing.
- Added mobile Archive control and operational incident entry.
- v26 exposed Archive visibility clearly; v27 fixed the missing local incident-banner trigger.
- Arda explicitly accepted M3-A after the v27 hotfix without requiring another full Flight 000 replay.
- M3-A status: USER-ACCEPTED.

## 2026-08-27 — M3-B connected mystery chain
- Added `brain/M3B_CONNECTED_CHAIN_LOCK.md`.
- Connected the existing Season 1 pillars into three operational Archive entries: Flight 000, Ownerless Suitcase, and The Lost Child.
- Archive progression is reconstructed from existing persistent PERFECT bonus discoveries rather than adding a second DataStore.
- Existing saves therefore do not need to replay old cases to restore valid archive progress.
- `ARCHIVE x/3` shows persistent chain progress.
- Archive popup shows all three slots as locked/unlocked mobile cards.
- Lost Child remains SECURITY/protective escalation and the 2001 date remains locked.
- Flight 000 retains the stronger terminal-incident presentation.
- Final supernatural explanation remains unknown.
- v29 standardized Credits / Index / Archive / Case File utility controls.
- v30 fixed Collection-open visibility so Archive is hidden while the Collection popup is active.

## 2026-08-27 — M4-A unique serialized item foundation accepted
- Added `brain/M4_UNIQUE_ITEM_TRADING_LOCK.md` as active M4 authority.
- Split progression conceptually into permanent Collection Index and owned Inventory Instances.
- Added stable Season 1 serial prefixes for all 20 collectible types.
- Added `SerialMintService.lua` with server-authoritative atomic global DataStore counters per collectible type.
- Display serial format is `<PREFIX>-S1-<GLOBAL MINT NUMBER>`, e.g. `CMB-S1-000001`.
- Every serialized instance also receives an immutable GUID-based internal `instanceId`.
- Extended existing `LostAndFound_PlayerData_v1` payload compatibly with optional serialized `inventory` data; persisted payload version is now 2 while the DataStore name is unchanged.
- Existing Credits / XP / discovered collection IDs remain backward compatible.
- Old discovered items without serialized inventory are backfilled after a successful profile load; replay is not required.
- Collection cards show a compact serial line below rarity.
- Runtime evidence on v31 confirmed serials survived rejoin unchanged: `SNP-S1-000001`, `ARP-S1-000001`, and `UMR-S1-000001` matched between first login and rejoin screenshots.
- M4-A status: COMPLETE / RUNTIME-ACCEPTED.
- Next gate: M4-B Secure Player Trading with server-side ownership validation, item locking, two-sided confirmation, atomic transfer, trade history/provenance, disconnect recovery, and anti-double-spend protection.
