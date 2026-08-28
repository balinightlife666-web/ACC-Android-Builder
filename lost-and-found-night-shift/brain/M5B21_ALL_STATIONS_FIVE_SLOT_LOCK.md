# LOST & FOUND: NIGHT SHIFT — M5-B.2.1 ALL-STATIONS FIVE-SLOT RACK LOCK

Status: ACTIVE

Runtime QC found that the owner's occupied station upgraded to the five-slot M5-B.2 rack, while other/vacant stations could still retain the old three-slot M5-B.1 rack. Root cause: M5-B.2 layout binding was player/current-station driven instead of world/station driven.

Fix scope is presentation-only:
- Every Station A-H must have the same five-slot large upper-right/back-wall rack whether vacant or occupied.
- Occupied stations still render only their owner's server-validated collectible selections.
- Vacant stations show five empty physical slots.
- Preserve large rack size, fixed physical info plates, and no floating overlapping labels.
- Roblox in-engine geometry/UI only. No generated images or external textures.

Do not change case logic/difficulty/answers, mystery canon, Credits/XP, Station Shop, drop rates, Collection Index history, inventory ownership, immutable instanceId/serial/provenance, mint counters, TradeService, station ownership/isolation, SCAN/TAG/OPEN/DECIDE validation, EN/ID foundation, or decision colors.

Exact-source deploy receipt required before LIVE claim.
