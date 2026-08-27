# LOST & FOUND: NIGHT SHIFT — M4-C ECONOMY HARDENING LOCK v1.0

Status: ACTIVE M4-C AUTHORITY

## Purpose
Protect the collectible economy before scaling player traffic, while preserving normal play and keeping SECRET / ANOMALY scarcity data-driven rather than arbitrarily nerfed.

## Credits role
Credits are the game's non-transferable soft currency.

Planned valid sinks:
- cosmetic scanner / desk / room styles;
- showcase / display upgrades;
- cosmetic case-file themes, titles, and nameplates;
- limited convenience such as controlled case rerolls;
- seasonal cosmetic shop content;
- optional processing fees only if telemetry later proves a sink is needed.

Credits MUST NOT:
- transfer directly player-to-player;
- be exchanged for Robux or real-world money;
- directly purchase SECRET / ANOMALY collectible instances;
- replace item-for-item serialized trading.

## M4-C v1 scope
1. Persistent per-player economy stats.
2. Buffered server economy telemetry.
3. Trade-access hardening for obvious throwaway alts.
4. No automatic farming feature.
5. No SECRET / ANOMALY daily cap or drop nerf until telemetry supports one.

## Persistent player economy stats
- `casesCompleted`
- `perfectCases`
- `creditsEarned`
- `creditsSpent`
- `serialsMinted`
- `tradesCompleted`
- `playSeconds`

Existing saves remain compatible. Missing stats default to zero, with conservative legacy progression estimation from existing XP / discoveries so established players are not unfairly reset.

## Trade access gate v1
Trading remains same-server and requires:
- persistence + serialized inventory ready;
- Roblox account age >= 7 days;
- either >= 5 completed cases OR >= 50 XP;
- at least one tradeable serialized item.

Credits are NOT used to unlock trading.

Reason:
This raises the cost of disposable alt accounts without making normal collectors grind excessively. This is not claimed to defeat all multi-account farming.

## Telemetry v1
Server records buffered aggregate counters into `LostAndFound_EconomyTelemetry_v1` by UTC day:
- `casesCompleted`
- `perfectCases`
- `creditsIssued`
- `serialsMinted`
- `tradeRequests`
- `tradeCompleted`
- `tradeCancelled`

Telemetry is aggregate gameplay data only; it does not store chat, external-payment data, or device identifiers.

## Anti-farm principles
- SCAN → TAG → OPEN → DECIDE remains active input; no auto-inspection / auto-decision.
- Client never controls rarity, serial minting, ownership, rewards, or trade commit.
- Do not add AFK reward loops.
- Do not add arbitrary collectible caps until real telemetry justifies them.
- If later abuse data shows a problem, prefer targeted controls (progression gates, event eligibility, diminishing returns) over blanket punishment.

## M4-C exit criteria
- old saves load without Credits / XP / Index / serial loss;
- economy stats persist through rejoin;
- normal case rewards remain unchanged;
- established player remains trade-eligible if requirements are met;
- new throwaway accounts are blocked from immediate trading;
- aggregate telemetry flushes without blocking gameplay;
- no new UI overlap or core-loop regression.
