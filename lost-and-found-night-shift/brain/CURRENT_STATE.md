# LOST & FOUND: NIGHT SHIFT — CURRENT STATE

Updated: 2026-08-28

## Identity
- Universe ID: `10745354451`
- Place ID: `93699016600671`
- Genre: Simulation
- Subgenre: None

## Infrastructure
- Temporary repo/build home: `balinightlife666-web/ACC-Android-Builder/lost-and-found-night-shift`
- Publish workflow is trigger-file/manual only.
- Deployment authority is `deploy-status/lost-and-found-m0.json`; never claim LIVE from source changes alone.

## Accepted baseline
- M0 — FIRST SUITCASE — COMPLETE / ACCEPTED.
- M0.1 FEEL PASS — COMPLETE / ACCEPTED.
- M1 PREMIUM ROOM — COMPLETE / RUNTIME-APPROVED.
- M2-A Collection UI — COMPLETE / ACCEPTED.
- M2-B 10-item variants + showcase — COMPLETE / ACCEPTED.
- M2-C persistence — COMPLETE / RUNTIME-ACCEPTED.
- M2-D collection 15 — COMPLETE / RUNTIME-ACCEPTED.
- M2-E collection 20 — COMPLETE / RUNTIME-ACCEPTED.
- Credits, XP, and discovered Collection Index IDs persist through `LostAndFound_PlayerData_v1`.

## M3 — FLIGHT 000 / CONNECTED MYSTERY
Authorities:
- `brain/M3_FLIGHT_000_LOCK.md`
- `brain/M3B_CONNECTED_CHAIN_LOCK.md`

### M3-A — FIRST INCIDENT
**COMPLETE / USER-ACCEPTED ON v27.**

Flight 000 remains:
- Jonas Vale;
- passenger record FOUND;
- flight record NOT FOUND;
- tag `F0-00013`;
- correct action QUARANTINE;
- CONNECTED / UNRESOLVED;
- exact final explanation CANON UNKNOWN.

### M3-B — CONNECTED MYSTERY CHAIN
**IMPLEMENTED / LIVE — visual cleanup complete.**

Archive entries:
1. `000-A — FLIGHT 000`
2. `000-B — OWNERLESS SUITCASE`
3. `000-C — THE LOST CHILD`

Archive is historical discovery progress and does not depend on current trade ownership. Lost Child remains 2001 + SECURITY/protective escalation. Final explanation remains unknown.

## M4 — UNIQUE ITEM ECONOMY / TRADING
Authorities:
- `brain/M4_UNIQUE_ITEM_TRADING_LOCK.md` v1.1
- `brain/M4C_ECONOMY_HARDENING_LOCK.md` v1.0

### M4-A — UNIQUE ITEM INSTANCE + SERIAL FOUNDATION
**COMPLETE / RUNTIME-ACCEPTED ON v31.**

Accepted model:
- Collection Index = ever discovered;
- Inventory Instance = currently owned transferable item;
- immutable `instanceId` = ownership key;
- immutable human-readable serial = collector identity;
- serial minting is server-authoritative with atomic global counters.

Runtime evidence:
- `SNP-S1-000001`, `ARP-S1-000001`, and `UMR-S1-000001` survived rejoin unchanged on v31.

### M4-B — SECURE PLAYER TRADING v1
**LIVE_PUBLISHED v32 — PHASE 1 MOBILE UI PASS / PROVISIONALLY USER-ACCEPTED; TWO-ACCOUNT OWNERSHIP QC DEFERRED.**

Scope:
- same-server only;
- one serialized item ↔ one serialized item;
- no trade currency and no multi-item bundle yet;
- exact `instanceId` ownership validation;
- request / accept / decline;
- item lock while session active;
- changing offer resets confirmation;
- both first-confirm;
- 3-second final review lock;
- both final-confirm before commit;
- durable trade journal + recovery markers + rollback path.

Phase 1 evidence:
- `SECURE SERIAL TRADE` panel opened cleanly on mobile;
- one-player empty-state, refresh and close were accepted.

Deferred Phase 2 QC:
- true two-account serial swap + both-account rejoin remains deferred until a second tester/friend is available;
- do NOT claim cross-player ownership transfer was independently runtime-proven yet.

### M4-C — ANTI-ALT / ECONOMY TELEMETRY HARDENING
**LIVE_PUBLISHED v33 — BUILD/DEPLOY VERIFIED; RUNTIME QC PENDING.**

Authority:
`brain/M4C_ECONOMY_HARDENING_LOCK.md`

Credits role is locked:
- Credits = non-transferable in-game soft currency;
- intended sinks: cosmetic scanner/desk/room styles, showcase/display upgrades, cosmetic case-file themes/titles/nameplates, controlled convenience such as limited rerolls, seasonal cosmetics, and only later optional processing fees if telemetry supports them;
- Credits MUST NOT transfer player-to-player;
- Credits MUST NOT directly purchase SECRET / ANOMALY collectible instances;
- Credits MUST NOT replace serialized item-for-item trading.

M4-C implementation:
- `EconomyTelemetryService.lua` buffers aggregate daily telemetry in `LostAndFound_EconomyTelemetry_v1`;
- `M4CEconomy.server.lua` tracks case/reward/mint/playtime economy signals without changing existing rewards;
- persistent player economy stats are added compatibly to `LostAndFound_PlayerData_v1`; payload version is 5 and the store name is unchanged;
- stats: `casesCompleted`, `perfectCases`, `creditsEarned`, `creditsSpent`, `serialsMinted`, `tradesCompleted`, `playSeconds`;
- legacy progression is conservatively seeded from existing XP/Credits rather than resetting established players;
- serial mint telemetry remains server-side;
- decision telemetry records completed cases, PERFECT outcomes, and Credits issued;
- trade request/completion/cancel telemetry is server-side;
- trade access requires persistence + serialized inventory ready, Roblox account age >= 7 days, and either >= 5 completed cases OR >= 50 XP, plus at least one tradeable serialized item;
- Credits are NOT required to unlock trading;
- no SECRET/ANOMALY cap or drop-rate nerf is introduced yet.

M4-C telemetry aggregate counters:
- `casesCompleted`
- `perfectCases`
- `creditsIssued`
- `serialsMinted`
- `tradeRequests`
- `tradeCompleted`
- `tradeCancelled`

M4-C hard limits:
- no auto-inspection / auto-decision;
- no AFK reward loop;
- no device fingerprinting;
- no external-payment data;
- no arbitrary scarcity nerf before telemetry justifies it.

## M5 / LIVE-SERVICE SEASONAL PRIORITY
Authority: `brain/SEASONAL_EVENTS_LOCK.md`.

2026 priorities:
- Halloween 2026 around 31 October;
- Christmas 2026 around 25 December.

Each major event must include limited collectible pool, event-edition serial identity, in-engine 3D/environment transformation, event-specific case/anomaly hook, and clear edition presentation.

Default serial direction:
- Halloween 2026: `<PREFIX>-HW26-<NUMBER>`;
- Christmas 2026: `<PREFIX>-XMAS26-<NUMBER>`.

Seasonal gameplay visuals are Roblox 3D/procedural/in-engine by default. No AI-generated image assets unless Arda explicitly requests image generation.

## Latest VERIFIED LIVE publish receipt
Run: `33096058726`
Source commit: `39ba78108fca79b6cb2b5ca04559a3ce8c5fa23a`
Rojo: `7.7.0`
Workflow conclusion: **SUCCESS**
Roblox publish status: **LIVE_PUBLISHED**
Roblox version: `33`
RBXL bytes: `74069`
RBXL SHA256: `a4ab3172235338033918204922ef5f0bfb343567fc866858b14858da4f141f74`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v33 BUILD/DEPLOY VERIFIED.**
M4-C is live in build/deploy terms; runtime regression QC is still pending.

## Active next gate — M4-C RUNTIME
1. rejoin established save: Credits / XP / INDEX / serials must remain intact;
2. normal case rewards must remain unchanged;
3. complete one case and confirm no core-loop regression;
4. established account should remain trade-eligible if age/progression gate is met;
5. no new mobile UI overlap;
6. telemetry must not block gameplay if DataStore flush fails;
7. deferred two-account M4-B Phase 2 remains on regression list.

After M4-C passes: collectible 3D visual-quality pass without image generation, then Halloween 2026 production preparation.
