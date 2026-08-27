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

Flight 000 canon remains locked:
- Passenger: Jonas Vale.
- Passenger record: FOUND.
- Flight record: NOT FOUND.
- Tag: `F0-00013`.
- Correct action: QUARANTINE.
- Status: CONNECTED / UNRESOLVED.
- Exact final explanation: CANON UNKNOWN.

### M3-B — CONNECTED MYSTERY CHAIN
**IMPLEMENTED / LIVE — visual cleanup complete.**

Archive entries remain:
1. `000-A — FLIGHT 000`
2. `000-B — OWNERLESS SUITCASE`
3. `000-C — THE LOST CHILD`

Archive progression is historical discovery progress and does not depend on current trade ownership. Lost Child remains 2001 + SECURITY/protective escalation. Final explanation remains unknown.

## M4 — UNIQUE ITEM ECONOMY / TRADING
Authority: `brain/M4_UNIQUE_ITEM_TRADING_LOCK.md` v1.1.

### M4-A — UNIQUE ITEM INSTANCE + SERIAL FOUNDATION
**COMPLETE / RUNTIME-ACCEPTED ON v31.**

Accepted model:
- Collection Index = whether a collectible type has ever been discovered;
- Inventory Instance = the actual owned item that can move between players;
- immutable internal `instanceId` is the ownership key;
- human-readable serial is immutable display identity;
- serial minting is server-authoritative using atomic global counters.

Runtime acceptance evidence:
- first v31 login showed serialized old-save items;
- after rejoin `SNP-S1-000001`, `ARP-S1-000001`, and `UMR-S1-000001` remained unchanged;
- therefore serial persistence passed.

### M4-B — SECURE PLAYER TRADING v1
**LIVE_PUBLISHED v32 — PHASE 1 MOBILE UI SMOKE PASS / PHASE 2 OWNERSHIP TEST PENDING.**

Scope:
- same-server only;
- one serialized item ↔ one serialized item;
- no currency / no multi-item bundle yet;
- exact instance ownership validation by `instanceId`;
- request / accept / decline;
- server item lock during active session;
- changing an offer resets confirmation;
- both first-confirm before final review;
- 3-second server-enforced final review lock;
- both final-confirm before ownership commit;
- cancel / disconnect before commit does not move ownership.

Persistence / anti-dupe:
- durable `LostAndFound_TradeJournal_v1`;
- per-user `LostAndFound_TradeRecovery_v1` marker;
- journal is `PREPARED` before ownership mutation;
- both player inventories are saved before journal becomes `COMMITTED`;
- failure attempts rollback to original inventory snapshots;
- unresolved recovery markers reconcile on future profile load;
- committed item receives updated `currentOwnerUserId`, `tradeCount`, `lastTradeAt`, `lastTradeId`, and bounded provenance;
- profile payload version is 4 while DataStore name remains `LostAndFound_PlayerData_v1`.

Critical migration hardening:
- persisted `serialMigrationComplete` flag;
- legacy backfill runs only once;
- after migration, trading away the final owned instance MUST NOT mint a free replacement on rejoin;
- Collection Index stays discovered, but UI shows `NOT OWNED` when current owned count is zero.

Mobile UI:
- `TRADE` joins the compact top-right utility stack below Archive;
- same-server player lobby;
- incoming ACCEPT / DECLINE;
- local exact-serial item picker;
- YOUR OFFER / THEIR OFFER review;
- first confirmation + final confirmation;
- COMMITTING state;
- completion summary with sent serial, received serial, and trade ID;
- utility visibility coordinator prevents TRADE overlap with Collection / Archive / Case File / Trade popups.

Phase 1 runtime evidence on v32:
- mobile screenshot confirmed `SECURE SERIAL TRADE` opens cleanly;
- one-player empty-state correctly shows `No other players are in this server.`;
- `REFRESH PLAYERS` and close control are readable and properly positioned;
- panel fits mobile without overlap with movement controls;
- Phase 1 UI smoke test is accepted.

## M5 / LIVE-SERVICE SEASONAL PRIORITY
Authority: `brain/SEASONAL_EVENTS_LOCK.md`.

2026 priorities:
- Halloween 2026 around 31 October;
- Christmas 2026 around 25 December.

Each major event must include limited collectible pool, event-edition serial identity, in-engine 3D/environment transformation, event-specific case/anomaly hook, and clear edition presentation.

Default event serial direction:
- Halloween 2026: `<PREFIX>-HW26-<NUMBER>`;
- Christmas 2026: `<PREFIX>-XMAS26-<NUMBER>`.

Seasonal gameplay visuals are Roblox 3D/procedural/in-engine by default. No AI-generated image assets unless Arda explicitly requests image generation.

## Latest VERIFIED LIVE publish receipt
Run: `33092557996`
Source commit: `4efee7af76775f1142d2b319c74bd55b6da83f07`
Rojo: `7.7.0`
Workflow conclusion: **SUCCESS**
Roblox publish status: **LIVE_PUBLISHED**
Roblox version: `32`
RBXL bytes: `69842`
RBXL SHA256: `b43fbcdfc402173ae4bf63283357c0c1b7be39b7827b066a19ff08de6852c609`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v32 BUILD/DEPLOY VERIFIED.**
M4-B Phase 1 mobile UI smoke test passed; trading ownership transfer is NOT runtime-accepted yet.

## Next gate — M4-B PHASE 2 OWNERSHIP
1. put two persistence-ready accounts in the same server;
2. request / accept works;
3. each selects one exact serialized instance;
4. both first-confirm;
5. final confirm remains locked for ~3 seconds;
6. both final-confirm once;
7. sent serial disappears from original inventory and received serial appears for new owner;
8. Collection Index remains historical discovery progress;
9. if a player owns zero copies after trade, card shows `NOT OWNED`;
10. both players leave/rejoin and the swapped serials remain with the new owners;
11. no duplicate serial appears.

After M4-B passes, harden anti-alt/economy telemetry, improve collectible 3D visual quality, then prepare Halloween 2026 seasonal production.
