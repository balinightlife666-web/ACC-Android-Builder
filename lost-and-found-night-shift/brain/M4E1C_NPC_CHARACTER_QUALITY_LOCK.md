# LOST & FOUND: NIGHT SHIFT — M4-E.1C NPC CHARACTER QUALITY PASS

Status: SOURCE PASS / RUNTIME SCREENSHOT QC REQUIRED
Date: 2026-08-28

## Runtime finding
M4-E.1B v40 passed runtime hook and facing QC: claimant face is now visible and oriented toward the player. Screenshot comparison against a normal player avatar still shows an unacceptable quality gap. The claimant also reveals two structural problems inherited from the original marker-based mannequin: shrinking the torso/head without recomputing vertical placement creates a floating-head look, while generated leg lengths can extend below the station floor.

## Scope
This is a narrow NPC character-quality pass only.

- Preserve the resilient retry + reconciliation runtime hook.
- Preserve the v40 player-facing orientation lock.
- Recompute body placement from the original claimant ground reference before resizing.
- Reposition torso, legs, shoes, neck and head as one coherent grounded character.
- Replace the oversized spherical head with Roblox built-in `MeshType.Head` shaping.
- Replace floating primitive facial blocks with a clean in-engine `SurfaceGui` face.
- Add ears and reduce head/body ratio.
- Add eight deterministic claimant character presets:
  - URBAN_JACKET
  - TRAVEL_HOODIE
  - SMART_COAT
  - CASUAL_LAYER
  - MID_LENGTH
  - BUN_COAT
  - CAP_VEST
  - LONG_LAYER
- Give presets visibly different hair silhouettes and layered outfit construction.
- Keep subtle body width/height/stance variation.
- Keep optional glasses and lightweight accessories.
- Roblox primitives, built-in mesh and UI only; no external NPC assets and no image generation.

## Mobile budget
Target remains eight active claimant stations. Character construction is intentionally static/anchored and avoids Humanoids, animations, external meshes and texture downloads. Presets reuse a bounded set of primitive parts and one face SurfaceGui per active claimant.

## Hard locks
Do not change:
- 26 M4-E.1 routine evidence archetypes;
- routine difficulty weighting;
- Season 1 mystery canon/outcomes;
- Credits or XP;
- collectible drop rates;
- Collection Index / inventory mapping;
- trading;
- serial/provenance rules;
- station ownership/isolation;
- SCAN / TAG / OPEN / DECIDE loop.

## Runtime acceptance
1. Claimant feet sit on/near the claimant-zone floor; no obvious below-floor legs.
2. Head connects naturally to the torso; no floating-head gap.
3. Head reads closer to a Roblox human head than a sphere/mannequin block.
4. Face is clean and readable from the station work area.
5. Hair creates a visible silhouette around the head.
6. Outfit has visible layering rather than one flat torso block.
7. Two or more consecutive claimants visibly differ in character profile.
8. Claimant remains lighter/simpler than a player avatar but no longer looks placeholder-grade beside one.
9. Next-case replacement receives the same quality pass with no duplicate geometry.
10. SCAN/TAG/OPEN/DECIDE and all economy/collection systems remain unchanged.
11. Exact-source deployment receipt must match the merged M4-E.1C source before claiming LIVE.
