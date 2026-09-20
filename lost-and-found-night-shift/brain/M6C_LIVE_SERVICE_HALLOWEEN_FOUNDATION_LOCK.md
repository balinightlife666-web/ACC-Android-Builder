# LOST & FOUND: NIGHT SHIFT — M6-C LIVE SERVICE / HALLOWEEN FOUNDATION LOCK v1.0

Date: 2026-09-20  
Status: **SOURCE FOUNDATION / DORMANT / NOT LIVE**

## Purpose
M6-C creates the reusable live-service foundation for Halloween 2026 and later seasonal events without activating an event prematurely or changing the existing economy/canon.

This execution label follows M6-A/M6-B progression work and maps to the live-service direction previously described in `ROADMAP.md`.

## Foundation scope
- shared seasonal event registry;
- server-authoritative replicated event-state folder;
- explicit seasonal edition tokens:
  - Halloween 2026: `HW26`
  - Christmas 2026: `XMAS26`;
- backward-compatible Collection Registry metadata hook for future seasonal entries;
- existing `StationSkinRegistry` event skins remain the visual-theme IDs;
- polling foundation can transition an approved event window without server restart.

## Hard locks
1. Halloween 2026 and Christmas 2026 remain **disabled** until Arda approves exact start/end windows.
2. Missing/invalid windows can never activate an event.
3. No seasonal collectible is added in this foundation commit.
4. No seasonal drop chance, mint cap, rarity mix, or event reward is invented here.
5. Existing S1 collectible edition/serial behavior remains unchanged.
6. Existing Credits, XP, rewards, rarity/drop targets, progression, trading, showcase, station ownership and decision colors remain unchanged.
7. Mystery canon remains unchanged; Flight 000 / Lost Child explanations remain CANON UNKNOWN.
8. Event state alone does not mutate the room or grant an event station skin.
9. Seasonal visuals remain Roblox 3D/procedural/in-engine by default.
10. Do not publish M6-C over the current v68 runtime-QC baseline until the v68 Android polish check is accepted or Arda explicitly overrides that gate.

## Reserved event identities

### Halloween 2026
- event ID: `HALLOWEEN_2026`
- edition token: `HW26`
- real-world anchor: `2026-10-31`
- station skin ID: `HALLOWEEN_2026`
- environment profile: `HALLOWEEN`
- runtime window: **TBD / disabled**
- collection pool: **TBD / empty**
- event case hooks: **TBD / empty**

### Christmas 2026
- event ID: `CHRISTMAS_2026`
- edition token: `XMAS26`
- real-world anchor: `2026-12-25`
- station skin ID: `CHRISTMAS_2026`
- environment profile: `CHRISTMAS`
- runtime window: **TBD / disabled**
- collection pool: **TBD / empty**
- event case hooks: **TBD / empty**

## Next M6-C production gates
1. v68 Android runtime acceptance for M6-B polish.
2. Approve Halloween event start/end window.
3. Design the limited Halloween collectible pool and event-specific case/anomaly hook.
4. Implement in-engine room dressing without blocking SCAN / TAG / OPEN / decision consoles.
5. Add clear `HW26` collection/index presentation.
6. Static/regression QC.
7. Publish through the locked LOST FOUND issue route and verify exact receipt.
8. Android runtime/event QC before calling Halloween LIVE.
