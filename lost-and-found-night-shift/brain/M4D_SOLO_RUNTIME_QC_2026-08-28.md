# LOST & FOUND: NIGHT SHIFT — M4-D SOLO MOBILE RUNTIME QC

Date: 2026-08-28
Live build under test: Roblox v34
Deploy source: `950eeb1e7b4c6119292340f4e630b8fa3e589461`

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

### Visual / UX issues found
1. **Room readability is too dark on mobile.** Large portions of floor, station structure, player silhouette, and station boundaries collapse into black. Functional controls are visible, but the physical station does not yet read as premium or easy to navigate.
2. **Station-to-station separation needs stronger visual language.** With multiple players later, bay ownership could be harder to read than intended. Station ID/signage, floor edge/guide lighting, and work-surface illumination need a controlled brightness pass.
3. **Decision controls read too much like flat floor panels.** They function, but their location and labels are visually weak from normal third-person mobile angles. Improve contrast/height/readability without enlarging the UI.
4. **Public serial BillboardGui can visually float into the HUD area.** The serial is useful for flex, but `AlwaysOnTop`/distance behavior should be softened so world labels do not compete with screen UI.
5. The owner/station identity sign is not clearly readable in the supplied framing, so physical owner-sign readability remains a visual QC item even though Station A assignment is confirmed by HUD/prompt.

## QC decision
**M4-D SOLO CORE FUNCTIONAL PASS / VISUAL POLISH REQUIRED.**

Do not call M4-D fully runtime-accepted yet. The solo gameplay foundation is functioning, but a Station Readability / Lighting pass should be completed before Station Shop becomes the next visible feature.

## Recommended immediate next patch
`M4-D.1 — STATION READABILITY PASS`
- raise ambient/work-light readability without losing night-shift mood;
- strengthen station boundary/ID visibility;
- improve decision-console readability;
- reduce public serial-label HUD interference;
- preserve current mobile HUD sizes and current working personal case loop.

Multiplayer isolation QC remains deferred until a second tester is available.