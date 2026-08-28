# LOST & FOUND: NIGHT SHIFT — M5-A.3 PREMIUM STATION THEME REWORK LOCK

Status: SOURCE PASS / RUNTIME QC REQUIRED
Date: 2026-08-28

## Goal

Station cosmetics must feel worth buying. Simple palette swaps are free. Paid skins must visibly transform the personal station beyond neon color changes.

## Product rule

### Free palette variants
- STANDARD_OPS
- INDUSTRIAL_SHIFT
- RETRO_AIRPORT
- BLACK_OPS

These are cosmetic color variants and cost 0 Credits.

### Paid full themes
- ARMY_FIELD — 12,000 Credits
- SAKURA_NIGHT — 16,000 Credits
- STREET_GRAFFITI — 20,000 Credits

Paid themes must alter multiple visual layers: floor/wall treatment, material treatment, signage/markings, themed props/decor and lighting palette.

No image generation and no external texture dependency. Theme art is Roblox in-engine/procedural only.

## Theme requirements

### ARMY_FIELD
- olive / khaki station palette;
- procedural camouflage patches on floor/back wall;
- military stencil signage / hazard chevrons;
- small crate-like decorative props;
- industrial material treatment.

### SAKURA_NIGHT
- dark charcoal + sakura pink palette;
- procedural branch geometry on back wall;
- multiple petal geometry accents on wall/floor;
- Japanese-inspired trim/sign treatment;
- warm pink station light treatment.

### STREET_GRAFFITI
- concrete/urban palette;
- procedural graffiti-style text/sign layers (Roblox TextLabel only);
- colored wall strokes / floor lane marks;
- urban barrier/crate details;
- neon accent lighting.

## Proper preview mode

TRY / COBA must no longer restore simply because the shop panel hides.

Flow:
`SHOP → TRY/COBA → SHOP HIDES → PLAYER CAN WALK AROUND STATION → PREVIEW HUD → BACK TO SHOP or END PREVIEW`

- BACK TO SHOP reopens shop while keeping preview active.
- END PREVIEW restores persisted equipped skin.
- rejoin never persists preview.
- preview costs 0 Credits and grants no ownership.

## Persistence / economy firewall

M5-A.3 must not change:
- Credits earning values;
- XP;
- case difficulty/archetypes;
- Season 1 mystery canon;
- collectible drop rates;
- Collection Index / Archive;
- inventory instance ownership;
- serial / provenance;
- trading;
- personal station ownership/isolation;
- SCAN/TAG/OPEN/DECIDE validation;
- decision semantic colors.

Existing paid palette ownership remains valid, but the palette variants are free going forward. No automatic historical refund is performed by this visual pass.

## Mobile/performance

- procedural decoration is static anchored geometry;
- non-colliding theme decor;
- no Humanoids / animations / external images;
- destroy previous ThemeDecorations before applying another theme;
- target lightweight decoration count per station;
- decision colors remain hard locked.

## Runtime acceptance

1. Old four palette variants show as FREE / owned.
2. ARMY_FIELD visibly changes floor/wall/decor, not only light color.
3. SAKURA_NIGHT visibly shows branch/petal motif.
4. STREET_GRAFFITI visibly shows wall/floor urban markings.
5. TRY/COBA closes the shop but leaves preview active.
6. Player can walk around and inspect the station during preview.
7. BACK TO SHOP preserves the temporary preview.
8. END PREVIEW restores persisted equipped skin.
9. Preview spends 0 Credits and grants no ownership.
10. Purchase/equip persists paid full themes normally.
11. RETURN/STORE/QUARANTINE/SECURITY colors remain green/cyan/amber/red.
12. Exact deploy receipt sourceCommit must equal the merged M5-A.3 source before calling LIVE.
