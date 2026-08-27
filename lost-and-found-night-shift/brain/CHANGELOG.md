# LOST & FOUND: NIGHT SHIFT — CHANGELOG

## 2026-08-27 — Foundation v1.0
- Locked title: LOST & FOUND: NIGHT SHIFT.
- Locked primary genre: Simulation / Job Simulator.
- Locked positioning: Mystery Inspection Simulator with Collection & Supernatural Cases.
- Locked M0 milestone: FIRST SUITCASE.
- Locked four decisions: RETURN / STORE / QUARANTINE / SECURITY.
- Locked Season 1 mystery pillars: Flight 000 / Lost Child / Ownerless Suitcase.
- Added anti-drift Project Brain hierarchy and initial 10-case registry.

## 2026-08-27 — M0 / M0.1 accepted
- Proved complete mobile case loop SCAN → TAG → OPEN → DECIDE.
- Added compact CASE FILE HUD, Credits display, movement safety, lighting/readability fixes and feel pass.

## 2026-08-27 — M1 complete
- Locked M1 premium visual language.
- Upgraded room, counter, conveyor, scanner, inspection station, decisions, storage and quarantine access.
- Runtime-approved five base item geometries and floor-accessible TAG / OPEN flow.

## 2026-08-27 — M2 collection foundation accepted
- Added persistent Collection Index, 3D Viewport collection cards and physical showcase.
- Expanded from 10 to 15 to 20 collectible entries.
- Added PERFECT-only bonus evidence collectibles for all 10 cases.
- Persisted Credits / XP / discovered IDs through `LostAndFound_PlayerData_v1`.
- M2-E 20-item collection accepted on Roblox v24.

## 2026-08-27 — M3-A Flight 000 accepted
- Added `brain/M3_FLIGHT_000_LOCK.md`.
- Preserved Jonas Vale, passenger FOUND, flight NOT FOUND, tag F0-00013 and QUARANTINE.
- Final explanation remains CANON UNKNOWN.
- v27 incident-banner hotfix user-accepted.

## 2026-08-27 — M3-B connected mystery chain
- Added `brain/M3B_CONNECTED_CHAIN_LOCK.md`.
- Connected Flight 000 / Ownerless Suitcase / The Lost Child through Archive entries 000-A/B/C.
- Lost Child remains 2001 + SECURITY/protective escalation.
- Final supernatural explanation remains unknown.
- v30 fixed Collection/Archive UI overlap.

## 2026-08-27 — M4-A unique serialized item foundation accepted
- Added `brain/M4_UNIQUE_ITEM_TRADING_LOCK.md`.
- Split permanent Collection Index from actual owned Inventory Instances.
- Added server-authoritative global serial mint counters and immutable GUID `instanceId`.
- Runtime v31 rejoin evidence confirmed serial persistence for `SNP-S1-000001`, `ARP-S1-000001`, `UMR-S1-000001`.

## 2026-08-27 — M4-B secure serialized trading v1
- Added same-server one-item-for-one-item trade request/accept flow.
- Added exact instance ownership validation, item locks, first confirm, 3-second review lock and final confirm.
- Added durable trade journal/recovery markers, rollback path and provenance persistence.
- Prevented legacy migration from reminting a traded-away final copy.
- v32 published from exact source `4efee7af76775f1142d2b319c74bd55b6da83f07`.
- Phase 1 mobile trade UI smoke passed.

## 2026-08-28 — M4-B Phase 2 deferred
- True two-account ownership swap/rejoin cannot yet be runtime-QC'd with one available device/tester.
- Keep cross-player ownership, `NOT OWNED`, anti-duplicate and both-account rejoin checks as deferred regression gates.

## 2026-08-28 — M4-C economy hardening LIVE v33
- Added `brain/M4C_ECONOMY_HARDENING_LOCK.md`.
- Locked Credits as non-transferable soft currency for cosmetic/display/convenience sinks.
- Added persistent economy telemetry/stat foundation; player payload version advanced to 5 while DataStore name remained unchanged.
- Added trade account-age/progression gate and server-side trade telemetry.
- Exact source `39ba78108fca79b6cb2b5ca04559a3ce8c5fa23a` published as Roblox v33 via run `33096058726`.

## 2026-08-28 — M4-D personal station / multiplayer job isolation LIVE v34
- Upgraded `brain/M4D_PERSONAL_STATION_LOCK.md` to v1.1.
- Replaced the single shared job runtime entrypoint with `PersonalShiftRuntime.lua`.
- Added `PersonalStationWorld.lua` with 8 physical station slots A-H in one shared social room.
- Each occupied station owns its case item, claimant, SCAN/TAG/OPEN/DECIDE progress, reward and case advancement.
- Server validates station ownership for every job interaction; another player cannot claim another station's job/reward.
- Added fixed 001→002→003 onboarding followed by personal weighted case selection and personal mystery progression gates.
- Added active-case avoidance so different cases are used across stations when practical.
- Added personal collectible ownership rolls: COMMON 100%, UNCOMMON 85%, RARE 65%, EPIC 40%, ANOMALY 16%, SECRET 8%; these remain balance values, not immutable canon.
- Collection Index remains historical discovery while actual owned copies require a valid server-side drop/mint or trade.
- Added persistent station profile foundation to `LostAndFound_PlayerData_v1`; payload version advanced to 6 while DataStore name stayed unchanged.
- Added Station Skin Registry with FREE / CREDITS / ROBUX / EVENT acquisition classes; Station Shop purchase/equip flow is not live yet.
- Added replicated three-item public serialized showcase per occupied station and retired the old local-only wall showcase.
- Added mobile station assignment HUD, short station highlight and local filtering of other station prompts.
- Consolidated M4-C economy tracking into personal runtime to avoid duplicate/cross-station prompt telemetry.
- Extended publish Static QC for M4-D files and ownership markers.
- Exact trigger/source `950eeb1e7b4c6119292340f4e630b8fa3e589461` published successfully as Roblox v34.
- Deploy receipt: run `33100322285`, Rojo `7.7.0`, bytes `83918`, SHA256 `b70b00eaeab8cdfc6cb72b1ea881625ddc75995d2903c6ed3cae903436692612`.
- M4-D status: LIVE_PUBLISHED / BUILD-DEPLOY VERIFIED / SOLO RUNTIME QC PENDING.
