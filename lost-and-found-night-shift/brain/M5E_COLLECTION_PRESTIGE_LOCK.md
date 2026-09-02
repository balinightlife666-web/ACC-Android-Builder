# LOST & FOUND: NIGHT SHIFT — M5-E COLLECTION PRESTIGE LOCK

Status: SOURCE CANDIDATE
Phase: M5-E — Collection Prestige & Showcase Polish

## Purpose
Make serialized collectibles feel more valuable in the public five-slot station showcase without changing the collectible itself or any economy/gameplay authority.

## Presentation language
- Collectible color/material remains realistic and independent from rarity.
- M5-C.4 remains the rarity-language layer.
- M5-E adds restrained gallery polish on top of M5-C.4:
  - Season/edition badge on the physical nameplate.
  - Thin gallery edge framing around the plinth.
  - COMMON: neutral front edge only.
  - UNCOMMON: restrained silver full edge frame.
  - RARE: cobalt metal edge frame.
  - EPIC: violet metal edge frame.
  - ANOMALY: cold metal frame + static cold spotlight.
  - SECRET: black/gold M5-C.4 presentation + gold metal frame + static warm spotlight.

## Lifecycle hard lock
M5-C.1.3 remains the sole stable collectible lifecycle authority.
M5-E must never Destroy, recreate, ScaleTo, PivotTo, recolor, or rematerial the stable collectible models.
M5-E may only own objects prefixed `M5E_` and the `M5EEdition` TextLabel inside the M5-C.4 nameplate GUI.

## No flicker rule
- Event-driven only.
- No periodic loop.
- No pulsing/tween loop.
- No repeated model transform writes.
- Slot refresh only on relevant child/attribute changes.

## Economy/canon firewall
M5-E must not modify:
- Credits or XP.
- Drop chance or rarity assignment.
- Collection Index mapping.
- Inventory ownership.
- Serial/global mint/provenance.
- Trading.
- Station ownership.
- Case decisions or mystery canon.
- M5-A theme pricing.

## Deployment rule
Source merge is not LIVE.
While the previous publisher accounts are limited, publish LOST & FOUND only through the temporary Ardarawk / ACC-Roblox-maps route using `ROBLOX_OPEN_CLOUD_MASTER_V2`, then verify an exact Roblox deploy receipt before calling the phase LIVE.
