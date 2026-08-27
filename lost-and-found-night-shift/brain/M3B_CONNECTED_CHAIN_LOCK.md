# LOST & FOUND: NIGHT SHIFT — M3-B CONNECTED MYSTERY CHAIN LOCK v1.0

Status: ACTIVE M3-B AUTHORITY

## Purpose
Connect the three existing Season 1 mystery pillars without revealing their final supernatural explanation and without forcing players with existing valid saves to replay old cases.

## Canon pillars
1. Ownerless Suitcase — `LF-M0-006`
2. Flight 000 — `LF-M0-007`
3. The Lost Child — `LF-M0-010`

All existing case facts, correct decisions, tags, people, dates, and resolutions remain unchanged.

## Persistent compatibility rule
M3-B does not create a second progression database. It derives archive progression from already-persistent PERFECT bonus discoveries:
- `ownerless_tag_00017284` => Ownerless Suitcase link confirmed;
- `flight_000_boarding_tag` => Flight 000 link confirmed;
- `milo_toy_train_2001` => Lost Child link confirmed.

This means players who earned these discoveries before M3-B automatically regain the corresponding archive entries after rejoin.

## Archive chain
### 000-A — FLIGHT 000
- Passenger: Jonas Vale
- Passenger record: FOUND
- Flight record: NOT FOUND
- Tag: `F0-00013`
- Correct operational action: QUARANTINE
- Status: CONNECTED / UNRESOLVED

### 000-B — OWNERLESS SUITCASE
- Owner: UNKNOWN
- Flight: `000`
- Tag: `000-17284`
- Database origin: NONE
- Correct operational action: QUARANTINE
- Status: CONNECTED / UNRESOLVED

### 000-C — LOST CHILD
- Name: Milo Hart
- Record: MISSING PERSON / 2001
- Tag: `OLD-2001-14`
- Correct operational action: SECURITY
- Status: CONNECTED / PROTECTIVE ESCALATION

## Connection statement allowed
The archive may state only that all three cases share a confirmed connection to the same unresolved Season 1 anomaly chain. It may not state the cause, entity, mechanism, origin, timeline explanation, or final supernatural answer.

## Runtime behavior
- ARCHIVE button shows discovered-chain count, e.g. `ARCHIVE 2/3`.
- Archive popup is a mobile-first scrolling list of entries 000-A / 000-B / 000-C.
- Locked entries remain visible as locked placeholders so the player understands the chain exists.
- Existing saved PERFECT bonus discoveries unlock their matching archive entries automatically.
- New PERFECT completion of any of the three cases updates the archive immediately.
- A brief `CASE LINK CONFIRMED` notice may appear for newly confirmed Ownerless/Lost Child links.
- Flight 000 retains its stronger terminal-incident presentation from M3-A.

## Hard limits
- No final explanation.
- No new location.
- No new currency.
- No trading.
- Lost Child remains a person requiring SECURITY/protective escalation; never treat the child as property.
- The 2001 date is immutable unless Arda explicitly revises canon.
