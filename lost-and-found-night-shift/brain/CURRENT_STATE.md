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

## M0 — FIRST SUITCASE
**ACCEPTED FOR CONTINUATION.**

Runtime proven on mobile:
- player joins and can move;
- case arrives on conveyor;
- enforced sequence is `SCAN → CHECK TAG → OPEN → DECIDE`;
- claimant data appears;
- RETURN / STORE / QUARANTINE / SECURITY work;
- grading and rewards work;
- Credits amount displays live in the top HUD;
- next case starts automatically;
- compact case card + on-demand CASE FILE popup work on mobile.

UI refinements through Roblox v10:
- compact HUD moved toward upper-left and clear of joystick;
- CASE FILE popup reduced while keeping readable evidence text;
- compact HUD hides while CASE FILE is open;
- result remains a bottom-center toast;
- movement/camera safety guard restores normal mobile controls;
- Credits are displayed separately at the top and update from leaderstats.

## Active milestone
**M0.1 — FEEL PASS**

Implemented:
- conveyor travel tuned from 3.2s to 2.8s;
- case advance delay tuned to 3.2s;
- interaction distance normalized to 7 studs;
- prompt hold duration reduced to 0.08s;
- claimant staged with a short 0.45s arrival delay after creation;
- lightweight built-in audio feedback layer for incoming case, ready state, SCAN, TAG, OPEN, blocked decision, and result grades;
- M0 gameplay, HUD, movement safety, economy values, and 10-case registry otherwise unchanged.

## M0.1 publish receipt
Run: `33005125067`
Source commit: `2fb9bf5298822ae8ec0249798cf5abd60c683159`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `11`
RBXL bytes: `20923`
RBXL SHA256: `7f8f73a19846e72d6807352ab996b0f4ee984e22023ff68403afdfff56e0cafa`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v11 BUILD/DEPLOY VERIFIED.**
Runtime acceptance of the new M0.1 feel layer still requires a short mobile retest.

## Next gate
**M0.1-RUNTIME:** verify on mobile:
1. movement/camera remain normal;
2. conveyor pacing feels faster without feeling abrupt;
3. prompts require closer intentional interaction;
4. claimant arrival does not feel instantaneous;
5. audio feedback is subtle and not annoying;
6. Credits display continues updating correctly;
7. full case loop still completes with no dead-end.

After M0.1 passes, proceed to **M1 — PREMIUM ROOM**. Do not start M2 collection expansion before M1 visual language is approved.
