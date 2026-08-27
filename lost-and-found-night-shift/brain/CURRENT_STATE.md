# LOST & FOUND: NIGHT SHIFT — CURRENT STATE

Updated: 2026-08-28

## Identity / infrastructure
- Universe ID: `10745354451`
- Place ID: `93699016600671`
- Repo/build home: `balinightlife666-web/ACC-Android-Builder/lost-and-found-night-shift`
- Publish workflow: `.github/workflows/lost-found-m0-publish.yml`
- Deployment authority: `deploy-status/lost-and-found-m0.json`; never claim LIVE from merge/source changes alone.

## Accepted baseline
- M0 — FIRST SUITCASE — COMPLETE / ACCEPTED.
- M0.1 FEEL PASS — COMPLETE / ACCEPTED.
- M1 PREMIUM ROOM — COMPLETE / RUNTIME-APPROVED.
- M2 Collection Foundation — COMPLETE / RUNTIME-ACCEPTED.
- M3-A Flight 000 — COMPLETE / USER-ACCEPTED on v27.
- M3-B Connected Mystery Chain — IMPLEMENTED / LIVE.
- M4-A serialized item foundation — COMPLETE / RUNTIME-ACCEPTED on v31.
- M4-B secure same-server serialized trading v1 — LIVE v32; Phase 1 mobile UI accepted; two-account ownership/rejoin QC deferred.
- M4-C anti-alt/economy telemetry — LIVE v33 build/deploy verified.

## Canon locks
Core loop:
`ITEM ARRIVES → SCAN → CHECK TAG → OPEN / INSPECT → DECIDE → RESULT → REWARD → NEXT ITEM`

Decisions:
`RETURN / STORE / QUARANTINE / SECURITY`

Season 1 pillars:
- Flight 000 — QUARANTINE; final explanation CANON UNKNOWN.
- Ownerless Suitcase — QUARANTINE; owner UNKNOWN; may reappear.
- The Lost Child — archive/missing year 2001; SECURITY/protective escalation; final supernatural explanation CANON UNKNOWN.

## Collection / ownership model
- Collection Index = historical discovery/encounter prestige.
- Inventory Instance = actual currently owned transferable item.
- Every instance has immutable `instanceId`, immutable human-readable serial, global mint number and provenance.
- Index discovery never creates a free replacement after an item is traded away.
- New copies require a valid future server mint/drop or trade.
- Same-server trading remains one serialized item ↔ one serialized item; no trade currency/off-platform payment flow.

## M4-D — PERSONAL STATION / MULTIPLAYER JOB ISOLATION
Authority: `brain/M4D_PERSONAL_STATION_LOCK.md` v1.1.

**LIVE_PUBLISHED v34 — BUILD/DEPLOY VERIFIED / SOLO RUNTIME QC PENDING.**

Exact deployment evidence:
- source commit: `950eeb1e7b4c6119292340f4e630b8fa3e589461`
- workflow run: `33100322285`
- status: `LIVE_PUBLISHED`
- Roblox version: `34`
- Rojo: `7.7.0`
- RBXL bytes: `83918`
- RBXL SHA256: `b70b00eaeab8cdfc6cb72b1ea881625ddc75995d2903c6ed3cae903436692612`
- receipt milestone: `M4D_PERSONAL_SHIFTS`

### Multiplayer station architecture
- initial design target: 8 active job players/server;
- 8 physical station slots A-H in one shared social room;
- station letter is temporary placement, not permanent account ownership;
- `PersonalStationWorld.lua` builds Station A-H;
- `PersonalShiftRuntime.lua` replaces the legacy global `activeCase` loop;
- every station owns its own active case, inspection progress, item, claimant, decision lock, reward and next-case timer;
- server validates Station OwnerUserId for every SCAN/TAG/OPEN/DECIDE interaction;
- other stations' prompts are locally hidden when practical, but server validation remains authority;
- leave cleans the active case and releases the station to VACANT;
- if more than 8 players reach a server before Creator MaxPlayers is configured to 8, extra players receive no shared-job fallback.

### Join / personal identity
- join assigns first available station;
- player attribute `LostFoundStationId` records current physical slot;
- mobile HUD shows `SHIFT STATION X`;
- assignment toast shows `SHIFT ASSIGNED — STATION X`;
- assigned station receives a temporary local highlight;
- character is staged at assigned station on join/respawn;
- station sign shows current owner identity.

### Personal case distribution
- fresh progression: fixed 001 → 002 → 003 onboarding;
- after onboarding: independent weighted random personal stream;
- server avoids assigning an already-active case when another eligible case is available;
- mystery eligibility is personal progression;
- current implementation thresholds: Ownerless >=5 completed cases, Flight 000 >=7, Changing Weight >=8, Double Identity >=9, Lost Child >=10.

### Personal collectible supply
Flow:
`PERSONAL CASE → PERFECT ELIGIBILITY → SERVER-SIDE ROLL → GLOBAL SERIAL MINT → ONLY THAT PLAYER RECEIVES INSTANCE`

Initial balance values:
- COMMON 100%
- UNCOMMON 85%
- RARE 65%
- EPIC 40%
- ANOMALY 16%
- SECRET 8%

Rules:
- roll is per-player/per-station, not one shared server prize;
- normal SECRET/ANOMALY is NOT one-drop-per-server;
- Index can be discovered while owned count is zero (`NOT OWNED`);
- replay can create another owned copy only through a new valid server-side roll;
- every copy receives a distinct immutable serial;
- future seasonal limited items may use global mint caps.

### Persistent Personal Station Profile
DataStore remains `LostAndFound_PlayerData_v1`; payload version is now 6.

Persisted foundation:
- `equippedSkin`
- `ownedSkins`
- `title`

Default:
- `STANDARD_OPS`
- owned `STANDARD_OPS`
- `NIGHT SHIFT OPERATOR`

Station skin registry currently defines:
- STANDARD_OPS — FREE
- INDUSTRIAL_SHIFT — 8,000 Credits target
- RETRO_AIRPORT — 18,000 Credits target
- BLACK_OPS — 35,000 Credits target
- LUXURY_EXECUTIVE — ROBUX; product/price TBD
- HALLOWEEN_2026 — EVENT
- CHRISTMAS_2026 — EVENT

Registry/profile loading is live foundation only. Station Shop purchase/equip UX is NOT implemented yet.
Robux cosmetics must never improve collectible odds, rewards, farming output or trading advantage.

### Social flex
- each occupied station has a replicated public showcase;
- automatically displays up to 3 currently owned high-rarity serialized items;
- nearby players can see serial labels;
- showcase items cannot be removed/mutated by another player;
- old giant local-only wall showcase is retired.

## M4-C / trading protections retained
- Credits remain non-transferable soft currency.
- Credits cannot directly purchase SECRET/ANOMALY instances.
- Trade unlock requires persistence/serialized inventory ready + account age >=7 days + >=5 completed cases OR >=50 XP + at least one tradeable item.
- trade journal/recovery/rollback architecture remains active.
- M4-B two-account ownership/rejoin QC remains deferred until a second tester is available.

## ACTIVE GATE — M4-D SOLO RUNTIME QC
User can test now on Roblox v34:
1. join/rejoin and confirm existing Credits / XP / INDEX / serials remain intact;
2. when alone, confirm assignment to Station A and `SHIFT STATION A` HUD;
3. confirm character lands at Station A and owner sign identifies the player;
4. confirm suitcase/case arrives at the personal station;
5. complete SCAN → TAG → OPEN → DECIDE;
6. confirm normal reward and next personal case start;
7. confirm public station showcase displays owned serialized items;
8. confirm old giant local wall showcase is gone;
9. confirm no obvious mobile HUD overlap or movement regression.

Do NOT call M4-D runtime-accepted until this solo QC passes.

## DEFERRED MULTIPLAYER QC
When a second tester is available:
- Station A/B separate assignment;
- independent simultaneous case streams;
- player B cannot operate player A job controls/rewards;
- item/claimant/HUD state does not leak across stations;
- avoid-duplicate active case behavior works when practical;
- same-server serialized trade still works;
- swapped serial ownership survives both-account rejoin with no duplicate serial.

## Next after solo pass
1. Station Shop v1: Credits purchase/equip for earnable station skins;
2. optional Robux premium cosmetic integration only after intentional product IDs/prices exist;
3. manual featured-showcase selection;
4. collectible 3D visual-quality pass;
5. Halloween 2026 production preparation;
6. performance telemetry before considering more than 8 active station slots.

Seasonal gameplay visuals remain Roblox 3D/procedural/in-engine by default; no AI-generated image assets unless explicitly requested.
