# LOST & FOUND: NIGHT SHIFT — M5-A STATION SHOP v1 LOCK

Status: SOURCE PASS / RUNTIME QC REQUIRED
Date: 2026-08-28

## Entry condition

M4-E case/NPC/localization foundation is treated as STABLE for forward development. M5-A adds the first intentional Credits sink without changing the deduction loop.

## Goal

Give Credits a persistent, visible purpose through earnable personal-station cosmetics while keeping the game non-pay-to-win.

Flow:

`WORK SHIFT → EARN CREDITS → OPEN STATION SHOP → BUY SKIN → EQUIP → PERSONAL STATION RECOLORS → OWNERSHIP PERSISTS`

## Earnable Station Shop v1 catalog

Source authority remains `src/shared/StationSkinRegistry.lua`.

- `STANDARD_OPS` — FREE / default
- `INDUSTRIAL_SHIFT` — 8,000 Credits
- `RETRO_AIRPORT` — 18,000 Credits
- `BLACK_OPS` — 35,000 Credits

Existing registry entries for `LUXURY_EXECUTIVE`, `HALLOWEEN_2026`, and `CHRISTMAS_2026` are NOT sold by Station Shop v1. Premium/event acquisition remains deferred until explicitly designed.

## Server authority

`src/server/StationShopService.server.lua` owns shop requests.

The server must validate:
- persistence ready;
- requested skin exists;
- Credits skins only may be bought in v1;
- current server Credits balance is sufficient;
- already-owned skins cannot charge again;
- only owned skins may be equipped;
- one shop mutation per player at a time.

Client UI is presentation only and never decides ownership, balance or equipped state.

## Persistence

Station cosmetic ownership stays inside the existing canonical player payload:

- DataStore: `LostAndFound_PlayerData_v1`
- `stationProfile.equippedSkin`
- `stationProfile.ownedSkins`

`PlayerDataStore` now maintains a station-profile session cache so normal runtime autosaves cannot overwrite a newly purchased/equipped skin with stale profile state.

Station Shop purchase/equip commits persist the profile immediately. Credits spent are recorded in the existing `creditsSpent` economy metric.

No separate shadow cosmetic DataStore is introduced.

## Station application

On successful purchase/equip, and again after join/station assignment:
- resolve the player's temporary A-H station;
- verify `OwnerUserId` matches the player;
- apply the selected palette through `PersonalStationWorld.ApplySkin`;
- set local session attribute `LostFoundStationSkin`.

Physical A-H slots remain temporary. The cosmetic follows the player profile, not the station letter.

## Decision-color firewall

Hard-locked decision colors remain:
- RETURN = green
- STORE = cyan/blue
- QUARANTINE = amber/yellow
- SECURITY = red

`DecisionColorLock.server.lua` marks decision surfaces as `decisionColor`, so station palette application must not recolor decision meaning.

## UI / mobile

`src/client/StationShop.client.lua` adds a compact top-right Station Shop button and constrained center panel.

The panel shows only FREE/CREDITS skins in v1, including:
- skin name;
- Credits price;
- owned/equipped state;
- BUY or EQUIP action;
- current Credits.

The shop is English/Bahasa Indonesia aware, following the M4-E.2 player-locale foundation.

## Economy rules

- Credits remain non-transferable soft currency.
- Station skins are cosmetic only.
- Buying/equipping a skin must not change Credits earning rate, XP, case rewards, case difficulty, collectible odds or mystery frequency.
- No SECRET/ANOMALY instance may be bought from the station shop.
- No Robux purchase is introduced in M5-A.
- No off-platform payment.

## HARD LOCKS

M5-A must not change:
- 26 M4-E.1 routine evidence archetypes;
- EASY / MEDIUM / HARD weighting;
- Season 1 mystery canon or outcomes;
- mystery candidate chance;
- reward values;
- collectible drop rates;
- Collection Index identity;
- serialized inventory / global serial / provenance;
- trading;
- station ownership/isolation;
- SCAN / TAG / OPEN / DECIDE validation;
- decision colors.

## Runtime acceptance

1. Station Shop opens on mobile without blocking movement after close.
2. Standard Ops shows as owned/default.
3. Industrial Shift shows exactly 8,000 Credits; Retro Airport 18,000; Black Ops 35,000.
4. Insufficient Credits cannot buy and no Credits are deducted.
5. Successful purchase deducts exactly the listed price once.
6. Purchased skin auto-equips and visibly recolors only cosmetic station roles.
7. RETURN/STORE/QUARANTINE/SECURITY colors remain hard-locked after skin apply.
8. Switching between owned skins costs 0 Credits.
9. Already-owned skin cannot be charged twice.
10. Purchased ownership/equipped skin survives rejoin.
11. Physical station letter may change while owned/equipped skin follows the player.
12. Credits/XP/Index/Archive/serialized inventory/trading remain intact.
13. Indonesian Roblox locale shows localized Station Shop action language; English remains fallback.
14. Exact deploy receipt `sourceCommit` must equal the merged M5-A source before calling LIVE.

## Close condition

After one successful buy/equip/rejoin test and one insufficient-Credits test, M5-A Station Shop v1 may be marked STABLE. Next candidate milestone: manual featured-showcase selection.
