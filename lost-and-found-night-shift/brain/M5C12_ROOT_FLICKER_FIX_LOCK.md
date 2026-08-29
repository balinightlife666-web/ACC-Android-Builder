# LOST & FOUND: NIGHT SHIFT — M5-C.1.2 Root Flicker Fix Lock

Status: implementation branch only until exact deploy receipt matches merged source.

Runtime QC on v54 still showed displayed collectibles alternating scale. Root cause: M5-C.1 and M5-C.1.1 both use `ScaleTo(1)` as an intermediate normalization state, while M5-C.1 also runs a destructive 2.5-second reconciliation loop. The intermediate state can replicate and become visible.

M5-C.1.2 locks:
- M5-C.1 and M5-C.1.1 are retired as active visual authorities at runtime;
- exactly one visual presentation authority controls fitted scale/pose;
- never call `ScaleTo(1)` during live normalization;
- derive target scale from current model scale + current bounding box and apply one final scale write;
- no destructive periodic visual loop;
- react only to model/folder creation or actual legacy writes, plus a non-mutating binding safety scan;
- preserve per-family pose, plinth grounding, teddy proportions, rarity hierarchy and fixed nameplates;
- no generated images, decals, external textures or external assets;
- preserve five-slot selection/persistence/trade cleanup, Credits/XP, Station Shop, case logic/difficulty/answers, Season 1 mystery canon, drop rates, Collection Index history, inventory ownership, mint counters, immutable instanceId/serial/provenance, TradeService, station isolation, SCAN/TAG/OPEN/DECIDE validation, EN/ID foundation and decision colors.

Runtime acceptance: displayed collectibles remain the same visible scale/pose for at least 60 seconds unless ownership or slot selection actually changes.
