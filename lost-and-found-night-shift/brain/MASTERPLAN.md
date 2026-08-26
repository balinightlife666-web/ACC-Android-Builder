# LOST & FOUND: NIGHT SHIFT — MASTERPLAN v1.0

Status: **ACTIVE / LOCKED FOUNDATION**  
Authority: Arda = final authority. This file governs project direction until explicitly revised by Arda.

## 1. Product vision
A Roblox job-simulation game where players work the night shift at Lost & Found, inspect incoming property, verify claimants, make procedural decisions, collect rare objects, and gradually uncover a connected supernatural mystery.

The game must remain understandable in one sentence:

> Inspect lost items, decide where they belong, collect rare finds, and survive cases that should not exist.

## 2. Genre
Primary: **Simulation / Job Simulator**  
Secondary: Mystery, Collection, light Supernatural/Horror, Social/Co-op.

The game is **not** pure horror, not a tycoon, not an idle simulator, and not an open-world airport game.

## 3. Core loop
`ITEM ARRIVES → SCAN → INSPECT → VERIFY CLAIMANT → DECIDE → RESULT → REWARD → NEXT ITEM`

Allowed decisions:
- RETURN
- STORE
- QUARANTINE
- SECURITY

Every case must have a gameplay resolution even when the lore remains unresolved.

## 4. Long-term retention loop
`simple action → evidence → decision → reward → rarity → collection → progression → flex/social → mystery → update → return`

## 5. World strategy
Do not solve content growth by continuously enlarging the map.

V1 world is one premium Lost & Found terminal room. Long-term expansion is horizontal through new locations/item pools/cases:
- Airport Terminal
- Subway Lost & Found
- Grand Hotel
- Festival
- Cruise Ship
- classified/supernatural locations
- The Archive endgame

## 6. Asset strategy
Never mass-generate hundreds of unrelated 3D meshes.

Use:
- small number of approved base assets
- strong silhouettes
- modular materials/colors/tags/damage/accessories
- mutations/variants
- one geometry reused across gameplay, inventory, collection, showcase, and trading

M0 may use procedural Roblox Parts. Premium art replacement happens only after gameplay proves itself.

## 7. M0 scope — FIRST SUITCASE
M0 exists to prove the core loop before expensive visual production.

Required:
- one generated Lost & Found workroom
- one conveyor
- one scanner
- one inspection table
- claimant point
- RETURN / STORE / QUARANTINE / SECURITY stations
- 10 test cases
- Credits + XP
- results: PERFECT / CORRECT / QUESTIONABLE / WRONG / CATASTROPHIC
- automatic next case

Explicitly out of M0:
- trading
- Robux monetization
- season system
- second terminal
- large airport map
- hundreds of items
- complex collection room
- live economy

## 8. Main Season 1 mystery lock
The following are connected pillars, but their complete explanation must not be dumped early:
- Flight 000
- The Lost Child
- The Ownerless Suitcase

Players should be able to enjoy the job simulator without understanding the lore. Hardcore players should be able to build theories from clues.

## 9. Case-resolution taxonomy
- CLOSED — normal case fully completed.
- RESOLVED — operational problem solved, anomaly may remain unexplained.
- UNRESOLVED — no complete answer; stored in archive.
- CONNECTED — linked to the main mystery.

## 10. Anti-drift governance
Source-of-truth hierarchy:
1. MASTERPLAN.md
2. GAME_BIBLE.md
3. CASE_REGISTRY / ITEM_REGISTRY / ASSET_REGISTRY
4. CURRENT_STATE.md
5. ROADMAP.md
6. CHANGELOG.md

Rules:
- Memory/chat summaries are shortcuts, not authority.
- Never invent a replacement fact when a registry already defines it.
- If documents conflict, stop implementation of the conflicting part and preserve the higher source.
- A material canon/gameplay change requires updating the source-of-truth documents in the same change.
- Never claim a feature is LIVE because code exists or merged; deployment must be separately verified.

## 11. Product discipline
**NO FEATURE WITHOUT PURPOSE.**

A feature must materially serve at least one:
- fun
- retention
- collection
- social
- monetization
- lore

If it serves none, it does not enter production.
