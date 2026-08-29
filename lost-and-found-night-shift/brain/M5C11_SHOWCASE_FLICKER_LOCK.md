# LOST & FOUND — M5-C.1.1 SHOWCASE FLICKER LOCK

Status: RUNTIME HOTFIX

Runtime QC on v53 showed displayed collectibles, especially Cream Memory Bear, oscillating between two visible scales/poses.

Root cause: M5-C.1 presentation normalization and older M5-B / M5-B.2 inventory reconciliation both write model scale/pivot. Older reconciliation remains required for inventory ownership, showcase persistence and trade cleanup, but it must not remain the visible presentation authority.

M5-C.1.1 adds an event-driven presentation authority that immediately restores the fitted M5-C.1 pose after legacy ScaleTo/PivotTo writes. It also binds newly recreated DisplayedItems models so slots 1-5 stabilize without waiting for the 2.5-second M5-C.1 self-heal.

No image generation, decals, external textures or external assets.

HARD LOCKS PRESERVED:
- five-slot selection/persistence/trade cleanup
- Collection Index history
- inventory ownership
- immutable instanceId / serial / provenance
- mint counters and drop rates
- Credits / XP / Station Shop
- case logic, difficulty and answers
- Season 1 mystery canon
- station ownership/isolation
- SCAN/TAG/OPEN/DECIDE server validation
- EN/ID localization foundation
- decision colors

Runtime acceptance: items remain at one stable fitted scale/pose for at least 30 seconds across legacy periodic reconciliation; no visible large/small oscillation; rejoin and showcase selection still work.
