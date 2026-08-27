# LOST & FOUND: NIGHT SHIFT — M4-D PERSONAL STATION / SOCIAL FLEX LOCK v1.1

Status: LIVE_PUBLISHED v34 — BUILD/DEPLOY VERIFIED / SOLO RUNTIME QC PENDING
Updated: 2026-08-28

## Deployment evidence
- exact source commit: `950eeb1e7b4c6119292340f4e630b8fa3e589461`
- workflow run: `33100322285`
- Roblox version: `34`
- Rojo: `7.7.0`
- place bytes: `83918`
- place SHA256: `b70b00eaeab8cdfc6cb72b1ea881625ddc75995d2903c6ed3cae903436692612`
- receipt: `deploy-status/lost-and-found-m0.json`

This proves build/publish identity only. Runtime multiplayer behavior is not accepted until the gates below are tested.

## Goal
Convert the single shared job loop into a multiplayer-safe personal shift system while preserving one shared social room for collection flex and same-server trading.

## Initial server capacity
- Initial soft-launch design target: 8 active job players per server.
- The room provides 8 physical station slots: A through H.
- Station letters are temporary physical slots, not permanent player ownership.
- If a ninth player reaches a server before the experience MaxPlayers setting is reduced to 8, the runtime does not give that player a job station; no shared-job fallback is allowed.
- Capacity architecture must remain scalable without changing save identity, collection serials, or trade ownership.

## Station assignment
- On join, the server assigns one available physical station slot.
- Player receives `SHIFT ASSIGNED — STATION X` and a compact persistent `SHIFT STATION X` indicator.
- Character is staged at that assigned station and the station is locally highlighted for a short orientation window.
- Station model stores server-owned `OwnerUserId` / owner identity attributes.
- SCAN / TAG / OPEN / DECIDE are validated server-side against the assigned station owner.
- Non-owned job prompts are hidden locally where possible, but server ownership validation remains the security authority.
- On leave, the physical slot is cleaned and returns to VACANT.

## Persistent Personal Station Profile
Persistent identity is the player's station profile, NOT the physical A-H slot.

Current persisted station profile foundation:
- `equippedSkin`
- `ownedSkins`
- `title`

Default:
- skin `STANDARD_OPS`
- owned skins include `STANDARD_OPS`
- title `NIGHT SHIFT OPERATOR`

`LostAndFound_PlayerData_v1` remains the DataStore name; payload version is now 6.
Existing Credits / XP / discovered Index / serialized inventory stay compatible.

## Station skin registry
Source authority: `src/shared/StationSkinRegistry.lua`.

Initial design registry:
- `STANDARD_OPS` — FREE
- `INDUSTRIAL_SHIFT` — 8,000 Credits target
- `RETRO_AIRPORT` — 18,000 Credits target
- `BLACK_OPS` — 35,000 Credits target
- `LUXURY_EXECUTIVE` — ROBUX, exact product/price TBD
- `HALLOWEEN_2026` — EVENT
- `CHRISTMAS_2026` — EVENT

Registry presence does NOT mean all purchase flows are live yet. M4-D loads equipped station cosmetics; Station Shop purchase/equip UX remains a later gate after the personal-shift runtime passes.

## Credits / Robux / prestige monetization rules
Credits are non-transferable soft currency.
Approved Credits sinks include station skins, scanner/desk cosmetics, display upgrades, nameplates/titles, seasonal basic cosmetics, and later controlled convenience if telemetry supports it.

Robux is optional premium cosmetic monetization only.
Robux MUST NOT increase collectible odds, SECRET/ANOMALY chance, case rewards, or farming output.

Some achievement/event skins must remain prestige-only and unavailable through Credits or Robux.

## Personal job stream
Global `activeCase` is replaced by state owned by player/station.
Each state independently owns:
- active case;
- inspection progress;
- active physical item;
- claimant;
- decision lock;
- reward;
- collectible roll;
- next-case timing.

No player may progress, decide, claim reward from, or mutate another station's job.

## Case distribution
Hybrid model is locked and implemented:
1. Fresh players receive fixed onboarding cases 001 → 002 → 003.
2. After onboarding, each player gets an independent weighted random stream.
3. Normal cases have higher selection weight than mystery cases.
4. Returning progression is derived from persistent completed-case/XP economy state rather than resetting to job 1.
5. Mystery eligibility unlocks progressively; Ownerless precedes Flight 000 and later incidents.
6. Server avoids assigning a case already active at another station when another eligible case is available; duplication is allowed only when needed.

Initial mystery eligibility thresholds are implementation values and may be tuned from telemetry without changing canon:
- Ownerless Suitcase from 5 completed cases;
- Flight 000 from 7;
- Changing Weight from 8;
- Double Identity from 9;
- Lost Child from 10.

## Collectible / drop ownership
Collectible outcome is personal, not one shared server prize.

Flow:
`PERSONAL CASE → PERFECT ELIGIBILITY → SERVER-SIDE ROLL → GLOBAL SERIAL MINT → ONLY THAT PLAYER RECEIVES INSTANCE`

Collection Index and owned inventory are intentionally separate:
- encountering the case records Index discovery;
- PERFECT bonus evidence records historical bonus discovery / Archive progression;
- actual owned serialized instance still requires a valid drop roll;
- failed roll may therefore leave an Index card as `NOT OWNED`;
- replay can legitimately mint another copy only through a new valid drop roll;
- every copy still has a unique immutable serial/instance identity.

Initial ownership roll rates:
- COMMON 100%
- UNCOMMON 85%
- RARE 65%
- EPIC 40%
- ANOMALY 16%
- SECRET 8%

These are initial balance values, not immutable canon. Telemetry may tune them. No normal SECRET/ANOMALY uses one-drop-per-server logic.
Future explicitly designed server-incident artifacts may use one-server-winner rules only as special exceptions.
Seasonal limited items may use global mint caps.

## Collection Index rule
- Index = historical encounter/discovery prestige.
- Trading away the last copy does not erase Index.
- Index discovery never creates a free replacement item.
- A new owned copy must come from a valid drop/mint or trade.

## Social flex implementation
Station is personal workspace + collection flex space.
M4-D adds a replicated public showcase inside each station:
- automatically displays up to 3 currently owned high-rarity serialized items;
- serial labels are visible to nearby players;
- showcase is server-replicated rather than the retired local-only wall display;
- other players cannot remove or mutate those items.

Later UX may allow the owner to choose featured items manually.

## Performance rule
Initial design target is 8 simultaneous personalized stations.
Do not increase capacity until mobile/server telemetry proves station geometry, claimant/item spawning, showcases, trading, persistence, and network traffic remain stable.

## Solo runtime QC gate — ACTIVE NOW
1. existing Credits / XP / Index / serials survive rejoin;
2. player receives Station A when alone;
3. assignment toast + station indicator appear;
4. character lands at assigned station;
5. personal case reaches the station and SCAN → TAG → OPEN → DECIDE works;
6. reward remains correct;
7. next case advances independently;
8. public showcase renders owned serialized items;
9. no legacy giant local collection showcase remains;
10. no obvious mobile HUD/movement regression.

## Deferred two-player QC
When another tester is available:
1. different station assignment;
2. independent case streams;
3. player B cannot operate player A controls;
4. simultaneous case progression does not cross-update HUD/reward;
5. avoid-duplicate case assignment works when practical;
6. item/claimant objects remain isolated;
7. same-server trading still works after station isolation;
8. swapped serial ownership survives both-account rejoin.

Do not call M4-D runtime-accepted until solo QC passes. Do not call cross-player isolation runtime-proven until the deferred two-player QC passes.
