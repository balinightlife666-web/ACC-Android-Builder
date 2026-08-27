# LOST & FOUND: NIGHT SHIFT — M4-D SOLO MOBILE RUNTIME QC

Date: 2026-08-28
Live build reviewed: Roblox v34
Deploy source reviewed: `950eeb1e7b4c6119292340f4e630b8fa3e589461`

## Runtime evidence supplied from mobile
Four in-game screenshots were reviewed from a solo server.

### Functional PASS evidence
- HUD shows `SHIFT STATION A`, confirming solo station assignment is visible.
- Personal case HUD is active at Station A.
- Multiple different personal cases were observed in the same session, including `LF-M0-007 Flight 000`, `LF-M0-003 Tag Mismatch`, and `LF-M0-001 Routine Claim`; this is consistent with returning-player personal case rotation rather than one fixed global first case.
- Station-scoped interaction prompt is visible as `STATION A SCANNER / SCAN ITEM`.
- Existing profile state visibly loaded: Credits, Index `18/20`, Archive `1/3`, and serialized collection display are present.
- A serialized public-showcase label is visible (`OT0-S1-000001`).
- A successful PERFECT result is visible for Routine Claim: `PERFECT • RETURN` with `+30 Credits / +20 XP`, matching locked reward values.
- A new serial mint is visibly confirmed: `MPA-S1-000003`, proving runtime mint/serial feedback remains active under Personal Shift.
- The old giant local-only wall showcase is not visible; M4-D replicated station showcase behavior is present instead.
- No obvious overlap with Roblox top controls or the jump button is visible in the supplied screenshots.

## Solo QC decision
**M4-D SOLO CORE FUNCTIONAL PASS.**

Multiplayer isolation remains deferred until a second tester is available; do not claim two-player isolation runtime-proven yet.

## Visual / UX issues found on v34
1. Room readability is too dark on mobile; large floor/station/character areas collapse into black.
2. Station-to-station separation needs stronger visible bay boundaries.
3. Decision controls read too much like flat floor panels from normal third-person mobile angles.
4. Public serial BillboardGui competes with screen HUD because it is too persistent/on-top.
5. Physical owner/station identity sign needs stronger readability.

## M4-D.1 — STATION READABILITY PASS
**IMPLEMENTED IN SOURCE / PUBLISH + RUNTIME QC PENDING.**

Changes:
- raised global indoor ambient/diffuse readability while retaining night-shift color language;
- reduced atmosphere density/haze and harsh contrast that crushed dark geometry;
- strengthened ceiling illumination with one controlled central fill light;
- added only one soft non-shadow station fill light per bay to protect mobile performance;
- added neon perimeter boundaries to each Station A-H without extra point lights;
- added visible floor `STATION X` marker near each personal bay entrance;
- enlarged and illuminated owner identity sign;
- raised decision consoles and added vertical decision faces plus low foot glow;
- brightened Standard Ops base/panel/trim palette;
- added `StationReadability.server.lua` to make public serial labels shorter-range, non-AlwaysOnTop, smaller and less HUD-competitive.

Hard locks preserved:
- no gameplay/reward/drop changes;
- no station ownership logic changes;
- no HUD size increase;
- no image generation/assets;
- no increase beyond 8 planned active stations;
- no extra shadow-casting lights.

## Next runtime QC after M4-D.1 publish
1. room should remain clearly night-shift but floor/player/station geometry must be readable;
2. Station A boundary and floor marker should be obvious;
3. owner sign should be readable from normal station approach;
4. RETURN / STORE / QUARANTINE / SECURITY consoles should read from third-person view;
5. serial showcase label should remain visible nearby but stop floating aggressively over HUD;
6. complete one case to confirm no functional regression.
