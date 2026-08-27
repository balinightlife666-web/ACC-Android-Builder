# LOST & FOUND: NIGHT SHIFT — CURRENT STATE

Updated: 2026-08-28

## Identity / infrastructure
- Universe ID: `10745354451`
- Place ID: `93699016600671`
- Repo/build home: `balinightlife666-web/ACC-Android-Builder/lost-and-found-night-shift`
- Publish workflow: `.github/workflows/lost-found-m0-publish.yml`
- Deployment authority: `deploy-status/lost-and-found-m0.json`; never claim LIVE from source changes alone.

## Accepted baseline
- M0 — FIRST SUITCASE — COMPLETE / ACCEPTED.
- M0.1 FEEL PASS — COMPLETE / ACCEPTED.
- M1 PREMIUM ROOM — COMPLETE / RUNTIME-APPROVED.
- M2 Collection Foundation — COMPLETE / RUNTIME-ACCEPTED.
- M3-A Flight 000 — COMPLETE / USER-ACCEPTED on v27.
- M3-B Connected Mystery Chain — IMPLEMENTED / LIVE.
- M4-A serialized item foundation — COMPLETE / RUNTIME-ACCEPTED on v31.
- M4-B secure same-server item trading — LIVE v32; one-player UI accepted; true two-account ownership/rejoin QC deferred.
- M4-C anti-alt/economy telemetry — LIVE v33 build/deploy verified.
- M4-D Personal Stations — LIVE v34 core; SOLO CORE FUNCTIONAL PASS; multiplayer isolation QC deferred.
- M4-D.1 Station Readability — LIVE v35.
- M4-D.1 decision color hotfix — LIVE v36.
- M4-E Case Depth + NPC Variation — LIVE v37 build/deploy verified; runtime QC pending.

## Canon / gameplay locks
Core loop:
`ITEM ARRIVES → SCAN → CHECK TAG → OPEN / INSPECT → DECIDE → RESULT → REWARD → NEXT ITEM`

Decisions:
`RETURN / STORE / QUARANTINE / SECURITY`

Season 1 mystery canon:
- Ownerless Suitcase — QUARANTINE; owner UNKNOWN.
- Flight 000 — QUARANTINE; final explanation CANON UNKNOWN.
- Changing Weight — QUARANTINE.
- Double Identity — SECURITY.
- The Lost Child — SECURITY/protective escalation; archive/missing year 2001; final supernatural explanation CANON UNKNOWN.

Mystery canon must not be procedurally rewritten.

## Personal station architecture
Authority: `brain/M4D_PERSONAL_STATION_LOCK.md` v1.1.
- initial target: 8 players/server;
- 8 physical slots A-H in one shared room;
- station letter is temporary placement, not permanent ownership;
- isolated per-player case / claimant / inspection / decision / reward / next-case state;
- server validates station ownership for every job interaction;
- player Station Profile persists independent of physical slot.

Station Profile foundation:
- `equippedSkin`
- `ownedSkins`
- `title`

Skin registry foundation:
- STANDARD_OPS — FREE
- INDUSTRIAL_SHIFT — 8,000 Credits target
- RETRO_AIRPORT — 18,000 Credits target
- BLACK_OPS — 35,000 Credits target
- LUXURY_EXECUTIVE — ROBUX, exact product/price TBD
- HALLOWEEN_2026 — EVENT
- CHRISTMAS_2026 — EVENT

Station Shop UX is not implemented yet.

Decision colors are independent from station skins:
- RETURN green
- STORE cyan/blue
- QUARANTINE amber/yellow
- SECURITY red

## Collection / economy
- Collection Index = historical discovery prestige.
- Inventory Instance = currently owned transferable item.
- immutable `instanceId`, serial, global mint number and provenance;
- no free remint after trade-away;
- Credits are non-transferable soft currency;
- Credits cannot directly buy SECRET/ANOMALY;
- same-server trade remains serialized item ↔ serialized item;
- no off-platform payment flow.

Collectible flow:
`PERSONAL CASE → PERFECT → SERVER DROP ROLL → GLOBAL SERIAL MINT → ONLY THAT PLAYER RECEIVES INSTANCE`

Drop targets remain:
- COMMON 100%
- UNCOMMON 85%
- RARE 65%
- EPIC 40%
- ANOMALY 16%
- SECRET 8%

## M4-E — CASE DEPTH + NPC VARIATION
Authority: `brain/M4E_CASE_DEPTH_NPC_LOCK.md` v1.0.

**LIVE_PUBLISHED v37 — BUILD/DEPLOY VERIFIED / SOLO RUNTIME QC PENDING.**

Purpose: stop experienced players from solving routine work through memorised case IDs/titles.

Live implementation:
- routine jobs are generated as neutral `LF-R-... / Property Review` tickets;
- broad claimant-name pool;
- variable tags, flights, weights and contents;
- 15 routine evidence archetypes across RETURN / STORE / SECURITY / QUARANTINE;
- internal scenario IDs are not shown to players;
- five established routine item/collection profiles are reused, avoiding unnecessary collectible-ID inflation;
- mystery cases remain progression-gated and canonical but are materially rarer routine candidates;
- `M4ENpcPolish.server.lua` adds lightweight procedural claimant body/outfit/hair/face/glasses variation using Roblox geometry only;
- no AI-generated image assets or external NPC dependencies.

M4-E does not change:
- Credits/XP reward values;
- drop rates;
- serial/provenance rules;
- trading;
- station ownership;
- mystery canon.

## Latest VERIFIED LIVE authority
Receipt: `deploy-status/lost-and-found-m0.json`

Roblox v37:
- status: `LIVE_PUBLISHED`
- source commit: `268800a54558b27de6e8b6ecfe4d166c7260fe80`
- workflow run: `33108987965`
- Rojo: `7.7.0`
- RBXL bytes: `94776`
- RBXL SHA256: `489259f15237b82e34127b218d4e7927ae212d8888e0b74706d8443fa30458f1`

## Active next gate — M4-E SOLO RUNTIME QC
1. join established save; Credits / XP / INDEX / ARCHIVE / serials remain intact;
2. routine HUD shows `Property Review`, not answer-bearing titles like Tag Mismatch / Wrong Color / False Claim;
3. play several routine jobs and confirm names / tags / flights / evidence vary;
4. correct decision should require reading evidence rather than remembering case number;
5. claimant NPCs visibly vary beyond torso/head mannequin;
6. Station A flow, reward and next-case loop still work;
7. mystery cases, when they occur, retain canonical evidence/action.

## Deferred multiplayer QC
When a second tester is available:
- Station A/B assignment isolation;
- independent simultaneous case streams;
- player cannot operate another station's controls/rewards;
- no item/claimant/HUD leakage;
- same-server serialized trade works;
- swapped serial ownership survives both-account rejoin with no duplicate serial.

## Next after M4-E runtime pass
1. Station Shop v1 using Credits for earnable station skins;
2. manual featured-showcase selection;
3. collectible 3D quality pass;
4. optional Robux cosmetics after deliberate product IDs/prices exist;
5. Halloween 2026 production preparation.

Seasonal visuals remain Roblox 3D/procedural/in-engine by default. No AI-generated image assets unless explicitly requested.
