# LOST & FOUND: NIGHT SHIFT — M5-B PERSONAL COLLECTION SHOWCASE v1

Status: SOURCE IMPLEMENTED / RUNTIME QC REQUIRED
Date: 2026-08-28

## Goal

Turn the existing three-shelf station display into a player-curated prestige feature.

Flow:

`INDEX → SHOWCASE / PAJANGAN → CHOOSE SLOT 1/2/3 → CHOOSE OWNED SERIALIZED INSTANCE → SAVE → PUBLIC 3D DISPLAY AT PERSONAL STATION`

## Product lock

- Maximum 3 displayed serialized inventory instances.
- Nearby players can see the replicated 3D display.
- Each displayed item shows its item name, rarity, and immutable serial.
- Display selection does not change Collection Index discovery history.
- Display selection does not grant ownership, duplicate an item, mint a new item, or change provenance.
- Trading remains the only supported same-server ownership transfer path.

## Default behavior

For a player with no saved M5-B showcase profile, the first sync seeds up to three currently persisted owned instances, prioritizing higher rarity and then lower serial number while preferring different collection identities first.

After initialization, player choice is authoritative. Clearing a slot keeps it empty until the player chooses another item.

## Persistence

Showcase selection is intentionally stored separately in:

`LostAndFound_Showcase_v1`

Reason:
- do not modify canonical serialized inventory payload;
- do not entangle showcase choices with Station Shop cosmetic profile;
- Station Shop purchases/equip changes cannot erase showcase selections;
- showcase remains presentation-only.

Selection records store only the three selected `instanceId` values plus version/timestamp.

Canonical ownership remains in:

`LostAndFound_PlayerData_v1.inventory`

The showcase service must verify current ownership against that canonical persisted inventory before accepting or rendering a selection.

## Trade / ownership firewall

A selected instance that is no longer present with `currentOwnerUserId == player.UserId` is automatically removed from that player's showcase selection during ownership reconciliation.

TradeService persists committed trades immediately. M5-B rechecks persisted ownership periodically and also re-applies curated display after the legacy M4-D automatic showcase rebuild runs.

Trading away a displayed item therefore does NOT:
- preserve a fake copy on the old owner's shelf;
- grant remint rights;
- change Collection Index discovery history;
- alter immutable serial/provenance.

## Existing M4-D compatibility

M4-D already owns:
- `PublicShowcase`
- three physical shelf anchors named `DisplayAnchor1..3`
- a legacy automatic top-three renderer.

M5-B reuses those physical anchors. It does not rebuild station geometry.

When M4-D creates its automatic `DisplayedItems` folder during a collection sync, M5-B waits for that synchronous build to finish and replaces only that presentation folder with the curated selection.

## UI

The manager is entered from the Collection Index popup through:
- English: `SHOWCASE`
- Indonesian: `PAJANGAN`

The manager contains:
- SLOT 1 / SLOT 2 / SLOT 3
- serialized owned inventory list
- name
- rarity
- serial
- SELECT / PILIH
- CLEAR SELECTED SLOT / KOSONGKAN SLOT

No extra permanent top-right HUD button is added.

## Persisted-inventory note

M5-B v1 validates against canonical persisted inventory. A collectible minted only moments ago may not appear in the manager until the normal player inventory save has completed. This is preferable to trusting client claims or weakening server ownership authority.

## HARD LOCKS

M5-B must not change:
- Credits balance or earning;
- XP;
- Station Shop prices/themes/ownership;
- routine case logic/difficulty;
- Season 1 mystery canon/outcomes;
- collectible drop chances;
- mint counters;
- immutable `instanceId` / serial / global mint number;
- provenance;
- Collection Index historical discovery;
- TradeService ownership transfer rules;
- station A-H ownership/isolation;
- SCAN / TAG / OPEN / DECIDE validation;
- EN/ID localization foundation;
- decision colors.

## Runtime acceptance

1. INDEX contains SHOWCASE / PAJANGAN entry.
2. Showcase manager lists currently persisted owned serialized items.
3. Player can choose one item for each of three slots.
4. Same instance cannot occupy multiple slots; selecting it again moves it.
5. Choice persists after rejoin.
6. Chosen item is visible as a replicated 3D collectible on the correct shelf.
7. Label exposes item name + rarity + serial.
8. Another nearby player can see the station display.
9. Clearing a slot removes only the display, not inventory ownership.
10. Trading away a displayed instance automatically removes the old owner's invalid display after ownership reconciliation.
11. Collection Index remains discovered after trade.
12. No Credits, XP, drop rates, serial/provenance, case logic, or station isolation changes.
13. Exact deploy receipt `sourceCommit` must equal the merged M5-B source before calling LIVE.
