# LOST & FOUND — M5-D PREMIUM STATION STRUCTURE LOCK

Status: SOURCE IMPLEMENTATION

Goal: paid Station Shop themes must read as different physical station silhouettes, not palette swaps.

Hard locks:
- Army Field stays 12,000 Credits.
- Sakura Night stays 16,000 Credits.
- Street Graffiti stays 20,000 Credits.
- Free palette skins remain free.
- Do not change Credits earning, XP, collection drops, serial/provenance, trading, station ownership, case logic, decision colors, mystery canon, or data stores.
- M5-B.2.1 remains sole five-slot rack geometry authority. Do not move/resize/rebuild the rack.
- M5-C.1.3 remains stable showcase lifecycle authority. Do not destroy/recreate collectible models.
- Structural theme pieces are presentation-only, anchored, non-colliding, non-touching, non-querying.

Visual direction:
- ARMY_FIELD: reinforced field-command cage, diamond-plate canopy, armored console shells, tactical header.
- SAKURA_NIGHT: timber rack surround, layered eaves, restrained lantern glow, wood/slatted console shells.
- STREET_GRAFFITI: asymmetrical scaffold cage, offset urban awning, cyan/magenta accents, metal console cage.

Preview requirement:
StationSkinPreviewService already applies temporary skins to the physical station. M5-D listens to SkinId, so structural overlays must appear/disappear in preview without buying, spending, or persisting.

Acceptance:
1. From several studs away, the three paid themes are distinguishable by silhouette before reading color.
2. Switching to a free palette removes M5-D structural overlay cleanly.
3. Five-slot rack position/size is unchanged.
4. Decision console interaction surfaces/colors remain functional and unchanged.
5. No collision or movement obstruction is introduced.
6. No gameplay/economy state is mutated.
