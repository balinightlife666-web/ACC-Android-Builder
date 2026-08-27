# LOST & FOUND: NIGHT SHIFT — M4-D PERSONAL STATION / SOCIAL FLEX LOCK v1.0

Status: DESIGN LOCKED / IMPLEMENTATION NEXT
Updated: 2026-08-28

## Goal
Convert the current single shared job loop into a multiplayer-safe personal shift system while preserving one shared social room for collection flex and same-server trading.

## Initial server capacity
- Initial soft-launch target: maximum 8 players per server.
- The room provides 8 physical station slots: A through H.
- Station letters are temporary physical slots, not permanent player ownership.
- Capacity must be implemented so it can later scale beyond 8 without changing player save identity, collection serials, or trade ownership.

## Station assignment
- On join, the server assigns one available physical station slot.
- First available slot may be used; social preference may later try to place friends near each other when possible.
- The player receives a clear `SHIFT ASSIGNED — STATION X` message and persistent compact station indicator.
- The assigned station must visibly identify its current player owner.
- Other players cannot operate another player's SCAN / TAG / OPEN / DECIDE controls.
- On leave, the physical slot is cleaned and returns to VACANT.

## Persistent Personal Station Profile
The persistent identity is the player's station profile, NOT the physical A-H slot.

A player's saved station profile may contain:
- equipped station skin/theme;
- scanner cosmetic;
- desk/workbench cosmetic;
- lighting/trim cosmetic;
- showcase/display style;
- nameplate/title;
- seasonal decorations;
- eligible QoL upgrades that do not alter collectible rarity/drop odds.

When the player joins any server, their saved station profile is applied to whichever physical slot they receive.

Example:
- Day 1: player profile loads into Station F.
- Day 2: same profile may load into Station B.
- Cosmetic ownership/equipment remains unchanged.

## Personal job stream
The existing global `activeCase` model must be replaced by per-player/per-station case state.

Required ownership domains:
- active case;
- inspection progress;
- active item;
- claimant;
- decision state;
- reward;
- collectible roll;
- case advancement.

No player may progress, decide, claim reward from, or mutate another station's job.

## Case distribution
Use a hybrid progression model:
1. Fresh players receive a short fixed onboarding sequence so SCAN → TAG → OPEN → DECIDE is learned consistently.
2. After onboarding, case selection becomes independent weighted random per player.
3. Returning players use their own progression state rather than resetting to the first job.
4. Mystery cases remain gated by personal progression/canon rules and are not thrown randomly before eligibility.
5. The server should avoid assigning the same active case to multiple stations when practical, but duplication is allowed when the eligible pool is exhausted.

## Collectible/drop ownership
Collectible outcome is personal, not one shared server prize.

Flow:
`PERSONAL CASE → ELIGIBILITY/PERFECT → SERVER-SIDE ROLL → GLOBAL SERIAL MINT → ONLY THAT PLAYER RECEIVES INSTANCE`

Rules:
- Regular/Rare/Epic: personal station roll.
- SECRET/ANOMALY: personal station roll with stricter eligibility/rarity; not automatically granted merely because a case completes.
- Two players may independently obtain the same collectible type, but every minted instance has a unique immutable serial/instance identity.
- Normal SECRET/ANOMALY supply is NOT restricted to one drop per server.
- Very rare future server-incident artifacts may use one-server-winner logic only as explicitly designed special events, never as the default collectible rule.
- Seasonal limited items may use global mint caps across the whole experience.

## Collection Index rule
- Collection Index remains historical discovery prestige.
- Trading away the last owned copy does not erase Index discovery.
- Historical discovery does NOT grant a free replacement mint.
- Any new owned copy must come from a valid future drop/mint or trade.

## Credits role
Credits are non-transferable soft currency.

Approved Credit sinks:
- standard/premium-looking earnable station skins;
- scanner/desk/workbench cosmetics;
- showcase/display upgrades;
- nameplates/titles/case-file themes;
- seasonal basic cosmetics;
- controlled convenience such as limited rerolls if later balancing supports it;
- optional processing fees only if telemetry later demonstrates a need.

Credits MUST NOT:
- transfer player-to-player;
- directly buy SECRET/ANOMALY collectible instances;
- replace serialized item-for-item trading;
- improve SECRET/ANOMALY drop odds.

## Robux monetization role
Robux is optional premium cosmetic monetization.

Suitable Robux products:
- premium/exclusive station skins;
- complete station theme packs;
- premium cosmetic lighting/ambience;
- premium decorative/showcase variants;
- selected limited cosmetic event themes.

Robux MUST NOT:
- increase collectible rarity odds;
- increase SECRET/ANOMALY chance;
- grant better case rewards;
- grant stronger farming output;
- create pay-to-win trading advantage.

## Achievement/Event prestige
Some station skins/decorations should not be purchasable by either Credits or Robux.
They may be awarded only from:
- achievements;
- collection milestones;
- seasonal participation;
- special mystery completion;
- other clearly defined prestige goals.

This creates three visible social-status paths:
`PLAY → EARN CREDITS → CUSTOMIZE`
`COLLECT/ACHIEVE → EARN PRESTIGE → FLEX`
`ROBux → OPTIONAL PREMIUM COSMETICS`

## Social flex role
A station is not only a work surface. It is the player's personal workspace + collectible showcase + social flex space.

Other players may be allowed to:
- view station cosmetics;
- view displayed collectibles and serials;
- inspect public showcase/profile details;
- walk around the station area.

Other players must NOT be able to:
- operate job controls;
- move/remove another player's collectible instances;
- alter another player's equipped station profile.

## Performance rule
Initial design target is 8 simultaneous personalized stations.
Do not raise server capacity until mobile/server telemetry proves the room, claimant/item spawning, station visuals, trading, persistence, and network traffic remain stable.

## Implementation priority
M4-D is a multiplayer-safety blocker before broad soft launch.
Implementation sequence:
1. station-slot allocator + ownership;
2. per-player case state isolation;
3. owner-validated prompts/actions/rewards;
4. personal case distribution;
5. personal collectible rolls + global serial mint compatibility;
6. persistent station profile foundation;
7. station skin/equipment loading;
8. mobile/runtime QC with multiple players when a second tester is available.

Do not proceed to broad monetization or larger player capacity before multiplayer job isolation is functioning safely.
