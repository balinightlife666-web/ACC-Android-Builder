# LOST & FOUND: NIGHT SHIFT — ROADMAP v1.1

## M0 — FIRST SUITCASE
Goal: prove the job loop with placeholder procedural assets.

Exit criteria:
- one complete case cycle works
- all four decisions work
- rewards/results work
- no dead-end after a case
- next case starts automatically

## M0.1 — FEEL PASS
- improve conveyor timing
- better interaction distance/feedback
- claimant timing
- audio placeholders
- remove confusing steps

## M1 — PREMIUM ROOM
- approve one visual language
- replace/upgrade key room modules
- premium scanner/conveyor/counter
- 5 approved base item meshes minimum
- lighting polish

## M2 — COLLECTION FOUNDATION
- rarity
- discovery index
- serialized inventory compatibility
- collection UI/showcase foundation

## M3 — FLIGHT 000
First major mystery update.
- connected case chain
- server incident
- archive/case-file UI
- anomaly/secret collection evidence

## M4 — SOCIAL / ECONOMY HARDENING
### M4-A — serialized inventory
COMPLETE / runtime accepted.

### M4-B — secure same-server serialized trading v1
LIVE / Phase 1 mobile UI accepted.
Two-account ownership QC remains deferred until a second tester is available.

### M4-C — anti-alt + economy telemetry
LIVE v33 in build/deploy terms.
Runtime regression remains part of M4-D solo QC because M4-D supersedes the single-job runtime.

### M4-D — Personal Station / Multiplayer Job Isolation
Authority: `brain/M4D_PERSONAL_STATION_LOCK.md` v1.1.
Status: IMPLEMENTED IN SOURCE / PUBLISH + RUNTIME QC PENDING.

Implemented source direction:
- 8 physical station slots A-H;
- personal station allocator and owner identity;
- per-player case state, item, claimant, inspections, decisions, reward and advancement;
- fixed 001-003 onboarding then weighted independent case streams;
- avoid duplicate active cases when practical;
- personal server-side collectible ownership rolls;
- Collection Index remains historical and separate from actual owned serialized instances;
- persistent station profile foundation in player payload v6;
- station skin registry with Credits / Robux / event acquisition classes;
- replicated 3-item public serialized showcase per occupied station;
- mobile station assignment HUD + local station guide;
- non-owned job prompts hidden locally where possible and always rejected server-side.

M4-D exit gates:
1. exact source publishes successfully;
2. solo mobile QC confirms save integrity + station assignment + full case loop + reward + next case + showcase;
3. two-player QC later confirms job isolation and cross-player ownership protection;
4. deferred M4-B two-account trade persistence test remains on the regression list.

After M4-D solo pass:
- Station Shop v1: Credits purchase/equip for earnable skins;
- Robux premium station cosmetic product integration only after product IDs/prices are intentionally created;
- manual featured-showcase selection;
- collectible 3D visual-quality pass;
- multiplayer performance telemetry before raising active station capacity beyond 8.

## M5 — LIVE SERVICE
- daily/weekly cases
- event scheduler
- seasonal item pools
- seasonal room/environment transformations
- seasonal edition serials
- content update pipeline

### 2026 seasonal priorities
Authority: `brain/SEASONAL_EVENTS_LOCK.md`
- Halloween 2026: limited event collectibles + in-engine seasonal visual transformation around 31 October.
- Christmas 2026: limited event collectibles + in-engine seasonal visual transformation around 25 December.
- Exact event windows, item counts, drop rates and mint caps remain balance/runtime decisions.
- Seasonal gameplay assets remain Roblox 3D/procedural/in-engine by default; no AI image generation unless explicitly requested.

## Expansion rule
New locations are added only when the existing core loop and retention justify them. Do not enlarge the map as a substitute for content quality.
