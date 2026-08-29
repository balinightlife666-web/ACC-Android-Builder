# LOST & FOUND: NIGHT SHIFT — M5-C.1.3 Stable Showcase Lock

Status: implementation branch only until exact deploy receipt matches merged source.

Runtime QC on v55 showed worse blinking. Root cause is now confirmed broader than presentation scale: multiple legacy authorities are fighting over the same showcase. `PersonalCollectionShowcase` destroys/recreates `DisplayedItems` during refresh; `M5B2FiveSlotShowcase` periodically rescales/re-pivots and recreates slots 4–5; `M5B1ShowcaseRackLayout` rewrites the rack back to three slots and rescales slots 1–3; and core `PersonalShiftRuntime.publicShowcaseFor()` still destroys/rebuilds its automatic top-three `DisplayedItems` on collection sync/mint.

M5-C.1.3 hard locks:
- `M5B1ShowcaseRackLayout.server.lua`, `M5B2FiveSlotShowcase.server.lua`, `PersonalCollectionShowcase.server.lua`, `M5C1ShowcasePresentation.server.lua`, `M5C11ShowcasePresentationAuthority.server.lua`, and `M5C12RootFlickerFix.server.lua` are retired as active authorities;
- `M5B21AllStationsFiveSlot.server.lua` remains the only five-slot rack geometry authority;
- `M5C13StableShowcaseService.server.lua` is the only selection/persistence/visible-model/presentation authority;
- visible models live in `M5C13StableItems`, separate from legacy `DisplayedItems`;
- legacy `PersonalShiftRuntime` automatic top-three preview creation is suppressed at the shared factory boundary only when parent is the station `PublicShowcase/DisplayedItems`; its core gameplay/inventory logic remains untouched;
- unchanged serialized instance in unchanged slot causes zero Destroy, ScaleTo, or PivotTo writes;
- model rebuild is allowed only when slot selection changes, ownership/trade invalidates an item, station changes, or player leaves;
- all scale/refinement/pose fitting is completed off-world before the visible model is parented into Workspace;
- preserve five slots, teddy refinement, rarity plinth/glow/bar, physical name + rarity + immutable serial plate;
- no generated images, decals, external textures, or external assets.

Gameplay/economy/canon firewall remains unchanged: Credits/XP, Station Shop, case logic/difficulty/answers, Season 1 mystery canon, drop chances, Collection Index history, inventory ownership, global mint counters, immutable instanceId/serial/provenance, TradeService rules, station isolation, SCAN/TAG/OPEN/DECIDE validation, EN/ID localization foundation, and decision colors are locked.

Runtime acceptance: after rejoin, a populated five-slot rack must remain visually stable for at least 60 seconds while idle, including across the 15-second ownership reconciliation interval. No size jump, disappearance/reappearance, duplicate legacy top-three overlay, or 3-slot rack rewrite is acceptable.
