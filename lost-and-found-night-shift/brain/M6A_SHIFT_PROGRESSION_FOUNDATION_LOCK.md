# LOST & FOUND: NIGHT SHIFT — M6-A SHIFT PROGRESSION FOUNDATION LOCK

Status: SOURCE IMPLEMENTATION

## Authority
- Existing persistent `xp` in `LostAndFound_PlayerData_v1` remains the only XP authority.
- `Config.Rewards` remains unchanged: PERFECT 20 XP, CORRECT 10 XP, QUESTIONABLE 3 XP, WRONG/CATASTROPHIC 0 XP.
- Shift Level is derived deterministically from persisted XP; no second progression currency or duplicate datastore is introduced.

## Level curve
1. 0 XP — PETUGAS BARU
2. 100 XP — OPERATOR JUNIOR
3. 250 XP — OPERATOR SHIFT
4. 500 XP — OPERATOR SENIOR
5. 900 XP — SPESIALIS KASUS
6. 1400 XP — PENGAWAS MALAM
7. 2100 XP — ANALIS INSIDEN
8. 3000 XP — SPESIALIS ARSIP
9. 4200 XP — PEMIMPIN SHIFT
10. 5600 XP — MASTER NIGHT SHIFT

## M6-A behavior
- Server derives level/title/current threshold/next threshold/progress/milestone from the canonical XP IntValue.
- Progression snapshot is exposed as player Attributes and finalized by `LostFoundProgressionRevision` so clients render an atomic snapshot.
- Milestone attributes are foundation tags only. M6-A does NOT gate or unlock gameplay content; actual unlock behavior belongs to M6-B.
- Compact Indonesia-first top-center HUD shows shift level, title, XP progress and next milestone.
- Level-up feedback is a short client-only text state; no reward is granted by the HUD.

## Hard locks preserved
- No change to Credits earning/spending.
- No change to XP rewards already defined in Config.Rewards.
- No change to Collection Index, drop rates, rarity assignment, serialized inventory, minting, trading or provenance.
- No change to station ownership, five-slot showcase lifecycle, rack geometry or station theme pricing.
- No change to case grading, decision semantics or mystery canon.
- No periodic progression polling loop; progression reacts to XP/leaderstats events only.
- No generated images/assets.

## Next phase
M6-B may consume the milestone/unlock tags to implement actual career-tier unlocks, but must preserve all hard locks above unless explicitly revised.
