# LOST & FOUND: NIGHT SHIFT — M4-E.1B NPC FACE ORIENTATION HOTFIX

Status: SOURCE PASS / RUNTIME SCREENSHOT QC REQUIRED
Date: 2026-08-28

## Runtime finding
M4-E.1A v39 proved the claimant runtime hook is active because limbs and layered clothing rendered. Screenshot QC also proved the claimant presented the back side of the head to the player, while facial detail was being built on local -Z.

## Fix
- Rotate claimant torso/head exactly once by 180 degrees around Y so local facial front points toward station +Z/player approach.
- Stamp `NpcFacingVersion=M4E1B_FACE_PLUS_Z` to prevent double rotation during retry/reconciliation.
- Replace legacy rectangular head treatment with a built-in spherical Roblox Part head.
- Rebuild readable eyes, brows, nose, mouth, hair and optional glasses/accessories after orientation is corrected.
- Keep M4-E.1A retry + reconciliation behavior.
- Roblox geometry only; no image generation or external NPC assets.

## Hard locks
Do not change case logic, 26 routine archetypes, difficulty weighting, Credits, XP, collectible drop rates, Collection Index/inventory mapping, trading, serial/provenance, station ownership/isolation, or Season 1 mystery canon.

## Runtime acceptance
1. Player sees claimant eyes/brows/nose/mouth from the station work area.
2. Head no longer reads as a blank rectangular block.
3. Hair is visible from the player-facing side.
4. Retry/reconciliation never flips the claimant a second time.
5. Next-case claimant receives the same orientation + visual pass.
6. SCAN/TAG/OPEN/DECIDE remains unchanged.
7. Exact-source deployment receipt must match the merged hotfix source before calling LIVE.
