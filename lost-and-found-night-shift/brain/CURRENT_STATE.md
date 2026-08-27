# LOST & FOUND: NIGHT SHIFT — CURRENT STATE

Updated: 2026-08-28

## Identity
- Universe ID: `10745354451`
- Place ID: `93699016600671`
- Genre: Simulation
- Subgenre: Mystery Inspection Simulator with Collection & Supernatural Cases

## Infrastructure
- Repo/build home: `balinightlife666-web/ACC-Android-Builder/lost-and-found-night-shift`
- Publish workflow is trigger-file/manual only.
- Deployment authority is `deploy-status/lost-and-found-m0.json`; never claim LIVE from source changes alone.

## Accepted baseline
- M0 — FIRST SUITCASE — COMPLETE / ACCEPTED.
- M0.1 FEEL PASS — COMPLETE / ACCEPTED.
- M1 PREMIUM ROOM — COMPLETE / RUNTIME-APPROVED.
- M2-A through M2-E Collection Foundation — COMPLETE / RUNTIME-ACCEPTED.
- M3-A Flight 000 — COMPLETE / USER-ACCEPTED on v27.
- M3-B Connected Mystery Chain — IMPLEMENTED / LIVE.
- M4-A serialized item foundation — COMPLETE / RUNTIME-ACCEPTED on v31.
- M4-B secure same-server serialized trading v1 — LIVE v32; Phase 1 mobile UI accepted; two-account ownership/rejoin QC deferred.
- M4-C anti-alt/economy telemetry — LIVE_PUBLISHED v33 in build/deploy terms.

## Core canon
Season 1 connected pillars remain:
1. Flight 000 — QUARANTINE; final explanation CANON UNKNOWN.
2. Ownerless Suitcase — QUARANTINE; may reappear.
3. The Lost Child — missing/archive year 2001; SECURITY/protective escalation; final supernatural explanation CANON UNKNOWN.

Core job loop remains:
`ITEM ARRIVES → SCAN → CHECK TAG → OPEN / INSPECT → DECIDE → RESULT → REWARD → NEXT ITEM`

Decisions remain:
`RETURN / STORE / QUARANTINE / SECURITY`

## M4 — SOCIAL / ECONOMY HARDENING
Authorities:
- `brain/M4_UNIQUE_ITEM_TRADING_LOCK.md` v1.1
- `brain/M4C_ECONOMY_HARDENING_LOCK.md` v1.0
- `brain/M4D_PERSONAL_STATION_LOCK.md` v1.1

### M4-A — serialized inventory
Accepted model:
- Collection Index = historical discovery/encounter prestige;
- Inventory Instance = currently owned transferable item;
- immutable `instanceId` = ownership key;
- immutable serial = collector identity;
- serial minting is server-authoritative with global counters.

Accepted runtime evidence on v31:
`SNP-S1-000001`, `ARP-S1-000001`, `UMR-S1-000001` survived rejoin unchanged.

### M4-B — secure player trading v1
Current scope:
- same-server only;
- one serialized item ↔ one serialized item;
- no trade currency;
- exact ownership validation by `instanceId`;
- request / accept / decline;
- server item locks;
- first confirmation;
- 3-second review lock;
- final confirmation;
- durable trade journal + recovery markers + rollback path.

Status:
- Phase 1 mobile UI smoke PASS on v32.
- True two-account ownership swap, `NOT OWNED`, anti-duplicate and both-account rejoin remain deferred until a second tester is available.
- Do NOT describe those deferred checks as runtime-proven.

### M4-C — economy hardening
LIVE_PUBLISHED v33 build/deploy verified.

Credits role:
- non-transferable soft currency;
- intended for station/customization/display/convenience sinks;
- cannot directly buy SECRET/ANOMALY instances;
- cannot replace serialized item-for-item trading.

Trade eligibility:
- persistence + serialized inventory ready;
- Roblox account age >= 7 days;
- >= 5 completed cases OR >= 50 XP;
- at least one tradeable serialized item.

Telemetry tracks cases, PERFECT outcomes, Credits issued, serial mints and trade events.

### M4-D — PERSONAL STATION / MULTIPLAYER JOB ISOLATION
**IMPLEMENTED IN SOURCE — PUBLISH + SOLO RUNTIME QC PENDING.**

Goal:
- prevent job/reward contention when multiple players share one server;
- preserve one shared social room for flex and same-server trading.

Initial design target:
- 8 active job players/server;
- 8 physical station slots A-H;
- physical station letter is temporary server placement, not permanent account identity.

Source implementation:
- `PersonalStationWorld.lua` builds shared M4-D room and Station A-H;
- `PersonalShiftRuntime.lua` replaces global `activeCase` with isolated per-player/per-station runtime state;
- server validates station ownership for every SCAN / TAG / OPEN / DECIDE action;
- player receives `SHIFT ASSIGNED — STATION X`, compact persistent station HUD and temporary station highlight;
- character stages at assigned station on join/respawn;
- leave cleans active station objects and returns slot to VACANT;
- if more than 8 players enter before Creator MaxPlayers is configured to 8, extra player receives no job station rather than falling back to a shared job.

Personal case distribution:
1. fresh progression: fixed cases 001 → 002 → 003;
2. after onboarding: independent weighted random per-player stream;
3. server avoids duplicate active cases when another eligible case is available;
4. mystery eligibility is personal progression;
5. implementation thresholds: Ownerless >=5 completed, Flight 000 >=7, Changing Weight >=8, Double Identity >=9, Lost Child >=10.

Personal collectible economy:
`PERSONAL CASE → PERFECT ELIGIBILITY → SERVER-SIDE ROLL → GLOBAL SERIAL MINT → ONLY THAT PLAYER RECEIVES INSTANCE`

Initial ownership roll values:
- COMMON 100%
- UNCOMMON 85%
- RARE 65%
- EPIC 40%
- ANOMALY 16%
- SECRET 8%

Rules:
- roll is per-player/per-station, not one shared server prize;
- normal SECRET/ANOMALY is not limited to one drop per server;
- Index can remain historically discovered even if the player owns zero copies;
- Index discovery does not create a free replacement;
- any new copy requires a valid future roll/mint or trade;
- seasonal limited items may later use global mint caps.

Persistent Personal Station Profile foundation:
- DataStore remains `LostAndFound_PlayerData_v1`;
- payload version becomes 6;
- persisted fields currently include `equippedSkin`, `ownedSkins`, `title`;
- default is `STANDARD_OPS` + `NIGHT SHIFT OPERATOR`.

Station skin registry source:
- STANDARD_OPS — FREE
- INDUSTRIAL_SHIFT — Credits target 8,000
- RETRO_AIRPORT — Credits target 18,000
- BLACK_OPS — Credits target 35,000
- LUXURY_EXECUTIVE — ROBUX, exact product/price TBD
- HALLOWEEN_2026 — EVENT
- CHRISTMAS_2026 — EVENT

Important: registry/profile loading exists, but Station Shop purchase/equip UX is NOT live yet.
Robux cosmetics must never improve collectible chance, reward, farming output, or trading advantage.

Social flex:
- each occupied station now has a replicated public showcase;
- automatically displays up to 3 currently owned high-rarity serialized items;
- nearby players can see serial labels;
- other players cannot remove or mutate the showcase items;
- old local-only wall showcase is retired.

## M5 / live-service seasonal priority
Authority: `brain/SEASONAL_EVENTS_LOCK.md`.

2026 priorities:
- Halloween 2026 around 31 October;
- Christmas 2026 around 25 December.

Seasonal gameplay visuals remain Roblox 3D/procedural/in-engine by default. No AI-generated image assets unless explicitly requested.

## Latest VERIFIED LIVE publish receipt
Run: `33096058726`
Source commit: `39ba78108fca79b6cb2b5ca04559a3ce8c5fa23a`
Rojo: `7.7.0`
Workflow conclusion: SUCCESS
Roblox status: LIVE_PUBLISHED
Roblox version: `33`
RBXL bytes: `74069`
RBXL SHA256: `a4ab3172235338033918204922ef5f0bfb343567fc866858b14858da4f141f74`
Receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**Current verified Roblox LIVE remains v33 until a new deploy receipt matches the exact M4-D trigger commit.**
M4-D source must NOT be called LIVE yet.

## Active next gate — M4-D publish + solo runtime QC
1. publish exact M4-D source and verify receipt sourceCommit;
2. join/rejoin with established save and confirm Credits / XP / INDEX / serials remain intact;
3. confirm `SHIFT ASSIGNED — STATION A` when alone and station indicator appears;
4. confirm character is placed at Station A and station visibly carries player identity;
5. run one complete personal SCAN → TAG → OPEN → DECIDE case;
6. confirm reward remains correct and next personal case starts;
7. confirm public showcase renders owned serialized items;
8. confirm old giant local collection showcase is gone;
9. confirm no obvious mobile HUD overlap or movement regression.

Deferred when a second tester is available:
- Station A/B assignment isolation;
- independent case streams;
- cross-station prompt/reward protection;
- simultaneous progression isolation;
- avoid-duplicate case behavior;
- same-server trade + swapped serial persistence after both players rejoin.

After M4-D solo pass:
- Station Shop v1 using Credits for earnable station skins;
- premium Robux cosmetic integration only after intentional product IDs/prices exist;
- manual featured showcase selection;
- collectible 3D visual-quality pass;
- performance telemetry before considering more than 8 active station slots.
