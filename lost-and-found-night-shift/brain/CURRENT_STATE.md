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

## Accepted baseline
- M0 — FIRST SUITCASE — COMPLETE / ACCEPTED.
- M0.1 FEEL PASS — COMPLETE / ACCEPTED.
- M1 PREMIUM ROOM — COMPLETE / RUNTIME-APPROVED.
- M2-A Collection UI — COMPLETE / ACCEPTED.
- M2-B 10-item variants + showcase — COMPLETE / ACCEPTED.
- M2-C persistence — COMPLETE / RUNTIME-ACCEPTED.
- M2-D collection 15 — COMPLETE / RUNTIME-ACCEPTED.
- M2-E collection 20 — COMPLETE / RUNTIME-ACCEPTED.
- Credits, XP, and discovered collection IDs persist through `LostAndFound_PlayerData_v1`.

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
**IMPLEMENTED / LIVE v30 — VISUAL CLEANUP COMPLETE, FULL RUNTIME ACCEPTANCE NOT FORMALLY RECORDED.**

Archive entries remain:
1. `000-A — FLIGHT 000`
2. `000-B — OWNERLESS SUITCASE`
3. `000-C — THE LOST CHILD`

Persistence is rebuilt from the existing PERFECT bonus discoveries. Old valid saves do not need to replay these cases. Lost Child remains 2001 + SECURITY/protective escalation. Final explanation remains unknown.

Mobile cleanup through v30:
- Credits / Index / Archive use a unified compact utility-button system;
- popup close controls are standardized;
- opening Collection hides CASE HUD, Credits, INDEX, and ARCHIVE so the popup is not visually overlapped.

## M4 — UNIQUE ITEM ECONOMY / TRADING
Authority: `brain/M4_UNIQUE_ITEM_TRADING_LOCK.md`.

### M4-A — UNIQUE ITEM INSTANCE + SERIAL FOUNDATION
**IMPLEMENTED IN SOURCE — PUBLISH / RUNTIME QC PENDING.**

Goal:
Turn collection ownership into actual unique item instances without breaking the existing Collection Index.

Model:
- Collection Index = whether a collectible type has ever been discovered;
- Inventory Instance = the actual owned item that can later move through trading;
- trading remains LOCKED until ownership integrity passes runtime QC.

Unique identity fields:
- immutable internal `instanceId`;
- human-readable serial;
- global mint number;
- edition;
- mint timestamp;
- original finder user ID;
- source case / source kind;
- tradeable flag.

Serial format:
`<PREFIX>-S1-<GLOBAL MINT NUMBER>`

Example:
`CMB-S1-000001`

Implementation:
- new `SerialMintService.lua` uses atomic DataStore `UpdateAsync` counters per collectible type;
- `CollectionRegistry` now defines stable serial prefixes for all 20 collectibles;
- `LostAndFound_PlayerData_v1` remains the store name and now accepts an optional serialized `inventory` payload (data version 2);
- old saves remain compatible because missing inventory defaults to empty;
- after a successful old-save load, discovered collection entries without an owned instance are gradually backfilled with serials;
- no replay is required for old discoveries;
- Collection cards can show the owned serial beneath rarity;
- newly minted discoveries can show a `SERIAL MINTED` toast;
- no trade request / transfer code is enabled yet.

Safety / anti-dupe direction:
- client never chooses a serial;
- global mint counters are server-authoritative;
- per-profile inventory sanitization rejects duplicate `instanceId` and duplicate serial values within the same payload;
- atomic ownership transfer / escrow / provenance are deferred to M4-B.

## Latest VERIFIED LIVE publish receipt
Run: `33078835836`
Source commit: `581e0bd32ea7c7342ca238b94ca395879237369d`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `30`
RBXL bytes: `49545`
RBXL SHA256: `702c96f46d5dc4393ea44d2a7f1a77429450bebf32e6a880636d1907e0b6767b`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v30 BUILD/DEPLOY VERIFIED.**
M4-A source is newer than the current LIVE receipt and must not be called LIVE until a new receipt matches the M4-A publish trigger.

## Next gate
**M4-A-RUNTIME**
1. publish exact M4-A source and verify receipt;
2. rejoin with the existing save;
3. Credits and INDEX `/20` must remain intact;
4. old discovered items should progressively receive stable serials without replay;
5. open Collection and confirm serials render cleanly below rarity on mobile;
6. leave/rejoin and confirm the same serials return;
7. core case loop, Archive, movement, and Collection must remain stable;
8. trading stays disabled until M4-B.

After M4-A passes, build M4-B Secure Player Trading with server-side ownership validation, item locking/escrow, two-sided confirmation, atomic transfer, trade history, and anti-double-spend checks.
