# LOST & FOUND: NIGHT SHIFT — M5-A.2 STATION SKIN PREVIEW LOCK

Status: SOURCE PASS / RUNTIME QC REQUIRED
Date: 2026-08-28

## Goal

Let players inspect earnable station cosmetics before buying them.

Flow:

`OPEN STATION SHOP → TRY / COBA → TEMPORARY STATION RECOLOR → NO CREDITS SPENT → CLOSE SHOP → RESTORE PERSISTED EQUIPPED SKIN`

## Scope

Preview is available only for the current Station Shop v1 earnable catalog:
- `STANDARD_OPS`
- `INDUSTRIAL_SHIFT`
- `RETRO_AIRPORT`
- `BLACK_OPS`

Premium/event registry entries remain deferred and are not exposed by preview mode.

## Server authority

`src/server/StationSkinPreviewService.server.lua` owns preview requests.

Server validates:
- player persistence is ready;
- requested skin exists;
- requested skin is FREE or CREDITS acquisition;
- player has a current personal station;
- station `OwnerUserId` matches the player.

Preview applies only visual palette roles through `PersonalStationWorld.ApplySkin`.

## Persistence firewall

Preview MUST NOT:
- add the skin to `ownedSkins`;
- change `equippedSkin`;
- spend Credits;
- increment `creditsSpent`;
- write a cosmetic purchase to DataStore;
- grant any collectible, reward, XP, case advantage or farming advantage.

The persisted station profile remains the only ownership/equip authority.

On shop close, server restores the currently persisted equipped skin.

## Decision-color firewall

After every temporary preview apply, semantic decision colors are restored:
- RETURN = green
- STORE = cyan/blue
- QUARANTINE = amber/yellow
- SECURITY = red

Station preview must never recolor decision meaning.

## Client UX

`src/client/StationSkinPreview.client.lua` adds a narrow `TRY` / `COBA` button to each current earnable shop row.

Mobile rules:
- no extra popup;
- no larger Station Shop panel;
- preview button fits between skin information and BUY/EQUIP action;
- Indonesian locale shows `COBA`;
- English fallback shows `TRY`;
- status explicitly says preview is temporary and no Credits were spent.

## HARD LOCKS

M5-A.2 must not change:
- Station Shop prices or purchase/equip authority;
- Credits earning or reward values;
- XP;
- routine case archetypes/difficulty;
- Season 1 mystery canon/outcomes;
- collectible drop rates;
- Collection Index / Archive;
- serialized inventory/global serial/provenance;
- trading;
- personal station ownership/isolation;
- SCAN/TAG/OPEN/DECIDE validation;
- EN/ID localization foundation;
- decision colors.

## Runtime acceptance

1. `COBA` / `TRY` appears beside each FREE/CREDITS Station Shop skin.
2. Tapping preview immediately recolors only the player's station cosmetic roles.
3. Previewing an unowned skin costs exactly 0 Credits.
4. Preview does not grant ownership.
5. Closing Station Shop restores the persisted equipped skin.
6. Previewing another skin replaces the previous temporary preview.
7. RETURN/STORE/QUARANTINE/SECURITY colors remain correct throughout preview.
8. Rejoin always loads the persisted equipped skin, never the temporary preview.
9. Purchase/equip flow from M5-A remains unchanged.
10. Exact deploy receipt `sourceCommit` must equal the merged M5-A.2 source before calling LIVE.
