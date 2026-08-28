# LOST & FOUND: NIGHT SHIFT — M5-A.1 HUD STACK HOTFIX

Status: SOURCE PASS / RUNTIME QC REQUIRED
Date: 2026-08-28

## Runtime finding

Roblox v44 showed that `StationShopButton` and Collection `IndexButton` shared the same top-right vertical slot. The Station Shop therefore visually covered the Collection Index even though Index logic/data remained intact.

Existing utility positions:
- Credits: Y 18
- Index: Y 56
- Archive: Y 94
- Trade: Y 132

M5-A initially placed Station Shop at Y 54, colliding with Index.

## Fix

Add `src/client/M5A1HudStackHotfix.client.lua`.

- Wait for `LostAndFoundStationShop/StationShopButton`.
- Move Station Shop to Y 170, directly below Trade.
- Stamp `HudStackSlot=SHOP_AFTER_TRADE` for runtime inspection.
- No changes to Collection Index state, Archive, Trade, Station Shop purchase logic, or core HUD data.

Final intended stack:
`CREDITS → INDEX → ARCHIVE → TRADE → STATION SHOP`

## HARD LOCKS

Do not change:
- case selection/difficulty;
- Season 1 mystery canon/outcomes;
- Credits earning or XP rewards;
- Station Shop prices/ownership/persistence;
- collectible drop rates;
- Collection Index identity/data;
- Archive progression;
- trading;
- station ownership/isolation;
- serial/provenance;
- decision validation or colors;
- EN/ID localization behavior.

## Runtime acceptance

1. INDEX is visible again under Credits.
2. Archive remains below Index.
3. Trade remains below Archive.
4. Station Shop appears below Trade with no overlap.
5. All five top-right utilities are tappable on mobile.
6. Index still opens the Collection popup and count remains correct.
7. Station Shop still opens/purchases/equips normally.
8. Exact deploy receipt `sourceCommit` must equal the merged M5-A.1 source before calling LIVE.
