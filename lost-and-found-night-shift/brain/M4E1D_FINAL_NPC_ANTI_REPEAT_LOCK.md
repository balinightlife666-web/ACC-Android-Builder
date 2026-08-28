# LOST & FOUND: NIGHT SHIFT — M4-E.1D FINAL NPC + ANTI-REPETITION POLISH

Status: SOURCE PASS / RUNTIME QC REQUIRED
Date: 2026-08-28

## Trigger

Runtime v41 comparison showed the M4-E.1C claimant system is functionally stable and visibly varied, but two final polish issues remained:

1. claimant quality is still intentionally simpler than a player avatar and benefits from one bounded final hair/outfit polish layer;
2. identical routine property presentations can repeat too close together (observed `Black Hardcase Suitcase` on Job 1 and Job 3 of the same runtime test).

## Scope

### Routine presentation anti-repeat

- Apply after M4-E.1 case depth and before `PersonalShiftRuntime` starts.
- Preserve the original routine scenario result and difficulty tier.
- Preserve `itemId`, `collectionId`, `bonusCollectionId`, reward logic and all collection/serial rules.
- Track recent routine source profiles for 4 jobs, item families for 2 jobs, and displayed titles for 6 jobs.
- When a routine presentation repeats too soon, rotate only its presentation name and close color shade within the same canonical collection identity.
- Five routine source profiles each have bounded presentation variants.
- Canonical Season 1 mystery cases pass through untouched.

The anti-repeat layer deliberately does NOT reroll a generated case after M4-E.1 has selected its evidence scenario. This avoids changing the EASY / MEDIUM / HARD evidence distribution simply to obtain a different item skin.

### NPC final polish overlay

- Preserve M4-E.1C body construction, grounding, face orientation, eight profiles and retry/reconciliation hook.
- Run only after `NpcVisualVersion=M4E1C_NPC_V4` is present.
- Add two lightweight front hair locks and longer side depth where appropriate.
- Add small pocket/drawstring/chest/sleeve details based on claimant profile.
- Refine built-in head mesh scale slightly.
- Convert solid glasses blocks toward transparent glass so eyes remain readable.
- Stamp `NpcFinalPolishVersion=M4E1D_NPC_FINAL_V1` to prevent duplicate geometry.
- Roblox primitives/UI only; no generated images or external character assets.

## Hard Locks

Do not change:
- the 26 M4-E.1 evidence archetypes;
- EASY / MEDIUM / HARD weighting;
- mystery candidate chance;
- Season 1 mystery canon/outcomes;
- Credits or XP;
- collectible drop rates;
- Collection Index / inventory mapping;
- global serial/provenance rules;
- trading;
- station ownership/isolation;
- SCAN / TAG / OPEN / DECIDE validation.

## Runtime Acceptance

1. An exact displayed routine property title does not repeat within roughly 3–5 nearby jobs when a presentation variant is available.
2. Repeated hardcase-family jobs are visually distinguished by name/close color treatment without changing collection identity.
3. Mystery cases retain their canonical item names/colors and outcomes.
4. Claimant hair has a clearer front silhouette than v41.
5. Outfit has small readable secondary details without becoming visually noisy.
6. Glasses no longer read as opaque black rectangles covering the eyes.
7. Claimant grounding, head connection and player-facing orientation remain correct.
8. Two or more consecutive claimant profiles remain visibly distinct.
9. No duplicate final-polish geometry accumulates across retries or next-case replacement.
10. SCAN / TAG / OPEN / DECIDE remains unchanged.
11. Credits/XP/Index/Archive/serialized inventory remain unchanged.
12. Exact-source deploy receipt must match the merged M4-E.1D source before calling LIVE.

## Close Condition

If the runtime checklist above passes across approximately 8–12 jobs, close M4-E as STABLE and move the next gameplay milestone to Station Shop v1.
