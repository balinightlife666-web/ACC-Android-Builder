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
GitHub Actions run: `32994564692`
Source commit: `be3707bed1aa67f657b92cd2723c2ee0603b6d8d`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
RBXL bytes: `15365`
RBXL SHA256: `058e31ad68c2992b6516fcc6d1ac01830db3424bed3e66a1da9ae65cd48d3347`

Roblox publish: **BLOCKED**
HTTP: `403`
Roblox response: `User is moderated`

This is a Roblox account/key-owner moderation blocker, not a Rojo/build failure. Do not repeatedly republish while this blocker remains.

## LIVE authority
**NOT LIVE / NOT VERIFIED.**
No LIVE claim is permitted until a successful Roblox publish receipt exists for Universe `10745354451` / Place `93699016600671`, followed by runtime gameplay verification.

## Next gate
Resolve/clear the Roblox moderation blocker for the publishing identity, then rerun the existing Lost & Found M0 publish gate. After successful publish, perform in-Roblox FIRST SUITCASE runtime verification.

Do not begin premium asset production until FIRST SUITCASE is functionally proven.
