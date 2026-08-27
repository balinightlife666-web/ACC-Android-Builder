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
- Trading remains locked.

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

Acceptance note:
- v26 confirmed Archive control visibility on mobile;
- v27 fixed the missing incident-banner path;
- Arda explicitly accepted M3-A without repeating the full Flight 000 runtime loop after the hotfix;
- therefore M3-A is USER-ACCEPTED rather than independently re-verified end-to-end after v27.

### M3-B — CONNECTED MYSTERY CHAIN
**IMPLEMENTED / LIVE v28 — RUNTIME QC PENDING.**

Goal:
Connect the three existing Season 1 pillars without forcing replay and without revealing the final explanation.

Archive entries:
1. `000-A — FLIGHT 000`
   - unlock key: `flight_000_boarding_tag`
   - Jonas Vale / passenger FOUND / flight NOT FOUND
   - tag `F0-00013`
   - action QUARANTINE
   - status CONNECTED / UNRESOLVED
2. `000-B — OWNERLESS SUITCASE`
   - unlock key: `ownerless_tag_00017284`
   - owner UNKNOWN / flight 000 / database origin NONE
   - tag `000-17284`
   - action QUARANTINE
   - status CONNECTED / UNRESOLVED
3. `000-C — THE LOST CHILD`
   - unlock key: `milo_toy_train_2001`
   - Milo Hart / MISSING PERSON RECORD / 2001
   - tag `OLD-2001-14`
   - action SECURITY
   - status CONNECTED / PROTECTIVE ESCALATION

Persistence compatibility:
- M3-B derives archive progression from the existing persistent PERFECT bonus discoveries already stored in the Collection save.
- No second archive DataStore was introduced.
- Old valid saves automatically rebuild Archive progress after join.
- Players do not need to replay Ownerless Suitcase, Flight 000, or Lost Child if the matching bonus discovery already exists in their save.

Mobile UX:
- top-right button displays `ARCHIVE x/3`;
- archive popup shows all three slots;
- unlocked slots reveal canon operational facts;
- locked slots stay visible as locked placeholders;
- newly earned Ownerless/Lost Child links may show a brief `CASE LINK CONFIRMED` toast;
- Flight 000 retains the stronger M3-A terminal incident banner;
- final explanation remains explicitly unknown.

M3-B hard limits:
- no final supernatural explanation;
- no new location/map expansion;
- no new currency;
- no trading;
- Lost Child remains a person requiring SECURITY/protective escalation;
- the 2001 date is immutable unless Arda explicitly revises canon.

## Latest publish receipt
Run: `33072052969`
Source commit: `8b71545d25c7a23729d2b2c91e0ce2bc720db5fa`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `28`
RBXL bytes: `49373`
RBXL SHA256: `c9e3e21c7948d07757e56e219a3fc03ec9fa77e3a55ee390de5e95a0e915573a`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v28 BUILD/DEPLOY VERIFIED.**
M3-B archive-chain UI/progression still requires mobile runtime acceptance.

## Next gate
**M3-B-RUNTIME**
1. rejoin with existing save;
2. ARCHIVE button shows the correct old-save count `/3` without replay;
3. open Archive and confirm three cards render on mobile;
4. already-earned linked bonuses reveal their corresponding entries;
5. locked entries remain readable placeholders;
6. Collection `/20`, Credits, movement, CASE FILE, and case loop remain stable;
7. no final lore explanation is exposed.

After M3-B passes, continue M3 with a deeper operational escalation/limited anomaly reward before M4 social/economy hardening. Trading remains locked.
