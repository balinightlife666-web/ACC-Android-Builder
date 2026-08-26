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

## M0-RUNTIME1 findings
In-Roblox mobile screenshots verified that the basic runtime loop is alive:
- player joins the generated Lost & Found room;
- cases arrive and advance automatically;
- claimant data appears;
- CHECK TAG interaction works;
- decision pads work;
- case completion advances into later cases.

Runtime defects found in v5:
1. decisions could be submitted while SCAN and OPEN were still pending;
2. mobile HUD was too large and overlapped Roblox top-bar space;
3. claimant billboard labels were oversized;
4. neon decision pads were visually overpowering;
5. room readability was too dark.

## M0-QC2 runtime patch
Patch source changes:
- enforce server-side inspection sequence `SCAN → CHECK TAG → OPEN → DECIDE`;
- disable later prompts until the required previous inspection is complete;
- disable all decision prompts until all three evidence steps are complete;
- correct decision after full required inspection grades as PERFECT;
- mobile-safe compact HUD and step-by-step instruction text;
- result moved to a compact bottom toast;
- smaller claimant billboard labels with max distance;
- decision pads changed from full neon to subdued smooth-plastic colors;
- ceiling and overhead lighting added for room readability.

Publish run `33000601563`:
- Source commit: `ac73ed6e779f0f3568ecd27788a6991f3365c83f`
- Rojo: `7.7.0`
- Static QC: **PASS**
- Rojo build: **PASS**
- RBXL bytes: `16439`
- RBXL SHA256: `c043acb7d9eb384e0b5275596ab361316e085f676f16e7428471b5b00a2b0da1`
- Roblox publish: **PASS**
- Roblox version: `6`
- Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v6 BUILD/DEPLOY VERIFIED.**
Roblox receipt proves source commit `ac73ed6e779f0f3568ecd27788a6991f3365c83f` was published to Universe `10745354451` / Place `93699016600671` as Roblox version `6`.

The original core runtime is proven alive by mobile testing, but v6 patch acceptance still requires a short retest.

## Next gate
**M0-RUNTIME2:** verify v6 on mobile:
1. HUD no longer covers roughly half the screen or Roblox top controls;
2. only SCAN is available first;
3. after SCAN, CHECK TAG becomes available;
4. after CHECK TAG, OPEN becomes available;
5. decision pads only become interactable after OPEN;
6. correct decision produces result/reward;
7. next case begins automatically;
8. room and claimant labels are readable without dominating the screen.

Do not begin premium asset production until M0-RUNTIME2 passes.
