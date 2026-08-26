# LOST & FOUND: NIGHT SHIFT — CURRENT STATE

Updated: 2026-08-27

## Identity
- Universe ID: `10745354451`
- Place ID: `93699016600671`
- Genre selection: Simulation
- Subgenre selection: None

## Infrastructure
- Temporary repo/build home: `balinightlife666-web/ACC-Android-Builder/lost-and-found-night-shift`
- Temporary routing is intentional while `ardarawk-cloud` quota/limits recover.
- RR/Roblox publishing credential is present in ACC Builder; do not duplicate or expose credentials.
- Lost & Found publish workflow is trigger-file/manual only; it does not run on ordinary commits.

## Active milestone
**M0 — FIRST SUITCASE**

Implementation target:
`spawn → suitcase arrives → scan → check tag → inspect/open → claimant → decide → grade/reward → next case`

## Implemented in source
- Rojo project structure
- procedural M0 room builder
- procedural suitcase and claimant placeholders
- 10-case Lua registry
- scanner/tag/open prompts
- four decision prompts
- result grading
- Credits + XP leaderstats
- HUD client
- automatic case cycling

## M0-QC1 result
Initial run `32994564692`:
- Static QC: **PASS**
- Rojo build: **PASS**
- Roblox publish: blocked once with HTTP `403` / `User is moderated`

Retry run `32998424565`:
- Source commit: `d6d7b5fa4c606771afbbd5cb8c5b8eb5496a7554`
- Rojo: `7.7.0`
- Static QC: **PASS**
- Rojo build: **PASS**
- RBXL bytes: `15365`
- RBXL SHA256: `058e31ad68c2992b6516fcc6d1ac01830db3424bed3e66a1da9ae65cd48d3347`
- Roblox publish: **PASS**
- Roblox version: `5`
- Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — BUILD/DEPLOY VERIFIED.**
Roblox receipt proves M0 source commit `d6d7b5fa4c606771afbbd5cb8c5b8eb5496a7554` was published to Universe `10745354451` / Place `93699016600671` as Roblox version `5`.

This does **not** yet prove runtime gameplay acceptance. The next authority gate is an in-Roblox functional check of FIRST SUITCASE.

## Next gate
**M0-RUNTIME1:** join Place `93699016600671` and verify:
1. player spawns in the Lost & Found room;
2. suitcase arrives on conveyor;
3. SCAN / CHECK TAG / OPEN work;
4. claimant appears when applicable;
5. RETURN / STORE / QUARANTINE / SECURITY work;
6. result grade + Credits/XP appear;
7. next case begins automatically;
8. no blocking script/runtime errors.

Do not begin premium asset production until FIRST SUITCASE is functionally proven.
