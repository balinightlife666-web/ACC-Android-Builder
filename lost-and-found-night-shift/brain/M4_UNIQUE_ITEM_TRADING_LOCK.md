# LOST & FOUND: NIGHT SHIFT — M4 UNIQUE ITEM / TRADING LOCK v1.1

Status: ACTIVE M4 AUTHORITY

## Purpose
Build a collectible economy where each owned collectible is an individual server-authoritative item instance with its own immutable identity and human-readable serial. Trading moves ownership by instance, never by Collection Index flag.

## Core model
Two layers remain separate:

1. COLLECTION INDEX
- Records whether the player has ever discovered a collectible type.
- Discovery completion must never be lost when an item is later traded away.

2. INVENTORY INSTANCE
- Represents an actual owned virtual object.
- Every instance has a unique immutable internal `instanceId`.
- Every instance has a unique human-readable serial.
- Ownership moves by instance, not by collection type.
- If a discovered type has no currently owned instance after a trade, Collection UI must show `NOT OWNED`, not mint a replacement automatically.

## Serial format
Default Season 1 format:
`<PREFIX>-S1-<GLOBAL MINT NUMBER>`

Example:
`CMB-S1-000001`

Rules:
- serial numbers are created only by the server;
- each collectible type uses an atomic global mint counter;
- no client may choose or overwrite a serial;
- gaps in mint numbers are allowed if a reserved mint cannot be persisted;
- a serial is immutable after creation;
- the internal `instanceId` remains the real ownership key even if the display serial is shown publicly.

## Instance fields
- `instanceId`
- `collectionId`
- `serial`
- `serialNumber`
- `edition`
- `mintedAt`
- `originalFinderUserId`
- `currentOwnerUserId`
- `sourceCaseId`
- `sourceKind`
- `tradeable`
- `tradeCount`
- `lastTradeAt`
- `lastTradeId`
- bounded provenance history

## Backward compatibility / migration hard lock
Existing `LostAndFound_PlayerData_v1` saves remain valid.
- Existing Credits / XP / discovered IDs must not reset.
- Serialized inventory is optional on legacy payloads.
- Legacy discovered collectibles are backfilled only during the one-time serial migration.
- A persisted `serialMigrationComplete` flag permanently closes legacy backfill after migration.
- Trading away the last owned instance of a discovered collectible MUST NOT cause a free remint on rejoin.
- A player may later earn another instance only through an actual gameplay award path, never because ownership became zero.

## M4-A — UNIQUE ITEM INSTANCE + SERIAL FOUNDATION
Status: COMPLETE / RUNTIME-ACCEPTED ON ROBLOX v31.

Accepted evidence:
- existing save backfilled without losing Collection progression;
- mobile Collection displayed serials;
- `SNP-S1-000001`, `ARP-S1-000001`, and `UMR-S1-000001` remained unchanged after rejoin;
- serial ownership persistence therefore passed the M4-A gate.

## M4-B — SECURE PLAYER TRADING v1
Status: IMPLEMENTED IN SOURCE / BUILD + RUNTIME QC PENDING.

### Scope lock
M4-B v1 is deliberately narrow:
- same Roblox server only;
- one serialized item offered by Player A;
- one serialized item offered by Player B;
- no currency in the trade;
- no multi-item bundles yet;
- no cross-server trade queue yet.

This is intentional to reduce dupe / rollback surface before scaling the economy.

### Player flow
`TRADE → SELECT PLAYER → REQUEST → ACCEPT → SELECT EXACT SERIAL → BOTH CONFIRM → 3s FINAL REVIEW LOCK → BOTH FINAL CONFIRM → COMMIT → RESULT`

### Server validation
- player must have persistence + serial migration ready;
- player must own at least one tradeable serialized instance;
- target must be in the same live server;
- exact ownership is validated using immutable `instanceId`;
- client never submits arbitrary item data as authority;
- selected instance is server-locked while the trade session is active;
- changing an offer resets confirmations;
- once both first-confirm, offers enter final review lock;
- disconnect or cancellation before commit releases item locks without moving ownership.

### Persistence / anti-dupe
M4-B uses:
- in-server instance locks;
- `LostAndFound_TradeJournal_v1` durable transaction records;
- `LostAndFound_TradeRecovery_v1` per-user recovery markers;
- journal status `PREPARED` before profile mutation;
- both profile inventories saved before journal becomes `COMMITTED`;
- persistence failure triggers rollback to original inventory snapshots;
- if rollback cannot fully persist, recovery markers remain so next load reconciles toward a safe journal state;
- committed recovery reasserts incoming ownership idempotently;
- uncommitted recovery restores the original outgoing instance;
- bounded provenance is appended to the moved instance on committed trades.

### Mobile UI
- compact `TRADE` utility button joins the existing Credits / Index / Archive control stack;
- player lobby lists same-server players;
- incoming request has ACCEPT / DECLINE;
- exact serial picker lists owned tradeable instances;
- trade screen shows YOUR OFFER and THEIR OFFER;
- first confirm and final confirm are separate;
- final review has a server-enforced delay;
- COMMITTING state warns the user not to leave;
- completion view shows sent serial, received serial, and trade ID;
- utility button is hidden behind Collection / Archive / Case File / Trade popups.

## Economy rules
- The game itself only handles in-game item ownership and in-game item-for-item trades.
- No external-payment fields, links, QR codes, account details, or off-platform transaction flow are part of the game.
- No automatic farming system is introduced as part of trading.
- Secret / Anomaly scarcity remains server-authoritative.
- Collection Index remains historical discovery progress even after ownership is traded away.

## M4-B runtime exit criteria
1. two players in one server can see each other in TRADE lobby;
2. request / accept / decline works;
3. each player can select one exact serial they own;
4. server prevents selecting an unowned / locked instance;
5. first confirmation requires both offers;
6. final confirmation is unavailable until the review delay ends;
7. both final-confirm → ownership swaps once;
8. Collection Index remains unchanged;
9. traded-away type can show `NOT OWNED` if no duplicate is retained;
10. received serial appears in new owner's inventory;
11. leave/rejoin preserves the swapped serial ownership;
12. cancellation / disconnect before commit does not move items;
13. no duplicate serial is created by the trade path.

## Deferred hardening after M4-B v1 passes
- stronger minimum progression / anti-alt thresholds based on telemetry;
- multi-item trade bundles;
- richer public provenance viewer;
- trade history browser;
- cross-server trade discovery only if later justified;
- economy telemetry / suspicious transfer detection.
