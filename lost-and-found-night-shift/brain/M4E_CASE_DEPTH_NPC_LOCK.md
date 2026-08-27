# LOST & FOUND: NIGHT SHIFT — M4-E CASE DEPTH + NPC VARIATION LOCK v1.0

Status: ACTIVE
Updated: 2026-08-28

## Purpose
Stop experienced players from solving routine work by memorising static case IDs/titles, while making the Lost & Found desk feel populated by varied claimants.

## Anti-memorization rule
Routine gameplay must be solved from evidence, not from a known case name or number.

Runtime routine cases therefore use:
- neutral ticket IDs (`LF-R-...`);
- neutral title `Property Review`;
- variable owner / claimant names;
- variable tags, flights, weights and contents;
- multiple evidence scenarios whose correct action can be RETURN, STORE, SECURITY or QUARANTINE;
- server-generated combinations from routine item profiles.

Do not expose internal scenario names such as `tag_mismatch_store` or `identity_mismatch_security` to the player HUD.

## Routine scenario pool v1
Current evidence archetypes include:
- fully verified return;
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

These combine with five existing normal item/collection profiles and a broad claimant-name pool, producing many runtime combinations without inventing new collectible IDs for every job.

## Mystery firewall
Season 1 mystery cases remain canonical and must NOT be procedurally rewritten:
- Ownerless Suitcase — QUARANTINE;
- Flight 000 — QUARANTINE;
- Changing Weight — QUARANTINE;
- Double Identity — SECURITY;
- The Lost Child — SECURITY, archive/missing year 2001.

Mystery cases remain progression-gated. They are intentionally reduced as routine candidates so they feel like incidents rather than repetitive daily work.

Exact supernatural explanations remain CANON UNKNOWN where already locked.

## Collection compatibility
Routine generation reuses the five established normal collection/bonus pairs. It does not create replacement copies automatically.

Collection ownership still follows:
`PERSONAL CASE → PERFECT → SERVER DROP ROLL → GLOBAL SERIAL MINT`

Collection Index remains historical discovery. Inventory Instance remains current ownership.

## NPC visual variation
`M4ENpcPolish.server.lua` adds lightweight procedural claimant variation using Roblox geometry only:
- multiple skin-tone palettes;
- outfit/accent variation;
- hair variation;
- arms and legs instead of torso/head-only mannequin;
- simple facial features;
- occasional glasses;
- compact world-space claimant nameplate.

No image generation or external character asset dependency is introduced.

NPC visual variation must stay lightweight enough for the initial 8-station mobile target.

## Hard locks
- no reward-rate change in M4-E;
- no Credits economy change;
- no trading change;
- no serial/provenance change;
- no station ownership change;
- no mystery canon rewrite;
- no AI-generated image assets.

## Runtime QC
After publish:
1. routine HUD should show neutral `Property Review`, not answer-revealing names like `Tag Mismatch`;
2. several consecutive routine jobs should vary names/tags/flights/evidence;
3. correct decisions should not follow one memorisable repeating order;
4. NPCs should visibly vary beyond the old torso/head mannequin;
5. existing Credits/XP/Index/Archive/serial inventory must remain intact;
6. mystery cases must retain canonical evidence/action when they occur;
7. personal Station A job flow and reward loop must remain functional.
