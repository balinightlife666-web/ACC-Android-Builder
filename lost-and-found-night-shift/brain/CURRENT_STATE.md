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
**COMPLETE / RUNTIME-ACCEPTED ON v31.**

Goal:
Turn collection ownership into actual unique item instances without breaking the existing Collection Index.

Model:
- Collection Index = whether a collectible type has ever been discovered;
- Inventory Instance = the actual owned item that can later move through trading.

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
- `SerialMintService.lua` uses atomic DataStore `UpdateAsync` counters per collectible type;
- `CollectionRegistry` defines stable serial prefixes for all 20 collectibles;
- `LostAndFound_PlayerData_v1` remains the store name and accepts serialized `inventory` data (data version 2);
- old saves remain compatible because missing inventory defaults to empty;
- after successful old-save load, discovered collection entries without an owned instance are backfilled with serials;
- no replay is required for old discoveries;
- Collection cards show the owned serial beneath rarity;
- newly minted discoveries can show a `SERIAL MINTED` toast.

Runtime acceptance evidence:
- mobile screenshot on first v31 login showed stable serialized instances, including `SNP-S1-000001`, `ARP-S1-000001`, and `UMR-S1-000001`;
- second screenshot after rejoin showed the same three serials unchanged;
- therefore old-save backfill + persistence survived rejoin and M4-A is accepted.

Safety / anti-dupe direction:
- client never chooses a serial;
- global mint counters are server-authoritative;
- per-profile inventory sanitization rejects duplicate `instanceId` and duplicate serial values within the same payload.

## Latest VERIFIED LIVE publish receipt
Run: `33089525745`
Source commit: `0811f21c99b100c650ad5261f7bff3d0743ff4f2`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `31`
RBXL bytes: `52821`
RBXL SHA256: `ad0c5baa511a55bbb2b2cdeb46a87621748cc4484b4be18420dcf81d45306a24`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v31 BUILD/DEPLOY VERIFIED.**
M4-A serial ownership and rejoin persistence are runtime-accepted.

## Next gate
**M4-B — SECURE PLAYER TRADING**
Build player-to-player collectible trading on top of serialized ownership with:
1. player trade request / accept / decline;
2. server-side ownership validation by immutable `instanceId`;
3. item lock while a trade is active;
4. two-sided offer review;
5. first confirmation + final confirmation;
6. atomic ownership transfer / anti-double-spend;
7. trade history / provenance update;
8. cancel / disconnect recovery;
9. mobile-readable UI;
10. no off-platform payment or price fields in the game.
