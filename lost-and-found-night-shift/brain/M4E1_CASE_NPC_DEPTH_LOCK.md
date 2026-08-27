# LOST & FOUND: NIGHT SHIFT — M4-E.1 CASE + NPC DEPTH LOCK v1.0

Status: SOURCE PASS / RUNTIME QC REQUIRED
Updated: 2026-08-28

## Purpose
Deepen routine Lost & Found work after M4-E successfully stopped static case memorization.

M4-E.1 keeps the same core loop and decisions, but increases evidence cross-checking, claimant diversity, and procedural NPC variation without changing rewards, drop rates, station ownership, trading, serial/provenance, or Season 1 mystery canon.

## Case audit result
The original 15 M4-E routine archetypes remain logically usable:
- verified return;
- delayed routing scan but verified return;
- damaged barcode with matching manual serial;
- no active claimant;
- claim-tag mismatch;
- claimant cannot provide tag/receipt;
- third-party finder turn-in;
- physical-description conflict;
- claimant identity mismatch;
- duplicate active claim;
- physical tag tampering;
- cloned/duplicated tag;
- contents-description conflict;
- unsafe swollen battery isolation;
- unknown liquid leak isolation.

M4-E.1 preserves their intent while adding counter-pattern cases so one clue cannot become a universal shortcut. In particular, a claimant-name mismatch or tag mismatch is no longer automatically suspicious if official authorization/replacement records resolve the discrepancy.

## Expanded routine scenario pool
M4-E.1 adds these evidence patterns:
- documented rebooking/rerouting with matching owner + tag → RETURN;
- registered authorized collector with matching tag → RETURN;
- officially cross-linked replacement baggage tag → RETURN;
- genuine receipt from the wrong/older journey → STORE;
- family-member pickup with no recorded authorization → STORE;
- valid ownership evidence blocked by unresolved intake-routing hold → STORE;
- invalid receipt checksum tied to the visible tag → SECURITY;
- claimant carrying multiple unrelated active claim credentials → SECURITY;
- undeclared restricted sharp object found during inspection → SECURITY;
- unknown chemical odor on opening → QUARANTINE;
- unexplained rapidly rising item temperature → QUARANTINE.

Total routine evidence archetypes after the pass: 26.

## Difficulty weighting
Routine generation now has weighted tiers:
- EASY: direct verification/hold/fraud distinctions; used by the earliest routine profile slots;
- MEDIUM: introduces manual serial, routing changes, authorized collector, replacement tag and limited hazard cross-checking;
- HARD: full 26-archetype pool with more cases that require reading SCAN + TAG + OPEN/INSPECT evidence together.

The generator also heavily down-weights recently generated archetypes and recently used claimant names so candidate pools do not collapse into obvious short repetitions.

This affects evidence variety/difficulty only. Reward values and collectible drop probabilities are unchanged.

## Anti-shortcut rule
Do not teach or encode any universal shortcut such as:
- `name mismatch = SECURITY`;
- `tag mismatch = STORE`;
- `routing mismatch = STORE`;
- `hazard = SECURITY`.

The correct decision must depend on the complete evidence context.

Routine player-facing identity remains:
- ticket ID: neutral `LF-R-...`;
- title: `Property Review`;
- internal `scenarioId` stays server-side and must not appear in the HUD.

## Mystery firewall
Canonical Season 1 mystery cases remain untouched:
- Ownerless Suitcase → QUARANTINE;
- Flight 000 → QUARANTINE;
- Changing Weight → QUARANTINE;
- Double Identity → SECURITY;
- The Lost Child → SECURITY; archive/missing year 2001.

Mystery candidate probability remains at the M4-E value and progression gating remains controlled by PersonalShiftRuntime.

## NPC depth pass
`M4ENpcPolish.server.lua` remains in-engine/procedural and now expands deterministic claimant variation with:
- 9 skin-tone palettes;
- 10 outfit palettes;
- 8 accent palettes;
- 7 hair colors and 7 hair constructions;
- varied pants/shoes;
- subtle limb proportion variation;
- multiple outfit constructions (band, jacket panels, chest band, collar);
- eyebrows + mouth variation;
- occasional glasses;
- occasional scarf, bag strap, lanyard/badge, cap or wrist band;
- compact claimant nameplate retained.

No external character assets or AI-generated image assets are used.

## Mobile budget rule
NPC depth remains lightweight geometry intended for the existing 8-station target. Do not add high-poly meshes, layered-clothing dependencies, external avatar bundles, or heavy particle systems in this milestone.

## Hard locks
M4-E.1 must NOT change:
- Credits reward values;
- XP reward values;
- collectible drop probabilities;
- collection IDs or bonus-pair mapping for routine profiles;
- serial mint/provenance rules;
- trading rules;
- Personal Station ownership/isolation;
- canonical mystery evidence/outcomes;
- final supernatural explanations.

## Runtime QC after publish
1. First three jobs remain understandable but are not identical/static.
2. Later routine jobs visibly require evidence cross-checks rather than one-word scan shortcuts.
3. Authorized collector / replacement-tag RETURN cases are understandable and do not feel contradictory.
4. Old-receipt/family/no-authorization STORE cases clearly explain why release is blocked.
5. SECURITY cases contain actual fraud/security evidence rather than harmless clerical mismatch alone.
6. QUARANTINE cases contain a genuine physical safety/isolation reason.
7. Several consecutive claimants should differ in name and visible appearance.
8. `Property Review` remains neutral; internal scenario IDs never leak to the player.
9. Credits/XP/Index/Archive/serialized inventory remain intact.
10. Mystery cases retain canonical evidence/action.
11. Station A personal job/reward/next-case loop remains functional.
12. Multi-account station isolation/trade/rejoin remains deferred until a second tester is available.
