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
- M4-D.1 Station Readability — LIVE v35 visual readability improved.
- M4-D.1 decision color hotfix — LIVE v36 build/deploy verified.

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
- station letter is temporary server placement, not permanent account ownership;
- each player has isolated active case, inspections, item, claimant, decision, rewards and next-case timer;
- server validates station ownership for SCAN/TAG/OPEN/DECIDE;
- station releases to VACANT on leave;
- player Station Profile persists independently of physical slot.

Persistent Station Profile foundation:
- `equippedSkin`
- `ownedSkins`
- `title`

Station skin registry foundation:
- STANDARD_OPS — FREE
- INDUSTRIAL_SHIFT — 8,000 Credits target
- RETRO_AIRPORT — 18,000 Credits target
- BLACK_OPS — 35,000 Credits target
- LUXURY_EXECUTIVE — ROBUX, product/price TBD
- HALLOWEEN_2026 — EVENT
- CHRISTMAS_2026 — EVENT

Station Shop purchase/equip UX is NOT implemented yet.

Functional decision colors are hard-locked independent from station skin:
- RETURN = green
- STORE = cyan/blue
- QUARANTINE = amber/yellow
- SECURITY = red

## Collection / economy
- Collection Index = historical discovery prestige.
- Inventory Instance = actual currently owned transferable item.
- every instance has immutable `instanceId`, human-readable serial, global mint number and provenance;
- traded-away item does not remint for free;
- Credits are non-transferable soft currency;
- Credits cannot directly buy SECRET/ANOMALY instances;
- same-server trading remains serialized item ↔ serialized item;
- no off-platform payment flow.

Personal collectible flow:
`PERSONAL CASE → PERFECT → SERVER DROP ROLL → GLOBAL SERIAL MINT → ONLY THAT PLAYER RECEIVES INSTANCE`

Current drop targets:
- COMMON 100%
- UNCOMMON 85%
- RARE 65%
- EPIC 40%
- ANOMALY 16%
- SECRET 8%

## M4-E — CASE DEPTH + NPC VARIATION
Authority: `brain/M4E_CASE_DEPTH_NPC_LOCK.md` v1.0.

**SOURCE IMPLEMENTED / NOT LIVE UNTIL RECEIPT MATCHES NEW TRIGGER COMMIT.**

Purpose: stop experienced players from solving routine work through memorised case IDs/titles.

Implemented source:
- `CaseRegistry.Get(1..5)` now generates neutral runtime routine tickets instead of exposing a fixed answer-bearing routine case;
- runtime routine HUD uses neutral `LF-R-... / Property Review` identity;
- broad claimant-name pool;
- variable tags, flights, weights and contents;
- 15 evidence archetypes across RETURN / STORE / SECURITY / QUARANTINE outcomes;
- combinations reuse the five existing routine collection/bonus profiles so collection IDs do not explode;
- internal scenario names are not exposed to player HUD;
- progression-gated mystery cases remain canonical but are only candidate incidents some cycles, making mystery appearances materially rarer than routine work;
- `M4ENpcPolish.server.lua` adds lightweight procedural claimant body/outfit/hair/face/glasses variation using Roblox geometry only;
- no image generation or external NPC assets.

M4-E does NOT change:
- Credits rewards;
- XP rewards;
- collectible drop rates;
- serial/provenance rules;
- trading;
- station ownership;
- mystery canon.

## Latest VERIFIED LIVE authority
Receipt: `deploy-status/lost-and-found-m0.json`

Roblox v36:
- status: `LIVE_PUBLISHED`
- source commit: `44e3b0c8046627375eb52e9d4d9ea18e5ca0e1c6`
- workflow run: `33105083714`
- Rojo: `7.7.0`
- RBXL bytes: `85865`
- RBXL SHA256: `a8487f13d33e577c1caa8d42607bbd4771cfe09b2664f99e627735c92cfaec7e`

**Current verified LIVE = Roblox v36. M4-E source is not LIVE yet.**

## Active next gate — M4-E publish + solo QC
1. publish exact M4-E source and verify receipt sourceCommit;
2. join established save and confirm Credits / XP / INDEX / ARCHIVE / existing serials remain intact;
3. routine case HUD should show neutral `Property Review`, not `Tag Mismatch`, `Wrong Color`, `False Claim`, etc.;
4. run several routine cases and confirm owner/claimant/tag/flight/evidence varies;
5. confirm correct answer is not a fixed repeating order and evidence must actually be read;
6. confirm claimant NPCs visibly vary beyond the old torso/head mannequin;
7. confirm personal Station A interaction/reward/next-case loop remains functional;
8. when a mystery occurs, verify its canonical decision/evidence is unchanged.

## Deferred multiplayer QC
When a second tester is available:
- Station A/B separate assignment;
- independent simultaneous case streams;
- other player cannot operate another station's job/reward;
- no item/claimant/HUD leakage;
- same-server serialized trade still works;
- swapped serial ownership survives both-account rejoin with no duplicate serial.

## Next after M4-E runtime pass
1. Station Shop v1 using Credits for earnable station skins;
2. manual featured-showcase selection;
3. collectible 3D quality pass;
4. optional Robux premium cosmetics after intentional product IDs/prices exist;
5. Halloween 2026 production preparation.

Seasonal gameplay visuals remain Roblox 3D/procedural/in-engine by default. No AI-generated image assets unless explicitly requested.
