# LOST & FOUND: NIGHT SHIFT — M5-C.4 RARITY DISPLAY LANGUAGE LOCK

Status: ACTIVE / VISUAL LANGUAGE LOCK

## Purpose
Make collectible rarity immediately readable from the five-slot public showcase without recoloring the collectible itself into unrealistic rarity colors.

## Permanent direction
- Collectible body/material stays realistic and type-authentic.
- Rarity is communicated by display infrastructure: plinth surface, accent rail, nameplate, trim and restrained halo/light.
- Do not use RETURN green, QUARANTINE amber/yellow, or SECURITY red as rarity language.

## Rarity language
- COMMON: neutral charcoal gallery plinth, grey/white nameplate, non-emissive neutral rail. No halo.
- UNCOMMON: dark-metal plinth, restrained silver trim/rail. No halo.
- RARE: deep cobalt/blue rail and trim. No halo.
- EPIC: violet rail/trim + static violet under-plinth halo.
- ANOMALY: cold-white + icy-cyan rail/trim + static cold halo. No aggressive flicker/pulse in this pass.
- SECRET: near-black metal presentation + gold rail/trim + restrained gold halo/top light.

## Architecture locks
- M5-C.1.3 remains sole stable showcase lifecycle authority.
- M5-C.4 must not ScaleTo, PivotTo, destroy/recreate, recolor, resize, or reposition collectible models.
- M5-C.4 uses its own `M5C4_*` display objects and only hides superseded rarity UI/rails while an occupied stable slot is active.
- Event-driven only; no periodic polling loop.
- Same exact serialized instance rules, trade cleanup, station ownership, persistence and five-slot geometry remain unchanged.
- Oxford external asset M5-C.3 remains independent and unchanged.

## Economy/canon hard locks
No changes to Credits, XP, drop chances, rarity assignment, mint counters, Collection Index, inventory ownership, immutable instanceId/serial/provenance, trading rules, case logic, decision answers, station isolation, localization, or Season 1 mystery canon.

## Image rule
No generated images, decals, or rarity textures are required by this pass.
