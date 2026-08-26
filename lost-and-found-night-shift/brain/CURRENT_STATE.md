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
- automatic case cycling

## Runtime authority so far
M0 core runtime is proven alive on mobile:
- player joins the generated Lost & Found room;
- cases arrive and advance;
- SCAN / CHECK TAG / OPEN sequence works;
- claimant data appears;
- decision pads work;
- result/reward and next-case flow work.

v5 runtime exposed defects: early decisions were allowed, HUD was too large, claimant labels and neon pads dominated the screen, and room readability was too dark.

v6 fixed the gameplay gate and first visual/readability pass:
- server-enforced `SCAN → CHECK TAG → OPEN → DECIDE`;
- decision prompts locked until evidence is complete;
- mobile HUD reduced;
- smaller claimant labels;
- subdued decision pads;
- ceiling/lighting pass.

Mobile retest of v6 proved the gameplay sequence and grading flow, but the permanent evidence panel still occupied too much horizontal screen area and competed with movement controls.

## M0-QC3 — mobile Case File UI
The HUD architecture is now:
- always-on compact case card at upper-left;
- compact card shows case identity, short status, SCAN/TAG/OPEN progress, and `CASE FILE` button;
- full readable evidence is moved into an on-demand `CASE FILE` popup;
- popup uses readable 14px mono evidence text and a scroll area rather than shrinking evidence;
- popup can be closed immediately and is automatically closed on result/new incoming case;
- result remains a compact bottom-center toast;
- movement controls remain visually unobstructed during normal gameplay.

Publish run `33001502235`:
- Source commit: `097ca8e6b82a0c107c988874cc70730e42a45a9b`
- Rojo: `7.7.0`
- Static QC: **PASS**
- Rojo build: **PASS**
- RBXL bytes: `18156`
- RBXL SHA256: `b6ea9340cedfbeb723981c9e6a996dd5332937f355b387c3a559b6f17853c3ee`
- Roblox publish: **PASS**
- Roblox version: `7`
- Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v7 BUILD/DEPLOY VERIFIED.**
Roblox receipt proves source commit `097ca8e6b82a0c107c988874cc70730e42a45a9b` was published to Universe `10745354451` / Place `93699016600671` as Roblox version `7`.

## Next gate
**M0-RUNTIME3:** mobile UI acceptance for v7:
1. compact case HUD does not interfere with movement controls;
2. case title/status/progress remain readable at normal gameplay distance;
3. `CASE FILE` opens full evidence popup;
4. full evidence text remains comfortably readable without being tiny;
5. popup can be closed and gameplay immediately resumes unobstructed;
6. result toast remains readable without covering movement controls;
7. gameplay sequence remains `SCAN → TAG → OPEN → DECIDE`.

Do not begin premium asset production until M0-RUNTIME3 passes.
